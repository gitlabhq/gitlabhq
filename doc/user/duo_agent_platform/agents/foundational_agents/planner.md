---
stage: AI-powered
group: Workflow Catalog
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Planner Agent
---

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/576618) as a beta in GitLab 18.6.
- Create and edit features introduced in GitLab 18.7.
- [Generally available](https://gitlab.com/gitlab-org/gitlab/-/work_items/585273) in GitLab 18.8.

{{< /history >}}

The Planner Agent is a specialized AI agent that assists with product management
and planning workflows in GitLab. It helps you create, prioritize, and track work more effectively
because it combines:

- Product management expertise.
- Awareness of GitLab planning objects, like issues and epics.

Use the Planner Agent when you need help with:

- Prioritization: Applying frameworks like RICE, MoSCoW, or WSJF to rank work items.
- Work breakdown: Decomposing initiatives into epics, features, and user stories.
- Create: Drafting memos or creating objects to provide value.
- Dependency analysis: Identifying blocked work and understanding relationships between items.
- Edit: Editing existing objects to save time and improve efficiency.
- Planning sessions: Organizing sprints, milestones, or quarterly planning.
- Status reporting: Generating summaries of progress, risks, and blockers.
- Backlog management: Identifying stale issues, duplicates, or items needing refinement.
- Estimation: Suggesting relative sizing or effort estimates for work items.

Please leave feedback in [issue 583008](https://gitlab.com/gitlab-org/gitlab/-/work_items/583008).

## Access the Planner Agent

Prerequisites:

- Foundational agents must be [turned on](_index.md#turn-foundational-agents-on-or-off).

1. On the top bar, select **Search or go to** and find your project or group.
1. Open an issue, epic, or merge request.
1. On the GitLab Duo sidebar, select either **New GitLab Duo Chat**
   ({{< icon name="pencil-square" >}}) or **Current GitLab Duo Chat**
   ({{< icon name="duo-chat" >}}).

   A Chat conversation opens in the GitLab Duo sidebar on the right side of your screen.

1. From the **New chat** ({{< icon name="duo-chat-new" >}}) dropdown list, select **Planner**.
1. Enter your planning-related question or request. To get the best results from your request:

   - Provide context about your request, like URLs, filter criteria, or scope.
   - If you have a preferred prioritization framework, specify it.
   - If the agent's assumptions don't match your workflow, ask for clarification.

### Example prompts

- "Generate an executive summary of this work items progress: (insert URL)"
- "Draft a memo for this work item (insert URL) including objectives, success criteria, and key stakeholders."
- "What tasks are needed to implement this work item?"
- "Draft a technical requirements work item for this (insert URL) including API needs, data models, and integration points."
- "What work items have missed their due dates?"
- "Write a dependency map narrative in an work item explaining the relationships and sequencing between these work items: (insert URLs)."
- "Find stale work items that haven't been updated in 6 months."
- "Identify duplicate or similar work items in this project."
- "Break down this initiative (insert URL) into key features we need to deliver."
- "How should we sequence the features in this work item? (insert URL)?"
- "What work should we defer in this work item (insert URL) to reduce scope?"
- "Close this work item (insert URL) as completed. Create a new retrospective work item documenting what went well and what needs improvement, and link it to the closed work item."
- "Show work items assigned to me."
- "Summarize blockers and mitigation plans for leadership: (insert URL)"
- "Group these work items into logical release themes: (insert URL)"
- "Rank these work items by strategic value for Q1."
- "Suggest a phased approach for this project: (insert URL)"
- "Help me prioritize work items in my backlog with the label (insert label name) by using the RICE framework."
- "Which child items on this work item should I remove from the current scope to meet the deadline?"
- "What would be the MVP version of this feature? (insert URL)"
- "Help me prioritize technical debt against new features."
- "Compare these features (insert URLs) using an effort versus impact matrix."
- "Use MoSCoW to categorize features with the criteria (insert criteria) based on customer impact."
