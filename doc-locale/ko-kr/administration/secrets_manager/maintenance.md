---
stage: Software Supply Chain Security
group: Pipeline Security
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: OpenBao 유지 관리
---

{{< details >}}

- 계층: Premium, Ultimate
- 제공 서비스: GitLab Self-Managed
- 상태:  베타

{{< /details >}}

Geo 장애 조치에 대한 자세한 내용은 [Geo 재해 복구](../geo/disaster_recovery/_index.md#step-4-optional-promote-the-openbao-ha-cluster)를 참조하세요.

## OpenBao 백업 및 복구 {#back-up-and-restore-openbao}

OpenBao는 PostgreSQL의 별도 논리 데이터베이스에 데이터를 저장합니다. 이 데이터베이스를 일반 GitLab 백업과 함께 백업하면 장애 발생 후 비밀을 복구할 수 있습니다.

OpenBao에 특화된 자세한 백업 및 복구 절차는 [OpenBao 백업 설명서](https://docs.gitlab.com/charts/charts/openbao/#back-up-openbao)를 참조하세요.

## 복구 키 관리 {#recovery-key-management}

OpenBao 복구 키 관리(저장, 보기 및 루트 토큰 생성에 사용)에 대한 자세한 내용은 [복구 키 관리](recovery_key.md)를 참조하세요.

## OpenBao 인증 복구 {#recover-openbao-authentication}

JWT `aud` (audience) 클레임과 저장된 `bound_audiences` 값이 동기화되지 않은 경우 OpenBao 인증을 복구해야 할 수 있습니다.

저장된 비밀을 보존하므로 먼저 복구 키를 사용하여 인증을 다시 구성하세요. 저장된 모든 비밀을 삭제하므로 OpenBao 데이터를 재설정하는 것은 최후의 수단으로만 사용하세요.

### 복구 키를 사용하여 인증 다시 구성 {#reconfigure-authentication-with-a-recovery-key}

이 방법은 저장된 모든 비밀을 보존하지만 복구 키가 필요합니다.

1. 복구 키에서 임시 루트 토큰을 생성합니다. 절차는 [복구 키에서 루트 토큰 생성](recovery_key.md#generate-a-root-token-from-the-recovery-key)을 참조하세요.

1. 현재 인증 역할을 읽어서 전체 구성을 확인합니다:

   ```shell
   OPENBAO_POD=$(kubectl get pods -n gitlab -l app.kubernetes.io/name=openbao -o name | head -1)
   kubectl exec -n gitlab "$OPENBAO_POD" -c openbao-server -- \
     sh -c "BAO_ADDR=http://127.0.0.1:8200 BAO_TOKEN=<root_token> bao read auth/gitlab_rails_jwt/role/app"
   ```

1. 수정된 `bound_audiences` 및 이전 단계의 다른 모든 필드로 역할을 다시 적용합니다. 업데이트 시 OpenBao는 생략된 필드를 기본값으로 재설정하므로 요청에는 전체 구성이 포함되어야 합니다. 중요한 점:

   - `role_type` 필드의 기본값은 `oidc`이므로 `role_type=jwt`를 포함해야 합니다. 그렇지 않으면 역할이 손상됩니다.
   - `claim_mappings` 필드를 생략하면 비어 있는 상태로 재설정되어 권한 부여가 손상됩니다. 이전 단계에서 반환한 것과 동일한 매핑을 포함하세요.

   `bound_claims` 및 `claim_mappings`는 맵이므로 `bao write <path> -`를 사용하여 표준 입력에서 JSON으로 구성을 제공하세요. `<your-domain>`을 OpenBao 도메인으로 바꾸고 `claim_mappings` 및 기타 값을 이전 단계에서 반환한 값으로 바꾸세요:

   ```shell
   kubectl exec -i -n gitlab "$OPENBAO_POD" -c openbao-server -- \
     sh -c "BAO_ADDR=http://127.0.0.1:8200 BAO_TOKEN=<root_token> bao write auth/gitlab_rails_jwt/role/app -" <<'JSON'
   {
     "role_type": "jwt",
     "user_claim": "user_id",
     "bound_subject": "gitlab_secrets_manager",
     "bound_audiences": ["https://openbao.<your-domain>"],
     "token_policies": ["secrets_manager"],
     "bound_claims": {"secrets_manager_scope": "privileged"},
     "claim_mappings": {
       "user_id": "user_id",
       "project_id": "project_id",
       "group_id": "group_id",
       "namespace_id": "namespace_id",
       "correlation_id": "correlation_id"
     }
   }
   JSON
   ```

1. 루트 토큰을 취소합니다. 첫 번째 단계의 절차에 취소 명령이 포함되어 있습니다.

이 절차는 루트 수준 audience만 수정합니다. 다른 도메인이 있는 보조 사이트로의 Geo 장애 조치는 모든 프로젝트 및 그룹에 대해 JWT 인증을 다시 프로비전해야 하므로 지원되지 않습니다. 대신 DNS를 업데이트하여 기본 도메인이 승격된 보조 도메인을 가리키도록 합니다. 자세한 내용은 [Geo 배포](_index.md#geo-deployment)를 참조하세요.

### OpenBao 데이터 재설정 {#reset-openbao-data}

> [!warning]
> 이 절차는 OpenBao에 저장된 모든 비밀을 영구적으로 삭제합니다. 완료 후 모든 Secrets Manager 비밀을 다시 생성하세요.

복구 키가 없고 `bound_audiences`가 JWT `aud` 클레임과 동기화되지 않으며 인증이 실패할 때 OpenBao 데이터를 재설정합니다. OpenBao가 잘못된 URL로 초기화되었을 때 불일치가 발생할 수 있습니다. 재설정은 OpenBao 데이터베이스를 초기화하여 OpenBao가 올바른 구성으로 자체 초기화되도록 합니다.

복구 키가 있으면 [복구 키를 사용하여 인증 다시 구성](#reconfigure-authentication-with-a-recovery-key)을 참조하세요. 이 방법은 저장된 비밀을 보존합니다.

시작하기 전에 구성에서 올바른 audience를 설정하세요:

- GitLab 18.10 이상의 경우 `global.openbao.jwt_audience`를 원하는 audience로 설정하세요.
- 이전 버전의 경우 OpenBao 외부 URL을 설정합니다. OpenBao는 자체 초기화 중에 이 URL에서 `bound_audiences`를 파생합니다.

OpenBao 데이터를 재설정하려면:

1. OpenBao를 0개 복제본으로 스케일합니다:

   ```shell
   kubectl -n gitlab scale deployment gitlab-openbao --replicas=0
   kubectl -n gitlab rollout status deployment gitlab-openbao --timeout=60s
   ```

1. toolbox Pod 이름을 확인합니다:

   ```shell
   kubectl -n gitlab get pods -l app=toolbox -o jsonpath='{.items[0].metadata.name}'
   ```

1. OpenBao 저장소 테이블을 초기화합니다. 플레이스홀더를 OpenBao 데이터베이스 비밀번호 및 호스트로 바꾸세요:

   ```shell
   kubectl -n gitlab exec -ti <toolbox-pod-name> -- \
     env PGPASSWORD='<openbao_database_password>' \
     psql -h <postgres_host> -U openbao -d openbao \
     -c "TRUNCATE TABLE openbao_kv_store; TRUNCATE TABLE openbao_ha_locks;"
   ```

1. 수정된 구성으로 OpenBao를 다시 배포합니다:

   ```shell
   helm upgrade --install --version <chart-version> gitlab gitlab/gitlab \
     -n gitlab -f gitlab.yaml
   ```

1. OpenBao를 다시 스케일업합니다. 차트를 다시 배포해도 수동으로 스케일을 축소한 배포는 복구되지 않습니다:

   ```shell
   kubectl -n gitlab scale deployment gitlab-openbao --replicas=2
   kubectl -n gitlab rollout status deployment gitlab-openbao --timeout=120s
   ```

1. OpenBao가 초기화되고 봉인 해제되었으며 올바른 audience를 사용하고 있는지 확인합니다:

   ```shell
   OPENBAO_POD=$(kubectl -n gitlab get pods -l app.kubernetes.io/name=openbao \
     -l openbao-active=true -o jsonpath='{.items[0].metadata.name}')
   kubectl -n gitlab exec -ti "$OPENBAO_POD" -c openbao-server -- \
     sh -c "BAO_ADDR=http://127.0.0.1:8200 bao status"
   kubectl -n gitlab get configmap gitlab-openbao-config -o yaml | grep bound_audiences
   ```

   상태에 `Initialized   true`와 `Sealed   false`가 표시되고 `bound_audiences` 값이 GitLab이 보내는 audience와 일치합니다.
