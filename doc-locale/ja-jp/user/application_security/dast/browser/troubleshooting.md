---
type: reference, howto
stage: Application Security Testing
group: Dynamic Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: DASTスキャンのトラブルシューティング
---

以下のトラブルシューティングのシナリオは、カスタマーサポートチケットから収集されたものです。ここに記載されていない問題が発生した場合、またはここに記載されている情報で問題が解決しない場合は、サポートチケットを作成してください。詳細については、[GitLabサポート](https://about.gitlab.com/support/)のページをご覧ください。

## 問題が発生した場合 {#when-something-goes-wrong}

DASTスキャンで問題が発生した場合、特定のエラーメッセージが表示された場合は、[既知の問題](#known-problems)を確認してください。

それ以外の場合は、次の質問に答えて問題を特定してください:

- [期待される結果は何ですか？](#what-is-the-expected-outcome)
- [その結果は人間が達成できますか？](#is-the-outcome-achievable-by-a-human)
- [DASTが機能しない理由は何ですか？](#any-reason-why-dast-would-not-work)
- [アプリケーションはどのように動作しますか？](#how-does-your-application-work)
- [DASTは何をしていますか？](#what-is-dast-doing)

### 期待される結果は何ですか？ {#what-is-the-expected-outcome}

DASTスキャンで問題が発生した多くのユーザーは、スキャナーが何をすべきかを大まかに把握しています。たとえば、特定ページのスキャンがされなかったり、ページ上のボタンが選択されなかったりします。

可能な限り問題を特定し、解決策の検索を絞り込んでください。たとえば、DASTが特定のページをスキャンしていない状況を考えてみましょう。DASTはどこからページを見つけるべきでしたか？そこにたどり着くまでにどのようなパスをたどりましたか？DASTが選択すべきだったのに、選択しなかった参照ページに要素はありましたか？

### その結果は人間が達成できますか？ {#is-the-outcome-achievable-by-a-human}

人間が手動でアプリケーションを移動できない場合、DASTスキャンはアプリケーションをスキャンできません。

期待される結果を把握したら、お使いのマシンでブラウザーを使用して手動でレプリケートしてみてください。例: 

- 新しいシークレット/プライベートブラウザウィンドウを開きます。
- 開発者ツールを開きます。コンソールでエラーメッセージに注意してください。
  - Chromeの場合: `View -> Developer -> Developer Tools`。
  - Firefoxの場合: `Tools -> Browser Tools -> Web Developer Tools`。
- 認証する場合:
  - `DAST_AUTH_URL`にアクセスします。
  - `DAST_AUTH_USERNAME_FIELD`の`DAST_AUTH_USERNAME`に入力します。
  - `DAST_AUTH_PASSWORD_FIELD`の`DAST_AUTH_PASSWORD`に入力します。
  - `DAST_AUTH_SUBMIT_FIELD`を選択します。
- リンクを選択し、フォームに入力します。正しくスキャンされないページに移動します。
- アプリケーションがどのように動作するかを観察します。自動スキャナーで問題が発生する可能性のあるものがあるかどうかを確認します。

### DASTが機能しない理由は何ですか？ {#any-reason-why-dast-would-not-work}

DASTは、次の場合に正しくスキャンできません:

- CAPTCHAがある。スキャン対象のアプリケーションのテスト環境でこれらをオフにします。
- ターゲットアプリケーションへのアクセス権がない。GitLab RunnerがDAST設定で使用されているURLを使用してアプリケーションにアクセスできることを確認します。

### アプリケーションはどのように動作しますか？ {#how-does-your-application-work}

アプリケーションの動作方法を理解することは、DASTスキャンが機能しない理由を解明するために不可欠です。たとえば、次の状況では、追加の設定が必要になる場合があります。

- 要素を隠すポップアップモーダルはありますか？
- 読み込まれたページは、一定期間後に大幅に変化しますか？
- アプリケーションの読み込みが特に遅いか速いですか？
- ターゲットアプリケーションは読み込み中に不安定ですか？
- アプリケーションは、クライアントの場所に基づいて異なる動作をしますか？
- アプリケーションはシングルページアプリケーションですか？
- アプリケーションはHTMLフォームを送信しますか、それともJavaScriptとAJAXを使用しますか？
- アプリケーションはウェブソケットを使用しますか？
- アプリケーションは特定のWebフレームワークを使用しますか？
- ボタンを選択すると、フォームの送信を続行する前にJavaScriptが実行されますか？速いですか、遅いですか？
- 要素またはページが準備できる前に、DASTが要素を選択または検索している可能性はありますか？

### DASTは何をしていますか？ {#what-is-dast-doing}

{{< history >}}

- 簡潔なログはGitLab [18.3](https://gitlab.com/gitlab-org/gitlab/-/issues/553625)で導入されました。

{{< /history >}}

ジョブログ（CI/CDジョブログ）は、DASTが行っていることの簡潔な要約を提供します。より詳細な診断情報については、詳細な出力を生成するようにログファイルを設定できます。

次のログオプションを使用できます:

- [診断ログ](#diagnostic-logs)。アナライザーが何をしているかを理解するのに役立ちます。
- [Chromium DevToolsロギング](#chromium-devtools-logging)。DASTとChromium間の通信を検査するのに役立ちます。
- [Chromiumログ](#chromium-logs)。Chromiumが予期せずクラッシュした場合にエラーを記録するのに役立ちます。

## 診断ログ {#diagnostic-logs}

アナライザーのログファイルを使用して、スキャンの問題を診断します。アナライザーのさまざまな部分をさまざまなログレベルで記録できます。

### ログメッセージ形式 {#log-message-format}

ログメッセージの形式は`[time] [log level] [log module] [message] [additional properties]`です。

たとえば、次のログエントリのログレベルは`INFO`で、`CRAWL`ログモジュールの一部であり、メッセージ`Crawled path`と追加のプロパティ`nav_id`および`path`があります。

```plaintext
2021-04-21T00:34:04.000 INF CRAWL Crawled path nav_id=0cc7fd path="LoadURL [https://my.site.com:8090]"
```

### ログの宛先 {#log-destination}

ログはログファイルアーティファクトに送信されます。環境変数`DAST_LOG_FILE_CONFIG`を使用して、各宛先が異なるログを受け入れるように設定できます。例: 

```yaml
include:
  - template: DAST.gitlab-ci.yml

dast:
  variables:
    DAST_BROWSER_SCAN: "true"
    DAST_LOG_FILE_CONFIG: "loglevel:debug,cache:warn"           # file log defaults to DEBUG level, logs CACHE module at WARN
```

デフォルトでは、ファイルログは`gl-dast-scan.log`というジョブアーティファクトです。[このパスを設定する](configuration/variables.md)には、`DAST_LOG_FILE_PATH` CI/CD変数を変更します。

### ログレベル {#log-levels}

設定できるログレベルは次のとおりです:

| ログモジュール              | コンポーネントの概要                                                       | 詳細                             |
|-------------------------|--------------------------------------------------------------------------|----------------------------------|
| `TRACE`                 | 特定の機能の、多くの場合ノイズの多い内部動作に使用されます。              |                                  |
| `DEBUG`                 | 機能の内部動作について説明します。診断の目的で使用されます。 |                                  |
| `INFO`                  | スキャンの高度な流れと結果について説明します。               | 何も指定されていない場合のデフォルトレベル。 |
| `WARN`                  | DASTが回復してスキャンを続行するエラー状況について説明します。 |                                  |
| `FATAL``ERROR``PANIC` | 終了前の回復不能なエラーについて説明します。                            |                                  |

### ログモジュール {#log-modules}

`LOGLEVEL`ログファイルの宛先のデフォルトのログレベルを設定します。次のモジュールのいずれかが設定されている場合、DASTは、そのモジュールのログレベルをデフォルトのログレベルよりも優先して使用します。

ロギング用に設定できるモジュールは次のとおりです:

| ログモジュール | コンポーネントの概要                                                                                |
|------------|---------------------------------------------------------------------------------------------------|
| `ACTIV`    | アクティブな攻撃に使用されます。                                                                          |
| `AUTH`     | 認証されたスキャンを作成するために使用されます。                                                          |
| `BPOOL`    | クローラー用にリースアウトされているブラウザーのセット。                                             |
| `BROWS`    | ブラウザーの状態またはページをクエリするために使用されます。                                               |
| `CACHE`    | キャッシュされたHTTPリソースのキャッシュヒットとミスをレポートするために使用されます。                               |
| `CHROM`    | Chrome DevToolsメッセージをログに記録するために使用されます。                                                             |
| `CONFG`    | アナライザーの設定をログに記録するために使用されます。                                                           |
| `CONTA`    | DevToolsメッセージからHTTPリクエストとレスポンスの一部を収集するコンテナに使用されます。 |
| `CRAWL`    | コアクローラーアルゴリズムに使用されます。                                                              |
| `CRWLG`    | クロールグラフジェネレーターに使用されます。                                                               |
| `DATAB`    | データを内部データベースに保持するために使用されます。                                                |
| `LEASE`    | ブラウザーを作成してブラウザプールに追加するために使用されます。                                          |
| `MAIN`     | クローラーのメインイベントループのフローに使用されます。                                          |
| `NAVDB`    | ナビゲーションエントリを保存するための永続化メカニズムに使用されます。                                      |
| `REGEX`    | 正規表現の実行時にパフォーマンス統計を記録するために使用されます。                       |
| `REPT`     | レポートを生成するために使用されます。                                                                      |
| `STAT`     | スキャンの実行中の一般的な統計に使用されます。                                               |
| `VLDFN`    | 脆弱性定義を読み込み、解析中に使用されます。                                           |
| `WEBGW`    | アクティブチェックの実行時に、ターゲットアプリケーションに送信されるメッセージをログに記録するために使用されます。                   |
| `SCOPE`    | [スコープ管理](configuration/customize_settings.md#managing-scope)に関連するメッセージをログに記録するために使用されます。 |

### SECURE_LOG_LEVEL {#secure_log_level}

{{< history >}}

- GitLab 17.11で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/524632)されました。

{{< /history >}}

`DAST_LOG_FILE_CONFIG`でログモジュールを設定するより簡単な代替手段として、`SECURE_LOG_LEVEL`を設定できます:

- [サポートされているログレベル](#log-levels)のいずれか。これを行うと、指定されたレベルが、すべてのモジュールのログファイルのデフォルトのログレベルになります。
- [認証レポート](configuration/authentication.md#configure-the-authentication-report)を有効にするには、`debug`または`trace`に設定します。
- [DevToolsロギング](#chromium-devtools-logging)を有効にするには、`trace`に設定します。

例: 

```yaml
include:
  - template: DAST.gitlab-ci.yml

dast:
  variables:
    SECURE_LOG_LEVEL: "trace"
    # is equivalent to:
    # DAST_LOG_FILE_CONFIG: "loglevel:trace"
    # DAST_LOG_DEVTOOLS_CONFIG: "Default:messageAndBody,truncate:2000"
    # DAST_AUTH_REPORT: "true"
```

`DAST_LOG_FILE_CONFIG`、`DAST_LOG_DEVTOOLS_CONFIG`、`DAST_AUTH_REPORT`の設定は、`SECURE_LOG_LEVEL`の設定をオーバーライドします。

### 例 - クロールされたパスのログ {#example---log-crawled-paths}

スキャンのクロールフェーズ中に検出されたナビゲーションパスをログに記録するには、ログモジュール`CRAWL`を`DEBUG`に設定します。これは、DASTがターゲットアプリケーションを正しくクロールしているかどうかを理解するのに役立ちます。

```yaml
include:
  - template: DAST.gitlab-ci.yml

dast:
  variables:
    DAST_LOG_CONFIG: "crawl:debug"
```

たとえば、次の出力は、`https://example.com`のページをクロール中に検出された4つのアンカーリンクを示しています。

```plaintext
2022-11-17T11:18:05.578 DBG CRAWL executing step nav_id=6ec647d8255c729160dd31cb124e6f89 path="LoadURL [https://example.com]" step=1
...
2022-11-17T11:18:11.900 DBG CRAWL found new navigations browser_id=2243909820020928961 nav_count=4 nav_id=6ec647d8255c729160dd31cb124e6f89 of=1 step=1
2022-11-17T11:18:11.901 DBG CRAWL adding navigation action="LeftClick [a href=/page1.html]" nav=bd458cc1fc2d7c6fb984464b6d968866 parent_nav=6ec647d8255c729160dd31cb124e6f89
2022-11-17T11:18:11.901 DBG CRAWL adding navigation action="LeftClick [a href=/page2.html]" nav=6dcb25f9f9ece3ee0071ac2e3166d8e6 parent_nav=6ec647d8255c729160dd31cb124e6f89
2022-11-17T11:18:11.901 DBG CRAWL adding navigation action="LeftClick [a href=/page3.html]" nav=89efbb0c6154d6c6d85a63b61a7cdc6f parent_nav=6ec647d8255c729160dd31cb124e6f89
2022-11-17T11:18:11.901 DBG CRAWL adding navigation action="LeftClick [a href=/page4.html]" nav=f29b4f4e0bdee70f5255de7fc080f04d parent_nav=6ec647d8255c729160dd31cb124e6f89
```

## Chromium DevToolsロギング {#chromium-devtools-logging}

{{< alert type="warning" >}}

DevToolsメッセージをログに記録することは、セキュリティリスクです。出力には、ユーザー名、パスワード、認証トークンなどのシークレットが含まれています。この出力はGitLabサーバーにアップロードされ、ジョブログに表示される可能性があります。

{{< /alert >}}

DASTブラウザーベースのスキャナーは、[Chrome DevToolsプロトコル](https://chromedevtools.github.io/devtools-protocol/)を使用してChromiumブラウザーをオーケストレーションを行うします。DevToolsメッセージをログに記録すると、ブラウザーが行っていることの透明性を高めることができます。たとえば、ボタンの選択が機能しない場合、DevToolsメッセージは、ブラウザコンソールログのCORSエラーが原因であることを示す場合があります。DevToolsメッセージを含むログは、サイズが非常に大きくなる可能性があります。このため、期間の短いジョブでのみ有効にする必要があります。

すべてのDevToolsメッセージをログに記録するには、`CHROM`ログモジュールを`trace`に切り替え、ログレベルを設定します。次に、DevToolsログの例を示します:

```plaintext
2022-12-05T06:27:24.280 TRC CHROM event received    {"method":"Fetch.requestPaused","params":{"requestId":"interception-job-3.0","request":{"url":"http://auth-auto:8090/font-awesome.min.css","method":"GET","headers":{"Accept":"text/css,*/*;q=0.1","Referer":"http://auth-auto:8090/login.html","User-Agent":"Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/105.0.5195.102 Safari/537.36"},"initialPriority":"VeryHigh","referrerPolicy":"strict-origin-when-cross-origin"},"frameId":"A706468B01C2FFAA2EB6ED365FF95889","resourceType":"Stylesheet","networkId":"39.3"}} method=Fetch.requestPaused
2022-12-05T06:27:24.280 TRC CHROM request sent      {"id":47,"method":"Fetch.continueRequest","params":{"requestId":"interception-job-3.0","headers":[{"name":"Accept","value":"text/css,*/*;q=0.1"},{"name":"Referer","value":"http://auth-auto:8090/login.html"},{"name":"User-Agent","value":"Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/105.0.5195.102 Safari/537.36"}]}} id=47 method=Fetch.continueRequest
2022-12-05T06:27:24.281 TRC CHROM response received {"id":47,"result":{}} id=47 method=Fetch.continueRequest
```

### DevToolsログレベルのカスタマイズ {#customizing-devtools-log-levels}

Chrome DevToolsのリクエスト、レスポンス、およびイベントは、ドメインによって名前空間が設定されています。DASTでは、各ドメインとメッセージを含む各ドメインに異なるロギング設定を持たせることができます。環境変数`DAST_LOG_DEVTOOLS_CONFIG`は、セミコロンで区切られたロギング設定のリストを受け入れます。ロギング設定は、構造`[domain/message]:[what-to-log][,truncate:[max-message-size]]`を使用して宣言されます。

- `domain/message`は、ログに記録されているものを参照します。
  - `Default`は、すべてのドメインとメッセージを表す値として使用できます。
  - たとえば、`Browser`、`CSS`、`Page`、`Network`などのドメインを指定できます。
  - たとえば、`Network.responseReceived`などのメッセージを含むドメインを指定できます。
  - 複数の設定が適用される場合は、最も具体的な設定が使用されます。
- `what-to-log`は、ログに記録するかどうか、および何をログに記録するかを参照します。
  - `message`は、メッセージが受信されたことをログに記録し、メッセージの内容はログに記録しません。
  - `messageAndBody`は、メッセージの内容を含むメッセージをログに記録します。`truncate`と一緒に使用することをお勧めします。
  - `suppress`はメッセージをログに記録しません。ノイズの多いドメインとメッセージを抑制するために使用されます。
- `truncate`は、印刷されるメッセージのサイズを制限するためのオプションの設定です。

### 例 - すべてのDevToolsメッセージをログに記録する {#example---log-all-devtools-messages}

どこから始めればよいかわからない場合に、すべてをログに記録するために使用されます。

```yaml
include:
  - template: DAST.gitlab-ci.yml

dast:
  variables:
    DAST_LOG_FILE_CONFIG: "chrom:trace"
    DAST_LOG_DEVTOOLS_CONFIG: "Default:messageAndBody,truncate:2000"
```

### 例 - HTTPメッセージをログに記録する {#example---log-http-messages}

リソースが正しく読み込みされない場合に役立ちます。HTTPメッセージイベントがログに記録されます。また、リクエストを続行するか、失敗させるかの決定もログに記録されます。ブラウザコンソールのエラーもログに記録されます。

```yaml
include:
  - template: DAST.gitlab-ci.yml

dast:
  variables:
    DAST_LOG_FILE_CONFIG: "chrom:trace"
    DAST_LOG_DEVTOOLS_CONFIG: "Default:suppress;Fetch:messageAndBody,truncate:2000;Network:messageAndBody,truncate:2000;Log:messageAndBody,truncate:2000;Console:messageAndBody,truncate:2000"
```

### ジョブコンソールの出力をオーバーライドする {#override-the-job-console-output}

デフォルトでは、ジョブコンソールにDASTアクティビティーの簡潔な概要が表示されます。ジョブコンソールに完全な診断ログを出力するには、`DAST_FF_DIAGNOSTIC_JOB_OUTPUT`と`DAST_LOG_CONFIG`の変数の両方を設定します:

```yaml
include:
  - template: DAST.gitlab-ci.yml

dast:
  variables:
    DAST_FF_DIAGNOSTIC_JOB_OUTPUT: "true"
    DAST_LOG_CONFIG: "crawl:debug"                               # console log defaults to INFO level, logs AUTH module at DEBUG
```

[イシュー552171](https://gitlab.com/gitlab-org/gitlab/-/issues/552171)は、GitLab 19.0でこのオプションを削除することを提案しています。

## Chromiumログ {#chromium-logs}

まれにChromiumがクラッシュした場合、Chromiumプロセスの`STDOUT`と`STDERR`をログに書き込むと役立つことがあります。環境変数`DAST_LOG_BROWSER_OUTPUT`を`true`に設定すると、この目的が達成されます。

DASTは多数のChromiumプロセスを開始および停止します。DASTは、各プロセス出力を、ログモジュール`LEASE`とログレベル`INFO`を使用して、すべてのログ宛先に送信します。

例: 

```yaml
include:
  - template: DAST.gitlab-ci.yml

dast:
  variables:
    DAST_LOG_BROWSER_OUTPUT: "true"
```

## 既知の問題 {#known-problems}

### ログに`response body exceeds allowed size`が含まれています {#logs-contain-response-body-exceeds-allowed-size}

デフォルトでは、DASTはHTTPレスポンスボディが10MB以下のHTTPリクエストを処理します。そうでない場合、DASTはレスポンスをブロックし、スキャンが失敗する可能性があります。この制約は、スキャン中のメモリ消費量を削減することを目的としています。

ログの例を次に示します。ここでは、DASTが`https://example.com/large.js`にあるJavaScriptファイルをブロックしました。これは、サイズが制限よりも大きいためです:

```plaintext
2022-12-05T06:28:43.093 WRN BROWS response body exceeds allowed size allowed_size_bytes=1000000 browser_id=752944257619431212 nav_id=ae23afe2acbce2c537657a9112926f1a of=1 request_id=interception-job-2.0 response_size_bytes=9333408 step=1 url=https://example.com/large.js
2022-12-05T06:28:58.104 WRN CONTA request failed, attempting to continue scan error=net::ERR_BLOCKED_BY_RESPONSE index=0 requestID=38.2 url=https://example.com/large.js
```

これは、設定`DAST_PAGE_MAX_RESPONSE_SIZE_MB`を使用して変更できます。例: 

```yaml
dast:
  variables:
    DAST_PAGE_MAX_RESPONSE_SIZE_MB: "25"
```

### クローラーが目的のページに到達しない {#crawler-doesnt-reach-expected-pages}

#### キャッシュの無効化を試してください {#try-disabling-the-cache}

DASTがアプリケーションページを誤ってキャッシュすると、DASTがアプリケーションを適切にクロールできなくなる可能性があります。一部のページがクローラーによって予期せず見つからない場合は、`DAST_USE_CACHE: "false"`変数を設定して、それが役立つかどうかを確認してください。これにより、スキャンのパフォーマンスが大幅に低下する可能性があります。キャッシュは絶対に必要な場合にのみ無効にしてください。サブスクリプションをお持ちの場合は、キャッシュがWebサイトのクロールを妨げている理由を調査するために、[サポートチケットを作成してください](https://about.gitlab.com/support/)。

#### ターゲットパスを直接指定する {#specifying-target-paths-directly}

クローラーは通常、定義されたターゲットURLから開始し、サイトと対話してさらにページを見つけようとします。ただし、クローラーが開始するパスを直接指定する方法が2つあります:

- sitemap.xmlを使用する: [Sitemap](https://www.sitemaps.org/protocol.html)は、Webサイトのページを指定するための適切なプロトコルです。DASTのクローラーは、`<target URL>/sitemap.xml`でsitemap.xmlファイルを検索し、指定されたすべてのURLをクローラーの開始ポイントとして使用します。[Sitemap Index](https://www.sitemaps.org/protocol.html#index)ファイルはサポートされていません。
- `DAST_TARGET_PATHS`を使用します: この変数を使用すると、クローラーの入力パスを指定できます。例: `DAST_TARGET_PATHS: /,/page/1.html,/page/2.html`。

#### リクエストがブロックされていないことを確認してください {#make-sure-requests-are-not-getting-blocked}

デフォルトでは、DASTはターゲットURLのドメインへのリクエストのみを許可します。Webサイトがターゲット以外のドメインにリクエストを送信する場合は、`DAST_SCOPE_ALLOW_HOSTS`を使用して、そのようなホストを指定します。例: 「example.com」は、認証トークンを更新するために「auth.example.com」に認証リクエストを送信します。ドメインが許可されていないため、リクエストはブロックされ、クローラーは新しいページを見つけることができません。
