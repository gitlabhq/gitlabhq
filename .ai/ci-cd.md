# CI/CD Configuration Guide

This document describes the architecture, patterns, and common tasks for the GitLab project CI/CD configuration.

## Overview

The CI/CD configuration spans ~58 YAML files and ~12,500 lines across `.gitlab-ci.yml` and `.gitlab/ci/`. The pipeline defines 18 stages:

`sync` > `preflight` > `prepare` > `build-images` > `release-environments` > `fixtures` > `lint` > `test-frontend` > `test` > `post-test` > `review` > `qa` > `post-qa` > `pre-merge` > `pages` > `notify` > `benchmark` > `ai-gateway`

## Directory Structure

```
.gitlab-ci.yml                    # Entry point: stages, workflow rules, global variables, includes
.gitlab/ci/
  version.yml                     # Pinned tool versions (Ruby, Go, Node, Chrome, etc.)
  global.gitlab-ci.yml            # Shared foundations: retry, before_script, DB/Redis services, caches
  rules.gitlab-ci.yml             # Centralized rules (~3,500 lines): conditions, file patterns, composite rules
  rails.gitlab-ci.yml             # RSpec jobs (FOSS + EE), predictive pipelines, coverage, artifact collectors
  rails/
    shared.gitlab-ci.yml          # RSpec base job definitions, parallel configs, DB service mixins
    rspec-predictive.gitlab-ci.yml.erb  # ERB template for dynamically generated predictive RSpec jobs
  frontend.gitlab-ci.yml          # Jest, Storybook, Webpack, ESLint, frontend fixtures
  static-analysis.gitlab-ci.yml   # RuboCop, ESLint, Semgrep, Haml-lint
  database.gitlab-ci.yml          # DB setup, schema validation, migration testing
  setup.gitlab-ci.yml             # clone-gitlab-repo, setup-test-env, compile-assets, cache warming
  qa.gitlab-ci.yml                # E2E QA test triggers
  qa-common/                      # Shared QA config (rules, variables, Allure reporting)
  test-on-cng/                    # Cloud-Native GitLab E2E tests
  test-on-gdk/                    # GDK-based E2E tests
  test-on-omnibus/                # Omnibus-based E2E tests (internal + external)
  cng/                            # CNG image build jobs
  templates/
    gem.gitlab-ci.yml             # Reusable gem child pipeline template (uses spec:inputs)
  gitlab-gems.gitlab-ci.yml       # Child pipelines for gems/ directory
  vendored-gems.gitlab-ci.yml     # Child pipelines for vendor/gems/ directory
  overrides/
    skip.yml                      # No-op pipeline for security-canonical-sync MRs
    gem-cache.rails-next.yml      # Cache override for rails-next pipelines
    README.md                     # Explains the override pattern
  includes/
    as-if-jh.gitlab-ci.yml        # JiHu (Chinese edition) compatibility testing
    gitlab-com/
      danger-review.gitlab-ci.yml # Danger bot review (CI component)
  as-if-foss.gitlab-ci.yml        # FOSS compatibility testing (strips EE code)
  docs.gitlab-ci.yml              # Documentation linting, review apps
  workhorse.gitlab-ci.yml         # GitLab Workhorse Go tests
  coverage.gitlab-ci.yml          # Code coverage collection
  caching.gitlab-ci.yml           # Cache warming/updating jobs
  reports.gitlab-ci.yml           # SAST, Secret Detection, Dependency Scanning
  notify.gitlab-ci.yml            # Slack notifications
  releases.gitlab-ci.yml          # Release tagging
  release-environments.gitlab-ci.yml  # Release environment deployments
  build-images.gitlab-ci.yml      # CI image builds
  # ... and more (benchmark, memory, preflight, pages, etc.)
```

## Include Mechanism

The main `.gitlab-ci.yml` uses a **wildcard include** to auto-register all top-level CI files:

```yaml
include:
  - local: .gitlab/ci/*.gitlab-ci.yml
```

Adding a new `.gitlab/ci/foo.gitlab-ci.yml` file automatically includes it in the pipeline. No manual registration needed.

Conditional includes handle special cases:

- `overrides/skip.yml` -- only for security-canonical-sync MRs (creates a no-op pipeline)
- `includes/gitlab-com/*.gitlab-ci.yml` -- only on gitlab.com or jihulab.com
- `includes/as-if-jh.gitlab-ci.yml` -- only for gitlab.com MRs (not stable branches, not quarantined)
- `overrides/gem-cache.rails-next.yml` -- only for rails-next pipelines

Sub-files can include other local files (two-level nesting). Key example:

- `rails.gitlab-ci.yml` includes `rails/shared.gitlab-ci.yml`
- `rails/shared.gitlab-ci.yml` includes `global.gitlab-ci.yml` and `rules.gitlab-ci.yml`

