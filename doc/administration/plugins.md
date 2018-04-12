# GitLab Plugin system

> Introduced in GitLab 10.6.

With custom plugins, GitLab administrators can introduce custom integrations
without modifying GitLab's source code.

NOTE: **Note:**
Instead of writing and supporting your own plugin you can make changes
directly to the GitLab source code and contribute back upstream. This way we can
ensure functionality is preserved across versions and covered by tests.

NOTE: **Note:**
Plugins must be configured on the filesystem of the GitLab server. Only GitLab
server administrators will be able to complete these tasks. Explore
[system hooks] or [webhooks] as an option if you do not have filesystem access.

A plugin will run on each event so it's up to you to filter events or projects
within a plugin code. You can have as many plugins as you want. Each plugin will
be triggered by GitLab asynchronously in case of an event. For a list of events
see the [system hooks] documentation.

## Setup

The plugins must be placed directly into the `plugins` directory, subdirectories
will be ignored. There is an
[`example` directory inside `plugins`](https://gitlab.com/gitlab-org/gitlab-ce/tree/master/plugins/examples)
where you can find some basic examples.

Follow the steps below to set up a custom hook:

1. On the GitLab server, navigate to the plugin directory.
   For an installation from source the path is usually
   `/home/git/gitlab/plugins/`. For Omnibus installs the path is
   usually `/opt/gitlab/embedded/service/gitlab-rails/plugins`.

    For [high availability] configurations, your hook file should be exist
    on each application server.

1. Inside the `plugins` directory, create a file with a name of your choice,
   without spaces or special characters.
1. Make the hook file executable and make sure it's owned by the git user.
1. Write the code to make the plugin function as expected. That can be
   in any language, and ensure the 'shebang' at the top properly reflects the
   language type. For example, if the script is in Ruby the shebang will
   probably be `#!/usr/bin/env ruby`.
1. The data to the plugin will be provided as JSON on STDIN. It will be exactly
   same as for [system hooks]

That's it! Assuming the plugin code is properly implemented, the hook will fire
as appropriate. The plugins file list is updated for each event, there is no
need to restart GitLab to apply a new plugin.

If a plugin executes with non-zero exit code or GitLab fails to execute it, a
message will be logged to `plugin.log`.

## Validation

Writing your own plugin can be tricky and it's easier if you can check it
without altering the system. A rake task is provided so that you can use it
in a staging environment to test your plugin before using it in production.
The rake task will use a sample data and execute each of plugin. The output
should be enough to determine if the system sees your plugin and if it was
executed without errors.

```bash
# Omnibus installations
sudo gitlab-rake plugins:validate

# Installations from source
cd /home/git/gitlab
bundle exec rake plugins:validate RAILS_ENV=production
```

Example of output:

```
Validating plugins from /plugins directory
* /home/git/gitlab/plugins/save_to_file.clj succeed (zero exit code)
* /home/git/gitlab/plugins/save_to_file.rb failure (non-zero exit code)
```

[system hooks]: ../system_hooks/system_hooks.md
[webhooks]: ../user/project/integrations/webhooks.md
[high availability]: ./high_availability/README.md