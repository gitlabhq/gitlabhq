---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: "Learn how to use GitLab CI/CD, the GitLab built-in Continuous Integration, Continuous Deployment, and Continuous Delivery toolset to build, test, and deploy your application."
type: index
---

# Get started with GitLab CI/CD **(FREE ALL)**

Use GitLab CI/CD to automatically build, test, deploy, and monitor your applications.

GitLab CI/CD can catch bugs and errors early in the development cycle. It can ensure that
all the code deployed to production complies with your established code standards.

<div class="video-fallback">
  Video demonstration of continuous integration with GitLab CI/CD: <a href="https://www.youtube.com/watch?v=ljth1Q5oJoo">Continuous Integration with GitLab (overview demo)</a>.
</div>
<figure class="video-container">
  <iframe src="https://www.youtube-nocookie.com/embed/ljth1Q5oJoo" frameborder="0" allowfullscreen> </iframe>
</figure>

If you are new to GitLab CI/CD, get started with a tutorial:

- [Create and run your first GitLab CI/CD pipeline](quick_start/index.md)
- [Create a complex pipeline](quick_start/tutorial.md)

## CI/CD methodologies

With the continuous method of software development, you continuously build,
test, and deploy iterative code changes. This iterative process helps reduce
the chance that you develop new code based on buggy or failed previous versions.
With this method, you strive to have less human intervention or even no intervention at all,
from the development of new code until its deployment.

The three primary approaches for CI/CD are:

- [Continuous Integration (CI)](https://en.wikipedia.org/wiki/Continuous_integration)
- [Continuous Delivery (CD)](https://en.wikipedia.org/wiki/Continuous_delivery)
- [Continuous Deployment (CD)](https://en.wikipedia.org/wiki/Continuous_deployment)

Out-of-the-box management systems can decrease hours spent on maintaining toolchains by 10% or more.
Watch our ["Mastering continuous software development"](https://about.gitlab.com/webcast/mastering-ci-cd/)
webcast to learn about continuous methods and how built-in GitLab CI/CD can help you simplify and scale software development.

- <i class="fa fa-youtube-play youtube" aria-hidden="true"></i>Learn how to: [configure CI/CD](https://www.youtube.com/watch?v=opdLqwz6tcE).
- [Make the case for CI/CD in your organization](https://about.gitlab.com/devops-tools/github-vs-gitlab/).
- Learn how [Verizon reduced rebuilds](https://about.gitlab.com/blog/2019/02/14/verizon-customer-story/) from 30 days to under 8 hours with GitLab.
- <i class="fa fa-youtube-play youtube" aria-hidden="true"></i> [Get a deeper look at GitLab CI/CD](https://youtu.be/l5705U8s_nQ?t=369).

## Administration

You can change the default behavior of GitLab CI/CD for:

- An entire GitLab instance in the [CI/CD administration settings](../administration/cicd.md).
- Specific projects in the [pipelines settings](pipelines/settings.md).

See also:

- [Enable or disable GitLab CI/CD in a project](enable_or_disable_ci.md).

## Related topics

- [Why you might choose GitLab CI/CD](https://about.gitlab.com/blog/2016/10/17/gitlab-ci-oohlala/)
- [Reasons you might migrate from another platform](https://about.gitlab.com/blog/2016/07/22/building-our-web-app-on-gitlab-ci/)
- [Five teams that made the switch to GitLab CI/CD](https://about.gitlab.com/blog/2019/04/25/5-teams-that-made-the-switch-to-gitlab-ci-cd/)
- If you use VS Code to edit your GitLab CI/CD configuration, the
  [GitLab Workflow VS Code extension](../user/project/repository/vscode.md) helps you
  [validate your configuration](https://marketplace.visualstudio.com/items?itemName=GitLab.gitlab-workflow#validate-gitlab-ci-configuration)
  and [view your pipeline status](https://marketplace.visualstudio.com/items?itemName=GitLab.gitlab-workflow#information-about-your-branch-pipelines-mr-closing-issue)
