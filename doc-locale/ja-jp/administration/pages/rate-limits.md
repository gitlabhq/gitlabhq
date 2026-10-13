---
stage: Plan
group: Planner Intelligence
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: GitLab Pagesのレート制限
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

{{< history >}}

- GitLab 17.3で[変更](https://gitlab.com/groups/gitlab-org/-/work_items/14653)され、サブネットをPagesのレート制限から除外できるようになりました。

{{< /history >}}

サービス拒否（DoS）攻撃のリスクを最小限に抑えるために、レート制限を適用できます。GitLab Pagesは、トークンバケットアルゴリズムを使用してレート制限を実施しています。デフォルトでは、指定された制限を超えたリクエストまたはTLS接続は報告され、拒否されます。

GitLab Pagesでは、次の種類のレート制限をサポートしています。

- `source_ip`ごとに: 単一のクライアントIPアドレスからのリクエストまたはTLS接続を制限します。
- `domain`ごとに: GitLab PagesでホストされているドメインごとのリクエストまたはTLS接続を制限します。これは、`example.com`のようなカスタムドメイン、または`group.gitlab.io`のようなグループドメインです。

HTTPリクエストベースのレート制限は、以下の設定を使用して適用されます:

- `rate_limit_source_ip`: クライアントIPごとの1秒あたりの最大リクエスト数。無効にするには`0`に設定します。
- `rate_limit_source_ip_burst`: クライアントIPごとの初期バーストで許可される最大リクエスト数。例えば、ページが複数のリソースを同時に読み込む場合など。
- `rate_limit_domain`: ホストされているPagesドメインごとの1秒あたりの最大リクエスト数。無効にするには`0`に設定します。
- `rate_limit_domain_burst`: ホストされているPagesドメインごとの初期バーストで許可される最大リクエスト数。

TLS接続ベースのレート制限は、以下の設定を使用して適用されます:

- `rate_limit_tls_source_ip`: クライアントIPごとの1秒あたりの最大TLS接続数。無効にするには`0`に設定します。
- `rate_limit_tls_source_ip_burst`: クライアントIPごとの初期バーストで許可される最大TLS接続数。
- `rate_limit_tls_domain`: ホストされているPagesドメインごとの1秒あたりの最大TLS接続数。無効にするには`0`に設定します。
- `rate_limit_tls_domain_burst`: ホストされているPagesドメインごとの初期バーストで許可される最大TLS接続数。

特定のIP範囲（サブネット）がすべてのレート制限をバイパスできるようにするには、`rate_limit_subnets_allow_list`を使用します。例: `['1.2.3.4/24', '2001:db8::1/32']`。[GitLab Pagesチャートの例](https://docs.gitlab.com/charts/charts/gitlab/gitlab-pages/#configure-rate-limits-subnets-allow-list)が利用可能です。

クライアントのIPアドレスがIPv6の場合、制限はアドレス全体ではなく、長さが64のIPv6プレフィックスに適用されます。

## ソースIPごとのHTTPリクエストレート制限を有効にする {#enable-http-requests-rate-limits-by-source-ip}

`/etc/gitlab/gitlab.rb`でレート制限を設定するには:

1. 以下を追加します:

   ```ruby
   gitlab_pages['rate_limit_source_ip'] = 20.0
   gitlab_pages['rate_limit_source_ip_burst'] = 600
   ```

1. ファイルを保存し、変更を反映するために[GitLabを再設定](../restart_gitlab.md#reconfigure-a-linux-package-installation)します。

## ドメインごとのHTTPリクエストレート制限を有効にする {#enable-http-requests-rate-limits-by-domain}

`/etc/gitlab/gitlab.rb`でレート制限を設定するには:

1. 追加します:

   ```ruby
   gitlab_pages['rate_limit_domain'] = 1000
   gitlab_pages['rate_limit_domain_burst'] = 5000
   ```

1. ファイルを保存し、変更を反映するために[GitLabを再設定](../restart_gitlab.md#reconfigure-a-linux-package-installation)します。

## ソースIPごとのTLS接続レート制限を有効にする {#enable-tls-connections-rate-limits-by-source-ip}

`/etc/gitlab/gitlab.rb`でレート制限を設定するには:

1. 追加します:

   ```ruby
   gitlab_pages['rate_limit_tls_source_ip'] = 20.0
   gitlab_pages['rate_limit_tls_source_ip_burst'] = 600
   ```

1. ファイルを保存し、変更を反映するために[GitLabを再設定](../restart_gitlab.md#reconfigure-a-linux-package-installation)します。

## ドメインごとのTLS接続レート制限を有効にする {#enable-tls-connections-rate-limits-by-domain}

`/etc/gitlab/gitlab.rb`でレート制限を設定するには:

1. 追加します:

   ```ruby
   gitlab_pages['rate_limit_tls_domain'] = 1000
   gitlab_pages['rate_limit_tls_domain_burst'] = 5000
   ```

1. ファイルを保存し、変更を反映するために[GitLabを再設定](../restart_gitlab.md#reconfigure-a-linux-package-installation)します。

## 関連トピック {#related-topics}

- [GitLab Pagesの管理](_index.md)
- [レート制限](../../rate_limits/_index.md)
