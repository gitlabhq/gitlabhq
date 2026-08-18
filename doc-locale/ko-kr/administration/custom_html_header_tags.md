---
stage: Software Supply Chain Security
group: Compliance
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: GitLab 인스턴스의 HTML 헤더 태그를 수정하는 방법을 알아봅니다.
title: 사용자 지정 HTML 헤더 태그
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed

{{< /details >}}

{{< history >}}

- GitLab 17.1에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/153877)되었습니다.

{{< /history >}}

EU 또는 쿠키 동의 배너가 필요한 다른 관할권에서 GitLab 인스턴스를 자체 관리하는 경우, 스크립트 및 스타일시트를 추가하기 위해 추가 HTML 헤더 태그가 필요합니다.

## 보안 의미 {#security-implications}

이 기능을 사용하기 전에 보안 의미를 이해해야 합니다.

이전에 정상이었던 외부 리소스가 손상될 수 있으며, GitLab 인스턴스의 모든 사용자로부터 거의 모든 데이터를 추출하는 데 사용될 수 있습니다. 이러한 이유로 신뢰할 수 없는 외부 소스의 리소스를 추가해서는 안 됩니다. 가능하면 제3자 리소스와 함께 [Subresource Integrity](https://www.w3.org/TR/SRI/)와 같은 무결성 검사를 항상 사용하여 로드되는 리소스의 진정성을 확인해야 합니다.

HTML 헤더 태그를 사용하여 추가하는 기능을 최소한으로 제한합니다. 그렇지 않으면, 예를 들어 GitLab의 다른 애플리케이션 코드와 상호 작용하는 경우 안정성 또는 기능 문제가 발생할 수 있습니다.

## 사용자 지정 HTML 헤더 태그 추가 {#add-a-custom-html-header-tag}

`content_security_policy` 옵션에서 사용할 수 있는 Content Security Policy에 외부 소스를 추가해야 합니다. 다음 예에서는 `script_src`와 `style_src`을 확장해야 합니다.

사용자 지정 HTML 헤더 태그를 추가하려면:

{{< tabs >}}

{{< tab title="Linux 패키지(Omnibus)" >}}

1. `/etc/gitlab/gitlab.rb`을 편집하고 구성을 추가합니다. 예를 들어:

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

1. 파일을 저장한 후 [재구성](restart_gitlab.md#reconfigure-a-linux-package-installation) 하고 GitLab을 [다시 시작](restart_gitlab.md#restart-a-linux-package-installation)합니다.

{{< /tab >}}

{{< tab title="자체 컴파일(Source)" >}}

1. `/home/git/gitlab/config/gitlab.yml`을 편집합니다:

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

1. 파일을 저장하고 GitLab을 다시 시작합니다:

   ```shell
   # For systems running systemd
   sudo systemctl restart gitlab.target

   # For systems running SysV init
   sudo service gitlab restart
   ```

{{< /tab >}}

{{< /tabs >}}
