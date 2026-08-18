---
stage: Verify
group: Runner Core
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: GitLab CI/CD를 사용하여 GitLab에서 제공하는 Docker 이미지와 CloudFormation 템플릿을 사용해 AWS(ECS 및 EC2 포함)에 애플리케이션을 배포합니다.
title: GitLab CI/CD에서 AWS로 배포
---

{{< details >}}

- 계층: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

GitLab은 AWS에 배포하는 데 필요한 라이브러리와 도구가 포함된 Docker 이미지를 제공합니다. 이 이미지를 CI/CD 파이프라인에서 참조할 수 있습니다.

GitLab.com을 사용 중이고 [Amazon Elastic Container Service](https://aws.amazon.com/ecs/)(ECS)에 배포하는 경우 [ECS에 배포](ecs/deploy_to_aws_ecs.md)하기에 대해 읽어보세요.

> [!note]
> 배포를 직접 구성하는 것에 익숙하고 AWS 자격 증명을 검색하기만 하면 되는 경우 [ID 토큰 및 OpenID Connect](../cloud_services/aws/_index.md) 사용을 고려하세요. ID 토큰은 CI/CD 변수에 자격 증명을 저장하는 것보다 더 안전하지만 이 페이지의 지침과 함께 작동하지 않습니다.

## GitLab으로 AWS 인증 {#authenticate-gitlab-with-aws}

GitLab CI/CD를 사용하여 AWS에 연결하려면 인증해야 합니다. 인증을 설정한 후 CI/CD를 배포하도록 구성할 수 있습니다.

1. AWS 계정에 로그인하세요.
1. [IAM 사용자](https://console.aws.amazon.com/iam/home#/home)를 생성하세요.
1. 사용자를 선택하여 세부 정보에 액세스하세요. **Security credentials** > **Create a new access key**로 이동하세요.
1. **Access key ID**와 **Secret access key**를 기록해 두세요.
1. GitLab 프로젝트에서 **설정** > **CI/CD**로 이동하세요. 다음 [CI/CD 변수](../variables/_index.md)를 설정하세요:

   | 환경 변수 이름 | 값 |
   |:--------------------------|:------|
   | `AWS_ACCESS_KEY_ID`       | 액세스 키 ID입니다. |
   | `AWS_SECRET_ACCESS_KEY`   | 비밀 액세스 키입니다. |
   | `AWS_DEFAULT_REGION`      | 리전 코드입니다. 사용하려는 AWS 서비스가 [선택한 리전에서 사용 가능한지](https://aws.amazon.com/about-aws/global-infrastructure/regional-product-services/) 확인하는 것이 좋습니다. |

1. 변수는 [기본적으로 보호됩니다](../variables/_index.md#protect-a-cicd-variable). 보호되지 않은 브랜치 또는 태그와 함께 GitLab CI/CD를 사용하려면 **보호 변수** 확인란을 선택 해제하세요.

## AWS 명령을 실행하기 위해 이미지 사용 {#use-an-image-to-run-aws-commands}

이미지에 [AWS Command Line Interface](https://aws.amazon.com/cli/)가 포함되어 있으면 프로젝트의 `.gitlab-ci.yml` 파일에서 이미지를 참조할 수 있습니다. 그러면 CI/CD 작업에서 `aws` 명령을 실행할 수 있습니다.

예를 들어:

```yaml
deploy:
  stage: deploy
  image: registry.gitlab.com/gitlab-org/cloud-deploy/aws-base:latest
  script:
    - aws s3 ...
    - aws create-deployment ...
  environment: production
```

GitLab은 AWS CLI를 포함하는 Docker 이미지를 제공합니다:

- 이미지는 GitLab 컨테이너 레지스트리에서 호스팅됩니다. 최신 이미지는 `registry.gitlab.com/gitlab-org/cloud-deploy/aws-base:latest`입니다.
- [이미지는 GitLab 리포지토리에 저장됩니다](https://gitlab.com/gitlab-org/cloud-deploy/-/tree/master/aws).

또는 [Amazon Elastic Container Registry(ECR)](https://aws.amazon.com/ecr/) 이미지를 사용할 수 있습니다. [이미지를 ECR 리포지토리에 푸시하는 방법을 알아보세요](https://docs.aws.amazon.com/AmazonECR/latest/userguide/docker-push-ecr-image.html).

타사 리포지토리의 이미지를 사용할 수도 있습니다.

## 애플리케이션을 ECS에 배포 {#deploy-your-application-to-ecs}

애플리케이션을 [Amazon ECS](https://aws.amazon.com/ecs/) 클러스터에 배포하는 것을 자동화할 수 있습니다.

전제 조건:

- [AWS로 GitLab 인증](#authenticate-gitlab-with-aws)하세요.
- Amazon ECS에서 클러스터를 생성하세요.
- ECS 서비스 또는 Amazon RDS의 데이터베이스와 같은 관련 컴포넌트를 생성하세요.
- `containerDefinitions[].name` 속성의 값이 타겟 ECS 서비스에서 정의된 `Container name`와 동일한 ECS 작업 정의를 생성하세요. 작업 정의는 다음과 같을 수 있습니다:
  - ECS의 기존 작업 정의입니다.
  - GitLab 프로젝트의 JSON 파일입니다. [AWS 설명서의 템플릿](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/create-task-definition.html#task-definition-template)을 사용하고 프로젝트에 파일을 저장하세요. 예를 들어 `<project-root>/ci/aws/task-definition.json`입니다.

ECS 클러스터에 배포하려면 다음을 수행하세요:

1. GitLab 프로젝트에서 **설정** > **CI/CD**로 이동하세요. 다음 [CI/CD 변수](../variables/_index.md)를 설정하세요. [Amazon ECS 대시보드](https://console.aws.amazon.com/ecs/home)에서 대상 클러스터를 선택하여 이 이름들을 찾을 수 있습니다.

   | 환경 변수 이름         | 값 |
   |:----------------------------------|:------|
   | `CI_AWS_ECS_CLUSTER`              | 배포를 위해 대상으로 하는 AWS ECS 클러스터의 이름입니다. |
   | `CI_AWS_ECS_SERVICE`              | AWS ECS 클러스터에 연결된 대상 서비스의 이름입니다. 이 변수가 적절한 환경(`production`, `staging`, `review/*`)으로 범위가 지정되어 있는지 확인하세요. |
   | `CI_AWS_ECS_TASK_DEFINITION`      | 작업 정의가 ECS에 있으면 서비스에 연결된 작업 정의의 이름입니다. |
   | `CI_AWS_ECS_TASK_DEFINITION_FILE` | 작업 정의가 GitLab의 JSON 파일이면 경로를 포함한 파일 이름입니다. 예를 들어, `ci/aws/my_task_definition.json`입니다. JSON 파일의 작업 정의 이름이 ECS의 기존 작업 정의와 동일한 이름이면 CI/CD가 실행될 때 새 개정이 생성됩니다. 그렇지 않으면 개정 1부터 시작하는 완전히 새로운 작업 정의가 생성됩니다. |

   > [!warning]
   > `CI_AWS_ECS_TASK_DEFINITION_FILE`와 `CI_AWS_ECS_TASK_DEFINITION`를 모두 정의하면 `CI_AWS_ECS_TASK_DEFINITION_FILE`가 우선합니다.

1. 이 템플릿을 `.gitlab-ci.yml`에 포함하세요:

   ```yaml
   include:
     - template: AWS/Deploy-ECS.gitlab-ci.yml
   ```

   `AWS/Deploy-ECS` 템플릿은 GitLab과 함께 제공되며 [GitLab.com](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/AWS/Deploy-ECS.gitlab-ci.yml)에서 사용할 수 있습니다.

1. 업데이트된 `.gitlab-ci.yml`를 프로젝트 리포지토리에 커밋하고 푸시하세요.

애플리케이션 Docker 이미지가 다시 빌드되고 GitLab 컨테이너 레지스트리로 푸시됩니다. 이미지가 비공개 레지스트리에 있으면 작업 정의가 [`repositoryCredentials` 속성으로 구성되어 있는지 확인하세요](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/private-auth.html).

대상 작업 정의가 새 Docker 이미지의 위치로 업데이트되고 결과적으로 ECS에서 새 개정이 생성됩니다.

마지막으로 AWS ECS 서비스가 작업 정의의 새 개정으로 업데이트되어 클러스터가 애플리케이션의 최신 버전을 끌어옵니다.

ECS 배포 작업은 롤아웃이 완료될 때까지 기다린 후 종료합니다. 이 동작을 비활성화하려면 `CI_AWS_ECS_WAIT_FOR_ROLLOUT_COMPLETE_DISABLED`을 비어 있지 않은 값으로 설정하세요.

> [!warning]
> [`AWS/Deploy-ECS.gitlab-ci.yml`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/AWS/Deploy-ECS.gitlab-ci.yml) 템플릿에는 [`Jobs/Build.gitlab-ci.yml`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Jobs/Build.gitlab-ci.yml)과 [`Jobs/Deploy/ECS.gitlab-ci.yml`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Jobs/Deploy/ECS.gitlab-ci.yml)의 두 템플릿이 포함되어 있습니다. 이 템플릿을 단독으로 포함하지 마세요. `AWS/Deploy-ECS.gitlab-ci.yml` 템플릿만 포함하세요. 이 다른 템플릿은 주 템플릿과만 함께 사용되도록 설계되었습니다. 예기치 않게 이동하거나 변경될 수 있습니다. 또한 이 템플릿의 작업 이름이 변경될 수 있습니다. 자신의 파이프라인에서 이 작업 이름을 재정의하지 마세요. 이름이 변경되면 재정의가 작동을 중단하기 때문입니다.

## 애플리케이션을 EC2에 배포 {#deploy-your-application-to-ec2}

GitLab은 `AWS/CF-Provision-and-Deploy-EC2`이라는 템플릿을 제공하여 Amazon EC2에 배포하는 것을 지원합니다.

관련 JSON 객체를 구성하고 템플릿을 사용하면 파이프라인이 다음을 수행합니다:

1. **Creates the stack**: 인프라는 [AWS CloudFormation](https://aws.amazon.com/cloudformation/) API를 사용하여 프로비저닝됩니다.
1. **Pushes to an S3 bucket**: 빌드가 실행되면 아티팩트가 생성됩니다. 아티팩트가 [AWS S3](https://aws.amazon.com/s3/) 버킷으로 푸시됩니다.
1. **Deploys to EC2**: 콘텐츠가 [AWS EC2](https://aws.amazon.com/ec2/) 인스턴스에 배포되며, 이 다이어그램에 표시되어 있습니다:

![CF-Provision-and-Deploy-EC2 파이프라인, 인프라 프로비저닝, S3에 아티팩트 푸시, EC2에 배포하는 단계를 포함합니다.](img/cf_ec2_diagram_v13_5.png)

### 템플릿 및 JSON 구성 {#configure-the-template-and-json}

EC2에 배포하려면 다음 단계를 완료하세요.

1. 스택의 JSON을 생성하세요. [AWS 템플릿](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/template-anatomy.html)을 사용하세요.
1. S3에 푸시할 JSON을 생성하세요. 다음 세부 정보를 포함하세요.

   ```json
   {
     "applicationName": "string",
     "source": "string",
     "s3Location": "s3://your/bucket/project_built_file...]"
   }
   ```

   `source`은 `build` 작업이 애플리케이션을 빌드한 위치입니다. 빌드는 [`artifacts:paths`](../yaml/_index.md#artifactspaths)에 저장됩니다.

1. EC2에 배포할 JSON을 생성하세요. [AWS 템플릿](https://docs.aws.amazon.com/codedeploy/latest/APIReference/API_CreateDeployment.html)을 사용하세요.
1. JSON 객체를 파이프라인에 액세스할 수 있도록 만드세요:
   - 이 JSON 객체를 리포지토리에 저장하려면 객체를 3개의 별도 파일로 저장하세요.

     `.gitlab-ci.yml` 파일에서 [CI/CD 변수](../variables/_index.md)를 추가하여 프로젝트 루트에 상대적인 파일 경로를 가리킵니다. 예를 들어, JSON 파일이 `<project_root>/aws` 폴더에 있으면:

     ```yaml
     variables:
       CI_AWS_CF_CREATE_STACK_FILE: 'aws/cf_create_stack.json'
       CI_AWS_S3_PUSH_FILE: 'aws/s3_push.json'
       CI_AWS_EC2_DEPLOYMENT_FILE: 'aws/create_deployment.json'
     ```

   - 이 JSON 객체를 리포지토리에 저장하지 않으려면 각 객체를 프로젝트 설정의 별도 [파일 유형 CI/CD 변수](../variables/_index.md#use-file-type-cicd-variables)로 추가하세요. 이전의 동일한 변수 이름을 사용하세요.

1. `.gitlab-ci.yml` 파일에서 스택 이름의 CI/CD 변수를 생성하세요. 예를 들어:

   ```yaml
   variables:
     CI_AWS_CF_STACK_NAME: 'YourStackName'
   ```

1. `.gitlab-ci.yml` 파일에서 CI 템플릿을 추가하세요:

   ```yaml
   include:
     - template: AWS/CF-Provision-and-Deploy-EC2.gitlab-ci.yml
   ```

1. 파이프라인을 실행하세요.

   - AWS CloudFormation 스택이 `CI_AWS_CF_CREATE_STACK_FILE` 변수의 콘텐츠를 기반으로 생성됩니다. 스택이 이미 있으면 이 단계는 건너뛰지만 해당 작업 `provision`은 여전히 실행됩니다.
   - 빌드된 애플리케이션이 S3 버킷으로 푸시된 다음 관련 JSON 객체의 콘텐츠를 기반으로 EC2 인스턴스에 배포됩니다. 배포 작업은 EC2로의 배포가 완료되거나 실패했을 때 종료됩니다.

## 문제 해결 {#troubleshooting}

### 오류 `'ascii' codec can't encode character '\uxxxx'` {#error-ascii-codec-cant-encode-character-uxxxx}

이 오류는 Cloud Deploy 이미지에서 사용하는 `aws-cli` 유틸리티의 응답에 유니코드 문자가 포함되어 있을 때 발생할 수 있습니다. Cloud Deploy 이미지는 정의된 로케일이 없으며 ASCII 사용으로 기본 설정됩니다. 이 오류를 해결하려면 다음 CI/CD 변수를 추가하세요:

```yaml
variables:
  LANG: "UTF-8"
```
