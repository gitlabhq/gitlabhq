---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
gitlab_dedicated: yes
title: 외부 인증 제어
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [이동됨](https://gitlab.com/gitlab-org/gitlab-foss/-/merge_requests/27056) \- GitLab Premium에서 GitLab Free로 11.10에 이동.

{{< /history >}}

엄격하게 제어되는 환경에서는 프로젝트 분류 및 사용자 액세스를 기반으로 액세스를 허용하는 외부 서비스에 의해 액세스 정책을 제어해야 할 수 있습니다. GitLab은 자신이 정의한 서비스로 프로젝트 인증을 확인하는 방법을 제공합니다.

외부 서비스가 구성되고 활성화된 후, 프로젝트에 액세스할 때 사용자 정보 및 프로젝트에 할당된 프로젝트 분류 레이블과 함께 외부 서비스에 요청이 전송됩니다. 서비스가 알려진 응답으로 응답하면 결과는 6시간 동안 캐시됩니다.

외부 인증이 활성화되면 GitLab은 교차 프로젝트 데이터를 렌더링하는 페이지 및 기능을 추가로 차단합니다. 여기에는 다음이 포함됩니다:

- 대시보드 아래의 대부분의 페이지(활동, 마일스톤, 스니펫, 할당된 머지 리퀘스트, 할당된 이슈, 할 일 목록).
- 특정 그룹 아래(활동, 기여 분석, 이슈, 이슈 보드, 레이블, 마일스톤, 머지 리퀘스트).
- 전역 및 그룹 검색이 비활성화되었습니다.

이는 외부 인증 서비스에 한 번에 너무 많은 요청을 수행하는 것을 방지하기 위함입니다.

액세스가 부여되거나 거부될 때마다 `external-policy-access-control.log`라는 로그 파일에 기록됩니다. GitLab이 유지하는 로그에 대해 자세히 알아보려면 [Linux 패키지 설명서](https://docs.gitlab.com/omnibus/settings/logs/)를 참조하세요.

자체 서명된 인증서를 사용하여 TLS 인증을 사용할 때 CA 인증서는 OpenSSL 설치에서 신뢰해야 합니다. Linux 패키지를 사용하여 설치된 GitLab을 사용할 때 [Linux 패키지 설명서](https://docs.gitlab.com/omnibus/settings/ssl/)에서 사용자 지정 CA를 설치하는 방법을 알아보세요. 또는 `openssl version -d`를 사용하여 사용자 지정 인증서를 설치할 위치를 알아보세요.

## 구성 {#configuration}

외부 인증 서비스는 관리자가 활성화할 수 있습니다:

1. 오른쪽 위 모서리에서 **Admin**을 선택합니다.
1. 왼쪽 사이드바에서 **Settings** > **General**을 선택합니다.
1. **외부 인증**을 확장합니다.
1. 필드를 완성하세요.
1. **변경 사항 저장**을 선택합니다.

### 배포 토큰 및 배포 키를 사용한 외부 인증 허용 {#allow-external-authorization-with-deploy-tokens-and-deploy-keys}

{{< history >}}

- GitLab 15.9에서 [도입됨](https://gitlab.com/gitlab-org/gitlab/-/issues/386656).
- 배포 토큰이 더 이상 컨테이너 또는 패키지 레지스트리에 액세스할 수 없음 - GitLab 16.0에서 [도입됨](https://gitlab.com/gitlab-org/gitlab/-/issues/387721).

{{< /history >}}

[배포 토큰](../../user/project/deploy_tokens/_index.md) 또는 [배포 키](../../user/project/deploy_keys/_index.md)로 Git 작업에 대한 외부 인증을 허용하도록 인스턴스를 설정할 수 있습니다.

전제 조건:

- 외부 인증을 위해 서비스 URL 없이 분류 레이블을 사용해야 합니다.

배포 토큰 및 키를 사용하여 인증을 허용하려면:

1. 오른쪽 위 모서리에서 **Admin**을 선택합니다.
1. 왼쪽 사이드바에서 **Settings** > **General**을 선택합니다.
1. **외부 인증**을 확장하고:
   - 서비스 URL 필드를 비워둡니다.
   - **외부 인증과 함께 배포 토큰 및 배포 키 사용 허용**을 선택합니다.
1. **변경 사항 저장**을 선택합니다.

> [!warning]
> 외부 인증을 활성화하면 배포 토큰은 컨테이너 또는 패키지 레지스트리에 액세스할 수 없습니다. 배포 토큰을 사용하여 이러한 레지스트리에 액세스하는 경우 이 조치는 이 토큰의 사용을 중단시킵니다. 외부 인증을 비활성화하여 컨테이너 또는 패키지 레지스트리와 함께 토큰을 사용합니다.

## GitLab이 외부 인증 서비스에 연결하는 방법 {#how-gitlab-connects-to-an-external-authorization-service}

GitLab이 액세스를 요청할 때 다음 본문으로 외부 서비스에 JSON POST 요청을 보냅니다:

```json
{
  "user_identifier": "jane@acme.org",
  "project_classification_label": "project-label",
  "user_ldap_dn": "CN=Jane Doe,CN=admin,DC=acme",
  "identities": [
    { "provider": "ldap", "extern_uid": "CN=Jane Doe,CN=admin,DC=acme" },
    { "provider": "bitbucket", "extern_uid": "2435223452345" }
  ]
}
```

`user_ldap_dn`은(는) 선택 사항이며 사용자가 LDAP을 통해 로그인한 경우에만 전송됩니다.

`identities`은(는) 사용자와 연결된 모든 ID의 세부 정보를 포함합니다. 사용자와 연결된 ID가 없으면 이는 빈 배열입니다.

외부 인증 서비스가 상태 코드 200으로 응답하면 사용자에게 액세스 권한이 부여됩니다. 외부 서비스가 상태 코드 401 또는 403으로 응답하면 사용자가 액세스가 거부됩니다. 어떤 경우든 요청은 6시간 동안 캐시됩니다.

액세스를 거부할 때 `reason`을(를) JSON 본문에 선택적으로 지정할 수 있습니다:

```json
{
  "reason": "You are not allowed access to this project."
}
```

200, 401 또는 403 이외의 다른 상태 코드도 사용자의 액세스를 거부하지만 응답은 캐시되지 않습니다.

서비스가 시간 초과되면(500ms 후) "외부 정책 서버가 응답하지 않음" 메시지가 표시됩니다.

## 분류 레이블 {#classification-labels}

프로젝트의 **설정** > **일반** > **General project settings** 페이지의 "분류 레이블" 상자에서 자신의 분류 레이블을 사용할 수 있습니다. 프로젝트에서 분류 레이블을 지정하지 않으면 [전역 설정](#configuration)에서 정의한 기본 레이블이 사용됩니다.

모든 프로젝트 페이지의 오른쪽 위 모서리에 레이블이 표시됩니다.

![빨간색 재정의된 레이블과 열린 잠금 아이콘이 프로젝트의 오른쪽 위 모서리에 표시됩니다.](img/classification_label_on_project_page_v14_8.png)
