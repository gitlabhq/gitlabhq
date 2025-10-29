---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: 説明テンプレート
description: イシューテンプレート、マージリクエストテンプレート、インスタンステンプレート、グループテンプレート。
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- [作業アイテムのサポート](https://gitlab.com/gitlab-org/gitlab/-/issues/512208)はGitLab 17.10で導入されました。
- エピックのサポートはGitLab 17.10で[導入](https://gitlab.com/groups/gitlab-org/-/epics/16088)され、[フラグ](../../administration/feature_flags/_index.md) `work_item_epics`が付いています。デフォルトでは有効になっています。[ベータ](../../policy/development_stages_support.md#beta)として導入されました。
- エピックのサポートはGitLab 18.1で[一般的に利用可能](https://gitlab.com/gitlab-org/gitlab/-/issues/468310)です。機能フラグ`work_item_epics`は削除されました。

{{< /history >}}

説明テンプレートは、GitLabでのイシューとマージリクエストの作成方法を標準化および自動化します。

説明テンプレートとは:

- プロジェクト全体のイシューとマージリクエストで、一貫性のあるレイアウトを作成します。
- さまざまなワークフローの段階と目的に合わせて、専用のテンプレートを提供します。
- プロジェクト、グループ、インスタンス全体のカスタムテンプレートをサポートします。
- 変数とクイックアクションを使用して、自動的にフィールドに入力します。
- バグ、機能、その他の作業アイテムが適切に追跡されるようにします。
- [サービスデスクのメール応答](service_desk/configure.md#use-a-custom-template-for-service-desk-tickets)をフォーマットします。

以下の説明として使用するテンプレートを定義できます:

- [イシュー](issues/_index.md)
- [エピック](../group/epics/_index.md) ( [グループレベルの説明テンプレート](#set-group-level-description-templates)が必要)
- [タスク](../tasks.md)
- [目標と主な成果](../okrs.md)
- [インシデント](../../operations/incident_management/manage_incidents.md)
- [サービスデスクチケット](service_desk/_index.md)
- [マージリクエスト](merge_requests/_index.md)

プロジェクトは、グループとインスタンスからテンプレートを継承します。

テンプレートは次の条件を満たす必要があります:

- `.md`拡張子で保存されている。
- `.gitlab/issue_templates`または`.gitlab/merge_request_templates`ディレクトリ内のプロジェクトのリポジトリに保存されている。
- デフォルトブランチ上に存在する。

## 説明テンプレートを作成する {#create-a-description-template}

`.md`ファイルとして、説明テンプレートを`.gitlab/issue_templates/`ディレクトリ内に新規作成します。

作業アイテムの説明テンプレートを作成するには:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **コード** > **リポジトリ**を選択します。
1. デフォルトブランチの横にある{{< icon name="plus" >}}を選択。
1. **新しいファイル**を選択。
1. デフォルトブランチの横にある**ファイル名**テキストボックスに、`.gitlab/issue_templates/mytemplate.md`と入力します。`mytemplate`は、説明テンプレートの名前です。
1. デフォルトブランチにコミットします。

これが正しく機能したか確認するには、以下を実行します:

1. [新しいイシューを作成](issues/create_issues.md)するか、[新しいエピックを作成](../group/epics/manage_epics.md#create-an-epic)します。
1. **テンプレートを選択してください**ドロップダウンリストで、作成した説明テンプレートが見つかるかどうかを確認します。

## マージリクエストテンプレートを作成する {#create-a-merge-request-template}

イシューテンプレートと同様に、リポジトリの`.gitlab/merge_request_templates/`ディレクトリ内に新しいMarkdown（`.md`）ファイルを作成します。イシュー説明テンプレートとは異なり、マージリクエストには、コミットメッセージとブランチ名の内容に応じた追加の継承ルールがあります。詳細については、[マージリクエストの作成](merge_requests/creating_merge_requests.md)を参照してください。

プロジェクトのマージリクエスト説明テンプレートを作成するには、以下を実行します:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **コード** > **リポジトリ**を選択します。
1. デフォルトブランチの横にある{{< icon name="plus" >}}を選択。
1. **新しいファイル**を選択。
1. デフォルトブランチの横にある**ファイル名**テキストボックスに、`.gitlab/merge_request_templates/mytemplate.md`と入力。ここで、`mytemplate`はマージリクエストテンプレートの名前です。
1. デフォルトブランチにコミットします。

この操作が正しく機能しているかどうかを確認するには、[新しいマージリクエストを作成](merge_requests/creating_merge_requests.md)し、**テンプレートを選択してください**ドロップダウンリストに説明テンプレートがあることを確認します。

## テンプレートを使用する {#use-the-templates}

イシューやマージリクエストを作成または編集すると、**テンプレートを選択してください**ドロップダウンリストに表示されます。

テンプレートを適用するには、以下を実行します:

1. イシュー、作業アイテム、またはマージリクエストを作成または編集。
1. **テンプレートを選択してください**ドロップダウンリストを選択。
1. **説明**テキストボックスが空白でない場合は**テンプレートを適用**を選択して確認します。
1. **変更を保存**を選択します。

説明テンプレートを選択すると、その内容が説明テキストボックスにコピーされます。

テンプレートを選択した後に説明に加えた変更を破棄するには、**テンプレートを選択してください**ドロップダウンリストを展開し、**テンプレートのリセット**を選択します。

![イシューで説明テンプレートを選択する](img/description_templates_v17_10.png)

{{< alert type="note" >}}

ショートカットリンクを作成し、指定されたテンプレートを使用してイシューを作成することができます。例: `https://gitlab.com/gitlab-org/gitlab/-/issues/new?issuable_template=Feature%20proposal`。詳細については、[値を事前に入力したURLを使用してイシューを作成する](issues/create_issues.md#using-a-url-with-prefilled-values)をお読みください。

{{< /alert >}}

### マージリクエストテンプレートでサポートされている変数 {#supported-variables-in-merge-request-templates}

{{< history >}}

- GitLab 15.7で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/89810)されました。

{{< /history >}}

{{< alert type="note" >}}

この機能は、[デフォルトテンプレート](#set-a-default-template-for-merge-requests-and-issues)でのみ使用できます。

{{< /alert >}}

マージリクエストを初めて保存したとき、GitLabはマージリクエストテンプレート内のこれらの変数を次の値に置き換えます:

| 変数                                | 説明                                                                                                                                                 | 出力例                                                                                                                                                                                   |
|-----------------------------------------|-------------------------------------------------------------------------------------------------------------------------------------------------------------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `%{all_commits}`                        | マージリクエスト内のすべてのコミットからのメッセージ。最新の100件のコミットに制限されています。100 KiBを超えるコミット本文とマージコミットメッセージはスキップされます。        | `* Feature introduced`<br><br> `This commit implements feature`<br> `Changelog:added`<br><br> `* Bug fixed`<br><br> `* Documentation improved`<br><br>`This commit introduced better docs.` |
| `%{co_authored_by}`                     | `Co-authored-by` Gitコミットトレーラー形式のコミット作成者の名前とメール。マージリクエストの最新の100件のコミットの作成者に制限されています。         | `Co-authored-by: Zane Doe <zdoe@example.com>`<br> `Co-authored-by: Blake Smith <bsmith@example.com>`                                                                                            |
| `%{first_commit}`                       | マージリクエストの差分の、最初のコミットのメッセージ全体。                                                                                                     | `Update README.md`                                                                                                                                                                               |
| `%{first_multiline_commit}`             | マージコミットではなく、メッセージ本文に複数の行が含まれる最初のコミットのメッセージ全体。すべてのコミットが複数行でない場合のマージリクエストのタイトル。 | `Update README.md`<br><br> `Improved project description in readme file.`                                                                                                                       |
| `%{first_multiline_commit_description}` | メッセージ本文に複数行が含まれる、マージコミットではない最初のコミットの説明（最初の行/タイトルを除く）。                        | `Improved project description in readme file.`                                                                                                                                                   |
| `%{source_branch}`                      | マージされるブランチの名前。                                                                                                                        | `my-feature-branch`                                                                                                                                                                              |
| `%{target_branch}`                      | 変更が適用されるブランチの名前。                                                                                                     | `main`                                                                                                                                                                                           |

### インスタンスレベルの説明テンプレートを設定する {#set-instance-level-description-templates}

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

**instance level**（インスタンスレベル）でイシューとマージリクエストの説明テンプレートを設定するには、[インスタンステンプレートリポジトリ](../../administration/settings/instance_template_repository.md)を使用します。ファイルテンプレートにインスタンステンプレートリポジトリを使用することもできます。

インスタンスで新しいプロジェクトを作成する際には、[プロジェクトテンプレート](../../administration/custom_project_templates.md)も使用できます。

### グループレベルの説明テンプレートを設定する {#set-group-level-description-templates}

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

**group-level**（グループレベル）の説明テンプレートを使用すると、グループ内のプロジェクトを選択してテンプレートを保存できます。次に、グループ内の他のプロジェクトでこれらのテンプレートにアクセスできます。これにより、グループのすべてのプロジェクトのイシューとマージリクエストで同じテンプレートを使用することができます。

前提要件:

- グループのオーナーの役割を持っている。
- プロジェクトは、グループの直接の子である。

[作成した](description_templates.md#create-a-description-template)テンプレートを再利用するには、以下を実行します:

1. 左側のサイドバーで、**検索または移動先**を選択して、グループを見つけます。
1. **設定** > **一般**を選択します。
1. **テンプレート**を展開。
1. ドロップダウンリストから、テンプレートプロジェクトをグループレベルのテンプレートリポジトリとして選択。
1. **変更を保存**を選択します。

![グループテンプレートを設定する](img/group_file_template_settings_v11_5.png)

[グループ内の各種ファイルタイプ向けテンプレート](../group/manage.md#group-file-templates)も利用できます。

### マージリクエストとイシューのデフォルトテンプレートを設定する {#set-a-default-template-for-merge-requests-and-issues}

プロジェクトで、新しいイシューとマージリクエストのデフォルトの説明テンプレートを選択することができます。これにより、新しいマージリクエストまたはイシューが作成されるたびに、テンプレートに入力したテキストが事前に入力されます。

前提要件: 

- プロジェクトの左側のサイドバーで、**設定** > **一般**を選択し、**可視性、プロジェクトの機能、権限**を展開します。イシューまたはマージリクエストが、**Everyone with access**（アクセスできる人すべて）または**プロジェクトメンバーのみ**に設定されていることを確認します。

マージリクエストのデフォルトの説明テンプレートを設定するには、以下のいずれかの操作を行います:

- `Default.md`という名前の[マージリクエストテンプレートを作成](#create-a-merge-request-template)し、`.gitlab/merge_request_templates/`に保存します。`Default.md`テンプレートは、プロジェクト設定で設定されたデフォルトのテンプレートよりも優先優先されません。詳細については、[デフォルトの説明テンプレートの優先度](#priority-of-default-description-templates)を参照してください。
- GitLab PremiumおよびUltimateのユーザー: プロジェクト設定で、デフォルトのテンプレートを設定します:

  1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
  1. **設定** > **マージリクエスト**を選択します。
  1. **マージリクエストのデフォルトの説明テンプレート**セクションで、テキスト領域に入力。
  1. **変更を保存**を選択します。

イシューのデフォルトの説明テンプレートを設定するには、次のいずれかの操作を行います:

- `Default.md`という名前の[イシューテンプレートを作成](#create-a-description-template)し、`.gitlab/issue_templates/`に保存します。`Default.md`テンプレートは、プロジェクト設定で設定されたデフォルトのテンプレートよりも優先優先されません。詳細については、[デフォルトの説明テンプレートの優先度](#priority-of-default-description-templates)を参照してください。
- GitLab PremiumおよびUltimateのユーザー: プロジェクト設定で、デフォルトのテンプレートを設定します:

  1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
  1. **設定** > **一般**を選択します。
  1. **イシューのデフォルトの説明テンプレート**を展開。
  1. テキスト領域に入力。
  1. **変更を保存**を選択します。

GitLabマージリクエストとイシューは[Markdown](../markdown.md)をサポートしているため、これを使用して見出しやリストなどをフォーマットできます。

また、[Projects REST API](../../api/projects.md)で`issues_template`属性と`merge_requests_template`属性を指定し、デフォルトのイシューテンプレートとマージリクエストテンプレートを最新の状態に保つこともできます。

#### デフォルトの説明テンプレートの優先順位 {#priority-of-default-description-templates}

さまざまな場所で[イシューの説明テンプレート](#set-a-default-template-for-merge-requests-and-issues)を設定した場合、プロジェクトでの優先順位は次のようになります。上位のものは、以下のものをオーバーライドします:

1. プロジェクトの設定で設定されたテンプレート。
1. 親グループからの`Default.md`（大文字と小文字を区別しません）。
1. プロジェクトリポジトリからの`Default.md`（大文字と小文字を区別しません）。

マージリクエストには、コミットメッセージとブランチ名の内容に応じて[追加の継承ルール](merge_requests/creating_merge_requests.md)があります。

## 説明テンプレートの例 {#example-description-template}

GitLabプロジェクトの[`.gitlab`フォルダー](https://gitlab.com/gitlab-org/gitlab/-/tree/master/.gitlab)には、イシューやマージリクエストで使用する説明テンプレートがあり、これらを例として参照できます。

{{< alert type="note" >}}

説明テンプレートで[クイックアクション](quick_actions.md)を使用して、ラベル、担当者、マイルストーンをすばやく追加することができます。クイックアクションは、イシューやマージリクエストを送信するユーザーが、関連するアクションを実行するための権限を持っている場合にのみ実行されます。

{{< /alert >}}

以下は、バグレポートテンプレートの例です:

```markdown
## Summary

<!-- HTML comments are not displayed -->
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
