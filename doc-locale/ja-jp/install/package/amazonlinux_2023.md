---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: Amazon Linux 2023にLinuxパッケージをインストールする
title: Amazon Linux 2023にLinuxパッケージをインストールする
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

{{< alert type="note" >}}

サポートされているディストリビューションとアーキテクチャの完全なリストについては、[サポートされているプラットフォーム](_index.md#supported-platforms)を参照してください。

{{< /alert >}}

## 前提要件 {#prerequisites}

- OS要件:
  - Amazon Linux 2023
- 最小ハードウェア要件については、[インストール要件](../requirements.md)を参照してください。
- 開始する前に、[DNSを設定](https://docs.gitlab.com/omnibus/settings/dns)していることを確認してください。次のコマンドの`https://gitlab.example.com`を、お好みのGitLab URLに置き換えてください。GitLabは、そのアドレスで自動的に構成され、開始されます。
- `https://` URLの場合、GitLabは自動的に[Let's Encryptで証明書をリクエストします](https://docs.gitlab.com/omnibus/settings/ssl/#enable-the-lets-encrypt-integration)。これには、受信HTTPアクセスと有効なホスト名が必要です。[独自の証明書](https://docs.gitlab.com/omnibus/settings/ssl/#configure-https-manually)を使用することも、暗号化されていないURLの場合は`http://`（`s`なし）を使用することもできます。

## SSHを有効にして、ファイアウォールポートを開きます {#enable-ssh-and-open-firewall-ports}

必要なファイアウォールポート (80, 443, 22) を開き、GitLabにアクセスできるようにするには:

1. OpenSSHサーバーデーモンを有効にして起動します:

   ```shell
   sudo systemctl enable --now sshd
   ```

1. `firewalld`がインストールされている状態で、ファイアウォールポートを開きます:

   ```shell
   sudo firewall-cmd --permanent --add-service=http
   sudo firewall-cmd --permanent --add-service=https
   sudo firewall-cmd --permanent --add-service=ssh
   sudo systemctl reload firewalld
   ```

## GitLabパッケージリポジトリを追加します {#add-the-gitlab-package-repository}

GitLabをインストールするには、まずGitLabパッケージリポジトリを追加します。

1. 必要なパッケージをインストールします:

   ```shell
   sudo dnf install -y curl
   ```

1. 次のスクリプトを使用してGitLabリポジトリを追加します（スクリプトのURLをブラウザーに貼り付けて、`bash`にパイプする前に何をするかを確認できます）:

   {{< tabs >}}

   {{< tab title="Enterprise Edition" >}}

   ```shell
   curl "https://packages.gitlab.com/install/repositories/gitlab/gitlab-ee/script.rpm.sh" | sudo bash
   ```

   {{< /tab >}}

   {{< tab title="Community Edition" >}}

   ```shell
   curl "https://packages.gitlab.com/install/repositories/gitlab/gitlab-ce/script.rpm.sh" | sudo bash
   ```

   {{< /tab >}}

   {{< /tabs >}}

## パッケージをインストールします {#install-the-package}

システムのパッケージマネージャーを使用してGitLabをインストールします。

{{< alert type="note" >}}

`EXTERNAL_URL`の設定はオプションですが、推奨されています。インストール中に設定しない場合は、[後で設定する](https://docs.gitlab.com/omnibus/settings/configuration/#configure-the-external-url-for-gitlab)ことができます。

{{< /alert >}}

{{< tabs >}}

{{< tab title="Enterprise Edition" >}}

```shell
sudo EXTERNAL_URL="https://gitlab.example.com" dnf install gitlab-ee
```

{{< /tab >}}

{{< tab title="Community Edition" >}}

```shell
sudo EXTERNAL_URL="https://gitlab.example.com" dnf install gitlab-ce
```

{{< /tab >}}

{{< /tabs >}}

GitLabは、root管理者アカウントのランダムなパスワードとメールアドレスを生成し、24時間`/etc/gitlab/initial_root_password`に保存します。24時間後、このファイルはセキュリティ上の理由から自動的に削除されます。

## 最初のサインイン {#initial-sign-in}

GitLabがインストールされたら、セットアップしたURLにアクセスし、次の認証情報を使用してサインインします:

- ユーザー名: `root`
- パスワード: `/etc/gitlab/initial_root_password`を参照してください

サインイン後、[パスワード](../../user/profile/user_passwords.md#change-your-password)と[メールアドレス](../../user/profile/_index.md#add-emails-to-your-user-profile)を変更します。

## 高度な設定 {#advanced-configuration}

インストール前に次のオプションの環境変数を設定して、GitLabインストールをカスタマイズできます。**これらの変数は、最初のインストール中にのみ機能します**。また、後続の再構成の実行には影響しません。既存のインストールの場合、`/etc/gitlab/initial_root_password`のパスワードを使用するか、[rootパスワードをリセットします](../../security/reset_user_password.md)。

| 変数 | 目的 | 必須 | 例 |
|----------|---------|----------|---------|
| `EXTERNAL_URL` | GitLabインスタンスの外部URLを設定します | 推奨 | `EXTERNAL_URL="https://gitlab.example.com"` |
| `GITLAB_ROOT_EMAIL` | root管理者アカウントのカスタムメール | オプション | `GITLAB_ROOT_EMAIL="admin@example.com"` |
| `GITLAB_ROOT_PASSWORD` | root管理者アカウントのカスタムパスワード（最小8文字） | オプション | `GITLAB_ROOT_PASSWORD="strongpassword"` |

{{< alert type="note" >}} GitLabがインストール中に有効なホスト名を検出できない場合、再構成は自動的に実行されません。この場合、必要な環境変数を最初の`gitlab-ctl reconfigure`コマンドに渡します。{{< /alert >}}

{{< alert type="warning" >}}

`gitlab_rails['initial_root_password']`を設定して`/etc/gitlab/gitlab.rb`に初期パスワードを設定することもできますが、推奨されません。パスワードがクリアテキストであるため、セキュリティ上のリスクがあります。これを構成している場合は、インストール後に必ず削除してください。

{{< /alert >}}

GitLabエディションを選択し、上記の環境変数でカスタマイズします:

{{< tabs >}}

{{< tab title="Enterprise Edition" >}}

```shell
sudo GITLAB_ROOT_EMAIL="admin@example.com" GITLAB_ROOT_PASSWORD="strongpassword" EXTERNAL_URL="https://gitlab.example.com" dnf install gitlab-ee
```

{{< /tab >}}

{{< tab title="Community Edition" >}}

```shell
sudo GITLAB_ROOT_EMAIL="admin@example.com" GITLAB_ROOT_PASSWORD="strongpassword" EXTERNAL_URL="https://gitlab.example.com" dnf install gitlab-ce
```

{{< /tab >}}

{{< /tabs >}}

## コミュニケーションの設定 {#set-up-your-communication-preferences}

[メールサブスクリプション設定センター](https://about.gitlab.com/company/preference-center/)にアクセスして、連絡が必要な時期をお知らせください。メールの明示的なオプトインポリシーがあるため、メールの送信内容と頻度を完全に制御できます。

月に2回、新機能、インテグレーション、ドキュメント、開発チームからの舞台裏ストーリーなど、知っておく必要のあるGitLabニュースをお届けします。バグやシステムパフォーマンスに関連する重要なセキュリティ更新については、専用のセキュリティニュースレターにサインアップしてください。

{{< alert type="note" >}}

セキュリティニュースレターにオプトインしない場合、セキュリティアラートは届きません。

{{< /alert >}}

## 推奨される次のステップ {#recommended-next-steps}

インストールが完了したら、[推奨される次のステップ（認証オプションやサインアップ制限など）](../next_steps.md)を検討してください。
