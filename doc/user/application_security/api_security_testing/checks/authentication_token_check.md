---
stage: Application Security Testing
group: Dynamic Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Authentication token
---

## Description

Perform various authentication token checks such as removing the token or changing to an invalid value.

## Remediation

API tokens must be unpredictable (random enough) to prevent guessing attacks, where an attacker is able to guess or predict a valid API Token through statistical analysis techniques. For this purpose, a good PRNG (Pseudo Random Number Generator) must be used.

The authentication token may have been:

- modified to an invalid value.
- removed from request.
- not match length requirements.
- configured as a signature.

An API operation failed to property restrict access using an authentication token. This allows an attacker to bypass authentication gaining access to information or even the ability to modify data.

## Links

- [OWASP](https://owasp.org/Top10/A07_2021-Identification_and_Authentication_Failures/)
- [CWE](https://cwe.mitre.org/data/definitions/285.html)
