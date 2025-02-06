---
stage: AI-powered
group: Custom Models
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
title: Setting up local development
---

## Set up your local GitLab instance

1. [Configure GDK to set up Duo Features in the local environment](../ai_features/_index.md)

1. For AI gateway:

- Set `AIGW_CUSTOM_MODELS__ENABLED=True`
- Set `AIGW_AUTH__BYPASS_EXTERNAL=False` or `AIGW_GITLAB_URL=<your-gitlab-instance>`

1. Run `gitlab:duo:verify_self_hosted_setup` task to verify the setup

## Configure self-hosted models

1. Follow the [instructions](../../administration/gitlab_duo_self_hosted/configure_duo_features.md#configure-the-self-hosted-model) to configure self-hosted models
1. Follow the [instructions](../../administration/gitlab_duo_self_hosted/configure_duo_features.md#configure-gitlab-duo-features-to-use-self-hosted-models) to configure features to use the models

AI-powered features are now powered by self-hosted models.

## Configure features to use AI vendor models

After adding [support](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/164924) for configuring features to either use self-hosted models for AI Vendor, setting `CLOUD_CONNECTOR_SELF_SIGN_TOKENS` is no longer necessary for the customers. But it is harder for developers to configure the features to use AI vendored because we still want to send all requests to the local AI gateway instead of Cloud Connector.

Setting [`CLOUD_CONNECTOR_BASE_URL`](https://gitlab.com/gitlab-org/gitlab/-/blob/1452de8cde035bb5eba53ba2a2903c28fc237455/config/initializers/1_settings.rb#L1028) is not sufficient because we [add](https://gitlab.com/gitlab-org/gitlab/-/blob/1452de8cde035bb5eba53ba2a2903c28fc237455/ee/lib/gitlab/ai_gateway.rb#L14) `/ai` suffix to it.

Currently, there are the following workarounds:

1. Verify that `CLOUD_CONNECTOR_SELF_SIGN_TOKENS=1`
1. Remove `ai_feature_settings` record responsible to the configuration to fallback to using `AI_GATEWAY_URL` as Cloud Connector URL:

```ruby
Ai::FeatureSetting.find_by(feature: :duo_chat).destroy!
```

## Testing

To comprehensively test that a feature using Custom Models works as expected, you must write `system` specs.

This is required because, unlike `unit` tests, `system` specs invoke all the components involved in the custom models stack. For example, the Puma, Workhorse, AI gateway + LLM Mock server.

To write a new `system` test and for it to run successfully, there are the following prerequisites:

- AI gateway must be running (usually on port `5052`), and you must configure the environment variable `AI_GATEWAY_URL`:

  ```shell
  export AI_GATEWAY_URL="http://localhost:5052"
  ```

- We use [LiteLLM proxy](https://www.litellm.ai/) to return mock responses. You must configure LiteLLM to return mock responses using a configuration file:

  ```yaml
  # config.yaml
  model_list:
    - model_name: codestral
      litellm_params:
        model: ollama/codestral
        mock_response: "Mock response from codestral"
  ```

- LiteLLM proxy must be running (usually on port `4000`), and the you must configure the environment variable `LITELLM_PROXY_URL`:

  ```shell
  litellm --config config.yaml

  export LITELLM_PROXY_URL="http://localhost:4000"
  ```

- You must tag the RSpec file with `requires_custom_models_setup`.

For an example, see [`ee/spec/features/custom_models/code_suggestions_spec.rb`](https://gitlab.com/gitlab-org/gitlab/-/blob/244e37a201620f9d98503e186b60e4e572a05d6e/ee/spec/features/custom_models/code_suggestions_spec.rb). In this file, we test that the code completions feature uses a self-hosted `codestral` model.

### Testing On CI

On CI, AI gateway and LiteLLM proxy are already configured to run for all tests tagged with `requires_custom_models_setup`.

<!-- markdownlint-disable proper-names -->
<!-- vale gitlab_base.Substitutions = NO -->
However, you must also update the `config` for LiteLLM if you are testing features that use newer models in the specs that have not been used before.
The configuration for LiteLLM is in [`.gitlab/ci/global.gitlab-ci.yml`](https://gitlab.com/gitlab-org/gitlab/-/blob/2b14f212d48ca2c22904805600491baf8460427e/.gitlab/ci/global.gitlab-ci.yml#L332).
<!-- vale gitlab_base.Substitutions = YES -->
<!-- markdownlint-enable proper-names -->
