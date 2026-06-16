---
stage: Tenant Scale
group: Organizations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: 조직에 맞게 프로젝트를 구성하세요.
title: 프로젝트로 작업 정리 시작하기
---

GitLab의 프로젝트는 특정 개발 프로젝트의 모든 데이터를 구성합니다. 프로젝트는 팀과 협업하고 파일을 저장하고 작업을 관리하는 곳입니다.

프로젝트를 사용하여:

- 코드 작성 및 저장
- 이슈 및 작업 추적
- 코드 변경 사항 협업
- 앱 테스트 및 배포

프로젝트 생성 및 유지 관리는 더 큰 워크플로의 일부입니다:

![프로젝트로 작업을 구성하는 것은 개발 워크플로 계획 스테이지의 일부입니다.](img/get_started_projects_v16_11.png)

## 1단계:  프로젝트 생성 {#step-1-create-a-project}

코드베이스, 문서 및 관련 리소스를 포함할 새 프로젝트를 GitLab에서 생성하여 시작하세요.

프로젝트는 리포지토리를 포함합니다. 리포지토리는 작업과 관련된 모든 파일, 디렉터리 및 데이터를 포함합니다.

프로젝트를 생성할 때 개발 워크플로 및 협업 요구 사항에 맞게 다음 설정을 검토하고 구성하세요:

- 가시성 수준
- 머지 리퀘스트 승인
- 이슈 추적
- CI/CD 파이프라인
- 이슈 또는 머지 리퀘스트와 같은 엔티티에 대한 설명 템플릿

자세한 정보는 다음을 참조하세요:

- [프로젝트 생성](../project/_index.md)
- [프로젝트 관리](../project/working_with_projects.md)
- [프로젝트 가시성](../public_access.md)
- [프로젝트 설정](../project/settings/_index.md)
- [설명 템플릿](../project/description_templates.md)

## 2단계:  프로젝트 보안 및 액세스 제어 {#step-2-secure-and-control-access-to-projects}

다음 도구를 사용하여 프로젝트에 대한 보안 액세스를 관리하세요:

- 프로젝트 액세스 토큰:  안전한 통합을 위해 자동화된 도구 또는 외부 시스템에 특정 액세스 권한을 부여하세요.
- 배포 키:  외부 시스템에 프로젝트를 안전하게 배포하기 위해 리포지토리에 대한 읽기 전용 액세스를 부여하세요.
- 배포 토큰:  안전한 배포 및 자동화를 위해 프로젝트 리포지토리 및 레지스트리에 임시 제한 액세스를 부여하세요.

자세한 정보는 다음을 참조하세요:

- [프로젝트 액세스 토큰](../project/settings/project_access_tokens.md)
- [배포 키](../project/deploy_keys/_index.md)
- [배포 토큰](../project/deploy_tokens/_index.md)

## 3단계:  프로젝트 협업 및 공유 {#step-3-collaborate-and-share-projects}

여러 프로젝트를 그룹에 초대할 수 있으며, 이를 `sharing a project with a group`이라고도 합니다. 각 프로젝트는 자체 리포지토리, 이슈, 머지 리퀘스트 및 기타 기능을 가지고 있습니다.

그룹에 여러 프로젝트가 있으면 팀원이 개별 프로젝트에서 협업하면서 그룹 내의 모든 작업에 대한 높은 수준의 보기를 가질 수 있습니다.

프로젝트 액세스를 더욱 세분화하려면 그룹에 하위 그룹을 추가할 수 있습니다.

자세한 정보는 다음을 참조하세요:

- [프로젝트 공유](../project/members/sharing_projects_groups.md)
- [하위 그룹](../group/subgroups/_index.md)

## 4단계:  프로젝트 발견 가능성 및 인식 향상 {#step-4-enhance-project-discoverability-and-recognition}

검색 상자를 사용하여 GitLab 인스턴스 전체에서 특정 프로젝트, 이슈, 머지 리퀘스트 또는 코드 스니펫을 빠르게 찾으세요.

프로젝트를 더 쉽게 찾으려면:

- 예약된 프로젝트 및 그룹 이름을 사용하여 프로젝트에 대한 일관되고 인식 가능한 명명 규칙을 만드세요.
- 프로젝트의 `README` 파일에 배지를 추가하세요. 배지는 빌드 상태, 프로젝트 상태, 테스트 커버리지 또는 버전 번호와 같은 중요한 정보를 표시할 수 있습니다.
- 프로젝트 주제를 할당하세요. 주제는 프로젝트를 정리하고 찾는 데 도움이 되는 레이블입니다.

자세한 정보는 다음을 참조하세요:

- [예약된 프로젝트 및 그룹 이름](../reserved_names.md)
- [검색](../search/_index.md)
- [배지](../project/badges.md)
- [프로젝트 주제](../project/project_topics.md)

## 5단계:  개발 효율성 향상 및 코드 품질 유지 {#step-5-boost-development-efficiency-and-maintain-code-quality}

다음과 같은 코드 인텔리전스 기능을 사용하여 생산성을 높이고 고품질 코드베이스를 유지하세요:

- 코드 탐색
- 마우스 호버 정보
- 자동 완성

코드 인텔리전스는 코드베이스를 효율적으로 탐색, 분석 및 유지 관리하는 데 도움이 되는 도구들입니다.

프로젝트의 특정 파일을 빠르게 찾아 이동하려면 파일 찾기를 사용하세요.

자세한 정보는 다음을 참조하세요:

- [코드 인텔리전스](../project/code_intelligence.md)
- [파일](../project/repository/files/_index.md)

## 6단계:  프로젝트를 GitLab으로 마이그레이션 {#step-6-migrate-projects-into-gitlab}

파일 내보내기를 사용하여 다른 시스템 또는 GitLab 인스턴스에서 GitLab으로 프로젝트를 마이그레이션하세요.

자주 액세스되는 리포지토리를 GitLab으로 마이그레이션할 때 프로젝트 별칭을 사용하여 원래 이름으로 계속 액세스할 수 있습니다.

GitLab.com에서는 프로젝트를 한 네임스페이스에서 다른 네임스페이스로 전송할 수 있습니다. 전송은 기본적으로 프로젝트를 다른 그룹으로 이동하여 멤버가 액세스 권한이나 소유권을 가질 수 있게 합니다.

자세한 정보는 다음을 참조하세요:

- [GitLab으로 가져오기 및 마이그레이션](../import/_index.md)
- [프로젝트 별칭](../project/working_with_projects.md#project-aliases)
- [프로젝트를 다른 네임스페이스로 전송](../project/working_with_projects.md#transfer-a-project)
