---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
type: concepts, howto
---

# Repository **(FREE)**

A [repository](https://git-scm.com/book/en/v2/Git-Basics-Getting-a-Git-Repository)
is where you store your code and make changes to it. Your changes are tracked with version control.

Each [project](../index.md) contains a repository.

## Create a repository

To create a repository, you can:

- [Create a project](../../../user/project/working_with_projects.md#create-a-project) or
- [Fork an existing project](forking_workflow.md).

## Add files to a repository

You can add files to a repository:

- When you create a project.
- After you create a project:
  - By using [the web editor](web_editor.md).
  - [From the command line](../../../gitlab-basics/command-line-commands.md).

## Commit changes to a repository

You can [commit your changes](https://git-scm.com/book/en/v2/Git-Basics-Recording-Changes-to-the-Repository),
to a branch in the repository. When you use the command line, you can commit multiple times before you push.

- **Commit message:**
  A commit message identities what is being changed and why.
  In GitLab, you can add keywords to the commit
  message to perform one of the following actions:
  - **Trigger a GitLab CI/CD pipeline:**
  If the project is configured with [GitLab CI/CD](../../../ci/index.md),
  you trigger a pipeline per push, not per commit.
  - **Skip pipelines:**
  Add the [`ci skip`](../../../ci/yaml/index.md#skip-pipeline) keyword to
  your commit message to make GitLab CI/CD skip the pipeline.
  - **Cross-link issues and merge requests:**
  Use [cross-linking](../issues/crosslinking_issues.md#from-commit-messages)
  to keep track of related parts of your workflow.
  If you mention an issue or a merge request in a commit message, they are displayed
  on their respective thread.
- **Cherry-pick a commit:**
  In GitLab, you can
  [cherry-pick a commit](../merge_requests/cherry_pick_changes.md#cherry-picking-a-commit)
  from the UI.
- **Revert a commit:**
  [Revert a commit](../merge_requests/revert_changes.md#reverting-a-commit)
  from the UI to a selected branch.
- **Sign a commit:**
  Use GPG to [sign your commits](gpg_signed_commits/index.md).

## Clone a repository

You can [clone a repository by using the command line](../../../gitlab-basics/start-using-git.md#clone-a-repository).

Alternatively, you can clone directly into a code editor.

### Clone and open in Apple Xcode

> [Introduced](https://gitlab.com/gitlab-org/gitlab-foss/-/issues/45820) in GitLab 11.0.

Projects that contain a `.xcodeproj` or `.xcworkspace` directory can be cloned
into Xcode on macOS.

1. From the GitLab UI, go to the project's overview page.
1. Select **Clone**.
1. Select **Xcode**.

The project is cloned onto your computer and you are
prompted to open XCode.

### Clone and open in Visual Studio Code

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/220957) in GitLab 13.10.

All projects can be cloned into Visual Studio Code. To do that:

1. From the GitLab UI, go to the project's overview page.
1. Click **Clone**.
1. Select **Clone with Visual Studio Code** under either HTTPS or SSH method.
1. Select a folder to clone the project into.

When VS Code has successfully cloned your project, it opens the folder.

## Download the code in a repository

> - Support for directory download was [introduced](https://gitlab.com/gitlab-org/gitlab-foss/-/issues/24704) in GitLab 11.11.
> - Support for [including Git LFS blobs](../../../topics/git/lfs#lfs-objects-in-project-archives) was [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/15079) in GitLab 13.5.

You can download the source code that's stored in a repository.

1. Above the file list, select the download icon (**{download}**).
1. From the options, select the files you want to download.

   - **Source code:**
     Download the source code from the current branch you're viewing.
     Available extensions: `zip`, `tar`, `tar.gz`, and `tar.bz2`.
   - **Directory:**
     Download a specific directory. Visible only when you view a subdirectory.
     Available extensions: `zip`, `tar`, `tar.gz`, and `tar.bz2`.
   - **Artifacts:**
     Download the artifacts from the latest CI job.

## Repository languages

For the default branch of each repository, GitLab determines which programming languages
are used. This information is displayed on the **Project information** page.

![Repository Languages bar](img/repository_languages_v12_2.gif)

When new files are added, this information can take up to five minutes to update.

### Add repository languages

Not all files are detected and listed on the **Project information** page. Documentation,
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
| [Rdoc](http://rdoc.sourceforge.net/doc/index.html)  | `rdoc` |
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

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/19515) in GitLab 12.6.

GitLab can render OpenAPI specification files. The filename
must include `openapi` or `swagger` and the extension must be `yaml`,
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
1. Between the **Display source** and **Edit** buttons, select **Display OpenAPI**. When an OpenAPI file is found, it replaces the
   **Display rendered file** button.

## Repository size

The **Project information** page shows the size of all files in the repository. The size is
updated, at most, every 15 minutes. The file size includes repository files, artifacts, and LFS.

The size can differ slightly from one instance to another due to compression, housekeeping, and other factors.

Administrators can set a [repository size limit](../../admin_area/settings/account_and_limit_settings.md).
[GitLab sets the size limits for GitLab.com](../../gitlab_com/index.md#account-and-limit-settings).

## Repository contributor graph

All code contributors are displayed under your project's **Repository > Contributors**.

The graph shows the contributor with the most commits to the fewest.

![contributors to code](img/contributors_graph.png)

## Repository history graph

A repository graph displays a visual history of the repository network, including branches and merges.
This graph can help you visualize the Git flow strategy used in the repository.

Go to your project's **Repository > Graph**.

![repository Git flow](img/repo_graph.png)

## What happens when a repository path changes

When a repository path changes, GitLab handles the transition from the
old location to the new one with a redirect.

When you [rename a user](../../profile/index.md#change-your-username),
[change a group path](../../group/index.md#change-a-groups-path), or [rename a repository](../settings/index.md#renaming-a-repository):

- URLs for the namespace and everything under it, like projects, are
  redirected to the new URLs.
- Git remote URLs for projects under the
  namespace redirect to the new remote URL. When you push or pull to a
  repository that has changed location, a warning message to update
  your remote is displayed. Automation scripts or Git clients continue to
  work after a rename.
- The redirects are available as long as the original path is not claimed by
  another group, user, or project.

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

## Related topics

- To lock files and prevent change conflicts, use [file locking](../file_lock.md).
- [Repository API](../../../api/repositories.md).
- [Find files](file_finder.md) in a repository.
- [Branches](branches/index.md).
- [File templates](web_editor.md#template-dropdowns).
- [Create a directory](web_editor.md#create-a-directory).
- [Start a merge request](web_editor.md#tips).
- [Find file history](git_history.md).
- [Identify changes by line (Git blame)](git_blame.md).
- [Use Jupyter notebooks with GitLab](jupyter_notebooks/index.md).
