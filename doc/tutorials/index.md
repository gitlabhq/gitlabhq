---
stage: none
group: unassigned
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Get started with GitLab tutorials

These tutorials can help you learn how to use GitLab.

## Find your way around GitLab

Get to know the features of GitLab and where to find them so you can get up
and running quickly.

| Topic | Description | Good for beginners |
|-------|-------------|--------------------|
| [GitLab 101](https://gitlab.edcast.com/pathways/copy-of-gitlab-certification)  |  Learn the basics of GitLab in this certification course. | **{star}** |
| <i class="fa fa-youtube-play youtube" aria-hidden="true"></i> [Use GitLab for DevOps](https://www.youtube.com/watch?v=7q9Y1Cv-ib0) (12m 34s) | Use GitLab through the entire DevOps lifecycle, from planning to monitoring. | **{star}** |
| [It's all connected in GitLab](https://about.gitlab.com/blog/2016/03/08/gitlab-tutorial-its-all-connected/) | Learn how to cross-link and reference your work. | **{star}** |
| [Use Markdown at GitLab](../user/markdown.md) |  GitLab Flavored Markdown (GFM) is used in many areas of GitLab, for example, in merge requests. | **{star}** |
| [GitLab 201](https://gitlab.edcast.com/pathways/ECL-44010cf6-7a9c-4b9b-b684-fa08508a3252)  |  Go beyond the basics to learn more about using GitLab for your work. | |
| Learn GitLab project | You might already have the **Learn GitLab** project, which has tutorial-style issues to help you learn GitLab. If not, download [this export file](https://gitlab.com/gitlab-org/gitlab/-/blob/master/vendor/project_templates/learn_gitlab_ultimate.tar.gz) and [import it to a new project](../user/project/settings/import_export.md#import-a-project-and-its-data). | |
| [Productivity tips](https://about.gitlab.com/blog/2021/02/18/improve-your-gitlab-productivity-with-these-10-tips/) | Get tips to help make you a productive GitLab user. | |
| <i class="fa fa-youtube-play youtube" aria-hidden="true"></i> [Structure a multi-team organization](https://www.youtube.com/watch?v=KmASFwSap7c) (37m 37s) | Learn to use issues, milestones, epics, labels, and more to plan and manage your work. | |

## Use Git

GitLab is a Git-based platform, so understanding Git is important to get
the most out of GitLab.

| Topic | Description | Good for beginners |
|-------|-------------|--------------------|
| [Start using Git on the command line](../gitlab-basics/start-using-git.md) | Learn how to set up Git, clone repositories, and work with branches. | **{star}** |
| [Git cheat sheet](https://about.gitlab.com/images/press/git-cheat-sheet.pdf) | Download a PDF of common Git commands. | |

## Plan your work in projects

Your work takes place in a project, from creating code, to planning,
collaborating, and more.

| Topic | Description | Good for beginners |
|-------|-------------|--------------------|
| [Create a project from a template](https://gitlab.com/projects/new#create_from_template) | For hands-on learning, select **Sample GitLab Project** and create a project with example issues and merge requests. | **{star}** |
| [Migrate to GitLab](../user/project/import/index.md) | If you are coming to GitLab from another platform, you can import or convert your projects. | |

## Use CI/CD pipelines

CI/CD pipelines are used to automatically build, test, and deploy your code.

| Topic | Description | Good for beginners |
|-------|-------------|--------------------|
| [Get started: Create a pipeline](../ci/quick_start/index.md) | Create a `.gitlab-ci.yml` file and start a pipeline. | **{star}** |
| <i class="fa fa-youtube-play youtube" aria-hidden="true"></i> [Get started: Learn about CI/CD](https://www.youtube.com/watch?v=sIegJaLy2ug) (9m 02s) | Learn about the `.gitlab-ci.yml` file and how it's used. | **{star}** |
| <i class="fa fa-youtube-play youtube" aria-hidden="true"></i> [CI deep dive](https://www.youtube.com/watch?v=ZVUbmVac-m8&list=PL05JrBw4t0KorkxIFgZGnzzxjZRCGROt_&index=27) (22m 51s) | Take a closer look at pipelines and continuous integration concepts. | |
| <i class="fa fa-youtube-play youtube" aria-hidden="true"></i> [CD deep dive](https://www.youtube.com/watch?v=Cn0rzND-Yjw&list=PL05JrBw4t0KorkxIFgZGnzzxjZRCGROt_&index=10) (47m 54s) | Learn about deploying in GitLab. | |
| [Set up CI/CD in the cloud](../ci/examples/index.md#cicd-in-the-cloud) | Learn how to set up CI/CD in different cloud-based environments. | |
| [Find CI/CD examples and templates](../ci/examples/index.md#cicd-examples)  | Use these examples and templates to set up CI/CD for your use case. | |
| <i class="fa fa-youtube-play youtube" aria-hidden="true"></i> [Understand CI/CD rules](https://www.youtube.com/watch?v=QjQc-zeL16Q) (8m 56s) |  Learn more about how to use CI/CD rules. | |

## Configure your applications and infrastructure

Use GitLab configuration features to reduce the effort needed to
configure the infrastructure for your application.

| Topic | Description | Good for beginners |
|-------|-------------|--------------------|
| [Connect with a Kubernetes cluster](https://about.gitlab.com/blog/2021/11/18/gitops-with-gitlab-connecting-the-cluster/)  |  Connect a Kubernetes cluster with GitLab for pull and push based deployments and security integrations. | |
| [Use Auto DevOps to deploy an application](../topics/autodevops/quick_start_guide.md)  | Deploy an application to Google Kubernetes Engine (GKE). | |

## Publish a static website

Use GitLab Pages to publish a static website directly from your project.

| Topic | Description | Good for beginners |
|-------|-------------|--------------------|
| [Create a Pages website from a CI/CD template](../user/project/pages/getting_started/pages_ci_cd_template.md) | Quickly generate a Pages website for your project using a CI/CD template for a popular Static Site Generator (SSG). | **{star}** |
| [Create a Pages website from scratch](../user/project/pages/getting_started/pages_from_scratch.md) | Create all the components of a Pages website from a blank project. | |

## Secure your application

GitLab can check your application for security vulnerabilities.

| Topic | Description | Good for beginners |
|-------|-------------|--------------------|
| [Set up dependency scanning](https://about.gitlab.com/blog/2021/01/14/try-dependency-scanning/) | Try out dependency scanning, which checks for known vulnerabilities in dependencies. | **{star}** |

## Work with a self-managed instance

If you're an administrator of a self-managed instance of GitLab, these tutorials
can help you manage and configure your instance.

| Topic | Description | Good for beginners |
|-------|-------------|--------------------|
| [Install GitLab](../install/index.md)  |  Install GitLab according to your requirements.| |
| [Get started administering GitLab](../administration/get_started.md) | Configure your organization and its authentication, then secure, monitor, and back up GitLab. | |
| [Secure your instance](https://about.gitlab.com/blog/2020/05/20/gitlab-instance-security-best-practices/)  |  Implement security features for your instance. | |

## Integrate with GitLab

GitLab [integrates](../integration/index.md) with a number of third-party services,
enabling you to work with those services directly from GitLab.

| Topic | Description | Good for beginners |
|-------|-------------|--------------------|
| [Integrate with Jira](https://about.gitlab.com/blog/2021/04/12/gitlab-jira-integration-selfmanaged/) | Configure the Jira integration, so you can work with Jira issues from GitLab. | |
| [Integrate with Gitpod](https://about.gitlab.com/blog/2021/07/19/teams-gitpod-integration-gitlab-speed-up-development/)  | Integrate with Gitpod, to help speed up your development. | |

## Find more tutorial content

If you're learning about GitLab, here are some ways you can find more tutorial
content:

- Find learning tracks and certification options at [GitLab Learn](https://about.gitlab.com/learn/).
  GitLab learning platform login required (email and password for non-GitLab team members).
  For more information, see [First time login details](https://about.gitlab.com/handbook/people-group/learning-and-development/gitlab-learn/user/#first-time-login-to-gitlab-learn).

- Find recent tutorials on the GitLab blog by [searching by the `tutorial` tag](https://about.gitlab.com/blog/tags.html#tutorial).

- Browse the **Learn@GitLab** [playlist on YouTube](https://www.youtube.com/playlist?list=PLFGfElNsQthYDx0A_FaNNfUm9NHsK6zED)
  to find video tutorials.

If you find an article, video, or other resource that would be a
great addition to this page, add it in a [merge request](../development/documentation/index.md).
