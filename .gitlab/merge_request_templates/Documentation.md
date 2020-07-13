<!-- Follow the documentation workflow https://docs.gitlab.com/ee/development/documentation/workflow.html -->
<!-- Additional information is located at https://docs.gitlab.com/ee/development/documentation/ -->
<!-- To find the designated Tech Writer for the stage/group, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#designated-technical-writers -->

<!-- Mention "documentation" or "docs" in the MR title -->
<!-- For changing documentation location use the "Change documentation location" template -->

## What does this MR do?

<!-- Briefly describe what this MR is about. -->

## Related issues

<!-- Link related issues below. Insert the issue link or reference after the word "Closes" if merging this should automatically close it. -->

## Author's checklist (required)

- [ ] Follow the [Documentation Guidelines](https://docs.gitlab.com/ee/development/documentation/) and [Style Guide](https://docs.gitlab.com/ee/development/documentation/styleguide.html).
- If you have `developer` access or higher (for example, GitLab team members or [Core Team](https://about.gitlab.com/community/core-team/) members)
  - [ ] Apply the ~documentation label, plus:
    - The corresponding DevOps stage and group label, if applicable.
    - ~"development guidelines" when changing docs under `doc/development/*`, `CONTRIBUTING.md`, or `README.md`.
    - ~"development guidelines" and ~"Documentation guidelines" when changing docs under `development/documentation/*`.
    - ~"development guidelines" and ~"Description templates (.gitlab/\*)" when creating/updating issue and MR description templates.
  - [ ] Assign the [designated Technical Writer](https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments).

Do not add the ~"feature", ~"frontend", ~"backend", ~"bug", or ~"database" labels if you are only updating documentation. These labels will cause the MR to be added to code verification QA issues.

When applicable:

- [ ] Update the [permissions table](https://docs.gitlab.com/ee/user/permissions.html).
- [ ] Link docs to and from the higher-level index page, plus other related docs where helpful.
- [ ] Add [GitLab's version history note(s)](https://docs.gitlab.com/ee/development/documentation/styleguide.html#text-for-documentation-requiring-version-text).
- [ ] Add the [product tier badge](https://docs.gitlab.com/ee/development/documentation/styleguide.html#product-badges).
- [ ] Add/update the [feature flag section](https://docs.gitlab.com/ee/development/documentation/feature_flags.html).
- [ ] If you're changing document headings, search `doc/*`, `app/views/*`, and `ee/app/views/*` for old headings replacing with the new ones to [avoid broken anchors](https://docs.gitlab.com/ee/development/documentation/styleguide.html#anchor-links).

## Review checklist

All reviewers can help ensure accuracy, clarity, completeness, and adherence to the [Documentation Guidelines](https://docs.gitlab.com/ee/development/documentation/) and [Style Guide](https://docs.gitlab.com/ee/development/documentation/styleguide.html).

**1. Primary Reviewer**

* [ ] Review by a code reviewer or other selected colleague to confirm accuracy, clarity, and completeness. This can be skipped for minor fixes without substantive content changes.

**2. Technical Writer**

- [ ] Technical writer review. If not requested for this MR, must be scheduled post-merge. To request for this MR, assign the writer listed for the applicable [DevOps stage](https://about.gitlab.com/handbook/product/product-categories/#devops-stages).
  - [ ] Ensure ~"Technical Writing", ~"documentation", and a `docs::` scoped label are added.
  - [ ] Add ~docs-only when the only files changed are under `doc/*`.
  - [ ] Add ~"tw::doing" when starting work on the MR.
  - [ ] Add ~"tw::finished" if Technical Writing team work on the MR is complete but it remains open.

**3. Maintainer**

1. [ ] Review by assigned maintainer, who can always request/require the above reviews. Maintainer's review can occur before or after a technical writer review.
1. [ ] Ensure a release milestone is set.
1. [ ] If there has not been a technical writer review, [create an issue for one using the Doc Review template](https://gitlab.com/gitlab-org/gitlab/issues/new?issuable_template=Doc%20Review).

/label ~documentation
