---
stage: Tenant Scale
group: Gitaly
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Gitaly TLS 지원
---

Gitaly는 TLS 암호화를 지원합니다. 보안 연결을 대기하는 Gitaly 인스턴스와 통신하려면 GitLab 구성의 해당 저장소 항목에서 `tls://` URL 스키마를 `gitaly_address`에 사용하세요.

Gitaly는 TLS 연결에서 GitLab으로의 클라이언트 인증서와 동일한 서버 인증서를 제공합니다. 클라이언트 인증서를 검증하는 역방향 프록시(예: NGINX)와 결합할 때 GitLab에 대한 액세스를 부여하는 상호 TLS 인증 전략의 일부로 사용할 수 있습니다.

자동으로 제공되지 않으므로 자신의 인증서를 직접 제공해야 합니다. 각 Gitaly 서버에 해당하는 인증서를 해당 Gitaly 서버에 설치해야 합니다.

또한 인증서(또는 그 인증 기관)를 다음 모든 위치에 설치해야 합니다:

- Gitaly 서버입니다.
- 이와 통신하는 Gitaly 클라이언트입니다.

로드 밸런서를 사용하는 경우, ALPN TLS 확장을 사용하여 HTTP/2를 협상할 수 있어야 합니다.

## 인증서 요구 사항 {#certificate-requirements}

- 인증서는 Gitaly 서버에 액세스할 때 사용하는 주소를 지정해야 합니다. 호스트 이름 또는 IP 주소를 주체 대체 이름(Subject Alternative Name)으로 인증서에 추가해야 합니다.
- Gitaly 서버를 암호화되지 않은 수신 주소 `listen_addr`와 암호화된 수신 주소 `tls_listen_addr`로 동시에 구성할 수 있습니다. 이를 통해 필요한 경우 암호화되지 않은 트래픽에서 암호화된 트래픽으로 점진적으로 전환할 수 있습니다.
- 인증서의 Common Name 필드는 무시됩니다.

## TLS를 사용하여 Gitaly 구성 {#configure-gitaly-with-tls}

{{< history >}}

