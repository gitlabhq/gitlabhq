---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: モックCI
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< alert type="note" >}}

このインテグレーションは、開発環境でのみ利用可能です。

{{< /alert >}}

モックCIサービスサーバーをセットアップするには、以下のエンドポイントに応答します:

- `commit_status`: `#{project.namespace.path}/#{project.path}/status/#{sha}.json`
  - サービスに`200 { status: ['failed'|'canceled'|'running'|'pending'|'success'|'success-with-warnings'|'skipped'|'not_found'] }`を返すようにします。
  - サービスが404を返した場合、サービスは`pending`と解釈されます。
- `build_page`: `#{project.namespace.path}/#{project.path}/status/#{sha}`
  - どこにビルドがリンクされているか（実装されているかどうか）。

モックCIサーバーの例については、[`gitlab-org/gitlab-mock-ci-service`](https://gitlab.com/gitlab-org/gitlab-mock-ci-service)を参照してください。
