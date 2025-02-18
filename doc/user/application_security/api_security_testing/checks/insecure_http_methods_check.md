---
stage: Application Security Testing
group: Dynamic Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Insecure HTTP methods
---

## Description

Checks to see if HTTP methods like OPTIONS and TRACE are enabled on any target endpoints.

## Remediation

The resource tested supports the OPTIONS HTTP method. Normally this is considered a security miss configuration as it leaks supported HTTP methods leading to information gathering about a specific server or resource. However, there is a sub-set of the API community looking to use OPTIONS as a method to self discover resource operations. If this is the intended use for enabling OPTIONS, than this issue can be considered a false positive.

The resource tested supports the TRACE HTTP method. In combination with other cross-domain vulnerabilities in web browsers, sensitive information can be leaked from headers. It's recommended the TRACE method be disabled in your server/framework.

## Links

- [OWASP](https://owasp.org/Top10/A05_2021-Security_Misconfiguration/)
- [CWE](https://cwe.mitre.org/data/definitions/200.html)
