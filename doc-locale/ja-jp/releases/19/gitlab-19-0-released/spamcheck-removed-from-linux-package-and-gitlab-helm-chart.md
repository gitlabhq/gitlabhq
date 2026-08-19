---
title: LinuxパッケージとGitLab HelmチャートからのSpamcheckの削除
stage: gitlab_delivery
level: secondary
tier: [ Free, Premium, Ultimate ]
offering: [ self_managed ]
documentation_link: "../../../administration/reporting/spamcheck/"
work_item: "https://gitlab.com/gitlab-org/gitlab/-/work_items/590796"
categories: [ Omnibus Package, Cloud Native Installation ]
weight: 60
---

[Spamcheck](../../../administration/reporting/spamcheck.md)は、GitLab 19.0でLinuxパッケージおよびGitLab Helmチャートから削除されました。現在Spamcheckを使用していないお客様への影響はありません。バンドルされたSpamcheckを使用している場合は、[Docker](https://gitlab.com/gitlab-org/gl-security/security-engineering/security-automation/spam/spamcheck)を使用して個別にデプロイできます。データ移行は不要です。
