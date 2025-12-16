---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: 診断ツール
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

GitLabサポートチームは、トラブルシューティング時にこれらの診断ツールを使用します。これらは透明性を確保するため、およびGitLabのトラブルシューティングの経験があるユーザーのためにここにリストされています。

GitLabでイシューが発生した場合、これらのツールを使用する前に、[サポートオプション](https://about.gitlab.com/support/)を確認してください。

## SOSスクリプト {#sos-scripts}

{{< history >}}

- `gitlabsos`のLinuxパッケージおよびDockerイメージとのバンドルは、GitLab 18.3で[導入](https://gitlab.com/gitlab-org/omnibus-gitlab/-/merge_requests/8565)されました。

{{< /history >}}

- [`gitlabsos`](https://gitlab.com/gitlab-com/support/toolbox/gitlabsos/)は、LinuxパッケージまたはDockerベースのGitLabインスタンス、およびそのオペレーティングシステムから情報と最近のログを収集します。

  ```shell
  sudo gitlabsos
  ```

- [`kubesos`](https://gitlab.com/gitlab-com/support/toolbox/kubesos/)は、GitLab HelmチャートデプロイメントからKubernetesクラスタの設定と最近のログを収集します。
- [`gitlab:db:sos`](../raketasks/maintenance.md#collect-information-and-statistics-about-the-database)は、データベースに関する詳細な診断データを収集します。

## `strace-parser` {#strace-parser}

[`strace-parser`](https://gitlab.com/gitlab-com/support/toolbox/strace-parser)は、raw `strace`データを解析および要約します。コンテキストについては、[`strace` zine](https://wizardzines.com/zines/strace/)をお勧めします。

## `gitlabrb_sanitizer` {#gitlabrb_sanitizer}

[`gitlabrb_sanitizer`](https://gitlab.com/gitlab-com/support/toolbox/gitlabrb_sanitizer/)は、機密性の高い値が削除済みの`/etc/gitlab/gitlab.rb`コンテンツのコピーを出力します。

`gitlabsos`は、設定をサニタイズするために、自動的に`gitlabrb_sanitizer`を使用します。

## `fast-stats` {#fast-stats}

{{< history >}}

- `fast-stats`のLinuxパッケージおよびDockerイメージとのバンドルは、GitLab 18.3で[導入](https://gitlab.com/gitlab-org/omnibus-gitlab/-/merge_requests/8618)されました。

{{< /history >}}

パフォーマンスと設定の問題をデバッグするために、[`fast-stats`](https://gitlab.com/gitlab-com/support/toolbox/fast-stats#fast-stats)はエラーとリソースを大量に消費する使用状況の統計をすばやく要約します。

`fast-stats`を使用して、大量のログを解析および比較するか、不明な問題のトラブルシューティングを開始します。

```shell
/opt/gitlab/embedded/bin/fast-stats
```

## `greenhat` {#greenhat}

[`greenhat`](https://gitlab.com/gitlab-com/support/toolbox/greenhat/)は、[SOSログ](#sos-scripts)を分析、フィルタリング、および要約するためのインタラクティブシェルを提供します。

## GitLab Detective {#gitlab-detective}

[GitLab Detective](https://gitlab.com/gitlab-com/support/toolbox/gitlab-detective)はGitLabインスタンスで自動チェックを実行して、一般的な問題を特定し、解決します。
