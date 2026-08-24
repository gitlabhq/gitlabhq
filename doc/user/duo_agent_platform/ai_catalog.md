---
stage: Agent Foundations
group: AI Catalog
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

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/549914) in GitLab 18.5 [with a feature flag](../../administration/feature_flags/_index.md) named `global_ai_catalog`. Enabled on GitLab.com as an [experiment](../../policy/development_stages_support.md).
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
- Have the [Agent Platform turned on](turn_on_off.md#turn-gitlab-duo-agent-platform-on-or-off).
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

## Configuration size limits

{{< history >}}

- Separate size limit for flow and external agent YAML [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/247313) in GitLab 19.3.

{{< /history >}}

The configuration of an AI Catalog item cannot exceed a maximum size:

| Item type      | Maximum size | Measured against                             |
|----------------|--------------|----------------------------------------------|
| Custom agent   | 80 KiB       | The stored configuration                     |
| Flow           | 40 KiB       | The YAML configuration you enter             |
| External agent | 40 KiB       | The YAML configuration you enter             |

Flows and external agents have a lower limit. GitLab stores both the YAML you enter and the
structured configuration that GitLab generates from it. Together, these are about twice the size
of the YAML.

If your configuration exceeds the limit, GitLab displays an error and does not save the item.
To resolve the error, reduce the size of your configuration.

## Item visibility

{{< history >}}

- Restricted visibility [introduced](https://gitlab.com/gitlab-org/gitlab/-/work_items/603253) in GitLab 19.3 [with a feature flag](../../administration/feature_flags/_index.md) named `ai_catalog_internal_visibility`. Enabled by default.

{{< /history >}}

> [!flag]
> The **Restricted** visibility option is controlled by a feature flag named `ai_catalog_internal_visibility`.
> For more information, see the history.

When you create an agent or flow, you select a project to manage it and choose whether the item is
public, private, or restricted.
Visibility controls who can view, enable, and run the item.
These rules apply to custom agents, external agents, and flows.

### Public items

- Can be viewed by anyone and can be turned on in any project that meets the prerequisites.

### Private items

- Can be viewed only by members of the managing project who have the Guest, Planner, Reporter,
  Developer, Maintainer, or Owner role.
- Cannot be turned on in projects other than the managing project.

You cannot make a public or restricted item private if the item has been turned on by a project other
than the managing project.

### Restricted items

- Can be viewed and used by members of any project in the top-level group of the managing project.
- Can be turned on in other projects in the same top-level group.
- Cannot be viewed or turned on outside that top-level group.
- Cannot be viewed in the AI Catalog in Explore.
- Cannot be created from the AI Catalog in Explore.

You cannot make a public item restricted if the item has been turned on by a project outside of that
top-level group.

#### Restricted items and shared projects or groups

GitLab lets you [share a project or group](../project/members/sharing_projects_groups.md) into another
project or group.
The restricted visibility rules around enablement consider only the actual top-level group of the managing project.
It does not consider shared project or group relationships.

A collaborator who gains access to a project or group through a share can view, enable, and run restricted
items only while working inside that shared container.
The share does not extend restricted access into the collaborator's own top-level group.

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
