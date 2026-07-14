---
title: フローと外部エージェントの新しいイベントトリガー
offering: [ gitlab_com, self_managed, gitlab_dedicated ]
tier: [ Premium, Ultimate ]
documentation_link: "../../../user/duo_agent_platform/triggers/#create-a-trigger"
categories: [ Duo Agent Platform ]
level: secondary
work_item: https://gitlab.com/groups/gitlab-org/-/work_items/21997
stage: ai-powered
---

<!-- categories: Duo Agent Platform -->

以前のバージョンのGitLabでは、サービスアカウントがメンションされた場合、割り当てられた場合、またはレビュアーとして追加された場合にのみ、フローと外部エージェントを実行できました。マージリクエストのライフサイクルの残りの部分や、作業アイテムの作成に関する自動化を調整するには、外部の連携ツールが必要でした。

現在は、4つの追加イベントに対してトリガーを設定できます。

- **マージリクエスト準備完了**: ユーザーがドラフトのマージリクエストをレビュー準備完了としてマークした場合。以前は機能フラグの後ろでリリースされていましたが、このイベントトリガーは現在一般提供されています。
- **マージリクエストコードコンフリクト**: コードコンフリクトにより、マージリクエストをマージできなくなった場合。
- **マージリクエスト承認済み**: マージリクエストが必要なすべての承認を受け取った場合。
- **作業アイテム作成済み**: ユーザーがプロジェクトに作業アイテムを作成した場合。

トリガーを設定するには、プロジェクトの **AI** > **トリガー** に移動するか、フローを有効にする際にトリガーを選択してください。
