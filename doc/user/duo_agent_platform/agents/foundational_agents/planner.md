---
stage: AI-powered
group: Workflow Catalog
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitLab Duo Planner
---

{{< details >}}

- Tier: Premium, Ultimate
- Add-on: GitLab Duo Core, Pro, or Enterprise
- Offering: GitLab.com
- Status: Beta

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/576618) in GitLab 18.5.

{{< /history >}}

GitLab Duo Planner is a specialized AI agent that assists with product management
and planning workflows in GitLab. It helps you organize, prioritize, and track work more effectively
because it combines:

- Product management expertise.
- Awareness of GitLab planning objects, like issues and epics.

Use GitLab Duo Planner when you need help with:

- Prioritization: Applying frameworks like RICE, MoSCoW, or WSJF to rank work items.
- Work breakdown: Decomposing initiatives into epics, features, and user stories.
- Dependency analysis: Identifying blocked work and understanding relationships between items.
- Planning sessions: Organizing sprints, milestones, or quarterly planning.
- Status reporting: Generating summaries of progress, risks, and blockers.
- Backlog management: Identifying stale issues, duplicates, or items needing refinement.
- Estimation: Suggesting relative sizing or effort estimates for work items.

## Access GitLab Duo Planner

Prerequisites:

- You must be working in a project, not a group.
- The GitLab Duo Planner agent is [enabled for your project](../../../duo_agent_platform/agents/_index.md#enable-an-agent).
- During the beta, GitLab Duo Planner is in read-only mode.

1. On the left sidebar, select **Search or go to** and find your project.
1. Open an issue, epic, or merge request in your project.
1. In the upper-right corner, select **Open GitLab Duo Chat** ({{< icon name="duo-chat" >}}).
   A drawer opens on the right side of your screen.
1. From the **New chat** ({{< icon name="duo-chat-new" >}}) dropdown list, select **Duo Planner**.
1. Enter your planning-related question or request. To get the best results from your request:

   - Provide context about your request, like URLs, filter criteria, or scope.
   - If you have a preferred prioritization framework, specify it.
   - If the agent's assumptions don't match your workflow, ask for clarification.

### Example prompts

- "Help me prioritize issues in my backlog with the label (insert label name)" using the RICE framework."
- "Use MoSCoW to categorize features with the criteria (insert criteria) based on customer impact."
- "Which of the bugs with a "boards" label should we fix first, considering user impact?"
- "Rank these epics by strategic value for Q1."
- "Help me prioritize technical debt against new features."
- "Compare these features (insert URLs) using an effort versus impact matrix."
- "Which child items on this epic should I remove from the current scope to meet the deadline?"
- "Break down this initiative (insert URL) into key features we need to deliver."
- "Create user stories for this epic (insert URL) with acceptance criteria."
- "What tasks are needed to implement this user story?"
- "Suggest a phased approach for this project: (insert URL)"
- "What would be the MVP version of this feature? (insert URL)"
- "Identify which features are required for version 1, and which are optional, and explain why: (insert URL)"
- "Suggest how to organize these 20 issues (insert filter criteria) across Q1 sprints."
- "What work should we defer in this epic (insert URL) to reduce scope?"
- "Review this backlog (insert filter criteria) and identify items that need refinement."
- "How should we sequence the features in this initiative? (insert URL)?"
- "Group these issues into logical release themes: (insert URL)"
- "Generate an executive summary of this epic's progress: (insert URL)"
- "Draft release notes based on issues assigned to (insert relevant milestone or iteration)."
- "Write a stakeholder update on this initiative's health: (insert URL)"
- "Summarize blockers and mitigation plans for leadership: (insert URL)"
- "Find stale issues that haven't been updated in 6 months."
- "Identify duplicate or similar issues in this project."
- "Which issues are missing estimates or assignees?"
- "Identify orphaned issues with no parent."
- "What issues have missed their due dates?"
