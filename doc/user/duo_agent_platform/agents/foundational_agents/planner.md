---
stage: AI-powered
group: Workflow Catalog
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Planner Agent
---

{{< details >}}

- Tier: [Free](../../../../subscriptions/gitlab_credits.md#for-the-free-tier), Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/576618) as a beta in GitLab 18.6.
- Create and edit features introduced in GitLab 18.7.
- [Generally available](https://gitlab.com/gitlab-org/gitlab/-/work_items/585273) in GitLab 18.8.
- Available on the Free tier on GitLab.com with GitLab Credits in GitLab 18.10.
- To-do management introduced in GitLab 19.0.

{{< /history >}}

The Planner Agent is a specialized AI agent that assists with product management
and planning workflows in GitLab. It helps you create, prioritize, and track work more effectively.

The Planner Agent understands GitLab planning concepts, including work item hierarchies
(epics, issues, and tasks), milestones, labels, and weights. It can analyze work items,
suggest prioritization strategies, and help you structure and communicate your plans.

Use the Planner Agent when you need help with:

- Prioritization: Applying frameworks like RICE, MoSCoW, or WSJF to rank work items.
- Work breakdown: Decomposing initiatives into epics, features, and user stories.
- Creating content: Drafting memos, requirements, and other planning artifacts, or creating
  epics, issues, and tasks directly when asked.
- Dependency analysis: Identifying blocked work and understanding relationships between items.
- Editing content: Updating work items, labels, milestones, and other attributes either when asked or after it
  asks for confirmation to take action.
- To-do management: Adding to-dos to work items and marking them as done.
- Planning sessions: Organizing sprints, milestones, or quarterly planning.
- Status reporting: Generating summaries of progress, risks, and blockers.
- Backlog management: Identifying stale issues, duplicates, or items needing refinement.
- Estimation: Suggesting relative sizing or effort estimates for work items.

You can leave feedback in [issue 583008](https://gitlab.com/gitlab-org/gitlab/-/work_items/583008).

## Use the Planner Agent

You can use the Planner Agent in the GitLab UI, VS Code, and JetBrains IDEs.

### Tips for best results

To get the best results from your requests:

- Provide context about your request, like URLs, filter criteria, or scope.
- Specify the work item type (epic, issue, or task) when relevant.
- If you have a preferred prioritization framework, specify it.
- Specify your intended audience when asking for summaries or updates, for example,
  engineering team, leadership, or stakeholders.
- Use explicit action verbs like "create", "update", or "close" when you want the
  agent to take action rather than make a recommendation.
- If the agent's assumptions do not match your workflow, ask for clarification.

### In the GitLab UI

Prerequisites:

- [Turn on](_index.md#turn-foundational-agents-on-or-off) foundational agents.

To use the Planner Agent in the GitLab UI:

1. In the top bar, select **Search or go to** and find your project or group.
1. On the GitLab Duo sidebar, select **Add new chat** ({{< icon name="pencil-square" >}}).
1. From the dropdown list, select **Planner**.

   A Chat conversation opens in the GitLab Duo sidebar on the right side of your screen.
1. Enter your planning-related question or request.

### In VS Code

Prerequisites:

- [Turn on](_index.md#turn-foundational-agents-on-or-off) foundational agents.
- Install and configure [GitLab for VS Code](../../../../editor_extensions/visual_studio_code/setup.md)
  version 6.57.3 or later.
- Set a [default GitLab Duo namespace](../../../profile/preferences.md#set-a-default-gitlab-duo-namespace).

To use the Planner Agent in VS Code:

1. In VS Code, in the left sidebar, select **GitLab Duo Agent Platform** ({{< icon name="duo-agentic-chat" >}}).
1. Select the **Chat** tab.
1. From the **New chat** ({{< icon name="duo-chat-new" >}}) dropdown list, select **Planner**.
1. Enter your planning-related question or request.

### In JetBrains IDEs

Prerequisites:

- [Turn on](_index.md#turn-foundational-agents-on-or-off) foundational agents.
- Install and configure the [GitLab Duo plugin for JetBrains IDEs](../../../../editor_extensions/jetbrains_ide/setup.md)
  version 3.11.1 or later.
- Set a [default GitLab Duo namespace](../../../profile/preferences.md#set-a-default-gitlab-duo-namespace).

First, enable the GitLab Duo Agent Platform:

1. In your JetBrains IDE, go to **Settings** > **Tools** > **GitLab Duo**.
1. Under **GitLab Duo Agent Platform**, select the **Enable GitLab Duo Agent Platform** checkbox.
1. Restart your IDE if prompted.

Then, to use the Planner Agent:

1. In your JetBrains IDE, on the right tool window bar, select **GitLab Duo Agent Platform** ({{< icon name="duo-agentic-chat" >}}).
1. Select the **Chat** tab.
1. From the **New chat** ({{< icon name="duo-chat-new" >}}) dropdown list, select **Planner**.
1. Enter your planning-related question or request.

## Example prompts

- Prioritization:
  - "Help me prioritize work items in my backlog with the label `<label name>` using the RICE
    framework."
  - "Use MoSCoW to categorize features in this work item with the criteria `<criteria>` based on
    customer impact: `<URL>`"
  - "Rank these work items by strategic value for Q1: `<URLs>`"
  - "Compare these features using an effort versus impact matrix: `<URLs>`"
  - "Which child items on this work item should I remove from the current scope to meet the
    deadline? `<URL>`"
- Work breakdown:
  - "Break down this initiative into key features we need to deliver: `<URL>`"
  - "What tasks are needed to implement this work item? `<URL>`"
  - "What would be the MVP version of this feature? `<URL>`"
  - "How should we sequence the features in this work item? `<URL>`"
  - "Suggest a phased approach for this project: `<URL>`"
- Status reporting:
  - "Provide a status update and progress report for this work item, including all child items:
    `<URL>`"
  - "Generate an executive summary of this work item's progress: `<URL>`"
  - "Summarize blockers and mitigation plans for leadership: `<URL>`"
  - "Write a stakeholder update on this initiative's health: `<URL>`"
- Content creation:
  - "Draft a memo for this initiative including objectives, success criteria, and key stakeholders:
    `<URL>`"
  - "Draft a technical requirements work item for this including API needs, data models, and
    integration points: `<URL>`"
  - "Write a dependency map narrative explaining the relationships and sequencing between these
    work items: `<URLs>`"
  - "Generate a risk assessment for this epic identifying potential blockers and mitigation
    strategies: `<URL>`"
  - "Estimate implementation effort for this work item, including development time, testing, and
    potential blockers: `<URL>`"
- Dependency analysis:
  - "What work should we defer in this work item to reduce scope? `<URL>`"
  - "Help me prioritize technical debt against new features."
- Planning sessions:
  - "Group these work items into logical release themes: `<URLs>`"
  - "What work items have missed their due dates?"
- Backlog management:
  - "Find stale work items that have not been updated in 6 months."
  - "Identify duplicate or similar work items in this project."
  - "Show work items assigned to me."
- Content editing:
  - "Close this work item as completed and create a new retrospective work item documenting
    what went well and what needs improvement: `<URL>`"
- To-do management:
  - "Add a to-do for this work item: `<URL>`"
  - "Mark all my to-dos as done for this work item: `<URL>`"

## Known issues

- The agent can analyze work items in bulk, but response quality might decrease for requests
  involving large numbers of items.
- The agent cannot reliably access comments on work items with long discussion histories.
  Comment histories exceeding approximately 100 entries might be incomplete.
- When you ask the agent to update the status of a work item to a value that does not exist,
  the agent might incorrectly report the update as successful without applying any change.
- The agent cannot create linked item relationships between work items.
  However, you can ask the agent to add a comment with the `/relate`,
  `/blocks`, or `/blocked_by` quick action as a workaround.
