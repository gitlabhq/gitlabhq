---
stage: Secure
group: Dynamic Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: API Security
---

DETAILS:
**Tier:** Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

API Security refers to the measures taken to secure and protect web Application Programming Interfaces (APIs) from unauthorized access, misuse, and attacks.
APIs are a crucial component of modern application development as they allow applications to interact with each other and exchange data.
However, this also makes them attractive to attackers and vulnerable to security threats if not properly secured.
In this section, we discuss GitLab features that can be used to ensure the security of web APIs in your application.
Some of the features discussed are specific to web APIs and others are more general solutions that are also used with web API applications.

- [SAST](../sast/_index.md) identified vulnerabilities by analyzing the application's codebase.
- [Dependency Scanning](../dependency_scanning/_index.md) reviews a project 3rd party dependencies for known vulnerabilities (for example CVEs).
- [Container Scanning](../container_scanning/_index.md) analyzes container images to identify known OS package vulnerabilities and installed language dependencies.
- [API Discovery](api_discovery/_index.md) examines an application containing a REST API and intuits an OpenAPI specification for that API. OpenAPI specification documents are used by other GitLab security tools.
- [API security testing analyzer](../api_security_testing/_index.md) performs dynamic analysis security testing of web APIs. It can identify various security vulnerabilities in your application, including the OWASP Top 10.
- [API Fuzzing](../api_fuzzing/_index.md) performs fuzz testing of a web API. Fuzz testing looks for issues in an application that are not previously known and don't map to classic vulnerability types such as SQL Injection.
