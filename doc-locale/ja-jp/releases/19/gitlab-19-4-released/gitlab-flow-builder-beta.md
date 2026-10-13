---
title: カスタムフロー用GitLabフロービルダー（ベータ版）
tier: [ Free, Premium, Ultimate ]
offering: [ gitlab_com, self_managed, gitlab_dedicated ]
stage: ai_clients
documentation_link: "../../../user/duo_agent_platform/flows/custom/#create-a-flow"
work_item: https://gitlab.com/groups/gitlab-org/editor-extensions/-/work_items/236
categories: [ AI Catalog Creation ]
level: secondary
weight: 50
---

GitLab for VS Code拡張機能に搭載された新しいビジュアルエディタ「GitLabフロービルダー」を使用して、GitLabプロジェクト用のカスタムフローを構築できます。
コンポーネント（エージェント、カスタムツール、AIタスク）を視覚的に組み合わせてフローを作成するか、基盤となるYAMLを直接編集することができます。

開始するには、VS CodeでフローのYAMLファイルを開き、**GitLabフロービルダーを開く**を選択します。
**実行**ボタンでフローをテストすると、実行コンソールが開きます。
フローの準備ができたら、**公開**を選択してAIカタログに公開します。

フロービルダーは、GitLab for VS Code 6.87.0以降でベータ版機能として利用できます。使用を開始するには、VS Codeで`gitlab.featureFlags.flowBuilder`設定を有効にしてください。
