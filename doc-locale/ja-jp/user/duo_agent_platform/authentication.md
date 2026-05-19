---
stage: AI-powered
group: Agent Foundations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitLab Duo Agent Platformの認証
---

GitLab Duo Agent Platformは、リクエストがモデルプロバイダーに到達する前に、マルチトークンの認証チェーンを使用します。

次の表に、トークンタイプと各トークンの存続時間 (TTL) を示します。

| トークン  | 発行者 | TTL    | 更新動作                                        |
|--------|--------|--------|---------------------------------------------------------|
| Cloud Connector JWT (自己署名) | GitLab Dedicatedインスタンス | 1時間  | 各リクエスト内。 |
| CustomersDotサービスアクセストークン | `customers.gitlab.com`    | 約3日 | 残り2日未満の場合、1時間ごとのcronで。 |
| OAuthアクセストークン                | GitLab Dedicatedインスタンス | 2時間  | 各ワークフロー内。                                 |
| GitLab Duo Workflow Service Internal JWT           | GitLab Duo Workflow Service | 1時間 | `GenerateToken` RPCを使用する各ワークフロー内。 |
| GLGO exchange JWT                 | AIゲートウェイ                | 1時間                              |  各リクエスト内。 |
