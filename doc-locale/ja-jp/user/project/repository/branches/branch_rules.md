---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: Gitブランチの命名、管理、保護の方法について説明します。
title: ブランチルール
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

GitLabは、個々のブランチを保護するための複数の方法を提供しています。これらの方法により、ブランチを作成してから削除するまで、監視と品質チェックを受けることができます:

- プロジェクトの[デフォルトブランチ](default.md)に、強化されたセキュリティと保護を適用します。
- [保護ブランチ](protected.md)を設定して以下を行います:
  - ブランチへのプッシュおよびマージを許可するユーザーを制限します。
  - ユーザーがブランチに強制プッシュできるかどうかを管理します。
  - `CODEOWNERS`ファイルにリストされているファイルへの変更を、ブランチに直接プッシュできるかどうかを管理します。
- [承認ルール](../../merge_requests/approvals/rules.md#approvals-for-protected-branches)を設定してレビュー要件を管理し、[セキュリティ関連の承認](../../merge_requests/approvals/rules.md#security-approvals)を実装します。
- サードパーティの[ステータスチェック](../../merge_requests/status_checks.md)と統合して、ブランチのコンテンツが定義された品質基準を満たしていることを確認します。

ブランチは以下で管理できます:

- GitLabのユーザーインターフェースを使用します。
- コマンドラインでGitを使用。
- [Branches API](../../../../api/branches.md)を使用。

## ブランチルールを表示する {#view-branch-rules}

{{< history >}}

- GitLab 16.1で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/123368)になりました。機能フラグ`branch_rules`は削除されました。

{{< /history >}}

ブランチルール概要ページには、設定された保護と保護方法が設定されたすべてのブランチが表示されます:

![保護が設定されたブランチの例](img/view_branch_protections_v15_10.png)

前提要件: 

- プロジェクトのメンテナー以上のロールを持っている必要があります。

ブランチルール概要リストを表示するには:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **設定** > **リポジトリ**を選択します。
1. **ブランチルール**を展開して、保護されたすべてのブランチを表示します。

### ブランチルールの詳細を表示 {#view-branch-rule-details}

単一のブランチに対するブランチルールと保護を表示するには:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **設定** > **リポジトリ**を選択します。
1. **ブランチルール**を展開して、保護されたすべてのブランチを表示します。
1. 目的のブランチを特定し、**詳細を表示**を選択します。

## ブランチルールを作成する {#create-a-branch-rule}

{{< history >}}

