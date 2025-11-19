---
stage: Systems
group: Cloud Connector
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: IP許可リスト
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

GitLabは、プローブされたときにヘルスチェック情報を提供する、いくつかの[モニタリングエンドポイント](health_check.md)を提供します。

IPアドレスの許可リストを使用してこれらのエンドポイントへのアクセスを制御するには、単一のホストを追加するか、IPアドレス範囲を使用します:

{{< tabs >}}

{{< tab title="Linuxパッケージ（Omnibus）" >}}

1. `/etc/gitlab/gitlab.rb`を開き、以下を追加またはコメント解除してください:

   ```ruby
   gitlab_rails['monitoring_whitelist'] = ['127.0.0.0/8', '192.168.0.1']
   ```

1. ファイルを保存して、変更を有効にするためにGitLabを[再設定](../restart_gitlab.md#reconfigure-a-linux-package-installation)します。

{{< /tab >}}

{{< tab title="Helmチャート（Kubernetes）" >}}

`gitlab.webservice.monitoring.ipWhitelist`キーの下に必要なIPを設定できます。例: 

```yaml
gitlab:
   webservice:
      monitoring:
         # Monitoring IP allowlist
         ipWhitelist:
         # Defaults
         - 0.0.0.0/0
         - ::/0
```

{{< /tab >}}

{{< tab title="自己コンパイル（ソース）" >}}

1. `config/gitlab.yml`を編集します: 

   ```yaml
   monitoring:
     # by default only local IPs are allowed to access monitoring resources
     ip_whitelist:
       - 127.0.0.0/8
       - 192.168.0.1
   ```

1. ファイルを保存して、変更を有効にするためにGitLabを[再起動](../restart_gitlab.md#self-compiled-installations)します。

{{< /tab >}}

{{< /tabs >}}
