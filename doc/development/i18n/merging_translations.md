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
suggesting to automate this process. Disapproving will exclude the
invalid translation, the merge request will be updated within a few
minutes.

It might be handy to pause the integration on the CrowdIn side for a
little while so translations don't keep coming. This can be done by
clicking `Pause sync` on the [CrowdIn integration settings
page](https://translate.gitlab.com/project/gitlab-ee/settings#integration).

When all failures are resolved, the translations need to be double
checked once more as discussed in [confidential issue](../../user/project/issues/confidential_issues.md) `https://gitlab.com/gitlab-org/gitlab/-/issues/19485`.

## Merging translations

When all translations are found good and pipelines pass the
translations can be merged into the master branch. When merging the translations,
make sure to check the **Remove source branch** checkbox, so CrowdIn recreates the
`master-i18n` from master after the new translation was merged.

We are discussing [automating this entire process](https://gitlab.com/gitlab-org/gitlab/-/issues/19896).

## Recreate the merge request

CrowdIn creates a new merge request as soon as the old one is closed
or merged. But it won't recreate the `master-i18n` branch every
time. To force CrowdIn to recreate the branch, close any [open merge
request](https://gitlab.com/gitlab-org/gitlab/-/merge_requests?scope=all&utf8=%E2%9C%93&state=opened&author_username=gitlab-crowdin-bot)
and delete the
[`master-18n`](https://gitlab.com/gitlab-org/gitlab/-/branches/all?utf8=✓&search=master-i18n).

This might be needed when the merge request contains failures that
have been fixed on master.

## Recreate the GitLab integration in CrowdIn

NOTE: ***Note:**
These instructions work only for GitLab Team Members.

If for some reason the GitLab integration in CrowdIn does not exist, it can be
recreated by the following steps:

1. Sign in to GitLab as `gitlab-crowdin-bot` (If you're a GitLab Team Member, find credentials in the GitLab shared  [1Password account](https://about.gitlab.com/handbook/security/#1password-for-teams)
1. Sign in to Crowdin with the GitLab integration
1. Navigate to Settings > Integrations > GitLab > Set Up Integration
1. Select `gitlab-org/gitlab` repository
1. On `Select Branches for Translation`, select `master`
1. Ensure the `Service Branch Name` is `master-i18n`
