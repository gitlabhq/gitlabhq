---
stage: Application Security Testing
group: Dynamic Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Heartbleed OpenSSL vulnerability
---

## Description

Check for Heartbleed OpenSSL vulnerability.

## Remediation

The Heartbleed vulnerability is a serious bug in the popular OpenSSL cryptographic library. OpenSSL is used to encrypt and decrypt communications and secure the Internet traffic. This vulnerability allows the attacker to steal protected information, which should not be accessible under other circumstance such as secret keys that are used to encrypt sensitive information.

Anyone on with access to the target API can use the Heartbleed vulnerability to read the memory from protected systems taking advantage of vulnerable versions of OpenSSL library.

## Links

- [OWASP](https://owasp.org/Top10/A06_2021-Vulnerable_and_Outdated_Components/)
- [CWE](https://cwe.mitre.org/data/definitions/119.html)
