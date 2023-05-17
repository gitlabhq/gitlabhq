---
stage: none
group: unassigned
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# VS Code debugging

This document describes how to set up Rails debugging in [VS Code](https://code.visualstudio.com/).

## Setup

1. Install the `debug` gem by running `gem install debug` inside your `gitlab` folder.
1. Add the following configuration to your `.vscode/tasks.json` file:

    ```json
    {
      "version": "2.0.0",
      "tasks": [
          {
            "label": "start rdbg",
            "type": "shell",
            "command": "gdk stop rails-web && GITLAB_RAILS_RACK_TIMEOUT_ENABLE_LOGGING=false PUMA_SINGLE_MODE=true rdbg --open -c -- bin/rails s",
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
          }
      ]
    }
    ```

1. Add the following configuration to your `.vscode/launch.json` file:

    ```json
    {
        // Use IntelliSense to learn about possible attributes.
        // Hover to view descriptions of existing attributes.
        // For more information, see https://go.microsoft.com/fwlink/?linkid=830387.
        "version": "0.2.0",
        "configurations": [
          {
            "type": "rdbg",
            "name": "Attach with rdbg",
            "request": "attach",
            "preLaunchTask": "start rdbg"
          }
        ]
    }
    ```

## Debugging

Prerequisite:

- You must have a running GDK instance.

To start debugging, do one of the following:

- Press <kbd>F5</kbd>.
- Run the `Debug: Start Debugging` command.
