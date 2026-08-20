---
stage: Solutions Architecture
group: Solutions Architecture
info: This page is owned by the Solutions Architecture team.
title: 통합 변경 관리 - ServiceNow
---

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- ServiceNow 버전: 최신 버전, Xanadu 및 이전 버전과의 하위 호환성

{{< /details >}}

이 문서는 ServiceNow DevOps Change Velocity를 사용하여 통합된 ServiceNow 솔루션으로 변경 관리를 조율하기 위한 GitLab의 지침 및 기능 세부 정보를 제공합니다.

ServiceNow DevOps Change Velocity 통합을 사용하면 GitLab 리포지토리 및 CI/CD 파이프라인의 활동 정보를 ServiceNow에서 추적할 수 있습니다.

GitLab CI/CD 파이프라인과 통합될 때 변경 요청 생성을 자동화하고 정책 기준에 따라 변경 요청을 자동으로 승인합니다.

이 문서에서는 다음 방법을 보여줍니다

1. 변경 관리를 위해 Change Velocity를 사용하여 ServiceNow를 GitLab과 통합합니다.
1. GitLab CI/CD 파이프라인에서 자동으로 ServiceNow에 변경 요청을 생성합니다.
1. CAB 검토 및 승인이 필요한 경우 ServiceNow에서 변경 요청을 승인합니다.
1. 변경 요청 승인에 따라 프로덕션 배포를 시작합니다.

## 시작하기 {#getting-started}

### 솔루션 구성 요소 다운로드 {#download-the-solution-component}