## Rules System

`rules.gitlab-ci.yml` is the single largest file (~3,500 lines) and the single source of truth for all job conditions. It uses three pattern types:

### 1. Condition anchors (`.if-*`)

Boolean conditions based on CI variables. Referenced via YAML anchors.

```yaml
.if-merge-request: &if-merge-request
  if: '$CI_PIPELINE_SOURCE == "merge_request_event" && ...'

.if-default-branch-refs: &if-default-branch-refs
  if: '$CI_COMMIT_REF_NAME == $CI_DEFAULT_BRANCH && ...'
```

### 2. File-change patterns (`.*-patterns`)

Glob arrays for detecting which files changed. Referenced via YAML anchors.

```yaml
.ci-patterns: &ci-patterns
  - "{,jh/}.gitlab-ci.yml"
  - "{,jh/}.gitlab/ci/**/*"

.backend-patterns: &backend-patterns
  - "app/**/*"
  - "lib/**/*"
  # ...
```

### 3. Composite rule sets (`.category:rules:job-type`)

Combine conditions + file patterns into complete `rules:` blocks that jobs reference via `extends:`.

```yaml
.rails:rules:ee-and-foss-default-rules:
  rules:
    - <<: *if-fork-merge-request
      changes: *code-backstage-spec-patterns
      when: never
    - <<: *if-merge-request-labels-pipeline-expedite
      when: never
    - <<: *if-merge-request-labels-run-all-rspec
    - <<: *if-merge-request
      changes: *core-backend-patterns
```

Jobs use these via extends:

```yaml
rspec unit pg17:
  extends:
    - .rspec-base-pg17
    - .rspec-unit-parallel
    - .rails:rules:ee-and-foss-unit
```

### Pipeline tiers

MR pipelines use a tiering system controlled by labels:

- `pipeline::tier-1` -- minimal (predictive tests only)
- `pipeline::tier-2` -- standard
- `pipeline::tier-3` -- full (all tests including nightly-level jobs)

Special labels:
- `pipeline::expedited` -- skip most jobs
- `pipeline:run-all-rspec` -- force all RSpec jobs
- `pipeline:run-all-jest` -- force all Jest jobs
- `pipeline:run-as-if-foss` -- run FOSS compatibility
- `pipeline:run-search-tests` -- run Elasticsearch/OpenSearch tests
- `pipeline:run-praefect-with-db` -- run Praefect DB tests
- `pipeline:update-cache` -- force cache updates

## Shared Foundations

### `global.gitlab-ci.yml`

Defines reusable building blocks:

- **`.default-retry`** -- retry policy (max 2 retries for infra failures)
- **`.default-before_script`** -- standard before_script (FOSS mode, GOPATH, utils)
- **`.repo-from-artifacts`** -- use cloned repo from artifacts instead of git clone
- **`.use-docker-in-docker`** -- Docker-in-Docker setup with registry mirror
- **`.use-pg16`, `.use-pg17`, `.use-pg18`** -- PostgreSQL service configs with auto-explain
- **`.use-pg17-es7-ee`, `.use-pg17-clickhouse23`, etc.** -- combined service stacks
- **Cache definitions** -- `.ruby-gems-cache`, `.node-modules-cache`, `.assets-cache`, `.rubocop-cache`, etc.

### `rails/shared.gitlab-ci.yml`

RSpec-specific foundations:

- **`.rspec-base`** -- base RSpec job (extends retry, before_script, cache; sets stage, needs, script, after_script)
- **`.rspec-base-pg17`** -- RSpec with PG17 services
- **`.rspec-ee-base-pg17`** -- EE RSpec with PG17 + Elasticsearch
- **Parallel configs** -- `.rspec-unit-parallel: parallel: 44`, `.rspec-system-parallel: parallel: 32`, etc.
- **DB variants** -- `.single-db`, `.single-db-ci-connection`, `.praefect-with-db`

### `version.yml`

Pinned versions for all tools used in CI images. The `DEFAULT_CI_IMAGE` variable in `.gitlab-ci.yml` is constructed from these versions.

## Child Pipelines

Child pipelines are triggered via `trigger:` jobs. Key patterns:

### RSpec predictive pipelines

`rspec-predictive:pipeline-generate` generates YAML from an ERB template based on detected test files, then `rspec:predictive:trigger` triggers a child pipeline from the generated artifact.

### Gem pipelines

`templates/gem.gitlab-ci.yml` uses `spec:inputs` to create parameterized gem pipelines:

```yaml
# In vendored-gems.gitlab-ci.yml:
include:
  - local: .gitlab/ci/templates/gem.gitlab-ci.yml
    inputs:
      gem_name: "microsoft_graph_mailer"
      gem_path_prefix: "vendor/gems/"
```

