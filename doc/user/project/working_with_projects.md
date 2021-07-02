---
stage: Create
group: Source Code
info: "To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments"
---

# Working with projects **(FREE)**

Most work in GitLab is done in a [project](../../user/project/index.md). Files and
code are saved in projects, and most features are in the scope of projects.

## Explore projects

You can explore other popular projects available on GitLab. To explore projects:

1. On the top bar, select **Menu > Project**.
1. Select **Explore Projects**.

GitLab displays a list of projects, sorted by last updated date. To view
projects with the most [stars](#star-a-project), click **Most stars**. To view
projects with the largest number of comments in the past month, click **Trending**.

## Create a project

To create a project in GitLab:

1. In your dashboard, click the green **New project** button or use the plus
   icon in the navigation bar. This opens the **New project** page.
1. On the **New project** page, choose if you want to:
   - Create a [blank project](#blank-projects).
   - Create a project using one of the available [project templates](#project-templates).
   - [Import a project](../../user/project/import/index.md) from a different repository,
     if enabled on your GitLab instance. Contact your GitLab administrator if this is unavailable.
   - Run [CI/CD pipelines for external repositories](../../ci/ci_cd_for_external_repos/index.md). **(PREMIUM)**

NOTE:
For a list of words that can't be used as project names see
[Reserved project and group names](../../user/reserved_names.md).

### Blank projects

To create a new blank project on the **New project** page:

1. Click **Create blank project**
1. Provide the following information:
   - The name of your project in the **Project name** field. You can't use
     special characters, but you can use spaces, hyphens, underscores, or even
     emoji. When adding the name, the **Project slug** auto populates.
     The slug is what the GitLab instance uses as the URL path to the project.
     If you want a different slug, input the project name first,
     then change the slug after.
   - The path to your project in the **Project slug** field. This is the URL
     path for your project that the GitLab instance uses. If the
     **Project name** is blank, it auto populates when you fill in
     the **Project slug**.
   - The **Project description (optional)** field enables you to enter a
     description for your project's dashboard, which helps others
     understand what your project is about. Though it's not required, it's a good
     idea to fill this in.
   - Changing the **Visibility Level** modifies the project's
     [viewing and access rights](../../public_access/public_access.md) for users.
   - Selecting the **Initialize repository with a README** option creates a
     README file so that the Git repository is initialized, has a default branch, and
     can be cloned.
1. Click **Create project**.

### Project templates

Project templates can pre-populate a new project with the necessary files to get you
started quickly.

There are two main types of project templates:

- [Built-in templates](#built-in-templates), sourced from the following groups:
  - [`project-templates`](https://gitlab.com/gitlab-org/project-templates)
  - [`pages`](https://gitlab.com/pages)
- [Custom project templates](#custom-project-templates), for custom templates
  configured by GitLab administrators and users.

#### Built-in templates

Built-in templates are project templates that are:

- Developed and maintained in the [`project-templates`](https://gitlab.com/gitlab-org/project-templates)
  and [`pages`](https://gitlab.com/pages) groups.
- Released with GitLab.
- Anyone can contribute a built-in template by following [these steps](https://about.gitlab.com/community/contribute/project-templates/).

To use a built-in template on the **New project** page:

1. Click **Create from template**
1. Select the **Built-in** tab.
1. From the list of available built-in templates, click the:
   - **Preview** button to look at the template source itself.
   - **Use template** button to start creating the project.
1. Finish creating the project by filling out the project's details. The process is
   the same as creating a [blank project](#blank-projects).

##### Enterprise templates **(ULTIMATE)**

GitLab is developing Enterprise templates to help you streamline audit management with selected regulatory standards. These templates automatically import issues that correspond to each regulatory requirement.

To create a new project with an Enterprise template, on the **New project** page:

1. Click **Create from template**
1. Select the **Built-in** tab.
1. From the list of available built-in Enterprise templates, click the:
   - **Preview** button to look at the template source itself.
   - **Use template** button to start creating the project.
1. Finish creating the project by filling out the project's details. The process is the same as creating a [blank project](#blank-projects).

Available Enterprise templates include:

- HIPAA Audit Protocol template ([introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/13756) in GitLab 12.10)

NOTE:
You can improve the existing built-in templates or contribute new ones in the
[`project-templates`](https://gitlab.com/gitlab-org/project-templates) and
[`pages`](https://gitlab.com/pages) groups by following [these steps](https://gitlab.com/gitlab-org/project-templates/contributing).

##### Custom project templates **(PREMIUM)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/6860) in [GitLab Premium](https://about.gitlab.com/pricing/) 11.2.

Creating new projects based on custom project templates is a convenient option for
quickly starting projects.

Custom projects are available at the [instance-level](../../user/admin_area/custom_project_templates.md)
from the **Instance** tab, or at the [group-level](../../user/group/custom_project_templates.md)
from the **Group** tab, on the **Create from template** page.

To use a custom project template on the **New project** page:

1. Click **Create from template**
1. Select the **Instance** tab or the **Group** tab.
1. From the list of available custom templates, click the:
   - **Preview** button to look at the template source itself.
   - **Use template** button to start creating the project.
1. Finish creating the project by filling out the project's details. The process is
   the same as creating a [blank project](#blank-projects).

## Push to create a new project

> [Introduced](https://gitlab.com/gitlab-org/gitlab-foss/-/issues/26388) in GitLab 10.5.

When you create a new repository locally, instead of manually creating a new project in GitLab
and then [cloning the repository](../../gitlab-basics/start-using-git.md#clone-a-repository)
locally, you can directly push it to GitLab to create the new project, all without leaving
your terminal. If you have access rights to the associated namespace, GitLab
automatically creates a new project under that GitLab namespace with its visibility
set to Private by default (you can later change it in the [project's settings](../../public_access/public_access.md#how-to-change-project-visibility)).

This can be done by using either SSH or HTTPS:

```shell
## Git push using SSH
git push --set-upstream git@gitlab.example.com:namespace/nonexistent-project.git master

## Git push using HTTPS
git push --set-upstream https://gitlab.example.com/namespace/nonexistent-project.git master
```

You can pass the flag `--tags` to the `git push` command to export existing repository tags.

Once the push finishes successfully, a remote message indicates
the command to set the remote and the URL to the new project:

```plaintext
remote:
remote: The private project namespace/nonexistent-project was created.
remote:
remote: To configure the remote, run:
remote:   git remote add origin https://gitlab.example.com/namespace/nonexistent-project.git
remote:
remote: To view the project, visit:
remote:   https://gitlab.example.com/namespace/nonexistent-project
remote:
```

## Fork a project

A fork is a copy of an original repository that you put in another namespace
where you can experiment and apply changes that you can later decide whether or
not to share, without affecting the original project.

It takes just a few steps to [fork a project in GitLab](repository/forking_workflow.md#creating-a-fork).

## Star a project

You can star a project to make it easier to find projects you frequently use.
The number of stars a project has can indicate its popularity.

To star a project:

1. Go to the home page of the project you want to star.
1. In the upper right corner of the page, click **Star**.

To view your starred projects:

1. On the top bar, select **Menu > Project**.
1. Select **Starred Projects**.
1. GitLab displays information about your starred projects, including:

   - Project description, including name, description, and icon
   - Number of times this project has been starred
   - Number of times this project has been forked
   - Number of open merge requests
   - Number of open issues

## Delete a project

To delete a project, first navigate to the home page for that project.

1. Navigate to **Settings > General**.
1. Expand the **Advanced** section.
1. Scroll down to the **Delete project** section.
1. Click **Delete project**
1. Confirm this action by typing in the expected text.

Projects in personal namespaces are deleted immediately on request. For information on delayed deletion of projects in a group, please see [Enable delayed project removal](../group/index.md#enable-delayed-project-removal).

## Project settings

Set the project's visibility level and the access levels to its various pages
and perform actions like archiving, renaming or transferring a project.

Read through the documentation on [project settings](settings/index.md).

## Project activity

To view the activity of a project:

1. On the left sidebar, select **Project information > Activity**.
1. Select a tab to view **All** the activity, or to filter it by any of these criteria:
   - **Push events**
   - **Merge events**
   - **Issue events**
   - **Comments**
   - **Team**
   - **Wiki**

### Leave a project

**Leave project** only displays on the project's dashboard
when a project is part of a group (under a
[group namespace](../group/index.md#namespaces)).
If you choose to leave a project you are no longer a project
member, and cannot contribute.

## Use your project as a Go package

Any project can be used as a Go package. GitLab responds correctly to `go get`
and `godoc.org` discovery requests, including the
[`go-import`](https://golang.org/cmd/go/#hdr-Remote_import_paths) and
[`go-source`](https://github.com/golang/gddo/wiki/Source-Code-Links) meta tags.

Private projects, including projects in subgroups, can be used as a Go package,
but may require configuration to work correctly. GitLab responds correctly
to `go get` discovery requests for projects that *are not* in subgroups,
regardless of authentication or authorization.
[Authentication](#authenticate-go-requests) is required to use a private project
in a subgroup as a Go package. Otherwise, GitLab truncates the path for
private projects in subgroups to the first two segments, causing `go get` to
fail.

GitLab implements its own Go proxy. This feature must be enabled by an
administrator and requires additional configuration. See [GitLab Go
Proxy](../packages/go_proxy/index.md).

### Disable Go module features for private projects

In Go 1.12 and later, Go queries module proxies and checksum databases in the
process of [fetching a
module](../../development/go_guide/dependencies.md#fetching). This can be
selectively disabled with `GOPRIVATE` (disable both),
[`GONOPROXY`](../../development/go_guide/dependencies.md#proxies) (disable proxy
queries), and [`GONOSUMDB`](../../development/go_guide/dependencies.md#fetching)
(disable checksum queries).

`GOPRIVATE`, `GONOPROXY`, and `GONOSUMDB` are comma-separated lists of Go
modules and Go module prefixes. For example,
`GOPRIVATE=gitlab.example.com/my/private/project` disables queries for that
one project, but `GOPRIVATE=gitlab.example.com` disables queries for *all*
projects on GitLab.com. Go does not query module proxies if the module name or a
prefix of it appears in `GOPRIVATE` or `GONOPROXY`. Go does not query checksum
databases if the module name or a prefix of it appears in `GONOPRIVATE` or
`GONOSUMDB`.

### Authenticate Go requests

To authenticate requests to private projects made by Go, use a [`.netrc`
file](https://everything.curl.dev/usingcurl/netrc) and a [personal access
token](../profile/personal_access_tokens.md) in the password field. **This only
works if your GitLab instance can be accessed with HTTPS.** The `go` command
does not transmit credentials over insecure connections. This authenticates
all HTTPS requests made directly by Go, but does not authenticate requests made
through Git.

For example:

```plaintext
machine gitlab.example.com
login <gitlab_user_name>
password <personal_access_token>
```

NOTE:
On Windows, Go reads `~/_netrc` instead of `~/.netrc`.

### Authenticate Git fetches

If a module cannot be fetched from a proxy, Go falls back to using Git (for
GitLab projects). Git uses `.netrc` to authenticate requests. You can also
configure Git to either:

- Embed specific credentials in the request URL.
- Use SSH instead of HTTPS, as Go always uses HTTPS to fetch Git repositories.

```shell
# Embed credentials in any request to GitLab.com:
git config --global url."https://${user}:${personal_access_token}@gitlab.example.com".insteadOf "https://gitlab.example.com"

# Use SSH instead of HTTPS:
git config --global url."git@gitlab.example.com".insteadOf "https://gitlab.example.com"
```

## Access project page with project ID

> [Introduced](https://gitlab.com/gitlab-org/gitlab-foss/-/issues/53671) in GitLab 11.8.

To quickly access a project from the GitLab UI using the project ID,
visit the `/projects/:id` URL in your browser or other tool accessing the project.

## Project's landing page

The project's landing page shows different information depending on
the project's visibility settings and user permissions.

For public projects, and to members of internal and private projects
with [permissions to view the project's code](../permissions.md#project-members-permissions):

- The content of a
  [`README` or an index file](repository/index.md#readme-and-index-files)
  is displayed (if any), followed by the list of directories in the
  project's repository.
- If the project doesn't contain either of these files, the
  visitor sees the list of files and directories of the repository.

For users without permissions to view the project's code, GitLab displays:

- The wiki homepage, if any.
- The list of issues in the project.
