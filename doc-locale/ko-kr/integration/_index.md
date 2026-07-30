---
stage: none
group: unassigned
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "프로젝트, 이슈, 인증, 보안 제공자."
title: GitLab과 통합하기
---

GitLab을 외부 애플리케이션과 통합하여 향상된 기능을 사용할 수 있습니다.

## 프로젝트 통합 {#project-integrations}

Jenkins, Jira, Slack과 같은 애플리케이션은 [프로젝트 통합](../user/project/integrations/_index.md)으로 사용할 수 있습니다.

## 이슈 추적기 {#issue-trackers}

[외부 이슈 추적기](external-issue-tracker.md)를 구성하고 다음을 사용할 수 있습니다:

- GitLab 이슈 추적기와 함께 외부 이슈 추적기
- 외부 이슈 추적기만

## 인증 제공자 {#authentication-providers}

GitLab을 LDAP 및 SAML과 같은 인증 제공자와 통합할 수 있습니다.

자세한 내용은 [GitLab 인증 및 권한 부여](../administration/auth/_index.md)를 참조하세요.

## 보안 개선 {#security-improvements}

Akismet 및 reCAPTCHA와 같은 솔루션은 스팸 방지에 사용할 수 있습니다.

다음 보안 파트너와 GitLab을 통합할 수도 있습니다:

<!-- vale gitlab_base.Spelling = NO -->

- [Anchore](https://docs.anchore.com/current/docs/integration/ci_cd/gitlab/)
- [Prisma Cloud](https://docs.prismacloud.io/en/enterprise-edition/content-collections/application-security/get-started/connect-code-and-build-providers/code-repositories/add-gitlab)
- [Checkmarx](https://checkmarx.atlassian.net/wiki/spaces/SD/pages/1929937052/GitLab+Integration)
- [CodeSecure](https://codesecure.com/our-integrations/codesonar-sast-gitlab-ci-pipeline/)
- [Fortify](https://www.microfocus.com/en-us/fortify-integrations/gitlab)
- [Jscrambler](https://docs.jscrambler.com/code-integrity/documentation/gitlab-ci-integration)
- [Mend](https://www.mend.io/gitlab/)
- [Semgrep](https://semgrep.dev/for/gitlab/)
- [StackHawk](https://docs.stackhawk.com/continuous-integration/gitlab/)
- [Tenable](https://docs.tenable.com/vulnerability-management/Content/vulnerability-management/VulnerabilityManagementOverview.htm)
- [Venafi](https://marketplace.venafi.com/xchange/620d2d6ed419fb06a5c5bd36/solution/6292c2ef7550f2ee553cf223)
- [Veracode](https://docs.veracode.com/r/c_integration_buildservs#gitlab)

<!-- vale gitlab_base.Spelling = YES -->

GitLab은 애플리케이션의 보안 취약성을 확인할 수 있습니다. 자세한 내용은 [애플리케이션 보안](../user/application_security/secure_your_application.md)을 참조하세요.

## 문제 해결 {#troubleshooting}

통합 작업 시 다음 이슈가 발생할 수 있습니다.

### SSL 인증서 오류 {#ssl-certificate-errors}

자체 서명된 인증서를 사용하여 GitLab을 외부 애플리케이션과 통합할 때 GitLab의 다양한 부분에서 SSL 인증서 오류가 발생할 수 있습니다.

해결 방법으로 다음 중 하나를 수행합니다:

- 인증서를 OS 신뢰 체인에 추가합니다. 자세한 정보는 다음을 참조하세요.
  - [서버에 신뢰할 수 있는 루트 인증서 추가](https://manuals.gfi.com/en/kerio/connect/content/server-configuration/ssl-certificates/adding-trusted-root-certificates-to-the-server-1605.html)
  - [Ubuntu에 인증서 기관(CA)을 추가하려면 어떻게 합니까?](https://superuser.com/questions/437330/how-do-you-add-a-certificate-authority-ca-to-ubuntu)
- Linux 패키지를 사용하는 설치의 경우 인증서를 GitLab 신뢰 체인에 추가합니다:
  1. [자체 서명된 인증서 설치](https://docs.gitlab.com/omnibus/settings/ssl/#install-custom-public-certificates)
  1. 자체 서명된 인증서를 GitLab 신뢰 인증서와 연결합니다. 자체 서명된 인증서는 업그레이드 중에 덮어쓰기될 수 있습니다.

     ```shell
     cat jira.pem >> /opt/gitlab/embedded/ssl/certs/cacert.pem
     ```

  1. GitLab을 다시 시작합니다.

     ```shell
     sudo gitlab-ctl restart
     ```

### Kibana에서 Sidekiq 로그 검색 {#search-sidekiq-logs-in-kibana}

Kibana에서 특정 통합을 찾으려면 다음 KQL 검색 문자열을 사용합니다:

```plaintext
`json.integration_class.keyword : "Integrations::Jira" and json.project_path : "path/to/project"`
```

다음에서 정보를 찾을 수 있습니다:

- `json.exception.backtrace`
- `json.exception.class`
- `json.exception.message`
- `json.message`

### 오류: `Test Failed. Save Anyway` {#error-test-failed-save-anyway}

초기화되지 않은 리포지토리에서 통합을 구성하면 통합이 `Test Failed. Save Anyway` 오류로 실패할 수 있습니다. 이 오류는 프로젝트에 푸시 이벤트가 없을 때 통합이 푸시 데이터를 사용하여 테스트 페이로드를 구성하기 때문에 발생합니다.

이 이슈를 해결하려면 테스트 파일을 프로젝트에 푸시하여 리포지토리를 초기화하고 통합을 다시 구성합니다.
