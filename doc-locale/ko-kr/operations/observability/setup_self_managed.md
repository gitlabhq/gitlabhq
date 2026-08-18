---
stage: none
group: Embody
info: This page is owned by <https://handbook.gitlab.com/handbook/engineering/embody-team/>
description: 애플리케이션 성능을 모니터링하고 성능 문제를 해결합니다.
ignore_in_report: true
title: GitLab Self-Managed에서 통합관찰 설정
---

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed
- 상태: 실험적 기능

{{< /details >}}

통합관찰 데이터는 GitLab.com 인스턴스 외부의 별도 애플리케이션에서 수집됩니다. GitLab 인스턴스의 문제는 통합관찰 데이터 수집 또는 보기에 영향을 주지 않으며 그 반대도 마찬가지입니다.

GitLab Self-Managed의 경우 데이터가 저장되는 위치를 제어합니다.

## 워크플로우 {#workflow}

GitLab Self-Managed 인스턴스에서 통합관찰을 설정하려면 다음을 수행합니다:

1. 필수 요구 사항을 충족하는지 확인합니다.
1. 서버와 스토리지를 프로비저닝합니다.
1. Docker를 구성하고 통합관찰을 컨테이너에 설치합니다.
1. 네트워크 액세스를 구성합니다.
1. 그룹의 URL을 구성합니다.

## 전제 조건 {#prerequisites}

- 다음이 포함된 EC2 인스턴스 또는 유사한 가상 머신이 있어야 합니다:
  - 최소:  `t3.large` (2 vCPU, 8 GB RAM).
  - 권장:  `t3.xlarge` (4 vCPU, 16 GB RAM) 프로덕션 사용의 경우.
  - 최소 100 GB 스토리지 공간.
- Docker와 Docker Compose를 설치해야 합니다.
- GitLab 버전은 18.1 이상이어야 합니다.
- GitLab 인스턴스를 통합관찰 인스턴스에 연결해야 합니다.

### 서버와 스토리지 프로비저닝 {#provision-server-and-storage}

AWS EC2의 경우:

1. 최소 2 vCPU와 8 GB RAM이 있는 EC2 인스턴스를 시작합니다.
1. 최소 100 GB의 EBS 볼륨을 추가합니다.
1. SSH를 사용하여 인스턴스에 연결합니다.

#### 스토리지 볼륨 마운트 {#mount-storage-volume}

```shell
sudo mkdir -p /mnt/data
sudo mount /dev/xvdbb /mnt/data  # Replace xvdbb with your volume name
sudo chown -R $(whoami):$(whoami) /mnt/data
```

영구 마운트의 경우 `/etc/fstab`에 추가합니다:

```shell
echo '/dev/xvdbb /mnt/data ext4 defaults,nofail 0 2' | sudo tee -a /etc/fstab
```

### Docker 설치 {#install-docker}

Ubuntu/Debian의 경우:

```shell
sudo apt update
sudo apt install -y docker.io docker-compose
sudo systemctl enable docker
sudo systemctl start docker
sudo usermod -aG docker $(whoami)
```

Amazon Linux의 경우:

```shell
sudo dnf update
sudo dnf install -y docker
sudo systemctl enable docker
sudo systemctl start docker
sudo usermod -aG docker $(whoami)
```

로그아웃했다가 다시 로그인하거나 다음을 실행합니다:

```shell
newgrp docker
```

#### 마운트된 볼륨을 사용하도록 Docker 구성 {#configure-docker-to-use-the-mounted-volume}

```shell
sudo mkdir -p /mnt/data/docker
sudo bash -c 'cat > /etc/docker/daemon.json << EOF
{
  "data-root": "/mnt/data/docker"
}
EOF'
sudo systemctl restart docker
```

다음으로 확인합니다:

```shell
docker info | grep "Docker Root Dir"
```

#### GitLab Observability 설치 {#install-gitlab-observability}

```shell
cd /mnt/data
git clone -b main https://gitlab.com/gitlab-org/embody-team/experimental-observability/gitlab_o11y.git
cd gitlab_o11y/deploy/docker
docker-compose up -d
```

타임아웃 오류가 발생하면 다음을 사용합니다:

```shell
COMPOSE_HTTP_TIMEOUT=300 docker-compose up -d
```

