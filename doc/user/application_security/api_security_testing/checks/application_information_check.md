---
stage: Application Security Testing
group: Dynamic Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Application information disclosure
---

## Description

Application information disclosure check. This includes information such as version numbers, database error messages, stack traces.

## Remediation

Application information disclosure is an application weakness where an application reveals sensitive data, such as technical details of the web application or environment. Application data may be used by an attacker to exploit the target web application, its hosting network, or its users. Therefore, leakage of sensitive data should be limited or prevented whenever possible. Information disclosure, in its most common form, is the result of one or more of the following conditions: a failure to scrub out HTML or script comments containing sensitive information or improper application or server configurations.

Failure to scrub HTML or script comments prior to a push to the production environment can result in the leak of sensitive, contextual, information such as server directory structure, SQL query structure, and internal network information. Often a developer will leave comments within the HTML and script code to help facilitate the debugging or integration process during the pre-production phase. Although there is no harm in allowing developers to include inline comments within the content they develop, these comments should all be removed prior to the content's public release.

Software version numbers and verbose error messages (such as ASP.NET version numbers) are examples of improper server configurations. This information is useful to an attacker by providing detailed insight as to the framework, languages, or pre-built functions being utilized by a web application. Most default server configurations provide software version numbers and verbose error messages for debugging and troubleshooting purposes. Configuration changes can be made to disable these features, preventing the display of this information.

## Links

- [OWASP](https://owasp.org/Top10/A05_2021-Security_Misconfiguration/)
- [CWE](https://cwe.mitre.org/data/definitions/200.html)
