---
title: マージリクエスト作成イベントトリガー
tier: [ Premium, Ultimate ]
offering: [ gitlab_com, self_managed, gitlab_dedicated ]
stage: ai_coding
documentation_link: "../../../user/duo_agent_platform/triggers/"
work_item: https://gitlab.com/groups/gitlab-org/-/work_items/22279
categories: [ DAP Triggers ]
level: secondary
weight: 50
---

以前のバージョンのGitLabでは、**マージリクエスト**トリガーイベントタイプは**承認済み**、**レビュー準備完了**、**マージコンフリクト**のアクションのみをサポートしていました。GitLab外のツールを使用せずに、誰かがマージリクエストを開いた瞬間にフローや外部エージェントを実行する方法はありませんでした。

**作成済み**をトリガーアクションとして選択できるようになりました。誰かがドラフトまたはレビュー準備完了の状態でマージリクエストを開き、GitLabが差分を生成すると、フローまたは外部エージェントが実行されます。最初のレビューや、関連するイシューからのコンテキスト追加にご活用ください。

このトリガーを設定するには、プロジェクトの**AI > トリガー**に移動するか、フローを有効にする際に選択してください。
