---
title: Malicious package detection in Dependency Scanning (Beta)
tier: [ Ultimate ]
offering: [ gitlab_com, self_managed, gitlab_dedicated ]
stage: application_security_testing
documentation_link: ../../../user/application_security/gitlab_advisory_database/
work_item: https://gitlab.com/gitlab-org/gitlab/-/work_items/606037
categories: [ Software Composition Analysis ]
level: secondary
---

In previous versions of GitLab, Dependency Scanning only surfaced packages with known
CVEs. Malicious packages, those crafted to harm through typosquatting, compromised
maintainer accounts, or embedded malware, produced no findings.

GitLab 19.4 introduces malicious package detection in beta. Dependency Scanning now checks
your dependencies against [GitLab malware advisories](../../../user/application_security/gitlab_advisory_database/_index.md#gitlab-malware-advisories),
so threats can surface before they are widely known. Findings appear in your Dependency List
and Vulnerability Report with a red **Malware** badge, always Critical severity, identified
by a `GLAM-` ID, not a CVE.

You can also block malicious packages before they merge, using the
[malware rule](../../../user/application_security/policies/merge_request_approval_policies.md#block-malicious-packages-with-the-malware-rule)
in merge request approval policies.

You don't need any additional setup. Coverage applies to the
[supported package types](../../../user/application_security/gitlab_advisory_database/_index.md#supported-package-types):
npm, PyPI, Maven, Go, NuGet, Cargo, and RubyGems. The same advisories power
[continuous vulnerability scanning](../../../user/application_security/continuous_vulnerability_scanning/_index.md#malicious-packages),
and [offline instances](../../../topics/offline/quick_start_guide.md) download them manually.

Share feedback on [issue 606036](https://gitlab.com/gitlab-org/gitlab/-/work_items/606036).
