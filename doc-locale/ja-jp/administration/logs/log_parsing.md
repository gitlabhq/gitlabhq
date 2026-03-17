---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: jqによるGitLabログの解析
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

KibanaやSplunkなどのログ集計検索ツールを可能な限り使用することをおすすめしますが、これらのツールが利用できない場合でも、[GitLabログ](_index.md)をJSON形式で[`jq`](https://stedolan.github.io/jq/)を使用して素早く解析できます。

> [!note]
> 特にエラーイベントと基本的な使用統計を要約するために、GitLabサポートチームは専門の[`fast-stats`ツール](https://gitlab.com/gitlab-com/support/toolbox/fast-stats/#when-to-use-it)を提供しています。通常、`jq`よりもはるかに高速に大規模なログを処理でき、より広範な統計出力を提供します。

## JQとは何ですか？ {#what-is-jq}

[マニュアル](https://stedolan.github.io/jq/manual/)に記載されているように、`jq`はコマンドラインのJSONプロセッサーです。次の例は、GitLabログファイルの解析を対象としたユースケースを含んでいます。

## ログの解析 {#parsing-logs}

以下に挙げる例は、それぞれのログファイルを相対的なLinuxパッケージのインストールパスとデフォルトファイル名で扱います。それぞれの完全なパスは、[GitLabログのセクション](_index.md#production_jsonlog)にあります。

### 圧縮されたログ {#compressed-logs}

[ログファイルがローテーションされる](https://smarden.org/runit/svlogd.8)と、Unixタイムスタンプ形式に名前が変更され、`gzip`で圧縮されます。結果のファイル名は`@40000000624492fa18da6f34.s`のようになります。これらのファイルは、より新しいログファイルとは異なり、解析前に異なる方法で処理する必要があります:

- ファイルを解凍するには、`gunzip -S .s @40000000624492fa18da6f34.s`を使用し、ファイル名を圧縮されたログファイルの名前に置き換えます。
- ファイルを直接読み取りまたはパイプするには、`zcat`または`zless`を使用します。
- ファイルの内容を検索するには、`zgrep`を使用します。

### 一般的なコマンド {#general-commands}

#### 色付けされた`jq`出力を`less`へパイプする {#pipe-colorized-jq-output-into-less}

```shell
jq . <FILE> -C | less -R
```

#### 用語を検索し、一致するすべての行をprettyプリントする {#search-for-a-term-and-pretty-print-all-matching-lines}

```shell
grep <TERM> <FILE> | jq .
```

#### 無効なJSON行をスキップする {#skip-invalid-lines-of-json}

```shell
jq -cR 'fromjson?' file.json | jq <COMMAND>
```

デフォルトでは、`jq`は有効なJSONではない行に遭遇するとエラーを出力します。これにより、すべての無効な行をスキップし、残りを解析することができます。

#### JSONログのタイムレンジを出力する {#print-a-json-logs-time-range}

```shell
cat log.json | (head -1; tail -1) | jq '.time'
```

ファイルがローテーションおよび圧縮されている場合は、`zcat`を使用します:

```shell
zcat @400000006026b71d1a7af804.s | (head -1; tail -1) | jq '.time'

zcat some_json.log.25.gz | (head -1; tail -1) | jq '.time'
```

#### 複数のJSONログ全体で相関IDのアクティビティを時系列順に取得する {#get-activity-for-correlation-id-across-multiple-json-logs-in-chronological-order}

```shell
grep -hR <correlationID> | jq -c -R 'fromjson?' | jq -C -s 'sort_by(.time)'  | less -R
```

### `gitlab-rails/production_json.log`および`gitlab-rails/api_json.log`の解析 {#parsing-gitlab-railsproduction_jsonlog-and-gitlab-railsapi_jsonlog}

#### 5XXステータスコードを持つすべてのリクエストを検索する {#find-all-requests-with-a-5xx-status-code}

```shell
jq 'select(.status >= 500)' <FILE>
```

#### 最も遅いリクエスト上位10件 {#top-10-slowest-requests}

```shell
jq -s 'sort_by(-.duration_s) | limit(10; .[])' <FILE>
```

#### プロジェクトに関連するすべてのリクエストを検索し、prettyプリントする {#find-and-pretty-print-all-requests-related-to-a-project}

```shell
grep <PROJECT_NAME> <FILE> | jq .
```

#### 合計処理時間が5秒を超えるすべてのリクエストを検索する {#find-all-requests-with-a-total-duration--5-seconds}

```shell
jq 'select(.duration_s > 5000)' <FILE>
```

#### Gitaly呼び出しが5回を超えるすべてのプロジェクトリクエストを検索する {#find-all-project-requests-with-more-than-5-gitaly-calls}

```shell
grep <PROJECT_NAME> <FILE> | jq 'select(.gitaly_calls > 5)'
```

#### Gitaly処理時間が10秒を超えるすべてのリクエストを検索する {#find-all-requests-with-a-gitaly-duration--10-seconds}

```shell
jq 'select(.gitaly_duration_s > 10000)' <FILE>
```

#### キュー処理時間が10秒を超えるすべてのリクエストを検索する {#find-all-requests-with-a-queue-duration--10-seconds}

```shell
jq 'select(.queue_duration_s > 10000)' <FILE>
```

#### Gitaly呼び出し数によるリクエスト上位10件 {#top-10-requests-by--of-gitaly-calls}

```shell
jq -s 'map(select(.gitaly_calls != null)) | sort_by(-.gitaly_calls) | limit(10; .[])' <FILE>
```

#### 特定の時間範囲を出力する {#output-a-specific-time-range}

```shell
jq 'select(.time >= "2023-01-10T00:00:00Z" and .time <= "2023-01-10T12:00:00Z")' <FILE>
```

### `gitlab-rails/production_json.log`の解析 {#parsing-gitlab-railsproduction_jsonlog}

#### リクエスト量で上位3つのコントローラーメソッドと、それらの3つの最長処理時間を表示する {#print-the-top-three-controller-methods-by-request-volume-and-their-three-longest-durations}

```shell
jq -s -r 'group_by(.controller+.action) | sort_by(-length) | limit(3; .[]) | sort_by(-.duration_s) | "CT: \(length)\tMETHOD: \(.[0].controller)#\(.[0].action)\tDURS: \(.[0].duration_s),  \(.[1].duration_s),  \(.[2].duration_s)"' production_json.log
```

**出力例**

```plaintext
CT: 2721   METHOD: SessionsController#new  DURS: 844.06,  713.81,  704.66
CT: 2435   METHOD: MetricsController#index DURS: 299.29,  284.01,  158.57
CT: 1328   METHOD: Projects::NotesController#index DURS: 403.99,  386.29,  384.39
```

または、[`fast-stats`](https://gitlab.com/gitlab-com/support/toolbox/fast-stats)を使用します:

```shell
fast-stats --verbose --limit=3 production_json.log
```

### `gitlab-rails/api_json.log`の解析 {#parsing-gitlab-railsapi_jsonlog}

#### リクエスト数と最長処理時間トップ3を持つルートを上位3つ表示する {#print-top-three-routes-with-request-count-and-their-three-longest-durations}

```shell
jq -s -r 'group_by(.route) | sort_by(-length) | limit(3; .[]) | sort_by(-.duration_s) | "CT: \(length)\tROUTE: \(.[0].route)\tDURS: \(.[0].duration_s),  \(.[1].duration_s),  \(.[2].duration_s)"' api_json.log
```

**出力例**

```plaintext
CT: 2472 ROUTE: /api/:version/internal/allowed   DURS: 56402.65,  38411.43,  19500.41
CT: 297  ROUTE: /api/:version/projects/:id/repository/tags       DURS: 731.39,  685.57,  480.86
CT: 190  ROUTE: /api/:version/projects/:id/repository/commits    DURS: 1079.02,  979.68,  958.21
```

または、[`fast-stats`](https://gitlab.com/gitlab-com/support/toolbox/fast-stats)を使用します:

```shell
fast-stats --verbose --limit=3 api_json.log
```

#### 上位APIユーザーエージェントを表示する {#print-top-api-user-agents}

```shell
jq --raw-output '
  select(.remote_ip != "127.0.0.1") | [
    (.time | split(".")[0] | strptime("%Y-%m-%dT%H:%M:%S") | strftime("…%m-%dT%H…")),
    ."meta.caller_id", .username, .ua
  ] | @tsv' api_json.log | sort | uniq -c \
  | grep --invert-match --extended-regexp '^\s+\d{1,3}\b'
```

**Example output**:

```plaintext
 1234 …01-12T01…  GET /api/:version/projects/:id/pipelines  some_user  # plus browser details; OK
54321 …01-12T01…  POST /api/:version/projects/:id/repository/files/:file_path/raw  some_bot
 5678 …01-12T01…  PATCH /api/:version/jobs/:id/trace gitlab-runner     # plus version details; OK
```

この例は、カスタムツールまたはスクリプトが予期せず高い[リクエストレート（>15 RPS）](../reference_architectures/_index.md#available-reference-architectures)を引き起こしていることを示しています。このような状況でのユーザーエージェントは、専門の[サードパーティクライアント](../../api/rest/third_party_clients.md)や、`curl`のような一般的なツールである可能性があります。

時間ごとの集計は、次の目的に役立ちます:

- ボットまたはユーザーのアクティビティの急増を、[Prometheus](../monitoring/prometheus/_index.md)などのモニタリングツールからのデータと関連付けます。
- [レート制限設定](../settings/user_and_ip_rate_limits.md)を評価します。

`jq`と並行して、[`fast-stats top`](https://gitlab.com/gitlab-com/support/toolbox/fast-stats/-/blob/main/README.md#top)を使用して、それらのユーザーとボットのパフォーマンスへの影響を確認します:

```shell
fast-stats top --display=percentage --sort-by=cpu-s api_json.log
```

高いリクエスト頻度だけでは自動的に問題にはなりませんが、いずれかのリソースの大部分を使用することは問題です。

### `gitlab-rails/importer.log`の解析 {#parsing-gitlab-railsimporterlog}

[プロジェクトのインポート](../raketasks/project_import_export.md)または[移行](../../user/import/_index.md)のトラブルシューティングを行うには、このコマンドを実行します:

```shell
jq 'select(.project_path == "<namespace>/<project>").error_messages' importer.log
```

一般的な問題については、[トラブルシューティング](../raketasks/import_export_rake_tasks_troubleshooting.md)を参照してください。

### `gitlab-workhorse/current`の解析 {#parsing-gitlab-workhorsecurrent}

#### 上位のWorkhorseユーザーエージェントを表示する {#print-top-workhorse-user-agents}

```shell
jq --raw-output '
  select(.remote_ip != "127.0.0.1") | [
    (.time | split(".")[0] | strptime("%Y-%m-%dT%H:%M:%S") | strftime("…%m-%dT%H…")),
    .remote_ip, .uri, .user_agent
  ] | @tsv' current |
  sort | uniq -c
```

[API`ua`の例](#print-top-api-user-agents)と同様に、この出力に予期せぬ多くのユーザーエージェントがある場合、スクリプトが最適化されていないことを示します。期待されるユーザーエージェントには、`gitlab-runner`、`GitLab-Shell`、およびブラウザが含まれます。

たとえば、Runnerが新しいジョブをチェックする際のパフォーマンスへの影響は、[`check_interval`設定](https://docs.gitlab.com/runner/configuration/advanced-configuration/#the-global-section)を増やすことで軽減できます。

### `gitlab-rails/geo.log`の解析 {#parsing-gitlab-railsgeolog}

#### 最も一般的なGeoの同期エラーを検索する {#find-most-common-geo-sync-errors}

もし[`geo:status` Rakeタスク](../geo/replication/troubleshooting/common.md#sync-status-rake-task)が、一部の項目が100%に達しないと繰り返し報告する場合、以下のコマンドは最も一般的なエラーに焦点を当てるのに役立ちます。

```shell
jq --raw-output 'select(.severity == "ERROR") | [
  (.time | split(".")[0] | strptime("%Y-%m-%dT%H:%M:%S") | strftime("…%m-%dT%H:%M…")),
  .class, .id, .message, .error
  ] | @tsv' geo.log \
  | sort | uniq -c
```

特定のエラーメッセージに関するアドバイスについては、[弊社のGeoトラブルシューティングページ](../geo/replication/troubleshooting/_index.md)を参照してください。

### `gitaly/current`の解析 {#parsing-gitalycurrent}

以下の例を使用して、[Gitalyのトラブルシューティングを行う](../gitaly/troubleshooting.md)ことができます。

#### Web UIから送信されたすべてのGitalyリクエストを検索する {#find-all-gitaly-requests-sent-from-web-ui}

```shell
jq 'select(."grpc.meta.client_name" == "gitlab-web")' current
```

#### すべての失敗したGitalyリクエストを検索する {#find-all-failed-gitaly-requests}

```shell
jq 'select(."grpc.code" != null and ."grpc.code" != "OK")' current
```

#### 30秒以上かかったすべてのリクエストを検索する {#find-all-requests-that-took-longer-than-30-seconds}

```shell
jq 'select(."grpc.time_ms" > 30000)' current
```

#### リクエスト量で上位10のプロジェクトと、それらの3つの最長処理時間を表示する {#print-top-ten-projects-by-request-volume-and-their-three-longest-durations}

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

または、[`fast-stats`](https://gitlab.com/gitlab-com/support/toolbox/fast-stats)を使用します:

```shell
fast-stats top --sort-by=duration current
```

#### ユーザーとプロジェクトのアクティビティの種類の概要 {#types-of-user-and-project-activity-overview}

```shell
jq --raw-output '[
    (.time | split(".")[0] | strptime("%Y-%m-%dT%H:%M:%S") | strftime("…%m-%dT%H…")),
    .username, ."grpc.method", ."grpc.request.glProjectPath"
  ] | @tsv' current | sort | uniq -c \
  | grep --invert-match --extended-regexp '^\s+\d{1,3}\b'
```

**Example output**:

```plaintext
 5678 …01-12T01…     ReferenceTransactionHook  # Praefect operation; OK
54321 …01-12T01…  some_bot   GetBlobs    namespace/subgroup/project
 1234 …01-12T01…  some_user  FindCommit  namespace/subgroup/project
```

この例は、カスタムツールまたはスクリプトがGitaly上で予期せぬ高い[リクエストレート（>15 RPS）](../reference_architectures/_index.md#available-reference-architectures)を引き起こしていることを示しています。時間ごとの集計は、次の目的に役立ちます:

- ボットまたはユーザーのアクティビティの急増を、[Prometheus](../monitoring/prometheus/_index.md)などのモニタリングツールからのデータと関連付けます。
- [レート制限設定](../settings/user_and_ip_rate_limits.md)を評価します。

`jq`と並行して、[`fast-stats top`](https://gitlab.com/gitlab-com/support/toolbox/fast-stats/-/blob/main/README.md#top)を使用して、それらのユーザーとボットのパフォーマンスへの影響を確認します:

```shell
fast-stats top --display=percentage --sort-by=cpu-s current
```

高いリクエスト頻度だけでは自動的に問題にはなりませんが、いずれかのリソースの大部分を使用することは問題です。

#### 致命的なGitの問題によって影響を受けるすべてのプロジェクトを検索する {#find-all-projects-affected-by-a-fatal-git-problem}

```shell
grep "fatal: " current |
  jq '."grpc.request.glProjectPath"' |
  sort | uniq
```

### `gitlab-shell/gitlab-shell.log`の解析 {#parsing-gitlab-shellgitlab-shelllog}

SSHを介したGit呼び出しの調査用。

プロジェクトとユーザー別の呼び出し上位20件を検索する:

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

プロジェクト、ユーザー、およびコマンド別の呼び出し上位20件を検索する:

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
