---
stage: AI-powered
group: Workflow Catalog
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: Discover, enable, and manage agents and flows from a central catalog.
title: AI Catalog
---

{{< details >}}

- Tier: [Free](../../subscriptions/gitlab_credits.md#for-the-free-tier), Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

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

The AI Catalog is a central list of agents and flows.
Add these agents and flows to your project to get started orchestrating agentic AI tasks.

Use the AI Catalog to:

- Discover agents and flows created by the GitLab team and community members.
- Create custom agents and flows, and share them with other users.
- Enable agents and flows in your projects to use them across the GitLab Duo Agent Platform.

## View the AI Catalog

{{< history >}}

- Ability to use the GitLab Duo sidebar to view the AI Catalog [introduced](https://gitlab.com/gitlab-org/gitlab/-/work_items/592493) in GitLab 18.11.

{{< /history >}}

Prerequisites:

- Meet the [GitLab Duo Agent Platform prerequisites](_index.md#prerequisites).
- On GitLab Self-Managed, have [GitLab Duo turned on for the instance](turn_on_off.md#for-an-instance).
- To enable agents and flows from the AI Catalog:
  - In a group, you must have the Maintainer or Owner role.
  - In a project, you must have the Maintainer or Owner role.

To view the AI Catalog, you can either:

- Use the top bar:
  1. In the top bar, select **Search or go to** > **Explore**.
  1. Select **AI Catalog**.

- Use the GitLab Duo sidebar:
  1. In the top bar, select **Search or go to** and find your project.
  1. On the GitLab Duo sidebar, select **GitLab Duo AI Catalog** ({{< icon name="tanuki-ai" >}}).

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
   - **AI** > **Agents**
   - **AI** > **Flows**
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
   - **AI** > **Agents**
   - **AI** > **Flows**
1. Select the agent or flow you want to update.
1. Review the latest version carefully. To update, select **View latest version** > **Update to `<x.y.z>`**.

## Restrict the AI Catalog to a group hierarchy

{{< details >}}

- Offering: GitLab.com

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/work_items/594617) in GitLab 19.0.

{{< /history >}}

In a top-level group, you can restrict the AI Catalog so that, for a project in that group hierarchy, users can
see, enable, and run only:

- Foundational agents and flows maintained by GitLab.
- Public agents and flows owned by projects in the same top-level group hierarchy.
- Private agents and flows owned by the project itself.

Agents and flows owned by projects outside the hierarchy are:

- Hidden from the AI Catalog.
- Blocked from being enabled.
- Blocked from running, even if a project previously enabled them.

You can configure this setting only on a top-level group. It applies to all projects
in that hierarchy. Changes to this setting are recorded in the audit log.

Prerequisites:

- You must have the Owner role for the top-level group.

To restrict the AI Catalog to your group hierarchy:

1. In the top bar, select **Search or go to** and find your top-level group.
1. Select **Settings** > **GitLab Duo**.
1. Select **Change configuration**.
1. In the **Data and privacy** section, under **AI Catalog**, select the **Restrict the AI Catalog to this group** checkbox.
1. Select **Save changes**.

## Related topics

- [Agents](agents/_index.md)
- [External agents](agents/external.md)
