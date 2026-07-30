---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: Diffblue Cover GitLab 연동을 구성하는 방법 - GitLab용 Cover 파이프라인
title: Diffblue Cover
---

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

[Diffblue Cover](https://www.diffblue.com/) 강화 학습 AI 도구를 CI/CD 파이프라인에 통합하여 GitLab 프로젝트를 위한 Java 단위 테스트를 자동으로 작성하고 유지할 수 있습니다. GitLab용 Diffblue Cover 파이프라인 연동을 통해 다음을 자동으로 수행할 수 있습니다:

- 프로젝트의 기본 단위 테스트 스위트를 작성합니다.
- 새 코드에 대한 새로운 단위 테스트를 작성합니다.
- 코드의 기존 단위 테스트를 업데이트합니다.
- 더 이상 필요하지 않은 경우 코드의 기존 단위 테스트를 제거합니다.

![GitLab용 Cover 파이프라인 기본 MR 프로세스](img/diffblue_cover_workflow_after_v16_8.png)

## 연동 구성 {#configure-the-integration}

Diffblue Cover를 파이프라인에 통합하려면 다음을 수행하세요:

1. Diffblue Cover 연동을 찾아서 구성합니다.
1. GitLab 파이프라인 편집기와 Diffblue Cover 파이프라인 템플릿을 사용하여 샘플 프로젝트의 파이프라인을 구성합니다.
1. 프로젝트의 전체 기본 단위 테스트 스위트를 생성합니다.

### Diffblue Cover 구성 {#configure-diffblue-cover}

1. 상단 바에서 **검색 또는 이동**을 선택하고 프로젝트를 찾습니다.
   - 샘플 프로젝트로 연동을 테스트하려면 [import](../user/import/third_party_systems/repo_by_url.md) Diffblue [Spring PetClinic 샘플 프로젝트](https://github.com/diffblue/demo-spring-petclinic)를 수행할 수 있습니다.
1. **설정** > **연동**을 선택합니다.
1. **Diffblue Cover**를 찾아서 **구성**을 선택합니다.
1. 필드를 완성합니다:

   - **활성** 확인란을 선택합니다.
   - 환영 이메일이나 조직에서 제공한 Diffblue Cover **라이선스 키**를 입력합니다. 필요한 경우 [**Diffblue Cover를 사용해 보세요**](https://www.diffblue.com/try-cover/gitlab/) 링크를 선택하여 무료 평가판에 가입하세요.
   - Diffblue Cover가 프로젝트에 액세스할 수 있도록 GitLab 액세스 토큰(**이름** 및 **비밀**)의 세부 정보를 입력합니다. 일반적으로 [프로젝트 액세스 토큰](../user/project/settings/project_access_tokens.md)을 `Developer` 역할과 `api` 및 `write_repository` 범위와 함께 사용합니다. 필요한 경우 [그룹 액세스 토큰](../user/group/settings/group_access_tokens.md) 또는 [개인 액세스 토큰](../user/profile/personal_access_tokens.md)을 사용할 수 있으며, `Developer` 역할과 `api` 및 `write_repository` 범위를 함께 사용합니다.

     > [!note]
     > 과도한 권한이 있는 액세스 토큰을 사용하는 것은 보안 위험입니다. 개인 액세스 토큰을 사용하는 경우 프로젝트에만 액세스할 수 있도록 제한된 전용 사용자를 만들고, 토큰이 유출될 경우의 영향을 최소화하는 것을 검토합니다.

1. **변경 사항 저장**을 선택합니다. 이제 Diffblue Cover 연동이 <mark style="color:green;">**활성**</mark>이며 프로젝트에서 사용할 준비가 되어 있습니다.

### 파이프라인 구성 {#configure-a-pipeline}

머지 리퀘스트 파이프라인을 생성하여 프로젝트의 최신 버전의 Diffblue Cover를 다운로드하고, 프로젝트를 빌드하고, 프로젝트에 대한 Java 단위 테스트를 작성하고, 변경 사항을 브랜치에 커밋합니다.

1. 상단 바에서 **검색 또는 이동**을 선택하고 프로젝트를 찾습니다.
1. [`Diffblue-Cover.gitlab-ci.yml` 템플릿](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Diffblue-Cover.gitlab-ci.yml)의 콘텐츠를 프로젝트의 `.gitlab-ci.yml` 파일에 복사합니다.

   > [!note]
   > 자신의 프로젝트 및 기존 파이프라인 파일과 함께 Diffblue Cover 파이프라인 템플릿을 사용할 때는 Diffblue 템플릿 콘텐츠를 파일에 추가하고 필요에 따라 수정합니다. 자세한 내용은 Diffblue 설명서에서 [GitLab용 Cover 파이프라인](https://docs.diffblue.com/features/cover-pipeline/cover-pipeline-for-gitlab)을 참조하세요.
1. 커밋 메시지를 입력합니다.
1. 새로운 **브랜치** 이름을 입력합니다. 예를 들어, `add-diffblue-cover-pipeline`입니다.
1. **Start a new merge request with these changes**을 선택합니다.
1. **변경 사항 커밋**을 선택합니다.

### 기본 단위 테스트 스위트 생성 {#create-a-baseline-unit-test-suite}

1. **새 머지 리퀘스트** 양식에서 **제목**(예: "Cover 파이프라인 추가 및 기본 단위 테스트 스위트 생성")을 입력하고 다른 필드를 작성합니다.
1. **머지 리퀘스트 생성**을 선택합니다. 머지 리퀘스트 파이프라인이 Diffblue Cover를 실행하여 프로젝트의 기본 단위 테스트 스위트를 생성합니다.
1. 파이프라인이 완료되면 **변경사항** 탭에서 변경 사항을 검토할 수 있습니다. 만족하면 업데이트를 리포지토리에 병합합니다. 프로젝트 리포지토리의 `src/test` 폴더로 이동하여 Diffblue Cover에서 생성한 단위 테스트를 확인합니다(`*DiffblueTest.java`로 접미사가 붙음).

## 후속 코드 변경 {#subsequent-code-changes}

프로젝트에 대한 후속 코드 변경을 수행할 때 머지 리퀘스트 파이프라인은 Diffblue Cover를 실행하지만 관련 테스트만 업데이트합니다. 결과 diff를 분석하여 새로운 동작을 확인하고, 재발을 파악하고, 코드의 계획되지 않은 동작 변경을 발견할 수 있습니다.

![머지 리퀘스트 diff는 코드 변경 사항을 보여주며, 테스트 추가는 녹색으로, 제거는 빨간색으로 표시됩니다.](img/diffblue_cover_diff_v16_8.png)

## 다음 단계 {#next-steps}

이 주제는 GitLab용 Cover 파이프라인의 주요 기능 중 일부와 파이프라인에서 연동을 사용하는 방법을 보여줍니다. 파이프라인 템플릿의 `dcover` 명령을 통해 제공되는 더 광범위하고 심화된 기능을 구현하여 단위 테스트 기능을 더욱 확장할 수 있습니다. 자세한 내용은 Diffblue 설명서에서 [GitLab용 Cover 파이프라인](https://docs.diffblue.com/features/cover-pipeline/cover-pipeline-for-gitlab)을 참조하세요.
