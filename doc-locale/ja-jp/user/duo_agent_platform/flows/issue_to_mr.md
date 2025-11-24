---
stage: AI-powered
group: Agent Foundations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: イシューからマージリクエストへのフロー
---

{{< details >}}

- プラン: Premium、Ultimate
- アドオン: GitLab Duo Core、Pro、またはEnterprise。
- 提供形態: GitLab.com、GitLab Self-Managed
- ステータス: ベータ

{{< /details >}}

{{< history >}}

- GitLab 18.3で`duo_workflow_in_ci`[フラグ](../../../administration/feature_flags/_index.md)とともに[ベータ](../../../policy/development_stages_support.md)として導入されました。デフォルトでは無効になっていますが、インスタンスまたはユーザーに対して有効にできます。
- `duo_workflow`フラグも有効にする必要がありますが、デフォルトで有効になっています。

{{< /history >}}

{{< alert type="flag" >}}

この機能の利用可否は、機能フラグによって制御されます。詳細については、履歴を参照してください。

{{< /alert >}}

イシューからマージリクエストへのフローは、イシューを実行可能なマージリクエストに変換するプロセスを効率化します。このフローの内容:

- イシューの説明と要件を分析します。
- 元のイシューにリンクされているドラフトマージリクエストを開きます。
- イシューの詳細に基づいて開発計画を作成します。
- コード構造または実装を作成します。
- コード変更でマージリクエストを更新します。

このフローは、GitLabユーザーインターフェースでのみ使用できます。

## 前提要件 {#prerequisites}

イシューからマージリクエストを作成するには、以下が必要です:

- 明確な要件を備えた既存のGitLabイシューが必要です。
- プロジェクトで少なくともデベロッパーロールが必要です。
- [その他の前提条件](../../duo_agent_platform/_index.md#prerequisites)を満たしていること。

## フローを使用する {#use-the-flow}

イシューをマージリクエストに変換するには:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. 左側のサイドバーで**Plan** > **イシュー**を選択します。
1. マージリクエストを作成するイシューを選択します。
1. イシューヘッダーの下にある**Duoでマージリクエストを生成**を選択します。
1. **自動化** > **セッション**を選択して、進行状況を監視します。
1. パイプラインが正常に実行されると、マージリクエストへのリンクがイシューのアクティビティーセクションに表示されます。
1. マージリクエストをレビューし、必要に応じて変更を加えます。

## ベストプラクティス {#best-practices}

- イシューのスコープを適切に維持します。複雑なタスクを、より小さく、焦点を絞った、アクション指向のリクエストに分解します。
- 正確なファイルパスを指定します。
- 特定の承認基準を記述します。
- 既存のパターンのコード例を含めて、一貫性を維持します。

## 例 {#example}

この例は、マージリクエストの生成に使用できる、適切に作成されたイシューを示しています。

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
