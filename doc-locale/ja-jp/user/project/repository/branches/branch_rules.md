---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: Gitブランチの命名、管理、保護の方法について説明します。
title: ブランチルール
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

GitLabは、個々のブランチを保護するための複数の方法を提供しています。これらのメソッドにより、ブランチは作成から削除まで監視と品質チェックを受けます:

- プロジェクトの[デフォルトブランチ](default.md)に強化されたセキュリティと保護を適用します。
- [保護ブランチ](protected.md)を次のように設定します:
  - ブランチへのプッシュとマージができるユーザーを制限します。
  - ユーザーがブランチに強制プッシュできるかどうかを管理します。
  - `CODEOWNERS`ファイルにリストされているファイルへの変更が、ブランチに直接プッシュできるかどうかを管理します。
- [承認ルール](../../merge_requests/approvals/rules.md#approvals-for-protected-branches)を設定し、レビュー要件を管理し、[セキュリティ関連の承認](../../merge_requests/approvals/rules.md#security-approvals)を実装します。
- サードパーティの[ステータスチェック](../../merge_requests/status_checks.md)と統合し、ブランチの内容が定義された品質基準を満たしていることを確認します。

ブランチは次のように管理できます:

- GitLabのユーザーインターフェースを使用します。
- コマンドラインのGitを使用します。
- [ブランチAPI](../../../../api/branches.md)を使用します。

## ブランチルールを表示 {#view-branch-rules}

{{< history >}}

- GitLab 16.1で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/123368)になりました。機能フラグ`branch_rules`は削除されました。

{{< /history >}}

ブランチルール概要ページには、設定されているすべてのブランチと、その保護方法が表示されます:

![保護が設定されたブランチの例](img/view_branch_protections_v15_10.png)

前提条件: 

- プロジェクトのメンテナーまたはオーナーロールが必要です。

ブランチルールの概要リストを表示するには:

1. 上部のバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **設定** > **リポジトリ**を選択します。
1. **ブランチルール**を展開して、保護されたすべてのブランチを表示します。

### ブランチルールの詳細を表示 {#view-branch-rule-details}

単一のブランチのブランチルールと保護を表示するには:

1. 上部のバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **設定** > **リポジトリ**を選択します。
1. **ブランチルール**を展開して、保護されたすべてのブランチを表示します。
1. 目的のブランチを特定し、**詳細を表示**を選択します。

## ブランチルールを作成 {#create-a-branch-rule}

{{< history >}}

