---
stage: Enablement
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# How to self-host the docs site **(FREE SELF)**

If you have a self-managed instance of GitLab, you may not be able to access the
product documentation as hosted on `docs.gitlab.com` from your GitLab instance.

Be aware of the following items if you self-host the product documentation:

- You must host the product documentation site under a subdirectory that matches
  your installed GitLab version (for example, `14.5/`). The
  [Docker images](https://gitlab.com/gitlab-org/gitlab-docs/container_registry/631635)
  hosted by the GitLab Docs team provide this by default. We use a
  [script](https://gitlab.com/gitlab-org/gitlab-docs/-/blob/2995d1378175803b22fb8806ba77adf63e79f32c/scripts/normalize-links.sh#L28-82)
  to normalize the links and prefix them with the respective version.
- The version dropdown will display additional versions that don't exist, selecting
  those versions will display a 404 Not Found page.
- Results when using the search box will display results from `docs.gitlab.com`
  and not the local documentation.
- When you use the Docker images to serve the product documentation site, by
  default the landing page redirects to the respective version (for example, `/14.5/`),
  which causes the landing page <https://docs.gitlab.com> to not be displayed.

## Documentation self-hosting options

You can self-host the GitLab product documentation locally using one of these
methods:

- Docker
- GitLab Pages
- From your own webserver

The examples on this page are based on GitLab 14.5.

### Self-host the product documentation with Docker

The Docker images use a built-in webserver listening on port `4000`, so you need
to expose that.

In the server that you host GitLab, or any other server that your GitLab instance
can talk to, you can use Docker to pull the docs site:

```shell
docker run -it --rm -p 4000:4000 registry.gitlab.com/gitlab-org/gitlab-docs:14.5
```

If you use [Docker compose](../install/docker.md#install-gitlab-using-docker-compose)
to host your GitLab instance, add the following to `docker-compose.yaml`:

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

You use GitLab Pages to host the GitLab product documentation locally.

Prerequisite:

- The Pages site URL must not use a subfolder. Due to the nature of how the docs
  site is pre-compiled, the CSS and JavaScript files are relative to the
  main domain or subdomain. For example, URLs like `https://example.com/docs/`
  are not supported.

To host the product documentation site with GitLab Pages:

1. [Create a new blank project](../user/project/working_with_projects.md#create-a-blank-project).
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

### Self-host the product documentation on your own webserver

Because the product documentation site is static, you can grab the directory from
the container (in `/usr/share/nginx/html`) and use your own web server to host
it wherever you want.

Use the following commands, and replace `<destination>` with the directory where the
documentation files will be copied to:

```shell
docker create -it --name gitlab-docs registry.gitlab.com/gitlab-org/gitlab-docs:14.5
docker cp gitlab-docs:/usr/share/nginx/html <destination>
docker rm -f gitlab-docs
```

## Redirect the `/help` links to the new docs page

After your local product documentation site is running, [redirect the help
links](../user/admin_area/settings/help_page.md#redirect-help-pages) in the GitLab
application to your local site.

Be sure to use the fully qualified domain name as the docs URL. For example, if you
used the [Docker method](#self-host-the-product-documentation-with-docker), enter `http://0.0.0.0:4000`.

You don't need to append the version, as GitLab will detect it and append it to
any documentation URL requests, as needed. For example, if your GitLab version is
14.5, the GitLab Docs URL becomes `http://0.0.0.0:4000/14.5/`. The link
inside GitLab displays as `<instance_url>/help/user/admin_area/settings/help_page#destination-requirements`,
but when you select it, you are redirected to
`http://0.0.0.0:4000/14.5/ee/user/admin_area/settings/help_page/#destination-requirements`.

To test the setting, select a **Learn more** link within the GitLab application.
