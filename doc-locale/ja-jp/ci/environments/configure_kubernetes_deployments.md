---
stage: Deploy
group: Environments
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Kubernetesデプロイを設定する（非推奨）
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< alert type="warning" >}}

この機能は、GitLab 14.5で[非推奨](https://gitlab.com/groups/gitlab-org/configure/-/epics/8)になりました。

{{< /alert >}}

プロジェクトに関連付けられた[Kubernetes](../../user/infrastructure/clusters/_index.md)クラスターにデプロイしている場合、`.gitlab-ci.yml`ファイルからこれらのデプロイを設定できます。

{{< alert type="note" >}}

Kubernetesクラスターの設定は、[GitLabで管理](../../user/project/clusters/gitlab_managed_clusters.md)されているKubernetesクラスターではサポートされていません。

{{< /alert >}}

次の設定オプションがサポートされています:

- [`namespace`](https://kubernetes.io/docs/concepts/overview/working-with-objects/namespaces/)

次の例では、ジョブはアプリケーションを`production` Kubernetesネームスペースにデプロイします。

```yaml
deploy:
  stage: deploy
  script:
    - echo "Deploy to production server"
  environment:
    name: production
    url: https://example.com
    kubernetes:
      agent: path/to/agent/project:agent-name
      dashboard:
        namespace: production
  rules:
    - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH
```

GitLab Kubernetesインテグレーションを使用してKubernetesクラスターにデプロイすると、クラスターとネームスペースの情報を表示できます。デプロイメントジョブページでは、ジョブトレースの上に表示されます:

![クラスターとネームスペースを含むデプロイメントクラスター情報](img/environments_deployment_cluster_v12_8.png)

## インクリメンタルロールアウト {#configure-incremental-rollouts}

[段階的なロールアウト](incremental_rollouts.md)を使用して、本番環境の変更をKubernetesポッドの一部だけにリリースする方法を説明します。

## 関連トピック {#related-topics}

- [デプロイボード（非推奨）](../../user/project/deploy_boards.md)
