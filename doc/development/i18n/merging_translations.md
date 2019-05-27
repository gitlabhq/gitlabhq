# Merging translations from Crowdin

Crowdin automatically syncs the `gitlab.pot` file presenting newly
added translations to the community of translators.

At the same time, it creates a merge request to merge all newly added
& approved translations. Find the [merge request created by
`gitlab-crowdin-bot`](https://gitlab.com/gitlab-org/gitlab-ee/merge_requests?scope=all&utf8=%E2%9C%93&state=opened&author_username=gitlab-crowdin-bot)
to see new and merged merge requests. They are created in EE and need
to be ported to CE manually.

## Validation

By default Crowdin commits translations with `[skip ci]` in the commit
message. This is done to avoid a bunch of pipelines being run. Before
merging translations, make sure to trigger a pipeline to validate
translations, we have static analysis validating things Crowdin
doesn't do. Create a [new pipeline](https://gitlab.com/gitlab-org/gitlab-ee/pipelines/new) for the
`master-i18n` branch.

If there are validation errors, the easiest solution is to disapprove
the offending string in Crowdin, leaving a comment with what is
required to fix the offense. There is an
[issue](https://gitlab.com/gitlab-org/gitlab-ce/issues/49208)
suggesting to automate this process. Disapproving will exclude the
invalid translation, the merge request will be updated within a few
minutes.

It might be handy to pause the integration on the Crowdin side for a
little while so translations don't keep coming. This can be done by
clicking `Pause sync` on the [Crowdin integration settings
page](https://translate.gitlab.com/project/gitlab-ee/settings#integration).

When all failures are resolved, the translations need to be double
checked once more as discussed in [confidential issue](../../user/project/issues/confidential_issues.md) `https://gitlab.com/gitlab-org/gitlab-ce/issues/37850`.

## Merging translations

When all translations are found good and pipelines pass the
translations can be merged into the master branch. After that is done,
create a new merge request cherry-picking the translations from EE to
CE. When merging the translations, make sure to check the `Remove
source branch` checkbox, so Crowdin recreates the `master-i18n` from
master after the new translation was merged.

We are discussing automating this entire process
[here](https://gitlab.com/gitlab-org/gitlab-ce/issues/39309).

## Recreate the merge request

Crowdin creates a new merge request as soon as the old one is closed
or merged. But it won't recreate the `master-i18n` branch every
time. To force Crowdin to recreate the branch, close any [open merge
request](https://gitlab.com/gitlab-org/gitlab-ee/merge_requests?scope=all&utf8=%E2%9C%93&state=opened&author_username=gitlab-crowdin-bot)
and delete the
[`master-18n`](https://gitlab.com/gitlab-org/gitlab-ee/branches/all?utf8=%E2%9C%93&search=master-i18n).

This might be needed when the merge request contains failures that
have been fixed on master.
