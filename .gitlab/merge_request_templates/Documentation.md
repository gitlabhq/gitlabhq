<!--See the general documentation guidelines https://docs.gitlab.com/ee/development/documentation -->

<!-- Mention "documentation" or "docs" in the MR title -->

<!-- Use this description template for new docs or updates to existing docs. For changing documentation location use the "Change documentation location" template -->

## What does this MR do?

<!-- Briefly describe what this MR is about -->

## Related issues

<!-- Mention the issue(s) this MR closes or is related to -->

Closes 

## Author's checklist

- [ ] [Apply the correct labels and milestone](https://docs.gitlab.com/ee/development/documentation/workflow.html#2-developer-s-role-in-the-documentation-process)
- [ ] Crosslink the document from the higher-level index
- [ ] Crosslink the document from other subject-related docs
- [ ] Correctly apply the product [badges](https://docs.gitlab.com/ee/development/documentation/styleguide.html#product-badges) and [tiers](https://docs.gitlab.com/ee/development/documentation/styleguide.html#gitlab-versions-and-tiers)
- [ ] [Port the MR to EE (or backport from CE)](https://docs.gitlab.com/ee/development/documentation/index.html#cherry-picking-from-ce-to-ee): _always recommended, required when the `ee-compat-check` job fails_

## Review checklist

- [ ] Your team's review (required)
- [ ] PM's review (recommended, but not a blocker)
- [ ] Technical writer's review (required)
- [ ] Merge the EE-MR first, CE-MR afterwards

/label ~Documentation
