---
stage: Deploy
group: Environments
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Kubernetesクラスター
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

クラスターをGitLabに接続するには、[Kubernetes向けGitLabエージェント](../../clusters/agent/_index.md)を使用します。

## 証明書ベースのKubernetesインテグレーション（非推奨） {#certificate-based-kubernetes-integration-deprecated}

{{< alert type="warning" >}}

GitLab 14.5では、Kubernetes クラスターをGitLabに接続する証明書ベースの方法は[deprecated](https://gitlab.com/groups/gitlab-org/configure/-/epics/8)になり、関連する[features](#deprecated-features)も同様に非推奨となりました。GitLab Self-Managed 17.0以降、この機能はデフォルトで無効になっています。GitLab SaaSユーザーの場合、この機能は、ネームスペース階層で少なくとも1つの証明書ベースのクラスターを有効にしているユーザーを対象に、GitLab 15.9まで利用できます。この機能を以前に使用したことがないGitLab SaaSユーザーの場合、この機能は利用できなくなりました。

{{< /alert >}}

GitLabとの証明書ベースのKubernetesインテグレーションは非推奨です。これには次の問題がありました:

- GitLabによるKubernetes APIへの直接アクセスが必要なため、セキュリティ上の問題がありました。
- 設定オプションに柔軟性がありませんでした。
- インテグレーションがFlakyでした。
- ユーザーは、このモデルに基づく機能に関する問題を常に報告していました。

このため、新しいモデルである[Kubernetes向けGitLabエージェント](../../clusters/agent/_index.md)に基づく機能の構築を開始しました。両方の方法を並行して維持すると、多くの混乱が生じ、使用、開発、維持、およびドキュメント化が著しく複雑になりました。このため、新しいモデルに注力するために、それらを非推奨にすることにしました。

証明書ベースの機能は、セキュリティと重大な修正を引き続き受け取り、その上に構築された機能は、サポートされているKubernetesバージョンで引き続き動作します。GitLabからのこれらの機能の削除はまだスケジュールされていません。更新については、この[epic](https://gitlab.com/groups/gitlab-org/configure/-/epics/8)に従ってください。

Kubernetes用GitLabエージェントへの移行により多くの時間が必要な場合は、`certificate_based_clusters`という名前の[機能フラグを有効](../../../administration/feature_flags/_index.md)にすることができます。これは[GitLab 15.0で導入](../../../update/deprecations.md#gitlab-self-managed-certificate-based-integration-with-kubernetes)されました。この機能フラグは、証明書ベースのKubernetesインテグレーションを再度有効にします。

## 非推奨機能 {#deprecated-features}

- [クラスター証明書を介して既存のクラスターを接続](../../project/clusters/add_existing_cluster.md)
- [アクセス制御](../../project/clusters/cluster_access.md)
- [GitLab管理対象クラスター](../../project/clusters/gitlab_managed_clusters.md)
- [証明書ベースの接続を介してアプリケーションをデプロイ](../../project/clusters/deploy_to_cluster.md)
- [クラスター管理プロジェクト](../../clusters/management_project.md)
- [クラスター環境](../../clusters/environments.md)
- [デプロイボードにカナリアIngressデプロイを表示](../../project/canary_deployments.md#show-canary-ingress-deployments-on-deploy-boards-deprecated)
- [デプロイボード](../../project/deploy_boards.md)
- [Webターミナル](../../../administration/integration/terminal.md)

### クラスターレベル {#cluster-levels}

[プロジェクトレベル](../../project/clusters/_index.md) 、[グループレベル](../../group/clusters/_index.md) 、および[インスタンスレベル](../../instance/clusters/_index.md)クラスターの概念は、機能はいくらか残っていますが、新しいモデルでは廃止されます。

エージェントは常に単一のGitLabプロジェクトで設定され、他のプロジェクトやグループにクラスター接続を公開して[GitLab CI/CDからアクセス](../../clusters/agent/ci_cd_workflow.md)できます。そうすることで、これらのプロジェクトとグループに同じクラスターへのアクセス権を付与することになり、これはグループレベルクラスターのユースケースと同様です。
