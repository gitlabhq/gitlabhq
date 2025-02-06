---
stage: Software Supply Chain Security
group: Compliance
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: Learn how to modify the HTML header tags of your GitLab instance.
title: Custom HTML header tags
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab Self-Managed

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/153877) in GitLab 17.1.

If you self-manage a GitLab instance in the EU, or any jurisdiction that
requires a cookie consent banner, additional HTML header tags are needed to
add scripts and stylesheets.

## Security implications

Before enabling this feature, you should understand the security implications this might have.

A previously legit external resource could end up being compromised and then used to extract
pretty much any data from any user in the GitLab instance. For that reason,
you should never add resources from untrusted external sources. If possible, you should always
use integrity checks like [Subresource Integrity](https://www.w3.org/TR/SRI/) with third-party
resources to confirm the authenticity of the resources that are loaded.

Limit the functionality you are adding by using HTML header tags to the minimum.
Otherwise, it could cause also stability or functionality issues if you, for example,
interact with other application code from GitLab.

## Add a custom HTML header tag

You must add the externals sources to the Content Security Policy which is
available in the `content_security_policy` option. For the following example, you
must extend the `script_src` and `style_src`.

To add a custom HTML header tag:

::Tabs

:::TabTitle Linux package (Omnibus)

1. Edit `/etc/gitlab/gitlab.rb` and add your configuration. For example:

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

1. Save the file, and then [reconfigure](restart_gitlab.md#reconfigure-a-linux-package-installation) and [restart](restart_gitlab.md#restart-a-linux-package-installation) GitLab.

:::TabTitle Self-compiled (Source)

1. Edit `/home/git/gitlab/config/gitlab.yml`:

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

1. Save the file and restart GitLab:

   ```shell
   # For systems running systemd
   sudo systemctl restart gitlab.target

   # For systems running SysV init
   sudo service gitlab restart
   ```

::EndTabs
