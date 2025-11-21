---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: ユーザーファイルのアップロード
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

ユーザーは、次の場所にアップロードできます:

- プロジェクトのイシューまたはマージリクエスト。
- グループのエピック。

GitLabは、認証されていないユーザーがURLを推測できないように、これらのアップロードされたファイルに対して、ランダムな32文字のIDを持つダイレクトURLを生成します。このランダム化により、機密情報を含むファイルに対してある程度のセキュリティが提供されます。

ユーザーがGitLabイシュー、マージリクエスト、およびエピックにアップロードしたファイルには、URLパスに`/uploads/<32-character-id>`が含まれています。

{{< alert type="warning" >}}

不明または信頼できないソースからアップロードされたファイルをダウンロードする際は、特にそのファイルが実行可能ファイルまたはスクリプトである場合は、注意してください。

{{< /alert >}}

## アップロードされたファイルのアクセス制御 {#access-control-for-uploaded-files}

{{< history >}}

- 認可チェックの強制は、GitLab 15.3で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/352291)になりました。機能フラグ`enforce_auth_checks_on_uploads`は削除されました。
- ユーザーインターフェースのプロジェクト設定は、GitLab 15.3で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/88567)されました。

{{< /history >}}

以下にアップロードされた画像以外のファイルへのアクセス制御:

- イシューまたはマージリクエストは、プロジェクトの表示レベルによって決定されます。
- グループエピックは、グループの表示レベルによって決定されます。

パブリックプロジェクトまたはグループの場合、イシュー、マージリクエスト、またはエピックが機密情報であっても、誰でもダイレクトアタッチメントURLからこれらのファイルにアクセスできます。プライベートプロジェクトと内部プロジェクトの場合、GitLabは、認証されたプロジェクトメンバーのみが、PDFなどの画像以外のファイルアップロードにアクセスできることを保証します。デフォルトでは、画像ファイルには同じ制限はなく、誰でもURLを使用して表示できます。画像ファイルを保護するには、[すべてのメディアファイルの認可チェックを有効にする](#enable-authorization-checks-for-all-media-files)と、認証されたユーザーのみが表示できるようになります。

画像の認証チェックにより、通知メールの本文に表示の問題が発生する可能性があります。メールは、GitLabで認証されていないクライアント（Outlook、Apple Mail、またはモバイルデバイスなど）から頻繁に読まれます。クライアントがGitLabに対して認可されていない場合、メール内の画像は壊れて表示されず、利用できません。

## すべてのメディアファイルの認可チェックを有効にする {#enable-authorization-checks-for-all-media-files}

認証されたプロジェクトメンバーのみが、プライベートプロジェクトおよび内部プロジェクトで画像以外の添付ファイル（PDFを含む）を表示できます。

プライベートまたは内部プロジェクトの画像ファイルに認証要件を適用するには:

前提要件: 

- プロジェクトのメンテナーロールまたはオーナーロールを持っている必要があります。
- プロジェクトの表示レベルの設定は、**プライベート**または**内部**である必要があります。

すべてのメディアファイルの認証設定を構成するには:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **設定** > **一般**を選択します。
1. **可視性、プロジェクトの機能、権限**を展開します。
1. **プロジェクトの表示レベル**までスクロールし、**メディアファイルを表示するには認証が必要**を選択します。

{{< alert type="note" >}}

パブリックプロジェクトでは、このオプションを選択できません。

{{< /alert >}}

## アップロードされたファイルを削除 {#delete-uploaded-files}

{{< history >}}

- GitLab 15.3で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/92791)されました。
- REST APIは、GitLab 17.2でサポートが[追加](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/157066)されました。

{{< /history >}}

そのファイルに機密情報が含まれている場合は、アップロードされたファイルを削除する必要があります。そのファイルを削除すると、ユーザーはそのファイルにアクセスできなくなり、ダイレクトURLは404エラーを返します。

プロジェクトオーナーとメンテナーは、[インタラクティブGraphQLエクスプローラー](../api/graphql/_index.md#interactive-graphql-explorer)を使用して、[GraphQLエンドポイント](../api/graphql/reference/_index.md#mutationuploaddelete)にアクセスし、アップロードされたファイルを削除できます。

例: 

```graphql
mutation{
  uploadDelete(input: { projectPath: "<path/to/project>", secret: "<32-character-id>" , filename: "<filename>" }) {
    upload {
      id
      size
      path
    }
    errors
  }
}
```

オーナーまたはメンテナーロールを持たないプロジェクトメンバーは、このGraphQLエンドポイントにアクセスできません。

アップロードされたファイルを削除するには、[プロジェクト](../api/project_markdown_uploads.md#delete-an-uploaded-file-by-secret-and-filename)または[グループ](../api/group_markdown_uploads.md#delete-an-uploaded-file-by-secret-and-filename)のREST APIを使用することもできます。
