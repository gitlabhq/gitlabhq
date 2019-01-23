---
description: How to add docs for new or enhanced GitLab features.
---

# Documentation process for feature changes

At GitLab, developers contribute new or updated documentation along with their code, but product managers and technical writers also have essential roles in the process.

- **Developers**: Author/update documentation in the same MR as their code, and
merge it by the feature freeze for the assigned milestone. Request technical writer
assistance if needed. Other developers typically act as reviewers.
- **Product Managers** (PMs): In the issue for all new and enhanced features,
confirm the documentation requirements, plus the mentioned feature description
and use cases, which can be reused in docs. They can bring in a technical
writer for discussion or collaboration, and can be called upon themselves as a doc reviewer.
- **Technical Writers**: Review doc requirements in issues, track issues and MRs
that contain docs changes, help with any questions throughout the authoring/editing process,
work on special projects related to the documentation, and review all new and updated
docs content after it's merged (unless a pre-merge review request is made).

Beyond this process, any member of the GitLab community can also author or request documentation
improvements that are not associated with a new or changed feature. See the [Documentation improvement workflow](improvement-workflow.md).

## When documentation is required

Documentation must be delivered whenever:

- A new or enhanced feature is shipped that impacts the user/admin experience
- There are changes to the UI or API
- A process, workflow, or previously documented feature is changed
- A feature is deprecated or removed

Documentation is not required when a feature is changed on the backend
only and does not directly affect the way that any user or
administrator would interact with GitLab. For example, a UI restyling that offers
no difference in functionality may require documentation updates if screenshots
are now needed, or need to be updated.

NOTE: **Note:**
When revamping documentation, if unrelated to the feature change, this should be submitted
in its own MR (using the [documentation improvement workflow](improvement-workflow.md))
so that we can ensure the more time-sensitive doc updates are merged with code by the freeze.

## Documenting a new or changed feature

To follow a consistent workflow every month, documentation changes
involve the Product Managers, the developer who shipped the feature,
and the technical writer for the DevOps stage. Each role is described below.

The Documentation items in the GitLab CE/EE [Feature Proposal issue template](https://gitlab.com/gitlab-org/gitlab-ce/raw/template-improvements-for-documentation/.gitlab/issue_templates/Feature%20proposal.md)
and default merge request template will assist you with following this process.

### 1. Product Manager's role

The Product Manager (PM) should confirm or add the following items in the issue:

- New or updated feature name, overview/description, and use cases, all required per the [Documentation structure and template](structure.md) (if applicable).
- The documentation requirements for the developer working on the docs.
  - What should the docs guide and enable the user to understand and accomplish?
  - To this end, what new page(s) are needed, if any? What pages/subsections need updates? For any guide or instruction set, should it help address one or more use cases?
  - Consider user, admin, and API doc changes and additions. Consider whether we need to update a previously recommended workflow, or if we should link the new feature from various relevant places. Consider all ways documentation should be affected.
  - Include suggested titles of any pages or subsections, if applicable.
- Add the `Documentation` label to the issue.

Anyone is welcome to draft the items above in the issue, but a product manager must review and update any such content whenever the issue is assigned a specific milestone, and finalize this content by the kickoff. 

### 2. Developer roles

**Authoring**

As a developer, you must ship the documentation with the code of the feature that
you are creating or updating. The documentation is an essential part of the product.
Technical writers are happy to help, as requested and planned on an issue-by-issue basis.

- New and edited docs should be included in the MR introducing the code, and planned
in the issue that proposed the feature. However, if the new or changed doc requires
extensive collaboration or conversation, a separate, linked issue can be used for the planning process.
We are trying to avoid using a separate MR, so the docs stay with the code, but the
Technical Writing team is interested in discussing any potential exceptions that may be suggested.
- Use the [Documentation guidelines](index.md), as well as other resources linked from there,
including the Documentation [Structure and template](structure.md) page, [Style Guide](styleguide.md), and [Markdown Guide](https://about.gitlab.com/handbook/product/technical-writing/markdown-guide/). 
- If you need any help to choose the correct place for a doc, discuss a documentation
idea or outline, or request any other help, ping the Technical Writer for the relevant
[DevOps stage](https://about.gitlab.com/handbook/product/categories/#devops-stages)
in your issue or MR, or write within `#docs` on the GitLab Slack.
- The docs must be merged with the code **by the feature freeze date**, otherwise
the feature cannot be included with the release.<!-- TODO: Policy for feature-flagged issues -->

**Reviews and merging**

All reviewers can help ensure accuracy, clarity, completeness, and adherence to the plans in the issue, as well as the [Documentation Guidelines](https://docs.gitlab.com/ee/development/documentation/) and [Style Guide](https://docs.gitlab.com/ee/development/documentation/styleguide.html).

- Prior to merge, documentation changes committed by the developer must be reviewed by:
  1. **The code reviewer** for the MR, to confirm accuracy, clarity, and completeness.
  2. Optionally: Others involved in the work, such as other devs or the PM.
  3. Optionally: The technical writer for the DevOps stage. If not prior to merging, the technical writer will review after the merge.
This helps us ensure that the developer has time to merge good content by the freeze, and that it can be further refined by the release.
  4. **The maintainer** who is assigned to merge the MR, to verify clarity, completeness, and quality, to the best of their ability.

- Upon merging, if a technical writer review has not been performed, the maintainer should [create an issue using the Doc Review template](https://gitlab.com/gitlab-org/gitlab-ce/issues/new?issuable_template=Doc%20Review).

- After merging, documentation changes are reviewed by:
  1. The technical writer--**if** their review was not performed prior to the merge.
  2. Optionally: by the PM (for accuracy and to ensure it's consistent with the vision for how the product will be used).
Any party can raise the item to the PM for review at any point: the dev, the technical writer, or the PM, who can request/plan a review at the outset.

### 3. Technical Writer's role

**Planning**
- The technical writer monitors the documentation needs of issues assigned to the current and next milestone
for their DevOps stage(s), and participates in any needed discussion on docs planning
with the dev, PM, and others.
- The technical writer will review these again upon the kickoff and provide feedback, as needed.
This is not a blocking review and developers should not wait to work on docs.

**Review**
- Techncial writers provide non-blocking reviews of all documentation changes,
typically after the change is merged. However, if the docs are ready in the MR while
there's time before the freeze, the technical writer's review can commence early, on request.
- The technical writer will confirm that the doc is clear, grammatically correct,
and discoverable, while avoiding redundancy, bad file locations, typos, broken links,
etc. The technical writer will review the documentation for the following, which
the developer and code reviewer should have already made a good-faith effort to ensure:
  - Clarity.
  - Adherence to the plans and goals in the issue.
  - Location (make sure the docs are in the correct directorkes and has the correct name).
  - Syntax, typos, and broken links.
  - Improvements to the content.
  - Accordance with the [Documentation Style Guide](styleguide.md), and [Structure and Template](structure.md) doc.
