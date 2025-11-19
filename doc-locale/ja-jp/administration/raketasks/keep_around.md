---
stage: Data Access
group: Gitaly
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Keep-around orphaned参照Rakeタスク
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

{{< history >}}

- Rakeタスクの改善は、GitLab 18.4で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/475246)されました。

{{< /history >}}

`gitlab:keep_around:orphaned`は、プロジェクトリポジトリ内のすべてのkeep-around参照と、Gitコミットへのすべてのデータベース参照のCSVレポートを生成します。

CSVレポートには3つの列があります:

- 参照のタイプ。keep-around参照の場合は`keep`、データベース参照の場合は`usage`。
- GitコミットID。
- 参照元（既知の場合）。たとえば`Pipeline`などです。

## 孤立した参照レポートを実行 {#run-orphaned-reference-report}

{{< tabs >}}

{{< tab title="Linuxパッケージ（Omnibus）" >}}

```shell
sudo gitlab-rake gitlab:keep_around:orphaned PROJECT_PATH=project/path FILENAME=/tmp/report.csv
```

{{< /tab >}}

{{< tab title="自己コンパイル（ソース）" >}}

```shell
bundle exec rake gitlab:keep_around:orphaned RAILS_ENV=production PROJECT_PATH=project/path FILENAME=/tmp/report.csv
```

{{< /tab >}}

{{< /tabs >}}
