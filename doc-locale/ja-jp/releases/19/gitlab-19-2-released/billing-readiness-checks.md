---
title: GitLab Duo Agent Platform Self-Hostedの使用量課金チェック
offering: [ self_managed, gitlab_dedicated_for_government ]
tier: [ Premium, Ultimate ]
stage: ai-powered
documentation_link: "../../../administration/gitlab_duo/configure/#run-a-health-check-for-gitlab-duo"
work_item: https://gitlab.com/gitlab-org/gitlab/-/work_items/603196
categories: [ Health & Connectivity ]
level: secondary
---

<!-- categories: Health & Connectivity  -->

オンラインライセンスでセルフホストモデルを使用しているGitLab Self-Managedのお客様向けに、GitLab Duoヘルスチェックが以下のエンドポイントへの接続を確認するようになりました。

- カスタマーポータル
- AIゲートウェイ
- Duoワークフローサービス

これらのエンドポイントへの接続は、使用量課金に必要です。

これまでは、ファイアウォールによってこれらのコンポーネントへの接続がブロックされていても、ユーザーが機能を使用できなくなるまで管理者は接続の問題を把握できませんでした。管理者はこの新しい検証チェックを使用して、ユーザーへの影響が生じる前に問題を診断し、ファイアウォールの許可リストを確認できるようになりました。
