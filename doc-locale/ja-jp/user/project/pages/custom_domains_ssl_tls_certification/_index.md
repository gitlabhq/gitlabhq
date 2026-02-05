---
stage: Plan
group: Knowledge
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitLab Pagesカスタムドメイン
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed

{{< /details >}}

カスタムドメインは、以下で使用できます:

- GitLab Pages。
- [SAMLまたはSCIMプロビジョニングされたユーザーのユーザーメール確認をバイパスする](../../../group/saml_sso/_index.md#bypass-user-email-confirmation-with-verified-domains)。このようにカスタムドメインを使用する場合、GitLab Pages機能を使用しますが、[prerequisites](#prerequisites)をスキップできます。

1つまたは複数のカスタムドメイン名を使用するには:

- [カスタムルートドメインまたはサブドメイン](#set-up-a-custom-domain)を追加します。
- [SSL/TLS証明書](#add-an-ssltls-certificate-to-pages)を追加します。

> [!warning] [最も一般的なパブリックメールドメイン](../../../group/access_and_permissions.md#restrict-group-access-by-domain)は確認できません。

## カスタムドメインの設定 {#set-up-a-custom-domain}

カスタムドメインでPagesを設定するには、以下の手順を実行します。

### 前提条件 {#prerequisites}

- 管理者が[GitLab Pagesカスタムドメイン](../../../../administration/pages/_index.md#advanced-configuration)のサーバーを設定しました。
- GitLab PagesのWebサイトが稼働中で、デフォルトのPagesドメイン（`*.gitlab.io`、GitLab.comの場合）で提供されています。
- カスタムドメイン名`example.com`またはサブドメイン`subdomain.example.com`。
- DNSレコードをセットアップするための、ドメインのサーバーコントロールパネルへのアクセス:
  - ドメインをGitLab Pagesサーバーに向けるDNSレコード（`A`、`AAAA`、`ALIAS`、または`CNAME`）。その名前に複数のDNSレコードがある場合は、`ALIAS`レコードを使用する必要があります。
  - ドメインの所有権を検証するためのDNS `TXT`レコード。

DNSレコードの概要については、[GitLab PagesDNSレコード](dns_concepts.md)を参照してください。

### ステップ1: カスタムドメインの追加 {#step-1-add-a-custom-domain}

カスタムドメインをGitLab Pagesに追加するには:

1. 上部のバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **デプロイ** > **Pages**を選択します。
1. 右上隅で、**新しいドメイン**を選択します。
1. **ドメイン**に、ドメイン名を入力します。
1. オプション。**証明書**で、**Let's Encryptを用いた自動証明書管理**切替をオフにして、[SSL/TLS証明書](#add-an-ssltls-certificate-to-pages)を追加します。後で証明書とキーを追加することもできます。証明書とキーは後で追加することもできます。
1. **Create New Domain**を選択します。

### ステップ2: 検証コードの取得 {#step-2-get-the-verification-code}

Pagesに新しいドメインを追加すると、GitLabは検証コードを表示します。値をコピーし、次の手順でドメインのコントロールパネルに`TXT`レコードとして貼り付けます。

![新しいドメイン用に生成された検証コードを示すGitLab Pages。](img/get_domain_verification_code_v12_0.png)

**検証ステータス**フィールドの構造は次のとおりです:

- 名前/ホスト:
  - ルートドメインの場合：`_gitlab-pages-verification-code.example.com`
  - サブドメインの場合：`_gitlab-pages-verification-code.subdomain.example.com`
- DNSレコードタイプ：`TXT`
- 値：`gitlab-pages-verification-code=00112233445566778899aabbccddeeff`（GitLabからの実際のコードを使用）

> [!note] Cloudflareなどの一部のDNSプロバイダーは、ドメイン名を[名前]または[ホスト]フィールドに自動的に追加します。プロバイダーがこれを行う場合は、ルートドメインの場合は`_gitlab-pages-verification-code`、サブドメインの場合は`_gitlab-pages-verification-code.subdomain`のみを入力します。

### ステップ3: DNSレコードの設定 {#step-3-set-up-dns-records}

Pagesサイトで使用するドメインのタイプに従ってDNSレコードを設定するには、次のいずれかを選択します:

- [ルートドメインの場合](#for-root-domains)
- [サブドメインの場合](#for-subdomains)
- [ルートドメインとサブドメインの両方の場合](#for-both-root-and-subdomains)

#### ルートドメインの場合 {#for-root-domains}

ルートドメイン（`example.com`）には、以下が必要です:

- 少なくとも1つ:
  - ドメインをPagesサーバーに向ける[DNS `A`レコード](dns_concepts.md#a-record)。
  - ドメインをPagesサーバーに向ける[DNS `AAAA`レコード](dns_concepts.md#aaaa-record)。
- ドメインの所有権を検証するための[`TXT`レコード](dns_concepts.md#txt-record)。

| 送信元                                          | DNSレコード | 宛先              |
| --------------------------------------------- | ---------- | --------------- |
| `example.com`                                 | `A`        | `35.185.44.232` |
| `example.com`                                 | `AAAA`     | `2600:1901:0:7b8a::` |
| `_gitlab-pages-verification-code.example.com` | `TXT`      | `gitlab-pages-verification-code=00112233445566778899aabbccddeeff` |

GitLab.comのプロジェクトの場合、IPv4アドレスは`35.185.44.232`、IPv6アドレスは`2600:1901:0:7b8a::`です。

他のGitLabインスタンス（CEまたはEE）のプロジェクトの場合は、システム管理者に連絡して、インスタンスのPagesサーバーIPアドレスをリクエストしてください。

![GitLab Pagesサーバーに追加されたAレコードを示すDNS設定画面。](img/dns_add_new_a_record_v11_2.png)

> [!warning]ルートドメインに`A`または`AAAA`レコードの代わりにDNSアペックス`CNAME`レコードを使用しないでください。ルートドメインの[`MX`DNSレコード](dns_concepts.md#mx-record)を設定した場合、このメソッドはほとんどの場合機能しません。

#### サブドメインの場合 {#for-subdomains}

サブドメイン（`subdomain.example.com`）には、以下が必要です:

- サブドメインをPagesサーバーに向ける[DNS `ALIAS`または`CNAME`レコード](dns_concepts.md#cname-record)。
- ドメインの所有権を検証するための[DNS `TXT`レコード](dns_concepts.md#txt-record)。

| 送信元                                                    | DNSレコード      | 宛先 |
|---------------------------------------------------------|-----------------|----|
| `subdomain.example.com`                                 | `ALIAS`/`CNAME` | `namespace.gitlab.io` |
| `_gitlab-pages-verification-code.subdomain.example.com` | `TXT`           | `gitlab-pages-verification-code=00112233445566778899aabbccddeeff` |

ユーザーまたはプロジェクトのWebサイトであるかどうかにかかわらず、DNSレコードは、パスなしで、Pagesドメイン（`namespace.gitlab.io`）を指している必要があります。

#### ルートドメインとサブドメインの両方の場合 {#for-both-root-and-subdomains}

たとえば、ルートドメインとサブドメインの両方を同じWebサイト（`example.com`や`www.example.com`など）に向けるには、以下が必要です:

- ドメインのDNS `A`レコード。
- ドメインのDNS `AAAA`レコード。
- サブドメインのDNS `ALIAS`/`CNAME`レコード。
- それぞれのDNS `TXT`レコード。

| 送信元                                              | DNSレコード | 宛先 |
|---------------------------------------------------|------------|----|
| `example.com`                                     | `A`        | `35.185.44.232` |
| `example.com`                                     | `AAAA`     | `2600:1901:0:7b8a::` |
| `_gitlab-pages-verification-code.example.com`     | `TXT`      | `gitlab-pages-verification-code=00112233445566778899aabbccddeeff` |
| `www.example.com`                                 | `CNAME`    | `namespace.gitlab.io` |
| `_gitlab-pages-verification-code.www.example.com` | `TXT`      | `gitlab-pages-verification-code=00112233445566778899aabbccddeeff` |

Cloudflareを使用している場合は、[Cloudflareを使用して`www.domain.com`から`domain.com`にリダイレクトする](#redirect-wwwdomaincom-to-domaincom-with-cloudflare)を参照してください。

追加の注意点:

- `CNAME`をGitLab Pagesサイトに向ける場合は、`domain.com`レコードを使用しないでください。代わりに`A`レコードを使用してください。
- デフォルトのPagesドメインの後に特殊文字を追加しないでください。たとえば、`subdomain.domain.com`をまたは`namespace.gitlab.io/`にポイントしないでください。一部のドメインホスティングプロバイダーは、末尾のドット（`namespace.gitlab.io.`）をリクエストする場合があります。
- GitLab.comのGitLab PagesIPは、2017年に[変更されました](https://about.gitlab.com/releases/2017/03/06/we-are-changing-the-ip-of-gitlab-pages-on-gitlab-com/)。
- GitLab.comのGitLab PagesIPは、2018年に[変更されました](https://about.gitlab.com/blog/2018/07/19/gcp-move-update/#gitlab-pages-and-custom-domains)（`52.167.214.135`から`35.185.44.232`）。
- IPv6サポートは、2023年にGitLab.comに[追加されました](https://gitlab.com/gitlab-org/gitlab/-/issues/214718)。

### ステップ4: ドメインの所有権を確認する {#step-4-verify-the-domains-ownership}

すべてのDNSレコードを追加した後は:

1. 上部のバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **デプロイ** > **Pages**を選択します。
1. ドメイン名の横にある**編集** ({{< icon name="pencil" >}}) を選択します。
1. **検証ステータス**で、**検証を再試行する**（{{< icon name="retry" >}}）を選択します。

![ドメインの[検証の再試行]オプションを示すGitLab Pagesの設定。](img/retry_domain_verification_v12_0.png)

ドメインがアクティブになると、Webサイトがドメイン名で使用できるようになります。

> [!warning]ドメイン検証が有効になっているGitLabインスタンスでは、GitLabは検証されていないドメインを7日後にプロジェクトから削除します。

追加の注意点:

- ドメインの検証は、**required for GitLab.com users**です。GitLab Self-Managedの場合、GitLab管理者は、[カスタムドメインの検証を無効にする](../../../../administration/pages/_index.md#custom-domain-verification)オプションがあります。
- [DNSの伝播には時間がかかる場合があります（最大24時間）](https://www.inmotionhosting.com/support/domain-names/dns-nameserver-changes/complete-guide-to-dns-records/)が、通常は数分で完了します。完了するまでは、検証が失敗し、ドメインにアクセスしようとすると404エラーが発生します。
- ドメインが検証されたら、検証レコードをそのままにしておきます。ドメインは定期的に再検証され、レコードが削除されると無効になる場合があります。

## ドメインエイリアスの追加 {#add-more-domain-aliases}

同じプロジェクトに複数のエイリアス（カスタムドメインとサブドメイン）を追加できます。エイリアスは、同じ部屋に通じる多くのドアがあるものと理解できます。

サイトに設定したすべてのエイリアスは、**設定** > **Pages**にリストされています。そのページから、それらを表示、追加、削除できます。

## Cloudflareを使用した`www.domain.com`から`domain.com`へのリダイレクト {#redirect-wwwdomaincom-to-domaincom-with-cloudflare}

Cloudflareを使用している場合は、両方のドメインをGitLabに追加せずに、ページルールを使用して`www.domain.com`を`domain.com`にリダイレクトできます:

1. Cloudflareで、次のいずれかを少なくとも1つ作成します:
   - `A`レコードが`domain.com`を`35.185.44.232`に向ける。
   - `AAAA`レコードが`domain.com`を`2600:1901:0:7b8a::`に向ける。
1. GitLabで、ドメインをGitLab Pagesに追加し、検証コードを取得します。
1. Cloudflareで、ドメインを検証するためのDNS `TXT`レコードを作成します。
1. GitLabで、ドメインを検証します。
1. Cloudflareで、`CNAME`レコードが`www`を`domain.com`に向けるように作成します。
1. Cloudflareで、`www.domain.com`を`domain.com`に向けるページルールを追加します:
   1. ドメインのダッシュボードに移動します。上部のナビゲーションで、**Page Rules**を選択します。
   1. **Create Page Rule**を選択します。
   1. ドメイン`www.domain.com`を入力し、**+ Add a Setting**を選択します。
   1. ドロップダウンリストから**Forwarding URL**を選択し、ステータスコード**301 - Permanent Redirect**を選択します。
   1. 宛先URL `https://domain.com`を入力します。

## PagesへのSSL/TLS証明書の追加 {#add-an-ssltls-certificate-to-pages}

GitLab Pagesでカスタムドメインを保護するには、次の操作を実行できます:

- SSL証明書を自動的に取得および更新するには、[Let's Encryptインテグレーション](lets_encrypt_integration.md)を使用します。
- SSL/TLS証明書を手動で追加します。

SSL/TLS証明書の概要については、[GitLab PagesのSSL/TLS証明書](ssl_tls_concepts.md)を参照してください。

### SSL/TLS証明書の手動追加 {#manually-add-ssltls-certificates}

前提条件: 

- カスタムドメインでアクセス可能なGitLab PagesのWebサイトが稼働中。
- 次のSSL証明書コンポーネント:

  - **PEM certificate**: CAによって生成された証明書。
  - **Intermediate certificate**: ルート証明書とも呼ばれ、CAを識別します。通常はPEM証明書と組み合わされますが、一部のSSL証明書（[Cloudflare証明書](https://about.gitlab.com/blog/2017/02/07/setting-up-gitlab-pages-with-cloudflare-certificates/)など）では、個別に追加する必要があります。
  - **秘密キー**: ドメインに対してPEMを検証する暗号化されたキー。

新しいドメインの作成時にSSL証明書を追加するには:

1. 上部のバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **デプロイ** > **Pages**を選択します。
1. 右上隅で、**新しいドメイン**を選択します。
1. **ドメイン**に、ドメイン名を入力します。
1. **証明書**で、**Let's Encryptを用いた自動証明書管理**切替をオフにします。
1. SSL証明書フィールドに入力します。
1. **Create New Domain**を選択します。

既存のドメインにSSL証明書を追加するには:

1. 上部のバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **デプロイ** > **Pages**を選択します。
1. ドメイン名の横にある**編集** ({{< icon name="pencil" >}}) を選択します。
1. **証明書**で、**Let's Encryptを用いた自動証明書管理**切替をオフにします。
1. SSL証明書フィールドに入力します。
1. **変更を保存**を選択します。

SSL証明書フィールドに入力する場合:

- **証明書 (PEM)**に、PEM証明書を貼り付けます。証明書に個別の中間証明書が必要な場合は、同じフィールドに貼り付け、空白行で区切ります。詳細については、[Cloudflare証明書を使用したGitLab Pagesの設定](https://about.gitlab.com/blog/2017/02/07/setting-up-gitlab-pages-with-cloudflare-certificates/)を参照してください。
- [秘密キー]フィールドに、秘密キーを貼り付けます。

> [!note]通常のテキストエディタでSSL証明書または暗号化キーを開かないでください。Sublime Text、Dreamweaver、またはVS Codeのようなコードエディタを使用してください。

## GitLab PagesWebサイトのHTTPSの強制 {#force-https-for-gitlab-pages-websites}

GitLab PagesにHTTPSを強制して、HTTPリクエストを301リダイレクトでHTTPSに自動的にリダイレクトできます。これは、デフォルトのGitLab Pagesドメインと、有効なSSL証明書を持つカスタムドメインで機能します。

HTTPSを強制するには:

1. 上部のバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **デプロイ** > **Pages**を選択します。
1. **HTTPSを強制 (有効な証明書が必要)**チェックボックスを選択します。
1. **変更を保存**を選択します。

GitLab Pagesの前にCloudflare CDNを使用する場合は、SSL接続設定を`full`ではなく`flexible`に設定します。詳細については、[Cloudflare CDNの手順](https://developers.cloudflare.com/ssl/origin-configuration/ssl-modes#h_4e0d1a7c-eb71-4204-9e22-9d3ef9ef7fef)を参照してください。

## カスタムドメインの編集 {#edit-a-custom-domain}

カスタムドメインを編集して、次の操作を実行できます:

- カスタムドメインを表示します。
- 追加するDNSレコードを表示します。
- TXT検証エントリを表示します。
- 検証を再試行します。
- 証明書の設定を編集します。

カスタムドメインを編集するには:

1. 上部のバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **デプロイ** > **Pages**を選択します。
1. ドメイン名の横にある**編集** ({{< icon name="pencil" >}}) を選択します。

## カスタムドメインの削除 {#delete-a-custom-domain}

カスタムドメインを削除すると、ドメインはGitLabで検証されなくなり、GitLab Pagesで使用できなくなります。

カスタムドメインを削除するには:

1. 上部のバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **デプロイ** > **Pages**を選択します。
1. ドメイン名の横にある**ドメインの消去** ({{< icon name="remove" >}}) を選択します。
1. プロンプトが表示されたら、**ドメインの消去**を選択します。

## トラブルシューティング {#troubleshooting}

### ドメインの検証 {#domain-verification}

ドメインの検証`TXT` DNSエントリが正しく設定されていることを手動で確認するには、ターミナルで次のコマンドを実行します:

```shell
dig _gitlab-pages-verification-code.<YOUR-PAGES-DOMAIN> TXT
```

次の出力が予想されます:

```plaintext
;; ANSWER SECTION:
_gitlab-pages-verification-code.<YOUR-PAGES-DOMAIN>. 300 IN TXT "gitlab-pages-verification-code=<YOUR-VERIFICATION-CODE>"
```

登録しようとしているドメイン名と同じドメイン名で検証コードを追加すると便利な場合があります。

ルートドメインの場合:

| 送信元                                          | DNSレコード | 宛先 |
|-----------------------------------------------|------------|----|
| `example.com`                                 | `TXT`      | `gitlab-pages-verification-code=00112233445566778899aabbccddeeff` |
| `_gitlab-pages-verification-code.example.com` | `TXT`      | `gitlab-pages-verification-code=00112233445566778899aabbccddeeff` |

サブドメインの場合:

| 送信元                                              | DNSレコード | 宛先 |
|---------------------------------------------------|------------|----|
| `www.example.com`                                 | `TXT`      | `gitlab-pages-verification-code=00112233445566778899aabbccddeeff` |
| `_gitlab-pages-verification-code.www.example.com` | `TXT`      | `gitlab-pages-verification-code=00112233445566778899aabbccddeeff` |
