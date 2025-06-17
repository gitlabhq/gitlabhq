---
stage: GitLab Delivery
group: Self Managed
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Install GitLab under a relative URL
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed

{{< /details >}}

While you should install GitLab on its own (sub)domain, sometimes
this is not possible due to a variety of reasons. In that case, GitLab can also
be installed under a relative URL, for example `https://example.com/gitlab`.

This document describes how to run GitLab under a relative URL for installations
from source. If you are using an official Linux package,
[the steps are different](https://docs.gitlab.com/omnibus/settings/configuration.html#configuring-a-relative-url-for-gitlab). Use this guide along with the
[installation guide](installation.md) if you are installing GitLab for the
first time.

There is no limit to how deeply nested the relative URL can be. For example you
could serve GitLab under `/foo/bar/gitlab/git` without any issues.

Changing the URL on an existing GitLab installation, changes all remote
URLs, so you have to manually edit them in any local repository
that points to your GitLab instance.

The list of configuration files you must change to serve GitLab from a
relative URL is:

- `/home/git/gitlab/config/initializers/relative_url.rb`
- `/home/git/gitlab/config/gitlab.yml`
- `/home/git/gitlab/config/puma.rb`
- `/home/git/gitlab-shell/config.yml`
- `/etc/default/gitlab`

After all the changes, you must recompile the assets and [restart GitLab](../administration/restart_gitlab.md#self-compiled-installations).

## Relative URL requirements

If you configure GitLab with a relative URL, the assets (including JavaScript,
CSS, fonts, and images) must be recompiled, which can consume a lot of CPU and
memory resources. To avoid out-of-memory errors, you should have at least 2 GB
of RAM available on your computer, and we recommend 4 GB RAM, and four or eight
CPU cores.

See the [requirements](requirements.md) document for more information.

## Enable relative URL in GitLab

{{< alert type="note" >}}

Do not make any changes to your web server configuration file regarding
relative URL. The relative URL support is implemented by GitLab Workhorse.

{{< /alert >}}

---

This process assumes:

- GitLab is served under `/gitlab`
- The directory under which GitLab is installed is `/home/git/`

To enable relative URLs in GitLab:

1. Optional. If you run short on resources, you can temporarily free up some
   memory by shutting down the GitLab service with the following command:

   ```shell
   sudo service gitlab stop
   ```

1. Create `/home/git/gitlab/config/initializers/relative_url.rb`

   ```shell
   cp /home/git/gitlab/config/initializers/relative_url.rb.sample \
      /home/git/gitlab/config/initializers/relative_url.rb
   ```

   and change the following line:

   ```ruby
   config.relative_url_root = "/gitlab"
   ```

1. Edit `/home/git/gitlab/config/gitlab.yml` and uncomment/change the
   following line:

   ```yaml
   relative_url_root: /gitlab
   ```

1. Edit `/home/git/gitlab/config/puma.rb` and uncomment/change the
   following line:

   ```ruby
   ENV['RAILS_RELATIVE_URL_ROOT'] = "/gitlab"
   ```

1. Edit `/home/git/gitlab-shell/config.yml` and append the relative path to
   the following line:

   ```yaml
   gitlab_url: http://127.0.0.1/gitlab
   ```

1. Make sure you have copied either the supplied systemd services, or the init
   script and the defaults file, as stated in the
   [installation guide](installation.md#install-the-service).
   Then, edit `/etc/default/gitlab` and set in `gitlab_workhorse_options` the
   `-authBackend` setting to read like:

   ```shell
   -authBackend http://127.0.0.1:8080/gitlab
   ```

   {{< alert type="note" >}}

   If you are using a custom init script, make sure to edit the previous
   GitLab Workhorse setting as needed.

   {{< /alert >}}

1. [Restart GitLab](../administration/restart_gitlab.md#self-compiled-installations) for the changes to take effect.

## Disable relative URL in GitLab

To disable the relative URL:

1. Remove `/home/git/gitlab/config/initializers/relative_url.rb`

1. Follow the previous steps starting from 2. and set up the
   GitLab URL to one that doesn't contain a relative path.
