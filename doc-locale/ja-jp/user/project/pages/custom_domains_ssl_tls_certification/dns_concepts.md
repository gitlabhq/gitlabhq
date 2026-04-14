---
stage: Plan
group: Knowledge
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: GitLab PagesのDNSレコード
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

ドメインネームシステム (DNS) ウェブサービスは、`www.example.com`のようなドメイン名を`192.0.2.1`のような数値のIPアドレスに変換することで、訪問者をウェブサイトにルーティングします。このIPアドレスは、コンピュータが互いに接続するために使用されます。

DNSレコードは、(サブ)ドメインを特定の場所(IPアドレスまたは別のドメイン)に指定するために作成されます。ご自身の(サブ)ドメインでGitLab Pagesを使用したい場合は、ドメインのレジストラコントロールパネルにアクセスし、ご自身のGitLab PagesサイトにポイントするDNSレコードを追加する必要があります。

DNSレコードを追加する方法は、ドメインがホストされているサーバーによって異なります。各コントロールパネルには、それぞれ設定する場所があります。ドメインの管理者ではなく、レジストラにアクセスできない場合は、ホスティングサービスのテクニカルサポートに依頼する必要があります。

詳細については、[GitLab PagesのDNSレコードを設定する](_index.md#step-3-set-up-dns-records)を参照してください。

最も人気のあるホスティングサービスについては、以下の手順を参照してください:

<!-- vale gitlab_base.Spelling = NO -->

- [123-reg](https://www.123-reg.co.uk/support/domains/domain-name-server-dns-management-guide/)
- [Amazon](https://docs.aws.amazon.com/AmazonS3/latest/userguide/website-hosting-custom-domain-walkthrough.html)
- [Bluehost](https://www.bluehost.com/help/article/dns-management-add-edit-or-delete-dns-entries)
- [Cloudflare](https://developers.cloudflare.com/fundamentals/setup/)
- [cPanel](https://docs.cpanel.net/cpanel/domains/zone-editor/)
- [DigitalOcean](https://docs.digitalocean.com/products/networking/dns/how-to/manage-records/)
- [DreamHost](https://help.dreamhost.com/hc/en-us/articles/360035516812)
- [Gandi](https://docs.gandi.net/en/domain_names/faq/dns_records.html)
- [Go Daddy](https://www.godaddy.com/help/add-an-a-record-19238)
- [Hostgator](https://www.hostgator.com/help/article/changing-dns-records)
- [Inmotion hosting](https://www.inmotionhosting.com/support/edu/cpanel/how-do-i-make-custom-dns-records/)
- [Microsoft](https://learn.microsoft.com/en-us/windows-server/networking/dns/manage-resource-records?tabs=powershell)
- [Namecheap](https://www.namecheap.com/support/knowledgebase/subcategory/2237/host-records-setup/)

<!-- vale gitlab_base.Spelling = YES -->

記載されていないホスティングサービスをご利用の場合は、`how to add dns record on <my hosting service>`とウェブで検索してみてください。

## `A`レコード {#a-record}

DNSの`A`レコードは、ホストをIPv4アドレスにマップします。`example.com`のようなルートドメインを、`192.0.2.1`のようなホストのIPアドレスに指定します。

例: 

- `example.com` => `A` => `192.0.2.1`

## `AAAA`レコード {#aaaa-record}

DNSの`AAAA`レコードは、ホストをIPv6アドレスにマップします。`example.com`のようなルートドメインを、`2001:db8::1`のようなホストのIPアドレスに指定します。

例: 

- `example.com` => `AAAA` => `2001:db8::1`

## `CNAME`レコード {#cname-record}

`CNAME`レコードは、サーバーの標準的な名前（`A`レコードで定義されているもの）のエイリアスを定義します。サブドメインを別のドメインに指定します。

例: 

- `www` => `CNAME` => `example.com`

このように、`www.example.com`を訪れる訪問者は`example.com`にリダイレクトされます。

## `MX`レコード {#mx-record}

MXレコードは、ドメインで使用されるメールエクスチェンジを定義するために使用されます。これにより、メールメッセージがメールサーバーに正しく届くようになります。

例: 

- `MX` => `mail.example.com`

その後、`users@mail.example.com`のメールを登録できます。

## `TXT`レコード {#txt-record}

`TXT`レコードは、任意のテキストをホストまたは別の名前にマップできます。一般的な使用方法は、サイト検証です。

例: 

- `example.com`=> `TXT` => `"google-site-verification=6P08Ow5E-8Q0m6vQ7FMAqAYIDprkVV8fUf_7hZ4Qvc8"`

この方法で、そのドメイン名の所有権を検証できます。

## すべての組み合わせ {#all-combined}

1つのDNSレコードまたは複数の組み合わせを持つことができます:

- `example.com` => `A` => `192.0.2.1`
- `example.com` => `AAAA` => `2001:db8::1`
- `www` => `CNAME` => `example.com`
- `MX` => `mail.example.com`
- `example.com`=> `TXT` => `"google-site-verification=6P08Ow5E-8Q0m6vQ7FMAqAYIDprkVV8fUf_7hZ4Qvc8"`
