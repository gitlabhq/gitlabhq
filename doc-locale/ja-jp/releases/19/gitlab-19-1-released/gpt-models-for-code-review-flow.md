---
title: コードレビューフローのGPTモデル対応
offering: [ gitlab_com, self_managed, gitlab_dedicated ]
tier: [ Premium, Ultimate ]
stage: ai-powered
documentation_link: "../../../user/duo_agent_platform/model_selection/#supported-models"
work_item: https://gitlab.com/gitlab-org/gitlab/-/work_items/598322
categories: [ Duo Agent Platform, Duo Code Review ]
level: secondary
---

<!-- categories: Duo Agent Platform, Duo Code Review -->

これまでのGitLabでは、コードレビューフローはAnthropicのClaudeモデルのみをサポートしていました。契約上、ポリシー上、または調達上の制約によりAnthropicモデルを使用できないチームは、コードレビューフローを実行する手段がありませんでした。

コードレビューフローのモデルとして、GPT-5.2またはGPT-5.3 Codexを選択できるようになりました。トップレベルグループのオーナーは、**設定** > **GitLab Duo** > **機能の設定**から、**GitLab Duo Agent Platform**の**エージェント型コードレビュー**のモデルを切り替えられます。GPTモデルはGitLab AIゲートウェイを通じてホストされるため、追加の設定は不要です。

両モデルはGitLab Duoコードレビューデータセットを用いたベンチマーク評価に合格しており、デフォルトのClaude Sonnet 4.6 Vertexモデルと同等のレビュー品質を示しています。結果については、[コードレビューベンチマーク](https://duo-review-bench-6f7260.gitlab.io/)をご覧ください。