#### 선택 사항:  외부 ClickHouse 데이터베이스 사용 {#optional-use-an-external-clickhouse-database}

원하는 경우 자신의 ClickHouse 데이터베이스를 사용할 수 있습니다.

전제 조건:

- 외부 ClickHouse 인스턴스에 액세스할 수 있는지 확인하고 필요한 인증 자격 증명으로 올바르게 구성합니다.

`docker-compose up -d`를 실행하기 전에 다음 단계를 완료합니다:

1. `docker-compose.yml` 파일을 엽니다.
1. 다음을 주석 처리합니다:
   - `clickhouse` 및 `zookeeper` 서비스.
   - `x-clickhouse-defaults` 및 `x-clickhouse-depend` 섹션.
1. 다음 파일에서 `clickhouse:9000`의 모든 항목을 관련 ClickHouse 엔드포인트 및 TCP 포트(예: `my-clickhouse.example.com:9000`)로 바꿉니다. ClickHouse 인스턴스에 인증이 필요한 경우 연결 문자열을 업데이트하여 자격 증명을 포함해야 할 수도 있습니다:
   - `docker-compose.yml`
   - `otel-collector-config.yaml`
   - `prometheus-config.yml`

### GitLab Observability의 네트워크 액세스 구성 {#configure-network-access-for-gitlab-observability}

원격 분석 데이터를 올바르게 수신하려면 GitLab Observability 인스턴스의 보안 그룹에서 특정 포트를 열어야 합니다:

1. **AWS Console** > **EC2** > **Security Groups**로 이동합니다.
1. GitLab Observability 인스턴스에 연결된 보안 그룹을 선택합니다.
1. **Edit inbound rules**를 선택합니다.
1. 다음 규칙을 추가합니다:
   - 유형: Custom TCP, 포트: 8080, 소스: 자신의 IP 또는 0.0.0.0/0 (UI 액세스용)
   - 유형: Custom TCP, 포트: 4317, 소스: 자신의 IP 또는 0.0.0.0/0 (OTLP gRPC용)
   - 유형: Custom TCP, 포트: 4318, 소스: 자신의 IP 또는 0.0.0.0/0 (OTLP HTTP용)
   - 유형: Custom TCP, 포트: 9411, 소스: 자신의 IP 또는 0.0.0.0/0 (Zipkin용 - 선택 사항)
   - 유형: Custom TCP, 포트: 14268, 소스: 자신의 IP 또는 0.0.0.0/0 (Jaeger HTTP용 - 선택 사항)
   - 유형: Custom TCP, 포트: 14250, 소스: 자신의 IP 또는 0.0.0.0/0 (Jaeger gRPC용 - 선택 사항)
1. **Save rules**를 선택합니다.

이제 다음 위치에서 GitLab Observability UI에 액세스합니다:

```plaintext
http://[your-instance-ip]:8080
```

### 그룹의 URL 구성 {#configure-the-url-for-your-group}

Rails 콘솔을 사용하여 그룹의 GitLab Observability URL을 구성합니다:

1. Rails 콘솔에 액세스합니다:

   ```shell
   docker exec -it gitlab gitlab-rails console
   ```

1. 그룹의 통합관찰 설정을 구성합니다:

   ```ruby
   group = Group.find_by_path('your-group-name')

   Observability::GroupO11ySetting.create!(
     group_id: group.id,
     o11y_service_url: 'your-o11y-instance-url',
     o11y_service_user_email: 'your-email@example.com',
     o11y_service_password: 'your-secure-password',
     o11y_service_post_message_encryption_key: 'your-super-secret-encryption-key-here-32-chars-minimum'
   )
   ```

   바꾸기:
   - `your-group-name`을 실제 그룹 경로로 바꿉니다.
   - `your-o11y-instance-url`을 GitLab Observability 인스턴스 URL(예: `http://192.168.1.100:8080`)로 바꿉니다.
   - 이메일 및 비밀번호를 원하는 자격 증명으로 바꿉니다.
   - 암호화 키를 보안 32자 이상의 문자열로 바꿉니다.

## 다음 단계 {#next-steps}

- [GitLab Observability로 텔레메트리 데이터 전송](send.md).
- [CI/CD 파이프라인 텔레메트리 표시](ci_cd.md).
- [문제 해결 정보 얻기](troubleshooting.md).
