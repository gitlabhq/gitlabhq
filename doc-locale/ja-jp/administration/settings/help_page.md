---
stage: None - Facilitated functionality, see https://handbook.gitlab.com/handbook/product/categories/#facilitated-functionality
group: Unassigned - Facilitated functionality, see https://handbook.gitlab.com/handbook/product/categories/#facilitated-functionality
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: ヘルプページのメッセージをカスタマイズします
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

大規模な組織では、誰に連絡を取るべきか、またはどこにヘルプを求めるべきかについての情報があると便利です。この情報は、GitLab `/help`ページでカスタマイズして表示できます。

## ヘルプページにヘルプメッセージを追加します {#add-a-help-message-to-the-help-page}

ヘルプメッセージを追加できます。これは、GitLab `/help`ページの上部に表示されます（例: <https://gitlab.com/help>）:

1. 左側のサイドバーの下部で、**管理者**を選択します。
1. **設定** > **設定**を選択します。
1. **ヘルプページ**を展開します。
1. **ヘルプページに表示する追加テキスト**に、`/help`に表示する情報を入力します。
1. **変更を保存**を選択します。

これで、`/help`にメッセージが表示されます。

{{< alert type="note" >}}

`/help`はデフォルトで認証されていないユーザーに表示されます。ただし、[**公開**表示レベル](visibility_and_access_controls.md#restrict-visibility-levels)が制限されている場合、`/help`は認証されたユーザーにのみ表示されます。

{{< /alert >}}

## サインインページにヘルプメッセージを追加します {#add-a-help-message-to-the-sign-in-page}

{{< history >}}

- サインインページに表示する追加テキストは、GitLab 17.0で[非推奨](https://gitlab.com/gitlab-org/gitlab/-/issues/410885)になりました。

{{< /history >}}

サインインページにヘルプメッセージを追加するには、[サインインページと登録ページをカスタマイズ](../appearance.md#customize-your-sign-in-and-register-pages)します。

## ヘルプページからマーケティング関連エントリを非表示にする {#hide-marketing-related-entries-from-the-help-page}

GitLabのマーケティング関連エントリがヘルプページに表示されることがあります。これらのエントリを非表示にするには、次の手順に従います:

1. 左側のサイドバーの下部で、**管理者**を選択します。
1. **設定** > **設定**を選択します。
1. **ヘルプページ**を展開します。
1. **ヘルプページからマーケティング関連のエントリを非表示にする**チェックボックスを選択します。
1. **変更を保存**を選択します。

## カスタムサポートページURLを設定する {#set-a-custom-support-page-url}

ユーザーが次の操作を行うときにリダイレクトされるカスタムURLを指定できます:

- **ヘルプ** > **サポート**を選択します。
- ヘルプページで**ヘルプが必要な場合はGitLabウェブサイトを参照してください**を選択します。

1. 左側のサイドバーの下部で、**管理者**を選択します。
1. **設定** > **設定**を選択します。
1. **ヘルプページ**を展開します。
1. **サポートページURL**フィールドに、URLを入力します。
1. **変更を保存**を選択します。

## `/help`ページをリダイレクトする {#redirect-help-pages}

すべての`/help`リンクを、[必要な要件](#destination-requirements)を満たす宛先にリダイレクトできます。

1. 左側のサイドバーの下部で、**管理者**を選択します。
1. **設定** > **設定**を選択します。
1. **ヘルプページ**を展開します。
1. **ドキュメントページのURL**フィールドに、URLを入力します。
1. **変更を保存**を選択します。

**ドキュメントページのURL**フィールドが空の場合、GitLabインスタンスには、GitLabの[`doc`ディレクトリ](https://gitlab.com/gitlab-org/gitlab/-/tree/master/doc)からリクエストされたドキュメントの基本バージョンが表示されます。

### リダイレクト先の要件 {#destination-requirements}

`/help`をリダイレクトする場合、GitLab:

- 指定されたURLを、リダイレクトのベースURLとして使用します。
- 次の方法で完全なURLを構築します:
  - バージョン番号（`${VERSION}`）を追加します。
  - ドキュメントパスを追加します。
  - すべての`.md`ファイルGo言語拡張子を削除します。

たとえば、URLが`https://docs.gitlab.com`に設定されている場合、`/help/administration/settings/help_page.md`のリクエストは`https://docs.gitlab.com/${VERSION}/administration/settings/help_page`にリダイレクトされます。
