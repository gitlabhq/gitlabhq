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
- [AI Gateway](https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist)

This should enable everyone to see locally any change in an IDE being sent to the main application transformed to a prompt which is then sent to the respective model.

### Setup instructions

1. Install and run locally the [VSCode Extension](https://gitlab.com/gitlab-org/gitlab-vscode-extension/-/blob/main/CONTRIBUTING.md#configuring-development-environment)
   1. Add the ```"gitlab.debug": true,``` info to the Code Suggestions development config
      1. In VS Code navigate to the Extensions page and find "GitLab Workflow" in the list
      1. Open the extension settings by clicking a small cog icon and select "Extension Settings" option
      1. Check a "GitLab: Debug" checkbox.
1. Main Application (GDK):
   1. Install the [GitLab Development Kit](https://gitlab.com/gitlab-org/gitlab-development-kit/-/blob/main/doc/index.md#one-line-installation).
   1. Enable Feature Flag ```code_suggestions_tokens_api```
      1. In your terminal, navigate to your `gitlab-development-kit` > `gitlab` directory.
      1. Run `gdk rails console` or `bundle exec rails c` to start a Rails console.
      1. [Enable the Feature Flag](../../administration/feature_flags.md#enable-or-disable-the-feature) for the code suggestions tokens API by calling 
         `Feature.enable(:code_suggestions_tokens_api)` from the console.
   1. Run the GDK with ```export AI_GATEWAY_URL=http://localhost:5052```
1. [Setup AI Gateway](https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist):
    1. Complete the steps to [run the server locally](https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist#how-to-run-the-server-locally).
        - If running `asdf install` doesn't install the dependencies in ``.tool-versions``, you may need to run `asdf plugin add <name>` for each dependency first.
    1. Inside ``poetry shell``, build tree sitter libraries by running ```poetry run scripts/build-tree-sitter-lib.py```
    1. Add the following variables to the `.env` file for all debugging insights:
        1. `AIGW_LOGGING__LEVEL=DEBUG`
        1. `AIGW_LOGGING__FORMAT_JSON=false`
        1. `AIGW_LOGGING__TO_FILE=true`
    1. Watch the new log file ```modelgateway_debug.log``` , e.g. ```tail -f modelgateway_debug.log | fblog -a prefix -a suffix -a current_file_name -a suggestion -a language -a input -a parameters -a score -a exception```

### Setup instructions to use staging AI Gateway

When testing interactions with the AI Gateway, you might want to integrate your local GDK
with the deployed staging AI Gateway. To do this:

1. You need a [cloud staging license](../../user/project/repository/code_suggestions/self_managed_prior_versions.md#upgrade-to-gitlab-163) that has the Code Suggestions add-on, because add-ons are enabled on staging. Drop a note in the `#s_fulfillment` internal Slack channel to request an add-on to your license. See this [handbook page](https://handbook.gitlab.com/handbook/developer-onboarding/#working-on-gitlab-ee-developer-licenses) for how to request a license for local development.
1. Set environment variables to point customers-dot to staging, and the AI Gateway to staging:

   ```shell
   export GITLAB_LICENSE_MODE=test
   export CUSTOMER_PORTAL_URL=https://customers.staging.gitlab.com
   export AI_GATEWAY_URL=https://cloud.staging.gitlab.com/ai
   ```

1. Restart the GDK.
1. Ensure you followed the necessary [steps to enable the Code Suggestions feature](../../user/project/repository/code_suggestions/self_managed.md).
1. Test out the Code Suggestions feature by opening the Web IDE for a project.
