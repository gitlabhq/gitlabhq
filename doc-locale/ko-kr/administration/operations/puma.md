---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: GitLab 패키지의 번들된 Puma 인스턴스 구성
---

{{< details >}}

- 계층:  Free, Premium, Ultimate
- 제공:  GitLab Self-Managed

{{< /details >}}

Puma는 Ruby 애플리케이션을 위한 빠르고 다중 스레드이며 높은 동시성을 갖춘 HTTP 1.1 서버입니다. GitLab의 사용자 중심 기능을 제공하는 핵심 Rails 애플리케이션을 실행합니다.

## 메모리 사용 튜닝 {#tuning-memory-use}

메모리 사용을 줄이기 위해 Puma는 워커 프로세스를 포크합니다. 워커를 생성할 때마다 주 프로세스와 메모리를 공유합니다. 워커는 메모리 페이지를 변경하거나 추가할 때만 추가 메모리를 사용합니다. 워커가 추가 웹 요청을 처리하면서 시간이 지남에 따라 Puma 워커가 더 많은 물리 메모리를 사용할 수 있습니다. 시간이 지남에 따라 사용되는 메모리의 양은 GitLab의 사용 방식에 따라 다릅니다. GitLab 사용자가 더 많은 기능을 사용할수록 시간이 지남에 따라 예상되는 메모리 사용이 높아집니다.

제어되지 않은 메모리 증가를 막기 위해 GitLab Rails 애플리케이션은 감시 스레드를 실행하여 워커가 특정 시간 동안 주어진 상주 집합 크기(RSS) 임계값을 초과하면 자동으로 워커를 다시 시작합니다.

GitLab은 메모리 제한에 대해 `1500Mb`의 기본값을 설정합니다. 기본값을 재정의하려면 `per_worker_max_memory_mb`을(를) 새 RSS 제한(메가바이트)으로 설정합니다:

1. `/etc/gitlab/gitlab.rb`을 편집합니다:

   ```ruby
   puma['per_worker_max_memory_mb'] = 1200 # 1.2 GB
   ```

1. GitLab을 다시 구성합니다:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

워커를 다시 시작하면 GitLab을 실행할 용량이 짧은 기간 동안 줄어듭니다. 워커가 너무 자주 교체되면 `per_worker_max_memory_mb`을(를) 더 높은 값으로 설정합니다.

워커 수는 CPU 코어를 기반으로 계산됩니다. 4~8개의 워커를 가진 소규모 GitLab 배포는 워커가 너무 자주(분당 1회 이상) 다시 시작되는 경우 성능 문제가 발생할 수 있습니다.

서버에 여유 메모리가 있으면 더 높은 `per_worker_max_memory_mb` 값이 유익할 수 있습니다.

## 데이터베이스 연결 계획 {#plan-the-database-connections}

Puma 워커 또는 스레드를 증가시키기 전에 PostgreSQL `max_connections` 설정에 대한 데이터베이스 연결 영향을 고려합니다.

[PostgreSQL 튜닝](../postgresql/tune.md) 페이지를 참조하세요.

### 워커 다시 시작 모니터링 {#monitor-worker-restarts}

높은 메모리 사용으로 인해 워커가 다시 시작되면 GitLab에서 로그 이벤트를 생성합니다.

다음은 `/var/log/gitlab/gitlab-rails/application_json.log`의 이러한 로그 이벤트 중 하나의 예입니다:

```json
{
  "severity": "WARN",
  "time": "2023-01-04T09:45:16.173Z",
  "correlation_id": null,
  "pid": 2725,
  "worker_id": "puma_0",
  "memwd_handler_class": "Gitlab::Memory::Watchdog::PumaHandler",
  "memwd_sleep_time_s": 5,
  "memwd_rss_bytes": 1077682176,
  "memwd_max_rss_bytes": 629145600,
  "memwd_max_strikes": 5,
  "memwd_cur_strikes": 6,
  "message": "rss memory limit exceeded"
}
```

`memwd_rss_bytes`은(는) 실제 메모리 사용량이고, `memwd_max_rss_bytes`은(는) `per_worker_max_memory_mb`을(를) 통해 설정되거나 [`DEFAULT_PUMA_WORKER_RSS_LIMIT_MB`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/memory/watchdog/configurator.rb)에 의해 정의된 RSS 제한입니다.

## 워커 시간 초과 변경 {#change-the-worker-timeout}