1. 계정 팀으로부터 초대 코드를 입수합니다.
1. 초대 코드를 사용하여 [솔루션 구성 요소 웹스토어](https://cloud.gitlab-accelerator-marketplace.com)에서 솔루션 구성 요소를 다운로드합니다.

## 변경 관리를 위한 통합 옵션 {#integration-options-for-change-management}

GitLab을 ServiceNow와 통합하는 여러 가지 방법이 있습니다. 이 솔루션 컴포넌트에서는 다음 옵션을 제공합니다:

1. 기본 제공 변경 요청 프로세스를 위한 ServiceNow DevOps Change Velocity
1. Velocity 컨테이너 이미지를 사용한 사용자 지정 변경 요청을 포함한 ServiceNow DevOps Change Velocity
1. 사용자 지정 변경 요청 프로세스를 위한 ServiceNow REST API

## ServiceNow DevOps Change Velocity {#servicenow-devops-change-velocity}

ServiceNow 스토어에서 DevOps Change Velocity를 설치 및 구성한 후 DevOps Change Workspace에서 직접 자동화된 변경 생성을 통해 변경 제어를 활성화합니다.

### 기본 제공 변경 요청 프로세스 {#built-in-change-request-process}

ServiceNow DevOps Change Velocity는 일반 변경 프로세스를 위한 기본 제공 변경 요청 모델을 제공하며, 자동으로 생성된 변경 요청에는 기본 명명 규칙이 있습니다.

정상적인 변경 프로세스에서는 배포 파이프라인 작업을 프로덕션에 배포하기 전에 변경 요청이 승인되어야 합니다.

#### 파이프라인 및 변경 요청 작업 설정 {#setup-the-pipeline-and-change-request-jobs}

시작 지점으로 솔루션 리포지토리의 `gitlab-ci-workflow1.yml` 샘플 파이프라인을 사용합니다. 자동 변경 생성을 활성화하고 파이프라인을 통해 변경 속성을 전달하는 단계는 아래를 확인하세요.

> [!note]
> 더 자세한 지침은 [DevOps 변경 요청 생성 자동화](https://www.servicenow.com/docs/bundle/yokohama-it-service-management/page/product/enterprise-dev-ops/task/automate-devops-change-request.html)를 참조하세요.

다음은 상위 수준의 단계입니다:

1. DevOps Change Workspace에서 변경 탭으로 이동한 다음 변경 자동화를 선택합니다.

   ![변경 자동화 옵션이 선택된 DevOps Change Workspace입니다.](img/snow_automate_cr_creation_v17_9.png)
1. 응용 프로그램 필드에서 파이프라인과 연결하려는 응용 프로그램을 선택하여 변경 요청 생성을 자동화하려는 응용 프로그램을 선택한 다음 다음을 선택합니다.
1. 변경 요청 자동 생성을 트리거하려는 파이프라인 단계(스테이지)가 있는 파이프라인을 선택합니다. 예를 들어 변경 요청 생성 파이프라인 단계입니다.
1. 변경 요청 자동 생성을 트리거하려는 파이프라인의 단계를 선택합니다.
1. 변경 필드에서 변경 속성을 지정하고 변경 영수증 옵션을 선택하여 변경 영수증을 활성화합니다.
1. 파이프라인을 수정하고 해당 코드 스니펫을 사용하여 변경 제어를 활성화하고 변경 속성을 지정합니다. 예를 들어 변경 제어가 활성화된 작업에 다음 두 가지 구성을 추가합니다:

   ```yaml
      when: manual
      allow_failure: false
   ```

   ![변경 제어를 지원하도록 업데이트된 GitLab CI/CD 파이프라인 작업입니다.](img/snow_automated_cr_pipeline_update_v17_9.png)

#### 변경 관리를 사용하여 파이프라인 실행 {#run-pipeline-with-change-management}

이전 단계를 완료한 후 프로젝트 CD 파이프라인은 `gitlab-ci-workflow1.yml` 샘플 파이프라인에 표시된 작업을 통합할 수 있습니다.

변경 관리를 사용하여 파이프라인을 실행하려면:

1. ServiceNow에서 파이프라인의 스테이지 중 하나에 대해 변경 제어를 활성화합니다.

   ![파이프라인에서 변경 제어가 활성화된 ServiceNow 스테이지입니다.](img/snow_change_control_enabled_v17_9.png)
1. GitLab에서 변경 제어 기능이 있는 파이프라인 작업이 실행됩니다.

   ![변경 승인을 위해 일시 중지된 GitLab 파이프라인입니다.](img/snow_pipeline_pause_for_approval_v17_9.png)
1. ServiceNow에서 변경 요청이 ServiceNow에 자동으로 생성됩니다.

   ![승인 대기 중인 ServiceNow 변경 요청입니다.](img/snow_cr_waiting_for_approval_v17_9.png)
1. ServiceNow에서 변경 요청을 승인합니다

   ![승인됨으로 표시된 ServiceNow 변경 요청입니다.](img/snow_cr_approved_v17_9.png)
1. 파이프라인이 재개되고 변경 요청 승인 시 프로덕션 환경에 배포하기 위한 다음 작업을 시작합니다.

   ![변경 승인 후 재개된 GitLab 파이프라인입니다.](img/snow_pipeline_resumes_v17_9.png)

### Velocity 컨테이너 이미지를 사용한 사용자 지정 작업 {#custom-actions-with-velocity-container-image}

DevOps Change Velocity Docker 이미지를 통해 ServiceNow 사용자 지정 작업을 사용하여 변경 요청 제목, 설명, 변경 계획, 롤백 계획, 배포할 아티팩트와 관련된 데이터 및 패키지 등록을 설정합니다. 이렇게 하면 파이프라인 메타데이터를 변경 요청 설명으로 전달하는 대신 변경 요청 설명을 사용자 지정할 수 있습니다.

#### 파이프라인 및 변경 요청 작업 설정 {#setup-the-pipeline-and-change-request-jobs-1}

이는 ServiceNow DevOps Change Velocity의 추가 기능이므로 이전 설정 단계는 동일합니다. 파이프라인 정의에 Docker 이미지를 포함하기만 하면 됩니다.

이 리포지토리의 `gitlab-ci-workflow2.yml` 샘플 파이프라인을 예로 사용합니다.

1. 작업에서 사용할 이미지를 지정합니다. 필요에 따라 이미지 버전을 업데이트합니다.

   ```yaml
      image: servicenowdocker/sndevops:5.0.0
   ```

1. 특정 작업에 CLI를 사용합니다. 예를 들어 sndevops CLI를 사용하여 변경 요청을 생성합니다

   ```yaml
   sndevopscli create change -p {
        "changeStepDetails": {
          "timeout": 3600,
          "interval": 100
        },
        "autoCloseChange": true,
        "attributes": {
          "short_description": "'"${CHANGE_REQUEST_SHORT_DESCRIPTION}"'",
          "description": "'"${CHANGE_REQUEST_DESCRIPTION}"'",
          "assignment_group": "'"${ASSIGNMENT_GROUP_ID}"'",
          "implementation_plan": "'"${CR_IMPLEMENTATION_PLAN}"'",
          "backout_plan": "'"${CR_BACKOUT_PLAN}"'",
          "test_plan": "'"${CR_TEST_PLAN}"'"
        }
      }

   ```

#### 사용자 지정 변경 관리를 사용하여 파이프라인 실행 {#run-pipeline-with-custom-change-management}

시작 지점으로 `gitlab-ci-workflow2.yml` 샘플 파이프라인을 사용합니다. 이전 단계를 완료한 후 프로젝트 CD 파이프라인은 `gitlab-ci-workflow2.yml` 샘플 파이프라인에 표시된 작업을 통합할 수 있습니다.

사용자 지정 변경 관리를 사용하여 파이프라인을 실행하려면:

1. ServiceNow에서 파이프라인의 스테이지 중 하나에 대해 변경 제어를 활성화합니다.

   ![사용자 지정 변경 흐름을 사용하여 파이프라인에서 변경 제어를 활성화한 ServiceNow 스테이지입니다.](img/snow_change_control_enabled_v17_9.png)
1. GitLab에서 변경 제어 기능이 있는 파이프라인 작업이 실행됩니다.

   ![변경 요청 생성 workflow2](img/snow_cr_creation_workflow2_v17_9.png)
1. ServiceNow에서 `servicenowdocker/sndevops` 이미지를 사용하여 파이프라인 변수 값으로 제공된 사용자 지정 제목, 설명 및 기타 필드가 포함된 변경 요청을 생성합니다.

   ![파이프라인의 사용자 지정 값으로 생성된 ServiceNow 변경 요청입니다.](img/snow_pipeline_workflow2_v17_9.png)
1. GitLab에서 변경 요청 번호 및 기타 정보는 파이프라인 세부 정보에서 찾을 수 있습니다. 파이프라인 작업은 변경 요청이 승인될 때까지 계속 실행된 후 다음 작업으로 진행합니다.

   ![승인 workflow2 후 파이프라인 변경 세부 정보](img/snow_pipeline_details_workflow2_v17_9.png)
1. ServiceNow에서 변경 요청을 승인합니다.

   ![파이프라인 세부 정보 workflow2](img/snow_pipeline_cr_details_workflow2_v17_9.png)
1. GitLab에서 파이프라인 작업이 재개되고 변경 요청 승인 시 프로덕션 환경에 배포하는 다음 작업을 시작합니다.

   ![파이프라인 resumes workflow2](img/snow_pipeline_resumes_workflow2_v17_9.png)