- 최소 TLS 버전 구성 옵션이 GitLab 17.11에서 [도입되었습니다](https://gitlab.com/gitlab-org/gitaly/-/merge_requests/7755).

{{< /history >}}

TLS 지원을 구성하기 전에 [Gitaly를 구성하세요](configure_gitaly.md).

TLS 지원 구성 프로세스는 설치 유형에 따라 다릅니다.

{{< tabs >}}

{{< tab title="Linux 패키지(Omnibus)" >}}

1. Gitaly 서버용 인증서를 생성합니다.
1. Gitaly 클라이언트에서 인증서(또는 인증 기관)를 `/etc/gitlab/trusted-certs`에 복사합니다:

   ```shell
   sudo cp cert.pem /etc/gitlab/trusted-certs/
   ```

1. Gitaly 클라이언트에서 `/etc/gitlab/gitlab.rb`의 `gitlab_rails['repositories_storages']`를 다음과 같이 편집합니다:

   ```ruby
   gitlab_rails['repositories_storages'] = {
     'default' => { 'gitaly_address' => 'tls://gitaly1.internal:9999' },
     'storage1' => { 'gitaly_address' => 'tls://gitaly1.internal:9999' },
     'storage2' => { 'gitaly_address' => 'tls://gitaly2.internal:9999' },
   }
   ```

1. 파일을 저장하고 [GitLab을 다시 구성합니다](../restart_gitlab.md#reconfigure-a-linux-package-installation).
1. Gitaly 서버에서 `/etc/gitlab/ssl` 디렉토리를 생성하고 키 및 인증서를 여기에 복사합니다:

   ```shell
   sudo mkdir -p /etc/gitlab/ssl
   sudo chmod 755 /etc/gitlab/ssl
   sudo cp key.pem cert.pem /etc/gitlab/ssl/
   sudo chmod 644 /etc/gitlab/ssl/cert.pem
   sudo chmod 600 /etc/gitlab/ssl/key.pem
   # For Linux package installations, 'git' is the default username. Modify the following command if it was changed from the default
   sudo chown -R git /etc/gitlab/ssl
   ```

1. 모든 Gitaly 서버 인증서(또는 인증 기관)를 모든 Gitaly 서버 및 클라이언트의 `/etc/gitlab/trusted-certs`에 복사하여 Gitaly 서버와 클라이언트가 자신에게 호출하거나 다른 Gitaly 서버에 호출할 때 인증서를 신뢰하도록 합니다:

   ```shell
   sudo cp cert1.pem cert2.pem /etc/gitlab/trusted-certs/
   ```

1. `/etc/gitlab/gitlab.rb`를 편집하고 다음을 추가합니다:

   <!-- Updates to following example must also be made at <https://gitlab.com/gitlab-org/charts/gitlab/blob/master/doc/advanced/external-gitaly/external-omnibus-gitaly.md#configure-linux-package-installation> -->

   ```ruby
   gitaly['configuration'] = {
      # ...
      tls_listen_addr: '0.0.0.0:9999',
      tls: {
        certificate_path: '/etc/gitlab/ssl/cert.pem',
        key_path: '/etc/gitlab/ssl/key.pem',
        ## Optionally configure the minimum TLS version Gitaly offers to clients.
        ##
        ## Default: "TLS 1.2"
        ## Options: ["TLS 1.2", "TLS 1.3"].
        #
        # min_version: "TLS 1.2"
      },
   }
   ```

1. 파일을 저장하고 [GitLab을 다시 구성합니다](../restart_gitlab.md#reconfigure-a-linux-package-installation).
1. Gitaly 클라이언트(예: Rails 애플리케이션)에서 `sudo gitlab-rake gitlab:gitaly:check`를 실행하여 Gitaly 서버에 연결할 수 있는지 확인합니다.
1. [Gitaly 연결 유형 관찰](#observe-type-of-gitaly-connections)을 통해 Gitaly 트래픽이 TLS를 통해 제공되는지 확인합니다.
1. 선택사항. 다음과 같이 보안을 개선합니다:
   1. `/etc/gitlab/gitlab.rb`에서 `gitaly['configuration'][:listen_addr]`를 주석 처리하거나 삭제하여 비-TLS 연결을 비활성화합니다.
   1. 파일을 저장합니다.
   1. [GitLab 다시 구성](../restart_gitlab.md#reconfigure-a-linux-package-installation)합니다.

{{< /tab >}}

{{< tab title="자체 컴파일(소스)" >}}

1. Gitaly 서버용 인증서를 생성합니다.
1. Gitaly 클라이언트에서 인증서를 시스템 신뢰 인증서에 복사합니다:

   ```shell
   sudo cp cert.pem /usr/local/share/ca-certificates/gitaly.crt
   sudo update-ca-certificates
   ```

1. Gitaly 클라이언트에서 `/home/git/gitlab/config/gitlab.yml`의 `storages`를 편집하여 `gitaly_address`를 TLS 주소를 사용하도록 변경합니다. 예를 들어:

   ```yaml
   gitlab:
     repositories:
       storages:
         default:
           gitaly_address: tls://gitaly1.internal:9999
           gitaly_token: AUTH_TOKEN_1
         storage1:
           gitaly_address: tls://gitaly1.internal:9999
           gitaly_token: AUTH_TOKEN_1
         storage2:
           gitaly_address: tls://gitaly2.internal:9999
           gitaly_token: AUTH_TOKEN_2
   ```

1. 파일을 저장하고 [GitLab을 다시 시작합니다](../restart_gitlab.md#self-compiled-installations).
1. Gitaly 서버에서 `/etc/default/gitlab`를 생성하거나 편집하고 다음을 추가합니다:

   ```shell
   export SSL_CERT_DIR=/etc/gitlab/ssl
   ```

1. Gitaly 서버에서 `/etc/gitlab/ssl` 디렉토리를 생성하고 키 및 인증서를 여기에 복사합니다:

   ```shell
   sudo mkdir -p /etc/gitlab/ssl
   sudo chmod 755 /etc/gitlab/ssl
   sudo cp key.pem cert.pem /etc/gitlab/ssl/
   sudo chmod 644 /etc/gitlab/ssl/cert.pem
   sudo chmod 600 /etc/gitlab/ssl/key.pem
   # Set ownership to the same user that runs Gitaly
   sudo chown -R git /etc/gitlab/ssl
   ```

1. 모든 Gitaly 서버 인증서(또는 인증 기관)를 시스템 신뢰 인증서 폴더에 복사하여 Gitaly 서버가 자신에게 호출하거나 다른 Gitaly 서버에 호출할 때 인증서를 신뢰하도록 합니다.

   ```shell
   sudo cp cert.pem /usr/local/share/ca-certificates/gitaly.crt
   sudo update-ca-certificates
   ```

1. `/home/git/gitaly/config.toml`를 편집하고 다음을 추가합니다:

   ```toml
   tls_listen_addr = '0.0.0.0:9999'

   [tls]
   certificate_path = '/etc/gitlab/ssl/cert.pem'
   key_path = '/etc/gitlab/ssl/key.pem'
   ```

1. 파일을 저장하고 [GitLab을 다시 시작합니다](../restart_gitlab.md#self-compiled-installations).
1. [Gitaly 연결 유형 관찰](#observe-type-of-gitaly-connections)을 통해 Gitaly 트래픽이 TLS를 통해 제공되는지 확인합니다.
1. 선택사항. 다음과 같이 보안을 개선합니다:
   1. `/home/git/gitaly/config.toml`에서 `listen_addr`를 주석 처리하거나 삭제하여 비-TLS 연결을 비활성화합니다.
   1. 파일을 저장합니다.
   1. [GitLab 다시 시작](../restart_gitlab.md#self-compiled-installations)합니다.

{{< /tab >}}

{{< /tabs >}}

### 인증서 업데이트 {#update-the-certificates}

초기 구성 후 Gitaly 인증서를 업데이트하려면:

{{< tabs >}}

{{< tab title="Linux 패키지(Omnibus)" >}}

`/etc/gitlab/ssl` 디렉토리의 SSL 인증서 내용이 업데이트되었지만 `/etc/gitlab/gitlab.rb`에 대한 구성 변경이 없으면 GitLab을 다시 구성해도 Gitaly에 영향을 주지 않습니다. 대신 Gitaly 프로세스에서 인증서를 로드할 수 있도록 Gitaly를 수동으로 다시 시작해야 합니다:

```shell
sudo gitlab-ctl restart gitaly
```

`/etc/gitlab/trusted-certs`의 인증서를 변경하거나 업데이트하고 `/etc/gitlab/gitlab.rb` 파일에 변경을 하지 않으면 다음을 수행해야 합니다:

1. 신뢰 인증서의 심볼릭 링크가 업데이트되도록 [GitLab을 다시 구성합니다](../restart_gitlab.md#reconfigure-a-linux-package-installation).
1. Gitaly 프로세스에서 인증서를 로드할 수 있도록 Gitaly를 수동으로 다시 시작합니다:

   ```shell
   sudo gitlab-ctl restart gitaly
   ```

{{< /tab >}}

{{< tab title="자체 컴파일(소스)" >}}

`/etc/gitlab/ssl` 디렉토리의 SSL 인증서 내용이 업데이트된 경우, Gitaly 프로세스에서 인증서를 로드할 수 있도록 [GitLab을 다시 시작](../restart_gitlab.md#self-compiled-installations)해야 합니다.

`/usr/local/share/ca-certificates`의 인증서를 변경하거나 업데이트하면 다음을 수행해야 합니다:

1. `sudo update-ca-certificates`를 실행하여 시스템의 신뢰 저장소를 업데이트합니다.
1. Gitaly 프로세스에서 인증서를 로드할 수 있도록 [GitLab을 다시 시작](../restart_gitlab.md#self-compiled-installations)합니다.

{{< /tab >}}

{{< /tabs >}}

## Gitaly 연결 유형 관찰 {#observe-type-of-gitaly-connections}

제공되는 Gitaly 연결 유형 관찰에 대한 자세한 정보는 [관련 문서](monitoring.md#queries)를 참조하세요.
