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
  docs content, whether before or after it is merged.

Beyond this process, any member of the GitLab community can also author or request documentation
improvements that are not associated with a new or changed feature. See the [Documentation improvement workflow](improvement-workflow.md).

## When documentation is required

Documentation must be delivered whenever:

- A new or enhanced feature is shipped that impacts the user/admin experience.
- There are changes to the UI or API.
- A process, workflow, or previously documented feature is changed.
- A feature is deprecated or removed.

For example, a UI restyling that offers no difference in functionality may require
documentation updates if screenshots are now needed, or need to be updated.

Documentation is not required when a feature is changed on the backend
only and does not directly affect the way that any user or administrator would
interact with GitLab.

NOTE: **Note:**
When revamping documentation, if unrelated to the feature change, this should be submitted
in its own MR (using the [documentation improvement workflow](improvement-workflow.md))
so that we can ensure the more time-sensitive doc updates are merged with code by the freeze.

## Documentation requirements in feature issues

Requirements for the documentation of a feature should be included as part of the
issue for planning that feature, in a Documentation section within the issue description.

This section is provided as part of the Feature Proposal template and should be added
to the issue if it is not already present.

Anyone can add these details, but the product manager who assigns the issue to a specific release
milestone will ensure these details are present and finalized by the time of that milestone's kickoff.
Developers, technical writers, and others may help further refine this plan at any time.

### Details to include

- What concepts and procedures should the docs guide and enable the user to understand or accomplish?
- To this end, what new page(s) are needed, if any? What pages/subsections need updates? Consider user, admin, and API doc changes and additions.
- For any guide or instruction set, should it help address a single use case, or be flexible to address a certain range of use cases?
- Do we need to update a previously recommended workflow? Should we link the new feature from various relevant locations? Consider all ways documentation should be affected.
- Are there any key terms or task descriptions that should be included so that the docs are found in relevant searches?
- Include suggested titles of any pages or subsections, if applicable.

## Documenting a new or changed feature

To follow a consistent workflow every month, documentation changes
involve the Product Managers, the developer who shipped the feature,
and the technical writer for the DevOps stage. Each role is described below.

