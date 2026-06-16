---
stage: GitLab Delivery
group: Build
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 패키지 기본값
---

{{< details >}}

- 계층:  Free, Premium, Ultimate
- 제공:  GitLab Self-Managed

{{< /details >}}

`/etc/gitlab/gitlab.rb` 파일에 구성이 지정되지 않은 경우, 패키지는 아래에 표시된 기본값을 가정합니다.

## 포트 {#ports}

Linux 패키지가 기본적으로 할당하는 포트 목록은 아래 표를 참조하세요:

| 구성 요소                 | 기본적으로 활성화 | 통신 방식 | 대체 방법   | 연결 포트 |
|:-------------------------:|:-------------:|:----------------:|:-------------:|:----------------|
| GitLab Rails              | 예           | 포트             |               | `80` 또는 `443`   |
| GitLab Shell              | 예           | 포트             |               | `22`            |
| PostgreSQL                | 예           | 소켓           | 포트 (`5432`) |                 |
| Redis                     | 예           | 소켓           | 포트 (`6379`) |                 |
| Puma                      | 예           | 소켓           | 포트 (`8080`) |                 |
| GitLab Workhorse          | 예           | 소켓           | 포트 (`8181`) |                 |
| NGINX 상태              | 예           | 포트             |               | `8060`          |
| Prometheus                | 예           | 포트             |               | `9090`          |
| Node exporter             | 예           | 포트             |               | `9100`          |
| Redis exporter            | 예           | 포트             |               | `9121`          |
| PostgreSQL exporter       | 예           | 포트             |               | `9187`          |
| PgBouncer exporter        | 아니오            | 포트             |               | `9188`          |
| GitLab Exporter           | 예           | 포트             |               | `9168`          |
| Sidekiq exporter          | 예           | 포트             |               | `8082`          |
| Sidekiq 상태 확인      | 예           | 포트             |               | `8092` <sup>1</sup> |
| Web exporter              | 아니오            | 포트             |               | `8083`          |
| Geo PostgreSQL            | 아니오            | 소켓           | 포트 (`5431`) |                 |
| Redis Sentinel            | 아니오            | 포트             |               | `26379`         |
| 수신 이메일            | 아니오            | 포트             |               | `143`           |
| Elasticsearch            | 아니오            | 포트             |               | `9200`          |
| GitLab Pages              | 아니오            | 포트             |               | `80` 또는 `443`   |
| GitLab Registry           | 아니오*           | 포트             |               | `80`, `443` 또는 `5050` |
| GitLab Registry           | 아니오            | 포트             |               | `5000`          |
| LDAP                      | 아니오            | 포트             |               | 구성 요소 설정에 따라 다름 |
| Kerberos                  | 아니오            | 포트             |               | `8443` 또는 `8088` |
| OmniAuth                  | 예           | 포트             |               | 구성 요소 설정에 따라 다름 |
| SMTP                      | 아니오            | 포트             |               | `465`           |
| 원격 syslog             | 아니오            | 포트             |               | `514`           |
| Mattermost                | 아니오            | 포트             |               | `8065`          |
| Mattermost                | 아니오            | 포트             |               | `80` 또는 `443`   |
| PgBouncer                 | 아니오            | 포트             |               | `6432`          |
| Consul                    | 아니오            | 포트             |               | `8300`, `8301`(TCP 및 UDP), `8500`, `8600` <sup>2</sup> |
| Patroni                   | 아니오            | 포트             |               | `8008`          |
| GitLab KAS                | 예           | 포트             |               | `8150`          |
| Gitaly                    | 예           | 소켓           | 포트 (`8075`) | `8075` 또는 `9999` (TLS) |
| Gitaly exporter           | 예           | 포트             |               | `9236`          |
| Praefect                  | 아니오            | 포트             |               | `2305` 또는 `3305` (TLS) |
| GitLab Workhorse exporter | 예           | 포트             |               | `9229`          |
| Registry exporter         | 아니오            | 포트             |               | `5001`          |

**각주**:

1. Sidekiq 상태 확인 설정이 지정되지 않은 경우, Sidekiq 메트릭 exporter 설정이 기본값으로 적용됩니다. 이 기본값은 더 이상 사용되지 않으며 [GitLab 15.0](https://gitlab.com/gitlab-org/gitlab/-/issues/347509)에서 제거될 예정입니다.
1. 추가 Consul 기능을 사용하는 경우, 더 많은 포트를 열어야 할 수 있습니다. 목록은 [공식 설명서](https://developer.hashicorp.com/consul/docs/install/ports#ports-table)를 참조하세요.

범례:

- `Component` - 구성 요소의 이름입니다.
- `On by default` - 구성 요소가 기본적으로 실행 중인지 여부입니다.
- `Communicates via` - 구성 요소가 다른 구성 요소와 통신하는 방식입니다.
- `Alternative` - 구성 요소를 다른 유형의 통신을 사용하도록 구성할 수 있는지 여부입니다. 유형은 해당 경우에 사용되는 기본 포트와 함께 나열됩니다.
- `Connection port` - 구성 요소가 통신하는 포트입니다.

GitLab은 또한 Git 리포지토리 및 기타 다양한 파일 저장을 위해 파일 시스템이 준비되어 있어야 합니다.

NFS(네트워크 파일 시스템)를 사용하는 경우, 파일은 네트워크를 통해 전송되며, 구현에 따라 포트 `111`과(와) `2049`를 열어야 합니다.

> [!note]
> 일부 경우에는 GitLab Registry가 기본적으로 자동으로 활성화됩니다. 자세한 내용은 [GitLab 컨테이너 레지스트리 관리](../packages/container_registry.md)를 참조하세요.
