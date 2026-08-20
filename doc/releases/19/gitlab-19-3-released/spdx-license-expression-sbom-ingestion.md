---
title: SPDX license expressions in CycloneDX SBOMs brought to GitLab
tier: [ Ultimate ]
offering: [ gitlab_com, self_managed, gitlab_dedicated ]
stage: software_supply_chain_security
documentation_link: "../../../user/compliance/license_scanning_of_cyclonedx_files/#license-expressions"
work_item: https://gitlab.com/gitlab-org/gitlab/-/work_items/606225
categories: [ Software Composition Analysis ]
level: secondary
weight: 50
---

<!-- Category: Software Composition Analysis -->

GitLab 19.3 adds support for Software Package Data Exchange (SPDX) license expressions in CycloneDX Software Bill of Materials (SBOM) files you bring to GitLab.
Previously, components with composite or custom licenses defined using SPDX expression syntax
would appear as unknown.

Now GitLab reads and stores the `expression` field from CycloneDX
license entries, including complex expressions like `MIT AND Apache-2.0` and custom license
references using the `LicenseRef-[NAME]` syntax.

SPDX expression support is especially useful for organizations that generate their own SBOMs and have components with complex or custom license expressions, giving you an accurate view of your license exposure without requiring GitLab-generated scans.

For more information, see [Bring your own CycloneDX SBOM](../../../user/application_security/dependency_scanning/dependency_scanning_sbom/_index.md).
