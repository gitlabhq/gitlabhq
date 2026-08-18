---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: GitLab Self-Managed에서 Git 프로토콜 v2를 설정하고 구성합니다.
title: Git 프로토콜 v2 구성
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed

{{< /details >}}

Git 프로토콜 v2는 v1 와이어 프로토콜을 여러 가지 방식으로 개선하며 GitLab에서 HTTP 요청에 대해 기본적으로 활성화됩니다. SSH를 활성화하려면 관리자의 추가 구성이 필요합니다.

새로운 기능 및 개선 사항에 대한 자세한 정보는 [Google Open Source Blog](https://opensource.googleblog.com/2018/05/introducing-git-protocol-version-2.html)에서 확인할 수 있습니다.

## 전제 조건 {#prerequisites}

클라이언트 측에서는 `git` `v2.18.0` 이상이 설치되어야 합니다.

서버 측에서 SSH를 구성하려면 `sshd` 서버를 `GIT_PROTOCOL` 환경을 허용하도록 설정해야 합니다.

[GitLab Helm Charts](https://docs.gitlab.com/charts/) 및 [All-in-one Docker image](../install/docker/_index.md)를 사용하는 설치의 경우 SSH 서비스가 이미 `GIT_PROTOCOL` 환경을 허용하도록 구성되어 있습니다. 사용자는 추가 작업을 수행할 필요가 없습니다.

Linux 패키지 또는 자체 컴파일 설치의 경우 `/etc/ssh/sshd_config` 파일에 다음 줄을 추가하여 서버의 SSH 구성을 수동으로 업데이트합니다:

```plaintext
AcceptEnv GIT_PROTOCOL
```

SSH 데몬을 구성한 후 변경 사항을 적용하려면 재시작합니다:

```shell
# CentOS 6 / RHEL 6
sudo service sshd restart

# All other supported distributions
sudo systemctl restart ssh
```

## 지침 {#instructions}

새 프로토콜을 사용하려면 클라이언트가 Git 명령에 `-c protocol.version=2` 구성을 전달하거나 전역으로 설정해야 합니다:

```shell
git config --global protocol.version 2
```

### HTTP 연결 {#http-connections}

클라이언트에서 Git v2가 사용되는지 확인합니다:

```shell
GIT_TRACE_CURL=1 git -c protocol.version=2 ls-remote https://your-gitlab-instance.com/group/repo.git 2>&1 | grep Git-Protocol
```

`Git-Protocol` 헤더가 전송되는지 확인합니다:

```plaintext
16:29:44.577888 http.c:657              => Send header: Git-Protocol: version=2
```

서버에서 Git v2가 사용되는지 확인합니다:

```shell
GIT_TRACE_PACKET=1 git -c protocol.version=2 ls-remote https://your-gitlab-instance.com/group/repo.git 2>&1 | head
```

Git 프로토콜 v2를 사용한 예시 응답:

```shell
$ GIT_TRACE_PACKET=1 git -c protocol.version=2 ls-remote https://your-gitlab-instance.com/group/repo.git 2>&1 | head
10:42:50.574485 pkt-line.c:80           packet:          git< # service=git-upload-pack
10:42:50.574653 pkt-line.c:80           packet:          git< 0000
10:42:50.574673 pkt-line.c:80           packet:          git< version 2
10:42:50.574679 pkt-line.c:80           packet:          git< agent=git/2.18.1
10:42:50.574684 pkt-line.c:80           packet:          git< ls-refs
10:42:50.574688 pkt-line.c:80           packet:          git< fetch=shallow
10:42:50.574693 pkt-line.c:80           packet:          git< server-option
10:42:50.574697 pkt-line.c:80           packet:          git< 0000
10:42:50.574817 pkt-line.c:80           packet:          git< version 2
10:42:50.575308 pkt-line.c:80           packet:          git< agent=git/2.18.1
```

### SSH 연결 {#ssh-connections}

클라이언트에서 Git v2가 사용되는지 확인합니다:

```shell
GIT_SSH_COMMAND="ssh -v" git -c protocol.version=2 ls-remote ssh://git@your-gitlab-instance.com/group/repo.git 2>&1 | grep GIT_PROTOCOL
```

`GIT_PROTOCOL` 환경 변수가 전송되는지 확인합니다:

```plaintext
debug1: Sending env GIT_PROTOCOL = version=2
```

서버 측에서는 [HTTP의 동일한 예시](#http-connections)를 사용하여 URL을 SSH로 변경할 수 있습니다.

### 연결의 Git 프로토콜 버전 확인 {#observe-git-protocol-version-of-connections}

프로덕션 환경에서 사용 중인 Git 프로토콜 버전을 확인하는 방법에 대한 정보는 [관련 문서](gitaly/monitoring.md#queries)를 참조하세요.
