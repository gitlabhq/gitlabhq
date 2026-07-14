---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Git 문제 해결
description: 일반적인 Git 오류 및 연결 문제를 해결하세요.
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Git을 사용할 때 예상과 달리 작동하지 않는 경우가 있습니다. 다음은 Git 문제를 해결하고 오류를 해결하기 위한 팁입니다.

## 디버깅 {#debugging}

GitLab 서버에서 Git 문제를 디버깅할 때는 시스템에서 제공하는 `git` 바이너리 대신 `/opt/gitlab/embedded/bin/git`을 사용합니다. 시스템 바이너리가 더 오래될 수 있습니다.

### Git 명령에 사용자 지정 SSH 키 사용 {#use-a-custom-ssh-key-for-a-git-command}

```shell
GIT_SSH_COMMAND="ssh -i ~/.ssh/gitlabadmin" git <command>
```

`<command>`을 실행하려는 Git 명령으로 바꿉니다.

### SSH를 통해 Git 디버깅 {#debug-git-over-ssh}

```shell
GIT_SSH_COMMAND="ssh -vvv" git clone <git@url> 2>&1 \
| tee /tmp/gitlab-clone-test.log
```

`<git@url>`을 리포지토리의 SSH URL로 바꿉니다. 출력은 `/tmp/gitlab-clone-test.log`에 저장됩니다.

### HTTPS를 통해 Git 디버깅 {#debug-git-over-https}

```shell
GIT_TRACE_PACKET=1 GIT_TRACE=2 GIT_CURL_VERBOSE=1 git clone <url> 2>&1 \
| tee /tmp/gitlab-clone-test.log
```

`<url>`을 리포지토리의 HTTPS URL로 바꿉니다. 출력은 `/tmp/gitlab-clone-test.log`에 저장됩니다.

### 추적을 사용하여 Git 디버깅 {#debug-git-with-traces}

