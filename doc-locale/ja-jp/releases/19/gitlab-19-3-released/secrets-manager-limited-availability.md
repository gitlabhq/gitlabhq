---
title: GitLab Secrets ManagerがGitLab.comで利用可能に
tier: [ Premium, Ultimate ]
add_ons: ["GitLab Secrets Manager"]
offering: [ gitlab_com ]
stage: software_supply_chain_security
documentation_link: "../../../ci/secrets/secrets_manager/"
work_item: https://gitlab.com/groups/gitlab-org/-/work_items/10723
categories: [ Secrets Management ]
level: primary
weight: 50
---

認証情報の漏洩は、多くの場合同じパターンで始まります。デベロッパーがシークレットを必要とし、適切な保管場所がないため、スコープが広すぎるCI/CD変数やコミットされた設定ファイルに書き込んでしまうのです。GitLab Secrets Managerは、GitLab.comでLimited Availabilityとして提供が開始され、認証情報のセキュリティを強化しながら、パイプラインを実行するのと同じプラットフォーム上で一元管理できます。

各シークレットは、環境、ブランチ、およびブランチ保護設定に基づいて、必要なジョブのみにスコープが限定されます。そのため、認証情報が侵害されても、許可された範囲を超えてアクセスされることはありません。Secrets Managerは既存のグループおよびプロジェクトの権限を使用するため、別途アクセスモデルを管理する必要はありません。作成、更新、読み取りのすべての操作が監査証跡に記録されるため、漏洩調査の際に複数のシステムからログを収集する手間がかかりません。

GitLab Secrets ManagerはGitLabクレジットで課金されるアドオンです。30日間の無料トライアルを開始して、すべての機能をお試しください。課金とトライアルの詳細については、[課金に関するドキュメント](../../../ci/secrets/secrets_manager/secrets_manager_billing.md)をご覧ください。
