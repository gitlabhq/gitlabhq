---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: 環境変数
description: サポートされている環境変数をオーバーライドします。
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

GitLabは、デフォルト値をオーバーライドするために使用できる特定の環境変数を公開しています。

通常、GitLabは以下のように設定されています。: 

- Linuxパッケージインストールの場合: `/etc/gitlab/gitlab.rb`。
- 自己コンパイルによるインストールの場合: `gitlab.yml`。

以下の環境変数を使用して、特定の値のオーバーライドが可能です。: 

## サポートされている環境変数 {#supported-environment-variables}

| 変数                                   | 型    | 説明 |
|--------------------------------------------|---------|-------------|
| `DATABASE_URL`                             | 文字列  | データベースのURL。形式は、`postgresql://localhost/blog_development`です。 |
| `ENABLE_BOOTSNAP`                          | 文字列  | 初期Railsブートを高速化するために、[Bootsnap](https://github.com/Shopify/bootsnap)を切り替えます。本番環境以外の環境では、デフォルトで有効になっています。無効にするには`0`に設定します。 |
| `EXTERNAL_URL`                             | 文字列  | [インストール時](https://docs.gitlab.com/omnibus/settings/configuration.html#specifying-the-external-url-at-the-time-of-installation)に外部URLを指定します。 |
| `EXTERNAL_VALIDATION_SERVICE_TIMEOUT`      | 整数 | [外部CI/CDパイプライン検証サービス](cicd/external_pipeline_validation.md)のタイムアウト。デフォルトは`5`です。 |
| `EXTERNAL_VALIDATION_SERVICE_URL`          | 文字列  | [外部CI/CDパイプライン検証サービス](cicd/external_pipeline_validation.md)のURL。 |
| `EXTERNAL_VALIDATION_SERVICE_TOKEN`        | 文字列  | [外部CI/CDパイプライン検証サービス](cicd/external_pipeline_validation.md)での認証のための`X-Gitlab-Token`。 |
| `GITLAB_CDN_HOST`                          | 文字列  | 静的アセットを処理するために、CDNのベースURLを設定します（`https://mycdnsubdomain.fictional-cdn.com`など）。 |
| `GITLAB_EMAIL_DISPLAY_NAME`                | 文字列  | GitLabから送信されるメールの**From**フィールドで使用される名前。 |
| `GITLAB_EMAIL_FROM`                        | 文字列  | GitLabから送信されるメールの**From**フィールドで使用されるメールアドレス。 |
| `GITLAB_EMAIL_REPLY_TO`                    | 文字列  | GitLabから送信されるメールの**Reply-To**フィールドで使用されるメールアドレス。 |
| `GITLAB_EMAIL_SUBJECT_PREFIX`              | 文字列  | GitLabから送信されるメールで使用されるメールの件名のプレフィックス。 |
| `GITLAB_EMAIL_SUBJECT_SUFFIX`              | 文字列  | GitLabから送信されるメールで使用されるメールの件名のサフィックス。 |
| `GITLAB_HOST`                              | 文字列  | GitLabサーバーの完全なURL（`http://`または`https://`を含む）。 |
| `GITLAB_MARKUP_TIMEOUT`                    | 文字列  | [`gitlab-markup` gem](https://gitlab.com/gitlab-org/gitlab-markup/)によって実行される`rest2html`コマンドと`pod2html`コマンドのタイムアウト（秒単位）。デフォルトは`10`です。 |
| `GITLAB_ROOT_PASSWORD`                     | 文字列  | インストール時に`root`ユーザーのパスワードを設定します。 |
| `GITLAB_SHARED_RUNNERS_REGISTRATION_TOKEN` | 文字列  | Runnerに使用される初期登録トークンを設定します。[GitLab 16.11で非推奨になりました](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/148310)  |
| `RAILS_ENV`                                | 文字列  | Rails環境。`production`、`development`、`staging`、または`test`のいずれかになります。 |
| `GITLAB_RAILS_CACHE_DEFAULT_TTL_SECONDS`   | 整数 | Railsキャッシュに保存されているエントリに使用されるデフォルトのTTL。デフォルトは`28800`です。15.3で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/95042)されました。 |
| `GITLAB_CI_CONFIG_FETCH_TIMEOUT_SECONDS`   | 整数 | CI設定のリモートインクルードを解決するためのタイムアウト（秒単位）。`0`～`60`の間である必要があります。デフォルトは`30`です。15.11で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/116383)されました。 |
| `GITLAB_DISABLE_MARKDOWN_TIMEOUT`          | 文字列  | `true`、`1`、または`yes`に設定されている場合、バックエンドでのMarkdownレンダリングはタイムアウトしません。デフォルトは`false`です。GitLab 17.4で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/163662)されました。 |
| `GITLAB_LFS_LINK_BATCH_SIZE`               | 整数 | LFSファイルのリンクのバッチサイズを設定します。デフォルトは`1000`です。 |
| `GITLAB_LFS_MAX_OID_TO_FETCH`              | 整数 | リンクするLFSオブジェクトの最大数を設定します。デフォルトは`100,000`です。 |
| `SIDEKIQ_SEMI_RELIABLE_FETCH_TIMEOUT`      | 整数 | Sidekiqの準信頼性フェッチのタイムアウトを設定します。デフォルトは`5`です。[以前のGitLab 16.7](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/139583)では、デフォルトは`3`でした。以前のGitLab 16.6以前でRedis CPUの消費量が多い場合、またはこの変数をカスタマイズした場合は、この変数を`5`に更新する必要があります。 |
| `SSL_IGNORE_UNEXPECTED_EOF`                | 文字列  | OpenSSL 3.0では、サーバーがSSL接続をシャットダウンする前に、close_notifyを送信する必要があります。これを`true`に設定すると、これは無効になります。詳細については、[OpenSSLのドキュメント](https://docs.openssl.org/3.0/man3/SSL_CTX_set_options/#notes)を参照してください。デフォルトは`false`です。 |

## 変数の追加 {#adding-more-variables}

変数を使用して、より多くの設定を設定可能にするマージリクエストをお待ちしております。`config/initializers/1_settings.rb`ファイルを変更し、命名規則`GITLAB_#{name in 1_settings.rb in upper case}`を使用します。

## Linuxパッケージのインストール設定 {#linux-package-installation-configuration}

環境変数を設定するには、[これらの手順](https://docs.gitlab.com/omnibus/settings/environment-variables.html)に従ってください。

環境変数`GITLAB_OMNIBUS_CONFIG`を`docker run`コマンドに追加することで、GitLab Dockerイメージを事前設定できます。詳細については、[Dockerコンテナの事前設定](../install/docker/configuration.md#pre-configure-docker-container)を参照してください。
