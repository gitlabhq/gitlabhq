---
stage: Create
group: Remote Development
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: Ona를 사용하여 GitLab 프로젝트용 사전 구축된 개발 환경을 구축하고 구성합니다.
title: Ona
---

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed

{{< /details >}}

[Ona](https://ona.com/)(이전의 Gitpod)를 사용하면 개발 환경을 코드로 설명하여 GitLab 프로젝트의 완전히 설정되고 컴파일되고 테스트된 개발 환경을 만들 수 있습니다. 개발 환경은 자동화될 뿐만 아니라 사전 구축되어 있으므로 Ona는 CI/CD 서버처럼 Git 브랜치를 지속적으로 구축합니다.

이는 종속성이 다운로드되기를 기다릴 필요가 없으며 빌드가 즉시 코딩을 시작할 수 있음을 의미합니다. Ona를 사용하면 브라우저에서 모든 프로젝트, 브랜치 및 머지 리퀘스트에서 즉시 코딩을 시작할 수 있습니다.

GitLab Ona 통합을 사용하려면 GitLab 인스턴스와 환경설정에서 활성화해야 합니다. 다음 사용자:

- GitLab.com은 [사용자 환경설정에서 활성화](#enable-ona-in-your-user-preferences)된 후 즉시 사용할 수 있습니다.
- GitLab Self-Managed 인스턴스는 다음 후에 사용할 수 있습니다:
  1. [GitLab 관리자가 활성화 및 구성](#configure-a-gitlab-self-managed-instance)합니다.
  1. [사용자 설정에서 활성화](#enable-ona-in-your-user-preferences)됩니다.

Ona에 대한 자세한 내용은 Ona [기능](https://ona.com/) 및 [설명서](https://ona.com/docs)를 참조하세요.

## 사용자 환경설정에서 Ona 활성화 {#enable-ona-in-your-user-preferences}

GitLab 인스턴스에 대해 Ona 통합이 활성화되면 자신을 위해 활성화하려면:

1. 오른쪽 위 모서리에서 아바타를 선택합니다.
1. **환경설정**을 선택합니다.
1. **환경설정**에서 **연동** 섹션을 찾습니다.
1. **Ona 통합 활성화** 확인란을 선택하고 **변경사항 저장**을 선택합니다.

## GitLab Self-Managed 인스턴스 구성 {#configure-a-gitlab-self-managed-instance}

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

GitLab Self-Managed의 경우 GitLab 관리자가 다음을 수행해야 합니다:

1. GitLab에서 Ona 통합을 활성화합니다:
   1. 오른쪽 위 모서리에서 **운영자**를 선택합니다.
   1. 왼쪽 사이드바에서 **설정** > **일반**을 선택합니다.
   1. **Ona** 구성 섹션을 확장합니다.
   1. **Ona 통합 활성화** 확인란을 선택합니다.
   1. Ona 인스턴스 URL을 입력합니다(예: `https://app.ona.com`).
   1. **변경 사항 저장**을 선택합니다.
1. Ona에서 인스턴스를 등록합니다. 자세한 내용은 [Ona 설명서](https://ona.com/docs/ona/source-control/gitlab)를 참조하세요.

GitLab 사용자는 [자신을 위해 Ona 통합을 활성화](#enable-ona-in-your-user-preferences)할 수 있습니다.

## GitLab에서 Ona 실행 {#launch-ona-in-gitlab}

[Ona를 활성화](#enable-ona-in-your-user-preferences)한 후 다음 방법 중 하나로 GitLab에서 실행할 수 있습니다:

- 프로젝트 리포지토리에서:
  1. 상단 바에서 **검색 또는 이동**을 선택하고 프로젝트를 찾습니다.
  1. 우측 상단에서 **코드** > **Ona**를 선택합니다.
- 머지 리퀘스트에서:
  1. 머지 리퀘스트로 이동합니다.
  1. 우측 상단 모서리에서 **코드** > **Ona에서 열기**를 선택합니다.

Ona는 브랜치의 개발 환경을 구축합니다.
