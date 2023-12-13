---
stage: Create
group: Source Code
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
---

# Source Code Management

The Source Code Management team is responsible for all backend aspects of the product categories
that fall under the [Source Code group](https://about.gitlab.com/handbook/product/categories/#source-code-group)
of the [Create stage](https://about.gitlab.com/handbook/product/categories/#create-stage)
of the [DevOps lifecycle](https://about.gitlab.com/handbook/product/categories/#devops-stages).

We interface with the Gitaly and Code Review teams. The features
we work with are listed on the
[Features by Group Page](https://about.gitlab.com/handbook/product/categories/features/#createsource-code-group).

The team works across three codebases: Workhorse, GitLab Shell and GitLab Rails.

## Workhorse

[GitLab Workhorse](../../workhorse/index.md) is a smart reverse proxy for GitLab. It handles "large" HTTP
requests such as file downloads, file uploads, `git push`, `git pull` and `git` archive downloads.

Workhorse itself is not a feature, but there are several features in GitLab
that would not work efficiently without Workhorse.

## GitLab Shell

GitLab Shell handles Git SSH sessions for GitLab and modifies the list of authorized keys.
For more information, refer to the [GitLab Shell documentation](../../gitlab_shell/index.md).

To learn about the reasoning behind our creation of `gitlab-sshd`, read the blog post
[Why we implemented our own SSHD solution](https://about.gitlab.com/blog/2022/08/17/why-we-have-implemented-our-own-sshd-solution-on-gitlab-sass/).

## CODEOWNERS

Source Code Management shares ownership of [Code Owners](../../code_owners/index.md) with the Code Review group.

## GitLab Rails

### Gitaly touch points

[Gitaly](../../../administration/gitaly/index.md) provides high-level RPC access to Git repositories.
It is present in every GitLab installation and coordinates Git repository storage and retrieval.
Gitaly implements a client-server architecture with Gitaly as the server and Gitaly clients, also
known as _Gitaly consumers_, including:

- GitLab Rails
- GitLab Shell
- GitLab Workhorse

Gitaly Rails provides API endpoints that are counterparts of Gitaly RPCs. For more information, read [Gitaly touch points](gitaly_touch_points.md).

### Annotated Rails Source Code

The `:source_code_management` annotation indicates which code belongs to the Source Code Management
group in the Rails codebase. The annotated objects are presented on
[this page](https://gitlab-com.gitlab.io/gl-infra/platform/stage-groups-index/source-code.html) along
with the [Error Budgets dashboards](https://dashboards.gitlab.net/d/stage-groups-source_code/stage-groups3a-source-code3a-group-dashboard?orgId=1).
