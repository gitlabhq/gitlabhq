---
stage: AI-powered
group: Agent Foundations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: デベロッパーフロー
---

{{< details >}}

- プラン: Premium、Ultimate
- アドオン: GitLab Duo Core、Pro、またはEnterprise
- 提供形態: GitLab.com、GitLab Self-Managed

この機能は[GitLabクレジット](../../../../subscriptions/gitlab_credits.md)を使用します。

{{< /details >}}

{{< history >}}

- GitLab 18.3で`duo_workflow_in_ci`[フラグ](../../../../administration/feature_flags/_index.md)とともに[ベータ版](../../../../policy/development_stages_support.md)として導入されました。デフォルトでは無効になっていますが、インスタンスまたはユーザーに対して有効にすることができます。
- 18.6で`duo_developer_button`フラグが導入され、`Issue to MR`から`Developer Flow`に名前が変更されました。デフォルトでは無効になっていますが、インスタンスまたはユーザーに対して有効にすることができます。
- `duo_workflow`フラグも有効にする必要がありますが、これはデフォルトで有効になっています。
- GitLab 18.8で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/work_items/585273)になりました。
- フィーチャフラグ`duo_workflow_in_ci`はGitLab 18.9で削除されました。

{{< /history >}}

{{< alert type="flag" >}}

この機能の利用可否は、機能フラグによって制御されます。詳細については、履歴を参照してください。

{{< /alert >}}

デベロッパーフローは、イシューを実行可能なマージリクエストに変換するプロセスを効率化します。このフローには次の特長があります:

- イシューの説明と要件を分析します。
- 元のイシューにリンクされているドラフトマージリクエストをオープンします。
- イシューの詳細に基づいて開発計画を作成します。
- コードの構造または実装を作成します。
- コードの変更内容をマージリクエストに反映します。

このフローは、GitLab UIでのみ使用できます。

> [!note] デベロッパーフローは、サービスアカウントを使用してマージリクエストを作成します。SOC 2、SOX法、ISO 27001、またはFedRAMPの要件がある組織は、適切なピアレビューポリシーが整備されていることを確認してください。詳細については、[マージリクエストに関するコンプライアンス上の考慮事項](../../composite_identity.md#compliance-considerations-for-merge-requests)を参照してください。

## 前提条件 {#prerequisites}

イシューからマージリクエストを作成するには、次の要件を満たしている必要があります:

- 明確な要件を持つ既存のGitLabイシューが存在する。
- プロジェクトのデベロッパーロール以上を持っている。
- [他の前提条件](../../../duo_agent_platform/_index.md#prerequisites)を満たしている。
- [GitLab Duoサービスアカウントがコミットとブランチを作成できることを確認している](../../troubleshooting.md#session-is-stuck-in-created-state)。
- デベロッパーフローが[オンになっている](../../../gitlab_duo/turn_on_off.md#turn-gitlab-duo-on-or-off)。

## フローを使用する {#use-the-flow}

イシューをマージリクエストに変換するには:

1. 上部のバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **計画** > **イシュー**を選択します。
1. マージリクエストを作成するイシューを選択します。
1. イシューヘッダーの下にある**GitLab Duoでマージリクエストを生成**を選択します。
1. **自動化** > **セッション**を選択して、進捗状況を監視します。
1. パイプラインが正常に実行されると、イシューのアクティビティーセクションにマージリクエストへのリンクが表示されます。
1. マージリクエストをレビューし、必要に応じて変更を加えます。

## ベストプラクティス {#best-practices}

- イシューのスコープを適切に維持する。複雑なタスクは、より小さく、スコープが絞られた、アクション指向のリクエストに分割してください。
- 正確なファイルパスを指定する。
- 具体的な受け入れ基準を記述する。
- 一貫性を保つため、既存パターンのコード例を含める。

## 例 {#example}

次の例は、マージリクエストの生成に使用できる、適切に作成されたイシューを示しています。

```plaintext
## Description
The users endpoint currently returns all users at once,
which will cause performance issues as the user base grows.
Implement cursor-based pagination for the `/api/users` endpoint
to handle large datasets efficiently.

## Implementation plan
Add pagination to GET /users API endpoint.
Include pagination metadata in /users API response (per_page, page).
Add query parameters for per page size limit (default 5, max 20).

#### Files to modify
- `src/api/users.py` - Add pagination parameters and logic.
- `src/models/user.py` - Add pagination query method.
- `tests/api/test_users_api.py` - Add pagination tests.

## Acceptance criteria
- Accepts page and per_page query parameters (default: page=5, per_page=10).
- Limits per_page to a maximum of 20 users.
- Maintains existing response format for user objects in data array.
```
