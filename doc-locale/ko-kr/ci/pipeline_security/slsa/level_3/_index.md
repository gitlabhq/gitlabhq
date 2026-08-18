---
stage: Software Supply Chain Security
group: Pipeline Security
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: SLSA 레벨 3 증명 정보 증명서
---

{{< details >}}

- 계층: Ultimate
- 제공 서비스: GitLab.com
- 상태:  실험적 기능

{{< /details >}}

{{< history >}}

- GitLab 18.3에서 [도입됨](https://gitlab.com/gitlab-org/gitlab/-/issues/547865) [플래그 포함](../../../../administration/feature_flags/_index.md) `slsa_provenance_statement` 기본적으로 비활성화되어 있습니다.

{{< /history >}}

> [!flag]
> 이 기능의 가용성은 기능 플래그로 제어됩니다. 자세한 내용은 기록을 참조하세요. 이 기능은 테스트 가능하지만 프로덕션 사용 준비가 되지 않았습니다.

GitLab은 SLSA 레벨 3 호환 증명 정보 증명서를 생성할 수 있습니다. 레벨 2와 3 증명 정보 증명서의 주요 차이점은 [격리 및 "위조 불가능" 요구사항](https://slsa.dev/spec/v1.2/build-requirements#isolated)입니다.

증명 정보에 대한 자세한 내용은 GitLab [SLSA 증명 정보 사양](provenance_v1.md)을 참조하세요.

## 전제 조건 {#prerequisites}

모든 컨테이너 또는 아티팩트의 증명을 위해 다음 조건을 충족해야 합니다:

- 빌드와 연결된 프로젝트는 공개여야 합니다. 이 요구사항은 [Rekor](https://docs.sigstore.dev/logging/overview/)에 정보가 실수로 공개되는 것을 방지하기 위해 적용됩니다.
- 빌드는 `build` 스테이지를 사용해야 합니다.
- `slsa_provenance_statement` 기능 플래그는 프로젝트에 대해 활성화되어야 합니다.

## 아티팩트에 대한 증명 생성 {#generate-an-attestation-for-artifacts}

빌드에서 생성된 모든 아티팩트에 대한 증명을 생성하려면:

- `ATTEST_BUILD_ARTIFACTS` CI/CD 변수를 `true`로 설정합니다.
- 아티팩트는 100MB를 초과하면 안 됩니다.

예를 들어, GitLab은 이 CI/CD 작업의 아티팩트에 대한 증명을 생성합니다:

```yaml
build-job:
  stage: build
  variables:
    ATTEST_BUILD_ARTIFACTS: true
  script:
    - echo "Hello, $GITLAB_USER_LOGIN!"
    - echo "Hello, $GITLAB_USER_LOGIN!" > test.txt
  artifacts:
    paths:
      - test.txt
```

## 컨테이너에 대한 증명 생성 {#generate-an-attestation-for-a-container}

컨테이너에 대한 증명을 생성하려면:

- CI/CD 변수 `ATTEST_CONTAINER_IMAGES`를 `true`로 설정합니다.
- `IMAGE_DIGEST` 변수를 유효한 SHA256 참조로 설정하고 다음 형식을 사용합니다:

  ```plaintext
  sha256:9bf00f5090086aba643d21f8ed663576855add63b7b780b4eaffc5124812c3c9
  org/project-name@sha256:9bf00f5090086aba643d21f8ed663576855add63b7b780b4eaffc5124812c3c9
  9bf00f5090086aba643d21f8ed663576855add63b7b780b4eaffc5124812c3c9
  ```

예를 들어, GitLab은 이 CI/CD 작업에서 생성된 이미지에 대한 증명을 생성합니다:

```yaml
build-dockerhub:
  stage: build
  variables:
    ATTEST_CONTAINER_IMAGES: true
    CI_REGISTRY: docker.io
    DOCKER_IMAGE_NAME: sroqueworcel/test-slsa-sbom:stable
  script:
    - echo $DOCKER_REGISTRY_PASSWORD | docker login $CI_REGISTRY -u $DOCKER_REGISTRY_USER --password-stdin
    - docker build -t $DOCKER_IMAGE_NAME .
    - docker push $DOCKER_IMAGE_NAME
    - IMAGE_DIGEST="$(docker inspect --format='{{index .Id}}' "$DOCKER_IMAGE_NAME")"
    - echo "IMAGE_DIGEST=$IMAGE_DIGEST" >> build.env
  artifacts:
    reports:
      dotenv: build.env
```

## 증명서 보기 {#view-attestations}

성공한 증명서는 증명서 페이지에 저장됩니다. 증명서를 보려면:

1. 상단 표시줄에서 **검색 또는 이동**을 선택하고 프로젝트를 찾습니다.
1. 왼쪽 사이드바에서 **빌드** > **증명서**를 선택합니다.

증명이 성공하지 못한 경우 CI/CD 작업 로그에 오류가 표시됩니다.

[Attestations API](../../../../api/attestations.md)를 사용하여 성공한 증명을 가져올 수도 있습니다.

## 증명 검증 {#verifying-attestations}

`glab` 명령줄 인터페이스를 사용하여 아티팩트 및 컨테이너를 검증할 수 있습니다. 예를 들어:

- 성공한 검증:

  ```shell
  % glab attestation verify ~/file-or-container -p org/project-name
  Artifact provenance successfully verified. Signatures confirm file.txt was attested by org/project-name
  ```

- 실패한 검증:

  ```shell
  % glab attestation verify ~/file.txt -p org/project-name

     ERROR

    Unable to find a provenance statement for 1f9e5808a340916aa5618ee13a893dcf9d4f7e2d42a254be0f7eb06a094ab8ea.
  ```
