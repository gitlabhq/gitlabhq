---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: GitLabへのサードパーティ認証。
title: OAuth 2.0 Identity Provider API
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

このAPIを使用すると、サードパーティサービスが[OAuth 2.0](https://oauth.net/2/)プロトコルを使用して、ユーザーのGitLabリソースにアクセスできるようになります。詳細については、[GitLabをOAuth 2.0認証用のIdentity Providerとして設定する](../integration/oauth_provider.md)を参照してください。

この機能は、[doorkeeper Ruby gem](https://github.com/doorkeeper-gem/doorkeeper)に基づいています。

## クロスオリジンリソース共有 {#cross-origin-resource-sharing}

{{< history >}}

- CORSプリフライトリクエストのサポートがGitLab 15.1で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/364680)されました。

{{< /history >}}

多くの`/oauth`エンドポイントは、クロスオリジンリソース共有（CORS）をサポートしています。GitLab 15.1以降、次のエンドポイントも[CORSプリフライトリクエスト](https://developer.mozilla.org/en-US/docs/Web/HTTP/Guides/CORS)をサポートしています。

- `/oauth/revoke`
- `/oauth/token`
- `/oauth/userinfo`

プリフライトリクエストには、特定のヘッダーのみを使用できます。

- [シンプルなリクエスト](https://developer.mozilla.org/en-US/docs/Web/HTTP/Guides/CORS#simple_requests)にリストされているヘッダー
- `Authorization`ヘッダー

たとえば、`X-Requested-With`ヘッダーはプリフライトリクエストには使用できません。

## サポートされているOAuth 2.0フロー {#supported-oauth-20-flows}

GitLabは、次の認証フローをサポートしています。

- **[Proof Key for Code Exchange（PKCE）](https://www.rfc-editor.org/rfc/rfc7636)を使用した認証コード**: もっとも安全です。PKCEを使用しない場合、モバイルクライアントにクライアントシークレットを含める必要があり、クライアントアプリとサーバーアプリの両方でPKCEの利用が推奨されています。
- **認証コード**: 安全で一般的なフローです。安全なサーバーサイドアプリに推奨される選択肢です。
- **デバイス認可グラント**（GitLab 17.1以降）ブラウザーへのアクセスがないデバイスへのセキュアフロー。この認証フローを完了するにはセカンダリデバイスが必要です。

[OAuth 2.1](https://oauth.net/2.1/)のドラフト仕様では、インプリシットグラントフローとリソースオーナーパスワードクレデンシャルフローの両方が明示的に除外されています。

[OAuth RFC](https://www.rfc-editor.org/rfc/rfc6749)を参照して、すべてのフローの仕組みを理解し、各自のユースケースに適したフローを選択してください。

認証コードフローでは（PKCEの有無にかかわらず）、最初にユーザーのアカウントの`/user_settings/applications`ページから`application`を登録する必要があります。登録中に適切なスコープを有効にすることで、`application`がアクセスできるリソースの範囲を制限できます。作成時に`application`認証情報（_アプリケーションID_と_クライアントシークレット_）を取得します。_クライアントシークレット_を**安全に保管する必要があります**。アプリケーションアーキテクチャで許可されている場合は、_アプリケーションID_もシークレットにしておくことをおすすめします。

GitLabのスコープのリストについては、[プロバイダーのドキュメント](../integration/oauth_provider.md#view-all-authorized-applications)を参照してください。

### CSRF攻撃を防ぐ {#prevent-csrf-attacks}

[リダイレクトベースのフローを保護する](https://datatracker.ietf.org/doc/html/draft-ietf-oauth-security-topics-13#section-3.1)ために、OAuth仕様では、`/oauth/authorize`エンドポイントへの各リクエストで、「ユーザーエージェントに安全にバインドされたstateパラメータで伝送される1回限りのCSRFトークン」を使用することが推奨されています。これにより、[CSRF攻撃](https://wiki.owasp.org/index.php/Cross-Site_Request_Forgery_(CSRF))を防ぐことができます。

### 本番環境でHTTPSを使用する {#use-https-in-production}

本番環境では`redirect_uri`にHTTPSを使用します。GitLabでは、開発環境の場合には安全でないHTTPリダイレクトURIを使用することを許可しています。

OAuth 2.0のセキュリティは完全にトランスポートレイヤに基づいているので、保護されていないURIは使用すべきではありません。詳細については、[OAuth 2.0 RFC](https://www.rfc-editor.org/rfc/rfc6749#section-3.1.2.1)と[OAuth 2.0 Threat Model RFC](https://www.rfc-editor.org/rfc/rfc6819#section-4.4.2.1)を参照してください。

以下のセクションでは、各フローで認証を取得するための詳しい手順を説明します。

### Proof Key for Code Exchange（PKCE）を使用した認証コード {#authorization-code-with-proof-key-for-code-exchange-pkce}

{{< history >}}

- OAuthアプリケーション向けのグループSAML SSOのサポートは、GitLab 18.2で`ff_oauth_redirect_to_sso_login`[フラグ](../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/461212)されました。デフォルトでは無効になっています。
- OAuthアプリケーションのSAML SSOのサポートは、GitLab 18.3で[GitLab.com、GitLab Self-Managed、GitLab Dedicatedで有効](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/200682)になりました。
- GitLab 18.5で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/561778)になりました。機能フラグ`ff_oauth_redirect_to_sso_login`は削除されました。

{{< /history >}}

[PKCE RFC](https://www.rfc-editor.org/rfc/rfc7636#section-1.1)には、認証リクエストからアクセストークンまで、詳細なフローの説明が含まれています。以下の手順では、GitLabでのフローの実装について説明します。

PKCEを使用した認証コードフロー（略してPKCE）を使用すると、_クライアントシークレット_へのアクセスを必要とせずに、パブリッククライアントでアクセストークンのクライアント認証情報のOAuth交換を安全に実行できます。これにより、ユーザーからシークレットを保持することが技術的に不可能なシングルページJavaScriptアプリケーションやその他のクライアント側アプリで、PKCEフローが有利になります。

フローを開始する前に、`STATE`、`CODE_VERIFIER`、および`CODE_CHALLENGE`を生成します。

- `STATE`は、リクエストとコールバックの間で状態を維持するためにクライアントが使用する予測不能な値です。これをCSRFトークンとしても使用する必要があります。
- `CODE_VERIFIER`は、長さが43 – 128文字のランダムな文字列で、文字`A-Z`、`a-z`、`0-9`、`-`、`.`、`_`、および`~`を使用できます。
- `CODE_CHALLENGE`は、`CODE_VERIFIER`のSHA256ハッシュのURLセーフなbase64エンコード文字列です。
  - SHA256ハッシュは、エンコード前にバイナリ形式である必要があります。
  - Rubyでは、`Base64.urlsafe_encode64(Digest::SHA256.digest(CODE_VERIFIER), padding: false)`を使用してこれを設定できます。
  - 参考までに、上記のRubyスニペットを使用してハッシュ化およびエンコードした場合、`CODE_VERIFIER`の文字列`ks02i3jdikdo2k0dkfodf3m39rjfjsdk0wk349rj3jrhf`により、`CODE_CHALLENGE`の文字列`2i0WFA-0AerkjQm4X4oDEhqA17QIAKNjXpagHBXmO_U`が生成されます。

1. 認証コードをリクエストします。これを行うには、次のクエリパラメータを指定して、ユーザーを`/oauth/authorize`ページにリダイレクトする必要があります。

   ```plaintext
   https://gitlab.example.com/oauth/authorize?client_id=APP_ID&redirect_uri=REDIRECT_URI&response_type=code&state=STATE&scope=REQUESTED_SCOPES&code_challenge=CODE_CHALLENGE&code_challenge_method=S256&root_namespace_id=ROOT_NAMESPACE_ID
   ```

   このページではユーザーに対し、`REQUESTED_SCOPES`で指定されたスコープに基づいて、アプリからアカウントへのアクセスリクエストを承認するように求めます。その後、ユーザーは指定された`REDIRECT_URI`にリダイレクトされます。[スコープパラメータ](../integration/oauth_provider.md#view-all-authorized-applications)は、ユーザーに関連付けられているスコープのスペース区切りのリストです。たとえば`scope=read_user+profile`は、`read_user`スコープと`profile`スコープをリクエストします。`root_namespace_id`は、プロジェクトに関連付けられたルートネームスペースIDです。このオプションのパラメータは、関連付けられたグループに[SAML SSO](../user/group/saml_sso/_index.md)が設定されている場合に使用する必要があります。リダイレクトには認証`code`が含まれます。次に例を示します。

   ```plaintext
   https://example.com/oauth/redirect?code=1234567890&state=STATE
   ```

1. 前のリクエストから返された認証`code`（次の例では`RETURNED_CODE`として示されます）を使用して、任意のHTTPクライアントを使用して`access_token`をリクエストできます。次の例では、Rubyの`rest-client`を使用しています。

   ```ruby
   parameters = 'client_id=APP_ID&code=RETURNED_CODE&grant_type=authorization_code&redirect_uri=REDIRECT_URI&code_verifier=CODE_VERIFIER'
   RestClient.post 'https://gitlab.example.com/oauth/token', parameters
   ```

   レスポンス例: 

   ```json
   {
    "access_token": "de6780bc506a0446309bd9362820ba8aed28aa506c71eedbe1c5c4f9dd350e54",
    "token_type": "bearer",
    "expires_in": 7200,
    "refresh_token": "8257e65c97202ed1726cf9571600918f3bffb2544b26e00a61df9897668c33a1",
    "created_at": 1607635748
   }
   ```

1. 新しい`access_token`を取得するには、`refresh_token`パラメータを使用します。リフレッシュトークンは、`access_token`自体が期限切れになった後でも使用可能です。このリクエストは次の処理を行います。
   - 既存の`access_token`と`refresh_token`を無効にします。
   - 応答で新しいトークンを送信します。

   ```ruby
     parameters = 'client_id=APP_ID&refresh_token=REFRESH_TOKEN&grant_type=refresh_token&redirect_uri=REDIRECT_URI'
     RestClient.post 'https://gitlab.example.com/oauth/token', parameters
   ```

   レスポンス例: 

   ```json
   {
     "access_token": "c97d1fe52119f38c7f67f0a14db68d60caa35ddc86fd12401718b649dcfa9c68",
     "token_type": "bearer",
     "expires_in": 7200,
     "refresh_token": "803c1fd487fec35562c205dac93e9d8e08f9d3652a24079d704df3039df1158f",
     "created_at": 1628711391
   }
   ```

> [!note]
> 元の認可リクエストで使用された`redirect_uri`と`redirect_uri`は一致する必要があります。

これで、アクセストークンを使用してAPIにリクエストを行えるようになります。

### 認証コードフロー {#authorization-code-flow}

{{< history >}}

- OAuthアプリケーション向けのグループSAML SSOのサポートは、GitLab 18.2で`ff_oauth_redirect_to_sso_login`[フラグ](../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/461212)されました。デフォルトでは無効になっています。
- OAuthアプリケーションのSAML SSOのサポートは、GitLab 18.3で[GitLab.com、GitLab Self-Managed、GitLab Dedicatedで有効](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/200682)になりました。
- GitLab 18.5で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/561778)になりました。機能フラグ`ff_oauth_redirect_to_sso_login`は削除されました。

{{< /history >}}

> [!note]
> 詳細なフローの説明については、[RFC仕様](https://www.rfc-editor.org/rfc/rfc6749#section-4.1)を確認してください。

この認証コードフローは、基本的に[PKCEを使用した認証コードフロー](#authorization-code-with-proof-key-for-code-exchange-pkce)と同じです。

フローを開始する前に、`STATE`を生成します。これは、リクエストとコールバックの間で状態を維持するためにクライアントが使用する予測不能な値です。これをCSRFトークンとしても使用する必要があります。

1. 認証コードをリクエストします。これを行うには、次のクエリパラメータを指定して、ユーザーを`/oauth/authorize`ページにリダイレクトする必要があります。

   ```plaintext
   https://gitlab.example.com/oauth/authorize?client_id=APP_ID&redirect_uri=REDIRECT_URI&response_type=code&state=STATE&scope=REQUESTED_SCOPES&root_namespace_id=ROOT_NAMESPACE_ID
   ```

   このページではユーザーに対し、`REQUESTED_SCOPES`で指定されたスコープに基づいて、アプリからアカウントへのアクセスリクエストを承認するように求めます。その後、ユーザーは指定された`REDIRECT_URI`にリダイレクトされます。[スコープパラメータ](../integration/oauth_provider.md#view-all-authorized-applications)は、ユーザーに関連付けられているスコープのスペース区切りのリストです。たとえば`scope=read_user+profile`は、`read_user`スコープと`profile`スコープをリクエストします。`root_namespace_id`は、プロジェクトに関連付けられたルートネームスペースIDです。このオプションのパラメータは、関連付けられたグループに[SAML SSO](../user/group/saml_sso/_index.md)が設定されている場合に使用する必要があります。リダイレクトには認証`code`が含まれます。次に例を示します。

   ```plaintext
   https://example.com/oauth/redirect?code=1234567890&state=STATE
   ```

1. 前のリクエストから返された認証`code`（次の例では`RETURNED_CODE`として示されます）を使用して、任意のHTTPクライアントを使用して`access_token`をリクエストできます。次の例では、Rubyの`rest-client`を使用しています。

   ```ruby
   parameters = 'client_id=APP_ID&client_secret=APP_SECRET&code=RETURNED_CODE&grant_type=authorization_code&redirect_uri=REDIRECT_URI'
   RestClient.post 'https://gitlab.example.com/oauth/token', parameters
   ```

   レスポンス例: 

   ```json
   {
    "access_token": "de6780bc506a0446309bd9362820ba8aed28aa506c71eedbe1c5c4f9dd350e54",
    "token_type": "bearer",
    "expires_in": 7200,
    "refresh_token": "8257e65c97202ed1726cf9571600918f3bffb2544b26e00a61df9897668c33a1",
    "created_at": 1607635748
   }
   ```

1. 新しい`access_token`を取得するには、`refresh_token`パラメータを使用します。リフレッシュトークンは、`access_token`自体が期限切れになった後でも使用可能です。このリクエストは次の処理を行います。
   - 既存の`access_token`と`refresh_token`を無効にします。
   - 応答で新しいトークンを送信します。

   ```ruby
     parameters = 'client_id=APP_ID&client_secret=APP_SECRET&refresh_token=REFRESH_TOKEN&grant_type=refresh_token&redirect_uri=REDIRECT_URI'
     RestClient.post 'https://gitlab.example.com/oauth/token', parameters
   ```

   レスポンス例: 

   ```json
   {
     "access_token": "c97d1fe52119f38c7f67f0a14db68d60caa35ddc86fd12401718b649dcfa9c68",
     "token_type": "bearer",
     "expires_in": 7200,
     "refresh_token": "803c1fd487fec35562c205dac93e9d8e08f9d3652a24079d704df3039df1158f",
     "created_at": 1628711391
   }
   ```

> [!note]
> 元の認可リクエストで使用された`redirect_uri`と`redirect_uri`は一致する必要があります。

これで、返されたアクセストークンを使用してAPIにリクエストを行えるようになります。

### デバイス認可グラントフロー {#device-authorization-grant-flow}

{{< history >}}

- GitLab 17.2で`oauth2_device_grant_flow`[フラグ](../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/332682)されました。
- 17.3ではデフォルトで[有効になっています](https://gitlab.com/gitlab-org/gitlab/-/issues/468479)。
- GitLab 17.9で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/505557)になりました。機能フラグ`oauth2_device_grant_flow`は削除されました。

{{< /history >}}

> [!note]
> デバイス認可グラントフローの詳細な説明については、デバイス認可リクエストからブラウザログインからのトークンレスポンスまで、[RFC仕様](https://datatracker.ietf.org/doc/html/rfc8628#section-3.1)を確認してください。

デバイス認可グラントフローを使うことで、ブラウザ操作ができない入力制限のあるデバイスからでも、安全にGitLabのアイデンティティ認証が可能になります。

そのため、このフローはヘッドレスサーバーや、UIがない、あるいは限られているデバイスからGitLabのサービスを利用しようとするユーザーに最適です。

1. デバイス認可をリクエストするには、インプットが制限されているデバイスクライアントから`https://gitlab.example.com/oauth/authorize_device`にリクエストを送信します。例: 

   ```ruby
     parameters = 'client_id=UID&scope=read'
     RestClient.post 'https://gitlab.example.com/oauth/authorize_device', parameters
   ```

   リクエストが成功すると、`verification_uri`を含む応答がユーザーに返されます。例: 

   ```json
   {
       "device_code": "GmRhmhcxhwAzkoEqiMEg_DnyEysNkuNhszIySk9eS",
       "user_code": "0A44L90H",
       "verification_uri": "https://gitlab.example.com/oauth/device",
       "verification_uri_complete": "https://gitlab.example.com/oauth/device?user_code=0A44L90H",
       "expires_in": 300,
       "interval": 5
   }
   ```

1. デバイスクライアントでは、応答の`user_code`と`verification_uri`がリクエストユーザーに対して表示されます。次に、ブラウザにアクセスできるセカンダリデバイスでユーザーが次の操作を実行します。
   1. 提供されたURIに移動します。
   1. ユーザーコードを入力します。
   1. プロンプトに従って認証を完了します。

1. デバイスクライアントは、`verification_uri`と`user_code`を表示した直後に、初回応答で返された関連付けられている`device_code`を使用して、トークンエンドポイントのポーリングを開始します。

   ```ruby
   parameters = 'grant_type=urn:ietf:params:oauth:grant-type:device_code
   &device_code=GmRhmhcxhwAzkoEqiMEg_DnyEysNkuNhszIySk9eS
   &client_id=1406020730'
   RestClient.post 'https://gitlab.example.com/oauth/token', parameters
   ```

1. デバイスクライアントは、トークンエンドポイントから応答を受信します。認証が成功した場合は成功応答が返され、それ以外の場合はエラー応答が返されます。返される可能性があるエラー応答は、次のいずれかに分類されます。

   - OAuth認可フレームワークアクセストークンのエラー応答によって定義されたもの。
   - ここで説明するデバイス認可グラントフローに固有のもの。

   デバイスフローに固有のエラー応答については、以降で説明します。返される可能性がある応答の詳細については、関連する[デバイス認可グラントのRFC仕様](https://datatracker.ietf.org/doc/html/rfc8628#section-3.5)と[認証トークンのRFC仕様](https://datatracker.ietf.org/doc/html/rfc6749#section-5.2)を参照してください。

   レスポンス例: 

   ```json
   {
     "error": "authorization_pending",
     "error_description": "..."
   }
   ```

   この応答を受信すると、デバイスクライアントはポーリングを続行します。

   ポーリングの間隔が短すぎると、スローダウンエラー応答が返されます。例: 

    ```json
    {
      "error": "slow_down",
      "error_description": "..."
    }
    ```

   この応答を受信すると、デバイスクライアントはポーリングレートを下げ、新しいレートでポーリングを続行します。

   認証が完了する前にデバイスコードが期限切れになると、期限切れトークンエラー応答が返されます。例: 

   ```json
   {
     "error": "expired_token",
     "error_description": "..."
   }
   ```

   この時点でデバイスクライアントは停止し、新しいデバイス認可リクエストを開始します。

   認証リクエストが拒否された場合、アクセス拒否エラー応答が返されます。例: 

   ```json
   {
     "error": "access_denied",
     "error_description": "..."
   }
   ```

   認証リクエストが拒否されました。ユーザーは自分の認証情報を確認するか、システム管理者に連絡する必要があります。

1. ユーザーが正常に認証されると、成功応答が返されます。

   ```json
   {
       "access_token": "TOKEN",
       "token_type": "Bearer",
       "expires_in": 7200,
       "scope": "read",
       "created_at": 1593096829
   }
   ```

この時点でデバイス認証フローは完了です。返された`access_token`トークンは、HTTPS経由での複製やAPIへのアクセスなど、GitLabリソースにアクセスするときに、ユーザーアイデンティティを認証するためにGitLabに提供できます。

クライアント側のデバイスフローを実装するサンプルアプリケーションは、<https://gitlab.com/johnwparent/git-auth-over-https>にあります。

## `access token`を使用してGitLab APIにアクセスする {#access-gitlab-api-with-access-token}

`access token`を使用すると、ユーザーの代理としてAPIにリクエストを行うことができます。トークンをGETパラメータとして渡すことができます。

```plaintext
GET https://gitlab.example.com/api/v4/user?access_token=<OAUTH-TOKEN>
```

また、トークンをAuthorizationヘッダーに配置することもできます。

```shell
curl --header "Authorization: Bearer <OAUTH-TOKEN>" \
  --url "https://gitlab.example.com/api/v4/user"
```

## `access token`を使用してHTTPS経由でGitにアクセスする {#access-git-over-https-with-access-token}

[スコープ](../integration/oauth_provider.md#view-all-authorized-applications)が`read_repository`または`write_repository`のトークンは、HTTPS経由でGitにアクセスできます。トークンをパスワードとして使用します。ユーザー名は任意の文字列値に設定できます。`oauth2`を使用する必要があります。

```plaintext
https://oauth2:<your_access_token>@gitlab.example.com/project_path/project_name.git
```

または、[Git認証情報ヘルパー](../user/profile/account/two_factor_authentication.md#oauth-credential-helpers)を使用して、OAuthでGitLabを認証できます。これにより、OAuthトークンの更新が自動的に処理されます。

## トークン情報を取得する {#retrieve-the-token-information}

トークンの詳細を検証するには、Doorkeeper gemが提供する`token/info`エンドポイントを使用します。詳細については、[`/oauth/token/info`](https://github.com/doorkeeper-gem/doorkeeper/wiki/API-endpoint-descriptions-and-examples#get----oauthtokeninfo)を参照してください。

次のいずれかの方法でアクセストークンを指定する必要があります。

- パラメータとして指定する。

  ```plaintext
  GET https://gitlab.example.com/oauth/token/info?access_token=<OAUTH-TOKEN>
  ```

- ヘッダーに指定する。

  ```shell
  curl --header "Authorization: Bearer <OAUTH-TOKEN>" \
    --url "https://gitlab.example.com/oauth/token/info"
  ```

応答の例を以下に示します。

```json
{
    "resource_owner_id": 1,
    "scope": ["api"],
    "expires_in": null,
    "application": {"uid": "1cb242f495280beb4291e64bee2a17f330902e499882fe8e1e2aa875519cab33"},
    "created_at": 1575890427
}
```

### 非推奨のフィールド {#deprecated-fields}

フィールド`scopes`と`expires_in_seconds`が応答に含まれていますが、現在ではこれらは非推奨となっています。`scopes`フィールドは`scope`エイリアスであり、`expires_in_seconds`フィールドは`expires_in`エイリアスです。詳細については、[Doorkeeper APIの変更点](https://github.com/doorkeeper-gem/doorkeeper/wiki/Migration-from-old-versions#api-changes-5)を参照してください。

## トークンを失効させる {#revoke-a-token}

トークンを失効させるには、`revoke`エンドポイントを使用します。APIは成功を示す応答コード200と空のJSONハッシュを返します。

```ruby
parameters = 'client_id=APP_ID&client_secret=APP_SECRET&token=TOKEN'
RestClient.post 'https://gitlab.example.com/oauth/revoke', parameters
```

## OAuth 2.0トークンとGitLabレジストリ {#oauth-20-tokens-and-gitlab-registries}

標準のOAuth 2.0トークンは、GitLabの各種レジストリに対して異なるレベルのアクセスをサポートします。これらのトークンは、下記のとおり振る舞います。

- 下記のものに対するユーザーによる認証を許可しません。
  - GitLab[コンテナレジストリ](../user/packages/container_registry/authenticate_with_container_registry.md)
  - GitLab[パッケージレジストリ](../user/packages/package_registry/_index.md)にリストされているパッケージ
  - [仮想レジストリ](../user/packages/virtual_registry/_index.md)。
- ユーザーによる[コンテナレジストリAPI](container_registry.md)を介したレジストリの取得、リスト、および削除を許可します。
- ユーザーによる[Maven仮想レジストリAPI](maven_virtual_registries.md)を介したレジストリオブジェクトの取得、一覧表示、および削除を許可します。
