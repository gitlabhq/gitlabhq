---
stage: Data Access
group: Gitaly
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Praefect Rakeタスク
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

Rakeタスクは、Praefectストレージに作成されたプロジェクトで使用できます。Praefectの設定については、[Praefectドキュメント](../gitaly/praefect/_index.md)を参照してください。

## レプリカのチェックサム {#replica-checksums}

`gitlab:praefect:replicas`は、指定された`project_id`のリポジトリのチェックサムを次のように出力します:

- プライマリGitalyノード。
- セカンダリ内部Gitalyノード。

このRakeタスクは、Praefectがインストールされているノードではなく、GitLabがインストールされているノードで実行してください。

- Linuxパッケージインストール:

  ```shell
  sudo gitlab-rake "gitlab:praefect:replicas[project_id]"
  ```

- 自己コンパイルによるインストール:

  ```shell
  sudo -u git -H bundle exec rake "gitlab:praefect:replicas[project_id]" RAILS_ENV=production
  ```
