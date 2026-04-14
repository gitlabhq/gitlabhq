---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: SAMLのトラブルシューティング
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

このページには、以下の使用時に遭遇する可能性のある問題に対する解決策が記載されています:

- [GitLab.comグループ向けのSAML SSO](_index.md)。
- GitLab Self-Managedインスタンスレベルの[SAML OmniAuthプロバイダー](../../../integration/saml.md)。
- GitLab DedicatedインスタンスのSAMLを[Switchboard](../../../administration/dedicated/configure_instance/authentication/saml.md#add-a-saml-provider-with-switchboard)で設定する。

## SAMLのデバッグツール {#saml-debugging-tools}

SAMLレスポンスはbase64エンコードされています。これらをオンザフライでデコードするには、**SAML-tracer**ブラウザ拡張機能（[Firefox](https://addons.mozilla.org/en-US/firefox/addon/saml-tracer/) 、[Chrome](https://chromewebstore.google.com/detail/saml-tracer/mpdajninpobndbfcldcmbpnnbhibjmch?hl=en)）を使用できます。

ブラウザプラグインをインストールできない場合は、代わりに[SAMLレスポンスを手動で生成して取得](#manually-generate-a-saml-response)できます。

次の点に特に注意してください:

- サインインするユーザーを識別する`NameID`。ユーザーが以前にサインインしている場合、これは[GitLabが保存した](#verify-nameid)値と一致する必要があります。
- レスポンス署名を検証するために必要な`X509Certificate`の存在。
- `SubjectConfirmation`および`Conditions`は、設定が誤っているとエラーを引き起こす可能性があります。

### SAMLレスポンスを生成する {#generate-a-saml-response}

SAMLレスポンスを使用して、Identity Providerでサインインを試行する際にアサーションリストで送信される属性名と値をプレビューします。

SAMLレスポンスを生成するには:

1. [ブラウザのデバッグツール](#saml-debugging-tools)のいずれかをインストールします。
1. 新しいブラウザタブを開きます。
1. SAMLトレーサーコンソールを開きます:
   - Chrome: ページ上のコンテキストメニューで**Inspect**を選択し、開発者コンソールで**SAML**タブを選択します。
   - Firefox: ブラウザのツールバーにあるSAML-tracerアイコンを選択します。
1. GitLab.comグループの場合:
   - グループのGitLabシングルサインオンURLにアクセスします。
   - **許可する**を選択するか、サインインを試行します。
1. GitLab Self-Managedインスタンスの場合:
   - インスタンスのホームページにアクセスします。
   - サインインするには`SAML Login`ボタンを選択します。
1. SAMLトレーサーコンソールに、この[例のSAMLレスポンス](_index.md#example-saml-response)に似たSAMLレスポンスが表示されます。
1. SAMLトレーサー内で、**エクスポート**アイコンを選択してレスポンスをJSON形式で保存します。

#### SAMLレスポンスを手動で生成する {#manually-generate-a-saml-response}

<i class="fa-youtube-play" aria-hidden="true"></i>概要については、GitLabサポートがアップロードした、[ブラウザプラグインを使用せずにSAMLレスポンスを手動で生成する方法（Google Chromeを使用）に関するこのビデオ](https://youtu.be/umMPj6ohF_I)をご覧ください。
<!-- Video published on 2024-09-09 -->

どのブラウザを使用しても、プロセスは次のとおりです:

1. 新しいブラウザを右クリックし、**Inspect**を選択して**DevTools**ウィンドウを開きます。
1. **ネットワーク**タブを選択します。**Preserve log**が選択されていることを確認します。
1. ブラウザページに切り替えて、SAML SSOを使用してGitLabにサインインします。
1. **DevTools**ウィンドウに戻り、`callback`イベントをフィルタリングします。
1. コールバックイベントの**Payload**タブを選択し、右クリックして値をコピーします。
1. この値を次のコマンドに貼り付けます: `echo "<value>" | base64 --decode > saml_response.xml`。
1. `saml_response.xml`をコードエディタで開きます。

   コードエディタにXMLの「prettifier」がインストールされている場合は、レスポンスを読みやすく自動的にフォーマットできるはずです。

## SAMLサインインのRailsログを検索する {#search-rails-logs-for-a-saml-sign-in}

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

SAMLサインインに関する詳細情報は、[`audit_json.log`ファイル](../../../administration/logs/_index.md#audit_jsonlog)で確認できます。

たとえば、`system_access`を検索することで、GitLabにSAMLを使用してサインインしたユーザーのエントリを見つけることができます:

```json
{
  "severity": "INFO",
  "time": "2024-08-13T06:05:35.721Z",
  "correlation_id": "01J555EZK136DQ8S7P32G9GEND",
  "meta.caller_id": "OmniauthCallbacksController#saml",
  "meta.remote_ip": "45.87.213.198",
  "meta.feature_category": "system_access",
  "meta.user": "bbtest",
  "meta.user_id": 16,
  "meta.client_id": "user/16",
  "author_id": 16,
  "author_name": "bbtest@agounder.onmicrosoft.com",
  "entity_id": 16,
  "entity_type": "User",
  "created_at": "2024-08-13T06:05:35.708+00:00",
  "ip_address": "45.87.213.198",
  "with": "saml",
  "target_id": 16,
  "target_type": "User",
  "target_details": "bbtest@agounder.onmicrosoft.com",
  "entity_path": "bbtest"
}
```

SAMLグループリンクを設定している場合、ログにはグループメンバーシップが削除されたことを詳述するエントリも表示されます:

```json
{
  "severity": "INFO",
  "time": "2024-08-13T05:24:07.769Z",
  "correlation_id": "01J55330SRTKTD5CHMS96DNZEN",
  "meta.caller_id": "Auth::SamlGroupSyncWorker",
  "meta.remote_ip": "45.87.213.206",
  "meta.feature_category": "system_access",
  "meta.client_id": "ip/45.87.213.206",
  "meta.root_caller_id": "OmniauthCallbacksController#saml",
  "id": 179,
  "author_id": 6,
  "entity_id": 2,
  "entity_type": "Group",
  "details": {
    "remove": "user_access",
    "member_id": 7,
    "author_name": "BB Test",
    "author_class": "User",
    "target_id": 6,
    "target_type": "User",
    "target_details": "BB Test",
    "custom_message": "Membership destroyed",
    "ip_address": "45.87.213.198",
    "entity_path": "group1"
  }
}
```

GitLabがSAMLプロバイダーから受け取ったユーザーの詳細は、`auth_json.log`でも確認できます。例:

```json
{
  "severity": "INFO",
  "time": "2024-08-20T07:01:20.979Z",
  "correlation_id": "01J5Q9E59X4P40ZT3MCE35C2A9",
  "meta.caller_id": "OmniauthCallbacksController#saml",
  "meta.remote_ip": "xxx.xxx.xxx.xxx",
  "meta.feature_category": "system_access",
  "meta.client_id": "ip/xxx.xxx.xxx.xxx",
  "payload_type": "saml_response",
  "saml_response": {
    "issuer": [
      "https://sts.windows.net/03b8c6c5-104b-43e2-aed3-abb07df387cc/"
    ],
    "name_id": "ab260d59-0317-47f5-9afb-885c7a1257ab",
    "name_id_format": "urn:oasis:names:tc:SAML:2.0:nameid-format:persistent",
    "name_id_spnamequalifier": null,
    "name_id_namequalifier": null,
    "destination": "https://dh-gitlab.agounder.com/users/auth/saml/callback",
    "audiences": [
      "https://dh-gitlab.agounder.com/16.11.6"
    ],
    "attributes": {
      "http://schemas.microsoft.com/identity/claims/tenantid": [
        "03b8c6c5-104b-43e2-aed3-abb07df387cc"
      ],
      "http://schemas.microsoft.com/identity/claims/objectidentifier": [
        "ab260d59-0317-47f5-9afb-885c7a1257ab"
      ],
      "http://schemas.microsoft.com/identity/claims/identityprovider": [
        "https://sts.windows.net/03b8c6c5-104b-43e2-aed3-abb07df387cc/"
      ],
      "http://schemas.microsoft.com/claims/authnmethodsreferences": [
        "http://schemas.microsoft.com/ws/2008/06/identity/authenticationmethod/password"
      ],
      "email": [
        "bbtest@agounder.com"
      ],
      "firstname": [
        "BB"
      ],
      "name": [
        "bbtest@agounder.onmicrosoft.com"
      ],
      "lastname": [
        "Test"
      ]
    },
    "in_response_to": "_f8863f68-b5f1-43f0-9534-e73933e6ed39",
    "allowed_clock_drift": 2.220446049250313e-16,
    "success": true,
    "status_code": "urn:oasis:names:tc:SAML:2.0:status:Success",
    "status_message": null,
    "session_index": "_b4f253e2-aa61-46a4-902b-43592fe30800",
    "assertion_encrypted": false,
    "response_id": "_392cc747-7c8b-41de-8be0-23f5590d5ded",
    "assertion_id": "_b4f253e2-aa61-46a4-902b-43592fe30800"
  }
}
```

## GitLab SAMLのテスト {#testing-gitlab-saml}

SAMLのトラブルシューティングを行うには、次のいずれかを使用できます:

- Docker Composeを使用した、[完全なGitLabのSAMLテスト環境](https://gitlab.com/gitlab-com/support/toolbox/replication/tree/master/compose_files)。
- SAMLプロバイダーのみが必要な場合は、プラグアンドプレイのSAML 2.0 Identity Providerで[Dockerコンテナを起動するクイックスタートガイド](../../../administration/troubleshooting/test_environments.md#saml)。
- [GitLab Self-ManagedインスタンスでグループのSAMLを有効にすること](../../../integration/saml.md#configure-group-saml-sso-on-gitlab-self-managed)によるローカル環境。

## 設定を検証する {#verify-configuration}

便宜上、GitLabサポートチームが使用するいくつかの[例示リソース](example_saml_config.md)が含まれています。これらはSAMLアプリケーションの設定の検証に役立つかもしれませんが、サードパーティ製品の現在の状態を反映している保証はありません。

### フィンガープリントを計算する {#calculate-the-fingerprint}

`idp_cert_fingerprint`を設定する際は、可能な限りSHA256フィンガープリントを使用する必要があります。SHA1もサポートされていますが、推奨されません。フィンガープリントを計算するには、証明書ファイルで次のコマンドを実行します:

```shell
openssl x509 -in <certificate.crt> -noout -fingerprint -sha256
```

`<certificate.crt>`を証明書ファイルの名前に置き換えます。

> [!note]
> 
> GitLab 17.11以降では、フィンガープリントの長さに基づいてフィンガープリントアルゴリズムが[自動的に検出されます](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/184530)。
>
> GitLab 17.10以前では、SHA1がデフォルトのフィンガープリントアルゴリズムです。SHA256フィンガープリントを使用するには、アルゴリズムを指定する必要があります:
>
> ```ruby
> idp_cert_fingerprint_algorithm: "http://www.w3.org/2001/04/xmlenc#sha256"
> ```

## SSO証明書の更新 {#sso-certificate-updates}

Identity Providerに使用される証明書が変更されると（たとえば、証明書の更新または再発行時）、証明書フィンガープリントも更新する必要があります。証明書フィンガープリントは、Identity ProviderのUIで見つけることができます。Identity Provider UIで証明書を取得できない場合は、[フィンガープリントを計算する](#calculate-the-fingerprint)ドキュメントの手順に従ってください。

## 設定エラー {#configuration-errors}

### 無効なオーディエンス {#invalid-audience}

このエラーは、Identity ProviderがGitLabをSAMLリクエストの有効な送信者および受信者として認識していないことを意味します。次のことを確認してください:

- GitLabコールバックURLをIdentity Providerサーバーの承認されたオーディエンスに追加します。
- `issuer`文字列の末尾の空白を避けます。

### キー検証エラー、ダイジェスト不一致、またはフィンガープリント不一致 {#key-validation-error-digest-mismatch-or-fingerprint-mismatch}

これらのエラーはすべて、SAML証明書という同様の原因から発生します。SAMLリクエストは、フィンガープリント、証明書、またはバリデーターのいずれかを使用して検証される必要があります。

この要件については、次の点を考慮してください:

- フィンガープリントを使用する場合は、SHA256フィンガープリントを確認します:
  1. 証明書ファイルを再ダウンロードします。
  1. [フィンガープリントを計算します](#calculate-the-fingerprint)。
  1. フィンガープリントを`idp_cert_fingerprint`で提供される値と比較します。値は同じである必要があります。
- 設定で証明書が提供されていない場合、フィンガープリントまたはフィンガープリントバリデーターを提供する必要があり、サーバーからのレスポンスには証明書（`<ds:KeyInfo><ds:X509Data><ds:X509Certificate>`）が含まれている必要があります。
- 設定で証明書が提供されている場合、リクエストに証明書が含まれている必要はありません。この場合、フィンガープリントまたはフィンガープリントバリデーターはオプションです。

以前に説明したシナリオのいずれも有効でない場合、リクエストは言及されたエラーのいずれかで失敗します。

### 欠落しているクレーム、または`Email can't be blank`エラー {#missing-claims-or-email-cant-be-blank-errors}

GitLabがアカウントを作成するか、ログイン情報を既存のアカウントと照合するために、Identity Providerサーバーは特定の情報を渡す必要があります。`email`は、渡す必要がある情報量の最低限です。Identity Providerサーバーがこの情報を提供していない場合、すべてのSAMLリクエストは失敗します。

この情報が提供されていることを確認してください。

このエラーの原因となる別の問題は、Identity Providerから正しい情報が送信されているにもかかわらず、属性がOmniAuth `info`ハッシュ内の名前と一致しない場合です。この場合、SAML設定で`attribute_statements`を設定して、[SAMLレスポンスの属性名を対応するOmniAuth `info`ハッシュ名にマップする](../../../integration/saml.md#map-saml-response-attribute-names)必要があります。

## ユーザーサインインバナーエラーメッセージ {#user-sign-in-banner-error-messages}

### メッセージ: `SAML authentication failed: SAML NameID is missing from your SAML response.` {#message-saml-authentication-failed-saml-nameid-is-missing-from-your-saml-response}

`SAML authentication failed: SAML NameID is missing from your SAML response. Please contact your administrator.`というエラーが表示されることがあります。

この問題は、グループSSOを使用してGitLabにサインインしようとしたときに、SAMLレスポンスに`NameID`が含まれていなかった場合に発生します。

この問題を解決するには、次の手順に従います:

- 管理者に連絡して、IdPアカウントに`NameID`が割り当てられていることを確認してください。
- [SAMLデバッグツール](#saml-debugging-tools)を使用して、SAMLレスポンスに有効な`NameID`が含まれていることを検証します。

### メッセージ: `SAML authentication failed: Extern uid has already been taken.` {#message-saml-authentication-failed-extern-uid-has-already-been-taken}

`SAML authentication failed: Extern uid has already been taken. Please contact your administrator to generate a unique external_uid (NameID).`というエラーが表示されることがあります。

この問題は、既存のGitLabアカウントをグループSSOを使用してSAML IDにリンクしようとしたときに、現在の`NameID`を持つ既存のGitLabアカウントが存在する場合に発生します。

この問題を解決するには、管理者に、IdPアカウントの一意の`Extern UID`（`NameID`）を再生成するように指示してください。この新しい`Extern UID`が、[GitLabの`NameID`制約](_index.md#manage-user-saml-identity)に準拠していることを確認してください。

そのGitLabユーザーをSAMLログインで使用したくない場合は、[GitLabアカウントをSAMLアプリケーションからリンク解除](_index.md#unlink-accounts)できます。

### メッセージ: `SAML authentication failed: User has already been taken` {#message-saml-authentication-failed-user-has-already-been-taken}

サインインしているユーザーは、すでにSAMLが別のIDにリンクされているか、`NameID`の値が変更されています。考えられる原因と解決策は次のとおりです:

| 原因                                                                                          | 解決策 |
|------------------------------------------------------------------------------------------------|----------|
| 特定のIdentity Providerに対して、複数のSAML IDを同じユーザーにリンクしようとしました。 | サインインするIDを変更します。そうするには、再度サインインを試行する前に、このGitLabアカウントから[以前のSAML IDをリンク解除](_index.md#unlink-accounts)します。 |
| ユーザーがSSOによる識別をリクエストするたびに、`NameID`が変更されます。                           | [`NameID`](#verify-nameid)が`Transient`形式で設定されていないこと、または`NameID`がその後のリクエストで変更されないことを確認してください。 |

### メッセージ: `SAML authentication failed: Email has already been taken` {#message-saml-authentication-failed-email-has-already-been-taken}

| 原因                                                                                                                | 解決策 |
|----------------------------------------------------------------------------------------------------------------------|----------|
| 同じメールアドレスを持つGitLabユーザーアカウントが存在するものの、そのアカウントがSAML IDに関連付けられていない場合。 | GitLab.comでは、ユーザーは[アカウントをリンク](_index.md#user-access-and-management)する必要があります。GitLab Self-Managedでは、管理者はインスタンスを設定して、初回サインイン時に[SAML IDをGitLabユーザーアカウントに自動的にリンク](../../../integration/saml.md#link-saml-identity-for-an-existing-user)できます。 |

ユーザーアカウントは次のいずれかの方法で作成されます:

- ユーザー登録
- OAuth経由でのサインイン
- SAML経由でのサインイン
- SCIMプロビジョニング

### エラー: ユーザーはすでに存在します {#error-user-has-already-been-taken}

これら両方のエラーが同時に発生する場合、Identity Providerによって提供される`NameID`の大文字/小文字の区別が、そのユーザーの以前の値と正確に一致しなかったことが示唆されます:

- `SAML authentication failed: Extern UID has already been taken`
- `User has already been taken`

これは、`NameID`が一貫した値を返すように設定することで防ぐことができます。個々のユーザーに対してこれを修正するには、ユーザーの識別子を変更するプロセスが含まれます。GitLab.comでは、ユーザーは[SAMLをGitLabアカウントからリンク解除](_index.md#unlink-accounts)する必要があります。

### メッセージ: `Request to link SAML account must be authorized` {#message-request-to-link-saml-account-must-be-authorized}

GitLabアカウントをリンクしようとしているユーザーが、Identity ProviderのSAMLアプリケーション内でユーザーとして追加されていることを確認してください。

あるいは、SAMLレスポンスに`samlp:Response`タグの`InResponseTo`属性が欠落している可能性があり、これは[SAML gemによって期待されます](https://github.com/onelogin/ruby-saml/blob/9f710c5028b069bfab4b9e2b66891e0549765af5/lib/onelogin/ruby-saml/response.rb#L307-L316)。Identity Provider管理者は、ログインがIdentity Providerだけでなくサービスプロバイダーによって開始されることを確認する必要があります。

### メッセージ: `There is already a GitLab account associated with this email address.` {#message-there-is-already-a-gitlab-account-associated-with-this-email-address}

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com

{{< /details >}}

ユーザーが[既存のGitLab.comアカウントにSAMLを手動でリンク](_index.md#link-saml-to-your-existing-gitlabcom-account)しようとすると、このメッセージが表示されることがあります:

```plaintext
There is already a GitLab account associated with this email address.
Sign in with your existing credentials to connect your organization's account
```

この問題を解決するには、ユーザーは正しいGitLabパスワードを使用してサインインしていることを確認する必要があります。次の両方の場合、ユーザーはまず[パスワードをリセット](https://gitlab.com/users/password/new)する必要があります:

- アカウントがSCIMによってプロビジョニングされた場合。
- 初めてユーザー名とパスワードでサインインしている場合。

### メッセージ: `SAML Name ID and email address do not match your user account` {#message-saml-name-id-and-email-address-do-not-match-your-user-account}

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com

{{< /details >}}

ユーザーに「SAML Name IDとメールアドレスがユーザーアカウントと一致しません。管理者に連絡してください。」というエラーが表示されることがあります。これは、次の意味をもちます。

- SAMLによって送信されたNameID値が、既存のSAML IDの`extern_uid`値と一致しません。NameIDと`extern_uid`の両方は大文字と小文字を区別します。詳細については、[ユーザーSAMLアイデンティティの管理](_index.md#manage-user-saml-identity)を参照してください。
- SAMLレスポンスにメールアドレスが含まれていなかったか、またはメールアドレスがユーザーのGitLabメールアドレスと一致しませんでした。

回避策として、GitLabグループオーナーが[SAML API](../../../api/saml.md)を使用して、ユーザーのSAML `extern_uid`を更新します。`extern_uid`値は、SAML Identity Provider（IdP）によって送信されたName ID値と一致する必要があります。IdPの設定によっては、これは生成された一意のID、メールアドレス、またはその他の値である場合があります。

### エラー: `Certificate element missing in response (ds:x509certificate)` {#error-certificate-element-missing-in-response-dsx509certificate}

このエラーは、IdPがSAMLレスポンスにX.509証明書を含めるように設定されていないことを示唆しています:

```plaintext
Certificate element missing in response (ds:x509certificate) and not cert provided at settings
```

X.509証明書をレスポンスに含める必要があります。この問題を解決するには、IdPを設定して、SAMLレスポンスにX.509証明書を含めるようにします。

詳細については、[IdP上のSAMLアプリケーションの追加設定](../../../integration/saml.md#additional-configuration-for-saml-apps-on-your-idp)に関するドキュメントを参照してください。

## その他のユーザーサインイン問題 {#other-user-sign-in-issues}

### `NameID`の検証 {#verify-nameid}

トラブルシューティングにおいて、すべての認証済みユーザーは、[`https://gitlab.com/api/v4/user`](https://gitlab.com/api/v4/user)にアクセスし、IDの下の`extern_uid`を確認することで、GitLabがすでにユーザーにリンクしている`NameID`をAPIを使用して検証できます。

GitLab Self-Managedでは、管理者は[ユーザーAPI](../../../api/users.md)を使用して同じ情報を確認できます。

グループでSAMLを使用する場合、適切な権限を持つロールのグループメンバーは、[メンバーAPI](../../../api/group_members.md)を利用して、グループのメンバーのグループSAML ID情報を表示できます。

これは、[SAMLデバッグツール](#saml-debugging-tools)でメッセージをデコードすることで、Identity Providerによって送信された`NameID`と比較できます。これらの値は、ユーザーを識別するために一致する必要があります。

### ログインの「ループ」にはまる {#stuck-in-a-login-loop}

**GitLabシングルサインオンURL**またはGitLab Self-Managedの場合のインスタンスURLが、Identity ProviderのSAMLアプリで「Login URL」（または同様の名称のフィールド）として設定されていることを確認してください。

GitLab.comの場合、あるいは、ユーザーが[既存のGitLab.comアカウントにSAMLをリンクする](_index.md#link-saml-to-your-existing-gitlabcom-account)必要がある場合は、**GitLabシングルサインオンURL**を提供し、初回サインイン時にSAMLアプリケーションを使用しないようにユーザーに指示します。

### ユーザーが404を受信する {#users-receive-a-404}

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com

{{< /details >}}

ユーザーが正常にサインインした後で`404`を受信した場合、IP制限が設定されているか確認してください。IP制限設定は次のように設定されます:

- GitLab.comでは、[グループレベル](../access_and_permissions.md#restrict-group-access-by-ip-address)で。
- GitLab Self-Managedでは、[インスタンスレベル](../../../administration/reporting/ip_addr_restrictions.md)で。

グループのSAML SSOは有料機能であるため、サブスクリプションの期限切れにより、GitLab.comでSAML SSOを使用してサインインする際に`404`エラーが発生する可能性があります。すべてのユーザーがSAMLを使用してサインインしようとしている際に`404`を受信している場合、このSAML SSOネームスペースで[アクティブなサブスクリプションが存在](../../../subscriptions/manage_subscription.md#view-subscription)することを確認してください。

「設定を検証」を使用するセットアップ中に`404`を受信した場合は、正しい[SHA-1で生成されたフィンガープリント](../../../integration/saml.md#configure-saml-on-your-idp)を使用していることを確認してください。

ユーザーが初めてサインインしようとしていて、GitLabシングルサインオンURLが[設定されていない](_index.md#set-up-your-identity-provider)場合、404が表示されることがあります。[ユーザーアクセスセクション](_index.md#link-saml-to-your-existing-gitlabcom-account)で概説されているように、グループオーナーはユーザーにURLを提供する必要があります。

トップレベルグループが[メールドメインによるグループメンバーシップを制限](../access_and_permissions.md#restrict-group-access-by-domain)しており、許可されていないメールドメインを持つユーザーがSSOでサインインしようとすると、そのユーザーは404を受信する可能性があります。ユーザーは複数のアカウントを持つ可能性があり、そのSAML IDが、会社のドメインとは異なるメールアドレスを持つ個人のアカウントにリンクされている可能性があります。これを確認するには、次のことを検証してください:

- トップレベルグループがメールドメインによるグループメンバーシップを制限していること。
- トップレベルグループの[監査イベント](../../../administration/compliance/audit_event_reports.md)で、次のこと:
  - そのユーザーの**Signed in with GROUP_SAML authentication**アクションを確認できます。
  - **作成者**名を選択することで、ユーザーのユーザー名がSAML SSO用に設定したユーザー名と同じであること。
    - ユーザー名がSAML SSO用に設定したユーザー名と異なる場合は、ユーザーに個人のアカウントから[SAML IDをリンク解除](_index.md#unlink-accounts)するように依頼します。

すべてのユーザーがIdentity Provider（IdP）にサインインした後で`404`を受信している場合:

- `assertion_consumer_service_url`を検証します:

  - GitLabの設定で、[GitLabのHTTPSエンドポイントと一致](../../../integration/saml.md#configure-saml-support-in-gitlab)させます。
  - IdP上でSAMLアプリケーションを設定する際に、`Assertion Consumer Service URL`または同等のものとして。

- `404`が、[ユーザーがAzure IdPで多くのグループを割り当てられていること](group_sync.md#microsoft-azure-active-directory-integration)に関連しているかどうかを検証します。

- IdPサーバーとGitLabの時計が同じ時間に同期されていることを検証します。

一部のユーザーがIdPにサインインした後で`404`エラーを受信する場合、ユーザーがグループに追加され、その後すぐに削除された場合に何が監査イベントとして返されるかをまず検証します。あるいは、ユーザーが正常にサインインできるものの、[トップレベルグループのメンバー](../_index.md#search-a-group)として表示されない場合:

- ユーザーが[SAML Identity Providerに追加](_index.md#user-access-and-management)されており、設定されている場合は[SCIM](scim_setup.md)も確認してください。
- [SCIM API](../../../api/scim.md)を使用して、ユーザーのSCIM IDの`active`属性が`true`であることを確認してください。`active`属性が`false`である場合、問題を解決するために次のいずれかを実行できます:

  - SCIM Identity Providerでユーザーの同期をトリガーします。例えば、Azureには「Provision on demand」オプションがあります。
  - SCIM Identity Providerでユーザーを削除して再追加します。
  - 可能であれば、ユーザーに[アカウントをリンク解除](_index.md#unlink-accounts)させ、その後[アカウントをリンク](_index.md#link-saml-to-your-existing-gitlabcom-account)させます。
  - [内部SCIM API](../../../development/internal_api/_index.md#update-a-single-scim-provisioned-user)を使用して、グループのSCIMトークンでユーザーのSCIM IDを更新します。グループのSCIMトークンがわからない場合は、トークンをリセットし、新しいトークンでSCIM Identity Providerアプリケーションを更新します。リクエスト例: 

    ```plaintext
    curl --request PATCH "https://gitlab.example.com/api/scim/v2/groups/test_group/Users/f0b1d561c-21ff-4092-beab-8154b17f82f2" --header "Authorization: Bearer <SCIM_TOKEN>" --header "Content-Type: application/scim+json" --data '{ "Operations": [{"op":"Replace","path":"active","value":"true"}] }'
    ```

### ログイン後の500エラー {#500-error-after-login}

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

SAMLサインインページからリダイレクトされたときにGitLabで「500エラー」が表示される場合、次のことを示している可能性があります:

- GitLabがSAMLユーザーのメールアドレスを取得できませんでした。Identity Providerが、ユーザーのメールアドレスを含むクレームを、クレーム名`email`または`mail`を使用して提供していることを確認してください。
- `gitlab.rb`ファイルに設定されている`identity provider_cert_fingerprint`または`identity provider_cert`の証明書が正しくありません。
- お使いの`gitlab.rb`ファイルが`identity provider_cert_fingerprint`を有効にするように設定されており、`identity provider_cert`が提供されているか、またはその逆です。

### ログイン後の422エラー {#422-error-after-login}

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

SAMLサインインページからリダイレクトされたときにGitLabで「422エラー」が表示される場合、Identity ProviderのAssertion Consumer Service (ACS) URLが誤って設定されている可能性があります。

ACS URLが`https://gitlab.example.com/users/auth/saml/callback`を指していることを確認してください。ここで`gitlab.example.com`はお使いのGitLabインスタンスのURLです。

ACS URLが正しく、まだエラーがある場合は、他のトラブルシューティングセクションをレビューしてください。

#### 許可されていないメールアドレスでの422エラー {#422-error-with-non-allowed-email}

「メールアドレスはサインアップに許可されていません。通常のメールアドレスを使用してください。」という422エラーが表示されることがあります。

このメッセージは、ドメイン許可リストまたは拒否リスト設定からドメインを追加または削除する必要があることを示している可能性があります。

前提条件: 

- 管理者アクセス権が必要です。

この回避策を実装するには:

1. 右上隅で、**管理者**を選択します。
1. **設定** > **一般**を選択します。
1. **新規登録の制限**を展開します。
1. **サインアップに許可されたドメイン**および**サインアップに拒否されたドメイン**に、必要に応じてドメインを追加または削除します。
1. **変更を保存**を選択します。

### SAML経由でサインインする際にユーザーがブロックされる {#user-is-blocked-when-signing-in-through-saml}

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

SAML経由でサインインする際にユーザーがブロックされる最も可能性の高い理由は次のとおりです:

- 設定で`gitlab_rails['omniauth_block_auto_created_users'] = true`が設定されており、これがユーザーの初回サインインである。
- [`required_groups`](../../../integration/saml.md#required-groups)が設定されているものの、ユーザーがそのいずれかのメンバーではない。

## Google Workspaceトラブルシューティングのヒント {#google-workspace-troubleshooting-tips}

サインイン中にGoogleからのエラーが表示される場合、[SAMLアプリケーションのエラーメッセージ](https://support.google.com/a/answer/6301076?hl=en)に関するGoogle Workspaceドキュメントはデバッグに役立ちます。次の403エラーに特に注意してください:

- `app_not_configured`
- `app_not_configured_for_user`

## メッセージ: `The member's email address is not linked to a SAML account` {#message-the-members-email-address-is-not-linked-to-a-saml-account}

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com

{{< /details >}}

[SAML SSO強制](_index.md#sso-enforcement)が有効になっているGitLab.comグループ（またはサブグループ、またはグループ内のプロジェクト）にユーザーを招待しようとすると、このエラーが表示されます。

グループにユーザーを招待しようとした後でこのメッセージが表示された場合:

1. ユーザーが[SAML Identity Providerに追加](_index.md#user-access-and-management)されていることを確認してください。
1. ユーザーに、既存のアカウントがある場合は[既存のGitLab.comアカウントにSAMLをリンク](_index.md#link-saml-to-your-existing-gitlabcom-account)するように依頼します。それ以外の場合、ユーザーに[Identity Providerのダッシュボード経由でGitLab.comにアクセスする](_index.md#user-access-and-management)か、または[手動でサインアップ](https://gitlab.com/users/sign_up)して新しいアカウントにSAMLをリンクすることで、GitLab.comアカウントを作成するよう依頼します。
1. ユーザーが[トップレベルグループのメンバー](../_index.md#search-a-group)であることを確認してください。

さらに、[サインイン後に404を受信するユーザーのトラブルシューティング](#users-receive-a-404)を参照してください。

## メッセージ: `The SAML response did not contain an email address.` {#message-the-saml-response-did-not-contain-an-email-address}

このエラーが表示された場合:

```plaintext
The SAML response did not contain an email address.
Either the SAML identity provider is not configured to send the attribute, or the
identity provider directory does not have an email address value for your user
```

このエラーは次の場合に表示されます:

- SAMLレスポンスに、**email**または**mail**属性にユーザーのメールアドレスが含まれていない。
- ユーザーがアカウントに[SAMLをリンク](_index.md#user-access-and-management)しようとするものの、[本人確認プロセス](../../../security/identity_verification.md)をまだ完了していない。

SAML Identity Providerが、[サポートされているメール属性](../../../integration/saml.md)を送信するように設定されていることを確認します:

```xml
<Attribute Name="email">
  <AttributeValue>user@example.com‹/AttributeValue>
</Attribute>
```

`http://schemas.xmlsoap.org/ws/2005/05/identity/claims`および`http://schemas.microsoft.com/ws/2008/06/identity/claims/`のような語句で始まる属性名は、GitLab 16.7以前でデフォルトでサポートされています。

```xml
<Attribute Name="http://schemas.microsoft.com/ws/2008/06/identity/claims/emailaddress">
  <AttributeValue>user@example.com‹/AttributeValue>
</Attribute>
```

## グローバルSAMLグループメンバーシップロックが有効なサービスアカウントを追加できません {#cannot-add-service-accounts-with-global-saml-group-memberships-lock}

{{< details >}}

- 提供形態: GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

[グローバルSAMLグループメンバーシップロック](group_sync.md#global-saml-group-memberships-lock)が有効になっている場合、管理者のみがUI経由でグループメンバーとサービスアカウントを管理できます。グループオーナーがサービスアカウントを管理する必要がある場合、代わりに[グループメンバーAPI](../../../api/group_members.md)を使用できます。
