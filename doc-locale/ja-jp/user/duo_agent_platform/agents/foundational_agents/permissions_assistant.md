---
stage: AI-powered
group: Workflow Catalog
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Permissions Assistant
---

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- ステータス: ベータ版

{{< /details >}}

{{< history >}}

- GitLab 18.11で[導入された](https://gitlab.com/gitlab-org/gitlab/-/work_items/592230) [ベータ](../../../../policy/development_stages_support.md#beta)機能。

{{< /history >}}

Permissions Assistantは、GitLab Duoのエージェントであり、パーソナルアクセストークンを作成する際に、適切な[詳細権限](../../../../auth/tokens/fine_grained_access_tokens.md)を選択するのに役立ちます。

トークンに何を実行させる必要があるかを説明すると、Permissions Assistantが作成フォームで適切な権限を選択します。選択がニーズと一致するまで、追加の質問をしたり、リクエストを調整したりできます。

## 前提条件 {#prerequisites}

- [GitLab Duo Agent Platformの前提条件](../../_index.md#prerequisites)を満たしていること。
- [基本エージェントがオンになっている](_index.md#turn-foundational-agents-on-or-off)必要があります。
- 詳細権限パーソナルアクセストークンが有効になっている必要があります。この機能は、`granular_personal_access_tokens`機能フラグに依存しており、GitLab.comではデフォルトで有効になっています。GitLab DedicatedとGitLab Self-Managedでは、管理者が[有効にする](../../../../administration/feature_flags/_index.md)必要があります。

## Permissions Assistantの使用 {#use-the-permissions-assistant}

Permissions Assistantは、GitLab UIの詳細権限パーソナルアクセストークン作成ページで利用できます。

Permissions Assistantを使用するには:

1. 右上隅で、アバターを選択します。
1. **プロファイルを編集**を選択します。
1. 左サイドバーで、**アクセス** > **パーソナルアクセストークン**を選択します。
1. **トークンを生成**ドロップダウンリストから、**きめ細やかな権限のトークン**を選択します。
1. **Duoで権限を追加する**を選択します。

   Permissions Assistantが事前に選択されたDuo Chatパネルが開きます。
1. トークンに実行させたい内容を説明するか、提案されたプロンプトのいずれかを選択します。

   Permissions Assistantは、フォームで適切な権限を選択します。
1. 選択された権限をレビューし、必要に応じてリクエストを調整します。
1. 残りのトークンフィールドを完了し、**トークンを生成**を選択します。

### 最高の結果を得るためのヒント {#tips-for-best-results}

- 具体的にユースケースを記述してください。例えば、「単一のプロジェクトでイシューを読み取り、マージリクエストを作成する必要がある」は、「APIアクセスが必要」よりも良い結果をもたらします。
- 最初の選択が広すぎるか狭すぎる場合は、調整を依頼してください。
- ニーズの記述方法が不明な場合は、提案されたプロンプトを開始点として使用してください。

## プロンプトの例 {#example-prompts}

- 「API経由でリポジトリを読み書きしたい。」
- 「CI/CDパイプラインを管理し、ジョブログを読み取る必要がある。」
- 「イシューとマージリクエストの管理を自動化したい。」
- 「プロジェクトとグループへの読み取り専用アクセスが必要。」
