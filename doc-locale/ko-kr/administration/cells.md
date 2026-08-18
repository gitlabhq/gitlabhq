---
stage: Runtime
group: Cells Infrastructure
info: Any user with the Maintainer or Owner role can merge updates to this content. For details, see <https://docs.gitlab.com/development/development_processes/#development-guidelines-review>.
title: 셀
description: GitLab.com 관리자를 위해 셀 기능 활성화 및 토폴로지 서비스 클라이언트 구성을 포함한 기능 테스트의 일부로 GitLab 셀 기능을 구성하고 테스트합니다.
---

{{< details >}}

- 제공 서비스: GitLab.com
- 상태:  실험 단계

{{< /details >}}

> [!disclaimer]

셀 기능을 테스트하려면 GitLab Rails 콘솔을 구성합니다.

> [!note]
> 이 기능은 GitLab.com의 관리자만 사용할 수 있습니다. 이 기능은 GitLab Self-Managed 또는 GitLab Dedicated 인스턴스에서 사용할 수 없습니다.
>
> Cells 1.0은 개발 중입니다. 셀 개발 상태에 대한 자세한 정보는 [에픽 12383](https://gitlab.com/groups/gitlab-org/-/epics/12383)을 참조하세요.

## 구성 {#configuration}

GitLab 인스턴스를 Cell 인스턴스로 구성하려면:

{{< tabs >}}

{{< tab title="자체 컴파일(소스)" >}}

`config/gitlab.yml`에서 셀 관련 구성은 다음 형식입니다:

```yaml
  cell:
    enabled: true
    id: 1
    database:
      skip_sequence_alteration: false
    topology_service_client:
      address: topology-service.gitlab.example.com:443
      ca_file: /home/git/gitlab/config/topology-service-ca.pem
      certificate_file: /home/git/gitlab/config/topology-service-cert.pem
      private_key_file: /home/git/gitlab/config/topology-service-key.pem
```

{{< /tab >}}

{{< tab title="Linux Package (Omnibus)" >}}

1. `/etc/gitlab/gitlab.rb`을(를) 편집하고 다음 줄을 추가하세요:

   ```ruby
   gitlab_rails['cell'] = {
     enabled: true,
     id: 1,
     database: {
       skip_sequence_alteration: false
     },
     topology_service_client: {
       enabled: true,
       address: 'topology-service.gitlab.example.com:443',
       ca_file: 'path/to/your/ca/.pem',
       certificate_file: 'path/to/your/cert/.pem',
       private_key_file: 'path/to/your/key/.pem'
     }
   }
   ```

1. GitLab을 다시 구성하고 재시작하세요:

   ```shell
   sudo gitlab-ctl reconfigure
   sudo gitlab-ctl restart
   ```

{{< /tab >}}

{{< tab title="Helm chart" >}}

1. `gitlab_values.yaml`을 편집합니다:

   ```yaml
   global:
     appConfig:
       cell:
         enabled: true
         id: 1
         database:
           skipSequenceAlteration: false
         topologyServiceClient:
           address: "topology-service.gitlab.example.com:443"
           tls:
             enabled: true
   ```

1. 파일을 저장하고 새 값을 적용하세요:

   ```shell
   helm upgrade -f gitlab_values.yaml gitlab gitlab/gitlab
   ```

{{< /tab >}}

{{< /tabs >}}

| 구성                                   | 기본값                                         | 설명                                                                                                                                                                                                                                                                                                                    |
|-------------------------------------------------|-------------------------------------------------------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `cell.enabled`                                  | `false`                                               | 인스턴스가 Cell인지 아닌지 구성합니다. `false`은(는) 모든 Cell 기능이 비활성화됨을 의미합니다. `session_cookie_prefix_token`은(는) 영향을 받지 않으며 별도로 설정할 수 있습니다.                                                                                                                                                    |
| `cell.id`                                       | `nil`                                                 | `cell.enabled`이(가) `true`일 때 양의 정수여야 합니다. 그렇지 않으면 `nil`이어야 합니다. 클러스터의 셀에 대한 고유한 정수 식별자입니다. 이 ID는 라우팅 가능한 토큰 내에서 사용됩니다. `cell.id`이(가) `nil`일 때, `organization_id`와 같은 라우팅 가능한 토큰 내의 다른 속성이 계속 사용됩니다. |
| `cell.database.skip_sequence_alteration`        | `false`                                               | `true`일 때 셀의 데이터베이스 시퀀스 변경을 건너뜁니다. 모놀리식 셀을 사용할 수 있게 되기 전에 레거시 셀(`cell-1`)에 대해 활성화합니다. 이 에픽에서 추적됩니다:  [Phase 6: Monolith Cell](https://gitlab.com/groups/gitlab-org/-/epics/14513).                                                                   |
| `cell.topology_service_client.address`          | `"topology-service.gitlab.example.com:443"`           | `cell.enabled`이(가) `true`일 때 필수입니다. 토폴로지 서비스 서버의 주소 및 포트입니다.                                                                                                                                                                                                                                       |
| `cell.topology_service_client.tls.enabled`      | `true`                                                | `true`일 때 토폴로지 서비스와의 통신을 위해 mTLS를 활성화합니다. 이를 위해서는 `cell.topology_service_client.tls.secret`이(가) 제대로 구성되어야 합니다. `false`으로 설정된 경우 TLS 암호화 없이 연결됩니다.                                                                                           |
| `cell.topology_service_client.tls.secret`       | `nil`                                                 | [Kubernetes TLS Secret](https://kubernetes.io/docs/reference/kubectl/generated/kubectl_create/kubectl_create_secret_tls/) mTLS 자격 증명을 포함하는 이름입니다. TLS가 활성화되어 있을 때 필수입니다. 시크릿은 `tls.crt` 및 `tls.key` 키를 포함해야 합니다. 명시적으로 설정하지 않으면 `<release.name>-topology-tls`으로 기본 설정됩니다. 이 시크릿은 **must be created manually**. Helm 차트는 자동으로 생성하지 않습니다.                |

## 관련 구성 {#related-configuration}

셀 아키텍처의 다른 구성 요소를 구성하는 방법에 대한 정보는 다음을 참조하세요:

1. [토폴로지 서비스 구성](https://gitlab.com/gitlab-org/cells/topology-service/-/blob/main/docs/config.md?ref_type=heads)
1. [HTTP 라우터 구성](https://gitlab.com/gitlab-org/cells/http-router/-/blob/main/docs/config.md?ref_type=heads)
