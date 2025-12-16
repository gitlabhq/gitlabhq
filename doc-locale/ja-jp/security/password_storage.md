---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: パスワードとOAuthトークンのストレージ
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

GitLabの管理者は、パスワードとOAuthトークンの保存方法を設定できます。

## パスワードストレージ {#password-storage}

{{< history >}}

- GitLab 15.2でPBKDF2+SHA512が[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/360658)されました（`pbkdf2_password_encryption`と`pbkdf2_password_encryption_write`という名前の[with flags](../administration/feature_flags/_index.md)）。デフォルトでは無効になっています。
- 機能フラグはGitLab 15.6で[削除](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/101691)され、PBKDF2+SHA512はFIPSモードで実行されているすべてのGitLabインスタンスで使用できるようになりました。

{{< /history >}}

GitLabは、パスワードがプレーンテキストとして保存されないように、ユーザーパスワードをハッシュ形式で保存します。

GitLabは、[Devise](https://github.com/heartcombo/devise)認証ライブラリを使用してユーザーパスワードをハッシュ化します。作成されたパスワードハッシュには、次の属性があります:

- **ハッシュ**:
  - **bcrypt**: [`bcrypt`](https://en.wikipedia.org/wiki/Bcrypt)ハッシュ関数はデフォルトで、提供されたパスワードのハッシュを生成するために使用されます。この暗号学的ハッシュ関数は、強力で業界標準です。
  - **PBKDF2+SHA512**: PBKDF2+SHA512は以下でサポートされています:
    - `pbkdf2_password_encryption`および`pbkdf2_password_encryption_write` [機能フラグ](../administration/feature_flags/_index.md)が有効になっている場合、GitLab 15.2からGitLab 15.5。
    - FIPSモードが有効になっている場合、GitLab 15.6以降（機能フラグは不要）。
- **ストレッチ**: パスワードハッシュは、ブルートフォース攻撃に対する強化のために[ストレッチ](https://en.wikipedia.org/wiki/Key_stretching)されます。デフォルトでは、GitLabはbcryptの場合は10、PBKDF2 + SHA512の場合は20,000のストレッチ係数を使用します。
- **ソルティング**: 各パスワードに[暗号学的](https://en.wikipedia.org/wiki/Salt_(cryptography))ソルトが追加され、事前計算されたハッシュおよび辞書攻撃に対する強化が行われます。セキュリティを向上させるために、各ソルトはパスワードごとにランダムに生成され、2つのパスワードがソルトを共有することはありません。

## OAuthアクセストークンストレージ {#oauth-access-token-storage}

{{< history >}}

- `hash_oauth_tokens`という名前の[フラグ](../administration/feature_flags/_index.md)を使用して、PBKDF2+SHA512がGitLab 15.3で導入されました。
- GitLab 15.5で[デフォルトで有効](https://gitlab.com/gitlab-org/gitlab/-/issues/367570)になりました。
- GitLab 15.6で[機能フラグ](https://gitlab.com/gitlab-org/gitlab/-/issues/367570)は削除されました。

{{< /history >}}

OAuthアクセストークンは、PBKDF2+SHA512形式でデータベースに保存されます。PBKDF2+SHA512パスワードストレージと同様に、アクセストークンの値は、ブルートフォース攻撃に対する強化のために20,000回[ストレッチ](https://en.wikipedia.org/wiki/Key_stretching)されます。
