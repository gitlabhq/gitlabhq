---
stage: Tenant Scale
group: Gitaly
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Gitaly 문제 해결
---

{{< details >}}

- 계층:  Free, Premium, Ultimate
- 제공:  GitLab Self-Managed

{{< /details >}}

다음 섹션에서는 Gitaly 오류에 대한 가능한 해결책을 제공합니다.

[Gitaly 시간 초과](../settings/gitaly_timeouts.md) 설정 및 [`gitaly/current` 파일 구문 분석](../logs/log_parsing.md#parsing-gitalycurrent)에 대한 조언도 참고하세요.

## 필수 요구 사항 {#prerequisites}

관리자 액세스 권한이 있어야 합니다.

## 독립 실행형 Gitaly 서버 사용 시 버전 확인 {#check-versions-when-using-standalone-gitaly-servers}

독립 실행형 Gitaly 서버를 사용하는 경우, 전체 호환성을 보장하기 위해 Gitaly 서버가 GitLab과 동일한 버전인지 확인해야 합니다:

1. 우측 상단 모서리에서 **운영자**를 선택하세요.
1. 왼쪽 사이드바에서 **개요** > **Gitaly 서버**를 선택합니다.
1. 모든 Gitaly 서버가 최신 버전임을 나타내는지 확인합니다.

## 스토리지 리소스 세부 정보 찾기 {#find-storage-resource-details}

[Rails 콘솔](../operations/rails_console.md#starting-a-rails-console-session)에서 다음 명령을 실행하여 Gitaly 스토리지에서 사용 가능한 공간과 사용된 공간을 확인할 수 있습니다:

```ruby
Gitlab::GitalyClient::ServerService.new("default").storage_disk_statistics
# For Gitaly Cluster (Praefect)
Gitlab::GitalyClient::ServerService.new("<storage name>").disk_statistics
```

## `gitaly-debug` 사용 {#use-gitaly-debug}

`gitaly-debug` 명령은 Gitaly 및 Git 성능을 위한 "프로덕션 디버깅" 도구를 제공합니다. Gitaly 성능 문제를 조사하는 데 도움이 되도록 프로덕션 엔지니어 및 지원 엔지니어를 돕기 위한 것입니다.

`gitaly-debug`의 도움말 페이지를 보고 지원되는 하위 명령 목록을 확인하려면 다음을 실행합니다:

```shell
gitaly-debug -h
```

## 문제 해결에 Git가 필요한 경우 `gitaly git` 사용 {#use-gitaly-git-when-git-is-required-for-troubleshooting}

디버깅 또는 테스트 목적으로 `gitaly git`을 사용하여 Gitaly와 동일한 Git 실행 환경을 사용하여 Git 명령을 실행합니다. `gitaly git`은 버전 호환성을 보장하기 위한 선호 방법입니다.

`gitaly git`은 모든 인수를 기본 Git 호출로 전달하고 Git이 지원하는 모든 형태의 입력을 지원합니다. `gitaly git`을 사용하려면 다음을 실행합니다:

```shell
sudo -u git -- /opt/gitlab/embedded/bin/gitaly git <git-command>
```

예를 들어 리포지토리의 작업 디렉터리에서 Linux 패키지 인스턴스의 Gitaly를 통해 `git ls-tree`을 실행하려면:

```shell
sudo -u git -- /opt/gitlab/embedded/bin/gitaly git ls-tree --name-status HEAD
```

## 커밋, 푸시 및 클론이 401을 반환합니다 {#commits-pushes-and-clones-return-a-401}

```plaintext
remote: GitLab: 401 Unauthorized
```

`gitlab-secrets.json` 파일을 GitLab 애플리케이션 노드와 동기화해야 합니다.

## 리포지토리 페이지에서 500 및 `fetching folder content` 오류 {#500-and-fetching-folder-content-errors-on-repository-pages}

`Fetching folder content`, 경우에 따라 `500` 오류는 GitLab과 Gitaly 간의 연결 문제를 나타냅니다. 세부 정보는 [클라이언트 측 gRPC 로그](#client-side-grpc-logs)를 참고하세요.

## 클라이언트 측 gRPC 로그 {#client-side-grpc-logs}

Gitaly는 [gRPC](https://grpc.io/) RPC 프레임워크를 사용합니다. Ruby gRPC 클라이언트에는 Gitaly 오류가 나타날 때 도움이 될 수 있는 정보가 포함된 자체 로그 파일이 있습니다. `GRPC_LOG_LEVEL` 환경 변수를 사용하여 gRPC 클라이언트의 로그 수준을 제어할 수 있습니다. 기본 수준은 `WARN`입니다.

다음을 사용하여 gRPC 추적을 실행할 수 있습니다:

```shell
sudo GRPC_TRACE=all GRPC_VERBOSITY=DEBUG gitlab-rake gitlab:gitaly:check
```

이 명령이 `failed to connect to all addresses` 오류로 실패하면 SSL 또는 TLS 문제가 있는지 확인하세요:

```shell
/opt/gitlab/embedded/bin/openssl s_client -connect <gitaly-ipaddress>:<port> -verify_return_error
```

`Verify return code` 필드에 [알려진 Linux 패키지 설치 구성 문제](https://docs.gitlab.com/omnibus/settings/ssl/)를 나타내는지 확인하세요.

`openssl`이 성공하지만 `gitlab-rake gitlab:gitaly:check`가 실패하면 Gitaly의 [인증서 요구 사항](tls_support.md#certificate-requirements)을 확인하세요.

## 서버 측 gRPC 로그 {#server-side-grpc-logs}

gRPC 추적은 `GODEBUG=http2debug` 환경 변수로 Gitaly 자체에서 활성화할 수 있습니다. Linux 패키지 설치에서 이를 설정하려면:

1. `gitlab.rb` 파일에 다음을 추가합니다:

   ```ruby
   gitaly['env'] = {
     "GODEBUG=http2debug" => "2"
   }
   ```

1. [GitLab 재구성](../restart_gitlab.md#reconfigure-a-linux-package-installation)합니다.

## Git 프로세스와 RPC 상호 연관 {#correlating-git-processes-with-rpcs}

Gitaly RPC가 특정 Git 프로세스를 생성했는지 알아내야 할 경우가 있습니다.

이를 수행하는 한 가지 방법은 `DEBUG` 로깅을 사용하는 것입니다. 그러나 미리 활성화해야 하며 생성되는 로그는 상세합니다.

이 상관 관계를 수행하는 간단한 방법은 Git 프로세스의 환경을 검사하여(해당 `PID` 사용) `CORRELATION_ID` 변수를 찾는 것입니다:

```shell
PID=<Git process ID>
sudo cat /proc/$PID/environ | tr '\0' '\n' | grep ^CORRELATION_ID=
```

이 방법은 Gitaly가 내부적으로 RPC 간에 `git cat-file` 프로세스를 풀링하고 재사용하기 때문에 신뢰할 수 없습니다.

## 리포지토리 변경이 `401 Unauthorized` 오류로 실패 {#repository-changes-fail-with-a-401-unauthorized-error}

Gitaly를 자체 서버에서 실행하고 다음 조건을 발견하는 경우:

- 사용자는 SSH와 HTTPS를 모두 사용하여 리포지토리를 성공적으로 클론하고 가져올 수 있습니다.
- 사용자는 리포지토리에 푸시할 수 없거나 웹 UI에서 변경하려고 할 때 `401 Unauthorized` 메시지를 받습니다.

Gitaly는 [잘못된 비밀 파일](configure_gitaly.md#configure-gitaly-servers)이 있기 때문에 Gitaly 클라이언트로 인증하지 못할 수 있습니다.

다음이 모두 참인지 확인합니다:

- 사용자가 이 Gitaly 서버의 리포지토리에 대해 `git push`을 수행하면 `401 Unauthorized` 오류로 실패합니다:

  ```shell
  remote: GitLab: 401 Unauthorized
  To <REMOTE_URL>
  ! [remote rejected] branch-name -> branch-name (pre-receive hook declined)
  error: failed to push some refs to '<REMOTE_URL>'
  ```

- 사용자가 GitLab UI를 사용하여 리포지토리의 파일을 추가하거나 수정할 때 빨간색 `401 Unauthorized` 배너로 즉시 실패합니다.
- 새 프로젝트를 만들고 [README로 초기화](../../user/project/_index.md#create-a-blank-project)하면 프로젝트는 성공적으로 만들어지지만 README는 생성되지 않습니다.
- Gitaly 클라이언트에서 [로그 추적](https://docs.gitlab.com/omnibus/settings/logs/#tail-logs-in-a-console-on-the-server)을 수행하고 오류를 재현할 때 `/api/v4/internal/allowed` 엔드포인트에 도달하면 `401` 오류를 받습니다:

  ```shell
  # api_json.log
  {
    "time": "2019-07-18T00:30:14.967Z",
    "severity": "INFO",
    "duration": 0.57,
    "db": 0,
    "view": 0.57,
    "status": 401,
    "method": "POST",
    "path": "\/api\/v4\/internal\/allowed",
    "params": [
      {
        "key": "action",
        "value": "git-receive-pack"
      },
      {
        "key": "changes",
        "value": "REDACTED"
      },
      {
        "key": "gl_repository",
        "value": "REDACTED"
      },
      {
        "key": "project",
        "value": "\/path\/to\/project.git"
      },
      {
        "key": "protocol",
        "value": "web"
      },
      {
        "key": "env",
        "value": "{\"GIT_ALTERNATE_OBJECT_DIRECTORIES\":[],\"GIT_ALTERNATE_OBJECT_DIRECTORIES_RELATIVE\":[],\"GIT_OBJECT_DIRECTORY\":null,\"GIT_OBJECT_DIRECTORY_RELATIVE\":null}"
      },
      {
        "key": "user_id",
        "value": "2"
      },
      {
        "key": "secret_token",
        "value": "[FILTERED]"
      }
    ],
    "host": "gitlab.example.com",
    "ip": "REDACTED",
    "ua": "Ruby",
    "route": "\/api\/:version\/internal\/allowed",
    "queue_duration": 4.24,
    "gitaly_calls": 0,
    "gitaly_duration": 0,
    "correlation_id": "XPUZqTukaP3"
  }

  # nginx_access.log
  [IP] - - [18/Jul/2019:00:30:14 +0000] "POST /api/v4/internal/allowed HTTP/1.1" 401 30 "" "Ruby"
  ```

이 문제를 해결하려면 Gitaly 서버의 [`gitlab-secrets.json` 파일](configure_gitaly.md#configure-gitaly-servers)이 Gitaly 클라이언트의 파일과 일치하는지 확인합니다. 일치하지 않으면 Gitaly 서버의 비밀 파일을 Gitaly 클라이언트와 일치하도록 업데이트한 후 [재구성](../restart_gitlab.md#reconfigure-a-linux-package-installation)합니다.

모든 Gitaly 서버 및 클라이언트에서 `gitlab-secrets.json` 파일이 동일함을 확인했다면 애플리케이션이 다른 파일에서 이 비밀을 가져올 수 있습니다. Gitaly 서버의 `config.toml file`는 사용 중인 비밀 파일을 나타냅니다.

## 리포지토리 푸시가 `401 Unauthorized` 및 `JWT::VerificationError`로 실패 {#repository-pushes-fail-with-401-unauthorized-and-jwtverificationerror}

`git push`을 시도할 때 다음을 볼 수 있습니다:

- `401 Unauthorized` 오류입니다.
- 서버 로그에 다음이 있습니다:

  ```json
  {
    ...
    "exception.class":"JWT::VerificationError",
    "exception.message":"Signature verification raised",
    ...
  }
  ```

이 오류 조합은 GitLab 서버가 GitLab 15.5 이상으로 업그레이드되었지만 Gitaly는 아직 업그레이드되지 않았을 때 발생합니다.

GitLab 15.5 이상 [공유 비밀 대신 JWT 토큰을 사용하여 GitLab Shell로 인증](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/86148)합니다. GitLab 서버를 업그레이드하기 전에 [외부 Gitaly 서버를 업그레이드](../../update/plan_your_upgrade.md#upgrades-for-optional-features)해야 합니다.

## 리포지토리 푸시가 `deny updating a hidden ref` 오류로 실패 {#repository-pushes-fail-with-a-deny-updating-a-hidden-ref-error}

Gitaly에는 사용자가 업데이트할 수 없는 읽기 전용 내부 GitLab 참조가 있습니다. `git push --mirror`을 사용하여 내부 참조를 업데이트하려고 하면 Git은 거부 오류 `deny updating a hidden ref`를 반환합니다.

다음 참조는 읽기 전용입니다:

- refs/environments/
- refs/keep-around/
- refs/merge-requests/
- refs/pipelines/

분기 및 태그만 미러 푸시하고 보호된 참조 미러 푸시를 시도하지 않으려면 다음을 실행합니다:

```shell
git push --force-with-lease origin 'refs/heads/*:refs/heads/*' 'refs/tags/*:refs/tags/*'
```

관리자가 푸시하려는 다른 네임스페이스는 추가 [refspecs](https://git-scm.com/docs/git-push#_options)를 통해 포함될 수 있습니다.

## 명령줄 도구가 Gitaly에 연결할 수 없음 {#command-line-tools-cannot-connect-to-gitaly}

다음 경우 gRPC가 Gitaly 서버에 도달할 수 없습니다:

- 명령줄 도구로 Gitaly 서버에 연결할 수 없습니다.
- 특정 작업으로 `14: Connect Failed` 오류 메시지가 나타납니다.

TCP를 사용하여 Gitaly에 도달할 수 있는지 확인합니다:

```shell
sudo gitlab-rake gitlab:tcp_check[GITALY_SERVER_IP,GITALY_LISTEN_PORT]
```

TCP 연결이:

- 실패하면 네트워크 설정 및 방화벽 규칙을 확인합니다.
- 성공하면 네트워킹 및 방화벽 규칙이 올바릅니다.

Bash와 같은 명령줄 환경에서 프록시 서버를 사용하는 경우 gRPC 트래픽에 방해가 될 수 있습니다.

Bash 또는 호환되는 명령줄 환경을 사용하는 경우 다음 명령을 실행하여 프록시 서버가 구성되어 있는지 확인합니다:

```shell
echo $http_proxy
echo $https_proxy
```

이러한 변수 중 하나라도 값을 가지면 Gitaly CLI 연결이 Gitaly에 연결할 수 없는 프록시를 통해 라우팅될 수 있습니다.

프록시 설정을 제거하려면 다음 명령을 실행합니다(어느 변수에 값이 있었는지에 따라):

```shell
unset http_proxy
unset https_proxy
```

## 리포지토리에 액세스할 때 Gitaly 또는 Praefect 로그에 나타나는 권한 거부 오류 {#permission-denied-errors-appearing-in-gitaly-or-praefect-logs-when-accessing-repositories}

Gitaly 및 Praefect 로그에서 다음을 볼 수 있습니다:

```shell
{
  ...
  "error":"rpc error: code = PermissionDenied desc = permission denied: token has expired",
  "grpc.code":"PermissionDenied",
  "grpc.meta.client_name":"gitlab-web",
  "grpc.request.fullMethod":"/gitaly.ServerService/ServerInfo",
  "level":"warning",
  "msg":"finished unary call with code PermissionDenied",
  ...
}
```

로그의 이 정보는 gRPC 호출 [오류 응답 코드](https://grpc.github.io/grpc/core/md_doc_statuscodes.html)입니다.

이 오류가 발생하더라도 [Gitaly 인증 토큰이 올바르게 설정](praefect/troubleshooting.md#praefect-errors-in-logs) 되어 있으면 Gitaly 서버가 [클록 드리프트](https://en.wikipedia.org/wiki/Clock_drift)를 경험할 가능성이 높습니다. Gitaly로 전송되는 인증 토큰에는 타임스탐프가 포함됩니다. 유효하다고 간주되려면 Gitaly는 해당 타임스탐프가 Gitaly 서버 시간의 60초 이내여야 합니다.

Gitaly 클라이언트 및 서버가 동기화되어 있는지 확인하고 NTP(네트워크 시간 프로토콜) 시간 서버를 사용하여 동기화 상태를 유지합니다.

## 재구성 후 Gitaly가 새 주소를 수신 대기하지 않음 {#gitaly-not-listening-on-new-address-after-reconfiguring}

`gitaly['configuration'][:listen_addr]` 또는 `gitaly['configuration'][:prometheus_listen_addr]` 값을 업데이트할 때 `sudo gitlab-ctl reconfigure` 후 Gitaly가 이전 주소에서 계속 수신 대기할 수 있습니다.

이 문제가 발생하면 `sudo gitlab-ctl restart`을 실행하여 문제를 해결합니다. [이 문제](https://gitlab.com/gitlab-org/gitaly/-/issues/2521)가 해결되었기 때문에 더 이상 필요하지 않아야 합니다.

## 상태 확인 경고 {#health-check-warnings}

`/var/log/gitlab/praefect/current`의 다음 경고는 무시할 수 있습니다.

```plaintext
"error":"full method name not found: /grpc.health.v1.Health/Check",
"msg":"error when looking up method info"
```

## 파일을 찾을 수 없음 오류 {#file-not-found-errors}

`/var/log/gitlab/gitaly/current`의 다음 오류는 무시할 수 있습니다. 이는 GitLab Rails 애플리케이션이 리포지토리에 없는 특정 파일을 확인하기 때문에 발생합니다.

```plaintext
"error":"not found: .gitlab/route-map.yml"
"error":"not found: Dockerfile"
"error":"not found: .gitlab-ci.yml"
```

## Dynatrace가 활성화되어 있을 때 Git 푸시가 느림 {#git-pushes-are-slow-when-dynatrace-is-enabled}

Dynatrace는 `sudo -u git -- /opt/gitlab/embedded/bin/gitaly-hooks` 참조 트랜잭션 후크가 시작 및 종료에 몇 초가 걸리도록 할 수 있습니다. `gitaly-hooks`는 사용자가 푸시할 때 두 번 실행되어 상당한 지연을 야기합니다.

Dynatrace는 `.so` 파일을 동적으로 로드하여 이진 파일을 계측하는 것으로 보이며, 이는 수명이 짧은 `gitaly-hooks` 프로세스의 성능 저하에 기여합니다.

Dynatrace가 활성화되어 있을 때 Git 푸시가 너무 느리면 Dynatrace를 비활성화합니다. `.so` 파일이 로드되는 것을 방지하기 위해 Gitaly가 실행 중인 시스템에서 Dynatrace를 완전히 제거해야 할 수 있습니다.

## `gitaly check`이 `401` 상태 코드로 실패합니다 {#gitaly-check-fails-with-401-status-code}

`gitaly check`은 Gitaly가 내부 GitLab API에 액세스할 수 없는 경우 `401` 상태 코드로 실패할 수 있습니다.

이 문제를 해결하는 한 가지 방법은 `gitlab.rb`에서 구성된 GitLab 내부 API URL 항목이 `gitlab_rails['internal_api_url']`에 맞게 올바른지 확인하는 것입니다.

## Gitaly TLS를 사용할 때 새 머지 리퀘스트에 대한 변경 사항(diffs)이 로드되지 않음 {#changes-diffs-dont-load-for-new-merge-requests-when-using-gitaly-tls}

[Gitaly with TLS](tls_support.md) 사용을 활성화한 후 새 머지 리퀘스트에 대한 변경 사항(diffs)이 생성되지 않으며 GitLab에 다음 메시지가 표시됩니다:

```plaintext
Building your merge request... This page will update when the build is complete
```

Gitaly는 일부 작업을 완료하기 위해 자신에 연결할 수 있어야 합니다. Gitaly 인증서가 Gitaly 서버에서 신뢰되지 않으면 머지 리퀘스트 diff를 생성할 수 없습니다.

Gitaly가 자신에 연결할 수 없으면 [Gitaly 로그](../logs/_index.md#gitaly-logs)에서 다음 메시지와 같은 메시지를 볼 수 있습니다:

```json
{
   "level":"warning",
   "msg":"[core] [Channel #16 SubChannel #17] grpc: addrConn.createTransport failed to connect to {Addr: \"ext-gitaly.example.com:9999\", ServerName: \"ext-gitaly.example.com:9999\", }. Err: connection error: desc = \"transport: authentication handshake failed: tls: failed to verify certificate: x509: certificate signed by unknown authority\"",
   "pid":820,
   "system":"system",
   "time":"2023-11-06T05:40:04.169Z"
}
{
   "level":"info",
   "msg":"[core] [Server #3] grpc: Server.Serve failed to create ServerTransport: connection error: desc = \"ServerHandshake(\\\"x.x.x.x:x\\\") failed: wrapped server handshake: remote error: tls: bad certificate\"",
   "pid":820,
   "system":"system",
   "time":"2023-11-06T05:40:04.169Z"
}
```

이 문제를 해결하려면 Gitaly 인증서를 Gitaly 서버의 `/etc/gitlab/trusted-certs` 폴더에 추가했는지 확인하고:

1. 인증서가 [심링크되도록 GitLab 재구성](../restart_gitlab.md#reconfigure-a-linux-package-installation)합니다
1. 인증서가 Gitaly 프로세스에 로드되도록 `sudo gitlab-ctl restart gitaly`을 사용하여 Gitaly를 수동으로 다시 시작합니다.

## Gitaly가 `noexec` 파일 시스템에 저장된 프로세스를 포크하지 못함 {#gitaly-fails-to-fork-processes-stored-on-noexec-file-systems}

`noexec` 옵션을 마운트 지점(예: `/var`)에 적용하면 Gitaly가 프로세스 포킹과 관련된 `permission denied` 오류를 throw합니다. 예를 들어:

```shell
fork/exec /var/opt/gitlab/gitaly/run/gitaly-2057/gitaly-git2go: permission denied
```

이를 해결하려면 파일 시스템 마운트에서 `noexec` 옵션을 제거합니다. 또는 Gitaly 런타임 디렉터리를 변경할 수 있습니다:

1. `/etc/gitlab/gitlab.rb`에 `gitaly['runtime_dir'] = '<PATH_WITH_EXEC_PERM>'`을 추가하고 `noexec`가 설정되지 않은 위치를 지정합니다.
1. `sudo gitlab-ctl reconfigure`을 실행합니다.

## 커밋 서명이 `invalid argument` 또는 `invalid data`로 실패 {#commit-signing-fails-with-invalid-argument-or-invalid-data}

커밋 서명이 다음 오류 중 하나로 실패하면:

- `invalid argument: signing key is encrypted`
- `invalid data: tag byte does not have MSB set`

이 오류는 Gitaly 커밋 서명이 헤드리스이고 특정 사용자와 연결되지 않아 발생합니다. GPG 서명 키는 암호 없이 생성하거나 내보내기 전에 암호를 제거해야 합니다.

## Gitaly 로그는 `info` 메시지에 오류를 표시합니다 {#gitaly-logs-show-errors-in-info-messages}

GitLab 16.3에서 [도입된](https://gitlab.com/gitlab-org/gitaly/-/merge_requests/6201) 버그 때문에 추가 항목이 [Gitaly 로그](../logs/_index.md#gitaly-logs)에 기록되었습니다. 이러한 로그 항목에는 `"level":"info"`이 포함되었지만 `msg` 문자열이 오류를 포함하는 것으로 나타났습니다.

예를 들어:

```json
{"level":"info","msg":"[core] [Server #3] grpc: Server.Serve failed to create ServerTransport: connection error: desc = \"ServerHandshake(\\\"x.x.x.x:x\\\") failed: wrapped server handshake: EOF\"","pid":6145,"system":"system","time":"2023-12-14T21:20:39.999Z"}
```

이 로그 항목의 이유는 기본 gRPC 라이브러리가 때때로 상세한 전송 로그를 출력하기 때문입니다. 이러한 로그 항목은 오류로 보이지만 일반적으로 무시해도 안전합니다.

이 버그는 GitLab 16.4.5, 16.5.5 및 16.6.0에서 [수정](https://gitlab.com/gitlab-org/gitaly/-/merge_requests/6513/)되었으며, 이러한 유형의 메시지가 Gitaly 로그에 기록되는 것을 방지합니다.

## Gitaly 프로파일링 {#profiling-gitaly}

Gitaly는 Prometheus 수신 대기 포트에서 여러 Go 기본 제공 성능 프로파일링 도구를 노출합니다. 예를 들어 Prometheus가 GitLab 서버의 포트 `9236`에서 수신 대기하고 있는 경우:

- 실행 중인 `goroutines` 및 해당 역추적 목록을 가져옵니다:

  ```shell
  curl --output goroutines.txt "http://<gitaly_server>:9236/debug/pprof/goroutine?debug=2"
  ```

- 30초 동안 CPU 프로필을 실행합니다:

  ```shell
  curl --output cpu.bin "http://<gitaly_server>:9236/debug/pprof/profile"
  ```

- 힙 메모리 사용을 프로파일합니다:

  ```shell
  curl --output heap.bin "http://<gitaly_server>:9236/debug/pprof/heap"
  ```

- 5초 실행 추적을 기록합니다. 이는 실행 중인 Gitaly 성능에 영향을 미칩니다:

  ```shell
  curl --output trace.bin "http://<gitaly_server>:9236/debug/pprof/trace?seconds=5"
  ```

`go`이 설치된 호스트에서 CPU 프로필 및 힙 프로필을 브라우저에서 볼 수 있습니다:

```shell
go tool pprof -http=:8001 cpu.bin
go tool pprof -http=:8001 heap.bin
```

실행 추적은 다음을 실행하여 볼 수 있습니다:

```shell
go tool trace heap.bin
```

### 프로필 Git 작업 {#profile-git-operations}

{{< history >}}

- `log_git_traces`라는 이름의 [플래그와 함께](../feature_flags/_index.md) [GitLab 16.9에서 도입됨](https://gitlab.com/gitlab-org/gitaly/-/issues/5700). 기본적으로 비활성화됨.

{{< /history >}}

> [!flag]
> GitLab Self-Managed에서는 기본적으로 이 기능을 사용할 수 없습니다. 사용 가능하게 하려면 관리자가 `log_git_traces` 이름의 [기능 플래그를 활성화](../feature_flags/_index.md)할 수 있습니다. GitLab.com에서는 이 기능을 사용할 수 있지만 GitLab.com 관리자만 구성할 수 있습니다. GitLab Dedicated에서는 이 기능을 사용할 수 없습니다.

Gitaly가 수행하는 Git 작업을 프로파일링할 수 있으며 Gitaly 로그에 Git 작업에 대한 추가 정보를 보냅니다. 이 정보를 통해 사용자는 성능 최적화, 디버깅 및 일반 원격 분석 수집에 대한 더 많은 통찰력을 얻을 수 있습니다. 자세한 내용은 [Git Trace2 API 참조](https://git-scm.com/docs/api-trace2)를 참고하세요.

시스템 과부하를 방지하기 위해 추가 정보 로깅은 속도 제한됩니다. 속도 제한을 초과하면 추적이 건너뜁니다. 그러나 속도 제한이 정상 상태로 돌아간 후에는 추적이 자동으로 다시 처리됩니다. 속도 제한은 시스템이 안정적으로 유지되도록 하고 과도한 추적 처리로 인한 부작용을 방지합니다.

## GitLab 복원 후 리포지토리가 비어 있는 것으로 표시됨 {#repositories-are-shown-as-empty-after-a-gitlab-restore}

보안 강화를 위해 `fapolicyd`를 사용하는 경우 GitLab은 GitLab 백업 파일에서의 복원이 성공했다고 보고할 수 있지만:

- 리포지토리가 비어 있는 것으로 표시됩니다.
- 새 파일을 만들면 다음과 유사한 오류가 발생합니다:

  ```plaintext
  13:commit: commit: starting process [/var/opt/gitlab/gitaly/run/gitaly-5428/gitaly-git2go -log-format json -log-level -correlation-id
  01GP1383JV6JD6MQJBH2E1RT03 -enabled-feature-flags -disabled-feature-flags commit]: fork/exec /var/opt/gitlab/gitaly/run/gitaly-5428/gitaly-git2go: operation not permitted.
  ```

- Gitaly 로그에는 다음과 유사한 오류가 포함될 수 있습니다:

  ```plaintext
   "error": "exit status 128, stderr: \"fatal: cannot exec '/var/opt/gitlab/gitaly/run/gitaly-5428/hooks-1277154941.d/reference-transaction':

    Operation not permitted\\nfatal: cannot exec '/var/opt/gitlab/gitaly/run/gitaly-5428/hooks-1277154941.d/reference-transaction': Operation
    not permitted\\nfatal: ref updates aborted by hook\\n\"",
   "grpc.code": "Internal",
   "grpc.meta.deadline_type": "none",
   "grpc.meta.method_type": "client_stream",
   "grpc.method": "FetchBundle",
   "grpc.request.fullMethod": "/gitaly.RepositoryService/FetchBundle",
  ...
  ```

[디버그 모드](https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/8/html/security_hardening/assembly_blocking-and-allowing-applications-using-fapolicyd_security-hardening#ref_troubleshooting-problems-related-to-fapolicyd_assembly_blocking-and-allowing-applications-using-fapolicyd)를 사용하면 `fapolicyd`가 현재 규칙에 따라 실행을 거부하는지 확인할 수 있습니다.

`fapolicyd`이 실행을 거부하는 경우 다음을 고려합니다:

1. `/var/opt/gitlab/gitaly`의 모든 실행 파일을 `fapolicyd` 구성에서 허용합니다:

   ```plaintext
   allow perm=any all : ftype=application/x-executable dir=/var/opt/gitlab/gitaly/
   ```

1. 서비스를 다시 시작합니다:

   ```shell
   sudo systemctl restart fapolicyd

   sudo gitlab-ctl restart gitaly
   ```

## `Pre-receive hook declined` 오류(RHEL 인스턴스에 `fapolicyd` 활성화됨) {#pre-receive-hook-declined-error-when-pushing-to-rhel-instance-with-fapolicyd-enabled}

`fapolicyd`이 활성화된 RHEL 기반 인스턴스로 푸시할 때 `Pre-receive hook declined` 오류를 받을 수 있습니다. 이 오류는 `fapolicyd`이 Gitaly 이진 파일의 실행을 차단할 수 있기 때문에 발생할 수 있습니다. 이 문제를 해결하려면 다음 중 하나를 수행합니다:

- `fapolicyd`을 비활성화합니다.
- `fapolicyd`이 활성화된 상태에서 Gitaly 이진 파일 실행을 허용하는 `fapolicyd` 규칙을 만듭니다.

Gitaly 이진 파일 실행을 허용하는 규칙을 만들려면:

1. `/etc/fapolicyd/rules.d/89-gitlab.rules`에 파일을 만듭니다.
1. 파일에 다음을 입력합니다:

   ```plaintext
   allow perm=any all : ftype=application/x-executable dir=/var/opt/gitlab/gitaly/
   ```

1. 서비스를 다시 시작합니다:

   ```shell
   systemctl restart fapolicyd
   ```

새 규칙은 디먼이 다시 시작된 후에 적용됩니다.

## 중복 경로가 있는 스토리지를 제거한 후 리포지토리 업데이트 {#update-repositories-after-removing-a-storage-with-a-duplicate-path}

{{< history >}}

- Rake 작업 `gitlab:gitaly:update_removed_storage_projects` [GitLab 17.1에서 도입](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/153008)됨.

{{< /history >}}

GitLab 17.0에서 중복 경로가 있는 스토리지를 구성하기 위한 지원 [제거](https://gitlab.com/gitlab-org/gitaly/-/issues/5598)되었습니다. 이는 `gitaly` 구성에서 중복 스토리지 구성을 제거해야 함을 의미할 수 있습니다.

> [!warning]
> 이 Rake 작업은 이전 스토리지와 새 스토리지가 동일한 Gitaly 서버에서 동일한 디스크 경로를 공유할 때만 사용합니다. 이 Rake 작업을 다른 상황에서 사용하면 리포지토리를 사용할 수 없게 됩니다. 다른 모든 상황에서 스토리지 간 리포지토리를 전송하려면 [프로젝트 리포지토리 스토리지 이동 API](../../api/project_repository_storage_moves.md)를 사용합니다.

Gitaly 구성에서 다른 스토리지와 동일한 경로를 사용한 스토리지를 제거할 때 이전 스토리지와 연결된 프로젝트를 새 스토리지에 다시 할당해야 합니다.

예를 들어 다음과 유사한 구성이 있을 수 있습니다:

```ruby
gitaly['configuration'] = {
  storage: [
    {
       name: 'default',
       path: '/var/opt/gitlab/git-data/repositories',
    },
    {
       name: 'duplicate-path',
       path: '/var/opt/gitlab/git-data/repositories',
    },
  ],
}
```

`duplicate-path`을 구성에서 제거하는 경우 다음 Rake 작업을 실행하여 이를 할당하는 모든 프로젝트를 `default`에 대신 연결합니다:

{{< tabs >}}

{{< tab title="Linux 패키지 설치" >}}

```shell
sudo gitlab-rake "gitlab:gitaly:update_removed_storage_projects[duplicate-path, default]"
```

{{< /tab >}}

{{< tab title="자체 컴파일 설치" >}}

```shell
sudo -u git -H bundle exec rake "gitlab:gitaly:update_removed_storage_projects[duplicate-path, default]" RAILS_ENV=production
```

{{< /tab >}}

{{< /tabs >}}

## 오류: ZIP 파일로 리포지토리 다운로드 시 `fatal: deflate error (0)\n` {#error-fatal-deflate-error-0n-when-downloading-repository-as-zip-file}

Git 버전 2.51에서 수정된 Git 버그([문제 575](https://gitlab.com/gitlab-org/git/-/issues/575))로 인해 경우에 따라 리포지토리를 ZIP 아카이브로 다운로드하면 불완전한 ZIP 파일이 나타납니다. 이 경우 Gitaly 로그에 다음 오류가 표시됩니다:

```plaintext
  "msg": "fatal: deflate error (0)\n",
```

이 문제를 해결하려면 Git의 고정 버전을 사용하는 GitLab 및 Gitaly 버전으로 업그레이드합니다. 업그레이드할 수 없는 경우 다음 단계를 사용하여 문제를 해결합니다:

{{< tabs >}}

{{< tab title="Linux 패키지 설치" >}}

1. [`git-sizer`](https://github.com/github/git-sizer#getting-started)를 사용하여 blob 크기를 확인합니다.
1. `core.bigFileThreshold`을 가장 큰 blob의 크기보다 크게 구성합니다(기본값은 `50m`):

   ```ruby
     gitaly['configuration'] = {
      # ... your existing configuration ...
      git: {
        config: [
          # ... any existing git config entries ...
          {
            key: 'core.bigFileThreshold',
            value: '500m'
          }
        ]
      }
    }
   ```

1. `gitlab-ctl reconfigure`을 실행합니다.

{{< /tab >}}

{{< tab title="Helm 차트(Kubernetes)" >}}

1. [`git-sizer`](https://github.com/github/git-sizer#getting-started)를 사용하여 blob 크기를 확인합니다.
1. `values.yml` 파일에서 `core.bigFileThreshold`을 구성합니다:

   ```yaml
   git:
     config:
       - key: "core.bigFileThreshold"
         value: "500m"
   ```

1. 구성을 업데이트하려면 `helm upgrade <gitlab_release> gitlab/gitlab -f values.yaml`을 실행합니다.

{{< /tab >}}

{{< tab title="자체 컴파일 설치" >}}

1. [`git-sizer`](https://github.com/github/git-sizer#getting-started)를 사용하여 blob 크기를 확인합니다.
1. `/home/git/gitaly/config.toml`에서 `core.bigFileThreshold`을 구성합니다:

   ```toml
   # [[git.config]]
   # key = core.bigFileThreshold
   # value = 500m
   ```

{{< /tab >}}

{{< /tabs >}}
