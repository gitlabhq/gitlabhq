---
stage: Verify
group: Continuous Integration
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#designated-technical-writers
type: reference
---

# Deprecated GitLab CI/CD variables

Read through this document to learn what predefined variables
were deprecated and their new references.

## GitLab 9.0 renamed variables

To follow conventions of naming across GitLab, and to further move away from the
`build` term and toward `job`, some [CI/CD environment variables](README.md#predefined-environment-variables) were renamed for GitLab 9.0
release.

NOTE: **Note:**
Starting with GitLab 9.0, we have deprecated the `$CI_BUILD_*` variables. **You are
strongly advised to use the new variables as we will remove the old ones in
future GitLab releases.**

| 8.x name              | 9.0+ name               |
| --------------------- |------------------------ |
| `CI_BUILD_BEFORE_SHA` | `CI_COMMIT_BEFORE_SHA`  |
| `CI_BUILD_ID`         | `CI_JOB_ID`             |
| `CI_BUILD_MANUAL`     | `CI_JOB_MANUAL`         |
| `CI_BUILD_NAME`       | `CI_JOB_NAME`           |
| `CI_BUILD_REF`        | `CI_COMMIT_SHA`         |
| `CI_BUILD_REF_NAME`   | `CI_COMMIT_REF_NAME`    |
| `CI_BUILD_REF_SLUG`   | `CI_COMMIT_REF_SLUG`    |
| `CI_BUILD_REPO`       | `CI_REPOSITORY_URL`     |
| `CI_BUILD_STAGE`      | `CI_JOB_STAGE`          |
| `CI_BUILD_TAG`        | `CI_COMMIT_TAG`         |
| `CI_BUILD_TOKEN`      | `CI_JOB_TOKEN`          |
| `CI_BUILD_TRIGGERED`  | `CI_PIPELINE_TRIGGERED` |
