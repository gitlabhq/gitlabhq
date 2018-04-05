# Plugins

**Note:** Plugins must be configured on the filesystem of the GitLab
server. Only GitLab server administrators will be able to complete these tasks.
Please explore [system hooks] or [webhooks] as an option if you do not
have filesystem access. 

Introduced in GitLab 10.6.

A plugin will run on each event so it's up to you to filter events or projects within a plugin code. You can have as many plugins as you want. Each plugin will be triggered by GitLab asynchronously in case of an event. For a list of events please see [system hooks] documentation.

## Setup

Plugins must be placed directly into `plugins` directory, subdirectories will be ignored. 
There is an `example` directory inside `plugins` where you can find some basic examples. 

Follow the steps below to set up a custom hook:

1. On the GitLab server, navigate to the project's plugin directory.
   For an installation from source the path is usually
   `/home/git/gitlab/plugins/`. For Omnibus installs the path is
   usually `/opt/gitlab/embedded/service/gitlab-rails/plugins`.
1. Inside the `plugins` directory, create a file with a name of your choice, but without spaces or special characters.
1. Make the hook file executable and make sure it's owned by the git user.
1. Write the code to make the plugin function as expected. Plugin can be
   in any language. Ensure the 'shebang' at the top properly reflects the language
   type. For example, if the script is in Ruby the shebang will probably be
   `#!/usr/bin/env ruby`.
1. The data to the plugin will be provided as JSON on STDIN. It will be exactly same as one for [system hooks]

That's it! Assuming the plugin code is properly implemented the hook will fire
as appropriate. Plugins file list is updated for each event. There is no need to restart GitLab to apply a new plugin.

If a plugin executes with non-zero exit code or GitLab fails to execute it, a
message will be logged to `plugin.log`.

## Validation

Writing own plugin can be tricky and its easier if you can check it without altering the system. 
We provided a rake task you can use with staging environment to test your plugin before using it in production. 
The rake task will use a sample data and execute each of plugins. By output you should be able to determine if 
system sees your plugin and if it was executed without errors.

```bash
# Omnibus installations
sudo gitlab-rake plugins:validate

# Installations from source
bundle exec rake plugins:validate RAILS_ENV=production
```

Example of output can be next: 

```
-> bundle exec rake plugins:validate RAILS_ENV=production
Validating plugins from /plugins directory
* /home/git/gitlab/plugins/save_to_file.clj succeed (zero exit code)
* /home/git/gitlab/plugins/save_to_file.rb failure (non-zero exit code)
```

[hooks]: https://git-scm.com/book/en/v2/Customizing-Git-Git-Hooks#Server-Side-Hooks
[system hooks]: ../system_hooks/system_hooks.md
[webhooks]: ../user/project/integrations/webhooks.md
[5073]: https://gitlab.com/gitlab-org/gitlab-ce/merge_requests/5073
[93]: https://gitlab.com/gitlab-org/gitlab-shell/merge_requests/93

