<!-- Please update EE::GitLab::GeoGitAccess::GEO_SERVER_DOCS_URL if this file is moved) -->

# Using a Geo Server **(PREMIUM ONLY)**

After you set up the [database replication and configure the Geo nodes](index.md#setup-instructions), use your closest GitLab node as you would a normal standalone GitLab instance.

Pushing directly to a **secondary** node (for both HTTP, SSH including Git LFS) was [introduced](https://about.gitlab.com/releases/2018/09/22/gitlab-11-3-released/) in [GitLab Premium](https://about.gitlab.com/pricing/#self-managed) 11.3.

Example of the output you will see when pushing to a **secondary** node:

```shell
$ git push
remote:
remote: You're pushing to a Geo secondary. We'll help you by proxying this
remote: request to the primary:
remote:
remote:   ssh://git@primary.geo/user/repo.git
remote:
Everything up-to-date
```
