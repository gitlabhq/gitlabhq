---
stage: Tenant Scale
group: Tenant Services
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Sidekiqヘルスチェック
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

GitLabは、サービスの健全性、およびSidekiqクラスターへの到達性を示すための稼働状況と準備状況プローブを提供します。これらのエンドポイントは、システムが準備できるまでトラフィックを保持するか、必要に応じてコンテナを再起動するために、[Kubernetesのようなスケジューラに提供できます](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/)。

ヘルスチェックサーバーは、[Sidekiqを設定する](_index.md)ときにセットアップできます。

## 準備状況 {#readiness}

Sidekiqワーカーがジョブを処理する準備ができているか確認します。

```plaintext
GET /readiness
```

サーバーが`localhost:8092`にバインドされている場合、プロセスクラスターの準備状況を次のようにプローブできます:

```shell
curl "http://localhost:8092/readiness"
```

成功すると、エンドポイントは`200` HTTPステータスコードと、次のような応答を返します:

```json
{
   "status": "ok"
}
```

## 稼働状況 {#liveness}

Sidekiqクラスターが実行中であるかを確認します。

```plaintext
GET /liveness
```

サーバーが`localhost:8092`にバインドされている場合、プロセスクラスターの稼働状況を次のようにプローブできます:

```shell
curl "http://localhost:8092/liveness"
```

成功すると、エンドポイントは`200` HTTPステータスコードと、次のような応答を返します:

```json
{
   "status": "ok"
}
```
