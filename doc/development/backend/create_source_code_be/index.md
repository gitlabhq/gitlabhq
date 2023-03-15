---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Create: Source Code backend

The Create: Source Code backend (BE) team focuses on the GitLab suite of Source Code Management
(SCM) tools. It is responsible for all backend aspects of the product categories
that fall under the [Source Code group](https://about.gitlab.com/handbook/product/categories/#source-code-group)
of the [Create stage](https://about.gitlab.com/handbook/product/categories/#create-stage)
of the [DevOps lifecycle](https://about.gitlab.com/handbook/product/categories/#devops-stages).

We interface with the Gitaly and Code Review teams, and work closely with the
[Create: Source Code frontend team](https://about.gitlab.com/handbook/engineering/development/dev/create/create-source-code-fe/). The features
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

## GitLab Rails

### Gitaly touch points

Gitaly is a Go RPC service which handles all the `git` calls made by GitLab.
GitLab is not exposed directly, and all traffic comes through Create: Source Code.
For more information, read [Gitaly touch points](gitaly_touch_points.md).

### Source Code REST API Endpoints

Create: Source Code has over 100 REST endpoints, being a mixture of Grape API endpoints and Rails controller endpoints.
For a detailed list, refer to [Source Code REST Endpoints](rest_endpoints.md).

An alternative list of the [Source Code endpoints and other owned objects](https://gitlab-com.gitlab.io/gl-infra/platform/stage-groups-index/source-code.html) is available.
