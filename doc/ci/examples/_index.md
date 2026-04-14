---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: Examples and community-contributed guides for implementing GitLab CI/CD across languages, frameworks, and deployment targets.
title: CI/CD examples
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Use these examples to implement [GitLab CI/CD](../_index.md) for your specific use case.

## Examples

| Use case                      | Resource |
| ----------------------------- | -------- |
| Deployment with Dpl           | [Deploy applications using the Dpl tool](deployment/_index.md) |
| GitLab Pages                  | [Publish static websites with automatic CI/CD deployment](../../user/project/pages/_index.md) |
| Multi-project pipeline        | [Build, test, and deploy using multi-project pipelines](https://gitlab.com/gitlab-examples/upstream-project) |
| npm with semantic-release     | [Publish npm packages to the GitLab package registry](semantic-release.md) |
| Composer and npm with SCP     | [Deploy Composer and npm scripts using SCP](deployment/composer-npm-deploy.md) |
| PHP with PHPUnit and `atoum`  | [Test PHP projects](php.md) |
| Secrets management with Vault | [Authenticate and read secrets with HashiCorp Vault](../secrets/hashicorp_vault_tutorial.md) |

## Community-contributed examples

These examples are maintained by the community rather than GitLab.
Most example projects are hosted on GitLab and can be forked and adapted for your own needs.

| Use case                   | Resource |
| -------------------------- | -------- |
| Clojure                    | [Test a Clojure application](https://gitlab.com/gitlab-examples/clojure-web-application) |
| Game development           | [Set up CI/CD for game development](https://gitlab.com/gitlab-examples/gitlab-game-demo/) |
| Java with Maven            | [Deploy Maven projects to Artifactory](https://gitlab.com/gitlab-examples/maven/simple-maven-example) |
| Java with Spring Boot      | [Deploy a Spring Boot application to Cloud Foundry](https://gitlab.com/gitlab-examples/spring-gitlab-cf-deploy-demo) |
| Parallel testing Ruby & JS | [Run parallel tests for Ruby and JavaScript](https://docs.knapsackpro.com/2019/how-to-run-parallel-jobs-for-rspec-tests-on-gitlab-ci-pipeline-and-speed-up-ruby-javascript-testing) |
| Python on Heroku           | [Test and deploy a Python application to Heroku](https://gitlab.com/gitlab-examples/python-getting-started) |
| Review apps with NGINX     | [Set up review apps with NGINX](https://gitlab.com/gitlab-examples/review-apps-nginx/) |
| Ruby on Heroku             | [Test and deploy a Ruby application to Heroku](https://gitlab.com/gitlab-examples/ruby-getting-started) |
| Scala on Heroku            | [Test and deploy a Scala application to Heroku](https://gitlab.com/gitlab-examples/scala-sbt) |

## CI/CD migration examples

- [Bamboo](../migration/bamboo.md)
- [CircleCI](../migration/circleci.md)
- [GitHub Actions](../migration/github_actions.md)
- [Jenkins](../migration/jenkins.md)
- [TeamCity](../migration/teamcity.md)

## Related topics

- [CI/CD Catalog](../components/_index.md#cicd-catalog)
- [Tutorials: Build your application](../../tutorials/build_application.md)
- [Example projects](https://gitlab.com/gitlab-examples)
