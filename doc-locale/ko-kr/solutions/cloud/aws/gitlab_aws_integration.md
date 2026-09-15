---
stage: Solutions Architecture
group: Solutions Architecture
info: This page is owned by the Solutions Architecture team.
description: GitLab과 AWS 통합 솔루션 인덱스
title: AWS와 통합
---

GitLab과 AWS를 통합하는 방법을 알아봅니다.

이 내용은 GitLab 팀 구성원과 더 넓은 커뮤니티 구성원을 위해 작성되었습니다.

달리 명시되지 않은 경우, 모든 내용은 GitLab.com과 GitLab Self-Managed 인스턴스 모두에 적용됩니다.

GitLab은 일반 구성, 두 플랫폼의 기본 제공 기능 및 전용 솔루션을 통해 AWS와 통합됩니다.

| 텍스트 태그                 | 구성 / 기본 제공 / 솔루션                             | 지원/유지 관리                                          |
| ------------------------ | ------------------------------------------------------------ | ------------------------------------------------------------ |
| `[AWS Configuration]`    | 기존 AWS 기능 구성을 통한 통합       | AWS                                                          |
| `[GitLab Configuration]` | 기존 GitLab 기능 구성을 통한 통합    | GitLab                                                       |
| `[AWS Built]`            | AWS 통합을 위해 제품 팀에서 AWS에 기본 제공됨    | AWS                                                          |
| `[GitLab Built]`         | AWS 통합을 위해 제품 팀에서 GitLab에 기본 제공됨 | GitLab                                                       |
| `[AWS Solution]`         | AWS 또는 AWS 파트너가 솔루션 예로 구축             | 커뮤니티/예                                            |
| `[GitLab Solution]`      | GitLab 또는 GitLab 파트너가 솔루션 예로 구축       | 커뮤니티/예                                            |
| `[CI Solution]`          | GitLab CI를 사용하여 적어도 부분적으로 구축되었으므로 <br />고객이 더 많이 사용자 지정할 수 있습니다. | `[CI Solution]`로 태그된 항목은 <br />다른 태그 중 하나도 함께 표시됩니다. <br />유지 관리 상태를 나타냅니다. |

## 개발 활동을 위한 통합 {#integrations-for-development-activities}

이러한 통합은 GitLab을 사용하여 애플리케이션 워크로드를 구축하고 이를 AWS에 배포하는 것과 관련이 있습니다.

### SCM 통합 {#scm-integrations}

#### AWS CodeStar Connection 통합 {#aws-codestar-connection-integrations}

