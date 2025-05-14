---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: To ensure all changes are reviewed, configure optional or required approvals for merge requests in your project.
title: マージリクエストの承認
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

プロジェクトの変更に対するレビュープロセスを設定するには、マージリクエストの承認を設定します。これにより、変更がプロジェクトにマージされる前にレビューできるようになります。プロジェクトのニーズとGitLabのプランに応じて、承認をオプションまたは必須に設定できます。

- [GitLab Free](https://about.gitlab.com/pricing/)では、デベロッパー以上の[ロール](../../../permissions.md)を持つすべてのユーザーが、マージリクエストを承認できます。これらの承認はオプションであり、承認なしのマージを防止することはできません。
- [GitLab Premium](https://about.gitlab.com/pricing/)と[GitLab Ultimate](https://about.gitlab.com/pricing/)は、次の点においてより柔軟性があります。

  - 必要な承認の数と種類に関する必須[ルール](rules.md)を作成する。
  - 特定のファイルの[コードオーナー](../../codeowners/_index.md)のリストを作成する。
  - [インスタンス全体](../../../../administration/merge_requests_approvals.md)の承認を設定する。
  - [グループマージリクエスト承認の設定](../../../group/manage.md#group-merge-request-approval-settings)を設定する。

    {{< alert type="note" >}}

    グループのマージリクエスト承認の設定のサポートは、[エピック4367](https://gitlab.com/groups/gitlab-org/-/epics/4367)で追跡されます。

    {{< /alert >}}

## 承認ルールを設定する

前提要件:

- プロジェクトのデベロッパーロール以上を持っている必要があります。

承認ルールを設定するには、以下を実行します。

1. プロジェクトの**設定 > マージリクエスト**に移動します。
1. **マージリクエスト承認**セクションに移動します。
1. 必要なルールを設定します。

次の設定も可能です。

- プロジェクトに必要な監視とセキュリティのレベルをより細かく制御するための、追加の[マージリクエスト承認の設定](settings.md)。
- [マージリクエスト承認API](../../../../api/merge_request_approvals.md)を使用して、マージリクエスト承認ルールを設定する。

ルール設定の詳細については、「[承認ルール](rules.md)」を参照してください。

### 必須の承認

{{< details >}}

- プラン: Premium、Ultimate
- 提供: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

必須の承認により、指定されたユーザーによるコードレビューを強制できます。これらの承認がなければ、マージはできません。

ユースケースは以下のとおりです。

- リポジトリにマージされるすべてのコードのレビューを強制する。
- レビュアーと最小承認数を指定する。
- バックエンド、フロントエンド、品質管理、データベース、ドキュメントなどのレビュアーのカテゴリを指定する。
- [コードオーナー](../../codeowners/_index.md)ファイルを使用して、レビュアーを決定する。
- [テストカバレッジの低下](../../../../ci/testing/code_coverage/_index.md#add-a-coverage-check-approval-rule)に対する承認を要求する。
- GitLab Ultimate: 潜在的な[脆弱性](../../../application_security/_index.md#security-approvals-in-merge-requests)に対して、セキュリティチームの承認を[要求](../../../application_security/_index.md#security-approvals-in-merge-requests)する。

## 承認ステータスを表示する

{{< history >}}

- GitLab 17.10で、よりきめ細かい承認者の表示が[一般提供](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/183058)になりました。機能フラグ`mr_approvers_filter_hidden_users`が削除されました。

{{< /history >}}

マージリクエストの承認ステータスは、2つの場所で確認できます。[マージリクエスト](#for-a-single-merge-request)と、プロジェクトまたはグループの[マージリクエストのリスト](#in-the-list-of-merge-requests)に表示されます。

### 単一のマージリクエストの場合

[対象となる承認者](rules.md#eligible-approvers)は、単一のマージリクエストの承認ステータスを表示できます。

承認ステータスを表示するには、以下を実行します。

1. 左側のサイドバーで、**検索または移動**を選択して、プロジェクトを検索します。
1. **コード > マージリクエスト**に移動し、マージリクエストを見つけます。
1. マージリクエストを表示するには、タイトルを選択します。
1. マージリクエストウィジェットに移動して、承認ステータスを表示します。この例では、マージリクエストを承認できます。

   ![承認ステータスを示すマージリクエストウィジェット](img/approval_and_merge_status_v17_3.png)

ウィジェットには、次のいずれかのステータスが表示されます:

- **承認**: マージリクエストに追加の承認が必要です。
- **追加の承認**: マージリクエストに必須の承認があります。
- **承認の失効**: マージリクエストをすでに承認しています。

承認が**コードオーナー**の要件を満たしているかどうかを確認するには、**対象となる承認者情報を展開**（{{< icon name="chevron-lg-down" >}}）を選択します。

承認者の表示レベルは、プロジェクトのメンバーシップとグループのプライバシーによって異なります:

- プロジェクトのメンバーには、すべての承認者が表示されます。
- プロジェクトのメンバー以外には、以下が表示されます。
  - すべての承認者がパブリックグループのメンバーである場合は、すべての承認者が表示されます。
  - 承認者のいずれかがプライベートグループのメンバーである場合は、承認者に関する情報は表示されません。

### マージリクエストのリスト

[プロジェクトまたはグループ](../_index.md#view-merge-requests)のマージリクエストのリストには、各マージリクエストの承認ステータスが表示されます。

| 例 | 説明 |
| :-----: | :---------- |
| ![承認が完了していません](img/approvals_unsatisfied_v17_1.png) | 必須の承認がありません。（{{< icon name="approval" >}}） |
| ![承認が完了しました](img/approvals_satisfied_v17_1.png) | 承認が完了しました。（{{< icon name="check" >}}） |
| ![承認が完了し、承認済みです](img/you_approvals_satisfied_v17_1.png) | 承認が完了しました。あなたは承認者の1人です。（{{< icon name="approval-solid" >}}） |

### 個々のレビュアーのステータス

各レビュアーのレビューと承認ステータスを確認するには、以下を実行します。

1. マージリクエストを開きます。
1. 右側のサイドバーを確認します。

各レビュアーのステータスが、名前の横に表示されます。

- {{< icon name="dash-circle" >}}レビュー待ち
- {{< icon name="status_running" >}}レビュー中
- {{< icon name="check-circle" >}}承認済み
- {{< icon name="comment-lines" >}}レビュアーがコメントしました
- {{< icon name="status_warning" >}}レビュアーが変更をリクエストしました

   ![このレビュアーが変更をリクエストし、このマージリクエストをブロックしました。](img/reviewer_blocks_mr_v17_3.png)

[レビューを再リクエスト](../reviews/_index.md#re-request-a-review)するには、ユーザーの横にある**レビューを再リクエスト**アイコン（{{< icon name="redo" >}}）を選択します。

## マージリクエストを承認する

対象となる承認者は、次の2つの方法でマージリクエストを承認できます。

1. マージリクエストウィジェットで、**承認**を選択します。
1. コメントで`/approve`[クイックアクション](../../quick_actions.md)を使用します。

承認されたマージリクエストには、レビュアーのリストのユーザー名の横に緑色のチェックマーク（{{< icon name="check-circle-filled" >}}）が表示されます。マージリクエストが必須の承認を受けると、次の理由でブロックされない限り、マージの準備が整います。

- [マージコンフリクト](../conflicts.md)
- [未解決のスレッド](../_index.md#prevent-merge-unless-all-threads-are-resolved)
- [CI/CDパイプラインの失敗](../auto_merge.md)

### 作成者による承認を防止する

マージリクエストの作成者が自分の作業を承認できないようにするには、[作成者自身による承認を防止します。](settings.md#prevent-approval-by-author)の設定を有効にします。

### 承認ルールを変更する

[承認ルールを上書きする](settings.md#prevent-editing-approval-rules-in-merge-requests)を有効にした場合、デフォルトの承認ルールへの変更は、[ターゲットブランチ](rules.md#approvals-for-protected-branches)の変更を除き、既存のマージリクエストへの影響はありません。

## 無効なルール

{{< history >}}

- GitLab 15.1で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/334698)されました。
- GitLab 15.11で、`invalid_scan_result_policy_prevents_merge`という名前の[フラグ](../../../../administration/feature_flags.md)で[変更](https://gitlab.com/gitlab-org/gitlab/-/issues/389905)されました。デフォルトでは無効になっています。
- GitLab 16.2で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/405023)になりました。機能フラグ`invalid_scan_result_policy_prevents_merge`が削除されました。

{{< /history >}}

GitLabは、次のような承認ルールが満たせない場合に、その承認ルールを**自動承認**としてマークします。

- 対象となる承認者がマージリクエストの作成者のみである。
- 対象となる承認者がルールに割り当てられていない。
- 必須の承認数が、対象となる承認者の数を超えている。

[マージリクエスト承認ポリシー](../../../application_security/policies/merge_request_approval_policies.md)を通じてルールを作成した場合を除き、これらのルールは自動的に承認され、マージリクエストのブロックが解除されます。

無効なポリシー作成ルール:

- **アクションが必要**として表示されます。
- 自動的に承認されません。
- 影響を受けるマージリクエストをブロックします。

## 関連トピック

- [マージリクエスト承認API](../../../../api/merge_request_approvals.md)
- GitLab Self-Managedインスタンスの[インスタンス承認ルール](../../../../administration/merge_requests_approvals.md)
- [レポーターロールを持つユーザーの承認権限を有効にする](rules.md#enable-approval-permissions-for-users-with-the-reporter-role)
- [マージリクエスト承認ルールを編集または上書きする](rules.md#edit-or-override-merge-request-approval-rules)
