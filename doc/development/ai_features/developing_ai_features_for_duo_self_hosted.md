---
stage: AI-powered
group: Custom Models
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
title: Developing AI Features for Duo Self-Hosted
---

This document outlines the process for developing AI features for GitLab Duo Self-Hosted. Developing AI features for GitLab Duo Self-Hosted is quite similar to developing AI features for Duo SaaS, but there are some differences.

## Gaining access to a hosted model

While GitLab Duo Self-Hosted supports a [wide range of models](../../administration/gitlab_duo_self_hosted/supported_models_and_hardware_requirements.md#supported-models), only the following models are currently available to GitLab team members for development purposes as of June, 2025:

- `Claude 3.5 Sonnet` on AWS Bedrock
- `Claude 3.5 Sonnet v2` on AWS Bedrock
- `Claude 3.7 Sonnet` on AWS Bedrock

To gain access to these models, create an [access request using the `aws_services_account_iam_update` template](https://gitlab.com/gitlab-com/gl-security/corp/issue-tracker/-/issues/new?description_template=aws_services_account_iam_update). See [this example access request](https://gitlab.com/gitlab-com/gl-security/corp/issue-tracker/-/issues/949) if you aren't sure what information to fill in.

Once your access request is approved, you can gain access to AWS credentials by visiting [https://gitlabsandbox.cloud/login](https://gitlabsandbox.cloud/login).

After logging into `gitlabsandbox.cloud`, perform the following steps:

1. Select the `cstm-mdls-dev-bedrock` AWS account.
1. On the top right corner of the page, select **View IAM Credentials**.
1. In the model that opens up, you should be able to see `AWS Console URL`, `Username` and `Password`. Visit this AWS Console URL and input the obtained username and password to sign in.

### Gaining access to models on AWS Bedrock

On AWS Bedrock, you must gain access to the models you want to use. To do this:

1. Visit the [AWS Model Catalog Console](https://us-east-1.console.aws.amazon.com/bedrock/home?region=us-east-1#/model-catalog).
1. Make sure your location is set to `us-east-1`.
1. From the list of models, find the model you want to use, and hover on the **Available to request** link. Then select **Request access**.
1. Complete the form to request access to the model.

Your access should be granted within a few minutes.

### Generating Access Key and Secret Key on AWS

To use AWS Bedrock models, you must generate access keys. To generate these access keys:

1. Visit the [IAM Console](https://us-east-1.console.aws.amazon.com/iam/home?region=us-east-1#/home).
1. Select the **Users** tab.
1. Select your username.
1. Select the **Security credentials** tab.
1. Select **Create access key**.
1. Select **Download .csv** to download the access keys.

Keep the access keys in a secure location. You will need them to configure the model.

Alternatively, to generate access keys on AWS, you can follow this [video on how to create access and secret keys in AWS](https://www.youtube.com/watch?v=d1e-2ToweXQ).

## Setting up your GDK environment

GitLab Duo Self-Hosted requires that your GDK environment runs on Self-Managed mode. It does not work in Multi-Tenant/SaaS mode.

To set up your GDK environment to run the GitLab Duo Self-Hosted, follow the steps in this [AI development documentation](_index.md#required-run-gitlabduosetup-script), under **GitLab Self-Managed / Dedicated mode**.

### Setting up Environment Variables

To use the hosted models, set the following environment variables on your AI gateway:

1. In the `GDK_ROOT/gitlab-ai-gateway/.env` file, set the following variables:

   ```plaintext
   AWS_ACCESS_KEY_ID=your-access-key-id
   AWS_SECRET_ACCESS_KEY=your-secret-access-key
   AWS_REGION=us-east-1
   AIGW_CUSTOM_MODELS__ENABLED=true
   # useful for debugging
   AIGW_LOGGING__ENABLE_REQUEST_LOGGING=true
   AIGW_LOGGING__ENABLE_LITELLM_LOGGING=true
   ```

1. In the `GDK_ROOT/env.runit` file, set the following variables:

   ```plaintext
   export GITLAB_SIMULATE_SAAS=0
   ```

1. Restart your GDK for the changes to take effect using `gdk restart`.

## Configuring the custom model in the UI

To enable the use of self-hosted models in the GitLab instance, follow these steps:

1. On your GDK instance, go to `/admin/gitlab_duo/configuration`.
1. Select the **Use beta models and features in GitLab Duo Self-Hosted** checkbox.
1. For **Local AI Gateway URL**, enter the URL of your AI gateway instance. In most cases, this will be `http://localhost:5052`.
1. Save the changes.

### Creating a new self-hosted model

Next, we need to configure a new model for use in the GitLab instance.

1. On your GDK instance, go to `/admin/ai/duo_self_hosted/new`.
1. For **Deployment name**, enter a name for the deployment for identification purposes. For example, `Claude 3.5 Sonnet on Bedrock`.
1. Under **Platform**, select **Amazon Bedrock**.
1. For **Model Family**, select **Claude 3*, as Claude 3.5 Sonnet falls under this family.
1. For **Model Identifier**, use the model name from the [AWS Model Catalog Console](https://us-east-1.console.aws.amazon.com/bedrock/home?region=us-east-1#/model-catalog?region=us-east-1), based on the model you want to use.

   | Model Name | Model Identifier |
   |------------|------------------|
   | Claude 3.5 Sonnet | `bedrock/us.anthropic.claude-3-5-sonnet-20240620-v1:0` |
   | Claude 3.5 Sonnet v2 | `bedrock/us.anthropic.claude-3-5-sonnet-20241022-v2:0` |
   | Claude 3.7 Sonnet | `bedrock/us.anthropic.claude-3-7-sonnet-20250219-v1:0` |

1. To save your changes, select **Create self-hosted model**.

- Save your changes by clicking on the `Create self-hosted model` button.

### Using the self-hosted model to power AI features

To use the created self-hosted model to power AI-native features:

1. On your GDK instance, go to `admin/ai/duo_self_hosted/features`.
1. For each AI feature you want to use with your self-hosted model (for example, Code Generation, Code Completion, General Chat, Explain Code, and so on), select your newly created self-hosted model (for example, **Claude 3.5 Sonnet on Bedrock**) from the corresponding dropdown list.
1. Optional. To copy the configuration to all features under a specific category, select the copy icon next to it.
1. After making your selections, the changes are usually saved automatically.

![GitLab Duo Self-Hosted Features Configuration](img/ai_features_page_v18_1.png)

With this, you have successfully configured the self-hosted model to power AI-native features in your GitLab instance. To test the feature using, for example, Chat, open Chat and say `Hello`. You should see the response powered by your self-hosted model in the chat.

## Moving a feature available in GitLab.com or GitLab Self-Managed to GitLab Duo Self-Hosted

To move a feature available in GitLab.com or GitLab Self-Managed to GitLab Duo Self-Hosted:

1. Make the feature configurable to use a self-hosted model.
1. Add prompts for the feature, for each model family you want to support.

### Making the feature configurable to use a self-hosted model

When a feature is available in GitLab.com or GitLab Self-Managed, it should be configurable to use a self-hosted model. To make the feature configurable to use a self-hosted model:

- Add the feature's name to `ee/app/models/ai/feature_setting.rb` as a stable feature or a beta/experimental feature.
- Add the feature's name to the `ee/lib/gitlab/ai/feature_settings/feature_metadata.yml` file, including the list of model families it supports.
- Add the unit primitive to `config/services/self_hosted_models.yml` in the [`gitlab-cloud-connector` repository](https://gitlab.com/gitlab-org/cloud-connector/gitlab-cloud-connector). This [merge request](https://gitlab.com/gitlab-org/cloud-connector/gitlab-cloud-connector/-/merge_requests/134) can be used as a reference.
- Associated spec changes based on the above changes.

Please refer to the following merge requests for reference:

- [Move Code Review Summary to Beta in Self-Hosted Duo](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/186662)
- [Move Vulnerability Explanation to Beta in Self-Hosted Duo](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/186500)

### Adding prompts for the feature

For each model family you want to support for the feature, you must add a prompt. Prompts are stored in the [AI Gateway repository](https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist).

In most cases, the prompt that is used on GitLab.com is also used for Self-Hosted Duo.

Please refer to the following Merge Requests for reference:

- [Add prompts for Code Review Summary](https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/-/merge_requests/2260)
- [Add prompts for Vulnerability Explanation](https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/-/merge_requests/2223)

Your feature should now be available in GitLab Duo Self-Hosted. Restart your GDK instance to apply the changes and test the feature.
