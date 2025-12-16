---
stage: Plan
group: Knowledge
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitLab Pagesへのアクセス制御
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- SAML SSOのPagesサポートがGitLab 18.2で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/326288)されました。[フラグ](../../../administration/feature_flags/_index.md)の名前は`ff_oauth_redirect_to_sso_login`です。デフォルトでは無効になっています。
- OAuthアプリケーションのSAML SSOのサポートは、GitLab 18.3で[GitLab.com、GitLab Self-Managed、GitLab Dedicatedで有効](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/200682)になりました。
- GitLab 18.5で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/561778)になりました。機能フラグ`ff_oauth_redirect_to_sso_login`は削除されました。

{{< /history >}}

管理者がGitLabインスタンスで[アクセス制御機能を有効にしている](../../../administration/pages/_index.md#access-control)場合、プロジェクトでPagesのアクセス制御を有効にできます。有効にすると、認証された[プロジェクトのメンバー](../../permissions.md#project-members-permissions)（少なくともゲスト）のみが、デフォルトでWebサイトにアクセスできます:

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i>デモンストレーションについては、[Pagesのアクセス制御](https://www.youtube.com/watch?v=tSPAr5mQYc8)を参照してください。

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。[新しいナビゲーションをオンにしている](../../interface_redesign.md#turn-new-navigation-on-or-off)場合、このフィールドは上部のバーにあります。
1. **設定** > **一般**を選択します。
1. **可視性、プロジェクトの機能、権限**を展開します。
1. **Pages**ボタンを切り替えて、アクセス制御を有効にします。切り替えボタンが表示されない場合は、有効になっていないことを意味します。管理者に[有効にする](../../../administration/pages/_index.md#access-control)ように依頼してください。

1. Pagesのアクセス制御ドロップダウンリストを使用すると、プロジェクトの表示レベルに応じて、GitLab Pagesでホストされているページを表示できるユーザーを設定できます:

   - プロジェクトがプライベートの場合:
     - **Only project members**（プロジェクトメンバーのみ）: プロジェクトメンバーのみがWebサイトを閲覧できます。
     - **全員**: GitLabにログインしているかログアウトしているかに関わらず、すべての人がプロジェクトのメンバーシップに関係なくWebサイトを閲覧できます。
   - プロジェクトが内部の場合:
     - **Only project members**（プロジェクトメンバーのみ）: プロジェクトメンバーのみがWebサイトを閲覧できます。
     - **Everyone with access**（アクセスできる人すべて）: GitLabにログインしているすべての人が、プロジェクトのメンバーシップに関係なくWebサイトを閲覧できます。[外部ユーザー](../../../administration/external_users.md)は、プロジェクトのメンバーシップを持っている場合にのみWebサイトにアクセスできます。
     - **全員**: GitLabにログインしているかログアウトしているかに関わらず、すべての人がプロジェクトのメンバーシップに関係なくWebサイトを閲覧できます。
   - プロジェクトがパブリックの場合:
     - **Only project members**（プロジェクトメンバーのみ）: プロジェクトメンバーのみがWebサイトを閲覧できます。
     - **Everyone with access**（アクセスできる人すべて）: GitLabにログインしているかログアウトしているかに関わらず、すべての人がプロジェクトのメンバーシップに関係なくWebサイトを閲覧できます。

1. **変更を保存**を選択します。変更はすぐには有効にならない場合があります。GitLab Pagesは効率性のためにキャッシュ機構を使用します。キャッシュが無効になるまで変更が有効にならない場合があります。通常、1分もかかりません。

次に誰かがWebサイトにアクセスしようとしたときにアクセス制御が有効になっている場合、GitLabにサインインしてWebサイトにアクセスできることを確認するページが表示されます。

関連付けられたグループに対して[SAML SSO](../../group/saml_sso/_index.md)が構成され、アクセス制御が有効になっている場合、ユーザーはWebサイトにアクセスする前にシングルサインオンを使用して認証する必要があります。

## グループPagesのパブリックアクセスを削除 {#remove-public-access-for-group-pages}

{{< history >}}

- GitLab 17.9で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/254962)されました。

{{< /history >}}

グループのPagesのパブリック表示レベルオプションを削除するための設定を構成します。有効にすると、グループとそのサブグループ内のすべてのプロジェクトは、「全員」の表示レベルを使用する機能を失い、プロジェクトの表示レベル設定に応じて、プロジェクトメンバーまたはアクセス権を持つすべてのユーザーに制限されます。

前提要件

- Pagesへのパブリックアクセスは、[インスタンスレベルで失効されていない](../../../administration/pages/_index.md#disable-public-access-to-all-pages-sites)必要があります。
- グループのオーナーロールを持っている必要があります。

これを行うには、次の手順を実行します:

1. 左側のサイドバーで、**検索または移動先**を選択して、グループを見つけます。[新しいナビゲーションをオンにしている](../../interface_redesign.md#turn-new-navigation-on-or-off)場合、このフィールドは上部のバーにあります。
1. **設定** > **一般**を選択します。
1. **権限とグループ機能**を展開します。
1. **Pages public access**（Pagesのパブリックアクセス）で、**パブリックアクセスの削除**チェックボックスをオンにします。
1. **変更を保存**を選択します。

GitLab Pagesは効率性のためにキャッシュを使用します。アクセス制御設定への変更は通常、キャッシュが更新されると1分以内に有効になります。

## アクセストークンで認証 {#authenticate-with-an-access-token}

{{< history >}}

- GitLab 17.10で[導入](https://gitlab.com/gitlab-org/gitlab-pages/-/issues/388)されました。

{{< /history >}}

制限されたGitLab Pagesサイトに対して認証するには、`Authorization`ヘッダーにアクセストークンを指定します。

前提要件: 

- `read_api`スコープを持つ次のアクセストークンのいずれかが必要です:
  - [パーソナルアクセストークン](../../profile/personal_access_tokens.md#create-a-personal-access-token)
  - [プロジェクトアクセストークン](../settings/project_access_tokens.md#create-a-project-access-token)
  - [グループアクセストークン](../../group/settings/group_access_tokens.md#create-a-group-access-token)
  - [OAuth 2.0トークン](../../../api/oauth2.md)

たとえば、OAuth準拠のヘッダーでアクセストークンを使用するには、次のようにします:

```shell
curl --header "Authorization: Bearer <your_access_token>" <published_pages_url>
```

無効または認証されていないアクセストークンの場合、[`404`](../../../api/rest/troubleshooting.md#status-codes)が返されます。

## Pagesセッションの終了 {#terminating-a-pages-session}

GitLab Pages Webサイトからサインアウトするには、GitLab Pagesのアプリケーションアクセストークンを失効します:

1. 左側のサイドバーで、自分のアバターを選択します。[新しいナビゲーションをオンにしている](../../interface_redesign.md#turn-new-navigation-on-or-off)場合、このボタンは右上隅にあります。
1. **プロファイルの編集**を選択します。
1. **アプリケーション**を選択します。
1. **許可したアプリケーション**セクションで、**GitLab Pages**エントリを見つけて、**取り消し**を選択します。