Git에는 [Git 명령 디버깅을 위한 추적](https://git-scm.com/book/en/v2/Git-Internals-Environment-Variables#_debugging) 기능이 완벽하게 포함되어 있습니다. 예를 들어:

- `GIT_TRACE_PERFORMANCE=1`: 성능 데이터 추적을 활성화하여 각 `git` 호출이 얼마나 오래 걸리는지 보여줍니다.
- `GIT_TRACE_SETUP=1`: `git`이 리포지토리 및 상호 작용하는 환경에 대해 발견하는 항목의 추적을 활성화합니다.
- `GIT_TRACE_PACKET=1`: 네트워크 작업에 대한 패킷 수준 추적을 활성화합니다.
- `GIT_CURL_VERBOSE=1`: `curl`의 자세한 출력을 활성화합니다. 이는 [자격 증명을 포함할 수 있습니다](https://curl.se/docs/manpage.html#-v).

## `Broken pipe` 오류 `git push` {#broken-pipe-errors-on-git-push}

`Broken pipe` 오류는 원격 리포지토리에 푸시하려고 할 때 발생할 수 있습니다. 푸시할 때 일반적으로 다음과 같이 표시됩니다.

```plaintext
Write failed: Broken pipe
fatal: The remote end hung up unexpectedly
```

이 문제를 해결하기 위한 몇 가지 가능한 해결 방법이 있습니다.

### Git에서 POST 버퍼 크기 증가 {#increase-the-post-buffer-size-in-git}

HTTPS를 통해 Git으로 대규모 리포지토리를 푸시하려고 할 때 다음과 같은 오류 메시지가 나타날 수 있습니다.

```shell
fatal: pack has bad object at offset XXXXXXXXX: inflate returned -5
```

이 이슈를 해결하려면:

- 로컬 Git 구성에서 [http.postBuffer](https://git-scm.com/docs/git-config#Documentation/git-config.txt-httppostBuffer) 값을 증가시킵니다. 기본값은 1MB입니다. 예를 들어 500MB 리포지토리를 복제할 때 `git clone`이 실패하면 다음을 실행합니다.

  1. 터미널 또는 명령 프롬프트를 엽니다.
  1. `http.postBuffer` 값을 증가시킵니다.

     ```shell
     # Set the http.postBuffer size in bytes
     git config http.postBuffer 524288000
     ```

로컬 구성으로 문제가 해결되지 않으면 서버 구성을 수정해야 할 수도 있습니다. 이는 신중하게 수행해야 하며 서버 액세스 권한이 있는 경우에만 수행합니다.

- 서버 측에서 `http.postBuffer`을 증가시킵니다.

  1. 터미널 또는 명령 프롬프트를 엽니다.
  1. GitLab 인스턴스의 [`gitlab.rb`](https://gitlab.com/gitlab-org/omnibus-gitlab/-/blob/13.5.1+ee.0/files/gitlab-config-template/gitlab.rb.template#L1435-1455) 파일을 수정합니다.

     ```ruby
     gitaly['configuration'] = {
       # ...
       git: {
         # ...
         config: [
           # Set the http.postBuffer size, in bytes
           {key: "http.postBuffer", value: "524288000"},
         ],
       },
     }
     ```

  1. 구성 변경을 적용합니다.

     ```shell
     sudo gitlab-ctl reconfigure
     ```

### 오류: `stream 0 was not closed cleanly` {#error-stream-0-was-not-closed-cleanly}

이 오류가 표시되면 느린 인터넷 연결로 인해 발생했을 수 있습니다.

```plaintext
RPC failed; curl 92 HTTP/2 stream 0 was not closed cleanly: INTERNAL_ERROR (err 2)
```

SSH 대신 HTTP를 통해 Git을 사용하는 경우 다음 해결 방법 중 하나를 시도하세요:

- Git 구성에서 POST 버퍼 크기를 `git config http.postBuffer 52428800`로 증가시킵니다.
- `HTTP/1.1` 프로토콜로 전환하려면 `git config http.version HTTP/1.1`을 사용합니다.

두 가지 접근 방식 모두 오류를 해결하지 못하면 다른 인터넷 서비스 제공자가 필요할 수 있습니다.

### SSH 구성 확인 {#check-your-ssh-configuration}

SSH를 통해 푸시하는 경우 먼저 SSH 구성을 확인합니다. 'Broken pipe' 오류는 SSH의 기본 문제(예: 인증)로 인해 발생할 수 있습니다. [SSH 문제 해결](../../user/ssh_troubleshooting.md#password-prompt-with-git-clone) 설명서의 지침을 따라 SSH가 올바르게 구성되어 있는지 확인합니다.

GitLab 관리자이고 서버 액세스 권한이 있으면 클라이언트 또는 서버에서 SSH `keep-alive`을 구성하여 세션 시간 초과를 방지할 수 있습니다.

> [!note]
> 클라이언트와 서버를 모두 구성할 필요는 없습니다.

클라이언트 측에서 SSH를 구성하려면:

- UNIX에서 `~/.ssh/config`을 편집(파일이 없으면 생성)하고 다음을 추가하거나 편집합니다.

  ```plaintext
  Host your-gitlab-instance-url.com
    ServerAliveInterval 60
    ServerAliveCountMax 5
  ```

- Windows에서 PuTTY를 사용하는 경우 세션 속성으로 이동한 다음 **연결**으로 이동하고 **Sending of null packets to keep session active** 아래에서 `Seconds between keepalives (0 to turn off)`을 `60`로 설정합니다.

서버 측에서 SSH를 구성하려면 `/etc/ssh/sshd_config`을 편집하고 다음을 추가합니다.

```plaintext
ClientAliveInterval 60
ClientAliveCountMax 5
```

### `git repack` 실행 {#running-a-git-repack}

'pack-objects' 유형의 오류도 표시되면 원격 리포지토리에 다시 푸시하기 전에 `git repack`을 실행해 볼 수 있습니다.

```shell
git repack
git push
```

### Git 클라이언트 업그레이드 {#upgrade-your-git-client}

Git의 이전 버전(2.9 미만)을 실행 중인 경우 2.9 이상으로 업그레이드를 고려하세요. 자세한 내용은 [Git 리포지토리로 푸시할 때 손상된 파이프](https://stackoverflow.com/questions/19120120/broken-pipe-when-pushing-to-git-repository/36971469#36971469)를 참조하세요.

## `ssh_exchange_identification` 오류 {#ssh_exchange_identification-error}

사용자는 SSH를 통해 Git을 사용하여 푸시 또는 풀을 시도할 때 다음 오류를 경험할 수 있습니다.

```plaintext
Please make sure you have the correct access rights
and the repository exists.
...
ssh_exchange_identification: read: Connection reset by peer
fatal: Could not read from remote repository.
```

또는

```plaintext
ssh_exchange_identification: Connection closed by remote host
fatal: The remote end hung up unexpectedly
```

또는

```plaintext
kex_exchange_identification: Connection closed by remote host
Connection closed by x.x.x.x port 22
```

이 오류는 일반적으로 SSH 데몬의 `MaxStartups` 값이 SSH 연결을 제한하고 있음을 나타냅니다. 이 설정은 SSH 데몬에 대한 최대 동시 인증되지 않은 연결 수를 지정합니다. 이는 적절한 인증 자격 증명(SSH 키)을 가진 사용자에게 영향을 미칩니다. 모든 연결이 처음에는 '인증되지 않은' 상태이기 때문입니다. [기본값](https://man.openbsd.org/sshd_config#MaxStartups)은 `10`입니다.

호스트의 [`sshd`](https://en.wikibooks.org/wiki/OpenSSH/Logging_and_Troubleshooting#Server_Logs) 로그를 검토하여 확인할 수 있습니다. Debian 계열 시스템의 경우 `/var/log/auth.log`을 참조하고 RHEL 계열의 경우 다음 오류에 대해 `/var/log/secure`을 확인합니다.

```plaintext
sshd[17242]: error: beginning MaxStartups throttling
sshd[17242]: drop connection #1 from [CLIENT_IP]:52114 on [CLIENT_IP]:22 past MaxStartups
```

이 오류가 없으면 SSH 데몬이 연결을 제한하지 않고 있음을 의미하며, 이는 기본 문제가 네트워크 관련일 수 있음을 나타냅니다.

### 인증되지 않은 동시 SSH 연결 수 증가 {#increase-the-number-of-unauthenticated-concurrent-ssh-connections}

GitLab 서버에서 `MaxStartups`을 증가시키려면 `/etc/ssh/sshd_config`의 값을 추가하거나 수정합니다.

```plaintext
MaxStartups 100:30:200
```

`100:30:200`은 최대 100개의 SSH 세션이 제한 없이 허용되고, 그 이후 절대 최대값인 200에 도달할 때까지 30%의 연결이 삭제됨을 의미합니다.

`MaxStartups`의 값을 수정한 후 구성에 오류가 있는지 확인합니다.

```shell
sudo sshd -t -f /etc/ssh/sshd_config
```

구성 확인이 오류 없이 실행되면 변경 사항을 적용하기 위해 SSH 데몬을 다시 시작하는 것이 안전합니다.

```shell
# Debian/Ubuntu
sudo systemctl restart ssh

# CentOS/RHEL
sudo service sshd restart
```

## `git push`/`git pull` 중 시간 초과 {#timeout-during-git-push--git-pull}

리포지토리에서 풀링/푸싱에 50초 이상 걸리면 시간 초과가 발생합니다. 수행된 작업의 수와 각 작업의 시간을 기록하며, 아래 예와 같습니다.

```plaintext
remote: Running checks for branch: master
remote: Scanning for LFS objects... (153ms)
remote: Calculating new repository size... (canceled after 729ms)
```

이를 통해 어느 작업이 성능이 떨어지는지 더 자세히 조사하고 서비스 개선 방법에 대한 더 많은 정보를 GitLab에 제공할 수 있습니다.

### 오류: `Operation timed out` {#error-operation-timed-out}

Git을 사용할 때 이와 같은 오류가 발생하면 일반적으로 네트워크 문제를 나타냅니다.

```shell
ssh: connect to host gitlab.com port 22: Operation timed out
fatal: Could not read from remote repository
```

기본 문제를 파악하는 데 도움이 됩니다.

- 다른 네트워크를 통해 연결합니다(예: Wi-Fi에서 셀룰러 데이터로 전환). 로컬 네트워크 또는 방화벽 문제를 배제합니다.
- 이 bash 명령을 실행하여 `traceroute` 및 `ping` 정보를 수집합니다. `mtr -T -P 22 <gitlab_server>.com` MTR 및 출력을 읽는 방법에 대해 알아보려면 Cloudflare의 [My Traceroute (MTR)](https://www.cloudflare.com/en-gb/learning/network-layer/what-is-mtr/) 문서를 참조하세요.

## 오류: `transfer closed with outstanding read data remaining` {#error-transfer-closed-with-outstanding-read-data-remaining}

때때로 오래되었거나 규모가 큰 리포지토리를 복제할 때 HTTP를 통해 `git clone`을 실행할 때 다음 오류가 표시됩니다.

```plaintext
error: RPC failed; curl 18 transfer closed with outstanding read data remaining
fatal: The remote end hung up unexpectedly
fatal: early EOF
fatal: index-pack failed
```

이 문제는 Git 자체에서 많은 파일이나 많은 양의 파일을 처리하지 못하기 때문에 일반적입니다. [Git LFS](https://about.gitlab.com/blog/getting-started-with-git-lfs-tutorial/)는 이 문제를 해결하기 위해 만들어졌습니다. 다만 제한 사항이 있습니다. 일반적으로 다음 중 하나의 이유로 인해 발생합니다.

- 리포지토리의 파일 수입니다.
- 히스토리의 개정 수입니다.
- 리포지토리에 있는 큰 파일의 존재입니다.

대규모 리포지토리를 복제할 때 이 오류가 발생하면 `1`의 값으로 [복제 깊이를 줄일 수 있습니다.](../../user/project/repository/monorepos/_index.md#use-shallow-clones-and-filters-in-cicd-processes) 예를 들어:

이 접근 방식은 기본 원인을 해결하지 못하지만 리포지토리를 성공적으로 복제할 수 있습니다. 복제 깊이를 `1`로 줄이려면 다음을 실행합니다.

  ```shell
  variables:
    GIT_DEPTH: 1
  ```

## `Your password expired` LDAP 사용자의 SSH를 사용한 Git fetch 오류 {#your-password-expired-error-on-git-fetch-with-ssh-for-ldap-user}

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed

{{< /details >}}

GitLab Self-Managed에서 `git fetch`가 이 `HTTP 403 Forbidden` 오류를 반환하면 GitLab 데이터베이스의 이 사용자에 대한 비밀번호 만료 날짜(`users.password_expires_at`)는 과거 날짜입니다.

```plaintext
Your password expired. Please access GitLab from a web browser to update your password.
```

SSO 계정으로 만든 요청이며 `password_expires_at`이 `null`이 아닌 경우 이 오류를 반환합니다.

```plaintext
"403 Forbidden - Your password expired. Please access GitLab from a web browser to update your password."
```

이 문제를 해결하려면 다음 중 하나로 비밀번호 만료를 업데이트할 수 있습니다.

- [GitLab Rails 콘솔](../../administration/operations/rails_console.md)을 사용하여 사용자 데이터를 확인하고 업데이트합니다.

  ```ruby
  user = User.find_by_username('<USERNAME>')
  user.password_expired?
  user.password_expires_at
  user.update!(password_expires_at: nil)
  ```

- `gitlab-psql`을 사용합니다.

  ```sql
  # gitlab-psql
  UPDATE users SET password_expires_at = null WHERE username='<USERNAME>';
  ```

이 버그는 [이슈 332455](https://gitlab.com/gitlab-org/gitlab/-/issues/332455)에서 보고되었습니다.

## Git fetch 오류: `HTTP Basic: Access Denied` {#error-on-git-fetch-http-basic-access-denied}

HTTP(S)를 통해 Git을 사용할 때 `HTTP Basic: Access denied` 오류가 수신되면 [2단계 인증 문제 해결 가이드](../../user/profile/account/two_factor_authentication_troubleshooting.md)를 참조합니다.

이 오류는 [Git for Windows](https://gitforwindows.org/) 2.46.0 이상에서도 발생할 수 있습니다. 토큰으로 인증할 때 사용자명은 모든 값이 될 수 있지만 빈 값은 인증 오류를 트리거할 수 있습니다.

이를 해결하려면 사용자명 문자열을 지정합니다. 다음 방법 중 하나를 사용하여 `<USERNAME>`을 GitLab 사용자명으로 바꿉니다.

- 리포지토리를 복제할 때:

  ```shell
  git clone https://<USERNAME>@gitlab.com/path/to/a/project.git
  ```

- 기존 원격 URL을 업데이트합니다.

  ```shell
  git remote set-url origin https://<USERNAME>@gitlab.com/path/to/a/project.git
  ```

- Git이 특정 호스트에 항상 사용자명을 사용하도록 구성합니다.

  ```shell
  git config --global url."https://<USERNAME>@gitlab.com/".insteadOf "https://gitlab.com/"
  ```

## `401` 오류가 성공적인 `git clone`에 기록됨 {#401-errors-logged-during-successful-git-clone}

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed

{{< /details >}}

HTTP를 사용하여 리포지토리를 복제할 때 [`production_json.log`](../../administration/logs/_index.md#production_jsonlog) 파일에 `401` (인증되지 않음) 초기 상태가 표시될 수 있으며, 빠르게 `200`이 나타납니다.

```json
{
   "method":"GET",
   "path":"/group/project.git/info/refs",
   "format":"*/*",
   "controller":"Repositories::GitHttpController",
   "action":"info_refs",
   "status":401,
   "time":"2023-04-18T22:55:15.371Z",
   "remote_ip":"x.x.x.x",
   "ua":"git/2.39.2",
   "correlation_id":"01GYB98MBM28T981DJDGAD98WZ",
   "duration_s":0.03585
}
{
   "method":"GET",
   "path":"/group/project.git/info/refs",
   "format":"*/*",
   "controller":"Repositories::GitHttpController",
   "action":"info_refs",
   "status":200,
   "time":"2023-04-18T22:55:15.714Z",
   "remote_ip":"x.x.x.x",
   "user_id":1,
   "username":"root",
   "ua":"git/2.39.2",
   "correlation_id":"01GYB98MJ0CA3G9K8WDH7HWMQX",
   "duration_s":0.17111
}
```

HTTP를 통해 수행된 각 Git 작업에 대해 이 초기 `401` 로그 항목이 표시되는 것으로 예상됩니다. [HTTP 기본 액세스 인증](https://en.wikipedia.org/wiki/Basic_access_authentication)의 작동 방식 때문입니다.

Git 클라이언트가 복제를 시작하면 GitLab으로 전송된 초기 요청에는 인증 정보가 제공되지 않습니다. GitLab은 해당 요청에 대해 `401 Unauthorized` 결과를 반환합니다. 몇 밀리초 후 Git 클라이언트는 인증 정보를 포함하는 후속 요청을 보냅니다. 이 두 번째 요청은 성공해야 하며 `200 OK` 로그 항목이 나타납니다.

`401` 로그 항목이 해당 `200` 로그 항목이 없으면 Git 클라이언트에서 다음 중 하나를 사용하고 있을 가능성이 높습니다.

- 잘못된 비밀번호입니다.
- 만료되었거나 취소된 토큰입니다.

해결하지 않으면 [`403` (Forbidden) 오류](#403-error-when-performing-git-operations-over-http)를 발생할 수 있습니다.

## `403` HTTP를 통해 Git 작업을 수행할 때의 오류 {#403-error-when-performing-git-operations-over-http}

HTTP를 통해 Git 작업을 수행할 때 `403` (Forbidden) 오류는 IP 주소가 인증 실패 차단으로 차단되었음을 나타냅니다.

```plaintext
fatal: unable to access 'https://gitlab.com/group/project.git/': The requested URL returned error: 403
```

인증 실패 차단 한도는 [GitLab Self-Managed](../../security/rate_limits.md#failed-authentication-ban-for-git-and-container-registry) 또는 [GitLab.com](../../user/gitlab_com/_index.md#ip-blocks)을 사용하는지 여부에 따라 다릅니다.

### 인증 실패 로그 확인 {#check-logs-for-failed-authentications}

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed

{{< /details >}}

`403`은 [`production_json.log`](../../administration/logs/_index.md#production_jsonlog)에서 볼 수 있습니다.

```json
{
   "method":"GET",
   "path":"/group/project.git/info/refs",
   "format":"*/*",
   "controller":"Repositories::GitHttpController",
   "action":"info_refs",
   "status":403,
   "time":"2023-04-19T22:14:25.894Z",
   "remote_ip":"x.x.x.x",
   "user_id":1,
   "username":"root",
   "ua":"git/2.39.2",
   "correlation_id":"01GYDSAKAN2SPZPAMJNRWW5H8S",
   "duration_s":0.00875
}
```

IP 주소가 차단된 경우 [`auth_json.log`](../../administration/logs/_index.md#auth_jsonlog)에 해당 로그 항목이 있습니다.

```json
{
    "severity":"ERROR",
    "time":"2023-04-19T22:14:25.893Z",
    "correlation_id":"01GYDSAKAN2SPZPAMJNRWW5H8S",
    "message":"Rack_Attack",
    "env":"blocklist",
    "remote_ip":"x.x.x.x",
    "request_method":"GET",
    "path":"/group/project.git/info/refs?service=git-upload-pack"}
```
