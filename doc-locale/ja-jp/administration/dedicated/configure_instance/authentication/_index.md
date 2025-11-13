---
stage: GitLab Dedicated
group: Switchboard
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: GitLab Dedicatedの認証方法を設定します。
title: GitLab Dedicatedの認証
---

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab Dedicated

{{< /details >}}

GitLab Dedicatedには、2つの異なる認証コンテキストがあります:

- スイッチボード認証: 管理者がサインインしてGitLab Dedicatedインスタンスを管理する方法。
- インスタンス認証: エンドユーザーがGitLab Dedicatedインスタンスにサインインする方法。

## スイッチボード認証 {#switchboard-authentication}

管理者スイッチボードを使用して、インスタンス、ユーザー、および設定を管理します。

スイッチボードは、以下の認証方法をサポートしています:

- SAMLまたはOIDCによるシングルサインオン
- 標準のGitLab.comアカウント

スイッチボードのユーザー管理の詳細については、[ユーザーと通知の管理](../users_notifications.md)を参照してください。

### スイッチボードのSSOを設定する {#configure-switchboard-sso}

スイッチボードのシングルサインオンを有効にして、組織のIDプロバイダーと統合します。スイッチボードは、SAMLとOIDCの両方のプロトコルをサポートしています。

{{< alert type="note" >}}

これにより、GitLab Dedicatedインスタンスを管理するスイッチボード管理者のシングルサインオンが構成されます。

{{< /alert >}}

スイッチボードのシングルサインオンを設定するには:

1. 選択したプロトコルに必要な情報を収集します:
   - [SAMLパラメータ](#saml-parameters-for-switchboard)
   - [OIDCパラメータ](#oidc-parameters-for-switchboard)
1. 情報とともに[サポートチケットをリクエストします](https://support.gitlab.com/hc/en-us/requests/new?ticket_form_id=4414917877650)。
1. GitLabが提供する情報を使用して、IDプロバイダーを設定します。

#### スイッチボードのSAMLパラメータ {#saml-parameters-for-switchboard}

SAML設定をリクエストする場合は、以下を指定する必要があります:

| パラメータ                 | 説明 |
| ------------------------- | ----------- |
| メタデータURL              | お使いのIDプロバイダーのSAMLメタデータドキュメントを指すURL。通常、これは`/saml/metadata.xml`で終わるか、IDプロバイダーのSSO設定セクションにあります。 |
| メール属性マッピング   | お使いのIDプロバイダーがメールアドレスを表すために使用する形式。たとえば、Auth0では、これは`http://schemas.auth0.com/email`になる可能性があります。 |
| 属性リクエストメソッド | お使いのIDプロバイダーから属性をリクエストするときに使用する必要があるHTTPメソッド(GETまたはPOST)。推奨される方法については、IDプロバイダーのドキュメントを確認してください。 |
| ユーザーメールドメイン         | ユーザーのメールアドレスのドメイン部分（例: `gitlab.com`）。 |

GitLabは、IDプロバイダーで設定するために、次の情報を提供します:

| パラメータ           | 説明 |
| ------------------- | ----------- |
| コールバック/ACS URL    | 認証後、IDプロバイダーがSAMLレスポンスを送信するURL。 |
| 必要な属性 | SAMLレスポンスに含める必要のある属性。少なくとも、`email`にマップされた属性が必要です。 |

暗号化されたレスポンスが必要な場合、GitLabはリクエストに応じて必要な証明書を提供できます。

{{< alert type="note" >}}

GitLab Dedicatedは、IdPが開始したSAMLをサポートしていません。

{{< /alert >}}

#### スイッチボードのOIDCパラメータ {#oidc-parameters-for-switchboard}

OIDC設定をリクエストする場合は、以下を指定する必要があります:

| パラメータ       | 説明 |
| --------------- | ----------- |
| 発行者URL      | お使いのOIDCプロバイダーを一意に識別するベースURL。通常、このURLは、`https://[your-idp-domain]/.well-known/openid-configuration`にあるプロバイダーのディスカバリードキュメントを指します。 |
| トークンエンドポイント | 認証トークンの取得と検証に使用される、IDプロバイダーからの特定のURL。これらのエンドポイントは通常、プロバイダーのOpenID Connect設定ドキュメントに記載されています。 |
| スコープ          | どのユーザー情報が共有されるかを決定する、認証中にリクエストされた権限レベル。標準スコープには、`openid`、`email`、および`profile`が含まれます。 |
| Client ID（クライアントID）       | お使いのIDプロバイダーでスイッチボードをアプリケーションとして登録するときに割り当てられる固有識別子。最初にIDプロバイダーのダッシュボードでこの登録を作成する必要があります。 |
| クライアントのシークレットキー   | お使いのIDプロバイダーでスイッチボードを登録するときに生成される機密セキュリティキー。このシークレットは、IdPに対するスイッチボードを認証し、安全に保管する必要があります。 |

GitLabは、IDプロバイダーで設定するために、次の情報を提供します:

| パラメータ              | 説明 |
| ---------------------- | ----------- |
| リダイレクト/コールバックURL | 認証に成功した後、IDプロバイダーがユーザーをリダイレクトするURL。これらは、IDプロバイダーの許可されたリダイレクトURLリストに追加する必要があります。 |
| 必要なクレーム        | 認証トークンペイロードに含める必要のある特定のユーザー情報。少なくとも、ユーザーのメールアドレスにマップされたクレームが必要です。 |

お使いのOIDCプロバイダーによっては、追加の設定の詳細が必要になる場合があります。

## インスタンス認証 {#instance-authentication}

組織のユーザーがGitLab Dedicatedインスタンスに対して認証する方法を設定します。

GitLab Dedicatedインスタンスは、次の認証方法をサポートしています:

- [SAML SSOを設定する](saml.md)
- [OIDCを設定する](openid_connect.md)
