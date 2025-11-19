---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: "`jq` を使用したGitLabログの解析"
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

可能な限り、KibanaやSplunkのようなログ集計および検索ツールを使用することをお勧めしますが、利用できない場合は、[GitLabログ](_index.md)を[`jq`](https://stedolan.github.io/jq/)でJSON形式で解析できます。

{{< alert type="note" >}}

特に、エラーイベントと基本的な使用状況統計を要約するために、GitLabサポートチームは特殊な[`fast-stats`ツール](https://gitlab.com/gitlab-com/support/toolbox/fast-stats/#when-to-use-it)を提供しています。

{{< /alert >}}

## JQとは？ {#what-is-jq}

[マニュアル](https://stedolan.github.io/jq/manual/)に記載されているように、`jq`はコマンドラインJSONプロセッサーです。次の例では、GitLabログファイルを解析するためのユースケースが含まれています。

## ログの解析 {#parsing-logs}

以下に示す例では、それぞれのログファイルが、それぞれのLinuxパッケージインストールパスとデフォルトのファイル名で示されています。それぞれのフルパスは、[GitLabログ](_index.md#production_jsonlog)のセクションにあります。

### 圧縮ログ {#compressed-logs}

[ログファイルがローテーションされる](https://smarden.org/runit/svlogd.8)と、Unixタイムスタンプ形式で名前が変更され、`gzip`で圧縮されます。結果のファイル名は`@40000000624492fa18da6f34.s`のようになります。これらのファイルは、より新しいログファイルよりも前に解析する前に、異なる方法で処理する必要があります:

- ファイルを解凍するには、`gunzip -S .s @40000000624492fa18da6f34.s`を使用して、ファイル名を圧縮ログファイルの名前に置き換えます。
- ファイルを直接読み取るか、パイプ処理するには、`zcat`または`zless`を使用します。
- ファイルの内容を検索するには、`zgrep`を使用します。

### 一般的なコマンド {#general-commands}

#### 色分けされた`jq`出力を`less`にパイプ処理します {#pipe-colorized-jq-output-into-less}

```shell
jq . <FILE> -C | less -R
```

#### 用語を検索して、一致するすべての行をpretty印刷します {#search-for-a-term-and-pretty-print-all-matching-lines}

```shell
grep <TERM> <FILE> | jq .
```

#### JSONの無効な行をスキップする {#skip-invalid-lines-of-json}

```shell
jq -cR 'fromjson?' file.json | jq <COMMAND>
```

デフォルトでは、`jq`は有効なJSONではない行を検出するとエラーになります。これにより、無効な行はすべてスキップされ、残りが解析されます。

#### JSONログの時間範囲を印刷する {#print-a-json-logs-time-range}

```shell
cat log.json | (head -1; tail -1) | jq '.time'
```

ファイルがローテーションおよび圧縮されている場合は、`zcat`を使用します:

```shell
zcat @400000006026b71d1a7af804.s | (head -1; tail -1) | jq '.time'

zcat some_json.log.25.gz | (head -1; tail -1) | jq '.time'
```

#### 時系列順に複数のJSONログにわたる相関IDのアクティビティーを取得する {#get-activity-for-correlation-id-across-multiple-json-logs-in-chronological-order}

```shell
grep -hR <correlationID> | jq -c -R 'fromjson?' | jq -C -s 'sort_by(.time)'  | less -R
```

### `gitlab-rails/production_json.log`および`gitlab-rails/api_json.log`の解析 {#parsing-gitlab-railsproduction_jsonlog-and-gitlab-railsapi_jsonlog}

#### 5XXステータスコードのすべてのリクエストを検索する {#find-all-requests-with-a-5xx-status-code}

```shell
jq 'select(.status >= 500)' <FILE>
```

#### 上位10件の最も遅いリクエスト {#top-10-slowest-requests}

```shell
jq -s 'sort_by(-.duration_s) | limit(10; .[])' <FILE>
```

#### プロジェクトに関連するすべてのリクエストを検索して、pretty印刷する {#find-and-pretty-print-all-requests-related-to-a-project}

```shell
grep <PROJECT_NAME> <FILE> | jq .
```

#### 合計期間が5秒を超えるすべてのリクエストを検索する {#find-all-requests-with-a-total-duration--5-seconds}

```shell
jq 'select(.duration_s > 5000)' <FILE>
```

#### 5回を超えるGitaly呼び出しがあるすべてのプロジェクトリクエストを検索する {#find-all-project-requests-with-more-than-5-gitaly-calls}

```shell
grep <PROJECT_NAME> <FILE> | jq 'select(.gitaly_calls > 5)'
```

#### Gitalyの期間が10秒を超えるすべてのリクエストを検索する {#find-all-requests-with-a-gitaly-duration--10-seconds}

```shell
jq 'select(.gitaly_duration_s > 10000)' <FILE>
```

#### キューの期間が10秒を超えるすべてのリクエストを検索する {#find-all-requests-with-a-queue-duration--10-seconds}

```shell
jq 'select(.queue_duration_s > 10000)' <FILE>
```

#### Gitaly呼び出しの＃による上位10件のリクエスト {#top-10-requests-by--of-gitaly-calls}

```shell
jq -s 'map(select(.gitaly_calls != null)) | sort_by(-.gitaly_calls) | limit(10; .[])' <FILE>
```

#### 特定の時間範囲を出力する {#output-a-specific-time-range}

```shell
jq 'select(.time >= "2023-01-10T00:00:00Z" and .time <= "2023-01-10T12:00:00Z")' <FILE>
```

### `gitlab-rails/production_json.log`の解析 {#parsing-gitlab-railsproduction_jsonlog}

#### リクエストボリュームによる上位3つのコントローラーメソッドと、それらの3つの最長期間を印刷する {#print-the-top-three-controller-methods-by-request-volume-and-their-three-longest-durations}

```shell
jq -s -r 'group_by(.controller+.action) | sort_by(-length) | limit(3; .[]) | sort_by(-.duration_s) | "CT: \(length)\tMETHOD: \(.[0].controller)#\(.[0].action)\tDURS: \(.[0].duration_s),  \(.[1].duration_s),  \(.[2].duration_s)"' production_json.log
```

**出力例**

```plaintext
CT: 2721   METHOD: SessionsController#new  DURS: 844.06,  713.81,  704.66
CT: 2435   METHOD: MetricsController#index DURS: 299.29,  284.01,  158.57
CT: 1328   METHOD: Projects::NotesController#index DURS: 403.99,  386.29,  384.39
```

### `gitlab-rails/api_json.log`の解析 {#parsing-gitlab-railsapi_jsonlog}

#### リクエスト数と3つの最長期間を含む上位3つのルートを印刷する {#print-top-three-routes-with-request-count-and-their-three-longest-durations}

```shell
jq -s -r 'group_by(.route) | sort_by(-length) | limit(3; .[]) | sort_by(-.duration_s) | "CT: \(length)\tROUTE: \(.[0].route)\tDURS: \(.[0].duration_s),  \(.[1].duration_s),  \(.[2].duration_s)"' api_json.log
```

**出力例**

```plaintext
CT: 2472 ROUTE: /api/:version/internal/allowed   DURS: 56402.65,  38411.43,  19500.41
CT: 297  ROUTE: /api/:version/projects/:id/repository/tags       DURS: 731.39,  685.57,  480.86
CT: 190  ROUTE: /api/:version/projects/:id/repository/commits    DURS: 1079.02,  979.68,  958.21
```

#### 上位APIユーザーエージェントを印刷する {#print-top-api-user-agents}

```shell
jq --raw-output '
  select(.remote_ip != "127.0.0.1") | [
    (.time | split(".")[0] | strptime("%Y-%m-%dT%H:%M:%S") | strftime("…%m-%dT%H…")),
    ."meta.caller_id", .username, .ua
  ] | @tsv' api_json.log | sort | uniq -c \
  | grep --invert-match --extended-regexp '^\s+\d{1,3}\b'
```

**出力例**:

```plaintext
 1234 …01-12T01…  GET /api/:version/projects/:id/pipelines  some_user  # plus browser details; OK
54321 …01-12T01…  POST /api/:version/projects/:id/repository/files/:file_path/raw  some_bot
 5678 …01-12T01…  PATCH /api/:version/jobs/:id/trace gitlab-runner     # plus version details; OK
```

この例は、カスタムツールまたはスクリプトが、予期しない高い[リクエストレート（>15 RPS）](../reference_architectures/_index.md#available-reference-architectures)をGitalyで引き起こしていることを示しています。この状況のユーザーエージェントは、特殊な[サードパーティクライアント](../../api/rest/third_party_clients.md)、または`curl`のような一般的なツールである可能性があります。

毎時の集計は、以下に役立ちます:

- [Prometheus](../monitoring/prometheus/_index.md)のようなモニタリングツールからのデータに、ボットまたはユーザーアクティビティーのスパイクを関連付けます。
- [レート制限](../settings/user_and_ip_rate_limits.md)を評価します。

これらのユーザーまたはボットのパフォーマンス統計を抽出するには、`fast-stats top` （ページ上部を参照）を使用することもできます。

### `gitlab-rails/importer.log`の解析 {#parsing-gitlab-railsimporterlog}

[プロジェクトのインポート](../raketasks/project_import_export.md)または[移行](../../user/project/import/_index.md)をトラブルシューティングするには、次のコマンドラインを実行します:

```shell
jq 'select(.project_path == "<namespace>/<project>").error_messages' importer.log
```

一般的な問題については、[トラブルシューティング](../raketasks/import_export_rake_tasks_troubleshooting.md)を参照してください。

### `gitlab-workhorse/current`の解析 {#parsing-gitlab-workhorsecurrent}

#### 上位のWorkhorseユーザーエージェントを印刷する {#print-top-workhorse-user-agents}

```shell
jq --raw-output '
  select(.remote_ip != "127.0.0.1") | [
    (.time | split(".")[0] | strptime("%Y-%m-%dT%H:%M:%S") | strftime("…%m-%dT%H…")),
    .remote_ip, .uri, .user_agent
  ] | @tsv' current |
  sort | uniq -c
```

[API `ua`の例](#print-top-api-user-agents)と同様に、この出力で予期しないユーザーエージェントが多数ある場合は、最適化されていないスクリプトを示しています。予期されるユーザーエージェントには、`gitlab-runner`、`GitLab-Shell`、およびブラウザーが含まれます。

[`check_interval`設定](https://docs.gitlab.com/runner/configuration/advanced-configuration.html#the-global-section)を増やすことで、新しいジョブをチェックするRunnerのパフォーマンスへの影響を軽減できます。

### `gitlab-rails/geo.log`の解析 {#parsing-gitlab-railsgeolog}

#### 最も一般的なGeo同期エラーを検索する {#find-most-common-geo-sync-errors}

[`geo:status` Rakeタスク](../geo/replication/troubleshooting/common.md#sync-status-rake-task)が、一部のアイテムが100%に達しないことを繰り返しレポートする場合は、次のコマンドラインを実行すると、最も一般的なエラーに焦点を当てることができます。

```shell
jq --raw-output 'select(.severity == "ERROR") | [
  (.time | split(".")[0] | strptime("%Y-%m-%dT%H:%M:%S") | strftime("…%m-%dT%H:%M…")),
  .class, .id, .message, .error
  ] | @tsv' geo.log \
  | sort | uniq -c
```

特定のエラーメッセージに関するアドバイスについては、[Geoトラブルシューティングページ](../geo/replication/troubleshooting/_index.md)を参照してください。

### `gitaly/current`の解析 {#parsing-gitalycurrent}

次の例を使用して、[Gitalyのトラブルシューティング](../gitaly/troubleshooting.md)を行います。

#### ウェブUIから送信されたすべてのGitalyリクエストを検索する {#find-all-gitaly-requests-sent-from-web-ui}

```shell
jq 'select(."grpc.meta.client_name" == "gitlab-web")' current
```

#### 失敗したすべてのGitalyリクエストを検索する {#find-all-failed-gitaly-requests}

```shell
jq 'select(."grpc.code" != null and ."grpc.code" != "OK")' current
```

#### 30秒以上かかったすべてのリクエストを検索する {#find-all-requests-that-took-longer-than-30-seconds}

```shell
jq 'select(."grpc.time_ms" > 30000)' current
```

#### リクエストボリュームによる上位10件のプロジェクトと、それらの3つの最長期間を印刷する {#print-top-ten-projects-by-request-volume-and-their-three-longest-durations}

```shell
jq --raw-output --slurp '
  map(
    select(
      ."grpc.request.glProjectPath" != null
      and ."grpc.request.glProjectPath" != ""
      and ."grpc.time_ms" != null
    )
  )
  | group_by(."grpc.request.glProjectPath")
  | sort_by(-length)
  | limit(10; .[])
  | sort_by(-."grpc.time_ms")
  | [
      length,
      .[0]."grpc.time_ms",
      .[1]."grpc.time_ms",
      .[2]."grpc.time_ms",
      .[0]."grpc.request.glProjectPath"
    ]
  | @sh' current |
  awk 'BEGIN { printf "%7s %10s %10s %10s\t%s\n", "CT", "MAX DURS", "", "", "PROJECT" }
  { printf "%7u %7u ms, %7u ms, %7u ms\t%s\n", $1, $2, $3, $4, $5 }'
```

**出力例**

```plaintext
   CT    MAX DURS                              PROJECT
  206    4898 ms,    1101 ms,    1032 ms      'groupD/project4'
  109    1420 ms,     962 ms,     875 ms      'groupEF/project56'
  663     106 ms,      96 ms,      94 ms      'groupABC/project123'
  ...
```

#### ユーザーとプロジェクトのアクティビティーの概要 {#types-of-user-and-project-activity-overview}

```shell
jq --raw-output '[
    (.time | split(".")[0] | strptime("%Y-%m-%dT%H:%M:%S") | strftime("…%m-%dT%H…")),
    .username, ."grpc.method", ."grpc.request.glProjectPath"
  ] | @tsv' current | sort | uniq -c \
  | grep --invert-match --extended-regexp '^\s+\d{1,3}\b'
```

**出力例**:

```plaintext
 5678 …01-12T01…     ReferenceTransactionHook  # Praefect operation; OK
54321 …01-12T01…  some_bot   GetBlobs    namespace/subgroup/project
 1234 …01-12T01…  some_user  FindCommit  namespace/subgroup/project
```

この例は、カスタムツールまたはスクリプトが、Gitalyで予期しない高い[リクエストレート（>15 RPS）](../reference_architectures/_index.md#available-reference-architectures)を引き起こしていることを示しています。毎時の集計は、以下に役立ちます:

- [Prometheus](../monitoring/prometheus/_index.md)のようなモニタリングツールからのデータに、ボットまたはユーザーアクティビティーのスパイクを関連付けます。
- [レート制限](../settings/user_and_ip_rate_limits.md)を評価します。

これらのユーザーまたはボットのパフォーマンス統計を抽出するには、`fast-stats top` （ページ上部を参照）を使用することもできます。

#### 致命的なGitの問題の影響を受けるすべてのプロジェクトを検索する {#find-all-projects-affected-by-a-fatal-git-problem}

```shell
grep "fatal: " current |
  jq '."grpc.request.glProjectPath"' |
  sort | uniq
```

### `gitlab-shell/gitlab-shell.log`の解析 {#parsing-gitlab-shellgitlab-shelllog}

SSH経由でのGit呼び出しを調査する場合。

プロジェクトとユーザーごとの上位20件の呼び出しを検索します:

```shell
jq --raw-output --slurp '
  map(
    select(
      .username != null and
      .gl_project_path !=null
    )
  )
  | group_by(.username+.gl_project_path)
  | sort_by(-length)
  | limit(20; .[])
  | "count: \(length)\tuser: \(.[0].username)\tproject: \(.[0].gl_project_path)" ' \
  gitlab-shell.log
```

プロジェクト、ユーザー、およびコマンドごとの上位20件の呼び出しを検索します:

```shell
jq --raw-output --slurp '
  map(
    select(
      .command  != null and
      .username != null and
      .gl_project_path !=null
    )
  )
  | group_by(.username+.gl_project_path+.command)
  | sort_by(-length)
  | limit(20; .[])
  | "count: \(length)\tcommand: \(.[0].command)\tuser: \(.[0].username)\tproject: \(.[0].gl_project_path)" ' \
  gitlab-shell.log
```
