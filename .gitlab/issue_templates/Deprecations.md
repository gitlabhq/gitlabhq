For guidance on the overall deprecations, removals and breaking changes workflow, please visit [Breaking changes, deprecations, and removing features](https://about.gitlab.com/handbook/product/gitlab-the-product/#deprecations-removals-and-breaking-changes)

<!-- Use this template as a starting point for deprecations. -->

### Deprecation Summary

<!--
This should contain a brief description of the feature or functionality that is deprecated. The description should clearly state the potential impact of the deprecation to end users.

It is recommended that you link to the documentation.

The description of the deprecation should state what actions the user should take to rectify the behavior. If the deprecation is scheduled for an upcoming release, the content should remain in the deprecations documentation page until it has been completed. For example, if a deprecation is announced in 14.9 and scheduled to be completed in 15.0, the same content would be included in the documentation for 14.9, 14.10, and 15.0.

**If this issue proposes a breaking change outside a major release XX.0, you need to get approval from your manager and request collaboration from Product Operations on communication. Be sure to follow the guidance [here](https://about.gitlab.com/handbook/product/gitlab-the-product/#deprecations-removals-and-breaking-changes.)** 

-->

### Breaking Change

<!-- Does this MR contain a breaking change? If yes:
- Add the ~"breaking change" label to this issue.
- Add instructions for how users can update their workflow. -->

### Affected Topology

<!--
Who is affected by this deprecation, Self-managed users, SaaS users, or both? This is especially important when nearing the annual major release where breaking changes and removals are typically introduced. These changes might be seen on GitLab.com before the official release date.
-->

### Affected Tier

<!--
Which tier is this feature available in?

* Free
* Premium
* Ultimate
-->

### Checklists

**Labels**

- [ ] This issue is labeled ~deprecation, and with the relevant `~devops::`, `~group::`, and `~Category:` labels.
- [ ] This issue is labeled  ~"breaking change" if the removal of the deprecated item will be a [breaking change](https://about.gitlab.com/handbook/product/gitlab-the-product/#examples-of-breaking-changes).

**Timeline**

Please add links to the relevant merge requests.

- As soon as possible, but no later than the third milestone preceding the major release (for example, given the following release schedule: `14.8, 14.9, 14.10, 15.0` – `14.8` is the third milestone preceding the major release):
    - [ ] A [deprecation announcement entry](https://about.gitlab.com/handbook/marketing/blog/release-posts/#creating-the-announcement) has been created so the deprecation will appear in release posts and on the [general deprecation page](https://docs.gitlab.com/ee/update/deprecations).
    - [ ] Documentation has been updated to mark the feature as [deprecated](https://docs.gitlab.com/ee/development/documentation/versions.html#deprecations-and-removals).
- [ ] On or before the major milestone: A [removal entry](https://about.gitlab.com/handbook/marketing/blog/release-posts/#creating-the-announcement-1) has been created so the removal will appear on the [removals by milestones](https://docs.gitlab.com/ee/update/removals) page and be announced in the release post.
- On the major milestone:
    - [ ] The deprecated item has been removed.
    - [ ] If the removal of the deprecated item is a [breaking change](https://about.gitlab.com/handbook/product/gitlab-the-product/#examples-of-breaking-changes), the merge request is labeled ~"breaking change".

**Mentions**

- [ ] Your stage's stable counterparts have been `@mentioned`  on this issue. For example, Customer Support, Customer Success (Technical Account Manager), Product Marketing Manager.
  - To see who the stable counterparts are for a product team visit [product categories](https://about.gitlab.com/handbook/product/categories/)
       - If there is no stable counterpart listed for Sales/CS please mention `@timtams`
       - If there is no stable counterpart listed for Support please mention `@gitlab-com/support/managers`
       - If there is no stable counterpart listed for Marketing please mention `@cfoster3`
- [ ] Your GPM has been `@mentioned` so that they are aware of planned deprecations. The goal is to have reviews happen at least two releases before the final removal of the feature or introduction of a breaking change.

### Deprecation Milestone

<!-- In which milestone will this deprecation be announced ? -->

### Planned Removal Milestone

<!-- In which milestone will the feature or functionality be removed and announced? -->

### Links

<!--
Add links to any relevant documentation or code that will provide additional details or clarity regarding the planned change.

This issue is the main SSOT for the deprecations and removals process. Be sure to link all
issues and MRs related to this deprecation/removal to this issue. This can include removal
issues that were created ahead of time, and the MRs doing the actual deprecation/removal work.
-->

<!-- Label reminders - you should have one of each of the following labels.
Use the following resources to find the appropriate labels:
- https://gitlab.com/gitlab-org/gitlab/-/labels
- https://about.gitlab.com/handbook/product/categories/features/
-->

<!-- Populate the Section, Group, and Category -->
/label ~devops:: ~group: ~Category:

<!-- Choose the Pricing Tier(s) -->
/label  ~"GitLab Free" ~"GitLab Premium" ~"GitLab Ultimate"

<!-- Identifies that this Issue is related to deprecating a feature -->
/label ~"deprecation"

<!-- Add the ~"breaking change" label to this issue if necessary -->
