---
stage: Foundations
group: Import and Integrate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Jiraイシュー管理
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

[GitLabでJiraイシューを直接管理](configure.md)できます。また、GitLabのコミットとマージリクエストで、JiraイシューをIDで参照できます。JiraイシューIDは大文字でなければなりません。

## GitLabのアクティビティとJiraイシューを相互参照する

このインテグレーションを使用すると、GitLabのイシュー、マージリクエスト、Gitでの作業中にJiraイシューを相互参照できます。GitLabのイシュー、マージリクエスト、コメント、コミットでJiraイシューをメンションすると、次のようになります。

- GitLabは、GitLabのメンションからJiraイシューにリンクします。
- GitLabは、GitLabのイシュー、マージリクエスト、コミットにリンクバックする書式設定されたコメントをJiraイシューに追加します。

たとえば、このコミットが`GIT-1` Jiraイシューを参照している場合:

```shell
git commit -m "GIT-1 this is a test commit"
```

GitLabは、そのJiraイシューに以下を追加します。

- **Webリンク**セクションの参照。
- 次の形式に従った、**アクティビティ**セクションのコメント。

  ```plaintext
  USER mentioned this issue in RESOURCE_NAME of [PROJECT_NAME|COMMENTLINK]:
  ENTITY_TITLE
  ```

  - `USER`: Jiraイシューをメンションしたユーザーの名前（GitLabのユーザープロファイルへのリンク付き）。
  - `RESOURCE_NAME`: Jiraイシューを参照したリソースのタイプ（例: GitLabのコミット、イシュー、またはマージリクエスト）。
  - `PROJECT_NAME`: GitLabのプロジェクト名。
  - `COMMENTLINK`: Jiraイシューがメンションされている場所へのリンク。
  - `ENTITY_TITLE`: GitLabのコミット（最初の行）、イシュー、またはマージリクエストのタイトル。

GitLabのイシュー、マージリクエスト、またはコミットごとに、Jiraに表示される相互参照は1つだけです。たとえば、Jiraイシューを参照するGitLabのマージリクエストに関する複数のコメントは、Jiraでそのマージリクエストへの単一の相互参照だけを作成します。

イシューの[コメントを無効にする](#disable-comments-on-jira-issues)ことができます。

### マージリクエストをマージするには関連付けられたJiraイシューが必要

{{< details >}}

- プラン: Ultimate
- 提供: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

このインテグレーションを使用すると、マージリクエストがJiraイシューを参照していない場合、そのマージリクエストがマージされないようにすることができます。この機能を有効にするには、次の手順に従います。

1. 左側のサイドバーで、**検索または移動**を選択して、プロジェクトを見つけます。
1. **設定 > マージリクエスト**を選択します。
1. **マージチェック**セクションで、**Jiraから関連付けられたイシューが必要**を選択します。
1. **保存**を選択します。

この機能を有効にすると、関連付けられたJiraイシューを参照していないマージリクエストをマージできなくなります。マージリクエストには、**マージするには、タイトルまたは説明でJiraイシューキーがメンションされている必要があります**というメッセージが表示されます。

## GitLabでのJiraイシューのマッチングをカスタマイズする

{{< history >}}

- GitLab 15.10で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/112826)されました。

{{< /history >}}

GitLabがJiraイシューキーをマッチングする方法について、以下を定義してカスタムルールを設定できます。

