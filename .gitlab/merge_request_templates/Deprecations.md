<!-- Set the correct label and milestone using autocomplete for guidance. Please @mention only the DRI(s) for each stage or group rather than an entire department. -->

**Be sure to link this MR to the relevant deprecation issue(s).**

- Deprecation Issue:

If there is no relevant deprecation issue, hit pause and:

- Review the [process for deprecating and removing features](https://handbook.gitlab.com/handbook/marketing/blog/release-posts/#deprecations-removals-and-breaking-changes).
- Connect with the Product Manager DRI.

Deprecation announcements can and should be created and merged into Docs at any time, to optimize user awareness and planning. We encourage confirmed deprecations to be merged as soon as the required reviews are complete, even if weeks ahead of the target milestone's release post. For the announcement to be included in a specific release post and that release's documentation packages, this MR must be reviewed/merged per the due dates below:

**10 days (Monday) before the Release Date**: Assign this MR to these team members as Reviewer and for Approval (optional unless noted as required):

- Product Marketing: `@PMM`
- Product Designer(s): `@ProductDesigners`
- Product Group Manager or Director: `@PM` - Required
- Engineering Manager: `@EM` - Required
- Technical writer: `@TW` - Required

**By 11:59 AM PDT 8 days (Wednesday) before the Release Date**: EM/PM assigns this MR to the TW reviewer for final review and merge: `@EM/PM`

**By 11:59 PM PDT 6 days (Friday) before the Release Date**: TW Reviewer updates Docs by merging this MR to `master`: `@TW`

---

Please review:

- The definitions of ["Deprecation"](https://docs.gitlab.com/ee/update/terminology.html#deprecation), ["End of Support"](https://docs.gitlab.com/ee/update/terminology.html#end-of-support), and ["Removal"](https://docs.gitlab.com/ee/update/terminology.html#removal).
- The [guidelines for deprecations](https://handbook.gitlab.com/handbook/marketing/blog/release-posts/#deprecations-removals-and-breaking-changes).
- The process for [creating a deprecation announcement](https://handbook.gitlab.com/handbook/marketing/blog/release-posts/#creating-the-announcement).

They are frequently updated, and everyone should make sure they are aware of the current standards (PM, PMM, EM, and TW).

## EM/PM release post item checklist

- [ ] Set yourself as the Assignee, meaning you are the DRI.
- [ ] For [breaking changes](https://docs.gitlab.com/ee/update/terminology.html#breaking-change):
  - [ ] Add the ~"breaking change"  label to the MR.
  - [ ] If the breaking change affects GitLab.com, add `window` with a value of `1`, `2`, or `3`. The value represents the planned [release window](https://docs.gitlab.com/ee/update/breaking_windows.html) for GitLab.com, typically in the three weeks before the major release date. You should intentionally plan this window ahead of time. If you're not sure, ask `@swiskow`.
- [ ] Confirm this MR is labeled ~"release post item::deprecation"
- [ ] Follow the process to [create a deprecation YAML file](https://handbook.gitlab.com/handbook/marketing/blog/release-posts/#creating-the-announcement).
- [ ] Add reviewers by the 10th.
- [ ] Add scoped `devops::` and `group::` labels as necessary.
- [ ] Add the appropriate milestone to this MR.
- [ ] If the changes modify log format(addition/deletion/modification) of product feature, tag `@gitlab-com/gl-security/engineering-and-research/security-logging` team over the GitLab issue/MR.
- [ ] When ready to be merged (and no later than the 15th) `@mention` the TW for final review and merge.

## Reviewers

When the content is ready for review, it must be reviewed by a Technical Writer and Engineering Manager, but can also be reviewed by
Product Marketing, Product Design, and the Product Leaders for this area. Please use the
[reviewers](https://docs.gitlab.com/ee/development/code_review.html#dogfooding-the-reviewers-feature)
feature for all reviews. Reviewers will then approve the MR and remove themselves from Reviewers when their review is complete.

- [ ] (Recommended) PMM
- [ ] (Optional) Product Designer
- [ ] (Optional) Group Manager or Director
- [ ] Required review and approval: [Technical Writer designated to the corresponding DevOps stage/group](https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments).

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
- [ ] Consistency:
  - Ensure that all resources (docs, deprecation, etc.) refer to the feature with the same term / feature name.
- [ ] Content:
  - Make sure the deprecation is accurate based on your understanding. Look for typos or grammar mistakes. Work with PM and PMM to ensure a consistent GitLab style and tone for messaging, based on other features and deprecations.
  - Review use of whitespace and bullet lists. Will the deprecation item be easily scannable when published? Consider adding line breaks or breaking content into bullets if you have more than a few sentences.
  - Make sure there aren't acronyms readers may not understand per [our Writing style guidelines](https://handbook.gitlab.com/handbook/communication/#writing-style-guidelines).
- [ ] Links:
  - All links must be full URLs, as the deprecation YAML files are used in two different projects. Do not use relative links. The generated doc is an exception to the relative link rule and currently uses absolute links only.
  - Make sure all links and anchors are correct. Do not link to the H1 (top) anchor on a docs page.
- [ ] Code. Make sure any included code is wrapped in code blocks.
- [ ] Capitalization. Make sure to capitalize feature names. Stay consistent with the Documentation Style Guidance on [Capitalization](https://docs.gitlab.com/ee/development/documentation/styleguide/index.html#capitalization).

</details>

When the PM indicates it is ready for merge and all issues have been addressed, start the merge process.

#### Technical writer merge process

Remove unnecessary spaces and text, and update the [deprecations doc's `.md` file](https://gitlab.com/gitlab-org/gitlab/blob/master/doc/update/deprecations.md):

1. Check out the MR's branch (in the [`gitlab-org/gitlab`](https://gitlab.com/gitlab-org/gitlab) project).
1. Remove unnecessary spaces (end of line spaces, double spaces, extra blank lines, lines with only spaces).
1. Remove unnecessary text (template and commented out text).
1. Update the `deprecations.md` file:

   1. From the command line (in the branch), run `bin/rake gitlab:docs:compile_deprecations`.
   1. To double check that it worked, you can run `bin/rake gitlab:docs:check_deprecations`
      to verify that the doc is up to date.

1. Update the `breaking_windows.md` file:

   1. From the command line (in the branch), run `bin/rake gitlab:docs:compile_windows`.

1. Commit the updated files and push the changes.
1. Set the merge request to auto-merge, or if the pipeline is already complete, merge.

If you have trouble running the Rake task, check the [troubleshooting steps](https://handbook.gitlab.com/handbook/marketing/blog/release-posts/#deprecation-rake-task-troubleshooting).

/label ~"release post" ~"release post item" ~"Technical Writing" ~"release post item::deprecation"
/label ~"type::maintenance"
/label ~"maintenance::removal"
