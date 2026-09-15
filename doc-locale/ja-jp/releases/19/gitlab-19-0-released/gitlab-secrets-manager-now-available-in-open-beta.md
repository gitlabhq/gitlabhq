---
title: GitLab Secrets Managerがオープンベータで利用可能に
stage: software_supply_chain_security
level: primary
tier: [ Premium, Ultimate ]
offering: [ gitlab_com, self_managed ]
documentation_link: "../../../ci/secrets/secrets_manager/"
work_item: "https://gitlab.com/groups/gitlab-org/-/work_items/21731"
categories: [ Secrets Management ]
weight: 30
---

以前のバージョンのGitLabでは、GitLab Secrets Managerはクローズドベータのコホートのみが利用できました。多くのチームは、HashiCorp VaultやAWS Secrets Managerなどの外部サービスに依存していました。

GitLab Secrets Managerは、GitLab.comおよびGitLab Self-ManagedのPremiumおよびUltimateのお客様向けにオープンベータで利用可能になりました。GitLab Secrets Managerを有効にすると、プロジェクトおよびグループのオーナーはGitLabでCI/CDシークレットを保存、取得、参照できます。シークレットはプロジェクトまたはグループにスコープされ、明示的にリクエストしたパイプラインジョブのみがアクセスできます。

オープンベータ期間中、GitLab Secrets Managerは[ベータサポートポリシー](../../../policy/development_stages_support.md#beta)に従っており、本番環境での使用には対応していない場合があります。

フィードバックは[イシュー598100](https://gitlab.com/gitlab-org/gitlab/-/issues/598100)をご覧ください。
