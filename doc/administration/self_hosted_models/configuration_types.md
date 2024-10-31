---
stage: AI-Powered
group: Custom Models
description: Get started with self-hosted AI models.
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Self-hosted model configuration and authentication

DETAILS:
**Tier:** Ultimate with GitLab Duo Enterprise - [Start a trial](https://about.gitlab.com/solutions/gitlab-duo-pro/sales/?type=free-trial)
**Offering:** Self-managed
**Status:** Beta

> - [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/12972) in GitLab 17.1 [with a flag](../../administration/feature_flags.md) named `ai_custom_model`. Disabled by default.
> - [Enabled on self-managed](https://gitlab.com/groups/gitlab-org/-/epics/15176) in GitLab 17.6.
> - Changed to require GitLab Duo add-on in GitLab 17.6 and later.

There are two configuration options for self-managed customers:

- **GitLab.com AI Gateway**: Use the GitLab-managed AI Gateway with default external
  large language model (LLM) providers (for example, Google Vertex or Anthropic).
- **Self-hosted AI Gateway**: Deploy and manage your own AI Gateway and language models in your infrastructure,
  without depending on GitLab-provided external language providers.

## GitLab.com AI Gateway

In this configuration, your GitLab instance depends on and sends requests to the external GitLab AI Gateway, which communicates with external AI vendors such as Google Vertex or Anthropic. The response is then forwarded back to your GitLab instance.

```mermaid
%%{init: { "theme": "default", "fontFamily": "GitLab Sans", "sequence": { "actorFontSize": 12, "participantFontSize": 12, "messageFontSize": 12 } }}%%
sequenceDiagram
    actor User as User
    participant SelfHostedGitLab as Self-hosted GitLab (Your Instance)
    participant GitLabAIGateway as GitLab AI Gateway (External)
    participant GitLabAIVendor as GitLab AI Vendor (External)

    User ->> SelfHostedGitLab: Send request
    SelfHostedGitLab ->> SelfHostedGitLab: Check if self-hosted model is configured
    SelfHostedGitLab ->> GitLabAIGateway: Forward request for AI processing
    GitLabAIGateway ->> GitLabAIVendor: Create prompt and send request to AI model server
    GitLabAIVendor -->> GitLabAIGateway: Respond to the prompt
    GitLabAIGateway -->> SelfHostedGitLab: Forward AI response
    SelfHostedGitLab -->> User: Forward AI response
```

## Self-hosted AI Gateway

In this configuration, the entire system is isolated within the enterprise, ensuring a fully self-hosted environment that safeguards data privacy.

```mermaid
%%{init: { "theme": "default", "fontFamily": "GitLab Sans", "sequence": { "actorFontSize": 12, "participantFontSize": 12, "messageFontSize": 12 } }}%%
sequenceDiagram
    actor User as User
    participant SelfHostedGitLab as Self-hosted GitLab
    participant SelfHostedAIGateway as Self-hosted AI Gateway
    participant SelfHostedModel as Self-hosted model

    User ->> SelfHostedGitLab: Send request
    SelfHostedGitLab ->> SelfHostedGitLab: Check if self-hosted model is configured
    SelfHostedAIGateway ->> SelfHostedModel: Create prompt and perform request to AI model server
    SelfHostedGitLab ->> SelfHostedAIGateway: Forward request for AI processing
    SelfHostedModel -->> SelfHostedAIGateway: Respond to the prompt
    SelfHostedAIGateway -->> SelfHostedGitLab: Forward AI response
    SelfHostedGitLab -->> User: Forward AI response
```

For more information, see the [self-hosted model deployment blueprint](https://handbook.gitlab.com/handbook/engineering/architecture/design-documents/custom_models/).

## Authentication for self-hosted models

The authentication process for self-hosted models is secure, efficient, and made up of the following key components:

- **Self-issued tokens**: In this architecture, access credentials are not synchronized with `cloud.gitlab.com`. Instead, tokens are self-issued dynamically, similar to the functionality on GitLab.com. This method provides users with immediate access while maintaining a high level of security.

- **Offline environments**: In offline setups, there are no connections to `cloud.gitlab.com`. All requests are routed exclusively to the self-hosted AI Gateway.

- **Token minting and verification**: The GitLab self-managed instance mints the token, which is then verified by the AI Gateway against the GitLab instance.

- **Model configuration and security**: When an administrator configures a model, they can incorporate an API key to authenticate requests. Additionally, you can enhance security by specifying connection IP addresses within your network, ensuring that only trusted IPs can interact with the model.

As illustrated in the following diagram:

1. The authentication flow begins when the user configures the model through the GitLab instance and submits a request to access the GitLab Duo feature.
1. The GitLab instance mints an access token, which the user forwards to GitLab and then to the AI Gateway for verification.
1. Upon confirming the token's validity, the AI Gateway sends a request to the AI model, which uses the API key to authenticate the request and process it.
1. The results are then relayed back to the GitLab instance, completing the flow by sending the response to the user, which is designed to be secure and efficient.

```mermaid
%%{init: { "theme": "default", "fontFamily": "GitLab Sans", "sequence": { "actorFontSize": 12, "participantFontSize": 12, "messageFontSize": 12 } }}%%
   sequenceDiagram
      participant User as User
      participant GitLab as GitLab Instance
      participant AI Gateway as AI Gateway
      participant AIModel as AI Model

      User->>GitLab: Configure Model
      User->>GitLab: Request Access
      GitLab->>GitLab: Mint Token
      GitLab->>User: Send Token
      User->>GitLab: Forward Minted Token
      GitLab->>AI Gateway: Verify Token
      AI Gateway->>GitLab: Token Validated
      GitLab->>AI Gateway: Send Request to Model
      AI Gateway->>AIModel: Send Request to Model
      AIModel->>AIModel: Authenticate using API Key
      AIModel->>AI Gateway: Process Request
      AI Gateway->>GitLab: Send Result to GitLab
      GitLab->>User: Send Response

```
