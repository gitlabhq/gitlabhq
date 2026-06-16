---
stage: Software Supply Chain Security
group: Pipeline Security
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 복구 키 관리
---

복구 키는 OpenBao를 위한 긴급 자격증명입니다. 기본 JWT 인증 방법을 사용할 수 없게 될 때 임시 루트 토큰을 생성하는 데 사용합니다.

복구 키는 보안 암호 조회 또는 네임스페이스 프로비저닝과 같은 표준 작업에서 사용되지 않습니다. 이를 높은 권한 자격증명으로 취급하고 안전하게 저장합니다.

> [!warning]
> 복구 키는 OpenBao 데이터베이스에 저장된 데이터를 복호화할 수 없습니다. 모든 OpenBao 데이터는 구성된 언실 메커니즘으로 보호됩니다. 이는 `gitlab-openbao-unseal` Kubernetes 보안 정보에 저장된 정적 키이거나 외부 KMS입니다. 복구 키와 별도로 언실 메커니즘을 백업합니다.

이 페이지의 명령을 실행하려면 toolbox 파드의 이름이 필요합니다. 찾으려면 다음을 실행합니다:

```shell
kubectl get pods -n gitlab -lapp=toolbox
```

다음 명령에서 `<toolbox-pod-name>` 대신 파드 이름을 사용합니다.

## 복구 키 저장 {#store-the-recovery-key}

초기 설정 중에 한 번 이 명령을 실행합니다. 인시던트가 발생하기 전에 실행합니다:

```shell
kubectl exec -n gitlab -it -c toolbox <toolbox-pod-name> -- \
  gitlab-rake "gitlab:secrets_management:openbao:recovery_key:store"
```

이 명령은 OpenBao에서 복구 키를 생성하고 GitLab 데이터베이스에 암호화되어 저장합니다.

> [!warning]
> 복구 키는 한 번만 생성될 수 있습니다. `recovery_key:store`를 두 번 실행할 수 없거나 `recovery_key:fetch`를 실행한 후에 실행할 수 없습니다.

이 명령을 실행할 때까지 OpenBao는 모든 파드 재시작 시 경고를 기록합니다: `[WARN]  core: post-unseal upgrade seal keys failed: error="no recovery key found"`. 키를 저장한 후 경고가 중지됩니다.

## 저장된 복구 키 보기 {#view-the-stored-recovery-key}

GitLab 데이터베이스에서 복구 키를 가져오고 보려면 다음을 실행합니다:

```shell
kubectl exec -n gitlab -it -c toolbox <toolbox-pod-name> -- \
  gitlab-rake "gitlab:secrets_management:openbao:recovery_key:show"
```

> [!warning]
> 이 명령은 키를 일반 텍스트로 표시하기 전에 확인을 요청합니다. 출력을 안전하게 저장합니다. 로그하거나 보안 채널 외부에서 공유하지 마세요.

## 복구 키를 저장하지 않고 가져오기 {#fetch-the-recovery-key-without-storing-it}

`recovery_key:fetch`를 사용하여 복구 키를 생성하고 GitLab 데이터베이스에 저장하지 않고 터미널에 표시합니다. 외부 시스템(예: 암호 관리자 또는 하드웨어 보안 모듈)에 키를 저장할 때 이 작업을 사용합니다.

> [!warning]
> 복구 키는 한 번만 생성될 수 있습니다. `recovery_key:fetch`를 두 번 실행할 수 없거나 `recovery_key:store`를 실행한 후에 실행할 수 없습니다.

```shell
kubectl exec -n gitlab -it -c toolbox <toolbox-pod-name> -- \
  gitlab-rake "gitlab:secrets_management:openbao:recovery_key:fetch"
```

이 작업은 키를 생성하고 표시하기 전에 확인을 요청합니다. 키가 일반 텍스트로 나타납니다.

## 복구 키에서 루트 토큰 생성 {#generate-a-root-token-from-the-recovery-key}

