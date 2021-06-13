---
stage: none
group: unassigned
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
type: reference, howto
---

# Project import decompressed archive size limits **(FREE SELF)**

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/31564) in GitLab 13.2.
> - [Enabled by default](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/63025) in GitLab 14.0.

When using [Project Import](../user/project/settings/import_export.md), the size of the decompressed project archive is limited to 10Gb.

If decompressed size exceeds this limit, `Decompressed archive size validation failed` error is returned.

## Enable/disable size validation

If you have a project with decompressed size exceeding this limit,
it is possible to disable the validation by turning off the
`validate_import_decompressed_archive_size` feature flag.

Start a [Rails console](../administration/operations/rails_console.md#starting-a-rails-console-session).

```ruby
# Disable
Feature.disable(:validate_import_decompressed_archive_size)

# Enable
Feature.enable(:validate_import_decompressed_archive_size)
```
