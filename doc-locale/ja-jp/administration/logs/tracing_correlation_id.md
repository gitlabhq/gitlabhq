---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: 相関IDを使用して関連するログエントリを検索する
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

ほとんどのリクエストに対し、GitLabインスタンスは一意のリクエスト追跡ID（「correlation ID」と呼ばれる）をログに記録します。GitLabへの個々のリクエストはそれぞれ独自のcorrelation IDを取得し、そのリクエストのために、各GitLabコンポーネントのログに記録されます。これにより、分散システムでの動作の追跡が容易になります。このIDがないと、相関するログエントリを一致させるのが難しいか、不可能になる可能性があります。

## リクエストのcorrelation IDを特定する {#identify-the-correlation-id-for-a-request}

Correlation IDは、構造化ログの`correlation_id`キーの下、および`x-request-id`ヘッダーの下でGitLabが送信するすべての応答ヘッダーに記録されます。どちらかの場所で検索することにより、correlation IDを見つけることができます。

### ブラウザーでcorrelation IDを取得する {#getting-the-correlation-id-in-your-browser}

ブラウザの開発者ツールを使用して、アクセスしているサイトでのネットワークアクティビティーをモニタリングおよび検査できます。一般的なブラウザのネットワークモニタリングのドキュメントについては、以下のリンクを参照してください。

