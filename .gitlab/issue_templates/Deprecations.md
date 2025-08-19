<!-- Use this template as a starting point for deprecations. -->
<!-- For guidance on the overall deprecations, removals and breaking changes workflow, please visit [Breaking changes, deprecations, and removing features](https://docs.gitlab.com/development/deprecation_guidelines/). -->

**A written process alone is unlikely to be sufficient to navigate through the complexity of how customers use GitLab. Please use this template as guidance with steps to take when deprecating GitLab functionality, but not as an exhaustive list designed to generate positive outcomes every time. Deprecations are often nuanced in their impact and the approach needed may not be fully covered in this template. Each team must be accountable for their deprecation, weighing the positives and negatives to ensure we prioritize results for customers.**

---
Only create this issue once you have received leadership approval on your breaking change request, as outlined [here](https://docs.gitlab.com/development/deprecation_guidelines/).

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

-->

### Breaking Change?
<!-- If the change includes removing functionality, which nearly all deprecations do, then it needs to be tracked as a breaking change. If user workflows rely on it to function, then removing it will break them. -->

Does this deprecation contain a breaking change? ```Yes / No```

<!-- If yes:
- Add the ~"breaking change" label to this issue.
- Add instructions for how users can update their workflow.
 -->

<!--
/label ~"breaking change"
-->

### Affected Customers

Who is affected by this deprecation: GitLab.com users, Self-managed users, or Dedicated users? (choose all that apply)

- [ ] GitLab.com
- [ ] Self-managed
- [ ] Dedicated

<!--
This is especially important when nearing the annual major release where breaking changes and removals are typically introduced. These changes might be seen on GitLab.com before the official release date.
-->

What pricing tiers are impacted?
- [ ] GitLab Free
- [ ] GitLab Premium
- [ ] GitLab Ultimate

<!-- Choose the Pricing Tier(s)
/label  ~"GitLab Free" ~"GitLab Premium" ~"GitLab Ultimate"
 -->


### Deprecation Milestone

This deprecation will be announced in milestone: ```xx.xx```
_If this deprecation has already been announced, include information about when the initial announcement went out and what follow-up announcements are scheduled._

### Planned Removal Milestone

The feature / functionality will be removed in milestone: ```xx.xx```


### Links

<!--
Add links to any relevant documentation or code that will provide additional details or clarity regarding the planned change.

This issue is the main SSOT for the deprecations and removals process. Be sure to link all
issues and MRs related to this deprecation/removal to this issue. This can include removal
issues that were created ahead of time, and the MRs doing the actual deprecation/removal work.
-->

### Checklists

#### Timeline

#### Rollout Plan

- DRI Engineers: `@engineer(s)`
- DRI Engineering Manager: `@EM`

- [ ] Describe rollout plans on GitLab.com
   - [ ] _Link to [a feature flag rollout issue](https://gitlab.com/gitlab-org/gitlab/-/blob/master/.gitlab/issue_templates/Feature%20Flag%20Roll%20Out.md
)_ that covers:
     - [ ] Expected release date on GitLab.com and GitLab version
     - [ ] Rollout timelines, such as a percentage rollout on GitLab.com
     - [ ] Creation of any clean-up issues, such as code removal
- [ ] Determine how to migrate users still using the existing functionality
- [ ] Document ways to migrate with the tooling available
- [ ] Automate any users who have not yet migrated, but ensure it's a two-way door decision

#### Communication Plan

- DRI Product Manager: `@PM`

An internal slack post and a release post are not sufficient notification for our customers or internal stakeholders. Plan to communicate proactively and directly with affected customers and the internal stakeholders supporting them.

**Internal Communication Plan**
This will have been documented in your [breaking change request](https://gitlab.com/gitlab-com/Product/-/issues/new?issuable_template=Breaking-Change-Exception). You can use this checklist to track completion of these items.
- [ ] [Support Preparedness issue](https://gitlab.com/gitlab-com/support/support-team-meta/-/blob/master/.gitlab/issue_templates/Support%20Preparedness.md?ref_type=heads) created
- [ ] Guidance for Engineering, Product, Security, Customer Success, and Sales created

**External Communication Plan**
This will have been documented in your [breaking change request](https://gitlab.com/gitlab-com/Product/-/issues/new?issuable_template=Breaking-Change-Exception). You can use this checklist to track completion of these items.
- [ ] Customer announcement plan (timeline for notifications, audience, channels, etc)
- [ ] Ensure you have approvals from legal and corp comms for any communication being sent directly to customers.
- [ ] As soon as possible, but no later than the third milestone preceding the major release, ensure that the following are complete (for example, given the following release schedule: `17.8, 17.9, 17.10, 17.11, 18.0` – `17.9` is the third milestone preceding the major release). 
    - [ ] A [deprecation announcement entry](https://about.gitlab.com/handbook/marketing/blog/release-posts/#creating-the-announcement) has been created so the deprecation will appear in release posts and on the [general deprecation page](https://docs.gitlab.com/ee/update/deprecations). _Add link to the relevant merge request._
    - [ ] Documentation has been updated to mark the feature as [deprecated](https://docs.gitlab.com/development/documentation/versions/#deprecations-and-removals).  _Add link to the relevant merge request._
- [ ] On the major milestone:
    - [ ] The deprecated item has been removed.  _Add link to the relevant merge request._
    - [ ] If the removal of the deprecated item is a [breaking change](https://docs.gitlab.com/update/terminology/#breaking-change), the merge request is labeled ~"breaking change".
    - [ ] Document the migration plan for users, clearly outlining the actions they need to take to mitigate the impact of the breaking change.
       - [ ] [Add link](here)

#### Development

- DRI Engineers: `@engineer(s)`
- DRI Engineering Manager: `@EM`

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

#### Stakeholder Mentions

- [ ] Product Designer `@ProductDesigner`
- [ ] Tech Writer `@TW`
- [ ] Software Engineering in Test `@SET`
- [ ] Any other stable counterparts based on the [product categories](https://handbook.gitlab.com/handbook/product/categories/):
     - [ ] Add Sales/CS counterpart or mention `@timtams`
     - [ ] Add Support counterpart or mention `@gitlab-com/support/managers`
     - [ ] Add Marketing counterpart or mention `@martin_klaus` 
     - [ ] Add Corp comms if direct customer comms are needed `@jmalleo`
     - [ ] Add Product Security counterpart, if relevant to your deprecation
     - [ ] Mention (in internal note) Customer Success Managers / Acount Managers / Solutions Architects for impacted customers 

#### Labels

<!-- Populate the Section, Group, and Category -->
/label ~devops:: ~group: ~"Category:

/label ~"awaiting-pm-approval" ~"awaiting-em-approval" ~"awaiting-senior-eng-approval" ~"awaiting-senior-product-approval"

- [ ] This issue is labeled ~deprecation, and with the relevant `~devops::`, `~group::`, and `~Category:` labels.
- [ ] This issue is labeled  ~"breaking change" if the removal of the deprecated item will be a [breaking change](https://docs.gitlab.com/update/terminology/#breaking-change).


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
- [REST API Deprecations](https://docs.gitlab.com/development/documentation/restful_api_styleguide/#deprecations) and [REST API breaking changes](https://docs.gitlab.com/development/api_styleguide/#breaking-changes).
- [GraphQL Deprecations](https://docs.gitlab.com/development/api_graphql_styleguide/#deprecating-schema-items) and [GraphQL API breaking changes](https://docs.gitlab.com/development/api_graphql_styleguide/#breaking-changes).
- [GitLab release and maintenance policy](https://docs.gitlab.com/policy/maintenance/)
- Videos 📺
   - [How to deprecate and remove features in GitLab releases](https://youtu.be/9gy7tg94j7s)
   - [Review of GitLab deprecations and removals policy & Runner team deprecations and removals process](https://youtu.be/ehT1xBajCRI)
