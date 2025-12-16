---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitLabをOAuth 2.0認証用のIdentity Providerとして設定する
---

{{< history >}}

- OAuthアプリケーション向けのグループSAML SSOのサポートは、GitLab 18.2で`ff_oauth_redirect_to_sso_login`[フラグ](../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/461212)されました。デフォルトでは無効になっています。
- OAuthアプリケーションのSAML SSOのサポートは、GitLab 18.3で[GitLab.com、GitLab Self-Managed、GitLab Dedicatedで有効](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/200682)になりました。
- GitLab 18.5で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/561778)開始。機能フラグ`ff_oauth_redirect_to_sso_login`は削除されました。

{{< /history >}}

[OAuth 2.0](https://oauth.net/2/)は、リソースオーナーに代わって、クライアントアプリケーションに対し、サーバーリソースへのアクセス権を安全に委任できる仕組みを提供します。OAuth 2を使用すると、認可サーバーがリソースオーナーまたはエンドユーザーの承認を得て、サードパーティクライアントにアクセストークンを発行できます。

インスタンスに次の種類のOAuth 2アプリケーションを追加することで、GitLabをOAuth 2認証用のIdentity Providerとして使用できます:

- [ユーザーが所有するアプリケーション](#create-a-user-owned-application)
- [グループが所有するアプリケーション](#create-a-group-owned-application)
- [インスタンス全体で使用されるアプリケーション](#create-an-instance-wide-application)

これらの方式の違いは、[権限](../user/permissions.md)レベルのみです。デフォルトのコールバックURLは、SSL URLの`https://your-gitlab.example.com/users/auth/gitlab/callback`です。非SSL URLを使用することもできますが、SSL URLの使用を推奨します。

インスタンスにOAuth 2アプリケーションを追加した後、OAuth 2を使用して次のことを行えます:

- ユーザーがGitLab.comアカウントでアプリケーションにサインインできるようにする。
- SAMLが関連付けられたグループに設定されている場合、[SAML SSO](../user/group/saml_sso/_index.md)を使用してユーザーがアプリケーションにサインインできるようにします。
- GitLabインスタンスへの認証にGitLab.comを使用できるように設定する。詳細については、[サーバーとGitLab.comの連携](gitlab.md)を参照してください。
- アプリケーションを作成すると、外部サービスは[OAuth 2 API](../api/oauth2.md)を使用してアクセストークンを管理できます。

## ユーザーが所有するアプリケーションを作成する {#create-a-user-owned-application}

ユーザーの新しいアプリケーションを作成するには、次の手順に従います:

1. 左側のサイドバーで、アバターを選択します。
1. **プロファイルの編集**を選択します。
1. 左側のサイドバーで、**アプリケーション**を選択します。
1. **新しいアプリケーションを追加**を選択します。
1. **名前**と**リダイレクトURI**を入力します。
1. [許可したアプリケーション](#view-all-authorized-applications)で定義されているように、OAuth 2の**スコープ**を選択します。
1. **リダイレクトURI**に、ユーザーがGitLabで認証した後に転送されるURLを入力します。
1. **アプリケーションを保存**を選択します。GitLabは以下を提供します:

   - **アプリケーションID**フィールドに表示されるOAuth 2クライアントID。
   - OAuth 2クライアントシークレット。**シークレット**フィールドで**コピー**を選択することでアクセスできます。
   - **シークレットを更新**する機能（[GitLab 15.9以降](https://gitlab.com/gitlab-org/gitlab/-/issues/338243)）。この機能を使用すると、このアプリケーションの新しいシークレットを生成し、コピーできます。シークレットを更新すると、認証情報が更新されるまで、既存のアプリケーションは機能しなくなります。

## グループが所有するアプリケーションを作成する {#create-a-group-owned-application}

グループの新しいアプリケーションを作成するには、次の手順に従います:

1. 目的のグループに移動します。
1. 左側のサイドバーで、**設定** > **アプリケーション**を選択します。
1. **名前**と**リダイレクトURI**を入力します。
1. [許可したアプリケーション](#view-all-authorized-applications)で定義されているように、OAuth 2のスコープを選択します。
1. **リダイレクトURI**に、ユーザーがGitLabで認証した後に転送されるURLを入力します。
1. **アプリケーションを保存**を選択します。GitLabは以下を提供します:

   - **アプリケーションID**フィールドに表示されるOAuth 2クライアントID。
   - OAuth 2クライアントシークレット。**シークレット**フィールドで**コピー**を選択することでアクセスできます。
   - **シークレットを更新**する機能（[GitLab 15.9以降](https://gitlab.com/gitlab-org/gitlab/-/issues/338243)）。この機能を使用すると、このアプリケーションの新しいシークレットを生成し、コピーできます。シークレットを更新すると、認証情報が更新されるまで、既存のアプリケーションは機能しなくなります。

## インスタンス全体で使用されるアプリケーションを作成する {#create-an-instance-wide-application}

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

GitLabインスタンスのアプリケーションを作成するには、次の手順に従います:

1. 左側のサイドバーの下部で、**管理者**を選択します。
1. **アプリケーション**を選択します。
1. **New application**（新しいアプリケーション）を選択します。

**管理者エリア**でアプリケーションを作成する場合は、**trusted**（信用済み）としてマークします。このアプリケーションでは、ユーザー認可ステップは自動的にスキップされます。

## 許可したアプリケーションをすべて確認する {#view-all-authorized-applications}

{{< history >}}

- `k8s_proxy`は、GitLab 16.4で`k8s_proxy_pat`[フラグ](../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/422408)されました。デフォルトでは有効になっています。
- 機能フラグ`k8s_proxy_pat`は、GitLab 16.5で[削除](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/131518)されました。

{{< /history >}}

GitLab認証情報を使用して許可したすべてのアプリケーションを表示するには、次の手順に従います:

1. 左側のサイドバーで、アバターを選択します。
1. **プロファイルの編集**を選択し、次に**アプリケーション**を選択します。
1. **許可したアプリケーション**セクションを確認します。

GitLab OAuth 2アプリケーションはスコープをサポートしており、アプリケーションが実行するさまざまなアクションを制御できます。使用可能なすべてのスコープについては、次の表を参照してください。

| スコープ                    | 説明 |
|--------------------------|-------------|
| `api`                    | APIへの完全な読み取り/書き込みアクセスを許可します。このアクセスの対象には、すべてのグループとプロジェクト、コンテナレジストリ、依存プロキシ、パッケージレジストリが含まれます。 |
| `read_api`               | APIへの読み取りアクセスを許可します。このアクセスの対象には、すべてのグループとプロジェクト、コンテナレジストリ、パッケージレジストリが含まれます。 |
| `read_user`              | `/user` APIエンドポイントを介して、認証済みユーザーのプロファイルへの読み取り専用アクセスを許可します。これには、ユーザー名、公開メール、および氏名が含まれます。また、`/users`にある読み取り専用APIエンドポイントへのアクセスも許可します。 |
| `create_runner`          | runnerへの作成アクセス権を付与します。 |
| `manage_runner`          | runnerを管理するためのアクセス権を付与します。 |
| `k8s_proxy`              | Kubernetesエージェントを使用してKubernetes APIコールを実行する権限を付与します。 |
| `read_repository`        | HTTP経由のGitまたはリポジトリファイルAPIを使用して、プライベートプロジェクトのリポジトリへの読み取り専用アクセスを許可します。 |
| `write_repository`       | HTTP経由のGit（APIは使用しない）を使用して、プライベートプロジェクトのリポジトリへの読み取り/書き込みアクセスを許可します。 |
| `read_registry`          | プライベートプロジェクトのコンテナレジストリ内のイメージへの読み取り専用アクセスを許可します。 |
| `write_registry`         | プライベートプロジェクトで、コンテナレジストリイメージへの書き込みアクセスを許可します。イメージをプッシュするには、読み取りアクセスと書き込みアクセスの両方が必要です。 |
| `read_virtual_registry`  | プライベートプロジェクトおよび仮想レジストリ内の依存プロキシを通じて、コンテナイメージへの読み取り専用アクセス権を付与します。 |
| `write_virtual_registry` | プライベートプロジェクト内の依存プロキシを通じて、コンテナイメージへの読み取り、書き込み、削除アクセス権を付与します。 |
| `read_observability`     | GitLab可観測性への読み取り専用アクセス権を付与します。 |
| `write_observability`    | GitLab可観測性への書き込みアクセス権を付与します。 |
| `ai_features`            | GitLab Duo関連のAPIエンドポイントへのアクセス権を付与します。 |
| `sudo`                   | 管理者ユーザーとして認証されている場合に、システム内の任意のユーザーとしてAPIアクションを実行する権限を許可します。 |
| `admin_mode`             | 管理者モードが有効になっている場合、管理者としてAPIアクションを実行する権限を許可します |
| `read_service_ping`      | 管理者ユーザーとして認証された場合、API経由でService Pingペイロードをダウンロードするためのアクセス権を付与します。 |
| `openid`                 | [OpenID Connect](openid_connect_provider.md)を使用してGitLabで認証する権限を許可します。また、ユーザーのプロファイルおよびグループメンバーシップへの読み取り専用アクセスも許可します。 |
| `profile`                | [OpenID Connect](openid_connect_provider.md)を使用して、ユーザーのプロファイルデータへの読み取り専用アクセスを許可します。 |
| `email`                  | [OpenID Connect](openid_connect_provider.md)を使用して、ユーザーのプライマリメールアドレスへの読み取り専用アクセスを許可します。 |

いつでも、**取り消し**を選択して、任意のアクセスを取り消すことができます。

## アクセストークンの有効期限 {#access-token-expiration}

{{< history >}}

- `expires_in`におけるデータベース検証は、GitLab 15.10で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/112765)されました。15.10以降にアップグレードする際、`expires_in`が設定されていないOAuthアクセストークンがGitLabインスタンスに残っている場合、データベースの移行時にエラーが発生します。回避策については、[GitLab 15.10.0のアップグレードに関するドキュメント](../update/versions/gitlab_15_changes.md#15100)を参照してください。

{{< /history >}}

{{< alert type="warning" >}}

アクセストークンの有効期限を無効にする機能は、GitLab 15.0で[削除](https://gitlab.com/gitlab-org/gitlab/-/issues/340848)されました。アクセストークンの更新に対応するため、既存のすべてのインテグレーションを更新する必要があります。

{{< /alert >}}

アクセストークンは2時間後に有効期限切れになります。アクセストークンを使用するインテグレーションは、`refresh_token`属性を使用して新しいトークンを生成する必要があります。リフレッシュトークンは、`access_token`自体が有効期限切れになった後でも使用可能です。有効期限切れのアクセストークンを更新する方法については、[OAuth 2.0トークンに関するドキュメント](../api/oauth2.md)を参照してください。

この有効期限の設定は、GitLabをOAuthプロバイダーとして機能させるライブラリである[Doorkeeper](https://github.com/doorkeeper-gem/doorkeeper)の`access_token_expires_in`設定を使用して、GitLabのコードベース内で設定されています。この有効期限設定は変更できません。

アプリケーションを削除すると、そのアプリケーションに関連付けられたすべての認可とトークンも削除されます。

## ハッシュ化されたOAuthアプリケーションシークレット {#hashed-oauth-application-secrets}

{{< history >}}

- GitLab 15.4で`hash_oauth_secrets`[フラグ](../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/374588)されました。デフォルトでは無効になっています。
- GitLab 15.8の[GitLab.comで有効になりました](https://gitlab.com/gitlab-org/gitlab/-/issues/374588)。
- GitLab 15.9の[GitLab Self-Managedで有効](https://gitlab.com/gitlab-org/gitlab/-/issues/374588)になりました。
- GitLab 15.10で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/113892)になりました。機能フラグ`hash_oauth_secrets`は削除されました。

{{< /history >}}

デフォルトでは、GitLabはOAuthアプリケーションシークレットをハッシュ化された形式でデータベースに保存します。これらのシークレットは、OAuthアプリケーションの作成直後にのみユーザーが確認できます。以前のバージョンのGitLabでは、アプリケーションシークレットをプレーンテキスト形式でデータベースに保存していました。

## GitLabにおけるOAuth 2のその他の活用方法 {#other-ways-to-use-oauth-2-in-gitlab}

次のことが可能です:

- [アプリケーションAPI](../api/applications.md)を使用して、OAuth 2アプリケーションを作成および管理する。
- サードパーティのOAuth 2プロバイダーを使用して、ユーザーがGitLabにサインインできるようにする。詳細については、[OmniAuthのドキュメント](omniauth.md)を参照してください。
- OAuth 2とGitLabインポーターを組み合わせることで、ユーザー認証情報をGitLab.comアカウントと共有することなく、リポジトリへのアクセスを許可する。
