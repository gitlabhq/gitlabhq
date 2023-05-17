<!-- Set the correct label and milestone using autocomplete for guidance. Please @mention only the DRI(s) for each stage or group rather than an entire department. -->

**Be sure to link this MR to the relevant deprecation issue(s).**

- Deprecation Issue:

If there is no relevant deprecation issue, hit pause and:

- Review the [process for deprecating and removing features](https://about.gitlab.com/handbook/product/gitlab-the-product/#process-for-deprecating-and-removing-a-feature).
- Connect with the Product Manager DRI.

Deprecation announcements can and should be created and merged into Docs at any time, to optimize user awareness and planning. We encourage confirmed deprecations to be merged as soon as the required reviews are complete, even if weeks ahead of the target milestone's release post. For the announcement to be included in a specific release post and that release's documentation packages, this MR must be reviewed/merged per the due dates below:

**By the 10th**: Assign this MR to these team members as Reviewer and for Approval (optional unless noted as required):

- Product Marketing: `@PMM`
- Product Designer(s): `@ProductDesigners`
- Product Group Manager or Director: `@PM` - Required
- Engineering Manager: `@EM` - Required
- Technical writer: `@TW` - Required

**By 11:59 AM PDT 15th**: EM/PM assigns this MR to the TW reviewer for final review and merge: `@EM/PM`

**By 11:59 PM PDT 17th**: TW Reviewer updates Docs by merging this MR to `master`: `@TW`

---

Please review:

- The definitions of ["Deprecation", "End of Support", and "Removal"](https://docs.gitlab.com/ee/development/deprecation_guidelines/#terminology).
- The [guidelines for deprecations](https://about.gitlab.com/handbook/marketing/blog/release-posts/#deprecations).
- The process for [creating a deprecation entry](https://about.gitlab.com/handbook/marketing/blog/release-posts/#creating-a-deprecation-entry).

They are frequently updated, and everyone should make sure they are aware of the current standards (PM, PMM, EM, and TW).

## EM/PM release post item checklist

- [ ] Set yourself as the Assignee, meaning you are the DRI.
- [ ] If the deprecation is a [breaking change](https://about.gitlab.com/handbook/product/gitlab-the-product/#breaking-change), add label `breaking change`.
- [ ] Confirm this MR is labeled ~"release post item::deprecation"
- [ ] Follow the process to [create a deprecation YAML file](https://about.gitlab.com/handbook/marketing/blog/release-posts/#creating-a-deprecation-entry).
- [ ] Add reviewers by the 10th.
- [ ] Add scoped `devops::` and `group::` labels as necessary.
- [ ] Add the appropriate milestone to this MR.
- [ ] When ready to be merged (and no later than the 15th) `@mention` the TW for final review and merge.

## Reviewers

When the content is ready for review, it must be reviewed by a Technical Writer and Engineering Manager, but can also be reviewed by
Product Marketing, Product Design, and the Product Leaders for this area. Please use the
[reviewers](https://docs.gitlab.com/ee/user/project/merge_requests/reviews/)
feature for all reviews. Reviewers will then `approve` the MR and remove themselves from Reviewers when their review is complete.

- [ ] (Recommended) PMM
- [ ] (Optional) Product Designer
- [ ] (Optional) Group Manager or Director
- [ ] Required review and approval: [Technical Writer designated to the corresponding DevOps stage/group](https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments).

### Tech writer review

After being added as a Reviewer to this merge request, the TW performs their review
according to the criteria described below.

Review deprecation MRs with a similar process as regular docs MRs. Add suggestions
as needed, @ message the PM to inform them the first review is complete, and remove
yourself as a reviewer if it's not ready for merge yet.

<details>
<summary>Expand for Details</summary>

- [ ] Title:
  - Length limit: 7 words (not including articles or prepositions).
  - Capitalization: ensure the title is [sentence cased](https://design.gitlab.com/content/punctuation#case).
- [ ] Dates:
  - Make sure that the milestone dates are based on the dates in [Product milestone creation](https://about.gitlab.com/handbook/product/milestones/#product-milestone-creation).
- [ ] Consistency:
  - Ensure that all resources (docs, deprecation, etc.) refer to the feature with the same term / feature name.
- [ ] Content:
  - Make sure the deprecation is accurate based on your understanding. Look for typos or grammar mistakes. Work with PM and PMM to ensure a consistent GitLab style and tone for messaging, based on other features and deprecations.
  - Review use of whitespace and bullet lists. Will the deprecation item be easily scannable when published? Consider adding line breaks or breaking content into bullets if you have more than a few sentences.
  - Make sure there aren't acronyms readers may not understand per <https://about.gitlab.com/handbook/communication/#writing-style-guidelines>.
- [ ] Links:
  - All links must be full URLs, as the deprecation YAML files are used in two different projects. Do not use relative links. The generated doc is an exception to the relative link rule and currently uses absolute links only.
  - Make sure all links and anchors are correct. Do not link to the H1 (top) anchor on a docs page.
- [ ] Code. Make sure any included code is wrapped in code blocks.
- [ ] Capitalization. Make sure to capitalize feature names. Stay consistent with the Documentation Style Guidance on [Capitalization](https://docs.gitlab.com/ee/development/documentation/styleguide.html#capitalization).
- [ ] Blank spaces. Remove unnecessary spaces (end of line spaces, double spaces, extra blank lines, and lines with only spaces).

</details>

When the PM indicates it is ready for merge and all issues have been addressed, start the merge process.

#### Technical writer merge process

The [deprecations doc's `.md` file](https://gitlab.com/gitlab-org/gitlab/blob/master/doc/update/deprecations.md)
must be updated before this MR is merged:

1. Check out the MR's branch (in the [`gitlab-org/gitlab`](https://gitlab.com/gitlab-org/gitlab) project).
1. From the command line (in the branch), run `bin/rake gitlab:docs:compile_deprecations`.
   If you want to double check that it worked, you can run `bin/rake gitlab:docs:check_deprecations`
   to verify that the doc is up to date.
1. Commit the updated file and push the changes.
1. Set the MR to merge when the pipeline succeeds (or merge if the pipeline is already complete).

If you have trouble running the Rake task, check the [troubleshooting steps](https://about.gitlab.com/handbook/marketing/blog/release-posts/#deprecation-rake-task-troubleshooting).

/label ~"release post" ~"release post item" ~"Technical Writing" ~"release post item::deprecation"
/label ~"type::maintenance"
/label ~"maintenance::removal"
