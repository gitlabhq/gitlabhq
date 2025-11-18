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

{{< history >}}

- GitLab 15.4で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/238461)された、検証済みのドメインを使用して、[SAMLまたはSCIMでプロビジョニングされたユーザーのユーザーEメールの確認を回避する](../../../group/saml_sso/_index.md#bypass-user-email-confirmation-with-verified-domains)ことができます。

{{< /history >}}

カスタムドメインは、以下の場合に使用できます。

- GitLab Pagesを使用。
- [SAMLまたはSCIMでプロビジョニングされたユーザーのユーザーEメールの確認を回避する](../../../group/saml_sso/_index.md#bypass-user-email-confirmation-with-verified-domains)。カスタムドメインをこのように使用する場合は、GitLab Pages機能を使用しますが、[前提要件](#prerequisites)をスキップできます。

1つまたは複数のカスタムドメイン名を使用するには:

- カスタム[**ルートドメイン**または**サブドメイン**](#set-up-a-custom-domain)を追加します。
- [SSL/TLS証明](#adding-an-ssltls-certificate-to-pages)を追加します。

{{< alert type="warning" >}}

[最も一般的なパブリック](../../../group/access_and_permissions.md#restrict-group-access-by-domain)は検証できません。

{{< /alert >}}

## カスタムドメインを設定する {#set-up-a-custom-domain}

カスタムドメイン名でPagesを設定するには、以下の要件と手順をお読みください。

### 前提要件 {#prerequisites}

- 管理者が[GitLab Pagesカスタムドメイン](../../../../administration/pages/_index.md#advanced-configuration)のサーバーをConfigureしている。
- GitLab PagesのWebサイトが起動し、実行され、デフォルトのPagesドメイン（`*.gitlab.io`、GitLab.comの場合）で提供されている。
- カスタムドメイン名`example.com`またはサブドメイン`subdomain.example.com`。
- を設定するために、ドメインのサーバーコントロールパネルにアクセスします。
  - ドメインをGitLab Pagesサーバーに（`A`、`AAAA`、`ALIAS`、または`CNAME`）。その名前に複数のがある場合は、`ALIAS`レコードを使用する必要があります。
  - ドメインの所有権を検証するための`TXT`。

### ステップ {#steps}

以下の手順に従って、カスタムドメインをPagesに追加します。[の概要](dns_concepts.md)については、このドキュメントも参照してください。

#### 1.カスタムドメインを追加する {#1-add-a-custom-domain}

カスタムドメインをGitLab Pagesに追加するには:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **デプロイ** > **Pages**を選択します。
1. 右上隅で、**新しいドメイン**を選択します。
1. **ドメイン**に、ドメイン名を入力します。
1. オプション: **証明書**で、**Let's Encryptを用いた自動証明書管理**切替をオフにして、[SSL/TLS証明書SSL/TLS証明書](#adding-an-ssltls-certificate-to-pages)を追加します。証明書とキーは後で追加することもできます。証明書とキーは後で追加することもできます。
1. **新しいドメインを作成**を選択します。

#### 2.検証コードを取得する {#2-get-the-verification-code}

Pagesに新しいドメインを追加すると、検証コードがプロンプトに表示されます。GitLabから値をコピーし、ドメインのコントロールパネルに`TXT`レコードとして貼り付けます。

![検証コードを取得する](img/get_domain_verification_code_v12_0.png)

#### 3.を設定する {#3-set-up-dns-records}

[Pagesのの概要](dns_concepts.md)については、このドキュメントをお読みください。この件について詳しい場合は、Pagesサイトで使用するドメインのタイプに応じて、以下の手順に従ってください。

- [ルートドメインの場合](#for-root-domains)、`example.com`。
- [サブドメインの場合](#for-subdomains)、`subdomain.example.com`。
- [両方の場合](#for-both-root-and-subdomains)。

##### ルートドメインの場合 {#for-root-domains}

ルートドメイン（`example.com`）には以下が要件です。

- 少なくとも次のいずれか。
  - ドメインをPagesサーバーに[`A`](dns_concepts.md#a-record)。
  - ドメインをPagesサーバーに[`AAAA`](dns_concepts.md#aaaa-record)。
- ドメインの所有権を検証するための[`TXT`](dns_concepts.md#txt-record)。

| からの                                          | DNSレコード | をに設定します。              |
| --------------------------------------------- | ---------- | --------------- |
| `example.com`                                 | `A`        | `35.185.44.232` |
| `example.com`                                 | `AAAA`     | `2600:1901:0:7b8a::` |
| `_gitlab-pages-verification-code.example.com` | `TXT`      | `gitlab-pages-verification-code=00112233445566778899aabbccddeeff` |

GitLab.comのプロジェクトの場合、IPv4アドレスは`35.185.44.232`、IPv6アドレスは`2600:1901:0:7b8a::`です。他のGitLabインスタンス（CEまたはGitLab Enterprise Edition）で稼働しているプロジェクトの場合は、システム管理者に問い合わせて、この情報（インスタンスで実行されているPagesサーバーのIPアドレス）を確認してください。

![GitLab.com Pagesサーバーを`A`](img/dns_add_new_a_record_v11_2.png)

{{< alert type="warning" >}}

ルートドメインをGitLab Pages Webサイト**のみ**に使用していて、ドメインレジストラーがこの機能をサポートしている場合は、`A`または`AAAA`レコードの代わりに、 apex `CNAME`レコードを追加できます。これを行う主な利点は、GitLab.comのGitLab Pages IPが何らかの理由で変更された場合に、`A`または`AAAA`レコードを更新する必要がないことです。いくつかの例外があるかもしれませんが、ルートドメインに[`MX`](dns_concepts.md#mx-record)を設定すると、**この方法は推奨されません**。

{{< /alert >}}

##### サブドメインの場合 {#for-subdomains}

サブドメイン（`subdomain.example.com`）には以下が要件です。

- サブドメインをPagesサーバーに[`ALIAS`または`CNAME`](dns_concepts.md#cname-record)。
- ドメインの所有権を検証するための[`TXT`](dns_concepts.md#txt-record)。

| からの                                                    | DNSレコード      | をに設定します。                    |
|:--------------------------------------------------------|:----------------|:----------------------|
| `subdomain.example.com`                                 | `ALIAS`/`CNAME` | `namespace.gitlab.io` |
| `_gitlab-pages-verification-code.subdomain.example.com` | `TXT`           | `gitlab-pages-verification-code=00112233445566778899aabbccddeeff` |

ユーザーまたはプロジェクトのWebサイトのどちらの場合でも、DNSレコード、パスなしで、Pagesドメイン（`namespace.gitlab.io`）を指す必要があります。

##### ルートとサブドメインの両方の場合 {#for-both-root-and-subdomains}

サブドメインとルートドメインの両方を同じWebサイトに指す必要があるケースがいくつかあります。たとえば、`example.com`や`www.example.com`などです。

以下が要件となります。

- ドメインの`A`。
- ドメインの`AAAA`。
- サブドメインの`ALIAS`/`CNAME`。
- それぞれの`TXT`。

| からの                                              | DNSレコード | をに設定します。 |
|---------------------------------------------------|------------|----|
| `example.com`                                     | `A`        | `35.185.44.232` |
| `example.com`                                     | `AAAA`     | `2600:1901:0:7b8a::` |
| `_gitlab-pages-verification-code.example.com`     | `TXT`      | `gitlab-pages-verification-code=00112233445566778899aabbccddeeff` |
| `www.example.com`                                 | `CNAME`    | `namespace.gitlab.io` |
| `_gitlab-pages-verification-code.www.example.com` | `TXT`      | `gitlab-pages-verification-code=00112233445566778899aabbccddeeff` |

Cloudflareを使用している場合は、[Cloudflareで`www.domain.com`から`domain.com`へのリダイレクト](#redirect-wwwdomaincom-to-domaincom-with-cloudflare)を確認してください。

追加の注意点:

- **Do not**（domain.com） をGitLab Pagesサイトに`CNAME`場合、`domain.com`レコードは使用**Do not**（しないでください）。代わりに`A`レコードを使用してください。
- デフォルトのPagesドメインの後に特殊文字を**Do not**（追加しないでください）。たとえば、`subdomain.domain.com`をまたは`namespace.gitlab.io/`に指すことはしないでください。一部のドメインホスティングプロバイダーでは、末尾のドット（`namespace.gitlab.io.`）がリクエストされる場合があります。
- GitLab.comのGitLab Pages IPは2017年に[変更されました](https://about.gitlab.com/releases/2017/03/06/we-are-changing-the-ip-of-gitlab-pages-on-gitlab-com/)。
- GitLab.comのGitLab Pages IPが、2018年に`52.167.214.135`から`35.185.44.232`に[変更されました](https://about.gitlab.com/blog/2018/07/19/gcp-move-update/#gitlab-pages-and-custom-domains)。
- 2023年にIPv6サポートがGitLab.comに[追加されました](https://gitlab.com/gitlab-org/gitlab/-/issues/214718)。

#### 4.ドメインの所有権を確認する {#4-verify-the-domains-ownership}

すべてのDNSレコードを追加した後は:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **デプロイ** > **Pages**を選択します。
1. ドメイン名の横にある**編集**({{< icon name="pencil" >}}) を選択します。
1. **検証ステータス**で、**検証を再試行する**（{{< icon name="retry" >}}）を選択します。

![ドメインを確認する](img/retry_domain_verification_v12_0.png)

ドメインがアクティブになるとすぐに、Webサイトがドメイン名で使用できるようになります。

{{< alert type="warning" >}}

インスタンスでドメイン検証が有効になっているGitLabでは、ドメインを7日間検証できない場合、そのドメインはGitLabプロジェクトから削除されます。

{{< /alert >}}

追加の注意点:

- ドメインの検証は**required for GitLab.com users**（GitLab.comユーザーに要件です）。GitLab Self-Managedの場合、GitLab管理者は[カスタムドメインの検証を無効](../../../../administration/pages/_index.md#custom-domain-verification)にするオプションがあります。
- [の伝播には時間がかかる場合があります（最大24時間）](https://www.inmotionhosting.com/support/domain-names/dns-nameserver-changes/complete-guide-to-dns-records/)が、通常は数分で完了します。完了するまで、検証に失敗し、ドメインへのアクセス試行の結果は404になります。
- ドメインが検証されたら、検証レコードをそのままにしておきます。ドメインは定期的に再検証され、レコードが削除されると無効になる場合があります。

### ドメインエイリアスを追加する {#add-more-domain-aliases}

同じプロジェクトに複数のエイリアス（カスタムドメインとサブドメイン）を追加できます。エイリアスは、同じ部屋に通じる多くのドアがあるものとして理解できます。

サイトに設定したすべてのエイリアスは、**設定 > Pages**に一覧表示されます。そのページから、表示、追加、削除できます。

### Cloudflareを使用して`www.domain.com`を`domain.com`にリダイレクトする {#redirect-wwwdomaincom-to-domaincom-with-cloudflare}

Cloudflareを使用している場合は、`www`と`domain.com`の両方をGitLabに追加せずに、`www.domain.com`を`domain.com`にリダイレクトできます。

これを行うには、`www.domain.com`を`domain.com`にリダイレクトするために、`CNAME`レコードに関連付けられたCloudflareのページルールを使用できます。次の設定を使用できます。

1. Cloudflareで、次のいずれかを少なくとも1つ作成します。
   - `domain.com`を`35.185.44.232`に`A`。
   - `domain.com`を`2600:1901:0:7b8a::`に`AAAA`。
1. GitLabで、ドメインをGitLab Pagesに追加して、検証コードを取得します。
1. Cloudflareで、ドメインを検証するための`TXT`を作成します。
1. GitLabで、ドメインを検証します。
1. Cloudflareで、`www`を`domain.com`に`CNAME`を作成します。
1. Cloudflareで、`www.domain.com`を`domain.com`にページルールを追加します。
   - ドメインのダッシュボードに移動し、上部のナビゲーションで**Page Rules**（ページルール）を選択します。
   - **Create Page Rule**（ページルールを作成）を選択します。
   - ドメイン`www.domain.com`を入力し、**+ Add a Setting**（+ 設定を追加）を選択します。
   - ドロップダウンリストから、**Forwarding URL**（転送URL）を選択し、ステータス状態コード**301 - Permanent Redirect**（301 - 恒久的なリダイレクト）を選択します。
   - 宛先URL `https://domain.com`を入力します。

## PagesにSSL/TLS証明書を追加する {#adding-an-ssltls-certificate-to-pages}

[SSL/TLS証明書>の概要](ssl_tls_concepts.md)については、このドキュメントをお読みください。

GitLab Pagesでカスタムドメインを保護するには、次のいずれかを選択できます。

- [GitLab PagesとのLet's Encryptインテグレーション](lets_encrypt_integration.md)を使用します。これにより、Pagesドメインのが自動的に取得および更新されます。
- 以下の手順に従って、SSL/TLS証明書を手動でGitLab Pages Webサイトに追加します。

### SSL/TLS証明書の手動追加 {#manual-addition-of-ssltls-certificates}

次の要件を満たす任意の証明書を使用できます。

- GitLab PagesのWebサイトが起動し、実行され、カスタムドメインでアクセスできる。
- **A PEM certificate**（PEM証明書）: 認証局によって生成された証明書であり、**証明書 (PEM)**フィールドに追加する必要があります。
- **An [intermediate certificate](https://en.wikipedia.org/wiki/Intermediate_certificate_authority)**: (aka "root certificate")**：（別名「ルート証明書」）とは、認証局を識別する暗号化キーチェーンの一部です。通常はPEM証明書と組み合わされますが、手動で追加する必要がある場合があります。[Cloudflare証明書](https://about.gitlab.com/blog/2017/02/07/setting-up-gitlab-pages-with-cloudflare-certificates/)は、これらのケースの1つです。
- **A private key**（秘密キー）: ドメインに対してPEMを検証する暗号化されたキーです。

たとえば、[Cloudflare証明書](https://about.gitlab.com/blog/2017/02/07/setting-up-gitlab-pages-with-cloudflare-certificates/)はこれらの要件を満たしています。

#### ステップ {#steps-1}

- 新しいドメインを追加する際に証明書を追加するには:

  1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
  1. 左側のサイドバーで、**デプロイ** > **Pages**を選択します。
  1. 右上隅で、**新しいドメイン**を選択します。
  1. **Domain**（Domain）に、ドメイン名を入力します。
  1. **証明書**で、**Let's Encryptを用いた自動証明書管理**切替をオフにして、[SSL/TLS証明書](#adding-an-ssltls-certificate-to-pages)を追加します。
  1. **Create New Domain**（新しいドメインを作成）を選択します。

- 以前に追加したドメインに証明書を追加するには:

  1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
  1. 左側のサイドバーで、**デプロイ** > **Pages**を選択します。
  1. ドメイン名の横にある**編集**({{< icon name="pencil" >}}) を選択します。
  1. **証明書**で、**Let's Encryptを用いた自動証明書管理**切替をオフにして、[SSL/TLS証明書](#adding-an-ssltls-certificate-to-pages)を追加します。
  1. **Save changes**（変更を保存）を選択します。

1. 対応するフィールドにPEM証明書を追加します。
1. 証明書に中間証明書がない場合は、ルート証明書（通常は認証局のWebサイトから入手可能）をコピーして、[PEM証明書と同じフィールド](https://about.gitlab.com/blog/2017/02/07/setting-up-gitlab-pages-with-cloudflare-certificates/)に貼り付け、その間に1行挿入します。
1. 秘密キーをコピーして、最後のフィールドに貼り付けます。

通常のテキストエディタで証明書または暗号化キーを**Do not**（開かないでください）。常にコードエディタ（Sublime Text、Dreamweaver、Bracketsなど）を使用してください。

## GitLab Pages WebサイトのHTTPSを強制する {#force-https-for-gitlab-pages-websites}

Webサイトの訪問者をさらに安全にするために、GitLab PagesのHTTPSを強制することを選択できます。そうすることで、HTTP経由でWebサイトにアクセスしようとするすべての試行が、301を介してHTTPSに自動的にリダイレクトされます。

これは、GitLabのデフォルトのドメインとカスタムドメインの両方で機能します（有効な証明書を設定している限り）。

この設定を有効にするには、次の手順に従います。

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **デプロイ** > **Pages**を選択します。
1. **HTTPSを強制 (有効な証明書が必要)**チェックボックスを選択します。
1. **変更を保存**を選択します。

GitLab Pagesの前面でCloudflare CDNを使用する場合は、SSL接続設定を`flexible`ではなく`full`に設定してください。詳細については、[Cloudflare CDNの指示](https://developers.cloudflare.com/ssl/origin-configuration/ssl-modes#h_4e0d1a7c-eb71-4204-9e22-9d3ef9ef7fef)を参照してください。

## カスタムドメインを編集する {#edit-a-custom-domain}

カスタムドメインを編集して、以下を行うことができます。

- カスタムドメインを表示します。
- 追加するDNSレコードを表示します。
- TXT検証エントリを表示します。
- 検証を再試行します。
- 証明書の設定を編集します。

カスタムドメインを編集するには:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **デプロイ** > **Pages**を選択します。
1. ドメイン名の横にある**編集** ({{< icon name="pencil" >}}) を選択します。

## カスタムドメインを削除する {#delete-a-custom-domain}

カスタムドメインを削除すると、そのドメインはGitLabで検証されなくなり、GitLab Pagesで使用できなくなります。

カスタムドメインを削除するには:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **デプロイ** > **Pages**を選択します。
1. ドメイン名の横にある**ドメインの消去**({{< icon name="remove" >}})を選択します。
1. プロンプトが表示されたら、**ドメインの消去**を選択します。

## トラブルシューティング {#troubleshooting}

### ドメインの検証 {#domain-verification}

ドメイン検証`TXT`エントリを適切にConfigureしたことを手動で検証するには、ターミナルで次のコマンドを実行します。

```shell
dig _gitlab-pages-verification-code.<YOUR-PAGES-DOMAIN> TXT
```

次の出力を想定します。

```plaintext
;; ANSWER SECTION:
_gitlab-pages-verification-code.<YOUR-PAGES-DOMAIN>. 300 IN TXT "gitlab-pages-verification-code=<YOUR-VERIFICATION-CODE>"
```

登録しようとしているドメイン名と同じドメイン名で検証コードを追加すると役立つ場合があります。

ルートドメインの場合:

| からの                                              | DNSレコード | をに設定します。                     |
| ------------------------------------------------- | ---------- | ---------------------- |
| `example.com`                                     | `TXT`      | `gitlab-pages-verification-code=00112233445566778899aabbccddeeff` |
| `_gitlab-pages-verification-code.example.com`     | `TXT`      | `gitlab-pages-verification-code=00112233445566778899aabbccddeeff` |

サブドメインの場合:

| からの                                              | DNSレコード | をに設定します。                     |
| ------------------------------------------------- | ---------- | ---------------------- |
| `www.example.com`                                 | `TXT`      | `gitlab-pages-verification-code=00112233445566778899aabbccddeeff` |
| `_gitlab-pages-verification-code.www.example.com` | `TXT`      | `gitlab-pages-verification-code=00112233445566778899aabbccddeeff` |
