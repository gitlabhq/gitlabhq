---
stage: Application Security Testing
group: Dynamic Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Sensitive file disclosure
---

## Description

Check for sensitive file disclosure. This check looks for files that may contain sensitive information. Examples include .htaccess, .htpasswd, .bash_history, etc.

## Remediation

Information leakage is an application weakness where an application reveals sensitive data, such as technical details of the web application, environment, or user-specific data. Sensitive data may be used by an attacker to exploit the target web application, its hosting network, or its users. Therefore, leakage of sensitive data should be limited or prevented whenever possible. Information Leakage, in its most common form,is the result of one or more of the following conditions: A failure to scrub out HTML/Script comments containing sensitive information, improper application or server configurations, or differences in page responses for valid versus invalid data.

In the case of this failure, one or more files and/or folders are accessible that should not be. This can include files common in home folders like such as command histories or files that contain secrets such as passwords.

## Links

- [OWASP](https://owasp.org/Top10/A01_2021-Broken_Access_Control/)
- [CWE](https://cwe.mitre.org/data/definitions/200.html)