- GitLab 16.8で`add_branch_rules`という名前のフラグとともに[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/88279)されました。デフォルトでは無効になっています。
- 機能フラグ`add_branch_rules`はGitLab 16.11で`edit_branch_rules`に[名称変更](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/88279)されました。デフォルトでは無効になっています。
- GitLab 17.0で**すべてのブランチ**と**全ての保護ブランチ**のオプションが[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/388129)されました。
- GitLab.comでGitLab 17.4で[有効](https://gitlab.com/gitlab-org/gitlab/-/issues/454501)になりました。
- GitLab Self-ManagedおよびGitLab DedicatedでGitLab 17.5で[有効](https://gitlab.com/gitlab-org/gitlab/-/issues/454501)になりました。
- GitLab 18.9で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/work_items/586354)になりました。機能フラグ`edit_branch_rules`は削除されました。

{{< /history >}}

前提条件: 

- プロジェクトのメンテナーまたはオーナーロールが必要です。

ブランチルールを作成するには:

1. 上部のバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **設定** > **リポジトリ**を選択します。
1. **ブランチルール**を展開します。
1. **ブランチルールの追加**を選択します。
1. 次のいずれかのオプションを選択します。
   - 特定のブランチ名またはパターンを入力するには:
     1. **ブランチ名またはパターン**を選択します。
     1. **ブランチルールの作成**ドロップダウンリストから、ブランチ名を選択するか、`*`を使用して[ワイルドカード](protected.md#use-wildcard-rules)を作成します。
   - プロジェクト内のすべてのブランチを保護するには:
     1. **すべてのブランチ**を選択します。
     1. ルールの詳細ページで、**マージリクエストの承認**の下にある必須の承認数を入力します。
   - すでに保護済みとして指定されているプロジェクト内のすべてのブランチを保護するには:
     1. **全ての保護ブランチ**を選択します。
     1. ルールの詳細ページで、**マージリクエストの承認**の下にある必須の承認数を入力します。

### ブランチルール保護の追加 {#add-a-branch-rule-protection}

> [!note]
> `all branches`には使用できません。

新しいブランチに保護を追加するには:

1. 上部のバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
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

> [!note]
> `all branches`には使用できません。

前提条件: 

- プロジェクトのメンテナーまたはオーナーロールが必要です。

マージリクエスト承認ルールを追加するには:

1. [ブランチルール詳細](#view-branch-rule-details)ページから、**マージリクエストの承認**セクションに移動します。
1. **承認ルール**セクションで、**承認ルールを追加**を選択します。
1. 右サイドバーで、フィールドに入力します:
   - **ルール名**を入力します。
   - **必要な承認数**に値を入力します (`0`-`100`)。

     `0`の値は[ルールをオプション](../../merge_requests/approvals/rules.md#configure-optional-approval-rules)にし、`0`より大きい値は必須ルールを作成します。必要な承認の最大数は`100`です。
   - [承認資格のある](../../merge_requests/approvals/rules.md#eligible-approvers)ユーザーまたはグループを選択します。

     GitLabは、マージリクエストによって変更されたファイルの以前の作成者に基づいて承認者を提案します。
1. **変更を保存**を選択します。

追加情報については、[承認ルール](../../merge_requests/approvals/rules.md#approvals-for-protected-branches)を参照してください。

### コミットをスカッシュオプションの編集 {#edit-squash-commits-option}

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 17.9で`branch_rule_squash_settings`という名前のフラグとともに[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/181370)されました。デフォルトでは無効になっています。
- GitLab 17.10の[GitLab.com、GitLab Self-Managed、およびGitLab Dedicatedで有効になりました](https://gitlab.com/gitlab-org/gitlab/-/issues/506542)。
- GitLab 17.11で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/524860)になりました。機能フラグ`branch_rule_squash_settings`は削除されました。

{{< /history >}}

前提条件: 

- プロジェクトのメンテナーまたはオーナーロールが必要です。
- GitLab Freeでは、この機能はブランチルールが**すべてのブランチ**をターゲットとする場合にのみ利用可能です。
- PremiumおよびUltimateでは、この機能はすべてのブランチルールで利用可能です。

スカッシュオプションを編集するには:

1. [ブランチルール詳細](#view-branch-rule-details)ページから、**マージ時にコミットをスカッシュする**セクションに移動します。
1. **編集**を選択します。
1. 以下のオプションのいずれかを選択します:

   - **デフォルト**: ブランチレベルのスカッシュ設定を削除し、プロジェクトのデフォルト設定を継承します。このオプションは、プロジェクトのデフォルト設定を定義する**すべてのブランチ**ルールでは利用できません。
   - **許可しない**: スカッシュは許可されず、チェックボックスは非表示になります。
   - **許可**: チェックボックスは表示され、デフォルトで選択されていません。
   - **推奨**: チェックボックスは表示され、デフォルトで選択されています。
   - **必須**: スカッシュは常に実行されます。チェックボックスは表示され、選択されており、ユーザーは変更できません。

1. **変更を保存**を選択します。

### ステータスチェックサービスの追加 {#add-a-status-check-service}

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 17.4で`edit_branch_rules`[フラグ](../../../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/groups/gitlab-org/-/epics/12522)されました。デフォルトでは無効になっています。
- GitLab.comでGitLab 17.4で[有効](https://gitlab.com/gitlab-org/gitlab/-/issues/454501)になりました。
- GitLab Self-ManagedおよびGitLab DedicatedでGitLab 17.5で[有効](https://gitlab.com/gitlab-org/gitlab/-/issues/454501)になりました。
- GitLab 18.9で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/work_items/586354)になりました。機能フラグ`edit_branch_rules`は削除されました。

{{< /history >}}

> [!note]
> `all protected branches`には使用できません。

ステータスチェックサービスを追加するには:

1. [ブランチルール詳細](#view-branch-rule-details)ページから、**ステータスチェック**セクションに移動します。
1. **ステータスチェックの追加**を選択します。
1. **サービス名**を入力します。
1. **チェックするAPI**フィールドにURLを入力します。

   マージリクエストデータを転送時に保護するために、HTTPS URLを使用する必要があります。

![ブランチルールステータスチェック](img/branch_rule_status_check_v17_4.png)

詳細については、[外部ステータスチェック](../../merge_requests/status_checks.md)を参照してください。

## ブランチルールターゲットの編集 {#edit-a-branch-rule-target}

{{< history >}}

- GitLab 16.8で`add_branch_rules`という名前のフラグとともに[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/88279)されました。デフォルトでは無効になっています。
- 機能フラグ`add_branch_rules`はGitLab 16.11で`edit_branch_rules`に[名称変更](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/88279)されました。デフォルトでは無効になっています。
- GitLab.comでGitLab 17.4で[有効](https://gitlab.com/gitlab-org/gitlab/-/issues/454501)になりました。
- GitLab Self-ManagedおよびGitLab DedicatedでGitLab 17.5で[有効](https://gitlab.com/gitlab-org/gitlab/-/issues/454501)になりました。
- GitLab 18.9で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/work_items/586354)になりました。機能フラグ`edit_branch_rules`は削除されました。

{{< /history >}}

前提条件: 

- プロジェクトのメンテナーまたはオーナーロールが必要です。

ブランチルールターゲットを編集するには:

1. 上部のバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **設定** > **リポジトリ**を選択します。
1. **ブランチルール**を展開して、保護されたすべてのブランチを表示します。
1. 目的のブランチを特定し、**詳細を表示**を選択します。
1. **ルールターゲット**セクションで、**編集**を選択します。
1. 必要に応じて情報を編集します。
1. **Update**を選択します。

### ブランチルール保護の編集 {#edit-a-branch-rule-protection}

ブランチ保護コントロールの詳細については、[保護ブランチ](protected.md)を参照してください。

> [!note]
> `all branches`には使用できません。

## ブランチルールを削除 {#delete-a-branch-rule}

{{< history >}}

- GitLab 16.8で`add_branch_rules`という名前のフラグとともに[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/88279)されました。デフォルトでは無効になっています。
- 機能フラグ`add_branch_rules`はGitLab 16.11で`edit_branch_rules`に[名称変更](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/88279)されました。デフォルトでは無効になっています。
- GitLab.comでGitLab 17.4で[有効](https://gitlab.com/gitlab-org/gitlab/-/issues/454501)になりました。
- GitLab Self-ManagedおよびGitLab DedicatedでGitLab 17.5で[有効](https://gitlab.com/gitlab-org/gitlab/-/issues/454501)になりました。
- GitLab 18.9で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/work_items/586354)になりました。機能フラグ`edit_branch_rules`は削除されました。

{{< /history >}}

前提条件: 

- プロジェクトのメンテナーまたはオーナーロールが必要です。

ブランチルールを削除するには:

1. 上部のバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **設定** > **リポジトリ**を選択します。
1. **ブランチルール**を展開します。
1. 削除するルールの横にある**詳細を表示**を選択します。
1. 右上隅にある**ブランチルールの削除**を選択します。
1. 確認ダイアログで、**ブランチルールの削除**を選択します。

> [!note]
> ブランチルールを削除する機能は、`all branches`をターゲットとするルールには利用できません。

## 関連トピック {#related-topics}

- [デフォルトブランチ](default.md)
- [保護ブランチ](protected.md)
- [リポジトリを保護する](../protect.md)
- [ブランチ戦略](strategies/_index.md)
- [マージリクエスト承認](../../merge_requests/approvals/_index.md)
