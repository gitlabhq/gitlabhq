---
stage: Enablement
group: Geo
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
type: howto
---

<!-- Please update EE::GitLab::GeoGitAccess::GEO_SERVER_DOCS_URL if this file is moved) -->

# Using a Geo Site **(PREMIUM SELF)**

After you set up the [database replication and configure the Geo nodes](../index.md#setup-instructions), use your closest GitLab site as you would do with the primary one.

You can push directly to a **secondary** site (for both HTTP, SSH including Git LFS), and the request will be proxied to the primary site instead ([introduced](https://about.gitlab.com/releases/2018/09/22/gitlab-11-3-released/) in [GitLab Premium](https://about.gitlab.com/pricing/#self-managed) 11.3).

Example of the output you will see when pushing to a **secondary** site:

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
