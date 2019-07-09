[//]: # (Please update EE::GitLab::GeoGitAccess::GEO_SERVER_DOCS_URL if this file is moved)

# Using a Geo Server **(PREMIUM ONLY)**

After you set up the [database replication and configure the Geo nodes][req], use your closest GitLab node as you would a normal standalone GitLab instance.

Pushing directly to a **secondary** node (for both HTTP, SSH including git-lfs) was [introduced](https://about.gitlab.com/2018/09/22/gitlab-11-3-released/) in [GitLab Premium](https://about.gitlab.com/pricing/#self-managed) 11.3.

Example of the output you will see when pushing to a **secondary** node:

```bash
$ git push
> GitLab: You're pushing to a Geo secondary.
> GitLab: We'll help you by proxying this request to the primary: ssh://git@primary.geo/user/repo.git
Everything up-to-date
```

[req]: index.md#setup-instructions