- GitLab 16.8で`add_branch_rules`フラグとともに[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/88279)されました。デフォルトでは無効になっています。
- 機能フラグ`add_branch_rules`がGitLab 16.11で[名前変更](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/88279)され、`edit_branch_rules`になりました。デフォルトでは無効になっています。
- **すべてのブランチ**および**全ての保護ブランチ**オプションがGitLab 17.0で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/388129)されました。
- GitLab 17.4で[GitLab.comで有効](https://gitlab.com/gitlab-org/gitlab/-/issues/454501)になりました。
- GitLab 17.5の[GitLab Self-ManagedおよびGitLab Dedicatedで有効](https://gitlab.com/gitlab-org/gitlab/-/issues/454501)になりました。

{{< /history >}}

{{< alert type="flag" >}}

この機能の利用可否は、機能フラグによって制御されます。詳細については、履歴を参照してください。

{{< /alert >}}

前提要件:

- プロジェクトのメンテナー以上のロールを持っている必要があります。

ブランチルールを作成するには:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **設定** > **リポジトリ**を選択します。
1. **ブランチルール**を展開します。
1. **ブランチルールの追加**を選択します。
1. 次のいずれかのオプションを選択します:
   - 特定のブランチ名またはパターンを入力するには:
     1. **ブランチ名またはパターン**を選択します。
     1. **ブランチルールの作成**ドロップダウンリストから、ブランチ名を選択するか、`*`で[ワイルドカード](protected.md#use-wildcard-rules)を作成します。
   - プロジェクト内のすべてのブランチを保護するには:
     1. **すべてのブランチ**を選択します。
     1. ルールの詳細ページの**マージリクエストの承認**で、ルールに必要な承認数を入力します。
   - すでに保護されていると指定されているプロジェクト内のすべてのブランチを保護するには:
     1. **全ての保護ブランチ**を選択します。
     1. ルールの詳細ページの**マージリクエストの承認**で、ルールに必要な承認数を入力します。

### ブランチルール保護の追加 {#add-a-branch-rule-protection}

{{< alert type="note" >}}

`all branches`では利用できません。

{{< /alert >}}

新しいブランチに保護を追加するには:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **設定** > **リポジトリ**を選択します。
1. **ブランチルール**を展開します。
1. **ブランチルールの追加**を選択します。
1. **全ての保護ブランチ**または**ブランチ名またはパターン**のいずれかを選択します。
1. **ブランチルールの作成**を選択します。

### 承認ルールを追加する {#add-an-approval-rule}

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< alert type="note" >}}

`all branches`では利用できません。

{{< /alert >}}

前提要件:

- プロジェクトのメンテナー以上のロールを持っている必要があります。

マージリクエスト承認ルールを追加するには:

1. [ブランチルールの詳細](#view-branch-rule-details)ページから、**マージリクエストの承認**セクションに移動します。
1. **承認ルール**セクションで、**承認ルールを追加**を選択します。
1. 右側のサイドバーで、次のフィールドに入力します:
   - **ルール名**を入力します。
   - **必要な承認数**に、値を入力します（`0`-`100`）。

     `0`の値は[ルールをオプション](../../merge_requests/approvals/rules.md#configure-optional-approval-rules)にし、`0`より大きい数値を指定すると必須ルールが作成されます。必要な承認の最大数は`100`です。
   - [承認できる](../../merge_requests/approvals/rules.md#eligible-approvers)ユーザーまたはグループを選択します。

     GitLabは、マージリクエストによって変更されたファイルの以前の作成者に基づいて承認者を提案します。
1. **変更を保存**を選択します。

詳細については、[承認ルール](../../merge_requests/approvals/rules.md#approvals-for-protected-branches)を参照してください。

### コミットをスカッシュオプションの編集 {#edit-squash-commits-option}

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 17.9で`branch_rule_squash_settings`フラグとともに[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/181370)されました。デフォルトでは無効になっています。
- GitLab 17.10の[GitLab.com、GitLab Self-Managed、およびGitLab Dedicatedで有効になりました](https://gitlab.com/gitlab-org/gitlab/-/issues/506542)。
- GitLab 17.11[で一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/524860)になりました。機能フラグ`branch_rule_squash_settings`は削除されました。

{{< /history >}}

前提要件:

- プロジェクトのメンテナー以上のロールを持っている必要があります。
- GitLab Freeでは、ブランチルールが**すべてのブランチ**を対象とする場合にのみ、この機能を使用できます。
- GitLab PremiumおよびGitLab Ultimateでは、この機能はすべてのブランチルールで使用できます。

スカッシュオプションを編集するには:

1. [ブランチルールの詳細](#view-branch-rule-details)ページから、**マージ時にコミットをスカッシュする**セクションに移動します。
1. **編集**を選択します。
1. 次のいずれかのオプションを選択します:

   - **許可しない**: スカッシュは許可されず、チェックボックスは非表示になります。
   - **許可**: チェックボックスが表示され、デフォルトで選択されていません。
   - **推奨**: チェックボックスが表示され、デフォルトで選択されています。
   - **必須**: スカッシュは常に実行されます。チェックボックスが表示されて選択され、ユーザーは変更できません。

1. **変更を保存**を選択します。

### ステータスチェックサービスを追加 {#add-a-status-check-service}

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 17.4で`edit_branch_rules`[フラグ](../../../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/groups/gitlab-org/-/epics/12522)されました。デフォルトでは無効になっています。
- GitLab 17.4で[GitLab.com](https://gitlab.com/gitlab-org/gitlab/-/issues/454501)で有効になりました。
- GitLab 17.5の[GitLab Self-ManagedおよびGitLab Dedicatedで有効](https://gitlab.com/gitlab-org/gitlab/-/issues/454501)になりました。

{{< /history >}}

{{< alert type="note" >}}

`all protected branches`では利用できません。

{{< /alert >}}

ステータスチェックサービスを追加するには:

1. [ブランチルールの詳細](#view-branch-rule-details)ページから、**ステータスチェック**セクションに移動します。
1. **ステータスチェックの追加**を選択します。
1. **サービス名**を入力します。
1. **チェックするAPI**フィールドに、URLを入力します。

   転送中のマージリクエストデータを保護するには、HTTPS URLを使用する必要があります。

![ブランチルールのステータスチェック](img/branch_rule_status_check_v17_4.png)

詳細については、[外部ステータスチェック](../../merge_requests/status_checks.md)を参照してください。

## ブランチルールターゲットの編集 {#edit-a-branch-rule-target}

{{< history >}}

- GitLab 16.8で`add_branch_rules`フラグとともに[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/88279)されました。デフォルトでは無効になっています。
- 機能フラグ`add_branch_rules`がGitLab 16.11で[名前変更](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/88279)され、`edit_branch_rules`になりました。デフォルトでは無効になっています。
- GitLab 17.4で[GitLab.com](https://gitlab.com/gitlab-org/gitlab/-/issues/454501)で有効になりました。
- GitLab 17.5の[GitLab Self-ManagedおよびGitLab Dedicatedで有効](https://gitlab.com/gitlab-org/gitlab/-/issues/454501)になりました。

{{< /history >}}

{{< alert type="flag" >}}

この機能の利用可否は、機能フラグによって制御されます。詳細については、履歴を参照してください。

{{< /alert >}}

前提要件:

- プロジェクトのメンテナー以上のロールを持っている必要があります。

ブランチルールターゲットを編集するには:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **設定** > **リポジトリ**を選択します。
1. **ブランチルール**を展開して、保護されたすべてのブランチを表示します。
1. 目的のブランチを特定し、**詳細を表示**を選択します。
1. **ルールターゲット**セクションで、**編集**を選択します。
1. 必要に応じて情報を編集します。
1. **更新**を選択します。

### ブランチルール保護の編集 {#edit-a-branch-rule-protection}

ブランチ保護コントロールの詳細については、[保護ブランチ](protected.md)を参照してください。

{{< alert type="note" >}}

`all branches`では利用できません。

{{< /alert >}}

## ブランチルールを削除する {#delete-a-branch-rule}

{{< history >}}

- GitLab 16.8で`add_branch_rules`フラグとともに[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/88279)されました。デフォルトでは無効になっています。
- 機能フラグ`add_branch_rules`がGitLab 16.11で[名前変更](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/88279)され、`edit_branch_rules`になりました。デフォルトでは無効になっています。
- GitLab 17.4で[GitLab.com](https://gitlab.com/gitlab-org/gitlab/-/issues/454501)で有効になりました。
- GitLab 17.5の[GitLab Self-ManagedおよびGitLab Dedicatedで有効](https://gitlab.com/gitlab-org/gitlab/-/issues/454501)になりました。

{{< /history >}}

{{< alert type="flag" >}}

この機能の利用可否は、機能フラグによって制御されます。詳細については、履歴を参照してください。

{{< /alert >}}

{{< alert type="note" >}}

ブランチルールの削除は、`all branches`を対象とするルールでは使用できません。

{{< /alert >}}

前提要件:

- プロジェクトのメンテナー以上のロールを持っている必要があります。

ブランチルールを削除するには:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **設定** > **リポジトリ**を選択します。
1. **ブランチルール**を展開します。
1. 削除するルールの横にある**詳細を表示**を選択します。
1. 右上隅で、**ブランチルールの削除**を選択します。
1. 確認ダイアログで、**ブランチルールの削除**を選択します。

## 関連トピック {#related-topics}

- [デフォルトブランチ](default.md)
- [保護ブランチ](protected.md)
- [リポジトリを保護する](../protect.md)
- [ブランチ戦略](strategies/_index.md)
- [マージリクエストの承認](../../merge_requests/approvals/_index.md)
