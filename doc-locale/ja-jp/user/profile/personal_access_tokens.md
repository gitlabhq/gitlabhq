---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: パーソナルアクセストークンを使用して、HTTPSを介してGitLab APIまたはGitで認証します。作成、ローテーション、取り消し、スコープ、および有効期限の設定などについて説明します。
title: パーソナルアクセストークン
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

パーソナルアクセストークンは、[OAuth2](../../api/oauth2.md)の代替として、次の目的で使用できます:

- GitLab APIで認証する。
- HTTP基本認証を使用してGitで認証する。

どちらの場合も、パスワードの代わりにパーソナルアクセストークンで認証します。ユーザー名は、認証プロセスの一環として評価されません。

パーソナルアクセストークンの特徴は次のとおりです:

- [2要素認証（2FA）](account/two_factor_authentication.md)または[SAML](../../integration/saml.md#password-generation-for-users-created-through-saml)が有効になっている場合に必要です。
- ユーザー名を必要とするGitLabの機能でGitLabのユーザー名と併用して認証します。たとえば、[GitLab管理のTerraformステート管理バックエンド](../infrastructure/iac/terraform_state.md#use-your-gitlab-backend-as-a-remote-data-source)や[Dockerコンテナレジストリ](../packages/container_registry/authenticate_with_container_registry.md)などです。
- [プロジェクトアクセストークン](../project/settings/project_access_tokens.md)や[グループアクセストークン](../group/settings/group_access_tokens.md)と似ていますが、プロジェクトやグループではなく、ユーザーに紐付いています。

{{< alert type="note" >}}

必須とされていますが、パーソナルアクセストークンで認証する場合、GitLabのユーザー名は実際には無視されます。GitLabがユーザー名を使用するように改善する[イシューを追跡](https://gitlab.com/gitlab-org/gitlab/-/issues/212953)できます。

{{< /alert >}}

APIでパーソナルアクセストークンを使用して認証する方法の例については、APIドキュメントを参照してください。

または、GitLab管理者はAPIを使用して、代理トークンを作成できます。特定のユーザーとして認証を自動化するには、代行トークンを使用します。

## パーソナルアクセストークンを作成する {#create-a-personal-access-token}

{{< history >}}

- GitLab 15.3で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/348660)されました。UIには、30日のデフォルトの有効期限が表示されるようになりました。
- 有効期限のないパーソナルアクセストークンを作成する機能は、GitLab 16.0で[削除](https://gitlab.com/gitlab-org/gitlab/-/issues/392855)されました。
- GitLab 17.6で、`buffered_token_expiration_limit`[フラグ](../../administration/feature_flags/list.md)とともに、最大許容ライフタイム制限が[400日に延長](https://gitlab.com/gitlab-org/gitlab/-/issues/461901)されました。デフォルトでは無効になっています。
- パーソナルアクセストークンの説明は、GitLab 17.7で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/443819)されました。

{{< /history >}}

{{< alert type="flag" >}}

拡張された最大許容ライフタイム制限の可用性は、機能フラグによって制御されます。詳細については、履歴を参照してください。

{{< /alert >}}

{{< alert type="warning" >}}

有効期限のないパーソナルアクセストークンを作成する機能は、GitLab 15.4で[非推奨](https://gitlab.com/gitlab-org/gitlab/-/issues/369122)となり、GitLab 16.0で[削除](https://gitlab.com/gitlab-org/gitlab/-/issues/392855)されました。パーソナルアクセストークンの有効期限がいつ切れ、既存のトークンに有効期限がいつ追加されるかについては、[アクセストークンの有効期限](#access-token-expiration)に関するドキュメントを参照してください。

{{< /alert >}}

パーソナルアクセストークンは必要な数だけ作成できます。

1. 左側のサイドバーで、自分のアバターを選択します。
1. **プロファイルの編集**を選択します。
1. 左側のサイドバーで、**パーソナルアクセストークン**を選択します。
1. **新しいトークンを追加**を選択します。
1. **トークン名**に、トークンの名前を入力します。
1. オプション。**トークンの説明**に、トークンの説明を入力します。
1. **有効期限**に、トークンの有効期限を入力します。
   - トークンは、その日付のUTC午前0時に期限切れになります。有効期限が2024-01-01のトークンは、2024-01-01の00:00:00 UTCに期限切れになります。
   - 有効期限を入力しない場合、有効期限は現在の日付より365日後に自動的に設定されます。
   - デフォルトでは、この日付は現在の日付より最大365日後に設定できます。GitLab 17.6以降では、この制限を400日に延長できます。

1. [必要なスコープ](#personal-access-token-scopes)を選択します。
1. **Create personal access token**（パーソナルアクセストークンを作成）を選択します。

パーソナルアクセストークンを安全な場所に保存します。ページを離れると、トークンにアクセスできなくなります。

### パーソナルアクセストークンの詳細を事前に入力する {#prefill-personal-access-token-details}

名前、説明、およびスコープのリストをURLに付加することで、パーソナルアクセストークンの詳細を事前に入力できます。次に例を示します:

```plaintext
https://gitlab.example.com/-/user_settings/personal_access_tokens?name=Example+Access+token&description=My+description&scopes=api,read_user
```

{{< alert type="warning" >}}

パーソナルアクセストークンは慎重に扱う必要があります。パーソナルアクセストークンの管理（短い有効期限の設定、最小限のスコープの使用など）については、[トークンのセキュリティに関する考慮事項](../../security/tokens/_index.md#security-considerations)をお読みください。

{{< /alert >}}

## パーソナルアクセストークンをローテーションする {#rotate-a-personal-access-token}

{{< history >}}

- UIを使用してパーソナルアクセストークンをローテーションする機能は、GitLab 17.7で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/241523)されました。
- GitLab 18.1の[更新されたUI](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/194582)。

{{< /history >}}

トークンをローテーションすると、以前のバージョンを無効にしながら、新しいトークンが新しい認証情報で作成されます。ローテーションされたトークンは、元のトークンと同じ権限とスコープを維持します。古いトークンはすぐに非アクティブになり、両方のバージョンは監査証跡の目的でシステムに残ります。

パーソナルアクセストークンをローテーションするには:

1. 左側のサイドバーで、自分のアバターを選択します。
1. **プロファイルの編集**を選択します。
1. 左側のサイドバーで、**パーソナルアクセストークン**を選択します。
1. アクティブなトークンの横にある縦方向の省略記号（{{< icon name="ellipsis_v" >}}）を選択します。
1. **ローテーション**（{{< icon name="retry" >}}）を選択します。
1. 確認ダイアログで、**ローテーション**を選択します。

## パーソナルアクセストークンを失効させる {#revoke-a-personal-access-token}

{{< history >}}

- GitLab 18.1の[更新されたUI](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/194582)。

{{< /history >}}

トークンを失効すると、すぐに無効になり、認証または認可にそれ以上使用できなくなります。失効されたトークンは、トークンの履歴の監査証跡を維持するためにシステムに残ります。トークンを完全に削除することはできませんが、トークンリストをフィルタリングしてアクティブなトークンのみを表示できます。

パーソナルアクセストークンを失効させるには:

1. 左側のサイドバーで、自分のアバターを選択します。
1. **プロファイルの編集**を選択します。
1. 左側のサイドバーで、**パーソナルアクセストークン**を選択します。
1. アクティブなトークンの横にある縦方向の省略記号（{{< icon name="ellipsis_v" >}}）を選択します。
1. **取り消し**（{{< icon name="remove" >}}）を選択します。
1. 確認ダイアログで、**取り消し**を選択します。

   {{< alert type="warning" >}}

   これらのアクションは元に戻せません。取り消しまたはローテーションされたアクセストークンに依存するツールは動作しなくなります。

   {{< /alert >}}

## パーソナルアクセストークンを無効にする {#disable-personal-access-tokens}

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

前提要件:

- 管理者である必要があります。

GitLabのバージョンに応じて、アプリケーション設定APIまたは管理者UIのいずれかを使用して、パーソナルアクセストークンを無効にすることができます。

### アプリケーション設定APIを使用する {#use-the-application-settings-api}

{{< history >}}

- GitLab 15.7で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/384201)されました。

{{< /history >}}

GitLab 15.7以降では、[アプリケーション設定APIの`disable_personal_access_tokens`属性](../../api/settings.md#available-settings)を使用して、パーソナルアクセストークンを無効にすることができます。

{{< alert type="note" >}}

APIを使用してパーソナルアクセストークンを無効にすると、その後はそれらのトークンを使って、この設定を管理するためのAPIコールを行えなくなります。パーソナルアクセストークンを再度有効にするには、[GitLab Railsコンソール](../../administration/operations/rails_console.md)を使用する必要があります。また、GitLab 17.3以降にアップグレードして、代わりに管理者UIを使用することもできます。

{{< /alert >}}

### 管理者UIを使用する {#use-the-admin-ui}

{{< history >}}

- GitLab 17.3で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/436991)されました。

{{< /history >}}

GitLab 17.3以降では、管理者UIを使用してパーソナルアクセストークンを無効にできます:

1. 左側のサイドバーの下部で、**管理者**を選択します。
1. **設定** > **一般**を選択します。
1. **表示レベルとアクセス制御**を展開します。
1. **パーソナルアクセストークンを無効にする**チェックボックスをオンにします。
1. **変更を保存**を選択します。

### エンタープライズユーザーのパーソナルアクセストークンを無効にする {#disable-personal-access-tokens-for-enterprise-users}

{{< history >}}

- GitLab 16.11で`enterprise_disable_personal_access_tokens`[フラグ](../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/369504)されました。デフォルトでは無効になっています。
- GitLab 17.2の[GitLab.comで有効](https://gitlab.com/gitlab-org/gitlab/-/issues/369504)になりました。
- GitLab 17.3で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/369504)になりました。機能フラグ`enterprise_disable_personal_access_tokens`は削除されました。

{{< /history >}}

前提要件:

- エンタープライズユーザーが所属するグループのオーナーロールを持っている必要があります。

グループの[エンタープライズユーザー](../enterprise_user/_index.md)のパーソナルアクセストークンを無効にすると、次のようになります:

- エンタープライズユーザーは新しいパーソナルアクセストークンを作成できなくなります。この動作は、エンタープライズユーザーがグループ管理者である場合でも適用されます。
- エンタープライズユーザーの既存のパーソナルアクセストークンが無効になります。

{{< alert type="warning" >}}

エンタープライズユーザーのパーソナルアクセストークンを無効にしても、[サービスアカウント](service_accounts.md)のパーソナルアクセストークンは無効になりません。

{{< /alert >}}

エンタープライズユーザーのパーソナルアクセストークンは、次の手順で無効にできます:

1. 左側のサイドバーで、**検索または移動先**を選択して、グループを見つけます。
1. **設定** > **一般**を選択します。
1. **権限とグループ機能**を展開します。
1. **パーソナルアクセストークン**で、**パーソナルアクセストークンを無効にする**を選択します。
1. **変更を保存**を選択します。

エンタープライズユーザーアカウントを削除またはブロックすると、そのユーザーのパーソナルアクセストークンは自動的に取り消されます。

## トークンの使用状況情報を表示する {#view-token-usage-information}

{{< history >}}

- GitLab 16.0以前では、トークンの使用状況情報は24時間ごとに更新されていました。
- トークンの使用状況情報の更新頻度は、GitLab 16.1で24時間から10分に[変更](https://gitlab.com/gitlab-org/gitlab/-/issues/410168)されました。
- IPアドレスを表示する機能は、GitLab 17.8で`pat_ip`[フラグ](../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/428577)されました。17.9ではデフォルトで有効になっています。
- IPアドレスを表示する機能は、GitLab 17.10で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/513302)になりました。機能フラグ`pat_ip`は削除されました。

{{< /history >}}

トークンの使用状況に関する情報は定期的に更新されます。トークンが最後に使用された時刻は10分ごとに更新され、最後に使用されたIPアドレスは1分ごとに更新されます。GitLabは、次の場合にトークンが使用されたと見なします:

- [REST](../../api/rest/_index.md)または[GraphQL](../../api/graphql/_index.md) APIで認証した場合。
- Gitオペレーションを実行した場合。

トークンが最後に使用された時刻と、トークンが使用されたIPアドレスは、次の手順で表示できます:

1. 左側のサイドバーで、自分のアバターを選択します。
1. **プロファイルの編集**を選択します。
1. 左側のサイドバーで、**パーソナルアクセストークン**を選択します。
1. **Active personal access tokens**（有効なパーソナルアクセストークン）エリアで、関連するトークンの**前回使用した日**と**最後に使用したIP**を確認します。**最後に使用したIP**には、最後に使用された5つの異なるIPアドレスが表示されます。

## パーソナルアクセストークンのスコープ {#personal-access-token-scopes}

{{< history >}}

- パーソナルアクセストークンがコンテナレジストリまたはパッケージレジストリにアクセスできなくなりました。この措置は、GitLab 16.0で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/387721)されました。
- `k8s_proxy`は、GitLab 16.4で`k8s_proxy_pat`[フラグ](../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/422408)されました。デフォルトでは有効になっています。
- 機能フラグ`k8s_proxy_pat`は、GitLab 16.5で[削除](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/131518)されました。
- `read_service_ping`は、GitLab 17.1で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/42692#note_1222832412)されました。
- `manage_runner`は、GitLab 17.1で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/460721)されました。
- `self_rotate`は、GitLab 17.9で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/178111)されました。デフォルトでは有効になっています。

{{< /history >}}

パーソナルアクセストークンは、割り当てられたスコープに基づいてアクションを実行できます。

| スコープ              | アクセス                                                                                                                                                                                                                                                                                                             |
|--------------------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `api`              | APIへの完全な読み取り/書き込みアクセスを許可します。すべてのグループとプロジェクト、コンテナレジストリ、依存プロキシ、およびパッケージレジストリを含みます。また、HTTP経由のGitを使用した、レジストリとリポジトリへの完全な読み取り/書き込みアクセスも許可します。                                                                                                                                                           |
| `read_user`        | `/user` APIエンドポイントを介して、認証済みユーザーのプロファイルへの読み取り専用アクセスを許可します。これには、ユーザー名、公開メール、および氏名が含まれます。また、[`/users`](../../api/users.md)の下にある読み取り専用APIエンドポイントへのアクセスも許可します。                                                                            |
| `read_api`         | APIへの読み取りアクセスを許可します。このアクセスの対象には、すべてのグループとプロジェクト、コンテナレジストリ、パッケージレジストリが含まれます。                    |
| `read_repository`  | HTTP経由のGitまたはリポジトリファイルAPIを使用して、プライベートプロジェクトのリポジトリへの読み取り専用アクセスを許可します。                                                                                                                                                                                                       |
| `write_repository` | HTTP経由のGit（APIは使用しない）を使用して、プライベートプロジェクトのリポジトリへの読み取り/書き込みアクセスを許可します。                                                                                                                                                                                                              |
| `read_registry`    | プロジェクトがプライベートで認証が必要な場合、[コンテナレジストリ](../packages/container_registry/_index.md)イメージへの読み取り専用（プル）アクセスを許可します。コンテナレジストリが有効になっている場合にのみ使用できます。                                                                                               |
| `write_registry`   | プロジェクトがプライベートで認証が必要な場合、[コンテナレジストリ](../packages/container_registry/_index.md)イメージへの読み取り/書き込み（プッシュ）アクセスを許可します。コンテナレジストリが有効になっている場合にのみ使用できます。  |
| `read_virtual_registry`  | プロジェクトがプライベートで、認証が必要な場合は、[依存プロキシ](../packages/dependency_proxy/_index.md)を介して、コンテナイメージへの読み取り専用（プル）アクセス権を付与します。依存プロキシが有効になっている場合にのみ使用できます。 |
| `write_virtual_registry` | プロジェクトがプライベートで、認証が必要な場合は、[依存プロキシ](../packages/dependency_proxy/_index.md)を介して、コンテナイメージへの読み取り（プル）、書き込み（プッシュ）、および削除アクセス権を付与します。依存プロキシが有効になっている場合にのみ使用できます。 |
| `sudo`             | 管理者として認証されている場合、システム内の任意のユーザーとしてAPIアクションを実行する権限を許可します。                                                                                                                                                                                                        |
| `admin_mode`       | [管理者モード](../../administration/settings/sign_in_restrictions.md#admin-mode)が有効になっている場合にAPIアクションを実行する権限を付与します。GitLab 15.8で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/107875)されました。GitLab Self-Managedインスタンスの管理者のみが使用できます。 |
| `create_runner`    | Runnerを作成する権限を付与します。                                                                                                                                                                                                                                                                               |
| `manage_runner`    | Runnerを管理する権限を付与します。                                                                    |
| `ai_features`      | このスコープには以下の機能があります:<br>\- GitLab Duo、コード提案API、Duo Chat APIなどの機能のAPIアクションを実行する権限を付与します。<br>\- GitLab Self-Managedバージョン16.5、16.6、および16.7では機能しません。<br>JetBrains用GitLab Duoプラグインの場合、このスコープの機能は以下のとおりです:<br>\- JetBrains用GitLab DuoプラグインでAI機能が有効になっているユーザーをサポートします。<br>\- パーソナルアクセストークンを公開する危険性のあるJetBrains IDEプラグインのセキュリティ脆弱性に対処します。<br>\- 不正なトークンの影響を制限することにより、GitLab Duoプラグインユーザーの潜在的なリスクを最小限に抑えるように設計されています。<br>その他のすべての拡張機能については、ドキュメントで個々のスコープ要件を参照してください。                                                                                                                                |
| `k8s_proxy`        | Kubernetesエージェントを使用してKubernetes APIコールを実行する権限を付与します。                                                                                                                                                                                                                                  |
| `self_rotate`      | [パーソナルアクセストークンAPI](../../api/personal_access_tokens.md#rotate-a-personal-access-token)を使用して、このトークンをローテーションする権限を付与します。他のトークンのローテーションは許可しません。 |
| `read_service_ping`| 管理者ユーザーとして認証された場合、APIを通じてService Pingペイロードをダウンロードするためのアクセス権を付与します。 |

{{< alert type="warning" >}}

[外部認証](../../administration/settings/external_authorization.md)を有効にした場合、パーソナルアクセストークンはコンテナレジストリまたはパッケージレジストリにアクセスできません。これらのレジストリへのアクセスにパーソナルアクセストークンを使用している場合、この対策により、そのようなトークンの使用が中断されます。コンテナレジストリまたはパッケージレジストリでパーソナルアクセストークンを使用するには、外部認証を無効にします。

{{< /alert >}}

## アクセストークンの有効期限 {#access-token-expiration}

{{< history >}}

- 400日の最大トークンライフタイムは、GitLab 17.6で`buffered_token_expiration_limit`[フラグ](../../administration/feature_flags/list.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/241523)されました。デフォルトでは無効になっています。

{{< /history >}}

{{< alert type="flag" >}}

拡張された最大許容ライフタイム制限の可用性は、機能フラグによって制御されます。詳細については、履歴を参照してください。

{{< /alert >}}

パーソナルアクセストークンは、定義した日付のUTC午前0時00分に期限切れになります。有効期限が2024-01-01のトークンは、2024-01-01の00:00:00 UTCに期限切れになります。

- GitLabはUTC午前1時00分にチェックを毎日実行して、間もなく期限切れになるパーソナルアクセストークンを特定します。これらのトークンの所有者は[メールで通知](#personal-access-token-expiry-emails)されます。
- GitLabはUTC午前2時00分にチェックを毎日実行して、当日期限切れになるパーソナルアクセストークンを特定します。これらのトークンの所有者はメールで通知されます。
- GitLab Ultimateでは、管理者は[アクセストークンの許容ライフタイムを制限](../../administration/settings/account_and_limit_settings.md#limit-the-lifetime-of-access-tokens)できます。設定されていない場合、パーソナルアクセストークンの最大許容ライフタイムは365日です。GitLab 17.6以降では、この制限を400日に延長できます。
- GitLab FreeおよびPremiumでは、パーソナルアクセストークンの最大許容ライフタイムは365日です。GitLab 17.6以降では、この制限を400日に延長できます。
- パーソナルアクセストークンを作成するときに有効期限を設定しない場合、有効期限は[トークンの最大許容ライフタイム](../../administration/settings/account_and_limit_settings.md#limit-the-lifetime-of-access-tokens)に設定されます。最大許容ライフタイムが設定されていない場合、デフォルトの有効期限は作成日から365日後です。

既存のパーソナルアクセストークンに有効期限が自動的に適用されるかどうかは、お使いのGitLabの提供形態と、GitLab 16.0以降にアップグレードした時期によって異なります:

- GitLab.comでは、16.0のマイルストーン中に、有効期限のない既存のパーソナルアクセストークンに対して、現在の日付から365日後という有効期限が自動的に設定されました。
- GitLab Self-Managedで、GitLab 15.11以前からGitLab 16.0以降にアップグレードした場合:
  - 2024年7月23日以前は、有効期限のない既存のパーソナルアクセストークンに、現在の日付から365日後の有効期限が自動的に付与されました。これは破壊的な変更です。
  - 2024年7月24日以降、有効期限のない既存のパーソナルアクセストークンには、有効期限が設定されていませんでした。

GitLab Self-Managedでは、次のGitLabバージョンのいずれかを新規インストールした場合、既存のパーソナルアクセストークンに有効期限が自動的に適用されることはありません:

- 16.0.9
- 16.1.7
- 16.2.10
- 16.3.8
- 16.4.6
- 16.5.9
- 16.6.9
- 16.7.9
- 16.8.9
- 16.9.10
- 16.10.9
- 16.11.7
- 17.0.5
- 17.1.3
- 17.2.1

### パーソナルアクセストークンの有効期限に関するメール {#personal-access-token-expiry-emails}

{{< history >}}

- 60日前と30日前の有効期限通知は、GitLab 17.6で`expiring_pats_30d_60d_notifications`[フラグ](../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/464040)されました。デフォルトでは無効になっています。
- 60日前と30日前の通知は、GitLab 17.7で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/173792)になりました。機能フラグ`expiring_pats_30d_60d_notifications`は削除されました。

{{< /history >}}

GitLabは、UTC午前1時00分にチェックを毎日実行して、近日中に有効期限が切れるパーソナルアクセストークンを特定します。該当トークンのオーナーには、一定の日数で有効期限が切れる旨をメールで通知します。日数は、GitLabのバージョンによって異なります:

- GitLab 17.6以降では、パーソナルアクセストークンが今後60日以内に有効期限切れになることが確認された場合、オーナーにメールで通知されます。グループアクセストークンが今後30日以内に有効期限切れになることが確認された場合、追加のメールが送信されます。
- グループアクセストークンが今後7日以内に有効期限切れになることが確認された場合、オーナーにメールで通知されます。

### パーソナルアクセストークンの有効期限カレンダー {#personal-access-token-expiry-calendar}

各トークンの有効期限にイベントが設定されたiCalendarエンドポイントをサブスクライブできます。サインイン後、このエンドポイントは`/-/user_settings/personal_access_tokens.ics`で利用できます。

### 有効期限のないサービスアカウントのパーソナルアクセストークンを作成する {#create-a-service-account-personal-access-token-with-no-expiry-date}

有効期限のない[サービスアカウントのパーソナルアクセストークンを作成](../../api/service_accounts.md#create-a-personal-access-token-for-a-group-service-account)できます。これらのパーソナルアクセストークンは、通常のアカウントのパーソナルアクセストークンとは異なり、有効期限切れになることはありません。

{{< alert type="note" >}}

サービスアカウントのパーソナルアクセストークンを有効期限なしで作成できるようにする設定は、この設定を変更した後に作成されたトークンにのみ影響します。既存のトークンには影響しません。

{{< /alert >}}

#### GitLab.com {#gitlabcom}

前提要件:

- トップレベルグループのオーナーロールが必要です。

1. 左側のサイドバーで、**検索または移動先**を選択して、グループを見つけます。
1. **設定** > **一般** > **権限とグループ機能**を選択します。
1. **Service account token expiration**（サービスアカウントトークンの有効期限）チェックボックスをオフにします。

これで、有効期限のないサービスアカウントユーザーのパーソナルアクセストークンを作成できます。

#### GitLab Self-Managed {#gitlab-self-managed}

前提要件:

- GitLab Self-Managedインスタンスの管理者である必要があります。

1. 左側のサイドバーの下部で、**管理者**を選択します。
1. **設定** > **一般**を選択します。
1. **アカウントと制限**を展開します。
1. **Service account token expiration**（サービスアカウントトークンの有効期限）チェックボックスをオフにします。

これで、有効期限のないサービスアカウントユーザーのパーソナルアクセストークンを作成できます。

## パーソナルアクセストークンでDPoPを使用する {#use-dpop-with-personal-access-tokens}

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed

{{< /details >}}

{{< history >}}

- GitLab 17.10で`dpop_authentication`[フラグ](../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/181053)されました。デフォルトでは無効になっています。

{{< /history >}}

{{< alert type="flag" >}}

この機能の利用可否は、機能フラグによって制御されます。詳細については、履歴を参照してください。この機能はテストには利用できますが、本番環境での使用には適していません。

{{< /alert >}}

Demonstrating Proof of Possession（DPoP、所有証明の実証）は、パーソナルアクセストークンのセキュリティを強化し、意図しないトークンの漏洩の影響を最小限に抑えます。アカウントでこの機能を有効にすると、PATを含むすべてのRESTおよびGraphQL APIリクエストで、署名付きDPoPヘッダーも提供する必要が生じます。署名付きDPoPヘッダーを作成するには、対応する秘密SSHキーが必要です。

{{< alert type="note" >}}

この機能を有効にすると、有効なDPoPヘッダーがないすべてのAPIリクエストは、`DpopValidationError`エラーを返します。

アクセストークンを含むHTTPS経由のGitオペレーションでは、DPoPヘッダーは必須ではありません。

{{< /alert >}}

前提要件:

- [少なくとも1つの公開SSHキーをアカウントに追加](../ssh.md#add-an-ssh-key-to-your-gitlab-account)します。**署名**、または**認証と署名**の**使用タイプ**を設定する必要があります。
  - SSHキータイプはRSAである必要があります。
- GitLabアカウント用に[GitLab CLI](../../editor_extensions/gitlab_cli/_index.md)をインストールして設定する必要があります。

RESTおよびGraphQL APIへのすべての呼び出しで、DPoPを要求するには:

1. 左側のサイドバーで、自分のアバターを選択します。
1. **プロファイルの編集**を選択します。
1. 左側のサイドバーで、**パーソナルアクセストークン**を選択します。
1. **Demonstrating Proof of Possession (DPoP)の使用**セクションに移動し、**DPoPを有効にする**を選択します。
1. **変更を保存**を選択します。
1. ターミナルで次のコマンドを実行して、[GitLab CLI](../../editor_extensions/gitlab_cli/_index.md)でDPoPヘッダーを生成します。`<your_access_token>`をアクセストークンに、`~/.ssh/id_rsa`を秘密キーの場所に置き換えます:

   ```shell
    glab auth dpop-gen --pat "<your_access_token>" --private-key ~/.ssh/id_rsa
   ```

CLIで生成したDPoPヘッダーは、以下のように使用できます:

- REST APIでの使用:

  ```shell
  curl --header "Private-Token: <your_access_token>" \
    --header "DPoP: <dpop-from-glab>" \
    "https://gitlab.example.com/api/v4/projects"
  ```

- GraphQLでの使用:

  ```shell
   curl --request POST \
   --header "Content-Type: application/json" \
   --header "Private-Token: <your_access_token>" \
   --header "DPoP: <dpop-from-glab>" \
   --data '{
   "query": "query { currentUser { id } }"
   }' \
   "https://gitlab.example.com/api/graphql"
  ```

DPoPの詳細については、ブループリント[送信者制約パーソナルアクセストークン](https://gitlab.com/gitlab-com/gl-security/product-security/appsec/security-feature-blueprints/-/tree/main/sender_constraining_access_tokens)を参照してください。

## プログラムを利用してパーソナルアクセストークンを作成する {#create-a-personal-access-token-programmatically}

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

テストまたは自動化の一環として、事前に決定されたパーソナルアクセストークンを作成できます。

前提要件:

- GitLabインスタンスで[Railsコンソールセッション](../../administration/operations/rails_console.md#starting-a-rails-console-session)を実行するための十分なアクセス権が必要です。

プログラムを利用してパーソナルアクセストークンを作成する手順は次のとおりです:

1. Railsコンソールを開きます:

   ```shell
   sudo gitlab-rails console
   ```

1. 次のコマンドを実行して、ユーザー名、トークン、スコープを参照します。

   トークンは20文字の長さでなければなりません。スコープは有効である必要があり、[ソースコード](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/auth.rb)で表示できます。

   たとえば、ユーザー名が`automation-bot`のユーザーに属し、1年後に期限切れになるトークンは、次のコマンドで作成できます:

   ```ruby
   user = User.find_by_username('automation-bot')
   token = user.personal_access_tokens.create(scopes: ['read_user', 'read_repository'], name: 'Automation token', expires_at: 365.days.from_now)
   token.set_token('token-string-here123')
   token.save!
   ```

このコードは、[Rails runner](../../administration/operations/rails_console.md#using-the-rails-runner)を使用して、単一行のシェルコマンドに短縮できます:

```shell
sudo gitlab-rails runner "token = User.find_by_username('automation-bot').personal_access_tokens.create(scopes: ['read_user', 'read_repository'], name: 'Automation token', expires_at: 365.days.from_now); token.set_token('token-string-here123'); token.save!"
```

## プログラムを利用してパーソナルアクセストークンを取り消す {#revoke-a-personal-access-token-programmatically}

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

テストまたは自動化の一環として、プログラムを利用してパーソナルアクセストークンを取り消すことができます。

前提要件:

- GitLabインスタンスで[Railsコンソールセッション](../../administration/operations/rails_console.md#starting-a-rails-console-session)を実行するための十分なアクセス権が必要です。

プログラムを利用してトークンを取り消す手順は次のとおりです:

1. Railsコンソールを開きます:

   ```shell
   sudo gitlab-rails console
   ```

1. 次のコマンドを実行して、`token-string-here123`のトークンを取り消します:

   ```ruby
   token = PersonalAccessToken.find_by_token('token-string-here123')
   token.revoke!
   ```

このコードは、[Rails runner](../../administration/operations/rails_console.md#using-the-rails-runner)を使用して、単一行のシェルコマンドに短縮できます:

```shell
sudo gitlab-rails runner "PersonalAccessToken.find_by_token('token-string-here123').revoke!"
```

## パーソナルアクセストークンを使用してリポジトリをクローンする {#clone-repository-using-personal-access-token}

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

SSHが無効になっている場合にリポジトリをクローンするには、次のコマンドを実行してパーソナルアクセストークンを使用してクローンします:

```shell
git clone https://<username>:<personal_token>@gitlab.com/gitlab-org/gitlab.git
```

この方法では、パーソナルアクセストークンがbashの履歴に保存されます。これを回避するには、次のコマンドを実行します:

```shell
git clone https://<username>@gitlab.com/gitlab-org/gitlab.git
```

`https://gitlab.com`のパスワードを求められたら、パーソナルアクセストークンを入力します。

`clone`コマンドの`username`は、次の条件を満たす必要があります:

- 任意の文字列を指定できます。
- 空の文字列は使用できません。

認証に依存する自動化パイプラインを設定する場合は、この条件を必ず守ってください。

## トラブルシューティング {#troubleshooting}

### パーソナルアクセストークンの取り消しを解除する {#unrevoke-a-personal-access-token}

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

何らかの方法でパーソナルアクセストークンが誤って取り消された場合、管理者はそのトークンの取り消しを解除できます。デフォルトでは、日次ジョブで午前1:00（システム時間）に、取り消されたトークンが削除されます。

{{< alert type="warning" >}}

次のコマンドを実行すると、データを直接変更できます。正しく実行されなかったり、適切な条件下で実行されなかったりすると、問題を引き起こす可能性があります。念のため、まずはインスタンスのバックアップを準備したテスト環境でこれらのコマンドを実行してください。

{{< /alert >}}

1. [Railsコンソール](../../administration/operations/rails_console.md#starting-a-rails-console-session)を開きます。
1. トークンの取り消しを解除します:

   ```ruby
   token = PersonalAccessToken.find_by_token('<token_string>')
   token.update!(revoked:false)
   ```

   たとえば`token-string-here123`のトークンの取り消しは、次のコマンドで解除できます:

   ```ruby
   token = PersonalAccessToken.find_by_token('token-string-here123')
   token.update!(revoked:false)
   ```

## パーソナルアクセストークンの代替 {#alternatives-to-personal-access-tokens}

HTTPS経由のGitの場合、パーソナルアクセストークンの代替手段として、OAuth認証情報ヘルパーを使用することが可能です。

## 関連トピック {#related-topics}

- [グループアクセストークン](../group/settings/group_access_tokens.md)
- [プロジェクトアクセストークン](../project/settings/project_access_tokens.md)
- [パーソナルアクセストークンAPI](../../api/personal_access_tokens.md)
