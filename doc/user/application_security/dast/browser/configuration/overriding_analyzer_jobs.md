---
stage: Application Security Testing
group: Dynamic Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
type: reference, howto
title: Overriding DAST jobs
---

To override a job definition, (for example, change properties like `variables`, `dependencies`, or [`rules`](../../../../../ci/yaml/_index.md#rules)),
declare a job with the same name as the DAST job to override. Place this new job after the template
inclusion and specify any additional keys under it. For example, this enables authentication debug logging for the analyzer:

```yaml
include:
  - template: Security/DAST.gitlab-ci.yml

dast:
  variables:
    DAST_LOG_CONFIG: auth:debug
```
