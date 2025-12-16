---
stage: Application Security Testing
group: Composition Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: SPDXライセンスリストRakeタスクのインポート
---

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

GitLabは、[SPDXライセンスリスト](https://spdx.org/licenses/)の新しいコピーをGitLabインスタンスにアップロードするためのRakeタスクを提供します。このリストは、[ライセンス承認ポリシー](../../user/compliance/license_approval_policies.md)の名前を照合するために必要です。

PDXライセンスリストの新しいコピーをインポートするには、以下を実行します:

```shell
# omnibus-gitlab
sudo gitlab-rake gitlab:spdx:import

# source installations
bundle exec rake gitlab:spdx:import RAILS_ENV=production
```

このタスクを[オフライン環境](../../user/application_security/offline_deployments/_index.md#defining-offline-environments)で実行するには、[`licenses.json`](https://spdx.org/licenses/licenses.json)への送信接続を許可する必要があります。
