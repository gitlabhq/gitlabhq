---
stage: none
group: unassigned
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
title: VS Code debugging
---

This document describes how to set up Rails debugging in [Visual Studio Code (VS Code)](https://code.visualstudio.com/) using the [GitLab Development Kit (GDK)](contributing/first_contribution/configure-dev-env-gdk.md).

## Setup

The examples below contain launch configurations for `rails-web` and `rails-background-jobs`.

1. Install the `debug` gem by running `gem install debug` inside your `gitlab` folder.
1. Install the [VS Code Ruby `rdbg` Debugger](https://marketplace.visualstudio.com/items?itemName=KoichiSasada.vscode-rdbg) extension to add support for the `rdbg` debugger type to VS Code.
1. In case you want to automatically stop and start GitLab and its associated Ruby Rails/Sidekiq process, you may add the following VS Code task to your configuration under the `.vscode/tasks.json` file:

   ```json
   {
     "version": "2.0.0",
     "tasks": [
       {
         "label": "start rdbg for rails-web",
         "type": "shell",
         "command": "gdk stop rails-web && GITLAB_RAILS_RACK_TIMEOUT_ENABLE_LOGGING=false PUMA_SINGLE_MODE=true rdbg --open -c bin/rails server",
         "isBackground": true,
         "problemMatcher": {
           "owner": "rails",
           "pattern": {
             "regexp": "^.*$",
           },
           "background": {
             "activeOnStart": false,
             "beginsPattern": "^(ok: down:).*$",
             "endsPattern": "^(DEBUGGER: wait for debugger connection\\.\\.\\.)$"
           }
         }
       },
       {
         "label": "start rdbg for rails-background-jobs",
         "type": "shell",
         "command": "gdk stop rails-background-jobs && rdbg --open -c bundle exec sidekiq",
         "isBackground": true,
         "problemMatcher": {
           "owner": "sidekiq",
           "pattern": {
             "regexp": "^(DEBUGGER: wait for debugger connection\\.\\.\\.)$"
           },
           "background": {
             "activeOnStart": false,
             "beginsPattern": "^(ok: down:).*$",
             "endsPattern": "^(DEBUGGER: wait for debugger connection\\.\\.\\.)$"
           }
         }
       }
     ]
   }
   ```

1. Add the following configuration to your `.vscode/launch.json` file:

   ```json
   {
     "version": "0.2.0",
     "configurations": [
       {
         "type": "rdbg",
         "name": "Attach rails-web with rdbg",
         "request": "attach",

         // remove the following "preLaunchTask" if you do not wish to stop and start
         // GitLab via VS Code but manually on a separate terminal.
         "preLaunchTask": "start rdbg for rails-web"
       },
       {
         "type": "rdbg",
         "name": "Attach rails-background-jobs with rdbg",
         "request": "attach",

         // remove the following "preLaunchTask" if you do not wish to stop and start
         // GitLab via VS Code but manually on a separate terminal.
         "preLaunchTask": "start rdbg for rails-background-jobs"
       }
     ]
   }
   ```

WARNING:
The VS Code Ruby extension might have issues finding the correct Ruby installation and the appropriate `rdbg` command. In this case, add `"rdbgPath": "/home/user/.asdf/shims/` (in the case of asdf) to the launch configuration above.

## Debugging

### Prerequisites

- You must have a running [GDK](contributing/first_contribution/configure-dev-env-gdk.md) instance.

To start debugging, do one of the following:

- Press <kbd>F5</kbd>.
- Run the `Debug: Start Debugging` command.
- Open the [Run and Debug view](https://code.visualstudio.com/docs/editor/debugging#_run-and-debug-view), select one of the launch profiles, then select **Play** (**{play}**).
