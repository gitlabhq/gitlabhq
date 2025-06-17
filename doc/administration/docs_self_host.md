---
stage: GitLab Delivery
group: Self Managed
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Host the GitLab product documentation
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed

{{< /details >}}

If you are not able to access the GitLab product documentation at `docs.gitlab.com`,
you can host the documentation yourself instead.

{{< alert type="note" >}}

The local help of your instance does not include all the docs (for example, it
doesn't include docs for GitLab Runner or GitLab Operator), and it's not
searchable or browsable. It's intended to only support direct links to specific
pages from within your instance.

{{< /alert >}}

## Container registry URL

The URL to the container image you want depends on the version of the GitLab Docs you need. See the following table
as a guide for the URL to use in the following sections.

| GitLab version | Container registry                                                                           | Container image URL |
|:---------------|:---------------------------------------------------------------------------------------------|:--------------------|
| 17.8 and later | <https://gitlab.com/gitlab-org/technical-writing/docs-gitlab-com/container_registry/8244403> | `registry.gitlab.com/gitlab-org/technical-writing/docs-gitlab-com/archives:<version>` |
| 15.5 - 17.7    | <https://gitlab.com/gitlab-org/gitlab-docs/container_registry/3631228>                       | `registry.gitlab.com/gitlab-org/gitlab-docs/archives:<version>` |
| 10.3 - 15.4    | <https://gitlab.com/gitlab-org/gitlab-docs/container_registry/631635>                        | `registry.gitlab.com/gitlab-org/gitlab-docs:<version>` |

## Documentation self-hosting options

To host the GitLab product documentation, you can use:

- A Docker container
- GitLab Pages
- Your own web server

The following examples use GitLab 17.8, but make sure to use the version that
corresponds to your GitLab instance.

### Self-host the product documentation with Docker

The documentation website is served under the port `4000` inside the container.
In the following example, we expose this on the host under the same port.

Make sure you either:

- Allow port `4000` in your firewall.
- Use a different port. In following examples, replace the leftmost `4000` with a different port number.

To run the GitLab product documentation website in a Docker container:

1. On the server where you host GitLab, or on any other server that your GitLab instance
   can communicate with:

   - If you use plain Docker, run:

     ```shell
     docker run --detach --name gitlab_docs -it --rm -p 4000:4000 registry.gitlab.com/gitlab-org/technical-writing/docs-gitlab-com/archives:17.8
     ```

   - If you host your GitLab instance using
     [Docker compose](../install/docker/installation.md#install-gitlab-by-using-docker-compose),
     add the following to your existing `docker-compose.yaml`:

     ```yaml
     version: '3.6'
     services:
       gitlab_docs:
         image: registry.gitlab.com/gitlab-org/technical-writing/docs-gitlab-com/archives:17.8
         hostname: 'https://docs.gitlab.example.com:4000'
         ports:
           - '4000:4000'
     ```

     Then, pull the changes:

     ```shell
     docker-compose up -d
     ```

1. Visit `http://0.0.0.0:4000` to view the documentation website and verify that
   it works.
1. [Redirect the help links to the new documentation site](#redirect-the-help-links-to-the-new-docs-site).

### Self-host the product documentation with GitLab Pages

You can use GitLab Pages to host the GitLab product documentation.

Prerequisites:

- Ensure the Pages site URL does not use a subfolder. Because of the way the
  site is pre-compiled, the CSS and JavaScript files are relative to the
  main domain or subdomain. For example, URLs like `https://example.com/docs/`
  are not supported.

To host the product documentation site with GitLab Pages:

1. [Create a blank project](../user/project/_index.md#create-a-blank-project).
1. Create a new or edit your existing `.gitlab-ci.yml` file, and add the following
   `pages` job, while ensuring the version is the same as your GitLab installation:

   ```yaml
   pages:
     image: registry.gitlab.com/gitlab-org/technical-writing/docs-gitlab-com/archives:17.8
     script:
       - mkdir public
       - cp -a /usr/share/nginx/html/* public/
     artifacts:
       paths:
       - public
   ```

1. Optional. Set the GitLab Pages domain name. Depending on the type of the
   GitLab Pages website, you have two options:

   | Type of website         | [Default domain](../user/project/pages/getting_started_part_one.md#gitlab-pages-default-domain-names) | [Custom domain](../user/project/pages/custom_domains_ssl_tls_certification/_index.md) |
   |-------------------------|----------------|---------------|
   | [Project website](../user/project/pages/getting_started_part_one.md#project-website-examples) | Not supported | Supported |
   | [User or group website](../user/project/pages/getting_started_part_one.md#user-and-group-website-examples) | Supported | Supported |

1. [Redirect the help links to the new documentation site](#redirect-the-help-links-to-the-new-docs-site).

### Self-host the product documentation on your own web server

{{< alert type="note" >}}

The website you create must be hosted under a subdirectory that matches
your installed GitLab version (for example, `17.8/`). The
[Docker images](https://gitlab.com/gitlab-org/technical-writing/docs-gitlab-com/container_registry/8244403)
use this version by default.

{{< /alert >}}

Because the product documentation site is static, you can take the contents of
`/usr/share/nginx/html` from inside the container, and use your own web server to host
the documentation wherever you want.

The `html` directory should be served as is and it has the following structure:

```plaintext
├── 17.8/
├── index.html
```

In this example:

- `17.8/` is the directory where the documentation is hosted.
- `index.html` is a simple HTML file that redirects to the directory containing the documentation. In this
  case, `17.8/`.

To extract the HTML files of the documentation site:

1. Create the container that holds the HTML files of the documentation website:

   ```shell
   docker create -it --name gitlab_docs registry.gitlab.com/gitlab-org/technical-writing/docs-gitlab-com/archives:17.8
   ```

1. Copy the website under `/srv/gitlab/`:

   ```shell
   docker cp gitlab-docs:/usr/share/nginx/html /srv/gitlab/
   ```

   You end up with a `/srv/gitlab/html/` directory that holds the documentation website.

1. Remove the container:

   ```shell
   docker rm -f gitlab_docs
   ```

1. Point your web server to serve the contents of `/srv/gitlab/html/`.
1. [Redirect the help links to the new documentation site](#redirect-the-help-links-to-the-new-docs-site).

## Redirect the `/help` links to the new Docs site

After your local product documentation site is running,
[redirect the help links](settings/help_page.md#redirect-help-pages)
in the GitLab application to your local site, by using the fully qualified domain
name as the documentation URL. For example, if you used the
[Docker method](#self-host-the-product-documentation-with-docker), enter `http://0.0.0.0:4000`.

You don't need to append the version. GitLab detects it and appends it to
documentation URL requests as needed. For example, if your GitLab version is
17.8:

- The GitLab documentation URL becomes `http://0.0.0.0:4000/17.8/`.
- The link in GitLab displays as `<instance_url>/help/administration/settings/help_page#destination-requirements`.
- When you select the link, you are redirected to
  `http://0.0.0.0:4000/17.8/administration/settings/help_page/#destination-requirements`.

To test the setting, in GitLab, select a **Learn more** link. For example:

1. On the left sidebar, select your avatar.
1. Select **Preferences**.
1. In the **Syntax highlighting theme** section, select **Learn more**.

## Upgrade the product documentation to a later version

Upgrading the documentation site to a later version requires downloading the newer Docker image tag.

### Upgrade using Docker

To upgrade to a later version [using Docker](#self-host-the-product-documentation-with-docker):

- If you use Docker:

  1. Stop the running container:

     ```shell
     sudo docker stop gitlab_docs
     ```

  1. Remove the existing container:

     ```shell
     sudo docker rm gitlab_docs
     ```

  1. Pull the new image. For example, 17.8:

     ```shell
     docker run --detach --name gitlab_docs -it --rm -p 4000:4000 registry.gitlab.com/gitlab-org/technical-writing/docs-gitlab-com/archives:17.8
     ```

- If you use Docker Compose:

  1. Change the version in `docker-compose.yaml`, for example 17.8:

     ```yaml
     version: '3.6'
     services:
       gitlab_docs:
         image: registry.gitlab.com/gitlab-org/technical-writing/docs-gitlab-com/archives:17.8
         hostname: 'https://docs.gitlab.example.com:4000'
         ports:
           - '4000:4000'
     ```

  1. Pull the changes:

     ```shell
     docker-compose up -d
     ```

### Upgrade using GitLab Pages

To upgrade to a later version [using GitLab Pages](#self-host-the-product-documentation-with-gitlab-pages):

1. Edit your existing `.gitlab-ci.yml` file, and replace the `image` version number:

   ```yaml
   image: registry.gitlab.com/gitlab-org/technical-writing/docs-gitlab-com/archives:17.8
   ```

1. Commit the changes, push, and GitLab Pages pulls the new documentation site version.

### Upgrade using your own web-server

To upgrade to a later version [using your own web-server](#self-host-the-product-documentation-on-your-own-web-server):

1. Copy the HTML files of the documentation site:

   ```shell
   docker create -it --name gitlab_docs registry.gitlab.com/gitlab-org/technical-writing/docs-gitlab-com/archives:17.8
   docker cp gitlab_docs:/usr/share/nginx/html /srv/gitlab/
   docker rm -f gitlab_docs
   ```

1. Optional. Remove the old site:

   ```shell
   rm -r /srv/gitlab/html/17.8/
   ```

## Troubleshooting

### Search does not work

Local search is included in versions 15.6 and later. If you're using an earlier
version, the search doesn't work.

For more information, read about the
[different types of searches](https://gitlab.com/gitlab-org/technical-writing/docs-gitlab-com/-/blob/main/doc/search.md)
GitLab Docs are using.

### The Docker image is not found

If you get an error that the Docker image is not found, check if you're using
the [correct registry URL](#container-registry-url).

### Docker-hosted documentation site fails to redirect

When previewing the GitLab documentation in Docker on macOS, you may encounter an issue preventing
redirection to the documentation, yielding the message `If you are not redirected automatically, click here.`

To escape the redirect, you need to append the version number to the URL, such as `http://127.0.0.0.1:4000/16.8/`.
