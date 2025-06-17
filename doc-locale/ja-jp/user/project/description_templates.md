---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: 説明テンプレート
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供:GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 17.10で[作業アイテムのサポート](https://gitlab.com/gitlab-org/gitlab/-/issues/512208)が導入されました。

{{< /history >}}

説明テンプレートは、GitLabでのイシューとマージリクエストの作成方法を標準化し、自動化します。

説明テンプレートとは

- プロジェクト全体のイシューとマージリクエストで、一貫性のあるレイアウトを作成します。
- さまざまなワークフローの段階と目的に合わせて、専用のテンプレートを提供します。
- プロジェクト、グループ、インスタンス全体のカスタムテンプレートをサポートします。
- 変数とクイックアクションを使用して、自動的にフィールドに入力します。
- バグ、機能、その他の作業アイテムが適切に追跡されるようにします。
- [サービスデスクのメールの応答](service_desk/configure.md#use-a-custom-template-for-service-desk-tickets)をフォーマットします。

以下の説明として使用するテンプレートを定義できます。

- [イシュー](issues/_index.md)
- [エピック](../group/epics/epic_work_items.md)
- [タスク](../tasks.md)
- [マージリクエスト](merge_requests/_index.md)

プロジェクトは、グループとインスタンスからテンプレートを継承します。

テンプレートは次の条件を満たしている必要があります。

- `.md`拡張子で保存されている。
- `.gitlab/issue_templates`ディレクトリまたは`.gitlab/merge_request_templates`ディレクトリのプロジェクトのリポジトリに保存されている。
- デフォルトブランチに存在する。

## イシューテンプレートを作成する

リポジトリの`.gitlab/issue_templates/`ディレクトリ内に、新しいMarkdown（`.md`）ファイルを作成します。

{{< alert type="note" >}}

イシューテンプレートは、イシュー、エピック、タスク、目標、OKR（Objective and Key Results）を含む、すべてのタイプの作業アイテムでサポートされています。

{{< /alert >}}

イシューの説明テンプレートを作成するには、以下を実行します。

1. 左側のサイドバーで、**検索または移動**を選択して、プロジェクトを検索します。
1. **コード > リポジトリ**を選択します。
1. デフォルトブランチの横にある{{< icon name="plus" >}}を選択します。
1. **新しいファイル**を選択します。
1. デフォルトブランチの横にある**ファイル名**テキストボックスに、`.gitlab/issue_templates/mytemplate.md`と入力します。`mytemplate`はイシューテンプレートの名前です。
1. デフォルトブランチをコミットします。

この操作が正しく機能しているかどうかを確認するには、[新しいイシューを作成](issues/create_issues.md)し、**テンプレートを選択**ドロップダウンリストに説明テンプレートがあることを確認します。

## マージリクエストテンプレートを作成する

イシューテンプレートと同様に、リポジトリの`.gitlab/merge_request_templates/`ディレクトリ内に新しいMarkdown（`.md`）ファイルを作成します。イシューテンプレートと違い、マージリクエストには、コミットメッセージとブランチ名の内容に応じた[追加の継承ルール](merge_requests/creating_merge_requests.md)があります。

プロジェクトのマージリクエスト説明テンプレートを作成するには、以下を実行します。

1. 左側のサイドバーで、**検索または移動**を選択して、プロジェクトを検索します。
1. **コード > リポジトリ**を選択します。
1. デフォルトブランチの横にある{{< icon name="plus" >}}を選択します。
1. **新しいファイル**を選択します。
1. デフォルトブランチの横にある**ファイル名**テキストボックスに、`.gitlab/merge_request_templates/mytemplate.md`と入力します。`mytemplate`はマージリクエストテンプレートの名前です。
1. デフォルトブランチをコミットします。

この操作が正しく機能しているかどうかを確認するには、[新しいマージリクエストを作成](merge_requests/creating_merge_requests.md)し、**テンプレートを選択**ドロップダウンリストに説明テンプレートがあることを確認します。

## テンプレートを使用する

イシューやマージリクエストを作成または編集すると、**テンプレートを選択**ドロップダウンリストに表示されます。

テンプレートを適用するには、以下を実行します。

1. イシュー、作業アイテム、マージリクエストを作成または編集します。
1. **テンプレートを選択**ドロップダウンリストを選択します。
1. **説明**テキストボックスが空白でない場合は**テンプレートの適用**を選択して確認します。
1. **変更を保存**を選択します。

説明テンプレートを選択すると、その内容が説明テキストボックスにコピーされます。

テンプレートを選択した後に説明に加えた変更を破棄するには、**テンプレートを選択**ドロップダウンリストを展開し、**テンプレートをリセット**を選択します。

![イシューで説明テンプレートを選択する](img/description_templates_v17_10.png)

{{< alert type="note" >}}

ショートカットリンクを作成し、指定されたテンプレートを使用してイシューを作成することができます。例: `https://gitlab.com/gitlab-org/gitlab/-/issues/new?issuable_template=Feature%20proposal`。詳細については、[値を事前に入力したURLを使用してイシューを作成する](issues/create_issues.md#using-a-url-with-prefilled-values)をお読みください。

{{< /alert >}}

### マージリクエストテンプレートでサポートされている変数

{{< history >}}

- GitLab 15.7で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/89810)されました。

{{< /history >}}

{{< alert type="note" >}}

この機能は、[デフォルトテンプレート](#set-a-default-template-for-merge-requests-and-issues)でのみ使用できます。

{{< /alert >}}

マージリクエストを初めて保存したとき、GitLabはマージリクエストテンプレート内のこれらの変数を次の値に置き換えます。

| 変数 | 説明 | 出力例 |
|----------|-------------|----------------|
| `%{all_commits}` | マージリクエスト内のすべてのコミットからのメッセージ。最新の100件のコミットに制限されます。100 KiBを超えるコミット本文とマージコミットメッセージはスキップします。 | `* Feature introduced`<br><br> `This commit implements feature`<br> `Changelog:added`<br><br> `* Bug fixed`<br><br> `* Documentation improved`<br><br>`This commit introduced better docs.` |
| `%{co_authored_by}` | `Co-authored-by`Gitコミットトレーラー形式のコミット作成者の名前とメールアドレス。マージリクエスト内の最新の100件のコミットの作成者に制限されます。 | `Co-authored-by: Zane Doe <zdoe@example.com>`<br> `Co-authored-by: Blake Smith <bsmith@example.com>` |
| `%{first_commit}` | マージリクエストの差分の最初のコミットの完全なメッセージ。 | `Update README.md` |
| `%{first_multiline_commit}` | マージコミットではなく、メッセージ本文に複数の行が含まれる最初のコミットの完全なメッセージ。すべてのコミットに複数の行が含まれていない場合は、マージリクエストのタイトル。 | `Update README.md`<br><br> `Improved project description in readme file.` |
| `%{source_branch}` | マージされるブランチの名前。 | `my-feature-branch`  |
| `%{target_branch}` | 変更が適用されるブランチの名前。 | `main` |

### インスタンスレベルの説明テンプレートを設定する

{{< details >}}

- プラン: Premium、Ultimate
- 提供:GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

**インスタンスレベル**で説明テンプレートを設定するには、[インスタンステンプレートリポジトリ](../../administration/settings/instance_template_repository.md)を使用します。インスタンステンプレートリポジトリは、ファイルテンプレートにも使用できます。

インスタンスで新しいプロジェクトを作成するときに使用できる[プロジェクトテンプレート](../../administration/custom_project_templates.md)もあわせてご覧ください。

### グループレベルの説明テンプレートを設定する

{{< details >}}

- プラン: Premium、Ultimate
- 提供: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

**グループレベル**の説明テンプレートを使用すると、グループ内のプロジェクトを選択してテンプレートを保存できます。その後、グループ内の他のプロジェクトでこれらのテンプレートにアクセスできます。これにより、グループのすべてのプロジェクトのイシューとマージリクエストで同じテンプレートを使用することができます。

前提要件:

- グループのオーナーロールを持っている必要があります。
- プロジェクトは、グループの直接の子である必要があります。

[作成した](description_templates.md#create-an-issue-template)テンプレートを再利用するには、以下を実行します。

1. 左側のサイドバーで、**検索または移動**を選択して、グループを検索します。
1. **設定 > 一般**を選択します。
1. **テンプレート**を展開します。
1. ドロップダウンリストから、テンプレートプロジェクトをグループレベルのテンプレートリポジトリとして選択します。
1. **変更を保存**を選択します。

![グループテンプレートを設定する](../group/img/group_file_template_settings_v11_5.png)

[グループ内のさまざまなファイルタイプ](../group/manage.md#group-file-templates)のテンプレートもあわせてご覧ください。

### マージリクエストとイシューのデフォルトテンプレートを設定する

プロジェクトで、新しいイシューとマージリクエストのデフォルトの説明テンプレートを選択することができます。これにより、新しいマージリクエストまたはイシューが作成されるたびに、テンプレートに入力したテキストが事前に入力されます。

前提要件:

- プロジェクトの左側のサイドバーで、**設定 > 一般**を選択し、**可視性、プロジェクトの機能、権限**を展開します。イシューまたはマージリクエストが、**アクセスできる人すべて**または**プロジェクトメンバーのみ**に設定されていることを確認します。

マージリクエストのデフォルトの説明テンプレートを設定するには、以下のいずれかの操作を行います。

- `Default.md`（大文字と小文字を区別しない）という名前の[マージリクエストテンプレートを作成](#create-a-merge-request-template)し、`.gitlab/merge_request_templates/`に保存します。プロジェクト設定でデフォルトのテンプレートが設定されている場合、これによってデフォルトテンプレートが[上書きされることはありません](#priority-of-default-description-templates)。
- GitLab PremiumおよびUltimateのユーザー: プロジェクト設定で、デフォルトのテンプレートを設定します。

  1. 左側のサイドバーで、**検索または移動**を選択して、プロジェクトを検索します。
  1. **設定 > マージリクエスト**を選択します。
  1. **マージリクエストのデフォルトの説明テンプレート**セクションで、テキストエリアに入力します。
  1. **変更を保存**を選択します。

イシューのデフォルトの説明テンプレートを設定するには、次のいずれかの操作を行います。

- `Default.md`（大文字と小文字を区別しない）という名前の[イシューテンプレートを作成](#create-an-issue-template)し、`.gitlab/issue_templates/`に保存します。プロジェクト設定でデフォルトのテンプレートが設定されている場合、これによってデフォルトテンプレートが[上書きされることはありません](#priority-of-default-description-templates)。
- GitLab PremiumおよびUltimateのユーザー: プロジェクト設定で、デフォルトのテンプレートを設定します。

  1. 左側のサイドバーで、**検索または移動**を選択して、プロジェクトを検索します。
  1. **設定 > 一般**を選択します。
  1. **イシューのデフォルトの説明テンプレート**を展開します。
  1. テキストエリアに入力します。
  1. **変更を保存**を選択します。

GitLabのマージリクエストとイシューは[Markdown](../markdown.md)をサポートしており、これを使用して見出しやリストなどをフォーマットできます。

また、[Projects REST API](../../api/projects.md)で`issues_template`属性と`merge_requests_template`属性を指定し、デフォルトのイシューテンプレートとマージリクエストテンプレートを最新の状態に保つこともできます。

#### デフォルトの説明テンプレートの優先順位

さまざまな場所で[イシューの説明テンプレート](#set-a-default-template-for-merge-requests-and-issues)を設定した場合、プロジェクトでの優先順位は次のようになります。上位のものは下位のものを上書きします。

1. プロジェクトの設定で設定されたテンプレート。
1. 親グループからの`Default.md`（大文字と小文字を区別しません）。
1. プロジェクトリポジトリからの`Default.md`（大文字と小文字を区別しません）。

マージリクエストには、コミットメッセージとブランチ名の内容に応じた[追加の継承ルール](merge_requests/creating_merge_requests.md)があります。

## 説明テンプレートの例

説明テンプレートの例については、GitLabプロジェクトの[`.gitlab`フォルダー](https://gitlab.com/gitlab-org/gitlab/-/tree/master/.gitlab)にある、「イシューとマージリクエストの説明テンプレート」を参照してください。

{{< alert type="note" >}}

説明テンプレートで[クイックアクション](quick_actions.md)を使用して、ラベル、担当者、マイルストーンをすばやく追加することができます。クイックアクションは、イシューやマージリクエストを送信するユーザーが、関連するアクションを実行するための権限を持っている場合にのみ実行されます。

{{< /alert >}}

以下は、バグレポートテンプレートの例です。

```markdown
## Summary

(Summarize the bug encountered concisely)

## Steps to reproduce

(How one can reproduce the issue - this is very important)

## Example Project

(If possible, create an example project here on GitLab.com that exhibits the problematic
behavior, and link to it here in the bug report.
If you are using an older version of GitLab, this will also determine whether the bug has been fixed
in a more recent version)

## What is the current bug behavior?

(What actually happens)

## What is the expected correct behavior?

(What you should see instead)

## Relevant logs and/or screenshots

(Paste any relevant logs - use code blocks (```) to format console output, logs, and code, as
it's very hard to read otherwise.)

## Possible fixes

(If you can, link to the line of code that might be responsible for the problem)

/label ~bug ~reproduced ~needs-investigation
/cc @project-manager
/assign @qa-tester
```
