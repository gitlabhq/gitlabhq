---
stage: AI-powered
group: Workflow Catalog
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Support Assistant
---

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- ステータス: ベータ版

{{< /details >}}

{{< history >}}

- GitLab 19.2で[ベータ版](../../../../policy/development_stages_support.md#beta)として[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/237380)されました。

{{< /history >}}

Support Assistantは、次のような用途に役立つ特殊なエージェントです:

- どこから始めればよいか分からないGitLab製品の問題を診断する。
- 特定の機能領域に関するトラブルシューティングのドキュメントを見つける。
- 問題が既知のイシューであるかどうかを確認する。
- 人間にエスカレートする必要がある場合に、関連する診断情報を含むサポートチケットを作成する。

Support AssistantはGitLabの問題の診断に役立ちます。その他の問題については、Support Assistantが適切なチームに誘導しようとします。

Support Assistantの詳細については、[エージェントの設定YAMLファイル](https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/-/blob/main/duo_workflow_service/agent_platform/v1/flows/configs/support_assistant/1.0.0.yml)を参照してください。

## Support Assistantを使用する {#use-the-support-assistant}

前提条件: 

- [基本エージェントをオンにする](_index.md#turn-foundational-agents-on-or-off)。
- [ベータ版機能と実験的機能をオンにする](../../turn_on_off.md#turn-on-beta-and-experimental-features)。

Support Assistantを使用するには:

1. 上部のバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. GitLab Duoサイドバーで、**新しいチャットを追加** ({{< icon name="pencil-square" >}}) を選択します。
1. ドロップダウンリストから、**Support Assistant**を選択します。

   画面右側のGitLab Duoサイドバーに、Chatの会話が表示されます。
1. GitLabの問題を自分の言葉で説明し、エージェントが原因を診断する際に、追加の質問に答えてください。リクエストから最良の結果を得るには、次の点に留意してください:

   - 症状と影響から始めます。例えば、「今朝からビルドが失敗し続けており、すべてのマージがブロックされている」という表現は、「CIが壊れている」と言うよりも多くの情報を提供します。
   - 正確なエラーメッセージ（削除済みのシークレットを含む）と、もしあればエラーコードを含めます。
   - すでに試したことを伝えてください。エージェントが同じことを再度提案しないようにするためです。
   - 環境を早めに伝えてください: GitLab.com SaaS、GitLab Self-Managed (LinuxパッケージやHelmチャートなどのインストールタイプ)、またはGitLab Dedicated、およびバージョン。
   - 緊急性を知らせます。それが本番環境の停止である場合は、その旨を伝えれば、エージェントは直ちに緊急チケットの作成に移ります。
   - 診断に集中できるよう、会話ごとに問題を1つに絞ってください。

### プロンプトの例 {#example-prompts}

- 「私のパイプラインは、明確なエラーなしに断続的に失敗し続けます。どこから始めればよいですか？」
- 「依存関係スキャンが、私のプロジェクトの脆弱性をレポートしません。」
- 「パーソナルアクセストークンを使用してAPIを呼び出すと、403エラーが発生します。」
- 「当社のGeoセカンダリは、プライマリから大幅に遅れています。これは既知のイシューですか？」
- 「Gitalyのパフォーマンス低下に関するサポートチケットをオープンする必要があります。何を含めるべきですか？」
- 「HelmベースのGitLab Self-Managedインストールの場合、どの診断アーカイブを収集すればよいですか？」
