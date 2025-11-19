---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: 受信メールRakeタスク
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

{{< history >}}

- GitLab 15.9で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/108279)されました。

{{< /history >}}

以下は、受信メール関連のRakeタスクです。

## シークレット {#secrets}

GitLabでは、[受信メール](../incoming_email.md)のシークレットを、ファイルシステムに平文で保存する代わりに、暗号化されたファイルから読み取ることができます。次のRakeタスクは、暗号化されたファイルの内容を更新するために提供されています。

### シークレットの表示 {#show-secret}

現在の受信メールシークレットの内容を表示します。

{{< tabs >}}

{{< tab title="Linuxパッケージ（Omnibus）" >}}

```shell
sudo gitlab-rake gitlab:incoming_email:secret:show
```

{{< /tab >}}

{{< tab title="Helmチャート（Kubernetes）" >}}

Kubernetesのシークレットを使用して、受信メールのパスワードを保存します。詳細については、[Helm IMAPシークレット](https://docs.gitlab.com/charts/installation/secrets.html#imap-password-for-incoming-emails)を参照してください。

{{< /tab >}}

{{< tab title="Docker" >}}

```shell
sudo docker exec -t <container name> gitlab:incoming_email:secret:show
```

{{< /tab >}}

{{< tab title="自己コンパイル（ソース）" >}}

```shell
bundle exec rake gitlab:incoming_email:secret:show RAILS_ENV=production
```

{{< /tab >}}

{{< /tabs >}}

#### 出力例: {#example-output}

```plaintext
password: 'examplepassword'
user: 'incoming-email@mail.example.com'
```

### シークレットの編集 {#edit-secret}

エディタでシークレットの内容を開き、終了時に結果の内容を暗号化されたシークレットファイルに書き込みます。

{{< tabs >}}

{{< tab title="Linuxパッケージ（Omnibus）" >}}

```shell
sudo gitlab-rake gitlab:incoming_email:secret:edit EDITOR=vim
```

{{< /tab >}}

{{< tab title="Helmチャート（Kubernetes）" >}}

Kubernetesのシークレットを使用して、受信メールのパスワードを保存します。詳細については、[Helm IMAPシークレット](https://docs.gitlab.com/charts/installation/secrets.html#imap-password-for-incoming-emails)を参照してください。

{{< /tab >}}

{{< tab title="Docker" >}}

```shell
sudo docker exec -t <container name> gitlab:incoming_email:secret:edit EDITOR=editor
```

{{< /tab >}}

{{< tab title="自己コンパイル（ソース）" >}}

```shell
bundle exec rake gitlab:incoming_email:secret:edit RAILS_ENV=production EDITOR=vim
```

{{< /tab >}}

{{< /tabs >}}

### Rawシークレットの書き込み {#write-raw-secret}

`STDIN`で新しいシークレットコンテンツを書き込みます。

{{< tabs >}}

{{< tab title="Linuxパッケージ（Omnibus）" >}}

```shell
echo -e "password: 'examplepassword'" | sudo gitlab-rake gitlab:incoming_email:secret:write
```

{{< /tab >}}

{{< tab title="Helmチャート（Kubernetes）" >}}

Kubernetesのシークレットを使用して、受信メールのパスワードを保存します。詳細については、[Helm IMAPシークレット](https://docs.gitlab.com/charts/installation/secrets.html#imap-password-for-incoming-emails)を参照してください。

{{< /tab >}}

{{< tab title="Docker" >}}

```shell
sudo docker exec -t <container name> /bin/bash
echo -e "password: 'examplepassword'" | gitlab-rake gitlab:incoming_email:secret:write
```

{{< /tab >}}

{{< tab title="自己コンパイル（ソース）" >}}

```shell
echo -e "password: 'examplepassword'" | bundle exec rake gitlab:incoming_email:secret:write RAILS_ENV=production
```

{{< /tab >}}

{{< /tabs >}}

### シークレットの例 {#secrets-examples}

**Editor example**（エディタの例）

書き込みタスクは、編集コマンドがエディタで動作しない場合に使用できます:

```shell
# Write the existing secret to a plaintext file
sudo gitlab-rake gitlab:incoming_email:secret:show > incoming_email.yaml
# Edit the incoming_email file in your editor
...
# Re-encrypt the file
cat incoming_email.yaml | sudo gitlab-rake gitlab:incoming_email:secret:write
# Remove the plaintext file
rm incoming_email.yaml
```

**KMS integration example**（KMSインテグレーションの例）

KMSで暗号化されたコンテンツの受信アプリケーションとしても使用できます:

```shell
gcloud kms decrypt --key my-key --keyring my-test-kms --plaintext-file=- --ciphertext-file=my-file --location=us-west1 | sudo gitlab-rake gitlab:incoming_email:secret:write
```

**Google Cloud secret integration example**（Google Cloudシークレットインテグレーションの例）

Google Cloudからシークレットを受信アプリケーションとしても使用できます:

```shell
gcloud secrets versions access latest --secret="my-test-secret" > $1 | sudo gitlab-rake gitlab:incoming_email:secret:write
```
