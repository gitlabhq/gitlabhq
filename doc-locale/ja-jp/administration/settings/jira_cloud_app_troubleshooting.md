---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Jira Cloudアプリの管理におけるGitLabのトラブルシューティング
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

GitLab for Jira Cloudアプリを管理する際に、次の問題が発生する可能性があります。

ユーザー向けドキュメントについては、[GitLab for Jira Cloudアプリ](../../integration/jira/connect-app.md#troubleshooting)を参照してください。

## すでにサインインしている場合にサインインメッセージが表示される {#sign-in-message-displayed-when-already-signed-in}

すでにサインインしている場合に、GitLab.comへのサインインを求める次のメッセージが表示されることがあります:

```plaintext
Sign in or sign up before continuing.
```

GitLab for Jira Cloudアプリは、iframeを使用して設定ページにグループを追加します。一部のブラウザはクロスサイトCookieをブロックするため、このイシューが発生することがあります。

このイシューを解決するには、[OAuth](jira_cloud_app.md#set-up-oauth-authentication)認証を設定します。

## 手動インストールが失敗する {#manual-installation-fails}

公式のMarketplaceリストからGitLab for Jira Cloudアプリをインストールし、[手動インストール](jira_cloud_app.md#install-the-gitlab-for-jira-cloud-app-manually)に置き換えた場合、次のいずれかのエラーが発生する可能性があります:

```plaintext
The app "gitlab-jira-connect-gitlab.com" could not be installed as a local app as it has previously been installed from Atlassian Marketplace
```

```plaintext
The app host returned HTTP response code 401 when we tried to contact it during installation. Please try again later or contact the app vendor.
```

このイシューを解決するには、**Jira ConnectのプロキシURL**設定を無効にします。

- GitLab 15.7の場合:

  1. [Railsコンソール](../operations/rails_console.md#starting-a-rails-console-session)を開きます。
  1. `ApplicationSetting.current_without_cache.update(jira_connect_proxy_url: nil)`を実行します。

- GitLab 15.8以降では、次のようになります:

  1. 左側のサイドバーの下部で、**管理者**を選択します。
  1. 左側のサイドバーで、**設定** > **一般**を選択します。
  1. **GitLab for Jira App**を展開します。
  1. **Jira ConnectのプロキシURL**テキストボックスをクリアします。
  1. **変更を保存**を選択します。

イシューが解決しない場合は、インスタンスが`connect-install-keys.atlassian.com`に接続してAtlassianから公開キーを取得できることを確認します。接続をテストするには、次のコマンドを実行します:

```shell
# A `404 Not Found` is expected because you're not passing a token
curl --head "https://connect-install-keys.atlassian.com"
```

## `Invalid JWT`でデータ同期が失敗する {#data-sync-fails-with-invalid-jwt}

GitLab for Jira Cloudアプリがインスタンスからデータを継続的に同期できない場合は、シークレットトークンが古くなっている可能性があります。Atlassianは、新しいシークレットトークンをGitLabに送信できます。GitLabがこれらのトークンの処理または保存に失敗すると、`Invalid JWT`エラーが発生します。

この問題を解決するには、以下を実行します:

- インスタンスが以下に対して公開されていることを確認します:
  - [公式のAtlassian Marketplaceリストからアプリをインストール](jira_cloud_app.md#install-the-gitlab-for-jira-cloud-app-from-the-atlassian-marketplace)した場合のGitLab.com。
  - [アプリを手動でインストール](jira_cloud_app.md#install-the-gitlab-for-jira-cloud-app-manually)した場合のJira Cloud。
- アプリのインストール時に`/-/jira_connect/events/installed`エンドポイントに送信されたトークンリクエストがJiraからアクセスできることを確認します。次のコマンドは、`401 Unauthorized`を返す必要があります:

  ```shell
  curl --include --request POST "https://gitlab.example.com/-/jira_connect/events/installed"
  ```

- インスタンスに[SSL](https://docs.gitlab.com/omnibus/settings/ssl/)が設定されている場合は、[証明書が有効で、公開的に信頼されている](https://docs.gitlab.com/omnibus/settings/ssl/ssl_troubleshooting.html#useful-openssl-debugging-commands)ことを確認してください。

アプリのインストール方法に応じて、次のことを確認してください:

- [公式のAtlassian Marketplaceリストからアプリをインストール](jira_cloud_app.md#install-the-gitlab-for-jira-cloud-app-from-the-atlassian-marketplace)した場合は、GitLab for Jira CloudアプリでGitLabバージョンを切り替えます:

  <!-- markdownlint-disable MD044 -->

  1. Jiraで、**Apps**（アプリ）の横にある横の省略記号（{{< icon name="ellipsis_h" >}}）を選択し、**Manage your apps**（アプリの管理）を選択します。

  1. 次のいずれかの方法を使用してアプリに移動します:

     **For instances with centralized app management:**（一元化されたアプリ管理を備えたインスタンスの場合:）

     1. 「App management has moved to Administration」（アプリの管理が管理に移動しました）と表示された場合は、**Take me there**（そちらに移動）を選択します。それ以外の場合は、**For instances with legacy app management**（従来のアプリ管理を使用するインスタンス）の手順に従ってください。
     1. **Installed apps**（インストール済みアプリ）タブで、**GitLab for Jira (gitlab.com)**アプリを見つけ、横の省略記号（{{< icon name="ellipsis_h" >}}）を選択し、**始めましょう**を選択します。

     **For instances with legacy app management:**（従来のアプリ管理を使用するインスタンスの場合:）

     1. **GitLab for Jira (gitlab.com)**アプリを見つけ、シェブロン（{{< icon name="chevron-right" >}}）を選択し、**始めましょう**を選択します。

  1. **GitLabのバージョンを変更**を選択します。
  1. **GitLab.com (SaaS)**を選択し、**保存**を選択します。
  1. もう一度**GitLabのバージョンを変更**を選択します。
  1. **GitLab(Self-Managed)**を選択し、**次へ**を選択します。
  1. すべてのチェックボックスをオンにし、**次へ**を選択します。
  1. **GitLabインスタンスのURL**を入力し、**保存**を選択します。

  <!-- markdownlint-enable MD044 -->

  この方法でうまくいかない場合は、PremiumまたはUltimateプランのお客様の場合は、[サポートチケット](https://support.gitlab.com/hc/en-us/requests/new)を送信してください。GitLabインスタンスのURLとJiraのURLを入力してください。GitLabサポートは、次のスクリプトを実行してイシューを解決できます:

  ```ruby
  # Check if GitLab.com can connect to the GitLab Self-Managed instance
  checker = Gitlab::TcpChecker.new("gitlab.example.com", 443)

  # Returns `true` if successful
  checker.check

  # Returns an error if the check fails
  checker.error
  ```

  ```ruby
  # Locate the installation record for the GitLab Self-Managed instance
  installation = JiraConnectInstallation.find_by_instance_url("https://gitlab.example.com")

  # Try to send the token again from GitLab.com to the GitLab Self-Managed instance
  ProxyLifecycleEventService.execute(installation, :installed, installation.instance_url)
  ```

- [アプリを手動でインストール](jira_cloud_app.md#install-the-gitlab-for-jira-cloud-app-manually)した場合:
  - [Jira Cloud Support](https://support.atlassian.com/jira-software-cloud/)に、Jiraがインスタンスに接続できることを確認するように依頼してください。
  - [アプリを再インストール](jira_cloud_app.md#install-the-gitlab-for-jira-cloud-app-manually)します。この方法では、[Jira開発パネル](../../integration/jira/development_panel.md)からすべての[同期データ](../../integration/jira/connect-app.md#gitlab-data-synced-to-jira)が削除される可能性があります。

## エラー: `Failed to update the GitLab instance` {#error-failed-to-update-the-gitlab-instance}

GitLab for Jira Cloudアプリをセットアップするときに、GitLab Self-ManagedインスタンスのURLを入力すると、`Failed to update the GitLab instance`エラーが発生する場合があります。

このイシューを解決するには、インストール方法のすべての前提条件が満たされていることを確認してください:

- [GitLab for Jira Cloudアプリを接続するための前提要件](jira_cloud_app.md#prerequisites)。
- [GitLab for Jira Cloudアプリを手動でインストールするための前提要件](jira_cloud_app.md#prerequisites-1)。

Jira Connectのプロキシ URLを設定し、前提条件を確認しても問題が解決しない場合は、[Jira Connectのプロキシの問題のデバッグ](#debugging-jira-connect-proxy-issues)を確認してください。

GitLab 15.8以前のバージョンを使用していて、`jira_connect_oauth_self_managed`および`jira_connect_oauth`の両方の機能フラグを以前に有効にしている場合は、[既知のイシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/388943)が原因で、`jira_connect_oauth_self_managed`フラグを無効にする必要があります。これらのフラグを確認するには:

1. [Railsコンソール](../operations/rails_console.md#starting-a-rails-console-session)を開きます。
1. 次のコードを実行します:

   ```ruby
   # Check if both feature flags are enabled.
   # If the flags are enabled, these commands return `true`.
   Feature.enabled?(:jira_connect_oauth)
   Feature.enabled?(:jira_connect_oauth_self_managed)

   # If both flags are enabled, disable the `jira_connect_oauth_self_managed` flag.
   Feature.disable(:jira_connect_oauth_self_managed)
   ```

### エラー: `Invalid audience` {#error-invalid-audience}

[リバースプロキシ](jira_cloud_app.md#using-a-reverse-proxy)を使用している場合、[`exceptions_json.log`](../logs/_index.md#exceptions_jsonlog)に次のようなメッセージが含まれている可能性があります:

```plaintext
Invalid audience. Expected https://proxy.example.com/-/jira_connect, received https://gitlab.example.com/-/jira_connect
```

このイシューを解決するには、リバースプロキシFQDNを[追加のJWTオーディエンス](jira_cloud_app.md#set-an-additional-jwt-audience)として設定します。

### Jira Connectのプロキシのイシューのデバッグ {#debugging-jira-connect-proxy-issues}

**Jira ConnectのプロキシURL**を`https://gitlab.com`に設定して[インスタンスをセットアップ](jira_cloud_app.md#set-up-your-instance-for-atlassian-marketplace-installation)すると、次のことができます:

- ブラウザの開発パネルでネットワークトラフィックを調べます。
- 詳細については、`Failed to update the GitLab instance`エラーを再現してください。

`GET`から`https://gitlab.com/-/jira_connect/installations`へのリクエストが表示されるはずです。

このリクエストは`200 OK`を返すはずですが、問題が発生した場合は`422 Unprocessable Entity`を返す可能性があります。応答本文でエラーを確認できます。

イシューを解決できず、GitLabのお客様である場合は、[GitLabサポート](https://about.gitlab.com/support/)にご連絡ください。次の情報をGitLabサポートに提供してください:

- GitLab Self-ManagedインスタンスのURL。
- GitLab.comのユーザー名。
- オプション。`https://gitlab.com/-/jira_connect/installations`への失敗した`GET`リクエストの`X-Request-Id`応答ヘッダー。
- オプション。イシューをキャプチャした[`harcleaner`](https://gitlab.com/gitlab-com/support/toolbox/harcleaner)で処理した[HARファイル](https://support.zendesk.com/hc/en-us/articles/4408828867098-Generating-a-HAR-file-for-troubleshooting)。

GitLabサポートは、GitLab.comサーバーログでイシューを調査できます。

#### GitLabサポート {#gitlab-support}

{{< alert type="note" >}}

これらの手順は、GitLabサポートのみが実行できます。

{{< /alert >}}

Jira ConnectプロキシURL `https://gitlab.com/-/jira_connect/installations`への各`GET`リクエストは、2つのログエントリを生成します。

Kibanaで関連するログエントリを見つけるには、次のいずれかを行います:

- `https://gitlab.com/-/jira_connect/installations`への`GET`リクエストの`X-Request-Id`値または相関IDがある場合、[Kibana](https://log.gprd.gitlab.net/app/r/s/0FdPP)ログは、`json.meta.caller_id: JiraConnect::InstallationsController#update`、`NOT json.status: 200`、および`json.correlation_id: <X-Request-Id>`でフィルタリングする必要があります。これにより、2つのログエントリが返されます。

- お客様のSelf-Managed URLがある場合:
  1. [Kibana](https://log.gprd.gitlab.net/app/r/s/QVsD4)ログは、`json.meta.caller_id: JiraConnect::InstallationsController#update`、`NOT json.status: 200`、および`json.params.value: {"instance_url"=>"https://gitlab.example.com"}`でフィルタリングする必要があります。Self-Managed URLに先頭のスラッシュを含めることはできません。これにより、ログエントリの1つが返されます。
  1. `json.correlation_id`をフィルターに追加します。
  1. `json.params.value`フィルターを削除します。これにより、もう一方のログエントリが返されます。

最初のログの場合:

- `json.status`が`422 Unprocessable Entity`と等しい。
- `json.params.value`は、GitLab Self-Managed URL `[[FILTERED], {"instance_url"=>"https://gitlab.example.com"}]`と一致する必要があります。

2番目のログでは、次のいずれかのシナリオが発生する可能性があります:

- シナリオ1:
  - `json.message`、`json.jira_status_code`、および`json.jira_body`が存在します。
  - `json.message`は`Proxy lifecycle event received error response`または類似しています。
  - `json.jira_status_code`および`json.jira_body`には、GitLab Self-Managedインスタンスまたはインスタンスの前面にあるプロキシから受信した応答が含まれている可能性があります。
  - `json.jira_status_code`が`401 Unauthorized`で、`json.jira_body`が`(empty)`の場合:
    - [**Jira ConnectのプロキシURL**](jira_cloud_app.md#set-up-your-instance-for-atlassian-marketplace-installation)が`https://gitlab.com`に設定されていない可能性があります。
    - GitLab Self-Managedインスタンスが送信接続をブロックしている可能性があります。GitLab Self-Managedインスタンスが`connect-install-keys.atlassian.com`と`gitlab.com`の両方に接続できることを確認してください。
    - GitLab Self-Managedインスタンスは、JiraからのJWTトークンを復号化できません。[GitLab 16.11以降](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/147234) 、[`exceptions_json.log`](../logs/_index.md#exceptions_jsonlog)にはエラーに関する詳細情報が含まれています。
    - [リバースプロキシ](jira_cloud_app.md#using-a-reverse-proxy)がGitLab Self-Managedインスタンスの前面にある場合、GitLab Self-Managedインスタンスに送信される`Host`ヘッダーがリバースプロキシFQDNと一致しない可能性があります。GitLab Self-Managedインスタンスの[Workhorseログ](../logs/_index.md#workhorse-logs)を確認します:

      ```shell
      grep /-/jira_connect/events/installed /var/log/gitlab/gitlab-workhorse/current
      ```

      出力には、次のものが含まれている可能性があります:

      ```json
      {
        "host":"gitlab.mycompany.com:443", // The host should match the reverse proxy FQDN entered into the GitLab for Jira Cloud app
        "remote_ip":"34.74.226.3", // This IP should be within the GitLab.com IP range https://docs.gitlab.com/ee/user/gitlab_com/#ip-range
        "status":401,
        "uri":"/-/jira_connect/events/installed"
      }
      ```

  - `json.jira_status_code`が`404 Not Found`で、`json.jira_body`に一般的なGitLab 404ページHTMLが含まれている場合は、Self-Managedインスタンスの[インテグレーション許可リスト](project_integration_management.md#integration-allowlist)がGitLab for Jira Cloudアプリを許可していることを確認します。

- シナリオ2:
  - `json.exception.class`と`json.exception.message`が存在します。
  - `json.exception.class`および`json.exception.message`には、GitLab Self-Managedインスタンスへの接続中に問題が発生したかどうかが含まれています。

## エラー: `Failed to link group` {#error-failed-to-link-group}

グループをリンクすると、次のエラーが発生する可能性があります:

```plaintext
Failed to link group. Please try again.
```

このエラーは、複数の理由で返される可能性があります。

- 権限が不十分でJiraからユーザー情報を取得できない場合、`403 Forbidden`が返されます。このイシューを解決するには、アプリをインストールして構成するJiraユーザー名が特定の[要件](jira_cloud_app.md#jira-user-requirements)を満たしていることを確認してください。

- このエラーは、[リバースプロキシ](jira_cloud_app.md#using-a-reverse-proxy)で書き換えまたはサブフィルターを使用する場合にも発生する可能性があります。リクエストで使用されるアプリキーには、一部のリバースプロキシフィルターがキャプチャする可能性のあるサーバーホスト名の一部が含まれています。認証が正しく機能するためには、AtlassianとGitLabのアプリキーが一致する必要があります。

- このエラーは、GitLab for Jira Cloudアプリが最初にインストールされたときにGitLabインスタンスが最初に誤って構成された場合に発生する可能性があります。この場合、`jira_connect_installation`テーブル内のデータを削除する必要があるかもしれません。既存のGitLab for Jiraアプリのインストールを保持する必要がないことを確認した場合にのみ、このデータを削除してください。

  1. JiraプロジェクトからGitLab for Jira Cloudアプリをアンインストールします。
  1. レコードを削除するには、[GitLab Railsコンソール](../operations/rails_console.md#starting-a-rails-console-session)で次のコマンドを実行します:

     ```ruby
     JiraConnectInstallation.delete_all
     ```

## エラー: `Failed to load Jira Connect Application ID` {#error-failed-to-load-jira-connect-application-id}

アプリをGitLab Self-Managedインスタンスに向​​けた後、GitLab for Jira Cloudアプリにサインインすると、次のエラーが発生する場合があります:

```plaintext
Failed to load Jira Connect Application ID. Please try again.
```

ブラウザコンソールを確認すると、次のメッセージも表示される場合があります:

```plaintext
Cross-Origin Request Blocked: The Same Origin Policy disallows reading the remote resource at https://gitlab.example.com/-/jira_connect/oauth_application_id. (Reason: CORS header 'Access-Control-Allow-Origin' missing). Status code: 403.
```

この問題を解決するには、以下を実行します:

1. `/-/jira_connect/oauth_application_id`が公開されており、JSON応答を返すことを確認します:

   ```shell
   curl --include "https://gitlab.example.com/-/jira_connect/oauth_application_id"
   ```

1. [公式のAtlassian Marketplaceリストからアプリをインストール](jira_cloud_app.md#install-the-gitlab-for-jira-cloud-app-from-the-atlassian-marketplace)した場合は、[**Jira ConnectのプロキシURL**](jira_cloud_app.md#set-up-your-instance-for-atlassian-marketplace-installation)が末尾にスラッシュなしで`https://gitlab.com`に設定されていることを確認してください。

## エラー: `Missing required parameter: client_id` {#error-missing-required-parameter-client_id}

アプリをGitLab Self-Managedインスタンスに向​​けた後、GitLab for Jira Cloudアプリにサインインすると、次のエラーが発生する場合があります:

```plaintext
Missing required parameter: client_id
```

このイシューを解決するには、インストール方法のすべての前提条件が満たされていることを確認してください:

- [GitLab for Jira Cloudアプリを接続するための前提要件](jira_cloud_app.md#prerequisites)。
- [GitLab for Jira Cloudアプリを手動でインストールするための前提要件](jira_cloud_app.md#prerequisites-1)。

## エラー: `Failed to sign in to GitLab` {#error-failed-to-sign-in-to-gitlab}

アプリをGitLab Self-Managedインスタンスに向​​けた後、GitLab for Jira Cloudアプリにサインインすると、次のエラーが発生する場合があります:

```plaintext
Failed to sign in to GitLab
```

このイシューを解決するには、アプリ用に作成された[OAuthアプリケーション](jira_cloud_app.md#set-up-oauth-authentication)で、**信用済み**と**非公開**のチェックボックスがオフになっていることを確認します。
