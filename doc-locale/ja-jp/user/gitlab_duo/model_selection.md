---
stage: AI-powered
group: Custom Models
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: GitLab Duo機能の大規模言語モデルを設定する。
title: GitLab Duo AIモデル
---

{{< details >}}

- プラン: Premium、Ultimate
- アドオン: GitLab Duo Core、Pro、またはEnterprise
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

すべてのGitLab Duo機能は、デフォルトモデルを使用します。GitLabは、パフォーマンスを最適化するためにデフォルトモデルを更新する可能性があります。機能を対象とした別のモデルを選択でき、それは変更するまで保持されます。

## デフォルトモデル {#default-models}

次の表は、各GitLab Duo機能のデフォルトモデルを一覧表示しています。

| 機能 | モデル |
|---------|---------------|
| **コード提案** | |
| コード生成 | Claude Sonnet 4 Vertex |
| コード補完 | Codestral 25.08 Fireworks |
| **GitLab Duo Chat** | |
| 一般チャット | Claude Sonnet 4.5 Vertex |
| コード説明 | Claude Sonnet 4 |
| テスト生成 | Claude Sonnet 4.5 Vertex |
| コードのリファクタリング | Claude Sonnet 4.5 Vertex |
| コード修正 | Claude Sonnet 4.5 Vertex |
| 根本原因分析 | Claude Sonnet 4 Vertex |
| **マージリクエストのためのGitLab Duo** | |
| マージコミットメッセージ生成 | Claude Sonnet 4 Vertex|
| マージリクエストサマリー | Claude Sonnet 4 Vertex |
| コードレビューサマリー | Claude Sonnet 4 Vertex |
| コードレビュー | Claude Sonnet 4.6 Vertex |
| **GitLab Duoのその他の機能** | |
| 脆弱性の説明 | Claude Sonnet 4.5 Vertex |
| 脆弱性の修正 | Claude Sonnet 4.5 |
| ディスカッションサマリー | Claude Sonnet 4.5 Vertex |
| GitLab Duo for CLI | Claude Haiku 4.5 |

## サポートされているモデル {#supported-models}

次の表は、各機能に選択できるモデルを一覧表示しています。

### コード提案 {#code-suggestions}

| モデル | コード生成 | コード補完 |
|------------|-----------------|-----------------|
| Claude Sonnet 4 | {{< yes >}} | {{< yes >}} |
| Claude Sonnet 4 Vertex | {{< yes >}} | {{< yes >}} |
| Claude Sonnet 4 Bedrock | {{< yes >}} | {{< yes >}} |
| Claude Sonnet 4.5 | {{< yes >}} | {{< yes >}} |
| Codestral 25.01 Fireworks | {{< no >}} | {{< yes >}} |
| Codestral 25.08 Fireworks | {{< no >}} | {{< yes >}} |
| Codestral 25.08 Vertex | {{< no >}} | {{< yes >}} |
| Gemini 2.5 Flash Vertex | {{< yes >}} | {{< no >}} |

### GitLab Duo非エージェント型チャット {#gitlab-duo-non-agentic-chat}

| モデル | 一般チャット | コード説明 | テスト生成 | コードのリファクタリング | コード修正 | 根本原因分析 |
|------------|--------------|------------------|-----------------|---------------|----------|---------------------|
| Claude Haiku 4.5 | {{< yes >}} | {{< no >}} | | | {{< no >}} | |
| Claude Sonnet 3 | {{< no >}} | | | {{< no >}} | | {{< yes >}} |
| Claude Sonnet 4 | {{< yes >}} | {{< yes >}} | {{< yes >}} | {{< yes >}} | {{< yes >}} | {{< yes >}} |
| Claude Sonnet 4 Vertex | {{< yes >}} | {{< yes >}} | {{< yes >}} | {{< yes >}} | {{< yes >}} | {{< yes >}} |
| Claude Sonnet 4.5 | {{< yes >}} | {{< yes >}} | {{< yes >}} | {{< yes >}} | {{< yes >}} | {{< yes >}} |
| Claude Sonnet 4.5 Vertex | {{< yes >}} | {{< yes >}} | {{< yes >}} | {{< yes >}} | {{< yes >}} |  |

### GitLab Duo forマージリクエスト {#gitlab-duo-for-merge-requests}

