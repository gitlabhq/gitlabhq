---
stage: Enablement
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
type: reference
---

# Install GitLab under a relative URL **(FREE SELF)**

While it is recommended to install GitLab on its own (sub)domain, sometimes
this is not possible due to a variety of reasons. In that case, GitLab can also
be installed under a relative URL, for example `https://example.com/gitlab`.

This document describes how to run GitLab under a relative URL for installations
from source. If you are using an Omnibus package,
[the steps are different](https://docs.gitlab.com/omnibus/settings/configuration.html#configuring-a-relative-url-for-gitlab). Use this guide along with the
[installation guide](installation.md) if you are installing GitLab for the
first time.

There is no limit to how deeply nested the relative URL can be. For example you
could serve GitLab under `/foo/bar/gitlab/git` without any issues.

Note that by changing the URL on an existing GitLab installation, all remote
URLs will change, so you'll have to manually edit them in any local repository
that points to your GitLab instance.

The list of configuration files you must change to serve GitLab from a
relative URL is:

- `/home/git/gitlab/config/initializers/relative_url.rb`
- `/home/git/gitlab/config/gitlab.yml`
- `/home/git/gitlab/config/puma.rb`
- `/home/git/gitlab-shell/config.yml`
- `/etc/default/gitlab`

After all the changes you need to recompile the assets and [restart GitLab](../administration/restart_gitlab.md#installations-from-source).

## Relative URL requirements

If you configure GitLab with a relative URL, the assets (JavaScript, CSS, fonts,
images, etc.) will need to be recompiled, which is a task which consumes a lot
of CPU and memory resources. To avoid out-of-memory errors, you should have at
least 2GB of RAM available on your system, while we recommend 4GB RAM, and 4 or
8 CPU cores.

See the [requirements](requirements.md) document for more information.

## Enable relative URL in GitLab

NOTE:
Do not make any changes to your web server configuration file regarding
relative URL. The relative URL support is implemented by GitLab Workhorse.

---

Before following the steps below to enable relative URL in GitLab, some
assumptions are made:

- GitLab is served under `/gitlab`
- The directory under which GitLab is installed is `/home/git/`

Make sure to follow all steps below:

1. (Optional) If you run short on resources, you can temporarily free up some
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

1. Make sure you have copied the supplied init script and the defaults file
   as stated in the [installation guide](installation.md#install-init-script).
   Then, edit `/etc/default/gitlab` and set in `gitlab_workhorse_options` the
   `-authBackend` setting to read like:

   ```shell
   -authBackend http://127.0.0.1:8080/gitlab
   ```

   NOTE:
   If you are using a custom init script, make sure to edit the above
   GitLab Workhorse setting as needed.

1. [Restart GitLab](../administration/restart_gitlab.md#installations-from-source) for the changes to take effect.

## Disable relative URL in GitLab

To disable the relative URL:

1. Remove `/home/git/gitlab/config/initializers/relative_url.rb`

1. Follow the same as above starting from 2. and set up the
    GitLab URL to one that doesn't contain a relative path.

<!-- ## Troubleshooting

Include any troubleshooting steps that you can foresee. If you know beforehand what issues
one might have when setting this up, or when something is changed, or on upgrading, it's
important to describe those, too. Think of things that may go wrong and include them here.
This is important to minimize requests for support, and to avoid doc comments with
questions that you know someone might ask.

Each scenario can be a third-level heading, e.g. `### Getting error message X`.
If you have none to add when creating a doc, leave this section in place
but commented out to help encourage others to add to it in the future. -->
