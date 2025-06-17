---
stage: Monitor
group: Platform Insights
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: ログシステム
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 製品:GitLab Self-Managed

{{< /details >}}

GitLabのログシステムは、GitLabインスタンスを分析するための包括的なログ生成およびモニタリング機能を提供します。ログを使用することで、システムの問題を特定し、セキュリティイベントを調査し、アプリケーションのパフォーマンスを分析できます。すべてのアクションに対してログエントリが存在するため、問題が発生した際には、問題の迅速な診断と解決に必要なデータが得られます。

ログシステムの機能:

- 構造化されたログファイルで、GitLabコンポーネント全体にわたるすべてのアプリケーションアクティビティを追跡する。
- 標準化された形式で、パフォーマンスメトリクス、エラー、セキュリティイベントを記録する。
- JSONログ生成を介して、ElasticsearchやSplunkなどのログ分析ツールと連携する。
- GitLabのさまざまなサービスとコンポーネントに対して、個別のログファイルを保持する。
- システム全体でリクエストをトレースするための相関IDを含む。

システムログファイルは通常、標準的なログファイル形式のプレーンテキストです。

ログシステムは、[監査イベント](../audit_event_reports.md)に似ています。詳細については、以下も参照してください。

- [Linuxパッケージインストールにおけるログ生成をカスタマイズする](https://docs.gitlab.com/omnibus/settings/logs.html)
- [JSON形式でGitLabログを解析および分析する](log_parsing.md)

## ログレベル

各ログメッセージには、その重要度と詳細度を示すログレベルが割り当てられています。各ロガーには、最小ログレベルが割り当てられています。ロガーは、ログレベルが最小ログレベル以上の場合にのみ、ログメッセージを出力します。

次のログレベルがサポートされています。

| レベル | 名前      |
|:------|:----------|
| 0     | `DEBUG`   |
| 1     | `INFO`    |
| 2     | `WARN`    |
| 3     | `ERROR`   |
| 4     | `FATAL`   |
| 5     | `UNKNOWN` |

GitLabロガーはデフォルトで`DEBUG`に設定されているため、すべてのログメッセージを出力します。

### デフォルトのログレベルをオーバーライドする

`GITLAB_LOG_LEVEL`環境変数を使用して、GitLabロガーの最小ログレベルをオーバーライドできます。有効な値は、`0` - `5`の値、またはログレベルの名前です。

例:

```shell
GITLAB_LOG_LEVEL=info
```

サービスによっては、この設定の影響を受けない他のログレベルが設定されています。これらのサービスの一部には、ログレベルをオーバーライドするための独自の環境変数があります。次に例を示します。

| サービス              | ログレベル | 環境変数 |
|:---------------------|:----------|:---------------------|
| GitLab Cleanup       | `INFO`    | `DEBUG`              |
| GitLab Doctor        | `INFO`    | `VERBOSE`            |
| GitLab Export        | `INFO`    | `EXPORT_DEBUG`       |
| GitLab Import        | `INFO`    | `IMPORT_DEBUG`       |
| GitLab QA Runtime    | `INFO`    | `QA_LOG_LEVEL`       |
| Google APIs          | `INFO`    |                      |
| Rack Timeout         | `ERROR`   |                      |
| Snowplow Tracker     | `FATAL`   |                      |
| gRPC Client (Gitaly) | `WARN`    | `GRPC_LOG_LEVEL`     |
| LLM                  | `INFO`    | `LLM_DEBUG`          |

## ログローテーション

特定のサービスのログは、次のいずれかによって管理およびローテーションされる場合があります。

- `logrotate`
- `svlogd`（`runit`のサービスログ生成デーモン）
- `logrotate`および`svlogd`
- または、いずれにも管理されない

次の表は、各サービスのログの管理およびローテーションを担当する仕組みに関する情報を示しています。[`svlogd`によって管理される](https://docs.gitlab.com/omnibus/settings/logs.html#runit-logs)ログは、`current`というファイルに書き込まれます。GitLabに組み込まれている`logrotate`サービスは、`runit`によってキャプチャされるログを除く、[すべてのログを管理](https://docs.gitlab.com/omnibus/settings/logs.html#logrotate)します。

| ログタイプ                                        | logrotateによる管理    | svlogd/runitによる管理 |
|:------------------------------------------------|:------------------------|:------------------------|
| [Alertmanagerのログ](#alertmanager-logs)         | {{< icon name="dotted-circle" >}} なし  | {{< icon name="check-circle" >}} あり  |
| [crondのログ](#crond-logs)                       | {{< icon name="dotted-circle" >}} なし  | {{< icon name="check-circle" >}} あり  |
| [Gitaly](#gitaly-logs)                          | {{< icon name="check-circle" >}} あり  | {{< icon name="check-circle" >}} あり  |
| [LinuxパッケージインストールのGitLab Exporter](#gitlab-exporter) | {{< icon name="dotted-circle" >}} なし  | {{< icon name="check-circle" >}} あり  |
| [GitLab Pagesのログ](#pages-logs)                | {{< icon name="check-circle" >}} あり  | {{< icon name="check-circle" >}} あり  |
| GitLab Rails                                    | {{< icon name="check-circle" >}} あり  | {{< icon name="dotted-circle" >}} なし  |
| [GitLab Shellのログ](#gitlab-shelllog)           | {{< icon name="check-circle" >}} あり  | {{< icon name="dotted-circle" >}} なし  |
| [Grafanaのログ](#grafana-logs)                   | {{< icon name="dotted-circle" >}} なし  | {{< icon name="check-circle" >}} あり  |
| [LogRotateのログ](#logrotate-logs)               | {{< icon name="dotted-circle" >}} なし  | {{< icon name="check-circle" >}} あり  |
| [Mailroom](#mail_room_jsonlog-default)          | {{< icon name="check-circle" >}} あり  | {{< icon name="check-circle" >}} あり  |
| [NGINX](#nginx-logs)                            | {{< icon name="check-circle" >}} あり  | {{< icon name="check-circle" >}} あり  |
| [PgBouncerのログ](#pgbouncer-logs)               | {{< icon name="dotted-circle" >}} なし  | {{< icon name="check-circle" >}} あり  |
| [PostgreSQLのログ](#postgresql-logs)             | {{< icon name="dotted-circle" >}} なし  | {{< icon name="check-circle" >}} あり  |
| [Praefectのログ](#praefect-logs)                 | {{< icon name="dotted-circle" >}} あり | {{< icon name="check-circle" >}} あり  |
| [Prometheusのログ](#prometheus-logs)             | {{< icon name="dotted-circle" >}} なし  | {{< icon name="check-circle" >}} あり  |
| [Puma](#puma-logs)                              | {{< icon name="check-circle" >}} あり  | {{< icon name="check-circle" >}} あり  |
| [Redisのログ](#redis-logs)                       | {{< icon name="dotted-circle" >}} なし  | {{< icon name="check-circle" >}} あり  |
| [レジストリのログ](#registry-logs)                 | {{< icon name="dotted-circle" >}} なし  | {{< icon name="check-circle" >}} あり  |
| [Workhorseのログ](#workhorse-logs)               | {{< icon name="check-circle" >}} あり  | {{< icon name="check-circle" >}} あり  |

## `production_json.log`

このファイルは次の場所にあります。

- Linuxパッケージインストール: `/var/log/gitlab/gitlab-rails/production_json.log`
- 自己コンパイルインストール: `/home/git/gitlab/log/production_json.log`

このファイルには、GitLabから受信したRailsコントローラーリクエストの構造化ログが含まれています。この構造化には[Lograge](https://github.com/roidrage/lograge/)が使用されています。APIからのリクエストは、`api_json.log`という別のファイルに記録されます。

各行には、ElasticsearchやSplunkなどのサービスにインジェストできるJSON形式のデータが含まれています。例では、可読性を高めるため改行が追加されています。

```json
{
  "method":"GET",
  "path":"/gitlab/gitlab-foss/issues/1234",
  "format":"html",
  "controller":"Projects::IssuesController",
  "action":"show",
  "status":200,
  "time":"2017-08-08T20:15:54.821Z",
  "params":[{"key":"param_key","value":"param_value"}],
  "remote_ip":"18.245.0.1",
  "user_id":1,
  "username":"admin",
  "queue_duration_s":0.0,
  "gitaly_calls":16,
  "gitaly_duration_s":0.16,
  "redis_calls":115,
  "redis_duration_s":0.13,
  "redis_read_bytes":1507378,
  "redis_write_bytes":2920,
  "correlation_id":"O1SdybnnIq7",
  "cpu_s":17.50,
  "db_duration_s":0.08,
  "view_duration_s":2.39,
  "duration_s":20.54,
  "pid": 81836,
  "worker_id":"puma_0"
}
```

この例は、特定のイシューに対するGETリクエストです。各行にはパフォーマンスデータが含まれており、時間は秒単位です。

- `duration_s`: リクエストの取得にかかった総時間
- `queue_duration_s`: GitLab Workhorse内でリクエストがキューに入っていた総時間
- `view_duration_s`: Railsビュー内の総時間
- `db_duration_s`: PostgreSQLからのデータの取得ににかかった総時間
- `cpu_s`: CPUで費やされた総時間
- `gitaly_duration_s`: Gitalyの呼び出しにかかった総時間
- `gitaly_calls`: Gitalyへの呼び出しの総数
- `redis_calls`: Redisへの呼び出しの総数
- `redis_cross_slot_calls`: Redisへのクロススロット呼び出しの総数
- `redis_allowed_cross_slot_calls`: Redisへの許可されたクロススロット呼び出しの総数
- `redis_duration_s`: Redisからのデータの取得にかかった総時間
- `redis_read_bytes`: Redisから読み取った総バイト数
- `redis_write_bytes`: Redisに書き込んだ総バイト数
- `redis_<instance>_calls`: Redisインスタンスへの呼び出しの総数
- `redis_<instance>_cross_slot_calls`: Redisインスタンスへのクロススロット呼び出しの総数
- `redis_<instance>_allowed_cross_slot_calls`: Redisインスタンスへの許可されたクロススロット呼び出しの総数
- `redis_<instance>_duration_s`: Redisインスタンスからのデータの取得にかかった総時間
- `redis_<instance>_read_bytes`: Redisインスタンスから読み取った総バイト数
- `redis_<instance>_write_bytes`: Redisインスタンスに書き込んだ総バイト数
- `pid`: ワーカーのLinuxプロセスID（ワーカーの再起動時に変更される）
- `worker_id`: ワーカーの論理ID（ワーカーの再起動時に変更されない）

HTTPトランスポートを使用したユーザーによるクローンとフェッチのアクティビティは、ログでは`action: git_upload_pack`として表示されます。

さらに、ログには、送信元のIPアドレス（`remote_ip`）、ユーザーのID（`user_id`）、ユーザー名（`username`）が含まれています。

一部のエンドポイント（例: `/search`）は、[高度な検索](../../user/search/advanced_search.md)を使用している場合にElasticsearchへのリクエストを行うことがあります。これに関連して、`elasticsearch_calls`と`elasticsearch_call_duration_s`もログに記録され、それぞれの意味は次のとおりです。

- `elasticsearch_calls`: Elasticsearchへの呼び出しの総数
- `elasticsearch_duration_s`: Elasticsearchの呼び出しにかかった総時間
- `elasticsearch_timed_out_count`: タイムアウトにより部分的な結果しか返されなかったElasticsearchへの呼び出しの総数

ActionCableの接続イベントとサブスクリプションイベントもこのファイルに記録され、前述の形式に従います。`method`、`path`、`format`の各フィールドは該当せず、常に空になります。`controller`として、ActionCableの接続またはチャンネルクラスが使用されます。

```json
{
  "method":null,
  "path":null,
  "format":null,
  "controller":"IssuesChannel",
  "action":"subscribe",
  "status":200,
  "time":"2020-05-14T19:46:22.008Z",
  "params":[{"key":"project_path","value":"gitlab/gitlab-foss"},{"key":"iid","value":"1"}],
  "remote_ip":"127.0.0.1",
  "user_id":1,
  "username":"admin",
  "ua":"Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:76.0) Gecko/20100101 Firefox/76.0",
  "correlation_id":"jSOIEynHCUa",
  "duration_s":0.32566
}
```

{{< alert type="note" >}}

エラーが発生した場合、`class`、`message`、`backtrace`を含む`exception`フィールドが追加されます。以前のバージョンでは、`exception.class`および`exception.message`ではなく`error`フィールドが含まれていました。次に例を示します。

{{< /alert >}}

```json
{
  "method": "GET",
  "path": "/admin",
  "format": "html",
  "controller": "Admin::DashboardController",
  "action": "index",
  "status": 500,
  "time": "2019-11-14T13:12:46.156Z",
  "params": [],
  "remote_ip": "127.0.0.1",
  "user_id": 1,
  "username": "root",
  "ua": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10.14; rv:70.0) Gecko/20100101 Firefox/70.0",
  "queue_duration": 274.35,
  "correlation_id": "KjDVUhNvvV3",
  "queue_duration_s":0.0,
  "gitaly_calls":16,
  "gitaly_duration_s":0.16,
  "redis_calls":115,
  "redis_duration_s":0.13,
  "correlation_id":"O1SdybnnIq7",
  "cpu_s":17.50,
  "db_duration_s":0.08,
  "view_duration_s":2.39,
  "duration_s":20.54,
  "pid": 81836,
  "worker_id": "puma_0",
  "exception.class": "NameError",
  "exception.message": "undefined local variable or method `adsf' for #<Admin::DashboardController:0x00007ff3c9648588>",
  "exception.backtrace": [
    "app/controllers/admin/dashboard_controller.rb:11:in `index'",
    "ee/app/controllers/ee/admin/dashboard_controller.rb:14:in `index'",
    "ee/lib/gitlab/ip_address_state.rb:10:in `with'",
    "ee/app/controllers/ee/application_controller.rb:43:in `set_current_ip_address'",
    "lib/gitlab/session.rb:11:in `with_session'",
    "app/controllers/application_controller.rb:450:in `set_session_storage'",
    "app/controllers/application_controller.rb:444:in `set_locale'",
    "ee/lib/gitlab/jira/middleware.rb:19:in `call'"
  ]
}
```

## `production.log`

このファイルは次の場所にあります。

- Linuxパッケージインストール: `/var/log/gitlab/gitlab-rails/production.log`
- 自己コンパイルインストール: `/home/git/gitlab/log/production.log`

このファイルには、実行されたすべてのリクエストに関する情報が含まれています。リクエストのURLや種類、IPアドレスに加えて、この特定のリクエストを処理するために使用されたコードの部分などを確認できます。また、実行されたすべてのSQLリクエストと、それぞれにかかった時間も確認できます。このタスクは、GitLabのコントリビューターやデベロッパーにとって特に有用です。バグを報告する際は、このログファイルの一部を使用してください。次に例を示します。

```plaintext
Started GET "/gitlabhq/yaml_db/tree/master" for 168.111.56.1 at 2015-02-12 19:34:53 +0200
Processing by Projects::TreeController#show as HTML
  Parameters: {"project_id"=>"gitlabhq/yaml_db", "id"=>"master"}

  ... [CUT OUT]

  Namespaces"."created_at" DESC, "namespaces"."id" DESC LIMIT 1 [["id", 26]]
  CACHE (0.0ms) SELECT  "members".* FROM "members"  WHERE "members"."source_type" = 'Project' AND "members"."type" IN ('ProjectMember') AND "members"."source_id" = $1 AND "members"."source_type" = $2 AND "members"."user_id" = 1  ORDER BY "members"."created_at" DESC, "members"."id" DESC LIMIT 1  [["source_id", 18], ["source_type", "Project"]]
  CACHE (0.0ms) SELECT  "members".* FROM "members"  WHERE "members"."source_type" = 'Project' AND "members".
  (1.4ms) SELECT COUNT(*) FROM "merge_requests"  WHERE "merge_requests"."target_project_id" = $1 AND ("merge_requests"."state" IN ('opened','reopened')) [["target_project_id", 18]]
  Rendered layouts/nav/_project.html.haml (28.0ms)
  Rendered layouts/_collapse_button.html.haml (0.2ms)
  Rendered layouts/_flash.html.haml (0.1ms)
  Rendered layouts/_page.html.haml (32.9ms)
Completed 200 OK in 166ms (Views: 117.4ms | ActiveRecord: 27.2ms)
```

この例では、サーバーが`2015-02-12 19:34:53 +0200`に、IPアドレス`168.111.56.1`からのHTTPリクエスト（URL `/gitlabhq/yaml_db/tree/master`）を処理しました。このリクエストは`Projects::TreeController`によって処理されました。

## `api_json.log`

このファイルは次の場所にあります。

- Linuxパッケージインストール: `/var/log/gitlab/gitlab-rails/api_json.log`
- 自己コンパイルインストール: `/home/git/gitlab/log/api_json.log`

これにより、APIに対して直接行われたリクエストを確認できます。次に例を示します。

```json
{
  "time":"2018-10-29T12:49:42.123Z",
  "severity":"INFO",
  "duration":709.08,
  "db":14.59,
  "view":694.49,
  "status":200,
  "method":"GET",
  "path":"/api/v4/projects",
  "params":[{"key":"action","value":"git-upload-pack"},{"key":"changes","value":"_any"},{"key":"key_id","value":"secret"},{"key":"secret_token","value":"[FILTERED]"}],
  "host":"localhost",
  "remote_ip":"::1",
  "ua":"Ruby",
  "route":"/api/:version/projects",
  "user_id":1,
  "username":"root",
  "queue_duration":100.31,
  "gitaly_calls":30,
  "gitaly_duration":5.36,
  "pid": 81836,
  "worker_id": "puma_0",
  ...
}
```

このエントリは、関連付けられたSSH鍵が`git fetch`または`git clone`を使用して、対象のプロジェクトをダウンロードできるかどうかを確認するためにアクセスされた内部エンドポイントを示しています。この例では、次の情報を確認できます。

- `duration`: リクエストの取得にかかった総時間（ミリ秒）
- `queue_duration`: リクエストがGitLab Workhorse内でキューに入っていた総時間（ミリ秒）
- `method`: リクエストに使用したHTTPメソッド
- `path`: クエリの相対パス
- `params`: クエリ文字列やHTTP本文で渡されたキーと値のペア（パスワードやトークンなどの機密性の高いパラメーターは除外）
- `ua`: リクエスタのユーザーエージェント

{{< alert type="note" >}}

[`Grape Logging`](https://github.com/aserafin/grape_logging) v1.8.4以降、`view_duration_s`は[`duration_s - db_duration_s`](https://github.com/aserafin/grape_logging/blob/v1.8.4/lib/grape_logging/middleware/request_logger.rb#L117-L119)によって算出されます。したがって、`view_duration_s`は、シリアライズプロセスだけでなく、Redisでの読み書きプロセスや外部HTTPなど、複数の異なる要因の影響を受ける可能性があります。

{{< /alert >}}

## `application.log`（非推奨）

{{< history >}}

- GitLab 15.10で[非推奨](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/111046)になりました。

{{< /history >}}

このファイルは次の場所にあります。

- Linuxパッケージインストール: `/var/log/gitlab/gitlab-rails/application.log`
- 自己コンパイルインストール: `/home/git/gitlab/log/application.log`

このファイルには、[`application_json.log`](#application_jsonlog)の内容の、より構造化されていないバージョンが含まれています。次に例を示します。

```plaintext
October 06, 2014 11:56: User "Administrator" (admin@example.com) was created
October 06, 2014 11:56: Documentcloud created a new project "Documentcloud / Underscore"
October 06, 2014 11:56: Gitlab Org created a new project "Gitlab Org / Gitlab Ce"
October 07, 2014 11:25: User "Claudie Hodkiewicz" (nasir_stehr@olson.co.uk)  was removed
October 07, 2014 11:25: Project "project133" was removed
```

## `application_json.log`

このファイルは次の場所にあります。

- Linuxパッケージインストール: `/var/log/gitlab/gitlab-rails/application_json.log`
- 自己コンパイルインストール: `/home/git/gitlab/log/application_json.log`

このファイルは、ユーザーの作成やプロジェクトの削除など、インスタンスで発生しているイベントを検出するのに役立ちます。次に例を示します。

```json
{
  "severity":"INFO",
  "time":"2020-01-14T13:35:15.466Z",
  "correlation_id":"3823a1550b64417f9c9ed8ee0f48087e",
  "message":"User \"Administrator\" (admin@example.com) was created"
}
{
  "severity":"INFO",
  "time":"2020-01-14T13:35:15.466Z",
  "correlation_id":"78e3df10c9a18745243d524540bd5be4",
  "message":"Project \"project133\" was removed"
}
```

## `integrations_json.log`

このファイルは次の場所にあります。

- Linuxパッケージインストール: `/var/log/gitlab/gitlab-rails/integrations_json.log`
- 自己コンパイルインストール: `/home/git/gitlab/log/integrations_json.log`

このファイルには、Jira、Asana、irkerなどのサービスの[インテグレーション](../../user/project/integrations/_index.md)アクティビティに関する情報が含まれています。JSON形式を使用します。次に例を示します。

```json
{
  "severity":"ERROR",
  "time":"2018-09-06T14:56:20.439Z",
  "service_class":"Integrations::Jira",
  "project_id":8,
  "project_path":"h5bp/html5-boilerplate",
  "message":"Error sending message",
  "client_url":"http://jira.gitlab.com:8080",
  "error":"execution expired"
}
{
  "severity":"INFO",
  "time":"2018-09-06T17:15:16.365Z",
  "service_class":"Integrations::Jira",
  "project_id":3,
  "project_path":"namespace2/project2",
  "message":"Successfully posted",
  "client_url":"http://jira.example.com"
}
```

## `kubernetes.log`（非推奨）

{{< history >}}

- GitLab 14.5で[非推奨](https://gitlab.com/groups/gitlab-org/configure/-/epics/8)になりました。

{{< /history >}}

このファイルは次の場所にあります。

- Linuxパッケージインストール: `/var/log/gitlab/gitlab-rails/kubernetes.log`
- 自己コンパイルインストール: `/home/git/gitlab/log/kubernetes.log`

このファイルには、接続エラーなど、[証明書ベースのクラスター](../../user/project/clusters/_index.md)に関連する情報が記録されます。各行には、ElasticsearchやSplunkなどのサービスにインジェストできるJSON形式のデータが含まれています。

## `git_json.log`

このファイルは次の場所にあります。

- Linuxパッケージインストール: `/var/log/gitlab/gitlab-rails/git_json.log`
- 自己コンパイルインストール: `/home/git/gitlab/log/git_json.log`

GitLabはGitリポジトリとやり取りする必要がありますが、ごくまれに問題が発生することがあります。そのような場合、何が起きたのかを正確に把握する必要があります。このログファイルには、GitLabからGitリポジトリへの失敗したリクエストがすべて含まれています。ほとんどの場合、このファイルはデベロッパーにとってのみ有用です。次に例を示します。

```json
{
   "severity":"ERROR",
   "time":"2019-07-19T22:16:12.528Z",
   "correlation_id":"FeGxww5Hj64",
   "message":"Command failed [1]: /usr/bin/git --git-dir=/Users/vsizov/gitlab-development-kit/gitlab/tmp/tests/gitlab-satellites/group184/gitlabhq/.git --work-tree=/Users/vsizov/gitlab-development-kit/gitlab/tmp/tests/gitlab-satellites/group184/gitlabhq merge --no-ff -mMerge branch 'feature_conflict' into 'feature' source/feature_conflict\n\nerror: failed to push some refs to '/Users/vsizov/gitlab-development-kit/repositories/gitlabhq/gitlab_git.git'"
}
```

## `audit_json.log`

{{< details >}}

- プラン: Free、Premium、Ultimate
- 製品:GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< alert type="note" >}}

GitLab Freeでは、数種類の監査イベントのみを追跡します。GitLab Premiumでは、さらに多くの監査イベントを追跡します。

{{< /alert >}}

このファイルは次の場所にあります。

- Linuxパッケージインストール: `/var/log/gitlab/gitlab-rails/audit_json.log`
- 自己コンパイルインストール: `/home/git/gitlab/log/audit_json.log`

このファイルには、グループまたはプロジェクトの設定とメンバーシップ（`target_details`）に対する変更が記録されます。次に例を示します。

```json
{
  "severity":"INFO",
  "time":"2018-10-17T17:38:22.523Z",
  "author_id":3,
  "entity_id":2,
  "entity_type":"Project",
  "change":"visibility",
  "from":"Private",
  "to":"Public",
  "author_name":"John Doe4",
  "target_id":2,
  "target_type":"Project",
  "target_details":"namespace2/project2"
}
```

## Sidekiqログ

Linuxパッケージインストールの場合、一部のSidekiqログは`/var/log/gitlab/sidekiq/current`にあり、次のようになります。

### `sidekiq.log`

{{< history >}}

- GitLab 16.0以降、Helmチャートインストールのデフォルトのログ形式が[`text`から`json`に変更](https://gitlab.com/gitlab-org/charts/gitlab/-/merge_requests/3169)されました。

{{< /history >}}

このファイルは次の場所にあります。

- Linuxパッケージインストール: `/var/log/gitlab/sidekiq/current`
- 自己コンパイルインストール: `/home/git/gitlab/log/sidekiq.log`

GitLabは、時間がかかる可能性のあるタスクを処理するためにバックグラウンドジョブを使用します。このファイルは、これらのジョブの処理に関するすべての情報が記録されます。次に例を示します。

```json
{
  "severity":"INFO",
  "time":"2018-04-03T22:57:22.071Z",
  "queue":"cronjob:update_all_mirrors",
  "args":[],
  "class":"UpdateAllMirrorsWorker",
  "retry":false,
  "queue_namespace":"cronjob",
  "jid":"06aeaa3b0aadacf9981f368e",
  "created_at":"2018-04-03T22:57:21.930Z",
  "enqueued_at":"2018-04-03T22:57:21.931Z",
  "pid":10077,
  "worker_id":"sidekiq_0",
  "message":"UpdateAllMirrorsWorker JID-06aeaa3b0aadacf9981f368e: done: 0.139 sec",
  "job_status":"done",
  "duration":0.139,
  "completed_at":"2018-04-03T22:57:22.071Z",
  "db_duration":0.05,
  "db_duration_s":0.0005,
  "gitaly_duration":0,
  "gitaly_calls":0
}
```

JSONログの代わりに、Sidekiqのテキストログを生成することも選択できます。次に例を示します。

```plaintext
2023-05-16T16:08:55.272Z pid=82525 tid=23rl INFO: Initializing websocket
2023-05-16T16:08:55.279Z pid=82525 tid=23rl INFO: Booted Rails 6.1.7.2 application in production environment
2023-05-16T16:08:55.279Z pid=82525 tid=23rl INFO: Running in ruby 3.0.5p211 (2022-11-24 revision ba5cf0f7c5) [arm64-darwin22]
2023-05-16T16:08:55.279Z pid=82525 tid=23rl INFO: See LICENSE and the LGPL-3.0 for licensing details.
2023-05-16T16:08:55.279Z pid=82525 tid=23rl INFO: Upgrade to Sidekiq Pro for more features and support: https://sidekiq.org
2023-05-16T16:08:55.286Z pid=82525 tid=7p4t INFO: Cleaning working queues
2023-05-16T16:09:06.043Z pid=82525 tid=7p7d class=ScheduleMergeRequestCleanupRefsWorker jid=efcc73f169c09a514b06da3f INFO: start
2023-05-16T16:09:06.050Z pid=82525 tid=7p7d class=ScheduleMergeRequestCleanupRefsWorker jid=efcc73f169c09a514b06da3f INFO: arguments: []
2023-05-16T16:09:06.065Z pid=82525 tid=7p81 class=UserStatusCleanup::BatchWorker jid=e279aa6409ac33031a314822 INFO: start
2023-05-16T16:09:06.066Z pid=82525 tid=7p81 class=UserStatusCleanup::BatchWorker jid=e279aa6409ac33031a314822 INFO: arguments: []
```

Linuxパッケージインストールの場合、次の設定オプションを追加します。

```ruby
sidekiq['log_format'] = 'text'
```

自己コンパイルインストールの場合、`gitlab.yml`を編集し、Sidekiqの`log_format`設定オプションを指定します。

```yaml
  ## Sidekiq
  sidekiq:
    log_format: text
```

### `sidekiq_client.log`

このファイルは次の場所にあります。

- Linuxパッケージインストール: `/var/log/gitlab/gitlab-rails/sidekiq_client.log`
- 自己コンパイルインストール: `/home/git/gitlab/log/sidekiq_client.log`

このファイルには、Sidekiqがジョブの処理を開始する前、たとえばキューに投入される前など、ジョブに関するログ情報が含まれています。

このログファイルは[`sidekiq.log`](#sidekiqlog)と同じ構造になっており、Sidekiqに対してJSON形式を使用するよう設定している場合は、JSON形式で構造化されています。

## `gitlab-shell.log`

GitLab Shellは、Gitコマンドの実行やGitリポジトリへのSSHアクセスを提供するためにGitLabが使用します。

`git-{upload-pack,receive-pack}`リクエストに関する情報は、`/var/log/gitlab/gitlab-shell/gitlab-shell.log`にあります。GitalyからGitLab Shellへのフックに関する情報は、`/var/log/gitlab/gitaly/current`にあります。

`/var/log/gitlab/gitlab-shell/gitlab-shell.log`のログエントリの例:

```json
{
  "duration_ms": 74.104,
  "level": "info",
  "method": "POST",
  "msg": "Finished HTTP request",
  "time": "2020-04-17T20:28:46Z",
  "url": "http://127.0.0.1:8080/api/v4/internal/allowed"
}
{
  "command": "git-upload-pack",
  "git_protocol": "",
  "gl_project_path": "root/example",
  "gl_repository": "project-1",
  "level": "info",
  "msg": "executing git command",
  "time": "2020-04-17T20:28:46Z",
  "user_id": "user-1",
  "username": "root"
}
```

`/var/log/gitlab/gitaly/current`のログエントリの例:

```json
{
  "method": "POST",
  "url": "http://127.0.0.1:8080/api/v4/internal/allowed",
  "duration": 0.058012959,
  "gitaly_embedded": true,
  "pid": 16636,
  "level": "info",
  "msg": "finished HTTP request",
  "time": "2020-04-17T20:29:08+00:00"
}
{
  "method": "POST",
  "url": "http://127.0.0.1:8080/api/v4/internal/pre_receive",
  "duration": 0.031022552,
  "gitaly_embedded": true,
  "pid": 16636,
  "level": "info",
  "msg": "finished HTTP request",
  "time": "2020-04-17T20:29:08+00:00"
}
```

## Gitalyログ

このファイルは`/var/log/gitlab/gitaly/current`にあり、[runit](https://smarden.org/runit/)によって生成されます。`runit`はLinuxパッケージに同梱されており、その目的の簡単な説明は[Linuxパッケージのドキュメント](https://docs.gitlab.com/omnibus/architecture/#runit)に記載されています。[ログファイルはローテーション](https://smarden.org/runit/svlogd.8)され、UNIXタイムスタンプ形式で名前が変更されたうえで`gzip`圧縮されます（例: `@1584057562.s`）。

### `grpc.log`

このファイルは、Linuxパッケージインストールの場合、`/var/log/gitlab/gitlab-rails/grpc.log`にあります。Gitalyが使用するネイティブの[gRPC](https://grpc.io/)ログです。

### `gitaly_hooks.log`

このファイルは、`/var/log/gitlab/gitaly/gitaly_hooks.log`にあり、`gitaly-hooks`コマンドによって生成されます。また、GitLab APIからの応答処理中に受信した失敗に関する記録も含まれています。

## Pumaログ

### `puma_stdout.log`

このファイルは次の場所にあります。

- Linuxパッケージインストール: `/var/log/gitlab/puma/puma_stdout.log`
- 自己コンパイルインストール: `/home/git/gitlab/log/puma_stdout.log`

### `puma_stderr.log`

このファイルは次の場所にあります。

- Linuxパッケージインストール: `/var/log/gitlab/puma/puma_stderr.log`
- 自己コンパイルインストール: `/home/git/gitlab/log/puma_stderr.log`

## `repocheck.log`

このファイルは次の場所にあります。

- Linuxパッケージインストール: `/var/log/gitlab/gitlab-rails/repocheck.log`
- 自己コンパイルインストール: `/home/git/gitlab/log/repocheck.log`

プロジェクトで[リポジトリチェックが実行される](../repository_checks.md)たびに、その情報が記録されます。

## `importer.log`

このファイルは次の場所にあります。

- Linuxパッケージインストール: `/var/log/gitlab/gitlab-rails/importer.log`
- 自己コンパイルインストール: `/home/git/gitlab/log/importer.log`

このファイルには、[プロジェクトのインポートと移行](../../user/project/import/_index.md)の進捗状況が記録されます。

## `exporter.log`

このファイルは次の場所にあります。

- Linuxパッケージインストール: `/var/log/gitlab/gitlab-rails/exporter.log`
- 自己コンパイルインストール: `/home/git/gitlab/log/exporter.log`

このファイルには、エクスポートプロセスの進捗状況が記録されます。

## `features_json.log`

このファイルは次の場所にあります。

- Linuxパッケージインストール: `/var/log/gitlab/gitlab-rails/features_json.log`
- 自己コンパイルインストール: `/home/git/gitlab/log/features_json.log`

このファイルには、[GitLabの開発における機能フラグ](../../development/feature_flags/_index.md)からの変更イベントが記録されます。次に例を示します。

```json
{"severity":"INFO","time":"2020-11-24T02:30:59.860Z","correlation_id":null,"key":"cd_auto_rollback","action":"enable","extra.thing":"true"}
{"severity":"INFO","time":"2020-11-24T02:31:29.108Z","correlation_id":null,"key":"cd_auto_rollback","action":"enable","extra.thing":"true"}
{"severity":"INFO","time":"2020-11-24T02:31:29.129Z","correlation_id":null,"key":"cd_auto_rollback","action":"disable","extra.thing":"false"}
{"severity":"INFO","time":"2020-11-24T02:31:29.177Z","correlation_id":null,"key":"cd_auto_rollback","action":"enable","extra.thing":"Project:1"}
{"severity":"INFO","time":"2020-11-24T02:31:29.183Z","correlation_id":null,"key":"cd_auto_rollback","action":"disable","extra.thing":"Project:1"}
{"severity":"INFO","time":"2020-11-24T02:31:29.188Z","correlation_id":null,"key":"cd_auto_rollback","action":"enable_percentage_of_time","extra.percentage":"50"}
{"severity":"INFO","time":"2020-11-24T02:31:29.193Z","correlation_id":null,"key":"cd_auto_rollback","action":"disable_percentage_of_time"}
{"severity":"INFO","time":"2020-11-24T02:31:29.198Z","correlation_id":null,"key":"cd_auto_rollback","action":"enable_percentage_of_actors","extra.percentage":"50"}
{"severity":"INFO","time":"2020-11-24T02:31:29.203Z","correlation_id":null,"key":"cd_auto_rollback","action":"disable_percentage_of_actors"}
{"severity":"INFO","time":"2020-11-24T02:31:29.329Z","correlation_id":null,"key":"cd_auto_rollback","action":"remove"}
```

## `ci_resource_groups_json.log`

{{< history >}}

- GitLab 15.9で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/384180)されました。

{{< /history >}}

このファイルは次の場所にあります。

- Linuxパッケージインストール: `/var/log/gitlab/gitlab-rails/ci_resource_group_json.log`
- 自己コンパイルインストール: `/home/git/gitlab/log/ci_resource_group_json.log`

このファイルには、[リソースグループ](../../ci/resource_groups/_index.md)の取得に関する情報が含まれています。次に例を示します。

```json
{"severity":"INFO","time":"2023-02-10T23:02:06.095Z","correlation_id":"01GRYS10C2DZQ9J1G12ZVAD4YD","resource_group_id":1,"processable_id":288,"message":"attempted to assign resource to processable","success":true}
{"severity":"INFO","time":"2023-02-10T23:02:08.945Z","correlation_id":"01GRYS138MYEG32C0QEWMC4BDM","resource_group_id":1,"processable_id":288,"message":"attempted to release resource from processable","success":true}
```

この例は、各エントリの`resource_group_id`、`processable_id`、`message`、`success`フィールドを示しています。

## `auth.log`

このファイルは次の場所にあります。

- Linuxパッケージインストール: `/var/log/gitlab/gitlab-rails/auth.log`
- 自己コンパイルインストール: `/home/git/gitlab/log/auth.log`

このログには、以下の内容が記録されます。

- rawエンドポイントに対する[レート制限](../settings/rate_limits_on_raw_endpoints.md)を超えるリクエスト
- [保護されたパス](../settings/protected_paths.md)に対する不正なリクエスト
- 利用可能な場合は、ユーザーIDとユーザー名

## `auth_json.log`

このファイルは次の場所にあります。

- Linuxパッケージインストール: `/var/log/gitlab/gitlab-rails/auth_json.log`
- 自己コンパイルインストール: `/home/git/gitlab/log/auth_json.log`

このファイルには、`auth.log`のログのJSON形式のバージョンが含まれています。次に例を示します。

```json
{
    "severity":"ERROR",
    "time":"2023-04-19T22:14:25.893Z",
    "correlation_id":"01GYDSAKAN2SPZPAMJNRWW5H8S",
    "message":"Rack_Attack",
    "env":"blocklist",
    "remote_ip":"x.x.x.x",
    "request_method":"GET",
    "path":"/group/project.git/info/refs?service=git-upload-pack"
}
```

## `graphql_json.log`

このファイルは次の場所にあります。

- Linuxパッケージインストール: `/var/log/gitlab/gitlab-rails/graphql_json.log`
- 自己コンパイルインストール: `/home/git/gitlab/log/graphql_json.log`

このファイルには、GraphQLクエリが記録されます。次に例を示します。

```json
{"query_string":"query IntrospectionQuery{__schema {queryType { name },mutationType { name }}}...(etc)","variables":{"a":1,"b":2},"complexity":181,"depth":1,"duration_s":7}
```

## `clickhouse.log`

{{< history >}}

- GitLab 16.5で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/133371)されました。

{{< /history >}}

`clickhouse.log`ファイルには、GitLabの[ClickHouseデータベースクライアント](../../integration/clickhouse.md)に関連する情報が記録されます。

## `migrations.log`

このファイルは次の場所にあります。

- Linuxパッケージインストール: `/var/log/gitlab/gitlab-rails/migrations.log`
- 自己コンパイルインストール: `/home/git/gitlab/log/migrations.log`

このファイルには、[データベースの移行](../raketasks/maintenance.md#display-status-of-database-migrations)の進捗状況が記録されます。

## `mail_room_json.log`（デフォルト）

このファイルは次の場所にあります。

- Linuxパッケージインストール: `/var/log/gitlab/mailroom/current`
- 自己コンパイルインストール: `/home/git/gitlab/log/mail_room_json.log`

この構造化されたログファイルには、`mail_room` gemの内部アクティビティが記録されます。名前とパスは設定可能であるため、名前とパスが上記と一致しない場合があります。

## `web_hooks.log`

{{< history >}}

- GitLab 16.3で導入されました。

{{< /history >}}

このファイルは次の場所にあります。

- Linuxパッケージインストール: `/var/log/gitlab/gitlab-rails/web_hooks.log`
- 自己コンパイルインストール: `/home/git/gitlab/log/web_hooks.log`

このファイルには、Webhookのバックオフ、無効化、再有効化イベントが記録されます。次に例を示します。

```json
{"severity":"INFO","time":"2020-11-24T02:30:59.860Z","hook_id":12,"action":"backoff","disabled_until":"2020-11-24T04:30:59.860Z","backoff_count":2,"recent_failures":2}
{"severity":"INFO","time":"2020-11-24T02:30:59.860Z","hook_id":12,"action":"disable","disabled_until":null,"backoff_count":5,"recent_failures":100}
{"severity":"INFO","time":"2020-11-24T02:30:59.860Z","hook_id":12,"action":"enable","disabled_until":null,"backoff_count":0,"recent_failures":0}
```

## 再設定ログ

Linuxパッケージインストールの場合、再設定ログファイルは`/var/log/gitlab/reconfigure`にあります。自己コンパイルインストールの場合、再設定ログはありません。`gitlab-ctl reconfigure`を手動で実行した場合、またはアップグレードの一部として実行した場合に、再設定ログが記録されます。

再設定ログファイルの名前は、再設定が開始された時点のUNIXタイムスタンプに基づいて付けられます（例: `1509705644.log`）。

## `sidekiq_exporter.log`および`web_exporter.log`

PrometheusメトリクスとSidekiq Exporterの両方が有効になっている場合、SidekiqはWebサーバーを起動し、定義されたポート（デフォルト: `8082`）をリッスンします。デフォルトでは、Sidekiq Exporterのアクセスログは無効になっていますが、有効にすることも可能です。

- Linuxパッケージインストールの場合、`/etc/gitlab/gitlab.rb`で`sidekiq['exporter_log_enabled'] = true`オプションを使用します。
- 自己コンパイルインストールの場合、`gitlab.yml`で`sidekiq_exporter.log_enabled`オプションを使用します。

有効にすると、インストール方法に応じてこのファイルが次の場所に生成されます。

- Linuxパッケージインストール: `/var/log/gitlab/gitlab-rails/sidekiq_exporter.log`
- 自己コンパイルインストール: `/home/git/gitlab/log/sidekiq_exporter.log`

PrometheusメトリクスとWeb Exporterの両方が有効になっている場合、PumaはWebサーバーを起動し、定義されたポート（デフォルト: `8083`）をリッスンします。インストール方法に応じてアクセスログが次の場所に生成されます。

- Linuxパッケージインストール: `/var/log/gitlab/gitlab-rails/web_exporter.log`
- 自己コンパイルインストール: `/home/git/gitlab/log/web_exporter.log`

## `database_load_balancing.log`

{{< details >}}

- プラン: Premium、Ultimate
- 製品:GitLab Self-Managed

{{< /details >}}

GitLabの[データベースロードバランシング](../postgresql/database_load_balancing.md)の詳細が含まれています。このファイルは次の場所にあります。

- Linuxパッケージインストール: `/var/log/gitlab/gitlab-rails/database_load_balancing.log`
- 自己コンパイルインストール: `/home/git/gitlab/log/database_load_balancing.log`

## `zoekt.log`

{{< details >}}

- プラン: Premium、Ultimate
- 製品:GitLab Self-Managed

{{< /details >}}

{{< history >}}

- GitLab 15.9で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/110980)されました。

{{< /history >}}

このファイルには、[完全一致コードの検索](../../user/search/exact_code_search.md)に関連する情報が記録されます。このファイルは次の場所にあります。

- Linuxパッケージインストール: `/var/log/gitlab/gitlab-rails/zoekt.log`
- 自己コンパイルインストール: `/home/git/gitlab/log/zoekt.log`

## `elasticsearch.log`

{{< details >}}

- プラン: Premium、Ultimate
- 製品:GitLab Self-Managed

{{< /details >}}

このファイルには、Elasticsearchのインデックス作成や検索中のエラーなど、Elasticsearchインテグレーションに関連する情報が記録されます。このファイルは次の場所にあります。

- Linuxパッケージインストール: `/var/log/gitlab/gitlab-rails/elasticsearch.log`
- 自己コンパイルインストール: `/home/git/gitlab/log/elasticsearch.log`

各行には、ElasticsearchやSplunkなどのサービスにインジェストできるJSON形式のデータが含まれています。次の例では、可読性を高めるため改行が追加されています。

```json
{
  "severity":"DEBUG",
  "time":"2019-10-17T06:23:13.227Z",
  "correlation_id":null,
  "message":"redacted_search_result",
  "class_name":"Milestone",
  "id":2,
  "ability":"read_milestone",
  "current_user_id":2,
  "query":"project"
}
```

## `exceptions_json.log`

このファイルには、`Gitlab::ErrorTracking`が追跡している例外に関する情報が記録されます。これは、[捕捉された例外を処理](https://gitlab.com/gitlab-org/gitlab/-/blob/master/doc/development/logging.md#exception-handling)するための標準的かつ一貫した方法を提供します。このファイルは次の場所にあります。

- Linuxパッケージインストール: `/var/log/gitlab/gitlab-rails/exceptions_json.log`
- 自己コンパイルインストール: `/home/git/gitlab/log/exceptions_json.log`

各行には、ElasticsearchにインジェストできるJSONが含まれています。次に例を示します。

```json
{
  "severity": "ERROR",
  "time": "2019-12-17T11:49:29.485Z",
  "correlation_id": "AbDVUrrTvM1",
  "extra.project_id": 55,
  "extra.relation_key": "milestones",
  "extra.relation_index": 1,
  "exception.class": "NoMethodError",
  "exception.message": "undefined method `strong_memoize' for #<Gitlab::ImportExport::RelationFactory:0x00007fb5d917c4b0>",
  "exception.backtrace": [
    "lib/gitlab/import_export/relation_factory.rb:329:in `unique_relation?'",
    "lib/gitlab/import_export/relation_factory.rb:345:in `find_or_create_object!'"
  ]
}
```

## `service_measurement.log`

このファイルは次の場所にあります。

- Linuxパッケージインストール: `/var/log/gitlab/gitlab-rails/service_measurement.log`
- 自己コンパイルインストール: `/home/git/gitlab/log/service_measurement.log`

このファイルには、各サービスの実行に関する測定値を含む、単一の構造化ログのみが記録されています。SQL呼び出しの数、`execution_time`、`gc_stats`、`memory usage`などの測定値が含まれています。

次に例を示します。

```json
{ "severity":"INFO", "time":"2020-04-22T16:04:50.691Z","correlation_id":"04f1366e-57a1-45b8-88c1-b00b23dc3616","class":"Projects::ImportExport::ExportService","current_user":"John Doe","project_full_path":"group1/test-export","file_path":"/path/to/archive","gc_stats":{"count":{"before":127,"after":127,"diff":0},"heap_allocated_pages":{"before":10369,"after":10369,"diff":0},"heap_sorted_length":{"before":10369,"after":10369,"diff":0},"heap_allocatable_pages":{"before":0,"after":0,"diff":0},"heap_available_slots":{"before":4226409,"after":4226409,"diff":0},"heap_live_slots":{"before":2542709,"after":2641420,"diff":98711},"heap_free_slots":{"before":1683700,"after":1584989,"diff":-98711},"heap_final_slots":{"before":0,"after":0,"diff":0},"heap_marked_slots":{"before":2542704,"after":2542704,"diff":0},"heap_eden_pages":{"before":10369,"after":10369,"diff":0},"heap_tomb_pages":{"before":0,"after":0,"diff":0},"total_allocated_pages":{"before":10369,"after":10369,"diff":0},"total_freed_pages":{"before":0,"after":0,"diff":0},"total_allocated_objects":{"before":24896308,"after":24995019,"diff":98711},"total_freed_objects":{"before":22353599,"after":22353599,"diff":0},"malloc_increase_bytes":{"before":140032,"after":6650240,"diff":6510208},"malloc_increase_bytes_limit":{"before":25804104,"after":25804104,"diff":0},"minor_gc_count":{"before":94,"after":94,"diff":0},"major_gc_count":{"before":33,"after":33,"diff":0},"remembered_wb_unprotected_objects":{"before":34284,"after":34284,"diff":0},"remembered_wb_unprotected_objects_limit":{"before":68568,"after":68568,"diff":0},"old_objects":{"before":2404725,"after":2404725,"diff":0},"old_objects_limit":{"before":4809450,"after":4809450,"diff":0},"oldmalloc_increase_bytes":{"before":140032,"after":6650240,"diff":6510208},"oldmalloc_increase_bytes_limit":{"before":68537556,"after":68537556,"diff":0}},"time_to_finish":0.12298400001600385,"number_of_sql_calls":70,"memory_usage":"0.0 MiB","label":"process_48616"}
```

## `geo.log`

{{< details >}}

- プラン: Premium、Ultimate
- 製品:GitLab Self-Managed

{{< /details >}}

Geoは、構造化されたログメッセージを`geo.log`ファイルに保存します。Linuxパッケージインストールの場合、このファイルは`/var/log/gitlab/gitlab-rails/geo.log`にあります。

Helmチャートインストールの場合、このファイルはSidekiqポッド内の`/var/log/gitlab/geo.log`に保存されます。このファイルは直接アクセスして読むことも、`kubectl`を使用してSidekiqログをフェッチし、その結果を`"subcomponent"=="geo"`でフィルタリングして読むことも可能です。以下の例では、`jq`を使用してGeoログのみを取得しています。

```shell
kubectl logs -l app=sidekiq --max-log-requests=50 | jq 'select(."subcomponent"=="geo")'
```

このファイルには、Geoがリポジトリおよびファイルの同期を試みたときの情報が含まれています。ファイル内の各行には個別のJSONエントリが含まれており、たとえばElasticsearchやSplunkにインジェストすることができます。

次に例を示します。

```json
{"severity":"INFO","time":"2017-08-06T05:40:16.104Z","message":"Repository update","project_id":1,"source":"repository","resync_repository":true,"resync_wiki":true,"class":"Gitlab::Geo::LogCursor::Daemon","cursor_delay_s":0.038}
```

このメッセージは、Geoがプロジェクト`1`に対してリポジトリの更新が必要であると検出したことを示しています。

## `update_mirror_service_json.log`

このファイルは次の場所にあります。

- Linuxパッケージインストール: `/var/log/gitlab/gitlab-rails/update_mirror_service_json.log`
- 自己コンパイルインストール: `/home/git/gitlab/log/update_mirror_service_json.log`

このファイルには、プロジェクトのミラーリング中に発生したLFSエラーに関する情報が含まれています。他のプロジェクトミラーリングエラーをこのログに移動する作業を進めていますが、それまでは[一般的なログ](#productionlog)を使用できます。

```json
{
   "severity":"ERROR",
   "time":"2020-07-28T23:29:29.473Z",
   "correlation_id":"5HgIkCJsO53",
   "user_id":"x",
   "project_id":"x",
   "import_url":"https://mirror-source/group/project.git",
   "error_message":"The LFS objects download list couldn't be imported. Error: Unauthorized"
}
```

## `llm.log`

{{< details >}}

- プラン: Premium、Ultimate
- 製品:GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 16.0で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/120506)されました。

{{< /history >}}

`llm.log`ファイルには、[AI機能](../../user/ai_features.md)に関連する情報が記録されます。ログには、AIイベントに関する情報が含まれています。

### LLMの入力および出力ログの生成

{{< history >}}

- GitLab 17.2で、`expanded_ai_logging`[フラグ](../feature_flags.md)とともに[導入](https://gitlab.com/groups/gitlab-org/-/epics/13401)されました。デフォルトで無効になっています。

{{< /history >}}

{{< alert type="flag" >}}

この機能の利用可否は、機能フラグによって制御されます。詳細については履歴を参照してください。この機能はテストには使用できますが、本番環境での使用にはまだ対応していません。

{{< /alert >}}

`expanded_ai_logging`機能フラグを有効にすると、LLMのプロンプト入力と応答出力をログに記録できるようになります。このフラグはデフォルトでは無効になっており、次の場合にのみ有効にできます。

- GitLab.comの場合、GitLab[サポートチケット](https://about.gitlab.com/support/portal/)を通じて同意を提供する
- GitLab Self-Managedの場合、この機能フラグを有効にする

デフォルトでは、AI機能データの[データ保持ポリシー](../../user/gitlab_duo/data_usage.md#data-retention)をサポートするため、LLMのプロンプト入力と応答出力はログに含まれません。

ログファイルは次の場所にあります。

- Linuxパッケージインストール: `/var/log/gitlab/gitlab-rails/llm.log`
- 自己コンパイルインストール: `/home/git/gitlab/log/llm.log`

## `epic_work_item_sync.log`

{{< details >}}

- プラン: Premium、Ultimate
- 製品:GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 16.9で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/120506)されました。

{{< /history >}}

`epic_work_item_sync.log`ファイルには、作業アイテムとしてエピックを同期および移行する際の情報が記録されます。

このファイルは次の場所にあります。

- Linuxパッケージインストール: `/var/log/gitlab/gitlab-rails/epic_work_item_sync.log`
- 自己コンパイルインストール: `/home/git/gitlab/log/epic_work_item_sync.log`

## `secret_push_protection.log`

{{< details >}}

- プラン: Ultimate
- 製品:GitLab.com、GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 16.7で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/137812)されました。

{{< /history >}}

`secret_push_protection.log`ファイルには、[シークレットプッシュ保護](../../user/application_security/secret_detection/secret_push_protection/_index.md)機能に関連する情報が記録されます。

このファイルは次の場所にあります。

- Linuxパッケージインストール: `/var/log/gitlab/gitlab-rails/secret_push_protection.log`
- 自己コンパイルインストール: `/home/git/gitlab/log/secret_push_protection.log`

## レジストリのログ

Linuxパッケージインストールの場合、コンテナレジストリのログは`/var/log/gitlab/registry/current`にあります。

## NGINXのログ

Linuxパッケージインストールの場合、NGINXのログは次の場所にあります。

- `/var/log/gitlab/nginx/gitlab_access.log`: GitLabへのリクエストのログ
- `/var/log/gitlab/nginx/gitlab_error.log`: GitLabに関するNGINXエラーのログ
- `/var/log/gitlab/nginx/gitlab_pages_access.log`: Pages静的サイトへのリクエストのログ
- `/var/log/gitlab/nginx/gitlab_pages_error.log`: Pages静的サイトに関するNGINXエラーのログ
- `/var/log/gitlab/nginx/gitlab_registry_access.log`: コンテナレジストリへのリクエストのログ
- `/var/log/gitlab/nginx/gitlab_registry_error.log`: コンテナレジストリに関するNGINXエラーのログ
- `/var/log/gitlab/nginx/gitlab_mattermost_access.log`: Mattermostへのリクエストのログ
- `/var/log/gitlab/nginx/gitlab_mattermost_error.log`: Mattermostに関するNGINXエラーのログ

以下は、デフォルトのGitLab NGINXアクセスログの形式です。

```plaintext
'$remote_addr - $remote_user [$time_local] "$request" $status $body_bytes_sent "$http_referer" "$http_user_agent"'
```

`$request`および`$http_referer`については、シークレットトークンなどの機密性の高いクエリ文字列パラメーターが[フィルタリング](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/support/nginx/gitlab)されます。

## Pagesのログ

Linuxパッケージインストールの場合、Pagesのログは`/var/log/gitlab/gitlab-pages/current`にあります。

次に例を示します。

```json
{
  "level": "info",
  "msg": "GitLab Pages Daemon",
  "revision": "52b2899",
  "time": "2020-04-22T17:53:12Z",
  "version": "1.17.0"
}
{
  "level": "info",
  "msg": "URL: https://gitlab.com/gitlab-org/gitlab-pages",
  "time": "2020-04-22T17:53:12Z"
}
{
  "gid": 998,
  "in-place": false,
  "level": "info",
  "msg": "running the daemon as unprivileged user",
  "time": "2020-04-22T17:53:12Z",
  "uid": 998
}
```

## Let's Encryptのログ

Linuxパッケージインストールの場合、Let's Encryptの[自動更新](https://docs.gitlab.com/omnibus/settings/ssl/#renew-the-certificates-automatically)ログは`/var/log/gitlab/lets-encrypt/`にあります。

## Mattermostのログ

Linuxパッケージインストールの場合、Mattermostのログは次の場所にあります。

- `/var/log/gitlab/mattermost/mattermost.log`
- `/var/log/gitlab/mattermost/current`

## Workhorseのログ

Linuxパッケージインストールの場合、Workhorseのログは`/var/log/gitlab/gitlab-workhorse/current`にあります。

## PgBouncerのログ

Linuxパッケージインストールの場合、PgBouncerのログは`/var/log/gitlab/pgbouncer/current`にあります。

## PostgreSQLのログ

Linuxパッケージインストールの場合、PostgreSQLのログは`/var/log/gitlab/postgresql/current`にあります。

## Prometheusのログ

Linuxパッケージインストールの場合、Prometheusのログは`/var/log/gitlab/prometheus/current`にあります。

## Redisのログ

Linuxパッケージインストールの場合、Redisのログは`/var/log/gitlab/redis/current`にあります。

## Alertmanagerのログ

Linuxパッケージインストールの場合、Alertmanagerのログは`/var/log/gitlab/alertmanager/current`にあります。

<!-- vale gitlab_base.Spelling = NO -->

## crondのログ

Linuxパッケージインストールの場合、crondのログは`/var/log/gitlab/crond/`にあります。

<!-- vale gitlab_base.Spelling = YES -->

## Grafanaのログ

Linuxパッケージインストールの場合、Grafanaのログは`/var/log/gitlab/grafana/current`にあります。

## LogRotateのログ

Linuxパッケージインストールの場合、`logrotate`のログは`/var/log/gitlab/logrotate/current`にあります。

## GitLab Monitorのログ

Linuxパッケージインストールの場合、GitLab Monitorのログは`/var/log/gitlab/gitlab-monitor/`にあります。

## GitLab Exporter

Linuxパッケージインストールの場合、GitLab Exporterのログは`/var/log/gitlab/gitlab-exporter/current`にあります。

## GitLabエージェントサーバー

Linuxパッケージインストールの場合、GitLabエージェントサーバーのログは`/var/log/gitlab/gitlab-kas/current`にあります。

## Praefectのログ

Linuxパッケージインストールの場合、Praefectのログは`/var/log/gitlab/praefect/`にあります。

GitLabは、[PraefectのPrometheusメトリクス](../gitaly/monitoring.md#monitor-gitaly-cluster)も追跡します。

## バックアップのログ

Linuxパッケージインストールの場合、バックアップのログは`/var/log/gitlab/gitlab-rails/backup_json.log`にあります。

Helmチャートインストールの場合、バックアップのログはToolboxポッド内の`/var/log/gitlab/backup_json.log`に保存されます。

このログは、[GitLabのバックアップが作成された](../backup_restore/_index.md)ときに記録されます。このログを使用して、バックアッププロセスの実行状況を把握できます。

## パフォーマンスバーの統計

このファイルは次の場所にあります。

- Linuxパッケージインストール: `/var/log/gitlab/gitlab-rails/performance_bar_json.log`
- 自己コンパイルインストール: `/home/git/gitlab/log/performance_bar_json.log`

このファイルには、パフォーマンスバーの統計（現在はSQLクエリの所要時間のみ）が記録されます。次に例を示します。

```json
{"severity":"INFO","time":"2020-12-04T09:29:44.592Z","correlation_id":"33680b1490ccd35981b03639c406a697","filename":"app/models/ci/pipeline.rb","method_path":"app/models/ci/pipeline.rb:each_with_object","request_id":"rYHomD0VJS4","duration_ms":26.889,"count":2,"query_type": "active-record"}
```

これらの統計は.comでのみ記録され、セルフデプロイでは無効になっています。

## ログを収集する

前述のいずれかのコンポーネントに限定されない問題を[トラブルシューティング](../troubleshooting/_index.md)する場合、GitLabインスタンスから複数のログや統計を同時に収集すると役立ちます。

{{< alert type="note" >}}

GitLabサポートはこれらの情報の提供を要求することが多く、そのために必要なツールを用意しています。

{{< /alert >}}

### メインログを短時間のみ追跡する

バグやエラーを容易に再現できる場合は、問題を数回再現しながら、GitLabのメインログを[ファイルに](../troubleshooting/linux_cheat_sheet.md#files-and-directories)保存します。

```shell
sudo gitlab-ctl tail | tee /tmp/<case-ID-and-keywords>.log
```

<kbd>Control</kbd> + <kbd>C</kbd>でログ収集を終了します。

### GitLabSOS

パフォーマンスの低下や、前述のGitLabコンポーネントのいずれに起因するのか容易に特定できない連鎖的なエラーが発生した場合、[GitLabSOS](https://gitlab.com/gitlab-com/support/toolbox/gitlabsos/)は、GitLabインスタンスをより広い視点で把握する手がかりとなります。詳細および実行手順については、[GitLabSOSのドキュメント](https://gitlab.com/gitlab-com/support/toolbox/gitlabsos/#gitlabsos)を参照してください。

### Fast-stats

[Fast-stats](https://gitlab.com/gitlab-com/support/toolbox/fast-stats)は、GitLabログからパフォーマンス統計を作成および比較するためのツールです。詳細および実行手順については、[fast-statsのドキュメント](https://gitlab.com/gitlab-com/support/toolbox/fast-stats#usage)を参照してください。

## 相関IDを使用して関連するログエントリを検索する

ほとんどのリクエストには、[関連するログエントリの特定](tracing_correlation_id.md)に使用できるログIDがあります。
