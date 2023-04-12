---
stage: Secure
group: Incubation
info: Breach and Attack Simulation is a GitLab Incubation Engineering program. No technical writer assigned to this group.
type: reference, howto
---

# Breach and Attack Simulation **(ULTIMATE)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/402784) in GitLab 15.11.

DISCLAIMER:
Breach and Attack Simulation is a set of experimental features being developed by the Incubation Engineering Department and is subject to significant changes over time.

Breach and Attack Simulation (BAS) uses additional security testing techniques to assess the risk of detected vulnerabilities and prioritize the remediation of exploitable vulnerabilities.

For feedback, bug reports, and feature requests, see the [feedback issue](https://gitlab.com/gitlab-org/gitlab/-/issues/404809).

WARNING:
Only run BAS scans against test servers. Testing attacker behavior can lead to modification or loss of data.

## Extend Dynamic Application Security Testing (DAST)

You can simulate attacks with [DAST](../dast/index.md) to detect vulnerabilities.
By default, DAST active checks match an expected response, or determine by response
time whether a vulnerability was exploited.

Enable the BAS feature flag in DAST to:

- Enable callback, match response, and timing attacks inside of active checks.
- Perform Out-of-Band Application Security Testing (OAST) through callback attacks in active checks.

To enable BAS:

1. Create a CI/CD job using the [DAST browser-based analyzer](../dast/browser_based.md#create-a-dast-cicd-job).
1. Set the `DAST_FF_ENABLE_BAS` [CI/CD variable](../dast/browser_based.md#available-cicd-variables) to `true`.

```yaml
include:
  - template: DAST.gitlab-ci.yml

dast:
  variables:
    DAST_BROWSER_SCAN: "true"
    DAST_FF_ENABLE_BAS: "true"
    DAST_WEBSITE: "https://my.site.com"
```
