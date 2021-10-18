<!-- Set the correct label and milestone using autocomplete for guidance. Please @mention only the DRI(s) for each stage or group rather than an entire department. -->

/label ~"release post" ~"release post item" ~"Technical Writing" ~"devops::" ~"group::"
/milestone %
/assign `@PM`

**Be sure to link this MR to the relevant deprecation issue(s).**

**By the 10th**: Assign this MR to these team members as Reviewer and for Approval (optional unless noted as required):

- Product Marketing: `@PMM`
- Product Designer(s): `@ProductDesigners`
- Group Manager or Director: `@manager`
- Engineering Manager: `@EM` - Required

**By 8:00 AM PDT 15th**: PM will assign this MR to the TW reviewer: `@PM`

**By 11:59 PM PDT 15th**: TW Reviewer will perform final review and merge this MR to Master: `@TW`

---

Please review the [guidelines for deprecations](https://about.gitlab.com/handbook/marketing/blog/release-posts/#deprecations),
as well as the process for [creating a deprecation entry](https://about.gitlab.com/handbook/marketing/blog/release-posts/#creating-a-deprecation-entry).
They are frequently updated, and everyone should make sure they are aware of the current standards (PM, PMM, EM, and TW).

## Links

- Deprecation Issue:
- Deprecation MR (optional):

## PM release post item checklist

- [ ] Set yourself as the Assignee.
- [ ] If the deprecation is a [breaking change](https://about.gitlab.com/handbook/product/gitlab-the-product/#breaking-change), add label `breaking change`
- [ ] Follow the process to [create a deprecation YAML file](https://about.gitlab.com/handbook/marketing/blog/release-posts/#creating-a-deprecation-entry).
- [ ] Add reviewers by the 10th
- [ ] When ready to be merged and not later than the 15th, add the ~ready label and @ message the TW for final review and merge.

## Reviewers

When the content is ready for review, it must be reviewed by Technical Writer and Engineering Manager, but can also be reviewed by
Product Marketing, Product Design, and the Product Leaders for this area. Please use the
[Reviewers for Merge Requests](https://docs.gitlab.com/ee/user/project/merge_requests/getting_started#reviewer)
feature for all reviews. Reviewers will then `approve` the MR and remove themselves from Reviewers when their review is complete.

- [ ] (Recommended) PMM
- [ ] (Optional) Product Designer
- [ ] (Optional) Group Manager or Director
- [ ] Required review and approval: [Technical Writer designated to the corresponding DevOps stage/group](https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments).

### Tech writer review

After being added as a Reviewer to this merge request, the TW performs their review
according to the criteria described below.

Review deprecation MRs with a similar process as regular docs MRs. Add suggestions
as needed, @ message the PM to inform them the first review is complete, and remove
yourself as a reviewer if it's not ready for merge yet.

<details>
<summary>Expand for Details </summary>

- [ ] Title:
  - Length limit: 7 words (not including articles or prepositions).
  - Capitalization: ensure the title is [sentence cased](https://design.gitlab.com/content/punctuation#case).
  - No Markdown `` `code` `` formatting in the title, as it doesn't render correctly in the release post.
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

When the PM indicates it is ready for merge, all issues have been addressed merge this MR. 
     - You must merge this MR by the 15th so the Release Post TW lead can run the [deprecations in Docs rake task](https://about.gitlab.com/handbook/marketing/blog/release-posts/#update-the-deprecations-doc) on the 16th