[GitLab.com용 2023년 8월 14일 AWS 릴리스 공지](https://aws.amazon.com/about-aws/whats-new/2023/08/aws-codepipeline-supports-gitlab/)

[Self-Managed / Dedicated용 2023년 12월 28일 AWS 릴리스 공지](https://aws.amazon.com/about-aws/whats-new/2023/12/codepipeline-gitlab-self-managed/)

**AWS CodeStar Connections** \- 여러 AWS 서비스에 대한 SCM 연결을 활성화합니다. [GitLab 구성](https://docs.aws.amazon.com/dtconsole/latest/userguide/connections-create-gitlab.html)합니다. [지원되는 공급자](https://docs.aws.amazon.com/dtconsole/latest/userguide/supported-versions-connections.html)입니다. [지원되는 AWS 서비스](https://docs.aws.amazon.com/dtconsole/latest/userguide/integrations-connections.html) \- 각각이 GitLab을 지원하도록 업데이트해야 할 수 있으므로 GitLab을 지원하는 하위 집합이 있습니다. 이는 GitLab.com, GitLab Self-Managed 및 GitLab Dedicated와 함께 작동합니다. AWS CodeStar 연결은 모든 AWS 리전에서 사용할 수 없습니다. 제외 목록은 [여기에 설명되어](https://docs.aws.amazon.com/codepipeline/latest/userguide/action-reference-CodestarConnectionSource.html) 있습니다. ([2023년 12월 28일](https://aws.amazon.com/about-aws/whats-new/2023/12/codepipeline-gitlab-self-managed/)) `[AWS Built]`

[AWS CodeStar Connection 통합 설명 비디오(1분)](https://youtu.be/f7qTSa_bNig)

AWS 계정에서 CodeStar Connection으로 직접 지원되는 AWS 서비스:

- **AWS Service Catalog**는 CodeStar Connections를 직접 상속하며, 계정에서 생성된 GitLab CodeStar Connection을 사용하기만 하므로 GitLab에 대한 특정 설명서가 없습니다. ([2023년 12월 28일](https://aws.amazon.com/about-aws/whats-new/2023/12/codepipeline-gitlab-self-managed/)) `[AWS Built]`
- **AWS Proton**은 CodeStar Connections를 직접 상속하며, 계정에서 생성된 GitLab CodeStar Connection을 사용하기만 하므로 GitLab에 대한 특정 설명서가 없습니다. ([2023년 12월 28일](https://aws.amazon.com/about-aws/whats-new/2023/12/codepipeline-gitlab-self-managed/)) `[AWS Built]`
- **AWS CodeBuild** - [GitLab.com, self-managed 및 dedicated를 위해 여기에서 설명서 탭을 클릭](https://docs.aws.amazon.com/codebuild/latest/userguide/create-project-console.html#create-project-console-source)합니다. ([2024년 3월 26일](https://aws.amazon.com/about-aws/whats-new/2024/03/aws-codebuild-gitlab-gitlab-self-managed/)) `[AWS Built]`

설명서 및 참고 자료:

- [GitLab.com 프로젝트에 대한 GitLab CodeStar Connection 생성](https://docs.aws.amazon.com/codepipeline/latest/userguide/connections-gitlab-managed.html)
- [GitLab Self-Managed 또는 GitLab Dedicated용 AWS CodeStar Connection 생성](https://docs.aws.amazon.com/codepipeline/latest/userguide/connections-gitlab-managed.html) (AWS에서 인터넷 수신을 허용하거나 VPC 연결을 사용해야 함)

#### AWS CodePipeline 통합 {#aws-codepipeline-integrations}

[AWS CodePipeline 통합](https://docs.aws.amazon.com/codepipeline/latest/userguide/connections-gitlab.html) \- CodePipeline의 CodeStar Connections 소스로 GitLab을 사용하면 추가 AWS 서비스 통합을 사용할 수 있습니다. ([2023년 12월 28일](https://aws.amazon.com/about-aws/whats-new/2023/12/codepipeline-gitlab-self-managed/)) `[AWS Built]`

AWS CodePipeline 통합으로 지원되는 AWS 서비스:

- **Amazon SageMaker MLOps Projects**는 CodePipeline을 통해 생성되며 ([여기에 설명되어](https://docs.aws.amazon.com/sagemaker/latest/dg/sagemaker-projects-walkthrough-3rdgit.html#sagemaker-proejcts-walkthrough-connect-3rdgit) 있음), 계정에서 생성된 GitLab CodeStar Connection을 사용하기만 하므로 GitLab에 대한 특정 설명서가 없습니다. ([2023년 12월 28일](https://aws.amazon.com/about-aws/whats-new/2023/12/codepipeline-gitlab-self-managed/)) `[AWS Built]`

설명서 및 참고 자료:

- [GitLab.com 프로젝트에 대한 GitLab CodePipeline 통합 생성](https://docs.aws.amazon.com/codepipeline/latest/userguide/connections-gitlab-managed.html)
- [GitLab Self-Managed 또는 GitLab Dedicated용 AWS CodePipeline 통합 생성](https://docs.aws.amazon.com/codepipeline/latest/userguide/connections-gitlab-managed.html) (AWS에서 인터넷 수신을 허용하거나 VPC 연결을 사용해야 함)

#### GitLab에 아직 지원되지 않는 CodeStar Connection 활성화된 AWS 서비스 {#codestar-connections-enabled-aws-services-that-are-not-yet-supported-for-gitlab}

- **AWS CloudFormation** 공개 확장 게시 - 아직 지원되지 않습니다. `[AWS Built]`
- **Amazon CodeGuru Reviewer Repositories** \- 아직 지원되지 않습니다. `[AWS Built]`
- **AWS App Runner** \- 아직 지원되지 않습니다. `[AWS Built]`

#### AWS 서비스에서 사용자 지정 GitLab 통합 {#custom-gitlab-integration-in-aws-services}

- **Amazon SageMaker Notebooks** [Git 클론 URL로 Git 리포지토리를 지정할 수 있습니다](https://docs.aws.amazon.com/sagemaker/latest/dg/nbi-git-resource.html) 그리고 비밀 구성 - GitLab을 구성할 수 있습니다. ([2023년 12월 28일](https://aws.amazon.com/about-aws/whats-new/2023/12/codepipeline-gitlab-self-managed/)) `[AWS Configuration]`
- **AWS Amplify** - [AWS Amplify 팀이 설계한 Git 통합 메커니즘을 사용](https://docs.aws.amazon.com/amplify/latest/userguide/getting-started.html)합니다. `[AWS Built]`
- **AWS Glue Notebook Jobs**는 "작업" 수준에서 개인 액세스 토큰(PAT) 인증을 통해 GitLab 리포지토리 URL을 지원합니다. ([2022년 10월 3일](https://aws.amazon.com/about-aws/whats-new/2022/10/aws-glue-git-integration/)) [GitLab 구성에 관한 AWS 문서](https://docs.aws.amazon.com/glue/latest/dg/edit-job-add-source-control-integration.html) `[AWS Configuration]`

#### 기타 SCM 통합 옵션 {#other-scm-integration-options}

- [GitLab Push Mirroring to CodeCommit](../../../user/project/repository/mirror/push.md#set-up-a-push-mirror-from-gitlab-to-aws-codecommit) 해결 방법은 GitLab 리포지토리가 CodePipeline SCM 트리거를 활용할 수 있게 합니다. GitLab은 이미 CodePipeline을 위해 S3 및 Container 트리거를 활용할 수 있습니다. 이 해결 방법은 문서화되었으므로 CodePipeline 기능을 활성화했습니다. (2020년 6월 6일) `[GitLab Configuration]`

아래의 [CD 및 운영 통합](#cd-and-operations-integrations)을 참고하여 사용 가능한 지속적 배포(CD) 특정 통합을 확인합니다.

### CI 통합 {#ci-integrations}

- **Direct CI Integrations That Use Keys, IAM or OIDC/JWT to Authenticate to AWS Services from GitLab Runners**
- **Amazon CodeGuru Reviewer CI workflows using GitLab CI** \- 수행할 수 있지만 아직 문서화되지 않았습니다.`[AWS Solution]` `[CI Solution]`
- [GitLab CI를 사용한 Amazon CodeGuru 보안 스캐닝](https://docs.aws.amazon.com/codeguru/latest/security-ug/get-started-gitlab.html) ([2022년 6월 13일](https://aws.amazon.com/about-aws/whats-new/2023/06/amazon-codeguru-security-available-preview/)) `[AWS Solution]` `[CI Solution]`

### CD 및 운영 통합 {#cd-and-operations-integrations}

- **AWS CodeDeploy Integration** \- SCM 통합에서 이전에 논의한 CodePipeline 지원을 통해 제공됩니다. 이 기능을 통해 GitLab은 [AWS의 고급 배포 하위 시스템 목록](https://docs.aws.amazon.com/codepipeline/latest/userguide/integrations-action-type.html#integrations-deploy)과 인터페이스할 수 있습니다. ([2023년 12월 28일](https://aws.amazon.com/about-aws/whats-new/2023/12/codepipeline-gitlab-self-managed/)) `[AWS Built]`
- **AWS SAM Pipelines** - [GitLab을 위한 파이프라인 지원](https://aws.amazon.com/about-aws/whats-new/2021/07/simplify-ci-cd-configuration-serverless-applications-your-favorite-ci-cd-system-public-preview/)입니다. (2021년 7월 31일)
- [애플리케이션 배포를 위한 EKS 클러스터 통합](../../../user/infrastructure/clusters/connect/new_eks_cluster.md)입니다. `[GitLab Built]`
- [GitLab이 빌드 아티팩트를 CodePipeline 모니터링 S3 위치로 푸시](https://docs.aws.amazon.com/codepipeline/latest/userguide/pipelines-about-starting.html#change-detection-methods) `[AWS Built]`
- [GitLab이 컨테이너를 CodePipeline 모니터링 AWS ECR로 푸시](https://docs.aws.amazon.com/codepipeline/latest/userguide/pipelines-about-starting.html#change-detection-methods) `[AWS Built]`
- [GitLab.com의 컨테이너 레지스트리를 Pull-Through Cache 규칙을 통해 AWS ECR의 업스트림 레지스트리로 사용](https://docs.aws.amazon.com/AmazonECR/latest/userguide/pull-through-cache-creating-rule.html) [구성 튜토리얼](tutorials/aws_ecr_pull_through_cache.md) `[AWS Built]`

## 특정 개발 프레임워크 또는 에코시스템의 개발 및 배포를 위한 엔드투엔드 솔루션 {#end-to-end-solutions-for-development-and-deployment-of-specific-development-frameworks-or-ecosystems}

일반적으로 솔루션은 개발 프레임워크를 위한 엔드투엔드 기능을 시연하며, 모든 관련 통합 기술을 활용하여 GitLab과 AWS를 함께 사용하기 위한 최대 가치의 기술을 보여줍니다.

### 서버리스 {#serverless}

- [엔터프라이즈 DevOps Blueprint: AWS의 서버리스 프레임워크 앱](https://gitlab.com/guided-explorations/aws/serverless/serverless-framework-aws) \- 작동하는 예제 코드 및 튜토리얼입니다. `[GitLab Solution]` `[CI Solution]`
  - [튜토리얼: GitLab 서버리스 SAST 스캐닝을 사용한 AWS의 서버리스 프레임워크 배포](https://gitlab.com/guided-explorations/aws/serverless/serverless-framework-aws/-/blob/master/TUTORIAL.md) `[GitLab Solution]` `[CI Solution]`
  - [튜토리얼: GitLab 보안 정책 승인 규칙 및 Managed DevOps 환경을 사용한 보안 서버리스 프레임워크 개발](https://gitlab.com/guided-explorations/aws/serverless/serverless-framework-aws/-/blob/prod/TUTORIAL2-SecurityAndManagedEnvs.md?ref_type=heads) `[GitLab Solution]` `[CI Solution]`

### Terraform {#terraform}

- [엔터프라이즈 DevOps Blueprint: AWS로의 Terraform 배포](https://gitlab.com/guided-explorations/aws/terraform/terraform-web-server-cluster)
  - [튜토리얼: GitLab IaC SAST 스캐닝을 사용한 AWS로의 Terraform 배포](https://gitlab.com/guided-explorations/aws/terraform/terraform-web-server-cluster/-/blob/prod/TUTORIAL.md) `[GitLab Solution]` `[CI Solution]`
  - [GitLab 보안 정책 승인 규칙 및 Managed DevOps 환경을 사용한 AWS로의 Terraform 배포](https://gitlab.com/guided-explorations/aws/terraform/terraform-web-server-cluster/-/blob/prod/TUTORIAL2-SecurityAndManagedEnvs.md) `[GitLab Solution]` `[CI Solution]`

### CloudFormation {#cloudformation}

[CloudFormation 개발 및 GitLab Lifecycle Managed DevOps 환경으로의 배포 작동 코드](https://gitlab.com/guided-explorations/aws/cloudformation-deploy) `[GitLab Solution]` `[CI Solution]`

### CDK {#cdk}

- [AWS CDK를 사용하여 GitLab 파이프라인에서 교차 계정 배포 구축](https://aws.amazon.com/blogs/apn/building-cross-account-deployment-in-gitlab-pipelines-using-aws-cdk/) `[AWS Solution]` `[CI Solution]`

### AWS의 .NET {#net-on-aws}

- [AWS에서 .NET Framework 4.x 러너 확장을 위한 작동하는 예제 코드](https://gitlab.com/guided-explorations/aws/dotnet-aws-toolkit) `[GitLab Solution]` `[CI Solution]`
- [코드 및 .NET Framework 4.x 프로젝트 빌드의 비디오 연습](https://www.youtube.com/watch?v=_4r79ZLmDuo) `[GitLab Solution]` `[CI Solution]`

## GitLab과 AWS의 시스템 간 통합 {#system-to-system-integration-of-gitlab-and-aws}

AWS Identity 공급자(IDP)를 GitLab에 인증하도록 구성하거나 GitLab이 AWS 계정으로 IDP 역할을 할 수 있습니다.

GitLab.com의 최상위 그룹은 "Namespaces"로도 알려져 있으며, 회사 이름을 따라 명명하는 것이 GitLab.com에서 조직을 위한 테넌트를 설정하는 첫 번째 단계입니다. 네임스페이스는 SSO와 같은 특수 기능으로 구성할 수 있으며, 이는 IDP를 GitLab에 통합합니다.

### GitLab과 AWS 간의 사용자 인증 및 권한 부여 {#user-authentication-and-authorization-between-gitlab-and-aws}

- [GitLab.com 그룹용 SAML SSO](../../../user/group/saml_sso/_index.md) `[GitLab Configuration]` - GitLab.com만
- [GitLab과 LDAP 통합](../../../administration/auth/ldap/_index.md) `[GitLab Configuration]` - GitLab Self-Managed만

### 러너 워크로드 인증 및 권한 부여 통합 {#runner-workload-authentication-and-authorization-integration}

- [Open ID & JWT 인증을 사용한 러너 작업 인증](../../../ci/cloud_services/aws/_index.md)입니다. `[GitLab Built]`
  - [GitLab과 AWS 간의 OpenID Connect 구성](https://gitlab.com/guided-explorations/aws/configure-openid-connect-in-aws) `[GitLab Solution]` `[CI Solution]`
  - [GitLab 및 ECS를 사용한 OIDC 및 다중 계정 배포](https://gitlab.com/guided-explorations/aws/oidc-and-multi-account-deployment-with-ecs) `[GitLab Solution]` `[CI Solution]`

## AWS에 배포된 GitLab 인프라 워크로드 {#gitlab-infrastructure-workloads-deployed-on-aws}

GitLab은 최대 500명의 사용자를 위해 단일 상자에 배포할 수 있지만, 50,000과 같은 매우 많은 사용자 수로 수평 확장되면 AWS에 배포하면 이점이 있는 복잡한 다층 플랫폼으로 확장됩니다. GitLab은 지원되며 AWS 서비스로 지원될 때 정기적으로 테스트됩니다. GitLab은 기존 확장을 위해 EC2로 배포할 수 있고 Cloud Native Hybrid 구현에서 AWS EKS로 배포할 수 있습니다. 특정 서비스 계층을 컨테이너 클러스터에 배치할 수 없기 때문에 Hybrid라고 불리며, Git에 공통적인 워크로드 형태 때문입니다(Git 프로세스가 해당 워크로드 다양성을 처리하는 방법에 공통적입니다).

### GitLab 인스턴스 컴퓨팅 & 운영 통합 {#gitlab-instance-compute--operations-integration}

- AWS에서 GitLab Self-Managed 설치
  - [GitLab을 배포할 때 사용할 수 있는 AWS 서비스](gitlab_instance_on_aws.md)
  - GitLab Single EC2 인스턴스입니다. `[GitLab Built]`
    - [5개 사용자 AWS 마켓플레이스 구독 사용](gitlab_single_box_on_aws.md#marketplace-subscription)
    - [준비된 AMI 사용](gitlab_single_box_on_aws.md#official-gitlab-releases-as-amis) \- Enterprise Edition의 경우 자신의 라이선스 가져오기입니다.
  - AWS EKS 및 Paas에서 Cloud Native Hybrid 확장 GitLab입니다. `[GitLab Built]`
    - [GitLab Environment Toolkit(GET) 사용](https://gitlab.com/gitlab-org/gitlab-environment-toolkit) - `[GitLab Solution]`
  - AWS EC2 및 PaaS에서 확장된 GitLab 인스턴스입니다. `[GitLab Built]`
    - [GitLab Environment Toolkit(GET) 사용](https://gitlab.com/gitlab-org/gitlab-environment-toolkit) - `[GitLab Solution]`
- [Amazon Managed Grafana](https://docs.aws.amazon.com/grafana/latest/userguide/gitlab-AMG-datasource.html) GitLab Self-Managed Prometheus 메트릭용입니다. `[AWS Built]`

### AWS 컴퓨팅에서 GitLab 러너 {#gitlab-runner-on-aws-compute}

- [GitLab 러너 자동 크기 조정](https://docs.gitlab.com/runner/runner_autoscale/) \- GitLab 러너 팀에서 구축한 핵심 기술입니다. `[GitLab Built]`
- [GitLab 러너 인프라 툴킷(GRIT)](https://gitlab.com/gitlab-org/ci-cd/runner-tools/grit) \- GitLab 러너 팀에서 관리하는 인프라 코드입니다. GitLab 러너 자동 크기 조정과 같은 것을 배포하는 데 필요합니다. `[GitLab Built]`
- [AWS EC2에서 GitLab 러너 자동 크기 조정](https://docs.gitlab.com/runner/configuration/runner_autoscale_aws/)입니다. `[GitLab Built]`
- [AWS EC2 ASG용 GitLab HA 확장 러너 벤딩 머신](https://gitlab.com/guided-explorations/aws/gitlab-runner-autoscaling-aws-asg/)입니다. `[GitLab Solution]`
  - 러너 벤딩 머신 교육 자료입니다.
- [GitLab EKS Fargate 러너](https://gitlab.com/guided-explorations/aws/eks-runner-configs/gitlab-runner-eks-fargate/-/blob/main/README.md)입니다. `[GitLab Solution]`
