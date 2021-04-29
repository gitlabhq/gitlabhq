<!-- Follow the documentation workflow https://docs.gitlab.com/ee/development/documentation/workflow.html -->
<!-- Additional information is located at https://docs.gitlab.com/ee/development/documentation/ -->
<!-- To find the designated Tech Writer for the stage/group, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#designated-technical-writers -->

<!-- Mention "documentation" or "docs" in the MR title -->
<!-- For changing documentation location use the "Change documentation location" template -->

## What does this MR do?

<!-- Briefly describe what this MR is about. -->

## Related issues

<!-- Link related issues below. -->

## Author's checklist (required)

- [ ] Follow the [Documentation Guidelines](https://docs.gitlab.com/ee/development/documentation/) and [Style Guide](https://docs.gitlab.com/ee/development/documentation/styleguide/).
- If you have **Developer** permissions or higher:
  - [ ] Ensure that the [product tier badge](https://docs.gitlab.com/ee/development/documentation/styleguide/index.html#product-tier-badges) is added to doc's `h1`.
  - [ ] Apply the ~documentation label, plus:
    - The corresponding DevOps stage and group labels, if applicable.
    - ~"development guidelines" when changing docs under `doc/development/*`, `CONTRIBUTING.md`, or `README.md`.
    - ~"development guidelines" and ~"Documentation guidelines" when changing docs under `development/documentation/*`.
    - ~"development guidelines" and ~"Description templates (.gitlab/\*)" when creating/updating issue and MR description templates.
  - [ ] [Request a review](https://docs.gitlab.com/ee/development/code_review.html#dogfooding-the-reviewers-feature)
        from the [designated Technical Writer](https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments).

/label ~documentation
/assign me

Do not add the ~"feature", ~"frontend", ~"backend", ~"bug", or ~"database" labels if you are only updating documentation. These labels will cause the MR to be added to code verification QA issues.

When applicable:

- [ ] Update the [permissions table](https://docs.gitlab.com/ee/user/permissions.html).
- [ ] Link docs to and from the higher-level index page, plus other related docs where helpful.
- [ ] Add the [product tier badge](https://docs.gitlab.com/ee/development/documentation/styleguide/index.html#product-tier-badges) accordingly.
- [ ] Add [GitLab's version history note(s)](https://docs.gitlab.com/ee/development/documentation/styleguide/index.html#gitlab-versions).
- [ ] Add/update the [feature flag section](https://docs.gitlab.com/ee/development/documentation/feature_flags.html).

## Review checklist

All reviewers can help ensure accuracy, clarity, completeness, and adherence to the [Documentation Guidelines](https://docs.gitlab.com/ee/development/documentation/) and [Style Guide](https://docs.gitlab.com/ee/development/documentation/styleguide/).

**1. Primary Reviewer**

* [ ] Review by a code reviewer or other selected colleague to confirm accuracy, clarity, and completeness. This can be skipped for minor fixes without substantive content changes.

**2. Technical Writer**

- [ ] Technical writer review. If not requested for this MR, must be scheduled post-merge. To request for this MR, assign the writer listed for the applicable [DevOps stage](https://about.gitlab.com/handbook/product/categories/#devops-stages).
  - [ ] Ensure docs metadata are present and up-to-date.
  - [ ] Ensure ~"Technical Writing" and ~"documentation" are added.
  - [ ] Add the corresponding `docs::` [scoped label](https://gitlab.com/groups/gitlab-org/-/labels?utf8=%E2%9C%93&subscribed=&search=docs%3A%3A).
  - [ ] If working on UI text, add the corresponding `UI Text` [scoped label](https://gitlab.com/groups/gitlab-org/-/labels?utf8=%E2%9C%93&subscribed=&search=ui+text).
  - [ ] Add ~"tw::doing" when starting work on the MR.
  - [ ] Add ~"tw::finished" if Technical Writing team work on the MR is complete but it remains open.

For more information about labels, see [Technical Writing workflows - Labels](https://about.gitlab.com/handbook/engineering/ux/technical-writing/workflow/#labels).

For suggestions that you are confident don't need to be reviewed, change them locally
and push a commit directly to save others from unneeded reviews. For example:

- Clear typos, like `this is a typpo`.
- Minor issues, like single quotes instead of double quotes, Oxford commas, and periods.

For more information, see our documentation on [Merging a merge request](https://docs.gitlab.com/ee/development/code_review.html#merging-a-merge-request).

**3. Maintainer**

1. [ ] Review by assigned maintainer, who can always request/require the above reviews. Maintainer's review can occur before or after a technical writer review.
1. [ ] Ensure a release milestone is set.
1. [ ] If there has not been a technical writer review, [create an issue for one using the Doc Review template](https://gitlab.com/gitlab-org/gitlab/issues/new?issuable_template=Doc%20Review).
