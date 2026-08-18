---
stage: Agent Foundations
group: AI Catalog
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Support Assistant
---

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Status: Beta

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/237380) as a [beta](../../../../policy/development_stages_support.md#beta) in GitLab 19.2.

{{< /history >}}

The Support Assistant is a specialized agent that helps you:

- Diagnose a GitLab product problem when you are not sure where to start.
- Find the troubleshooting documentation for a specific feature area.
- Check whether the problem is a known issue.
- Prepare a support ticket with the relevant diagnostic information when you need to escalate to a human.

The Support Assistant helps diagnose GitLab problems. For other issues,
the Support Assistant tries to point you to the correct team.

For more information on the Support Assistant, see the [agent configuration YAML file](https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/-/blob/main/duo_workflow_service/agent_platform/v1/flows/configs/support_assistant/1.0.0.yml).

## Use the Support Assistant

Prerequisites:

- [Turn on foundational agents](_index.md#turn-foundational-agents-on-or-off).
- [Turn on beta and experimental features](../../turn_on_off.md#turn-on-beta-and-experimental-features).

To use the Support Assistant:

1. In the top bar, select **Search or go to** and find your project.
1. In the GitLab Duo sidebar, select **Add new chat**
   ({{< icon name="pencil-square" >}}).
1. From the dropdown list, select **Support Assistant**.

   A Chat conversation opens in the GitLab Duo sidebar on the right side of your screen.
1. Describe your GitLab problem in your own words, then answer the follow-up
   questions as the agent diagnoses the cause. To get the best results from
   your request:

   - Lead with the symptom and the impact. For example, "Builds have been failing
     since this morning and are blocking all merges" gives more to work with than
     "CI is broken".
   - Include the exact error message (with any secrets redacted) and the error
     code, if there is one.
   - Say what you have already tried, so the agent does not suggest the same
     thing again.
   - Mention your environment early: GitLab.com SaaS, GitLab Self-Managed (and
     the install type, such as Linux package or Helm chart), or GitLab
     Dedicated, plus the version.
   - Flag urgency. If it is a production outage, say so, and the agent moves
     straight to preparing an urgent ticket.
   - Keep to one problem per conversation, so the diagnosis stays focused.

### Example prompts

- "My pipeline keeps failing intermittently with no clear error. Where do I start?"
- "Dependency scanning isn't reporting any vulnerabilities for my project."
- "I'm getting 403 errors when calling the API with a personal access token."
- "Our Geo secondary is way behind the primary. Is this a known issue?"
- "I need to open a support ticket for slow Gitaly performance. What should I include?"
- "Which diagnostic archive should I collect for a Helm-based GitLab Self-Managed install?"
