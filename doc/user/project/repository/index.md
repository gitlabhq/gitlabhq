---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: "How to create, clone, and use GitLab repositories."
---

# Repository

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, Self-managed, GitLab Dedicated

A [repository](https://git-scm.com/book/en/v2/Git-Basics-Getting-a-Git-Repository)
is where you store your code and make changes to it. Your changes are tracked with version control.

Each [project](../index.md) contains a repository.

## Create a repository

To create a repository, you can:

- [Create a project](../../../user/project/index.md) or
- [Fork an existing project](forking_workflow.md).

A repository cannot exist without a project. A project contains many things,
one of which is a repository.

## Add files to a repository

You can add files to a repository:

- When you create a project.
- After you create a project, by using:
  - [The web editor](web_editor.md#upload-a-file).
  - [The UI](#add-a-file-from-the-ui).
  - [The command line](../../../gitlab-basics/add-file.md).

### Add a file from the UI

You can upload a file from the GitLab UI.

<!-- Original source for this list: doc/user/project/repository/web_editor.md#upload-a-file -->
<!-- For why we duplicated the info, see https://gitlab.com/gitlab-org/gitlab/-/merge_requests/111072#note_1267429478 -->

1. On the left sidebar, select **Search or go to** and find your project.
1. Go to the directory where you want to upload the file.
1. Next to the directory name, select the plus icon (**{plus}**) > **Upload file**.
1. Complete the fields.
   To create a merge request with your changes, enter a branch name
   that's not your repository's [default branch](branches/default.md).
1. Select **Upload file**.

## Commit changes to a repository

You can [commit your changes](https://git-scm.com/book/en/v2/Git-Basics-Recording-Changes-to-the-Repository),
to a branch in the repository. When you use the command line, you can commit multiple times before you push.

- **Commit message:**
  A commit message identifies what is being changed and why.
  In GitLab, you can add keywords to the commit
  message to perform one of the following actions:
  - **Trigger a GitLab CI/CD pipeline:**
    If the project is configured with [GitLab CI/CD](../../../ci/index.md),
    you trigger a pipeline per push, not per commit.
  - **Skip pipelines:**
    Add the [`ci skip`](../../../ci/pipelines/index.md#skip-a-pipeline) keyword to
    your commit message to make GitLab CI/CD skip the pipeline.
  - **Cross-link issues and merge requests:**
    Use [cross-linking](../issues/crosslinking_issues.md#from-commit-messages)
    to keep track of related parts of your workflow.
    If you mention an issue or a merge request in a commit message, they are displayed
    on their respective thread.
- **Cherry-pick a commit:**
  In GitLab, you can
  [cherry-pick a commit](../merge_requests/cherry_pick_changes.md#cherry-pick-a-single-commit)
  from the UI.
- **Revert a commit:**
  [Revert a commit](../merge_requests/revert_changes.md#revert-a-commit)
  from the UI to a selected branch.
- **Sign a commit:**
  Add extra security by [signing your commits](signed_commits/index.md).

## Clone a repository

You can [clone a repository by using the command line](../../../topics/git/get_started.md#cloning-git-repositories).

Alternatively, you can clone directly into a code editor.

### Clone and open in Apple Xcode

Projects that contain a `.xcodeproj` or `.xcworkspace` directory can be cloned
into Xcode on macOS.

1. From the GitLab UI, go to the project's overview page.
1. In the upper-right corner, select **Code**.
1. Select **Xcode**.

The project is cloned onto your computer and you are
prompted to open Xcode.

### Clone and open in Visual Studio Code

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/220957) in GitLab 13.10.

All projects can be cloned into Visual Studio Code from the GitLab user interface, but you
can also install the [GitLab Workflow VS Code extension](../../../editor_extensions/visual_studio_code/index.md) to clone from
Visual Studio Code:

- From the GitLab interface:
  1. Go to the project's overview page.
  1. In the upper-right corner, select **Code**.
  1. Under **Open in your IDE**, select **Visual Studio Code (SSH)** or **Visual Studio Code (HTTPS)**.
  1. Select a folder to clone the project into.

     After Visual Studio Code clones your project, it opens the folder.
- From Visual Studio Code, with the [extension](../../../editor_extensions/visual_studio_code/index.md) installed, use the
  extension's [`Git: Clone` command](https://marketplace.visualstudio.com/items?itemName=GitLab.gitlab-workflow#clone-gitlab-projects).

### Clone and open in IntelliJ IDEA

All projects can be cloned into [IntelliJ IDEA](https://www.jetbrains.com/idea/)
from the GitLab user interface.

Prerequisites:

- The [JetBrains Toolbox App](https://www.jetbrains.com/toolbox-app/) must be also be installed.

To do this:

1. Go to the project's overview page.
1. In the upper-right corner, select **Code**.
1. Under **Open in your IDE**, select **IntelliJ IDEA (SSH)** or **IntelliJ IDEA (HTTPS)**.

## Download the code in a repository

You can download the source code that's stored in a repository.

1. On the left sidebar, select **Search or go to** and find your project.
1. Above the file list, select **Code**.
1. From the options, select the files you want to download.

   - **Source code:**
     Download the source code from the current branch you're viewing.
     Available extensions: `zip`, `tar`, `tar.gz`, and `tar.bz2`.
   - **Directory:**
     Download a specific directory. Visible only when you view a subdirectory.
     Available extensions: `zip`, `tar`, `tar.gz`, and `tar.bz2`.
   - **Artifacts:**
     Download the artifacts from the latest CI job.

The checksums of generated archives can change even if the repository itself doesn't
change. This can occur, for example, if Git or a third-party library that GitLab uses changes.

## Repository languages

For the default branch of each repository, GitLab determines which programming languages
are used. This information is displayed on the **Project overview** page.

![Repository Languages bar](img/repository_languages_v15_2.png)

When new files are added, this information can take up to five minutes to update.

### Add repository languages

Not all files are detected and listed on the **Project overview** page. Documentation,
vendor code, and most markup languages are excluded.

You can change this behavior by overriding the default settings.

1. In your repository's root directory, create a file named `.gitattributes`.
1. Add a line that tells GitLab to include files of this type. For example,
   to enable `.proto` files, add the following code:

   ```plaintext
   *.proto linguist-detectable=true
   ```

View a list of
[supported data types](https://github.com/github/linguist/blob/master/lib/linguist/languages.yml).

This feature can use excessive CPU.
For more information, see the [troubleshooting section](#repository-languages-excessive-cpu-use).

### Supported markup languages

If your file has one of the following file extensions, GitLab renders the
contents of the file's [markup language](https://en.wikipedia.org/wiki/Lightweight_markup_language) in the UI.

| Markup language | Extensions |
| --------------- | ---------- |
| Plain text | `txt` |
| [Markdown](../../markdown.md) | `mdown`, `mkd`, `mkdn`, `md`, `markdown` |
| [reStructuredText](https://docutils.sourceforge.io/rst.html) | `rst` |
| [AsciiDoc](../../asciidoc.md) | `adoc`, `ad`, `asciidoc` |
| [Textile](https://textile-lang.com/) | `textile` |
| [Rdoc](https://rdoc.sourceforge.net/doc/index.html)  | `rdoc` |
| [Org mode](https://orgmode.org/) | `org` |
| [creole](http://www.wikicreole.org/) | `creole` |
| [MediaWiki](https://www.mediawiki.org/wiki/MediaWiki) | `wiki`, `mediawiki` |

### README and index files

When a `README` or `index` file is present in a repository, GitLab renders its contents.
These files can either be plain text or have the extension of a
[supported markup language](#supported-markup-languages).

- When both a `README` and an `index` file are present, the `README` always
  takes precedence.
- When multiple files have the same name but a different extension, the files are
  ordered alphabetically. Any file without an extension is ordered last.
  For example, `README.adoc` takes precedence over `README.md`, and `README.rst`
  takes precedence over `README`.

### OpenAPI viewer

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/19515) in GitLab 12.6.

GitLab can render OpenAPI specification files. The filename must include `openapi` or `swagger` and the extension must be `yaml`,
`yml`, or `json`. The following examples are all correct:

- `openapi.yml`
- `openapi.yaml`
- `openapi.json`
- `swagger.yml`
- `swagger.yaml`
- `swagger.json`
- `gitlab_swagger.yml`
- `openapi_gitlab.yml`
- `OpenAPI.YML`
- `openapi.Yaml`
- `openapi.JSON`
- `openapi.gitlab.yml`
- `gitlab.openapi.yml`

To render an OpenAPI file:

1. Go to the OpenAPI file in your repository.
1. Select **Display rendered file**.
1. To display the `operationId` in the operations list, add `displayOperationId=true` to the query string.

NOTE:
When `displayOperationId` is present in the query string and has _any_ value, it
evaluates to `true`. This behavior matches the default behavior of Swagger.

## Repository size

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/368150) in GitLab 15.3, feature flags `gitaly_revlist_for_repo_size` and `gitaly_catfile_repo_size` for alternative repository size calculations.

FLAG:
On self-managed GitLab, by default GitLab uses the `du -sk` command to determine the size of a repository. GitLab can use either
`git-rev-list` (enabled with feature flag `gitaly_revlist_for_repo_size`) or `git-cat-file` (enabled with feature flag
`gitaly_catfile_repo_size`) instead. To switch between different calculation methods, an administrator can
[enable or disable](../../../administration/feature_flags.md) these feature flags.

The **Project overview** page shows the size of all files in the repository. The size is
updated, at most, every 15 minutes. The file size includes repository files, artifacts, and LFS.

The size can differ slightly from one instance to another due to compression, housekeeping, and other factors.

Administrators can set a [repository size limit](../../../administration/settings/account_and_limit_settings.md).
[GitLab sets the size limits for GitLab.com](../../gitlab_com/index.md#account-and-limit-settings).

## Repository contributor analytics

You can view a list and charts of commits made by project members in [Contributor analytics](../../analytics/contributor_analytics.md).

## Repository history graph

A repository graph displays a visual history of the repository network, including branches and merges.
This graph can help you visualize the Git flow strategy used in the repository.

Go to your project's **Code > Repository graph**.

![repository Git flow](img/repo_graph.png)

## What happens when a repository path changes

When a repository path changes, GitLab handles the transition from the
old location to the new one with a redirect.

When you [rename a user](../../profile/index.md#change-your-username),
[change a group path](../../group/manage.md#change-a-groups-path), or [rename a repository](../../project/working_with_projects.md#rename-a-repository):

- URLs for the namespace and everything under it, like projects, are
  redirected to the new URLs.
- Git remote URLs for projects under the
  namespace redirect to the new remote URL. When you push or pull to a
  repository that has changed location, a warning message to update
  your remote is displayed. Automation scripts or Git clients continue to
  work after a rename.
- The redirects are available as long as the original path is not claimed by
  another group, user, or project.
- [API redirects](../../../api/rest/index.md#redirects) may need to be followed explicitly.

After you change a path, you must update the existing URL in the following resources,
because they can't follow redirects:

- [Include statements](../../../ci/yaml/includes.md) except [`include:component`](../../../ci/components/index.md), otherwise pipelines fail with a syntax error. CI/CD component references can follow redirects.
- Namespaced API calls that use the [encoded path](../../../api/rest/index.md#namespaced-path-encoding) instead of the numeric namespace and project IDs.
- [Docker image references](../../../ci/yaml/index.md#image).
- Variables that specify a project or namespace.

## Related topics

- [GitLab Workflow VS Code extension](../../../editor_extensions/visual_studio_code/index.md)
- [Lock files and prevent change conflicts](../file_lock.md)
- [Repository API](../../../api/repositories.md)
- [Find files](file_finder.md)
- [Branches](branches/index.md)
- [Create a directory](web_editor.md#create-a-directory)
- [Find file history](git_history.md)
- [Identify changes by line (Git blame)](git_blame.md)
- [Use Jupyter notebooks with GitLab](jupyter_notebooks/index.md)

## Troubleshooting

### Repository Languages: excessive CPU use

To determine which languages are in a repository's files, GitLab uses a Ruby gem.
When the gem parses a file to determine which type it is, [the process can use excessive CPU](https://gitlab.com/gitlab-org/gitaly/-/issues/1565).
The gem contains a [heuristics configuration file](https://github.com/github/linguist/blob/master/lib/linguist/heuristics.yml)
that defines which file extensions must be parsed.

Files with the `.txt` extension and XML files with an extension not defined by the gem can take excessive CPU.

The workaround is to specify the language to assign to specific file extensions.
The same approach should also allow misidentified file types to be fixed.

1. Identify the language to specify. The gem contains a [configuration file for known data types](https://github.com/github/linguist/blob/master/lib/linguist/languages.yml).
   To add an entry for text files, for example:

   ```yaml
   Text:
     type: prose
     wrap: true
     aliases:
     - fundamental
     - plain text
     extensions:
     - ".txt"
   ```

1. Add or modify `.gitattributes` in the root of your repository:

   ```plaintext
   *.txt linguist-language=Text
   ```

  `*.txt` files have an entry in the heuristics file. This example prevents parsing of these files.

### Search sequence of pushes to a repository

If it seems that a commit has gone "missing", search the sequence of pushes to a repository.
[This StackOverflow article](https://stackoverflow.com/questions/13468027/the-mystery-of-the-missing-commit-across-merges)
describes how you can end up in this state without a force push. Another cause can be a misconfigured [server hook](../../../administration/server_hooks.md) that changes a HEAD ref in a `git reset` operation.

If you look at the output from the sample code below for the target branch, you
see a discontinuity in the from/to commits as you step through the output.
The `commit_from` of each new push should equal the `commit_to` of the previous push.
A break in that sequence indicates one or more commits have been "lost" from the repository history.

Using the [rails console](../../../administration/operations/rails_console.md#starting-a-rails-console-session), the following example checks the last 100 pushes and prints the `commit_from` and `commit_to` entries:

```ruby
p = Project.find_by_full_path('project/path')
p.events.pushed_action.last(100).each do |e|
  puts "%-20.20s %8s...%8s (%s)", e.push_event_payload[:ref], e.push_event_payload[:commit_from], e.push_event_payload[:commit_to], e.author.try(:username)
end ; nil
```

Example output showing break in sequence at line 4:

```plaintext
master f21b07713251e04575908149bdc8ac1f105aabc3...6bc56c1f46244792222f6c85b11606933af171de root
master 6bc56c1f46244792222f6c85b11606933af171de...132da6064f5d3453d445fd7cb452b148705bdc1b root
master 132da6064f5d3453d445fd7cb452b148705bdc1b...a62e1e693150a2e46ace0ce696cd4a52856dfa65 root
master 58b07b719a4b0039fec810efa52f479ba1b84756...f05321a5b5728bd8a89b7bf530aa44043c951dce root
master f05321a5b5728bd8a89b7bf530aa44043c951dce...7d02e575fd790e76a3284ee435368279a5eb3773 root
```
