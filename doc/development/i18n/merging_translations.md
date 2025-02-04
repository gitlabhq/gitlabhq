---
stage: Foundations
group: Import and Integrate
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
title: Merging translations from Crowdin
---

Crowdin automatically syncs the `gitlab.pot` file with the Crowdin service, presenting
newly added externalized strings to the community of translators.

The [GitLab Crowdin Bot](https://gitlab.com/gitlab-crowdin-bot) also creates merge requests
to take newly approved translation submissions and merge them into the `locale/<language>/gitlab.po`
files. Check the [merge requests created by `gitlab-crowdin-bot`](https://gitlab.com/gitlab-org/gitlab/-/merge_requests?scope=all&state=opened&author_username=gitlab-crowdin-bot)
to see new and merged merge requests.

## Validation

By default Crowdin commits translations with `[skip ci]` in the commit
message. This avoids an excessive number of pipelines from running.
Before merging translations, make sure to trigger a pipeline to validate
translations. Static analysis validates things Crowdin doesn't do. Create
a new pipeline at [`https://gitlab.com/gitlab-org/gitlab/pipelines/new`](https://gitlab.com/gitlab-org/gitlab/pipelines/new)
(requires the Developer role) for the `master-i18n` branch.

The pipeline job validates translations with the [`PoLinter` class](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/i18n/po_linter.rb).
If the linter finds any errors, they appear in the job log.
For an example of a failed pipeline, see [these error messages](https://gitlab.com/gitlab-org/gitlab/-/jobs/6771832489#L873).

If validation errors occur, you must manually disapprove the offending string
in Crowdin and leave a comment about how to fix the errors:

1. Sign in to Crowdin with the `gitlab-crowdin-bot` account.
1. Find the offending string.
1. Select **Current translation is wrong** to disapprove the translation for the specific target language.
1. Include the error message from the job log as a comment.

The invalid translation is then excluded, and the merge request is updated.
Automating this process is proposed in [issue 23256](https://gitlab.com/gitlab-org/gitlab/-/issues/23256).

If the translation fails validation due to angle brackets (`<` or `>`),
it should be disapproved in Crowdin. Our strings must use [variables](externalization.md#html)
for HTML instead.

It might be useful to pause the integration on the Crowdin side for a
moment so translations don't keep coming. You can do this by selecting
**Pause sync** on the [Crowdin integration settings page](https://translate.gitlab.com/project/gitlab-ee/settings#integration).

## Merging translations

After all translations are determined to be appropriate and the pipelines pass,
you can merge the translations into the default branch. When merging translations,
be sure to select the **Remove source branch** checkbox. This causes Crowdin
to recreate the `master-i18n` branch from the default branch after merging the new
translation.

We are discussing [automating this entire process](https://gitlab.com/gitlab-org/gitlab/-/issues/19896).

## Recreate the merge request

Crowdin creates a new merge request as soon as the old one is closed
or merged. But it does not recreate the `master-i18n` branch every
time. To force Crowdin to recreate the branch, close any [open merge requests](https://gitlab.com/gitlab-org/gitlab/-/merge_requests?scope=all&state=opened&author_username=gitlab-crowdin-bot)
and delete the [`master-18n`](https://gitlab.com/gitlab-org/gitlab/-/branches/all?utf8=✓&search=master-i18n) branch.

This might be needed when the merge request contains failures that
have been fixed on the default branch.

## Recreate the GitLab integration in Crowdin

NOTE:
These instructions work only for GitLab Team Members.

If for some reason the GitLab integration in Crowdin doesn't exist, you can
recreate it with the following steps:

1. Sign in to GitLab as `gitlab-crowdin-bot`. (If you're a GitLab Team Member,
   find credentials in the GitLab shared
   [1Password account](https://handbook.gitlab.com/handbook/security/password-guidelines/#1password-for-teams).)
1. Sign in to Crowdin with the GitLab integration.
1. Go to **Settings > Integrations > GitLab > Set Up Integration**.
1. Select the `gitlab-org/gitlab` repository.
1. In **Select Branches for Translation**, select `master`.
1. Ensure the **Service Branch Name** is `master-i18n`.

## Manually update the translation levels

There's no automated way to pull the translation levels from Crowdin, to display
this information in the language selection dropdown list. Therefore, the translation
levels are hard-coded in the `TRANSLATION_LEVELS` constant in [`i18n.rb`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/i18n.rb),
and must be regularly updated.

To update the translation levels:

1. Get the translation levels (percentage of approved words) from [Crowdin](https://crowdin.com/project/gitlab-ee/settings#translations).

1. Update the hard-coded translation levels in [`i18n.rb`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/i18n.rb#L40).
