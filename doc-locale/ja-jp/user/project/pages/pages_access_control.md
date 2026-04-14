---
stage: Plan
group: Knowledge
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: GitLab Pagesアクセス制御
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- グループのSAML SSOによるPagesサポートは、GitLab 18.2で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/326288)され、`ff_oauth_redirect_to_sso_login`という名前の[フラグ](../../../administration/feature_flags/_index.md)が付けられました。デフォルトでは無効になっています。
- OAuthアプリケーションのSAML SSOのサポートは、GitLab 18.3で[GitLab.com、GitLab Self-Managed、GitLab Dedicatedで有効](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/200682)になりました。
- GitLab 18.5で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/561778)になりました。機能フラグ`ff_oauth_redirect_to_sso_login`は削除されました。

{{< /history >}}

管理者がGitLabのインスタンスで[アクセス制御機能を有効にしている](../../../administration/pages/_index.md#access-control)場合、プロジェクトでPagesのアクセス制御を有効にできます。有効にすると、デフォルトでは、[プロジェクトのメンバー](../../permissions.md#project-permissions)のうちゲストロール以上の認証されたユーザーのみがウェブサイトにアクセスできます:

<i class="fa-youtube-play" aria-hidden="true"></i>デモンストレーションについては、[Pagesアクセス制御](https://www.youtube.com/watch?v=tSPAr5mQYc8)を参照してください。

1. 上部のバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **設定** > **一般**を選択します。
1. **可視性、プロジェクトの機能、権限**を展開します。
1. アクセス制御を有効にするには、**Pages**を切替えます。切替ボタンが表示されない場合、それは有効になっていません。管理者に[有効に](../../../administration/pages/_index.md#access-control)するよう依頼してください。

1. プロジェクトの表示レベルに応じて、GitLab Pagesでホストされているページを誰が閲覧できるかを、Pagesアクセス制御ドロップダウンリストで設定できます:

   - プロジェクトがプライベートの場合:
     - **プロジェクトメンバーのみ**: [プロジェクトメンバー](../members/_index.md)のみがウェブサイトを閲覧できます。
     - **全員**: GitLabにログインしているかログアウトしているかにかかわらず、プロジェクトメンバーシップに関係なく、全員がウェブサイトを閲覧できます。
   - プロジェクトが内部の場合:
     - **プロジェクトメンバーのみ**: プロジェクトメンバーのみがウェブサイトを閲覧できます。
     - **Everyone with access**: GitLabにログインしている全員が、プロジェクトメンバーシップに関係なく、ウェブサイトを閲覧できます。[外部ユーザー](../../../administration/external_users.md)は、プロジェクトにメンバーシップがある場合にのみウェブサイトにアクセスできます。
     - **全員**: GitLabにログインしているかログアウトしているかにかかわらず、プロジェクトメンバーシップに関係なく、全員がウェブサイトを閲覧できます。
   - プロジェクトが公開の場合:
     - **プロジェクトメンバーのみ**: プロジェクトメンバーのみがウェブサイトを閲覧できます。
     - **Everyone with access**: GitLabにログインしているかログアウトしているかにかかわらず、プロジェクトメンバーシップに関係なく、全員がウェブサイトを閲覧できます。

1. **変更を保存**を選択します。変更はすぐに反映されない場合があります。GitLab Pagesは効率性のためにキャッシュメカニズムを使用します。そのキャッシュが無効になるまで変更は反映されない場合があります。これは通常1分未満で完了します。

次回、誰かがウェブサイトにアクセスしようとしてアクセス制御が有効になっている場合、GitLabにサインインしてウェブサイトにアクセスできることを確認するためのページが表示されます。

関連グループに[SAML SSO](../../group/saml_sso/_index.md)が設定され、アクセス制御が有効になっている場合、ユーザーはウェブサイトにアクセスする前にSSOを使用して認証する必要があります。

[インスタンス](../../../administration/pages/_index.md#disable-public-access-to-all-pages-sites)または[グループ](#remove-public-access-for-group-pages)レベルでパブリックアクセスが無効になっている場合、プロジェクトは**全員**表示レベルオプションを失い、プロジェクトの表示レベル設定に応じて、プロジェクトメンバーまたはアクセス権を持つすべてのユーザーに制限されます。

## グループPagesのパブリックアクセスを削除 {#remove-public-access-for-group-pages}

{{< history >}}

- GitLab 17.9で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/254962)されました。

{{< /history >}}

Pagesのパブリック表示レベルオプションを削除するようにグループの設定を構成します。有効にすると、グループおよびそのサブグループ内のすべてのプロジェクトは、「全員」表示レベルを使用するオプションを失い、プロジェクトの表示レベル設定に応じて、プロジェクトメンバーまたはアクセス権を持つすべてのユーザーに制限されます。

前提条件

- Pagesへのパブリックアクセスは、[インスタンス](../../../administration/pages/_index.md#disable-public-access-to-all-pages-sites)で無効にされていない必要があります。
- グループのオーナーのロールを持っている必要があります。

これを行うには、次の手順を実行します:

1. 上部のバーで、**検索または移動先**を選択して、グループを見つけます。
1. **設定** > **一般**を選択します。
1. **権限とグループ機能**を展開します。
1. **GitLab Pagesのパブリックアクセス**の下で、**パブリックアクセスの削除**チェックボックスをオンにします。
1. **変更を保存**を選択します。

GitLab Pagesは効率性のためにキャッシュを使用します。アクセス設定の変更は、キャッシュが更新されると通常1分で反映されます。

## アクセストークンで認証する {#authenticate-with-an-access-token}

{{< history >}}

- GitLab 17.10で[導入](https://gitlab.com/gitlab-org/gitlab-pages/-/issues/388)されました。

{{< /history >}}

制限されたGitLab Pagesサイトに対して認証するには、`Authorization`ヘッダーにアクセストークンを指定できます。

前提条件: 

- `read_api`スコープを持つ以下のいずれかのアクセストークンが必要です:
  - [パーソナルアクセストークン](../../profile/personal_access_tokens.md#create-a-personal-access-token)
  - [プロジェクトアクセストークン](../settings/project_access_tokens.md#create-a-project-access-token)
  - [グループアクセストークン](../../group/settings/group_access_tokens.md#create-a-group-access-token)
  - [OAuth 2.0トークン](../../../api/oauth2.md)

例えば、OAuth準拠のヘッダーを持つアクセストークンを使用するには:

```shell
curl --header "Authorization: Bearer <your_access_token>" <published_pages_url>
```

無効または不正なアクセストークンの場合、[`404`](../../../api/rest/troubleshooting.md#status-codes)を返します。

## Pagesセッションの終了 {#terminating-a-pages-session}

GitLab Pagesウェブサイトからサインアウトするには、GitLab Pagesのアプリケーションアクセストークンを失効します:

1. 右上隅で、アバターを選択します。
1. **プロファイルを編集**を選択します。
1. 左サイドバーで、**アクセス** > **アプリケーション**を選択します。
1. **許可したアプリケーション**セクションで、**GitLab Pages**のエントリを見つけて、**取り消し**を選択します。
