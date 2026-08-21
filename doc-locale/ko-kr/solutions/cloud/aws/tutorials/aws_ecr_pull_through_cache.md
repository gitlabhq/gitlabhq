---
stage: Solutions Architecture
group: Solutions Architecture
info: This page is owned by the Solutions Architecture team.
description: GitLab과 AWS 통합 솔루션 인덱스
title: '튜토리얼: GitLab.com 프로젝트에 대한 인증된 액세스를 위해 AWS ECR Pull Through Cache 규칙 구성'
---

1. <https://console.aws.amazon.com/ecr/>에서 Amazon ECR 콘솔을 엽니다.
1. 탐색 모음에서 프라이빗 레지스트리 설정을 구성할 Region을 선택합니다.
1. 탐색 창에서 Private registry, Pull through cache를 선택합니다.
1. Pull through cache 구성 페이지에서 Add rule을 선택합니다.

Step 1: 소스 지정 페이지에서 Registry에 대해 GitLab Container Registry를 선택한 다음 Next를 선택합니다.

Step 2: 인증 구성 페이지에서 Upstream credentials에 대해 GitLab 컨테이너 레지스트리의 인증 자격 증명을 AWS Secrets Manager secret에 저장해야 합니다. 기존 secret을 지정하거나 Amazon ECR 콘솔을 사용하여 새 secret을 만들 수 있습니다.

기존 secret을 사용하려면 Use an existing AWS secret를 선택합니다. Secret name의 경우 드롭다운을 사용하여 기존 secret을 선택한 다음 Next를 선택합니다. Secrets Manager 콘솔을 사용하여 Secrets Manager secret을 만드는 방법에 대한 자세한 내용은 Storing your upstream repository credentials in an AWS Secrets Manager secret을 참조하세요.

> [!note]
> AWS Management Console에서는 ecr-pullthroughcache/ 접두사를 사용하는 이름의 Secrets Manager secret만 표시합니다. secret은 pull through cache 규칙이 생성되는 동일한 계정과 Region에 있어야 합니다.

새 secret을 만들려면 Create an AWS secret를 선택한 후 다음 작업을 수행하고 Next를 선택합니다.

Secret name의 경우 secret에 대한 설명이 포함된 이름을 지정합니다. Secret 이름에는 1~512개의 유니코드 문자가 포함되어야 합니다.

GitLab 컨테이너 레지스트리 사용자 이름의 경우 GitLab 컨테이너 레지스트리 사용자 이름을 지정합니다.

GitLab 컨테이너 레지스트리 액세스 토큰의 경우 GitLab 컨테이너 레지스트리 액세스 토큰을 지정합니다. 최소 권한의 원칙을 따르려면 Guest 역할과 `read_registry` 범위만 포함된 Group Access Token을 만듭니다.

Step 3: 대상 지정 페이지에서 Amazon ECR 리포지토리 접두사의 경우 소스 공용 레지스트리에서 가져온 이미지를 캐싱할 때 사용할 리포지토리 네임스페이스를 지정한 다음 Next를 선택합니다.

기본적으로 네임스페이스가 채워지지만 사용자 지정 네임스페이스를 지정할 수도 있습니다.

Step 4: 검토 및 만들기 페이지에서 pull through cache 규칙 구성을 검토한 다음 Create를 선택합니다.

만들려는 각 pull through cache에 대해 이전 단계를 반복합니다. pull through cache 규칙은 각 Region에 대해 별도로 생성됩니다.

ECR Pull Through Cache 규칙이 성공적으로 생성되었는지 확인하려면 AWS CLI를 통해 다음 명령을 실행하여 규칙을 확인할 수 있습니다:

```shell
aws ecr validate-pull-through-cache-rule \
     --ecr-repository-prefix ecr-public \
     --region us-east-2
```

ECR Pull Through Cache 규칙이 GitLab.com 업스트림 레지스트리에 대한 pull-through 액세스를 제공하는지 확인하려면 `docker pull` 명령을 실행하여 확인할 수 있습니다:

```shell
docker pull aws_account_id.dkr.ecr.region.amazonaws.com/{destination-namespace e.g. gitlab-ef1b}/{path to Gitlab.com project/group where image is hosted}/image_name:tag
```

`docker pull` 명령 예시:

```shell
docker pull aws_account_id.dkr.ecr.region.amazonaws.com/gitlab-ef1b/guided-explorations/ci-components/working-code-examples/kaniko-component-multiarch-build:latest
```
