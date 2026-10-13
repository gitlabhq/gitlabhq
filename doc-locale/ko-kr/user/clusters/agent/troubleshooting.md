---
stage: Verify
group: Runner Core
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Kubernetes용 GitLab 에이전트 문제 해결
---

Kubernetes용 GitLab 에이전트를 사용할 때 문제 해결이 필요한 문제가 발생할 수 있습니다.

서비스 로그를 확인하여 시작할 수 있습니다:

```shell
kubectl logs -f -l=app.kubernetes.io/name=gitlab-agent -n gitlab-agent
```

GitLab 관리자인 경우 [Kubernetes용 GitLab 에이전트 서버 로그](../../../administration/clusters/kas.md#troubleshooting)도 볼 수 있습니다.

## 전송: WebSocket 다이얼에 연결 오류 발생 {#transport-error-while-dialing-failed-to-websocket-dial}

```json
{
  "level": "warn",
  "time": "2020-11-04T10:14:39.368Z",
  "msg": "GetConfiguration failed",
  "error": "rpc error: code = Unavailable desc = connection error: desc = \"transport: Error while dialing failed to WebSocket dial: failed to send handshake request: Get \\\"https://gitlab-kas:443/-/kubernetes-agent\\\": dial tcp: lookup gitlab-kas on 10.60.0.10:53: no such host\""
}
```

이 오류는 `kas-address`과(와) 에이전트 포드 간에 연결 문제가 있을 때 발생합니다. 이 문제를 해결하려면 `kas-address`가 정확한지 확인하세요.

```json
{
  "level": "error",
  "time": "2021-06-25T21:15:45.335Z",
  "msg": "Reverse tunnel",
  "mod_name": "reverse_tunnel",
  "error": "Connect(): rpc error: code = Unavailable desc = connection error: desc= \"transport: Error while dialing failed to WebSocket dial: expected handshake response status code 101 but got 301\""
}
```

이 오류는 `kas-address`에 뒤따르는 슬래시가 포함되지 않을 때 발생합니다. 이 문제를 해결하려면 `wss` 또는 `ws` URL이 `wss://GitLab.host.tld:443/-/kubernetes-agent/` 또는 `ws://GitLab.host.tld:80/-/kubernetes-agent/`와 같이 뒤따르는 슬래시로 끝나는지 확인하세요.

## WebSocket 다이얼에 연결 오류 발생: 핸드셰이크 요청을 보내지 못함 {#error-while-dialing-failed-to-websocket-dial-failed-to-send-handshake-request}

```json
{
  "level": "warn",
  "time": "2020-10-30T09:50:51.173Z",
  "msg": "GetConfiguration failed",
  "error": "rpc error: code = Unavailable desc = connection error: desc = \"transport: Error while dialing failed to WebSocket dial: failed to send handshake request: Get \\\"https://GitLabhost.tld:443/-/kubernetes-agent\\\": net/http: HTTP/1.x transport connection broken: malformed HTTP response \\\"\\\\x00\\\\x00\\\\x06\\\\x04\\\\x00\\\\x00\\\\x00\\\\x00\\\\x00\\\\x00\\\\x05\\\\x00\\\\x00@\\\\x00\\\"\""
}
```

이 오류는 에이전트 측에서 `wss`을(를) `kas-address`(으)로 구성했지만 에이전트 서버가 `wss`에서 사용 가능하지 않을 때 발생합니다. 이 문제를 해결하려면 양쪽에서 동일한 스키마가 구성되어 있는지 확인하세요.

## grpc-encoding에 압축 해제 프로그램이 설치되지 않음 {#decompressor-is-not-installed-for-grpc-encoding}

```json
{
  "level": "warn",
  "time": "2020-11-05T05:25:46.916Z",
  "msg": "GetConfiguration.Recv failed",
  "error": "rpc error: code = Unimplemented desc = grpc: Decompressor is not installed for grpc-encoding \"gzip\""
}
```

이 오류는 에이전트의 버전이 에이전트 서버(KAS)의 버전보다 최신일 때 발생합니다. 이 문제를 해결하려면 `agentk`과(와) 에이전트 서버가 동일한 버전인지 확인하세요.

## 알 수 없는 인증 기관에서 서명한 인증서 {#certificate-signed-by-unknown-authority}

```json
{
  "level": "error",
  "time": "2021-02-25T07:22:37.158Z",
  "msg": "Reverse tunnel",
  "mod_name": "reverse_tunnel",
  "error": "Connect(): rpc error: code = Unavailable desc = connection error: desc = \"transport: Error while dialing failed to WebSocket dial: failed to send handshake request: Get \\\"https://GitLabhost.tld:443/-/kubernetes-agent/\\\": x509: certificate signed by unknown authority\""
}
```

이 오류는 GitLab 인스턴스가 에이전트에 알려지지 않은 내부 인증 기관에서 서명한 인증서를 사용할 때 발생합니다.

이 문제를 해결하려면 [Helm 설치 사용자 정의](install/_index.md#customize-the-helm-installation)를 통해 CA 인증서 파일을 에이전트에 제공할 수 있습니다. `--set-file config.kasCaCert=my-custom-ca.pem`을(를) `helm install` 명령에 추가합니다. 파일은 유효한 PEM 또는 DER로 인코딩된 인증서여야 합니다.

`agentk`을(를) 설정된 `config.kasCaCert` 값으로 배포하면 인증서가 `configmap`에 추가되고 인증서 파일이 `/etc/ssl/certs`에 마운트됩니다.

예를 들어 `kubectl get configmap -lapp=gitlab-agent -o yaml` 명령을 사용하면:

```yaml
apiVersion: v1
items:
- apiVersion: v1
  data:
    ca.crt: |-
      -----BEGIN CERTIFICATE-----
      MIIFmzCCA4OgAwIBAgIUE+FvXfDpJ869UgJitjRX7HHT84cwDQYJKoZIhvcNAQEL
      ...truncated certificate...
      GHZCTQkbQyUwBWJOUyOxW1lro4hWqtP4xLj8Dpq1jfopH72h0qTGkX0XhFGiSaM=
      -----END CERTIFICATE-----
  kind: ConfigMap
  metadata:
    annotations:
      meta.helm.sh/release-name: self-signed
      meta.helm.sh/release-namespace: gitlab-agent-self-signed
    creationTimestamp: "2023-03-07T20:12:26Z"
    labels:
      app: gitlab-agent
      app.kubernetes.io/managed-by: Helm
      app.kubernetes.io/name: gitlab-agent
      app.kubernetes.io/version: v15.9.0
      helm.sh/chart: gitlab-agent-1.11.0
    name: self-signed-gitlab-agent
    resourceVersion: "263184207"
kind: List
```

GitLab 애플리케이션 서버의 [에이전트 서버(KAS) 로그](../../../administration/logs/_index.md#gitlab-agent-server-for-kubernetes-logs)에서 유사한 오류가 표시될 수 있습니다:

```json
{"level":"error","time":"2023-03-07T20:19:48.151Z","msg":"AgentInfo()","grpc_service":"gitlab.agent.agent_configuration.rpc.AgentConfiguration","grpc_method":"GetConfiguration","error":"Get \"https://gitlab.example.com/api/v4/internal/kubernetes/agent_info\": x509: certificate signed by unknown authority"}
```

이 문제를 해결하려면 [내부 CA의 공개 인증서 설치](https://docs.gitlab.com/omnibus/settings/ssl/#install-custom-public-certificates)를 `/etc/gitlab/trusted-certs` 디렉토리에 진행합니다.

또는 에이전트 서버(KAS)를 구성하여 사용자 정의 디렉토리에서 인증서를 읽을 수 있습니다. `/etc/gitlab/gitlab.rb`에 다음 구성을 추가합니다:

```ruby
gitlab_kas['env'] = {
   'SSL_CERT_DIR' => "/opt/gitlab/embedded/ssl/certs/"
 }
```

변경 사항을 적용하려면:

1. GitLab을 다시 구성합니다.

   ```shell
   sudo gitlab-ctl reconfigure
   ```

1. `gitlab-kas`을(를) 다시 시작합니다.

   ```shell
   gitlab-ctl restart gitlab-kas
   ```

## 오류: `Failed to register agent pod` {#error-failed-to-register-agent-pod}

에이전트 포드 로그에 `Failed to register agent pod. Please make sure the agent version matches the server version` 오류 메시지가 표시될 수 있습니다.

이 문제를 해결하려면 에이전트 버전이 GitLab 버전과 일치하는지 확인합니다.

버전이 일치하지만 오류가 계속되는 경우:

1. `gitlab-kas`이(가) `gitlab-ctl status gitlab-kas`로 실행 중인지 확인하세요.
1. `gitlab-kas` [로그](../../../administration/logs/_index.md#gitlab-agent-server-for-kubernetes-logs)를 확인하여 에이전트가 제대로 작동하는지 확인하세요.

## 워크로드 취약성 검사 수행 실패: jobs.batch가 이미 존재함 {#failed-to-perform-vulnerability-scan-on-workload-jobsbatch-already-exists}

```json
{
  "level": "error",
  "time": "2022-06-22T21:03:04.769Z",
  "msg": "Failed to perform vulnerability scan on workload",
  "mod_name": "starboard_vulnerability",
  "error": "running scan job: creating job: jobs.batch \"scan-vulnerabilityreport-b8d497769\" already exists"
}
```

Kubernetes용 GitLab 에이전트는 각 워크로드를 검사하는 작업을 만들어 취약성 검사를 수행합니다. 검사가 중단되면 이러한 작업이 남아 있을 수 있으며 더 많은 작업을 실행하기 전에 정리해야 합니다. 다음을 실행하여 이러한 작업을 정리할 수 있습니다:

```shell
kubectl delete jobs -l app.kubernetes.io/managed-by=starboard -n gitlab-agent
```

[이러한 작업을 보다 강력하게 정리하기 위해 노력하고 있습니다.](https://gitlab.com/gitlab-org/gitlab/-/issues/362016)

## 설치 중 구문 분석 오류 {#parse-error-during-installation}

에이전트를 설치할 때 다음 오류가 표시될 수 있습니다:

```shell
Error: parse error at (gitlab-agent/templates/observability-secret.yaml:1): unclosed action
```

이 오류는 일반적으로 호환되지 않는 Helm 버전으로 인해 발생합니다. 이 문제를 해결하려면 [Kubernetes 버전과 호환되는](_index.md#supported-kubernetes-versions-for-gitlab-features) Helm 버전을 사용하고 있는지 확인하세요.

## `GitLab Agent Server: Unauthorized` Kubernetes 대시보드 오류 {#gitlab-agent-server-unauthorized-error-on-dashboard-for-kubernetes}

`GitLab Agent Server: Unauthorized. Trace ID: <...>` 같은 오류가 [Kubernetes 대시보드](../../../ci/environments/kubernetes_dashboard.md) 페이지에 나타날 수 있으며, 다음 중 하나로 인해 발생할 수 있습니다:

- 에이전트 구성 파일의 `user_access` 항목이 없거나 잘못되었습니다. 해결하려면 [사용자에게 Kubernetes 액세스 권한 부여](user_access.md)를 참조하세요.
- 브라우저와 KAS에 전송되는 [`_gitlab_kas` 쿠키](../../../administration/clusters/kas.md#kubernetes-api-proxy-cookie)가 여러 개 있습니다. 가장 가능성 높은 원인은 같은 사이트에서 호스팅되는 여러 GitLab 인스턴스입니다.

  예를 들어 `gitlab.com`이(가) `kas.gitlab.com`을(를) 대상으로 하는 `_gitlab_kas` 쿠키를 설정했지만, 쿠키가 `kas.staging.gitlab.com`에도 전송되어 `staging.gitlab.com`에서 오류가 발생합니다.

  일시적으로 해결하려면 브라우저 쿠키 저장소에서 `gitlab.com`의 `_gitlab_kas` 쿠키를 삭제합니다. [이슈 418998](https://gitlab.com/gitlab-org/gitlab/-/issues/418998)은(는) 이 알려진 문제에 대한 수정을 제안합니다.
- GitLab과 KAS가 다른 사이트에서 실행됩니다. 예를 들어 `gitlab.example.com`에서 실행되는 GitLab과 `kas.example.com`에서 실행되는 KAS입니다. GitLab은 이 사용 사례를 지원하지 않습니다. 자세한 내용은 [이슈 416436](https://gitlab.com/gitlab-org/gitlab/-/issues/416436)을(를) 참조하세요.

## 에이전트 버전 불일치 {#agent-version-mismatch}

GitLab의 Kubernetes 클러스터 페이지 **에이전트** 탭에서 `Agent version mismatch: The agent versions do not match each other across your cluster's pods.` 경고가 표시될 수 있습니다.

이 경고는 에이전트의 이전 버전이 Kubernetes용 에이전트 서버(`kas`)에 의해 캐시되어 발생할 수 있습니다. `kas`이(가) 주기적으로 오래된 에이전트 버전을 삭제하므로 에이전트와 GitLab을 조정하기 위해 최소 20분 이상 기다려야 합니다.

경고가 지속되면 클러스터에 설치된 에이전트를 업데이트합니다.

## Kubernetes API 프록시 응답 헤더가 손실되었거나 차단됨 {#kubernetes-api-proxy-response-headers-are-lost-or-blocked}

HTTP 응답 헤더는 Kubernetes 클러스터에서 Kubernetes API 프록시를 통해 사용자에게 전송될 때 차단될 수 있습니다.

이 오류는 응답 헤더가 KAS의 기본 허용 목록에 포함되지 않을 때 발생할 수 있습니다.

이 문제를 해결하는 방법에 대한 단계는 [차단된 응답 헤더](../../../administration/clusters/kas.md#error-blocked-kubernetes-api-proxy-response-header)를 참조하세요.
