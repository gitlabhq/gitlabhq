---
stage: Agent Foundations
group: AI Catalog
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
gitlab_dedicated: no
title: Onboarding Agent
---

{{< details >}}

- Tier: Premium, Ultimate
- Add-on: GitLab Duo
- Offering: GitLab.com, GitLab Self-Managed
- Status: Experiment

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/245452) in GitLab 19.4 as an [experiment](../../../../policy/development_stages_support.md#experiment)
  [with a feature flag](../../../../administration/feature_flags/_index.md) named `onboarding_guide_agent`.
  Disabled by default.

{{< /history >}}

The Onboarding Agent helps you set up the GitLab DevSecOps platform. The agent reads your project context and subscription tier, then
explains features, recommends the next adoption step, and provides configuration examples (for example, a `.gitlab-ci.yml`).

The Onboarding Agent only provides responses in GitLab Duo Chat. It does not modify your files, pipelines, or project settings. The agent can create and update work items, issues, and epics, and add comments to issues and work items. Before each action, the agent shows you the exact content and waits for your approval.

Use the Onboarding Agent when you need to:

- Set up a team or project for the first time.
- Migrate from GitHub, Bitbucket, or Jenkins and map your existing workflow to GitLab.
- Adopt more features in the platform, such as security scanning, compliance, or the agentic workflows.
- Discover what capabilities your tier includes or what to configure next.

## Prerequisites

Before you can use the Onboarding Agent:

- [Turn on](_index.md#turn-foundational-agents-on-or-off) foundational agents.
- [Turn on beta and experimental features](../../turn_on_off.md#turn-on-beta-and-experimental-features)

## Use the Onboarding Agent

1. In the top bar, select **Search or go to** and find your project or group.
1. On the GitLab Duo sidebar, select **Add new chat** ({{< icon name="pencil-square" >}}).
1. From the dropdown list, select **Onboarding Agent**.

   A Chat conversation opens in the GitLab Duo sidebar on the right side of your screen.
1. Describe what you want help with. To get the best results:
   - Ask follow-up questions in the same conversation. The agent remembers the context of your session and uses that to provide instructions.
   - Be explicit about whether you want to explore a specific stage (for example, security or compliance).
   - Review configuration suggestions from the agent before you apply it to your own project.

The agent gathers context from your current project and tier before it responds, and provides context-specific instructions.

## Example prompts

Use these prompts to get started:

- `Help me get started with GitLab.`
- `I'm migrating from GitHub — where should I begin?`
- `Set up security scanning for this project.`
- `What should I do next to get more value out of GitLab?`
- `What features am I missing on my current tier?`
- `Help me convert my Jenkins pipeline to GitLab CI/CD.`
- `Help me get started with compliance frameworks.` (Ultimate)

## Known issues

- The agent runs in only GitLab Duo Chat UI and in your IDE. You cannot create a [trigger](../../triggers/_index.md) for this agent.
- The agent does not create, edit, or commit files, modify pipelines, or change project settings. It can create and update work items, issues, and epics, and add comments to issues and work items after you approve each action.
- The agent cannot read vulnerabilities, security findings, pipeline errors, or job logs. It asks you for the relevant output, and might point you to the Security Analyst Agent or the CI Expert Agent. It cannot delegate to another agent.
- The agent uses project and page context, but cannot always detect whether a specific feature has been turned on for the project.
- Agent Platform usage is reported in aggregate on the [GitLab Duo and SDLC trends dashboard](../../../analytics/duo_and_sdlc_trends.md). You cannot yet see usage for individual agents.

## Give feedback

This agent is an experiment, and your feedback helps us improve it.
To share your experience or report a problem, add a comment to
[issue 606350](https://gitlab.com/gitlab-org/gitlab/-/issues/606350).

## Related topics

- [Foundational agents](_index.md)
- [GitLab Duo Agent Platform](../../_index.md)
