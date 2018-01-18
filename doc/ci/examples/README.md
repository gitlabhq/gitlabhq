---
comments: false
---

# GitLab CI Examples

A collection of `.gitlab-ci.yml` files is maintained at the [GitLab CI Yml project][gitlab-ci-templates].
If your favorite programming language or framework are missing we would love your help by sending a merge request
with a `.gitlab-ci.yml`.

Apart from those, here is an collection of tutorials and guides on setting up your CI pipeline:

## Languages, frameworks, OSs

### PHP

- [Testing a PHP application](php.md)
- [Run PHP Composer & NPM scripts then deploy them to a staging server](deployment/composer-npm-deploy.md)

### Ruby

- [Test and deploy a Ruby application to Heroku](test-and-deploy-ruby-application-to-heroku.md)

### Python

- [Test and deploy a Python application to Heroku](test-and-deploy-python-application-to-heroku.md)

### Java

- [Continuous Delivery of a Spring Boot application with GitLab CI and Kubernetes](https://about.gitlab.com/2016/12/14/continuous-delivery-of-a-spring-boot-application-with-gitlab-ci-and-kubernetes/)

### Scala

- [Test a Scala application](test-scala-application.md)

### Clojure

- [Test a Clojure application](test-clojure-application.md)

### Elixir

- [Test a Phoenix application](test-phoenix-application.md)
- [Building an Elixir Release into a Docker image using GitLab CI](https://about.gitlab.com/2016/08/11/building-an-elixir-release-into-docker-image-using-gitlab-ci-part-1/)

### iOS

- [Setting up GitLab CI for iOS projects](https://about.gitlab.com/2016/03/10/setting-up-gitlab-ci-for-ios-projects/)

### Android

- [Setting up GitLab CI for Android projects](https://about.gitlab.com/2016/11/30/setting-up-gitlab-ci-for-android-projects/)

### Code quality analysis

- [Analyze code quality with the Code Climate CLI](code_climate.md)

### Static Application Security Testing (SAST)

- **(EEU)** [Scan your code for vulnerabilities](https://docs.gitlab.com/ee/ci/examples/sast.html)
- [Scan your Docker images for vulnerabilities](sast_docker.md)

### Dynamic Application Security Testing (DAST)

Scan your app for vulnerabilities with GitLab [Dynamic Application Security Testing (DAST)](dast.md).

### Browser Performance Testing with Sitespeed.io

Analyze your [browser performance with Sitespeed.io](browser_performance.md).

### GitLab CI/CD for Review Apps

## GitLab CI/CD for GitLab Pages

- [Example projects](https://gitlab.com/pages)
- [Creating and Tweaking `.gitlab-ci.yml` for GitLab Pages](../../user/project/pages/getting_started_part_four.md)
- [SSGs Part 3: Build any SSG site with GitLab Pages](https://about.gitlab.com/2016/06/17/ssg-overview-gitlab-pages-part-3-examples-ci/):
examples for Ruby-, NodeJS-, Python-, and GoLang-based SSGs
- [Building a new GitLab docs site with Nanoc, GitLab CI, and GitLab Pages](https://about.gitlab.com/2016/12/07/building-a-new-gitlab-docs-site-with-nanoc-gitlab-ci-and-gitlab-pages/)
- [Publish code coverage reports with GitLab Pages](https://about.gitlab.com/2016/11/03/publish-code-coverage-report-with-gitlab-pages/)

See the documentation on [GitLab Pages](../../user/project/pages/index.md) for a complete overview.

## More

Contributions are very much welcomed! You can help your favorite programming
language and GitLab by sending a merge request with a guide for that language.

[gitlab-ci-templates]: https://gitlab.com/gitlab-org/gitlab-ci-yml
