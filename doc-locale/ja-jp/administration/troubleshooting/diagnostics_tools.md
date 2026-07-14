---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 診断ツール
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

GitLabサポートチームは、トラブルシューティング中にこれらの診断ツールを使用します。これらは透明性のため、およびGitLabのトラブルシューティング経験を持つユーザーのためにここに記載されています。

GitLabにイシューがある場合は、これらのツールを使用する前に[サポートオプション](https://support.gitlab.com/)を確認することをおすすめします。

## SOSスクリプト {#sos-scripts}

{{< history >}}

- LinuxパッケージおよびDockerイメージへの`gitlabsos`のバンドルは、GitLab 18.3で[導入](https://gitlab.com/gitlab-org/omnibus-gitlab/-/merge_requests/8565)されました。

{{< /history >}}

- [`gitlabsos`](https://gitlab.com/gitlab-com/support/toolbox/gitlabsos/)は、LinuxパッケージまたはDockerベースのGitLabインスタンスとそのオペレーティングシステムから情報と最新のログを収集します。

  ```shell
  sudo gitlabsos
  ```

- [`kubesos`](https://gitlab.com/gitlab-com/support/toolbox/kubesos/)は、GitLab HelmチャートデプロイからKubernetesクラスター設定と最新のログを収集します。
- [`gitlab:db:sos`](../raketasks/maintenance.md#collect-information-and-statistics-about-the-database)は、データベースに関する詳細な診断データを収集します。

## `strace-parser` {#strace-parser}

[`strace-parser`](https://gitlab.com/gitlab-com/support/toolbox/strace-parser)は、raw `strace`データを分析および要約します。コンテキストとして、[`strace` zine](https://wizardzines.com/zines/strace/)をおすすめします。

## `gitlabrb_sanitizer` {#gitlabrb_sanitizer}

[`gitlabrb_sanitizer`](https://gitlab.com/gitlab-com/support/toolbox/gitlabrb_sanitizer/)は、機密情報が削除済みの`/etc/gitlab/gitlab.rb`コンテンツのコピーを出力します。

`gitlabsos`は、`gitlabrb_sanitizer`を自動的に使用して設定をサニタイズします。

## `fast-stats` {#fast-stats}

{{< history >}}

- LinuxパッケージおよびDockerイメージへの`fast-stats`のバンドルは、GitLab 18.3で[導入](https://gitlab.com/gitlab-org/omnibus-gitlab/-/merge_requests/8618)されました。

{{< /history >}}

パフォーマンスおよび設定の問題のデバッグに役立つように、[`fast-stats`](https://gitlab.com/gitlab-com/support/toolbox/fast-stats#fast-stats)はエラーとリソースを大量に消費する使用状況の統計情報を迅速に要約します。

`fast-stats`を使用して、大量のログを解析および比較したり、不明な問題のトラブルシューティングを開始したりできます。

```shell
/opt/gitlab/embedded/bin/fast-stats
```

## `greenhat` {#greenhat}

[`greenhat`](https://gitlab.com/gitlab-com/support/toolbox/greenhat/)は、[SOSログ](#sos-scripts)を分析、フィルタリング、および要約するための対話型Shellを提供します。

## GitLab Detective {#gitlab-detective}

[GitLab Detective](https://gitlab.com/gitlab-com/support/toolbox/gitlab-detective)はGitLabインスタンスで自動チェックを実行して、一般的な問題を特定し、解決します。

## `soslab` {#soslab}

[soslab](https://gitlab.com/gitlab-com/support/toolbox/soslab)は、マルチノードデプロイ全体でのGitLab SOSバンドルのトラブルシューティング用のログアナライザーです。パターンクラスタリング、相関トレーシング、システムメトリクスダッシュボード、PowerSearch、自動分析、および組み込みのターミナルアクセスを提供します。soslabを使用して、大規模なGitLabインフラストラクチャ全体でイシューを特定します。
