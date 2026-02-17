---
stage: Security Risk Management
group: Security Insights
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Explain vulnerabilities with AI
---

{{< details >}}

- Tier: Ultimate
- Add-on: GitLab Duo Enterprise, GitLab Duo with Amazon Q
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< collapsible title="Model information" >}}

- [Default LLM](../../gitlab_duo/model_selection.md#default-models)
- LLM for Amazon Q: Amazon Q Developer
- Available on [GitLab Duo with self-hosted models](../../../administration/gitlab_duo_self_hosted/_index.md)

{{< /collapsible >}}

{{< history >}}

- [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/10368) in GitLab 16.0 as an [experiment](../../../policy/development_stages_support.md#experiment) on GitLab.com.
- Promoted to [beta](../../../policy/development_stages_support.md#beta) status in GitLab 16.2.
- [Generally available](https://gitlab.com/groups/gitlab-org/-/epics/10642) in GitLab 17.2.
- Changed to require GitLab Duo add-on in GitLab 17.6 and later.

{{< /history >}}

GitLab Duo Vulnerability Explanation can help you with a vulnerability by using a large language model to:

- Summarize the vulnerability.
- Help developers and security analysts to understand the vulnerability, how it could be exploited, and how to fix it.
- Provide a suggested mitigation.

GitLab Duo can also automatically analyze critical and high severity SAST vulnerabilities to
identify potential false positives. For more information, see
[SAST false positive detection](../vulnerabilities/false_positive_detection.md).

<i class="fa-youtube-play" aria-hidden="true"></i> [Watch an overview](https://www.youtube.com/watch?v=MMVFvGrmMzw&list=PLFGfElNsQthZGazU1ZdfDpegu0HflunXW)

Prerequisites:

- [GitLab Duo](../../gitlab_duo/turn_on_off.md) must be enabled for the group or instance.
- You must be a member of the project.
- The vulnerability must be from a SAST scanner.

To explain the vulnerability:

1. On the top bar, select **Search or go to** and find your project.
1. Select **Secure** > **Vulnerability report**.
1. Optional. To remove the default filters, select **Clear** ({{< icon name="clear" >}}).
1. Above the list of vulnerabilities, select the filter bar.
1. In the dropdown list that appears, select **Tool**, then select all the values in the **SAST** category.
1. Select outside the filter field. The vulnerability severity totals and list of matching vulnerabilities are updated.
1. Select the SAST vulnerability you want explained.
1. Do one of the following:

   - Select the text below the vulnerability description that reads _You can also use AI by asking GitLab Duo Chat to explain this vulnerability and a suggested fix._
   - In the upper right, from the **Resolve with merge request** dropdown list, select **Explain vulnerability**, then select **Explain vulnerability**.
   - Open GitLab Duo Chat and use the [explain a vulnerability](../../gitlab_duo_chat/examples.md#explain-a-vulnerability) command by typing `/vulnerability_explain`.

The response is shown on the right side of the page.

On GitLab.com this feature is available. By default, it is powered by the Anthropic [`claude-3-haiku`](https://docs.anthropic.com/en/docs/about-claude/models#claude-3-a-new-generation-of-ai)
model. GitLab cannot guarantee that the large language model produces results that are correct. Use the
explanation with caution.

## Data shared with third-party AI APIs for Vulnerability Explanation

The following data is shared with third-party AI APIs:

- Vulnerability title (which might contain the filename, depending on which scanner is used).
- Vulnerability identifiers.
- Filename.
