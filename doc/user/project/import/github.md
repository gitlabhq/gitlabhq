---
type: reference, howto
stage: Manage
group: Import
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Import your project from GitHub to GitLab **(FREE)**

You can import your GitHub repositories:

- From either GitHub.com or GitHub Enterprise.
- To either GitLab.com or a self-managed GitLab instance.

This process does not migrate or import any types of groups or organizations from GitHub to GitLab.

The namespace is a user or group in GitLab, such as `gitlab.com/sidney-jones` or
`gitlab.com/customer-success`. You can use bulk actions in the rails console to move projects to
different namespaces.

If you are importing to a self-managed GitLab instance, you can use the
[GitHub Rake task](../../../administration/raketasks/github_import.md) instead. This allows you to import projects
without the constraints of a [Sidekiq](../../../development/sidekiq/index.md) worker.

If you are importing from GitHub Enterprise to a self-managed GitLab instance:

- You must first enable [GitHub integration](../../../integration/github.md).
- To import projects from GitHub Enterprise to GitLab.com, use the [Import API](../../../api/import.md).
- If GitLab is behind a HTTP/HTTPS proxy, you must populate the [allowlist for local requests](../../../security/webhooks.md#create-an-allowlist-for-local-requests)
  with `github.com` and `api.github.com` to solve the hostname. For more information, read the issue
  [Importing a GitHub project requires DNS resolution even when behind a proxy](https://gitlab.com/gitlab-org/gitlab/-/issues/37941).

If you are importing from GitHub.com to a self-managed GitLab instance:

- Setting up GitHub integration is not required.
- You can use the [Import API](../../../api/import.md).

When importing projects:

- If a user referenced in the project is not found in the GitLab database, the project creator is set as the author and
  assignee. The project creator is usually the user that initiated the import process. A note on the issue mentioning the
  original GitHub author is added.
- The importer creates any new namespaces (or groups) if they do not exist, or, if the namespace is taken, the
  repository is imported under the namespace of the user who initiated the import process. The namespace or repository
  name can also be edited, with the proper permissions.
- The importer also imports branches on forks of projects related to open pull requests. These branches are
  imported with a naming scheme similar to `GH-SHA-username/pull-request-number/fork-name/branch`. This may lead to
  a discrepancy in branches compared to those of the GitHub repository.

For additional technical details, refer to the [GitHub Importer](../../../development/github_importer.md)
developer documentation.

For an overview of the import process, see the video [Migrating from GitHub to GitLab](https://youtu.be/VYOXuOg9tQI).

## Prerequisites

When issues and pull requests are being imported, the importer attempts to find
their GitHub authors and assignees in the database of the GitLab instance. Pull requests are called _merge requests_ in
GitLab.

For this association to succeed, each GitHub author and assignee in the repository
must have a [public-facing email address](https://docs.github.com/en/account-and-profile/setting-up-and-managing-your-personal-account-on-github/managing-email-preferences/setting-your-commit-email-address)
on GitHub that matches their GitLab email address (regardless of how the account was created).

GitLab content imports that use GitHub accounts require that the GitHub public-facing email address is populated. This means
all comments and contributions are properly mapped to the same user in GitLab. GitHub Enterprise does not require this
field to be populated so you may have to add it on existing accounts.

## Import your GitHub repository into GitLab

### Use the GitHub integration

Before you begin, ensure that any GitHub user you want to map to a GitLab user has a GitLab email address that matches their
[publicly visible email address](https://docs.github.com/en/rest/users#get-a-user) on GitHub.

If you are importing to GitLab.com, you can alternatively import GitHub repositories using a [personal access token](#use-a-github-token).
We do not recommend this method, as it does not associate all user activity (such as issues and pull requests) with matching GitLab users.

User-matching attempts occur in that order, and if a user is not identified either way, the activity is associated with
the user account that is performing the import.

NOTE:
If you are using a self-managed GitLab instance or if you are importing from GitHub Enterprise, this process requires that you have configured
[GitHub integration](../../../integration/github.md).

1. From the top navigation bar, select **+** and select **New project**.
1. Select the **Import project** tab and then select **GitHub**.
1. Select the first button to **List your GitHub repositories**. You are redirected to a page on [GitHub](https://github.com) to authorize the GitLab application.
1. Select **Authorize GitlabHQ**. You are redirected back to the GitLab Import page and all of your GitHub repositories are listed.
1. Continue on to [selecting which repositories to import](#select-which-repositories-to-import).

### Use a GitHub token

Prerequisite:

- Authentication token with administrator access.

Using a personal access token to import projects is not recommended. If you are a GitLab.com user,
you can use a personal access token to import your project from GitHub, but this method cannot
associate all user activity (such as issues and pull requests) with matching GitLab users.
If you are an administrator of a self-managed GitLab instance or if you are importing from
GitHub Enterprise, you cannot use a personal access token.
The [GitHub integration method (above)](#use-the-github-integration) is recommended for all users.

If you are not using the GitHub integration, you can still perform an authorization with GitHub to grant GitLab access your repositories:

1. Go to <https://github.com/settings/tokens/new>
1. Enter a token description.
1. Select the repository scope.
1. Select **Generate token**.
1. Copy the token hash.
1. Go back to GitLab and provide the token to the GitHub importer.
1. Select **List Your GitHub Repositories** and wait while GitLab reads your repositories' information.
   When done, you are taken to the importer page to select the repositories to import.

To use a newer personal access token in imports after previously performing these steps, sign out of
your GitLab account and sign in again, or revoke the older personal access token in GitHub.

### Select additional items to import

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/373705) in GitLab 15.5.

To make imports as fast as possible, the following items aren't imported from GitHub by default:

- Issue and pull request events. For example, _opened_ or _closed_, _renamed_, and _labeled_ or _unlabeled_.
- All comments. In regular import of large repositories some comments might get skipped due to limitation of GitHub API.
- Markdown attachments from repository comments, release posts, issue descriptions, and pull request descriptions. These can include
  images, text, or binary attachments. If not imported, links in Markdown to attachments break after you remove the attachments from GitHub.

You can choose to import these items, but this could significantly increase import time. To import these items, select the appropriate fields in the UI:

- **Import issue and pull request events**.
- **Use alternative comments import method**.
- **Import Markdown attachments**.

### Select which repositories to import

After you have authorized access to your GitHub repositories, you are redirected to the GitHub importer page and
your GitHub repositories are listed.

1. By default, the proposed repository namespaces match the names as they exist in GitHub, but based on your permissions,
   you can choose to edit these names before you proceed to import any of them.
1. Select the **Import** button next to any number of repositories, or select **Import all repositories**. Additionally,
   you can filter projects by name. If filter is applied, **Import all repositories** only imports matched repositories.
1. The **Status** column shows the import status of each repository. You can choose to leave the page open and it will
   update in real-time or you can return to it later.
1. Once a repository has been imported, select its GitLab path to open its GitLab URL.

![GitHub importer page](img/import_projects_from_github_importer_v12_3.png)

## Mirror a repository and share pipeline status **(PREMIUM)**

Depending on your GitLab tier, [repository mirroring](../repository/mirror/index.md) can be set up to keep
your imported repository in sync with its GitHub copy.

Additionally, you can configure GitLab to send pipeline status updates back to GitHub with the
[GitHub Project Integration](../integrations/github.md).

If you import your project using [CI/CD for external repository](../../../ci/ci_cd_for_external_repos/index.md), then both
of the above are automatically configured.

NOTE:
Mirroring does not sync any new or updated pull requests from your GitHub project.

## Improve the speed of imports on self-managed instances

Administrator access on the GitLab server is required for this process.

For large projects it may take a while to import all data. To reduce the time necessary, you can increase the number of
Sidekiq workers that process the following queues:

- `github_importer`
- `github_importer_advance_stage`

For an optimal experience, it's recommended having at least 4 Sidekiq processes (each running a number of threads equal
to the number of CPU cores) that *only* process these queues. It's also recommended that these processes run on separate
servers. For 4 servers with 8 cores this means you can import up to 32 objects (for example, issues) in parallel.

Reducing the time spent in cloning a repository can be done by increasing network throughput, CPU capacity, and disk
performance (by using high performance SSDs, for example) of the disks that store the Git repositories (for your GitLab instance).
Increasing the number of Sidekiq workers does *not* reduce the time spent cloning repositories.

## Imported data

The following items of a project are imported:

- Repository description.
- Git repository data.
- Branch protection rules. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/22650) in GitLab 15.4.
- Issues.
- Pull requests.
- Wiki pages.
- Milestones.
- Labels.
- Release note descriptions.
- Attachments for:
  - Release notes. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/15620) in GitLab 15.4.
  - Comments and notes. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/18052) in GitLab 15.5.
  - Issue description. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/18052) in GitLab 15.5.
  - Merge Request description. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/18052) in GitLab 15.5.

  All attachment imports are disabled by default behind
  `github_importer_attachments_import` [feature flag](../../../administration/feature_flags.md). From GitLab 15.5, can
  be imported [as an additional item](#select-additional-items-to-import). The feature flag was removed.
- Pull request review comments.
- Regular issue and pull request comments.
- [Git Large File Storage (LFS) Objects](../../../topics/git/lfs/index.md).
- Pull request reviews.
- Pull request assigned reviewers. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/355137) in GitLab 15.6.
- Pull request "merged by" information.
- Pull request comments replies in discussions. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/336596) in
  GitLab 14.5.
- Diff Notes suggestions. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/340624) in GitLab 14.7.
- Issue events and pull requests events. [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/7673) in GitLab 15.4
  with `github_importer_issue_events_import` [feature flag](../../../administration/feature_flags.md) disabled by default.
  From GitLab 15.5, can be imported [as an additional item](#select-additional-items-to-import). The feature flag was
  removed.

References to pull requests and issues are preserved. Each imported repository maintains visibility level unless that
[visibility level is restricted](../../public_access.md#restrict-use-of-public-or-internal-projects), in which case it
defaults to the default project visibility.

### Branch protection rules and project settings

When they are imported, supported GitHub branch protection rules are mapped to either:

- GitLab branch protection rules.
- Project-wide GitLab settings.

| GitHub rule                                                                         | GitLab rule                                                                                                                                                 | Introduced in                                                       |
| :---------------------------------------------------------------------------------- | :---------------------------------------------------------------------------------------------------------------------------------------------------------- | :------------------------------------------------------------------ |
| **Require conversation resolution before merging** for the project's default branch | **All threads must be resolved** [project setting](../../discussions/index.md#prevent-merge-unless-all-threads-are-resolved)                                | [GitLab 15.5](https://gitlab.com/gitlab-org/gitlab/-/issues/371110) |
| **Require a pull request before merging**                                           | **No one** option in the **Allowed to push** list of [branch protection settings](../protected_branches.md#configure-a-protected-branch)                    | [GitLab 15.5](https://gitlab.com/gitlab-org/gitlab/-/issues/370951) |
| **Require signed commits** for the project's default branch                         | **Reject unsigned commits** GitLab [push rule](../repository/push_rules.md#prevent-unintended-consequences) **(PREMIUM)**                                   | [GitLab 15.5](https://gitlab.com/gitlab-org/gitlab/-/issues/370949) |
| **Allow force pushes - Everyone**                                                   | **Allowed to force push** [branch protection setting](../protected_branches.md#allow-force-push-on-a-protected-branch)                                      | [GitLab 15.6](https://gitlab.com/gitlab-org/gitlab/-/issues/370943) |
| **Require a pull request before merging - Require review from Code Owners**         | **Require approval from code owners** [branch protection setting](../protected_branches.md#require-code-owner-approval-on-a-protected-branch) **(PREMIUM)** | [GitLab 15.6](https://gitlab.com/gitlab-org/gitlab/-/issues/376683) |

Mapping GitHub rule **Require status checks to pass before merging** to
[external status checks](../merge_requests/status_checks.md) was considered in issue
[370948](https://gitlab.com/gitlab-org/gitlab/-/issues/370948). However, this rule is not imported during project import
into GitLab due to technical difficulties. You can still create [external status checks](../merge_requests/status_checks.md)
manually.

## Alternative way to import notes and diff notes

When GitHub Importer runs on extremely large projects not all notes & diff notes can be imported due to GitHub API `issues_comments` & `pull_requests_comments` endpoints limitation.
Not all pages can be fetched due to the following error coming from GitHub API: `In order to keep the API fast for everyone, pagination is limited for this resource. Check the rel=last link relation in the Link response header to see how far back you can traverse.`.

An [alternative approach](#select-additional-items-to-import) for importing comments is available.

Instead of using `issues_comments` and `pull_requests_comments`, use individual resources `issue_comments` and `pull_request_comments` instead to pull notes from one object at a time.
This allows us to carry over any missing comments, however it increases the number of network requests required to perform the import, which means its execution takes a longer time.

## Reduce GitHub API request objects per page

Some GitHub API endpoints may return a 500 or 502 error for project imports from large repositories.
To reduce the chance of such errors, you can enable the feature flag
`github_importer_lower_per_page_limit` in the group project importing the data. This reduces the
page size from 100 to 50.

To enable this feature flag, start a [Rails console](../../../administration/operations/rails_console.md#starting-a-rails-console-session)
and run the following `enable` command:

```ruby
group = Group.find_by_full_path('my/group/fullpath')

# Enable
Feature.enable(:github_importer_lower_per_page_limit, group)
```

To disable the feature, run this command:

```ruby
# Disable
Feature.disable(:github_importer_lower_per_page_limit, group)
```

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

WARNING:
For simplicity, the snippet does not have configuration to encrypt the connection between the client and the proxy. However, for security reasons you should include that
configuration. See [sample Apache TLS/SSL configuration](https://ssl-config.mozilla.org/#server=apache&version=2.4.41&config=intermediate&openssl=1.1.1k&guideline=5.6).

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

## Automate group and project import **(PREMIUM)**

For information on automating user, group, and project import API calls, see
[Automate group and project import](index.md#automate-group-and-project-import).

## Troubleshooting

### Manually continue a previously failed import process

In some cases, the GitHub import process can fail to import the repository. This causes GitLab to abort the project import process and requires the
repository to be imported manually. Administrators can manually import the repository for a failed import process:

1. Open a Rails console.
1. Run the following series of commands in the console:

   ```ruby
   project_id = <PROJECT_ID>
   github_access_token =  <GITHUB_ACCESS_TOKEN>
   github_repository_path = '<GROUP>/<REPOSITORY>'

   github_repository_url = "https://#{github_access_token}@github.com/#{github_repository_path}.git"

   # Find project by ID
   project = Project.find(project_id)
   # Set import URL and credentials
   project.import_url = github_repository_url
   project.import_type = 'github'
   project.import_source = github_repository_path
   project.save!
   # Create an import state if the project was created manually and not from a failed import
   project.create_import_state if project.import_state.blank?
   # Set state to start
   project.import_state.force_start
   # Trigger import from second step
   Gitlab::GithubImport::Stage::ImportRepositoryWorker.perform_async(project.id)
   ```
