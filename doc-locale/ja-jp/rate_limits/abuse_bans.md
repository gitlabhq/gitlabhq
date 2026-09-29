---
stage: none
group: unassigned
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: 繰り返される認証失敗リクエストの後でクライアントをブロックする利用停止。
title: 不正利用と認証失敗の利用停止
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

一部の保護機能は、リクエストを遅くするのではなく、一定期間クライアントをブロックします。

## Gitおよびコンテナレジストリに対する認証失敗による利用停止 {#failed-authentication-ban-for-git-and-container-registry}

デフォルトでは、単一のIPアドレスから1分間に10回の認証失敗リクエストが受信された場合、GitLabはHTTPステータスコード`403`を1時間返します。これら3つの値はすべて設定可能です。これは、次の組み合わせにのみ適用されます:

- Gitリクエスト。
- コンテナレジストリ（`/jwt/auth`）リクエスト。

この制限は、次のようになります。

- 利用停止が開始されるまで、認証に成功したリクエストによってリセットされます。たとえば、9回の認証失敗リクエストの後に1回の認証成功リクエストがあり、さらに9回の認証失敗リクエストが続いても、利用停止はトリガーされません。
- 利用停止が開始されると、認証によって解除することはできません。利用停止は認証情報より先にチェックされるため、利用停止されたIPは、利用停止期間が終了するまで、有効な認証情報であっても`403`を受け取ります。
- `gitlab-ci-token`で認証されたJSON Webトークンリクエストには適用されません。
- デフォルトでは無効になっています。

応答ヘッダーは提供されません。

レート制限を回避するには、次のことができます:

- 自動パイプラインの実行をずらします。
- 認証失敗の試行に対して[指数関数的なバックオフと再試行](https://docs.aws.amazon.com/prescriptive-guidance/latest/cloud-design-patterns/retry-backoff.html)を設定します。
- トークンの有効期限を管理するために、ドキュメント化されたプロセスと[ベストプラクティス](https://about.gitlab.com/blog/access-token-lifetime-limits/#how-to-minimize-the-impact)を使用します。

設定情報については、[Linuxパッケージ設定オプション](https://docs.gitlab.com/omnibus/settings/configuration/#configure-a-failed-authentication-ban)を参照してください。

## トラブルシューティング {#troubleshooting}

### Rack Attackがロードバランサーを拒否リストに追加している {#rack-attack-is-denylisting-the-load-balancer}

すべてのトラフィックがロードバランサーから来ているように見える場合、Rack Attackがロードバランサーをブロックすることがあります。その場合、次のことを行う必要があります:

1. [`nginx[real_ip_trusted_addresses]`を設定](https://docs.gitlab.com/omnibus/settings/nginx/#configure-gitlab-trusted-proxies-and-nginx-real_ip-module)します。これにより、ユーザーのIPがロードバランサーのIPとしてリストされるのを防ぎます。
1. ロードバランサーのIPアドレスを許可リストに追加します。
1. GitLabを再設定します:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

### Rack AttackからブロックされたIPをRedisで削除する {#remove-blocked-ips-from-rack-attack-with-redis}

ブロックされたIPを削除するには:

1. 本番環境ログでブロックされたIPを見つけます:

   ```shell
   grep "Rack_Attack" /var/log/gitlab/gitlab-rails/auth.log
   ```

1. 拒否リストはレート制限Redisインスタンスに保存されているため、それに対して`redis-cli`を開く必要があります。インスタンスを分離しないインストールでは、これがデフォルトのRedisです:

   ```shell
   /opt/gitlab/embedded/bin/redis-cli -s /var/opt/gitlab/redis/redis.socket
   ```

   `gitlab_rails['redis_rate_limiting_instance']`を設定している場合は、代わりにそのインスタンスに接続してください。誤ったインスタンスからキーを削除しても成功したように見え、利用停止は解除されません。

1. 次の構文を使用してブロックを削除できます。`<ip>`を実際に拒否リストに追加されているIPに置き換えてください:

   ```plaintext
   del cache:gitlab:rack::attack:allow2ban:ban:<ip>
   ```

1. IPアドレスを持つキーが表示されなくなったことを確認します:

   ```plaintext
   keys *rack::attack*
   ```

   デフォルトでは、[`keys`コマンドは無効](https://docs.gitlab.com/omnibus/settings/redis/#renamed-commands)です。

1. オプションで、IPを[許可リストに追加](https://docs.gitlab.com/omnibus/settings/configuration/#configure-a-failed-authentication-ban)して、再度拒否リストに追加されるのを防ぎます。