Each gem gets its own child pipeline triggered from its `.gitlab-ci.yml`.

### QA/E2E pipelines

`qa.gitlab-ci.yml`, `test-on-cng/`, `test-on-omnibus/`, and `test-on-gdk/` trigger E2E test child pipelines with shared config from `qa-common/`.

## Override Pattern

The `overrides/` directory contains files that conditionally redefine job keys. GitLab CI natively merges definitions with the same key name, so conditional `include` directives can alter job behavior.

Example: `overrides/skip.yml` is included only for security-canonical-sync MRs. It defines a `no-op` job that replaces the entire pipeline with a skip message.

## Artifact Collectors

RSpec jobs run with high parallelism (e.g., 44 parallel unit jobs). Since `needs:` has a 50-job limit, intermediate `rspec:artifact-collector` jobs aggregate artifacts from groups of RSpec jobs, allowing downstream jobs like `rspec:coverage` to depend on all results.

## Workflow Rules

The `workflow:rules:` block in `.gitlab-ci.yml` (~30 rules) determines:

- Whether a pipeline runs at all
- Which Ruby version to use (default vs next)
- The pipeline name
- Special variable overrides (e.g., `BUNDLE_GEMFILE: Gemfile.next` for rails-next)

Key pipeline types:
- **MR pipelines** -- triggered by merge request events
- **Default branch pipelines** -- pushes/merges to master
- **Scheduled pipelines** -- nightly, weekly, maintenance
- **Tag pipelines** -- for releases
- **Triggered pipelines** -- from Gitaly or AI Gateway projects
- **Security sync pipelines** -- security mirror to canonical

## Common Tasks

### Add a new CI job

1. Add the job to the appropriate `.gitlab/ci/*.gitlab-ci.yml` file (or create a new one -- it auto-includes via wildcard).
2. Define rules in `rules.gitlab-ci.yml` using existing condition anchors and file patterns.
3. Extend shared foundations (`.default-retry`, `.default-before_script`, service mixins).

### Add file-change patterns for a new area

1. In `rules.gitlab-ci.yml`, add a new pattern anchor:
   ```yaml
   .my-new-patterns: &my-new-patterns
     - "path/to/files/**/*"
   ```
2. Create composite rules that use the pattern with appropriate conditions.

### Add a new child pipeline

1. Create the child pipeline YAML (e.g., `.gitlab/ci/my-feature/main.gitlab-ci.yml`).
2. Add a trigger job in a top-level CI file.
3. Add rules for when the trigger should run.

### Modify RSpec parallel counts

In `rails/shared.gitlab-ci.yml`, adjust the `.rspec-*-parallel` values. Follow the formula in the comments:

```
parallel_job_count = ceil(current_count * (avg_duration / target_duration))
```

Target is 30 minutes per job. Snowflake dashboard links are in the comments next to each parallel config.

### Add a new gem child pipeline

In `gitlab-gems.gitlab-ci.yml` or `vendored-gems.gitlab-ci.yml`, add:

```yaml
- local: .gitlab/ci/templates/gem.gitlab-ci.yml
  inputs:
    gem_name: "my-gem"
    gem_path_prefix: "gems/"  # or "vendor/gems/"
```

The gem must have its own `.gitlab-ci.yml` at its root.

## External Dependencies

The CI config pulls from external sources:

- **Remote template**: `untamper-my-lockfile` (lockfile integrity check)
- **CI Components**: `danger-review@2.1.0`, `allure-report@11.18.0`
- **CI Templates**: SAST, Secret Detection, Dependency Scanning
- **External project includes**: `gitlab-org/quality/pipeline-common`

## Gotchas

- **Wildcard auto-include**: Any new `*.gitlab-ci.yml` at the top level of `.gitlab/ci/` is automatically included. Files in subdirectories are NOT auto-included.
- **Rules first-match-wins**: GitLab CI `rules:` uses first-match-wins semantics. Order matters. Put `when: never` exclusions before `when: always` inclusions.
- **YAML anchor scope**: Anchors defined in `rules.gitlab-ci.yml` are available in files that `include:` it (like `rails/shared.gitlab-ci.yml`), but NOT in files included via the top-level wildcard. Top-level files use `!reference` instead.
- **`!reference` vs YAML anchors**: Use `!reference [".some-key", rules]` to reference keys across files included at the same level. YAML anchors (`*anchor`) only work within the same file or direct includes.
- **needs: limit**: A job can depend on at most 50 other jobs via `needs:`. This is why artifact collector jobs exist.
- **Merge train exclusion**: Most `.if-merge-request` conditions explicitly exclude merge trains (`$CI_MERGE_REQUEST_EVENT_TYPE != "merge_train"`).
