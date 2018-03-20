---
comments: false
---

# GitLab CI/CD Examples

A collection of `.gitlab-ci.yml` template files is maintained at the [GitLab CI/CD YAML project][gitlab-ci-templates]. When you create a new file via the UI,
GitLab will give you the option to choose one of the templates existent on this project.
If your favorite programming language or framework are missing we would love your
help by sending a merge request with a new `.gitlab-ci.yml` to this project.

There's also a collection of repositories with [example projects](https://gitlab.com/gitlab-examples) for various languages. You can fork an adjust them to your own needs.

## Languages, frameworks, OSs

- **PHP**:
  - [Testing a PHP application](php.md)
  - [Run PHP Composer & NPM scripts then deploy them to a staging server](deployment/composer-npm-deploy.md)
  - [How to test and deploy Laravel/PHP applications with GitLab CI/CD and Envoy](laravel_with_gitlab_and_envoy/index.md)
- **Ruby**: [Test and deploy a Ruby application to Heroku](test-and-deploy-ruby-application-to-heroku.md)
- **Python**: [Test and deploy a Python application to Heroku](test-and-deploy-python-application-to-heroku.md)
- **Java**: [Continuous Delivery of a Spring Boot application with GitLab CI and Kubernetes](https://about.gitlab.com/2016/12/14/continuous-delivery-of-a-spring-boot-application-with-gitlab-ci-and-kubernetes/)
- **Scala**: [Test a Scala application](test-scala-application.md)
- **Clojure**: [Test a Clojure application](test-clojure-application.md)
- **Elixir**:
  - [Testing a Phoenix application with GitLab CI/CD](test_phoenix_app_with_gitlab_ci_cd/index.md)
  - [Building an Elixir Release into a Docker image using GitLab CI](https://about.gitlab.com/2016/08/11/building-an-elixir-release-into-docker-image-using-gitlab-ci-part-1/)
- **iOS and macOS**:
  - [Setting up GitLab CI for iOS projects](https://about.gitlab.com/2016/03/10/setting-up-gitlab-ci-for-ios-projects/)
  - [How to use GitLab CI and MacStadium to build your macOS or iOS projects](https://about.gitlab.com/2017/05/15/how-to-use-macstadium-and-gitlab-ci-to-build-your-macos-or-ios-projects/)
- **Android**: [Setting up GitLab CI for Android projects](https://about.gitlab.com/2016/11/30/setting-up-gitlab-ci-for-android-projects/)
- **Debian**: [Continuous Deployment with GitLab: how to build and deploy a Debian Package with GitLab CI](https://about.gitlab.com/2016/10/12/automated-debian-package-build-with-gitlab-ci/)
- **Maven**: [How to deploy Maven projects to Artifactory with GitLab CI/CD](artifactory_and_gitlab/index.md)

### Game development

- [DevOps and Game Dev with GitLab CI/CD](devops_and_game_dev_with_gitlab_ci_cd/index.md)

### Miscellaneous

- [Using `dpl` as deployment tool](deployment/README.md)
- [The `.gitlab-ci.yml` file for GitLab itself](https://gitlab.com/gitlab-org/gitlab-ce/blob/master/.gitlab-ci.yml)

## Code quality analysis

[Analyze code quality with the Code Climate CLI](code_climate.md).

## Static Application Security Testing (SAST)

**(Ultimate)** [Scan your code for vulnerabilities](sast.md)

## Dependency Scanning

**(Ultimate)** [Scan your dependencies for vulnerabilities](dependency_scanning.md)

## Container Scanning

[Scan your Docker images for vulnerabilities](container_scanning.md)

## Dynamic Application Security Testing (DAST)

Scan your app for vulnerabilities with GitLab [Dynamic Application Security Testing (DAST)](dast.md).

## Browser Performance Testing with Sitespeed.io

Analyze your [browser performance with Sitespeed.io](browser_performance.md).

## GitLab CI/CD for Review Apps

- [Example project](https://gitlab.com/gitlab-examples/review-apps-nginx/) that shows how to use GitLab CI/CD for [Review Apps](../review_apps/index.html).
- [Dockerizing GitLab Review Apps](https://about.gitlab.com/2017/07/11/dockerizing-review-apps/)

## GitLab CI/CD for GitLab Pages

See the documentation on [GitLab Pages](../../user/project/pages/index.md) for a complete overview.

## Contributing

Contributions are very welcome! You can help your favorite programming
language users and GitLab by sending a merge request with a guide for that language.
You may want to apply for the [GitLab Community Writers Program](https://about.gitlab.com/community-writers/)
to get paid for writing complete articles for GitLab.

[gitlab-ci-templates]: https://gitlab.com/gitlab-org/gitlab-ci-yml
