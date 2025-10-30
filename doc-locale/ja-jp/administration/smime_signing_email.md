---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: S/MIMEで送信メールに署名する
description: 送信メールのS/MIMEを設定します。
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

GitLabから送信される通知メールは、セキュリティ向上のためS/MIMEで署名できます。

S/MIME証明書とTLS/SSL証明書は同じではなく、異なる目的に使用されることに注意してください: TLSはセキュアなチャンネルを作成しますが、S/MIMEはメッセージ自体に署名または暗号化されたを行います。

## S/MIME署名を有効にする {#enable-smime-signing}

この設定は明示的に有効にする必要があり、キーと証明書ファイルの単一のペアを提供する必要があります:

- 両方のファイルがPEMエンコードされている必要があります。
- キーファイルは、GitLabがユーザーの操作なしに読み取りできるように、暗号化されていない必要があります。
- RSAキーのみがサポートされています。

オプションで、各署名に含める認証局証明書のバンドル（PEMエンコード）を提供することもできます。これは通常、中間認証局です。

{{< alert type="warning" >}}

プライベートキーのアクセスレベルと、サードパーティへの表示レベルに注意してください。

{{< /alert >}}

Linuxパッケージインストールの場合:

1. `/etc/gitlab/gitlab.rb`を編集して、ファイルパスを調整します:

   ```ruby
   gitlab_rails['gitlab_email_smime_enabled'] = true
   gitlab_rails['gitlab_email_smime_key_file'] = '/etc/gitlab/ssl/gitlab_smime.key'
   gitlab_rails['gitlab_email_smime_cert_file'] = '/etc/gitlab/ssl/gitlab_smime.crt'
   # Optional
   gitlab_rails['gitlab_email_smime_ca_certs_file'] = '/etc/gitlab/ssl/gitlab_smime_cas.crt'
   ```

1. ファイルを保存して、[GitLabを再設定](restart_gitlab.md#reconfigure-a-linux-package-installation)し、変更を有効にします。

キーは、GitLabシステムユーザー（`git`がデフォルト）が読み取り可能である必要があります。

自己コンパイルによるインストールの場合: 

1. `config/gitlab.yml`を編集します:

   ```yaml
   email_smime:
     # Uncomment and set to true if you need to enable email S/MIME signing (default: false)
     enabled: true
     # S/MIME private key file in PEM format, unencrypted
     # Default is '.gitlab_smime_key' relative to Rails.root (the root of the GitLab app).
     key_file: /etc/pki/smime/private/gitlab.key
     # S/MIME public certificate key in PEM format, will be attached to signed messages
     # Default is '.gitlab_smime_cert' relative to Rails.root (the root of the GitLab app).
     cert_file: /etc/pki/smime/certs/gitlab.crt
     # S/MIME extra CA public certificates in PEM format, will be attached to signed messages
     # Optional
     ca_certs_file: /etc/pki/smime/certs/gitlab_cas.crt
   ```

1. ファイルを保存して、[GitLabを再起動](restart_gitlab.md#self-compiled-installations)し、変更を有効にします。

キーは、GitLabシステムユーザー（`git`がデフォルト）が読み取り可能である必要があります。

### S/MIME PKCS #12形式をPEMエンコードに変換する方法 {#how-to-convert-smime-pkcs-12-format-to-pem-encoding}

通常、S/MIME証明書は、バイナリ公開キー暗号化標準（PKCS）#12形式（`.pfx`または`.p12`拡張子）で処理されます。これには、次のものが単一の暗号化されたファイルに含まれています:

- 公開証明書
- 中間証明書（存在する場合）
- 秘密キー

PKCS #12ファイルから必要なファイルをPEMエンコードでエクスポートするには、`openssl`コマンドを使用できます:

```shell
#-- Extract private key in PEM encoding (no password, unencrypted)
$ openssl pkcs12 -in gitlab.p12 -nocerts -nodes -out gitlab.key

#-- Extract certificates in PEM encoding (full certs chain including CA)
$ openssl pkcs12 -in gitlab.p12 -nokeys -out gitlab.crt
```
