---
stage: Application Security Testing
group: Dynamic Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: SQL injection
---

## Description

Check for SQL and NoSQL injection vulnerabilities. A SQL injection attack
consists of insertion or "injection" of a SQL query via the input data from the
client to the application. A successful SQL injection exploit can read sensitive
data from the database, modify database data (Insert/Update/Delete), execute
administration operations on the database (such as shutdown the DBMS), recover
the content of a given file present on the DBMS file system and in some cases
issue commands to the operating system. SQL injection attacks are a type of
injection attack, in which SQL commands are injected into data-plane input in
order to effect the execution of predefined SQL commands. This check modifies
parameters in the request (path, query string, headers, JSON, XML, etc.) to try
and create a syntax error in the SQL or NoSQL query. Logs and responses are then
analyzed to try and detect if an error occurred. If an error is detected there is
a high likelihood that a vulnerability exists.

## Remediation

The software constructs all or part of an SQL command using
externally-influenced input from an upstream component, but it does not
neutralize or incorrectly neutralizes special elements that could modify the
intended SQL command when it is sent to a downstream component.

Without sufficient removal or quoting of SQL syntax in user-controllable inputs,
the generated SQL query can cause those inputs to be interpreted as SQL instead
of ordinary user data. This can be used to alter query logic to bypass security
checks, or to insert additional statements that modify the back-end database,
possibly including execution of system commands.

SQL injection has become a common issue with database-driven websites. The flaw
is easily detected, and easily exploited, and as such, any site or software
package with even a minimal user base is likely to be subject to an attempted
attack of this kind. This flaw depends on the fact that SQL makes no real
distinction between the control and data planes.

## Links

- [OWASP](https://owasp.org/Top10/A03_2021-Injection/)
- [CWE](https://cwe.mitre.org/data/definitions/930.html)