- [ネットワークモニター - Firefox開発ツール](https://firefox-source-docs.mozilla.org/devtools-user/network_monitor/index.html)
- [Chrome DevToolsでネットワークアクティビティーを検査する](https://developer.chrome.com/docs/devtools/network/)
- [Safari Web開発ツール](https://developer.apple.com/safari/tools/)
- [Microsoftエッジネットワークパネル](https://learn.microsoft.com/en-us/microsoft-edge/devtools-guide-chromium/network/)

関連するリクエストを見つけて、そのcorrelation IDを表示するには、次の手順を実行します:

1. ネットワークモニターで永続的なログ記録を有効にします。GitLabでの一部のアクションは、フォームを送信するとすぐにリダイレクトされるため、これにより、関連するすべてのアクティビティーをキャプチャできます。
1. 探しているリクエストを分離するために、`document`リクエストをフィルタリングできます。
1. 詳細を表示するには、目的のリクエストを選択します。
1. **ヘッダー**セクションに移動し、**Response Headers**（レスポンスヘッダー）を探します。そこに、`x-request-id`ヘッダーがあり、リクエストのためにGitLabによってランダムに生成された値があります。

次の例を見てください:

![HTMLドキュメントのネットワークリクエスト詳細のヘッダーセクションにある相関IDの例](img/network_monitor_xid_v13_6.png)

### ログからcorrelation IDを取得する {#getting-the-correlation-id-from-your-logs}

正しいcorrelation IDを見つけるためのもう1つのアプローチは、ログを検索または監視し、監視しているログエントリの`correlation_id`値を見つけることです。

たとえば、GitLabでアクションを再現するときに何が起こっているか、または壊れているかを把握したい場合は、GitLabログを追跡し、ユーザーごとのリクエストをフィルタリングして、目的のものが見つかるまでリクエストを監視します。

### cURLからcorrelation IDを取得する {#getting-the-correlation-id-from-curl}

`curl`を使用している場合は、詳細オプションを使用して、リクエストと応答ヘッダー、およびその他のデバッグ情報を表示できます。

```shell
➜  ~ curl --verbose "https://gitlab.example.com/api/v4/projects"
# look for a line that looks like this
< x-request-id: 4rAMkV3gof4
```

#### jqを使用する {#using-jq}

この例では、[jq](https://stedolan.github.io/jq/)を使用して結果をフィルタリングし、最も重要な値を表示します。

```shell
sudo gitlab-ctl tail gitlab-rails/production_json.log | jq 'select(.username == "bob") | "User: \(.username), \(.method) \(.path), \(.controller)#\(.action), ID: \(.correlation_id)"'
```

```plaintext
"User: bob, GET /root/linux, ProjectsController#show, ID: U7k7fh6NpW3"
"User: bob, GET /root/linux/commits/master/signatures, Projects::CommitsController#signatures, ID: XPIHpctzEg1"
"User: bob, GET /root/linux/blob/master/README, Projects::BlobController#show, ID: LOt9hgi1TV4"
```

#### grepを使用する {#using-grep}

この例では、`grep`と`tr`のみを使用します。`jq`よりもインストールされている可能性が高くなります。

```shell
sudo gitlab-ctl tail gitlab-rails/production_json.log | grep '"username":"bob"' | tr ',' '\n' | egrep 'method|path|correlation_id'
```

```plaintext
{"method":"GET"
"path":"/root/linux"
"username":"bob"
"correlation_id":"U7k7fh6NpW3"}
{"method":"GET"
"path":"/root/linux/commits/master/signatures"
"username":"bob"
"correlation_id":"XPIHpctzEg1"}
{"method":"GET"
"path":"/root/linux/blob/master/README"
"username":"bob"
"correlation_id":"LOt9hgi1TV4"}
```

## ログでcorrelation IDを検索する {#searching-your-logs-for-the-correlation-id}

correlation IDを取得したら、関連するログエントリの検索を開始できます。行をcorrelation ID自体でフィルタリングできます。`find`と`grep`を組み合わせると、探しているエントリを見つけるのに十分です。

```shell
# find <gitlab log directory> -type f -mtime -0 exec grep '<correlation ID>' '{}' '+'
find /var/log/gitlab -type f -mtime 0 -exec grep 'LOt9hgi1TV4' '{}' '+'
```

```plaintext
/var/log/gitlab/gitlab-workhorse/current:{"correlation_id":"LOt9hgi1TV4","duration_ms":2478,"host":"gitlab.domain.tld","level":"info","method":"GET","msg":"access","proto":"HTTP/1.1","referrer":"https://gitlab.domain.tld/root/linux","remote_addr":"68.0.116.160:0","remote_ip":"[filtered]","status":200,"system":"http","time":"2019-09-17T22:17:19Z","uri":"/root/linux/blob/master/README?format=json\u0026viewer=rich","user_agent":"Mozilla/5.0 (Mac) Gecko Firefox/69.0","written_bytes":1743}
/var/log/gitlab/gitaly/current:{"correlation_id":"LOt9hgi1TV4","grpc.code":"OK","grpc.meta.auth_version":"v2","grpc.meta.client_name":"gitlab-web","grpc.method":"FindCommits","grpc.request.deadline":"2019-09-17T22:17:47Z","grpc.request.fullMethod":"/gitaly.CommitService/FindCommits","grpc.request.glProjectPath":"root/linux","grpc.request.glRepository":"project-1","grpc.request.repoPath":"@hashed/6b/86/6b86b273ff34fce19d6b804eff5a3f5747ada4eaa22f1d49c01e52ddb7875b4b.git","grpc.request.repoStorage":"default","grpc.request.topLevelGroup":"@hashed","grpc.service":"gitaly.CommitService","grpc.start_time":"2019-09-17T22:17:17Z","grpc.time_ms":2319.161,"level":"info","msg":"finished streaming call with code OK","peer.address":"@","span.kind":"server","system":"grpc","time":"2019-09-17T22:17:19Z"}
/var/log/gitlab/gitlab-rails/production_json.log:{"method":"GET","path":"/root/linux/blob/master/README","format":"json","controller":"Projects::BlobController","action":"show","status":200,"duration":2448.77,"view":0.49,"db":21.63,"time":"2019-09-17T22:17:19.800Z","params":[{"key":"viewer","value":"rich"},{"key":"namespace_id","value":"root"},{"key":"project_id","value":"linux"},{"key":"id","value":"master/README"}],"remote_ip":"[filtered]","user_id":2,"username":"bob","ua":"Mozilla/5.0 (Mac) Gecko Firefox/69.0","queue_duration":3.38,"gitaly_calls":1,"gitaly_duration":0.77,"rugged_calls":4,"rugged_duration_ms":28.74,"correlation_id":"LOt9hgi1TV4"}
```

### 分散アーキテクチャでの検索 {#searching-in-distributed-architectures}

GitLabインフラストラクチャで水平方向のスケーリングを行った場合は、すべてのGitLabノードを検索する必要があります。これは、Loki、ELK、Splunkなどのログ集計ソフトウェアを使用して行うことができます。

AnsibleやPSSH（パラレルSSH）などのツールを使用して、サーバー間で同一のコマンドを並行して実行したり、独自のソリューションを作成したりできます。

### パフォーマンスバーでリクエストを表示する {#viewing-the-request-in-the-performance-bar}

[パフォーマンスバー](../monitoring/performance/performance_bar.md)を使用して、SQLおよびGitalyへの呼び出しなど、興味深いデータを表示できます。

データを表示するには、リクエストのcorrelation IDが、パフォーマンスバーを表示しているユーザーと同じセッションと一致する必要があります。APIリクエストの場合、これは、認証済みユーザーのセッションクッキーを使用してリクエストを実行する必要があることを意味します。

たとえば、次のAPIエンドポイントに対して実行されたデータベースクエリを表示するとします:

```shell
https://gitlab.com/api/v4/groups/2564205/projects?with_security_reports=true&page=1&per_page=1
```

まず、**Developer Tools**（開発者ツール）パネルを有効にします。これを行う方法の詳細については、[ブラウザでcorrelation IDを取得する](#getting-the-correlation-id-in-your-browser)を参照してください。

開発者ツールが有効になったら、次のようにセッションクッキーを取得します:

1. ログインした状態で<https://gitlab.com>にアクセスします。
1. オプション。**Fetch/XHR**リクエストフィルターを**Developer Tools**（開発者ツール）パネルで選択します。この手順は、Google Chrome開発者ツールについて説明されており、厳密には必須ではありません。これにより、正しいリクエストを簡単に見つけることができます。
1. 左側の`results?request_id=<some-request-id>`リクエストを選択します。
1. セッションクッキーは、`Request Headers`パネルの`Headers`ヘッダーセクションの下に表示されます。クッキー値を右クリックして、`Copy value`を選択します。

![ブラウザの開発者ツールパネルでセッションクッキーを表示する](img/obtaining-a-session-cookie-for-request_v14_3.png)

セッションクッキーの値がクリップボードにコピーされました。例:

```shell
experimentation_subject_id=<subject-id>; _gitlab_session=<session-id>; event_filter=all; visitor_id=<visitor-id>; perf_bar_enabled=true; sidebar_collapsed=true; diff_view=inline; sast_entry_point_dismissed=true; auto_devops_settings_dismissed=true; cf_clearance=<cf-clearance>; collapsed_gutter=false
```

セッションクッキーの値を使用して、`curl`リクエストのカスタムヘッダーに貼り付けることにより、APIリクエストを作成します:

```shell
$ curl --include "https://gitlab.com/api/v4/groups/2564205/projects?with_security_reports=true&page=1&per_page=1" \
--header 'cookie: experimentation_subject_id=<subject-id>; _gitlab_session=<session-id>; event_filter=all; visitor_id=<visitor-id>; perf_bar_enabled=true; sidebar_collapsed=true; diff_view=inline; sast_entry_point_dismissed=true; auto_devops_settings_dismissed=true; cf_clearance=<cf-clearance>; collapsed_gutter=false'

  date: Tue, 28 Sep 2021 03:55:33 GMT
  content-type: application/json
  ...
  x-request-id: 01FGN8P881GF2E5J91JYA338Y3
  ...
  [
    {
      "id":27497069,
      "description":"Analyzer for images used on live K8S containers based on Starboard"
    },
    "container_registry_image_prefix":"registry.gitlab.com/gitlab-org/security-products/analyzers/cluster-image-scanning",
    "..."
  ]
```

レスポンスには、APIエンドポイントからのデータと、[correlation IDを特定する](#identify-the-correlation-id-for-a-request)セクションで説明されているように、`x-request-id`ヘッダーで返される`correlation_id`値が含まれています。

次に、このリクエストのデータベースの詳細を表示できます:

1. [パフォーマンスバー](../monitoring/performance/performance_bar.md)の`request details`フィールドに`x-request-id`値を貼り付け、<kbd>Enter/Return</kbd>を押します。この例では、前の応答によって返された`x-request-id`値`01FGN8P881GF2E5J91JYA338Y3`を使用します:

   ![値を含むパフォーマンスバーのリクエスト詳細フィールド](img/paste-request-id-into-progress-bar_v14_3.png)

1. 新しいリクエストは、パフォーマンスバーの右側にある`Request Selector`ドロップダウンリストに挿入されます。新しいリクエストを選択して、APIリクエストのメトリクスを表示します:

   ![開いているリクエストセレクタードロップダウンリストの強調表示されたリクエスト](img/select-request-id-from-request-selector-drop-down-menu_v14_3.png)

1. パフォーマンスバーの`pg`リンクを選択して、APIリクエストによって実行されるデータベースクエリを表示します:

   ![GitLab APIデータベースの詳細:29ミリ秒/ 34クエリ](img/view-pg-details_v14_3.png)

   データベースクエリダイアログが表示されます:

   ![34個のSQLクエリ、29ミリ秒の継続時間、34個のレプリカ、4つのキャッシュ、およびソートオプションを備えたデータベースクエリダイアログ](img/database-query-dialog_v14_3.png)
