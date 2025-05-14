---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: Third-party authorization to GitLab.
title: OAuth 2.0 Identity Provider API
---

{{< details >}}

- プラン:Free、Premium、Ultimate
- 提供形態:GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

このAPIを使用すると、サードパーティーサービスが[OAuth 2.0](https://oauth.net/2/)プロトコルを使用して、ユーザーのGitLab リソースにアクセスできるようになります。詳細については、[GitLabをOAuth 2.0認証用のIdentity Providerとして設定する](../integration/oauth_provider.md)を参照してください。

この機能は、[doorkeeper Ruby gem](https://github.com/doorkeeper-gem/doorkeeper)に基づいています。

## クロスオリジンリソース共有

{{< history >}}

- CORSプリフライトリクエストのサポートがGitLab 15.1で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/364680)されました。

{{< /history >}}

多くの`/oauth`エンドポイントは、クロスオリジンリソース共有（CORS）をサポートしています。GitLab 15.1以降、次のエンドポイントも[CORSプリフライトリクエスト](https://developer.mozilla.org/en-US/docs/Web/HTTP/CORS)をサポートしています。

- `/oauth/revoke`
- `/oauth/token`
- `/oauth/userinfo`

プリフライトリクエストには、特定のヘッダーのみを使用できます。

- [シンプルなリクエスト](https://developer.mozilla.org/en-US/docs/Web/HTTP/CORS#simple_requests)にリストされているヘッダー。
- `Authorization`ヘッダー。

たとえば、`X-Requested-With`ヘッダーはプリフライトリクエストには使用できません。

## サポートされているOAuth 2.0フロー

GitLabは、次の認可フローをサポートしています。

- **[Proof Key for Code Exchange（PKCE）](https://www.rfc-editor.org/rfc/rfc7636)を使用した認可コード。**最も安全です。PKCEを使用しない場合、モバイルクライアントにクライアントシークレットを含める必要があります。クライアントアプリとサーバーアプリの両方に推奨されます。
- **認可コード:**安全で一般的なフローです。安全なサーバーサイドアプリに推奨されるオプションです。
- **リソースオーナーパスワードクレデンシャル:**安全にホストされているファーストパーティーサービス**のみ**に使用します。GitLabではこのフローの使用を推奨していません。
- **デバイス認可グラント**（GitLab 17.1以降）ブラウザーへのアクセスがないデバイスへのセキュアフロー。この認可フローを完了するにはセカンダリデバイスが必要です。

[OAuth 2.1](https://oauth.net/2.1/)のドラフト仕様では、インプリシットグラントフローとリソースオーナーパスワードクレデンシャルフローの両方が明確に省略されています。

[OAuth RFC](https://www.rfc-editor.org/rfc/rfc6749)を参照して、すべてのフローの仕組みを理解し、各自のユースケースに適したフローを選択してください。

認可コードフローでは（PKCEの有無にかかわらず）、最初にユーザーのアカウントの`/user_settings/applications`ページから`application`を登録する必要があります。登録中に適切なスコープを有効にすることで、`application`がアクセスできるリソースの範囲を制限できます。作成時に`application`認証情報（_アプリケーションID_と_クライアントシークレット_）を取得します。_クライアントシークレット_を**安全に保管する必要があります**。アプリケーションアーキテクチャで許可されている場合は、_アプリケーションID_もシークレットにしておくことをお勧めします。

GitLabのスコープのリストについては、[プロバイダーのドキュメント](../integration/oauth_provider.md#view-all-authorized-applications)を参照してください。

### CSRF攻撃を防ぐ

[リダイレクトベースのフローを保護する](https://datatracker.ietf.org/doc/html/draft-ietf-oauth-security-topics-13#section-3.1)ために、OAuth仕様では、`/oauth/authorize`エンドポイントへの各リクエストで、「ユーザーエージェントに安全にバインドされたstateパラメーターで伝送される1回限りのCSRFトークン」を使用することが推奨されています。これにより、[CSRF攻撃](https://wiki.owasp.org/index.php/Cross-Site_Request_Forgery_(CSRF))を防ぐことができます。

### 本番環境でHTTPSを使用する

本番環境では`redirect_uri`にHTTPSを使用します。GitLabでは、開発環境の場合には安全でないHTTPリダイレクトURIを使用することを許可しています。

OAuth 2.0のセキュリティは完全にトランスポートレイヤに基づいているので、保護されていないURIは使用すべきではありません。詳細については、[OAuth 2.0 RFC](https://www.rfc-editor.org/rfc/rfc6749#section-3.1.2.1)と[OAuth 2.0 Threat Model RFC](https://www.rfc-editor.org/rfc/rfc6819#section-4.4.2.1)を参照してください。

以下のセクションでは、各フローで認可を取得するための詳しい手順を説明します。

### Proof Key for Code Exchange（PKCE）を使用した認証コード

[PKCE RFC](https://www.rfc-editor.org/rfc/rfc7636#section-1.1)には、認可リクエストからアクセストークンまで、詳細なフローの説明が含まれています。以下の手順では、GitLabでのフローの実装について説明します。

PKCEを使用した認可コードフロー（略してPKCE）を使用すると、_クライアントシークレット_へのアクセスを必要とせずに、パブリッククライアントでアクセストークンのクライアント認証情報のOAuth交換を安全に実行できます。これにより、ユーザーからシークレットを保持することが技術的に不可能なシングルページJavaScriptアプリケーションやその他のクライアント側アプリで、PKCEフローが有利になります。

フローを開始する前に、`STATE`、`CODE_VERIFIER`、および`CODE_CHALLENGE`を生成します。

- `STATE`は、リクエストとコールバックの間で状態を維持するためにクライアントが使用する予測不能な値です。これをCSRFトークンとしても使用する必要があります。
- `CODE_VERIFIER`は、長さが43～128文字のランダムな文字列で、文字`A-Z`、`a-z`、`0-9`、`-`、`.`、`_`、および`~`を使用できます。
- `CODE_CHALLENGE`は、`CODE_VERIFIER`のSHA256ハッシュのURLセーフなbase64エンコード文字列です。
  - SHA256ハッシュは、エンコード前にバイナリ形式である必要があります。
  - Rubyでは、`Base64.urlsafe_encode64(Digest::SHA256.digest(CODE_VERIFIER), padding: false)`を使用してこれを設定できます。
  - 参考までに、上記のRubyスニペットを使用してハッシュ化およびエンコードした場合、`CODE_VERIFIER`の文字列`ks02i3jdikdo2k0dkfodf3m39rjfjsdk0wk349rj3jrhf`により、`CODE_CHALLENGE`の文字列`2i0WFA-0AerkjQm4X4oDEhqA17QIAKNjXpagHBXmO_U`が生成されます。

1. 認可コードをリクエストします。このためには、次のクエリパラメーターを指定して、ユーザーを`/oauth/authorize`ページにリダイレクトする必要があります。

   ```plaintext
   https://gitlab.example.com/oauth/authorize?client_id=APP_ID&redirect_uri=REDIRECT_URI&response_type=code&state=STATE&scope=REQUESTED_SCOPES&code_challenge=CODE_CHALLENGE&code_challenge_method=S256
   ```

   このページではユーザーに対し、`REQUESTED_SCOPES`で指定されたスコープに基づいて、アプリからアカウントへのアクセスリクエストを承認するように求めます。その後、ユーザーは指定された`REDIRECT_URI`にリダイレクトされます。[スコープパラメーター](../integration/oauth_provider.md#view-all-authorized-applications)は、ユーザーに関連付けられているスコープのスペース区切りのリストです。たとえば`scope=read_user+profile`は、`read_user`スコープと`profile`スコープをリクエストします。リダイレクトには認可`code`が含まれます。次に例を示しますきるようにします。

   ```plaintext
   https://example.com/oauth/redirect?code=1234567890&state=STATE
   ```

1. 前のリクエストから返された認可`code`（次の例では`RETURNED_CODE`として示されます）を使用して、任意のHTTPクライアントを使用して`access_token`をリクエストできます。次の例では、Ruby の`rest-client`を使用しています。

   ```ruby
   parameters = 'client_id=APP_ID&code=RETURNED_CODE&grant_type=authorization_code&redirect_uri=REDIRECT_URI&code_verifier=CODE_VERIFIER'
   RestClient.post 'https://gitlab.example.com/oauth/token', parameters
   ```

   応答の例:

   ```json
   {
    "access_token": "de6780bc506a0446309bd9362820ba8aed28aa506c71eedbe1c5c4f9dd350e54",
    "token_type": "bearer",
    "expires_in": 7200,
    "refresh_token": "8257e65c97202ed1726cf9571600918f3bffb2544b26e00a61df9897668c33a1",
    "created_at": 1607635748
   }
   ```

1. 新しい`access_token`を取得するには、`refresh_token`パラメーターを使用します。リフレッシュトークンは、`access_token`自体が期限切れになった後でも使用可能です。このリクエストは次の処理を行います。
   - 既存の`access_token`と`refresh_token`を無効にします。
   - 応答で新しいトークンを送信します。

   ```ruby
     parameters = 'client_id=APP_ID&refresh_token=REFRESH_TOKEN&grant_type=refresh_token&redirect_uri=REDIRECT_URI&code_verifier=CODE_VERIFIER'
     RestClient.post 'https://gitlab.example.com/oauth/token', parameters
   ```

   応答の例:

   ```json
   {
     "access_token": "c97d1fe52119f38c7f67f0a14db68d60caa35ddc86fd12401718b649dcfa9c68",
     "token_type": "bearer",
     "expires_in": 7200,
     "refresh_token": "803c1fd487fec35562c205dac93e9d8e08f9d3652a24079d704df3039df1158f",
     "created_at": 1628711391
   }
   ```

{{< alert type="note" >}}

`redirect_uri`は、元の認可リクエストで使用された`redirect_uri`と一致している必要があります。

{{< /alert >}}

これで、アクセストークンを使用してAPIにリクエストを行うことができます。

### 認可コードフロー

{{< alert type="note" >}}

詳細なフローの説明については、[RFC仕様](https://www.rfc-editor.org/rfc/rfc6749#section-4.1)を確認してください。

{{< /alert >}}

この認可コードフローは、基本的に[PKCEを使用した認可コードフロー](#authorization-code-with-proof-key-for-code-exchange-pkce)と同じです。

フローを開始する前に、`STATE`を生成します。これは、リクエストとコールバックの間で状態を維持するためにクライアントが使用する予測不能な値です。これをCSRFトークンとしても使用する必要があります。

1. 認可コードをリクエストします。このためには、次のクエリパラメーターを指定して、ユーザーを`/oauth/authorize`ページにリダイレクトする必要があります。

   ```plaintext
   https://gitlab.example.com/oauth/authorize?client_id=APP_ID&redirect_uri=REDIRECT_URI&response_type=code&state=STATE&scope=REQUESTED_SCOPES
   ```

   このページではユーザーに対し、`REQUESTED_SCOPES`で指定されたスコープに基づいて、アプリからアカウントへのアクセスリクエストを承認するように求めます。その後、ユーザーは指定された`REDIRECT_URI`にリダイレクトされます。[スコープパラメーター](../integration/oauth_provider.md#view-all-authorized-applications)は、ユーザーに関連付けられているスコープのスペース区切りのリストです。たとえば`scope=read_user+profile`は、`read_user`スコープと`profile`スコープをリクエストします。リダイレクトには認可`code`が含まれます。次に例を示しますきるようにします。

   ```plaintext
   https://example.com/oauth/redirect?code=1234567890&state=STATE
   ```

1. 前のリクエストから返された認可`code`（次の例では`RETURNED_CODE`として示されます）を使用して、任意のHTTPクライアントを使用して`access_token`をリクエストできます。次の例では、Ruby の`rest-client`を使用しています。

   ```ruby
   parameters = 'client_id=APP_ID&client_secret=APP_SECRET&code=RETURNED_CODE&grant_type=authorization_code&redirect_uri=REDIRECT_URI'
   RestClient.post 'https://gitlab.example.com/oauth/token', parameters
   ```

   応答の例:

   ```json
   {
    "access_token": "de6780bc506a0446309bd9362820ba8aed28aa506c71eedbe1c5c4f9dd350e54",
    "token_type": "bearer",
    "expires_in": 7200,
    "refresh_token": "8257e65c97202ed1726cf9571600918f3bffb2544b26e00a61df9897668c33a1",
    "created_at": 1607635748
   }
   ```

1. 新しい`access_token`を取得するには、`refresh_token`パラメーターを使用します。リフレッシュトークンは、`access_token`自体が期限切れになった後でも使用可能です。このリクエストは次の処理を行います。
   - 既存の`access_token`と`refresh_token`を無効にします。
   - 応答で新しいトークンを送信します。

   ```ruby
     parameters = 'client_id=APP_ID&client_secret=APP_SECRET&refresh_token=REFRESH_TOKEN&grant_type=refresh_token&redirect_uri=REDIRECT_URI'
     RestClient.post 'https://gitlab.example.com/oauth/token', parameters
   ```

   応答の例:

   ```json
   {
     "access_token": "c97d1fe52119f38c7f67f0a14db68d60caa35ddc86fd12401718b649dcfa9c68",
     "token_type": "bearer",
     "expires_in": 7200,
     "refresh_token": "803c1fd487fec35562c205dac93e9d8e08f9d3652a24079d704df3039df1158f",
     "created_at": 1628711391
   }
   ```

{{< alert type="note" >}}

`redirect_uri`は、元の認可リクエストで使用された`redirect_uri`と一致している必要があります。

{{< /alert >}}

これで、返されたアクセストークンを使用してAPIにリクエストを行うことができます。

### デバイス認可グラントフロー

{{< history >}}

- GitLab 17.2で`oauth2_device_grant_flow`[フラグを使用して](../administration/feature_flags.md)[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/332682)されました。
- 17.3ではデフォルトで[有効になっています](https://gitlab.com/gitlab-org/gitlab/-/issues/468479)。
- GitLab 17.9で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/505557)になりました。機能フラグ`oauth2_device_grant_flow`が削除されました。

{{< /history >}}

{{< alert type="note" >}}

デバイス認可リクエストから、ブラウザーログインからのトークン応答まで、デバイス認可グラントフローの詳細な説明については、[RFC 仕様](https://datatracker.ietf.org/doc/html/rfc8628#section-3.1)を確認してください。

{{< /alert >}}

デバイス認可グラントフローを使用すると、ブラウザーの操作を使用できない、入力が制約されたデバイスからGitLabアイデンティティを安全に認証できます。

このため、デバイス認可グラントフローは、UIがないかまたは制限されているヘッドレスサーバーやその他のデバイスからGitLabサービスを使用しようとしているユーザーに最適です。

1. デバイス認可をリクエストするには、入力が制限されているデバイスクライアントから`https://gitlab.example.com/oauth/authorize_device`にリクエストを送信します。次に例を示します。

   ```ruby
     parameters = 'client_id=UID&scope=read'
     RestClient.post 'https://gitlab.example.com/oauth/authorize_device', parameters
   ```

   リクエストが成功すると、`verification_uri`を含む応答がユーザーに返されます。次に例を示します。

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

1. デバイスクライアントでは、応答の`user_code`と`verification_uri`がリクエストユーザーに対して表示されます。次に、ブラウザーにアクセスできるセカンダリデバイスでユーザーが次の操作を実行します。
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

1. デバイスクライアントは、トークンエンドポイントから応答を受信します。認可が成功した場合は成功応答が返され、それ以外の場合はエラー応答が返されます。返される可能性があるエラー応答は、次のいずれかに分類されます。
   - OAuth認可フレームワークアクセストークンのエラー応答によって定義されたもの。
   - ここで説明するデバイス認可グラントフローに固有のもの。デバイスフローに固有のエラー応答については、以降で説明します。返される可能性がある応答の詳細については、関連する[デバイス認可グラントのRFC仕様](https://datatracker.ietf.org/doc/html/rfc8628#section-3.5)と[認証トークンのRFC仕様](https://datatracker.ietf.org/doc/html/rfc6749#section-5.2)を参照してください。

   応答の例:

   ```json
   {
     "error": "authorization_pending",
     "error_description": "..."
   }
   ```

   この応答を受信すると、デバイスクライアントはポーリングを続行します。

   ポーリングの間隔が短すぎると、スローダウンエラー応答が返されます。次に例を示します。

    ```json
    {
      "error": "slow_down",
      "error_description": "..."
    }
    ```

   この応答を受信すると、デバイスクライアントはポーリングレートを下げ、新しいレートでポーリングを続行します。

   認証が完了する前にデバイスコードが期限切れになると、期限切れトークンエラー応答が返されます。次に例を示します。

   ```json
   {
     "error": "expired_token",
     "error_description": "..."
   }
   ```

   この時点でデバイスクライアントは停止し、新しいデバイス認可リクエストを開始します。

   認可リクエストが拒否された場合、アクセス拒否エラー応答が返されます。次に例を示します。

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

この時点でデバイス認証フローは完了です。返された`access_token`は、HTTPS経由でのクローンやAPIへのアクセスなど、GitLabリソースにアクセスするときに、ユーザーアイデンティティを認証するためにGitLabに提供できます。

クライアント側のデバイスフローを実装するサンプルアプリケーションは、<https://gitlab.com/johnwparent/git-auth-over-https>にあります。

### リソースオーナーパスワードクレデンシャルフロー

{{< alert type="note" >}}

詳細なフローの説明については、[RFC仕様](https://www.rfc-editor.org/rfc/rfc6749#section-4.3)を確認してください。

{{< /alert >}}

{{< alert type="note" >}}

リソースオーナーパスワードクレデンシャルは、[2要素認証](../user/profile/account/two_factor_authentication.md)が有効になっているユーザーと、[グループに対してパスワード認証が無効になっている](../user/enterprise_user/_index.md#disable-password-authentication-for-enterprise-users)[エンタープライズユーザー](../user/enterprise_user/_index.md)に対しては無効になっています。これらのユーザーは、代わりに[パーソナルアクセストークン](../user/profile/personal_access_tokens.md)を使用してAPIにアクセスできます。{{< /alert >}}

{{< alert type="note" >}}

パスワードクレデンシャルフローをサポートするため、GitLabインスタンスで[**Git over HTTP(S)のパスワード認証を許可する**](../administration/settings/sign_in_restrictions.md#password-authentication-enabled)チェックボックスがオンになっていることを確認してください。{{< /alert >}}

このフローでは、リソースオーナー認証情報（ユーザー名とパスワード）と引き換えにトークンがリクエストされます。

この認証情報は、次の場合にのみ使用してください。

- リソースオーナーとクライアントの間に高度な信頼関係がある。たとえば、クライアントがデバイスオペレーティングシステムまたは高度な特権付きアプリケーションの一部である場合などです。
- ほかの認可付与タイプ（認可コードなど）は使用できません。

{{< alert type="warning" >}}

ユーザーの認証情報を保存しないでください。また、信頼できる環境にクライアントがデプロイされている場合にのみ、この付与タイプを使用してください。99％の割合で、[パーソナルアクセストークン](../user/profile/personal_access_tokens.md)の方が適しています。

{{< /alert >}}

この付与タイプでも、リソースオーナー認証情報へのクライアントの直接アクセスが必要ですが、リソースオーナー認証情報は1つのリクエストに使用され、アクセストークンと交換されます。この付与タイプを使用すると、認証情報を有効期間の長いアクセストークンまたはリフレッシュトークンと交換することで、クライアントが将来使用するためにリソースオーナー認証情報を保存する必要がなくなります。

アクセストークンをリクエストするには、`/oauth/token`に対して次のパラメーターを指定したPOSTリクエストを行う必要があります。

```json
{
  "grant_type"    : "password",
  "username"      : "user@example.com",
  "password"      : "secret"
}
```

cURLリクエストの例:

```shell
echo 'grant_type=password&username=<your_username>&password=<your_password>' > auth.txt
curl --data "@auth.txt" --request POST "https://gitlab.example.com/oauth/token"
```

登録済みのOAuthアプリケーションでこの付与フローを使用することもできます。このためにはアプリケーションの`client_id`と`client_secret`でHTTP基本認証を使用します。

```shell
echo 'grant_type=password&username=<your_username>&password=<your_password>' > auth.txt
curl --data "@auth.txt" --user client_id:client_secret \
     --request POST "https://gitlab.example.com/oauth/token"
```

次に、アクセストークンを含む応答を受信します。

```json
{
  "access_token": "1f0af717251950dbd4d73154fdf0a474a5c5119adad999683f5b450c460726aa",
  "token_type": "bearer",
  "expires_in": 7200
}
```

デフォルトでは、アクセストークンのスコープは`api`であり、完全な読み取り/書き込みアクセスを提供します。

テストには`oauth2` Ruby gemを使用できます。

```ruby
client = OAuth2::Client.new('the_client_id', 'the_client_secret', :site => "https://example.com")
access_token = client.password.get_token('user@example.com', 'secret')
puts access_token.token
```

## `access token`を使用してGitLab APIにアクセスする

`access token`を使用すると、ユーザーの代理としてAPIにリクエストを行うことができます。トークンをGETパラメーターとして渡すことができます。

```plaintext
GET https://gitlab.example.com/api/v4/user?access_token=OAUTH-TOKEN
```

また、トークンをAuthorizationヘッダーに配置することもできます。

```shell
curl --header "Authorization: Bearer OAUTH-TOKEN" "https://gitlab.example.com/api/v4/user"
```

## `access token`を使用してHTTPS経由でGitにアクセスする

[スコープ](../integration/oauth_provider.md#view-all-authorized-applications)が`read_repository`または`write_repository`のトークンは、HTTPS経由でGitにアクセスできます。トークンをパスワードとして使用します。ユーザー名は任意の文字列値に設定できます。`oauth2`を使用する必要があります。

```plaintext
https://oauth2:<your_access_token>@gitlab.example.com/project_path/project_name.git
```

または[Git認証情報ヘルパー](../user/profile/account/two_factor_authentication.md#oauth-credential-helpers)を使用して、OAuthでGitLabを認証できます。これにより、OAuthトークンの更新が自動的に処理されます。

## トークン情報を取得する

トークンの詳細を確認するには、Doorkeeper gemによって提供される`token/info`エンドポイントを使用します。詳細については、[`/oauth/token/info`](https://github.com/doorkeeper-gem/doorkeeper/wiki/API-endpoint-descriptions-and-examples#get----oauthtokeninfo)を参照してください。

次のいずれかの方法でアクセストークンを指定する必要があります。

- パラメーターとして指定する。

  ```plaintext
  GET https://gitlab.example.com/oauth/token/info?access_token=<OAUTH-TOKEN>
  ```

- Authorization ヘッダーに指定する。

  ```shell
  curl --header "Authorization: Bearer <OAUTH-TOKEN>" "https://gitlab.example.com/oauth/token/info"
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

### 非推奨のフィールド

フィールド`scopes`と`expires_in_seconds`が応答に含まれていますが、現在ではこれらは非推奨となっています。`scopes`フィールドは`scope`のエイリアスであり、`expires_in_seconds`フィールドは`expires_in`のエイリアスです。詳細については、[Doorkeeper APIの変更点](https://github.com/doorkeeper-gem/doorkeeper/wiki/Migration-from-old-versions#api-changes-5)を参照してください。

## トークンを失効させる

トークンを失効させるには、`revoke`エンドポイントを使用します。APIは成功を示す応答コード200と空のJSONハッシュを返します。

```ruby
parameters = 'client_id=APP_ID&client_secret=APP_SECRET&token=TOKEN'
RestClient.post 'https://gitlab.example.com/oauth/revoke', parameters
```

## OAuth 2.0トークンとGitLabレジストリ

標準のOAuth 2.0トークンは次のようにすることで、GitLabレジストリへのさまざまなレベルのアクセスをサポートしています。

- ユーザーが次のものに対して認証することを許可しません。
  - GitLab[コンテナレジストリ](../user/packages/container_registry/authenticate_with_container_registry.md)。
  - GitLab[パッケージレジストリ](../user/packages/package_registry/_index.md)にリストされているパッケージ。
- ユーザーが[コンテナレジストリAPI](container_registry.md)を介してレジストリを取得、リスト、および削除することを許可します。