기본 Puma [시간 초과는 60초](https://gitlab.com/gitlab-org/gitlab/-/blob/master/config/initializers/rack_timeout.rb)입니다.

> [!note]
> `puma['worker_timeout']` 설정은 최대 요청 기간을 설정하지 않습니다.

워커 시간 초과를 600초로 변경하려면:

1. `/etc/gitlab/gitlab.rb`을 편집합니다:

   ```ruby
   gitlab_rails['env'] = {
      'GITLAB_RAILS_RACK_TIMEOUT' => 600
    }
   ```

1. GitLab을 다시 구성합니다:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

## 메모리 제약 환경에서 Puma 클러스터 모드 비활성화 {#disable-puma-clustered-mode-in-memory-constrained-environments}

> [!warning]
> 이 기능은 [실험](../../policy/development_stages_support.md#experiment)이며 예고 없이 변경될 수 있습니다. 이 기능은 프로덕션 사용을 위해 준비되지 않았습니다. 이 기능을 사용하려면 프로덕션 외부에서 먼저 테스트해야 합니다. 자세한 내용은 [알려진 문제](#puma-single-mode-known-issues)를 참조하세요.

4GB 미만의 RAM을 사용할 수 있는 메모리 제약 환경에서는 Puma [클러스터 모드](https://github.com/puma/puma#clustered-mode)를 비활성화하는 것을 고려합니다.

`workers`의 수를 `0`로 설정하여 메모리 사용을 수백 MB 줄입니다:

1. `/etc/gitlab/gitlab.rb`을 편집합니다:

   ```ruby
   puma['worker_processes'] = 0
   ```

1. GitLab을 다시 구성합니다:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

기본적으로 설정되는 클러스터 모드와 달리 단일 Puma 프로세스만 애플리케이션을 제공합니다. Puma 워커 및 스레드 설정에 대한 자세한 내용은 [Puma 요구사항](../../install/requirements.md#puma)을(를) 참조하세요.

이 구성에서 Puma를 실행하는 단점은 메모리 제약 환경에서 공정한 트레이드오프로 간주될 수 있는 처리량이 감소합니다.

메모리 부족(OOM) 조건을 피하기 위해 충분한 스왑을 사용할 수 있도록 해야 합니다. 자세한 내용은 [메모리 요구사항](../../install/requirements.md#memory)을(를) 참조하세요.

### Puma 단일 모드 알려진 문제 {#puma-single-mode-known-issues}

Puma를 단일 모드에서 실행할 때 일부 기능이 지원되지 않습니다:

- [단계별 다시 시작](https://gitlab.com/gitlab-org/gitlab/-/issues/300665)
- [메모리 킬러](#tuning-memory-use)

자세한 내용은 [에픽 5303](https://gitlab.com/groups/gitlab-org/-/epics/5303)을(를) 참조하세요.

## SSL을 통해 수신하도록 Puma 구성 {#configuring-puma-to-listen-over-ssl}

Puma는 Linux 패키지 설치로 배포할 때 기본적으로 Unix 소켓을 통해 수신합니다. 대신 HTTPS 포트를 통해 수신하도록 Puma를 구성하려면 아래 단계를 따릅니다:

1. Puma가 수신할 주소에 대해 SSL 인증서 키 쌍을 생성합니다. 아래 예에서는 `127.0.0.1`입니다.

   > [!note]
   > 자체 서명된 인증서를 사용자 지정 인증 기관(CA)에서 사용하는 경우 [설명서](https://docs.gitlab.com/omnibus/settings/ssl/#install-custom-public-certificates)를 따라 다른 GitLab 구성 요소에서 신뢰할 수 있도록 합니다.

1. `/etc/gitlab/gitlab.rb`을 편집합니다:

   ```ruby
   puma['ssl_listen'] = '127.0.0.1'
   puma['ssl_port'] = 9111
   puma['ssl_certificate'] = '<path_to_certificate>'
   puma['ssl_certificate_key'] = '<path_to_key>'

   # Disable UNIX socket
   puma['socket'] = ""
   ```

1. GitLab을 다시 구성합니다:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

> [!note]
> Unix 소켓 외에도 Puma는 Prometheus로 스크래핑할 메트릭을 제공하기 위해 포트 8080의 HTTP를 통해 수신합니다. Prometheus가 HTTPS를 통해 이를 스크래핑하는 것은 불가능하며, [이 문제](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/6811)에서 지원에 대해 논의하고 있습니다. 따라서 Prometheus 메트릭을 잃지 않으면서 이 HTTP 리스너를 끄는 것은 기술적으로 불가능합니다.

### 암호화된 SSL 키 사용 {#using-an-encrypted-ssl-key}

{{< history >}}

- GitLab 16.1에서 [도입](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/7799)되었습니다.

{{< /history >}}

Puma는 암호화된 프라이빗 SSL 키 사용을 지원하며, 이는 런타임에 해독할 수 있습니다. 다음 지침은 이를 구성하는 방법을 보여줍니다:

1. 아직 암호화되지 않은 경우 키를 암호로 암호화합니다:

   ```shell
   openssl rsa -aes256 -in /path/to/ssl-key.pem -out /path/to/encrypted-ssl-key.pem
   ```

   암호화된 파일을 작성하기 위해 암호를 두 번 입력합니다. 이 예에서는 `some-password-here`을(를) 사용합니다.

1. 암호를 출력하는 스크립트 또는 실행 파일을 만듭니다. 예를 들어 `/var/opt/gitlab/gitlab-rails/etc/puma-ssl-key-password`에서 암호를 반향하는 기본 스크립트를 만듭니다:

   ```shell
   #!/bin/sh
   echo some-password-here
   ```

   디스크에 암호를 저장하지 않으며, Vault와 같은 암호를 검색하기 위한 안전한 메커니즘을 사용합니다. 예를 들어 스크립트는 다음과 같을 수 있습니다:

   ```shell
   #!/bin/sh
   export VAULT_ADDR=http://vault-password-distribution-point:8200
   export VAULT_TOKEN=<some token>

   echo "$(vault kv get -mount=secret puma-ssl-password)"
   ```

1. Puma 프로세스에 스크립트를 실행하고 암호화된 키를 읽기에 충분한 권한이 있는지 확인합니다:

   ```shell
   chown git:git /var/opt/gitlab/gitlab-rails/etc/puma-ssl-key-password
   chmod 770 /var/opt/gitlab/gitlab-rails/etc/puma-ssl-key-password
   chmod 660 /path/to/encrypted-ssl-key.pem
   ```

1. `/etc/gitlab/gitlab.rb`을(를) 편집하고, `puma['ssl_certificate_key']`을(를) 암호화된 키로 바꾸고 `puma['ssl_key_password_command]`을(를) 지정합니다:

   ```ruby
   puma['ssl_certificate_key'] = '/path/to/encrypted-ssl-key.pem'
   puma['ssl_key_password_command'] = '/var/opt/gitlab/gitlab-rails/etc/puma-ssl-key-password'
   ```

1. GitLab을 다시 구성합니다:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

1. GitLab이 성공적으로 시작되면 GitLab 인스턴스에 저장된 암호화되지 않은 SSL 키를 제거할 수 있습니다.

## Unicorn에서 Puma로 전환 {#switch-from-unicorn-to-puma}

> [!note]
> Helm 기반 배포의 경우 [`webservice` 차트 설명서](https://docs.gitlab.com/charts/charts/gitlab/webservice/)를 참조하세요.

Puma는 기본 웹 서버이며 Unicorn은 더 이상 지원되지 않습니다.

Puma는 Unicorn과 같은 다중 프로세스 애플리케이션 서버보다 적은 메모리를 사용하는 다중 스레드 아키텍처를 가집니다. GitLab.com에서 메모리 소비가 40% 감소했습니다. 대부분의 Rails 애플리케이션 요청에는 일반적으로 I/O 대기 시간의 비율이 포함됩니다.

I/O 대기 시간 동안 MRI Ruby는 GVL을 다른 스레드로 해제합니다. 따라서 다중 스레드 Puma는 여전히 단일 프로세스보다 더 많은 요청을 제공할 수 있습니다.

Puma로 전환할 때 두 애플리케이션 서버 간의 차이로 인해 Unicorn 서버 구성이 자동으로 수행되지 않습니다.

Unicorn에서 Puma로 전환하려면:

1. 적절한 Puma [워커 및 스레드 설정](../../install/requirements.md#puma)을(를) 결정합니다.
1. 모든 사용자 지정 Unicorn 설정을 `/etc/gitlab/gitlab.rb`의 Puma로 변환합니다.

   아래 표는 Linux 패키지를 사용할 때 Unicorn 구성 키가 Puma의 어떤 키에 해당하는지, 대응하는 항목이 없는 항목을 요약합니다.

   | Unicorn                              | Puma                               |
   | ------------------------------------ | ---------------------------------- |
   | `unicorn['enable']`                  | `puma['enable']`                   |
   | `unicorn['worker_timeout']`          | `puma['worker_timeout']`           |
   | `unicorn['worker_processes']`        | `puma['worker_processes']`         |
   | 해당 사항 없음                       | `puma['ha']`                       |
   | 해당 사항 없음                       | `puma['min_threads']`              |
   | 해당 사항 없음                       | `puma['max_threads']`              |
   | `unicorn['listen']`                  | `puma['listen']`                   |
   | `unicorn['port']`                    | `puma['port']`                     |
   | `unicorn['socket']`                  | `puma['socket']`                   |
   | `unicorn['pidfile']`                 | `puma['pidfile']`                  |
   | `unicorn['tcp_nopush']`              | 해당 사항 없음                     |
   | `unicorn['backlog_socket']`          | 해당 사항 없음                     |
   | `unicorn['somaxconn']`               | `puma['somaxconn']`                |
   | 해당 사항 없음                       | `puma['state_path']`               |
   | `unicorn['log_directory']`           | `puma['log_directory']`            |
   | `unicorn['worker_memory_limit_min']` | 해당 사항 없음                     |
   | `unicorn['worker_memory_limit_max']` | `puma['per_worker_max_memory_mb']` |
   | `unicorn['exporter_enabled']`        | `puma['exporter_enabled']`         |
   | `unicorn['exporter_address']`        | `puma['exporter_address']`         |
   | `unicorn['exporter_port']`           | `puma['exporter_port']`            |

1. GitLab을 다시 구성합니다:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

1. 선택사항. 다중 노드 배포의 경우 로드 밸런서를 [준비 상태 확인](../load_balancer.md#readiness-check)을(를) 사용하도록 구성합니다.

## Puma 문제 해결 {#troubleshooting-puma}

### Puma가 100% CPU에서 회전한 후 502 게이트웨이 시간 초과 {#502-gateway-timeout-after-puma-spins-at-100-cpu}

이 오류는 웹 서버가 시간 초과(기본값:  60초) Puma 워커로부터 응답을 받지 못한 후 발생합니다. CPU가 진행되는 동안 100%로 회전하면 예상보다 오래 걸리는 항목이 있을 수 있습니다.

이 문제를 해결하려면 먼저 어떤 일이 일어나고 있는지 파악해야 합니다. 다음 팁은 사용자가 다운타임의 영향을 받는 것을 신경 쓰지 않는 경우에만 권장됩니다. 그렇지 않으면 다음 섹션으로 건너뜁니다.

1. 문제가 있는 URL을 로드합니다
1. `sudo gdb -p <PID>`을(를) 실행하여 Puma 프로세스에 연결합니다.
1. GDB 창에서 입력합니다:

   ```plaintext
   call (void) rb_backtrace()
   ```

1. 이것은 프로세스가 Ruby 역추적을 생성하게 합니다. 역추적을 위해 `/var/log/gitlab/puma/puma_stderr.log`을(를) 확인합니다. 예를 들어 다음과 같은 것을 볼 수 있습니다:

   ```plaintext
   from /opt/gitlab/embedded/service/gitlab-rails/lib/gitlab/metrics/sampler.rb:33:in `block in start'
   from /opt/gitlab/embedded/service/gitlab-rails/lib/gitlab/metrics/sampler.rb:33:in `loop'
   from /opt/gitlab/embedded/service/gitlab-rails/lib/gitlab/metrics/sampler.rb:36:in `block (2 levels) in start'
   from /opt/gitlab/embedded/service/gitlab-rails/lib/gitlab/metrics/sampler.rb:44:in `sample'
   from /opt/gitlab/embedded/service/gitlab-rails/lib/gitlab/metrics/sampler.rb:68:in `sample_objects'
   from /opt/gitlab/embedded/service/gitlab-rails/lib/gitlab/metrics/sampler.rb:68:in `each_with_object'
   from /opt/gitlab/embedded/service/gitlab-rails/lib/gitlab/metrics/sampler.rb:68:in `each'
   from /opt/gitlab/embedded/service/gitlab-rails/lib/gitlab/metrics/sampler.rb:69:in `block in sample_objects'
   from /opt/gitlab/embedded/service/gitlab-rails/lib/gitlab/metrics/sampler.rb:69:in `name'
   ```

1. 현재 스레드를 보려면 다음을 실행합니다:

   ```plaintext
   thread apply all bt
   ```

1. `gdb`로 디버깅을 완료한 후 프로세스에서 분리되고 종료해야 합니다:

   ```plaintext
   detach
   exit
   ```

이러한 명령을 실행하기 전에 Puma 프로세스가 종료되면 GDB에서 오류를 보고합니다. 더 많은 시간을 벌기 위해 항상 Puma 워커 시간 초과를 높일 수 있습니다. Linux 패키지 설치 사용자의 경우 `/etc/gitlab/gitlab.rb`을(를) 편집하고 60초에서 600으로 증가시킬 수 있습니다:

```ruby
gitlab_rails['env'] = {
        'GITLAB_RAILS_RACK_TIMEOUT' => 600
}
```

자체 컴파일된 설치의 경우 환경 변수를 설정합니다. [Puma 워커 시간 초과](puma.md#change-the-worker-timeout)를 참조하세요.

변경 사항을 적용하려면 [다시 구성](../restart_gitlab.md#reconfigure-a-linux-package-installation)하세요.

#### 다른 사용자에게 영향을 주지 않고 문제 해결 {#troubleshooting-without-affecting-other-users}

이전 섹션은 실행 중인 Puma 프로세스에 연결했으며, 이는 이 기간 동안 GitLab에 접근하려는 사용자에게 바람직하지 않은 영향을 미칠 수 있습니다. 프로덕션 시스템 중에 다른 사용자에게 영향을 주는 것이 염려되면 별도의 Rails 프로세스를 실행하여 문제를 디버깅할 수 있습니다:

1. GitLab 계정에 로그인합니다.
1. 문제를 일으키는 URL을 복사합니다(예: `https://gitlab.com/ABC`).
1. 사용자에 대한 개인 액세스 토큰을 만듭니다(사용자 설정 -> 액세스 토큰).
1. [GitLab Rails 콘솔](rails_console.md#starting-a-rails-console-session)을(를) 불러옵니다.
1. Rails 콘솔에서 다음을 실행합니다:

   ```ruby
   app.get '<URL FROM STEP 2>/?private_token=<TOKEN FROM STEP 3>'
   ```

   예를 들어:

   ```ruby
   app.get 'https://gitlab.com/gitlab-org/gitlab-foss/-/issues/1?private_token=123456'
   ```

1. 새 창에서 `top`을(를) 실행합니다. 이 Ruby 프로세스가 100% CPU를 사용하는 것을 표시해야 합니다. PID를 기록합니다.
1. GDB 사용에 대한 이전 섹션의 2단계를 따릅니다.

### GitLab:  API에 액세스할 수 없음 {#gitlab-api-is-not-accessible}

이는 일반적으로 GitLab Shell이 내부 API를 통해 인증을 요청하려고 할 때(예: `http://localhost:8080/api/v4/internal/allowed`) 발생하며, 확인 중 무언가 실패합니다. 이 문제는 다음과 같은 이유로 발생할 수 있습니다:

1. 데이터베이스 연결 시간 초과(예: PostgreSQL 또는 Redis)
1. Git 후크 또는 푸시 규칙 오류
1. 리포지토리 접근 오류(예: 부실 NFS 핸들)

이 문제를 진단하려면 문제를 재현해 본 다음 `top`을(를) 통해 회전 중인 Puma 워커가 있는지 확인합니다. 이전에 문서화된 `gdb` 기법을 사용해 봅니다. 또한 `strace`을(를) 사용하면 문제를 격리하는 데 도움이 될 수 있습니다:

```shell
strace -ttTfyyy -s 1024 -p <PID of puma worker> -o /tmp/puma.txt
```

어떤 Puma 워커가 문제인지 격리할 수 없으면 모든 Puma 워커에서 `strace`을(를) 실행하여 `/internal/allowed` 엔드포인트가 어디서 중단되는지 확인해 봅니다:

```shell
ps auwx | grep puma | awk '{ print " -p " $2}' | xargs  strace -ttTfyyy -s 1024 -o /tmp/puma.txt
```

`/tmp/puma.txt`의 출력이 근본 원인을 진단하는 데 도움이 될 수 있습니다.

## 관련 항목 {#related-topics}

- [웹 메트릭을 내보낼 전용 메트릭 서버 사용](../monitoring/prometheus/web_exporter.md)
