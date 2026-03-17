---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 環境変数
description: サポートされている環境変数をオーバーライドします。
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

GitLabは、環境変数を公開しており、それらを使用してデフォルト値をオーバーライドできます。

通常、GitLabの設定は、以下で行います:

- Linuxパッケージインストールの場合: `/etc/gitlab/gitlab.rb`。
- 自己コンパイルによるインストールの場合: `gitlab.yml`。

以下の環境変数を使用して、特定の値をオーバーライドできます:

## サポートされている環境変数 {#supported-environment-variables}

| 変数                                     | 種類    | 説明                                                                                                                                                                                                                                                                                                                      |
|----------------------------------------------|---------|----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `DATABASE_URL`                               | 文字列  | データベースURLは`postgresql://localhost/blog_development`の形式です。                                                                                                                                                                                                                                                     |
| `ENABLE_BOOTSNAP`                            | 文字列  | 最初のRailsの起動を高速化するための[Bootsnap](https://github.com/Shopify/bootsnap)を切替ます。本番環境以外の環境では、デフォルトで有効です。無効にするには`0`に設定します。                                                                                                                                                           |
| `EXTERNAL_URL`                               | 文字列  | [インストール時](https://docs.gitlab.com/omnibus/settings/configuration/#specifying-the-external-url-at-the-time-of-installation)に外部URLを指定します。                                                                                                                                                     |
| `EXTERNAL_VALIDATION_SERVICE_TIMEOUT`        | 整数 | [外部CI/CDパイプライン検証サービス](cicd/external_pipeline_validation.md)に対するタイムアウト（秒単位）。デフォルトは`5`です。                                                                                                                                                                                                  |
| `EXTERNAL_VALIDATION_SERVICE_URL`            | 文字列  | [外部CI/CDパイプライン検証サービス](cicd/external_pipeline_validation.md)へのURL。                                                                                                                                                                                                                                    |
| `EXTERNAL_VALIDATION_SERVICE_TOKEN`          | 文字列  | [外部CI/CDパイプライン検証サービス](cicd/external_pipeline_validation.md)で認証するための`X-Gitlab-Token`。                                                                                                                                                                                              |
| `GITLAB_CDN_HOST`                            | 文字列  | 静的アセットを提供するCDNのベースURLを設定します（例: `https://mycdnsubdomain.fictional-cdn.com`）。                                                                                                                                                                                                                    |
| `GITLAB_EMAIL_DISPLAY_NAME`                  | 文字列  | GitLabから送信されるメールの**From**フィールドで使用される名前。                                                                                                                                                                                                                                                                    |
| `GITLAB_EMAIL_FROM`                          | 文字列  | GitLabから送信されるメールの**From**フィールドで使用されるメールアドレス。                                                                                                                                                                                                                                                           |
| `GITLAB_EMAIL_REPLY_TO`                      | 文字列  | GitLabから送信されるメールの**Reply-To**フィールドで使用されるメールアドレス。                                                                                                                                                                                                                                                       |
| `GITLAB_EMAIL_SUBJECT_PREFIX`                | 文字列  | GitLabから送信されるメールで使われる件名のプレフィックス。                                                                                                                                                                                                                                                                          |
| `GITLAB_EMAIL_SUBJECT_SUFFIX`                | 文字列  | GitLabから送信されるメールで使われる件名のサフィックス。                                                                                                                                                                                                                                                                          |
| `GITLAB_HOST`                                | 文字列  | GitLabサーバーの完全なURL（`http://`または`https://`を含む）。                                                                                                                                                                                                                                                           |
| `GITLAB_MARKUP_TIMEOUT`                      | 文字列  | [`gitlab-markup` gem](https://gitlab.com/gitlab-org/gitlab-markup/)によって実行される`rest2html`コマンドと`pod2html`コマンドのタイムアウト（秒単位）。デフォルトは`10`です。                                                                                                                                                               |
| `GITLAB_ROOT_PASSWORD`                       | 文字列  | インストール時に`root`ユーザーのパスワードを設定します。                                                                                                                                                                                                                                                                           |
| `GITLAB_SHARED_RUNNERS_REGISTRATION_TOKEN`   | 文字列  | Runnerで使用される初期の登録トークンを設定します。GitLab 16.11で[非推奨](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/148310)になりました。                                                                                                                                                                                |
| `RAILS_ENV`                                  | 文字列  | Railsの環境。`production`、`development`、`staging`、または`test`のいずれかを指定できます。                                                                                                                                                                                                                                          |
| `GITLAB_RAILS_CACHE_DEFAULT_TTL_SECONDS`     | 整数 | Rails-キャッシュに保存されたエントリに使用されるデフォルトのTTL。デフォルトは`28800`です。15.3で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/95042)。                                                                                                                                                               |
| `GITLAB_CI_CONFIG_FETCH_TIMEOUT_SECONDS`     | 整数 | リモートインクルードをCI設定で解決するためのタイムアウト（秒単位）。`0`から`60`の間にする必要があります。デフォルトは`30`です。15.11で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/116383)。                                                                                                                               |
| `GITLAB_CI_MAX_COMMIT_MESSAGE_SIZE_IN_BYTES` | 整数 | CI Runnerに送信できる最大コミットメッセージサイズ（バイト単位）。`0`から`1000000`の間にする必要があります。デフォルトは`100000`です。18.6で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/208666)。                                                                                                                                                                           |
| `GITLAB_DISABLE_MARKDOWN_TIMEOUT`            | 文字列  | `true`、`1`、または`yes`に設定すると、バックエンドでのMarkdownのレンダリングはタイムアウトしません。デフォルトは`false`です。GitLab 17.4で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/163662)されました。                                                                                                                                    |
| `GITLAB_LFS_LINK_BATCH_SIZE`                 | 整数 | LFSファイルをリンクするためのバッチサイズを設定します。デフォルトは`1000`です。                                                                                                                                                                                                                                                                    |
| `GITLAB_LFS_MAX_OID_TO_FETCH`                | 整数 | リンクするLFSオブジェクトの最大数を設定します。デフォルトは`100000`です。                                                                                                                                                                                                                                                            |
| `SIDEKIQ_SEMI_RELIABLE_FETCH_TIMEOUT`        | 整数 | Sidekiqのセミ信頼性フェッチのタイムアウトを設定します。デフォルトは`5`です。[GitLab 16.7以前](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/139583)は、デフォルトは`3`でした。GitLab 16.6以前で高いRedis CPU消費が発生する場合、またはこの変数をカスタマイズしている場合は、この変数を`5`に更新する必要があります。 |
| `SSL_IGNORE_UNEXPECTED_EOF`                  | 文字列  | OpenSSL 3.0では、SSL接続をシャットダウンする前に、サーバーが`close_notify`アラートを送信する必要があります。デフォルトは`false`です。この変数を`true`に設定すると、アラートは無効になります。詳細については、[OpenSSLドキュメント](https://docs.openssl.org/3.0/man3/SSL_CTX_set_options/#notes)を参照してください。                                                        |

## 追加の変数 {#adding-more-variables}

変数を使用してより多くの設定を設定可能にするマージリクエストを歓迎します。`config/initializers/1_settings.rb`ファイルに変更を加え、`GITLAB_#{name in 1_settings.rb in upper case}`の命名規則を使用します。

## Linuxパッケージの設定 {#linux-package-installation-configuration}

環境変数を設定するには、[これらの手順](https://docs.gitlab.com/omnibus/settings/environment-variables/)に従ってください。

GitLab Dockerイメージは、`GITLAB_OMNIBUS_CONFIG`環境変数を`docker run`コマンドに追加することで事前設定できます。詳細については、[Dockerコンテナの事前設定](../install/docker/configuration.md#pre-configure-docker-container)を参照してください。
