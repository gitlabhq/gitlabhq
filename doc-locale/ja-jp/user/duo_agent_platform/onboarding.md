---
stage: AI-powered
group: AI Coding
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: GitLab Duo Agent Platformのプロジェクトオンボーディング 
---

{{< details >}}

- プラン: [Free](../../subscriptions/gitlab_credits.md#for-the-free-tier)、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 19.0でプロジェクトコンテキストの初期化が`duo_agent_onboarding`[フラグ](../../administration/feature_flags/_index.md)とともに[ベータ](../../policy/development_stages_support.md)版として[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/229847)されました。デフォルトでは無効になっています。
- GitLab 19.1でCIセットアップの改善が`duo_agent_onboarding`[フラグ](../../administration/feature_flags/_index.md)とともに[ベータ](../../policy/development_stages_support.md)版として[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/234426)されました。デフォルトでは無効になっています。

{{< /history >}}

> [!flag]
> この機能の利用可否は、機能フラグによって制御されます。詳細については、履歴を参照してください。

**オンボーディング**ページは、GitLab Duo Agent Platformで使用するプロジェクトの設定を支援します。このページから、プロジェクトコンテキストを初期化し、AIエージェントを使用してCI/CDのセットアップを改善できます。

## 前提条件 {#prerequisites}

- プロジェクトのデベロッパー、メンテナー、またはオーナーロール。
- The [GitLab Duo Agent Platform](_index.md#prerequisites)の前提条件。
- **Improve CI setup**タスクの場合は、プロジェクト内の`.gitlab-ci.yml`ファイル。

## プロジェクトコンテキストを初期化する {#initialize-project-context}

**Initialize project context**タスクは、リポジトリを分析し、プロジェクト用の`AGENTS.md`ファイルを作成します。 

このファイルは[`AGENTS.md`仕様](https://agents.md/)に従い、テストコマンド、Lintルール、コミットフォーマット、コードパターンなど、プロジェクトの慣例をドキュメント化します。Agent Platformの機能は、リポジトリで作業する際のコンテキストとしてこれを使用します。

プロジェクトコンテキストを初期化するには:

1. 上部のバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. 左サイドバーで、**自動化** > **Onboarding**を選択します。
1. **Initialize project context**を選択します。`AGENTS.md`または`.ai/AGENTS.md`がデフォルトブランチに既に存在する場合、このオプションは利用できません。

GitLabは、`developer/v1`エージェントセッションを開始し、リポジトリを分析して、`AGENTS.md`ファイルを追加するドラフトマージリクエストを開きます。エージェントセッションへのリンクが表示され、進捗を追跡することができます。

## CI/CDセットアップを改善する {#improve-cicd-setup}

**Improve CI setup**タスクは、既存のCI/CD設定を分析し、改善を提案するエージェントを起動します。

CI/CDセットアップを改善するには:

1. 上部のバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. 左サイドバーで、**自動化** > **Onboarding**を選択します。
1. **Improve CI setup**を選択します。`.gitlab-ci.yml`がデフォルトブランチに存在しない場合、このオプションは利用できません。

GitLabは、`.gitlab-ci.yml`を分析し、提案された改善を含むドラフトマージリクエストを開くエージェントセッションを開始します。エージェントセッションへのリンクが表示され、進捗を追跡することができます。

## 関連トピック {#related-topics}

- [AGENTS.mdカスタマイズファイル](customize/agents_md.md)
- [デベロッパーフロー](flows/foundational_flows/developer.md)
- [CI/CDパイプライン修正フロー](flows/foundational_flows/fix_pipeline.md)
