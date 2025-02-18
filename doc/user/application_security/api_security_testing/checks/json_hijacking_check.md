---
stage: Application Security Testing
group: Dynamic Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: JSON hijacking
---

## Description

Checks for JSON data potentially vulnerable to hijacking. This check looks for a GET request that returns a JSON array, which could potentially be hijacked and read by a malicious website.

## Remediation

JSON hijacking allows an attacker to send a GET request via a malicious web site or similar attack vector and utilize a user's stored credentials to retrieve sensitive or protected data to which that user has access. Since a JSON array on its own is valid JavaScript, a malicious GET request to a resource that returns only a JavaScript array can allow the attacker to use a malicious script to read the data in the array from the request. GET requests should never return a JSON array, even if the resource requires authentication to access. Consider using POST instead of a GET for this request or wrapping the array in a JSON object.

## Links

- [OWASP](https://owasp.org/Top10/A01_2021-Broken_Access_Control/)
- [CWE](https://cwe.mitre.org/data/definitions/352.html)
