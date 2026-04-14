---
stage: Create
group: Code Review
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: マージリクエストのタイトル検証を使用して、命名規則を適用し、設定された正規表現パターンにタイトルが一致しない場合にマージをブロックします。
title: マージリクエストのタイトル検証
---

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 17.11で`merge_request_title_regex`[フラグ](../../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/25689)されました。デフォルトでは無効になっています。
- [GitLab.comおよびGitLab Self-Managedで有効](https://gitlab.com/gitlab-org/gitlab/-/issues/508022) (GitLab 18.10にて)。
- GitLab 18.10で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/508022)になりました。機能フラグ`merge_request_title_regex`は削除されました。

{{< /history >}}

マージリクエストのタイトルに命名規則を適用するには、[RE2](https://github.com/google/re2/wiki/Syntax)正規表現パターンと照合します。プロジェクトのタイトルパターンを設定すると、そのパターンに一致しないマージリクエストはマージがブロックされます。

タイトル検証の使用目的:

- タイトルにJiraまたはイシュートラッカーのチケット参照を必須とします。
- [conventional commit](https://www.conventionalcommits.org/)の書式を適用します。
- リリースマネージメントまたはガバナンスワークフローのタイトルプレフィックスを標準化します。

## マージリクエストのタイトル検証を設定する {#configure-merge-request-title-validation}

プロジェクト内のすべてのマージリクエストのタイトルがマージされる前に一致する必要がある正規表現パターンを設定します。

前提条件: 

- プロジェクトのメンテナーまたはオーナーのロール。

タイトル検証を設定するには:

1. 上部のバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **設定 > マージリクエスト**を選択します。
1. **タイトルパターン**テキストボックスに、正規表現パターンを入力します。
1. **タイトルの例**テキストボックスに、期待されるフォーマットの説明を入力します。マージリクエストの作成者が何を使用すべきか分かるように、有効な例を含めてください。
1. **変更を保存**を選択します。

![プロジェクトのタイトル検証設定フィールド。](img/title_validation_settings_v18_10.png)

**タイトルパターン**を設定すると、**タイトルの例**も必須になります。マージリクエストのタイトルがパターンに一致しない場合、ユーザーには**タイトルの例**が表示されます。

タイトル検証を削除するには、**タイトルパターン**と**タイトルの例**のテキストボックスを両方クリアし、**変更を保存**を選択します。

APIでタイトル検証を設定するには、[projects API](../../../api/projects.md)も使用できます。

## 正規表現構文 {#regex-syntax}

タイトル検証はPCREではなく[RE2構文](https://github.com/google/re2/wiki/Syntax)を使用します。RE2は後方参照や先読み/後読みアサーションをサポートしていません。

パターンと説明のフィールドは、それぞれ最大255文字です。

### パターンの例 {#example-patterns}

以下は正規表現パターンの例です:

- Jiraチケット参照（有効なタイトルの例: `PROJ-123 Fix login bug`）:

  ```plaintext
  ^[A-Z]+-\d+ .+
  ```

- Conventionalコミット（有効なタイトルの例: `feat(auth): add SSO support`）:

  ```plaintext
  ^(feat|fix|docs|chore|refactor|test|style)(\(.+\))?: .+
  ```

- カスタムプレフィックス（有効なタイトルの例: `BUGFIX: resolve timeout error`）:

  ```plaintext
  ^(FEATURE|BUGFIX|HOTFIX): .+
  ```

- 角括弧で囲まれたカテゴリ（有効なタイトルの例: `[Feature] Add dark mode`）:

  ```plaintext
  ^\[.+\] .+
  ```

## 検証の適用 {#validation-enforcement}

タイトル検証パターンが設定されている場合:

- パターンに一致しないマージリクエストのタイトルはマージできません。
- タイトルチェックは、承認、パイプラインステータス、スレッド解決などの他のチェックと並んでマージチェックとして表示されます。
- If [自動マージ](auto_merge.md)が有効な場合、マージリクエストはタイトルがパターンに一致するのを待ってからマージされます。
- 検証はマージ時の現在のタイトルに適用されます。作成者はマージする前の任意の時点でタイトルを更新できます。

![タイトル検証チェックによってブロックされたマージリクエスト。](img/title_validation_failed_v18_10.png)

## トラブルシューティング {#troubleshooting}

### タイトル検証のためマージリクエストをマージできません {#merge-request-cannot-be-merged-due-to-title-validation}

マージリクエストがタイトル検証によってブロックされた場合:

1. マージリクエストのマージチェックセクションで、タイトル検証の失敗を確認します。
1. **設定** > **マージリクエスト** > **タイトルパターン**で設定されたパターンに一致するように、マージリクエストのタイトルを更新します。
1. エラーメッセージに表示されている**タイトルの例**を、期待されるフォーマットの参照として使用してください。

### ドラフトマージリクエスト {#draft-merge-requests}

タイトル検証は、`Draft:`プレフィックスを含む完全なタイトル文字列に適用されます。正規表現パターンが`Draft:`プレフィックスを考慮していない場合、ドラフトマージリクエストは検証に失敗する可能性があります。ドラフトおよび非ドラフトの両方のタイトルを許可するには、`^(Draft: )?YOUR_PATTERN`のようなパターンを使用することを検討してください。

### 正規表現パターンが期待どおりに一致しない {#regex-pattern-does-not-match-as-expected}

タイトル検証は、多くのオンライン正規表現テスターで使用されるPCRE構文とは異なる[RE2構文](https://github.com/google/re2/wiki/Syntax)を使用します。パターンを検証するには:

- RE2互換の正規表現テスターを使用します。
- 後方参照や先読みアサーションのようなサポートされていない機能を使用していないことを確認します。
- 特殊文字が正しくエスケープされていることを確認します。

## 関連トピック {#related-topics}

- [自動マージ](auto_merge.md)
- [Projects API - `merge_request_title_regex`](../../../api/projects.md)
- [マージステータスAPI](../../../api/merge_requests.md#merge-status)
