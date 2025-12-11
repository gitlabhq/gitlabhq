---
stage: AI-powered
group: Workflow Catalog
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Planner Agent
---

{{< details >}}

- Tier: Premium, Ultimate
- Add-on: GitLab Duo Core, Pro, or Enterprise
- Offering: GitLab.com, GitLab Self-Managed
- Status: Beta

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/576618) in GitLab 18.6.

{{< /history >}}

The Planner Agent is a specialized AI agent that assists with product management
and planning workflows in GitLab. It helps you organize, prioritize, and track work more effectively
because it combines:

- Product management expertise.
- Awareness of GitLab planning objects, like issues and epics.

Use the Planner Agent when you need help with:

- Prioritization: Applying frameworks like RICE, MoSCoW, or WSJF to rank work items.
- Work breakdown: Decomposing initiatives into epics, features, and user stories.
- Dependency analysis: Identifying blocked work and understanding relationships between items.
- Planning sessions: Organizing sprints, milestones, or quarterly planning.
- Status reporting: Generating summaries of progress, risks, and blockers.
- Backlog management: Identifying stale issues, duplicates, or items needing refinement.
- Estimation: Suggesting relative sizing or effort estimates for work items.

Please leave feedback in [issue 576622](https://gitlab.com/gitlab-org/gitlab/-/issues/576622).

## Access the Planner Agent

Prerequisites:

- You must be working in a project, not a group.
- Foundational agents must be [turned on](_index.md#turn-foundational-agents-on-or-off).
- During the beta, the Planner Agent is in read-only mode.

1. On the top bar, select **Search or go to** and find your project.
1. Open an issue, epic, or merge request in your project.
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

- "Generate an executive summary of this epic's progress: (insert URL)"
- "What tasks are needed to implement this user story?"
- "What issues have missed their due dates?"
- "Find stale issues that haven't been updated in 6 months."
- "Identify duplicate or similar issues in this project."
- "Break down this initiative (insert URL) into key features we need to deliver."
- "How should we sequence the features in this initiative? (insert URL)?"
- "What work should we defer in this epic (insert URL) to reduce scope?"
- "Suggest how to organize these 20 issues (insert filter criteria) across Q1 sprints."
- "Summarize blockers and mitigation plans for leadership: (insert URL)"
- "Which of the bugs with a "boards" label should we fix first, considering user impact?"
- "Group these issues into logical release themes: (insert URL)"
- "Identify which features are required for version 1, and which are optional, and explain why: (insert URL)"
- "Rank these epics by strategic value for Q1."
- "Suggest a phased approach for this project: (insert URL)"
- "Help me prioritize issues in my backlog with the label (insert label name) by using the RICE framework."
- "Which child items on this epic should I remove from the current scope to meet the deadline?"
- "What would be the MVP version of this feature? (insert URL)"
- "Help me prioritize technical debt against new features."
- "Compare these features (insert URLs) using an effort versus impact matrix."
- "Use MoSCoW to categorize features with the criteria (insert criteria) based on customer impact."
