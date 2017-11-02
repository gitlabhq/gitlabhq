# Install GitLab under a relative URL

NOTE: **Note:**
This document describes how to run GitLab under a relative URL for installations
from source. If you are using an Omnibus package,
[the steps are different][omnibus-rel]. Use this guide along with the
[installation guide](installation.md) if you are installing GitLab for the
first time.

---

While it is recommended to install GitLab on its own (sub)domain, sometimes
this is not possible due to a variety of reasons. In that case, GitLab can also
be installed under a relative URL, for example `https://example.com/gitlab`.

There is no limit to how deeply nested the relative URL can be. For example you
could serve GitLab under `/foo/bar/gitlab/git` without any issues.

Note that by changing the URL on an existing GitLab installation, all remote
URLs will change, so you'll have to manually edit them in any local repository
that points to your GitLab instance.

---

The TL;DR list of configuration files that you need to change in order to
serve GitLab under a relative URL is:

- `/home/git/gitlab/config/initializers/relative_url.rb`
- `/home/git/gitlab/config/gitlab.yml`
- `/home/git/gitlab/config/unicorn.rb`
- `/home/git/gitlab-shell/config.yml`
- `/etc/default/gitlab`

After all the changes you need to recompile the assets and [restart GitLab].

## Relative URL requirements

If you configure GitLab with a relative URL, the assets (JavaScript, CSS, fonts,
images, etc.) will need to be recompiled, which is a task which consumes a lot
of CPU and memory resources. To avoid out-of-memory errors, you should have at
least 2GB of RAM available on your system, while we recommend 4GB RAM, and 4 or
8 CPU cores.

See the [requirements](requirements.md) document for more information.

## Enable relative URL in GitLab

NOTE: **Note:**
Do not make any changes to your web server configuration file regarding
relative URL. The relative URL support is implemented by GitLab Workhorse.

---

Before following the steps below to enable relative URL in GitLab, some
assumptions are made:

- GitLab is served under `/gitlab`
- The directory under which GitLab is installed is `/home/git/`

Make sure to follow all steps below:

1.  (Optional) If you run short on resources, you can temporarily free up some
    memory by shutting down the GitLab service with the following command:

    ```shell
    sudo service gitlab stop
    ```

1.  Create `/home/git/gitlab/config/initializers/relative_url.rb`

    ```shell
    cp /home/git/gitlab/config/initializers/relative_url.rb.sample \
       /home/git/gitlab/config/initializers/relative_url.rb
    ```

    and change the following line:

    ```ruby
    config.relative_url_root = "/gitlab"
    ```

1.  Edit `/home/git/gitlab/config/gitlab.yml` and uncomment/change the
    following line:

    ```yaml
    relative_url_root: /gitlab
    ```

1.  Edit `/home/git/gitlab/config/unicorn.rb` and uncomment/change the
    following line:

    ```ruby
    ENV['RAILS_RELATIVE_URL_ROOT'] = "/gitlab"
    ```

1.  Edit `/home/git/gitlab-shell/config.yml` and append the relative path to
    the following line:

    ```yaml
    gitlab_url: http://127.0.0.1/gitlab
    ```

1.  Make sure you have copied the supplied init script and the defaults file
    as stated in the [installation guide](installation.md#install-init-script).
    Then, edit `/etc/default/gitlab` and set in `gitlab_workhorse_options` the
    `-authBackend` setting to read like:

    ```shell
    -authBackend http://127.0.0.1:8080/gitlab
    ```

    **Note:**
    If you are using a custom init script, make sure to edit the above
    gitlab-workhorse setting as needed.

1. [Restart GitLab][] for the changes to take effect.

## Disable relative URL in GitLab

To disable the relative URL:

1.  Remove `/home/git/gitlab/config/initializers/relative_url.rb`

1.  Follow the same as above starting from 2. and set up the
    GitLab URL to one that doesn't contain a relative path.

[omnibus-rel]: http://docs.gitlab.com/omnibus/settings/configuration.html#configuring-a-relative-url-for-gitlab "How to setup relative URL in Omnibus GitLab"
[restart gitlab]: ../administration/restart_gitlab.md#installations-from-source "How to restart GitLab"
