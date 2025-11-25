---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: パスワードメンテナンスRakeタスク
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

GitLabは、パスワードを管理するためのRakeタスクを提供します。

## パスワードのリセット {#reset-passwords}

Rakeタスクを使用してパスワードをリセットするには、[ユーザーパスワードのリセット](../../security/reset_user_password.md#use-a-rake-task)を参照してください。

## パスワードハッシュの確認 {#check-password-hashes}

GitLab 17.11以降、ユーザーがサインインすると、FIPSインスタンス上のパスワードハッシュのソルトが増加します。

FIPS以外のインスタンスでは、GitLab 17.9で更新されたbcryptワークファクターの使用を開始しました。

移行されていないパスワードハッシュを持つユーザー数を確認できます:

```shell
# omnibus-gitlab
sudo gitlab-rake gitlab:password:check_hashes:[true]

# installation from source
bundle exec rake gitlab:password:check_hashes:[true] RAILS_ENV=production
```

注: GitLab 18.6より前は、このタスクは`gitlab:password:fips_check_salts`として利用可能であり、FIPS/PBKDF2ハッシュ検証に限定されていました。このタスクは`:check_hashes`に名前が変更され、現在はすべてのパスワード移行をチェックするようになり、古い名前はエイリアスとして残っています。
