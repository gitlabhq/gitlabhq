---
stage: Foundations
group: Import and Integrate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Pivotal Tracker
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

The Pivotal Tracker integration adds commit messages as comments to Pivotal Tracker stories.

Once enabled, commit messages are checked for square brackets containing a hash mark followed by
the story ID (for example, `[#555]`). Every story ID found gets the commit comment added to it.

You can also close a story with a message containing: `fix [#555]`.
You can use any of these words:

- `fix`
- `fixed`
- `fixes`
- `complete`
- `completes`
- `completed`
- `finish`
- `finished`
- `finishes`
- `delivers`

Read more about the
[Source Commits endpoint](https://www.pivotaltracker.com/help/api/rest/v5#Source_Commits) in
the Pivotal Tracker API documentation.

See also the [Pivotal Tracker integration API documentation](../../../api/integrations.md#pivotal-tracker).

## Set up Pivotal Tracker

In Pivotal Tracker, [create an API token](https://www.pivotaltracker.com/help/articles/api_token/).

Complete these steps in GitLab:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Settings > Integrations**.
1. Select **Pivotal Tracker**.
1. Ensure that the **Active** toggle is enabled.
1. Paste the token you generated in Pivotal Tracker.
1. Optional. To restrict this setting to specific branches, list them in the **Restrict to branch**
   field, separated with commas.
1. Optional. Select **Test settings**.
1. Select **Save changes**.
