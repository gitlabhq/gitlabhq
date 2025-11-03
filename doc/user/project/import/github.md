---
stage: Create
group: Import
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Import your project from GitHub to GitLab
description: "Import projects from GitHub to GitLab."
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- **Imported** badge [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/461208) in GitLab 17.2.

{{< /history >}}

You can import your GitHub projects from either GitHub.com or GitHub Enterprise. Importing projects does not
migrate or import any types of groups or organizations from GitHub to GitLab.

Imported issues, merge requests, comments, and events have an **Imported** badge in GitLab.

The namespace is a user or group in GitLab, such as `gitlab.com/sidney-jones` or
`gitlab.com/customer-success`.

Using the GitLab UI, the GitHub importer always imports from the
`github.com` domain. If you are importing from a self-hosted GitHub Enterprise Server domain, use the
[GitLab Import API](#use-the-api) GitHub endpoint with a GitLab access token with the `api` scope.

You can change the target namespace and target repository name before you import.

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i>
For an overview of the import process, see [How to migrate from GitHub to GitLab including Actions](https://www.youtube.com/watch?v=0Id5oMl1Kqs).

## Estimating import duration

Every import from GitHub is different, which affects the duration of imports you perform. However, in our testing we
imported `https://github.com/kubernetes/kubernetes` in 76 hours. When we tested, that project comprised:

- 80,000 pull requests.
- 45,000 issues.
- Approximately 1.5 million comments.

## Prerequisites

To import projects from GitHub, you must enable the
[GitHub import source](../../../administration/settings/import_and_export_settings.md#configure-allowed-import-sources).
If that import source is not enabled, ask your GitLab administrator to enable it. The GitHub import source is enabled
by default on GitLab.com.

### Permissions and roles

To use the GitHub importer, you must have:

- Access to the source GitHub project
- At least the Maintainer role for the destination GitLab group (introduced in GitLab 16.0)

Also, the organization the GitHub repository belongs to must not impose restrictions of a
[third-party application access policy](https://docs.github.com/en/organizations/managing-oauth-access-to-your-organizations-data/about-oauth-app-access-restrictions)
on the GitLab instance you import to.

### Accounts for user contribution mapping

{{< history >}}

- [Preparation requirement removed on GitLab.com](https://gitlab.com/groups/gitlab-org/-/epics/14667) in GitLab 17.8.

{{< /history >}}

Before using [the old method of user contribution mapping](#old-method-of-user-contribution-mapping) for imports to GitLab Self-Managed and GitLab
Dedicated, you must meet certain requirements. Imports to GitLab.com use an [improved method](_index.md#user-contribution-and-membership-mapping)
that doesn't require preparation.

These requirements are:

- Each GitHub author and assignee in the repository must have a
  [public-facing email address](https://docs.github.com/en/account-and-profile/setting-up-and-managing-your-personal-account-on-github/managing-email-preferences/setting-your-commit-email-address).
- The GitHub user's email address must match their GitLab email address.
- If a user's email address in GitHub is set as their secondary email address in GitLab, they must confirm it.

GitHub Enterprise does not require a public email address, so you might have to add it to existing accounts.

## Known issues

- GitHub pull request comments (known as diff notes in GitLab) created before 2017 are imported in separate threads.
  This occurs because of a limitation of the GitHub API that doesn't include `in_reply_to_id` for comments before 2017.
- [In GitLab 18.3 and earlier](https://gitlab.com/gitlab-org/gitlab/-/issues/424400), Markdown attachments
  from repositories on GitHub Enterprise Server instances are not imported.
  [In GitLab 18.4 and later](https://gitlab.com/gitlab-org/gitlab/-/issues/553386):
  - Only video and image files in Markdown attachments are imported.
  - Other file attachments are not imported.
- Because of a [known issue](https://gitlab.com/gitlab-org/gitlab/-/issues/418800), when importing projects that used
  [GitHub auto-merge](https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/incorporating-changes-from-a-pull-request/automatically-merging-a-pull-request), the imported project in GitLab can have merge commits labeled `unverified` if the commit was signed with the GitHub internal GPG key.
- GitLab [can't import](https://gitlab.com/gitlab-org/gitlab/-/issues/424046) GitHub Markdown image attachments that
  were uploaded to private repositories before 2023-05-09. If you encounter this problem, would like to help us resolve the problem, and are willing to provide a sample repository
  for us, add a comment to [issue 424046](https://gitlab.com/gitlab-org/gitlab/-/issues/424046) and we'll contact you.
- For [GitLab-specific references](../../markdown.md#gitlab-specific-references), GitLab uses the `#` character for issues and a `!` character for merge requests.
  However, GitHub uses only the `#` character for both issues and pull requests. When importing:

  - Comment notes, GitLab only creates links to issues because GitLab can't determine whether a references points to an
    issue or a merge request.
  - Issues or merge request descriptions, GitLab doesn't create links for any references because their imported
    counterparts might not have been created on the destination yet.

## Import your GitHub repository into GitLab

You can import your GitHub repository by either:

- [Using GitHub OAuth](#use-github-oauth)
- [Using a GitHub personal access token](#use-a-github-personal-access-token)
- [Using the API](#use-the-api)

If importing from `github.com` you can use any method to import. Self-hosted GitHub Enterprise Server customers must use the API.

### Use GitHub OAuth

If you are importing to GitLab.com or to a GitLab Self-Managed that has GitHub OAuth [configured](../../../integration/github.md), you can use GitHub OAuth to import your repository.

This method has an advantage over using a [personal access token (PAT)](#use-a-github-personal-access-token)
because the backend exchanges the access token with the appropriate permissions.

1. On the left sidebar, at the top, select **Create new** ({{< icon name="plus" >}}) and **New project/repository**. If you've [turned on the new navigation](../../interface_redesign.md#turn-new-navigation-on-or-off), this button is in the upper-right corner.
1. Select **Import project** and then **GitHub**.
1. Select **Authorize with GitHub**.
1. Proceed to [selecting which repositories to import](#select-which-repositories-to-import).

To use a different method to perform an import after previously performing
these steps, sign out of your GitLab account and sign in again.

### Use a GitHub personal access token

To import your GitHub repository using a GitHub personal access token:

1. Generate a GitHub personal access token. Only classic personal access tokens are supported.
   1. Go to <https://github.com/settings/tokens/new>.
   1. In the **Note** field, enter a token description.
   1. Select the `repo` scope.
   1. Optional. To [import collaborators](#select-additional-items-to-import), or if your project has [Git LFS files](../../../topics/git/lfs/_index.md), select the `read:org` scope.
   1. Select **Generate token**.
1. On the GitLab left sidebar, at the top, select **Create new** ({{< icon name="plus" >}}) and **New project/repository**. If you've [turned on the new navigation](../../interface_redesign.md#turn-new-navigation-on-or-off), this button is in the upper-right corner.
1. Select **Import project** and then **GitHub**.
1. Select **Authorize with GitHub**.
1. In the **Personal access token** field, paste the GitHub personal access token.
1. Select **Authenticate**.
1. Proceed to [selecting which repositories to import](#select-which-repositories-to-import).

To use a different token to perform an import after previously performing
these steps, sign out of your GitLab account and sign in again, or revoke the
older token in GitHub.

### Use the API

The [GitLab REST API](../../../api/import.md#import-repository-from-github) can be used to import a GitHub repository. It has some advantages over using the GitLab UI:

- Can be used to import GitHub repositories that you do not own if they are public.
- It can be used to import from a GitHub Enterprise Server that is self-hosted.
- Can be used to set the `timeout_strategy` option that is not available to the UI.

The REST API is limited to authenticating with GitLab personal access tokens.

To import your GitHub repository using the GitLab REST API:

1. Generate a GitHub personal access token. Only classic personal access tokens are supported.
   1. Go to <https://github.com/settings/tokens/new>.
   1. In the **Note** field, enter a token description.
   1. Select the `repo` scope.
   1. Optional. To [import collaborators](#select-additional-items-to-import), or if your project has [Git LFS files](../../../topics/git/lfs/_index.md), select the `read:org` scope.
   1. Select **Generate token**.
1. Use the [GitLab REST API](../../../api/import.md#import-repository-from-github) to import your GitHub repository.

### Filter repositories list

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/385113) in GitLab 16.0.

{{< /history >}}

After you authorize access to your GitHub repositories, GitLab redirects you to the importer page and
your GitHub repositories are listed.

Use one of the following tabs to filter the list of repositories:

- **Owner** (default): Filter the list to the repositories that you are the owner of.
- **Collaborated**: Filter the list to the repositories that you have contributed to.
- **Organization**: Filter the list to the repositories that belong to an organization you are a member of.

When the **Organization** tab is selected, you can further narrow down your search by selecting an available GitHub organization from a dropdown list.

### Select additional items to import

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/139410) in GitLab 16.8 [with a flag](../../../administration/feature_flags/_index.md) named `github_import_extended_events`. Disabled by default.
- [Enabled on GitLab.com, GitLab Self-Managed, and GitLab Dedicated](https://gitlab.com/gitlab-org/gitlab/-/issues/435089) in GitLab 16.9.
- [Generally available](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/146695) in GitLab 16.11. Feature flag `github_import_extended_events` removed.

{{< /history >}}

To make imports as fast as possible, the following items aren't imported from GitHub by default:

- More than approximately 30,000 comments because of a [limitation of the GitHub API](troubleshooting_github_import.md#missing-comments).
- Markdown attachments from repository comments, release posts, issue descriptions, and pull request descriptions. These can include
  images, text, or binary attachments. If not imported, links in Markdown to attachments break after you remove the attachments from GitHub.

You can choose to import these items, but this could significantly increase import time. To import these items, select the appropriate fields in the UI:

- **Use alternative comments import method**. If importing GitHub projects with more than approximately 30,000 comments across all issues and pull requests, you should enable this method because of a
  [limitation of the GitHub API](troubleshooting_github_import.md#missing-comments).
- **Import Markdown attachments**.
- **Import collaborators** (selected by default). Leaving it selected might result in new users using a seat in the group or namespace,
  and being granted permissions [as high as project owner](#collaborators-members). Only direct collaborators are imported.
  Outside collaborators are never imported.
  [In GitLab 18.4 and later](https://gitlab.com/gitlab-org/gitlab/-/issues/559224), when you import collaborators,
  the [**Users cannot be added to projects in this group** setting](../../group/access_and_permissions.md#prevent-members-from-being-added-to-projects-in-a-group) is respected.

### Select which repositories to import

By default, the proposed repository namespaces match the names as they exist in GitHub, but based
on your permissions, you can choose to edit these names before you proceed to import any of them.

To select which repositories to import, next to any number of repositories select **Import** or
select **Import all repositories**.

Additionally, you can filter projects by name. If a filter is applied, **Import all repositories**
only imports matched repositories.

The **Status** column shows the import status of each repository. You can choose to keep the page
open and watch updates in real time or you can return to it later.

To cancel imports that are pending or in progress, next to the imported project, select **Cancel**.
If the import has already started, the imported files are kept.

To open a repository in GitLab URL after it has been imported, select its GitLab path.

Completed imports can be re-imported by selecting **Re-import** and specifying new name. This creates a new copy of the source project.

![The GitHub importer page, which lists repositories to be imported into GitLab.](img/import_projects_from_github_importer_v16_0.png)

### Check status of imports

{{< history >}}

- Details of partially completed imports with a list of entities that failed to import [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/386748) in GitLab 16.1.

{{< /history >}}

After imports are completed, they can be in one of three states:

- **Complete**: GitLab imported all repository entities.
- **Partially completed**: GitLab failed to import some repository entities.
- **Failed**: GitLab aborted the import after a critical error occurred.

Expand **Details** to see a list of [repository entities](#imported-data) that failed to import.

## Username mentions

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/477553) in GitLab 17.5.

{{< /history >}}

GitLab adds backticks to username mentions in issues, merge requests, and notes.
These backticks prevent linking to an incorrect user with the same username on the GitLab instance.

## User contribution and membership mapping

{{< history >}}

- [Changed on GitLab.com](https://gitlab.com/groups/gitlab-org/-/epics/14667) to [**user contribution and membership mapping**](_index.md#user-contribution-and-membership-mapping) in GitLab 17.8.
- [Enabled on GitLab.com, GitLab Self-Managed, and GitLab Dedicated](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/176675) in GitLab 17.8.

{{< /history >}}

The GitHub importer uses an [improved method](_index.md#user-contribution-and-membership-mapping)
of mapping user contributions for GitLab.com, GitLab Self-Managed, and GitLab Dedicated.

### Old method of user contribution mapping

You can use the old user contribution mapping method for imports to GitLab Self-Managed and GitLab Dedicated instances.
To use this method, `github_user_mapping` must be disabled.
For imports to GitLab.com, you must
use the [improved method](_index.md#user-contribution-and-membership-mapping) instead.

Using the old method, when [user accounts are provisioned correctly](#accounts-for-user-contribution-mapping), users are mapped during the import.

If the requirements are not met, the importer can't map the particular user's contributions. In that case:

- The project creator is set as the author and assignee of issues and merge requests. The project creator is usually the
  user that initiated the import process. For some contributions that have a description or note such as pull requests,
  issue, notes, the importer amends the text with details of who originally created the contribution.
- Reviewers and approvals added on pull requests in GitHub cannot be imported. In this case, the importer creates comments
  describing that non-existent users were added as reviewers and approvers. However, the actual reviewer status and
  approval are not applied to the merge request in GitLab.

## Mirror a repository and share pipeline status

{{< details >}}

- Tier: Premium, Ultimate

{{< /details >}}

Depending on your GitLab tier, [repository mirroring](../repository/mirror/_index.md) can be set up to keep
your imported repository in sync with its GitHub copy.

Additionally, you can configure GitLab to send pipeline status updates back to GitHub with the
[GitHub Project Integration](../integrations/github.md).

If you import your project using [CI/CD for external repository](../../../ci/ci_cd_for_external_repos/_index.md), then both
features are automatically configured.

{{< alert type="note" >}}

Mirroring does not sync any new or updated pull requests from your GitHub project.

{{< /alert >}}

## Improve the speed of imports on GitLab Self-Managed instances

Administrator access on the GitLab server is required for these steps.

### Increase the number of Sidekiq workers

For large projects it may take a while to import all data. To reduce the time necessary, you can increase the number of
Sidekiq workers that process the following queues:

- `github_importer`
- `github_importer_advance_stage`

For an optimal experience, it's recommended having at least 4 Sidekiq processes (each running a number of threads equal
to the number of CPU cores) that only process these queues. It's also recommended that these processes run on separate
servers. For 4 servers with 8 cores this means you can import up to 32 objects (for example, issues) in parallel.

Reducing the time spent in cloning a repository can be done by increasing network throughput, CPU capacity, and disk
performance (by using high performance SSDs, for example) of the disks that store the Git repositories (for your GitLab instance).
Increasing the number of Sidekiq workers does not reduce the time spent cloning repositories.

### Enable GitHub OAuth using a GitHub Enterprise Cloud OAuth App

If you belong to a [GitHub Enterprise Cloud organization](https://docs.github.com/en/enterprise-cloud@latest/get-started/onboarding) you can configure GitLab Self-Managed to obtain a higher [GitHub API rate limit](https://docs.github.com/en/rest/using-the-rest-api/rate-limits-for-the-rest-api?apiVersion=2022-11-28#primary-rate-limit-for-authenticated-users).

GitHub API requests are usually subject to a rate limit of 5,000 requests per hour. Using the steps below, you obtain a higher 15,000 requests per hour rate limit, resulting in a faster overall import time.

Prerequisites:

- You have access to a
  [GitHub Enterprise Cloud organization](https://docs.github.com/en/enterprise-cloud@latest/get-started/onboarding/getting-started-with-github-enterprise-cloud).
- GitLab is configured to enable [GitHub OAuth](../../../integration/github.md#enable-github-oauth-in-gitlab).

To enable a higher rate limit:

- [Create an OAuth app in GitHub](../../../integration/github.md#create-an-oauth-app-in-github). Ensure that the OAuth app is owned by the Enterprise Cloud Organization, not your personal GitHub account.
- Perform the project import using [GitHub OAuth](#use-github-oauth).
- Optional. By default, sign-in is enabled for all configured OAuth providers.
  If you want to enable GitHub OAuth for imports but you want to
  prevent the ability for users to sign in to your GitLab instance with GitHub,
  you can
  [disable sign-in with GitHub](../../../integration/omniauth.md#enable-or-disable-sign-in-with-an-omniauth-provider-without-disabling-import-sources).

## Imported data

The following items of a project are imported:

- All fork branches of the project related to open pull requests

  {{< alert type="note" >}}

  Fork branches are imported with a naming scheme similar to `GH-SHA-username/pull-request-number/fork-name/branch`.

  {{< /alert >}}

- All project branches
- Attachments for:
  - Comments
  - Issue descriptions
  - Pull request descriptions
  - Release notes
- Branch protection rules
- [Collaborators (members)](#collaborators-members)
- [Git LFS objects](../../../topics/git/lfs/_index.md)
- Git repository data
- Issue and pull request comments
- Issue and pull request events (can be imported as an [additional item](#select-additional-items-to-import))
- Issues
- Labels
- Milestones
- Pull request assigned reviewers
- Pull request merged by information
- Pull request reviews
- Pull request review comments
- Pull request review replies to discussions
- Pull request review suggestions
- Pull requests
- Release notes content
- Repository descriptions
- Wiki pages

References to pull requests and issues are preserved. Each imported repository maintains visibility level unless that
[visibility level is restricted](../../public_access.md#restrict-use-of-public-or-internal-projects), in which case it
defaults to the default project visibility.

### Branch protection rules and project settings

Imported GitHub branch protection rules are mapped to one of the following:

- GitLab branch protection rules
- Project-wide GitLab settings

| GitHub rule                                                                                         | GitLab rule                                                                                                                                                                                                                                                          |
|:----------------------------------------------------------------------------------------------------|:---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| **Require conversation resolution before merging** for the project's default branch                 | **All threads must be resolved** [project setting](../merge_requests/_index.md#prevent-merge-unless-all-threads-are-resolved)                                                                                                                                         |
| **Require a pull request before merging**                                                           | **No one** option in the **Allowed to push and merge** [branch protection settings](../repository/branches/protected.md#protect-a-branch)                                                                                                            |
| **Require signed commits** for the project's default branch                                         | **Reject unsigned commits** GitLab [push rule](../repository/push_rules.md#require-signed-commits)                                                                                                                                                          |
| **Allow force pushes - Everyone**                                                                   | **Allowed to force push** [branch protection setting](../repository/branches/protected.md#allow-force-push)                                                                                                                                               |
| **Require a pull request before merging - Require review from Code Owners**                         | **Require approval from code owners** [branch protection setting](../repository/branches/protected.md#require-code-owner-approval)                                                                                                                        |
| **Require a pull request before merging - Allow specified actors to bypass required pull requests** | List of users in the **Allowed to push and merge** [branch protection settings](../repository/branches/protected.md#protect-a-branch). Without a GitLab Premium subscription, the list of users that are allowed to push and merge is limited to roles. |

The **Require status checks to pass before merging** GitHub rule is not imported.
You can still create [external status checks](../merge_requests/status_checks.md) manually.
For more information, see [issue 370948](https://gitlab.com/gitlab-org/gitlab/-/issues/370948).

### Collaborators (members)

{{< history >}}

- Importing collaborators as an additional item [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/398154) in GitLab 16.0.

{{< /history >}}

These GitHub collaborator roles are mapped to these GitLab [member roles](../../permissions.md#roles):

| GitHub role | Mapped GitLab role |
|:------------|:-------------------|
| Read        | Guest              |
| Triage      | Reporter           |
| Write       | Developer          |
| Maintain    | Maintainer         |
| Admin       | Owner              |

GitHub Enterprise Cloud has
[custom repository roles](https://docs.github.com/en/enterprise-cloud@latest/organizations/managing-user-access-to-your-organizations-repositories/managing-repository-roles/about-custom-repository-roles).
These roles aren't supported and cause partially completed imports.

To import GitHub collaborators, you must have at least the Write role on the GitHub project. Otherwise collaborators import is skipped.

## Import from GitHub Enterprise on an internal network

If your GitHub Enterprise instance is on a internal network that is inaccessible to the internet, you can use a reverse proxy
to allow GitLab.com to access the instance.

The proxy needs to:

- Forward requests to the GitHub Enterprise instance.
- Convert to the public proxy hostname all occurrences of the internal hostname in:
  - The API response body.
  - The API response `Link` header.

GitHub API uses the `Link` header for pagination.

After configuring the proxy, test it by making API requests. Below there are some examples of commands to test the API:

```shell
curl --header "Authorization: Bearer <YOUR-TOKEN>" "https://{PROXY_HOSTNAME}/user"

### URLs in the response body should use the proxy hostname

{
  "login": "example_username",
  "id": 1,
  "url": "https://{PROXY_HOSTNAME}/users/example_username",
  "html_url": "https://{PROXY_HOSTNAME}/example_username",
  "followers_url": "https://{PROXY_HOSTNAME}/api/v3/users/example_username/followers",
  ...
  "created_at": "2014-02-11T17:03:25Z",
  "updated_at": "2022-10-18T14:36:27Z"
}
```

```shell
curl --head --header "Authorization: Bearer <YOUR-TOKEN>" "https://{PROXY_DOMAIN}/api/v3/repos/{repository_path}/pulls?states=all&sort=created&direction=asc"

### Link header should use the proxy hostname

HTTP/1.1 200 OK
Date: Tue, 18 Oct 2022 21:42:55 GMT
Server: GitHub.com
Content-Type: application/json; charset=utf-8
Cache-Control: private, max-age=60, s-maxage=60
...
X-OAuth-Scopes: repo
X-Accepted-OAuth-Scopes:
github-authentication-token-expiration: 2022-11-22 18:13:46 UTC
X-GitHub-Media-Type: github.v3; format=json
X-RateLimit-Limit: 5000
X-RateLimit-Remaining: 4997
X-RateLimit-Reset: 1666132381
X-RateLimit-Used: 3
X-RateLimit-Resource: core
Link: <https://{PROXY_DOMAIN}/api/v3/repositories/1/pulls?page=2>; rel="next", <https://{PROXY_DOMAIN}/api/v3/repositories/1/pulls?page=11>; rel="last"
```

Also test that cloning the repository using the proxy does not fail:

```shell
git clone -c http.extraHeader="Authorization: basic <base64 encode YOUR-TOKEN>" --mirror https://{PROXY_DOMAIN}/{REPOSITORY_PATH}.git
```

### Sample reverse proxy configuration

The following configuration is an example on how to configure Apache HTTP Server as a reverse proxy

{{< alert type="warning" >}}

For simplicity, the snippet does not have configuration to encrypt the connection between the client and the proxy. However, for security reasons you should include that
configuration. See [sample Apache TLS/SSL configuration](https://ssl-config.mozilla.org/#server=apache&version=2.4.41&config=intermediate&openssl=1.1.1k&guideline=5.6).

{{< /alert >}}

```plaintext
# Required modules
LoadModule filter_module lib/httpd/modules/mod_filter.so
LoadModule reflector_module lib/httpd/modules/mod_reflector.so
LoadModule substitute_module lib/httpd/modules/mod_substitute.so
LoadModule deflate_module lib/httpd/modules/mod_deflate.so
LoadModule headers_module lib/httpd/modules/mod_headers.so
LoadModule proxy_module lib/httpd/modules/mod_proxy.so
LoadModule proxy_connect_module lib/httpd/modules/mod_proxy_connect.so
LoadModule proxy_http_module lib/httpd/modules/mod_proxy_http.so
LoadModule ssl_module lib/httpd/modules/mod_ssl.so

<VirtualHost GITHUB_ENTERPRISE_HOSTNAME:80>
  ServerName GITHUB_ENTERPRISE_HOSTNAME

  # Enables reverse-proxy configuration with SSL support
  SSLProxyEngine On
  ProxyPass "/" "https://GITHUB_ENTERPRISE_HOSTNAME/"
  ProxyPassReverse "/" "https://GITHUB_ENTERPRISE_HOSTNAME/"

  # Replaces occurrences of the local GitHub Enterprise URL with the Proxy URL
  # GitHub Enterprise compresses the responses, the filters INFLATE and DEFLATE needs to be used to
  # decompress and compress the response back
  AddOutputFilterByType INFLATE;SUBSTITUTE;DEFLATE application/json
  Substitute "s|https://GITHUB_ENTERPRISE_HOSTNAME|https://PROXY_HOSTNAME|ni"
  SubstituteMaxLineLength 50M

  # GitHub API uses the response header "Link" for the API pagination
  # For example:
  #   <https://example.com/api/v3/repositories/1/issues?page=2>; rel="next", <https://example.com/api/v3/repositories/1/issues?page=3>; rel="last"
  # The directive below replaces all occurrences of the GitHub Enterprise URL with the Proxy URL if the
  # response header Link is present
  Header edit* Link "https://GITHUB_ENTERPRISE_HOSTNAME" "https://PROXY_HOSTNAME"
</VirtualHost>
```
