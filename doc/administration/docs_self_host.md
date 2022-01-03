---
stage: Enablement
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# How to self-host the docs site **(FREE SELF)**

The following guide describes how to use a local instance of the docs site with
a self-managed GitLab instance.

## Run the docs site

The easiest way to run the docs site locally it to pick up one of the existing
Docker images that contain the HTML files.

Pick the version that matches your GitLab version and run it, in the following
examples 14.5.

### Host the docs site using Docker

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

### Host the docs site using GitLab Pages

You can also host the docs site with GitLab Pages.

Prerequisite:

- The Pages site URL must not use a subfolder. Due to the nature of how the docs
  site is pre-compiled, the CSS and JavaScript files are relative to the
  main domain or subdomain. For example, URLs like `https://example.com/docs/`
  are not supported.

To host the docs site with GitLab Pages:

1. [Create a new blank project](../user/project/working_with_projects.md#create-a-blank-project).
1. Create a new or edit your existing `.gitlab-ci.yml` file and add the following
   `pages` job. Make sure the version is the same as your GitLab installation:

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

1. (Optional) Set the Pages domain name. Depending on the type of the Pages website,
   you have two options:

   | Type of website | [Default domain](../user/project/pages/getting_started_part_one.md#gitlab-pages-default-domain-names) | [Custom domain](../user/project/pages/custom_domains_ssl_tls_certification/index.md) |
   | --------------- | -------------- | ------------- |
   | [Project website](../user/project/pages/getting_started_part_one.md#project-website-examples) | Not supported | Supported |
   | [User or group website](../user/project/pages/getting_started_part_one.md#user-and-group-website-examples) | Supported | Supported |

### Host the docs site on your own webserver

Since the docs site is static, you can grab the directory from the container
(under `/usr/share/nginx/html`) and use your own web server to host
it wherever you want. Replace `<destination>` with the directory where the
docs will be copied to:

```shell
docker create -it --name gitlab-docs registry.gitlab.com/gitlab-org/gitlab-docs:14.5
docker cp gitlab-docs:/usr/share/nginx/html <destination>
docker rm -f gitlab-docs
```

## Redirect the `/help` links to the new docs page

When the docs site is up and running:

1. [Enable the help page redirects](../user/admin_area/settings/help_page.md#redirect-help-pages).
   Use the Fully Qualified Domain Name as the docs URL. For example, if you
   used the [Docker method](#host-the-docs-site-using-docker) , enter `http://0.0.0.0:4000`.
   You don't need to append the version, it is detected automatically.
1. Test that everything works by selecting the **Learn more** link on the page
   you're on. Your GitLab version is automatically detected and appended to the docs URL
   you set in the admin area. In this example, if your GitLab version is 14.5,
   `https://<instance_url>/` becomes `http://0.0.0.0:4000/14.5/`.
   The link inside GitLab link shows as
   `<instance_url>/help/user/admin_area/settings/help_page#destination-requirements`,
   but when you select it, you are redirected to
   `http://0.0.0.0:4000/14.5/ee/user/admin_area/settings/help_page/#destination-requirements`.

## Caveats

- You need to host the docs site under a subdirectory matching your GitLab version,
  in the example of this guide `14.5/`. The
  [Docker images](https://gitlab.com/gitlab-org/gitlab-docs/container_registry/631635)
  hosted by the Docs team provide this by default. We use a
  [script](https://gitlab.com/gitlab-org/gitlab-docs/-/blob/2995d1378175803b22fb8806ba77adf63e79f32c/scripts/normalize-links.sh#L28-82)
  to normalize the links and prefix them with the respective version.
- The version dropdown will show more versions which do not exist and will lead
  to 404 if selected.
- The search results point to `docs.gitlab.com` and not the local docs.
- When you use the Docker images to serve the docs site, the landing page redirects
  by default to the respective version, for example `/14.5/`, so you don't
  see the landing page as seen at <https://docs.gitlab.com>.
