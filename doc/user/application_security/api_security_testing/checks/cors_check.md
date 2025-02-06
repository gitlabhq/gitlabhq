---
stage: Application Security Testing
group: Dynamic Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: CORS
---

## Description

Check for CORS misconfiguration including overly permissive white-lists of accepted Origin headers or failure to validate Origin header. Also checks for allowing credentials on potentially invalid or dangerous Origins and missing headers that could potentially result in cache poisoning.

## Remediation

A misconfigured CORS implementation may be overly permissive in which domains should be trusted and at what level of trust. This could allow an untrusted domain to forge the Origin header and launch various types of attacks such as cross-site request forgery or cross-site scripting. An attacker could potentially steal a victim's credentials or send malicious requests on behalf of a victim. The victim may not even be aware that an attack is being launched.

## Links

- [OWASP](https://owasp.org/Top10/A01_2021-Broken_Access_Control/)
- [CWE](https://cwe.mitre.org/data/definitions/942.html)
