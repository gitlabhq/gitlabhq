---
stage: Foundations
group: Import and Integrate
info: "To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments"
title: File hooks
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab Self-Managed

Use custom file hooks (not to be confused with [server hooks](server_hooks.md) or [system hooks](system_hooks.md)),
to introduce custom integrations without modifying the GitLab source code.

A file hook runs on each event. You can filter events or projects
in a file hook's code, and create many file hooks as you need. Each file hook is
triggered by GitLab asynchronously in case of an event. For a list of events,
see the [system hooks](system_hooks.md) and [webhooks](../user/project/integrations/webhook_events.md) documentation.

NOTE:
File hooks must be configured on the file system of the GitLab server. Only GitLab
server administrators can complete these tasks. Explore
[system hooks](system_hooks.md) or [webhooks](../user/project/integrations/webhooks.md)
as an option if you do not have file system access.

Instead of writing and supporting your own file hook, you can also make changes
directly to the GitLab source code and contribute back upstream. In this way, we can
ensure functionality is preserved across versions and covered by tests.

## Set up a custom file hook

File hooks must be in the `file_hooks` directory. Subdirectories are ignored.
Find examples in the
[`example` directory under `file_hooks`](https://gitlab.com/gitlab-org/gitlab/-/tree/master/file_hooks/examples).

To set up a custom hook:

1. On the GitLab server, locate the plugin directory. For self-compiled installations, the path is usually
   `/home/git/gitlab/file_hooks/`. For Linux package installations, the path is usually
   `/opt/gitlab/embedded/service/gitlab-rails/file_hooks`.

   For [configurations with multiple servers](reference_architectures/_index.md), your hook file should exist on each
   application server.

1. Inside the `file_hooks` directory, create a file with a name of your choice,
   without spaces or special characters.
1. Make the hook file executable and make sure it's owned by the Git user.
1. Write the code to make the file hook function as expected. That can be
   in any language, and ensure the 'shebang' at the top properly reflects the
   language type. For example, if the script is in Ruby the shebang will
   probably be `#!/usr/bin/env ruby`.
1. The data to the file hook is provided as JSON on `STDIN`. It is exactly the
   same as for [system hooks](system_hooks.md).

Assuming the file hook code is properly implemented, the hook fires
as appropriate. The file hooks file list is updated for each event. There is no
need to restart GitLab to apply a new file hook.

If a file hook executes with non-zero exit code or GitLab fails to execute it, a
message is logged to:

- `gitlab-rails/file_hook.log` in a Linux package installation.
- `log/file_hook.log` in a self-compiled installation.

## File hook example

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

## Validation example

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
