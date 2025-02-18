---
stage: Application Security Testing
group: Dynamic Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: DNS rebinding
---

## Description

Check for DNS rebinding. This check verifies that the host checks that the HOST header of the request exists and matches the expected name of the host to avoid attacks via malicious DNS entries.

## Remediation

DNS rebinding allows a malicious host to spoof or redirect a request to an alternate IP address, potentially allowing an attacker to bypass security authentication or authorization. DNS resolution on its own does not properly constitute a valid authentication mechanism. Servers should validate that the Host header of the request matches the expected hostname of the server. In cases where the hostname is missing or does not match the expected value, the server should return a 400. The X-Forwarded-Host header is sometimes used instead of the Host header in cases where the request is being forwarded. In these cases, the X-Forwarded-Host header should also be validated if it is being used to determine the Host of the original request.

## Links

- [OWASP](https://owasp.org/Top10/A05_2021-Security_Misconfiguration/)
- [CWE](https://cwe.mitre.org/data/definitions/350.html)
