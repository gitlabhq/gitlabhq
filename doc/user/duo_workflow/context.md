---
stage: AI-powered
group: Duo Workflow
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Context in GitLab Duo Workflow
---

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com
- Status: Experiment

{{< /details >}}

{{< alert type="warning" >}}

This feature is considered [experimental](../../policy/development_stages_support.md) and is not intended for customer usage outside of initial design partners. We expect major changes to this feature.

{{< /alert >}}

Workflow is aware of the context you're working in, specifically:

| Area                          | How to use GitLab Workflow |
|-------------------------------|--------------------------------|
| Epics                         | Enter the epic ID and the name of the group the epic is in. The group must include a project that meets the [prerequisites](set_up.md#prerequisites). |
| Issues                        | Enter the issue ID if it's in the current project. In addition, enter the project ID if it is in a different project. The other project must also meet the [prerequisites](set_up.md#prerequisites). |
| Local files                   | Workflow can access all files available to Git in the project you have open in your editor. Enter the file path to reference a specific file. |
| Merge requests                | Enter the merge request ID if it's in the current project. In addition, enter the project ID if it's in a different project. The other project must also meet the [prerequisites](set_up.md#prerequisites). |
| Merge request pipelines       | Enter the merge request ID that has the pipeline, if it's in the current project. In addition, enter the project ID if it's in a different project. The other project must also meet the [prerequisites](set_up.md#prerequisites).  |

Workflow also has access to the GitLab [Search API](../../api/search.md) to find related issues or merge requests.