| モデル | マージコミットメッセージ生成 | マージリクエストサマリー | コードレビューサマリー | コードレビュー |
|------------|--------------------------------|------------------------|---------------------|-------------|
| Claude Sonnet 4 | {{< yes >}} | {{< yes >}} | {{< yes >}} | {{< yes >}} |
| Claude Sonnet 4 Vertex | {{< yes >}} | {{< yes >}} | {{< yes >}} | {{< yes >}} |
| Claude Sonnet 4.5 | {{< yes >}} | {{< yes >}} | {{< yes >}} | {{< yes >}} |

### その他のGitLab Duo機能 {#other-gitlab-duo-features}

| モデル | 脆弱性の説明 | 脆弱性の修正 | GitLab Duo for CLI | ディスカッションサマリー |
|------------|----------------------------|--------------------------|-------------------|---------------------|
| Claude Haiku 3 | {{< yes >}} | {{< no >}} | {{< yes >}} | {{< no >}} |
| Claude Haiku 4.5 | {{< no >}} | | {{< yes >}} | {{< no >}} |
| Claude Sonnet 4 |  | {{< yes >}} | {{< yes >}} | {{< yes >}} |
| Claude Sonnet 4 Vertex | {{< yes >}} |  | {{< yes >}} | {{< yes >}} |
| Claude Sonnet 4.5 | {{< yes >}} | {{< yes >}} | {{< yes >}} | {{< yes >}} |
| Claude Sonnet 4.5 Vertex | {{< yes >}} |  |  | {{< yes >}} |

## 機能のモデルを選択する {#select-a-model-for-a-feature}

{{< details >}}

- 提供形態: GitLab.com

{{< /details >}}

{{< history >}}

- `ai_model_switching`[フラグ](../../administration/feature_flags/_index.md)とともに、GitLab 18.1でトップレベルグループ向けに[導入](https://gitlab.com/groups/gitlab-org/-/epics/17570)されました。デフォルトでは無効になっています。
- GitLab 18.4でベータ版に[変更](https://gitlab.com/gitlab-org/gitlab/-/issues/526307)されました。
- GitLab 18.4で[有効](https://gitlab.com/gitlab-org/gitlab/-/issues/526307)になりました。
- GitLab 18.5で[一般提供](https://gitlab.com/groups/gitlab-org/-/epics/18818)になりました。機能フラグ`ai_model_switching`が有効になりました。
- GitLab 18.7で機能フラグ`ai_model_switching`が[削除](https://gitlab.com/gitlab-org/gitlab/-/issues/526307)されました。

{{< /history >}}

トップレベルグループの機能のモデルを選択できます。選択したモデルは、その機能に対して、すべての子グループとプロジェクトに適用されます。

前提条件: 

- グループのオーナーロールを持っている。
- モデルを選択するグループがトップレベルグループである。
- GitLab 18.3以降で、複数のGitLab Duoネームスペースに属している場合は、[デフォルトのネームスペースを割り当てる](../profile/preferences.md#set-a-default-gitlab-duo-namespace)必要があります。

機能のモデルを選択するには:

1. 上部のバーで、**検索または移動先**を選択して、グループを見つけます。
1. **設定** > **GitLab Duo**を選択します。
1. **機能を設定**を選択します。
1. 設定したい機能について、ドロップダウンリストからモデルを選択します。
1. オプション。セクション内のすべての機能にモデルを適用するには、**すべてに適用**を選択します。

## トラブルシューティング {#troubleshooting}

デフォルト以外のモデルを選択すると、次の問題が発生する可能性があります。

### モデルが利用できない {#model-is-not-available}

GitLab Duo AIネイティブ機能にデフォルトのGitLabモデルを使用している場合、GitLabは、最適なパフォーマンスと信頼性を維持するために、ユーザーに通知せずにデフォルトモデルを変更する場合があります。

GitLab Duo AIネイティブ機能に特定のモデルを選択していて、そのモデルが利用できない場合、自動フォールバックはありません。このモデルを使用する機能は使用できません。

### デフォルトのGitLab Duoネームスペースが設定されていない {#no-default-gitlab-duo-namespace}

選択したモデルでGitLab Duo機能を使用している場合、デフォルトのGitLab Duoネームスペースを設定する必要があることを示すエラーが発生する場合があります。

このイシューは、複数のGitLab Duoネームスペースに属している場合、またはGitLabリモートが設定されていないプロジェクトをローカルで作業している場合に発生します。

これを解決するには、[デフォルトのGitLab Duoネームスペースを設定](../profile/preferences.md#set-a-default-gitlab-duo-namespace)します。
