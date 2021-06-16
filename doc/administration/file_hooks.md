---
stage: Create
group: Source Code
info: "To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments"
type: reference
---

# File hooks **(FREE SELF)**

> - Introduced in GitLab 10.6.
> - Until GitLab 12.8, the feature name was Plugins.

With custom file hooks, GitLab administrators can introduce custom integrations
without modifying the GitLab source code.

NOTE:
Instead of writing and supporting your own file hook you can make changes
directly to the GitLab source code and contribute back upstream. This way we can
ensure functionality is preserved across versions and covered by tests.

NOTE:
File hooks must be configured on the file system of the GitLab server. Only GitLab
server administrators can complete these tasks. Explore
[system hooks](../system_hooks/system_hooks.md) or [webhooks](../user/project/integrations/webhooks.md)
as an option if you do not have file system access.

A file hook runs on each event. You can filter events or projects
in a file hook's code, and create many file hooks as you need. Each file hook is
triggered by GitLab asynchronously in case of an event. For a list of events
see the [system hooks](../system_hooks/system_hooks.md) documentation.

## Setup

The file hooks must be placed directly into the `file_hooks` directory, subdirectories
are ignored. There is an
[`example` directory inside `file_hooks`](https://gitlab.com/gitlab-org/gitlab/-/tree/master/file_hooks/examples)
where you can find some basic examples.

Follow the steps below to set up a custom hook:

1. On the GitLab server, navigate to the plugin directory.
   For an installation from source the path is usually
   `/home/git/gitlab/file_hooks/`. For Omnibus installs the path is
   usually `/opt/gitlab/embedded/service/gitlab-rails/file_hooks`.

    For [configurations with multiple servers](reference_architectures/index.md),
    your hook file should exist on each application server.

1. Inside the `file_hooks` directory, create a file with a name of your choice,
   without spaces or special characters.
1. Make the hook file executable and make sure it's owned by the Git user.
1. Write the code to make the file hook function as expected. That can be
   in any language, and ensure the 'shebang' at the top properly reflects the
   language type. For example, if the script is in Ruby the shebang will
   probably be `#!/usr/bin/env ruby`.
1. The data to the file hook is provided as JSON on STDIN. It is exactly the
   same as for [system hooks](../system_hooks/system_hooks.md).

That's it! Assuming the file hook code is properly implemented, the hook fires
as appropriate. The file hooks file list is updated for each event, there is no
need to restart GitLab to apply a new file hook.

If a file hook executes with non-zero exit code or GitLab fails to execute it, a
message is logged to:

- `gitlab-rails/file_hook.log` in an Omnibus installation.
- `log/file_hook.log` in a source installation.

NOTE:
Before 14.0 release, the file name was `plugin.log`

## Creating file hooks

This example responds only on the event `project_create`, and
the GitLab instance informs the administrators that a new project has been created.

```ruby
#!/opt/gitlab/embedded/bin/ruby
# By using the embedded ruby version we eliminate the possibility that our chosen language
# would be unavailable from
require 'json'
require 'mail'

# The incoming variables are in JSON format so we need to parse it first.
ARGS = JSON.parse($stdin.read)

# We only want to trigger this file hook on the event project_create
return unless ARGS['event_name'] == 'project_create'

# We will inform our admins of our gitlab instance that a new project is created
Mail.deliver do
  from    'info@gitlab_instance.com'
  to      'admin@gitlab_instance.com'
  subject "new project " + ARGS['name']
  body    ARGS['owner_name'] + 'created project ' + ARGS['name']
end
```

## Validation

Writing your own file hook can be tricky and it's easier if you can check it
without altering the system. A Rake task is provided so that you can use it
in a staging environment to test your file hook before using it in production.
The Rake task uses a sample data and execute each of file hook. The output
should be enough to determine if the system sees your file hook and if it was
executed without errors.

```shell
# Omnibus installations
sudo gitlab-rake file_hooks:validate

# Installations from source
cd /home/git/gitlab
bundle exec rake file_hooks:validate RAILS_ENV=production
```

Example of output:

```plaintext
Validating file hooks from /file_hooks directory
* /home/git/gitlab/file_hooks/save_to_file.clj succeed (zero exit code)
* /home/git/gitlab/file_hooks/save_to_file.rb failure (non-zero exit code)
```
