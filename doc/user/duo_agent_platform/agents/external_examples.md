---
stage: Agent Foundations
group: AI Catalog
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: External agent configuration examples
---

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- Introduced in GitLab 18.3 [with a feature flag](../../../administration/feature_flags/_index.md) named `ai_flow_triggers`. Enabled by default.
- [Enabled on GitLab Self-Managed and GitLab Dedicated](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/218840) in GitLab 18.8.

{{< /history >}}

Use the following examples to create your external agent configuration.
These examples contain the following variables:

- `AI_FLOW_CONTEXT`: the JSON-serialized parent object, including:
  - In merge requests, the diff and comments (up to a limit)
  - In issues or epics, the comments (up to a limit)
- `$AI_FLOW_EVENT`: the type of trigger event (for example, `mention`)
- `$AI_FLOW_INPUT`: the prompt the user enters as a comment in the merge request, issue, or epic

## Integrated with GitLab

The following agents are integrated with GitLab and available on GitLab.com.

### Claude Code

```yaml
injectGatewayToken: true
image: node:22-slim
commands:
  - echo "Installing claude"
  - npm install -g @anthropic-ai/claude-code
  - echo "Installing glab"
  - apt-get update --quiet && apt-get install --yes curl wget gpg git && rm --recursive --force /var/lib/apt/lists/*
  - |
    if command -v glab > /dev/null 2>&1; then echo "glab already present, skipping installation"; else ( set -o pipefail && echo "Installing glab@1.111.0..." && GLAB_OS=$(uname -s | tr '[:upper:]' '[:lower:]') && GLAB_ARCH=$(uname -m) && case "$GLAB_ARCH" in x86_64) GLAB_ARCH=amd64 ;; aarch64|arm64) GLAB_ARCH=arm64 ;; *) echo "Unsupported architecture: $GLAB_ARCH" >&2; exit 1 ;; esac && mkdir -p /tmp/bin /tmp/glab && curl --silent --show-error --fail --location --output /tmp/glab/glab.tar.gz "https://gitlab.com/gitlab-org/cli/-/releases/v1.111.0/downloads/glab_1.111.0_${GLAB_OS}_${GLAB_ARCH}.tar.gz" && case "${GLAB_OS}_${GLAB_ARCH}" in darwin_amd64) GLAB_SHA256=bf97aee449ae37e31e0ce9c052dd42840487317fa6159a42bce633ebda4f7333 ;; darwin_arm64) GLAB_SHA256=5cef8943f7aa73dcd619928d13ece8465a07962f1b036d74eef4f3d258d5cec3 ;; linux_amd64) GLAB_SHA256=d3aa186428ce6668455e2e35184c6f60b013840d759c7ea4cf02bac68d2a1827 ;; linux_arm64) GLAB_SHA256=13737967bf713574ac6c9b7316a8878c9a5920e1c1c3ccdc99772eafd274020a ;; *) echo "No vetted glab checksum for ${GLAB_OS}_${GLAB_ARCH}" >&2; exit 1 ;; esac && echo "$GLAB_SHA256 */tmp/glab/glab.tar.gz" | sha256sum --check --quiet && tar --extract --gzip --file /tmp/glab/glab.tar.gz --directory /tmp/glab && mv /tmp/glab/bin/glab /tmp/bin/ ) || echo "Warning: glab installation failed; continuing without glab" >&2; fi
  - export PATH="/tmp/bin:$PATH"
  - mkdir -p ~/.config/glab-cli
  - |
    cat > ~/.config/glab-cli/config.yml <<EOF
    hosts:
      $AI_FLOW_GITLAB_HOSTNAME:
        token: $AI_FLOW_GITLAB_TOKEN
        is_oauth2: "true"
        client_id: "bypass"
        oauth2_refresh_token: ""
        oauth2_expiry_date: "01 Jan 50 00:00 UTC"
        api_host: $AI_FLOW_GITLAB_HOSTNAME
        user: ClaudeCode
    check_update: "false"
    git_protocol: https
    EOF
  - chmod 600 ~/.config/glab-cli/config.yml
  - echo "Configuring git"
  - git config --global user.email "claudecode@gitlab.com"
  - git config --global user.name "Claude Code"
  - echo "Setting up git remote with authentication"
  - git remote set-url origin https://gitlab-ci-token:$AI_FLOW_GITLAB_TOKEN@$AI_FLOW_GITLAB_HOSTNAME/$AI_FLOW_PROJECT_PATH.git
  - export ANTHROPIC_AUTH_TOKEN=$AI_FLOW_AI_GATEWAY_TOKEN
  - export ANTHROPIC_CUSTOM_HEADERS=$AI_FLOW_AI_GATEWAY_HEADERS
  - export ANTHROPIC_BASE_URL="https://cloud.gitlab.com/ai/v1/proxy/anthropic"
  - echo "Running claude"
  - |
    claude --allowedTools="Bash(glab:*),Bash(git:*)" --permission-mode acceptEdits --verbose --output-format stream-json -p "
    You are an AI assistant helping with GitLab operations.

    Context: $AI_FLOW_CONTEXT
    Task: $AI_FLOW_INPUT
    Event: $AI_FLOW_EVENT

    Please execute the requested task using the available GitLab tools.
    Be thorough in your analysis and provide clear explanations.

    <important>
    Use the glab CLI to access data from GitLab. The glab CLI has already been authenticated. You can run the corresponding commands.

    When you complete your work create a new Git branch, if you aren't already working on a feature branch, with the format of 'feature/<short description of feature>' and check in/push code.

    Lastly, after pushing the code, if a merge request doesn't already exist, create a new merge request for the branch and link it to the issue using:
    glab mr create --title '<title>' --description '<desc>' --source-branch '<branch>'

    If you are asked to summarize a merge request or issue, or asked to provide more information then please post back a note to the merge request / issue so that the user can see it.

    $ADDITIONAL_INSTRUCTIONS
    </important>
    "
variables:
  - ADDITIONAL_INSTRUCTIONS
```

