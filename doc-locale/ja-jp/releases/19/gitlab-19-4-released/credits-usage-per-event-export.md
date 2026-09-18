---
title: クレジット使用状況エクスポートのイベント別詳細
tier: [ Premium, Ultimate ]
offering: [ gitlab_com, self_managed, gitlab_dedicated ]
stage: fulfillment
documentation_link: "../../../subscriptions/gitlab_credits_dashboard/#export-usage-data"
work_item: https://gitlab.com/gitlab-org/customers-gitlab-com/-/work_items/18963
categories: [ Consumables Cost Management ]
level: secondary
---

クレジット使用状況エクスポートでは、1日1行のデータが提供されていました。これにより、サブスクリプションの消費量は把握できましたが、何に使用されたかは分かりませんでした。クレジットをチーム、プロジェクト、または特定の自動化処理に紐付けるには、推測に頼るしかありませんでした。

エクスポートは2つのCSVファイルを含むZIPファイルとして出力されるようになりました。1つは従来の日次サマリー、もう1つは請求対象イベントごとに1行を含むイベント別ファイルです。各行には、製品、フロータイプ、セッション、ユーザー、ネームスペース、プロジェクト、使用クレジット数、トークン数が含まれます。エクスポートはバックグラウンドで実行され、ファイルの準備が完了するとGitLabからダウンロードリンクがメールで送信されます。
