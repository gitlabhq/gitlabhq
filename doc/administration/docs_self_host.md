---
stage: Enablement
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# How to host the GitLab product documentation **(FREE SELF)**

If you are not able to access the GitLab product documentation at `docs.gitlab.com`,
you can host the documentation yourself instead.

## Documentation self-hosting options

To host the GitLab product documentation, you can use:

- A Docker container
- GitLab Pages
- Your own web server

After you create a website by using one of these methods, you redirect the UI links
in the product to point to your website.

NOTE:
The website you create must be hosted under a subdirectory that matches
your installed GitLab version (for example, `14.5/`). The
[Docker images](https://gitlab.com/gitlab-org/gitlab-docs/container_registry/631635)
use this version by default.

The following examples use GitLab 14.5.

### Self-host the product documentation with Docker

You can run the GitLab product documentation website in a Docker container:

1. Expose port `4000`. The Docker image uses this port for the web server.
1. On the server where you host GitLab, or on any other server that your GitLab instance
   can communicate with, pull the docs site:

   ```shell
   docker run -it --rm -p 4000:4000 registry.gitlab.com/gitlab-org/gitlab-docs:14.5
   ```

   If you host your GitLab instance using [Docker compose](../install/docker.md#install-gitlab-using-docker-compose),
   add the following to `docker-compose.yaml`:

   ```yaml
   version: '3.6'
   services:
     docs:
       image: registry.gitlab.com/gitlab-org/gitlab-docs:14.5
       hostname: 'https://gitlab.example.com'
       ports:
         - '4000:4000'
   ```

### Self-host the product documentation with GitLab Pages

You can use GitLab Pages to host the GitLab product documentation.

Prerequisite:

- Ensure the Pages site URL does not use a subfolder. Because of how the docs
  site is pre-compiled, the CSS and JavaScript files are relative to the
  main domain or subdomain. For example, URLs like `https://example.com/docs/`
  are not supported.

To host the product documentation site with GitLab Pages:

1. [Create a blank project](../user/project/working_with_projects.md#create-a-blank-project).
1. Create a new or edit your existing `.gitlab-ci.yml` file, and add the following
   `pages` job, while ensuring the version is the same as your GitLab installation:

   ```yaml
   image: registry.gitlab.com/gitlab-org/gitlab-docs:14.5
   pages:
     script:
     - mkdir public
     - cp -a /usr/share/nginx/html/* public/
     artifacts:
       paths:
       - public
   ```

1. Optional. Set the GitLab Pages domain name. Depending on the type of the
   GitLab Pages website, you have two options:

   | Type of website         | [Default domain](../user/project/pages/getting_started_part_one.md#gitlab-pages-default-domain-names) | [Custom domain](../user/project/pages/custom_domains_ssl_tls_certification/index.md) |
   |-------------------------|----------------|---------------|
   | [Project website](../user/project/pages/getting_started_part_one.md#project-website-examples) | Not supported | Supported |
   | [User or group website](../user/project/pages/getting_started_part_one.md#user-and-group-website-examples) | Supported | Supported |

### Self-host the product documentation on your own web server

Because the product documentation site is static, from the container, you can take the contents
of `/usr/share/nginx/html` and use your own web server to host
the docs wherever you want.

Run the following commands, replacing `<destination>` with the directory where the
documentation files will be copied to:

```shell
docker create -it --name gitlab-docs registry.gitlab.com/gitlab-org/gitlab-docs:14.5
docker cp gitlab-docs:/usr/share/nginx/html <destination>
docker rm -f gitlab-docs
```

## Redirect the `/help` links to the new docs page

After your local product documentation site is running,
[redirect the help links](../user/admin_area/settings/help_page.md#redirect-help-pages)
in the GitLab application to your local site.

Be sure to use the fully qualified domain name as the docs URL. For example, if you
used the [Docker method](#self-host-the-product-documentation-with-docker), enter `http://0.0.0.0:4000`.

You don't need to append the version. GitLab detects it and appends it to
documentation URL requests as needed. For example, if your GitLab version is
14.5:

- The GitLab Docs URL becomes `http://0.0.0.0:4000/14.5/`.
- The link in GitLab displays as `<instance_url>/help/user/admin_area/settings/help_page#destination-requirements`.
- When you select the link, you are redirected to
`http://0.0.0.0:4000/14.5/ee/user/admin_area/settings/help_page/#destination-requirements`.

To test the setting, select a **Learn more** link within the GitLab application.

## Known issues

If you self-host the product documentation:

- The version dropdown displays additional versions that don't exist. Selecting
  these versions displays a `404 Not Found` page.
- The search displays results from `docs.gitlab.com` and not the local site.
- By default, the landing page redirects to the
  respective version (for example, `/14.5/`). This causes the landing page <https://docs.gitlab.com> to not be displayed.
