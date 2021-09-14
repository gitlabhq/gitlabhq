---
stage: none
group: none
info: "See the Technical Writers assigned to Development Guidelines: https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments-to-development-guidelines"
---

# Deprecated feature removal schedule

<!--
This page is automatically generated from the YAML files in `/data/deprecations` by the rake task
located at `lib/tasks/gitlab/docs/compile_deprecations.rake`.

Do not edit this page directly.

To add a deprecation, use the example.yml file in `/data/deprecations/templates` as a template,
then run `bin/rake gitlab:docs:compile_deprecations`.
-->

## 15.0

### Audit events for repository push events

Audit events for [repository events](../administration/audit_events.md#repository-push) are now deprecated and will be removed in GitLab 15.0.

These events have always been disabled by default and had to be manually enabled with a
feature flag. Enabling them can cause too many events to be generated which can
dramatically slow down GitLab instances. For this reason, they are being removed.
