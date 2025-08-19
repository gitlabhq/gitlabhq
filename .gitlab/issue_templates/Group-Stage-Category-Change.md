Note: For guidance on **when this issue template applies**, see [the categories handbook page](https://handbook.gitlab.com/handbook/product/categories/#changes) and [the `www-gitlab-com` issue template with the same name](https://gitlab.com/gitlab-com/www-gitlab-com/-/blob/master/.gitlab/issue_templates/Group-Stage-Category-Change.md).

Please review all tasks.
If a task is not relevant, consider crossing it out (`[~]`) instead of removing it to communicate to others that it was reviewed, but not applicable.

If there are any references in the GitLab (product-related) projects, they need to be updated. While primarily `gitlab-org/gitlab`, this also applies to other projects directly tied to the product, such as `gitlab-org/gitlab-runner`. However, this issue template does not include `triage-ops`, which has its own issue template.

1. [ ] Notify the [relevant Technical Writer (TW)](https://handbook.gitlab.com/handbook/product/ux/technical-writing/#designated-technical-writers) if you haven't already. For reference, [docs metadata](https://docs.gitlab.com/development/documentation/metadata/).
1. [ ] Merge changes to `stages.yml` in `www-gitlab-com`. Make sure to mention the `www-gitlab-com` MR in the MRs to be created.
   - Otherwise, CI will fail when validating changes. When we update `feature_categories.yml` in `gitlab-org/gitlab` CI will validate that it represents the latest changes from `stages.yml` in `www-gitlab-com`.
1. [ ] Update categories. For applicability, see [categories changes](#categories-changes) below.
1. [ ] Update any references outside of `doc/` in the various code repositories.

## Categories changes

Code related to the categories in the group may need to be updated depending on what's happening with them:

1. Name of the category stays the same, with new group taking ownership.
   - No action required beyond the `www-gitlab-com` update.
2. Category is renamed with single new owning group.
   - No action required beyond the `www-gitlab-com` update.
3. Category ownership is being split to multiple groups.
   - Each category can only be owned by one group, so features will need to be split into two categories.
   - Update the category as necessary.
4. Category is removed, with no new owner.
   - Code needs to be removed while assessing breakages, including if it's a breaking change.
   - If the code cannot be removed within the current milestone, then another group needs to take ownership.

If point 3 or 4 applies, follow these steps:

1. [ ] Run https://gitlab.com/gitlab-com/runbooks/-/blob/master/scripts/update_stage_groups_feature_categories.rb in the runbooks project and create an MR.
   - The runbooks repository has a process to understand the transitional state: it can map 2 versions of a feature category name to a group, or keep an old feature category mapped to a group and so on.
1. [ ] Run https://gitlab.com/gitlab-org/gitlab/-/blob/master/scripts/update-feature-categories in `gitlab-org/gitlab`, make other changes to spec files as necessary, and create an MR.
   - which will make the required changes to `feature_categories.yml` in `gitlab-org/gitlab`
1. [ ] Request a review based on reviewer roulette in the `runbooks` MR with a link to the `gitlab-org/gitlab` one for them to also review.

For more information on updating categories in the codebase, please see https://gitlab-com.gitlab.io/gl-infra/observability/docs-hub/update-feature-categories/ . If you require assistance, you can reach out to ~"group::observability" `@gitlab-com/gl-infra/observability`.
