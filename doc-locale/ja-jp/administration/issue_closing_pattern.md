---
stage: Create
group: Code Review
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: インスタンス管理者は、GitLabのインスタンス用にカスタムイシューのクローズパターンを設定できます。
title: イシューのクローズパターン
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

> [!note]
> イシューのクローズパターンに関するユーザードキュメントについては、[イシューを自動的にクローズする](../user/project/issues/managing_issues.md#closing-issues-automatically)を参照してください。

コミットまたはマージリクエストが1つ以上のイシューを解決する場合、GitLabは、コミットまたはマージリクエストがプロジェクトのデフォルトブランチに着地したときに、それらのイシューをクローズできます。[デフォルトイシューのクローズパターン](../user/project/issues/managing_issues.md#default-closing-pattern)は広範な単語をカバーしており、管理者は必要に応じて単語リストを設定できます。

## イシューのクローズパターンを変更する {#change-the-issue-closing-pattern}

デフォルトイシューのクローズパターンを必要に応じて変更するには:

{{< tabs >}}

{{< tab title="Linuxパッケージ（Omnibus）" >}}

1. `/etc/gitlab/gitlab.rb`を編集し、`gitlab_rails['gitlab_issue_closing_pattern']`の値を変更します:

   ```ruby
   gitlab_rails['gitlab_issue_closing_pattern'] = /<regular_expression>/.source
   ```

1. ファイルを保存して、GitLabを再設定します:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

{{< /tab >}}

{{< tab title="Helmチャート（Kubernetes）" >}}

1. Helmの値をエクスポートします: 

   ```shell
   helm get values gitlab > gitlab_values.yaml
   ```

1. `gitlab_values.yaml`を編集し、`issueClosingPattern`の値を変更します:

   ```yaml
   global:
     appConfig:
       issueClosingPattern: "<regular_expression>"
   ```

1. ファイルを保存して、新しい値を適用します: 

   ```shell
   helm upgrade -f gitlab_values.yaml gitlab gitlab/gitlab
   ```

{{< /tab >}}

{{< tab title="Docker" >}}

1. `docker-compose.yml`を編集し、`gitlab_rails['gitlab_issue_closing_pattern']`の値を変更します:

   ```yaml
   version: "3.6"
   services:
     gitlab:
       environment:
         GITLAB_OMNIBUS_CONFIG: |
           gitlab_rails['gitlab_issue_closing_pattern'] = /<regular_expression>/.source
   ```

1. ファイルを保存して、GitLabを再起動します: 

   ```shell
   docker compose up -d
   ```

{{< /tab >}}

{{< tab title="自己コンパイル（ソース）" >}}

1. `/home/git/gitlab/config/gitlab.yml`を編集し、`issue_closing_pattern`の値を変更します:

   ```yaml
   production: &base
     gitlab:
       issue_closing_pattern: "<regular_expression>"
   ```

1. ファイルを保存して、GitLabを再起動します: 

   ```shell
   # For systems running systemd
   sudo systemctl restart gitlab.target

   # For systems running SysV init
   sudo service gitlab restart
   ```

{{< /tab >}}

{{< /tabs >}}

イシューのクローズパターンをテストするには、[Rubular](https://rubular.com)を使用します。Rubularは`%{issue_ref}`を認識しません。パターンをテストする際は、この文字列を`#\d+`に置き換えてください。これは`#123`のようなローカルのイシュー参照のみに一致します。
