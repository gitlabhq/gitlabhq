---
stage: none
group: Engineering Productivity
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/development/development_processes/#development-guidelines-review.
title: Code coverage
---

Coverage data powers, among others, [predictive test selection](_index.md#predictive-test-jobs-before-a-merge-request-is-approved), coverage analytics dashboards, and flaky test analysis.

## Data collection

Coverage is collected from multiple test suites using different tools.

### Backend coverage (RSpec)

RSpec tests collect coverage using [SimpleCov](https://github.com/simplecov-ruby/simplecov), configured in [`spec/simplecov_env.rb`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/spec/simplecov_env.rb).

- **Output**: `coverage/lcov/gitlab.lcov` (LCOV format)
- **Test mappings**: [Crystalball](https://gitlab.com/gitlab-org/ruby/gems/crystalball) generates `crystalball/packed-mapping.json.gz` containing source file to test file mappings

### Frontend coverage (Jest)

Jest tests collect coverage using [Istanbul](https://istanbul.js.org/), configured in [`jest.config.base.js`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/jest.config.base.js).

- **Output**: `coverage-frontend/*/coverage-final.json` (Istanbul JSON format)
- **Test mappings**: `jest-test-mapping/jest-source-to-test.json`

### Workhorse coverage (Go)

Workhorse tests collect coverage using Go's built-in coverage tooling.

- **Output**: `workhorse/coverage.lcov` (converted to LCOV format)
- **Test mappings**: `workhorse-source-to-test.json`

### E2E coverage

E2E tests collect coverage from a running GitLab instance.

#### Backend E2E (Coverband)

The [`coverband_formatter.rb`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/qa/qa/support/formatters/coverband_formatter.rb) collects backend coverage by calling the GitLab coverage API before and after each test.

- **Output**: `tmp/coverband-coverage-*.json` and `tmp/test-code-paths-mapping-*.json`
- **API endpoints**: Coverage data is collected via `/-/coverband/coverage_data` API

#### Frontend E2E (Istanbul)

Frontend E2E coverage is collected via Istanbul instrumentation of the running GitLab instance.

- **Output**: `coverage-e2e-frontend/coverage-final.json` and `js-coverage-by-example-*.json`

## Data merging

After tests complete, coverage from parallel jobs and E2E tests is merged.

### Backend merge

The [`merge_backend_coverage.rb`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/scripts/coverage/merge_backend_coverage.rb) script merges:

- RSpec coverage from `coverage/lcov/gitlab.lcov`
- E2E Coverband coverage from `coverage-e2e-backend/coverband-*.json`

Output: `coverage-backend/coverage.lcov`

### Backend test mapping merge

The [`merge_e2e_backend_test_mapping.rb`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/scripts/coverage/merge_e2e_backend_test_mapping.rb) script merges:

- Crystalball mappings from `crystalball/packed-mapping.json.gz` (includes both `DescribedClassStrategy` and `CoverageStrategy` mappings)
- E2E test mappings from `e2e-test-mapping/test-code-paths-mapping-*.json`

Output: `crystalball/merged-mapping.json.gz`

File paths are normalized during merge to ensure consistent relative paths (for example, `/builds/gitlab-org/gitlab/app/models/user.rb` becomes `app/models/user.rb`).

### Frontend merge

The [`merge_coverage_frontend.js`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/scripts/frontend/merge_coverage_frontend.js) script merges:

- Jest coverage from `coverage-frontend/*/coverage-final.json`
- E2E Istanbul coverage from `coverage-e2e-frontend/coverage-final.json`

Output: `coverage-frontend/lcov.info` and Cobertura XML

### Frontend test mapping merge

The [`merge_e2e_frontend_test_mapping.js`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/scripts/frontend/merge_e2e_frontend_test_mapping.js) script merges Jest and E2E test mappings.

Output: `jest-test-mapping/merged-source-to-test.json`

## Data enrichment

Before export to ClickHouse, coverage data is enriched with metadata.

### Source file classification

Source files are classified by type based on file path patterns:

- `frontend` - JavaScript/Vue/CSS files
- `backend` - Ruby files (models, controllers, services, etc.)
- `database` - Migrations and schema files
- `infrastructure` - CI configuration, Dockerfiles
- `qa` - QA test files
- `workhorse` - Go files
- `tooling` - Tooling and RuboCop files
- `configuration` - Config files
- `other` - Files not matching any pattern

See the [`SourceFileClassifier`](https://gitlab.com/gitlab-org/ruby/gems/gitlab_quality-test_tooling/-/blob/main/lib/gitlab_quality/test_tooling/code_coverage/source_file_classifier.rb) for the full pattern definitions.

### Test responsibility classification

Tests are classified as either:

- **Responsible**: Tests that directly test a source file (for example, `spec/models/user_spec.rb` for `app/models/user.rb`)
- **Dependent**: Tests that indirectly cover a source file

Classification uses patterns defined in [`.gitlab/coverage/responsibility_patterns.yml`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/.gitlab/coverage/responsibility_patterns.yml).

### Feature category attribution

Each source file is attributed to one or more feature categories based on test metadata. This enables per-team coverage tracking.

For files covered by tests with multiple feature categories, multiple coverage records are created (one per category).

### Organization data lookup

Feature categories are enriched with organization hierarchy (group, stage, section) from the `category_owners` reference table.

## Data storage (ClickHouse)

Coverage data is exported to ClickHouse for analytics and dashboards.

### Tables

| Table | Database | Description |
|-------|----------|-------------|
| `coverage_metrics` | `code_coverage` | Per-file coverage percentages with organization data |
| `test_file_mappings` | `shared` | Source file to test file relationships |
| `category_owners` | `shared` | Feature category to organization hierarchy mapping |

### Export jobs

Coverage is exported by the [`gitlab_quality-test_tooling`](https://gitlab.com/gitlab-org/ruby/gems/gitlab_quality-test_tooling) gem:

- `test-coverage:export-rspec-and-e2e` - Backend coverage
- `test-coverage:export-jest-and-e2e` - Frontend coverage
- `test-coverage:export-workhorse` - Workhorse coverage

For implementation details, see the [gem's code coverage README](https://gitlab.com/gitlab-org/ruby/gems/gitlab_quality-test_tooling/-/blob/main/lib/gitlab_quality/test_tooling/code_coverage/README.md).

## Troubleshooting

### Missing coverage data

If coverage export fails, check:

1. **Missing artifacts**: Ensure prerequisite jobs completed successfully and artifacts exist
1. **Invalid JSON**: Test reports or coverage files may contain malformed JSON

### Path normalization issues

E2E coverage may contain absolute paths. The merge scripts normalize paths, but if you see path mismatches:

1. Check that paths start from the repository root (for example, `app/models/user.rb`)
1. Paths should not have `./` prefix or absolute paths like `/builds/gitlab-org/gitlab/`

### NaN coverage values

Coverage percentages may be `NaN` if a file has zero lines to cover. These records are filtered out during export.

## Related topics

- [Predictive test selection](_index.md#predictive-test-jobs-before-a-merge-request-is-approved)
- [Code coverage user documentation](../../ci/testing/code_coverage/_index.md)
- [`gitlab_quality-test_tooling` gem](https://gitlab.com/gitlab-org/ruby/gems/gitlab_quality-test_tooling)
