---
stage: Plan
group: Knowledge
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: GitLab Pages SSL/TLS証明書
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed

{{< /details >}}

すべてのGitLab Pagesプロジェクトは、GitLab.com上で、デフォルトのPagesドメイン（`*.gitlab.io`）でHTTPSが利用可能です。カスタム（サブ）ドメインでPagesプロジェクトを設定した後、HTTPSで保護したい場合は、その（サブ）ドメインの証明書を発行してプロジェクトにインストールする必要があります。

> [!note]
> 証明書は、GitLab Pagesプロジェクトのカスタム(サブ)ドメインに追加する必要は**not**が、強くお勧めします。

HTTPSの重要性について説明します。

## なぜHTTPSを気にする必要があるのですか？ {#why-should-you-care-about-https}

これが最初の疑問かもしれません。サイトがGitLab Pagesでホストされている場合、それらは静的であるため、サーバーサイドスクリプトやクレジットカード取引を扱うことはありません。では、なぜ安全な接続が必要なのでしょうか？

1990年にHTTPSが登場した際、[SSL](https://en.wikipedia.org/wiki/Transport_Layer_Security#SSL_1.0.2C_2.0_and_3.0)は銀行や金融取引を行うショッピングサイトのような大企業にのみ必要な「特別な」セキュリティ対策と見なされていました。

<!-- vale gitlab_base.Spelling = NO -->

現在では状況が異なっています。[Josh Aas氏](https://letsencrypt.org/2015/10/29/phishing-and-malware.html) （[Internet Security Research Group (ISRG)](https://en.wikipedia.org/wiki/Internet_Security_Research_Group)のExecutive Director）によると:

<!-- vale gitlab_base.rulename = YES -->

> HTTPSがほぼすべてのウェブサイトにとって重要であると認識するようになりました。パスワードでサインインできるあらゆるウェブサイト、あらゆる方法で[ユーザーを追跡する](https://www.washingtonpost.com/news/the-switch/wp/2013/12/10/nsa-uses-google-cookies-to-pinpoint-targets-for-hacking/)あらゆるウェブサイト、[コンテンツを改ざんされたくない](https://arstechnica.com/tech-policy/2014/09/why-comcasts-javascript-ad-injections-threaten-security-net-neutrality/)あらゆるウェブサイト、そして、人々が他人に知られたくないコンテンツを提供するあらゆるサイトにとって重要です。また、HTTPSで保護されていないサイトは、[他のサイトを攻撃するために利用される可能性がある](https://krebsonsecurity.com/2015/04/dont-be-fodder-for-chinas-great-cannon/)ことも学んでいます。

したがって、証明書が非常に重要である理由は、**client**と**server**間の接続を、認証と検証のキーチェーンを介して暗号化するためです。

## HTTPSをサポートする組織 {#organizations-supporting-https}

ウェブ全体を保護しようとする大きな動きがあります。W3Cは全面的に[この活動をサポート](https://w3ctag.github.io/web-https/)し、その理由を非常によく説明しています。Mozilla Security BlogのライターであるRichard Barnesは、[FirefoxがHTTPを非推奨](https://blog.mozilla.org/security/2015/04/30/deprecating-non-secure-http/)にし、もはや安全でない接続を受け入れなくなるだろうと示唆しました。最近、MozillaはHTTPSの重要性を再確認する[コミュニケ](https://blog.mozilla.org/security/2016/03/29/march-2016-ca-communication/)を発表しました。

## 証明書の発行 {#issuing-certificates}

GitLab Pagesは、[PEM](https://knowledge.digicert.com/quovadis)形式で提供される証明書を、[認証局](https://en.wikipedia.org/wiki/Certificate_authority)または[自己署名証明書](https://en.wikipedia.org/wiki/Self-signed_certificate)として受け入れます。セキュリティ上の理由と、ブラウザがサイトの証明書を信頼することを保証するため、[自己署名証明書は通常、公開ウェブサイトでは使用されません](https://www.mcafee.com/blogs/other-blogs/mcafee-labs/self-signed-certificates-secure-so-why-ban/)。

証明書にはそれぞれ異なるセキュリティレベルがあります。例えば、静的な個人ウェブサイトは、オンラインバンキングのウェブアプリと同じセキュリティレベルを必要としません。

一部の認証局は、インターネットをすべての人にとってより安全にするために、Free証明書を提供しています。最も人気があるのは[Let's Encrypt](https://letsencrypt.org/)で、ほとんどのブラウザから信頼される証明書を発行しており、オープンソースでFreeで使用できます。カスタムドメインでHTTPSを有効にするには、[GitLab PagesのLet's Encryptとのインテグレーション](lets_encrypt_integration.md)を参照してください。

同様に人気があるのは、[Cloudflareが発行する証明書](https://www.cloudflare.com/application-services/products/ssl/)で、これも[FreeのCDNサービス](https://blog.cloudflare.com/cloudflares-free-cdn-and-you/)を提供しています。これらの証明書は最長15年間有効です。[Cloudflare証明書をGitLab Pagesウェブサイトに追加する方法](https://about.gitlab.com/blog/setting-up-gitlab-pages-with-cloudflare-certificates/)に関するチュートリアルを参照してください。
