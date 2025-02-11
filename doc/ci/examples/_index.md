---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitLab CI/CD examples
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

This page contains links to a variety of examples that can help you understand how to
implement [GitLab CI/CD](../_index.md) for your specific use case.

Examples are available in several forms. As a collection of:

- `.gitlab-ci.yml` [template files](#cicd-templates) maintained in GitLab, for many
  common frameworks and programming languages.
- Repositories with [example projects](https://gitlab.com/gitlab-examples) for various languages. You can fork and adjust them to your own needs. Projects include an example of using [review apps with a static site served by NGINX](https://gitlab.com/gitlab-examples/review-apps-nginx/).
- Examples and [other resources](#other-resources) listed below.

## CI/CD examples

The following table lists examples with step-by-step tutorials that are contained in this section:

| Use case                      | Resource |
|-------------------------------|----------|
| Deployment with Dpl           | [Using `dpl` as deployment tool](deployment/_index.md). |
| GitLab Pages                  | See the [GitLab Pages](../../user/project/pages/_index.md) documentation for a complete example of deploying a static site. |
| Multi project pipeline        | [Build, test deploy using multi project pipeline](https://gitlab.com/gitlab-examples/upstream-project). |
| npm with semantic-release     | [Publish npm packages to the GitLab package registry using semantic-release](semantic-release.md). |
| PHP with npm, SCP             | [Running Composer and npm scripts with deployment via SCP in GitLab CI/CD](deployment/composer-npm-deploy.md). |
| PHP with PHPUnit, `atoum`     | [Testing PHP projects](php.md). |
| Secrets management with Vault | [Authenticating and Reading Secrets With HashiCorp Vault](../secrets/hashicorp_vault.md). |

### Contributed examples

You can help people that use your favorite programming language by submitting a link
to a guide for that language. These contributed guides are hosted externally or in
separate example projects:

| Use case                      | Resource |
|-------------------------------|----------|
| Clojure                       | [Test a Clojure application with GitLab CI/CD](https://gitlab.com/gitlab-examples/clojure-web-application). |
| Game development              | [DevOps and Game Development with GitLab CI/CD](https://gitlab.com/gitlab-examples/gitlab-game-demo/). |
| Java with Maven               | [How to deploy Maven projects to Artifactory with GitLab CI/CD](https://gitlab.com/gitlab-examples/maven/simple-maven-example). |
| Java with Spring Boot         | [Deploy a Spring Boot application to Cloud Foundry with GitLab CI/CD](https://gitlab.com/gitlab-examples/spring-gitlab-cf-deploy-demo). |
| Parallel testing Ruby & JS    | [GitLab CI/CD parallel jobs testing for Ruby & JavaScript projects](https://docs.knapsackpro.com/2019/how-to-run-parallel-jobs-for-rspec-tests-on-gitlab-ci-pipeline-and-speed-up-ruby-javascript-testing). |
| Python on Heroku              | [Test and deploy a Python application with GitLab CI/CD](https://gitlab.com/gitlab-examples/python-getting-started). |
| Ruby on Heroku                | [Test and deploy a Ruby application with GitLab CI/CD](https://gitlab.com/gitlab-examples/ruby-getting-started). |
| Scala on Heroku               | [Test and deploy a Scala application to Heroku](https://gitlab.com/gitlab-examples/scala-sbt). |

## CI/CD templates

Get started with GitLab CI/CD and your favorite programming language or framework by using a
`.gitlab-ci.yml` [template](https://gitlab.com/gitlab-org/gitlab/-/tree/master/lib/gitlab/ci/templates).

When you create a `.gitlab-ci.yml` file in the UI, you can
choose one of these templates:

- [Android (`Android.gitlab-ci.yml`)](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Android.gitlab-ci.yml)
- [Android with fastlane (`Android-Fastlane.gitlab-ci.yml`)](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Android-Fastlane.gitlab-ci.yml)
- [Bash (`Bash.gitlab-ci.yml`)](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Bash.gitlab-ci.yml)
- [C++ (`C++.gitlab-ci.yml`)](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/C++.gitlab-ci.yml)
- [Chef (`Chef.gitlab-ci.yml`)](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Chef.gitlab-ci.yml)
- [Clojure (`Clojure.gitlab-ci.yml`)](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Clojure.gitlab-ci.yml)
- [Composer `Composer.gitlab-ci.yml`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Composer.gitlab-ci.yml)
- [Crystal (`Crystal.gitlab-ci.yml`)](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Crystal.gitlab-ci.yml)
- [Dart (`Dart.gitlab-ci.yml`)](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Dart.gitlab-ci.yml)
- [Django (`Django.gitlab-ci.yml`)](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Django.gitlab-ci.yml)
- [Docker (`Docker.gitlab-ci.yml`)](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Docker.gitlab-ci.yml)
- [dotNET (`dotNET.gitlab-ci.yml`)](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/dotNET.gitlab-ci.yml)
- [dotNET Core (`dotNET-Core.gitlab-ci.yml`)](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/dotNET-Core.gitlab-ci.yml)
- [Elixir (`Elixir.gitlab-ci.yml`)](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Elixir.gitlab-ci.yml)
- [Flutter (`Flutter.gitlab-ci.yml`)](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Flutter.gitlab-ci.yml)
- [Go (`Go.gitlab-ci.yml`)](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Go.gitlab-ci.yml)
- [Gradle (`Gradle.gitlab-ci.yml`)](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Gradle.gitlab-ci.yml)
- [Grails (`Grails.gitlab-ci.yml`)](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Grails.gitlab-ci.yml)
- [iOS with fastlane (`iOS-Fastlane.gitlab-ci.yml`)](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/iOS-Fastlane.gitlab-ci.yml)
- [Julia (`Julia.gitlab-ci.yml`)](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Julia.gitlab-ci.yml)
- [Laravel (`Laravel.gitlab-ci.yml`)](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Laravel.gitlab-ci.yml)
- [LaTeX (`LaTeX.gitlab-ci.yml`)](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/LaTeX.gitlab-ci.yml)
- [Maven (`Maven.gitlab-ci.yml`)](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Maven.gitlab-ci.yml)
- [Mono (`Mono.gitlab-ci.yml`)](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Mono.gitlab-ci.yml)
- [npm (`npm.gitlab-ci.yml`)](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/npm.gitlab-ci.yml)
- [Node.js (`Nodejs.gitlab-ci.yml`)](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Nodejs.gitlab-ci.yml)
- [OpenShift (`OpenShift.gitlab-ci.yml`)](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/OpenShift.gitlab-ci.yml)
- [Packer (`Packer.gitlab-ci.yml`)](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Packer.gitlab-ci.yml)
- [PHP (`PHP.gitlab-ci.yml`)](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/PHP.gitlab-ci.yml)
- [Python (`Python.gitlab-ci.yml`)](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Python.gitlab-ci.yml)
- [Ruby (`Ruby.gitlab-ci.yml`)](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Ruby.gitlab-ci.yml)
- [Rust (`Rust.gitlab-ci.yml`)](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Rust.gitlab-ci.yml)
- [Scala (`Scala.gitlab-ci.yml`)](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Scala.gitlab-ci.yml)
- [Swift (`Swift.gitlab-ci.yml`)](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Swift.gitlab-ci.yml)
- [Terraform (`Terraform.gitlab-ci.yml`)](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Terraform.gitlab-ci.yml)
- [Terraform (`Terraform.latest.gitlab-ci.yml`)](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Terraform.latest.gitlab-ci.yml)

If a programming language or framework template is not in this list, you can contribute
one. To create a template, submit a merge request
to [the templates list](https://gitlab.com/gitlab-org/gitlab/-/tree/master/lib/gitlab/ci/templates).

### Adding templates to your GitLab installation

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** GitLab Self-Managed, GitLab Dedicated

You can add custom examples and templates to your instance.
Your GitLab administrator can [designate an instance template repository](../../administration/settings/instance_template_repository.md)
that contains examples and templates specific to your organization.

## Other resources

This section provides further resources to help you get familiar with various uses of GitLab CI/CD.
Older articles and videos may not reflect the state of the latest GitLab release.

### CI/CD in the cloud

For examples of setting up GitLab CI/CD for cloud-based environments, see:

- [How to set up multi-account AWS SAM deployments with GitLab CI](https://about.gitlab.com/blog/2019/02/04/multi-account-aws-sam-deployments-with-gitlab-ci/)
- Video: [Automating Kubernetes Deployments with GitLab CI/CD](https://www.youtube.com/watch?v=wEDRfAz6_Uw)
- [How to autoscale continuous deployment with GitLab Runner on DigitalOcean](https://about.gitlab.com/blog/2018/06/19/autoscale-continuous-deployment-gitlab-runner-digital-ocean/)
- [How to create a CI/CD pipeline with Auto Deploy to Kubernetes using GitLab and Helm](https://about.gitlab.com/blog/2017/09/21/how-to-create-a-ci-cd-pipeline-with-auto-deploy-to-kubernetes-using-gitlab/)
- Video: [Demo - Deploying from GitLab to OpenShift Container Cluster](https://youtu.be/EwbhA53Jpp4)
- Tutorial: [Set up a GitLab.com Civo Kubernetes integration with Gitpod](https://gitlab.com/k33g_org/k33g_org.gitlab.io/-/issues/82)

See also the following video overviews:

- Video: [Kubernetes, GitLab, and Cloud Native](https://www.youtube.com/watch?v=d-9awBxEbvQ)
- Video: [Deploying to IBM Cloud with GitLab CI/CD](https://www.youtube.com/watch?v=6ZF4vgKMd-g)

### Customer stories

For some customer experiences with GitLab CI/CD, see:

- [How Verizon Connect reduced data center deploys from 30 days to under 8 hours with GitLab](https://about.gitlab.com/blog/2019/02/14/verizon-customer-story/)
- [How Wag! cut their release process from 40 minutes to just 6](https://about.gitlab.com/blog/2019/01/16/wag-labs-blog-post/)
- [How Jaguar Land Rover embraced CI to speed up their software lifecycle](https://about.gitlab.com/blog/2018/07/23/chris-hill-devops-enterprise-summit-talk/)

### Getting started

For some examples to help get you started, see:

- [GitLab CI/CD's 2018 highlights](https://about.gitlab.com/blog/2019/01/21/gitlab-ci-cd-features-improvements/)
- [A beginner's guide to continuous integration](https://about.gitlab.com/blog/2018/01/22/a-beginners-guide-to-continuous-integration/)

### Implementing GitLab CI/CD

For examples of others who have implemented GitLab CI/CD, see:

- [How to streamline interactions between multiple repositories with multi-project pipelines](https://about.gitlab.com/blog/2018/10/31/use-multiproject-pipelines-with-gitlab-cicd/)
- [How we used GitLab CI to build GitLab faster](https://about.gitlab.com/blog/2018/05/02/using-gitlab-ci-to-build-gitlab-faster/)
- [Test all the things in GitLab CI with Docker by example](https://about.gitlab.com/blog/2018/02/05/test-all-the-things-gitlab-ci-docker-examples/)
- [A Craftsman looks at continuous integration](https://about.gitlab.com/blog/2018/01/17/craftsman-looks-at-continuous-integration/)
- [Go tools and GitLab: How to do continuous integration like a boss](https://about.gitlab.com/blog/2017/11/27/go-tools-and-gitlab-how-to-do-continuous-integration-like-a-boss/)
- [GitBot - automating boring Git operations with CI](https://about.gitlab.com/blog/2017/11/02/automating-boring-git-operations-gitlab-ci/)
- [How to use GitLab CI for Vue.js](https://about.gitlab.com/blog/2017/09/12/vuejs-app-gitlab/)
- Video: [GitLab CI/CD Deep Dive](https://youtu.be/pBe4t1CD8Fc?t=195)
- [Dockerizing GitLab review apps](https://about.gitlab.com/blog/2017/07/11/dockerizing-review-apps/)
- [Fast and natural continuous integration with GitLab CI](https://about.gitlab.com/blog/2017/05/22/fast-and-natural-continuous-integration-with-gitlab-ci/)
- [Demo: CI/CD with GitLab in action](https://about.gitlab.com/blog/2017/03/13/ci-cd-demo/)

### Migrating to GitLab from third-party CI tools

Examples of migration to GitLab CI/CD from other tools:

- [Bamboo](../migration/bamboo.md)
- [CircleCI](../migration/circleci.md)
- [GitHub Actions](../migration/github_actions.md)
- [Jenkins](../migration/jenkins.md)
- [TeamCity](../migration/teamcity.md)

### Integrating GitLab CI/CD with other systems

To see how you can integrate GitLab CI/CD with third-party systems, see:

- [Streamline and shorten error remediation with Sentry's new GitLab integration](https://about.gitlab.com/blog/2019/01/25/sentry-integration-blog-post/)
- [How to simplify your smart home configuration with GitLab CI/CD](https://about.gitlab.com/blog/2018/08/02/using-the-gitlab-ci-slash-cd-for-smart-home-configuration-management/)
- [Demo: GitLab + Jira + Jenkins](https://about.gitlab.com/blog/2018/07/30/gitlab-workflow-with-jira-jenkins/)
- [Introducing Auto Breakfast from GitLab (sort of)](https://about.gitlab.com/blog/2018/06/29/introducing-auto-breakfast-from-gitlab/)

### Mobile development

For help with using GitLab CI/CD for mobile application development, see:

- [How to publish Android apps to the Google Play Store with GitLab and fastlane](https://about.gitlab.com/blog/2019/01/28/android-publishing-with-gitlab-and-fastlane/)
- [Setting up GitLab CI for Android projects](https://about.gitlab.com/blog/2018/10/24/setting-up-gitlab-ci-for-android-projects/)
- [Working with YAML in GitLab CI from the Android perspective](https://about.gitlab.com/blog/2017/11/20/working-with-yaml-gitlab-ci-android/)
- [How to use GitLab CI and MacStadium to build your macOS or iOS projects](https://about.gitlab.com/blog/2017/05/15/how-to-use-macstadium-and-gitlab-ci-to-build-your-macos-or-ios-projects/)
- [Setting up GitLab CI for iOS projects](https://about.gitlab.com/blog/2016/03/10/setting-up-gitlab-ci-for-ios-projects/)
