---
stage: Solutions Architecture
group: Solutions Architecture
info: This page is owned by the Solutions Architecture team.
title: Rust Language and Ecosystem Solutions Index
---

Learn how to GitLab supports the Rust ecosystem.

Unless otherwise noted, all of this content applies to both GitLab.com and self-managed instances.

This page attempts to index the ways in which GitLab supports Rust. It does so whether the integration is the result of configuring general functionality, was built in to Rust or GitLab or is provided as a solution.

| Text Tag                 | Configuration / Built / Solution                             | Support/Maintenance                                          |
| ------------------------ | ------------------------------------------------------------ | ------------------------------------------------------------ |
| `[Rust Configuration]`    | Integration accomplished by Configuring Existing Rust Functionality       | Rust                                                          |
| `[GitLab Configuration]` | Integration accomplished by Configuring Existing GitLab Functionality    | GitLab                                                       |
| `[Rust Partner Built]`         | Built into GitLab by Product Team to Address Rust Integration | GitLab                                                       |
| `[Rust Partner Solution]`         | Built as Solution Example by Rust or Rust Partners             | Community/Example                                            |
| `[GitLab Solution]`      | Built as Solution Example by GitLab or GitLab Partners       | Community/Example                                            |
| `[CI Solution]`          | Built using GitLab CI and therefore <br />more customer customizable. | Items tagged `[CI Solution]` will <br />also carry one of the other tags <br />that indicate the maintenance status. |

## Rust SCM

- [GitLab Duo Code Suggestions](../../../user/project/repository/code_suggestions/supported_extensions.md#supported-languages) `[GitLab Built]`

## Rust CI

- [Unit Testing Results](../../../ci/testing/unit_test_report_examples.md#rust) `[GitLab Built]`
- [GitLab CICD Rust Component](https://gitlab.com/explore/catalog/components/rust) `[GitLab Built]`
  - [Using Rust Component](../../../ci/components/examples.md#example-test-a-rust-language-cicd-component) `[GitLab Built]`

## Rust CD

- GitLab Package Registry Support for Cargo - [Open for Contributions](https://gitlab.com/gitlab-org/gitlab/-/issues/33060)
- [GitLab CICD Rust Component (Currently in Prerelease)](https://gitlab.com/explore/catalog/components/rust) `[GitLab Built]`
  - [How To Use the Rust Component](../../../ci/components/examples.md#example-test-a-rust-language-cicd-component) `[GitLab Built]`

## Rust Security and SBOM

- [Testing Code Coverage](../../../ci/testing/code_coverage/_index.md#coverage-regex-patterns) `[GitLab Built]`
- [GitLab SAST Scanning](../../../user/application_security/sast/_index.md#supported-languages-and-frameworks)  `[GitLab Built]`- requires custom ruleset be created.
- [Rust License Scanning (Currently in Prerelease)](https://gitlab.com/groups/gitlab-org/-/epics/13093)  `[GitLab Built]`
- [CodeSecure CodeSonar Embedded C Deep SAST Scanner as a GitLab CI/CD Component](https://gitlab.com/explore/catalog/codesonar/components/codesonar-ci) `[Rust Partner Built]` `[CI Solution]` - supports deep Abstract Execution analysis by watching compiles. Supports GitLabs SAST JSON which enables the findings throughout GitLab Ultimate security features. Features MISRA support and direct support for many Embedded Systems compilers.
