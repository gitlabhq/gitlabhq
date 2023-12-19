---
stage: Create
group: Code Creation
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
---

# Code Suggestions development guidelines

## Code Suggestions development setup

The recommended setup for locally developing and debugging Code Suggestions is to have all 3 different components running:

- IDE Extension (e.g. VS Code Extension)
- Main application configured correctly
- [Model gateway](https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist)

This should enable everyone to see locally any change in an IDE being sent to the main application transformed to a prompt which is then sent to the respective model.

### Setup instructions

1. Install and run locally the [VSCode Extension](https://gitlab.com/gitlab-org/gitlab-vscode-extension/-/blob/main/CONTRIBUTING.md#configuring-development-environment)
   1. Add the ```"gitlab.debug": true,``` info to the Code Suggestions development config
      1. In VS Code navigate to the Extensions page and find "GitLab Workflow" in the list
      1. Open the extension settings by clicking a small cog icon and select "Extension Settings" option
      1. Check a "GitLab: Debug" checkbox.
1. Main Application
   1. Enable Feature Flag ```code_suggestions_tokens_api```
      1. In your terminal, navigate to a `gitlab` inside your `gitlab-development-kit` directory
      1. Run `bundle exec rails c` to start a Rails console
      1. Call `Feature.enable(:code_suggestions_tokens_api)` from the console
   1. Run the GDK with ```export CODE_SUGGESTIONS_BASE_URL=http://localhost:5052```
1. [Setup Model Gateway](https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist#how-to-run-the-server-locally)
    1. Build tree sitter libraries ```poetry run scripts/build-tree-sitter-lib.py```
    1. Extra .env Changes for all debugging insights
        1. LOG_LEVEL=DEBUG
        1. LOG_FORMAT_JSON=false
        1. LOG_TO_FILE=true
    1. Watch the new log file ```modelgateway_debug.log``` , e.g. ```tail -f modelgateway_debug.log | fblog -a prefix -a suffix -a current_file_name -a suggestion -a language -a input -a parameters -a score -a exception```

### Setup instructions to use staging Model Gateway

When testing interactions with the Model Gateway, you might want to integrate your local GDK
with the deployed staging Model Gateway. To do this:

1. You need a [cloud staging license](../../user/project/repository/code_suggestions/self_managed.md#upgrade-gitlab) that has the Code Suggestions add-on, because add-ons are enabled on staging. Drop a note in the `#s_fulfillment` internal Slack channel to request an add-on to your license. See this [handbook page](https://about.gitlab.com/handbook/developer-onboarding/#working-on-gitlab-ee-developer-licenses) for how to request a license for local development.
1. Set environment variables to point customers-dot to staging, and the Model Gateway to staging:

   ```shell
   export GITLAB_LICENSE_MODE=test
   export CUSTOMER_PORTAL_URL=https://customers.staging.gitlab.com
   export CODE_SUGGESTIONS_BASE_URL=https://codesuggestions.staging.gitlab.com
   ```

1. Restart the GDK.
1. Ensure you followed the necessary [steps to enable the Code Suggestions feature](../../user/project/repository/code_suggestions/self_managed.md#gitlab-163-and-later).
1. Test out the Code Suggestions feature by opening the Web IDE for a project.
