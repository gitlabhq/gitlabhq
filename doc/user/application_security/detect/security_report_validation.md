---
stage: Application Security Testing
group: Static Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Security report validation
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Security reports are validated before their content is added to the database. This prevents
ingestion of broken vulnerability data into the database. Reports that fail validation are listed in
the pipeline's **Security** tab with the validation error message.

Validation is done against the
[report schemas](https://gitlab.com/gitlab-org/security-products/security-report-schemas/-/tree/master/dist),
according to the schema version declared in the report:

- If the security report specifies a supported schema version, GitLab uses this version to validate.
- If the security report uses a deprecated version, GitLab attempts validation against that version
  and adds a deprecation warning to the validation result.
- If the security report uses a supported MAJOR-MINOR version of the report schema but the PATCH
  version doesn't match any vendored versions, GitLab attempts to validate it against latest
  vendored PATCH version of the schema.
  - Example: security report uses version 14.1.1 but the latest vendored version is 14.1.0. GitLab
    would validate against schema version 14.1.0.
- If the security report uses a version that is not supported, GitLab attempts to validate it
  against the earliest schema version available in your installation but doesn't ingest the report.
- If the security report does not specify a schema version, GitLab attempts to validate it against
  the earliest schema version available in GitLab. Because the `version` property is required,
  validation always fails in this case, but other validation errors may also be present.

For details of the supported and deprecated schema versions, view the
[schema validator source code](https://gitlab.com/gitlab-org/gitlab/blob/master/lib/gitlab/ci/parsers/security/validators/schema_validator.rb).
