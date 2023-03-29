---
stage: none
group: Tutorials
info: For assistance with this tutorials page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments-to-other-projects-and-subjects.
---

# Learn GitLab with tutorials

These tutorials can help you learn how to use GitLab.

## Find your way around GitLab

Get to know the features of GitLab and where to find them so you can get up
and running quickly.

| Topic | Description | Good for beginners |
|-------|-------------|--------------------|
| <i class="fa fa-youtube-play youtube" aria-hidden="true"></i> [Introduction to GitLab](https://youtu.be/_4SmIyQ5eis?t=90) (59m 51s) | Walk through recommended processes and example workflows for using GitLab. | **{star}** |
| [GitLab with Git Essentials](https://levelup.gitlab.com/courses/gitlab-with-git-essentials)  |  Learn the basics of Git and GitLab in this self-paced course. | **{star}** |
| <i class="fa fa-youtube-play youtube" aria-hidden="true"></i> [Use GitLab for DevOps](https://www.youtube.com/watch?v=7q9Y1Cv-ib0) (12m 34s) | Use GitLab through the entire DevOps lifecycle, from planning to monitoring. | **{star}** |
| [Use Markdown at GitLab](../user/markdown.md) |  GitLab Flavored Markdown (GLFM) is used in many areas of GitLab, for example, in merge requests. | **{star}** |
| <i class="fa fa-youtube-play youtube" aria-hidden="true"></i> [Learn GitLab project walkthrough](https://www.youtube.com/watch?v=-oaI2WEKdI4&list=PL05JrBw4t0KofkHq4GZJ05FnNGa11PQ4d) (59m 2s) | Step through the tutorial-style issues in the **Learn GitLab** project. If you don't have this project, download [the export file](https://gitlab.com/gitlab-org/gitlab/-/blob/master/vendor/project_templates/learn_gitlab_ultimate.tar.gz) and [import it to a new project](../user/project/settings/import_export.md#import-a-project-and-its-data). | |
| <i class="fa fa-youtube-play youtube" aria-hidden="true"></i> [GitLab Continuous Delivery overview](https://www.youtube.com/watch?v=g-gO93PMZvk&list=PLFGfElNsQthYDx0A_FaNNfUm9NHsK6zED&index=134) (17m 2s) | Learn how to use GitLab features to continuously build, test, and deploy iterative code changes. | |
| [Productivity tips](https://about.gitlab.com/blog/2021/02/18/improve-your-gitlab-productivity-with-these-10-tips/) | Get tips to help make you a productive GitLab user. | |

## Use Git

GitLab is a Git-based platform, so understanding Git is important to get
the most out of GitLab.

| Topic | Description | Good for beginners |
|-------|-------------|--------------------|
| [Make your first Git commit](make_your_first_git_commit.md) | Create a project, edit a file, and commit changes to a Git repository from the command line. | **{star}** |
| [Start using Git on the command line](../gitlab-basics/start-using-git.md) | Learn how to set up Git, clone repositories, and work with branches. | **{star}** |
| [Take advantage of Git rebase](https://about.gitlab.com/blog/2022/10/06/take-advantage-of-git-rebase/)| Learn how to use the `rebase` command in your workflow. | |
| [Git cheat sheet](https://about.gitlab.com/images/press/git-cheat-sheet.pdf) | Download a PDF of common Git commands. | |

## Plan your work in projects

Your work takes place in a project, from creating code, to planning,
collaborating, and more.

| Topic | Description | Good for beginners |
|-------|-------------|--------------------|
| [Create a project from a template](https://gitlab.com/projects/new#create_from_template) | Choose a project template and create a project with files to get you started. | |
| [Migrate to GitLab](../user/project/import/index.md) | If you are coming to GitLab from another platform, you can import or convert your projects. | |
| [Run an agile iteration](agile_sprint.md) | Use group, projects, and iterations to run an agile development iteration. |

## Use CI/CD pipelines

CI/CD pipelines are used to automatically build, test, and deploy your code.

| Topic | Description | Good for beginners |
|-------|-------------|--------------------|
| [Create and run your first GitLab CI/CD pipeline](../ci/quick_start/index.md) | Create a `.gitlab-ci.yml` file and start a pipeline. | **{star}** |
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
| [Use GitOps with GitLab](https://about.gitlab.com/blog/2022/04/07/the-ultimate-guide-to-gitops-with-gitlab/)  |  Learn how to provision and manage a base infrastructure, connect to a Kubernetes cluster, deploy third-party applications, and carry out other infrastructure automation tasks. | |
| [Use Auto DevOps to deploy an application](../topics/autodevops/cloud_deployments/auto_devops_with_gke.md)  | Deploy an application to Google Kubernetes Engine (GKE). | |

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
| [Get started with GitLab application security](../user/application_security/get-started-security.md) | Follow recommended steps to set up security tools. | |
| [GitLab Security Essentials](https://levelup.gitlab.com/courses/security-essentials) | Learn about the essential security capabilities of GitLab in this self-paced course. | |

## Work with a self-managed instance

If you're an administrator of a self-managed instance of GitLab, these tutorials
can help you manage and configure your instance.

| Topic | Description | Good for beginners |
|-------|-------------|--------------------|
| [Install GitLab](../install/install_methods.md)  |  Install GitLab according to your requirements.| |
| [Get started administering GitLab](../administration/get_started.md) | Configure your organization and its authentication, then secure, monitor, and back up GitLab. | |

## Integrate with GitLab

GitLab [integrates](../user/project/integrations/index.md) with a number of third-party services,
enabling you to work with those services directly from GitLab.

| Topic | Description | Good for beginners |
|-------|-------------|--------------------|
| [Integrate with Jira](https://about.gitlab.com/blog/2021/04/12/gitlab-jira-integration-selfmanaged/) | Configure the Jira integration, so you can work with Jira issues from GitLab. | |
| [Integrate with Gitpod](https://about.gitlab.com/blog/2021/07/19/teams-gitpod-integration-gitlab-speed-up-development/)  | Integrate with Gitpod, to help speed up your development. | |

## Find more tutorial content

If you're learning about GitLab, here are some ways you can find more tutorial
content:

- Find learning tracks and certification options at [Level Up](https://levelup.gitlab.com/).
  GitLab learning platform login required (email and password for non-GitLab team members).

- Find recent tutorials on the GitLab blog by [searching by the `tutorial` tag](https://about.gitlab.com/blog/tags.html#tutorial).

- Browse the **Learn@GitLab** [playlist on YouTube](https://www.youtube.com/playlist?list=PLFGfElNsQthYDx0A_FaNNfUm9NHsK6zED)
  to find video tutorials.

If you find an article, video, or other resource that would be a
great addition to this page, add it in a [merge request](../development/documentation/index.md).
