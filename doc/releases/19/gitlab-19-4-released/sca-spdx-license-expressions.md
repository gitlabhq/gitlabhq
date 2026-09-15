---
title: SPDX license expression support in dependency and license scanning
tier: [ Ultimate ]
offering: [ gitlab_com, self_managed, gitlab_dedicated ]
stage: software_supply_chain_security
documentation_link: ../../../user/compliance/license_scanning_of_cyclonedx_files/
work_item: https://gitlab.com/groups/gitlab-org/-/work_items/16801
categories: [ "Software Composition Analysis" ]
level: primary
---

GitLab license data now carries SPDX license expressions, including compound declarations
such as `MIT OR Apache-2.0` or `GPL-2.0-only WITH Classpath-exception-2.0`.
Previously these were reported as `unknown` in the dependency list and were invisible to
license approval policies.

Composite licenses now appear in the dependency list with their operator (`AND`, `OR`,
`WITH`), and license approval policies can allow or deny them the same way they handle
single-license dependencies.

Expressions declared in a CycloneDX SBOM have been supported since GitLab 19.3.
This release adds them to the license data GitLab synchronizes.
Offline instances receive expressions only after
[downloading the v3 license data](../../../topics/offline/quick_start_guide.md#download-v3-license-data).
