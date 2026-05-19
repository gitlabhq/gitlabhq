---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 相対URLからサブドメインへの移行
description: 相対URLの代わりにサブドメインを使用するようにGitLabインスタンスを再設定します。
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

GitLabを相対URLの設定からサブドメインのデプロイに移行できます。

移行中のダウンタイムは、デプロイアーキテクチャとロードバランサーの設定によって異なります:

- GitLabアップグレードのダウンタイム: 単一ノードのインストールの場合、GitLabの再設定にはダウンタイムが必要です。マルチノードのインストールでロードバランシングを使用している場合は、[ゼロダウンタイムアップグレード](../../update/zero_downtime.md)プロセスに従ってノードを順次更新することでダウンタイムを最小限に抑えることができます。
- URLの切り替え中のユーザー向けダウンタイム: 影響は、ロードバランサーとDNSの設定によって異なります。GitLabの設定変更を適用する前に、ロードバランサーまたはDNSを設定して、古いURLと新しいURLの両方を同じバックエンドにルーティングすることで、移行中のユーザーへの混乱を最小限に抑えることができます。

> [!warning]
> GitLabは、実際に使用するURLで設定する必要があります。GitLabはAPI応答、メール、UI要素に対して内部的に絶対URLを生成するため、1つのURLにGitLabを設定し、ロードバランサーを使用してユーザーに異なるURLを提示することはできません。

## サブドメインへの移行 {#migrate-to-a-subdomain}

相対URLからサブドメインへ移行するには:

1. インストールタイプに基づいて、相対URLの設定を無効にするようにGitLabの設定を更新します。

   {{< tabs >}}

   {{< tab title="Linuxパッケージ（Omnibus）" >}}

      `/etc/gitlab/gitlab.rb`を編集し、`external_url`を更新して新しいサブドメインを使用します:

      ```ruby
      external_url "https://gitlab.example.com"
      ```

   {{< /tab >}}

   {{< tab title="Helmチャート（Kubernetes）" >}}

      [`global.hosts`](https://docs.gitlab.com/charts/charts/globals/#configure-host-settings)の設定を更新して、新しいサブドメインを使用します。

   {{< /tab >}}

   {{< tab title="自己コンパイル（ソース）" >}}

      [GitLabで相対URLを無効にする](../../install/relative_url.md#disable-relative-url-in-gitlab)を参照してください。

   {{< /tab >}}

   {{< /tabs >}}

1. 新しいサブドメインの設定を適用するには、インストールタイプに適用される[GitLabインスタンスをアップグレードする](../../update/_index.md)ためのアップグレードプロセスに従ってください。
1. URLを変更するとすべてのリモートURLが変更されるため、GitLabインスタンスを指す任意のローカルリポジトリで手動で編集する必要があります。相対URLを使用中にクローンされたローカルリポジトリは、古いパスを指すリモートURLを持っています。ユーザーはこれらを個別に更新する必要があります。
1. 移行期間中に既存のリンクを保持する必要がある場合は、[ロードバランサーを設定して](#configure-load-balancer-redirects)レガシーの相対URLを新しいサブドメインにリダイレクトします。

## ロードバランサーのリダイレクトを設定する {#configure-load-balancer-redirects}

GitLabを相対URLからサブドメインへ移行する後、ロードバランサーを設定して古い相対URLを新しいサブドメインにリダイレクトします:

1. ロードバランサーが、古いドメインと新しいドメインの両方のSSL証明書を持っていることを確認してください。
1. DNSを設定して、両方のドメインをロードバランサーに解決するようにします。
1. ロードバランサーの設定にリダイレクトルールを追加します:
   - 相対URLのプレフィックスで始まるパスを持つ古いドメインへのリクエストを検出します (例: `/gitlab/`)。
   - リクエストを301 (恒久的なリダイレクト) ステータスで新しいサブドメインにリダイレクトします。
   - パスの先頭から相対URLのプレフィックスを削除することで、パスとクエリパラメータを保持します。
1. 個別のURL設定を持つGitLabコンポーネント (コンテナレジストリやPagesなど) がある場合は、それらのパスに対しても同様のリダイレクトルールを追加します。
