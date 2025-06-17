---
stage: Verify
group: Pipeline Authoring
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/development/development_processes/#development-guidelines-review.
title: Testing guide for CI/CD Rails application code
---

This document contains details for testing CI/CD application code.

## Backend

### Integration specs

The CI/CD specs include informal integration specs for the core CI/CD processes.

#### Linting

Integration specs for linting are kept in `spec/lib/gitlab/ci/yaml_processor_spec.rb` and
`spec/lib/gitlab/ci/yaml_processor/test_cases/`. Add any new specs to the
`test_cases/` directory.

#### Pipeline creation

Integration specs for pipeline creation are kept in `spec/services/ci/create_pipeline_service_spec.rb` and
`spec/services/ci/create_pipeline_service/`. Add new specs to the
`create_pipeline_service/` directory.

#### Pipeline processing

`spec/services/ci/pipeline_processing/atomic_processing_service_spec.rb` runs integration specs for pipeline processing.
To add a new integration spec, add a YAML CI/CD configuration file to `spec/services/ci/pipeline_processing/test_cases`.
It is run automatically with `atomic_processing_service_spec.rb`.

## Frontend

### Fixtures

The following files contain frontend fixtures for CI/CD endpoints used in frontend unit tests:

- `spec/frontend/fixtures/pipelines.rb` - General pipeline fixtures
- `spec/frontend/fixtures/pipeline_create.rb` - Pipeline creation fixtures
- `spec/frontend/fixtures/pipeline_details.rb` - Pipeline details fixtures
- `spec/frontend/fixtures/pipeline_header.rb` - Pipeline header fixtures
- `spec/frontend/fixtures/pipeline_schedules.rb` - Pipeline schedule fixtures

These fixtures provide mock API responses for consistent testing of CI/CD frontend components.

### Unit tests

Frontend unit tests for CI/CD components are located in spec/frontend/ci. These tests verify proper rendering, interactions, and state management for pipeline visualization, job execution, scheduling, and status reporting components.
