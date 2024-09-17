---
stage: AI-powered
group: Custom Models
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
---

# Setting up local development

## Set up your local GitLab instance

1. [Configure GDK to set up Duo Features in the local environment](../ai_features/index.md)
1. For GitLab Rails, enable `ai_custom_model` feature flag:

   ```ruby
   Feature.enable(:ai_custom_model)
   ```

1. For AI Gateway:

- Set `AIGW_CUSTOM_MODELS__ENABLED=True`
- Set `AIGW_AUTH__BYPASS_EXTERNAL=False` or `AIGW_GITLAB_URL=<your-gitlab-instance>`

1. Run `gitlab:duo:verify_self_hosted_setup` task to verify the setup

## Configure self-hosted models

1. Follow the [instructions](../../administration/self_hosted_models/configure_duo_features.md#configure-the-self-hosted-model) to configure self-hosted models
1. Follow the [instructions](../../administration/self_hosted_models/configure_duo_features.md#configure-the-features-to-your-models) to configure features to use the models

AI-powered features are now powered by self-hosted models.

## Configure features to use AI vendor models

After adding [support](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/164924) for configuring features to either use self-hosted models for AI Vendor, setting `CLOUD_CONNECTOR_SELF_SIGN_TOKENS` is no longer necessary for the customers. But it is harder for developers to configure the features to use AI vendored because we still want to send all requests to the local AI Gateway instead of Cloud Connector.

Setting [`CLOUD_CONNECTOR_BASE_URL`](https://gitlab.com/gitlab-org/gitlab/-/blob/1452de8cde035bb5eba53ba2a2903c28fc237455/config/initializers/1_settings.rb#L1028) is not sufficient because we [add](https://gitlab.com/gitlab-org/gitlab/-/blob/1452de8cde035bb5eba53ba2a2903c28fc237455/ee/lib/gitlab/ai_gateway.rb#L14) `/ai` suffix to it.

Currently, there are the following workarounds:

1. Verify that `CLOUD_CONNECTOR_SELF_SIGN_TOKENS=1`
1. Remove `ai_feature_settings` record responsible to the configuration to fallback to using `AI_GATEWAY_URL` as Cloud Connector URL:

```ruby
Ai::FeatureSetting.find_by(feature: :duo_chat).destroy!
```
