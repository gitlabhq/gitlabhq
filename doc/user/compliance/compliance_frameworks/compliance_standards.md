---
stage: Software Supply Chain Security
group: Compliance
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Compliance standards
---

You can use [GitLab compliance controls](_index.md#gitlab-compliance-controls) to help meet the requirements of many
compliance standards.

## ISO 27001 compliance requirements

ISO 27001 is an internationally recognized standard that provides a framework for implementing and managing an
Information Security Management System (ISMS).

The following table lists the requirements supported by GitLab for ISO 27001 and the controls for the requirements.

| ISO 27001 requirement                               | Description                                                                                                                                                                                                  | Supported controls |
|:----------------------------------------------------|:-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|:-------------------|
| 5.3 Segregation of duties                           | Conflicting duties and conflicting areas of responsibility shall be segregated.                                              | <ul><li>At least two approvals</li><li>Author approved merge request is forbidden</li><li>Committers approved merge request is forbidden</li><li>Merge requests approval rules prevent editing</li></ul> |
| 5.17 Authentication information                     | Allocation and management of authentication information should be controlled by a management process, including advising personnel on the appropriate handling of authentication information.                | <ul><li>Secret detection running</li></ul> |
| 5.18 Access rights                                  | Access rights to information and other associated assets should be provisioned, reviewed, modified, and removed in accordance with the organization's topic-specific policy on and rules for access control. | <ul><li>At least two approvals</li><li>Author approved merge request is forbidden</li><li>Committers approved merge request is forbidden</li><li>Merge requests approval rules prevent editing</li></ul> |
| 5.32 Intellectual property rights                   | The organization should implement appropriate procedures to protect intellectual property rights.                                                                                                            | <ul><li>License compliance running</li></ul> |
| 8.4 Access to source code                           | Read and write access to source code, development tools and software libraries shall be appropriately managed.                                                                                               | <ul><li>Default branch protected</li></ul> |
| 8.8 Management of technical vulnerabilities         | Information about technical vulnerabilities of information systems in use shall be obtained, the organization's exposure to such vulnerabilities shall be evaluated and appropriate measures shall be taken. | <ul><li>Dependency scanning running</li><li>Container scanning running</li><li>SAST running</li><li>DAST running</li><li>API security running</li><li>Fuzz testing running</li></ul> |
| 8.28 Secure coding                                  | Secure coding principles shall be applied to software development.                                                                                                                                           | <ul><li>Dependency scanning running</li><li>Container scanning running</li><li>SAST running</li><li>DAST running</li><li>API security running</li><li>Secret detection running</li><li>Fuzz testing running</li></ul> |
| 8.29 Security testing in development and acceptance | Security testing processes shall be defined and implemented in the development lifecycle.                                                                                                                    | <ul><li>Dependency scanning running</li><li>Container scanning running</li><li>SAST running</li><li>DAST running</li><li>API security running</li><li>Secret detection running</li><li>Fuzz testing running</li></ul> |
| 8.32 Change management                              | Changes to information processing facilities and information systems shall be subject to change management procedures.                                                                                       | <ul><li>Default branch protected</li></ul> |
