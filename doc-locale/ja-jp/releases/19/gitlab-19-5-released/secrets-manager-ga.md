---
title: GitLab Secrets Managerが一般提供を開始
tier: [ Premium, Ultimate ]
add_ons: ["GitLab Secrets Manager"]
offering: [ gitlab_com, self_managed ]
stage: software_supply_chain_security
documentation_link: "../../../ci/secrets/secrets_manager/"
work_item: https://gitlab.com/groups/gitlab-org/-/work_items/10723
categories: [ Secrets Management ]
level: primary
weight: 20
---

一元化されたシークレットストアがない場合、認証情報はスコープが広すぎるCI/CD変数、ローカルの設定ファイル、個別のVaultなどに分散してしまいます。これにより、管理、保護、監査がより困難になります。

GitLab Secrets Managerが、GitLab.comおよびGitLab Self-Managedで一般提供を開始しました。OpenBaoをベースに構築されており、既存のグループおよびプロジェクトの権限をそのまま利用できるため、別途アクセスモデルを管理する必要はありません。各CIシークレットは、環境、ブランチ、およびブランチ保護ルールに基づいて、必要なジョブにスコープが限定されます。作成、読み取り、更新、削除のすべての操作に対して監査ログが生成されます。

GitLab Secrets ManagerはGitLabクレジットを消費します。[30日間の無料トライアルを開始する](../../../ci/secrets/secrets_manager/credit_usage.md#start-a-trial)か、[グループまたはインスタンスで有効にする](../../../ci/secrets/secrets_manager/_index.md#enable-gitlab-secrets-manager)ことができます。
