---
title: GitLab Dedicated向けAIゲートウェイ
tier: [ Ultimate ]
offering: [ gitlab_dedicated ]
stage: gitlab_dedicated
documentation_link: "../../../administration/gitlab_duo_self_hosted/supported_llm_serving_platforms/#configure-authentication-with-aws-bedrock"
work_item: https://gitlab.com/gitlab-com/gl-infra/gitlab-dedicated/team/-/work_items/13486
categories: [ GitLab Dedicated ]
level: secondary
---

GitLab Dedicated向けAIゲートウェイは、GitLab DedicatedインスタンスとAWSの同一リージョン内のAWS環境で動作します。コード入力、プロンプト、モデルレスポンスを含む推論リクエストは、お客様のネットワークおよびリージョン内に留まります。GitLab Duo Agent Platformの推論リクエストはすべて、GitLab Dedicatedインスタンスと同じ監査スコープ内で処理されます。GitLab Dedicated向けAIゲートウェイはデフォルトで有効になっており、セットアップは不要です。

オプションとして、Bring Your Own Model（BYOM）を使用して、独自のクラウドホスト型モデルに接続することもできます。お客様が選択したモデルを使用して、お客様のリージョンおよびアクセス制御のもとで、GitLab Duo Agent Platformの機能を活用できます。
