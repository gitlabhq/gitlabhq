---
type: reference, howto
stage: Application Security Testing
group: Dynamic Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: DASTスキャンのトラブルシューティング
---

次のトラブルシューティングのシナリオは、カスタマーサポートの事例から収集したものです。ここで対処されていない問題が発生した場合、またはここにある情報で問題が修正されない場合は、サポートチケットを作成してください。詳細については、[GitLab Support](https://support.gitlab.com/)ページを参照してください。

## 問題が発生した場合 {#when-something-goes-wrong}

DASTスキャンで問題が発生した場合:

- DASTを初めてセットアップする場合は、[DASTのセットアップ](#setting-up-dast)を確認してください。
- 特定のメッセージがある場合は、[既知の問題](#known-problems)を確認してください。

それ以外の場合は、次の質問に答えることで問題を発見してみてください:

- [期待される結果は何ですか？](#what-is-the-expected-outcome)
- [その結果は人間によって達成可能ですか？](#is-the-outcome-achievable-by-a-human)
- [DASTが機能しない理由がありますか？](#any-reason-why-dast-would-not-work)
- [アプリケーションはどのように動作しますか？](#how-does-your-application-work)
- [DASTは何をしていますか？](#what-is-dast-doing)

### DASTのセットアップ {#setting-up-dast}

DASTを初めてセットアップするときに、次の問題に遭遇する可能性があります。

#### 設定の検証に失敗しました: 必須フィールドのURLが設定されていません {#configuration-validation-failed-required-field-url-was-not-set}

ターゲットURLを定義せずにDASTテンプレートを含めると、パイプラインは設定の検証中に次のエラーで失敗します:

```plaintext
ERR MAIN  configuration validation failed error="the required field URL was not set"
```

このエラーは、DASTがどのURLをスキャンすべきか認識していないことを示しています。この問題を修正するには、次のいずれかの方法でターゲットURLを定義してください:

- お使いの`.gitlab-ci.yml`ファイルで`DAST_TARGET_URL` CI/CD変数を設定します:

  ```yaml
  stages:
    - dast

  include:
    - template: Security/DAST.gitlab-ci.yml

  dast:
    variables:
      DAST_TARGET_URL: "https://example.com"
  ```

- プロジェクトのルートに`environment_url.txt`ファイルを作成し、ターゲットURLを追加します。動的な環境でアプリケーションをテストするには、この方法を使用してください。

#### Runnerがターゲットアプリケーションに接続できません {#runner-cannot-connect-to-target-application}

Runnerがターゲットアプリケーションに到達できない場合、DASTスキャンは接続エラーで失敗します。これは通常、ネットワークの設定またはファイアウォールの問題が原因で発生します。

DASTは、指定したURLを使用してアプリケーションに接続する必要があります:

- お使いの`DAST_TARGET_URL`または`DAST_AUTH_URL`にポート番号が含まれている場合は、Runnerがその特定のポートにアクセスできることを確認してください。
- URLにポートが指定されていない場合、DASTは標準ポートを使用します:
  - HTTP URLのポート`80` (例: `http://example.com`)。
  - HTTPS URLのポート`443` (例: `https://example.com`)。

接続問題の一般的な原因には、次のものがあります:

- HTTPとHTTPSのコンテンツの混在。お使いのアプリケーションは、HTTPとHTTPSの両方を使用する場合があります。たとえば、ターゲットURLが`http://example.com`であっても、サイトが`https://example.com`からリソースを読み込む場合は、Runnerが両方のポートにアクセスできることを確認してください。
- カスタムポート。アプリケーションが非標準のポートで実行されている場合は、`DAST_TARGET_URL`に含めてください。例: `https://example.com:8443`。
- ファイアウォールルール。アプリケーションがファイアウォールの背後にある場合は、RunnerのIPアドレスからのトラフィックを許可するルールを設定してください。
- 内部ネットワークと外部ネットワーク。Runnerがアプリケーションに到達できるネットワーク上にあることを確認してください。たとえば、内部ネットワークのステージング環境でテストする場合は、同じネットワーク上のRunnerを使用してください。

#### ターゲット接続の問題 {#target-connection-issues}

DASTはスキャンを開始する前に、ターゲットURLに到達可能かチェックします。ターゲットURLに到達できない場合、DASTは問題を診断するのに役立つ詳細なエラーメッセージを生成します。デフォルトでは、DASTは接続を2秒ごとに再試行し、最大60秒まで行います。DASTが接続を再試行するタイミングは、`DAST_TARGET_CHECK_TIMEOUT`で設定できます。

接続問題が発生した場合は:

1. お使いの`DAST_TARGET_URL`の設定を確認してください。
   - ホスト名、ポート、またはプロトコルに誤字がないか確認してください。
   - URLにプロトコル (`http://`または`https://`) が含まれていることを確認してください。
   - ポート番号がアプリケーションが実行されている場所と一致することを確認してください。

1. Runnerからの接続をテストします。
   - 接続をテストします: `curl --verbose "http://your-target-url:port"`
   - DNS解決をチェックします: `nslookup your-hostname.com`
   - ポートが開いていることを確認します: `nc -zv your-hostname.com port`

1. アプリケーションが実行中であることを確認してください。
   - アプリケーションが正常に起動したことを確認してください。
   - 起動エラーについては、アプリケーションログを確認してください。
   - データベースやAPIを含むすべての依存関係が利用可能であることを確認してください。

1. ネットワークとファイアウォールの設定を確認してください。
   - ファイアウォールルールが、必要なポートでのトラフィックを許可していることを確認してください。
   - 内部アプリケーションの場合は、Runnerが内部DNSサーバーにアクセスできることを確認してください。

1. アプリケーションの起動や正常な状態になるまでに時間がかかる場合は、タイムアウトを増やしてください:

   ```yaml
      variables:
        DAST_TARGET_CHECK_TIMEOUT: "5m"  # Wait up to 5 minutes
   ```

#### DNSルックアップに失敗しました {#dns-lookup-failed}

`DNS lookup failed`のようなエラーが表示される場合があります。これは、DASTが指定されたホスト名のサーバーアドレスを見つけられない場合に発生します。理由は次のとおりです:

- `DAST_TARGET_URL`のホスト名が誤植されているか、正しくありません。
- ドメインが登録されていないか、存在しません。
- ネットワークまたはRunner環境でDNS解決の問題が発生しています。

#### 接続が拒否されました {#connection-refused}

`connection refused`というエラーが表示される場合があります。これは通常、サーバーは存在するものの、次のいずれかの理由で発生します:

- アプリケーションがまだ起動を完了していません。
- アプリケーションが指定されたポートとは異なるポートで実行されています。
- ファイアウォールがRunnerとアプリケーション間の接続をブロックしています。
- アプリケーションがクラッシュしたか、起動に失敗しました。

#### ターゲットがHTTP 5xxエラーで応答しました {#target-responded-with-http-5xx-error}

ターゲットアプリケーションが`HTTP 5xx`エラーで応答する場合があります。これは、アプリケーションに到達可能であるにもかかわらず、`500 Internal Server Error`、`502 Bad Gateway`、`503 Service Unavailable`、または`504 Gateway Timeout`のようなサーバーエラーで応答している場合に発生します。

次の場合にサーバーエラーが表示される場合があります:

- アプリケーションが起動中で、まだ完全に準備ができていません。
- アプリケーションに設定エラーがあります。
- データベースやAPIなど、必要な依存関係が利用できません。

### 期待される結果は何ですか？ {#what-is-the-expected-outcome}

DASTスキャンで問題に遭遇する多くのユーザーは、スキャナーが何をすべきかについて、ある程度の全体像を持っています。たとえば、特定のページをスキャンしていない、またはページ上のボタンを選択していないなどです。

可能な限り、問題を絞り込んで解決策を見つけるために、問題を特定してみてください。たとえば、DASTが特定のページをスキャンしていない状況を考えてみましょう。DASTはどこからそのページを見つけたはずですか？そこに到達するためにどのパスをたどりましたか？参照元のページに、DASTが選択すべきだったが選択しなかった要素がありましたか？

### その結果は人間によって達成可能ですか？ {#is-the-outcome-achievable-by-a-human}

人間が手動でアプリケーションを操作できない場合、DASTはアプリケーションをスキャンできません。

期待される結果が分かっている場合は、お使いのマシンでブラウザーを使用して手動でそれをレプリケートするようにしてください。例: 

- 新しいシークレット/プライベートブラウザーウィンドウを開きます。
- 開発者ツールを開きます。エラーメッセージがないかコンソールを監視してください。
  - Chromeの場合: `View -> Developer -> Developer Tools`。
  - Firefoxの場合: `Tools -> Browser Tools -> Web Developer Tools`。
- 認証する場合:
  - `DAST_AUTH_URL`にアクセスします。
  - `DAST_AUTH_USERNAME_FIELD`に`DAST_AUTH_USERNAME`ユーザー名を入力します。
  - `DAST_AUTH_PASSWORD_FIELD`に`DAST_AUTH_PASSWORD`ユーザー名を入力します。
  - `DAST_AUTH_SUBMIT_FIELD`を選択します。
- リンクを選択してフォームを入力します。正しくスキャンされていないページに移動します。
- アプリケーションの動作を観察します。自動スキャナーに問題を引き起こす可能性のあるものがあるか確認してください。

### DASTが機能しない理由がありますか？ {#any-reason-why-dast-would-not-work}

次の場合、DASTは正しくスキャンできません:

- CAPTCHAが存在します。スキャン対象のアプリケーションのテスト環境でこれらをオフにしてください。
- ターゲットアプリケーションへのアクセス権がありません。GitLab Runnerが、DASTの設定で使用されているURLを使用してアプリケーションにアクセスできることを確認してください。

### アプリケーションはどのように動作しますか？ {#how-does-your-application-work}

アプリケーションがどのように動作するかを理解することは、DASTスキャンが機能しない理由を解明するために不可欠です。たとえば、次の状況では追加の設定が必要になる場合があります。

- 要素を隠すポップアップダイアログはありますか？
- 読み込まれたページは一定時間後に劇的に変化しますか？
- アプリケーションの読み込みは特に遅いですか、速いですか？
- ターゲットアプリケーションは読み込み中に動作がぎくしゃくすることがありますか？
- アプリケーションはクライアントの場所に基づいて異なる動作をしますか？
- アプリケーションはシングルページアプリケーションですか？
- アプリケーションはHTMLフォームを送信しますか、それともJavaScriptとAJAXを使用しますか？
- アプリケーションはウェブソケットを使用しますか？
- アプリケーションは特定のWebフレームワークを使用しますか？
- ボタンを選択すると、フォームの送信を続行する前にJavaScriptが実行されますか？それは速いですか、遅いですか？
- 要素またはページが準備される前に、DASTが要素を選択または検索している可能性がありますか？

### DASTは何をしていますか？ {#what-is-dast-doing}

{{< history >}}

- GitLab [18.3](https://gitlab.com/gitlab-org/gitlab/-/issues/553625)で簡潔なログが導入されました。

{{< /history >}}

CI/CDのジョブログは、DASTが何を行っているかを簡潔にまとめたものを提供します。より詳細な診断情報については、ログファイルを出力するように設定できます。

次のロギングオプションが利用可能です:

- アナライザーが何を行っているかを理解するのに役立つ[診断ログ](#diagnostic-logs)。
- DASTとChromium間の通信を検査するのに役立つ[Chromium DevToolsロギング](#chromium-devtools-logging)。
- Chromiumが予期せずクラッシュした場合のエラーをログに記録するのに役立つ[Chromiumログ](#chromium-logs)。

## 診断ログ {#diagnostic-logs}

スキャンの問題を診断するには、アナライザーのログファイルを使用してください。アナライザーの異なる部分を異なるレベルでログに記録できます。

### ログメッセージの形式 {#log-message-format}

ログメッセージは`[time] [log level] [log module] [message] [additional properties]`の形式です。

たとえば、次のログエントリはレベル`INFO`を持ち、`CRAWL`ログモジュールの一部であり、メッセージ`Crawled path`、および追加のプロパティ`nav_id`と`path`を持ちます。

```plaintext
2021-04-21T00:34:04.000 INF CRAWL Crawled path nav_id=0cc7fd path="LoadURL [https://my.site.com:8090]"
```

### ログの出力先 {#log-destination}

ログはログファイルアーティファクトに送信されます。環境変数`DAST_LOG_FILE_CONFIG`を使用して、各出力先が異なるログを受け入れるように設定できます。例: 

```yaml
include:
  - template: DAST.gitlab-ci.yml

dast:
  variables:
    DAST_BROWSER_SCAN: "true"
    DAST_LOG_FILE_CONFIG: "loglevel:debug,cache:warn"           # file log defaults to DEBUG level, logs CACHE module at WARN
```

デフォルトでは、ファイルログは`gl-dast-scan.log`という名前のジョブアーティファクトです。このパスを[設定する](configuration/variables.md)には、`DAST_LOG_FILE_PATH` CI/CD変数を修正してください。

### ログレベル {#log-levels}

設定できるログレベルは次のとおりです:

| ログモジュール              | コンポーネントの概要                                                       | その他                             |
|-------------------------|--------------------------------------------------------------------------|----------------------------------|
| `TRACE`                 | 特定の、しばしばノイズの多い機能の内部動作に使用されます。              |                                  |
| `DEBUG`                 | 機能の内部動作を記述します。診断目的で使用されます。 |                                  |
| `INFO`                  | スキャンの高レベルなフローと結果を記述します。               | 指定がない場合のデフォルトレベル。 |
| `WARN`                  | DASTが回復してスキャンを続行するエラー状況を記述します。 |                                  |
| `FATAL`/`ERROR`/`PANIC` | 終了前の回復不能なエラーを記述します。                            |                                  |

### ログモジュール {#log-modules}

`LOGLEVEL`は、ログ出力先のデフォルトログレベルを設定します。次のいずれかのモジュールが設定されている場合、DASTはデフォルトログレベルよりもそのモジュールのログレベルを優先して使用します。

ロギング用に設定できるモジュールは次のとおりです:

| ログモジュール | コンポーネントの概要                                                                                |
|------------|---------------------------------------------------------------------------------------------------|
| `ACTIV`    | アクティブな攻撃に使用されます。                                                                          |
| `AUTH`     | 認証されたスキャンを作成するために使用されます。                                                          |
| `BPOOL`    | クロールのためにリースされるブラウザーのセット。                                             |
| `BROWS`    | ブラウザーの状態またはページをクエリするために使用されます。                                               |
| `CACHE`    | キャッシュされたHTTPリソースのキャッシュヒットとミスに関するレポートに使用されます。                               |
| `CHROM`    | Chrome DevToolsメッセージをログに記録するために使用されます。                                                             |
| `CONFG`    | アナライザーの設定をログに記録するために使用されます。                                                           |
| `CONTA`    | DevToolsメッセージからHTTPリクエストおよび応答の一部を収集するコンテナに使用されます。 |
| `CRAWL`    | コアとなるクローラーアルゴリズムに使用されます。                                                              |
| `CRWLG`    | クロールグラフジェネレーターに使用されます。                                                               |
| `DATAB`    | データを内部データベースに永続化するために使用されます。                                                |
| `LEASE`    | ブラウザーをブラウザープールに追加するために作成するために使用されます。                                          |
| `MAIN`     | クローラーのメインイベントループのフローに使用されます。                                          |
| `NAVDB`    | ナビゲーションエントリを保存するための永続化メカニズムに使用されます。                                      |
| `REGEX`    | 正規表現の実行時にパフォーマンス統計を記録するために使用されます。                       |
| `REPT`     | レポートを生成するために使用されます。                                                                      |
| `STAT`     | スキャンの実行中に一般的な統計情報に使用されます。                                               |
| `VLDFN`    | 脆弱性定義の読み込みと解析に使用されます。                                           |
| `WEBGW`    | アクティブチェックの実行時にターゲットアプリケーションに送信されたメッセージをログに記録するために使用されます。                   |
| `SCOPE`    | [スコープ管理](configuration/customize_settings.md#managing-scope)に関連するメッセージをログに記録するために使用されます。 |

### SECURE_LOG_LEVEL {#secure_log_level}

{{< history >}}

- GitLab 17.11で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/524632)されました。

{{< /history >}}

`DAST_LOG_FILE_CONFIG`でログモジュールを設定するよりも簡単な代替手段として、`SECURE_LOG_LEVEL`を設定できます:

- [サポートされているログレベル](#log-levels)のいずれかに設定します。これを行うと、指定されたレベルがすべてのモジュールのログファイルのデフォルトログレベルになります。
- [認証レポート](configuration/authentication.md#configure-the-authentication-report)を有効にするには`debug`または`trace`に設定します。
- [DevToolsロギング](#chromium-devtools-logging)を有効にするには`trace`に設定します。

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

### 例 - クロールされたパスをログに記録する {#example---log-crawled-paths}

スキャンのクロールフェーズ中に見つかったナビゲーションパスをログファイルにログ記録するには、ログファイルモジュール`CRAWL`を`DEBUG`に設定します。これは、DASTがターゲットアプリケーションを正しくクロールしているかどうかを理解するのに役立ちます。

```yaml
include:
  - template: DAST.gitlab-ci.yml

dast:
  variables:
    DAST_LOG_FILE_CONFIG: "crawl:debug"
```

たとえば、次の出力は、`https://example.com`のページをクロール中に4つのアンカーリンクが発見されたことを示しています。

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

> [!warning]
> DevToolsメッセージのロギングはセキュリティリスクです。出力には、ユーザー名、パスワード、認証トークンなどのシークレットが含まれています。この出力はGitLabサーバーにアップロードされ、ジョブログに表示される場合があります。

DASTブラウザーベースのスキャナーは、[Chrome DevTools Protocol](https://chromedevtools.github.io/devtools-protocol/)を使用してChromiumブラウザーをオーケストレーションします。DevToolsメッセージをログに記録することは、ブラウザーが何を行っているかについての透明性を提供するのに役立ちます。たとえば、ボタンの選択が機能しない場合、DevToolsメッセージは、原因がブラウザコンソールログのCORSエラーであることを示す場合があります。DevToolsメッセージを含むログは、サイズが非常に大きくなる可能性があります。このため、短時間のジョブでのみ有効にする必要があります。

すべてのDevToolsメッセージをログに記録するには、`CHROM`ログモジュールを`trace`に設定し、ロギングレベルを設定します。DevToolsログの例は次のとおりです:

```plaintext
2022-12-05T06:27:24.280 TRC CHROM event received    {"method":"Fetch.requestPaused","params":{"requestId":"interception-job-3.0","request":{"url":"http://auth-auto:8090/font-awesome.min.css","method":"GET","headers":{"Accept":"text/css,*/*;q=0.1","Referer":"http://auth-auto:8090/login.html","User-Agent":"Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/105.0.5195.102 Safari/537.36"},"initialPriority":"VeryHigh","referrerPolicy":"strict-origin-when-cross-origin"},"frameId":"A706468B01C2FFAA2EB6ED365FF95889","resourceType":"Stylesheet","networkId":"39.3"}} method=Fetch.requestPaused
2022-12-05T06:27:24.280 TRC CHROM request sent      {"id":47,"method":"Fetch.continueRequest","params":{"requestId":"interception-job-3.0","headers":[{"name":"Accept","value":"text/css,*/*;q=0.1"},{"name":"Referer","value":"http://auth-auto:8090/login.html"},{"name":"User-Agent","value":"Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/105.0.5195.102 Safari/537.36"}]}} id=47 method=Fetch.continueRequest
2022-12-05T06:27:24.281 TRC CHROM response received {"id":47,"result":{}} id=47 method=Fetch.continueRequest
```

### DevToolsログレベルのカスタマイズ {#customizing-devtools-log-levels}

Chrome DevToolsのリクエスト、応答、イベントはドメインによってネームスペース化されています。DASTは、各ドメインおよびメッセージを持つ各ドメインに異なるロギング設定を許可します。環境変数`DAST_LOG_DEVTOOLS_CONFIG`は、セミコロンで区切られたロギング設定のリストを受け入れます。ロギング設定は、`[domain/message]:[what-to-log][,truncate:[max-message-size]]`の構造を使用して宣言されます。

- `domain/message`は、ログに記録されているものを参照します。
  - `Default`は、すべてのドメインとメッセージを表す値として使用できます。
  - ドメインとして使用できます。たとえば、`Browser`、`CSS`、`Page`、`Network`などです。
  - メッセージを含むドメインとして使用できます。たとえば、`Network.responseReceived`などです。
  - 複数の設定が適用される場合、最も具体的な設定が使用されます。
- `what-to-log`は、何をログに記録するか、また記録するかどうかを参照します。
  - `message`は、メッセージが受信されたことをログに記録し、メッセージの内容はログに記録しません。
  - `messageAndBody`は、メッセージ内容とともにメッセージをログに記録します。`truncate`と組み合わせて使用することをお勧めします。
  - `suppress`はメッセージをログに記録しません。ノイズの多いドメインやメッセージを抑制するために使用されます。
- `truncate`は、出力されるメッセージのサイズを制限するためのオプションの設定です。

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

リソースが正しく読み込まれていない場合に役立ちます。HTTPメッセージイベントは、リクエストを続行するか失敗させるかの決定と同様にログに記録されます。ブラウザコンソールのエラーもログに記録されます。

```yaml
include:
  - template: DAST.gitlab-ci.yml

dast:
  variables:
    DAST_LOG_FILE_CONFIG: "chrom:trace"
    DAST_LOG_DEVTOOLS_CONFIG: "Default:suppress;Fetch:messageAndBody,truncate:2000;Network:messageAndBody,truncate:2000;Log:messageAndBody,truncate:2000;Console:messageAndBody,truncate:2000"
```

### ジョブコンソール出力のオーバーライド {#override-the-job-console-output}

デフォルトでは、ジョブコンソールはDASTのアクティビティを簡潔にまとめたものを表示します。診断ログ全体をジョブコンソールに出力するには、`DAST_FF_DIAGNOSTIC_JOB_OUTPUT`と`DAST_LOG_CONFIG`の変数の両方を設定します:

```yaml
include:
  - template: DAST.gitlab-ci.yml

dast:
  variables:
    DAST_FF_DIAGNOSTIC_JOB_OUTPUT: "true"
    DAST_LOG_CONFIG: "crawl:debug"                               # console log defaults to INFO level, logs AUTH module at DEBUG
```

[イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/552171) 552171は、GitLab 19.0でこのオプションを削除することを提案しています。

## Chromiumログ {#chromium-logs}

Chromiumがクラッシュするまれなケースでは、Chromiumプロセスの`STDOUT`と`STDERR`をログに書き込むことが役立ちます。環境変数`DAST_LOG_BROWSER_OUTPUT`を`true`に設定することで、この目的が達成されます。

DASTは多数のChromiumプロセスを起動および停止します。DASTは、各プロセスの出力を、ログモジュール`LEASE`とログレベル`INFO`を持つすべてのログ出力先に送信します。

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

デフォルトでは、DASTはHTTP応答本文が10 MB以下のHTTPリクエストを処理します。それ以外の場合、DASTは応答をブロックし、スキャンの失敗につながる可能性があります。この制約は、スキャン中のメモリ消費を削減することを目的としています。

例を次に示します。DASTは、`https://example.com/large.js`で見つかったJavaScriptファイルのサイズが制限を超えているため、そのファイルをブロックしました:

```plaintext
2022-12-05T06:28:43.093 WRN BROWS response body exceeds allowed size allowed_size_bytes=1000000 browser_id=752944257619431212 nav_id=ae23afe2acbce2c537657a9112926f1a of=1 request_id=interception-job-2.0 response_size_bytes=9333408 step=1 url=https://example.com/large.js
2022-12-05T06:28:58.104 WRN CONTA request failed, attempting to continue scan error=net::ERR_BLOCKED_BY_RESPONSE index=0 requestID=38.2 url=https://example.com/large.js
```

これは、設定`DAST_PAGE_MAX_RESPONSE_SIZE_MB`を使用して変更できます。たとえば、

```yaml
dast:
  variables:
    DAST_PAGE_MAX_RESPONSE_SIZE_MB: "25"
```

### クローラーが期待されるページに到達しない {#crawler-doesnt-reach-expected-pages}

#### キャッシュを無効にしてみてください {#try-disabling-the-cache}

DASTがアプリケーションページを誤ってキャッシュすると、DASTがアプリケーションを適切にクロールできなくなる可能性があります。一部のページがクローラーによって予期せず見つからない場合は、`DAST_USE_CACHE: "false"`変数を設定して問題が解決するかどうか確認してください。これにより、スキャンのパフォーマンスが大幅に低下する可能性があります。絶対に必要ない限り、キャッシュを無効にしないようにしてください。サブスクリプションをお持ちの場合は、[サポートチケットを作成](https://support.gitlab.com/)して、キャッシュがウェブサイトのクロールを妨げている理由を調査してください。

#### ターゲットパスを直接指定する {#specifying-target-paths-directly}

クローラーは通常、定義されたターゲットURLから開始し、サイトと対話することでさらなるページを見つけようとします。ただし、クローラーが開始するパスを直接指定する方法は2つあります:

- sitemap.xmlを使用する: [サイトマップ](https://www.sitemaps.org/protocol.html)は、ウェブサイト内のページを指定するための明確に定義されたプロトコルです。DASTのクローラーは`<target URL>/sitemap.xml`でsitemap.xmlファイルを探し、指定されたすべてのURLをクローラーの開始点として使用します。[サイトマップインデックス](https://www.sitemaps.org/protocol.html#index)ファイルはサポートされていません。
- `DAST_TARGET_PATHS`を使用します。この設定変数は、クローラーの入力パスを指定できます。例: `DAST_TARGET_PATHS: /,/page/1.html,/page/2.html`。

#### リクエストがブロックされていないことを確認してください {#make-sure-requests-are-not-getting-blocked}

デフォルトでは、DASTはターゲットURLドメインへのリクエストのみを許可します。ウェブサイトがターゲット以外のドメインにリクエストを行う場合、`DAST_SCOPE_ALLOW_HOSTS`を使用してそのようなホストを指定してください。例: 「example.com」は、「auth.example.com」に認証リクエストを行い、認証トークンを更新します。ドメインが許可されていないため、リクエストはブロックされ、クローラーは新しいページを見つけるのに失敗します。

#### 最大アクション数とクローラーのタイムアウト {#maximum-actions-and-crawler-timeout}

クローラーは、ターゲットサイトでのアクティビティと滞在時間に関してデフォルトの制限があります:

1. デフォルトでは、クローラーは10,000のアクションを処理します。アクションは、リンクの選択またはフォームの入力である場合があります。クローラーがこの制限を超えると、デバッグレベルのログ`not adding navigation as it exceeds max actions`が表示されます。
1. デフォルトでは、クローラーは最大24時間実行されます。この時間制限を超えると、トレースレベルのログ`crawl complete, timed out`が表示されます。

クローラーがこれらの制限のいずれかに達すると、スキャナーは停止し、ターゲットウェブサイトを完全にカバーできません。したがって、これらの制限の違反は、スキャン中の問題と最適化の潜在的な機会を示す可能性があります。

アプリケーションに同様の構造を持つテンプレートベースのページがあり、ページ間でデータが異なる場合、またはURLパターン (たとえば、`/products/item-123`、`/products/item-456`、`/products/item-789`) に気付いた場合は、[グループ化されたURL](configuration/customize_settings.md#grouped-urls)を設定して、セキュリティカバレッジを維持しながらスキャン時間を短縮してください。

グループ化されたURLは、多くの製品ページを持つeコマースサイト、コンテンツベースのサイト、または検索インターフェース (たとえば、`/search?q=term&page=1`、`/search?q=term&page=2`) でうまく機能します。

スキャン時間の管理の詳細については、[スキャン時間の管理](configuration/customize_settings.md#managing-scan-time)を参照してください。他の戦略が適切ではなく、ターゲットサイトが広範囲にわたる場合は、クローラーのタイムアウト (`DAST_CRAWL_TIMEOUT`) または最大アクション (`DAST_CRAWL_MAX_ACTIONS`) を増やしてください。
