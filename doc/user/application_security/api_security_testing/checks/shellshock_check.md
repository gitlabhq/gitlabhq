---
stage: Application Security Testing
group: Dynamic Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Shellshock
---

## Description

Check for Shellshock vulnerabilities.

## Remediation

Shellshock vulnerability takes advantage of a bug in BASH, in which, BASH incorrectly executes trailing commands when it imports a function definition stored into an environment variable. Any environment which allows defining BASH environmental variables could be vulnerable to this bug, as for example a Apache Web Server using mod_cgi and mod_cgid modules. A known-good request was modified to include malicious content. The malicious content includes an Shell shock attack in which the server-side application returns a specific text (evidence) in the response headers.

## Links

- [OWASP](https://owasp.org/Top10/A03_2021-Injection/)
- [CWE](https://cwe.mitre.org/data/definitions/78.html)
