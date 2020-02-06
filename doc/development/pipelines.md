# Pipelines for the GitLab project

Pipelines for <https://gitlab.com/gitlab-org/gitlab> and <https://gitlab.com/gitlab-org/gitlab-foss> (as well as the
`dev` instance's mirrors) are configured in the usual
[`.gitlab-ci.yml`](https://gitlab.com/gitlab-org/gitlab/blob/master/.gitlab-ci.yml)
which itself includes files under
[`.gitlab/ci/`](https://gitlab.com/gitlab-org/gitlab/tree/master/.gitlab/ci)
for easier maintenance.

We're striving to [dogfood](https://about.gitlab.com/handbook/engineering/#dogfooding)
GitLab [CI/CD features and best-practices](../ci/yaml/README.md)
as much as possible.

## Stages

The current stages are:

- `sync`: This stage is used to synchronize changes from <https://gitlab.com/gitlab-org/gitlab> to
  <https://gitlab.com/gitlab-org/gitlab-foss>.
- `prepare`: This stage includes jobs that prepare artifacts that are needed by
  jobs in subsequent stages.
- `test`: This stage includes most of the tests, DB/migration jobs, and static analysis jobs.
- `post-test`: This stage includes jobs that build reports or gather data from
  the `test` stage's jobs (e.g. coverage, Knapsack metadata etc.).
- `review-prepare`: This stage includes a job that build the CNG images that are
  later used by the (Helm) Review App deployment (see
  [Review Apps](testing_guide/review_apps.md) for details).
- `review`: This stage includes jobs that deploy the GitLab and Docs Review Apps.
- `qa`: This stage includes jobs that perform QA tasks against the Review App
  that is deployed in the previous stage.
- `post-qa`: This stage includes jobs that build reports or gather data from
  the `qa` stage's jobs (e.g. Review App performance report).
- `notification`: This stage includes jobs that sends notifications about pipeline status.
- `pages`: This stage includes a job that deploys the various reports as
  GitLab Pages (e.g. <https://gitlab-org.gitlab.io/gitlab/coverage-ruby/>,
  <https://gitlab-org.gitlab.io/gitlab/coverage-javascript/>,
  <https://gitlab-org.gitlab.io/gitlab/webpack-report/>).

## Default image

The default image is currently
`registry.gitlab.com/gitlab-org/gitlab-build-images:ruby-2.6.5-golang-1.12-git-2.24-lfs-2.9-chrome-73.0-node-12.x-yarn-1.21-postgresql-9.6-graphicsmagick-1.3.34`.

It includes Ruby 2.6.5, Go 1.12, Git 2.24, Git LFS 2.9, Chrome 73, Node 12, Yarn 1.21,
PostgreSQL 9.6, and Graphics Magick 1.3.33.

The images used in our pipelines are configured in the
[`gitlab-org/gitlab-build-images`](https://gitlab.com/gitlab-org/gitlab-build-images)
project, which is push-mirrored to <https://dev.gitlab.org/gitlab/gitlab-build-images>
for redundancy.

The current version of the build images can be found in the
["Used by GitLab section"](https://gitlab.com/gitlab-org/gitlab-build-images/blob/master/.gitlab-ci.yml).

## Default variables

In addition to the [predefined variables](../ci/variables/predefined_variables.md),
each pipeline includes default variables defined in
<https://gitlab.com/gitlab-org/gitlab/blob/master/.gitlab-ci.yml>.

## Common job definitions

Most of the jobs [extend from a few CI definitions](../ci/yaml/README.md#extends)
that are scoped to a single
[configuration parameter](../ci/yaml/README.md#configuration-parameters).

These common definitions are:

- `.default-tags`: Ensures a job has the `gitlab-org` tag to ensure it's using
  our dedicated runners.
- `.default-retry`: Allows a job to [retry](../ci/yaml/README.md#retry) upon `unknown_failure`, `api_failure`,
  `runner_system_failure`, `job_execution_timeout`, or `stuck_or_timeout_failure`.
- `.default-before_script`: Allows a job to use a default `before_script` definition
  suitable for Ruby/Rails tasks that may need a database running (e.g. tests).
- `.default-cache`: Allows a job to use a default `cache` definition suitable for
  Ruby/Rails and frontend tasks.
- `.default-only`: Restricts the cases where a job is created. This currently
  includes `master`, `/^[\d-]+-stable(-ee)?$/` (stable branches),
  `/^\d+-\d+-auto-deploy-\d+$/` (auto-deploy branches), `/^security\//` (security branches), `merge_requests`, `tags`.
  Note that jobs won't be created for branches with this default configuration.
- `.only:variables-canonical-dot-com`: Only creates a job if the project is
  located under <https://gitlab.com/gitlab-org>.
- `.only:variables_refs-canonical-dot-com-schedules`: Same as
  `.only:variables-canonical-dot-com` but add the condition that pipeline is scheduled.
- `.except:refs-deploy`: Don't create a job if the `ref` is an auto-deploy branch.
- `.except:refs-master-tags-stable-deploy`: Don't create a job if the `ref` is one of:
  - `master`
  - a tag
  - a stable branch
  - an auto-deploy branch
- `.only:kubernetes`: Only creates a job if a Kubernetes integration is enabled
  on the project.
- `.only-review`: This extends from:
  - `.only:variables-canonical-dot-com`
  - `.only:kubernetes`
  - `.except:refs-master-tags-stable-deploy`
- `.only-review-schedules`: This extends from:
  - `.only:variables_refs-canonical-dot-com-schedules`
  - `.only:kubernetes`
  - `.except:refs-deploy`
- `.use-pg9`: Allows a job to use the `postgres:9.6` and `redis:alpine` services.
- `.use-pg10`: Allows a job to use the `postgres:10.9` and `redis:alpine` services.
- `.use-pg9-ee`: Same as `.use-pg9` but also use the
  `docker.elastic.co/elasticsearch/elasticsearch:5.6.12` services.
- `.use-pg10-ee`: Same as `.use-pg10` but also use the
  `docker.elastic.co/elasticsearch/elasticsearch:5.6.12` services.
- `.only-ee`: Only creates a job for the `gitlab` or `gitlab-ee` project.
- `.only-ee-as-if-foss`: Same as `.only-ee` but simulate the FOSS project by
  setting the `FOSS_ONLY='1'` environment variable.

## Changes detection

If a job extends from `.default-only` (and most of the jobs should), it can restrict
the cases where it should be created
[based on the changes](../ci/yaml/README.md#onlychangesexceptchanges)
from a commit or MR by extending from the following CI definitions:

- `.only:changes-code`: Allows a job to only be created upon code-related changes.
- `.only:changes-qa`: Allows a job to only be created upon QA-related changes.
- `.only:changes-docs`: Allows a job to only be created upon docs-related changes.
- `.only:changes-graphql`: Allows a job to only be created upon GraphQL-related changes.
- `.only:changes-code-backstage`: Allows a job to only be created upon code-related or backstage-related (e.g. Danger, RuboCop, specs) changes.
- `.only:changes-code-qa`: Allows a job to only be created upon code-related or QA-related changes.
- `.only:changes-code-backstage-qa`: Allows a job to only be created upon code-related, backstage-related (e.g. Danger, RuboCop, specs) or QA-related changes.

**See <https://gitlab.com/gitlab-org/gitlab/blob/master/.gitlab/ci/global.gitlab-ci.yml>
for the list of exact patterns.**

## Rules conditions and changes patterns

We're making use of the [`rules` keyword](https://docs.gitlab.com/ee/ci/yaml/#rules) but we're currently
duplicating the `if` conditions and `changes` patterns lists since they cannot be shared across
`include`d files as we do with `extends`.

**If you update an `if` condition or `changes`
patterns list, make sure to mass-update those across all the CI config files (i.e. `.gitlab/ci/*.yml`).**

### Canonical/security namespace merge requests only

This condition limits jobs creation to merge requests under the `gitlab-org/` top-level group
on GitLab.com only (i.e. this won't run for `master`, stable or auto-deploy branches).
This is similar to the `.only:variables-canonical-dot-com` + `only:refs: [merge_requests]`
CI definitions.

The definition for `if-canonical-dot-com-gitlab-org-groups-merge-request` can be
seen in <https://gitlab.com/gitlab-org/gitlab/-/blob/master/.gitlab/ci/docs.gitlab-ci.yml>.

### Canonical/security namespace tags only

This condition limits jobs creation to tags under the `gitlab-org/` top-level group
on GitLab.com only.
This is similar to the `.only:variables-canonical-dot-com` + `only:refs: [tags]` CI definition:

The definition for `if-canonical-dot-com-gitlab-org-groups-tag` can be seen in
<https://gitlab.com/gitlab-org/gitlab/-/blob/master/.gitlab/ci/cng.gitlab-ci.yml>.

### Canonical namespace `master` only

This condition limits jobs creation to `master` pipelines for the `gitlab-org` top-level group
on GitLab.com only.
This is similar to the `.only:variables-canonical-dot-com` + `only:refs: [master]` CI definition:

The definition for `if-canonical-dot-com-gitlab-org-group-master-refs` can be
seen in <https://gitlab.com/gitlab-org/gitlab/-/blob/master/.gitlab/ci/pages.gitlab-ci.yml>.

### Canonical namespace schedules only

This condition limits jobs creation to scheduled pipelines for the `gitlab-org` top-level group
on GitLab.com only.
This is similar to the `.only:variables-canonical-dot-com` + `only:refs: [schedules]` CI definition:

The definition for `if-canonical-dot-com-gitlab-org-group-schedule` can be seen
in <https://gitlab.com/gitlab-org/gitlab/-/blob/master/.gitlab/ci/qa.gitlab-ci.yml>.

### Not canonical/security namespace

This condition matches if the project isn't in the canonical/security namespace.
Useful to **not** create a job if the project is a fork, or in other words, when
a job should only run in the canonical projects.

The definition for `if-not-canonical-namespace` can be seen in
<https://gitlab.com/gitlab-org/gitlab/-/blob/master/.gitlab/ci/frontend.gitlab-ci.yml>.

### Not EE

This condition matches if the project isn't EE. Useful to **not** create a job if
the project is GitLab, or in other words, when a job should only run in the GitLab
FOSS project.

The definition for `if-not-ee` can be seen in
<https://gitlab.com/gitlab-org/gitlab/-/blob/master/.gitlab/ci/frontend.gitlab-ci.yml>.

### Default refs only

This condition is the equivalent of `.default-only`.

The definition for `if-default-refs` can be seen in
<https://gitlab.com/gitlab-org/gitlab/-/blob/master/.gitlab/ci/frontend.gitlab-ci.yml>.

### `master` refs only

This condition is the equivalent of `only:refs: [master]`.

The definition for `if-master-refs` can be seen in
<https://gitlab.com/gitlab-org/gitlab/-/blob/master/.gitlab/ci/frontend.gitlab-ci.yml>.

### Code changes patterns

Similar patterns as for `.only:changes-code`:

The definition for `code-patterns` can be seen in
<https://gitlab.com/gitlab-org/gitlab/-/blob/master/.gitlab/ci/qa.gitlab-ci.yml>.

### QA changes patterns

Similar patterns as for `.only:changes-qa`:

The definition for `qa-patterns` can be seen in
<https://gitlab.com/gitlab-org/gitlab/-/blob/master/.gitlab/ci/qa.gitlab-ci.yml>.

### Docs changes patterns

Similar patterns as for `.only:changes-docs`:

The definition for `docs-patterns` can be seen in
<https://gitlab.com/gitlab-org/gitlab/-/blob/master/.gitlab/ci/docs.gitlab-ci.yml>.

### Code and QA changes patterns

Similar patterns as for `.only:changes-code-qa`:

The definition for `code-qa-patterns` can be seen in
<https://gitlab.com/gitlab-org/gitlab/-/blob/master/.gitlab/ci/review.gitlab-ci.yml>.

### Code, backstage and QA changes patterns

Similar patterns as for `.only:changes-code-backstage-qa`:

The definition for `code-backstage-qa-patterns` can be seen in
<https://gitlab.com/gitlab-org/gitlab/-/blob/master/.gitlab/ci/frontend.gitlab-ci.yml>.

## Directed acyclic graph

We're using the [`needs:`](../ci/yaml/README.md#needs) keyword to
execute jobs out of order for the following jobs:

```mermaid
graph RL;
  A[setup-test-env];
  B["gitlab:assets:compile pull-push-cache<br/>(canonical master only)"];
  C["gitlab:assets:compile pull-cache<br/>(canonical default refs only)"];
  D["cache gems<br/>(master and tags only)"];
  E[review-build-cng];
  F[build-qa-image];
  G[review-deploy];
  G2["schedule:review-deploy<br/>(master only)"];
  I["karma, jest, webpack-dev-server, static-analysis"];
  I2["karma-foss, jest-foss<br/>(EE default refs only)"];
  J["compile-assets pull-push-cache<br/>(master only)"];
  J2["compile-assets pull-push-cache foss<br/>(EE master only)"];
  K[compile-assets pull-cache];
  K2["compile-assets pull-cache foss<br/>(EE default refs only)"];
  M[coverage];
  N["pages (master only)"];
  Q[package-and-qa];
  S["RSpec<br/>(e.g. rspec unit pg9)"]
  T[retrieve-tests-metadata];

subgraph "`prepare` stage"
    A
    B
    C
    F
    K
    K2
    J
    J2
    T
    end

subgraph "`test` stage"
    D -.-> |needs| A;
    I -.-> |needs and depends on| A;
    I -.-> |needs and depends on| K;
    I2 -.-> |needs and depends on| A;
    I2 -.-> |needs and depends on| K;
    L -.-> |needs and depends on| A;
    S -.-> |needs and depends on| A;
    S -.-> |needs and depends on| K;
    S -.-> |needs and depends on| T;
    L["db:*, gitlab:setup, graphql-docs-verify, downtime_check"] -.-> |needs| A;
    end

subgraph "`post-test` stage"
    M --> |happens after| S
    end

subgraph "`review-prepare` stage"
    E -.-> |needs| C;
    E2["schedule:review-build-cng<br/>(master schedule only)"] -.-> |needs| C;
    end

subgraph "`review` stage"
    G --> |happens after| E
    G2 --> |happens after| E2
    end

subgraph "`qa` stage"
    Q -.-> |needs| C;
    Q -.-> |needs| F;
    QA1["review-qa-smoke, review-qa-all, review-performance, dast"] -.-> |needs and depends on| G;
    QA2["schedule:review-performance<br/>(master only)"] -.-> |needs and depends on| G2;
    end

subgraph "`post-qa` stage"
  PQA1["parallel-spec-reports"] -.-> |depends on `review-qa-all`| QA1;
  end

subgraph "`pages` stage"
    N -.-> |depends on| C;
    N -.-> |depends on karma| I;
    N -.-> |depends on| M;
    N --> |happens after| PQA1
    end
```

## Test jobs

Consult [GitLab tests in the Continuous Integration (CI) context](testing_guide/ci.md)
for more information.

## Review app jobs

Consult the [Review Apps](testing_guide/review_apps.md) dedicated page for more information.

---

[Return to Development documentation](README.md)
