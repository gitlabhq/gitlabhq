---
stage: Software Supply Chain Security
group: Compliance
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: GitLabインスタンスのHTMLヘッダータグを変更する方法を説明します。
title: カスタムHTMLヘッダータグ
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

{{< history >}}

- GitLab 17.1で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/153877)されました。

{{< /history >}}

EU内、またはクッキーの同意バナーを必要とする管轄区域で自身でGitLabインスタンスを管理している場合、スクリプトやスタイルシートを追加するために追加のHTMLヘッダータグが必要です。

## セキュリティ上の注意点 {#security-implications}

この機能を有効にする前に、これにより発生する可能性のあるセキュリティへの影響を理解しておく必要があります。

以前は正当だった外部リソースが侵害され、GitLabインスタンスのあらゆるユーザーからほぼすべてのデータを抽出するために使用される可能性があります。そのため、信頼できない外部ソースからのリソースは絶対に追加しないでください。可能な場合は、常に[Subresource Integrity](https://www.w3.org/TR/SRI/)などの整合性チェックをサードパーティのリソースで使用して、読み込まれるリソースの信頼性を確認する必要があります。

HTMLヘッダータグを使用して追加する機能を最小限に制限してください。そうでなければ、たとえばGitLabの他のアプリケーションコードとインタラクトした場合、安定性や機能性の問題を引き起こす可能性があります。

## カスタムHTMLヘッダータグを追加 {#add-a-custom-html-header-tag}

外部ソースをContent Security Policyに追加する必要があります。これは`content_security_policy`オプションで利用できます。以下の例では、`script_src`と`style_src`を拡張する必要があります。

カスタムHTMLヘッダータグを追加するには:

{{< tabs >}}

{{< tab title="Linuxパッケージ（Omnibus）" >}}

1. `/etc/gitlab/gitlab.rb`を編集し、設定を追加します。例: 

   ```ruby
   gitlab_rails['custom_html_header_tags'] = <<-'EOS'
   <script src="https://example.com/cookie-consent.js" integrity="sha384-Li9vy3DqF8tnTXuiaAJuML3ky+er10rcgNR/VqsVpcw+ThHmYcwiB1pbOxEbzJr7" crossorigin="anonymous"></script>
   <link rel="stylesheet" href="https://example.com/cookie-consent.css" integrity="sha384-+/M6kredJcxdsqkczBUjMLvqyHb1K/JThDXWsBVxMEeZHEaMKEOEct339VItX1zB" crossorigin="anonymous">
   EOS

   gitlab_rails['content_security_policy'] = {
   # extend the following directives
     'directives' => {
       'script_src' => "'self' 'unsafe-eval' https://example.com https://www.google.com/recaptcha/ https://www.recaptcha.net/ https://www.gstatic.com/recaptcha/ https://apis.google.com",
       'style_src' => "'self' 'unsafe-inline' https://example.com",
     }
    }
   ```

1. ファイルを保存し、[reconfigure](restart_gitlab.md#reconfigure-a-linux-package-installation)してGitLabを[restart](restart_gitlab.md#restart-a-linux-package-installation)します。

{{< /tab >}}

{{< tab title="自己コンパイル（ソース）" >}}

1. `/home/git/gitlab/config/gitlab.yml`を編集します:

   ```yaml
   production: &base
     gitlab:
       custom_html_header_tags: |
         <script src="https://example.com/cookie-consent.js" integrity="sha384-Li9vy3DqF8tnTXuiaAJuML3ky+er10rcgNR/VqsVpcw+ThHmYcwiB1pbOxEbzJr7"         crossorigin="anonymous"></script>
         <link rel="stylesheet" href="https://example.com/cookie-consent.css" integrity="sha384-+/M6kredJcxdsqkczBUjMLvqyHb1K/JThDXWsBVxMEeZHEaMKEOEct339VItX1zB"        crossorigin="anonymous">
       content_security_policy:
         directives:
           script_src: "'self' 'unsafe-eval' https://example.com http://localhost:* https://www.google.com/recaptcha/ https://www.recaptcha.net/ https://www.gstatic.com/recaptcha/ https://apis.google.com"
           style_src: "'self' 'unsafe-inline' https://example.com"
   ```

1. ファイルを保存して、GitLabを再起動します: 

   ```shell
   # For systems running systemd
   sudo systemctl restart gitlab.target

   # For systems running SysV init
   sudo service gitlab restart
   ```

{{< /tab >}}

{{< /tabs >}}
