---
stage: none
group: unassigned
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
gitlab_dedicated: no
title: ヘルスチェック
description: ヘルスチェック、活性度、および準備状況のチェックを実行します。
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

GitLabは、サービスのヘルスチェックと、必要なサービスへの到達可能性を示すために、活性度と準備状況のプローブを提供します。これらのプローブは、データベース接続、Redis接続、およびファイルシステムへのアクセス状況をレポートします。これらのエンドポイントは、システムが準備できるまでトラフィックを保持したり、必要に応じてコンテナを再起動したりするために、[Kubernetesなどのスケジューラに提供できます](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/)。

ヘルスチェックのエンドポイントは通常、ロードバランサーや、トラフィックのリダイレクト前にサービスの可用性を判断する必要がある他のKubernetesスケジューリングシステムで使用されます。

大規模なKubernetesデプロイで有効なアップタイムを判断するために、これらのエンドポイントを使用しないでください。そうすると、ポッドがオートスケール、ノードの失敗、またはその他の通常動作で中断を伴わない運用上のニーズによって削除された場合に、偽陰性を示す可能性があります。

大規模なKubernetesデプロイでアップタイムを判断するには、UIへのトラフィックを確認します。これは適切にバランスが取れてスケジュールされているため、有効なアップタイムのより良い指標となります。サインインページ`/users/sign_in`エンドポイントをモニタリングすることもできます。

<!-- vale gitlab_base.Spelling = NO -->

GitLab.comでは、[Pingdom](https://www.pingdom.com/)などのツールとApdex測定を使用して、アップタイムを判断します。

<!-- vale gitlab_base.Spelling = YES -->

## IP許可リスト {#ip-allowlist}

モニタリングリソースにアクセスするには、リクエスト元のクライアントIPを許可リストに含める必要があります。詳細については、[IPをモニタリングエンドポイントの許可リストに追加する方法](ip_allowlist.md)を参照してください。

## エンドポイントをローカルで使用する {#using-the-endpoints-locally}

デフォルトの許可リスト設定では、次のURLを使用して、localhostからプローブにアクセスできます:

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

アプリケーションサーバーが実行されているかどうかを確認します。データベースや他のサービスが実行されていることは検証しません。このエンドポイントは、Railsコントローラーを回避し、リクエストの処理ライフサイクルの非常に早い段階で追加のミドルウェア`BasicHealthCheck`として実装されます。

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

{{< alert type="warning" >}} **`/health_check`ロードバランシングまたはオートスケールにはコードを使用しないでください。**このエンドポイントは、バックエンドサービス（データベース、Redis）を検証し、これらのサービスの速度が遅いか利用できない場合、アプリケーションが適切に機能している場合でも失敗します。これにより、正常なアプリケーションノードがロードバランサーから不必要に削除される可能性があります。{{< /alert >}}

`/health_check`エンドポイントは、データベース接続、Redisの可用性、およびその他のバックエンドサービスを含む包括的なヘルスチェックを実行します。これは`health_check` gemによって提供され、アプリケーションスタック全体を検証します。

このエンドポイントは以下に使用します:

- 包括的なアプリケーションモニタリング
- バックエンドサービスのヘルスチェック検証
- 接続性のイシューのトラブルシューティング
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

レポートのコード例（成功）:

```plaintext
success
```

レポートのコード例（失敗）:

```plaintext
health_check failed: Unable to connect to database
```

使用可能なチェック:

- `database` - データベース接続
- `migrations` - データベース移行ステータス
- `cache` - Redisキャッシュ接続
- `geo`（EEのみ）- Geoレプリケーションステータス

## 準備完了 {#readiness}

準備状況プローブは、GitLabインスタンスがRailsコントローラー経由でトラフィックを受け入れる準備ができているかどうかを確認します。チェックではデフォルトでインスタンスチェックのみが検証されます。

`all=1`パラメータが指定されている場合、チェックは依存サービス（データベース、Redis、Gitalyなど）も検証し、それぞれのステータスを表示します。

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

失敗すると、エンドポイントは`503` HTTPステータスを返します。

このチェックは、Rack Attackから除外されます。

## 活性度 {#liveness}

{{< alert type="warning" >}}

GitLab [12.4](https://about.gitlab.com/upcoming-releases/)では、活性度チェックのレポート本文が以下の例と一致するように変更されました。

{{< /alert >}}

アプリケーションサーバーが実行されているかどうかを確認します。このプローブは、マルチスレッドが原因でRailsコントローラーがデッドロックしていないかどうかを確認するために使用されます。

```plaintext
GET /-/liveness
```

リクエスト例:

```shell
curl "https://gitlab.example.com/-/liveness"
```

レスポンス例:

成功すると、エンドポイントは`200` HTTPステータスを返し、以下のようなレポートを返します。

```json
{
   "status": "ok"
}
```

失敗すると、エンドポイントは`503` HTTPステータスを返します。

このチェックは、Rack Attackから除外されます。

## Sidekiq {#sidekiq}

[Sidekiqヘルスチェック](../sidekiq/sidekiq_health_check.md)の構成方法について説明します。
