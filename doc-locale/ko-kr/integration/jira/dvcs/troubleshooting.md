---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Jira DVCS 커넥터 문제 해결
---

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

[Jira DVCS 커넥터](_index.md)로 작업할 때 다음 이슈가 발생할 수 있습니다.

## Jira에서 GitLab 서버에 액세스할 수 없음 {#jira-cannot-access-the-gitlab-server}

**Add New Account** 양식을 완료하고 액세스를 승인한 후 이 오류가 표시되면 Jira와 GitLab을 연결할 수 없습니다. 다른 오류 메시지는 로그에 표시되지 않습니다:

```plaintext
Error obtaining access token. Cannot access https://gitlab.example.com from Jira.
```

## Jira의 세션 토큰 버그 {#session-token-bug-in-jira}

Jira Server와 함께 GitLab 15.0 이상을 사용하면 [Jira의 세션 토큰 버그](https://jira.atlassian.com/browse/JSWSERVER-21389)가 발생할 수 있습니다. 이 버그는 Jira Server 8.20.8, 8.22.3, 8.22.4, 9.4.6 및 9.4.14에 영향을 미칩니다.

이 이슈를 해결하려면 Jira Server 8.20.11 이상 또는 9.1.0 이상을 사용하는지 확인하세요.

## SSL 및 TLS 문제 {#ssl-and-tls-problems}

SSL 및 TLS 문제로 인해 다음 오류 메시지가 발생할 수 있습니다:

```plaintext
Error obtaining access token. Cannot access https://gitlab.example.com from Jira.
```

- [Jira 이슈 통합](../_index.md)은 GitLab이 Jira에 연결되어야 합니다. GitLab이 TLS 클라이언트이므로 개인 인증 기관이나 자체 서명된 인증서로 인해 발생하는 모든 TLS 이슈는 [GitLab 서버](https://docs.gitlab.com/omnibus/settings/ssl/#install-custom-public-certificates)에서 해결됩니다.
- Jira 개발 패널에서는 Jira가 GitLab에 연결되어야 하므로 Jira가 TLS 클라이언트가 됩니다. GitLab 서버의 인증서가 공개 인증 기관에서 발급되지 않은 경우 적절한 인증서(예: 조직의 루트 인증서)를 Jira Server의 Java Truststore에 추가하세요.

Jira 설정에 대한 자세한 내용은 Atlassian 설명서 및 Atlassian 지원을 참조하세요.

- [인증서 추가](https://confluence.atlassian.com/kb/how-to-import-a-public-ssl-certificate-into-a-jvm-867025849.html) (신뢰 저장소에).
  - 가장 간단한 방법은 [`keytool`](https://docs.oracle.com/javase/8/docs/technotes/tools/unix/keytool.html)입니다.
  - Java의 기본 Truststore (`cacerts`)에 추가 루트를 추가하여 Jira가 공개 인증 기관도 신뢰하도록 허용하세요.
  - Jira Java 런타임을 업그레이드한 후 통합이 작동하지 않으면 `cacerts` Truststore가 업그레이드 중에 교체되었을 수 있습니다.
- `SSLPoke` Java 클래스를 사용하여 [TLS 핸드셰이킹까지 포함한](https://confluence.atlassian.com/kb/unable-to-connect-to-ssl-services-due-to-pkix-path-building-failed-error-779355358.html) 연결을 문제 해결합니다.
- Atlassian 기술 자료에서 클래스를 Jira Server의 디렉터리(예: `/tmp`)로 다운로드합니다.
- Jira와 동일한 Java 런타임을 사용하세요.
- Jira가 호출되는 프록시 설정 또는 대체 루트 Truststore(`-Djavax.net.ssl.trustStore`)와 같은 모든 네트워킹 관련 매개변수를 전달하세요:

```shell
${JAVA_HOME}/bin/java -Djavax.net.ssl.trustStore=/var/atlassian/application-data/jira/cacerts -classpath /tmp SSLPoke gitlab.example.com 443
```

`Successfully connected` 메시지는 성공적인 TLS 핸드셰이크를 나타냅니다.

문제가 있으면 Java TLS 라이브러리가 자세한 내용을 찾아볼 수 있는 오류를 생성합니다.

## DVCS로 Jira에 연결할 때 범위 오류 {#scope-error-when-connecting-to-jira-with-dvcs}

```plaintext
The requested scope is invalid, unknown, or malformed.
```

가능한 해결책:

1. Jira에서 리디렉션된 후 브라우저에 표시되는 URL이 [Jira DVCS 커넥터 설정](https://confluence.atlassian.com/adminjiraserver/linking-gitlab-accounts-1027142272.html#LinkingGitLabaccounts-InJiraagain)에서 쿼리 문자열에 `scope=api`을 포함하는지 확인하세요.
1. URL에서 `scope=api`이 없으면 [GitLab 계정 구성](https://confluence.atlassian.com/adminjiraserver/linking-gitlab-accounts-1027142272.html#LinkingGitLabaccounts-InGitLab)을 편집하세요. **범위** 필드를 검토하고 `api` 체크박스가 선택되어 있는지 확인하세요.

## 오류: `410 Gone` {#error-410-gone}

Jira에 연결하고 를 동기화할 때 `410 Gone` 오류가 발생할 수 있습니다. 이 이슈는 Jira DVCS 커넥터를 사용하고 통합이 **GitHub Enterprise**를 사용하도록 구성되어 있을 때 발생합니다.

자세한 내용은 [이슈 340160](https://gitlab.com/gitlab-org/gitlab/-/issues/340160)을 참조하세요.

## 동기화 이슈 {#synchronization-issues}

Jira에 삭제된 와 같은 잘못된 정보가 표시되면 정보를 다시 동기화해야 할 수 있습니다:

1. Jira에서 **Jira Administration** > **응용 프로그램** > **DVCS accounts**를 선택하세요.
1. 계정(그룹 또는 서브그룹)의 경우 {{< icon name="ellipsis_h" >}} (줄임표) 메뉴에서 **Refresh repositories**를 선택하세요.
1. 각 프로젝트의 **마지막 활동** 날짜 옆에서:
   - 소프트 재동기화를 수행하려면 동기화 아이콘을 선택하세요.
   - 완전한 동기화를 완료하려면 `Shift`을 누르고 동기화 아이콘을 선택하세요.

자세한 내용은 [Atlassian 설명서](https://support.atlassian.com/jira-cloud-administration/docs/integrate-with-development-tools/)를 참조하세요.

## 오류: `Sync Failed` {#error-sync-failed}

특정 프로젝트에 대해 `Sync Failed` 오류가 발생하면 Jira DVCS 커넥터 로그를 확인하세요 [데이터 새로 고침](_index.md#refresh-data-imported-to-jira)할 때. GitLab의 API 리소스에 요청을 실행할 때 발생하는 오류를 찾으세요. 예를 들어:

```plaintext
Failed to execute request [https://gitlab.com/api/v4/projects/:id/merge_requests?page=1&per_page=100 GET https://gitlab.com/api/v4/projects/:id/merge_requests?page=1&per_page=100 returned a response status of 403 Forbidden] errors:
{"message":"403 Forbidden"}
```

`403 Forbidden` 오류가 발생하면 이 프로젝트에 일부 [GitLab 기능이 비활성화](../../../user/project/settings/_index.md#configure-project-features-and-permissions)되어 있을 수 있습니다. 앞의 예에서 머지 리퀘스트 기능이 비활성화되어 있습니다.

이 이슈를 해결하려면 관련 기능을 활성화하세요:

1. 상단 바에서 **검색 또는 이동**을 선택하고 프로젝트를 찾습니다.
1. 왼쪽 사이드바에서 **설정** > **일반**을 선택합니다.
1. **표시 여부, 프로젝트 기능, 권한**을 확장합니다.
1. 필요에 따라 토글을 사용하여 기능을 활성화하세요.

## DVCS 연결 프로젝트에서 웹후크 로그 찾기 {#find-webhook-logs-in-a-dvcs-linked-project}

DVCS 연결 프로젝트에서 웹후크 로그를 찾으려면:

1. 상단 바에서 **검색 또는 이동**을 선택하고 프로젝트를 찾습니다.
1. 왼쪽 사이드바에서 **설정** > **웹후크**를 선택합니다.
1. **Project hooks**로 아래로 스크롤하세요.
1. Jira 인스턴스를 가리키는 로그 옆에서 **편집**을 선택하세요.
1. **최근 이벤트**로 아래로 스크롤하세요.

프로젝트에서 웹후크 로그를 찾을 수 없으면 DVCS 설정에서 문제를 확인하세요.