### OpenAI Codex

```yaml
image: node:22-slim
injectGatewayToken: true
commands:
  - echo "Installing codex"
  - npm install --global @openai/codex
  - echo "Installing glab"
  - export OPENAI_API_KEY=$AI_FLOW_AI_GATEWAY_TOKEN
  - apt-get update --quiet && apt-get install --yes curl wget gpg git && rm --recursive --force /var/lib/apt/lists/*
  - |
    if command -v glab > /dev/null 2>&1; then echo "glab already present, skipping installation"; else ( set -o pipefail && echo "Installing glab@1.111.0..." && GLAB_OS=$(uname -s | tr '[:upper:]' '[:lower:]') && GLAB_ARCH=$(uname -m) && case "$GLAB_ARCH" in x86_64) GLAB_ARCH=amd64 ;; aarch64|arm64) GLAB_ARCH=arm64 ;; *) echo "Unsupported architecture: $GLAB_ARCH" >&2; exit 1 ;; esac && mkdir -p /tmp/bin /tmp/glab && curl --silent --show-error --fail --location --output /tmp/glab/glab.tar.gz "https://gitlab.com/gitlab-org/cli/-/releases/v1.111.0/downloads/glab_1.111.0_${GLAB_OS}_${GLAB_ARCH}.tar.gz" && case "${GLAB_OS}_${GLAB_ARCH}" in darwin_amd64) GLAB_SHA256=bf97aee449ae37e31e0ce9c052dd42840487317fa6159a42bce633ebda4f7333 ;; darwin_arm64) GLAB_SHA256=5cef8943f7aa73dcd619928d13ece8465a07962f1b036d74eef4f3d258d5cec3 ;; linux_amd64) GLAB_SHA256=d3aa186428ce6668455e2e35184c6f60b013840d759c7ea4cf02bac68d2a1827 ;; linux_arm64) GLAB_SHA256=13737967bf713574ac6c9b7316a8878c9a5920e1c1c3ccdc99772eafd274020a ;; *) echo "No vetted glab checksum for ${GLAB_OS}_${GLAB_ARCH}" >&2; exit 1 ;; esac && echo "$GLAB_SHA256 */tmp/glab/glab.tar.gz" | sha256sum --check --quiet && tar --extract --gzip --file /tmp/glab/glab.tar.gz --directory /tmp/glab && mv /tmp/glab/bin/glab /tmp/bin/ ) || echo "Warning: glab installation failed; continuing without glab" >&2; fi
  - export PATH="/tmp/bin:$PATH"
  - mkdir -p ~/.config/glab-cli
  - |
    cat > ~/.config/glab-cli/config.yml <<EOF
    hosts:
      $AI_FLOW_GITLAB_HOSTNAME:
        token: $AI_FLOW_GITLAB_TOKEN
        is_oauth2: "true"
        client_id: "bypass"
        oauth2_refresh_token: ""
        oauth2_expiry_date: "01 Jan 50 00:00 UTC"
        api_host: $AI_FLOW_GITLAB_HOSTNAME
        user: OpenAICodex
    check_update: "false"
    git_protocol: https
    EOF
  - chmod 600 ~/.config/glab-cli/config.yml
  - echo "Configuring git"
  - git config --global user.email "codex@gitlab.com"
  - git config --global user.name "OpenAI Codex"
  - echo "Setting up git remote with authentication"
  - git remote set-url origin https://gitlab-ci-token:$AI_FLOW_GITLAB_TOKEN@$AI_FLOW_GITLAB_HOSTNAME/$AI_FLOW_PROJECT_PATH.git
  - echo "Running Codex"
  - |
    # Parse AI_FLOW_AI_GATEWAY_HEADERS (newline-separated "Key: Value" pairs)
    header_str="{"
    first=true
    while IFS= read -r line; do
      # skip empty lines
      [ -z "$line" ] && continue
      key="${line%%:*}"
      value="${line#*: }"
      if [ "$first" = true ]; then
        first=false
      else
        header_str+=", "
      fi
      header_str+="'$key' = '$value'"
    done <<< "$AI_FLOW_AI_GATEWAY_HEADERS"
    header_str+="}"

    echo "Headers: $header_str"

    codex exec \
      --config 'model="gpt-5.3-codex"' \
      --config 'model_provider="gitlab"' \
      --config 'model_providers.gitlab.name="GitLab Managed Codex"' \
      --config 'model_providers.gitlab.base_url="https://cloud.gitlab.com/ai/v1/proxy/openai/v1"' \
      --config 'model_providers.gitlab.env_key="OPENAI_API_KEY"' \
      --config 'model_providers.gitlab.wire_api="responses"' \
      --config "model_providers.gitlab.http_headers=${header_str}" \
      --config shell_environment_policy.ignore_default_excludes=true \
      --dangerously-bypass-approvals-and-sandbox "
    You are an AI assistant helping with GitLab operations.

    Context: $AI_FLOW_CONTEXT
    Task: $AI_FLOW_INPUT
    Event: $AI_FLOW_EVENT

    Please execute the requested task using the available GitLab tools.
    Be thorough in your analysis and provide clear explanations.

    <important>
    Use the glab CLI to access data from GitLab. The glab CLI has already been authenticated. You can run the corresponding commands.

    When you complete your work create a new Git branch, if you aren't already working on a feature branch, with the format of 'feature/<short description of feature>' and check in/push code.

    Lastly, after pushing the code, if a merge request doesn't already exist, create a new merge request for the branch and link it to the issue using:
    glab mr create --title '<title>' --description '<desc>' --source-branch '<branch>'

    If you are asked to summarize a merge request or issue, or asked to provide more information then please post back a note to the merge request / issue so that the user can see it.

    $ADDITIONAL_INSTRUCTIONS
    </important>
    "
variables:
  - ADDITIONAL_INSTRUCTIONS
```
