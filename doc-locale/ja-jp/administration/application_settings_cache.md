---
stage: None
group: Unassigned
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: アプリケーションキャッシュ間隔
description: GitLabアプリケーションのキャッシュを管理します。
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

デフォルトでは、GitLabはアプリケーションの設定を60秒間キャッシュします。場合によっては、アプリケーションの設定の変更と、ユーザーがアプリケーションでそれらの変更に気付くまでの間に、より多くの遅延を持たせるために、その有効期限間隔を長くする必要がある場合があります。

この値は`0`秒より大きく設定することをお勧めします。これを`0`に設定すると、すべてのリクエストに対して`application_settings`テーブルを読み込むようになります。これにより、RedisとPostgreSQLに対する余分な負荷が発生します。

## アプリケーションキャッシュの有効期限間隔を変更する {#change-the-expiration-interval-for-application-cache}

有効期限の値を変更するには:

{{< tabs >}}

{{< tab title="Linuxパッケージ（Omnibus）" >}}

1. `/etc/gitlab/gitlab.rb`を編集します:

   ```ruby
   gitlab_rails['application_settings_cache_seconds'] = 60
   ```

1. ファイルを保存し、変更を有効にするためにGitLabを再構成して再起動します:

   ```shell
   gitlab-ctl reconfigure
   gitlab-ctl restart
   ```

{{< /tab >}}

{{< tab title="自己コンパイル（ソース）" >}}

1. `config/gitlab.yml`を編集します:

   ```yaml
   gitlab:
     application_settings_cache_seconds: 60
   ```

1. ファイルを保存してから、変更を有効にするためにGitLabを[再起動](restart_gitlab.md#self-compiled-installations)します。

{{< /tab >}}

{{< /tabs >}}
