---
stage: AI-powered
group: Editor Extensions
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Agent Skills
---

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- Support for workspace-level Agent Skills [added](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/merge_requests/2951) in GitLab 18.10.
  - [Introduced](https://gitlab.com/gitlab-org/gitlab-vscode-extension/-/releases/v6.71.4) in GitLab for VS Code 6.71.4.
  - [Introduced](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/releases/v8.73.0) in GitLab Duo CLI 8.73.0.

{{< /history >}}

GitLab Duo supports the [Agent Skills specification](https://agentskills.io/specification), an
emerging standard for giving agents new capabilities and expertise.

Use Agent Skills to give agents specialized knowledge and workflows for specific tasks, like writing
tests in a specific framework. Agents load the related skills automatically as they encounter tasks
and use the information as they work.

When you specify a `SKILL.md` file, the skills are available for GitLab Duo Agent Platform and any
other AI tool that supports the specification.

Specify Agent Skills for GitLab Duo to use with:

- GitLab Duo Chat in your local environment.
- Foundational and custom flows.

## How GitLab Duo uses Agent Skills

When an agent starts working, GitLab Duo adds metadata for all available skills to the agent's
context. When the agent encounters a task that matches a skill's description, it automatically loads
the skill and uses it to complete the task.

You can also manually direct GitLab Duo to use a skill by name, file path, or slash command.

## Use Agent Skills with GitLab Duo

> [!note]
> Existing conversations and flows do not have access to new or updated skills automatically.
> Start a new conversation, or ask GitLab Duo to load a skill by name or relative path.

### Prerequisites

- Meet the [Agent Platform prerequisites](../_index.md#prerequisites).
- For GitLab Duo Chat in your local environment, install and configure one of the following:
  - [GitLab for VS Code](../../../editor_extensions/visual_studio_code/setup.md) 6.71.4 or later.
  - [GitLab Duo CLI](../../gitlab_duo_cli/_index.md#set-up-the-gitlab-duo-cli) 8.73.0 or later.
- For custom flows, update the flow's configuration file to access the `workspace_agent_skills`
  context passed from the executor:

  ```yaml
  components:
  - name: "my_agent"
     type: AgentComponent
     prompt_id: "my_prompt"
     inputs:
     - from: "context:inputs.workspace_agent_skills"
        as: "workspace_agent_skills"
      optional: true
  ```

  By setting `optional: true`, the flow gracefully handles cases where no agent skills exist.
  The agent works with or without additional context.

### Create workspace-level skills

Workspace-level skills apply to a specific project or workspace. You define them in a `SKILL.md`
file in a `skills/<skill-name>/` directory of your project.

To create a workspace-level skill:

1. In the root of your project workspace, create a `skills` directory.
1. In the new directory, create another directory for the specific skill. Use the skill name as the
   directory name.
1. Create a `SKILL.md` file and include instructions using the following format.
   The `name` and `description` YAML front matter fields are required.

   ```markdown
   ---
   name: <skill_name>
   description: <skill_description>
   ---

   <your_instructions_and_context_for_the_skill>
   ```

    For example, a skill to [sign artifacts using cosign](../../../ci/yaml/signing_examples.md) in
    `skills/cosign-blob/SKILL.md`:

    ````markdown
    ---
    name: cosign-blob
    description: Sign artifacts using cosign with local keypairs and Sigstore v3 bundles. Integrate with 1Password for secure key management.
    ---

    ## Cosign Blob Signing

    Sign artifacts locally using cosign with Sigstore v3 bundles for artifact verification and integrity.

    ### Generate a Local Keypair

    Generate a new cosign keypair:

    ```shell
    cosign generate-key-pair
    ```

    This creates two files:
    - `cosign.key` - Private key (encrypted)
    - `cosign.pub` - Public key

    Store the private key securely, preferably in a password manager like 1Password.

    ### Store Private Key in 1Password

    1. Create a new login item in 1Password with:
      - Title: "Duo Skills cosign"
      - Username: (optional)
      - Password: Your cosign private key password

    2. Save the secret reference path (for example, `op://Employee/Duo Skills cosign/password`)

    ### Sign Artifacts with Cosign

    Sign a file and generate a Sigstore v3 bundle:

    ```shell
    COSIGN_PASSWORD=$(op read "op://Employee/Duo Skills cosign/password") \
      timeout -v 4 cosign sign-blob \
        --key ~/.gitlab/duo/cosign.key \
        --bundle <filename>.bundle \
        --new-bundle-format \
        --yes \
        <filename>
    ```

    Replace:
    - `<filename>` with the file to sign (for example, `SKILL.md`)
    - The bundle output will be saved as `<filename>.bundle`

    ### Key Points

    - Use timeout to fail-fast and report the error back to the user.
    - Use `--bundle` with `$file.bundle` format for Sigstore v3 bundles
    - Use `--yes` to skip interactive prompts
    - Use `--new-bundle-format` to output a v3 Sigstore bundle rather than the legacy format
    - Set `COSIGN_PASSWORD` environment variable to avoid password prompts
    - Integrate with 1Password CLI for secure credential management
    - The bundle file contains the signature and can be verified later
    ````

1. Save the file.
1. Start a new conversation or flow. You should do this every time you change or add a `SKILL.md`
   file to avoid context confusion for the agent.

#### Expose skills as slash commands

To enable a skill as a custom slash command, add `slash-command: enabled` to the metadata in the
YAML front matter of your `SKILL.md` file:

```yaml
---
name: <skill_name>
description: <skill_description>
metadata:
  slash-command: enabled
---
```

After you add the metadata, you can use `/<skill_name>` in new sessions to instruct GitLab Duo to use the
skill. For example, `/fix-bugs`.

### Use a skill manually

To direct GitLab Duo to use a specific skill, use one of the following methods:

- Instruct GitLab Duo to use the skill by name or file path in your prompt.
- Start your prompt with the slash command for the skill.

To list all available skills in the current session's context, use `/skills`.

## Related topics

- [Custom rules](custom_rules.md)
