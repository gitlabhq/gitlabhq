<!-- Use this template as a starting point for deprecations. -->
<!-- For guidance on the overall deprecations, removals and breaking changes workflow, please visit [Breaking changes, deprecations, and removing features](https://handbook.gitlab.com/handbook/marketing/blog/release-posts/#deprecations-removals-and-breaking-changes). -->

### Deprecation Summary

_Add a brief description of the feature or functionality that is deprecated. Clearly state the potential impact of the deprecation to end users._

#### Documentation

- Deprecation notice: [add link](here)
- Migration guidelines: [add link](here)
- etc.

#### Product Usage

_Describe why deprecation of this feature is necessary, ideally with dashboards/metrics that show product usage._
[add links to the documentation](here)

<!--
The description of the deprecation should state what actions the user should take to rectify the behavior. If the deprecation is scheduled for an upcoming release, the content should remain in the deprecations documentation page until it has been completed. For example, if a deprecation is announced in 14.9 and scheduled to be completed in 15.0, the same content would be included in the documentation for 14.9, 14.10, and 15.0.

**If this issue proposes a breaking change outside a major release XX.0, you need to get approval from your manager and request collaboration from Product Operations on communication. Be sure to follow the guidance**:

- https://docs.gitlab.com/ee/development/deprecation_guidelines/#requesting-a-breaking-change-in-a-minor-release
-->

### Breaking Change?

<!-- Does this MR contain a breaking change? If yes:
- Add the ~"breaking change" label to this issue.
- Add instructions for how users can update their workflow. -->

<!--
/label ~"breaking change"
-->

### Affected Customers

<!--
Who is affected by this deprecation, Self-managed users, SaaS users, or both? This is especially important when nearing the annual major release where breaking changes and removals are typically introduced. These changes might be seen on GitLab.com before the official release date.
-->

- [ ] GitLab.com
- [ ] Self-managed
- [ ] Dedicated

<!--
After creating the issue, add an Internal Note to discuss customer impact, using this template:

| Tier     | Number of Customers Impacted |
| -------- | ---------------------------- |
| Free     |                              |
| Premium  |                              |
| Ultimate |                              |
-->

<!-- Choose the Pricing Tier(s)
/label  ~"GitLab Free" ~"GitLab Premium" ~"GitLab Ultimate"
 -->

### Deprecation Milestone

<!-- In which milestone will this deprecation be announced? -->

### Planned Removal Milestone

<!-- In which milestone will the feature or functionality be removed? -->

### Links

<!--
Add links to any relevant documentation or code that will provide additional details or clarity regarding the planned change.

This issue is the main SSOT for the deprecations and removals process. Be sure to link all
issues and MRs related to this deprecation/removal to this issue. This can include removal
issues that were created ahead of time, and the MRs doing the actual deprecation/removal work.
-->

### Checklists

#### Timeline

##### Rollout Plan

**DRIs:**

- Engineers: `@engineer(s)`
- Engineering Manager: `@EM`

- [ ] Describe rollout plans on GitLab.com
   - [ ] _Link to [a feature flag rollout issue](https://gitlab.com/gitlab-org/gitlab/-/blob/master/.gitlab/issue_templates/Feature%20Flag%20Roll%20Out.md
)_ that covers:
     - [ ] Expected release date on GitLab.com and GitLab version
     - [ ] Rollout timelines, such as a percentage rollout on GitLab.com
     - [ ] Creation of any clean-up issues, such as code removal
- [ ] Determine how to migrate users still using the existing functionality
- [ ] Document ways to migrate with the tooling available
- [ ] Automate any users who have not yet migrated, but ensure it's a two-way door decision

##### Communication Plan

**DRIs:**

- Product Manager: `@PM`

_Add links to the relevant merge requests._

- As soon as possible, but no later than the third milestone preceding the major release (for example, given the following release schedule: `17.8, 17.9, 17.10, 17.11, 18.0` – `17.9` is the third milestone preceding the major release):
    - [ ] A [deprecation announcement entry](https://about.gitlab.com/handbook/marketing/blog/release-posts/#creating-the-announcement) has been created so the deprecation will appear in release posts and on the [general deprecation page](https://docs.gitlab.com/ee/update/deprecations).
    - [ ] Documentation has been updated to mark the feature as [deprecated](https://docs.gitlab.com/ee/development/documentation/versions.html#deprecations-and-removals).
- On the major milestone:
    - [ ] The deprecated item has been removed.
    - [ ] If the removal of the deprecated item is a [breaking change](https://docs.gitlab.com/ee/update/terminology.html#breaking-change), the merge request is labeled ~"breaking change".
    - [ ] Document the migration plan for users, clearly outlining the actions they need to take to mitigate the impact of the breaking change.
       - [ ] [Add link](here)

#### Development

**DRIs:**

- Engineers: `@engineer(s)`
- Engineering Manager: `@EM`

- [ ] Measure usage of the impacted product feature
   - [ ] Evaluate metrics across **GitLab.com, Self-Managed, Dedicated**
   - [ ] _add issue link_
   - [ ] _list any metrics and/or dashboards_
- [ ] Create tooling for customers to manually migrate their data or workflows
   - [ ] _add issue link_
- [ ] Build mechanism for users to manually enable the breaking change ahead of time
   - [ ] _add issue link_
- [ ] Automate the migration for those who do not take any manual steps (ensure the automation can be reverted)
   - [ ] _add issue link_
- [ ] Develop rollout plan of breaking change on GitLab.com
   - [ ] _add feature flag rollout issue_
- [ ] Dogfood the changes on GitLab.com or a Self-Managed test instance
   - [ ] _add issue link_
- [ ] (Optional) Create UI controls for instance admins to disable the breaking change, providing flexibility to Self-Managed / Dedicated customers. Optional as this depends on the breaking change.
   - [ ] _add issue link_

#### Approvals

- [ ] Product Manager `@PM`
- [ ] Engineering Manager `@EM`
- [ ] Senior Engineering Manager / Director `@senior-eng-leader`
- [ ] Group / Director of Product Management `@senior-product-leader`

#### Mentions (as applicable)

- [ ] Product Designer `@ProductDesigner`
- [ ] Tech Writer `@TW`
- [ ] Software Engineering in Test `@SET`
- [ ] Any other stable counterparts based on the [product categories](https://handbook.gitlab.com/handbook/product/categories/):
     - [ ] Add Sales/CS counterpart or mention `@timtams`
     - [ ] Add Support counterpart or mention `@gitlab-com/support/managers`
     - [ ] Add Marketing counterpart or mention `@cfoster3`

#### Labels

<!-- Populate the Section, Group, and Category -->
/label ~devops:: ~group: ~"Category:

/label ~"awaiting-pm-approval" ~"awaiting-em-approval" ~"awaiting-senior-eng-approval" ~"awaiting-senior-product-approval"

- [ ] This issue is labeled ~deprecation, and with the relevant `~devops::`, `~group::`, and `~Category:` labels.
- [ ] This issue is labeled  ~"breaking change" if the removal of the deprecated item will be a [breaking change](https://docs.gitlab.com/ee/update/terminology.html#breaking-change).


<!-- Label reminders - you should have one of each of the following labels.
Use the following resources to find the appropriate labels:
- https://gitlab.com/gitlab-org/gitlab/-/labels
- https://about.gitlab.com/handbook/product/categories/features/
-->

<!-- Identifies that this Issue is related to deprecating a feature -->
/label ~"deprecation"

### References

- [Deprecations, removals, and breaking changes](https://handbook.gitlab.com/handbook/marketing/blog/release-posts/#deprecations-removals-and-breaking-changes)
- [Deprecation guidelines](https://docs.gitlab.com/ee/development/deprecation_guidelines/)
- [Deprecations and removals doc styleguide](https://docs.gitlab.com/ee/development/documentation/styleguide/deprecations_and_removals)
- [REST API Deprecations](https://docs.gitlab.com/ee/development/documentation/restful_api_styleguide.html#deprecations) and [REST API breaking changes](https://docs.gitlab.com/ee/development/api_styleguide.html#breaking-changes).
- [GraphQL Deprecations](https://docs.gitlab.com/ee/development/api_graphql_styleguide.html#deprecating-schema-items) and [GraphQL API breaking changes](https://docs.gitlab.com/ee/development/api_graphql_styleguide.html#breaking-changes).
- [GitLab release and maintenance policy](https://docs.gitlab.com/ee/policy/maintenance.html)
- Videos 📺
   - [How to deprecate and remove features in GitLab releases](https://youtu.be/9gy7tg94j7s)
   - [Review of GitLab deprecations and removals policy & Runner team deprecations and removals process](https://youtu.be/ehT1xBajCRI)
