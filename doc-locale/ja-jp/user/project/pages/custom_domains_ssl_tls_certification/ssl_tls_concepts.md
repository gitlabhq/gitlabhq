---
stage: Plan
group: Knowledge
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitLab Pages SSL/TLS証明書
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed

{{< /details >}}

すべてのGitLab Pagesプロジェクトは、デフォルトのページドメイン（`*.gitlab.io`）のHTTPSでGitLab.comで利用できます。カスタム（サブ）ドメインでページプロジェクトをセットアップしたら、HTTPSで保護する場合は、その（サブ）ドメインの認証局を発行し、プロジェクトにインストールする必要があります。

{{< alert type="note" >}}

お勧めしますが、証明書はGitLab Pagesプロジェクトのカスタム（サブ）ドメインに追加するために必須**ではありません**。

{{< /alert >}}

HTTPSの重要性の紹介から始めましょう。

## HTTPSを気にする必要があるのはなぜですか？ {#why-should-you-care-about-https}

これは最初の質問かもしれません。サイトがGitLab Pagesでホストされている場合、サイトは静的であるため、サーバー側のスクリプトやクレジットカードトランザクションを処理していませんが、なぜ安全な接続が必要なのでしょうか？

HTTPSが1990年に登場したとき、[SSL](https://en.wikipedia.org/wiki/Transport_Layer_Security#SSL_1.0.2C_2.0_and_3.0)は「特別な」セキュリティ対策と見なされ、銀行や金融取引のあるショッピングサイトのような大企業でのみ必要とされました。

<!-- vale gitlab_base.Spelling = NO -->

今では、状況は異なっています。[Josh Aas氏](https://letsencrypt.org/2015/10/29/phishing-and-malware.html) 、[Internet Security Research Group（ISRG）](https://en.wikipedia.org/wiki/Internet_Security_Research_Group)のエグゼクティブディレクターによると:

<!-- vale gitlab_base.rulename = YES -->

> HTTPSはほぼすべてのウェブサイトにとって重要であると認識するようになりました。パスワードでサインインできるウェブサイト、何らかの方法で[ユーザーを追跡する](https://www.washingtonpost.com/news/the-switch/wp/2013/12/10/nsa-uses-google-cookies-to-pinpoint-targets-for-hacking/)ウェブサイト、[コンテンツが変更されることを望まない](https://arstechnica.com/tech-policy/2014/09/why-comcasts-javascript-ad-injections-threaten-security-net-neutrality/)ウェブサイト、および人々が消費していることを他の人に知られたくないコンテンツを提供するサイトにとって重要です。HTTPSで保護されていないサイトは、[他のサイトへの攻撃に使用される可能性があります](https://krebsonsecurity.com/2015/04/dont-be-fodder-for-chinas-great-cannon/)。

したがって、証明書が非常に重要な理由は、認証と検証のキーチェーンを介して、**client**（あなた、あなたの訪問者）と**server**（サイトが存在する場所）間の接続を暗号化するためです。

## HTTPSをサポートする組織 {#organizations-supporting-https}

すべてのWebを保護することを支持する大きな動きがあります。W3Cは完全に[原因をサポート](https://w3ctag.github.io/web-https/)し、その理由を非常にうまく説明しています。Mozilla Security BlogのライターであるRichard Barnesは、[FirefoxがHTTPを非推奨にする](https://blog.mozilla.org/security/2015/04/30/deprecating-non-secure-http/)ことを提案し、保護されていない接続を受け入れなくなります。最近、MozillaはHTTPSの重要性を繰り返し述べる[コミュニケーション](https://blog.mozilla.org/security/2016/03/29/march-2016-ca-communication/)を発表しました。

## 証明書の発行 {#issuing-certificates}

GitLab Pagesは、[PEM](https://knowledge.digicert.com/quovadis)形式で提供される証明書、[認証局](https://en.wikipedia.org/wiki/Certificate_authority)によって発行される証明書、または[自己署名証明書](https://en.wikipedia.org/wiki/Self-signed_certificate)として提供される証明書を受け入れます。[自己署名証明書は通常使用されません](https://www.mcafee.com/blogs/other-blogs/mcafee-labs/self-signed-certificates-secure-so-why-ban/)セキュリティ上の理由から、パブリックWebサイトの場合、ブラウザがサイトの証明書を信頼するようにします。

さまざまな種類の証明書があり、それぞれに特定のセキュリティレベルがあります。たとえば、静的な個人Webサイトは、オンラインバンキングWebアプリと同じセキュリティレベルを必要としません。

インターネットをすべての人にとってより安全にすることを目指して、無料の証明書を提供する認証局がいくつかあります。最も人気のあるのは[Let's Encrypt](https://letsencrypt.org/)で、ほとんどのブラウザで信頼されている証明書を発行し、オープンソースであり、Freeで使用できます。カスタムドメインでHTTPSを有効にするには、[Let's EncryptとのGitLab Pagesインテグレーション](lets_encrypt_integration.md)を参照してください。

同様に人気があるのは、[Cloudflareによって発行された証明書](https://www.cloudflare.com/application-services/products/ssl/)であり、[無料のCDNサービス](https://blog.cloudflare.com/cloudflares-free-cdn-and-you/)も提供しています。それらの証明書は最大15年間有効です。[GitLab Pages WebサイトにCloudflare証明書を追加する方法](https://about.gitlab.com/blog/2017/02/07/setting-up-gitlab-pages-with-cloudflare-certificates/)に関するチュートリアルを参照してください。
