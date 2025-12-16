---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: Amazon Linux 2にLinuxパッケージをインストール
title: Amazon Linux 2にLinuxパッケージをインストール
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
  - Amazon Linux 2
- 最小ハードウェア要件については、[インストール要件](../requirements.md)を参照してください。
- 開始する前に、[DNSを設定](https://docs.gitlab.com/omnibus/settings/dns)していることを確認してください。次のコマンドの`https://gitlab.example.com`を、希望するGitLab URLに置き換えてください。GitLabは、そのアドレスで自動的に構成され、起動されます。
- `https://` URLの場合、GitLabは自動的に[Let's Encryptで証明書をリクエストします](https://docs.gitlab.com/omnibus/settings/ssl/#enable-the-lets-encrypt-integration)。これには、受信HTTPアクセスと有効なホスト名が必要です。[独自の証明書](https://docs.gitlab.com/omnibus/settings/ssl/#configure-https-manually)を使用することも、`http://`（`s`なし）を暗号化されたURLに使用することもできます。

## SSHを有効にし、ファイアウォールポートを開きます {#enable-ssh-and-open-firewall-ports}

必要なファイアウォールポート（80、443、22）を開き、GitLabにアクセスできるようにするには、次の手順を実行します:

1. OpenSSHサーバーデーモンを有効にして起動します:

   ```shell
   sudo systemctl enable --now sshd
   ```

1. `firewalld`がインストールされた状態で、ファイアウォールポートを開きます:

   ```shell
   sudo firewall-cmd --permanent --add-service=http
   sudo firewall-cmd --permanent --add-service=https
   sudo firewall-cmd --permanent --add-service=ssh
   sudo systemctl reload firewalld
   ```

## GitLabパッケージリポジトリを追加する {#add-the-gitlab-package-repository}

GitLabをインストールするには、まずGitLabパッケージリポジトリを追加します。

1. 必要なパッケージをインストールします:

   ```shell
   sudo yum install -y curl
   ```

1. 次のスクリプトを使用してGitLabリポジトリを追加します（スクリプトのURLをブラウザに貼り付けて、`bash`にパイプする前に何をするかを確認できます）:

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

`EXTERNAL_URL`の設定はオプションですが、推奨されます。インストール中に設定しなかった場合は、[後で設定](https://docs.gitlab.com/omnibus/settings/configuration/#configure-the-external-url-for-gitlab)できます。

{{< /alert >}}

{{< tabs >}}

{{< tab title="Enterprise Edition" >}}

```shell
sudo EXTERNAL_URL="https://gitlab.example.com" yum install gitlab-ee
```

{{< /tab >}}

{{< tab title="Community Edition" >}}

```shell
sudo EXTERNAL_URL="https://gitlab.example.com" yum install gitlab-ce
```

{{< /tab >}}

{{< /tabs >}}

GitLabは、管理者アカウントのランダムな認証情報とメールアドレスを生成し、24時間`/etc/gitlab/initial_root_password`に保存します。24時間後、このファイルはセキュリティ上の理由から自動的に削除されます。

## 最初のサインイン {#initial-sign-in}

GitLabのインストール後、セットアップしたURLにアクセスし、次の認証情報を使用してサインインします:

- ユーザー名: `root`
- パスワード: `/etc/gitlab/initial_root_password`を参照してください

サインインしたら、[パスワード](../../user/profile/user_passwords.md#change-your-password)と[メールアドレス](../../user/profile/_index.md#add-emails-to-your-user-profile)を変更します。

## 高度な設定 {#advanced-configuration}

インストール前に次のオプションの環境変数を設定して、GitLabインストールをカスタマイズできます。**これらの変数は、最初のインストール中にのみ機能します**。また、後続の再構成の実行には影響しません。既存のインストールでは、`/etc/gitlab/initial_root_password`のパスワードを使用するか、[管理者のルートパスワードをリセット](../../security/reset_user_password.md)します。

| 変数 | 目的 | 必須 | 例 |
|----------|---------|----------|---------|
| `EXTERNAL_URL` | GitLabインスタンスの外部URLを設定します | 推奨 | `EXTERNAL_URL="https://gitlab.example.com"` |
| `GITLAB_ROOT_EMAIL` | 管理者のルートアカウントのカスタムメール | オプション | `GITLAB_ROOT_EMAIL="admin@example.com"` |
| `GITLAB_ROOT_PASSWORD` | 管理者のルートアカウントのカスタムパスワード（最低8文字） | オプション | `GITLAB_ROOT_PASSWORD="strongpassword"` |

{{< alert type="note" >}} GitLabがインストール中に有効なホスト名を検出できない場合、再構成は自動的に実行されません。この場合、必要な環境変数を最初の`gitlab-ctl reconfigure`コマンドに渡します。{{< /alert >}}

{{< alert type="warning" >}}

`gitlab_rails['initial_root_password']`を設定して`/etc/gitlab/gitlab.rb`で初期パスワードを設定することもできますが、お勧めしません。パスワードがクリアテキストであるため、セキュリティ上のリスクがあります。これを設定している場合は、インストール後に必ず削除してください。

{{< /alert >}}

GitLabエディションを選択し、上記の環境変数でカスタマイズします:

{{< tabs >}}

{{< tab title="Enterprise Edition" >}}

```shell
sudo GITLAB_ROOT_EMAIL="admin@example.com" GITLAB_ROOT_PASSWORD="strongpassword" EXTERNAL_URL="https://gitlab.example.com" yum install gitlab-ee
```

{{< /tab >}}

{{< tab title="Community Edition" >}}

```shell
sudo GITLAB_ROOT_EMAIL="admin@example.com" GITLAB_ROOT_PASSWORD="strongpassword" EXTERNAL_URL="https://gitlab.example.com" yum install gitlab-ce
```

{{< /tab >}}

{{< /tabs >}}

## コミュニケーション設定を行う {#set-up-your-communication-preferences}

コミュニケーションが必要なときに知らせるには、[メールサブスクリプション設定センター](https://about.gitlab.com/company/preference-center/)にアクセスしてください。当社には明示的なメールオプトインポリシーがあるため、お客様に送信するメールの内容と頻度を完全に制御できます。

月に2回、新機能、インテグレーション、ドキュメント、および開発チームからの舞台裏ストーリーなど、知っておく必要のあるGitLabニュースを送信します。バグやシステムのパフォーマンスに関連する重要なセキュリティアップデートについては、専用のセキュリティニュースレターにサインアップしてください。

{{< alert type="note" >}}

セキュリティニュースレターにオプトインしないと、セキュリティアラートは届きません。

{{< /alert >}}

## 推奨される次のステップ {#recommended-next-steps}

インストールが完了したら、[推奨される次のステップ（認証オプションやサインアップ制限など）](../next_steps.md)を検討してください。
