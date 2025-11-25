---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: 暗号化された設定
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

GitLabは、暗号化された設定ファイルから、特定の機能の設定を読み取りできます。サポートされている機能は次のとおりです:

- [受信メール`user`と`password`](incoming_email.md#use-encrypted-credentials)。
- [LDAP `bind_dn`および`password`](auth/ldap/_index.md#use-encrypted-credentials)。
- [サービスデスクemail `user`および`password`](../user/project/service_desk/configure.md#use-encrypted-credentials)。
- [SMTP `user_name`および`password`](raketasks/smtp.md#secrets)。

暗号化された設定を有効にするには、`encrypted_settings_key_base`の新しいベースキーを生成する必要があります。シークレットは、次の方法で生成できます:

- Linux packageインストールの場合は、新しいシークレットが自動的に生成されますが、`/etc/gitlab/gitlab-secrets.json`にすべてのノードで同じ値が含まれていることを確認する必要があります。
- Helmチャートインストールの場合は、`shared-secrets`チャートが有効になっている場合、新しいシークレットが自動的に生成されます。それ以外の場合は、[シークレットを追加するためのシークレットガイド](https://docs.gitlab.com/charts/installation/secrets.html#gitlab-rails-secret)に従う必要があります。
- セルフコンパイルインストールの場合、新しいシークレットは次を実行して生成できます:

  ```shell
  bundle exec rake gitlab:env:info RAILS_ENV=production GITLAB_GENERATE_ENCRYPTED_SETTINGS_KEY_BASE=true
  ```

  これは、GitLabインスタンスに関する一般的な情報を出力し、`<path-to-gitlab-rails>/config/secrets.yml`にキーを生成します。
