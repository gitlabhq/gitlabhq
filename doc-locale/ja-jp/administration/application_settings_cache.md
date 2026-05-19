---
stage: None
group: Unassigned
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: アプリケーションキャッシュ間隔
description: GitLabアプリケーションキャッシュを管理します。
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

デフォルトでは、GitLabはアプリケーション設定を60秒間キャッシュします。アプリケーション設定の変更と、ユーザーがアプリケーションでこれらの変更に気づくまでの遅延を長くするために、この間隔を長くする必要がある場合があります。

この値を`0`秒より大きい値に設定することをおすすめします。これを`0`に設定すると、`application_settings`テーブルがすべてのリクエストで読み込まれます。これにより、RedisとPostgreSQLに追加の負荷がかかります。

## アプリケーションキャッシュの有効期限間隔を変更する {#change-the-expiration-interval-for-application-cache}

有効期限の値を変更するには:

{{< tabs >}}

{{< tab title="Linuxパッケージ（Omnibus）" >}}

1. `/etc/gitlab/gitlab.rb`を編集します:

   ```ruby
   gitlab_rails['application_settings_cache_seconds'] = 60
   ```

1. ファイルを保存し、GitLabを再設定して再起動し、変更を有効にします:

   ```shell
   gitlab-ctl reconfigure
   gitlab-ctl restart
   ```

{{< /tab >}}

{{< tab title="セルフコンパイル（ソース）" >}}

1. `config/gitlab.yml`を編集します:

   ```yaml
   gitlab:
     application_settings_cache_seconds: 60
   ```

1. ファイルを保存してから、変更を反映するためにGitLabを[再起動](restart_gitlab.md#self-compiled-installations)します。

{{< /tab >}}

{{< /tabs >}}
