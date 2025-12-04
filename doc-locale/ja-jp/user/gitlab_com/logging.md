---
stage: none
group: unassigned
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitLab.comのログ
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com

{{< /details >}}

GitLab.comのログに関する情報。

## GitLab.comでのログ記録の方法 {#how-we-log-on-gitlabcom}

[Fluentd](https://gitlab.com/gitlab-com/runbooks/tree/master/logging/doc#fluentd)はlogを解析し、次の場所に送信します:

- [Stackdriver Logging](https://gitlab.com/gitlab-com/runbooks/tree/master/logging/doc#stackdriver)。ここでは、logをGoogle Cold Storage（GCS）に長期的に保存します。
- [Cloud Pub/Sub](https://gitlab.com/gitlab-com/runbooks/tree/master/logging/doc#cloud-pubsub) 。ここでは、[`pubsubbeat`](https://gitlab.com/gitlab-com/runbooks/tree/master/logging/doc#pubsubbeat-vms)を使用して、logを[Elasticクラスター](https://gitlab.com/gitlab-com/runbooks/tree/master/logging/doc#elastic)に転送します。

詳細については、当社の手順書を参照してください:

- ログに記録している内容の[詳細なリスト](https://gitlab.com/gitlab-com/runbooks/-/tree/master/docs/logging#what-are-we-logging)。
- 現在のログ[保持ポリシー](https://gitlab.com/gitlab-com/runbooks/-/tree/master/docs/logging#retention)。
- [ロギングインフラストラクチャの図](https://gitlab.com/gitlab-com/runbooks/-/tree/master/docs/logging#logging-infrastructure-overview)。

## CI/CDジョブログの消去 {#erase-cicd-job-logs}

デフォルトでは、GitLabはCI/CDのジョブログに有効期限を設定しません。ジョブログは無期限に保持され、期限切れになるようにGitLab.comで設定することはできません。ジョブログは、次のいずれかの方法で消去できます:

- [Jobs APIを使用する](../../api/jobs.md#erase-a-job)。
- ジョブが属する[パイプラインを削除する](../../ci/pipelines/_index.md#delete-a-pipeline)。
