---
title: Block merge requests that add malicious packages
tier: [ Ultimate ]
offering: [ gitlab_com, self_managed, gitlab_dedicated ]
stage: security_risk_management
documentation_link: "../../../user/application_security/policies/merge_request_approval_policies/#block-malicious-packages-with-the-malware-rule"
work_item: https://gitlab.com/groups/gitlab-org/-/work_items/19465
categories: [ Security Policy Management ]
level: secondary
---

In previous versions of GitLab, merge request approval policies treated malicious packages
like any other vulnerability. If a finding was dismissed or fell outside a rule's severity
filters, a package built to cause harm could still be merged.

Now you can add a malware rule to your merge request approval policies. When dependency
scanning detects a package listed in the GitLab malware advisories, the merge request
requires approval, regardless of the finding's severity or state. The malware rule works
alongside your existing scan finding rules, so you can add it to the policies you already
have without rebuilding them.

To use the malware rule, your project must run
[dependency scanning by using SBOM](../../../user/application_security/dependency_scanning/dependency_scanning_sbom/_index.md#turn-on-dependency-scanning).
Malware advisories cover npm, PyPI, Maven, Go, NuGet, Cargo, and RubyGems packages.
