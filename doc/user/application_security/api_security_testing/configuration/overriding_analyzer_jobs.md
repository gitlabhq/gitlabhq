---
stage: Application Security Testing
group: Dynamic Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
type: reference, howto
title: Overriding API security testing jobs
---

To override a job definition, (for example, change properties like `variables`, `dependencies`, or [`rules`](../../../../ci/yaml/_index.md#rules)),
declare a job with the same name as the DAST job to override. Place this new job after the template
inclusion and specify any additional keys under it. For example, this sets the target APIs base URL:

```yaml
include:
  - template: Security/API-Security.gitlab-ci.yml

api_security:
  variables:
    APISEC_TARGET_URL: https://target/api
```
