# GitLab Continuous Integration

![CI/CD pipeline graph](img/cicd_pipeline_infograph.png)

The benefits of Continuous Integration are huge when automation plays an
integral part of your workflow. GitLab comes with integrated Continuous
Integration (CI) and Continuous Delivery (CD) to test, build and deploy your
code.

Here's some info we've gathered to get you started.

## Getting started

- [Getting started with GitLab CI](quick_start/README.md)
- [Configure a Runner, the application that runs your jobs](runners/README.md)
- [Pipelines and jobs](pipelines.md)
- [Environments and deployments](environments.md)
- [Job artifacts](../user/project/pipelines/job_artifacts.md)
- **Using Docker**
  - [Use Docker images with GitLab Runner](docker/using_docker_images.md)
  - [Use CI to build Docker images](docker/using_docker_build.md)
  - [CI services (linked Docker containers)](services/README.md)
- **Blog posts**
  - [Getting started with GitLab and GitLab CI](https://about.gitlab.com/2015/12/14/getting-started-with-gitlab-and-gitlab-ci/)
  - [GitLab CI: Run jobs sequentially, in parallel or build a custom pipeline](https://about.gitlab.com/2016/07/29/the-basics-of-gitlab-ci/)
  - [Continuous Integration, Delivery, and Deployment with GitLab](https://about.gitlab.com/2016/08/05/continuous-integration-delivery-and-deployment-with-gitlab/)
  - [CI deployments and environments](https://about.gitlab.com/2016/08/26/ci-deployment-and-environments/)
- **Videos**
  - [Getting started with CI in GitLab](https://about.gitlab.com/2016/04/20/webcast-recording-and-slides-introduction-to-ci-in-gitlab/)

## Reference guides

Once you get familiar with the getting started guides, you'll find yourself
digging into specific reference guides.

- [`.gitlab-ci.yml` reference](yaml/README.md)
- **The permissions model**
  - [User permissions](../user/permissions.md#gitlab-ci)
  - [Jobs permissions](../user/permissions.md#jobs-permissions)
- [CI Variables](variables/README.md) - Learn how to use variables defined in
  your `.gitlab-ci.yml` or secured ones defined in your project's settings

## Advanced use

- [Git submodules](git_submodules.md)
- [Review Apps](review_apps/index.md)
- [Auto deploy](autodeploy/index.md)
- [Use SSH keys in your build environment](ssh_keys/README.md)
- [Trigger jobs through the GitLab API](triggers/README.md)
- [Using GitLab CI with GitLab Pages](../user/project/pages/index.md)

## Special project configuration

- [CI/CD pipelines settings](../user/project/pipelines/settings.md)
- [Learn how to enable or disable GitLab CI](enable_or_disable_ci.md)

## Examples

>**Note:**
A collection of `.gitlab-ci.yml` files is maintained at the
[GitLab CI Yml project][gitlab-ci-templates].
If your favorite programming language or framework are missing we would love
your help by sending a merge request with a `.gitlab-ci.yml`.

Here is an collection of tutorials and guides on setting up your CI pipeline:

- **Languages and frameworks**
  - [Testing a PHP application](examples/php.md)
  - [Test and deploy a Ruby application to Heroku](examples/test-and-deploy-ruby-application-to-heroku.md)
  - [Test and deploy a Python application to Heroku](examples/test-and-deploy-python-application-to-heroku.md)
  - [Test a Clojure application](examples/test-clojure-application.md)
  - [Test a Scala application](examples/test-scala-application.md)
  - [Test a Phoenix application](examples/test-phoenix-application.md)
  - [Run PHP Composer & NPM scripts then deploy them to a staging server](examples/deployment/composer-npm-deploy.md)
- **Blog posts**
  - [Automated Debian packaging](https://about.gitlab.com/2016/10/12/automated-debian-package-build-with-gitlab-ci/)
  - [Spring boot application with GitLab CI and Kubernetes](https://about.gitlab.com/2016/11/30/setting-up-gitlab-ci-for-android-projects/)
  - [Setting up CI for iOS projects](https://about.gitlab.com/2016/12/14/continuous-delivery-of-a-spring-boot-application-with-gitlab-ci-and-kubernetes/)
  - [Using GitLab CI for iOS projects](https://about.gitlab.com/2016/03/10/setting-up-gitlab-ci-for-ios-projects/)
  - [Setting up GitLab CI for Android projects](https://about.gitlab.com/2016/11/30/setting-up-gitlab-ci-for-android-projects/)
  - [Building a new GitLab Docs site with Nanoc, GitLab CI, and GitLab Pages](https://about.gitlab.com/2016/12/07/building-a-new-gitlab-docs-site-with-nanoc-gitlab-ci-and-gitlab-pages/)
  - [CI/CD with GitLab in action](https://about.gitlab.com/2017/03/13/ci-cd-demo/)
  - [Building an Elixir Release into a Docker image using GitLab CI](https://about.gitlab.com/2016/08/11/building-an-elixir-release-into-docker-image-using-gitlab-ci-part-1/)
- **Miscellaneous**
  - [Using `dpl` as deployment tool](examples/deployment/README.md)
  - [Repositories with examples for various languages](https://gitlab.com/groups/gitlab-examples)
  - [The .gitlab-ci.yml file for GitLab itself](https://gitlab.com/gitlab-org/gitlab-ce/blob/master/.gitlab-ci.yml)
  - [Example project that shows how to use Review Apps](https://gitlab.com/gitlab-examples/review-apps-nginx/)

## Breaking changes

- [CI variables renaming for GitLab 9.0](variables/README.md#9-0-renaming) Read about the
  deprecated CI variables and what you should use for GitLab 9.0+.
- [New CI job permissions model](../user/project/new_ci_build_permissions_model.md)
  Read about what changed in GitLab 8.12 and how that affects your jobs.
  There's a new way to access your Git submodules and LFS objects in jobs.

[gitlab-ci-templates]: https://gitlab.com/gitlab-org/gitlab-ci-yml
