# Custom Git Hooks

**Note: Custom git hooks must be configured on the filesystem of the GitLab
server. Only GitLab server administrators will be able to complete these tasks.
Please explore webhooks as an option if you do not have filesystem access. For a user configurable Git Hooks interface, please see [GitLab Enterprise Edition Git Hooks](http://doc.gitlab.com/ee/git_hooks/git_hooks.html).**

Git natively supports hooks that are executed on different actions.
Examples of server-side git hooks include pre-receive, post-receive, and update.
See
[Git SCM Server-Side Hooks](http://git-scm.com/book/en/v2/Customizing-Git-Git-Hooks#Server-Side-Hooks)
for more information about each hook type.

As of gitlab-shell version 2.2.0 (which requires GitLab 7.5+), GitLab
administrators can add custom git hooks to any GitLab project.

## Setup

Normally, git hooks are placed in the repository or project's `hooks` directory.
GitLab creates a symlink from each project's `hooks` directory to the
gitlab-shell `hooks` directory for ease of maintenance between gitlab-shell
upgrades. As such, custom hooks are implemented a little differently. Behavior
is exactly the same once the hook is created, though. Follow these steps to
set up a custom hook.

1. Pick a project that needs a custom git hook.
1. On the GitLab server, navigate to the project's repository directory.
For an installation from source the path is usually
`/home/git/repositories/<group>/<project>.git`. For Omnibus installs the path is
usually `/var/opt/gitlab/git-data/repositories/<group>/<project>.git`.
1. Create a new directory in this location called `custom_hooks`.
1. Inside the new `custom_hooks` directory, create a file with a name matching
the hook type. For a pre-receive hook the file name should be `pre-receive` with
no extension.
1. Make the hook file executable and make sure it's owned by git.
1. Write the code to make the git hook function as expected. Hooks can be
in any language. Ensure the 'shebang' at the top properly reflects the language
type. For example, if the script is in Ruby the shebang will probably be
`#!/usr/bin/env ruby`.

That's it! Assuming the hook code is properly implemented the hook will fire
as appropriate.
