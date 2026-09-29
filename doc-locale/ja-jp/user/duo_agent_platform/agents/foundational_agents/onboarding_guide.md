---
stage: Agent Foundations
group: AI Catalog
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
gitlab_dedicated: no
title: オンボーディングエージェント
---

{{< details >}}

- プラン: Premium、Ultimate
- アドオン: GitLab Duo
- 提供形態: GitLab.com、GitLab Self-Managed
- ステータス: 実験的機能

{{< /details >}}

{{< history >}}

- GitLab 19.4で`onboarding_guide_agent`[機能フラグ](../../../../administration/feature_flags/_index.md)とともに[実験的機能](../../../../policy/development_stages_support.md#experiment)として[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/245452)されました。デフォルトでは無効になっています。

{{< /history >}}

オンボーディングエージェントは、GitLab DevSecOpsプラットフォームのセットアップを支援します。エージェントは、プロジェクトのコンテキストとサブスクリプションプランを読み取り、機能の説明、次の導入ステップの推奨、設定例（たとえば、`.gitlab-ci.yml`）を提供します。

オンボーディングエージェントは、GitLab Duo Chatでのみ応答を提供します。ファイル、パイプライン、プロジェクト設定を変更しません。エージェントは、作業アイテム、イシュー、およびエピックを作成および更新し、イシューと作業アイテムにコメントを追加できます。各アクションの前に、エージェントは正確な内容を表示し、承認を待ちます。

オンボーディングエージェントを以下の場合に使用します:

- 初めてチームまたはプロジェクトをセットアップする場合。
- GitHub、Bitbucket、またはJenkinsから移行し、既存のワークフローをGitLabにマップする場合。
- セキュリティスキャン、コンプライアンス、またはエージェント型ワークフローなど、プラットフォームのより多くの機能を導入する場合。
- 自分のプランに含まれる機能、または次に設定すべき機能を確認する場合。

## 前提条件 {#prerequisites}

オンボーディングエージェントを使用する前に:

- 基本エージェントを[オンにする](_index.md#turn-foundational-agents-on-or-off)。
- [ベータ版および実験的機能をオンにする](../../turn_on_off.md#turn-on-beta-and-experimental-features)。

## オンボーディングエージェントの使用 {#use-the-onboarding-agent}

1. 上部のバーで、**検索または移動先**を選択して、プロジェクトまたはグループを見つけます。
1. GitLab Duoサイドバーで、**新しいチャットを追加**（{{< icon name="pencil-square" >}}）を選択します。
1. ドロップダウンリストから、**オンボーディングエージェント**を選択します。

   画面右側のGitLab Duoサイドバーに、Chatの会話が表示されます。
1. 支援が必要な内容を記述します。最良の結果を得るには:
   - 同じ会話で追加の質問をします。エージェントはセッションのコンテキストを記憶し、それを使用して指示を提供します。
   - 特定のステージ（例: セキュリティまたはコンプライアンス）を探索したいかどうかを明確にします。
   - エージェントからの設定の提案を、自分のプロジェクトに適用する前にレビューします。

エージェントは、応答する前に現在のプロジェクトとプランからコンテキストを収集し、コンテキスト固有の指示を提供します。

## プロンプトの例 {#example-prompts}

これらのプロンプトを使用して開始します:

- `Help me get started with GitLab.`
- `I'm migrating from GitHub — where should I begin?`
- `Set up security scanning for this project.`
- `What should I do next to get more value out of GitLab?`
- `What features am I missing on my current tier?`
- `Help me convert my Jenkins pipeline to GitLab CI/CD.`
- `Help me get started with compliance frameworks.`（Ultimate）

## 既知の問題 {#known-issues}

- エージェントはGitLab Duo Chat UIとIDEでのみ動作します。このエージェントの[トリガー](../../triggers/_index.md)を作成することはできません。
- エージェントは、ファイルを作成、編集、またはコミットしたり、パイプラインを変更したり、プロジェクト設定を変更したりしません。各アクションの承認後、作業アイテム、イシュー、およびエピックを作成および更新し、イシューと作業アイテムにコメントを追加できます。
- エージェントは、脆弱性、セキュリティ検出結果、パイプラインエラー、またはジョブログを読み取ることができません。関連する出力を求め、セキュリティ分析エージェントまたはCIエキスパートエージェントを案内する場合があります。他のエージェントに委任することはできません。
- エージェントはプロジェクトとページのコンテキストを使用しますが、特定の機能がプロジェクトで有効になっているかどうかを常に検出できるとは限りません。
- Agent Platformの使用状況は、[GitLab DuoとSDLCのトレンドダッシュボード](../../../analytics/duo_and_sdlc_trends.md)で集計して報告されます。個々のエージェントの使用状況はまだ確認できません。

## フィードバックを提供する {#give-feedback}

このエージェントは実験的機能であり、皆様のフィードバックが改善に役立ちます。経験を共有したり問題を報告したりするには、[イシュー606350](https://gitlab.com/gitlab-org/gitlab/-/issues/606350)にコメントを追加してください。

## 関連トピック {#related-topics}

- [基本エージェント](_index.md)
- [GitLab Duo Agent Platform](../../_index.md)
