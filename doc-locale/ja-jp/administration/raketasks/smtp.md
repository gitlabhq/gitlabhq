---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: SMTP Rakeタスク
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

以下は、SMTP関連のRakeタスクです。

## シークレット {#secrets}

GitLabは、暗号化されたファイルから読み取るために、SMTP設定シークレットを使用できます。次のRakeタスクは、暗号化されたファイルの内容を更新するために提供されています。

### シークレットを表示 {#show-secret}

現在のSMTPシークレットの内容を表示します。

- Linuxパッケージインストール:

  ```shell
  sudo gitlab-rake gitlab:smtp:secret:show
  ```

- 自己コンパイルによるインストール:

  ```shell
  bundle exec rake gitlab:smtp:secret:show RAILS_ENV=production
  ```

**Example output**（出力例）:

```plaintext
password: '123'
user_name: 'gitlab-inst'
```

### シークレットをエディタで編集 {#edit-secret}

シークレットの内容をエディタで開き、終了時に結果の内容を暗号化されたシークレットファイルに書き込みます。

- Linuxパッケージインストール:

  ```shell
  sudo gitlab-rake gitlab:smtp:secret:edit EDITOR=vim
  ```

- 自己コンパイルによるインストール:

  ```shell
  bundle exec rake gitlab:smtp:secret:edit RAILS_ENV=production EDITOR=vim
  ```

### rawシークレットを書き込む {#write-raw-secret}

`STDIN`で新しいシークレットコンテンツを書き込みます。

- Linuxパッケージインストール:

  ```shell
  echo -e "password: '123'" | sudo gitlab-rake gitlab:smtp:secret:write
  ```

- 自己コンパイルによるインストール:

  ```shell
  echo -e "password: '123'" | bundle exec rake gitlab:smtp:secret:write RAILS_ENV=production
  ```

### シークレットの例 {#secrets-examples}

**Editor example**（エディタの例）

書き込みタスクは、編集コマンドがエディタで機能しない場合に使用できます:

```shell
# Write the existing secret to a plaintext file
sudo gitlab-rake gitlab:smtp:secret:show > smtp.yaml
# Edit the smtp file in your editor
...
# Re-encrypt the file
cat smtp.yaml | sudo gitlab-rake gitlab:smtp:secret:write
# Remove the plaintext file
rm smtp.yaml
```

**KMS integration example**（KMSインテグレーションの例）

KMSで暗号化されたコンテンツの受信アプリケーションとしても使用できます:

```shell
gcloud kms decrypt --key my-key --keyring my-test-kms --plaintext-file=- --ciphertext-file=my-file --location=us-west1 | sudo gitlab-rake gitlab:smtp:secret:write
```

**Google Cloud secret integration example**（Google Cloudシークレットインテグレーションの例）

Google Cloudからシークレットを受信するアプリケーションとしても使用できます:

```shell
gcloud secrets versions access latest --secret="my-test-secret" > $1 | sudo gitlab-rake gitlab:smtp:secret:write
```
