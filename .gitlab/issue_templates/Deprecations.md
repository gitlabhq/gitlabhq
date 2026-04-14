<!-- For guidance on navigating breaking changes at GitLab, please visit [this Breaking changes page](https://internal.gitlab.com/handbook/engineering/r-and-d-pmo/knowledge-base/all-articles/breaking-changes/). -->

---
Only create this issue once you have received **leadership approval** on your breaking change request, by following [this process](https://gitlab.com/gitlab-com/Product/-/blob/main/.gitlab/issue_templates/Breaking-Change-Exception.md?ref_type=heads).

### Deprecation Summary

_Add a brief description of the feature or functionality that is deprecated. Clearly state the potential impact of the deprecation to end users._

[Documentation on feature being deprecated](add-link-to-Docs-page-here)

#### Migration guidelines

Where a migration is applicable, document the steps customers should take and share the link here. [Migration documentation](add-link-here)

If an automated migration will be performed, document how and when.

#### Background

_Describe why deprecation of this feature is necessary._

### Breaking Change?
<!-- Any change counts as a breaking change if customers need to take action to ensure their GitLab workflows aren’t disrupted. -->

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

What pricing tiers are impacted?
- [ ] GitLab Free
- [ ] GitLab Premium
- [ ] GitLab Ultimate

<!-- Choose the Pricing Tier(s)
/label  ~"GitLab Free" ~"GitLab Premium" ~"GitLab Ultimate"
 -->

### Deprecation Milestone

This deprecation is being announced in milestone: ```xx.xx```

### Planned Removal Milestone

The feature / functionality will be removed in milestone: ```xx.xx```

#### Rollout Plan

- DRI Engineers: `@engineer(s)`
- DRI Engineering Manager: `@EM`

- [ ] Describe rollout plans on GitLab.com
   - [ ] _Link to [a feature flag rollout issue](https://gitlab.com/gitlab-org/gitlab/-/blob/master/.gitlab/issue_templates/Feature%20Flag%20Roll%20Out.md
   - [ ] Determine how to migrate users still using the existing functionality
)_ that covers:
     - [ ] Expected release date on GitLab.com and GitLab version
     - [ ] Rollout timelines, such as a percentage rollout on GitLab.com
     - [ ] Creation of any clean-up issues, such as code removal

#### Communication Plan

- DRI Product Manager: `@PM`

An internal slack post and a release post are not sufficient notification for our customers or internal stakeholders. Plan to communicate proactively and directly with affected customers and the internal stakeholders supporting them.

**Internal Communication Plan**
This will have been documented in your [breaking change request](https://gitlab.com/gitlab-com/Product/-/issues/new?issuable_template=Breaking-Change-Exception). You can use this checklist to track completion of these items.
- [ ] [Support Preparedness issue](https://gitlab.com/gitlab-com/support/support-team-meta/-/blob/master/.gitlab/issue_templates/Support%20Preparedness.md?ref_type=heads) created
- [ ] Guidance for Engineering, Product, Security, Customer Success, and Sales created

**External Communication Plan**
This will have been documented in your [breaking change request](https://gitlab.com/gitlab-com/Product/-/issues/new?issuable_template=Breaking-Change-Exception). You can use this checklist to track completion of these items.

- [ ] Customer announcement plan
    - [ ] Document the migration plan for users, clearly outlining the actions they need to take to mitigate the impact of the breaking change.
    - [ ] A [deprecation announcement entry](https://about.gitlab.com/handbook/marketing/blog/release-posts/#creating-the-announcement) has been created so the deprecation will appear in release posts and on the [general deprecation page](https://docs.gitlab.com/update/deprecations/). _Add link to the relevant merge request._
    - [ ] Documentation has been updated to mark the feature as [deprecated](https://docs.gitlab.com/development/documentation/versions/#deprecations-and-removals).  _Add link to the relevant merge request._
- [ ] On the major milestone:
    - [ ] The deprecated item has been removed.  _Add link to the relevant merge request._
    - [ ] If the removal of the deprecated item is a [breaking change](https://docs.gitlab.com/update/terminology/#breaking-change), the merge request is labeled ~"breaking change".

#### Labels

<!-- Populate the Section, Group, and Category -->
/label ~devops:: ~group: ~"Category:

- [ ] This issue is labeled ~deprecation, and with the relevant `~devops::`, `~group::`, and `~Category:` labels.
- [ ] This issue is labeled  ~"breaking change" if the removal of the deprecated item will be a [breaking change](https://docs.gitlab.com/update/terminology/#breaking-change).


<!-- Label reminders - you should have one of each of the following labels.
Use the following resources to find the appropriate labels:
- https://gitlab.com/gitlab-org/gitlab/-/labels
- https://about.gitlab.com/handbook/product/categories/features/
-->

<!-- Identifies that this Issue is related to deprecating a feature -->
/label ~"deprecation"

<!-- References

- [Internal Resource on Breaking Changes](https://internal.gitlab.com/handbook/engineering/r-and-d-pmo/knowledge-base/all-articles/breaking-changes/)
- [Public Resource on Deprecations, removals, and breaking changes](https://handbook.gitlab.com/handbook/marketing/blog/release-posts/#deprecations-removals-and-breaking-changes)
- [Deprecation guidelines](https://docs.gitlab.com/development/deprecation_guidelines/)
- [Deprecations and removals doc styleguide](https://docs.gitlab.com/development/documentation/styleguide/deprecations_and_removals/)
- [REST API Deprecations](https://docs.gitlab.com/development/documentation/restful_api_styleguide/#deprecations) and [REST API breaking changes](https://docs.gitlab.com/development/api_styleguide/#breaking-changes).
- [GraphQL Deprecations](https://docs.gitlab.com/development/api_graphql_styleguide/#deprecating-schema-items) and [GraphQL API breaking changes](https://docs.gitlab.com/development/api_graphql_styleguide/#breaking-changes).
- [GitLab release and maintenance policy](https://docs.gitlab.com/policy/maintenance/)
- [Review of GitLab deprecations and removals policy & Runner team deprecations and removals process](https://youtu.be/ehT1xBajCRI)
-->
