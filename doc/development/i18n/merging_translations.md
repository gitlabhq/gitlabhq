---
stage: Manage
group: Import
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Merging translations from CrowdIn

CrowdIn automatically syncs the `gitlab.pot` file with the CrowdIn service, presenting
newly added externalized strings to the community of translators.

[GitLab CrowdIn Bot](https://gitlab.com/gitlab-crowdin-bot) also creates merge requests
to take newly approved translation submissions and merge them into the `locale/<language>/gitlab.po`
files. Check the [merge requests created by `gitlab-crowdin-bot`](https://gitlab.com/gitlab-org/gitlab/-/merge_requests?scope=all&utf8=%E2%9C%93&state=opened&author_username=gitlab-crowdin-bot)
to see new and merged merge requests.

## Validation

By default CrowdIn commits translations with `[skip ci]` in the commit
message. This is done to avoid a bunch of pipelines being run. Before
merging translations, make sure to trigger a pipeline to validate
translations, we have static analysis validating things CrowdIn
doesn't do. Create a new pipeline at `https://gitlab.com/gitlab-org/gitlab/pipelines/new`
(need Developer access permissions) for the `master-i18n` branch.

If there are validation errors, the easiest solution is to disapprove
the offending string in CrowdIn, leaving a comment with what is
required to fix the offense. There is an
[issue](https://gitlab.com/gitlab-org/gitlab/-/issues/23256)
suggesting to automate this process. Disapproving excludes the
invalid translation, the merge request is then updated within a few
minutes.

If the translation has failed validation due to angle brackets `<` or `>`
it should be disapproved on CrowdIn as our strings should be
using [variables](externalization.md#html) for HTML instead.

It might be handy to pause the integration on the CrowdIn side for a
little while so translations don't keep coming. This can be done by
clicking `Pause sync` on the [CrowdIn integration settings
page](https://translate.gitlab.com/project/gitlab-ee/settings#integration).

## Merging translations

After all translations are determined to be appropriate and the pipelines pass,
you can merge the translations into the default branch. When merging translations,
be sure to select the **Remove source branch** check box, which causes CrowdIn
to recreate the `master-i18n` from the default branch after merging the new
translation.

We are discussing [automating this entire process](https://gitlab.com/gitlab-org/gitlab/-/issues/19896).

## Recreate the merge request

CrowdIn creates a new merge request as soon as the old one is closed
or merged. But it does not recreate the `master-i18n` branch every
time. To force CrowdIn to recreate the branch, close any [open merge
request](https://gitlab.com/gitlab-org/gitlab/-/merge_requests?scope=all&utf8=%E2%9C%93&state=opened&author_username=gitlab-crowdin-bot)
and delete the
[`master-18n`](https://gitlab.com/gitlab-org/gitlab/-/branches/all?utf8=✓&search=master-i18n).

This might be needed when the merge request contains failures that
have been fixed on the default branch.

## Recreate the GitLab integration in CrowdIn

NOTE:
These instructions work only for GitLab Team Members.

If for some reason the GitLab integration in CrowdIn doesn't exist, you can
recreate it with the following steps:

1. Sign in to GitLab as `gitlab-crowdin-bot`. (If you're a GitLab Team Member,
   find credentials in the GitLab shared
   [1Password account](https://about.gitlab.com/handbook/security/#1password-for-teams).)
1. Sign in to CrowdIn with the GitLab integration.
1. Go to **Settings > Integrations > GitLab > Set Up Integration**.
1. Select the `gitlab-org/gitlab` repository.
1. In `Select Branches for Translation`, select `master`.
1. Ensure the `Service Branch Name` is `master-i18n`.

## Manually update the translation levels

There's no automated way to pull the translation levels from CrowdIn, to display
this information in the language selection dropdown. Therefore, the translation
levels are hard-coded in the `TRANSLATION_LEVELS` constant in [`i18n.rb`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/i18n.rb),
and must be regularly updated.
