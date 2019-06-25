---
description: Learn how to contribute to GitLab Documentation.
---

# GitLab Documentation guidelines

GitLab's documentation is [intended as the single source of truth (SSOT)](https://about.gitlab.com/handbook/documentation/) for information about how to configure, use, and troubleshoot GitLab. The documentation contains use cases and usage instructions covering every GitLab feature, organized by product area and subject. This includes topics and workflows that span multiple GitLab features, as well as the use of GitLab with other applications.

In addition to this page, the following resources to help craft and contribute documentation are available:

- [Style Guide](styleguide.md) - What belongs in the docs, language guidelines, and more.
- [Structure and template](structure.md) - Learn the typical parts of a doc page and how to write each one.
- [Workflows](workflow.md) - A landing page for our key workflows:
  - [Documentation process for feature changes](feature-change-workflow.md) - Adding required documentation when developing a GitLab feature.
  - [Documentation improvement workflow](improvement-workflow.md) - New content not associated with a new feature.
- [Markdown Guide](https://about.gitlab.com/handbook/product/technical-writing/markdown-guide/) - A reference for the markdown implementation used by GitLab's documentation site and about.gitlab.com.
- [Site architecture](site_architecture/index.md) - How docs.gitlab.com is built.

## Source files and rendered web locations

Documentation for GitLab Community Edition (CE) and Enterprise Edition (EE), along with GitLab Runner and Omnibus, is published to [docs.gitlab.com](https://docs.gitlab.com). The documentation for CE and EE is also published within the application at `/help` on the domain of the GitLab instance.

At `/help`, only content for your current edition and version is included, whereas multiple versions' content is available at docs.gitlab.com.

The source of the documentation exists within the codebase of each GitLab application in the following repository locations:

| Project | Path |
| --- | --- |
| [GitLab Community Edition](https://gitlab.com/gitlab-org/gitlab-ce/) | [`/doc`](https://gitlab.com/gitlab-org/gitlab-ce/tree/master/doc) |
| [GitLab Enterprise Edition](https://gitlab.com/gitlab-org/gitlab-ee/) | [`/doc`](https://gitlab.com/gitlab-org/gitlab-ee/tree/master/doc) |
| [GitLab Runner](https://gitlab.com/gitlab-org/gitlab-runner/) | [`/docs`](https://gitlab.com/gitlab-org/gitlab-runner/tree/master/docs) |
| [Omnibus GitLab](https://gitlab.com/gitlab-org/omnibus-gitlab/) | [`/doc`](https://gitlab.com/gitlab-org/gitlab-ee/tree/master/doc) |

Documentation issues and merge requests are part of their respective repositories and all have the label `Documentation`.

## Contributing to docs

[Contributions to GitLab docs](workflow.md) are welcome from the entire GitLab community.

To ensure that GitLab docs keep up with changes to the product, special processes and responsibilities are in place concerning all [feature changes](feature-change-workflow.md)—i.e. development work that impacts the appearance, usage, or administration of a feature.

Meanwhile, anyone can contribute [documentation improvements](improvement-workflow.md) large or small that are not associated with a feature change. For example, adding a new doc on how to accomplish a use case that's already possible with GitLab or with third-party tools and GitLab.

## Markdown and styles

[GitLab docs](https://gitlab.com/gitlab-com/gitlab-docs) uses [GitLab Kramdown](https://gitlab.com/gitlab-org/gitlab_kramdown)
as its markdown rendering engine. See the [GitLab Markdown Guide](https://about.gitlab.com/handbook/product/technical-writing/markdown-guide/) for a complete Kramdown reference.

Adhere to the [Documentation Style Guide](styleguide.md). If a style standard is missing, you are welcome to suggest one via a merge request.

## Folder structure and files

See the [Structure](styleguide.md#structure) section of the [Documentation Style Guide](styleguide.md).

## Single codebase

We currently maintain two sets of docs: one in the
[gitlab-ce](https://gitlab.com/gitlab-org/gitlab-ce/tree/master/doc) repo and
one in [gitlab-ee](https://gitlab.com/gitlab-org/gitlab-ee/tree/master/doc).
They are similar, and most pages are identical, but they are different repositories.
With the single codebase effort, we want to make those two sets identical, so when the
time comes to have only one codebase, we'll be ready.

Here are some links to get you up to speed with the current effort:

- [CE/EE codebases blueprint](https://about.gitlab.com/handbook/engineering/infrastructure/blueprint/ce-ee-codebases/)
- [CE/EE codebases merge design](https://about.gitlab.com/handbook/engineering/infrastructure/design/merge-ce-ee-codebases/)
- [Single docs codebase epic](https://gitlab.com/groups/gitlab-org/-/epics/199)
- [Issue board of related issues](https://gitlab.com/groups/gitlab-org/-/boards/981090?&label_name[]=Documentation&label_name[]=single%20codebase)
- [Related merge requests](https://gitlab.com/groups/gitlab-org/-/merge_requests?scope=all&utf8=%E2%9C%93&state=all&label_name[]=Documentation&label_name[]=single%20codebase)
- [Visualize the existing diffs](https://leipert-projects.gitlab.io/is-gitlab-pretty-yet/diff/?search=%5Edoc)

### CE first

After a given documentation path is aligned across CE and EE, all merge requests
affecting that path must be submitted to CE, regardless of the content it has.
This means that:

- For **EE-only docs changes**, you only have to submit a CE MR.
- For **EE-only features** that touch both the code and the docs, you have to submit
  an EE MR containing all changes, and a CE MR containing only the docs changes
  and without a changelog entry.

This might seem like a duplicate effort, but it's only for the short term.
A list of the already aligned docs can be found in
[the epic description](https://gitlab.com/groups/gitlab-org/-/epics/199#ee-specific-lines-check).

Since the docs will be combined, it's crucial to add the relevant
[product badges](styleguide.md#product-badges) for all EE documentation, so that
we can discern which features belong to which tier.

### EE specific lines check

There's a special test in place
([`ee_specific_check.rb`](https://gitlab.com/gitlab-org/gitlab-ee/blob/master/scripts/ee_specific_check/ee_specific_check.rb)),
which, among others, checks and prevents creating/editing new files and directories
in EE under `doc/`.

We have a long list of documentation paths that are either whitelisted or not.
Paths in the whitelist (not commented out) will not be subject to the test,
which means you are allowed to create/change docs content in EE for the time
being. The goal is to not have any doc whitelisted.

At the time of this writing, the only items left to be aligned are the API docs:

- `doc/api/*` ([issue](https://gitlab.com/gitlab-org/gitlab-ce/issues/60045) / [merge request](https://gitlab.com/gitlab-org/gitlab-ce/merge_requests/27491))

Eventually, once all docs are aligned, we'll remove any doc reference from that
script, so it catches everything.

## Changing document location

Changing a document's location requires specific steps to be followed to ensure that
users can seamlessly access the new doc page, whether they are accesing content
on a GitLab instance domain at `/help` or at docs.gitlab.com. Be sure to ping a
GitLab technical writer if you have any questions during the process (such as
whether the move is necessary), and ensure that a technical writer reviews this
change prior to merging.

If you indeed need to change a document's location, do not remove the old
document, but rather replace all of its content with a new line:

```md
This document was moved to [another location](path/to/new_doc.md).
```

where `path/to/new_doc.md` is the relative path to the root directory `doc/`.

---

For example, if you were to move `doc/workflow/lfs/lfs_administration.md` to
`doc/administration/lfs.md`, then the steps would be:

1. Copy `doc/workflow/lfs/lfs_administration.md` to `doc/administration/lfs.md`
1. Replace the contents of `doc/workflow/lfs/lfs_administration.md` with:

    ```md
    This document was moved to [another location](../../administration/lfs.md).
    ```

1. Find and replace any occurrences of the old location with the new one.
   A quick way to find them is to use `git grep`. First go to the root directory
   where you cloned the `gitlab-ce` repository and then do:

    ```sh
    git grep -n "workflow/lfs/lfs_administration"
    git grep -n "lfs/lfs_administration"
    ```

NOTE: **Note:**
If the document being moved has any Disqus comments on it, there are extra steps
to follow documented just [below](#redirections-for-pages-with-disqus-comments).

Things to note:

- Since we also use inline documentation, except for the documentation itself,
  the document might also be referenced in the views of GitLab (`app/`) which will
  render when visiting `/help`, and sometimes in the testing suite (`spec/`).
  You must search these paths for references to the doc and update them as well.
- The above `git grep` command will search recursively in the directory you run
  it in for `workflow/lfs/lfs_administration` and `lfs/lfs_administration`
  and will print the file and the line where this file is mentioned.
  You may ask why the two greps. Since we use relative paths to link to
  documentation, sometimes it might be useful to search a path deeper.
- The `*.md` extension is not used when a document is linked to GitLab's
  built-in help page, that's why we omit it in `git grep`.
- Use the checklist on the "Change documentation location" MR description template.

### Alternative redirection method

Alternatively to the method described above, you can simply replace the content
of the old file with a frontmatter containing a redirect link:

```yaml
---
redirect_to: '../path/to/file/README.md'
---
```

It supports both full and relative URLs, e.g. `https://docs.gitlab.com/ee/path/to/file.html`, `../path/to/file.html`, `path/to/file.md`. Note that any `*.md` paths will be compiled to `*.html`.

NOTE: **Note:**
This redirection method will not provide a redirect fallback on GitLab `/help`. When using
it, make sure to add a link to the new page on the doc, otherwise it's a dead end for users that
land on the doc via `/help`.

### Redirections for pages with Disqus comments

If the documentation page being relocated already has any Disqus comments,
we need to preserve the Disqus thread.

Disqus uses an identifier per page, and for docs.gitlab.com, the page identifier
is configured to be the page URL. Therefore, when we change the document location,
we need to preserve the old URL as the same Disqus identifier.

To do that, add to the frontmatter the variable `redirect_from`,
using the old URL as value. For example, let's say I moved the document
available under `https://docs.gitlab.com/my-old-location/README.html` to a new location,
`https://docs.gitlab.com/my-new-location/index.html`.

Into the **new document** frontmatter add the following:

```yaml
---
redirect_from: 'https://docs.gitlab.com/my-old-location/README.html'
---
```

Note: it is necessary to include the file name in the `redirect_from` URL,
even if it's `index.html` or `README.html`.

## Branch naming

If your contribution contains **only** documentation changes, you can speed up
the CI process by following some branch naming conventions. You have three
choices:

| Branch name           | Valid example                |
|:----------------------|:-----------------------------|
| Starting with `docs/` | `docs/update-api-issues`     |
| Starting with `docs-` | `docs-update-api-issues`     |
| Ending in `-docs`     | `123-update-api-issues-docs` |

If your branch name matches any of the above, it will run only the docs
tests. If it does not, the whole application test suite will run (including docs tests).

## Merge requests for GitLab documentation

Before getting started, make sure you read the introductory section
"[contributing to docs](#contributing-to-docs)" above and the
[documentation workflow](workflow.md).

- Use the current [merge request description template](https://gitlab.com/gitlab-org/gitlab-ce/blob/master/.gitlab/merge_request_templates/Documentation.md)
- Use the correct [branch name](#branch-naming)
- Label the MR `Documentation`
- Assign the correct milestone (see note below)

Documentation will be merged if it is an improvement on existing content,
represents a good-faith effort to follow the template and style standards,
and is believed to be accurate.

Further needs for what would make the doc even better should be immediately addressed
in a follow-up MR or issue.

NOTE: **Note:**
If the release version you want to add the documentation to has already been
frozen or released, use the label `Pick into X.Y` to get it merged into
the correct release. Avoid picking into a past release as much as you can, as
it increases the work of the release managers.

### Cherry-picking from CE to EE

As we have the `master` branch of CE merged into EE once a day, it's common to
run into merge conflicts. To avoid them, we [test for merge conflicts against EE](#testing)
with the `ee-compat-check` job, and use the following method of creating equivalent
branches for CE and EE.

Follow this [method for cherry-picking from CE to EE](../automatic_ce_ee_merge.md#cherry-picking-from-ce-to-ee), with a few adjustments:

- Create the [CE branch](#branch-naming) starting with `docs-`,
  e.g.: `git checkout -b docs-example`
- Create the EE-equivalent branch ending with `-ee`, e.g.,
  `git checkout -b docs-example-ee`
- Once all the jobs are passing in CE and EE, and you've addressed the
  feedback from your own team, assign the CE MR to a technical writer for review
- When both MRs are ready, the EE merge request will be merged first, and the
  CE-equivalent will be merged next.
- Note that the review will occur only in the CE MR, as the EE MR
  contains the same commits as the CE MR.
- If you have a few more changes that apply to the EE-version only, you can submit
  a couple more commits to the EE branch, but ask the reviewer to review the EE merge request
  additionally to the CE MR. If there are many EE-only changes though, start a new MR
  to EE only.

## GitLab `/help`

Every GitLab instance includes the documentation, which is available from `/help`
(`http://my-instance.com/help`), e.g., <https://gitlab.com/help>.

The documentation available online on docs.gitlab.com is continuously
deployed every hour from the `master` branch of CE, EE, Omnibus, and Runner. Therefore,
once a merge request gets merged, it will be available online on the same day.
However, they will be shipped (and available on `/help`) within the milestone assigned
to the MR.

For instance, let's say your merge request has a milestone set to 11.3, which
will be released on 2018-09-22. If it gets merged on 2018-09-15, it will be
available online on 2018-09-15, but, as the feature freeze date has passed, if
the MR does not have a "pick into 11.3" label, the milestone has to be changed
to 11.4 and it will be shipped with all GitLab packages only on 2018-10-22,
with GitLab 11.4. Meaning, it will only be available under `/help` from GitLab
11.4 onwards, but available on docs.gitlab.com on the same day it was merged.

### Linking to `/help`

When you're building a new feature, you may need to link the documentation
from GitLab, the application. This is normally done in files inside the
`app/views/` directory with the help of the `help_page_path` helper method.

In its simplest form, the HAML code to generate a link to the `/help` page is:

```haml
= link_to 'Help page', help_page_path('user/permissions')
```

The `help_page_path` contains the path to the document you want to link to with
the following conventions:

- it is relative to the `doc/` directory in the GitLab repository
- the `.md` extension must be omitted
- it must not end with a slash (`/`)

Below are some special cases where should be used depending on the context.
You can combine one or more of the following:

1. **Linking to an anchor link.** Use `anchor` as part of the `help_page_path`
   method:

    ```haml
    = link_to 'Help page', help_page_path('user/permissions', anchor: 'anchor-link')
    ```

1. **Opening links in a new tab.** This should be the default behavior:

    ```haml
    = link_to 'Help page', help_page_path('user/permissions'), target: '_blank'
    ```

1. **Linking to a circle icon.** Usually used in settings where a long
   description cannot be used, like near checkboxes. You can basically use
   any font awesome icon, but prefer the `question-circle`:

    ```haml
    = link_to icon('question-circle'), help_page_path('user/permissions')
    ```

1. **Using a button link.** Useful in places where text would be out of context
   with the rest of the page layout:

    ```haml
    = link_to 'Help page', help_page_path('user/permissions'),  class: 'btn btn-info'
    ```

1. **Using links inline of some text.**

    ```haml
    Description to #{link_to 'Help page', help_page_path('user/permissions')}.
    ```

1. **Adding a period at the end of the sentence.** Useful when you don't want
   the period to be part of the link:

    ```haml
    = succeed '.' do
      Learn more in the
      = link_to 'Help page', help_page_path('user/permissions')
    ```

### GitLab `/help` tests

Several [rspec tests](https://gitlab.com/gitlab-org/gitlab-ce/blob/master/spec/features/help_pages_spec.rb)
are run to ensure GitLab documentation renders and works correctly. In particular, that [main docs landing page](../../README.md) will work correctly from `/help`.
For example, [GitLab.com's `/help`](https://gitlab.com/help).

CAUTION: **Caution:**
Because the rspec tests only run in a full pipeline, and not a special [docs-only pipeline](#branch-naming), it is possible
to merge changes that will break `master` from a merge request with a successful docs-only pipeline run.

## Docs site architecture

See the [Docs site architecture](site_architecture/index.md) page to learn
how we build and deploy the site at [docs.gitlab.com](https://docs.gitlab.com) and
to review all the assets and libraries in use.

### Global navigation

See the [Global navigation](site_architecture/global_nav.md) doc for information
on how the left-side navigation menu is built and updated.

## Previewing the changes live

NOTE: **Note:**
To preview your changes to documentation locally, follow this
[development guide](https://gitlab.com/gitlab-com/gitlab-docs/blob/master/README.md#development-when-contributing-to-gitlab-documentation) or [these instructions for GDK](https://gitlab.com/gitlab-org/gitlab-development-kit/blob/master/doc/howto/gitlab_docs.md).

The live preview is currently enabled for the following projects:

- <https://gitlab.com/gitlab-org/gitlab-ce>
- <https://gitlab.com/gitlab-org/gitlab-ee>
- <https://gitlab.com/gitlab-org/gitlab-runner>

If your branch contains only documentation changes, you can use
[special branch names](#branch-naming) to avoid long-running pipelines.

For [docs-only changes](#branch-naming), the review app is run automatically.
For all other branches, you can use the manual `review-docs-deploy-manual` job
in your merge request. You will need at least Maintainer permissions to be able
to run it. In the mini pipeline graph, you should see a `>>` icon. Clicking it will
reveal the `review-docs-deploy-manual` job. Click the play button to start the job.

![Manual trigger a docs build](img/manual_build_docs.png)

NOTE: **Note:**
You will need to push a branch to those repositories, it doesn't work for forks.

The `review-docs-deploy*` job will:

1. Create a new branch in the [gitlab-docs](https://gitlab.com/gitlab-com/gitlab-docs)
   project named after the scheme: `$DOCS_GITLAB_REPO_SUFFIX-$CI_ENVIRONMENT_SLUG`,
   where `DOCS_GITLAB_REPO_SUFFIX` is the suffix for each product, e.g, `ce` for
   CE, etc.
1. Trigger a cross project pipeline and build the docs site with your changes

After a few minutes, the Review App will be deployed and you will be able to
preview the changes. The docs URL can be found in two places:

- In the merge request widget
- In the output of the `review-docs-deploy*` job, which also includes the
  triggered pipeline so that you can investigate whether something went wrong

TIP: **Tip:**
Someone that has no merge rights to the CE/EE projects (think of forks from
contributors) will not be able to run the manual job. In that case, you can
ask someone from the GitLab team who has the permissions to do that for you.

NOTE: **Note:**
Make sure that you always delete the branch of the merge request you were
working on. If you don't, the remote docs branch won't be removed either,
and the server where the Review Apps are hosted will eventually be out of
disk space.

### Troubleshooting review apps

In case the review app URL returns 404, follow these steps to debug:

1. **Did you follow the URL from the merge request widget?** If yes, then check if
   the link is the same as the one in the job output.
1. **Did you follow the URL from the job output?** If yes, then it means that
   either the site is not yet deployed or something went wrong with the remote
   pipeline. Give it a few minutes and it should appear online, otherwise you
   can check the status of the remote pipeline from the link in the job output.
   If the pipeline failed or got stuck, drop a line in the `#docs` chat channel.

### Technical aspects

If you want to know the in-depth details, here's what's really happening:

1. You manually run the `review-docs-deploy` job in a CE/EE merge request.
1. The job runs the [`scripts/trigger-build-docs`](https://gitlab.com/gitlab-org/gitlab-ce/blob/master/scripts/trigger-build-docs)
   script with the `deploy` flag, which in turn:
   1. Takes your branch name and applies the following:
      - The slug of the branch name is used to avoid special characters since
        ultimately this will be used by NGINX.
      - The `preview-` prefix is added to avoid conflicts if there's a remote branch
        with the same name that you created in the merge request.
      - The final branch name is truncated to 42 characters to avoid filesystem
        limitations with long branch names (> 63 chars).
   1. The remote branch is then created if it doesn't exist (meaning you can
      re-run the manual job as many times as you want and this step will be skipped).
   1. A new cross-project pipeline is triggered in the docs project.
   1. The preview URL is shown both at the job output and in the merge request
      widget. You also get the link to the remote pipeline.
1. In the docs project, the pipeline is created and it
   [skips the test jobs](https://gitlab.com/gitlab-com/gitlab-docs/blob/8d5d5c750c602a835614b02f9db42ead1c4b2f5e/.gitlab-ci.yml#L50-55)
   to lower the build time.
1. Once the docs site is built, the HTML files are uploaded as artifacts.
1. A specific Runner tied only to the docs project, runs the Review App job
   that downloads the artifacts and uses `rsync` to transfer the files over
   to a location where NGINX serves them.

The following GitLab features are used among others:

- [Manual actions](../../ci/yaml/README.md#whenmanual)
- [Multi project pipelines](../../ci/multi_project_pipeline_graphs.md)
- [Review Apps](../../ci/review_apps/index.md)
- [Artifacts](../../ci/yaml/README.md#artifacts)
- [Specific Runner](../../ci/runners/README.md#locking-a-specific-runner-from-being-enabled-for-other-projects)

## Testing

We treat documentation as code, thus have implemented some testing.
Currently, the following tests are in place:

1. `docs lint`: Check that all internal (relative) links work correctly and
   that all cURL examples in API docs use the full switches. It's recommended
   to [check locally](#previewing-the-changes-live) before pushing to GitLab by executing the command
   `bundle exec nanoc check internal_links` on your local
   [`gitlab-docs`](https://gitlab.com/gitlab-com/gitlab-docs) directory.
1. [`ee_compat_check`](../automatic_ce_ee_merge.md#avoiding-ce-ee-merge-conflicts-beforehand) (runs on CE only):
    When you submit a merge request to GitLab Community Edition (CE),
    there is this additional job that runs against Enterprise Edition (EE)
    and checks if your changes can apply cleanly to the EE codebase.
    If that job fails, read the instructions in the job log for what to do next.
    As CE is merged into EE once a day, it's important to avoid merge conflicts.
    Submitting an EE-equivalent merge request cherry-picking all commits from CE to EE is
    essential to avoid them.
1. [`ee-files-location-check`/`ee-specific-lines-check`](#ee-specific-lines-check) (runs on EE only):
   This test ensures that no new files/directories are created/changed in EE.
   All docs should be submitted in CE instead, regardless the tier they are on.
   This is for the [single codebase](#single-codebase) effort.
1. In a full pipeline, tests for [`/help`](#gitlab-help-tests).

### Linting

To help adhere to the [documentation style guidelines](styleguide.md), and to improve the content
added to documentation, consider locally installing and running documentation linters. This will
help you catch common issues before raising merge requests for review of documentation.

The following are some suggested linters you can install locally and sample configuration:

- [`proselint`](#proselint)
- [`markdownlint`](#markdownlint)

NOTE: **Note:**
This list does not limit what other linters you can add to your local documentation writing toolchain.

#### `proselint`

`proselint` checks for common problems with English prose. It provides a
 [plethora of checks](http://proselint.com/checks/) that are helpful for technical writing.

`proselint` can be used [on the command line](http://proselint.com/utility/), either on a single
 Markdown file or on all Markdown files in a project. For example, to run `proselint` on all
 documentation in the [`gitlab-ce` project](https://gitlab.com/gitlab-org/gitlab-ce), run the
 following commands from within the `gitlab-ce` project:

```sh
cd doc
proselint **/*.md
```

`proselint` can also be run from within editors using plugins. For example, the following plugins
 are available:

- [Sublime Text](https://packagecontrol.io/packages/SublimeLinter-contrib-proselint)
- [Visual Studio Code](https://marketplace.visualstudio.com/items?itemName=PatrykPeszko.vscode-proselint)
- [Others](https://github.com/amperser/proselint#plugins-for-other-software)

##### Sample `proselint` configuration

All of the checks are good to use. However, excluding the `typography.symbols` and `misc.phrasal_adjectives` checks will reduce
noise. The following sample `proselint` configuration disables these checks:

```json
{
  "checks": {
    "typography.symbols": false,
    "misc.phrasal_adjectives": false
  }
}
```

A file with `proselint` configuration must be placed in a
[valid location](https://github.com/amperser/proselint#checks). For example, `~/.config/proselint/config`.

#### `markdownlint`

`markdownlint` checks that certain rules ([example](https://github.com/DavidAnson/markdownlint/blob/master/README.md#rules--aliases))
 are followed for Markdown syntax.
 Our [Documentation Style Guide](styleguide.md) and [Markdown Guide](https://about.gitlab.com/handbook/product/technical-writing/markdown-guide/)
 elaborate on which choices must be made when selecting Markdown syntax for
 GitLab documentation. This tool helps catch deviations from those guidelines.

`markdownlint` can be used [on the command line](https://github.com/igorshubovych/markdownlint-cli#markdownlint-cli--),
 either on a single Markdown file or on all Markdown files in a project. For example, to run
 `markdownlint` on all documentation in the [`gitlab-ce` project](https://gitlab.com/gitlab-org/gitlab-ce),
 run the following commands from within the `gitlab-ce` project:

```sh
cd doc
markdownlint **/*.md
```

`markdownlint` can also be run from within editors using plugins. For example, the following plugins
 are available:

- [Sublime Text](https://packagecontrol.io/packages/SublimeLinter-contrib-markdownlint)
- [Visual Studio Code](https://marketplace.visualstudio.com/items?itemName=DavidAnson.vscode-markdownlint)
- [Others](https://github.com/DavidAnson/markdownlint#related)

##### Sample `markdownlint` configuration

The following sample `markdownlint` configuration modifies the available default rules to:

- Adhere to the [Documentation Style Guide](styleguide.md).
- Apply conventions found in the GitLab documentation.
- Allow the flexibility of using some inline HTML.

```json
{
  "default": true,
  "header-style": { "style": "atx" },
  "ul-style": { "style": "dash" },
  "line-length": false,
  "no-trailing-punctuation": false,
  "ol-prefix": { "style": "one" },
  "blanks-around-fences": false,
  "no-inline-html": {
    "allowed_elements": [
      "table",
      "tbody",
      "tr",
      "td",
      "ul",
      "ol",
      "li",
      "br",
      "img",
      "a",
      "strong",
      "i",
      "div"
    ]
  },
  "hr-style": { "style": "---" },
  "fenced-code-language": false
}
```

For [`markdownlint`](https://github.com/DavidAnson/markdownlint/), this configuration must be
placed in a [valid location](https://github.com/igorshubovych/markdownlint-cli#configuration). For
example, `~/.markdownlintrc`.

## Danger Bot

GitLab uses [Danger](https://github.com/danger/danger) for some elements in
code review. For docs changes in merge requests, whenever a change to files under `/doc`
is made, Danger Bot leaves a comment with further instructions about the documentation
process. This is configured in the Dangerfile in the GitLab CE and EE repo under
[/danger/documentation/](https://gitlab.com/gitlab-org/gitlab-ce/tree/master/danger/documentation).
