<!-- Set the correct label and milestone using autocomplete for guidance. Please @mention only the DRI(s) for each stage or group rather than an entire department. -->

/label ~"release post" ~"release post item" ~"Technical Writing" ~devops:: ~group:: ~"release post item::removal"
/label ~"type::maintenance" ~"maintenance::removal"
/milestone %
/assign `@EM/PM` (choose the DRI; remove backticks here, and below)

**Be sure to link this MR to the relevant issues.**

- Deprecation issue:
- Removal issue:
- MR that removed (or _will_ remove) the feature:

If there is no relevant deprecation issue, hit pause and:

- Review the [process for deprecating and removing features](https://about.gitlab.com/handbook/product/gitlab-the-product/#process-for-deprecating-and-removing-a-feature).
- Connect with the Product Manager DRI.

Removals must be [announced as deprecations](https://about.gitlab.com/handbook/marketing/blog/release-posts/#deprecations) at least 2 milestones in advance of the planned removal date.

If the removal creates a [breaking change](https://about.gitlab.com/handbook/product/gitlab-the-product/#deprecations-removals-and-breaking-changes), it can only be removed in a major "XX.0" release.

**By the 10th**: Assign this MR to these team members as reviewers, and for approval:

- Required:
  - Product Group Manager or Director: `@PM`
  - Engineering Manager: `@EM`
  - Technical writer: `@TW`
- Optional:
  - Product Designer(s): `@ProductDesigners`
  - Product Marketing: `@PMM`

**By 7:59 PM UTC 15th (11:59 AM PT)**: EM/PM assigns this MR to the TW reviewer for final review and merge: `@EM/PM`

**By 7:59 AM UTC 18th (11:59 PM PT 17th)**: TW Reviewer updates Docs by merging this MR to `master`: `@TW`

---

Please review:

- The definitions of ["Deprecation", "End of Support", and "Removal"](https://docs.gitlab.com/ee/development/deprecation_guidelines/#terminology).
- The [guidelines for removals](https://about.gitlab.com/handbook/marketing/blog/release-posts/#removals).

## EM/PM release post item checklist

- [ ] Set yourself as the Assignee, meaning you are the DRI.
- [ ] If the removal is a [breaking change](https://about.gitlab.com/handbook/product/gitlab-the-product/#breaking-change), add label `breaking change`.
- [ ] Follow the process to [create a removal YAML file](https://about.gitlab.com/handbook/marketing/blog/release-posts/#creating-a-removal-entry).
- [ ] Make sure that the milestone dates are based on the dates in [Product milestone creation](https://about.gitlab.com/handbook/product/milestones/#product-milestone-creation).
- [ ] Add reviewers by the 10th.
- [ ] When ready to be merged and not later than the 15th, add the ~ready label and @ message the TW for final review and merge.
  - Removal notices should not be merged before the code is removed from the product. Do not mark ~ready until the removal is complete, or you are certain it will be completed within the current milestone and released. If PMs are not sure, they should confirm with their Engineering Manager.

## Reviewers

When the content is ready for review, the Technical Writer and Engineering Manager _must_
review it. Optional reviewers can include Product Marketing, Product Design, and the Product Leaders
for this area. Use the
[reviewers](https://docs.gitlab.com/ee/user/project/merge_requests/reviews/)
feature for all reviews. Reviewers will `approve` the MR and remove themselves from the reviewers list when their review is complete.

- [ ] (Recommended) PMM
- [ ] (Optional) Product Designer
- [ ] (Optional) Group Manager or Director
- [ ] Required review and approval: [Technical Writer designated to the corresponding DevOps stage/group](https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments).

### Tech writer review

The TW should review according to the criteria listed below. Review a removal MR
with the same process as regular docs MRs. Add suggestions as needed, @ message
the PM to inform them the first review is complete, and remove
yourself as a reviewer if it's not yet ready for merge.

**Removal notices should not be merged before the code is removed from the product.**

<details>
<summary>Expand for Details</summary>

- [ ] Title:
  - Length limit: 7 words (not including articles or prepositions).
  - Capitalization: ensure the title is [sentence cased](https://design.gitlab.com/content/punctuation#case).
- [ ] Dates:
  - Make sure that the milestone dates are based on the dates in [Product milestone creation](https://about.gitlab.com/handbook/product/milestones/#product-milestone-creation).
- [ ] Consistency:
  - Ensure that all resources (docs, removal, etc.) refer to the feature with the same term / feature name.
- [ ] Content:
  - Make sure the removal is accurate based on your understanding. Look for typos or grammar mistakes. Work with PM and PMM to ensure a consistent GitLab style and tone for messaging, based on other features and removals.
  - Review use of whitespace and bullet lists. Will the removal item be easily scannable when published? Consider adding line breaks or breaking content into bullets if you have more than a few sentences.
  - Make sure there aren't acronyms readers may not understand per <https://about.gitlab.com/handbook/communication/#writing-style-guidelines>.
- [ ] Links:
  - All links must be full URLs, as the removal YAML files are used in multiple projects. Do not use relative links. The generated doc is an exception to the relative link rule and currently uses absolute links only.
  - Make sure all links and anchors are correct. Do not link to the H1 (top) anchor on a docs page.
- [ ] Code. Make sure any included code is wrapped in code blocks.
- [ ] Capitalization. Make sure to capitalize feature names. Stay consistent with the Documentation Style Guidance on [Capitalization](https://docs.gitlab.com/ee/development/documentation/styleguide.html#capitalization).
- [ ] Blank spaces. Remove unnecessary spaces (end of line spaces, double spaces, extra blank lines, and lines with only spaces).

</details>

When the PM indicates it is ready for merge and all issues have been addressed, start the merge process.

#### Technical writer merge process

The [removals doc's `.md` file](https://gitlab.com/gitlab-org/gitlab/blob/master/doc/update/removals.md)
must be updated before this MR is merged:

1. Check out the MR's branch (in the [`gitlab-org/gitlab`](https://gitlab.com/gitlab-org/gitlab) project).
1. From the command line (in the branch), run `bin/rake gitlab:docs:compile_removals`.
   If you want to double check that it worked, you can run `bin/rake gitlab:docs:check_removals`
   to verify that the doc is up to date.
1. Commit the updated file and push the changes.
1. Set the MR to merge when the pipeline succeeds (or merge if the pipeline is already complete).

If you have trouble running the rake task, check the [troubleshooting steps](https://about.gitlab.com/handbook/marketing/blog/release-posts/#deprecation-rake-task-troubleshooting).
