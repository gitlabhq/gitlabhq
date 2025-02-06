---
stage: Application Security Testing
group: Dynamic Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Cleartext authentication
---

## Description

This check looks for cleartext authentication such as HTTP Basic auth with no-TLS.

## Remediation

Authentication credentials are transported via unencrypted channel (HTTP). This exposes the transmitted credentials to any attacker who can monitor (sniff) the network traffic during transmission. Sensitive information such as credentials should always be transmitted via encrypted channels such as HTTPS.

## Links

- [OWASP](https://owasp.org/Top10/A02_2021-Cryptographic_Failures/)
- [CWE](https://cwe.mitre.org/data/definitions/319.html)
