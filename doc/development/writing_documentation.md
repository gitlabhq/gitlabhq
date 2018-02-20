# Writing documentation

  - **General Documentation**: written by the [developers responsible by creating features](#contributing-to-docs). Should be submitted in the same merge request containing code. Feature proposals (by GitLab contributors) should also be accompanied by its respective documentation. They can be later improved by PMs and Technical Writers.
  - **[Technical articles](#technical-articles)**: written by any [GitLab Team](https://about.gitlab.com/team/) member, GitLab contributors, or [Community Writers](https://about.gitlab.com/community-writers/).
  - **Indexes per topic**: initially prepared by the Technical Writing Team, and kept up-to-date by developers and PMs in the same merge request containing code. They gather all resources for that topic in a single page (user and admin documentation, articles, and third-party docs).

## Documentation style guidelines

All the docs follow the same [styleguide](doc_styleguide.md).

## Contributing to docs

Whenever a feature is changed, updated, introduced, or deprecated, the merge
request introducing these changes must be accompanied by the documentation
(either updating existing ones or creating new ones). This is also valid when
changes are introduced to the UI.

The one responsible for writing the first piece of documentation is the developer who
wrote the code. It's the job of the Product Manager to ensure all features are
shipped with its docs, whether is a small or big change. At the pace GitLab evolves,
this is the only way to keep the docs up-to-date. If you have any questions about it,
please ask a Technical Writer. Otherwise, when your content is ready, assign one of
them to review it for you.

We use the [monthly release blog post](https://about.gitlab.com/handbook/marketing/blog/release-posts/#monthly-releases) as a changelog checklist to ensure everything
is documented.

Whenever you submit a merge request for the documentation, use the documentation MR description template.

### Documentation directory structure

The documentation is structured based on the GitLab UI structure itself,
separated by [`user`](https://gitlab.com/gitlab-org/gitlab-ce/tree/master/doc/user),
[`administrator`](https://gitlab.com/gitlab-org/gitlab-ce/tree/master/doc/administration), and [`contributor`](https://gitlab.com/gitlab-org/gitlab-ce/tree/master/doc/development).

To learn where to place a new document, check the [documentation style guide](doc_styleguide.md#location-and-naming-of-documents).

In order to have a [solid site structure](https://searchengineland.com/seo-benefits-developing-solid-site-structure-277456) for our documentation,
all docs should be linked. Every new document should be cross-linked to its related documentation, and linked from its topic-related index, when existent.

The directories `/workflow/`, `/gitlab-basics/`, `/university/`, and `/articles/` have
been deprecated and the majority their docs have been moved to their correct location
in small iterations. Please don't create new docs in these folders.

To move a document from its location to another directory, read the section
[changing document location](doc_styleguide.md#changing-document-location) of the doc style guide.

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

### Markdown

Currently GitLab docs use Redcarpet as [markdown](../user/markdown.md) engine, but there's an [open discussion](https://gitlab.com/gitlab-com/gitlab-docs/issues/50) for implementing Kramdown in the near future.

### Previewing locally

To preview your changes to documentation locally, please follow
this [development guide](https://gitlab.com/gitlab-com/gitlab-docs/blob/master/README.md#development).

### Testing

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

### Branch naming

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

### Previewing the changes live

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

#### Technical aspects

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

## General documentation vs technical articles

### General documentation

General documentation is categorized by _User_, _Admin_, and _Contributor_, and describe what that feature is, what it does, and its available settings.

### Technical articles

Technical articles replace some technical content that once lived on the [GitLab blog](https://about.gitlab.com/blog/), where they became out of date and weren't easily found.

They are topic-related documentation, written with an user-friendly approach and language, aiming to provide the community with guidance on specific processes to achieve certain objectives.

A technical article guides users and/or admins to achieve certain objectives (within guides and tutorials), or provide an overview of that particular topic or feature (within technical overviews). It can also describe the use, implementation, or integration of third-party tools with GitLab.

They should be placed in a new directory named `/article-title/index.md` under a topic-related folder, and their images should be placed in `/article-title/img/`. For example, a new article on GitLab Pages should be placed in `doc/user/project/pages/article-title/` and a new article on GitLab CI/CD should be placed in `doc/ci/article-title/`.

#### Types of technical articles

- **User guides**: technical content to guide regular users from point A to point B
- **Admin guides**: technical content to guide administrators of GitLab instances from point A to point B
- **Technical overviews**: technical content describing features, solutions, and third-party integrations
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

