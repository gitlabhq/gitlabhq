---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: タイムゾーンを変更
description: インスタンスのタイムゾーンを変更します。
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

{{< alert type="note" >}}

ユーザーは[プロフィールのタイムゾーン](../user/profile/_index.md#set-your-time-zone)を設定できます。新規ユーザーにはデフォルトのタイムゾーンが設定されていないため、プロフィールに表示する前に明示的に設定する必要があります。GitLab.comでは、デフォルトのタイムゾーンはUTCです。

{{< /alert >}}

GitLabのデフォルトのタイムゾーンはUTCですが、好みに合わせて変更できます。

GitLabインスタンスのタイムゾーンを更新するには:

1. 指定するタイムゾーンは、[tz形式](https://en.wikipedia.org/wiki/List_of_tz_database_time_zones)である必要があります。利用可能なタイムゾーンを確認するには、`timedatectl`コマンドを使用します:

   ```shell
   timedatectl list-timezones
   ```

1. タイムゾーンを変更します（例：`America/New_York`）。

{{< tabs >}}

{{< tab title="Linuxパッケージ（Omnibus）" >}}

1. `/etc/gitlab/gitlab.rb`を編集します:

   ```ruby
   gitlab_rails['time_zone'] = 'America/New_York'
   ```

1. ファイルを保存し、GitLabを再構成して再起動します:

   ```shell
   sudo gitlab-ctl reconfigure
   sudo gitlab-ctl restart
   ```

{{< /tab >}}

{{< tab title="Helmチャート（Kubernetes）" >}}

1. Helmの値をエクスポートします:

   ```shell
   helm get values gitlab > gitlab_values.yaml
   ```

1. `gitlab_values.yaml`を編集します:

   ```yaml
   global:
     time_zone: 'America/New_York'
   ```

1. ファイルを保存して、新しい値を適用します:

   ```shell
   helm upgrade -f gitlab_values.yaml gitlab gitlab/gitlab
   ```

{{< /tab >}}

{{< tab title="Docker" >}}

1. `docker-compose.yml`を編集します:

   ```yaml
   version: "3.6"
   services:
     gitlab:
       environment:
         GITLAB_OMNIBUS_CONFIG: |
           gitlab_rails['time_zone'] = 'America/New_York'
   ```

1. ファイルを保存して、GitLabを再起動します:

   ```shell
   docker compose up -d
   ```

{{< /tab >}}

{{< tab title="自己コンパイル（ソース）" >}}

1. `/home/git/gitlab/config/gitlab.yml`を編集します:

   ```yaml
   production: &base
     gitlab:
       time_zone: 'America/New_York'
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
