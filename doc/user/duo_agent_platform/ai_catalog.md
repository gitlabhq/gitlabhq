---
stage: AI-powered
group: Workflow Catalog
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: AI Catalog
---

{{< details >}}

- Tier: [Free](../../subscriptions/gitlab_credits.md#for-the-free-tier-on-gitlabcom), Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed

{{< /details >}}

{{< collapsible title="Model information" >}}

- LLM: Anthropic [Claude Sonnet 4](https://www.anthropic.com/claude/sonnet)

{{< /collapsible >}}

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/549914) in GitLab 18.5 [with a flag](../../administration/feature_flags/_index.md) named `global_ai_catalog`. Enabled on GitLab.com as an [experiment](../../policy/development_stages_support.md).
- Support for external agents [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/207610) in GitLab 18.6 with a flag named `ai_catalog_third_party_flows`. Enabled on GitLab.com as an [experiment](../../policy/development_stages_support.md).
- [Changed](https://gitlab.com/gitlab-org/gitlab/-/issues/568176) to beta in GitLab 18.7.
- [Generally available](https://gitlab.com/gitlab-org/gitlab/-/work_items/585273) in GitLab 18.8.
- Feature flag `global_ai_catalog` [removed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/223135) in 18.10.
- Available on the Free tier on GitLab.com with GitLab Credits in GitLab 18.10.

{{< /history >}}

> [!flag]
> The availability of this feature is controlled by a feature flag.
> For more information, see the history.

The AI Catalog is a central list of agents and flows.
Add these agents and flows to your project to get started orchestrating agentic AI tasks.

Use the AI Catalog to:

- Discover agents and flows created by the GitLab team and community members.
- Create custom agents and flows, and share them with other users.
- Enable agents and flows in your projects to use them across the GitLab Duo Agent Platform.

## View the AI Catalog

Prerequisites:

- You must meet the [prerequisites](_index.md#prerequisites).
- On GitLab.com, you must be a member of a top-level group that has
  [turned on GitLab Duo experiment and beta features](../gitlab_duo/turn_on_off.md#on-gitlabcom-2).
- To enable agents and flows from the AI Catalog:
  - In a group, you must have the Maintainer or Owner role.
  - In a project, you must have the Maintainer or Owner role.

To view the AI Catalog:

1. In the top bar, select **Search or go to** > **Explore**.
1. Select **AI Catalog**.

A list of agents is displayed.

On GitLab Self-Managed, the following agents are not displayed in the AI Catalog:

- Custom agents created on GitLab.com.
- GitLab-managed external agents that have not been [added to the instance](agents/external.md#add-gitlab-managed-agents-to-other-instances).

To view available flows, select the **Flows** tab.

## Agent and flow versions

{{< history >}}

- [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/20022) in GitLab 18.7.

{{< /history >}}

Each custom agent and flow in the AI Catalog maintains a version history.
When you make changes to an item's configuration, GitLab automatically creates a new version.
Foundational agents and flows do not use versioning.

GitLab uses semantic versioning to indicate the scope of changes.
For example, an agent can have a version number like `1.0.0` or `1.1.0`.
GitLab manages semantic versioning automatically. Updates to agents or flows always increment the minor version.

Versioning ensures that your projects and groups continue to use a stable, tested configuration of an agent or flow.
This prevents unexpected changes from affecting your workflows.

### Creating versions

GitLab creates a version when you:

- Update a custom agent's system prompt.
- Modify an external agent or flow's configuration.

To ensure consistent behavior, versions are immutable.

### Version pinning

{{< history >}}

- Project that manages an agent or flow always on the latest version of that item [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/583024) in GitLab 18.10.

{{< /history >}}

When you enable an AI Catalog item:

- In a group, GitLab pins the latest version.
- In a project that does not manage that item, GitLab pins the same version as the project's top-level group.

Version pinning means:

- Your project or group uses a fixed version of the item.
- Updates to the agent or flow in the AI Catalog do not affect your configuration.
- You maintain control over when to adopt new versions.

This approach provides stability and predictability for your AI-powered workflows.

When you enable an AI Catalog item in the project that manages the item, GitLab does not pin a version.
Instead, the manager project always uses the latest version of the item.

If you enabled an agent or flow in its manager project before GitLab 18.10, your configuration remains at the pinned version.

After you update to the latest version for the first time, GitLab automatically uses the latest version from then onwards.

### View the current version

Prerequisites:

- You must have the Developer, Maintainer, or Owner role.

To view the current version of an agent or flow:

1. In the top bar, select **Search or go to** and find your project or group.
1. In the left sidebar, select either:
   - **Automate** > **Agents**
   - **Automate** > **Flows**
1. Select the agent or flow to view its details.

The details page displays:

- The pinned version your project or group is using.
- The version identifier. For example, `1.2.0`.
- Details about that specific version's configuration.

### Update to the latest version

Prerequisites:

- You must have the Maintainer or Owner role.

To make your group or project use the latest version of an agent or flow:

1. In the top bar, select **Search or go to** and find your project or group.
1. In the left sidebar, select either:
   - **Automate** > **Agents**
   - **Automate** > **Flows**
1. Select the agent or flow you want to update.
1. Review the latest version carefully. To update, select **View latest version** > **Update to `<x.y.z>`**.

## Related topics

- [Agents](agents/_index.md)
- [External agents](agents/external.md)
