---
stage: Application Security Testing
group: Dynamic Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Sensitive information disclosure
---

## Description

Sensitive information disclosure check. This includes credit card numbers, health records, personal information, etc.

## Remediation

Sensitive information leakage is an application weakness where an application
reveals sensitive, user-specific data. Sensitive data may be used by an attacker
to exploit its users. Therefore, leakage of sensitive data should be limited or
prevented whenever possible. Information Leakage, in its most common form,
is the result of differences in page responses for valid versus invalid data.

Pages that provide different responses based on the validity of the data can
also lead to Information Leakage; specifically when data deemed confidential is
being revealed as a result of the web application's design. Examples of
sensitive data includes (but is not limited to): account numbers, user
identifiers (Drivers license number, Passport number, Social Security Numbers,
etc.) and user-specific information (passwords, sessions, addresses).
Information Leakage in this context deals with exposure of key user data deemed
confidential, or secret, that should not be exposed in plain view, even to the
user. Credit card numbers and other heavily regulated information are prime
examples of user data that needs to be further protected from exposure or
leakage even with proper encryption and access controls already in place.

## Links

- [OWASP](https://owasp.org/Top10/A01_2021-Broken_Access_Control/)
- [CWE](https://cwe.mitre.org/data/definitions/200.html)
