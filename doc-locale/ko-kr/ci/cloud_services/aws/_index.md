---
stage: Software Supply Chain Security
group: Pipeline Security
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: AWS에서 OpenID Connect를 구성하여 임시 자격증명 검색
---

{{< details >}}

- 계층: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

> [!warning]
> `CI_JOB_JWT_V2`는 [GitLab 15.9에서 사용 중단되었으며](../../../update/deprecations.md#old-versions-of-json-web-tokens-are-deprecated) GitLab 17.0에서 제거될 예정입니다. 대신 [ID 토큰](../../secrets/id_token_authentication.md)을 사용하세요.

이 튜토리얼에서는 JSON 웹 토큰(JWT)과 함께 GitLab CI/CD 작업을 사용하여 비밀을 저장하지 않고 AWS에서 임시 자격증명을 검색하는 방법을 보여줍니다. 이를 수행하려면 GitLab과 AWS 간의 ID 페더레이션을 위해 OpenID Connect(OIDC)를 구성해야 합니다. OIDC를 사용하여 GitLab을 통합하기 위한 배경 정보와 요구 사항은 [클라우드 서비스에 연결](../_index.md)을 참조하세요.

이 튜토리얼을 완료하려면:

1. [ID 공급자 추가](#add-the-identity-provider)
1. [역할 및 신뢰 구성](#configure-a-role-and-trust)
1. [임시 자격증명 검색](#retrieve-temporary-credentials)

## ID 공급자 추가 {#add-the-identity-provider}

다음 [지침](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_providers_create_oidc.html)에 따라 AWS에서 GitLab을 IAM OIDC 공급자로 생성합니다.

다음 정보를 포함합니다:

- **공급자 URL**: GitLab 인스턴스의 주소입니다. 예: `https://gitlab.com` 또는 `http://gitlab.example.com`. 이 주소는 공개적으로 접근 가능해야 합니다. 공개적으로 사용 가능하지 않은 경우 [비공개 GitLab 인스턴스 구성](#configure-a-non-public-gitlab-instance) 방법을 참조하세요.
- **오디언스**: 요청된 보안 토큰과 함께 사용할 대상 서비스의 논리적 이름입니다.
  - AWS OIDC 통합에서 이는 일반적으로 IAM OIDC ID 공급자에서 구성된 오디언스 값과 일치합니다(자주 `sts.amazonaws.com` 또는 GitLab 인스턴스 URL).
  - 이 값은 AWS에 의해 검증되어 토큰이 특정 ID 공급자를 위한 것임을 확인합니다.

  > [!note]
  > `https://gitlab.com` 또는 GitLab 인스턴스 URL을 사용하면 AWS ID 공급자 참조가 일치하는 경우 작동할 수 있지만 의미적으로 오도적입니다. 오디언스는 토큰을 검증하고 수락하는 서비스를 나타내야 합니다.

## 역할 및 신뢰 구성 {#configure-a-role-and-trust}

ID 공급자를 생성한 후 GitLab 리소스에 대한 액세스를 제한하기 위한 조건이 있는 [웹 ID 역할](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_create_for-idp_oidc.html)을 구성합니다. 임시 자격증명은 [AWS Security Token Service](https://docs.aws.amazon.com/STS/latest/APIReference/welcome.html)를 사용하여 얻어지므로 `Action`을 [`sts:AssumeRoleWithWebIdentity`](https://docs.aws.amazon.com/STS/latest/APIReference/API_AssumeRoleWithWebIdentity.html)로 설정합니다.

역할 및 태그에 대한 액세스를 제한하기 위해 특정 그룹, 프로젝트, 브랜치에 대한 [사용자 지정 신뢰 정책](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_create_for-custom.html)을 만들 수 있습니다. 지원되는 필터링 유형의 전체 목록은 [클라우드 서비스에 연결](../_index.md#configure-a-conditional-role-with-oidc-claims)을 참조하세요.

GitLab.com에서 AWS는 `gitlab.com` OIDC ID 공급자에 대한 추가 조건 키(예: `namespace_id` 및 `project_id`)를 지원합니다. 역할 신뢰 정책에 이러한 안정적이고 고유한 식별자에 대한 조건을 포함합니다. 이러한 식별자는 경로와 독립적이므로 이를 참조하는 신뢰 정책은 그룹 또는 프로젝트 이름 바꾸기와 같은 경로 변경에 영향을 받지 않습니다.

이러한 추가 조건 키는 `gitlab.com` OIDC ID 공급자에만 사용 가능합니다. GitLab Self-Managed 및 GitLab Dedicated의 경우 현재 `sub` 클레임만 AWS 조건 키로 지원됩니다. 해당 배포의 경우 `sub` 만 사용하여 신뢰 정책의 범위를 지정합니다(예: `gitlab.example.com:sub`).

`project_id`은 전역적으로 고유하며 그룹 이름 바꾸기, 프로젝트 이름 바꾸기 및 프로젝트 전송을 포함하여 프로젝트의 전체 수명 동안 동일하게 유지됩니다. `namespace_id`은 프로젝트가 현재 네임스페이스에 남아 있는 동안 안정적입니다. 프로젝트가 다른 네임스페이스로 전송되면 `namespace_id`이 변경되어 신뢰 정책을 의도적으로 무효화합니다.

프로젝트의 `namespace_id` 및 `project_id` 값을 찾으려면 프로젝트 설정 페이지 또는 [Projects API](../../../api/projects.md)를 참조하세요. 조건 키로 사용 가능한 클레임의 전체 목록은 [ID 토큰 페이로드](../../secrets/id_token_authentication.md#token-payload)를 참조하세요.

다음 예제 신뢰 정책은 `sub`, `namespace_id` 및 `project_id`을 함께 사용하여 GitLab.com의 특정 그룹, 프로젝트 및 브랜치에 신뢰를 고정합니다:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::AWS_ACCOUNT:oidc-provider/gitlab.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "gitlab.com:sub": "project_path:mygroup/myproject:ref_type:branch:ref:main",
          "gitlab.com:namespace_id": "12345",
          "gitlab.com:project_id": "67890"
        }
      }
    }
  ]
}
```

역할을 생성한 후 AWS 서비스(S3, EC2, Secrets Manager)에 권한을 정의하는 정책을 연결합니다.

## 임시 자격증명 검색 {#retrieve-temporary-credentials}

OIDC 및 역할을 구성한 후 GitLab CI/CD 작업은 [AWS Security Token Service(STS)](https://docs.aws.amazon.com/STS/latest/APIReference/welcome.html)에서 임시 자격증명을 검색할 수 있습니다.

```yaml
assume role:
  id_tokens:
    GITLAB_OIDC_TOKEN:
      aud: https://gitlab.example.com
  script:
    # this is split out for correct exit code handling
    - >
      aws_sts_output=$(aws sts assume-role-with-web-identity
      --role-arn ${ROLE_ARN}
      --role-session-name "GitLabRunner-${CI_PROJECT_ID}-${CI_PIPELINE_ID}"
      --web-identity-token ${GITLAB_OIDC_TOKEN}
      --duration-seconds 3600
      --query 'Credentials.[AccessKeyId,SecretAccessKey,SessionToken]'
      --output text)
    - export $(printf "AWS_ACCESS_KEY_ID=%s AWS_SECRET_ACCESS_KEY=%s AWS_SESSION_TOKEN=%s" $aws_sts_output)
    - aws sts get-caller-identity
```

- `ROLE_ARN`: 이 [단계](#configure-a-role-and-trust)에서 정의된 역할 ARN입니다.
- `GITLAB_OIDC_TOKEN`: OIDC [ID 토큰](../../secrets/id_token_authentication.md)입니다.

## 작업 예시 {#working-examples}

- Terraform을 사용하여 AWS에서 OIDC를 프로비저닝하고 임시 자격증명을 검색하기 위한 샘플 스크립트에 대해서는 이 [참조 프로젝트](https://gitlab.com/guided-explorations/aws/configure-openid-connect-in-aws)를 참조하세요.
- [GitLab 및 ECS를 사용한 OIDC 및 다중 계정 배포](https://gitlab.com/guided-explorations/aws/oidc-and-multi-account-deployment-with-ecs).
- AWS Partner(APN) Blog: [GitLab CI/CD를 사용한 OpenID Connect 설정](https://aws.amazon.com/blogs/apn/setting-up-openid-connect-with-gitlab-ci-cd-to-provide-secure-access-to-environments-in-aws-accounts/).
- [AWS re:Inforce 2023에서의 GitLab: OpenID 및 JWT를 사용한 AWS에 대한 보안 GitLab CD 파이프라인](https://www.youtube.com/watch?v=xWQGADDVn8g).

## 비공개 GitLab 인스턴스 구성 {#configure-a-non-public-gitlab-instance}

{{< details >}}

- 계층: Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed

{{< /details >}}

{{< history >}}

- GitLab 18.1에서 [도입됨](https://gitlab.com/gitlab-org/gitlab/-/issues/391928)

{{< /history >}}

> [!warning]
> 이 해결 방법은 이해해야 할 보안 고려 사항이 있는 고급 구성 옵션입니다. 비공개 GitLab Self-Managed 인스턴스의 OpenID 구성 및 공개 키를 S3 버킷과 같은 공개적으로 사용 가능한 위치와 올바르게 동기화해야 합니다. 또한 S3 버킷 및 내부 파일이 적절히 보안되도록 해야 합니다. S3 버킷을 제대로 보안하지 못하면 이 OpenID Connect ID와 연결된 모든 클라우드 계정을 탈취할 수 있습니다.

GitLab 인스턴스가 공개적으로 접근 가능하지 않은 경우 AWS에서 OpenID Connect를 구성할 수 없습니다. 인스턴스에 대한 OpenID Connect 구성을 활성화하여 특정 구성을 공개적으로 접근 가능하게 하는 해결 방법을 사용할 수 있습니다:

1. GitLab 인스턴스의 인증 세부 정보를 공개적으로 사용 가능한 위치(예: S3 파일)에 저장합니다:

   - 인스턴스의 OpenID 구성을 S3 파일에서 호스팅합니다. 구성은 `/.well-known/openid-configuration`에서 사용 가능합니다. 예: `http://gitlab.example.com/.well-known/openid-configuration`. 구성 파일에서 `issuer:` 및 `jwks_uri:` 값을 공개적으로 사용 가능한 위치를 가리키도록 업데이트합니다.
   - 인스턴스 URL의 공개 키를 S3 파일에 호스팅합니다. 키는 `/oauth/discovery/keys`에서 사용 가능합니다. 예: `http://gitlab.example.com/oauth/discovery/keys`.

   예를 들어:

   - OpenID 구성 파일: `https://example-oidc-configuration-s3-bucket.s3.eu-north-1.amazonaws.com/.well-known/openid-configuration`.
   - JWKS(JSON 웹 키 집합): `https://example-oidc-configuration-s3-bucket.s3.eu-north-1.amazonaws.com/oauth/discovery/keys`.
   - ID 토큰의 발급자 클레임 `iss:` 및 OpenID 구성의 `issuer:` 값은 `https://example-oidc-configuration-s3-bucket.s3.eu-north-1.amazonaws.com`이 됩니다.

1. 선택 사항. [OpenID 구성 엔드포인트 검증자](https://www.oauth2.dev/tools/openid-configuration-validator)와 같은 OpenID 구성 검증자를 사용하여 공개적으로 사용 가능한 OpenID 구성을 검증합니다.
1. ID 토큰에 대한 사용자 지정 발급자 클레임을 구성합니다. 기본적으로 GitLab ID 토큰에는 발급자 클레임 `iss:`이 GitLab 인스턴스의 주소로 설정되어 있습니다. 예: `http://gitlab.example.com`.

1. 발급자 URL 업데이트:

   {{< tabs >}}

   {{< tab title="Linux 패키지(Omnibus)" >}}

   1. `/etc/gitlab/gitlab.rb`을 편집합니다.

      ```ruby
      gitlab_rails['ci_id_tokens_issuer_url'] = '<public_url_with_openid_configuration_and_keys>'
      ```

      `<public_url_with_openid_configuration_and_keys>`을 `https://example-oidc-configuration-s3-bucket.s3.eu-north-1.amazonaws.com`와 같은 URL로 바꿉니다.

   1. 파일을 저장하고 [GitLab 재구성](../../../administration/restart_gitlab.md#reconfigure-a-linux-package-installation)하여 변경 사항을 적용합니다.

   {{< /tab >}}

   {{< tab title="Helm 차트(Kubernetes)" >}}

   1. Helm 값을 내보냅니다:

      ```shell
      helm get values gitlab > gitlab_values.yaml
      ```

   1. `gitlab_values.yaml`을 편집합니다.

      ```yaml
      global:
        appConfig:
          ciIdTokens:
            issuerUrl: '<public_url_with_openid_configuration_and_keys>'
      ```

      `<public_url_with_openid_configuration_and_keys>`을 `https://example-oidc-configuration-s3-bucket.s3.eu-north-1.amazonaws.com`와 같은 URL로 바꿉니다.

   1. 파일을 저장하고 새 값을 적용합니다:

      ```shell
      helm upgrade -f gitlab_values.yaml gitlab gitlab/gitlab
      ```

   {{< /tab >}}

   {{< tab title="Docker" >}}

   1. `docker-compose.yml`을 편집합니다.

      ```yaml
      version: "3.6"
      services:
        gitlab:
          environment:
            GITLAB_OMNIBUS_CONFIG: |
              gitlab_rails['ci_id_tokens_issuer_url'] = '<public_url_with_openid_configuration_and_keys>'
      ```

      `<public_url_with_openid_configuration_and_keys>`을 `https://example-oidc-configuration-s3-bucket.s3.eu-north-1.amazonaws.com`와 같은 URL로 바꿉니다.

   1. 파일을 저장하고 GitLab을 다시 시작합니다.

      ```shell
      docker compose up -d
      ```

   {{< /tab >}}

   {{< tab title="Self-compiled(source)" >}}

   1. `/home/git/gitlab/config/gitlab.yml`을 편집합니다.

      ```yaml
       production: &base
         ci_id_tokens:
           issuer_url: '<public_url_with_openid_configuration_and_keys>'
      ```

      `<public_url_with_openid_configuration_and_keys>`을 `https://example-oidc-configuration-s3-bucket.s3.eu-north-1.amazonaws.com`와 같은 URL로 바꿉니다.

   1. 파일을 저장하고 [GitLab 재구성](../../../administration/restart_gitlab.md#self-compiled-installations)하여 변경 사항을 적용합니다.

   {{< /tab >}}

   {{< /tabs >}}

1. [`ci:validate_id_token_configuration` Rake 작업](../../../administration/raketasks/tokens/_index.md#validate-custom-issuer-url-configuration-for-cicd-id-tokens)을 실행하여 CI/CD ID 토큰 구성을 검증합니다.

## 문제 해결 {#troubleshooting}

### 오류: `Not authorized to perform sts:AssumeRoleWithWebIdentity` {#error-not-authorized-to-perform-stsassumerolewithwebidentity}

이 오류가 표시되면:

```plaintext
An error occurred (AccessDenied) when calling the AssumeRoleWithWebIdentity operation:
Not authorized to perform sts:AssumeRoleWithWebIdentity
```

여러 이유로 인해 발생할 수 있습니다:

- 클라우드 관리자가 GitLab에서 OIDC를 사용하도록 프로젝트를 구성하지 않았습니다.
- 역할이 브랜치 또는 태그에서 실행되는 것으로 제한됩니다. [조건부 역할 구성](../_index.md)을 참조하세요.
- 와일드카드 조건을 사용할 때 `StringEquals`이 `StringLike` 대신 사용됩니다. [관련 이슈](https://gitlab.com/guided-explorations/aws/configure-openid-connect-in-aws/-/issues/2#note_852901934)를 참조하세요.

### `Could not connect to openid configuration of provider` 오류 {#could-not-connect-to-openid-configuration-of-provider-error}

AWS IAM에서 ID 공급자를 추가한 후 다음 오류가 발생할 수 있습니다:

```plaintext
Your request has a problem. Please see the following details.
  - Could not connect to openid configuration of provider: `https://gitlab.example.com`
```

OIDC ID 공급자의 발급자가 인증서 체인이 잘못된 순서로 되어 있거나 중복되거나 추가 인증서가 포함되어 있을 때 이 오류가 발생합니다.

GitLab 인스턴스의 인증서 체인을 확인합니다. 체인은 도메인 또는 발급자 URL로 시작하고 중간 인증서를 거쳐 루트 인증서로 끝나야 합니다. 다음 명령을 사용하여 인증서 체인을 검토하고 `gitlab.example.com`을 GitLab 호스트명으로 바꿉니다:

```shell
echo | /opt/gitlab/embedded/bin/openssl s_client -connect gitlab.example.com:443
```

### `Couldn't retrieve verification key from your identity provider` 오류 {#couldnt-retrieve-verification-key-from-your-identity-provider-error}

다음과 유사한 오류가 발생할 수 있습니다:

- `An error occurred (InvalidIdentityToken) when calling the AssumeRoleWithWebIdentity operation: Couldn't retrieve verification key from your identity provider, please reference AssumeRoleWithWebIdentity documentation for requirements`

이 오류의 원인은 다음과 같을 수 있습니다:

- ID 공급자(IdP)의 `.well_known` URL 및 `jwks_uri`은 공개 인터넷에서 액세스할 수 없습니다.
- 사용자 지정 방화벽이 요청을 차단하고 있습니다.
- IdP에서 AWS STS 엔드포인트에 도달하는 API 요청에 5초 이상의 지연이 있습니다.
- STS가 `.well_known` URL 또는 IdP의 `jwks_uri`에 너무 많은 요청을 보내고 있습니다.

[이 오류에 대한 AWS 기술 센터 문서](https://repost.aws/knowledge-center/iam-sts-invalididentitytoken)에서 설명한 대로 `.well_known` URL 및 `jwks_uri`을 해결할 수 있도록 GitLab 인스턴스가 공개적으로 접근 가능해야 합니다. 이것이 불가능한 경우, 예를 들어 GitLab 인스턴스가 오프라인 환경에 있는 경우 [비공개 GitLab 인스턴스 구성](#configure-a-non-public-gitlab-instance) 방법을 참조하세요.
