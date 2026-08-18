---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "GitLab CI/CD를 다양한 언어, 프레임워크 및 배포 대상에 걸쳐 구현하기 위한 예제와 커뮤니티에서 제공한 가이드입니다."
title: CI/CD 예제
---

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

이 예제를 사용하여 특정 사용 사례에 맞게 [GitLab CI/CD](../_index.md)를 구현합니다.

## 예제 {#examples}

| 사용 사례                      | 리소스 |
| ----------------------------- | -------- |
| Dpl을 사용한 배포           | [Dpl 도구를 사용하여 애플리케이션 배포](deployment/_index.md) |
| GitLab Pages                  | [자동 CI/CD 배포로 정적 웹사이트 게시](../../user/project/pages/_index.md) |
| 다중 프로젝트 파이프라인        | [다중 프로젝트 파이프라인을 사용하여 빌드, 테스트 및 배포](https://gitlab.com/gitlab-examples/upstream-project) |
| semantic-release를 사용한 npm     | [GitLab 패키지 레지스트리에 npm 패키지 게시](semantic-release.md) |
| SCP를 사용한 Composer 및 npm     | [SCP를 사용하여 Composer 및 npm 스크립트 배포](deployment/composer-npm-deploy.md) |
| PHPUnit 및 `atoum`을 사용한 PHP  | [PHP 프로젝트 테스트](php.md) |
| Vault를 사용한 시크릿 관리 | [HashiCorp Vault를 사용하여 시크릿 인증 및 읽기](../secrets/hashicorp_vault_tutorial.md) |

## 커뮤니티 기여 예제 {#community-contributed-examples}

이 예제들은 GitLab이 아닌 커뮤니티에서 관리합니다. 대부분의 예제 프로젝트는 GitLab에서 호스팅되며 포크하여 자신의 요구 사항에 맞게 수정할 수 있습니다.

| 사용 사례                   | 리소스 |
| -------------------------- | -------- |
| Clojure                    | [Clojure 애플리케이션 테스트](https://gitlab.com/gitlab-examples/clojure-web-application) |
| 게임 개발           | [게임 개발을 위한 CI/CD 설정](https://gitlab.com/gitlab-examples/gitlab-game-demo/) |
| Maven을 사용한 Java            | [Maven 프로젝트를 Artifactory에 배포](https://gitlab.com/gitlab-examples/maven/simple-maven-example) |
| Spring Boot를 사용한 Java      | [Spring Boot 애플리케이션을 Cloud Foundry에 배포](https://gitlab.com/gitlab-examples/spring-gitlab-cf-deploy-demo) |
| Ruby 및 JS 병렬 테스트 | [Ruby 및 JavaScript의 병렬 테스트 실행](https://docs.knapsackpro.com/2019/how-to-run-parallel-jobs-for-rspec-tests-on-gitlab-ci-pipeline-and-speed-up-ruby-javascript-testing) |
| Heroku의 Python           | [Python 애플리케이션을 Heroku에 테스트 및 배포](https://gitlab.com/gitlab-examples/python-getting-started) |
| NGINX를 사용한 검토 앱     | [NGINX를 사용한 검토 앱 설정](https://gitlab.com/gitlab-examples/review-apps-nginx/) |
| Heroku의 Ruby             | [Ruby 애플리케이션을 Heroku에 테스트 및 배포](https://gitlab.com/gitlab-examples/ruby-getting-started) |
| Heroku의 Scala            | [Scala 애플리케이션을 Heroku에 테스트 및 배포](https://gitlab.com/gitlab-examples/scala-sbt) |

## CI/CD 마이그레이션 예제 {#cicd-migration-examples}

- [Bamboo](../migration/bamboo.md)
- [CircleCI](../migration/circleci.md)
- [GitHub Actions](../migration/github_actions.md)
- [Jenkins](../migration/jenkins.md)
- [TeamCity](../migration/teamcity.md)

## 관련 항목 {#related-topics}

- [CI/CD 카탈로그](../components/_index.md#cicd-catalog)
- [튜토리얼: 애플리케이션 빌드](../../tutorials/build_application.md)
- [예제 프로젝트](https://gitlab.com/gitlab-examples)
