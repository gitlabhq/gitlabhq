---
title: Revoked GPG identities no longer verify commits
tier: [ Free, Premium, Ultimate ]
offering: [ gitlab_com, self_managed, gitlab_dedicated ]
stage: create
co_create: true
documentation_link: "../../../user/project/repository/signed_commits/gpg/"
work_item: https://gitlab.com/gitlab-org/gitlab/-/merge_requests/255300
categories: [ Source Code Management ]
level: secondary
weight: 70
---

GitLab now ignores user IDs that GPG reports as revoked. A revoked identity no longer appears
under **Access** > **GPG keys** in user settings and no longer counts as a verified email for the
**Verified** badge on signed commits. Commits signed under a revoked identity move to "same
user, different email" or "other user", and a key whose every identity is revoked verifies
nothing. Signatures already verified under a key that stays in place are not re-derived.

Thank you to [José M. Requena Plens](https://gitlab.com/jmrp) for this contribution ([MR](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/255300))!
