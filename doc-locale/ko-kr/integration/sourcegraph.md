---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 소스그래프
---

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

> [!note]
> GitLab.com에서는 이 기능이 공개 프로젝트에만 사용 가능합니다.

[소스그래프](https://sourcegraph.com)는 GitLab UI에서 코드 인텔리전스 기능을 제공합니다. 활성화되면 참여 프로젝트는 다음 코드 보기에서 코드 인텔리전스 팝오버를 표시합니다:

- 머지 리퀘스트 diff
- 커밋 보기
- 파일 보기

이러한 보기 중 하나를 방문할 때, 코드 참조 위에 커서를 올려 다음이 포함된 팝오버를 확인합니다:

- 이 참조가 정의된 방식에 대한 세부 정보입니다.
- **정의로 이동** \- 이 참조가 정의된 코드 줄로 이동합니다.
- **Find references** \- 구성된 소스그래프 인스턴스로 이동하여 강조 표시된 코드에 대한 참조 목록을 표시합니다.

<i class="fa-youtube-play" aria-hidden="true"></i> 개요는 [Sourcegraph의 새로운 GitLab 네이티브 통합](https://www.youtube.com/watch?v=LjVxkt4_sEA) 비디오를 시청하세요.
<!-- Video published on 2019-11-12 -->

자세한 내용은 [에픽 2201](https://gitlab.com/groups/gitlab-org/-/epics/2201)을 참고합니다.

## GitLab Self-Managed 설정 {#set-up-for-gitlab-self-managed}

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

전제 조건:

- Sourcegraph 인스턴스가 GitLab 인스턴스와 외부 서비스로 [구성되고 실행 중](https://sourcegraph.com/docs/admin)이어야 합니다.
- Sourcegraph 인스턴스에서 GitLab으로의 HTTPS 연결을 사용하는 경우, Sourcegraph 인스턴스에 대해 [HTTPS를 구성](https://sourcegraph.com/docs/admin/http_https_configuration)해야 합니다.

Sourcegraph에서:

1. **Site admin** 영역으로 이동합니다.
1. 선택 사항. [GitLab 외부 서비스 구성](https://sourcegraph.com/docs/admin/code_hosts/gitlab). GitLab 리포지토리가 이미 Sourcegraph에서 검색 가능한 경우, 이 단계를 건너뜁니다.
1. 테스트 쿼리를 실행하여 Sourcegraph 인스턴스에서 GitLab의 리포지토리를 검색할 수 있는지 확인합니다.
1. GitLab 인스턴스 URL을 Sourcegraph 구성의 [`corsOrigin` 설정](https://sourcegraph.com/docs/admin/config/site_config#corsOrigin)에 추가합니다.

다음으로, GitLab 인스턴스가 Sourcegraph 인스턴스에 연결되도록 구성합니다.

### GitLab 인스턴스를 Sourcegraph와 함께 구성 {#configure-your-gitlab-instance-with-sourcegraph}

전제 조건:

- 관리자(administrator) 권한이 있어야 합니다.

1. 오른쪽 위 모서리에서 **운영자**를 선택합니다.
1. 왼쪽 사이드바에서 **설정** > **일반**을 선택합니다.
1. **소스 그래프**를 확장합니다.
1. **Sourcegraph 활성화**를 선택합니다.
1. 선택 사항. **비공개 및 내부 프로젝트 차단**을 선택합니다.
1. **Sourcegraph URL**을 Sourcegraph 인스턴스(예: `https://sourcegraph.example.com`)로 설정합니다.
1. **변경 사항 저장**을 선택합니다.

## 사용자 기본 설정에서 Sourcegraph 활성화 {#enable-sourcegraph-in-user-preferences}

GitLab Self-Managed의 사용자는 Sourcegraph 통합을 사용하기 위해 사용자 설정도 구성해야 합니다.

GitLab.com에서는 모든 공개 프로젝트에서 통합을 사용할 수 있습니다. 비공개 프로젝트는 지원되지 않습니다.

전제 조건:

- GitLab Self-Managed의 경우, Sourcegraph를 활성화해야 합니다.

GitLab 사용자 기본 설정에서 이 기능을 활성화하려면:

1. 오른쪽 위 모서리에서 아바타를 선택합니다.
1. **환경설정**을 선택합니다.
1. **연동** 섹션으로 스크롤합니다. **소스 그래프** 아래에서 **코드 보기에서 통합 코드 인텔리전스 활성화**를 선택합니다.
1. **변경 사항 저장**을 선택합니다.

## 참고 자료 {#references}

- Sourcegraph 설명서의 [개인정보 보호 정보](https://sourcegraph.com/docs/integration/browser_extension/references/privacy)

## 문제 해결 {#troubleshooting}

### Sourcegraph가 작동하지 않음 {#sourcegraph-is-not-working}

프로젝트에 대해 Sourcegraph를 활성화했지만 작동하지 않는 경우, Sourcegraph가 아직 프로젝트를 인덱싱하지 않았을 수 있습니다. `https://sourcegraph.com/gitlab.com/<project-path>`을 방문하여 프로젝트에 Sourcegraph를 사용할 수 있는지 확인할 수 있습니다. `<project-path>`를 GitLab 프로젝트의 경로로 바꿉니다.
