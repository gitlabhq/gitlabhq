---
stage: AI-powered
group: Editor Extensions
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: Indicate the wildcard domain used by the Web IDE to isolate VS Code extensions and web views
title: Web IDE extension host domain
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed

{{< /details >}}

The extension host domain is a wildcard domain name used by the Web IDE to isolate third-party code installed
using [Extension Marketplace](../../user/project/web_ide/_index.md#manage-extensions). The Web IDE
relies on the web browser's [same origin](https://developer.mozilla.org/en-US/docs/Web/Security/Same-origin_policy)
policy to run extensions in a sandbox environment.

GitLab provides a default extension host domain `cdn.web-ide.gitlab-static.net` that is available to all
GitLab offerings by default. This domain name points to an external HTTP server that hosts VS Code static assets.
In offline environments, a user's web browser can't connect to this external HTTP server which,
in turn, limits the Web IDE's capabilities.

To circumvent this limitation, GitLab instance administrators can set up a custom extension host domain. The
custom extension host domain points to the GitLab instance itself which can also serve the VS Code static
assets just like the default solution.

> [!warning]
> There are severe security risks associated with configuring overly broad wildcard domains in the Web IDE extension
> host domain. Misconfiguration can lead to compromise of your GitLab instance and all associated data.

## Set up custom extension host domain

Prerequisites:

- You must be an administrator.

These instructions are for a [Linux package installation](../../install/package/_index.md) that uses
the default NGINX installation. GitLab administrators and DevOps engineers
should adapt this guide to other installation methods.

1. Follow the guide to [insert custom settings into the NGINX configuration](https://docs.gitlab.com/omnibus/settings/nginx/#insert-custom-settings-into-the-nginx-configuration) to add a `server` block. This block configures NGINX to handle requests for the extension host domain. The following code snippet provides a reference configuration. Replace `<extension-host-domain-placeholder>` with the wildcard domain name for your Web IDE extension host domain:

   ```nginx
   server {
     listen *:443 ssl;
     server_name *.<extension-host-domain-placeholder>;

     ssl_certificate /etc/gitlab/ssl/<extension-host-domain-placeholder>.pem;
     ssl_certificate_key /etc/gitlab/ssl/<extension-host-domain-placeholder>-key.pem;

     ## Individual nginx logs for this GitLab vhost
     access_log  /var/log/gitlab/nginx/gitlab_access.log gitlab_access;
     error_log   /var/log/gitlab/nginx/gitlab_error.log;

     location /assets/ {
       client_max_body_size 0;
       gzip off;

       proxy_read_timeout      300;
       proxy_connect_timeout   300;
       proxy_redirect          off;

       proxy_http_version 1.1;

       proxy_set_header    Host                $http_host;
       proxy_set_header    X-Real-IP           $remote_addr;
       proxy_set_header    X-Forwarded-For     $remote_addr;
       proxy_set_header    X-Forwarded-Proto   $scheme;

       proxy_pass http://gitlab-workhorse;
     }
   }
   ```

1. Save the file and [reconfigure GitLab](../restart_gitlab.md#reconfigure-a-linux-package-installation) for the changes to take effect. Then, open the GitLab application.
1. In the upper-right corner, select **Admin**.
1. Select **Settings** > **General**.
1. Expand **Web IDE**.
1. In the **Extension host domain** text box, enter the custom extension host domain.
1. Select **Save changes**.

After saving the changes, you can open a project in the Web IDE to verify that the custom
extension host is used by the editor.
