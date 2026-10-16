---
title: GitLab Dedicated向けホスト型Runnerが一般提供開始
tier: [ Ultimate ]
offering: [ gitlab_dedicated ]
stage: production_engineering
documentation_link: "../../../administration/dedicated/hosted_runners"
work_item: https://gitlab.com/gitlab-com/gl-infra/gitlab-dedicated/transistor/-/merge_requests/834
categories: [ GitLab Hosted Runners ]
level: secondary
weight: 50
---

GitLab Dedicated向けホスト型Runnerが一般提供を開始しました。GitLabがRunnerのプロビジョニング、パッチ適用、スケーリングを代行し、GitLab Dedicatedインスタンスと同じセキュリティおよびコンプライアンス境界内で運用されます。

主な機能は次のとおりです。

- GitLab Dedicatedインスタンスと同じリージョンのAWS EC2インスタンスで動作し、ジョブごとに破棄される一時的なシングルテナントVMで実行
- GitLabインスタンスへの送信PrivateLink接続によるセキュアな通信
- Linux x86-64およびArm64 Runner（smallから2X-largeまでの5サイズ）
- GitLab DedicatedインスタンスのSLAとは別に算出される99.9%アップタイムSLAにより、ワークフローの安定性、耐障害性、および可用性を確保

ホスト型Runnerはスイッチボードで作成・管理でき、使用した分だけお支払いいただきます。使用量はGitLab Creditsダッシュボードで追跡されます。ご利用を開始するには、カスタマーサクセスマネージャーまたはアカウント担当者にお問い合わせください。
