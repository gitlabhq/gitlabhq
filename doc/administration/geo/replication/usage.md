---
stage: Systems
group: Geo
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

<!-- Please update EE::GitLab::GeoGitAccess::GEO_SERVER_DOCS_URL if this file is moved) -->

# Using a Geo Site

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** GitLab Self-Managed

After you set up the [database replication and configure the Geo nodes](../setup/_index.md), use your closest GitLab site as you would do with the primary one.

## Git operations

You can push directly to a **secondary** site (for both HTTP, SSH including
Git LFS), and the request is proxied to the primary site instead.

Example of the output you see when pushing to a **secondary** site:

```shell
$ git push
remote:
remote: This request to a Geo secondary node will be forwarded to the
remote: Geo primary node:
remote:
remote:   ssh://git@primary.geo/user/repo.git
remote:
Everything up-to-date
```

NOTE:
If you're using HTTPS instead of [SSH](../../../user/ssh.md) to push to the secondary,
you can't store credentials in the URL like `user:password@URL`. Instead, you can use a
[`.netrc` file](https://www.gnu.org/software/inetutils/manual/html_node/The-_002enetrc-file.html)
for Unix-like operating systems or `_netrc` for Windows. In that case, the credentials
are stored as a plain text. If you're looking for a more secure way to store credentials,
you can use [Git Credential Storage](https://git-scm.com/book/en/v2/Git-Tools-Credential-Storage).

## Web user interface

The web user interface on the **secondary** site is read/write. As a user, all actions permitted on the **primary** site can be performed on the **secondary** site without limitations.

Web interface access requests on the **secondary** sites are automatically and transparently proxied to the **primary** site.

## Fetch Go modules from Geo secondary sites

Go modules can be pulled from secondary sites, with a number of limitations:

- Git configuration (using `insteadOf`) is needed to fetch data from the Geo secondary site.
- For private projects, authentication details need to be specified in `~/.netrc`.

For more information, see
[Using a project as a Go package](../../../user/project/use_project_as_go_package.md#fetch-go-modules-from-geo-secondary-sites).