복구 키를 사용하여 JWT 인증을 재구성하거나 언실을 마이그레이션하는 것과 같은 권한이 필요한 OpenBao 작업을 수행해야 할 때 임시 루트 토큰을 생성합니다. 예를 들어 다른 도메인이 있는 Geo 보조 사이트로 장애 조치할 때입니다. 자세한 내용은 [JWT 인증 구성](../geo/disaster_recovery/_index.md#optional-configure-jwt-authentication)을 참조하세요.

> [!warning]
> 필요한 작업을 완료한 후 루트 토큰을 즉시 해지합니다. 루트 토큰은 모든 OpenBao 작업 및 네임스페이스에 대한 제한 없는 액세스 권한이 있습니다.

`bao` 바이너리는 OpenBao 파드 내에서 사용할 수 있습니다. `kubectl exec`로 모든 명령을 실행합니다. 포트 포워딩은 필요하지 않습니다.

1. 복구 키를 검색합니다:

   ```shell
   kubectl exec -n gitlab -it -c toolbox <toolbox-pod-name> -- \
     gitlab-rake "gitlab:secrets_management:openbao:recovery_key:show"
   ```

   `recovery_key:fetch`를 사용하여 키를 외부적으로 저장한 경우 해당 위치에서 검색합니다.

1. OpenBao 파드 이름을 가져옵니다:

   ```shell
   kubectl get pods -n gitlab -l app.kubernetes.io/name=openbao -o name
   ```

   다음 단계에서 `<openbao-pod-name>` 대신 이 명령의 출력을 사용합니다. 예를 들어, `pod/gitlab-openbao-0`.

1. OTP를 생성합니다:

   ```shell
   kubectl exec -n gitlab <openbao-pod-name> -- \
     sh -c "BAO_ADDR=http://127.0.0.1:8200 bao operator generate-root -generate-otp"
   ```

   다음 명령에서 `<otp>` 대신 이 출력을 사용합니다.

1. 루트 생성을 초기화합니다:

   ```shell
   kubectl exec -n gitlab <openbao-pod-name> -- \
     sh -c "BAO_ADDR=http://127.0.0.1:8200 bao operator generate-root -init -otp=<otp>"
   ```

   성공적인 응답에는 `Started: true`과 `Nonce` 값이 포함됩니다. 다음 단계에서 `<nonce>` 대신 이 `Nonce` 값을 사용합니다.

1. 복구 키를 제출합니다:

   ```shell
   kubectl exec -n gitlab <openbao-pod-name> -- \
     sh -c "echo '<recovery_key>' | BAO_ADDR=http://127.0.0.1:8200 bao operator generate-root -nonce=<nonce>"
   ```

   OpenBao는 단일 복구 키 공유로 구성되어 있으므로 작업이 즉시 완료됩니다. 성공적인 응답에는 `Complete: true`과 `Encoded Token` 값이 포함됩니다. 다음 단계에서 `<encoded_token>` 대신 이 토큰 값을 사용합니다.

1. 루트 토큰을 디코딩합니다:

   ```shell
   kubectl exec -n gitlab <openbao-pod-name> -- \
     sh -c "BAO_ADDR=http://127.0.0.1:8200 bao operator generate-root -decode=<encoded_token> -otp=<otp>"
   ```

   다음 단계에서 `<root_token>` 대신 디코딩된 루트 토큰을 사용합니다.

1. 루트 토큰이 작동하는지 확인합니다:

   ```shell
   kubectl exec -n gitlab <openbao-pod-name> -- \
     sh -c "BAO_ADDR=http://127.0.0.1:8200 BAO_TOKEN=<root_token> bao token lookup"
   ```

   성공적인 응답에는 `policies  [root]`이 포함됩니다.

1. 필요한 권한이 필요한 작업을 수행합니다.

1. 루트 토큰을 해지합니다:

   ```shell
   kubectl exec -n gitlab <openbao-pod-name> -- \
     sh -c "BAO_ADDR=http://127.0.0.1:8200 BAO_TOKEN=<root_token> bao token revoke -self"
   ```
