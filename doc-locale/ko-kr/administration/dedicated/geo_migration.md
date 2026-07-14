---
stage: GitLab Dedicated
group: Environment Automation
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: GitLab Self-Managed에서 GitLab Dedicated로 Geo를 통해 마이그레이션합니다.
title: Geo를 통해 GitLab Dedicated로 마이그레이션
---

{{< details >}}

- 계층:  Ultimate
- 제공:  GitLab Dedicated

{{< /details >}}

Geo 마이그레이션은 GitLab Self-Managed 주 인스턴스의 보안 정보가 필요하므로 GitLab Dedicated이 마이그레이션 후 데이터를 복호화할 수 있습니다. 이러한 보안 정보에는 CI/CD 변수 및 기타 민감한 구성 세부 정보를 포함한 데이터베이스 암호화 키가 포함됩니다.

SSH 호스트 키는 선택 사항이지만 적극 권장합니다. 이를 보존하면 사용자가 마이그레이션 후 SSH를 통해 `git clone` 또는 `git pull`를 실행할 때 SSH 호스트 키 검증 실패를 방지합니다. 자신의 도메인을 사용할 계획이 있다면 특히 중요합니다.

수집 스크립트는 [age](https://github.com/FiloSottile/age)를 사용하며, 이는 파일 암호화 도구로 Switchboard에 업로드하기 전에 보안 정보를 안전하게 암호화합니다.

## 마이그레이션 보안 정보 수집 및 업로드 {#collect-and-upload-migration-secrets}

[GitLab Dedicated 인스턴스를 생성](create_instance/_index.md#create-your-instance)할 때 Geo 마이그레이션 보안 정보를 수집하고 업로드합니다.

전제 조건:

- GitLab Self-Managed 주 인스턴스에 대한 관리 액세스
- Python 3.x
- Switchboard의 **Geo migration secrets** 페이지에서 `age` 공개 키
- GitLab 클러스터에 대한 액세스 권한이 있는 `kubectl`(Kubernetes 설치만 해당)

마이그레이션 보안 정보를 수집하고 업로드하려면:

1. [Switchboard](https://console.gitlab-dedicated.com/)에 로그인합니다.
1. **Geo migration secrets** 페이지에서 설치 유형에 적합한 수집 스크립트를 다운로드합니다.
1. 선택사항. 오프라인 환경의 경우, 실행하기 전에 `age` 바이너리를 수집 스크립트에 포함합니다. 자세한 내용은 [오프라인 환경](#offline-environments)을 참조하세요.
1. 설치 유형에 해당하는 수집 스크립트를 실행하고 `<age_public_key>`을(를) 페이지에 표시되는 키로 바꿉니다:

   - Linux 패키지 설치의 경우, Rails 노드에서 다음 명령을 실행합니다:

     ```shell
     python3 collect_secrets_linux_package.py <age_public_key>
     ```

     `/etc/gitlab/gitlab-secrets.json`, `/var/opt/gitlab/gitlab-rails/etc/database.yml` 및 `/etc/ssh/`에 대한 읽기 액세스가 필요합니다.

   - Kubernetes 설치의 경우, `kubectl` 액세스 권한이 있는 워크스테이션에서 다음 명령을 실행합니다:

     ```shell
     python3 collect_secrets_k8s.py <age_public_key>
     ```

     기본값을 재정의하려면 추가 플래그를 전달할 수 있습니다. 자세한 내용은 [Kubernetes 수집 스크립트 플래그](#kubernetes-collection-script-flags)를 참조하세요.

1. 선택사항. SSH 호스트 키만 수집하려면 명령에 `--hostkeys-only` 플래그를 추가합니다.

   스크립트는 다음을 생성합니다:

   - `migration_secrets.json.age`:  GitLab 보안 정보(필수)
   - `ssh_host_keys.json.age`:  SSH 호스트 키(선택 사항이지만 권장)

1. `migration_secrets.json.age` 파일을 업로드합니다.
1. 선택사항. `ssh_host_keys.json.age` 파일을 업로드합니다.
1. 검증이 완료될 때까지 기다립니다. 검증은 파일당 약 10-20초가 소요됩니다.
1. 표시된 파일 이름과 지문이 업로드된 파일과 일치하는지 확인합니다.

> [!note]
> 검증은 파일이 제대로 암호화되어 있고 예상된 구조를 포함하는지 확인합니다. 파일의 내용을 복호화하거나 노출하지 않습니다.

보안 정보를 업로드한 후 테넌트를 생성하는 나머지 단계를 완료합니다.

### Kubernetes 수집 스크립트 플래그 {#kubernetes-collection-script-flags}

`collect_secrets_k8s.py`에서 이러한 선택적 플래그를 사용하여 기본값을 재정의합니다:

| 플래그                     | 기본값         | 설명 |
|--------------------------|-----------------|-------------|
| `--namespace NAME`       | 현재 컨텍스트 | Kubernetes 네임스페이스입니다. |
| `--release NAME`         | `gitlab`        | Helm 릴리스 이름 접두사입니다. |
| `--rails-secret NAME`    | 없음            | Rails 보안 정보 보안 정보 이름입니다. |
| `--registry-secret NAME` | 없음            | 레지스트리 보안 정보 이름입니다. |
| `--postgres-secret NAME` | 없음            | Postgres 암호 보안 정보 이름입니다. |
| `--hostkeys-secret NAME` | 없음            | SSH 호스트 키 보안 정보 이름입니다. |

### 오프라인 환경 {#offline-environments}

GitLab Self-Managed 인스턴스에 인터넷 액세스 권한이 없으면 수집 스크립트를 실행하기 전에 `age` 바이너리를 수동으로 다운로드합니다.

오프라인 환경을 위해 수집 스크립트를 설정하려면:

1. 인터넷 액세스 권한이 있는 머신에서 `age` 바이너리를 다운로드합니다:

   ```shell
   python3 download_age_binaries.py
   ```

   이는 여러 플랫폼용 `age` 바이너리를 포함하는 `age_binaries.tar.gz` 파일을 생성합니다.

1. `age_binaries.tar.gz` 파일을 오프라인 환경으로 전송합니다.
1. 바이너리를 수집 스크립트에 포함합니다:

   ```shell
   python3 embed_age_binary.py --binaries age_binaries.tar.gz
   ```

   이는 `age` 바이너리를 포함하는 자체 포함 스크립트를 생성합니다.

1. [마이그레이션 보안 정보 수집 및 업로드](#collect-and-upload-migration-secrets)에 설명된 대로 GitLab Self-Managed 인스턴스에서 포함된 스크립트를 실행합니다.

포함된 스크립트는 포함된 `age` 바이너리를 자동으로 추출하고 사용합니다.

## 문제 해결 {#troubleshooting}

Geo 마이그레이션 작업 시 다음과 같은 이슈가 발생할 수 있습니다.

### 오류: 수집 스크립트 실행 시 `Permission denied` {#error-permission-denied-when-running-the-collection-script}

수집 스크립트가 GitLab 구성 파일에 액세스하려고 할 때 권한 오류가 발생할 수 있습니다.

이 이슈는 스크립트가 필요한 파일을 읽을 수 있는 충분한 권한 없이 실행될 때 발생합니다.

이 이슈를 해결하려면:

1. Linux 패키지 설치의 경우, 스크립트를 `root` 사용자로 실행하거나 `sudo`를 사용합니다.
1. Kubernetes 설치의 경우, `kubectl` 컨텍스트가 GitLab 네임스페이스에 액세스할 수 있는지 확인합니다.
1. 필요한 파일이 예상된 경로에 있는지 확인합니다.

### 수집 스크립트가 GitLab 설치를 찾을 수 없음 {#collection-script-cannot-find-gitlab-installation}

스크립트가 GitLab 설치 또는 구성 파일을 찾을 수 없다는 오류가 발생할 수 있습니다.

이 이슈는 다음 시나리오에서 발생합니다:

- 스크립트가 GitLab이 설치되지 않은 머신에서 실행됩니다.
- GitLab이 비표준 위치에 설치되어 있습니다.
- 필요한 구성 파일이 누락되었거나 이동되었습니다.

일반적인 오류 메시지는 다음을 포함합니다:

- Linux 패키지: `Error: database.yml not found: /var/opt/gitlab/gitlab-rails/etc/database.yml`다음 `✗ Failed to collect GitLab secrets`
- Kubernetes: `Error: Could not retrieve gitlab-rails-secrets`

이 이슈를 해결하려면:

1. 스크립트가 올바른 머신(Linux 패키지 설치의 경우 Rails 노드)에서 실행되는지 확인합니다.
1. GitLab이 제대로 설치되고 구성되었는지 확인합니다.
1. GitLab이 비표준 위치에 설치된 경우, 구성 파일 경로가 설치와 일치하는지 확인합니다.
1. 필요한 파일이 누락되었거나 손상된 경우, Professional Services에 연락하여 마이그레이션을 진행하기 전에 설치의 상태 확인을 수행하도록 합니다.
