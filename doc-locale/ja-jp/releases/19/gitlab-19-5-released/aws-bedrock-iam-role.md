---
title: Amazon BedrockセルフホストモデルのIAMロール
tier: [ Premium, Ultimate ]
offering: [ self_managed, gitlab_dedicated ]
stage: ai_platform
documentation_link: "../../../administration/gitlab_duo_self_hosted/supported_llm_serving_platforms/#assume-an-iam-role-with-aws-bedrock"
work_item: https://gitlab.com/gitlab-org/gitlab/-/work_items/542393
categories: [ Model Selection ]
level: secondary
weight: 50
---

以前は、AIゲートウェイがAmazon Bedrockモデルに使用するAWS認証情報を制御できませんでした。
すべてのモデルへのアクセスに、単一のAWSアイデンティティが必要でした。

今回のリリースで、モデルごとにIAMロールを指定できるようになりました。
AIゲートウェイはモデルを呼び出す際にそのロールを引き受けます。
これにより、ロールが別のAWSアカウントにある場合でも、各モデルに必要なAWSアクセス権のみを付与できます。
