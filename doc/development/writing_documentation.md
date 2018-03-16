# GitLab Documentation guidelines

  - **General Documentation**: written by the [developers responsible by creating features](#contributing-to-docs). Should be submitted in the same merge request containing code. Feature proposals (by GitLab contributors) should also be accompanied by its respective documentation. They can be later improved by PMs and Technical Writers.
  - **[Technical Articles](#technical-articles)**: written by any [GitLab Team](https://about.gitlab.com/team/) member, GitLab contributors, or [Community Writers](https://about.gitlab.com/handbook/product/technical-writing/community-writers/).
  - **Indexes per topic**: initially prepared by the Technical Writing Team, and kept up-to-date by developers and PMs in the same merge request containing code. They gather all resources for that topic in a single page (user and admin documentation, articles, and third-party docs).

## Contributing to docs

Whenever a feature is changed, updated, introduced, or deprecated, the merge
request introducing these changes must be accompanied by the documentation
(either updating existing ones or creating new ones). This is also valid when
changes are introduced to the UI.

The one responsible for writing the first piece of documentation is the developer who
wrote the code. It's the job of the Product Manager to ensure all features are
shipped with its docs, whether is a small or big change. At the pace GitLab evolves,
this is the only way to keep the docs up-to-date. If you have any questions about it,
ask a Technical Writer. Otherwise, when your content is ready, assign one of
them to review it for you.

We use the [monthly release blog post](https://about.gitlab.com/handbook/marketing/blog/release-posts/#monthly-releases) as a changelog checklist to ensure everything
is documented.

Whenever you submit a merge request for the documentation, use the documentation MR description template.

Please check the [documentation workflow](https://about.gitlab.com/handbook/product/technical-writing/workflow/) before getting started.

## Documentation structure

- Overview and use cases: what it is, why it is necessary, why one would use it
- Requirements: what do we need to get started
- Tutorial: how to set it up, how to use it

Always link a new document from its topic-related index, otherwise, it will
not be included it in the documentation site search.

_Note: to be extended._

### Feature overview and use cases

Every major feature (regardless if present in GitLab Community or Enterprise editions)
should present, at the beginning of the document, two main sections: **overview** and
**use cases**. Every GitLab EE-only feature should also contain these sections.

**Overview**: as the name suggests, the goal here is to provide an overview of the feature.
Describe what is it, what it does, why it is important/cool/nice-to-have,
what problem it solves, and what you can do with this feature that you couldn't
do before.

**Use cases**: provide at least two, ideally three, use cases for every major feature.
You should answer this question: what can you do with this feature/change? Use cases
are examples of how this feauture or change can be used in real life.

Examples:
- CE and EE: [Issues](../user/project/issues/index.md#use-cases)
- CE and EE: [Merge Requests](../user/project/merge_requests/index.md#overview)
- EE-only: [Geo](https://docs.gitlab.com/ee/gitlab-geo/README.html#overview)
- EE-only: [Jenkins integration](https://docs.gitlab.com/ee/integration/jenkins.md#overview)

Note that if you don't have anything to add between the doc title (`<h1>`) and
the header `## Overview`, you can omit the header, but keep the content of the
overview there.

> **Overview** and **use cases** are required to **every** Enterprise Edition feature,
and for every **major** feature present in Community Edition.

## Markdown and styles

Currently GitLab docs use Redcarpet as [markdown](../user/markdown.md) engine, but there's an [open discussion](https://gitlab.com/gitlab-com/gitlab-docs/issues/50) for implementing Kramdown in the near future.

All the docs follow the [documentation style guidelines](doc_styleguide.md).

## Documentation directory structure

The documentation is structured based on the GitLab UI structure itself,
separated by [`user`](https://gitlab.com/gitlab-org/gitlab-ce/tree/master/doc/user),
[`administrator`](https://gitlab.com/gitlab-org/gitlab-ce/tree/master/doc/administration), and [`contributor`](https://gitlab.com/gitlab-org/gitlab-ce/tree/master/doc/development). 

In order to have a [solid site structure](https://searchengineland.com/seo-benefits-developing-solid-site-structure-277456) for our documentation,
all docs should be linked. Every new document should be cross-linked to its related documentation, and linked from its topic-related index, when existent.

The directories `/workflow/`, `/gitlab-basics/`, `/university/`, and `/articles/` have
been deprecated and the majority their docs have been moved to their correct location
in small iterations. Please don't create new docs in these folders.

### Location and naming documents

The documentation hierarchy can be vastly improved by providing a better layout
and organization of directories.

Having a structured document layout, we will be able to have meaningful URLs
like `docs.gitlab.com/user/project/merge_requests/index.html`. With this pattern,
you can immediately tell that you are navigating a user related documentation
and is about the project and its merge requests.

Do not create summaries of similar types of content (e.g. an index of all articles, videos, etc.),
rather organize content by its subject (e.g. everything related to CI goes together)
and cross-link between any related content.

The table below shows what kind of documentation goes where.

| Directory | What belongs here |
| --------- | -------------- |
| `doc/user/` | User related documentation. Anything that can be done within the GitLab UI goes here including `/admin`. |
| `doc/administration/`  | Documentation that requires the user to have access to the server where GitLab is installed. The admin settings that can be accessed via GitLab's interface go under `doc/user/admin_area/`. |
| `doc/api/` | API related documentation. |
| `doc/development/` | Documentation related to the development of GitLab. Any styleguides should go here. |
| `doc/legal/` | Legal documents about contributing to GitLab. |
| `doc/install/`| Probably the most visited directory, since `installation.md` is there. Ideally this should go under `doc/administration/`, but it's best to leave it as-is in order to avoid confusion (still debated though). |
| `doc/update/` | Same with `doc/install/`. Should be under `administration/`, but this is a well known location, better leave as-is, at least for now. |
| `doc/topics/` | Indexes per Topic (`doc/topics/topic-name/index.md`): all resources for that topic (user and admin documentation, articles, and third-party docs) |

---

**General rules:**

1. The correct naming and location of a new document, is a combination
   of the relative URL of the document in question and the GitLab Map design
   that is used for UX purposes ([source][graffle], [image][gitlab-map]).
1. When creating a new document and it has more than one word in its name,
   make sure to use underscores instead of spaces or dashes (`-`). For example,
   a proper naming would be `import_projects_from_github.md`. The same rule
   applies to images.
1. Start a new directory with an `index.md` file.
1. There are four main directories, `user`, `administration`, `api` and `development`.
1. The `doc/user/` directory has five main subdirectories: `project/`, `group/`,
   `profile/`, `dashboard/` and `admin_area/`.
   1. `doc/user/project/` should contain all project related documentation.
   1. `doc/user/group/` should contain all group related documentation.
   1. `doc/user/profile/` should contain all profile related documentation.
      Every page you would navigate under `/profile` should have its own document,
      i.e. `account.md`, `applications.md`, `emails.md`, etc.
   1. `doc/user/dashboard/` should contain all dashboard related documentation.
   1. `doc/user/admin_area/` should contain all admin related documentation
      describing what can be achieved by accessing GitLab's admin interface
      (_not to be confused with `doc/administration` where server access is
      required_).
      1. Every category under `/admin/application_settings` should have its
         own document located at `doc/user/admin_area/settings/`. For example,
         the **Visibility and Access Controls** category should have a document
         located at `doc/user/admin_area/settings/visibility_and_access_controls.md`.
1. The `doc/topics/` directory holds topic-related technical content. Create
   `doc/topics/topic-name/subtopic-name/index.md` when subtopics become necessary.
   General user- and admin- related documentation, should be placed accordingly.

If you are unsure where a document should live, you can ping `@axil` or `@marcia` in your
merge request.

### Changing document location

Changing a document's location is not to be taken lightly. Remember that the
documentation is available to all installations under `help/` and not only to
GitLab.com or http://docs.gitlab.com. Make sure this is discussed with the
Documentation team beforehand.

If you indeed need to change a document's location, do NOT remove the old
document, but rather replace all of its contents with a new line:

```
This document was moved to [another location](path/to/new_doc.md).
```

where `path/to/new_doc.md` is the relative path to the root directory `doc/`.

---

For example, if you were to move `doc/workflow/lfs/lfs_administration.md` to
`doc/administration/lfs.md`, then the steps would be:

1. Copy `doc/workflow/lfs/lfs_administration.md` to `doc/administration/lfs.md`
1. Replace the contents of `doc/workflow/lfs/lfs_administration.md` with:

    ```
    This document was moved to [another location](../../administration/lfs.md).
    ```

1. Find and replace any occurrences of the old location with the new one.
   A quick way to find them is to use `git grep`. First go to the root directory
   where you cloned the `gitlab-ce` repository and then do:

    ```
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
- The above `git grep` command will search recursively in the directory you run
  it in for `workflow/lfs/lfs_administration` and `lfs/lfs_administration`
  and will print the file and the line where this file is mentioned.
  You may ask why the two greps. Since we use relative paths to link to
  documentation, sometimes it might be useful to search a path deeper.
- The `*.md` extension is not used when a document is linked to GitLab's
  built-in help page, that's why we omit it in `git grep`.
- Use the checklist on the documentation MR description template.

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

## Testing

We treat documentation as code, thus have implemented some testing.
Currently, the following tests are in place:

1. `docs lint`: Check that all internal (relative) links work correctly and
   that all cURL examples in API docs use the full switches. It's recommended
   to [check locally](#previewing-locally) before pushing to GitLab by executing the command
   `bundle exec nanoc check internal_links` on your local
   [`gitlab-docs`](https://gitlab.com/gitlab-com/gitlab-docs) directory.
1. [`ee_compat_check`](https://docs.gitlab.com/ee/development/automatic_ce_ee_merge.html#avoiding-ce-gt-ee-merge-conflicts-beforehand) (runs on CE only):
    When you submit a merge request to GitLab Community Edition (CE),
    there is this additional job that runs against Enterprise Edition (EE)
    and checks if your changes can apply cleanly to the EE codebase.
    If that job fails, read the instructions in the job log for what to do next.
    As CE is merged into EE once a day, it's important to avoid merge conflicts.
    Submitting an EE-equivalent merge request cherry-picking all commits from CE to EE is
    essential to avoid them.

## Branch naming

If your contribution contains **only** documentation changes, you can speed up
the CI process by following some branch naming conventions. You have three
choices:

| Branch name | Valid example |
| ----------- | ------------- |
| Starting with `docs/` | `docs/update-api-issues`     |
| Starting with `docs-` | `docs-update-api-issues`     |
| Ending in `-docs`     | `123-update-api-issues-docs` |

If your branch name matches any of the above, it will run only the docs
tests. If it doesn't, the whole test suite will run (including docs).

## Merge requests for GitLab documentation

Before getting started, make sure you read the introductory section
"[contributing to docs](#contributing-to-docs)" above and the
[tech writing workflow](https://about.gitlab.com/handbook/product/technical-writing/workflow/)
for GitLab Team members.

- Use the current [merge request description template](https://gitlab.com/gitlab-org/gitlab-ce/blob/master/.gitlab/merge_request_templates/Documentation.md)
- Use the correct [branch name](#branch-naming)
- Label the MR `Documentation`
- Assign the correct milestone (see note below)


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

Follow this [method for cherry-picking from CE to EE](automatic_ce_ee_merge.md#cherry-picking-from-ce-to-ee), with a few adjustments:

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

## Previewing the changes live

To preview your changes to documentation locally, please follow
this [development guide](https://gitlab.com/gitlab-com/gitlab-docs/blob/master/README.md#development).

If you want to preview the doc changes of your merge request live, you can use
the manual `review-docs-deploy` job in your merge request. You will need at
least Master permissions to be able to run it and is currently enabled for the
following projects:

- https://gitlab.com/gitlab-org/gitlab-ce
- https://gitlab.com/gitlab-org/gitlab-ee

NOTE: **Note:**
You will need to push a branch to those repositories, it doesn't work for forks.

TIP: **Tip:**
If your branch contains only documentation changes, you can use
[special branch names](#branch-naming) to avoid long running pipelines.

In the mini pipeline graph, you should see an `>>` icon. Clicking on it will
reveal the `review-docs-deploy` job. Hit the play button for the job to start.

![Manual trigger a docs build](img/manual_build_docs.png)

This job will:

1. Create a new branch in the [gitlab-docs](https://gitlab.com/gitlab-com/gitlab-docs)
   project named after the scheme: `preview-<branch-slug>`
1. Trigger a cross project pipeline and build the docs site with your changes

After a few minutes, the Review App will be deployed and you will be able to
preview the changes. The docs URL can be found in two places:

- In the merge request widget
- In the output of the `review-docs-deploy` job, which also includes the
  triggered pipeline so that you can investigate whether something went wrong

In case the Review App URL returns 404, follow these steps to debug:

1. **Did you follow the URL from the merge request widget?** If yes, then check if
   the link is the same as the one in the job output. It can happen that if the
   branch name slug is longer than 35 characters, it is automatically
   truncated. That means that the merge request widget will not show the proper
   URL due to a limitation of how `environment: url` works, but you can find the
   real URL from the output of the `review-docs-deploy` job.
1. **Did you follow the URL from the job output?** If yes, then it means that
   either the site is not yet deployed or something went wrong with the remote
   pipeline. Give it a few minutes and it should appear online, otherwise you
   can check the status of the remote pipeline from the link in the job output.
   If the pipeline failed or got stuck, drop a line in the `#docs` chat channel.

TIP: **Tip:**
Someone that has no merge rights to the CE/EE projects (think of forks from
contributors) will not be able to run the manual job. In that case, you can
ask someone from the GitLab team who has the permissions to do that for you.

NOTE: **Note:**
Make sure that you always delete the branch of the merge request you were
working on. If you don't, the remote docs branch won't be removed either,
and the server where the Review Apps are hosted will eventually be out of
disk space.

### Technical aspects

If you want to know the hot details, here's what's really happening:

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

- [Manual actions](../ci/yaml/README.md#manual-actions)
- [Multi project pipelines](https://docs.gitlab.com/ee/ci/multi_project_pipeline_graphs.html)
- [Review Apps](../ci/review_apps/index.md)
- [Artifacts](../ci/yaml/README.md#artifacts)
- [Specific Runner](../ci/runners/README.md#locking-a-specific-runner-from-being-enabled-for-other-projects)

## GitLab `/help`

Every GitLab instance includes the documentation, which is available from `/help`
(`http://my-instance.com/help`), e.g., <https://gitlab.com/help>.

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

## General Documentation vs Technical Articles

### General documentation

General documentation is categorized by _User_, _Admin_, and _Contributor_, and describe what that feature is, what it does, and its available settings.

### Technical Articles

Technical articles replace technical content that once lived in the [GitLab Blog](https://about.gitlab.com/blog/), where they got out-of-date and weren't easily found.

They are topic-related documentation, written with an user-friendly approach and language, aiming to provide the community with guidance on specific processes to achieve certain objectives.

A technical article guides users and/or admins to achieve certain objectives (within guides and tutorials), or provide an overview of that particular topic or feature (within technical overviews). It can also describe the use, implementation, or integration of third-party tools with GitLab.

They should be placed in a new directory named `/article-title/index.md` under a topic-related folder, and their images should be placed in `/article-title/img/`. For example, a new article on GitLab Pages should be placed in `doc/user/project/pages/article-title/` and a new article on GitLab CI/CD should be placed in `doc/ci/examples/article-title/`.

#### Types of Technical Articles

- **User guides**: technical content to guide regular users from point A to point B
- **Admin guides**: technical content to guide administrators of GitLab instances from point A to point B
- **Technical Overviews**: technical content describing features, solutions, and third-party integrations
- **Tutorials**: technical content provided step-by-step on how to do things, or how to reach very specific objectives

#### Understanding guides, tutorials, and technical overviews

Suppose there's a process to go from point A to point B in 5 steps: `(A) 1 > 2 > 3 > 4 > 5 (B)`.

A **guide** can be understood as a description of certain processes to achieve a particular objective. A guide brings you from A to B describing the characteristics of that process, but not necessarily going over each step. It can mention, for example, steps 2 and 3, but does not necessarily explain how to accomplish them.

- Live example: "[Static sites and GitLab Pages domains (Part 1)](../user/project/pages/getting_started_part_one.md) to [Creating and Tweaking GitLab CI/CD for GitLab Pages (Part 4)](../user/project/pages/getting_started_part_four.md)"

A **tutorial** requires a clear **step-by-step** guidance to achieve a singular objective. It brings you from A to B, describing precisely all the necessary steps involved in that process, showing each of the 5 steps to go from A to B.
It does not only describes steps 2 and 3, but also shows you how to accomplish them.

- Live example (on the blog): [Hosting on GitLab.com with GitLab Pages](https://about.gitlab.com/2016/04/07/gitlab-pages-setup/)

A **technical overview** is a description of what a certain feature is, and what it does, but does not walk
through the process of how to use it systematically.

- Live example (on the blog): [GitLab Workflow, an overview](https://about.gitlab.com/2016/10/25/gitlab-workflow-an-overview/)

#### Special format

Every **Technical Article** contains a frontmatter at the beginning of the doc
with the following information:

- **Type of article** (user guide, admin guide, technical overview, tutorial)
- **Knowledge level** expected from the reader to be able to follow through (beginner, intermediate, advanced)
- **Author's name** and **GitLab.com handle**
- **Publication date** (ISO format YYYY-MM-DD)

For example:


```yaml
---
author: John Doe
author_gitlab: johnDoe
level: beginner
article_type: user guide
date: 2017-02-01
---
```

#### Technical Articles - Writing Method

Use the [writing method](https://about.gitlab.com/handbook/product/technical-writing/#writing-method) defined by the Technical Writing team.

[gitlab-map]: https://gitlab.com/gitlab-org/gitlab-design/raw/master/production/resources/gitlab-map.png
[graffle]: https://gitlab.com/gitlab-org/gitlab-design/blob/d8d39f4a87b90fb9ae89ca12dc565347b4900d5e/production/resources/gitlab-map.graffle
