# Documentation process

The process for creating and maintaining GitLab product documentation depends on whether the
documentation is associated with:

- [A new feature or feature enhancement](#for-a-product-change).

  Delivered for a specific milestone and associated with specific code changes. This documentation
  has the highest priority.

- [Changes outside a specific milestone](#for-all-other-documentation).

  It is usually not associated with a specific code change and has a lower priority.

Documentation is not usually required when a "backstage feature" is added or changed, and does not
directly affect the way that any user or administrator interacts with GitLab.

## Documentation labels

Regardless of the type of issue or merge request, certain labels are required when documentation
is added or updated. The following are added by the issue or merge request author:

- An appropriate [type label](../contributing/issue_workflow.md#type-labels). For example,
  `~backstage`.
- The [stage label](../contributing/issue_workflow.md#stage-labels) and
  [group label](../contributing/issue_workflow.md#group-labels). For example, `~devops::create` and
  `~group::source code`.
- The `~documentation` [specialization label](../contributing/issue_workflow.md#specialization-labels).

The following are also added by members of the Technical Writing team:

- A documentation [scoped label](../../user/project/labels.md#scoped-labels-premium) with the
  `docs::` prefix. For example, `~docs::improvement`.
- The `~Technical Writing` [team label](../contributing/issue_workflow.md#team-labels).

## For a product change

This documentation is required for any new or changed feature and is:

- Created or updated as part of feature development, almost always in the same merge request as the
  feature code. Including documentation in the same merge request as the code eliminates the
  possibility that code and documentation get out of sync.
- Required with the delivery of a feature for a specific milestone as part of GitLab's
  [definition of done](../contributing/merge_request_workflow.md#definition-of-done).
- Often linked from the release post.

### Roles and responsibilities

Documentation for specific milestones involves the:

- Developer of a feature or enhancement.
- Product Manager for the group delivering the new feature or feature enhancement.
- Technical Writer assigned to the group.

Each role is described below.

#### Developers

Developers are the primary author of documentation for a feature or feature enhancement. They are
responsible for:

- Developing initial content required for a feature.
- Liaising with their Product Manager to understand what documentation must be delivered, and when.
- Requesting technical reviews from other developers within their group.
- Requesting documentation reviews from the Technical Writer
  [assigned to the DevOps stage group](https://about.gitlab.com/handbook/product/technical-writing/index.html#assignments)
  that is delivering the new feature or feature enhancements.

TIP: **Tip:**
Community Contributors can ask for additional help from GitLab team members.

##### Authoring

Because the documentation is an essential part of the product, if a ~feature issue also contains the
~documentation label, you must ship the new or updated documentation with the code of the feature.

Technical Writers are happy to help, as requested and planned on an issue-by-issue basis.

For feature issues requiring documentation, follow the process below unless otherwise agreed with
the Product Manager and Technical Writer for a given issue:

- Include any new and edited documentation, either in:
  - The merge request introducing the code.
  - A separate merge request raised around the same time.
- Use the [documentation requirements](#documentation-requirements) developed by the Product Manager
  in the issue and discuss any further documentation plans or ideas as needed.

  If the new or changed documentation requires extensive collaboration or conversation, a
  separate, linked issue can be used for the planning process.

- Use the [Documentation guidelines](index.md), as well as other resources linked from there,
  including:
  - Documentation [Structure and template](structure.md) page.
  - [Style Guide](styleguide.md).
  - [Markdown Guide](https://about.gitlab.com/handbook/product/technical-writing/markdown-guide/).
- Contact the Technical Writer for the relevant [DevOps stage](https://about.gitlab.com/handbook/product/technical-writing/index.html#assignments)
  in your issue or merge request, or within `#docs` on GitLab Slack, if you:
  - Need any help to choose the correct place for documentation.
  - Want to discuss a documentation idea or outline.
  - Want to request any other help.
- If you are working on documentation in a separate merge request, ensure the documentation is
  merged as close as possible to the code merge.
- A policy for documenting [feature-flagged](../feature_flags/index.md) issues is forthcoming and you
  are welcome to join the [discussion](https://gitlab.com/gitlab-org/gitlab/issues/26347).

##### Reviews and merging

Reviewers help ensure:

- Accuracy.
- Clarity.
- Completeness.
- Adherence to:
  - [Documentation requirements](#documentation-requirements) in the issue.
  - [Documentation guidelines](index.md).
  - [Style guide](styleguide.md).

Prior to merging, documentation changes committed by the developer must be reviewed by:

- The code reviewer for the merge request. This is known as a technical review.
- Optionally, others involved in the work, such as other developers or the Product Manager.
- The Technical Writer for the DevOps stage group, except in exceptional circumstances where a
  [post-merge review](#post-merge-reviews) can be requested.
- A maintainer of the project.

#### Product Managers

Product Managers are responsible for the [documentation requirements](#documentation-requirements)
for a feature or feature enhancement. They can also:

- Liaise with the Technical Writer for discussion and collaboration.
- Review documentation themselves.

For issues requiring any new or updated documentation, the Product Manager must:

- Add the ~documentation label.
- Confirm or add the [documentation requirements](#documentation-requirements).
- Ensure the issue contains:
  - Any new or updated feature name.
  - Overview, description, and use cases, as required by the
    [documentation structure and template](structure.md), when applicable.

Everyone is encouraged to draft the documentation requirements in the issue, but a Product Manager
will do the following:

- When the issue is assigned a release milestone, review and update the Documentation details.
- By the kickoff, finalize the documentation details.

#### Technical Writers

Technical Writers are responsible for:

- Participating in issues discussions and reviewing MRs for the upcoming milestone.
- Reviewing documentation requirements in issues when called upon.
- Answering questions, and helping and providing advice throughout the authoring and editing
  process.
- Reviewing all significant new and updated documentation content, whether before merge or after it
  is merged.
- Assisting the developer and Product Manager with feature documentation delivery.

##### Planning

The Technical Writer:

- Reviews their group's `~feature` issues that are part of the next milestone to get a sense of the
  scope of content likely to be authored.
- Recommends the `~documentation` label on issues from that list which don't have it but should, or
  inquires with the PM to determine if documentation is truly required.
- For `~direction` issues from that list, reads the full issue and reviews its Documentation
  requirements section. Addresses any recommendations or questions with the PMs and others
  collaborating on the issue in order to refine or expand the Documentation requirements.

##### Collaboration

By default, the developer will work on documentation changes independently, but
the developer, Product Manager, or Technical Writer can propose a broader collaboration for
any given issue.

Additionally, Technical Writers are available for questions at any time.

##### Review

Technical Writers:

- Provide non-blocking reviews of all documentation changes, before or after the change is merged.
- Confirm that the documentation is:
  - Clear.
  - Grammatically correct.
  - Discoverable.
  - Navigable.
- Ensures that the documentation avoids:
  - Redundancy.
  - Bad file locations.
  - Typos.
  - Broken links.

The Technical Writer will review the documentation to check that the developer and
code reviewer have ensured:

- Clarity.
- Appropriate location, making sure the documentation is in the correct directories (often
  reflecting how the product is structured) and has the correct name.
- Syntax, typos, and broken links.
- Improvements to the content.
- Accordance with the:
  - [Documentation Style Guide](styleguide.md).
  - [Structure and Template](structure.md) doc.

### When documentation is required

Documentation [is required](../contributing/merge_request_workflow.html#definition-of-done) for a
milestone when:

- A new or enhanced feature is shipped that impacts the user or administrator experience.
- There are changes to the UI or API.
- A process, workflow, or previously documented feature is changed.
- A feature is deprecated or removed.

NOTE: **Note:**
Documentation refactoring unrelated to a feature change is covered in the
[other process](#for-all-other-documentation), so that time-sensitive documentation updates are
prioritized.

### Documentation requirements

Requirements for the documentation of a feature should be included as part of the
issue for planning that feature in a **Documentation** section within the issue description. Issues
created using the [**Feature Proposal** template](https://gitlab.com/gitlab-org/gitlab/raw/master/.gitlab/issue_templates/Feature%20proposal.md)
have this section by default.

Anyone can add these details, but the Product Manager who assigns the issue to a specific release
milestone will ensure these details are present and finalized by the time of that milestone's kickoff.

Developers, Technical Writers, and others may help further refine this plan at any time on request.

The following details should be included:

- What concepts and procedures should the documentation guide and enable the user to understand or
  accomplish?
- To this end, what new page(s) are needed, if any? What pages or subsections need updates?
  Consider user, admin, and API documentation changes and additions.
- For any guide or instruction set, should it help address a single use case, or be flexible to
  address a certain range of use cases?
- Do we need to update a previously recommended workflow? Should we link the new feature from
  various relevant locations? Consider all ways documentation should be affected.
- Are there any key terms or task descriptions that should be included so that the documentation is
  found in relevant searches?
- Include suggested titles of any pages or subsection headings, if applicable.
- List any documentation that should be cross-linked, if applicable.

## For all other documentation

These documentation changes are not associated with the release of a new or updated feature, and are
therefore labeled `backstage` in GitLab, rather than `feature`. They may include:

- Documentation created or updated to improve accuracy, completeness, ease of use, or any reason
  other than a [feature change](#for-a-product-change).
- Addressing gaps in existing documentation, or making improvements to existing documentation.
- Work on special projects related to the documentation.

TIP: **Tip:**
Anyone can contribute a merge request or create an issue for GitLab's documentation.

### Who updates the docs

Anyone can contribute! You can create a merge request for documentation when:

- You find errors or other room for improvement in existing documentation.
- You have an idea for all-new documentation that would help a GitLab user or administrator to
  accomplish their work with GitLab.

### How to update the docs

To update GitLab documentation:

1. Either:
   - Click the **Edit this Page** link at the bottom of any page on <https://docs.gitlab.com>.
   - Navigate to one of the repositories and documentation paths listed on the
     [GitLab Documentation guidelines](index.md) page.
1. Follow the described standards and processes listed on the page, including:
   - The [Structure and template](structure.md) page.
   - The [Style Guide](styleguide.md).
   - The [Markdown Guide](https://about.gitlab.com/handbook/product/technical-writing/markdown-guide/).
1. Follow GitLab's [Merge Request Guidelines](../contributing/merge_request_workflow.md#merge-request-guidelines).

TIP: **Tip:**
Work in a fork if you do not have developer access to the GitLab project.

Request help from the Technical Writing team if you:

- Need help to choose the correct place for documentation.
- Want to discuss a documentation idea or outline.
- Want to request any other help.

To request help:

1. Locate the the Technical Writer for the relevant
   [DevOps stage group](https://about.gitlab.com/handbook/product/technical-writing/index.html#assignments).
1. Either:
   - If urgent help is required, directly assign the Technical Writer in the issue or in the merge request.
   - If non-urgent help is required, ping the Technical Writer in the issue or merge request.

If you are a member of GitLab's Slack workspace, you can request help in `#docs`.

### Reviewing and merging

Anyone with Maintainer access to the relevant GitLab project can merge documentation changes.
Maintainers must make a good-faith effort to ensure that the content:

- Is clear and sufficiently easy for the intended audience to navigate and understand.
- Meets the [Documentation Guidelines](index.md) and [Style Guide](styleguide.md).

If the author or reviewer has any questions, they can mention the writer who is assigned to the relevant
[DevOps stage group](https://about.gitlab.com/handbook/product/technical-writing/index.html#assignments).

The process involves the following:

- Primary Reviewer. Review by a [code reviewer](https://about.gitlab.com/handbook/engineering/projects/)
  or other appropriate colleague to confirm accuracy, clarity, and completeness. This can be skipped
  for minor fixes without substantive content changes.
- Technical Writer (Optional). If not completed for a merge request prior to merging, must be scheduled
  post-merge. Schedule post-merge reviews only if an urgent merge is required. To request a:
  - Pre-merge review, assign the Technical Writer listed for the applicable
    [DevOps stage group](https://about.gitlab.com/handbook/product/technical-writing/index.html#assignments).
  - Post-merge review, see [Post-merge reviews](#post-merge-reviews).
- Maintainer. For merge requests, Maintainers:
  - Can always request any of the above reviews.
  - Review before or after a Technical Writer review.
  - Ensure the given release milestone is set.
  - Ensure the appropriate labels are applied, including any required to pick a merge request into
    a release.
  - Ensure that, if there has not been a Technical Writer review completed or scheduled, they
    [create the required issue](https://gitlab.com/gitlab-org/gitlab/issues/new?issuable_template=Doc%20Review), assign to the Technical Writer of the given stage group,
    and link it from the merge request.

The process is reflected in the **Documentation**
[merge request template](https://gitlab.com/gitlab-org/gitlab/blob/master/.gitlab/merge_request_templates/Documentation.md).

### Other ways to help

If you have ideas for further documentation resources please
[create an issue](https://gitlab.com/gitlab-org/gitlab/issues/new?issuable_template=Documentation)
using the Documentation template.

## Post-merge reviews

If not assigned to a Technical Writer for review prior to merging, a review must be scheduled
immediately after merge by the developer or maintainer. For this,
create an issue using the [Doc Review description template](https://gitlab.com/gitlab-org/gitlab/issues/new?issuable_template=Doc%20Review)
and link to it from the merged merge request that introduced the documentation change.

Circumstances where a regular pre-merge Technical Writer review might be skipped include:

- There is a short amount of time left before the milestone release. If there are less than three days
  remaining, seek a post-merge review and ping the writer via Slack to ensure the review is
  completed as soon as possible.
- The size of the change is small and you have a high degree of confidence
  that early users of the feature (for example, GitLab.com users) can easily
  use the documentation as written.

Remember:

- At GitLab, we treat documentation like code. As with code, documentation must be reviewed to
  ensure quality.
- Documentation forms part of the GitLab [definition of done](../contributing/merge_request_workflow.md#definition-of-done).
- That pre-merge Technical Writer reviews should be most common when the code is complete well in
  advance of a milestone release and for larger documentation changes.
- You can request a post-merge Technical Writer review of documentation if it's important to get the
  code with which it ships merged as soon as possible. In this case, the author of the original MR
  will address the feedback provided by the Technical Writer in a follow-up MR.
- The Technical Writer can also help decide that documentation can be merged without Technical
  writer review, with the review to occur soon after merge.

### Before merging

Ensure the following if skipping an initial Technical Writer review:

- That [product badges](styleguide.md#product-badges) are applied.
- That the GitLab [version](styleguide.md#text-for-documentation-requiring-version-text) that
  introduced the feature has been included.
- That changes to headings don't affect in-app hyperlinks.
- Specific [user permissions](../../user/permissions.md) are documented.
- That new documents are linked from higher-level indexes, for discoverability.
- Style guide is followed:
  - For [directories and files](styleguide.md#working-with-directories-and-files).
  - For [images](styleguide.md#images).

NOTE: **Note:**
Merge requests that change the location of documentation must always be reviewed by a Technical
Writer prior to merging.
