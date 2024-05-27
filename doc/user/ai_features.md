---
stage: AI-powered
group: AI Model Validation
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# GitLab Duo

> - [First GitLab Duo features introduced](https://about.gitlab.com/blog/2023/05/03/gitlab-ai-assisted-features/) in GitLab 16.0.
> - [Removed third-party AI setting](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/136144) in GitLab 16.6.
> - [Removed support for OpenAI from all GitLab Duo features](https://gitlab.com/groups/gitlab-org/-/epics/10964) in GitLab 16.6.

GitLab is creating AI-assisted features across our DevSecOps platform. These features aim to help increase velocity and solve key pain points across the software development lifecycle.

Some features are still in development. View details about [support for each status](../policy/experiment-beta-support.md#experiment) (Experiment, Beta, Generally Available).

 As features become Generally Available, GitLab is [transparent](https://handbook.gitlab.com/handbook/values/#transparency) and updates the documentation to clearly state how and where you can access these capabilities.

| Goal | Feature | Tier/Offering/Status |
|---|---|---|
| Helps you write code more efficiently by showing code suggestions as you type. <br><br><i class="fa fa-youtube-play youtube" aria-hidden="true"></i> [Watch overview](https://www.youtube.com/watch?v=hCAyCTacdAQ) | [Code Suggestions](project/repository/code_suggestions/index.md) | **Tier:** Premium or Ultimate with [GitLab Duo Pro](../subscriptions/subscription-add-ons.md) <br>**Offering:** GitLab.com, Self-managed, GitLab Dedicated |
| Processes and generates text and code in a conversational manner. Helps you quickly identify useful information in large volumes of text in issues, epics, code, and GitLab documentation. | [Chat](gitlab_duo_chat.md) | **Tier/Offering:** For GitLab.com and Self-managed: Premium, Ultimate. <br>For Dedicated: GitLab Duo Pro or Enterprise<br>**Status:** Beta (Subject to the [Testing Agreement](https://handbook.gitlab.com/handbook/legal/testing-agreement/)) |
| Helps you discover or recall Git commands when and where you need them. | [Git suggestions](../editor_extensions/gitlab_cli/index.md#gitlab-duo-commands) | **Tier:** Ultimate <br>**Offering:** GitLab.com <br>**Status:** Experiment |
| Assists with quickly getting everyone up to speed on lengthy conversations to help ensure you are all on the same page.  <br><br><i class="fa fa-youtube-play youtube" aria-hidden="true"></i> [Watch overview](https://www.youtube.com/watch?v=IcdxLfTIUgc) | [Discussion summary](#summarize-issue-discussions-with-discussion-summary) | **Tier:** Ultimate <br>**Offering:** GitLab.com <br>**Status:** Experiment |
| Generates issue descriptions. | [Issue description generation](#summarize-an-issue-with-issue-description-generation) | **Tier:** Ultimate<br>**Offering:** GitLab.com <br>**Status:** Experiment |
| Automates repetitive tasks and helps catch bugs early. | [Test generation](gitlab_duo_chat.md#write-tests-in-the-ide) | **Tier/Offering:** For GitLab.com and Self-managed: Premium, Ultimate. <br>For Dedicated: GitLab Duo Pro or Enterprise <br>**Status:** Beta |
| Generates a description for the merge request based on the contents of the template. | [Merge request template population](project/merge_requests/ai_in_merge_requests.md#fill-in-merge-request-templates) | **Tier:** Ultimate<br>**Offering:** GitLab.com <br>**Status:** Experiment |
| Assists in creating faster and higher-quality reviews by automatically suggesting reviewers for your merge request. <br><br><i class="fa fa-youtube-play youtube" aria-hidden="true"></i> [Watch overview](https://www.youtube.com/watch?v=ivwZQgh4Rxw) | [Suggested Reviewers](project/merge_requests/reviews/index.md#gitlab-duo-suggested-reviewers) | **Tier:** Ultimate <br>**Offering:** GitLab.com<br>**Status:** Generally Available  |
| Efficiently communicates the impact of your merge request changes. | [Merge request summary](project/merge_requests/ai_in_merge_requests.md#summarize-merge-request-changes) | **Tier:** Ultimate <br>**Offering:** GitLab.com <br>**Status:** Beta |
| Helps ease merge request handoff between authors and reviewers and help reviewers efficiently understand suggestions. | [Code review summary](project/merge_requests/ai_in_merge_requests.md#summarize-my-merge-request-review) | **Tier:** Ultimate <br>**Offering:** GitLab.com <br>**Status:** Experiment |
| Helps you remediate vulnerabilities more efficiently, boost your skills, and write more secure code. <br><br><i class="fa fa-youtube-play youtube" aria-hidden="true"></i> [Watch overview](https://www.youtube.com/watch?v=6sDf73QOav8) | [Vulnerability explanation](application_security/vulnerabilities/index.md#explaining-a-vulnerability) | **Tier:** Ultimate <br>**Offering:** GitLab.com <br>**Status:** Beta |
| Generates a merge request containing the changes required to mitigate a vulnerability. | [Vulnerability resolution](application_security/vulnerabilities/index.md#vulnerability-resolution) | **Tier:** Ultimate <br>**Offering:** GitLab.com <br>**Status:** Experiment |
| Helps you understand code by explaining it in English language. <br><br><i class="fa fa-youtube-play youtube" aria-hidden="true"></i> [Watch overview](https://www.youtube.com/watch?v=1izKaLmmaCA) | [Code explanation](#explain-code-in-the-web-ui-with-code-explanation) | **Tier:** Ultimate <br>**Offering:** GitLab.com <br>**Status:** Experiment |
| Assists you in determining the root cause for a pipeline failure and failed CI/CD build. | [Root cause analysis](#root-cause-analysis) | **Tier:** Ultimate <br>**Offering:** GitLab.com <br>**Status:** Experiment |
| Assists you with predicting productivity metrics and identifying anomalies across your software development lifecycle. | [Value stream forecasting](#forecast-deployment-frequency-with-value-stream-forecasting) | **Tier/Offering:** For GitLab.com and Self-managed: Ultimate. <br>For Dedicated: GitLab Duo Enterprise <br>**Status:** Experiment |

## Controlling GitLab Duo features

There are two different levels at which GitLab Duo features can be controlled. The user level and the content level.

GitLab Duo features that are generally available are always enabled for all users that have access to these features. Whether they have access depends on the tier or the add-on as stated in the previous table. [Experimental](../policy/experiment-beta-support.md#experiment) and [Beta](../policy/experiment-beta-support.md#beta) GitLab Duo features need to be enabled as follows.

Owners of projects and groups as well as administrators of self-managed instances can control if GitLab Duo features can be used with their content such as code files.

### Giving access to users

If a feature is dependent on an add-on seat such as [Code Suggestions](project/repository/code_suggestions/index.md), access to the feature can be controlled through [GitLab Duo seat assignment](../subscriptions/subscription-add-ons.md#assign-gitlab-duo-pro-seats).

### Enabling Beta and Experimental AI-powered features

Features listed as Experiment and Beta are disabled by default. These features are subject to the [Testing Agreement](https://handbook.gitlab.com/handbook/legal/testing-agreement/).

#### GitLab.com

Prerequisites

- You must have the Owner role in the top-level group.

To enable Beta and Experimental AI-powered features, use the [Experiment and Beta features checkbox](group/manage.md#enable-experiment-and-beta-features).

#### GitLab self-managed

To enable Beta and Experimental AI-powered features for GitLab versions where GitLab Duo Chat is not yet generally available, see the [GitLab Duo Chat documentation](gitlab_duo_chat.md#for-self-managed-and-gitlab-dedicated).

### Enable outbound connections to enable GitLab Duo features on Self-managed instances

- Your firewalls and HTTP/S proxy servers must allow outbound connections
  to `gitlab.com` and `cloud.gitlab.com` on port `443`.
- Both `HTTP2` and the `'upgrade'` header must be allowed, because GitLab Duo
  uses both REST and WebSockets.
- To use an HTTP/S proxy, both `gitLab_workhorse` and `gitLab_rails` must have the necessary
  [web proxy environment variables](https://docs.gitlab.com/omnibus/settings/environment-variables.html) set.
- Check for restrictions on WebSocket (`wss://`) traffic to `wss://gitlab.com/-/cable` and other `.com` domains.
  Network policy restrictions on `wss://` traffic can cause issues with some GitLab Duo Chat
  services. Consider policy updates to allow these services.

### Disable GitLab Duo features for specific groups or projects or an entire instance

> - [Settings to disable AI features introduced](https://gitlab.com/groups/gitlab-org/-/epics/12404) in GitLab 16.10.

You can disable GitLab Duo AI features for a group, project, or instance.
When it's disabled, any attempt to use GitLab Duo features on the group, project, or instance is blocked and an error is displayed.
GitLab Duo features are also blocked for resources in the group or project, like epics,
issues, and vulnerabilities.

#### For the group or project

Prerequisites:

- You must have the Owner role for the group or project.

To disable GitLab Duo:

1. Use the [GitLab GraphQL API](../api/graphql/getting_started.md)
   `groupUpdate` or `projectSettingsUpdate` mutation.
1. Disable GitLab Duo for the project or group by setting the `duo_features_enabled` setting to `false`.
   (The default is `true`.)
1. Optional. To make all groups or projects in the hierarchy inherit the value for a top-level group,
   set `lock_duo_features_enabled` to `true`. (The default is `false`.)
   The child groups and projects cannot override this value.

#### For an instance

Prerequisites:

- You must be an administrator.

To disable GitLab Duo:

1. Use the [application settings API](../api/settings.md).
1. Disable GitLab Duo for the instance by setting the `duo_features_enabled` setting to `false`.
   (The default is `true`.)
1. Optional. To ensure this setting cannot be overridden at the group or project level,
   set `lock_duo_features_enabled` to `true`. (The default is `false`.)
   The child groups and projects cannot override this value.

#### Future plans

- An [issue exists](https://gitlab.com/gitlab-org/gitlab/-/issues/441489) for making this setting
  available in the UI.
- An [issue exists](https://gitlab.com/gitlab-org/gitlab/-/issues/448709) for making the setting
  cascade to all groups and projects. Right now the projects and groups do not
  display the setting of the top-level group. To ensure the setting cascades,
  ensure `lock_duo_features_enabled` is set to `true`.

## Experimental AI features and how to use them

The following subsections describe the experimental AI features in more detail.

### Explain code in the Web UI with Code explanation

DETAILS:
**Tier:** Ultimate
**Offering:** GitLab.com
**Status:** Experiment

> - Introduced in GitLab 15.11 as an [Experiment](../policy/experiment-beta-support.md#experiment) on GitLab.com.

To use this feature:

- The parent group of the project must:
  - Enable the [experiment and beta features setting](group/manage.md#enable-experiment-and-beta-features).
- You must:
  - Belong to at least one group with the [experiment and beta features setting](group/manage.md#enable-experiment-and-beta-features) enabled.
  - Have sufficient permissions to view the project.

GitLab can help you get up to speed faster if you:

- Spend a lot of time trying to understand pieces of code that others have created, or
- Struggle to understand code written in a language that you are not familiar with.

By using a large language model, GitLab can explain the code in natural language.

To explain your code:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select any file in your project that contains code.
1. On the file, select the lines that you want to have explained.
1. On the left side, select the question mark (**{question}**). You might have to scroll to the first line of your selection to view it. This sends the selected code, together with a prompt, to provide an explanation to the large language model.
1. A drawer is displayed on the right side of the page. Wait a moment for the explanation to be generated.
1. Provide feedback about how satisfied you are with the explanation, so we can improve the results.

You can also have code explained in the context of a merge request. To explain
code in a merge request:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Code > Merge requests**, then select your merge request.
1. On the secondary menu, select **Changes**.
1. On the file you would like explained, select the three dots (**{ellipsis_v}**) and select **View File @ $SHA**.

   A separate browser tab opens and shows the full file with the latest changes.

1. On the new tab, select the lines that you want to have explained.
1. On the left side, select the question mark (**{question}**). You might have to scroll to the first line of your selection to view it. This sends the selected code, together with a prompt, to provide an explanation to the large language model.
1. A drawer is displayed on the right side of the page. Wait a moment for the explanation to be generated.
1. Provide feedback about how satisfied you are with the explanation, so we can improve the results.

![How to use the Explain Code Experiment](img/explain_code_experiment.png)

We cannot guarantee that the large language model produces results that are correct. Use the explanation with caution.

### Summarize issue discussions with Discussion summary

DETAILS:
**Tier:** Ultimate
**Offering:** GitLab.com
**Status:** Experiment

> - [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/10344) in GitLab 16.0 as an [Experiment](../policy/experiment-beta-support.md#experiment).

To use this feature:

- The parent group of the issue must:
  - Enable the [experiment and beta features setting](group/manage.md#enable-experiment-and-beta-features).
- You must:
  - Belong to at least one group with the [experiment and beta features setting](group/manage.md#enable-experiment-and-beta-features) enabled.
  - Have sufficient permissions to view the issue.

You can generate a summary of discussions on an issue:

1. In an issue, scroll to the **Activity** section.
1. Select **View summary**.

The comments in the issue are summarized in as many as 10 list items.
The summary is displayed only for you.

Provide feedback on this experimental feature in [issue 407779](https://gitlab.com/gitlab-org/gitlab/-/issues/407779).

**Data usage**: When you use this feature, the text of all comments on the issue are sent to the large
language model referenced above.

### Forecast deployment frequency with Value stream forecasting

DETAILS:
**Tier:** Freely available for Ultimate for a limited time for self-managed and GitLab.com. In the future, will require [GitLab Duo Enterprise](../subscriptions/subscription-add-ons.md). For GitLab Dedicated, you must have GitLab Duo Enterprise.
**Offering:** GitLab.com, Self-managed, GitLab Dedicated
**Status:** Experiment

> - [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/10228) in GitLab 16.2 as an [Experiment](../policy/experiment-beta-support.md#experiment).

To use this feature:

- The parent group of the project must:
  - Enable the [experiment and beta features setting](group/manage.md#enable-experiment-and-beta-features).
- You must:
  - Belong to at least one group with the [experiment and beta features setting](group/manage.md#enable-experiment-and-beta-features) enabled.
  - Have sufficient permissions to view the CI/CD analytics.

In CI/CD Analytics, you can view a forecast of deployment frequency:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Analyze > CI/CD analytics**.
1. Select the **Deployment frequency** tab.
1. Turn on the **Show forecast** toggle.
1. On the confirmation dialog, select **Accept testing terms**.

The forecast is displayed as a dotted line on the chart. Data is forecasted for a duration that is half of the selected date range.
For example, if you select a 30-day range, a forecast for the following 15 days is displayed.

![Forecast deployment frequency](img/forecast_deployment_frequency.png)

Provide feedback on this experimental feature in [issue 416833](https://gitlab.com/gitlab-org/gitlab/-/issues/416833).

### Root cause analysis

DETAILS:
**Tier:** Ultimate
**Offering:** GitLab.com
**Status:** Experiment

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/123692) in GitLab 16.2 as an [Experiment](../policy/experiment-beta-support.md#experiment).

To use this feature:

- The parent group of the project must:
  - Enable the [experiment and beta features setting](group/manage.md#enable-experiment-and-beta-features).
- You must:
  - Belong to at least one group with the [experiment and beta features setting](group/manage.md#enable-experiment-and-beta-features) enabled.
  - Have sufficient permissions to view the CI/CD job.

When the feature is available, the "Root cause analysis" button will appears on
a failed CI/CD job. Selecting this button generates an analysis regarding the
reason for the failure.

### Summarize an issue with Issue description generation

DETAILS:
**Tier:** Ultimate
**Offering:** GitLab.com
**Status:** Experiment

> - [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/10762) in GitLab 16.3 as an [Experiment](../policy/experiment-beta-support.md#experiment).

To use this feature:

- The parent group of the project must:
  - Enable the [experiment and beta features setting](group/manage.md#enable-experiment-and-beta-features).
- You must:
  - Belong to at least one group with the [experiment and beta features setting](group/manage.md#enable-experiment-and-beta-features) enabled.
  - Have sufficient permissions to view the issue.

You can generate the description for an issue from a short summary.

1. Create a new issue.
1. Above the **Description** field, select **AI actions > Generate issue description**.
1. Write a short description and select **Submit**.

The issue description is replaced with AI-generated text.

Provide feedback on this experimental feature in [issue 409844](https://gitlab.com/gitlab-org/gitlab/-/issues/409844).

**Data usage**: When you use this feature, the text you enter is sent to the large
language model referenced above.

## Language models

| Feature | Large Language Model |
|---|---|
| [Git suggestions](https://gitlab.com/gitlab-org/gitlab/-/issues/409636) | Vertex AI Codey [`codechat-bison`](https://cloud.google.com/vertex-ai/generative-ai/docs/model-reference/code-chat) |
| [Discussion summary](#summarize-issue-discussions-with-discussion-summary) |Anthropic [`Claude-2`](https://docs.anthropic.com/claude/reference/selecting-a-model) |
| [Issue description generation](#summarize-an-issue-with-issue-description-generation) | Anthropic [`Claude-2`](https://docs.anthropic.com/claude/reference/selecting-a-model) |
| [Code Suggestions](project/repository/code_suggestions/index.md) | For Code Completion: Vertex AI Codey [`code-gecko`](https://cloud.google.com/vertex-ai/generative-ai/docs/model-reference/code-completion)    For Code Generation: Anthropic [`Claude-2`](https://docs.anthropic.com/claude/reference/selecting-a-model) |
| [Test generation](gitlab_duo_chat.md#write-tests-in-the-ide) | Anthropic [`Claude-2`](https://docs.anthropic.com/claude/reference/selecting-a-model) |
| [Merge request template population](project/merge_requests/ai_in_merge_requests.md#fill-in-merge-request-templates) | Vertex AI Codey [`text-bison`](https://cloud.google.com/vertex-ai/generative-ai/docs/model-reference/text) |
| [Suggested Reviewers](project/merge_requests/reviews/index.md#gitlab-duo-suggested-reviewers) | GitLab creates a machine learning model for each project, which is used to generate reviewers    [View the issue](https://gitlab.com/gitlab-org/modelops/applied-ml/applied-ml-updates/-/issues/10) |
| [Merge request summary](project/merge_requests/ai_in_merge_requests.md#summarize-merge-request-changes) | Vertex AI Codey [`text-bison`](https://cloud.google.com/vertex-ai/generative-ai/docs/model-reference/text) |
| [Code review summary](project/merge_requests/ai_in_merge_requests.md#summarize-my-merge-request-review) | Vertex AI Codey [`text-bison`](https://cloud.google.com/vertex-ai/generative-ai/docs/model-reference/text) |
| [Vulnerability explanation](application_security/vulnerabilities/index.md#explaining-a-vulnerability) | Vertex AI Codey [`text-bison`](https://cloud.google.com/vertex-ai/generative-ai/docs/model-reference/text)    Anthropic [`Claude-2`](https://docs.anthropic.com/claude/reference/selecting-a-model) if degraded performance |
| [Vulnerability resolution](application_security/vulnerabilities/index.md#explaining-a-vulnerability) | Vertex AI Codey [`code-bison`](https://cloud.google.com/vertex-ai/generative-ai/docs/model-reference/code-generation) |
| [Code explanation](#explain-code-in-the-web-ui-with-code-explanation) | Vertex AI Codey [`codechat-bison`](https://cloud.google.com/vertex-ai/generative-ai/docs/model-reference/code-chat) |
| [GitLab Duo Chat](gitlab_duo_chat.md) | Anthropic [`Claude-2`](https://docs.anthropic.com/claude/reference/selecting-a-model)    Vertex AI Codey [`textembedding-gecko`](https://cloud.google.com/vertex-ai/generative-ai/docs/embeddings/get-text-embeddings) |
| [Root cause analysis](#root-cause-analysis) | Vertex AI Codey [`text-bison`](https://cloud.google.com/vertex-ai/generative-ai/docs/model-reference/text) |
| [Value stream forecasting](#forecast-deployment-frequency-with-value-stream-forecasting) | Statistical forecasting |

## Data usage

GitLab AI features leverage generative AI to help increase velocity and aim to help make you more productive. Each feature operates independently of other features and is not required for other features to function. GitLab selects the best-in-class large-language models for specific tasks. We use [Google Vertex AI Models](https://cloud.google.com/vertex-ai/generative-ai/docs/learn/overview#genai-models) and [Anthropic Claude](https://www.anthropic.com/product).

### Progressive enhancement

These features are designed as a progressive enhancement to existing GitLab features across our DevSecOps platform. They are designed to fail gracefully and should not prevent the core functionality of the underlying feature. You should note each feature is subject to its expected functionality as defined by the relevant [feature support policy](../policy/experiment-beta-support.md).

### Stability and performance

These features are in a variety of [feature support levels](../policy/experiment-beta-support.md#beta). Due to the nature of these features, there may be high demand for usage which may cause degraded performance or unexpected downtime of the feature. We have built these features to gracefully degrade and have controls in place to allow us to mitigate abuse or misuse. GitLab may disable **beta and experimental** features for any or all customers at any time at our discretion.

### Data privacy

GitLab Duo AI features are powered by a generative AI models. The processing of any personal data is in accordance with our [Privacy Statement](https://about.gitlab.com/privacy/). You may also visit the [Sub-Processors page](https://about.gitlab.com/privacy/subprocessors/#third-party-sub-processors) to see the list of our Sub-Processors that we use to provide these features.

### Data retention

The below reflects the current retention periods of GitLab AI model [Sub-Processors](https://about.gitlab.com/privacy/subprocessors/#third-party-sub-processors):

- Anthropic discards model input and output data immediately after the output is provided. Anthropic currently does not store data for abuse monitoring. Model input and output is not used to train models.
- Google discards model input and output data immediately after the output is provided. Google currently does not store data for abuse monitoring. Model input and output is not used to train models.

All of these AI providers are under data protection agreements with GitLab that prohibit the use of Customer Content for their own purposes, except to perform their independent legal obligations.

GitLab retains input and output for up to 30 days for the purpose of troubleshooting, debugging, and addressing latency issues.

### Telemetry

GitLab Duo collects aggregated or de-identified first-party usage data through our [Snowplow collector](https://handbook.gitlab.com/handbook/business-technology/data-team/platform/snowplow/). This usage data includes the following metrics:

- Number of unique users
- Number of unique instances
- Prompt lengths
- Model used
- Status code responses
- API responses times

### Training data

GitLab does not train generative AI models based on private (non-public) data. The vendors we work with also do not train models based on private data.

For more information on our AI [sub-processors](https://about.gitlab.com/privacy/subprocessors/#third-party-sub-processors), see:

- Google Vertex AI Models APIs [data governance](https://cloud.google.com/vertex-ai/generative-ai/docs/data-governance) and [responsible AI](https://cloud.google.com/vertex-ai/generative-ai/docs/learn/responsible-ai).
- Anthropic Claude's [constitution](https://www.anthropic.com/news/claudes-constitution).

### Model accuracy and quality

Generative AI may produce unexpected results that may be:

- Low-quality
- Incoherent
- Incomplete
- Produce failed pipelines
- Insecure code
- Offensive or insensitive
- Out of date information

GitLab is actively iterating on all our AI-assisted capabilities to improve the quality of the generated content. We improve the quality through prompt engineering, evaluating new AI/ML models to power these features, and through novel heuristics built into these features directly.
