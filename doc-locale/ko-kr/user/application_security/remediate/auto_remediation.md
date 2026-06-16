---
stage: Application Security Testing
group: Composition Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 자동 수정
description: 취약한 종속성을 수정하기 위해 자동으로 머지 리퀘스트를 열습니다.
---

{{< details >}}

- 계층:  Ultimate
- 제공:  GitLab.com, GitLab Self-Managed, GitLab Dedicated
- 상태:  실험

{{< /details >}}

{{< history >}}

- [GitLab 19.0에 도입](https://gitlab.com/groups/gitlab-org/-/work_items/17403)되었으며 `dependency_management_auto_remediation` 이름의 [기능 플래그](../../../administration/feature_flags/_index.md) 를 사용하는 [실험](../../../policy/development_stages_support.md#experiment)입니다. 기본적으로 비활성화됨.

{{< /history >}}

자동 수정은 비취약 버전을 사용할 수 있을 때 취약성이 있는 종속성을 비취약 버전으로 업그레이드하는 머지 리퀘스트를 자동으로 열어줍니다. 서비스 계정이 인간의 입력 없이 머지 리퀘스트를 생성하고, 이후 표준 검토 및 승인 프로세스를 거칩니다.

베타 로드맵 및 계획된 개선 사항에 대해서는 [에픽 18236](https://gitlab.com/groups/gitlab-org/-/work_items/18236)을 참조하세요.

## 자동 수정 켜기 {#turn-on-auto-remediation}

전제 조건:

- 프로젝트의 Maintainer 이상의 역할이 최소 1명 필요합니다.
- `dependency_management_auto_remediation` [기능 플래그](../../../administration/feature_flags/_index.md)를 활성화해야 합니다.
- [종속성 검사](../dependency_scanning/_index.md)를 활성화하고 결과를 생성해야 합니다.
- 프로젝트는 [지원되는 패키지 관리자](#supported-package-managers)를 사용해야 합니다.

취약성 탐지 및 자동 수정을 트리거하려면 파이프라인을 실행합니다. 자동 수정은 사용 가능한 수정 사항이 있는 취약성이 탐지되면 자동으로 트리거됩니다.

## 자동 수정이 작동하는 방식 {#how-auto-remediation-works}

각 파이프라인 후 GitLab은 알려진 수정 버전이 있는 취약성에 대해 종속성 검사 결과를 확인합니다. 각 적격 취약성에 대해:

1. GitLab은 가장 가까운 하위 호환 업그레이드 경로(패치 또는 마이너 버전 업그레이드)를 결정합니다.
1. 서비스 계정이 관련 매니페스트 파일을 업데이트하는 머지 리퀘스트를 열어줍니다.
1. 머지 리퀘스트는 프로젝트의 표준 승인 워크플로우를 거칩니다.

실험 단계에서 GitLab은 최고 심각도 발견부터 시작하여 한 번에 3개의 취약성을 처리합니다.

## 지원되는 패키지 관리자 {#supported-package-managers}

자동 수정은 다음 패키지 관리자를 지원합니다:

| 언어 | 패키지 관리자 | 파일                     |
| -------- | --------------- | ------------------------- |
| Ruby     | Bundler         | `Gemfile`, `Gemfile.lock` |

추가 생태계에 대한 지원이 계획 중입니다. 자세한 내용은 [에픽 21643](https://gitlab.com/groups/gitlab-org/-/work_items/21643)을 참조하세요.

## 알려진 이슈 {#known-issues}

실험 단계에서:

- 머지 리퀘스트 열기 제한:  프로젝트당 최대 3개의 자동 수정 머지 리퀘스트를 열 수 있습니다. 기존 머지 리퀘스트가 병합되거나 종료될 때까지 새 머지 리퀘스트는 생성되지 않습니다.
- 버전 업그레이드 범위:  패치 및 마이너 버전 업그레이드만 제안됩니다. 주요 버전 업그레이드(주요 변경 사항을 야기할 수 있음)는 시도되지 않습니다.
- 파이프라인 실행당 1개 취약성:  각 파이프라인 실행은 사용 가능한 수정 사항이 있는 단일 취약성을 대상으로 합니다. 여러 수정 사항을 1개 머지 리퀘스트로 일괄 처리하는 것은 베타 버전에서 계획 중입니다.
- 사용 가능한 수정 사항 없음:  취약성에 대해 하위 호환 수정 버전이 없으면 해당 발견을 위해 머지 리퀘스트가 생성되지 않습니다.
