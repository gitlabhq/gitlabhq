---
stage: None - Facilitated functionality, see <https://handbook.gitlab.com/handbook/product/categories/#facilitated-functionality>
group: Unassigned - Facilitated functionality, see <https://handbook.gitlab.com/handbook/product/categories/#facilitated-functionality>
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
gitlab_dedicated: no
title: ヘルスチェック
description: ヘルス、ライブネス、およびレディネスチェックを実行します。
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

GitLabは、サービスの正常性と必要なサービスへの到達可能性を示すライブネスプローブとレディネスプローブを提供します。これらのプローブは、データベース接続、Redis接続、およびファイルシステムへのアクセスのステータスを報告します。これらのエンドポイントは、システムが準備できるまでトラフィックを保持するか、必要に応じてコンテナを再起動するために、[Kubernetesのようなスケジューラーに提供できます](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/)。

ヘルスチェックエンドポイントは通常、トラフィックをリダイレクトする前にサービスの可用性を判断する必要があるロードバランサーやその他のKubernetesスケジューリングシステムで使用されます。

大規模なKubernetesデプロイにおいて、これらのエンドポイントを効果的なアップタイムの判断に使用するべきではありません。これを行うと、ポッドがオートスケール、ノード障害、またはその他の通常の、サービスを中断しない運用上の必要性によって削除された場合に、誤った陰性結果を示す可能性があります。

大規模なKubernetesデプロイのアップタイムを判断するには、トラフィックをUIで確認してください。これは適切にバランスされ、スケジュールされているため、効果的なアップタイムのより良い指標となります。サインインページ`/users/sign_in`エンドポイントを監視することもできます。

<!-- vale gitlab_base.Spelling = NO -->

GitLab.comでは、[Pingdom](https://www.pingdom.com/)などのツールやApdex測定がアップタイムの判断に使用されます。

<!-- vale gitlab_base.Spelling = YES -->

## IP許可リスト {#ip-allowlist}

モニタリングリソースにアクセスするには、リクエスト元のクライアントIPが許可リストに含まれている必要があります。詳細については、[モニタリングエンドポイントに許可リストでIPを追加する方法](ip_allowlist.md)を参照してください。

## ローカルでエンドポイントを使用する {#using-the-endpoints-locally}

デフォルトの許可リスト設定では、以下のURLを使用してlocalhostからプローブにアクセスできます:

```plaintext
GET http://localhost/-/health
```

```plaintext
GET http://localhost/health_check
```

```plaintext
GET http://localhost/-/readiness
```

```plaintext
GET http://localhost/-/liveness
```

## ヘルス {#health}

アプリケーションサーバーが実行中かどうかを確認します。データベースやその他のサービスが実行中であることは検証しません。このエンドポイントはRailsコントローラーを回避し、リクエスト処理ライフサイクルの非常に初期段階で追加のミドルウェア`BasicHealthCheck`として実装されています。

```plaintext
GET /-/health
```

リクエスト例: 

```shell
curl "https://gitlab.example.com/-/health"
```

レスポンス例: 

```plaintext
GitLab OK
```

## 包括的なヘルスチェック {#comprehensive-health-check}

> [!warning] 
> 
> **ロードバランシングまたはオートスケールに`/health_check`を使用しないでください。**このエンドポイントはバックエンドサービス（データベース、Redis）を検証し、これらのサービスが遅い、または利用できない場合、アプリケーションが正常に機能していても失敗します。これにより、健全なアプリケーションノードがロードバランサーから不必要に削除される可能性があります。

`/health_check`エンドポイントは、データベース接続性、Redisの可用性、およびその他のバックエンドサービスを含む包括的なヘルスチェックを実行します。これは`health_check`gemによって提供され、アプリケーションスタック全体を検証します。

このエンドポイントは以下に使用します:

- 包括的なアプリケーションモニタリング
- バックエンドサービスの健全性検証
- 接続の問題のトラブルシューティング
- モニタリングダッシュボードとアラート

```plaintext
GET /health_check
GET /health_check/database
GET /health_check/cache
GET /health_check/migrations
```

リクエスト例: 

```shell
curl "https://gitlab.example.com/health_check"
```

レスポンス例（成功）:

```plaintext
success
```

レスポンス例（失敗）:

```plaintext
health_check failed: Unable to connect to database
```

利用可能なチェック:

- `database` - データベース接続性
- `migrations` - データベース移行ステータス
- `cache` - Redisキャッシュ接続性
- `geo`（EEのみ） - Geoレプリケーションステータス

## レディネス {#readiness}

レディネスプローブは、GitLabインスタンスがRailsコントローラー経由でトラフィックを受け入れる準備ができているかを確認します。デフォルトでは、このチェックはインスタンスチェックのみを検証します。

`all=1`パラメータが指定されている場合、チェックは依存するサービス（データベース、Redis、Gitalyなど）も検証し、それぞれのステータスを返します。

```plaintext
GET /-/readiness
GET /-/readiness?all=1
```

リクエスト例: 

```shell
curl "https://gitlab.example.com/-/readiness"
```

レスポンス例: 

```json
{
   "master_check":[{
      "status":"failed",
      "message": "unexpected Master check result: false"
   }],
   ...
}
```

失敗した場合、エンドポイントは`503`のHTTPステータスコードを返します。

このチェックはRack Attackの対象外です。

## ライブネス {#liveness}

> [!warning] 
> 
> GitLab[12.4](https://about.gitlab.com/upcoming-releases/)では、ライブネスチェックのレスポンスボディが以下の例に合うように変更されました。

アプリケーションサーバーが実行中かどうかを確認します。このプローブは、マルチスレッドによりRailsコントローラーがデッドロック状態にないかを確認するために使用されます。

```plaintext
GET /-/liveness
```

リクエスト例: 

```shell
curl "https://gitlab.example.com/-/liveness"
```

レスポンス例: 

成功した場合、エンドポイントは`200`のHTTPステータスコードと、以下の例のようなレスポンスを返します。

```json
{
   "status": "ok"
}
```

失敗した場合、エンドポイントは`503`のHTTPステータスコードを返します。

このチェックはRack Attackの対象外です。

## Sidekiq {#sidekiq}

[Sidekiqのヘルスチェック](../sidekiq/sidekiq_health_check.md)を設定する方法を学習します。
