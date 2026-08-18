---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: GitLab과 함께 NFS 사용
description: GitLab과 함께 NFS를 사용합니다.
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed

{{< /details >}}

NFS를 객체 스토리지의 대체 방안으로 사용할 수 있지만 성능상 이유로 인해 일반적으로 권장되지 않습니다.

LFS, 업로드 및 아티팩트와 같은 데이터 객체의 경우 더 나은 성능으로 인해 가능한 한 NFS보다 [Object Storage 서비스](object_storage.md)를 권장합니다. NFS 사용을 제거할 때 Object Storage로 이동하는 것 외에도 [추가로 수행해야 할 단계](object_storage.md#alternatives-to-file-system-storage)가 있습니다.

NFS는 리포지토리 스토리지에 사용할 수 없습니다.

파일 시스템 성능을 테스트하기 위해 사용할 수 있는 단계는 [파일 시스템 성능 벤치마킹](operations/filesystem_benchmarking.md)을 참조하세요.

## 승인된 SSH 키의 빠른 조회 {#fast-lookup-of-authorized-ssh-keys}

[빠른 SSH 키 조회](operations/fast_ssh_key_lookup.md) 기능은 블록 스토리지를 사용하는 경우에도 GitLab 인스턴스의 성능을 향상할 수 있습니다.

[빠른 SSH 키 조회](operations/fast_ssh_key_lookup.md)는 GitLab 데이터베이스를 사용하여 `authorized_keys` (`/var/opt/gitlab/.ssh`에 위치)을 대체합니다.

NFS는 지연 시간을 증가시키므로 `/var/opt/gitlab`을(를) NFS로 이동하는 경우 빠른 조회를 권장합니다.

저희는 [기본값으로 빠른 조회](https://gitlab.com/groups/gitlab-org/-/epics/3104) 사용을 조사 중입니다.

## NFS 서버 {#nfs-server}

`nfs-kernel-server` 패키지를 설치하면 GitLab 애플리케이션을 실행하는 클라이언트와 디렉터리를 공유할 수 있습니다:

```shell
sudo apt-get update
sudo apt-get install nfs-kernel-server
```

### 필수 기능 {#required-features}

**File locking**:  GitLab은 **requires** 파일 잠금이 필요하며, 이는 NFS 버전 4에서만 기본적으로 지원됩니다. NFSv3도 Linux 커널 2.6.5+ 이상이 사용되는 경우 잠금을 지원합니다. 버전 4 사용을 권장하며 NFSv3을(를) 특별히 테스트하지는 않습니다.

### 권장 옵션 {#recommended-options}

NFS 내보내기를 정의할 때 다음 옵션도 추가할 것을 권장합니다:

- `no_root_squash` - NFS는 일반적으로 `root` 사용자를 `nobody`로 변경합니다. 이는 NFS 공유에 많은 다양한 사용자가 액세스할 때 좋은 보안 조치입니다. 그러나 이 경우 GitLab만 NFS 공유를 사용하므로 안전합니다. GitLab은 파일 권한을 자동으로 관리해야 하므로 `no_root_squash` 설정을 권장합니다. 이 설정이 없으면 Linux 패키지가 권한을 변경하려고 할 때 오류가 발생할 수 있습니다. GitLab 및 기타 번들된 구성 요소는 **not** 사용자로 `root`로 실행되지 않습니다. `no_root_squash`에 대한 권장 사항은 필요에 따라 Linux 패키지가 파일에 대한 소유권과 권한을 설정할 수 있도록 하기 위한 것입니다. `no_root_squash` 옵션을 사용할 수 없는 경우 `root` 플래그로 동일한 결과를 얻을 수 있습니다.
- `sync` - 동기 동작을 강제합니다. 기본값은 비동기이며 특정 상황에서 데이터 동기화 전에 오류가 발생하면 데이터 손실이 발생할 수 있습니다.

LDAP를 사용하여 Linux 패키지를 실행하는 복잡성과 LDAP 없이 ID 매핑을 유지 관리하는 복잡성으로 인해 대부분의 경우 시스템 간 단순화된 권한 관리를 위해 숫자 UID 및 GID를 활성화해야 합니다(일부 경우 기본적으로 꺼져 있음):

- [NetApp 지침](https://docs.netapp.com/a/ontap/7-mode/8.2.4/File-Access-And-Protocols-Management-Guide-For-7-Mode.pdf)
- NetApp이 아닌 장치의 경우 [NFSv4 idmapper 활성화](https://wiki.archlinux.org/title/NFS#Enabling_NFSv4_idmapping)의 반대를 수행하여 NFSv4 `idmapping`을(를) 비활성화합니다.

### NFS 서버 위임 비활성화 {#disable-nfs-server-delegation}

모든 NFS 사용자가 NFS 서버 위임 기능을 비활성화할 것을 권장합니다. 이는 NFS 클라이언트가 [여러 `TEST_STATEID` NFS 메시지로부터의 과도한 네트워크 트래픽](https://gitlab.com/gitlab-org/gitlab-foss/-/issues/52017) 으로 인해 급격히 느려지게 하는 [Linux 커널 버그](https://bugzilla.redhat.com/show_bug.cgi?id=1552203)를 방지하기 위함입니다.

NFS 서버 위임을 비활성화하려면 다음을 수행합니다:

1. NFS 서버에서 실행하세요:

   ```shell
   echo 0 > /proc/sys/fs/leases-enable
   sysctl -w fs.leases-enable=0
   ```

1. NFS 서버 프로세스를 다시 시작합니다. 예를 들어 CentOS에서는 `service nfs restart`을(를) 실행하세요.

> [!note]
> 커널 버그는 [이 커밋이 포함된 더 최근 커널](https://github.com/torvalds/linux/commit/95da1b3a5aded124dd1bda1e3cdb876184813140)에서 수정될 수 있습니다. Red Hat Enterprise 7은 2019년 8월 6일에 이 문제를 해결할 수 있는 [커널 업데이트](https://access.redhat.com/errata/RHSA-2019:2029)를 출시했습니다. Linux 커널의 수정된 버전을 사용하고 있음을 알고 있다면 NFS 서버 위임을 비활성화할 필요가 없을 수 있습니다. 즉, GitLab은 여전히 인스턴스 관리자가 NFS 서버 위임을 비활성화 상태로 유지할 것을 권장합니다.

## NFS 클라이언트 {#nfs-client}

`nfs-common`은(는) 애플리케이션 노드에서 실행할 필요가 없는 서버 구성 요소를 설치하지 않고도 NFS 기능을 제공합니다.

```shell
apt-get update
apt-get install nfs-common
```

### 마운트 옵션 {#mount-options}

`/etc/fstab`에 추가할 예제 스니펫은 다음과 같습니다:

```plaintext
10.1.0.1:/var/opt/gitlab/.ssh /var/opt/gitlab/.ssh nfs4 defaults,vers=4.1,hard,rsize=1048576,wsize=1048576,noatime,nofail,_netdev,lookupcache=positive 0 2
10.1.0.1:/var/opt/gitlab/gitlab-rails/uploads /var/opt/gitlab/gitlab-rails/uploads nfs4 defaults,vers=4.1,hard,rsize=1048576,wsize=1048576,noatime,nofail,_netdev,lookupcache=positive 0 2
10.1.0.1:/var/opt/gitlab/gitlab-rails/shared /var/opt/gitlab/gitlab-rails/shared nfs4 defaults,vers=4.1,hard,rsize=1048576,wsize=1048576,noatime,nofail,_netdev,lookupcache=positive 0 2
10.1.0.1:/var/opt/gitlab/gitlab-ci/builds /var/opt/gitlab/gitlab-ci/builds nfs4 defaults,vers=4.1,hard,rsize=1048576,wsize=1048576,noatime,nofail,_netdev,lookupcache=positive 0 2
```

`nfsstat -m`을(를) 실행하고 `cat /etc/fstab`하여 마운트된 각 NFS 파일 시스템에 설정된 정보 및 옵션을 볼 수 있습니다.

사용을 고려해야 할 몇 가지 옵션이 있습니다:

| 설정                | 설명 |
|------------------------|-------------|
| `vers=4.1`             | NFS v4.1은 v4.0 대신 사용해야 합니다. 왜냐하면 오래된 데이터로 인해 심각한 문제를 일으킬 수 있는 Linux [v4.0의 NFS 클라이언트 버그](https://gitlab.com/gitlab-org/gitaly/-/issues/1339)가 있기 때문입니다. |
| `nofail`               | 이 마운트가 사용 가능해질 때까지 부팅 프로세스를 중단하지 마세요. |
| `lookupcache=positive` | NFS 클라이언트가 `positive` 캐시 결과를 준수하도록 지시하지만 모든 `negative` 캐시 결과를 무효화합니다. 부정적인 캐시 결과는 Git에 문제를 유발합니다. 특히 `git push`은(는) 모든 NFS 클라이언트에서 균일하게 등록되지 않을 수 있습니다. 부정적인 캐시는 클라이언트가 파일이 이전에 존재하지 않았다는 것을 '기억'하도록 합니다. |
| `hard`                 | `soft` 대신. [자세한 내용](#soft-mount-option). |
| `cto`                  | `cto`은(는) 사용해야 할 기본 옵션입니다. `nocto`을(를) 사용하지 마세요. [자세한 내용](#nocto-mount-option). |
| `_netdev`              | 네트워크가 온라인 상태가 될 때까지 파일 시스템 마운트를 기다리세요. [`high_availability['mountpoint']`](https://docs.gitlab.com/omnibus/settings/configuration/#start-linux-package-installation-services-only-after-a-given-file-system-is-mounted) 옵션도 참조하세요. |

#### `soft` 마운트 옵션 {#soft-mount-option}

`hard`을(를) 마운트 옵션에서 사용할 것을 권장합니다. `soft`을(를) 사용해야 할 특정한 이유가 없는 한.

GitLab.com에서 NFS를 사용했을 때 NFS 서버를 다시 부팅할 때가 있었고 `soft`이(가) 가용성을 향상시켰기 때문에 `soft`을(를) 사용했지만 모든 인프라는 다릅니다. 예를 들어 중복 컨트롤러가 있는 온프레미스 스토리지 배열에서 NFS를 제공하는 경우 NFS 서버 가용성에 대해 걱정할 필요가 없어야 합니다.

NFS man 페이지는 다음과 같습니다:

> "soft" 타임아웃은 특정 경우에 자동 데이터 손상을 일으킬 수 있습니다.

[Linux man 페이지](https://linux.die.net/man/5/nfs)를 읽어 차이를 이해하고, `soft`을(를) 사용하는 경우 위험을 완화하기 위한 단계를 취했는지 확인하세요.

NFS 서버에 기록되지 않은 디스크 기록으로 인해 발생했을 수 있는 동작(예: 누락된 커밋)이 발생하는 경우 `hard` 옵션을 사용하세요(man 페이지에서):

> 클라이언트 반응성이 데이터 무결성보다 더 중요한 경우에만 soft 옵션을 사용하세요.

기타 공급업체도 [읽기-쓰기 디렉터리에 권장되는 마운트 옵션](https://help.sap.com/docs/SUPPORT_CONTENT/basis/3354611703.html) 및 NetApp의 [지식 기반](https://kb.netapp.com/on-prem/ontap/da/NAS/NAS-KBs/What_are_the_differences_between_hard_mount_and_soft_mount)을 포함하여 유사한 권장 사항을 제공합니다. 이들은 NFS 클라이언트 드라이버가 데이터를 캐시하는 경우 `soft`은(는) GitLab의 쓰기가 실제로 디스크에 있는지에 대한 확실성이 없음을 강조합니다.

`hard` 옵션으로 설정된 마운트 포인트는 잘 작동하지 않을 수 있으며, NFS 서버가 다운되면 `hard`은(는) 마운트 포인트와 상호 작용할 때 프로세스가 중단되도록 합니다. `SIGKILL` (`kill -9`)을(를) 사용하여 중단된 프로세스를 처리합니다. `intr` 옵션은 [2.6 커널에서 작동을 중단](https://access.redhat.com/solutions/157873)했습니다.

#### `nocto` 마운트 옵션 {#nocto-mount-option}

`nocto`을(를) 사용하지 마세요. 대신 기본값인 `cto`을(를) 사용하세요.

`nocto`을(를) 사용할 때 dentry 캐시는 생성된 시간부터 `acdirmax` 초(속성 캐시 시간)까지 항상 사용됩니다.

이로 인해 여러 클라이언트에서 dentry 캐시 문제가 발생하며, 각 클라이언트는 디렉터리의 다른 (캐시된) 버전을 볼 수 있습니다.

[Linux man 페이지](https://linux.die.net/man/5/nfs)에서 중요한 부분:

> `nocto` 옵션이 지정된 경우 클라이언트는 서버의 파일이 변경된 시기를 결정하기 위해 비표준 휴리스틱을 사용합니다.
>
> `nocto` 옵션을 사용하면 읽기 전용 마운트의 성능이 향상될 수 있지만 서버의 데이터가 가끔만 변경되는 경우에만 사용해야 합니다.

저희는 [푸시 후 refs를 찾을 수 없는](https://gitlab.com/gitlab-org/gitlab/-/issues/326066) 문제에서 이 동작을 발견했으며, 새로 추가된 느슨한 refs가 로컬 dentry 캐시를 사용하는 다른 클라이언트에서 누락된 것으로 표시될 수 있으며, [이 문제에서 설명됨](https://gitlab.com/gitlab-org/gitlab/-/issues/326066#note_539436931).

### 단일 NFS 마운트 {#a-single-nfs-mount}

모든 GitLab 데이터 디렉터리를 마운트 내에 중첩하여 기존 데이터를 수동으로 이동하지 않고 백업을 자동으로 복원할 수 있도록 하는 것이 좋습니다.

```plaintext
mountpoint
└── gitlab-data
    ├── builds
    ├── shared
    └── uploads
```

이렇게 하려면 마운트 포인트 내에 중첩된 각 디렉터리의 경로를 사용하여 Linux 패키지를 구성합니다:

`/gitlab-nfs`을(를) 마운트하고 다음 Linux 패키지 구성을 사용하여 각 데이터 위치를 하위 디렉터리로 이동합니다:

```ruby
gitlab_rails['uploads_directory'] = '/gitlab-nfs/gitlab-data/uploads'
gitlab_rails['shared_path'] = '/gitlab-nfs/gitlab-data/shared'
gitlab_ci['builds_directory'] = '/gitlab-nfs/gitlab-data/builds'
```

`sudo gitlab-ctl reconfigure`을(를) 실행하여 중앙 위치 사용을 시작합니다. 기존 데이터가 있는 경우 이를 이 새 위치로 수동으로 복사 또는 rsync한 후 GitLab을 다시 시작해야 합니다.

### 바인드 마운트 {#bind-mounts}

Linux 패키지의 구성을 변경하는 대신 바인드 마운트를 사용하여 데이터를 NFS 마운트에 저장할 수 있습니다.

바인드 마운트는 단일 NFS 마운트를 지정한 다음 기본 GitLab 데이터 위치를 NFS 마운트에 바인드할 수 있는 방법을 제공합니다. `/etc/fstab`에서 일반적으로 수행하는 대로 단일 NFS 마운트 포인트를 정의하여 시작합니다. NFS 마운트 포인트가 `/gitlab-nfs`이라고 가정합시다. 그런 다음 `/etc/fstab`에서 다음 바인드 마운트를 추가합니다:

```shell
/gitlab-nfs/gitlab-data/.ssh /var/opt/gitlab/.ssh none bind 0 0
/gitlab-nfs/gitlab-data/uploads /var/opt/gitlab/gitlab-rails/uploads none bind 0 0
/gitlab-nfs/gitlab-data/shared /var/opt/gitlab/gitlab-rails/shared none bind 0 0
/gitlab-nfs/gitlab-data/builds /var/opt/gitlab/gitlab-ci/builds none bind 0 0
```

바인드 마운트를 사용하려면 복원을 시도하기 전에 데이터 디렉터리가 비어 있는지 수동으로 확인해야 합니다. [복원 사전 요구 사항](backup_restore/_index.md)에 대해 자세히 알아보세요.

### 여러 NFS 마운트 {#multiple-nfs-mounts}

기본 Linux 패키지 구성을 사용할 때는 모든 GitLab 클러스터 노드 간에 3개의 데이터 위치를 공유해야 합니다. 다른 위치는 공유하면 안 됩니다. 공유해야 할 3개 위치는 다음과 같습니다:

| 위치 | 설명 | 기본 구성 |
| -------- | ----------- | --------------------- |
| `/var/opt/gitlab/gitlab-rails/uploads` | 사용자가 업로드한 첨부 파일 | `gitlab_rails['uploads_directory'] = '/var/opt/gitlab/gitlab-rails/uploads'` |
| `/var/opt/gitlab/gitlab-rails/shared` | 빌드 아티팩트, GitLab Pages, LFS 개체 및 임시 파일과 같은 개체입니다. LFS를 사용하는 경우 데이터의 상당 부분을 차지할 수도 있습니다. | `gitlab_rails['shared_path'] = '/var/opt/gitlab/gitlab-rails/shared'` |
| `/var/opt/gitlab/gitlab-ci/builds` | GitLab CI/CD 빌드 추적 | `gitlab_ci['builds_directory'] = '/var/opt/gitlab/gitlab-ci/builds'` |

다른 GitLab 디렉터리는 노드 간에 공유하면 안 됩니다. 여기에는 노드 특정 파일과 공유할 필요가 없는 GitLab 코드가 포함되어 있습니다. 로그를 중앙 위치로 전송하려면 원격 syslog 사용을 고려하세요. Linux 패키지는 [UDP 로그 배송](https://docs.gitlab.com/omnibus/settings/logs/#udp-log-forwarding)에 대한 구성을 제공합니다.

여러 NFS 마운트를 사용하려면 복원을 시도하기 전에 데이터 디렉터리가 비어 있는지 수동으로 확인해야 합니다. [복원 사전 요구 사항](backup_restore/_index.md)에 대해 자세히 알아보세요.

## NFS 테스트 {#testing-nfs}

NFS 서버 및 클라이언트를 설정한 후 다음 명령을 테스트하여 NFS가 올바르게 구성되었는지 확인할 수 있습니다:

```shell
sudo mkdir /gitlab-nfs/test-dir
sudo chown git /gitlab-nfs/test-dir
sudo chgrp root /gitlab-nfs/test-dir
sudo chmod 0700 /gitlab-nfs/test-dir
sudo chgrp gitlab-www /gitlab-nfs/test-dir
sudo chmod 0751 /gitlab-nfs/test-dir
sudo chgrp git /gitlab-nfs/test-dir
sudo chmod 2770 /gitlab-nfs/test-dir
sudo chmod 2755 /gitlab-nfs/test-dir
sudo -u git mkdir /gitlab-nfs/test-dir/test2
sudo -u git chmod 2755 /gitlab-nfs/test-dir/test2
sudo ls -lah /gitlab-nfs/test-dir/test2
sudo -u git rm -r /gitlab-nfs/test-dir
```

`Operation not permitted` 오류가 발생하면 NFS 서버 내보내기 옵션을 조사해야 합니다.

## 방화벽으로 보호된 환경의 NFS {#nfs-in-a-firewalled-environment}

NFS 서버와 NFS 클라이언트 간의 트래픽이 방화벽에 의한 포트 필터링의 대상이 되는 경우 해당 방화벽을 재구성하여 NFS 통신을 허용해야 합니다.

[The Linux Documentation Project (TDLP)의 이 가이드](https://tldp.org/HOWTO/NFS-HOWTO/security.html#FIREWALLS)는 방화벽으로 보호된 환경에서 NFS를 사용하는 기본 사항을 다룹니다. 또한 운영 체제 또는 배포판과 방화벽 소프트웨어에 대한 특정 설명서를 검색하고 검토할 것을 권장합니다.

Ubuntu의 예:

명령어 `sudo ufw status`을(를) 실행하여 호스트의 방화벽에 의해 클라이언트의 NFS 트래픽이 허용되는지 확인합니다. 차단되는 경우 아래 명령을 사용하여 특정 클라이언트의 트래픽을 허용할 수 있습니다.

```shell
sudo ufw allow from <client_ip_address> to any port nfs
```

## 알려진 이슈 {#known-issues}

### 클라우드 기반 파일 시스템 사용 금지 {#avoid-using-cloud-based-file-systems}

GitLab은 다음과 같은 클라우드 기반 파일 시스템의 사용을 강력히 권장하지 않습니다:

- AWS Elastic File System (EFS).
- Google Cloud Filestore.
- Azure Files.

저희 지원팀은 클라우드 기반 파일 시스템 액세스와 관련된 성능 문제를 지원할 수 없습니다.

고객 및 사용자는 이러한 파일 시스템이 GitLab이 필요로 하는 파일 시스템 액세스에 대해 잘 작동하지 않는다고 보고했습니다. `git`처럼 많은 수의 작은 파일이 직렬 방식으로 작성되는 워크로드는 클라우드 기반 파일 시스템에 적합하지 않습니다.

이를 사용하기로 선택한 경우 GitLab 로그 파일(예: `/var/log/gitlab`에 있는 파일)을 저장하지 마세요. 이는 성능에도 영향을 미치기 때문입니다. 로그 파일을 로컬 볼륨에 저장하는 것을 권장합니다.

GitLab에서 클라우드 기반 파일 시스템을 사용하는 환경에 대한 자세한 내용은 [Commit Brooklyn 2019 비디오](https://youtu.be/K6OS8WodRBQ?t=313)를 참조하세요.

### CephFS 및 GlusterFS 사용 금지 {#avoid-using-cephfs-and-glusterfs}

GitLab은 CephFS 및 GlusterFS 사용을 강력히 권장하지 않습니다. 이러한 분산 파일 시스템은 Git이 많은 수의 작은 파일을 사용하고 액세스 시간 및 파일 잠금 시간을 전파하여 Git 작업을 매우 느리게 만들기 때문에 GitLab 입출력 액세스 패턴에 적합하지 않습니다.

### PostgreSQL과 함께 NFS 사용 금지 {#avoid-using-postgresql-with-nfs}

GitLab은 NFS를 통해 PostgreSQL 데이터베이스를 실행하지 않을 것을 강력히 권장합니다. GitLab 지원팀은 이 구성과 관련된 성능 문제에 대해 지원할 수 없습니다.

또한 이 구성은 [PostgreSQL 문서](https://www.postgresql.org/docs/16/creating-cluster.html#CREATING-CLUSTER-NFS)에서 특별히 경고합니다:

>PostgreSQL은 NFS 파일 시스템에 대해 특별히 수행하는 작업이 없으므로 NFS가 로컬로 연결된 드라이브와 정확히 동일하게 작동한다고 가정합니다. 클라이언트 또는 서버 NFS 구현이 표준 파일 시스템 의미를 제공하지 않는 경우 신뢰성 문제가 발생할 수 있습니다. 특히 NFS 서버에 대한 지연된(비동기) 쓰기로 인해 데이터 손상 문제가 발생할 수 있습니다.

지원되는 데이터베이스 아키텍처는 [복제 및 장애 조치를 위한 데이터베이스 구성](postgresql/replication_and_failover.md)에 대한 설명서를 참조하세요.

## 문제 해결 {#troubleshooting}

### NFS에 대해 수행되는 요청 찾기 {#finding-the-requests-that-are-being-made-to-nfs}

NFS 관련 문제가 발생한 경우 `perf`을(를) 사용하여 수행되는 파일 시스템 요청을 추적하는 것이 도움이 될 수 있습니다:

```shell
sudo perf trace -e 'nfs4:*' -p $(pgrep -fd ',' puma)
```
