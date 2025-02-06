---
stage: Application Security Testing
group: Dynamic Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: OS command injection
---

## Description

Check for OS command injection vulnerabilities. An OS command injection attack consists of insertion or "injection" of an OS command via the input data from the client to the application.
A successful OS command injection exploit can run arbitrary commands. This allows an attacker the ability to read, write, and delete data. Depending on the user the commands run as, this can also include administrative functions.

This check modifies parameters in the request (path, query string, headers, JSON, XML, etc.) to try and execute an OS command. Both standard injections and blind injections are performed. Blind injections cause delays in response when successful.

## Remediation

It is possible to execute arbitrary OS commands on the target application server. OS Command Injection is a critical vulnerability that can lead to a full system compromise. User input should never be used in constructing commands or command arguments to functions which execute OS commands. This includes filenames supplied by user uploads or downloads.

Ensure your application does not:

- Use user supplied information in the process name to execute.
- Use user supplied information in an OS command execution function which does
  not escape shell meta-characters.
- Use user supplied information in arguments to OS commands.

The application should have a hardcoded set of arguments that are to be passed to OS commands. If filenames are being passed to these functions, it is recommended that a hash of the filename be used instead, or some other unique identifier. It is strongly recommended that a native library that implements the same functionality be used instead of using OS system commands due to the risk of unknown attacks against third party commands.

## Links

- [OWASP](https://owasp.org/Top10/A03_2021-Injection/)
- [CWE](https://cwe.mitre.org/data/definitions/78.html)
