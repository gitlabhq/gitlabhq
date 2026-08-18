---
title: Advanced SAST for iOS in beta
tier: [ Ultimate ]
offering: [ gitlab_com, self_managed, gitlab_dedicated ]
stage: application_security_testin
documentation_link: "../../../user/application_security/sast/gitlab_advanced_sast"
work_item: "https://gitlab.com/groups/gitlab-org/-/work_items/22353"
categories: [ SAST ]
level: secondary
---

<!-- Category: SAST -->

GitLab Advanced SAST now supports Objective-C and Swift, bringing the same interprocedural
taint analysis it delivers for other languages to iOS development. The beta is available for
all GitLab Ultimate customers starting in GitLab 19.3.

The beta detects key OWASP Mobile Top 10 vulnerability classes, including insecure data
storage, broken cryptography, insecure communication, and authentication and authorization
flaws. When a vulnerability begins in one language and reaches a sink in the other, Advanced
SAST detects the complete taint path, including paths that cross the Swift and Objective-C
language boundary.

To enable, set `GITLAB_ADVANCED_SAST_ENABLED: 'true'` in your pipeline. If your project
contains Objective-C or Swift files, the `gitlab-advanced-sast-ext` job runs automatically.
For full setup instructions, see the
[Advanced SAST documentation](../../../user/application_security/sast/gitlab_advanced_sast.md).

Share feedback in the [beta feedback issue](https://gitlab.com/gitlab-org/gitlab/-/work_items/607091).
