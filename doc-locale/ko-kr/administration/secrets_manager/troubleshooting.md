---
stage: Software Supply Chain Security
group: Pipeline Security
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: OpenBao 문제 해결
---

{{< details >}}

- 계층: Premium, Ultimate
- 제공 서비스: GitLab Self-Managed
- 상태:  베타

{{< /details >}}

복구 키 작업 및 break-glass 루트 토큰에 대해서는 [복구 키 관리](recovery_key.md)를 참조하세요. Geo 장애 조치에 대한 자세한 내용은 [Geo 재해 복구](../geo/disaster_recovery/_index.md#step-4-optional-promote-the-openbao-ha-cluster)를 참조하세요.

## OpenBao가 실행되는 위치 {#where-openbao-runs}

OpenBao는 GitLab이 Linux 패키지를 사용할 때에도 항상 Kubernetes에서 실행됩니다. 네임스페이스와 배포 이름은 설치 방법에 따라 달라집니다:

| 설치 방법 | 네임스페이스 | 배포       | Pod 컨테이너    |
|---------------------|-----------|------------------|------------------|
| Cloud Native GitLab | `gitlab`  | `gitlab-openbao` | `openbao-server` |
| Linux 패키지       | `openbao` | `openbao`        | `openbao-server` |

이 예제들은 Cloud Native 네임스페이스 `gitlab`를 사용합니다. Linux 패키지 설치의 경우, `gitlab`를 `openbao`로 바꾸고 `kubectl` 명령어에 적용합니다.

OpenBao pod는 `app.kubernetes.io/name=openbao` 레이블을 가집니다. 활성 노드는 또한 `openbao-active=true`를 가집니다.

## OpenBao 로그 찾기 {#find-openbao-logs}

`kubectl logs`로 OpenBao 로그를 읽습니다. 관련 GitLab Rails 및 Sidekiq 로그는 설치 방법에 따라 별도로 저장됩니다:

| 출처         | Cloud Native GitLab                              | Linux 패키지                                      |
|----------------|--------------------------------------------------|----------------------------------------------------|
| OpenBao 서버 | `kubectl logs` `openbao-server` 컨테이너에서 | `kubectl logs` `openbao-server` 컨테이너에서   |
| GitLab Rails   | `kubectl logs` `webservice` pod에서          | `/var/log/gitlab/gitlab-rails/production_json.log` |
| Sidekiq        | `kubectl logs` `sidekiq` pod에서             | `/var/log/gitlab/sidekiq/current`                  |
| GitLab Runner  | GitLab UI의 CI/CD 작업 로그                   | GitLab UI의 CI/CD 작업 로그                     |

OpenBao는 감사 이벤트를 GitLab에 게시하고 OpenBao pod 로그에도 작성합니다.

### OpenBao pod 찾기 {#find-the-openbao-pods}

OpenBao pod를 나열하고 활성 노드를 확인하려면:

```shell
kubectl get pods -n gitlab -l app.kubernetes.io/name=openbao \
  --label-columns openbao-active,openbao-sealed
```

`OPENBAO-ACTIVE`이 `true`로 설정된 pod가 활성 노드입니다. 나머지는 대기 노드입니다.

### OpenBao 상태 확인 {#check-openbao-status}

OpenBao는 요청을 처리하려면 봉인이 해제되어야 합니다. 확인하려면 pod에서 `bao status`을 실행합니다:

```shell
OPENBAO_POD=$(kubectl get pods -n gitlab -l app.kubernetes.io/name=openbao -o name | head -1)
kubectl exec -n gitlab "$OPENBAO_POD" -c openbao-server -- \
  sh -c "BAO_ADDR=http://127.0.0.1:8200 bao status"
```

출력에서 `Sealed`은 `false`여야 합니다. 활성 노드는 `HA Mode    active`을 표시하고 대기 노드는 `HA Mode    standby`을 표시합니다:

```plaintext
Seal Type       static
Initialized     true
Sealed          false
Storage Type    postgresql
HA Enabled      true
HA Mode         active
```

`sys/seal-status` 엔드포인트는 `"sealed":false`와 같은 상태를 보고합니다:

```shell
kubectl exec -n gitlab "$OPENBAO_POD" -c openbao-server -- \
  sh -c "BAO_ADDR=http://127.0.0.1:8200 bao read sys/seal-status"
```

> [!note]
> `bao` 바이너리는 pod에 있습니다. pod 내부에서 엔드포인트 쿼리에 `bao read`을 사용합니다.

로그에서 성공적으로 봉인이 해제된 노드는 `vault is unsealed`을 기록합니다. 활성 노드는 `acquired lock, enabling active operation`을 기록하고 대기 노드는 `entering standby mode`을 기록합니다:

```shell
OPENBAO_POD=$(kubectl get pods -n gitlab -l app.kubernetes.io/name=openbao -o name | head -1)
kubectl logs -n gitlab "$OPENBAO_POD" -c openbao-server \
  | grep -E "acquired lock, enabling active operation|entering standby mode"
```

### 시간 범위에서 오류 찾기 {#find-errors-in-a-time-window}

시간 범위에서 OpenBao 로그를 읽으려면 `--since`을 사용합니다:

```shell
OPENBAO_POD=$(kubectl get pods -n gitlab -l app.kubernetes.io/name=openbao -o name | head -1)
kubectl logs -n gitlab "$OPENBAO_POD" -c openbao-server --since=30m \
  | grep -iE "error|warn|failed"
```

Linux 패키지 설치의 경우, Rails 및 Sidekiq 로그 파일을 시간별로 검색합니다. 로그는 JSON이며 한 줄에 하나의 이벤트입니다.

> [!note]
> OpenBao는 모든 출력을 표준 오류로 기록하므로 일부 로그 플랫폼은 모든 줄을 오류로 태그합니다. 메시지 본문의 수준(`[info]`, `[warn]`)을 신뢰하고 플랫폼의 레이블은 신뢰하지 마세요.

### GitLab Rails 로그 {#gitlab-rails-logs}

Rails 로그는 UI 및 GraphQL API의 비밀 작업과 OpenBao의 감사 콜백을 포함합니다.

Cloud Native 설치의 경우:

```shell
kubectl logs -n gitlab -l app=webservice -c webservice \
  | grep -E "Projects::SecretsController|Groups::SecretsController|secrets_manager/audit_logs"
```

Linux 패키지 설치의 경우:

```shell
grep -E "Projects::SecretsController|Groups::SecretsController|secrets_manager/audit_logs" \
  /var/log/gitlab/gitlab-rails/production_json.log
```

GraphQL 작업은 `caller_id`가 `graphql:createProjectSecret` 또는 `graphql:getGroupSecrets`와 같이 나타납니다. 감사 콜백은 `/api/v4/internal/secrets_manager/audit_logs` 경로로 나타납니다.

### Sidekiq 로그 {#sidekiq-logs}

Secrets Manager 레코드를 프로비저닝, 프로비저닝 해제 및 유지 관리하는 작업자는 `SecretsManagement::` 네임스페이스 아래에서 실행됩니다.

Cloud Native 설치의 경우:

```shell
kubectl logs -n gitlab -l app=sidekiq -c sidekiq | grep "SecretsManagement::"
```

Linux 패키지 설치의 경우:

```shell
grep "SecretsManagement::" /var/log/gitlab/sidekiq/current
```

프로비저닝 문제의 경우, `ProvisionProjectSecretsManagerWorker` 또는 `ProvisionGroupSecretsManagerWorker`에 대해 필터링합니다.

### GitLab Runner 로그 {#gitlab-runner-logs}

CI/CD 작업이 비밀을 가져오지 못할 때, 원인은 GitLab UI의 작업 로그에 나타납니다. 다음 문자열을 위해 작업 로그를 검색합니다:

| 문자열                                           | 의미                                                            |
|--------------------------------------------------|--------------------------------------------------------------------|
| `Resolving secrets`                              | 러너가 작업의 비밀 해결을 시작했습니다.                    |
| `Using "gitlab_secrets_manager" secret resolver` | 러너가 GitLab Secrets Manager 리졸버를 선택했습니다.           |
| `not initialized or sealed Vault server`         | OpenBao가 봉인되었거나 초기화되지 않았습니다.                              |
| `api error: status code 403: permission denied`  | OpenBao가 요청을 거부했습니다. 주로 대상 또는 권한 문제입니다. |
| `inline auth JWT is required`                    | 러너가 인증 요청을 작성하지 못했습니다.            |

### 정상 시작 로그 {#healthy-startup-logs}

재시작 후 활성 노드는 이 순서대로 로그합니다. 대기 노드는 `vault is unsealed`에서 중지한 후 `entering standby mode`을 기록합니다. 줄 형식은 구성에 따라 다르므로 접두사보다는 메시지 텍스트를 일치시킵니다.

| 로그 메시지                                | 의미                              | 누락된 경우                                            |
|--------------------------------------------|--------------------------------------|-------------------------------------------------------|
| `==> OpenBao server started!`              | 프로세스가 시작되고 구성을 읽었습니다. | Pod이 시작되지 못했습니다. Pod 이벤트를 확인합니다.        |
| `vault is unsealed`                        | 자동 봉인 해제가 성공했습니다.               | 자동 봉인 해제가 실패했습니다. 봉인 해제 비밀 또는 KMS를 확인합니다.   |
| `acquired lock, enabling active operation` | 이 노드가 활성화되었습니다.             | 활성 노드가 없습니다. 데이터베이스 및 HA 잠금을 확인합니다.    |
| `post-unseal setup complete`               | 활성 노드가 설정을 완료했습니다.      | 설정이 완료되지 않았습니다. 데이터베이스 연결을 확인합니다.  |

### 오류 메시지 {#error-messages}

OpenBao 메시지는 `openbao-server` 컨테이너에서 옵니다. GitLab 메시지는 Rails 또는 Sidekiq 로그에서 옵니다.

| 컨테이너        | 메시지                                                       | 설명                                                        | 작업                                                              |
|------------------|---------------------------------------------------------------|--------------------------------------------------------------------|---------------------------------------------------------------------|
| `openbao-server` | `cipher: message authentication failed`                       | 봉인 키가 저장된 데이터를 해독할 수 없습니다.                       | 정적 봉인 해제의 경우, 기본 사이트에서 봉인 해제 비밀을 복사합니다. KMS 봉인의 경우, KMS 키를 확인합니다. [Geo 배포 문제 해결](#troubleshoot-geo-deployments)를 참조하세요. |
| `openbao-server` | `unknown key ID`                                              | 정적 봉인 해제 키 ID가 데이터베이스의 데이터와 일치하지 않습니다.  | 기본 사이트에서 봉인 해제 비밀을 복사합니다. [Geo 배포 문제 해결](#troubleshoot-geo-deployments)를 참조하세요. |
| `openbao-server` | `failed to acquire lock`                                      | 대기 노드가 읽기 전용 데이터베이스에서 HA 잠금을 획득할 수 없습니다. | Geo 보조 사이트에서 예상됩니다. 작업이 필요하지 않습니다.                    |
| `openbao-server` | `cannot execute INSERT in a read-only transaction`            | 대기 노드가 읽기 복제본에 쓰려고 시도했습니다.                   | Geo 보조 사이트에서 예상됩니다. 그 외의 경우, OpenBao가 데이터베이스에 대한 쓰기 액세스 권한이 있는지 확인하고 데이터베이스 권한을 확인합니다. |
| `openbao-server` | `post-unseal upgrade seal keys failed: error="no recovery key found"` | 복구 키가 저장된 적이 없습니다.                         | 무해합니다. `recovery_key:store`을 실행합니다. |
| Rails 또는 Sidekiq | `[OpenBao] health check returned unhealthy`                   | OpenBao가 응답했지만 비정상 상태를 보고했습니다.                 | `bao status`을 확인하고 OpenBao 로그를 확인합니다.                            |
| Rails 또는 Sidekiq | `[OpenBao] health check failed`                               | GitLab이 OpenBao에 연결할 수 없습니다.                                    | 연결을 확인합니다. [GitLab이 OpenBao에 연결할 수 없음](#gitlab-cannot-connect-to-openbao)을 참조하세요. |
| Rails 또는 Sidekiq | `Failed to authenticate with OpenBao`                         | OpenBao가 JWT를 거부했습니다.                                          | 대상을 확인합니다. [JWT 인증 실패](#jwt-authentication-fails)를 참조하세요. |
| Rails 또는 Sidekiq | `Failed to open TCP connection to <host>:443 (execution expired)` | Sidekiq이 OpenBao URL에 연결할 수 없습니다.                       | DNS 및 Sidekiq pod의 OpenBao URL을 확인합니다.                   |
| Rails 또는 Sidekiq | `SSL_connect ... state=error: wrong version number`           | `https` URL이 `http`을 제공하는 OpenBao 리스너를 가리킵니다.   | URL 스킴을 리스너와 일치시킵니다. [GitLab이 OpenBao에 연결할 수 없음](#gitlab-cannot-connect-to-openbao)을 참조하세요. |
| Rails 또는 Sidekiq | `Retrying failed secrets_manager maintenance task`            | 프로비저닝 또는 프로비저닝 해제 작업이 다시 시도 중입니다.            | 동일한 로그에서 작업자 오류를 확인합니다. 재시도는 세 번 시도 후에 중지됩니다. |

## Secrets Manager가 프로비저닝에서 고정됨 {#secrets-manager-is-stuck-in-provisioning}

Secrets Manager를 활성화하면 토글이 로딩 상태에서 `provisioning` 상태로 유지될 수 있습니다. Secrets Manager에는 `failed` 상태가 없으므로 활성화 전에 실패한 모든 단계가 레코드를 고정 상태로 남깁니다. 일반적인 원인은 Sidekiq이 OpenBao에 연결할 수 없다는 것입니다.

진단하려면:

1. 프로비저닝 작업자를 위해 Sidekiq 로그를 확인합니다:

   ```shell
   kubectl logs -n gitlab -l app=sidekiq -c sidekiq \
     | grep -E "ProvisionProjectSecretsManagerWorker|ProvisionGroupSecretsManagerWorker"
   ```

1. Sidekiq pod 또는 노드에서 Sidekiq이 OpenBao에 연결할 수 있는지 테스트합니다:

   ```shell
   curl "https://openbao.example.com/v1/sys/health"
   ```

유지 관리 작업자는 오래된 작업을 최대 3회 재시도한 후 중지합니다. 그 후, 레코드는 `provisioning`에서 자동 복구 없이 유지되고 재시도는 `Retrying failed
secrets_manager maintenance task`을 기록합니다.

연결을 수정한 후 Secrets Manager를 비활성화했다가 다시 활성화하여 다시 프로비저닝합니다.

### 자체 초기화 후 인증 마운트 누락 {#authentication-mount-missing-after-self-initialization}

여러 OpenBao pod를 가진 새로운 설치에서 자체 초기화 경쟁은 OpenBao를 봉인 해제된 상태로 남길 수 있지만 `gitlab_rails_jwt/` 인증 마운트 없이 남길 수 있습니다. pod는 정상으로 보이지만 비밀 작업은 권한 거부로 실패합니다. 루트 토큰으로 `bao auth list`을 실행하여 마운트가 있는지 확인합니다. 경쟁을 방지하려면 단일 복제본으로 새로운 설치를 시작하고 초기화가 완료되는지 확인한 후 확장합니다.

## GitLab이 OpenBao에 연결할 수 없음 {#gitlab-cannot-connect-to-openbao}

GitLab Rails 및 Sidekiq은 HTTP를 통해 OpenBao에 연결합니다. Rails는 `internal_url`을 사용하고, `internal_url`이 설정되지 않은 경우 `url`로 돌아갑니다. 구성을 검사하려면 [Rails 콘솔](../operations/rails_console.md)에서 다음을 실행합니다:

```ruby
Gitlab.config.openbao.to_h
```

일반적인 원인:

- `https://` URL이 `http`을 제공하는 OpenBao 리스너에 대해 `wrong version number`으로 실패합니다. `global.openbao.https`는 OpenBao 리스너 TLS가 아니라 GitLab이 연결하는 스킴을 설정합니다. 리스너는 기본적으로 일반 HTTP를 제공합니다. `global.openbao.https`을 설정하지 않은 상태로 두거나 `openbao.config.tlsDisable: false`으로 리스너 TLS를 활성화하고 `global.openbao.https`을 `true`로 설정합니다.
- OIDC 검색 및 감사 로깅은 신뢰할 수 없는 TLS 인증서에 대해 실패합니다. GitLab이 신뢰하는 인증서를 사용합니다.
- OpenBao 감사 항목을 생성하지 않는 요청은 인증 백엔드에 도달하지 않습니다. Ingress 또는 역방향 프록시를 확인합니다.

Cloud Native 설치의 경우, 작동 구성은 다음과 같습니다:

```yaml
global:
  openbao:
    enabled: true
    url: http://gitlab-openbao-active:8200
    internal_url: http://gitlab-openbao-active:8200
```

Linux 패키지 설치의 경우, GitLab은 `/etc/gitlab/gitlab.rb`의 `gitlab_rails['openbao']['url']` 설정을 사용하여 OpenBao에 연결합니다. 번들 NGINX 역방향 프록시는 `oak['components']['openbao']` 설정으로 OpenBao로 라우팅합니다. 자세한 내용은 [Linux 패키지 배포를 위해 OpenBao 설치](linux_package_integration.md)를 참조하세요.

## JWT 인증 실패 {#jwt-authentication-fails}

GitLab은 JWT를 사용하여 OpenBao에 인증합니다. JWT의 `aud` (대상) 클레임은 OpenBao 인증 역할의 `bound_audiences` 값과 정확히 일치해야 합니다. 모든 차이는 인증에 실패하며, 후행 슬래시, `http` 비교 `https` 또는 포트를 포함합니다.

OpenBao는 OpenBao URL에서 파생된 초기화 시간에 `bound_audiences`을 저장합니다. 저장된 값은 나중에 URL을 변경할 때 변경되지 않습니다. URL을 변경하면 저장된 `bound_audiences`이 더 이상 GitLab이 보내는 `aud`과 일치하지 않아 인증이 중단됩니다. 연결 URL과 독립적으로 대상을 설정하려면 `global.openbao.jwt_audience`을 사용합니다.

GitLab이 보내는 대상을 찾으려면 Rails 콘솔에서 다음을 실행합니다:

```ruby
SecretsManagement::ProjectSecretsManager.jwt_audience
```

메서드는 구성된 `jwt_audience`을 반환하거나 `jwt_audience`이 설정되지 않은 경우 OpenBao `url`을 반환합니다. 저장된 값을 검사하려면 루트 토큰을 사용하여 인증 역할을 읽고 `bound_audiences`을 해당 대상과 비교합니다.

> [!warning]
> 권한이 있는 액세스 없이는 이를 수정할 수 없습니다. 루트 토큰은 자체 초기화 후 취소되고 봉인 해제 키는 대체가 아닙니다. 봉인 해제 비밀에는 루트 토큰이 아니라 봉인 해제 키만 포함됩니다.

저장된 비밀을 삭제하지 않고 불일치를 수정하려면 복구 키를 사용하여 인증을 다시 구성합니다. 절차는 [복구 키를 사용한 인증 재구성](maintenance.md#reconfigure-authentication-with-a-recovery-key)을 참조하세요.

복구 키가 없는 경우 [OpenBao 데이터 재설정](maintenance.md#reset-openbao-data)합니다. 저장된 모든 비밀이 삭제됩니다.

## OpenBao pod가 봉인됨 {#openbao-pods-are-sealed}

`bao status`이 시작 시 `Sealed    true`을 보고하면 자동 봉인 해제가 실패합니다:

- 기본 정적 봉인 해제의 경우, 원인은 일반적으로 누락되었거나 잘못된 봉인 해제 비밀입니다. 비밀은 Cloud Native 설치의 경우 `gitlab-openbao-unseal`이고 Linux 패키지 설치의 경우 `openbao-static-unseal`입니다.
- KMS 자동 봉인 해제(현재 AWS KMS (`awskms`))의 경우, 원인은 일반적으로 OpenBao가 KMS에 연결할 수 없다는 것입니다.

봉인 상태를 확인하려면 [OpenBao 상태 확인](#check-openbao-status)을 참조하세요.

> [!warning]
> 이전 키를 사용 가능하게 유지하지 않고 정적 봉인 해제 키를 교체하면 OpenBao가 기존 데이터를 해독할 수 없습니다. 이전 키를 새 키 옆에 추가하고 모든 pod이 새 키에서 실행된 후에만 제거합니다.

## 데이터베이스 문제 {#database-problems}

OpenBao는 자체 PostgreSQL 데이터베이스가 필요합니다. GitLab 차트는 전용 데이터베이스 없이 OpenBao를 활성화하면 설치 또는 업그레이드에 실패합니다.

기타 데이터베이스 문제:

- 연결 풀 고갈 또는 높은 지연은 간헐적 시간 초과를 유발합니다.
- Linux 패키지 PostgreSQL 구성에서 잘못된 `md5_auth_cidr_addresses`, `sslMode` 또는 암호 값이 OpenBao pod를 `CrashLoopBackOff`로 보냅니다. 올바른 설정은 [Linux 패키지 배포를 위해 OpenBao 설치](linux_package_integration.md)를 참조하세요.

## 감사 이벤트 누락 {#audit-events-are-missing}

OpenBao는 감사 이벤트를 GitLab의 `/api/v4/internal/secrets_manager/audit_logs`에 게시합니다. GitLab 차트는 기본적으로 감사 로깅을 활성화합니다. 감사 이벤트가 도착하지 않으면:

- `config.audit.http.enabled`을 `false`로 설정하면 OpenBao가 이벤트 게시를 중지합니다. 감사 로깅이 활성화되어 있는지 확인합니다.
- 공유 감사 토큰 불일치는 감사 엔드포인트에서 `401`을 반환합니다. GitLab과 OpenBao가 동일한 감사 토큰을 사용하는지 확인합니다.

## Geo 배포 문제 해결 {#troubleshoot-geo-deployments}

OpenBao는 기본 Geo 사이트의 활성 노드로 실행되고 각 보조 사이트의 대기 노드로 실행됩니다. 보조 노드는 읽기 전용 PostgreSQL 복제본에 연결되므로 `failed to acquire lock`과 `cannot execute INSERT in a read-only transaction`을 기록합니다. 이 메시지들은 예상됩니다.

보조 노드가 `cipher: message authentication failed` 또는 `unknown key ID`을 기록하면 봉인 키가 기본과 일치하지 않습니다. 수정은 봉인 메커니즘에 따라 다릅니다:

- 정적 봉인 해제의 경우, 기본 클러스터에서 보조 클러스터로 `gitlab-openbao-unseal` 비밀을 복사한 후 OpenBao pod를 재시작합니다:

  ```shell
  kubectl -n gitlab get secret gitlab-openbao-unseal -o yaml
  ```

- KMS 봉인의 경우, 두 사이트를 모두 동일한 KMS 키를 사용하도록 구성합니다.

장애 조치 후 JWT 인증이 실패하면 대상이 더 이상 저장된 `bound_audiences`과 일치하지 않습니다. 수정은 도메인에 따라 다릅니다:

- 두 사이트가 모두 기본 OpenBao URL을 사용하는 경우, 두 사이트에서 `jwt_audience`을 기본 OpenBao URL로 설정합니다. [보조 사이트에 OpenBao 설치](_index.md#install-openbao-on-a-secondary-site)를 참조하세요.
- 보조 사이트가 다른 도메인을 사용하는 경우, 이 구성은 지원되지 않습니다. 대상을 다시 구성해도 인증이 복구되지 않습니다. 모든 프로젝트 및 그룹 네임스페이스도 다시 프로비저닝이 필요하기 때문입니다. DNS를 업데이트하여 기본 도메인이 승격된 보조를 가리키도록 합니다. 자세한 내용은 [Geo 배포](_index.md#geo-deployment)를 참조하세요.

## 느린 비밀 작업 진단 {#diagnose-slow-secret-operations}

CI/CD 작업이 비밀을 가져오는 데 느리거나 비밀 작업이 시간 초과되는 경우, 다음 쿼리를 사용하여 원인을 찾습니다. OpenBao 메트릭을 스크래핑하는 Prometheus 또는 Grafana 인스턴스에서 이러한 쿼리를 실행합니다. 해당 메트릭을 표시하려면 [OpenBao 메트릭](_index.md#openbao-metrics)을 참조하세요.

### 지연 시간이 높아졌는지 확인 {#confirm-latency-is-elevated}

다음 쿼리를 사용하여 밀리초 단위의 평균 요청 지연을 측정합니다. 쿼리는 낮은 트래픽 배포를 포함한 모든 트래픽 수준에서 작동합니다:

```prometheus
rate(openbao_core_handle_request_sum[5m])
/
rate(openbao_core_handle_request_count[5m])
```

정상 부하에서 모든 요청 유형의 평균 지연은 일반적으로 3~7ms입니다. 평균 지연이 지속적으로 20ms를 초과하면 조사합니다.

OpenBao가 활성적으로 요청을 처리할 때, P99 지연에 대해 다음 쿼리를 사용합니다:

```prometheus
openbao_core_handle_request{quantile="0.99"}
```

정상 P99는 10ms 미만입니다. OpenBao가 유휴 상태이면 요약 창에 최근 관찰이 없어 이 쿼리는 `NaN`을 반환합니다. 그 경우 비율 기반 쿼리를 사용합니다.

### 잠재적 문제 확인 {#identify-potential-issues}

| 잠재적 문제             | 확인할 항목                   | 쿼리                                                                       | 임계값           | 작업                                                             |
|-----------------------------|---------------------------------|-----------------------------------------------------------------------------|---------------------|--------------------------------------------------------------------|
| CPU 제한이 너무 낮음           | CFS 스로틀 비율              | [CPU 스로틀링 쿼리](_index.md#cpu-throttling)                            | > 25%               | CPU 제한 증가                                                 |
| 수요가 CPU 용량 초과 | CPU 사용률                 | [CPU 사용률 쿼리](_index.md#cpu-utilization)                          | > 요청의 50%    | [크기 조정 표](_index.md#pod-resources)의 다음 행으로 확장 |
| 요청 급증               | 진행 중인 요청              | `openbao_core_in_flight_requests`                                           | 5 이상 지속   | 일시적입니다. 재발을 모니터링합니다.                                 |
| PostgreSQL 병목 현상       | 평균 PostgreSQL 읽기 지연 | `rate(openbao_postgres_get_sum[5m]) / rate(openbao_postgres_get_count[5m])` | > 5ms              | PostgreSQL 리소스 및 연결 풀 확인                     |
| 메모리 압박             | 메모리 사용률              | [메모리 사용률 쿼리](_index.md#memory-utilization)                    | 메모리 요청에 가까움 | [네임스페이스 공식](_index.md#memory-utilization)을 사용하여 메모리 증가 |

PostgreSQL 지연이 높으면 연결 풀이 포화되었는지 확인합니다. 모든 연결이 바쁘면 추가 요청이 대기하고 지연을 유발합니다. 연결 풀 구성은 [데이터베이스 리소스](_index.md#database-resources)를 참조하세요.
