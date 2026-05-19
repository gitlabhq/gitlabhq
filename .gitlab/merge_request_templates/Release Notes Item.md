# Release notes item

<!-- Set the correct label and milestone using autocomplete for guidance. Please @mention only the DRI(s) for each stage or group rather than an entire department. -->

/label ~"release post" ~"release post item" ~"Technical Writing" ~"type::maintenance" ~"maintenance::refactor" ~"devops::" ~"group::"

Team members for review and approval: Engineer(s): `@engineers` | Product Marketing: `@PMM` | Tech Writer: `@TW`  | Product Designer(s): `@ProductDesigners`

Engineering Manager to merge when the feature is deployed and enabled: `@EM`

[Deprecations follow a different process](https://handbook.gitlab.com/handbook/marketing/blog/release-posts/#creating-a-deprecation-entry).

## Links

- Feature Issue (required):
- Pricing theme MR (required for primary features in Premium or Ultimate only):
- Feature MR (optional):
- Feature Flag Issue (optional):

## Key dates

| Timeline                              | DRI                                                          | Action |
| ------------------------------------- | ------------------------------------------------------------ | ------ |
| Monday of milestone week or earlier   | PMs                                                          | Draft all release post item content and submit for review |
| Thursday of milestone week or earlier | TWs (required); PMM and PM Director/Group Manager (optional) | Complete reviews of release post item content |
| Friday of milestone week or earlier   | TWs or EMs                                                   | Merge content by 00:00 UTC (midnight) |

Note: Not all EMs have Maintainer role, so the EM needs to rely on the TW in this case. If necessary, make the MR dependent on the code MR.

Draft your content as soon as possible to avoid missing the cutoff!

**Reminder: Make sure any feature flags have been enabled or removed!**

## PM release post item checklist

<details>
<summary>Expand for Details</summary>

**Please only mark a section as completed after you perform all individual checks!**

- [ ] Set yourself as the Assignee.
- [ ] **Why?** – The benefit of this feature to the user is clearly explained
  - What is the problem we are solving for the user, and how is the situation improved?
  - Be specific about the problem, using examples so that the reader can recall the last time they had that problem.
  - Be specific about the solution, using examples so that the reader can quickly understand the improvement.
  - Describe the benefits in terms of outcomes like productivity, efficiency, velocity, communication.
  - Avoid feature language, like removing a limitation, that focuses on the product and not our users.
  - Avoid assumed knowledge, assume a customer or prospect will be linked this description without context.
- [ ] Title:
  - Length limit: 7 words (not including articles or prepositions).
  - Sentence case.
- [ ] Content:
  - Make it clear whether the feature is new or an improvement to an existing feature.
  - Ensure all links are functional and have meaningful text for SEO (for example, use descriptive links instead of "click here").
  - Ensure that the text is fewer than 125 words.
- [ ] Details block:
  - Use the [tiers, offerings, and status](https://docs.gitlab.com/development/documentation/styleguide/availability_details/#available-options)
    as detailed in the style guide.
  - Ensure the documentation link points to the latest docs, and includes the anchor to the relevant section on the page if possible.
    Not every release item links to an exact match in the documentation. Just ensure the link seems appropriate.
  - Ensure the documentation is updated and clearly talks about the feature.
  - Ensure all links to `docs.gitlab.com` content are relative URLs.
- [ ] For any [primary features](https://handbook.gitlab.com/handbook/marketing/blog/release-posts/#primary-vs-secondary):
  - Be sure to include or revise the [`features.yml` file](https://gitlab.com/gitlab-com/www-gitlab-com/-/blob/master/data/features.yml) as needed, as described in the [Handbook](https://handbook.gitlab.com/handbook/marketing/blog/release-posts/#features).
  - A category is required, matching an entry in the [`categories.yml` file](https://gitlab.com/gitlab-com/www-gitlab-com/-/blob/master/data/categories.yml). If needed, add or update a category as [described in the handbook](https://handbook.gitlab.com/handbook/product/categories/#category-and-feature-changes).
  - [Update the pricing theme, if a Premium or Ultimate feature](https://gitlab.com/gitlab-com/www-gitlab-com/-/blob/master/.gitlab/merge_request_templates/pricing-theme-primary-feature.md).
- [ ] Add Reviewers: When the above are complete, add the Tech Writer, PMM, and Group Manager or Director as Reviewers.
- [ ] If this MR is a community contribution, consider nominating the contributor for MVP.
  - Check the `#release-post` channel in Slack for the most recent call for MVP Nominations.
  - (The MVP Nomination issue is generated around the 3rd of each month, so there is a period of time between the 18th-3rd when an open nomination issue may not yet exist.)

</details>

## Review

When the above checklist is complete and the content is ready for review, it must be reviewed by Tech Writing.
It can also be reviewed by Product Marketing, Product Design, and the Product Leader for this area.

- [ ] (Required) Tech Writer [reviewed and approved](https://handbook.gitlab.com/handbook/marketing/blog/release-posts/#tw-reviewers)
- [ ] (Recommended) PMM [reviewed and approved](https://handbook.gitlab.com/handbook/marketing/blog/release-posts/#pmm-reviewers)
- [ ] (Optional) Product Designer [reviewed and approved](https://handbook.gitlab.com/handbook/marketing/blog/release-posts/#product-design-reviewers)
- [ ] (Optional) Group Manager or Director [reviewed and approved](https://handbook.gitlab.com/handbook/marketing/blog/release-posts/#recommendations-for-optional-pm-directorgroup-manager-and-pmm-reviews) (ensuring the **why** is clearly explained: what is the problem we are solving for the user, and what value are we delivering.)

Any maintainer can merge. As soon as the code is in the branch, the release notes should be updated.

_Tip:_ Try using the [Review App](https://docs.gitlab.com/ee/ci/review_apps/) in this MR to see exactly how the release post item is rendered.
When this MR is merged, you can view it on the release [preview page](https://docs.gitlab.com/releases/upcoming/).

### Tech writer review

<details>
<summary>Expand for Details </summary>

After [the technical writer from the corresponding group](https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments) is **added as a reviewer to this merge request**, they will perform their review.

**Please mark a section as complete after you perform all individual checks!**

- [ ] Feature:
  - If the feature is in the primary section, review changes to [`features.yml`](https://gitlab.com/gitlab-com/www-gitlab-com/-/blob/master/data/features.yml). Ensure the `category` field contains the relevant categories from [`categories.yml`](https://gitlab.com/gitlab-com/www-gitlab-com/-/blob/master/data/categories.yml).
- [ ] Name/title:
  - Try to limit to 7 words (not including articles or prepositions).
  - Use sentence case.
- [ ] Details block:
  - Ensure the tiers, offerings, and status are correct and match the docs and `features.yml` if applicable.
  - Ensure the documentation link goes to the correct document and anchor. Not every release item links to an exact match in the documentation.
    Just ensure the link seems somewhat appropriate.
  - Ensure the documentation is updated and clearly talks about the feature.
  - Ensure all links to `docs.gitlab.com` content are relative URLs.
- [ ] Description:
  - Review the description for accuracy.
  - Try to limit to 125 words.
  - Stay consistent with the documentation. All resources (docs, release post, `features.yml`, etc.) should refer to the feature the same way, including capitalization.
  - Look for typos or grammar mistakes.
  - Remove unnecessary spaces (end of line spaces, double spaces, extra blank lines, and lines with only spaces).
  - Review use of whitespace and bulleted lists. Are things easily scannable?
    Consider adding line breaks or breaking content into bullets if you have more than a few sentences.
  - Avoid acronyms as much as possible.
  - Ensure code is wrapped in code blocks.

Notes:
- If checklist items are incomplete, tell the PMs or other team members.
- After all checklist items are done, approve the merge request, select your checkbox in the [review](#review) checklist.

</details>

### PMM review

**PMM Review is Optional**
<details>
<summary>Expand for Details</summary>

**Please only mark this section as complete after you perform all individual checks!** When your review is complete, please `approve` this MR.

- [ ] PMM review
  - **problem/solution**: Does this describe the user pain points (problem) as well as how the new feature removes the pain points (solves the problem)?
  - **short/pithy:** Is this communicated clearly with the fewest words possible?
  - **tone clarify:** Is the language and sentence structure clear and grammatically correct?
  - **technical clarity**: Does the description of the feature make sense for various audiences, including folks who are not deeply familiar with GitLab?
  - [ ] Check/copyedit all your content blocks
  - [ ] Check/copyedit features.yml

</details>

## EM release post item checklist

<details>
<summary>Expand for Details </summary>

- When this MR is assigned to you:
  - [ ] Confirm the feature is in the release. Use a dependent MR if the release notes are dependent on the feature being merged.
    - Be aware that merging code to `master` **does not guarantee that the feature will be in the release** ([source](https://handbook.gitlab.com/handbook/engineering/workflow/#product-development-timeline)).
    - If in doubt, confirm the feature commits are in the `x-y-stable-ee` branch (for example, `13-12-stable-ee`).
    - Changes merged into `master` 1+ day prior to `x-y-stable-ee` branch being created will likely be included in the release and release notes for those features can be merged, unless there are incident blocking pipelines or a broken master.
    - You can also use the chatops command `/chatops run release check [MR_URL] [RELEASE]` to check if the MR will be included in the release.
    - Note: For any MRs merged close to the cutoff date, the results are not definitive until the stable branch is cut.
  - [ ] If the feature is behind a feature flag, ensure it is enabled by default.

</details>
