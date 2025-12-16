---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: SAMLのトラブルシューティング
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

このページでは、以下を使用する際に発生する可能性のある問題の解決策を紹介します:

- [GitLab.comグループのSAML SSO](_index.md)
- GitLab Self-Managedインスタンスレベルの[SAML OmniAuthプロバイダー](../../../integration/saml.md)。
- [スイッチボード](../../../administration/dedicated/configure_instance/authentication/saml.md#add-a-saml-provider-with-switchboard)を使用して、GitLab DedicatedインスタンスのSAMLを設定します。

## SAMLデバッグツール {#saml-debugging-tools}

SAMLレスポンスはbase64でエンコードされています。それらをその場でエンコード解除するには、**SAML-tracer**ブラウザー拡張機能（[Firefox](https://addons.mozilla.org/en-US/firefox/addon/saml-tracer/) 、[Chrome](https://chromewebstore.google.com/detail/saml-tracer/mpdajninpobndbfcldcmbpnnbhibjmch?hl=en)）を使用できます。

ブラウザプラグインをインストールできない場合は、代わりに[SAMLレスポンスを手動で生成してキャプチャする](#manually-generate-a-saml-response)ことができます。

以下に特に注意してください:

- サインインしているユーザーを識別するために使用する`NameID`ID。ユーザーが以前にサインインしている場合、これは[保存されている値と一致](#verify-nameid)する必要があります。
- 応答署名を検証するために必要な`X509Certificate`の存在。
- 設定を誤るとエラーが発生する可能性がある`SubjectConfirmation`と`Conditions`。

### SAMLレスポンスを生成 {#generate-a-saml-response}

IDプロバイダーを使用してサインインを試みる際に、アサーションリストで送信される属性名と値をプレビューするには、SAMLレスポンスを使用します。

SAMLレスポンスを生成するには、次の手順を実行します:

1. [ブラウザデバッグツール](#saml-debugging-tools)のいずれかをインストールします。
1. 新しいブラウザータブを開きます。
1. SAMLトレーサーコンソールを開きます:
   - Chrome: ページのコンテキストメニューで、**Inspect**を選択し、開発者コンソールで**SAML**タブを選択します。
   - Firefox: ブラウザーツールバーにあるSAMLトレーサーアイコンを選択します。
1. GitLab.comグループの場合:
   - グループのGitLabシングルサインオンのURLに移動します。
   - **許可する**を選択するか、サインインを試みます
1. GitLab Self-Managedインスタンスの場合:
   - インスタンスのホームページに移動します
   - `SAML Login`ボタンを選択してサインインします
1. SAMLレスポンスがトレーサーコンソールに表示されます。これは、この[SAMLレスポンスの例](_index.md#example-saml-response)に似ています。
1. SAMLトレーサー内で、**エクスポート**アイコンを選択して、レスポンスをJSON形式で保存します。

#### SAMLレスポンスを手動で生成 {#manually-generate-a-saml-response}

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i>概要については、GitLabサポートがアップロードした[ブラウザプラグインを使用せずにSAMLレスポンスを手動で生成する（Google Chromeを使用）ビデオ](https://youtu.be/umMPj6ohF_I)をご覧ください。
<!-- Video published on 2024-09-09 -->

使用するブラウザーに関係なく、プロセスは次のようになります:

1. 新しいブラウザーを右クリックし、**Inspect**を選択して、**DevTools**ウィンドウを開きます。
1. **ネットワーク**タブを選択します。**Preserve log**が選択されていることを確認します。
1. ブラウザーページに切り替えて、SAMLシングルサインオンを使用してGitLabにサインインします。
1. **DevTools**ウィンドウに戻り、`callback`イベントをフィルターします。
1. コールバックイベントの**Payload**（ペイロード）タブを選択し、右クリックして値をコピーします。
1. この値を次のコマンドに貼り付けます: `echo "<value>" | base64 --decode > saml_response.xml`。
1. `saml_response.xml`をコードエディタで開きます。

   XMLの「プリティファイア」がコードエディタにインストールされている場合は、応答を自動的にフォーマットして読みやすくすることができます。

## SAMLサインインのRailsログを検索 {#search-rails-logs-for-a-saml-sign-in}

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

SAMLサインインに関する詳細情報は、[`audit_json.log`ファイル](../../../administration/logs/_index.md#audit_jsonlog)にあります。

たとえば、`system_access`を検索すると、ユーザーがSAMLを使用してGitLabにサインインしたときに表示されるエントリが見つかります:

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

SAMLグループリンクを設定している場合、ログには、削除されるグループメンバーシップの詳細も表示されます:

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

GitLabがSAMLプロバイダーから受信したユーザーの詳細も、`auth_json.log`で確認できます。次に例を示します:

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

- [Docker composeを使用したSAMLテスト環境を備えた完全なGitLab](https://gitlab.com/gitlab-com/support/toolbox/replication/tree/master/compose_files)。
- SAMLプロバイダーのみが必要な場合は、[プラグアンドプレイSAML 2.0 IDプロバイダーを使用してDockerコンテナを起動するためのクイックスタートガイド](../../../administration/troubleshooting/test_environments.md#saml)。
- [GitLab Self-ManagedインスタンスでグループのSAMLを有効](../../../integration/saml.md#configure-group-saml-sso-on-gitlab-self-managed)にすることによるローカル環境。

## 構成の検証 {#verify-configuration}

便宜上、サポートチームが使用する[サンプルリソース](example_saml_config.md)をいくつか含めました。これらはSAMLアプリの設定を検証するのに役立つ場合がありますが、サードパーティ製品の現在の状態を反映することを保証するものではありません。

### フィンガープリントを計算します {#calculate-the-fingerprint}

`idp_cert_fingerprint`を設定する場合は、可能な限りSHA256フィンガープリントを使用する必要があります。SHA1もサポートされていますが、推奨されていません。フィンガープリントを計算するには、証明書ファイルに対して次のコマンドを実行します:

```shell
openssl x509 -in <certificate.crt> -noout -fingerprint -sha256
```

`<certificate.crt>`を証明書ファイルの名前に置き換えます。

{{< alert type="note" >}}

GitLab 17.11以降では、フィンガープリントアルゴリズムはフィンガープリントの長さに基[づいて自動的に検出](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/184530)されます。

GitLab 17.10以前では、SHA1はデフォルトのフィンガープリントアルゴリズムです。SHA256フィンガープリントを使用するには、アルゴリズムを指定する必要があります:

```ruby
idp_cert_fingerprint_algorithm: "http://www.w3.org/2001/04/xmlenc#sha256"
```

{{< /alert >}}

## SSO証明書の更新 {#sso-certificate-updates}

IDプロバイダーに使用される証明書が変更された場合（たとえば、証明書の更新時）、証明書フィンガープリントも更新する必要があります。証明書フィンガープリントは、IDプロバイダーのUIにあります。IDプロバイダーのUIで証明書を取得できない場合は、[フィンガープリントの計算](#calculate-the-fingerprint)に関するドキュメントの手順に従ってください。

## 設定エラー {#configuration-errors}

### 無効なオーディエンス {#invalid-audience}

このエラーは、IDプロバイダーがGitLabをSAMLリクエストの有効な送信者および受信者として認識しないことを意味します。以下を必ずご確認ください:

- IDプロバイダーサーバーの承認済みオーディエンスにGitLabコールバックURLを追加します。
- `issuer`文字列の末尾の空白を避けてください。

### キー検証エラー、ダイジェストの不一致、またはフィンガープリントの不一致 {#key-validation-error-digest-mismatch-or-fingerprint-mismatch}

これらのエラーはすべて、SAML証明書と同様の場所から発生します。SAMLリクエストは、フィンガープリント、証明書、または検証ツールを使用して検証する必要があります。

この要件については、次の点を考慮してください:

- フィンガープリントを使用する場合は、SHA256フィンガープリントを確認します:
  1. 証明書ファイルを再度ダウンロードしてください。
  1. [フィンガープリントを計算します](#calculate-the-fingerprint)。
  1. `idp_cert_fingerprint`で提供されている値とフィンガープリントを比較します。値は同じである必要があります。
- 設定で証明書が提供されていない場合、フィンガープリントまたはフィンガープリント検証ツールを提供する必要があり、サーバーからの応答に証明書（`<ds:KeyInfo><ds:X509Data><ds:X509Certificate>`）が含まれている必要があります。
- 証明書が設定で提供されている場合、リクエストに証明書を含める必要はなくなりました。この場合、フィンガープリントまたはフィンガープリント検証ツールはオプションです。

上記で説明したシナリオのいずれも有効でない場合、リクエストは前述のエラーのいずれかで失敗します。

### クレームがないか、`Email can't be blank`エラー {#missing-claims-or-email-cant-be-blank-errors}

IDプロバイダーサーバーは、GitLabがアカウントを作成するか、ログイン情報を既存のアカウントと照合するために、特定の情報を渡す必要があります。`email`は、渡す必要のある最小限の情報量です。IDプロバイダーサーバーがこの情報を提供していない場合、すべてのSAMLリクエストは失敗します。

この情報が提供されていることを確認してください。

このエラーが発生する可能性のあるもう1つの問題は、IDプロバイダーによって正しい情報が送信されているものの、属性がOmniAuth `info`ハッシュの名前と一致しない場合です。この場合、[SAMLレスポンスの属性名を対応するOmniAuth `info`ハッシュ名にマップ](../../../integration/saml.md#map-saml-response-attribute-names)するには、SAML設定で`attribute_statements`を設定する必要があります。

## ユーザーサインインバナーエラーメッセージ {#user-sign-in-banner-error-messages}

### メッセージ: `SAML authentication failed: SAML NameID is missing from your SAML response.` {#message-saml-authentication-failed-saml-nameid-is-missing-from-your-saml-response}

`SAML authentication failed: SAML NameID is missing from your SAML response. Please contact your administrator.`というエラーが表示される場合があります。

この問題は、グループSSOを使用してGitLabにサインインしようとしたときに、SAMLレスポンスに`NameID`が含まれていない場合に発生します。

この問題を解決するには、以下を実行します:

- IdPアカウントに`NameID`が割り当てられていることを確認するには、管理者に連絡してください。
- [SAMLデバッグツール](#saml-debugging-tools)を使用して、SAMLレスポンスに有効な`NameID`があることを確認します。

### メッセージ: `SAML authentication failed: Extern uid has already been taken.` {#message-saml-authentication-failed-extern-uid-has-already-been-taken}

`SAML authentication failed: Extern uid has already been taken. Please contact your administrator to generate a unique external_uid (NameID).`というエラーが表示される場合があります。

この問題は、グループSSOを使用して既存のGitLabアカウントをSAMLアイデンティティにリンクしようとしたときに、現在の`NameID`を持つ既存のGitLabアカウントが存在する場合に発生します。

この問題を解決するには、管理者にIdPアカウントの一意の`Extern UID`（`NameID`）を再生成するように依頼してください。この新しい`Extern UID`が[GitLab `NameID`制約](_index.md#manage-user-saml-identity)に準拠していることを確認します。

SAMLログインでそのGitLabユーザーを使用したくない場合は、[SAMLアプリからGitLabアカウントのリンクを解除](_index.md#unlink-accounts)できます。

### メッセージ: `SAML authentication failed: User has already been taken` {#message-saml-authentication-failed-user-has-already-been-taken}

サインインしているユーザーが別のアイデンティティにリンクされたSAMLを既に持っているか、`NameID`の値が変更されています。考えられる原因と解決策を次に示します:

| 原因                                                                                          | 解決策: |
|------------------------------------------------------------------------------------------------|----------|
| 特定のIDプロバイダーに対して、複数のSAMLアイデンティティを同じユーザーにリンクしようとしました。 | サインインに使用するアイデンティティを変更します。これを行うには、再度サインインする前に、このGitLabアカウントから[以前のSAMLアイデンティティのリンクを解除](_index.md#unlink-accounts)します。 |
| ユーザーがSSO識別をリクエストするたびに`NameID`が変更されます                           | [`NameID`を確認してください](#verify-nameid)が`Transient`形式で設定されていないか、後続のリクエストで`NameID`が変更されていません。 |

### メッセージ: `SAML authentication failed: Email has already been taken` {#message-saml-authentication-failed-email-has-already-been-taken}

| 原因                                                                                                                | 解決策: |
|----------------------------------------------------------------------------------------------------------------------|----------|
| 同じメールアドレスを持つGitLabユーザーアカウントが存在する場合、そのアカウントはSAMLアイデンティティに関連付けられていません。 | GitLab.comでは、ユーザーは[自分のアカウントをリンク](_index.md#user-access-and-management)する必要があります。GitLab Self-Managedインスタンスでは、管理者は、最初にサインインするときに、[SAMLアイデンティティをGitLabユーザーアカウントに自動的にリンク](../../../integration/saml.md#link-saml-identity-for-an-existing-user)するようにインスタンスを設定できます。 |

ユーザーアカウントは、次のいずれかの方法で作成されます:

- ユーザー登録
- OAuth経由でサインイン
- SAML経由でサインイン
- SCIMプロビジョニング

### エラー: ユーザーは既に使用されています {#error-user-has-already-been-taken}

これらのエラーが同時に発生するということは、IDプロバイダーによって提供された`NameID`の大文字と小文字の区別が、そのユーザーの以前の値と正確に一致しなかったことを示唆しています:

- `SAML authentication failed: Extern UID has already been taken`
- `User has already been taken`

`NameID`が一貫した値を返すように設定することで、これを防ぐことができます。個々のユーザーに対してこれを修正するには、ユーザーの識別子を変更する必要があります。GitLab.comの場合、ユーザーは[GitLabアカウントからSAMLのリンクを解除](_index.md#unlink-accounts)する必要があります。

### メッセージ: `Request to link SAML account must be authorized` {#message-request-to-link-saml-account-must-be-authorized}

GitLabアカウントをリンクしようとしているユーザーが、IDプロバイダーのSAMLアプリ内のユーザーとして追加されていることを確認します。

または、SAMLレスポンスで`InResponseTo`属性が`samlp:Response`タグにない可能性があります。これは[SAML gemで想定](https://github.com/onelogin/ruby-saml/blob/9f710c5028b069bfab4b9e2b66891e0549765af5/lib/onelogin/ruby-saml/response.rb#L307-L316)されています。IDプロバイダーの管理者は、ログインがIDプロバイダーだけでなく、サービスプロバイダーによって開始されるようにする必要があります。

### メッセージ: `There is already a GitLab account associated with this email address.` {#message-there-is-already-a-gitlab-account-associated-with-this-email-address}

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com

{{< /details >}}

ユーザーが[SAMLを手動で既存のGitLab.comアカウントにリンク](_index.md#link-saml-to-your-existing-gitlabcom-account)しようとすると、このメッセージが表示されることがあります:

```plaintext
There is already a GitLab account associated with this email address.
Sign in with your existing credentials to connect your organization's account
```

この問題を解決するには、ユーザーが正しいGitLabパスワードを使用してサインインしていることを確認する必要があります。ユーザーは、次の両方に該当する場合、最初に[パスワードをリセット](https://gitlab.com/users/password/new)する必要があります:

- アカウントはSCIMによってプロビジョニングされました。
- 初めてユーザー名とパスワードでサインインします。

### メッセージ: `SAML Name ID and email address do not match your user account` {#message-saml-name-id-and-email-address-do-not-match-your-user-account}

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com

{{< /details >}}

ユーザーが「SAML Name IDとメールアドレスがユーザーアカウントと一致しません」というエラーを受け取ることがあります。管理者にお問い合わせください。」これは、次の意味をもちます:

- SAMLによって送信されたNameID値が、既存のSAMLアイデンティティ`extern_uid`値と一致しません。NameIDと`extern_uid`の両方で、大文字と小文字が区別されます。詳細については、[ユーザーSAMLアイデンティティの管理](_index.md#manage-user-saml-identity)を参照してください。
- SAMLレスポンスにメールアドレスが含まれていないか、メールアドレスがユーザーのGitLabメールアドレスと一致しませんでした。

回避策として、GitLabグループオーナーが[SAML API](../../../api/saml.md)を使用して、ユーザーのSAML `extern_uid`を更新します。`extern_uid`の値は、SAMLIDプロバイダー（IdP）によって送信されるName ID値と一致する必要があります。IdPの設定によっては、生成された一意のID、メールアドレス、またはその他の値になる場合があります。

### エラー: `Certificate element missing in response (ds:x509certificate)` {#error-certificate-element-missing-in-response-dsx509certificate}

このエラーは、IdPがSAMLレスポンスにX.509証明書を含めるように設定されていないことを示唆しています:

```plaintext
Certificate element missing in response (ds:x509certificate) and not cert provided at settings
```

X.509証明書は、レスポンスに含める必要があります。この問題を解決するには、SAMLレスポンスにX.509証明書を含めるようにIdPを設定します。

詳細については、[IdPでのSAMLアプリの追加設定](../../../integration/saml.md#additional-configuration-for-saml-apps-on-your-idp)に関するドキュメントを参照してください。

## その他のユーザーサインインの問題 {#other-user-sign-in-issues}

### `NameID`の検証 {#verify-nameid}

トラブルシューティングでは、認証済みユーザーは誰でもAPIを使用して、GitLabが既に自分のユーザーにリンクしている`NameID`を[`https://gitlab.com/api/v4/user`](https://gitlab.com/api/v4/user)にアクセスし、アイデンティティの`extern_uid`を確認することで検証できます。

GitLab Self-Managedインスタンスの場合、管理者は[users API](../../../api/users.md)を使用して同じ情報を確認できます。

グループにSAMLを使用する場合、適切な権限を持つロールのグループメンバーは、[members API](../../../api/members.md)を使用して、グループのメンバーのグループSAMLアイデンティティ情報を表示できます。

これは、[SAMLデバッグツール](#saml-debugging-tools)でメッセージをエンコード解除することにより、IDプロバイダーから送信されている`NameID`と比較できます。ユーザーを識別するには、これらを一致させる必要があります。

### ログイン「ループ」でスタック {#stuck-in-a-login-loop}

（GitLab.comの場合）**GitLabシングルサインオンのURL**、または（GitLab Self-Managedインスタンスの場合）インスタンスURLが、IDプロバイダーのSAMLアプリで「ログインURL」（または同様の名前のフィールド）として設定されていることを確認します。

GitLab.comの場合、またはユーザーが[SAMLを既存のGitLab.comアカウントにリンク](_index.md#link-saml-to-your-existing-gitlabcom-account)する必要がある場合は、**GitLabシングルサインオンのURL**を指定し、最初にサインインするときにSAMLアプリを使用しないようにユーザーに指示します。

### ユーザーが404を受け取る {#users-receive-a-404}

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com

{{< /details >}}

サインインが成功した後にユーザーが`404`を受信した場合は、IP制限が設定されているかどうかを確認します。IP制限設定は、次のように設定されます:

- GitLab.comでは、[グループレベル](../access_and_permissions.md#restrict-group-access-by-ip-address)。
- GitLab Self-Managedインスタンスの場合、[インスタンスレベル](../../../administration/reporting/ip_addr_restrictions.md)。

グループのSAMLSSOは有料機能であるため、サブスクリプションの期限が切れると、GitLab.comでSAML SSOを使用してサインインするときに`404`エラーが発生する可能性があります。すべてのユーザーがSAMLを使用してサインインしようとしたときに`404`を受信する場合は、このSAML SSOネームスペースで使用されている[アクティブなサブスクリプションがある](../../../subscriptions/manage_subscription.md#view-subscription)ことを確認してください。

「verify configuration」を使用するセットアップ中に`404`が表示された場合は、正しい[SHA-1で生成されたフィンガープリント](../../../integration/saml.md#configure-saml-on-your-idp)を使用していることを確認してください。

ユーザーが初めてサインインしようとしたときに、GitLabシングルサインオンURLが[設定](_index.md#set-up-your-identity-provider)されていない場合、404が表示されることがあります。[ユーザーアクセスセクション](_index.md#link-saml-to-your-existing-gitlabcom-account)で概説されているように、グループメンバーシップのオーナーはユーザーにURLを提供する必要があります。

トップレベルグループが[メールドメインでメンバーシップを制限](../access_and_permissions.md#restrict-group-access-by-domain)しており、許可されていないメールドメインを持つユーザーがSSOでサインインしようとすると、404が表示されることがあります。ユーザーは複数のアカウントを持っている可能性があり、そのSAML IDは、会社のドメインとは異なるメールアドレスを持つ個人アカウントにリンクされている可能性があります。これを確認するには、以下を確認してください:

- トップレベルグループがメールドメインでメンバーシップを制限していること。
- トップレベルグループの[監査イベント](../../../administration/compliance/audit_event_reports.md)で、以下を確認してください:
  - そのユーザーに対して**Signed in with GROUP_SAML authentication**（GROUP_SAML認証でサインイン）アクションが表示されること。
  - **作成者**名を選択して、ユーザーのユーザー名がSAML SSOに設定したユーザー名と同じであることを確認します。
    - ユーザー名がSAML SSOに設定したユーザー名と異なる場合は、個人アカウントから[SAML IDのリンクを解除](_index.md#unlink-accounts)するようにユーザーに依頼してください。

すべてのユーザーがIDプロバイダー（IdP）へのサインイン後に`404`を受信している場合:

- 以下を確認してください`assertion_consumer_service_url`:

  - [GitLabのHTTPSエンドポイントと一致させる](../../../integration/saml.md#configure-saml-support-in-gitlab)ことにより、GitLab設定で確認してください。
  - IDプロバイダーでSAMLアプリを設定するときに、`Assertion Consumer Service URL`または同等のものを指定します。

- `404`が、[ユーザーがAzure IdPで割り当てられているグループが多すぎる](group_sync.md#microsoft-azure-active-directory-integration)ことに関連しているかどうかを確認します。

- IdPサーバーとGitLabのクロックが同じ時刻に同期されていることを確認します。

IdPへのサインイン後に一部のユーザーが`404`エラーを受信する場合は、まず、ユーザーがグループに追加されてすぐに削除された場合に返される監査イベントを確認してください。または、ユーザーが正常にサインインできても、[トップレベルグループのメンバー](../_index.md#search-a-group)として表示されない場合:

- ユーザーが[SAMLIDプロバイダーに追加](_index.md#user-access-and-management)され、[SCIM](scim_setup.md)が設定されていることを確認します。
- [SCIM API](../../../api/scim.md)を使用して、ユーザーのSCIM IDの`active`属性が`true`であることを確認します。`active`属性が`false`の場合は、次のいずれかを実行して、問題を解決できる可能性があります:

  - SCIMIDプロバイダーでユーザーの同期をトリガーします。たとえば、Azureには「オンデマンドのプロビジョニング」オプションがあります。
  - SCIMIDプロバイダーでユーザーを削除して再度追加します。
  - 可能であれば、ユーザーに[アカウントのリンクを解除](_index.md#unlink-accounts)してから、[アカウントをリンク](_index.md#link-saml-to-your-existing-gitlabcom-account)してもらいます。
  - [内部SCIM API](../../../development/internal_api/_index.md#update-a-single-scim-provisioned-user)を使用して、グループのSCIMトークンを使用してユーザーのSCIM IDを更新します。グループのSCIMトークンが不明な場合は、トークンをリセットし、新しいトークンでSCIMIDプロバイダーアプリを更新します。リクエスト例:

    ```plaintext
    curl --request PATCH "https://gitlab.example.com/api/scim/v2/groups/test_group/Users/f0b1d561c-21ff-4092-beab-8154b17f82f2" --header "Authorization: Bearer <SCIM_TOKEN>" --header "Content-Type: application/scim+json" --data '{ "Operations": [{"op":"Replace","path":"active","value":"true"}] }'
    ```

### ログイン後の500エラー {#500-error-after-login}

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

SAMLサインインページからリダイレクトされたときにGitLabで「500エラー」が表示される場合は、次の原因が考えられます:

- GitLabがSAMLユーザーのメールアドレスを取得できませんでした。IDプロバイダーが、`email`または`mail`のクレーム名を使用して、ユーザーのメールアドレスを含むクレームを提供していることを確認してください。
- `identity provider_cert_fingerprint`または`identity provider_cert`ファイルに対する`gitlab.rb`ファイルの証明書セットが正しくありません。
- `gitlab.rb`ファイルが`identity provider_cert_fingerprint`を有効にするように設定されており、`identity provider_cert`が提供されているか、またはその逆です。

### ログイン後の422エラー {#422-error-after-login}

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

SAMLサインインページからリダイレクトされたときにGitLabで「422エラー」が表示される場合は、IDプロバイダーでAssertion Consumer Service（ACS）URLが誤って設定されている可能性があります。

ACS URLが`https://gitlab.example.com/users/auth/saml/callback`を指していることを確認してください。ここで、`gitlab.example.com`はGitLabインスタンスのURLです。

ACS URLが正しくても、まだエラーが発生する場合は、他のトラブルシューティングセクションを確認してください。

#### 許可されていないメールでの422エラー {#422-error-with-non-allowed-email}

「メールアドレスはサインアップできません」という422エラーが表示されることがあります。通常のメールアドレスを使用してください。」

このメッセージは、ドメイン許可リストまたは拒否リストの設定からドメインを追加または削除する必要があることを示している可能性があります。

この回避策を実装するには:

1. 左側のサイドバーの下部で、**管理者**を選択します。
1. **設定** > **一般**を選択します。
1. **新規登録の制限**を展開します。
1. **サインアップに許可されたドメイン**と**サインアップに拒否されたドメイン**に、必要に応じてドメインを追加または削除します。
1. **変更を保存**を選択します。

### SAML経由でサインインするときのユーザーがブロックされる {#user-is-blocked-when-signing-in-through-saml}

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

SAML経由でサインインするときにユーザーがブロックされる最も可能性の高い理由は次のとおりです:

- 設定で、`gitlab_rails['omniauth_block_auto_created_users'] = true`が設定されており、これはユーザーが初めてサインインするときです。
- [`required_groups`](../../../integration/saml.md#required-groups)が設定されていますが、ユーザーはそのメンバーではありません。

## Googleワークスペースのトラブルシューティングのヒント {#google-workspace-troubleshooting-tips}

[SAMLアプリのエラーメッセージ](https://support.google.com/a/answer/6301076?hl=en)に関するGoogleワークスペースドキュメントは、サインイン中にGoogleからエラーが表示された場合にデバッグに役立ちます。次の403エラーに特に注意してください:

- `app_not_configured`
- `app_not_configured_for_user`

## メッセージ: `The member's email address is not linked to a SAML account` {#message-the-members-email-address-is-not-linked-to-a-saml-account}

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com

{{< /details >}}

このエラーは、[SAML SSOの強制](_index.md#sso-enforcement)が有効になっているGitLab.comグループ（またはサブグループ、またはグループ内のプロジェクト）にユーザーを招待しようとしたときに表示されます。

ユーザーをグループに招待しようとした後にこのメッセージが表示された場合:

1. ユーザーが[SAMLIDプロバイダーに追加](_index.md#user-access-and-management)されていることを確認します。
1. ユーザーに[既存のGitLab.comアカウントにSAMLをリンク](_index.md#link-saml-to-your-existing-gitlabcom-account)するように依頼します（ある場合）。それ以外の場合は、ユーザーに[IDプロバイダーのダッシュボードからGitLab.comにアクセス](_index.md#user-access-and-management)するか、[手動でサインアップ](https://gitlab.com/users/sign_up)して、新しいアカウントにSAMLをリンクして、GitLab.comアカウントを作成するように依頼します。
1. ユーザーが[トップレベルグループのメンバー](../_index.md#search-a-group)であることを確認します。

さらに、[サインイン後に404を受信するユーザーのトラブルシューティング](#users-receive-a-404)を参照してください。

## メッセージ: `The SAML response did not contain an email address.` {#message-the-saml-response-did-not-contain-an-email-address}

このエラーが表示された場合:

```plaintext
The SAML response did not contain an email address.
Either the SAML identity provider is not configured to send the attribute, or the
identity provider directory does not have an email address value for your user
```

このエラーは、次の場合に表示されます:

- SAML応答に、ユーザーのメールアドレスが**email**（メール）または**mail**（メール）属性に含まれていない場合。
- ユーザーがアカウントに[SAMLをリンク](_index.md#user-access-and-management)しようとしたが、[ID検証プロセス](../../../security/identity_verification.md)をまだ完了していない場合。

[サポートされているメール属性](../../../integration/saml.md)を送信するようにIDプロバイダーが設定されていることを確認してください:

```xml
<Attribute Name="email">
  <AttributeValue>user@example.com‹/AttributeValue>
</Attribute>
```

`http://schemas.xmlsoap.org/ws/2005/05/identity/claims`や`http://schemas.microsoft.com/ws/2008/06/identity/claims/`などのフレーズで始まる属性名は、GitLab 16.7以降ではデフォルトでサポートされています。

```xml
<Attribute Name="http://schemas.microsoft.com/ws/2008/06/identity/claims/emailaddress">
  <AttributeValue>user@example.com‹/AttributeValue>
</Attribute>
```

## グローバルSAMLグループメンバーシップロックでサービスアカウントを追加できません {#cannot-add-service-accounts-with-global-saml-group-memberships-lock}

{{< details >}}

- 提供形態: GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

[グローバルSAMLグループメンバーシップロック](group_sync.md#global-saml-group-memberships-lock)が有効になっている場合、管理者のみがUIを介してグループメンバーとサービスアカウントを管理できます。グループのオーナーがサービスアカウントを管理する必要がある場合は、代わりに[グループメンバーAPI](../../../api/members.md)を使用できます。