The Documentation items in the GitLab CE/EE [Feature Proposal issue template](https://gitlab.com/gitlab-org/gitlab-ce/raw/template-improvements-for-documentation/.gitlab/issue_templates/Feature%20proposal.md)
and default merge request template will assist you with following this process.

### Product Manager role

For issues requiring any new or updated documentation, the Product Manager (PM)
must:

- Add the `Documentation` label.
- Confirm or add the [documentation requirements](#documentation-requirements-in-feature-issues).
- Ensure the issue contains any new or updated feature name, overview/description,
  and use cases, as required per the [documentation structure and template](structure.md), when applicable.

Everyone is encouraged to draft the requirements in the issue, but a product manager will
do the following:

- When the issue is assigned a release milestone, review and update the Documentation details.
- By the kickoff, finalize the Documentation details.

### Developer and maintainer roles

#### Authoring

As a developer, you must ship the documentation with the code of the feature that
you are creating or updating. The documentation is an essential part of the product.
Technical writers are happy to help, as requested and planned on an issue-by-issue basis.

Follow the process below unless otherwise agreed with the product manager and technical writer for a given issue:

- Include any new and edited docs in the MR introducing the code.
- Use the Documentation requirements confirmed by the Product Manager in the
  issue and discuss any further doc plans or ideas as needed.
  - If the new or changed doc requires extensive collaboration or conversation, a separate,
  linked issue can be used for the planning process.
  - We are trying to avoid using a separate MR, so that the docs stay with the code, but the
  Technical Writing team is interested in discussing any potential exceptions that may be suggested.
- Use the [Documentation guidelines](index.md), as well as other resources linked from there,
  including the Documentation [Structure and template](structure.md) page, [Style Guide](styleguide.md), and [Markdown Guide](https://about.gitlab.com/handbook/product/technical-writing/markdown-guide/).
- If you need any help to choose the correct place for a doc, discuss a documentation
  idea or outline, or request any other help, ping the Technical Writer for the relevant
  [DevOps stage](https://about.gitlab.com/handbook/product/categories/#devops-stages)
  in your issue or MR, or write within `#docs` on the GitLab Slack.
- The docs must be merged with the code **by the feature freeze date**, otherwise
  the feature cannot be included with the release. A policy for documenting feature-flagged
  issues is forthcoming and you are welcome to join the [discussion](https://gitlab.com/gitlab-org/gitlab-ce/issues/56813).

#### Reviews and merging

All reviewers can help ensure accuracy, clarity, completeness, and adherence to the plans in the issue, as well as the [Documentation Guidelines](index.md) and [Style Guide](styleguide.md).

- **Prior to merging**, documentation changes committed by the developer must be reviewed by:

  1. **The code reviewer** for the MR, to confirm accuracy, clarity, and completeness.
  1. Optionally: Others involved in the work, such as other devs or the PM.
  1. Optionally: The technical writer for the DevOps stage. If not prior to merging, the technical writer will review after the merge.
     This helps us ensure that the developer has time to merge good content by the freeze, and that it can be further refined by the release, if needed.
     - To decide whether to request this review before the merge, consider the amount of time left before the code freeze, the size of the change,
       and your degree of confidence in having users of an RC use your docs as written.
     - Pre-merge tech writer reviews should be most common when the code is complete well in advance of the freeze and/or for larger documentation changes.
     - You can request a review and if there is not sufficient time to complete it prior to the freeze,
       the maintainer can merge the current doc changes (if complete) and create a follow-up doc review issue.
     - The technical writer can also help decide what docs to merge before the freeze and whether to work on further changes in a follow up MR.
     - **To request a pre-merge technical writer review**, assign the writer listed for the applicable [DevOps stage](https://about.gitlab.com/handbook/product/categories/#devops-stages).
     - **To request a post-merge technical writer review**, [create an issue for one using the Doc Review template](https://gitlab.com/gitlab-org/gitlab-ce/issues/new?issuable_template=Doc%20Review) and link it from the MR that makes the doc change.
  1. **The maintainer** who is assigned to merge the MR, to verify clarity, completeness, and quality, to the best of their ability.

- Upon merging, if a technical writer review has not been performed and there is not yet a linked issue for a follow-up review, the maintainer should [create an issue using the Doc Review template](https://gitlab.com/gitlab-org/gitlab-ce/issues/new?issuable_template=Doc%20Review), link it from the MR, and
  mention the original MR author in the new issue. Alternatively, the maintainer can ask the MR author to create and link this issue before the MR is merged.

- After merging, documentation changes are reviewed by:

  1. The technical writer -- **if** their review was not performed prior to the merge.
  1. Optionally: by the PM (for accuracy and to ensure it's consistent with the vision for how the product will be used).
      Any party can raise the item to the PM for review at any point: the dev, the technical writer, or the PM, who can request/plan a review at the outset.

### Technical Writer role

#### Planning

- The technical writer monitors the documentation needs of issues assigned to the current and next milestone
  for their DevOps stage(s), and participates in any needed discussion on docs planning and requirements refinement
  with the dev, PM, and others.
- The technical writer will review these requirements again upon the kickoff and provide feedback, as needed.
  This is not a blocking review and developers should not wait to work on docs.

#### Collaboration

By default, the developer will work on documentation changes independently, but
the developer, PM, or technical writer can propose a broader collaboration for
any given issue.

Additionally, technical writers are available for questions at any time.

#### Review

- Technical writers provide non-blocking reviews of all documentation changes,
  before or after the change is merged. However, if the docs are ready in the MR while
  there's time before the freeze, the technical writer's review can commence early, on request.
- The technical writer will confirm that the doc is clear, grammatically correct,
  and discoverable, while avoiding redundancy, bad file locations, typos, broken links,
  etc. The technical writer will review the documentation for the following, which
  the developer and code reviewer should have already made a good-faith effort to ensure:
  - Clarity.
  - Adherence to the plans and goals in the issue.
  - Location (make sure the docs are in the correct directories and has the correct name).
  - Syntax, typos, and broken links.
  - Improvements to the content.
  - Accordance with the [Documentation Style Guide](styleguide.md), and [Structure and Template](structure.md) doc.
