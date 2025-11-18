---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitLabをOpenID Connect Identity Providerとして使用する
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed

{{< /details >}}

GitLabを[OpenID Connect](https://openid.net/developers/how-connect-works/)（OIDC）Identity Providerとして使用し、他のサービスにアクセスすることができます。OIDCは、OpenID 2.0と同様のタスクを数多く実行するアイデンティティレイヤーですが、APIフレンドリーで、ネイティブアプリケーションやモバイルアプリケーションでも使用できます。

クライアントはOIDCを使用して、次のことができます。

- GitLabによって実行された認証に基づいて、エンドユーザーのアイデンティティを検証する。
- 相互運用可能でRESTに近い方法により、エンドユーザーの基本的なプロファイル情報を取得する。

Railsアプリケーションには[OmniAuth::OpenIDConnect](https://github.com/omniauth/omniauth_openid_connect)を使用できます。その他にも多くの[クライアント実装](https://openid.net/developers/certified-openid-connect-implementations/)を利用できます。

GitLabは、OIDCサービスを提供するために`doorkeeper-openid_connect` gemを使用しています。詳しくは、[doorkeeper-openid_connectリポジトリ](https://github.com/doorkeeper-gem/doorkeeper-openid_connect "Doorkeeper::OpenidConnectリポジトリ")を参照してください。

## OAuthアプリケーションでOIDCを有効にする {#enable-oidc-for-oauth-applications}

OAuthアプリケーションでOIDCを有効にするには、アプリケーション設定で`openid`スコープを選択する必要があります。詳細については、[GitLabをOAuth 2.0認証用のIdentity Providerとして設定する](oauth_provider.md)を参照してください。

## 設定の検出 {#settings-discovery}

クライアントがディスカバリURLからOIDC設定をインポートできる場合、GitLabはその情報にアクセスするためのエンドポイントを提供します。

- GitLab.comの場合は、`https://gitlab.com/.well-known/openid-configuration`を使用します。
- GitLab Self-Managedの場合は、`https://<your-gitlab-instance>/.well-known/openid-configuration`を使用します。

## 共有情報 {#shared-information}

クライアントと共有するユーザー情報は、次のとおりです。

| クレーム                | タイプ      | 説明 | IDトークンに含まれる | `userinfo`エンドポイントに含まれる |
|:---------------------|:----------|:------------|:---------------------|:------------------------------|
| `sub`                | `string`  | ユーザーのID | {{< icon name="check-circle" >}}はい | {{< icon name="check-circle" >}}はい |
| `auth_time`          | `integer` | ユーザーの最終認証のタイムスタンプ | {{< icon name="check-circle" >}}はい | {{< icon name="dotted-circle" >}}いいえ |
| `name`               | `string`  | ユーザーのフルネーム | {{< icon name="check-circle" >}}はい | {{< icon name="check-circle" >}}はい |
| `nickname`           | `string`  | ユーザーのGitLabユーザー名 | {{< icon name="check-circle" >}}はい| {{< icon name="check-circle" >}}はい |
| `preferred_username` | `string`  | ユーザーのGitLabユーザー名 | {{< icon name="check-circle" >}}はい | {{< icon name="check-circle" >}}はい |
| `email`              | `string`  | ユーザーのプライマリメールアドレス | {{< icon name="check-circle" >}}はい | {{< icon name="check-circle" >}}はい |
| `email_verified`     | `boolean` | ユーザーのメールアドレスが検証済みかどうか | {{< icon name="check-circle" >}}はい | {{< icon name="check-circle" >}}はい |
| `website`            | `string`  | ユーザーのWebサイトのURL | {{< icon name="check-circle" >}}はい | {{< icon name="check-circle" >}}はい |
| `profile`            | `string`  | ユーザーのGitLabプロファイルのURL | {{< icon name="check-circle" >}}はい | {{< icon name="check-circle" >}}はい|
| `picture`            | `string`  | ユーザーのGitLabアバターのURL | {{< icon name="check-circle" >}}はい| {{< icon name="check-circle" >}}はい |
| `groups`             | `array`   | ユーザーが直接、または祖先グループを通じて所属しているグループのパス。 | {{< icon name="dotted-circle" >}}いいえ | {{< icon name="check-circle" >}}はい |
| `groups_direct`      | `array`   | ユーザーが直接所属しているグループのパス。 | {{< icon name="check-circle" >}}はい | {{< icon name="dotted-circle" >}}いいえ |
| `https://gitlab.org/claims/groups/owner`      | `array`   | ユーザーがオーナーロールを持ち、直接所属しているグループの名前 | {{< icon name="dotted-circle" >}}いいえ | {{< icon name="check-circle" >}}はい |
| `https://gitlab.org/claims/groups/maintainer` | `array`   | ユーザーがメンテナーロールを持ち、直接所属しているグループの名前 | {{< icon name="dotted-circle" >}}いいえ | {{< icon name="check-circle" >}}はい |
| `https://gitlab.org/claims/groups/developer`  | `array`   | ユーザーがデベロッパーロールを持ち、直接所属しているグループの名前 | {{< icon name="dotted-circle" >}}いいえ | {{< icon name="check-circle" >}}はい |

アプリケーションが`email`スコープおよびユーザーの公開メールアドレスへのアクセス権を持っている場合にのみ、`email`および`email_verified`のクレームが含まれます。その他すべてのクレームは、OIDCクライアントが使用する`/oauth/userinfo`エンドポイントから取得できます。
