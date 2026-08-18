---
stage: Agent Foundations
group: AI Catalog
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Flow Creator
---

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/groups/gitlab-org/-/work_items/22644) in GitLab 19.3.

{{< /history >}}

The Flow Creator is a specialized AI agent that helps you create
[custom flows](../../flows/custom.md) for the AI Catalog. Describe the flow you want
in plain language, and the agent produces a complete flow YAML that you can use in the
AI Catalog.

The agent understands the Flow Registry framework, including components, triggers,
inputs, and routing. It researches the live framework documentation before answering,
so its responses reflect the current capabilities of the framework rather than a
fixed snapshot.

Use the Flow Creator when you need to:

- Create a flow: Generate a complete flow YAML from your description of
  what the flow should do and how it should be triggered.
- Debug a flow: Find out why an existing flow configuration fails validation or
  does not behave as expected.
- Understand the framework: Learn which components, parameters, and triggers are
  available, and how to wire them together.

## Use the Flow Creator

Prerequisites:

- [Turn on](_index.md#turn-foundational-agents-on-or-off) foundational agents.

To use the Flow Creator in the GitLab UI:

1. In the top bar, select **Search or go to** and find your project or group.
1. On the GitLab Duo sidebar, select **Add new chat** ({{< icon name="pencil-square" >}}).
1. From the dropdown list, select **Flow Creator**.

   A Chat conversation opens in the GitLab Duo sidebar on the right side of your screen.
1. Describe the flow you want to create. To get the best results:

   - Describe what should trigger the flow, for example, being assigned to an issue,
   or a new merge request being created.
   - Describe the outcome you want, not the components you think you need. The agent
   selects the appropriate components.
   - When debugging, paste the full flow YAML so the agent can validate it against
   the framework rules.
1. Copy the flow YAML from the agent's response, then paste it into the
   [new flow](../../flows/custom.md) screen in a project where you have permission to
   create flows.

## Example prompts

- Create a flow:
  - "Create a flow that summarizes an issue when I am assigned to it."
  - "Create a flow that adds a label to new issues based on the issue description."
  - "Create a flow that asks me for approval before it comments on a merge request."
- Debug a flow:
  - "Why does this flow configuration fail validation? `<flow YAML>`"
  - "This flow never stops running. What is wrong with it? `<flow YAML>`"
- Understand how flows work:
  - "How do I pass the branch name into my flow?"
  - "Which component do I use to ask the user for input in the middle of a flow?"

## Known issues

- The agent generates YAML only for the Flow Registry v1 schema.
- The agent reads the framework documentation before responding. As a result, responses can take longer than responses from other agents.
