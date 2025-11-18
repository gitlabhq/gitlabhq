---
stage: Create
group: Code Review
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: マージリクエストでコードの改善を提案し、ブラウザから直接、マージリクエストにそれらの改善をコミットします。
title: 変更を提案する
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

レビュアーは、マージリクエストの差分スレッドでMarkdown構文を使用してコードの変更を提案できます。マージリクエストの作成者（または適切なロールを持つ他のユーザー）は、GitLab UIから提案のすべてまたは一部を適用できます。提案を適用すると、変更を提案したユーザーが作成したコミットがマージリクエストに追加されます。

## 提案を作成する {#create-suggestions}

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **コード** > **マージリクエスト**を選択し、マージリクエストを見つけます。
1. セカンダリメニューで、**変更**を選択します。
1. 変更したいコードの行を見つけます。
   - 1行を選択するには、行番号にカーソルを合わせ、**この行にコメントを追加**（{{< icon name="comment" >}}）を選択します。
   - 複数行を選択するには、次の手順に従います:
     1. 行番号にカーソルを合わせ、**この行にコメントを追加**（{{< icon name="comment" >}}）を選択します: ![差分ファイルの任意の行にコメントします。](img/comment_on_any_diff_line_v16_6.png)
     1. 選択してドラッグし、目的のすべての行を含めます。詳細については、[複数行を提案する](#multi-line-suggestions)を参照してください。
   - 特定ラインではなくファイル全体にコメントするには、ファイルのヘッダーで、**このファイルにコメントする** ({{< icon name="comment" >}}) を選択します。
1. コメントツールバーで、**候補を挿入する**（{{< icon name="doc-code" >}}）を選択します。GitLabは、次のように、自動入力されたコードブロックをコメントに挿入します:

   ````markdown
   ```suggestion:-0+0
   The content of the line you selected is shown here.
   ```
   ````

1. 自動入力されたコードブロックを編集して、提案を追加します。
1. コメントをすぐに送信するには、**今すぐコメントを追加**を選択するか、キーボードショートカットを使用します:
   - macOS: <kbd>Shift</kbd> + <kbd>Command</kbd> + <kbd>Enter</kbd>
   - その他すべてのOS: <kbd>Shift</kbd> + <kbd>Control</kbd> + <kbd>Enter</kbd>
1. [レビュー](_index.md)を完了するまでコメントを公開しないようにするには、**レビューを開始**を選択するか、キーボードショートカットを使用します:
   - macOS: <kbd>Command</kbd> + <kbd>Enter</kbd>
   - その他すべてのOS: <kbd>Control</kbd> + <kbd>Enter</kbd>

### 複数行の提案 {#multi-line-suggestions}

{{< history >}}

- 複数行の提案は、提案にコードブロックが含まれている場合にレンダリングをサポートするために、GitLab 17.7で[変更](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/172981/)されました。

{{< /history >}}

マージリクエストの差分をレビューするときに、次のいずれかの方法で、1つの提案で複数の行（最大200行）への変更を提案できます:

- [提案を作成する](#create-suggestions)で説明されている方法で、選択してドラッグします。GitLabが、提案ブロックを作成します。
- 1行を選択し、提案ブロックで範囲オフセットを手動で編集します。

提案の最初の行の範囲オフセットは、選択した行に対する行番号を示します。オフセットは、提案が置き換える行を指定します。たとえば、この提案は、コメント行の上下2行をカバーしています:

````markdown
```suggestion:-2+2
## Prevent approval by author

By default, the author of a merge request cannot approve it. To change this setting:
```
````

適用すると、提案はコメント行の上下2行を置き換えます:

![複数行の提案をプレビューする](img/multi-line-suggestion-preview_v16_6.png)

GitLabでは、複数行の提案は、コメントされた差分行の上100行と下100行に制限されています。これにより、提案ごとに最大201行の変更が可能になります。

複数行のコメントには、コメントの本文の上にコメントの行番号が表示されます:

![コメントの上に表示される複数行のコメントの選択範囲](img/multiline-comment-saved_v17_5.png)

#### リッチテキストエディタを使用する {#using-the-rich-text-editor}

{{< history >}}

- GitLab 16.1で`content_editor_on_issues`[フラグ](../../../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/388449)されました。デフォルトでは無効になっています。
- GitLab 16.2の[GitLab.comおよびGitLab Self-Managedで有効化](https://gitlab.com/gitlab-org/gitlab/-/issues/375172)されました。
- 機能フラグ`content_editor_on_issues`は、GitLab 16.5で削除されました。

{{< /history >}}

提案を挿入するときは、WYSIWYG[リッチテキストエディタ](../../../rich_text_editor.md)を使用して、UIでソースファイルの行番号を上下に移動します。

変更された行を追加または削除するには、**From line**（開始行）の横にある**+**（+）または**-**（-）を選択します。

![複数行の提案をプレビューする](img/suggest_changes_v16_2.png)

## 提案を適用する {#apply-suggestions}

前提要件:

- マージリクエストの作成者であるか、プロジェクトのデベロッパー以上のロールを持っている必要があります。

マージリクエストから提案された変更を直接適用するには、次の手順に従います:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **コード** > **マージリクエスト**を選択し、マージリクエストを見つけます。
1. 適用する提案を含むコメントを見つけます。
   - 提案を個別に適用するには、**提案を適用**を選択します。
   - 単一のコミットで複数の提案を適用するには、**提案をバッチに追加**を選択します。
1. オプション。変更を説明するためのカスタムコミットメッセージを入力します。カスタムメッセージを入力しない場合は、デフォルトのコミットメッセージが使用されます。
1. **適用**を選択します。

提案を適用すると、GitLabは次のようになります:

- 提案を**適用済み**としてマークします。
- コメントスレッドを解決します。
- 変更を含む新しいコミットを作成します。
- （ユーザーがデベロッパーロールを持っている場合）提案された変更をマージリクエストのブランチ内のコードベースに直接プッシュします。

## 適用された提案のコミットメッセージを設定する {#configure-the-commit-message-for-applied-suggestions}

GitLabは、提案を適用するときにデフォルトのコミットメッセージを使用しますが、これは変更可能です。このメッセージはプレースホルダーをサポートしています。たとえば、デフォルトのメッセージ`Apply %{suggestions_count} suggestion(s) to %{files_count} file(s)`は、2つの異なるファイルに3つの提案を適用すると、次のようになります:

```plaintext
Apply 3 suggestion(s) to 2 file(s)
```

フォークから作成されたマージリクエストは、ターゲットプロジェクトで定義されたテンプレートを使用します。プロジェクトのニーズに合わせて、これらのメッセージをカスタマイズし、他のプレースホルダー変数を含めます。

前提要件:

- メンテナーのロールを持っている必要があります。

これを行うには、次の手順に従います:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **設定** > **マージリクエスト**を選択します。
1. **マージ提案**までスクロールし、ニーズに合わせてテキストを変更します。このメッセージで使用できるプレースホルダーの一覧については、[サポートされている変数](#supported-variables)を参照してください。

### サポートされている変数 {#supported-variables}

適用された提案のコミットメッセージのテンプレートは、次の変数をサポートしています:

| 変数               | 説明 | 出力例 |
|------------------------|-------------|----------------|
| `%{branch_name}`       | 提案が適用されたブランチの名前。 | `my-feature-branch` |
| `%{files_count}`       | 提案が適用されたファイルの数。| `2` |
| `%{file_paths}`        | 提案が適用されたファイルのパス。パスはカンマで区切られます。| `docs/index.md, docs/about.md` |
| `%{project_path}`      | プロジェクトパス。 | `my-group/my-project` |
| `%{project_name}`      | 人間が判別できるプロジェクト名。 | `My Project` |
| `%{suggestions_count}` | 適用された提案の数。| `3` |
| `%{username}`          | 提案を適用しているユーザーのユーザー名。 | `user_1` |
| `%{user_full_name}`    | 提案を適用しているユーザーの氏名。 | `User 1` |
| `%{co_authored_by}`    | `Co-authored-by`Gitコミットトレーラー形式の提案作成者の名前とメール。 | `Co-authored-by: Zane Doe <zdoe@example.com>`<br> `Co-authored-by: Blake Smith <bsmith@example.com>` |

たとえば、コミットメッセージをカスタマイズして`Addresses user_1's review`を出力するには、カスタムテキストを`Addresses %{username}'s review`に設定します。

## バッチ提案 {#batch-suggestions}

前提要件:

- ソースブランチへのコミットを許可するプロジェクトのロールを持っている必要があります。

ブランチに追加されるコミットの数を減らすには、単一のコミットで複数の提案を適用します。

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **コード** > **マージリクエスト**を選択し、マージリクエストを見つけます。
1. 適用する提案ごとに、**提案をバッチに追加**を選択します。
1. オプション。提案を削除するには、**バッチから削除**を選択します。
1. 目的の提案を追加したら、**Apply suggestions**（提案を適用）を選択します。

   {{< alert type="warning" >}}

   複数の作成者からの変更を含む提案のバッチを適用すると、結果のコミットにより、作成者としてクレジットされます。[コミットを追加するユーザーからの承認を防止する](../approvals/settings.md#prevent-approvals-by-users-who-add-commits)ようにプロジェクトを設定すると、このマージリクエストの適格な承認者ではなくなります。

   {{< /alert >}}

1. オプション。変更を説明するために、[バッチ提案](#batch-suggestions)のカスタムコミットメッセージを入力します。指定しない場合は、デフォルトのコミットメッセージが使用されます。

## 関連トピック {#related-topics}

- [提案API](../../../../api/suggestions.md)
