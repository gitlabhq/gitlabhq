---
stage: Tenant Scale
group: Gitaly
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 번들 URI
---

{{< details >}}

계층:  Free, Premium, Ultimate

제공:  GitLab Self-Managed

{{< /details >}}

{{< history >}}

- GitLab 17.0에서 [도입](https://gitlab.com/groups/gitlab-org/-/epics/8939)되었으며, `gitaly_bundle_uri` [플래그](../feature_flags/_index.md)로 표시되었습니다. 기본적으로 비활성화됨.

{{< /history >}}

Gitaly는 Git [번들 URI](https://git-scm.com/docs/bundle-uri)를 지원합니다. 번들 URI는 Git이 원격에서 나머지 객체를 가져오기 전에 하나 이상의 번들을 다운로드하여 객체 데이터베이스를 부트스트랩할 수 있는 위치입니다. 번들 URI는 Git 프로토콜에 기본적으로 내장되어 있습니다.

번들 URI를 사용하면 다음을 수행할 수 있습니다:

- GitLab 서버에 대한 네트워크 연결이 좋지 않은 사용자의 클론 및 페치 속도를 높입니다. 번들을 CDN에 저장하여 전 세계에서 사용 가능하게 할 수 있습니다.
- CI/CD 작업을 실행하는 서버의 로드를 줄입니다. CI/CD 작업이 다른 곳에서 번들을 미리 로드할 수 있으면, 누락된 객체 및 참조를 증분으로 가져오는 나머지 작업으로 인한 서버 로드가 훨씬 줄어듭니다.

## 필수 요구 사항 {#prerequisites}

번들 URI를 사용하기 위한 사전 조건은 CI/CD 작업에서 클론하는지 또는 터미널에서 로컬로 클론하는지에 따라 달라집니다.

### CI/CD 작업에서 클론 {#cloning-in-cicd-jobs}

CI/CD 작업에서 번들 URI를 사용하도록 준비하려면:

1. [GitLab Runner 도우미 이미지](https://gitlab.com/gitlab-org/gitlab-runner/container_registry/1472754)를 다음을 실행하는 버전으로 선택합니다:

   - Git 버전 2.49.0 이상입니다.
   - GitLab Runner 도우미 버전 18.0 이상입니다.

   번들 URI는 `git clone` 중에 Git 서버의 로드를 줄이는 것을 목표로 하는 메커니즘이므로 이 단계가 필요합니다. 따라서 CI/CD 파이프라인이 실행될 때 `git` 클라이언트가 `git clone` 명령을 시작하는 것은 GitLab Runner입니다. `git` 프로세스는 도우미 이미지 내에서 실행됩니다.

   GitLab 러너에 사용하는 운영 체제 배포 및 아키텍처에 해당하는 이미지를 선택했는지 확인하세요.

   다음 명령을 실행하여 이미지가 요구 사항을 충족하는지 확인할 수 있습니다:

   ```shell
   docker run -it <image:tag>
   $ git version
   $ gitlab-runner-helper -v
   ```

   운영 체제 배포의 패키지 관리자를 사용하여 `gitlab-runner-helper` 이미지에서 Git 버전을 관리하므로, 일부 최신 사용 가능 이미지는 여전히 Git 2.49를 실행하지 못할 수 있습니다. 따라서 일부 최신 사용 가능 이미지는 여전히 Git 2.49를 실행하지 못할 수 있습니다.

   요구 사항을 충족하는 이미지를 찾지 못한 경우 `gitlab-runner-helper`을(를) 자신의 커스텀 빌드 이미지의 기본 이미지로 사용합니다. [GitLab 컨테이너 레지스트리](../../user/packages/container_registry/_index.md)를 사용하여 커스텀 빌드 이미지에서 호스팅할 수 있습니다.

1. `config.toml` 파일을 업데이트하여 선택한 이미지를 사용하도록 GitLab Runner 인스턴스를 구성합니다:

   ```toml
   [[runners]]
     (...)
     executor = "docker"
     [runners.docker]
       (...)
       helper_image = "image:tag" ## <-- put the image name and tag here
   ```

    자세한 내용은 [도우미 이미지 정보](https://docs.gitlab.com/runner/configuration/advanced-configuration/#helper-image)를 참조하세요.

1. 새 구성을 적용하려면 러너를 다시 시작합니다.
1. `FF_USE_GIT_NATIVE_CLONE` [GitLab Runner 기능 플래그](https://docs.gitlab.com/runner/configuration/feature-flags/)를 `.gitlab-ci.yml` 파일에서 `true`로 설정하여 활성화합니다:

   ```yaml
   variables:
     FF_USE_GIT_NATIVE_CLONE: "true"
   ```

### 터미널에서 로컬로 클론 {#cloning-locally-in-your-terminal}

터미널에서 로컬로 클론하기 위해 번들 URI를 사용하도록 준비하려면, 로컬 Git 구성에서 `bundle-uri`을(를) 활성화합니다:

```shell
git config --global transfer.bundleuri true
```

## 서버 구성 {#server-configuration}

번들이 저장되는 위치를 구성해야 합니다. Gitaly는 다음 스토리지 서비스를 지원합니다:

- Google Cloud Storage
- AWS S3(또는 호환)
- Azure Blob Storage
- 로컬 파일 스토리지(권장하지 않음)

### Azure Blob 스토리지 구성 {#configure-azure-blob-storage}

Azure Blob 스토리지를 번들 URI에 구성하는 방법은 보유한 설치 유형에 따라 다릅니다. 자체 컴파일된 설치의 경우 GitLab 외부에서 `AZURE_STORAGE_ACCOUNT` 및 `AZURE_STORAGE_KEY` 환경 변수를 설정해야 합니다.

{{< tabs >}}

{{< tab title="Linux 패키지(Omnibus)" >}}

`/etc/gitlab/gitlab.rb`을(를) 편집하고 `bundle_uri.go_cloud_url`를 구성합니다:

```ruby
gitaly['env'] = {
    'AZURE_STORAGE_ACCOUNT' => 'azure_storage_account',
    'AZURE_STORAGE_KEY' => 'azure_storage_key' # or 'AZURE_STORAGE_SAS_TOKEN'
}
gitaly['configuration'] = {
    bundle_uri: {
        go_cloud_url: 'azblob://<bucket>'
    }
}
```

{{< /tab >}}

{{< tab title="자체 컴파일(소스)" >}}

`/home/git/gitaly/config.toml`을(를) 편집하고 `go_cloud_url`를 구성합니다:

```toml
[bundle_uri]
go_cloud_url = "azblob://<bucket>"
```

{{< /tab >}}

{{< /tabs >}}

### Google Cloud 스토리지 구성 {#configure-google-cloud-storage}

Google Cloud 스토리지(GCP)는 애플리케이션 기본 자격증명을 사용하여 인증합니다. 다음 중 하나를 사용하여 각 Gitaly 서버에서 애플리케이션 기본 자격증명을 설정합니다:

- [`gcloud auth application-default login`](https://cloud.google.com/sdk/gcloud/reference/auth/application-default/login) 명령입니다.
- `GOOGLE_APPLICATION_CREDENTIALS` 환경 변수입니다. 자체 컴파일된 설치의 경우 GitLab 외부에서 환경 변수를 설정합니다.

자세한 내용은 [애플리케이션 기본 자격증명](https://cloud.google.com/docs/authentication/provide-credentials-adc)을(를) 참조하세요.

대상 버킷은 `go_cloud_url` 옵션을 사용하여 구성됩니다.

{{< tabs >}}

{{< tab title="Linux 패키지(Omnibus)" >}}

`/etc/gitlab/gitlab.rb`을(를) 편집하고 `go_cloud_url`를 구성합니다:

```ruby
gitaly['env'] = {
    'GOOGLE_APPLICATION_CREDENTIALS' => '/path/to/service.json'
}
gitaly['configuration'] = {
    bundle_uri: {
        go_cloud_url: 'gs://<bucket>'
    }
}
```

{{< /tab >}}

{{< tab title="자체 컴파일(소스)" >}}

`/home/git/gitaly/config.toml`을(를) 편집하고 `go_cloud_url`를 구성합니다:

```toml
[bundle_uri]
go_cloud_url = "gs://<bucket>"
```

{{< /tab >}}

{{< /tabs >}}

### S3 스토리지 구성 {#configure-s3-storage}

S3 스토리지 인증을 구성하려면:

- AWS CLI로 인증하면 기본 AWS 세션을 사용할 수 있습니다.
- 또는 `AWS_ACCESS_KEY_ID` 및 `AWS_SECRET_ACCESS_KEY` 환경 변수를 사용할 수 있습니다. 자체 컴파일된 설치의 경우 GitLab 외부에서 환경 변수를 설정합니다.

자세한 내용은 [AWS 세션 설명서](https://docs.aws.amazon.com/sdk-for-go/api/aws/session/)를 참조하세요.

대상 버킷 및 리전은 `go_cloud_url` 옵션을 사용하여 구성됩니다.

{{< tabs >}}

{{< tab title="Linux 패키지(Omnibus)" >}}

`/etc/gitlab/gitlab.rb`을(를) 편집하고 `go_cloud_url`를 구성합니다:

```ruby
gitaly['env'] = {
    'AWS_ACCESS_KEY_ID' => 'aws_access_key_id',
    'AWS_SECRET_ACCESS_KEY' => 'aws_secret_access_key'
}
gitaly['configuration'] = {
    bundle_uri: {
        go_cloud_url: 's3://<bucket>?region=us-west-1'
    }
}
```

{{< /tab >}}

{{< tab title="자체 컴파일(소스)" >}}

`/home/git/gitaly/config.toml`을(를) 편집하고 `go_cloud_url`를 구성합니다:

```toml
[bundle_uri]
go_cloud_url = "s3://<bucket>?region=us-west-1"
```

{{< /tab >}}

{{< /tabs >}}

#### S3 호환 서버 구성 {#configure-s3-compatible-servers}

{{< history >}}

- `use_path_style` 및 `disable_https` 매개변수가 GitLab 17.4에서 [도입](https://gitlab.com/groups/gitlab-org/-/epics/8939)되었습니다.

{{< /history >}}

S3 호환 서버는 S3과 유사하게 구성되며 `endpoint` 매개변수가 추가됩니다.

다음 매개변수가 지원됩니다:

- `region`:  AWS 리전입니다.
- `endpoint`:  엔드포인트 URL입니다.
- `disableSSL`:  `true`로 설정하여 SSL을 비활성화합니다. GitLab 17.4.0 이하에서 사용 가능합니다. GitLab 17.4.0 이후 버전의 경우 `disable_https`을(를) 사용합니다.
- `disable_https`:  `true`로 설정하여 엔드포인트 옵션에서 HTTPS를 비활성화합니다.
- `s3ForcePathStyle`:  `true`로 설정하여 S3 객체에 대한 경로 스타일 URL을 강제합니다. GitLab 17.4.0~17.4.3 버전에서는 사용할 수 없습니다. 이러한 버전에서는 대신 `use_path_style`을(를) 사용합니다.
- `use_path_style`:  `true`로 설정하여 경로 스타일 S3 URL(`https://<host>/<bucket>` 대신 `https://<bucket>.<host>`)을 활성화합니다.
- `awssdk`:  특정 버전의 AWS SDK를 강제합니다. `v1`로 설정하여 AWS SDK v1을 강제하거나 `v2`로 설정하여 AWS SDK v2를 강제합니다. 다음의 경우:
  - `v1`로 설정된 경우 `disable_https` 대신 `disableSSL`를 사용해야 합니다.
  - 설정되지 않은 경우 기본값은 `v2`입니다.

`use_path_style`은(는) Go Cloud Development Kit 종속성이 v0.38.0에서 v0.39.0으로 업데이트되어 AWS SDK v1에서 v2로 전환되었을 때 도입되었습니다. 그러나 `s3ForcePathStyle` 매개변수는 gocloud.dev 관리자가 하위 호환성 지원을 추가한 후 GitLab 17.4.4에서 복원되었습니다. 자세한 내용은 [이슈 6489](https://gitlab.com/gitlab-org/gitaly/-/issues/6489)를 참조하세요.

`disable_https`은(는) Go Cloud Development Kit v0.40.0(AWS SDK v2)에서 도입되었습니다.

`awssdk`은(는) Go Cloud Development Kit v0.24.0에서 도입되었습니다.

{{< tabs >}}

{{< tab title="Linux 패키지(Omnibus)" >}}

`/etc/gitlab/gitlab.rb`을(를) 편집하고 `go_cloud_url`를 구성합니다:

```ruby
gitaly['env'] = {
    'AWS_ACCESS_KEY_ID' => '<your_access_key_id>',
    'AWS_SECRET_ACCESS_KEY' => '<your_secret_access_key>'
}
gitaly['configuration'] = {
    bundle_uri: {
        go_cloud_url: 's3://<bucket>?region=us-east-1&endpoint=s3.example.com:9000&disable_https=true&use_path_style=true'
    }
}
```

{{< /tab >}}

{{< tab title="자체 컴파일(소스)" >}}

`/home/git/gitaly/config.toml`을(를) 편집하고 `go_cloud_url`를 구성합니다:

```toml
[bundle_uri]
go_cloud_url = "s3://<bucket>?region=us-east-1&endpoint=s3.example.com:9000&disable_https=true&use_path_style=true"
```

{{< /tab >}}

{{< /tabs >}}

## 번들 생성 {#generating-bundles}

Gitaly가 구성되면 Gitaly는 번들을 수동으로 또는 자동으로 생성할 수 있습니다.

### 수동 생성 {#manual-generation}

이 명령은 번들을 생성하고 구성된 스토리지 서비스에 저장합니다.

```shell
sudo -u git -- /opt/gitlab/embedded/bin/gitaly bundle-uri \
                                               --config=<config-file> \
                                               --storage=<storage-name> \
                                               --repository=<relative-path>
```

Gitaly는 생성된 번들을 자동으로 새로 고치지 않습니다. 번들의 더 최신 버전을 생성하려면 명령을 다시 실행해야 합니다.

`cron(8)`과(와) 같은 도구를 사용하여 이 명령을 예약할 수 있습니다.

### 자동 생성 {#automatic-generation}

{{< history >}}

- GitLab 18.0에서 [도입](https://gitlab.com/groups/gitlab-org/-/epics/16007)되었으며, `gitaly_bundle_generation` [플래그](../feature_flags/_index.md)로 표시되었습니다. 기본적으로 비활성화됨.

{{< /history >}}

> [!flag]
> 이 기능의 가용성은 기능 플래그로 제어됩니다. 자세한 내용은 기록을 참조하세요.

Gitaly는 동일한 리포지토리에 대한 빈번한 클론을 처리하는지 여부를 결정하여 번들을 자동으로 생성할 수 있습니다. 현재 휴리스틱은 각 리포지토리에 대해 `git fetch` 요청이 실행되는 횟수를 추적합니다. 요청 수가 주어진 간격에서 특정 임계값에 도달하면 Gitaly가 자동으로 번들을 생성합니다.

Gitaly는 또한 리포지토리에 대해 마지막으로 번들을 생성한 시간을 추적합니다. `threshold` 및 `interval`를 기반으로 새 번들을 재생성해야 할 때, Gitaly는 주어진 리포지토리에 대해 마지막으로 번들을 생성한 시간을 확인합니다. Gitaly는 기존 번들이 `maxBundleAge` 구성보다 오래된 경우에만 새 번들을 생성하며, 이 경우 이전 번들이 덮어씁니다. 클라우드 스토리지의 리포지토리당 번들은 하나만 있을 수 있습니다.

## 번들 URI 예시 {#bundle-uri-example}

다음 예시에서 번들 URI를 사용하거나 사용하지 않고 `gitlab.com/gitlab-org/gitlab.git`을(를) 클론하는 것의 차이를 보여줍니다.

```shell
$ git -c transfer.bundleURI=false clone https://gitlab.com/gitlab-org/gitlab.git
Cloning into 'gitlab'...
remote: Enumerating objects: 5271177, done.
remote: Total 5271177 (delta 0), reused 0 (delta 0), pack-reused 5271177
Receiving objects: 100% (5271177/5271177), 1.93 GiB | 32.93 MiB/s, done.
Resolving deltas: 100% (4140349/4140349), done.
Updating files: 100% (71304/71304), done.

$ git -c transfer.bundleURI=true clone https://gitlab.com/gitlab-org/gitlab.git
Cloning into 'gitlab'...
remote: Enumerating objects: 1322255, done.
remote: Counting objects: 100% (611708/611708), done.
remote: Total 1322255 (delta 611708), reused 611708 (delta 611708), pack-reused 710547
Receiving objects: 100% (1322255/1322255), 539.66 MiB | 22.98 MiB/s, done.
Resolving deltas: 100% (1026890/1026890), completed with 223946 local objects.
Checking objects: 100% (8388608/8388608), done.
Checking connectivity: 1381139, done.
Updating files: 100% (71304/71304), done.
```

이전 예제에서:

- 번들 URI를 사용하지 않을 때 GitLab 서버에서 5,271,177개의 객체를 수신했습니다.
- 번들 URI를 사용할 때 GitLab 서버에서 1,322,255개의 객체를 수신했습니다.

이러한 감소는 클라이언트가 먼저 스토리지 서버에서 번들을 다운로드했기 때문에 GitLab이 더 적은 객체를 함께 패킹해야 한다는 것을 의미합니다(이전 예시에서는 대략 객체 수의 약 1/4).

## 번들 보안 {#securing-bundles}

번들은 서명된 URL을 사용하여 클라이언트가 접근할 수 있게 됩니다. 서명된 URL은 제한된 권한 및 요청을 수행할 시간을 제공하는 URL입니다. 스토리지 서비스가 서명된 URL을 지원하는지 확인하려면 스토리지 서비스의 설명서를 참조하세요.
