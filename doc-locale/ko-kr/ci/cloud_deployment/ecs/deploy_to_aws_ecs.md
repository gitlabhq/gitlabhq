---
stage: Verify
group: Runner Core
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "GitLab 프로젝트를 Amazon ECS에 배포합니다. 애플리케이션을 컨테이너화하고 지속적 배포, 검토 앱 및 보안 테스트를 설정합니다."
title: Amazon Elastic Container Service에 배포
---

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

이 단계별 가이드는 GitLab.com에서 호스팅되는 프로젝트를 Amazon [Elastic Container Service (ECS)](https://aws.amazon.com/ecs/)에 배포하는 데 도움이 됩니다.

이 가이드에서는 AWS 콘솔을 사용하여 ECS 클러스터를 수동으로 생성하여 시작합니다. GitLab 템플릿에서 생성한 간단한 애플리케이션을 생성하고 배포합니다.

이 지침은 GitLab.com 및 GitLab Self-Managed 인스턴스 모두에서 작동합니다. 자신의 [러너가 구성되어 있는지](../../runners/_index.md) 확인합니다.

## 전제 조건 {#prerequisites}

- [AWS 계정](https://repost.aws/knowledge-center/create-and-activate-aws-account)입니다. 기존 AWS 계정으로 로그인하거나 새 계정을 생성합니다.
- 이 가이드에서는 [`us-east-2` 리전](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/using-regions-availability-zones.html)에 인프라를 생성합니다. 모든 리전을 사용할 수 있지만, 시작한 후에는 변경하지 않습니다.

## AWS에서 인프라 생성 및 초기 배포 {#create-an-infrastructure-and-initial-deployment-on-aws}

GitLab에서 애플리케이션을 배포하려면 먼저 AWS에서 인프라 및 초기 배포를 생성해야 합니다. 여기에는 [ECS 클러스터](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/clusters.html) 및 [ECS 작업 정의](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task_definitions.html), [ECS 서비스](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/ecs_services.html), 컨테이너화된 애플리케이션 이미지와 같은 관련 구성 요소가 포함됩니다.

첫 번째 단계에서는 프로젝트 템플릿에서 데모 애플리케이션을 생성합니다.

### 템플릿에서 새 프로젝트 생성 {#create-a-new-project-from-a-template}

GitLab 프로젝트 템플릿을 사용하여 시작합니다. 이름에서 알 수 있듯이 이러한 프로젝트는 잘 알려진 프레임워크에 구축된 기본 애플리케이션을 제공합니다.

1. 오른쪽 상단 모서리에서 **새로 만들기** ({{< icon name="plus" >}}) 및 **새 프로젝트/리포지토리**를 선택합니다.
1. **템플릿으로 부터 생성**을 선택합니다. Ruby on Rails, Spring 또는 NodeJS Express 프로젝트 중에서 선택할 수 있습니다. 이 가이드의 경우 Ruby on Rails 템플릿을 사용합니다.
1. 프로젝트에 이름을 지정합니다. 이 예제에서는 `ecs-demo`로 명명됩니다. 공개로 설정하여 [GitLab Ultimate](https://about.gitlab.com/pricing/) 플랜에서 사용 가능한 기능을 활용할 수 있습니다.
1. **프로젝트 생성**을 선택합니다.

이제 데모 프로젝트를 만들었으므로 애플리케이션을 컨테이너화하고 컨테이너 레지스트리로 푸시해야 합니다.

### 컨테이너화된 애플리케이션 이미지를 GitLab 컨테이너 레지스트리로 푸시 {#push-a-containerized-application-image-to-gitlab-container-registry}

[ECS](https://aws.amazon.com/ecs/)는 컨테이너 오케스트레이션 서비스이므로 인프라 빌드 중에 컨테이너화된 애플리케이션 이미지를 제공해야 합니다. 이를 위해 GitLab [Auto Build](../../../topics/autodevops/stages.md#auto-build) 및 [컨테이너 레지스트리](../../../user/packages/container_registry/_index.md)를 사용할 수 있습니다.

1. 상단 표시줄에서 **검색 또는 이동**을 선택하고 `ecs-demo` 프로젝트를 찾습니다.
1. **CI/CD 설정**을 선택합니다. `.gitlab-ci.yml` 생성 양식으로 이동합니다.
1. 다음 콘텐츠를 빈 `.gitlab-ci.yml`에 복사하여 붙여넣습니다. 이는 ECS로의 지속적 배포를 위한 파이프라인을 정의합니다.

   ```yaml
   include:
     - template: AWS/Deploy-ECS.gitlab-ci.yml
   ```

1. **Commit Changes**을 선택합니다. 자동으로 새로운 파이프라인이 트리거됩니다. 이 파이프라인에서 `build` 작업은 애플리케이션을 컨테이너화하고 이미지를 [GitLab 컨테이너 레지스트리](../../../user/packages/container_registry/_index.md)로 푸시합니다.

1. **배포** > **컨테이너 레지스트리**를 방문합니다. 애플리케이션 이미지가 푸시되었는지 확인합니다.

   ![GitLab 컨테이너 레지스트리의 컨테이너화된 애플리케이션 이미지입니다.](img/registry_v13_10.png)

이제 AWS에서 가져올 수 있는 컨테이너화된 애플리케이션 이미지가 있습니다. 다음으로 이 애플리케이션 이미지가 AWS에서 어떻게 사용되는지에 대한 사양을 정의합니다.

`production_ecs` 작업은 ECS 클러스터가 아직 연결되지 않아서 실패합니다. 이는 나중에 수정할 수 있습니다.

### ECS 작업 정의 생성 {#create-an-ecs-task-definition}

[ECS 작업 정의](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task_definitions.html)는 애플리케이션 이미지가 [ECS 서비스](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/ecs_services.html)에 의해 시작되는 방식에 대한 사양입니다.

1. **ECS** > **Task Definitions** > [AWS 콘솔](https://aws.amazon.com/)로 이동합니다.
1. **Create new Task Definition**을 선택합니다.

   !['새 작업 정의 생성' 버튼이 있는 작업 정의 페이지입니다.](img/ecs-task-definitions_v13_10.png)

1. 시작 유형으로 **EC2**를 선택합니다. **Next Step**를 선택합니다.
1. `ecs_demo`을 **Task Definition Name**으로 설정합니다.
1. `512`을 **Task Size** > **Task memory** 및 **Task CPU**로 설정합니다.
1. **Container Definitions** > **Add container**를 선택합니다. 컨테이너 등록 양식이 열립니다.
1. `web`을 **Container name**으로 설정합니다.
1. `registry.gitlab.com/<your-namespace>/ecs-demo/master:latest`을 **이미지**로 설정합니다. 또는 [GitLab 컨테이너 레지스트리 페이지](#push-a-containerized-application-image-to-gitlab-container-registry)에서 이미지 경로를 복사하여 붙여넣을 수 있습니다.

   ![컨테이너 이름 및 이미지 필드가 완료되었습니다.](img/container-name_v13_10.png)

1. 포트 매핑을 추가합니다. `80`을 **Host Port**로 설정하고 `5000`을 **Container port**로 설정합니다.

   ![포트 매핑 필드가 완료되었습니다.](img/container-port-mapping_v13_10.png)

1. **생성**을 선택합니다.

이제 초기 작업 정의가 있습니다. 다음으로 애플리케이션 이미지를 실행할 실제 인프라를 생성합니다.

### ECS 클러스터 생성 {#create-an-ecs-cluster}

[ECS 클러스터](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/clusters.html)는 [ECS 서비스](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/ecs_services.html)의 가상 그룹입니다. 또한 EC2 또는 Fargate와 계산 리소스로도 연결됩니다.

1. **ECS** > **Clusters** > [AWS 콘솔](https://aws.amazon.com/)로 이동합니다.
1. **Create Cluster**을 선택합니다.
1. 클러스터 템플릿으로 **EC2 Linux + Networking**을 선택합니다. **Next Step**를 선택합니다.
1. `ecs-demo`을 **Cluster Name**으로 설정합니다.
1. **Networking**에서 기본 [VPC](https://aws.amazon.com/vpc/?vpc-blogs.sort-by=item.additionalFields.createdDate&vpc-blogs.sort-order=desc)를 선택합니다. 기존 VPC가 없으면 그대로 두고 새로 만들 수 있습니다.
1. VPC의 모든 사용 가능한 서브넷을 **Subnets**으로 설정합니다.
1. **생성**을 선택합니다.
1. ECS 클러스터가 성공적으로 생성되었는지 확인합니다.

   ![ECS 클러스터가 성공적으로 생성되었으며 모든 인스턴스가 실행 중입니다.](img/ecs-launch-status_v13_10.png)

이제 다음 단계에서 ECS 서비스를 ECS 클러스터에 등록할 수 있습니다.

다음을 참고하세요:

- 선택적으로 생성 양식에서 SSH 키 쌍을 설정할 수 있습니다. 이를 통해 디버깅을 위해 EC2 인스턴스로 SSH할 수 있습니다.
- 기존 VPC를 선택하지 않으면 기본적으로 새 VPC를 만듭니다. 계정에서 인터넷 게이트웨이의 최대 허용 수에 도달하면 오류가 발생할 수 있습니다.
- 클러스터에는 EC2 인스턴스가 필요하므로 [인스턴스 유형에 따라](https://aws.amazon.com/ec2/pricing/on-demand/) 비용이 발생합니다.

### ECS 서비스 생성 {#create-an-ecs-service}

[ECS 서비스](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/ecs_services.html)는 [ECS 작업 정의](#create-an-ecs-task-definition)를 기반으로 애플리케이션 컨테이너를 생성하는 데몬입니다.

1. **ECS** > **Clusters** > **ecs-demo** > **서비스** > [AWS 콘솔](https://aws.amazon.com/)로 이동합니다.
1. **배포**를 선택합니다. 서비스 생성 양식이 열립니다.
1. **Launch Type**에서 `EC2`를 선택합니다.
1. `ecs_demo`을 **Task definition**로 설정합니다. 이는 [이전에 생성한 작업 정의](#create-an-ecs-task-definition)에 해당합니다.
1. `ecs_demo`을 **서비스 이름**으로 설정합니다.
1. `1`을 **Desired tasks**으로 설정합니다.

   ![모든 입력이 완료된 서비스 페이지입니다.](img/service-parameter_v13_10.png)

1. **배포**를 선택합니다.
1. 생성된 서비스가 활성 상태인지 확인합니다.

   ![작업과 함께 실행 중인 활성 서비스입니다.](img/service-running_v13_10.png)

AWS 콘솔 UI는 시간이 지남에 따라 변경됩니다. 지침에서 관련 구성 요소를 찾을 수 없으면 가장 가까운 것을 선택합니다.

### 데모 애플리케이션 보기 {#view-the-demo-application}

이제 데모 애플리케이션은 인터넷에서 액세스할 수 있습니다.

1. **EC2** > **인스턴스** > [AWS 콘솔](https://aws.amazon.com/)로 이동합니다.
1. `ECS Instance`로 검색하여 [ECS 클러스터에서 만든](#create-an-ecs-cluster) 해당 EC2 인스턴스를 찾습니다.
1. EC2 인스턴스의 ID를 선택합니다. 인스턴스 세부 정보 페이지로 이동합니다.
1. **Public IPv4 address**를 복사하여 브라우저에 붙여넣습니다. 이제 실행 중인 데모 애플리케이션을 볼 수 있습니다.

   ![브라우저에서 실행 중인 데모 애플리케이션입니다.](img/view-running-app_v13_10.png)

이 가이드에서는 HTTPS/SSL이 구성되어 있지 않습니다. HTTP를 통해서만 애플리케이션에 액세스할 수 있습니다 (예: `http://<ec2-ipv4-address>`).

## GitLab에서 지속적 배포 설정 {#set-up-continuous-deployment-from-gitlab}

이제 ECS에서 실행 중인 애플리케이션이 있으므로 GitLab에서 지속적 배포를 설정할 수 있습니다.

### 배포자로서 새로운 IAM 사용자 생성 {#create-a-new-iam-user-as-a-deployer}

GitLab에서 이전에 생성한 ECS 클러스터, 서비스 및 작업 정의에 액세스하려면 AWS에서 배포자 사용자를 생성해야 합니다:

1. **IAM** > **사용자** > [AWS 콘솔](https://aws.amazon.com/)로 이동합니다.
1. **사용자 추가**를 선택합니다.
1. `ecs_demo`을 **User name**으로 설정합니다.
1. **Programmatic access** 확인란을 활성화합니다. **다음: 권한**
1. **Set permissions**에서 `Attach existing policies directly`을 선택합니다.
1. 정책 목록에서 `AmazonECS_FullAccess`을 선택합니다. **다음: 태그** 및 **다음: 검토**

   ![`AmazonECS_FullAccess` 정책이 선택되었습니다.](img/ecs-policy_v13_10.png)

1. **사용자 생성**을 선택합니다.
1. 생성된 사용자의 **Access key ID** 및 **Secret access key**를 기록해 둡니다.

> [!note]
> 비밀 액세스 키를 공개 위치에서 공유하지 마세요. 안전한 장소에 저장해야 합니다.

### 파이프라인 작업이 ECS에 액세스할 수 있도록 GitLab에서 자격 증명 설정 {#setup-credentials-in-gitlab-to-let-pipeline-jobs-access-to-ecs}

[GitLab CI/CD 변수](../../variables/_index.md)에 액세스 정보를 등록할 수 있습니다. 이러한 변수는 파이프라인 작업에 주입되며 ECS API에 액세스할 수 있습니다.

1. 상단 표시줄에서 **검색 또는 이동**을 선택하고 `ecs-demo` 프로젝트를 찾습니다.
1. **설정** > **CI/CD** > **변수**로 이동합니다.
1. **Add Variable**를 선택하고 다음 키-값 쌍을 설정합니다.

   | 키                          | 값                                 | 참고 |
   |------------------------------|---------------------------------------|------|
   | `AWS_ACCESS_KEY_ID`          | `<Access key ID of the deployer>`     | `aws` CLI 인증을 위해. |
   | `AWS_SECRET_ACCESS_KEY`      | `<Secret access key of the deployer>` | `aws` CLI 인증을 위해. |
   | `AWS_DEFAULT_REGION`         | `us-east-2`                           | `aws` CLI 인증을 위해. |
   | `CI_AWS_ECS_CLUSTER`         | `ecs-demo`                            | ECS 클러스터는 `production_ecs` 작업에 의해 액세스됩니다. |
   | `CI_AWS_ECS_SERVICE`         | `ecs_demo`                            | 클러스터의 ECS 서비스는 `production_ecs` 작업에 의해 업데이트됩니다. 이 변수가 적절한 환경(`production`, `staging`, `review/*`)으로 범위지정되도록 합니다. |
   | `CI_AWS_ECS_TASK_DEFINITION` | `ecs_demo`                            | ECS 작업 정의는 `production_ecs` 작업에 의해 업데이트됩니다. |

### 데모 애플리케이션 변경 {#make-a-change-to-the-demo-application}

프로젝트의 파일을 변경하고 ECS의 데모 애플리케이션에 반영되는지 확인합니다:

1. 상단 표시줄에서 **검색 또는 이동**을 선택하고 `ecs-demo` 프로젝트를 찾습니다.
1. `app/views/welcome/index.html.erb` 파일을 엽니다.
1. **편집**을 선택합니다.
1. 텍스트를 `You're on ECS!`로 변경합니다.
1. **Commit Changes**을 선택합니다. 자동으로 새로운 파이프라인이 트리거됩니다. 완료될 때까지 기다립니다.
1. [ECS 클러스터에서 실행 중인 애플리케이션에 액세스](#view-the-demo-application)합니다. 다음을 확인해야 합니다:

   ![확인 메시지가 표시된 ECS에서 실행 중인 애플리케이션입니다.](img/view-running-app-2_v13_10.png)

축하합니다! ECS에 대한 지속적 배포를 성공적으로 설정했습니다.

> [!note]
> ECS 배포 작업은 롤아웃이 완료될 때까지 기다린 후 종료됩니다. 이 동작을 비활성화하려면 `CI_AWS_ECS_WAIT_FOR_ROLLOUT_COMPLETE_DISABLED`을 0이 아닌 값으로 설정합니다.

## 검토 앱 설정 {#set-up-review-apps}

ECS를 사용하여 검토 앱을 사용하려면:

1. 새로운 [서비스](#create-an-ecs-service)를 설정합니다.
1. `CI_AWS_ECS_SERVICE` 변수를 사용하여 이름을 설정합니다.
1. 환경 범위를 `review/*`로 설정합니다.

이 서비스가 모든 검토 앱에서 공유되므로 한 번에 하나의 검토 앱만 배포할 수 있습니다.

## 보안 테스트 설정 {#set-up-security-testing}

### SAST 구성 {#configure-sast}

ECS에서 [SAST](../../../user/application_security/sast/_index.md)를 사용하려면 `.gitlab-ci.yml` 파일에 다음을 추가합니다:

```yaml
include:
   - template: Jobs/SAST.gitlab-ci.yml
```

자세한 내용과 구성 옵션은 [SAST 설명서](../../../user/application_security/sast/_index.md#configuration)를 참조하세요.

### DAST 구성 {#configure-dast}

비기본 브랜치에서 [DAST](../../../user/application_security/dast/_index.md)를 사용하려면 [검토 앱을 설정](#set-up-review-apps)하고 `.gitlab-ci.yml` 파일에 다음을 추가합니다:

```yaml
include:
  - template: Security/DAST.gitlab-ci.yml
```

기본 브랜치에서 DAST를 사용하려면:

1. 새로운 [서비스](#create-an-ecs-service)를 설정합니다. 이 서비스는 임시 DAST 환경을 배포하는 데 사용됩니다.
1. `CI_AWS_ECS_SERVICE` 변수를 사용하여 이름을 설정합니다.
1. 범위를 `dast-default` 환경으로 설정합니다.
1. `.gitlab-ci.yml` 파일에 다음을 추가합니다:

```yaml
include:
  - template: Security/DAST.gitlab-ci.yml
  - template: Jobs/DAST-Default-Branch-Deploy.gitlab-ci.yml
```

자세한 내용과 구성 옵션은 [DAST 설명서](../../../user/application_security/dast/_index.md)를 참조하세요.

## 추가 읽기 {#further-reading}

- 클라우드로의 지속적 배포에 더 관심이 있으면 [클라우드 배포](../_index.md)를 참조하세요.
- 프로젝트에서 DevSecOps를 빠르게 설정하려면 [Auto DevOps](../../../topics/autodevops/_index.md)를 참조하세요.
- 프로덕션 등급 환경을 빠르게 설정하려면 [5분 프로덕션 앱](https://gitlab.com/gitlab-org/5-minute-production-app/deploy-template/-/blob/master/README.md)을 참조하세요.
