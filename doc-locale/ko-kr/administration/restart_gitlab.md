---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: GitLab을 다시 시작하는 방법
description: GitLab을 다시 시작하는 방법입니다.
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed

{{< /details >}}

GitLab을 설치하는 방식에 따라 서비스를 다시 시작하는 방법이 다릅니다.

> [!note]
> 모든 방법에서 짧은 다운타임이 발생합니다.

## Linux 패키지 설치 {#linux-package-installations}

[Linux 패키지](https://about.gitlab.com/install/)를 사용하여 GitLab을 설치했다면 `gitlab-ctl`이 `PATH`에 이미 있어야 합니다.

`gitlab-ctl`은 Linux 패키지 설치와 상호작용하며 GitLab Rails 애플리케이션(Puma) 및 다음과 같은 다른 구성 요소를 다시 시작하는 데 사용할 수 있습니다:

- GitLab Workhorse
- Sidekiq
- PostgreSQL (번들로 제공되는 것을 사용 중인 경우)
- NGINX (번들로 제공되는 것을 사용 중인 경우)
- Redis (번들로 제공되는 것을 사용 중인 경우)
- [Mailroom](reply_by_email.md)
- Logrotate

### Linux 패키지 설치 다시 시작 {#restart-a-linux-package-installation}

문서에서 GitLab을 _다시 시작_하도록 요청받는 경우가 있을 수 있습니다. Linux 패키지 설치를 다시 시작하려면 다음을 실행합니다:

```shell
sudo gitlab-ctl restart
```

출력은 다음과 유사해야 합니다:

```plaintext
ok: run: gitlab-workhorse: (pid 11291) 1s
ok: run: logrotate: (pid 11299) 0s
ok: run: mailroom: (pid 11306) 0s
ok: run: nginx: (pid 11309) 0s
ok: run: postgresql: (pid 11316) 1s
ok: run: redis: (pid 11325) 0s
ok: run: sidekiq: (pid 11331) 1s
ok: run: puma: (pid 11338) 0s
```

구성 요소를 별도로 다시 시작하려면 `restart` 명령에 서비스 이름을 추가할 수 있습니다. 예를 들어 NGINX **only** 다시 시작하려면 다음을 실행합니다:

```shell
sudo gitlab-ctl restart nginx
```

GitLab 서비스의 상태를 확인하려면 다음을 실행합니다:

```shell
sudo gitlab-ctl status
```

모든 서비스에서 `ok: run`이 표시되는지 확인합니다.

경우에 따라 구성 요소가 다시 시작하는 동안 시간이 초과되거나(로그에서 `timeout`을 확인) 멈출 수 있습니다. 이 경우 `gitlab-ctl kill <service>`를 사용하여 `SIGKILL` 신호를 서비스로 보낼 수 있습니다. 예를 들어 `sidekiq`입니다. 그 후에는 다시 시작이 정상적으로 수행되어야 합니다.

마지막 수단으로 GitLab을 다시 구성해 볼 수 있습니다.

### Linux 패키지 설치 다시 구성 {#reconfigure-a-linux-package-installation}

문서에서 GitLab을 _다시 구성_하도록 요청받는 경우가 있을 수 있습니다. 이 방법은 Linux 패키지 설치에만 적용됩니다.

Linux 패키지 설치를 다시 구성하려면 다음을 실행합니다:

```shell
sudo gitlab-ctl reconfigure
```

GitLab 구성(`/etc/gitlab/gitlab.rb`)의 내용이 변경된 경우 GitLab을 다시 구성해야 합니다.

`gitlab-ctl reconfigure`을 실행하면 [Chef](https://www.chef.io/products/chef-infra)는 Linux 패키지 설치를 지원하는 기본 구성 관리 애플리케이션으로 몇 가지 검사를 실행합니다. Chef는 디렉터리, 권한 및 서비스가 제 위치에 있고 작동하는지 확인합니다.

Chef는 또한 구성 파일이 변경된 경우 GitLab 구성 요소를 다시 시작합니다.

`/var/opt/gitlab`에서 Chef가 관리하는 파일을 수동으로 편집하면 `reconfigure`을 실행하면 변경 사항이 되돌려지고 해당 파일에 따라 달라지는 서비스가 다시 시작됩니다.

## 자체 컴파일된 설치 {#self-compiled-installations}

공식 설치 가이드를 따라 [설치를 자체 컴파일](../install/self_compiled/_index.md)했다면 다음 명령을 실행하여 GitLab을 다시 시작합니다:

```shell
# For systems running systemd
sudo systemctl restart gitlab.target

# For systems running SysV init
sudo service gitlab restart
```

그러면 Puma, Sidekiq, GitLab Workhorse 및 [Mailroom](reply_by_email.md)(활성화된 경우)을 다시 시작해야 합니다.

## Helm 차트 설치 {#helm-chart-installations}

[클라우드 네이티브 Helm 차트](https://docs.gitlab.com/charts/)를 통해 설치된 전체 GitLab 애플리케이션을 다시 시작하는 단일 명령은 없습니다. 일반적으로 특정 구성 요소를 별도로 다시 시작(예: `gitaly`, `puma`, `workhorse`, 또는 `gitlab-shell`)하고 관련된 모든 포드를 삭제하는 것으로 충분합니다:

```shell
kubectl delete pods -l release=<helm release name>,app=<component name>
```

`helm list` 명령의 출력에서 릴리스 이름을 가져올 수 있습니다.

## Docker 설치 {#docker-installation}

[Docker 설치](../install/docker/_index.md)의 구성을 변경하면 그 변경 사항이 적용되려면 다음을 다시 시작해야 합니다:

- 주 `gitlab` 컨테이너입니다.
- 별도의 구성 요소 컨테이너입니다.

예를 들어 Sidekiq을 별도의 컨테이너에 배포한 경우 컨테이너를 다시 시작하려면 다음을 실행합니다:

```shell
sudo docker restart gitlab
sudo docker restart sidekiq
```