- [正規表現パターン](#define-a-regex-pattern)
- [プレフィックス](#define-a-prefix)

カスタムルールを設定しない場合は、[デフォルトの動作](https://gitlab.com/gitlab-org/gitlab/-/blob/9b062706ac6203f0fa897a9baf5c8e9be1876c74/lib/gitlab/regex.rb#L245)が使用されます。

### 正規表現パターンを定義する

{{< history >}}

- GitLab 17.6で、インテグレーション名が**Jiraイシュー**に[更新](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/166555)されました。

{{< /history >}}

正規表現（regex）を使用して、Jiraイシューキーをマッチングできます。正規表現パターンは、[RE2構文](https://github.com/google/re2/wiki/Syntax)に従う必要があります。

Jiraイシューキーの正規表現パターンを定義するには、次の定義に従います。

1. 左側のサイドバーで、**検索または移動**を選択して、プロジェクトを見つけます。
1. **設定 > インテグレーション**を選択します。
1. **Jiraイシュー**を選択します。
1. **Jiraイシューの一致**セクションに移動します。
1. **Jiraイシューの正規表現**テキストボックスに、正規表現パターンを入力します。
1. **変更の保存**を選択します。

詳細については、[Atlassianのドキュメント](https://confluence.atlassian.com/adminjiraserver073/changing-the-project-key-format-861253229.html)を参照してください。

### プレフィックスを定義する

{{< history >}}

- GitLab 17.6で、インテグレーション名が**Jiraイシュー**に[更新](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/166555)されました。

{{< /history >}}

プレフィックスを使用して、Jiraイシューキーをマッチングできます。たとえば、Jiraイシューキーが`ALPHA-1`で、`JIRA#`プレフィックスを定義した場合、GitLabでは、`ALPHA-1`ではなく、`JIRA#ALPHA-1`が一致します。

Jiraイシューキーのプレフィックスを定義するには、次の手順に従います。

1. 左側のサイドバーで、**検索または移動**を選択して、プロジェクトを見つけます。
1. **設定 > インテグレーション**を選択します。
1. **Jiraイシュー**を選択します。
1. **Jiraイシューの一致**セクションに移動します。
1. **Jiraイシューのプレフィックス**テキストボックスに、プレフィックスを入力します。
1. **変更の保存**を選択します。

## GitLabでJiraイシューをクローズする

GitLabの移行IDを設定している場合、GitLabからJiraイシューを直接クローズできます。コミットまたはマージリクエストで、JiraイシューIDが後に続くトリガーワードを使用します。トリガーワードとJiraイシューIDを含むコミットをプッシュすると、GitLabは次の操作を行います。

1. メンションされたJiraイシューにコメントします。
1. Jiraイシューをクローズします。Jiraイシューに解決策がある場合、Jiraイシューは移行されません。

たとえば、次のトリガーワードのいずれかを使用して、Jiraイシュー`PROJECT-1`をクローズします。

- `Resolves PROJECT-1`
- `Closes PROJECT-1`
- `Fixes PROJECT-1`

コミットまたはマージリクエストは、プロジェクトの[デフォルトブランチ](../../user/project/repository/branches/default.md)をターゲットにする必要があります。[プロジェクト設定](../../user/project/repository/branches/default.md#change-the-default-branch-name-for-a-project)でプロジェクトのデフォルトブランチを変更できます。

ブランチ名がJiraイシューIDと一致する場合、`Closes <JIRA-ID>`が既存のマージリクエストテンプレートに自動的に付加されます。イシューをクローズしない場合は、[イシューの自動クローズを無効にします](../../user/project/issues/managing_issues.md#disable-automatic-issue-closing)。

### イシューのクローズのユースケース

次の例を検討してください。

1. ユーザーがJiraイシュー`PROJECT-7`を作成して、新しい機能をリクエストします。
1. リクエストされた機能をビルドするために、GitLabでマージリクエストを作成します。
1. マージリクエストで、イシューのクローズトリガー`Closes PROJECT-7`を追加します。
1. マージリクエストがマージされると、次のようになります。
   - GitLabがJiraイシューをクローズします。
   - GitLabは、書式設定されたコメントをJiraに追加し、イシューを解決したコミットにリンクバックします。[コメントを無効にする](#disable-comments-on-jira-issues)ことができます。

## イシューの自動移行

イシューの自動移行を設定すると、参照されているJiraイシューを、**完了**のカテゴリの利用可能な次の状態に移行できます。この設定を構成するには、次の手順に従います。

1. [GitLabの設定](configure.md)の手順を参照してください。
1. **Jira移行を有効にする**チェックボックスをオンにします。
1. **完了に移動**オプションを選択します。

## カスタムイシュー移行

高度なワークフローでは、カスタムJira移行IDを指定できます。

1. Jiraのサブスクリプション状態に基づいた方法を使用します。
   - *（Jira Cloudのユーザーの場合）***テキスト**ビューでワークフローを編集して、移行IDを取得します。移行IDは、**移行**列に表示されます。
   - *（Jira Serverのユーザーの場合）*次のいずれかの方法で移行IDを取得します。
     - 適切な「オープン」状態にあるイシューを使って、`https://yourcompany.atlassian.net/rest/api/2/issue/ISSUE-123/transitions`のようなリクエストでAPIを使用します。
     - 目的の移行のリンクにカーソルを合わせ、URLで**アクション**パラメーターを探します。変更先の状態が同じであっても、ワークフロー（たとえば、ストーリーではなくバグ）によって移行IDが異なる場合があります。
1. [GitLabの設定](configure.md)の手順を参照してください。
1. **Jira移行を有効にする**設定を選択します。
1. **カスタム移行**オプションを選択します。
1. テキストフィールドに移行IDを入力します。複数の移行ID（`,`または`;`で区切られている）を挿入すると、指定した順序で、イシューが各状態に次々と移動します。移行が失敗すると、シーケンスは中断されます。

## Jiraイシューのコメントを無効にする

GitLabは、Jiraイシューにコメントを追加せずに、ソースコミットまたはマージリクエストをJiraイシューとクロスリンクできます。

1. [GitLabの設定](configure.md)の手順を参照してください。
1. **コメントを有効にする**チェックボックスをオフにします。
