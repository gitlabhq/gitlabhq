---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
gitlab_dedicated: no
title: 객체 저장소
description: 데이터용 객체 저장소 서비스를 구성합니다.
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed

{{< /details >}}

GitLab은 다양한 유형의 데이터를 보관하기 위해 객체 저장소 서비스를 사용할 수 있습니다. NFS보다 권장되며, 객체 저장소가 일반적으로 훨씬 더 뛰어난 성능, 안정성 및 확장성을 제공하므로 더 큰 설정에서는 일반적으로 더 나은 선택입니다.

객체 저장소를 구성하려면 두 가지 옵션이 있습니다:

- 권장됩니다. [모든 객체 유형에 대해 단일 저장소 연결 구성](#configure-a-single-storage-connection-for-all-object-types-consolidated-form):  모든 지원되는 객체 유형이 단일 자격 증명을 공유합니다. 이를 통합 형식이라고 합니다.
- [각 객체 유형이 자신의 저장소 연결을 정의하도록 구성](#configure-each-object-type-to-define-its-own-storage-connection-storage-specific-form):  모든 객체는 자신의 객체 저장소 연결 및 구성을 정의합니다. 이를 저장소 특화 형식이라고 합니다.

  이미 저장소 특화 형식을 사용 중인 경우 [통합 형식으로 전환하는 방법](#transition-to-consolidated-form)을 참조하세요.

데이터를 로컬에 저장하는 경우 [객체 저장소로 마이그레이션하는 방법](#migrate-to-object-storage)을 참조하세요.

## 객체 저장소 제공자 지원 {#object-storage-provider-support}

GitLab은 [Fog 라이브러리](https://fog.github.io/about/supported_services.html)를 객체 저장소에 사용하며 다음 세 가지 연결 유형을 지원합니다. 다른 Fog 제공자는 지원되지 않습니다.

| 연결 유형      | `provider` 값 | 함께 사용 |
|:---------------------|:-----------------|:---------|
| S3 호환        | `AWS`            | Amazon S3 및 모든 S3 호환 서비스 |
| Google Cloud Storage | `Google`         | Google Cloud Storage |
| Azure Blob Storage   | `AzureRM`        | Azure Blob Storage |

객체 저장소 서비스가 이러한 연결 유형 중 하나와 호환되는 경우 아래의 해당 연결 설정을 사용하여 구성합니다. 제공자 선택은 귀사의 판단입니다.

### 활성 테스트 범위가 있는 제공자 {#providers-with-active-test-coverage}

GitLab은 다음 제공자를 적극적으로 테스트합니다:

- [Amazon S3](https://aws.amazon.com/s3/) - `AWS` 연결 유형입니다. [Object Lock](https://docs.aws.amazon.com/AmazonS3/latest/userguide/object-lock.html)은 지원되지 않습니다. 자세한 내용은 [이슈 335775](https://gitlab.com/gitlab-org/gitlab/-/issues/335775)를 참조하세요.
- [Google Cloud Storage](https://cloud.google.com/storage) - `Google` 연결 유형입니다.
- [Azure Blob Storage](https://learn.microsoft.com/en-us/azure/storage/blobs/storage-blobs-introduction) - `AzureRM` 연결 유형입니다.

### 커뮤니티 문서화 제공자 {#community-documented-providers}

다음 제공자는 커뮤니티에 의해 문서화되었습니다. GitLab은 이러한 제공자를 테스트하지 않습니다. 구성 예시는 편의상 제공됩니다. 이러한 제공자 중 하나를 사용하고 문제가 발생하면 GitLab 지원이 도움을 줄 수 없을 수 있습니다.

- [Digital Ocean Spaces](https://www.digitalocean.com/products/spaces). S3 호환이며 [제공자별 구성 예시](#provider-specific-configuration-examples)를 참조하세요.
- [Oracle Cloud Infrastructure](https://docs.oracle.com/en-us/iaas/Content/Object/Tasks/s3compatibleapi.htm). S3 호환이며 [제공자별 구성 예시](#provider-specific-configuration-examples)를 참조하세요.
- [OpenStack Swift](https://docs.openstack.org/swift/latest/s3_compat.html) (S3 호환 모드).
- [Storj Gateway](https://www.storj.io/). S3 호환이며 [제공자별 구성 예시](#provider-specific-configuration-examples)를 참조하세요.
- [Ceph RGW](https://docs.ceph.com/en/reef/cephadm/services/rgw/). S3 호환이며 [제공자별 구성 예시](#provider-specific-configuration-examples)를 참조하세요.
- [Hitachi Vantara HCP](https://docs.hitachivantara.com/r/en-us/content-platform/9.7.x/mk-95hcph001/hcp-management-api-reference/introduction-to-the-hcp-management-api/support-for-the-amazon-s3-api). S3 호환이며 [제공자별 구성 예시](#provider-specific-configuration-examples)를 참조하세요.
- S3 호환 API를 제공하는 온프레미스 하드웨어 및 어플라이언스.

## 모든 객체 유형에 대해 단일 저장소 연결 구성 (통합 형식) {#configure-a-single-storage-connection-for-all-object-types-consolidated-form}

CI 아티팩트, LFS 파일, 업로드 첨부 파일 등 대부분의 객체 유형은 여러 버킷이 있는 객체 저장소에 대해 단일 자격 증명을 지정하여 객체 저장소에 저장할 수 있습니다.

> [!note]
> GitLab Helm Charts의 경우 [통합 형식을 구성하는 방법](https://docs.gitlab.com/charts/charts/globals/#consolidated-object-storage)을 참조하세요.

통합 형식을 사용하여 객체 저장소를 구성하면 다음과 같은 많은 이점이 있습니다:

- 연결 세부 정보가 객체 유형 전체에서 공유되므로 GitLab 구성을 단순화할 수 있습니다.
- [암호화된 S3 버킷](#encrypted-s3-buckets)의 사용을 활성화합니다.
- [S3에 적절한 `Content-MD5` 헤더가 있는 파일을 업로드](https://gitlab.com/gitlab-org/gitlab-workhorse/-/issues/222)합니다.

통합 형식을 사용하면 직접 업로드가 자동으로 활성화됩니다. 따라서 다음 제공자만 사용할 수 있습니다:

- [S3 호환 제공자](#s3-compatible-providers)
- [Google Cloud Storage](#google-cloud-storage-gcs)
- [Azure Blob 저장소](#azure-blob-storage)

통합 형식 구성은 백업 또는 Mattermost에 사용할 수 없습니다. 백업은 [서버 측 암호화](backup_restore/backup_gitlab.md#s3-encrypted-buckets)로 별도로 구성할 수 있습니다. 지원되는 객체 저장소 유형의 전체 목록을 보려면 [표를 참조](#configure-each-object-type-to-define-its-own-storage-connection-storage-specific-form)하세요.

통합 형식을 활성화하면 모든 객체 유형에 대해 객체 저장소가 활성화됩니다. 모든 버킷이 지정되지 않으면 다음과 같은 오류가 표시될 수 있습니다:

```plaintext
Object storage for <object type> must have a bucket specified
```

특정 객체 유형에 로컬 저장소를 사용하려면 [특정 기능에 대해 객체 저장소 비활성화](#disable-object-storage-for-specific-features)할 수 있습니다.

### 일반 매개변수 구성 {#configure-the-common-parameters}

통합 형식에서 `object_store` 섹션은 일반 매개변수 집합을 정의합니다.

| 설정           | 설명                       |
|-------------------|-----------------------------------|
| `enabled`         | 객체 저장소를 활성화 또는 비활성화합니다. |
| `proxy_download`  | `true`로 설정하여 [제공되는 모든 파일 프록시를 활성화](#proxy-download)합니다. 이 옵션을 사용하면 클라이언트가 모든 데이터를 프록시하는 대신 원격 저장소에서 직접 다운로드할 수 있으므로 송신 트래픽을 줄일 수 있습니다. |
| `connection`      | 아래에 설명된 다양한 [연결 옵션](#configure-the-connection-settings). |
| `storage_options` | [서버 측 암호화](#server-side-encryption-headers)와 같이 새 객체를 저장할 때 사용할 옵션. |
| `objects`         | [객체별 구성](#configure-the-parameters-of-each-object). |

예시를 보려면 [통합 형식 및 Amazon S3 사용 방법](#full-example-using-the-consolidated-form-and-amazon-s3)을 참조하세요.

### 각 객체의 매개변수 구성 {#configure-the-parameters-of-each-object}

각 객체 유형은 최소한 저장될 버킷 이름을 정의해야 합니다.

다음 표에는 사용할 수 있는 유효한 `objects`이 나열되어 있습니다:

| 유형               | 설명 |
|--------------------|-------------|
| `artifacts`        | [CI/CD 작업 아티팩트](cicd/job_artifacts.md) |
| `external_diffs`   | [머지 리퀘스트 diff](merge_request_diffs.md) |
| `uploads`          | [사용자 업로드](uploads.md) |
| `lfs`              | [Git Large File Storage 객체](lfs/_index.md) |
| `packages`         | [프로젝트 패키지 (예: PyPI, Maven 또는 NuGet)](packages/_index.md) |
| `dependency_proxy` | [종속성 프록시](packages/dependency_proxy.md) |
| `terraform_state`  | [Terraform 상태 파일](terraform_state.md) |
| `pages`            | [Pages](pages/_index.md) |
| `ci_secure_files`  | [Secure files](cicd/secure_files.md) |

각 객체 유형 내에서 세 가지 매개변수를 정의할 수 있습니다:

| 설정          | 필수?              | 설명                         |
|------------------|------------------------|-------------------------------------|
| `bucket`         | {{< icon name="check-circle" >}} 예* | 객체 유형의 버킷 이름. `enabled`이 `false`로 설정된 경우 필수가 아닙니다. |
| `enabled`        | {{< icon name="dotted-circle" >}} 아니요 | [일반 매개변수](#configure-the-common-parameters)를 재정의합니다.     |
| `proxy_download` | {{< icon name="dotted-circle" >}} 아니요 | [일반 매개변수](#configure-the-common-parameters)를 재정의합니다.     |

예시를 보려면 [통합 형식 및 Amazon S3 사용 방법](#full-example-using-the-consolidated-form-and-amazon-s3)을 참조하세요.

#### 특정 기능에 대해 객체 저장소 비활성화 {#disable-object-storage-for-specific-features}

이전에 보았듯이 `enabled` 플래그를 `false`로 설정하여 특정 유형에 대해 객체 저장소를 비활성화할 수 있습니다. 예를 들어, CI 아티팩트에 대해 객체 저장소를 비활성화하려면:

```ruby
gitlab_rails['object_store']['objects']['artifacts']['enabled'] = false
```

기능이 완전히 비활성화된 경우 버킷이 필요하지 않습니다. 예를 들어, CI 아티팩트가 이 설정으로 비활성화된 경우 버킷이 필요하지 않습니다:

```ruby
gitlab_rails['artifacts_enabled'] = false
```

## 각 객체 유형이 자신의 저장소 연결을 정의하도록 구성 (저장소 특화 형식) {#configure-each-object-type-to-define-its-own-storage-connection-storage-specific-form}

저장소 특화 형식을 사용하면 모든 객체가 자신의 객체 저장소 연결 및 구성을 정의합니다. 통합 형식에서 지원되지 않는 저장소 유형을 제외하고 [통합 형식을 사용](#transition-to-consolidated-form)해야 합니다. GitLab Helm 차트를 사용할 때 차트가 [객체 저장소에 대한 통합 형식](https://docs.gitlab.com/charts/charts/globals/#consolidated-object-storage)을 처리하는 방법을 참조하세요.

비통합 형식의 [암호화된 S3 버킷](#encrypted-s3-buckets) 사용은 지원되지 않습니다. 이를 사용하면 [ETag 불일치 오류](#etag-mismatch)가 발생할 수 있습니다.

> [!note]
> 저장소 특화 형식의 경우 [직접 업로드가 기본값이 될 수 있습니다](https://gitlab.com/gitlab-org/gitlab/-/issues/27331). 공유 폴더가 필요하지 않기 때문입니다.

통합 형식에서 지원되지 않는 저장소 유형의 경우 다음 가이드를 참조하세요:

| 객체 저장소 유형 | 통합 형식에서 지원됨? |
|---------------------|------------------------------------------|
| [백업](backup_restore/backup_gitlab.md#upload-backups-to-a-remote-cloud-storage) | {{< icon name="dotted-circle" >}} 아니요 |
| [컨테이너 레지스트리](packages/container_registry.md#use-object-storage) (선택 사항 기능) | {{< icon name="dotted-circle" >}} 아니요 |
| [Mattermost](https://docs.mattermost.com/configure/file-storage-configuration-settings.html)| {{< icon name="dotted-circle" >}} 아니요 |
| [자동 확장 러너 캐싱](https://docs.gitlab.com/runner/configuration/autoscale/#distributed-runners-caching) (성능 향상 선택) | {{< icon name="dotted-circle" >}} 아니요 |
| [Secure Files](cicd/secure_files.md#using-object-storage) | {{< icon name="check-circle" >}} 예 |
| [작업 아티팩트](cicd/job_artifacts.md#using-object-storage) (아카이브된 작업 로그 포함) | {{< icon name="check-circle" >}} 예 |
| [LFS 객체](lfs/_index.md#storing-lfs-objects-in-remote-object-storage) | {{< icon name="check-circle" >}} 예 |
| [업로드](uploads.md#using-object-storage) | {{< icon name="check-circle" >}} 예 |
| [머지 리퀘스트 diff](merge_request_diffs.md#using-object-storage) | {{< icon name="check-circle" >}} 예 |
| [패키지](packages/_index.md#migrate-packages-between-object-storage-and-local-storage) (선택 사항 기능) | {{< icon name="check-circle" >}} 예 |
| [종속성 프록시](packages/dependency_proxy.md#using-object-storage) (선택 사항 기능) | {{< icon name="check-circle" >}} 예 |
| [Terraform 상태 파일](terraform_state.md#using-object-storage) | {{< icon name="check-circle" >}} 예 |
| [Pages 콘텐츠](pages/_index.md#object-storage-settings) | {{< icon name="check-circle" >}} 예 |

## 연결 설정 구성 {#configure-the-connection-settings}

통합 및 저장소 특화 형식 모두 연결을 구성해야 합니다. 다음 섹션에서는 `connection` 설정에서 사용할 수 있는 매개변수를 설명합니다.

### S3 호환 제공자 {#s3-compatible-providers}

이러한 설정은 `AWS` 연결 유형을 사용하는 Amazon S3 및 모든 S3 호환 서비스에 적용됩니다. AWS를 직접 사용하지 않는 경우 `endpoint`를 제공자의 URL로 설정합니다.

S3 호환 서비스는 AWS S3 API를 얼마나 밀접하게 구현하는지 다양합니다. GitLab은 사전 서명된 URL, 다중 부분 업로드, 선택적으로 청크 서명 스트리밍을 포함한 특정 S3 동작을 사용하며 모든 S3 호환 구현이 동일하게 지원하는 것은 아닙니다. 제공자가 다른 도구에서는 작동하지만 GitLab에서는 작동하지 않으면 조정해야 할 가능성이 가장 높은 설정은:

- `aws_signature_version`.
- `enable_signature_v4_streaming`.

연결 설정은 [fog-aws](https://github.com/fog/fog-aws)에서 제공한 설정과 일치합니다:

| 설정                                     | 설명                        | 기본값 |
|---------------------------------------------|------------------------------------|---------|
| `provider`                                  | 호환되는 호스트의 경우 항상 `AWS`. | `AWS` |
| `aws_access_key_id`                         | AWS 자격 증명 또는 호환성.    | |
| `aws_secret_access_key`                     | AWS 자격 증명 또는 호환성.    | |
| `aws_signature_version`                     | 사용할 AWS 서명 버전. `2` 또는 `4`이 유효한 옵션입니다. 일부 S3 호환 제공자는 `2`이 필요할 수 있습니다. | `4` |
| `enable_signature_v4_streaming`             | `true`로 설정하여 [AWS v4 서명](https://docs.aws.amazon.com/AmazonS3/latest/API/sigv4-streaming.html)으로 HTTP 청크 전송을 활성화합니다. 일부 S3 호환 제공자는 이것을 `false`로 설정해야 합니다. GitLab 17.4는 기본값을 `true`에서 `false`로 변경했습니다. | `false` |
| `region`                                    | AWS 리전.                        | |
| `host`                                      | 더 이상 사용되지 않음:  대신 `endpoint`을 사용합니다. AWS를 사용하지 않을 때 S3 호환 호스트. 예: `localhost` 또는 `storage.example.com`. HTTPS 및 포트 443이 가정됩니다. | `s3.amazonaws.com` |
| `endpoint`                                  | S3 호환 서비스를 구성할 때 `http://127.0.0.1:9000`과 같은 URL을 입력하여 사용할 수 있습니다. 이는 `host`보다 우선합니다. 통합 형식의 경우 항상 `endpoint`을 사용합니다. | (선택 사항) |
| `path_style`                                | `true`로 설정하여 `host/bucket_name/object` 스타일 경로를 `bucket_name.host/object` 대신 사용합니다. S3 호환 서비스에서 경로 스타일 주소 지정이 필요한 경우 `true`로 설정합니다. AWS S3의 경우 `false`로 유지합니다. | `false` |
| `use_iam_profile`                           | `true`로 설정하여 액세스 키 대신 IAM 프로필을 사용합니다. | `false` |
| `aws_credentials_refresh_threshold_seconds` | IAM에서 임시 자격 증명을 사용할 때 초 단위로 [자동 새로 고침 임계값](https://github.com/fog/fog-aws#controlling-credential-refresh-time-with-iam-authentication)을 설정합니다. | `15` |
| `disable_imds_v2`                           | `X-aws-ec2-metadata-token`을 검색하는 IMDS v2 엔드포인트에 대한 액세스를 비활성화하여 IMDS v1의 사용을 강제합니다. | `false` |

#### S3 호환성 및 알려진 실패 모드 {#s3-compatibility-and-known-failure-modes}

S3 호환성을 주장한다고 해서 제공자가 GitLab에서 올바르게 작동한다는 보장은 없습니다. S3 호환 제공자에서 오류가 발생하면 지원 요청을 하기 전에 다음 조정을 시도하세요:

- **Signature streaming**:  일부 제공자는 AWS 서명 버전 4 스트리밍에서 사용하는 청크 전송 인코딩을 거부합니다. `enable_signature_v4_streaming: false`를 설정합니다.
- **Signature version**:  일부 제공자는 서명 버전 4를 완전히 지원하지 않습니다. `aws_signature_version: 2`를 설정합니다.
- **Path-style URLs**:  일부 제공자는 경로 스타일 버킷 주소 지정이 필요합니다. `path_style: true`를 설정합니다.
- **ETag validation**:  일부 제공자는 GitLab이 검증하는 업로드된 객체의 MD5와 일치하지 않는 ETag를 반환합니다. [ETag 불일치](#etag-mismatch)를 참조하세요.

GitLab 지원은 구성 문제 해결을 도와줄 수 있지만 [테스트된 세트](#providers-with-active-test-coverage)에 없는 제공자와 관련된 문제 해결을 보장할 수 없습니다.

#### Amazon 인스턴스 프로필 사용 {#use-amazon-instance-profiles}

객체 저장소 구성에서 AWS 액세스 및 비밀 키를 제공하는 대신 GitLab을 구성하여 Amazon Identity Access and Management (IAM) 역할을 사용하여 [Amazon 인스턴스 프로필](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_use_switch-role-ec2.html)을 설정할 수 있습니다. 이를 사용하면 S3 버킷에 액세스할 때마다 GitLab이 임시 자격 증명을 가져오므로 구성에 하드 코딩된 값이 필요하지 않습니다.

전제 조건:

- GitLab은 [인스턴스 메타데이터 엔드포인트](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/instancedata-data-retrieval.html)에 연결할 수 있어야 합니다.
- GitLab이 [인터넷 프록시를 사용하도록 구성](https://docs.gitlab.com/omnibus/settings/environment-variables/)된 경우 엔드포인트 IP 주소를 `no_proxy` 목록에 추가해야 합니다.
- IMDS v2 액세스의 경우 [홉 제한](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/instancedata-data-retrieval.html)이 충분한지 확인하세요. GitLab이 컨테이너에서 실행 중인 경우 제한을 1에서 2로 올려야 할 수 있습니다.

인스턴스 프로필을 설정하려면:

1. 필요한 권한으로 IAM 역할을 만듭니다. 다음은 `test-bucket`이라는 S3 버킷에 대한 역할의 예입니다:

   ```json
   {
       "Version": "2012-10-17",
       "Statement": [
           {
               "Effect": "Allow",
               "Action": [
                   "s3:PutObject",
                   "s3:GetObject",
                   "s3:DeleteObject"
               ],
               "Resource": "arn:aws:s3:::test-bucket/*"
           },
           {
               "Effect": "Allow",
               "Action": [
                   "s3:ListBucket"
               ],
               "Resource": "arn:aws:s3:::test-bucket"
           }
       ]
   }
   ```

1. 이 역할을 [GitLab 인스턴스를 호스팅하는 EC2 인스턴스에 연결](https://repost.aws/knowledge-center/attach-replace-ec2-instance-profile)합니다.
1. `use_iam_profile` GitLab 구성 옵션을 `true`로 설정합니다.

#### 암호화된 S3 버킷 {#encrypted-s3-buckets}

인스턴스 프로필 또는 통합 형식으로 구성된 경우 GitLab Workhorse는 [기본적으로 SSE-S3 또는 SSE-KMS 암호화가 활성화된 S3 버킷](https://docs.aws.amazon.com/kms/latest/developerguide/overview.html)에 파일을 올바르게 업로드합니다. AWS KMS 키 및 SSE-C 암호화는 [모든 요청에서 암호화 키를 전송해야 하기 때문에 지원되지 않습니다](https://gitlab.com/gitlab-org/gitlab/-/issues/226006).

#### 서버 측 암호화 헤더 {#server-side-encryption-headers}

S3 버킷에서 기본 암호화를 설정하는 것이 암호화를 활성화하는 가장 쉬운 방법이지만 [암호화된 객체만 업로드되도록 버킷 정책을 설정](https://repost.aws/knowledge-center/s3-bucket-store-kms-encrypted-objects)할 수도 있습니다. 이를 수행하려면 GitLab을 구성하여 `storage_options` 구성 섹션에서 올바른 암호화 헤더를 전송해야 합니다:

| 설정                             | 설명                              |
|-------------------------------------|------------------------------------------|
| `server_side_encryption`            | 암호화 모드 (`AES256` 또는 `aws:kms`). |
| `server_side_encryption_kms_key_id` | Amazon Resource Name. `aws:kms`이 `server_side_encryption`에서 사용될 때만 필요합니다. [KMS 암호화 사용에 대한 Amazon 문서](https://docs.aws.amazon.com/AmazonS3/latest/userguide/UsingKMSEncryption.html)를 참조하세요. |

기본 암호화의 경우와 마찬가지로 이러한 옵션은 Workhorse S3 클라이언트가 활성화된 경우에만 작동합니다. 다음 두 조건 중 하나를 충족해야 합니다:

- `use_iam_profile`이 연결 설정에서 `true`입니다.
- 통합 형식이 사용 중입니다.

[ETag 불일치 오류](#etag-mismatch)는 Workhorse S3 클라이언트를 활성화하지 않고 서버 측 암호화 헤더를 사용하는 경우 발생합니다.

### Google Cloud Storage (GCS) {#google-cloud-storage-gcs}

{{< history >}}

- `universe_domain` 설정은 GitLab 18.9에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/221401)되었습니다.

{{< /history >}}

GCS의 유효한 연결 매개변수는 다음과 같습니다:

| 설정                      | 설명       | 예제 |
|------------------------------|-------------------|---------|
| `provider`                   | 제공자 이름.    | `Google` |
| `google_project`             | GCP 프로젝트 이름. | `gcp-project-12345` |
| `google_json_key_location`   | JSON 키 경로.    | `/path/to/gcp-project-12345-abcde.json` |
| `google_json_key_string`     | JSON 키 문자열.  | `{ "type": "service_account", "project_id": "example-project-382839", ... }` |
| `google_application_default` | `true`로 설정하여 [Google Cloud Application Default Credentials](https://cloud.google.com/docs/authentication#adc)을 사용하여 서비스 계정 자격 증명을 찾습니다. | |
| `universe_domain`            | Google Cloud 요청에 사용할 우주 도메인. [Google Cloud Dedicated](https://cloud.google.com/sovereign-cloud) 또는 다른 기본이 아닌 우주 도메인에 연결하는 데 사용합니다. | `googleapis.com` |

GitLab은 `google_json_key_location`의 값을 읽은 다음 `google_json_key_string`, 마지막으로 `google_application_default`을 읽습니다. 값이 있는 이러한 설정 중 첫 번째를 사용합니다.

서비스 계정은 버킷에 액세스할 수 있는 권한이 있어야 합니다. 자세한 내용은 [Cloud Storage 인증 문서](https://cloud.google.com/storage/docs/authentication)를 참조하세요.

#### Google Cloud Application Default Credentials {#google-cloud-application-default-credentials}

[Google Cloud Application Default Credentials (ADC)](https://cloud.google.com/docs/authentication/application-default-credentials) 는 일반적으로 GitLab에서 기본 서비스 계정 또는 [Workload Identity Federation](https://cloud.google.com/iam/docs/workload-identity-federation)을 사용하는 데 사용됩니다. `google_application_default`을 `true`로 설정하고 `google_json_key_location` 및 `google_json_key_string`을 생략합니다.

ADC를 사용하는 경우 다음을 확인하세요:

- 사용하는 서비스 계정에 [`iam.serviceAccounts.signBlob` 권한](https://cloud.google.com/iam/docs/reference/credentials/rest/v1/projects.serviceAccounts/signBlob)이 있어야 합니다. 일반적으로 이는 서비스 계정에 `Service Account Token Creator` 역할을 부여하여 수행됩니다.
- Google Compute 가상 머신을 사용하는 경우 Google Cloud API에 액세스할 수 있는 [올바른 액세스 범위](https://cloud.google.com/compute/docs/access/create-enable-service-accounts-for-instances#changeserviceaccountandscopes)가 있는지 확인하세요. 머신에 올바른 범위가 없으면 오류 로그에 다음이 표시될 수 있습니다:

  ```shell
  Google::Apis::ClientError (insufficientPermissions: Request had insufficient authentication scopes.)
  ```

> [!note]
> [고객이 관리하는 암호화 키](https://cloud.google.com/storage/docs/encryption/using-customer-managed-keys) 를 사용하여 버킷 암호화를 사용하려면 [통합 형식](#configure-a-single-storage-connection-for-all-object-types-consolidated-form)을 사용합니다.

{{< tabs >}}

{{< tab title="Linux 패키지(Omnibus)" >}}

1. `/etc/gitlab/gitlab.rb`을 편집하고 원하는 값으로 대체하여 다음 줄을 추가합니다:

   ```ruby
   gitlab_rails['object_store']['connection'] = {
    'provider' => 'Google',
    'google_project' => '<GOOGLE PROJECT>',
    'google_json_key_location' => '<FILENAME>'
   }
   ```

   ADC를 사용하려면 `google_application_default`을 대신 사용합니다:

   ```ruby
   gitlab_rails['object_store']['connection'] = {
    'provider' => 'Google',
    'google_project' => '<GOOGLE PROJECT>',
    'google_application_default' => true
   }
   ```

   기본이 아닌 우주 도메인을 사용하려면 (예: [Google Cloud Dedicated](https://cloud.google.com/sovereign-cloud)):

   ```ruby
   gitlab_rails['object_store']['connection'] = {
    'provider' => 'Google',
    'google_project' => '<GOOGLE PROJECT>',
    'google_application_default' => true,
    'universe_domain' => '<UNIVERSE DOMAIN>'
   }
   ```

1. 파일을 저장하고 GitLab을 재구성합니다:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

{{< /tab >}}

{{< tab title="Helm 차트(Kubernetes)" >}}

1. `object_storage.yaml`이라는 파일에 다음 내용을 넣어 [Kubernetes Secret](https://docs.gitlab.com/charts/charts/globals/#connection)으로 사용합니다:

   ```yaml
   provider: Google
   google_project: <GOOGLE PROJECT>
   google_json_key_location: '<FILENAME>'
   ```

   ADC를 사용하려면 `google_application_default`을 대신 사용합니다:

   ```yaml
   provider: Google
   google_project: <GOOGLE PROJECT>
   google_application_default: true
   ```

   기본이 아닌 우주 도메인을 사용하려면 (예: [Google Cloud Dedicated](https://cloud.google.com/sovereign-cloud)):

   ```yaml
   provider: Google
   google_project: <GOOGLE PROJECT>
   google_application_default: true
   universe_domain: <UNIVERSE DOMAIN>
   ```

1. Kubernetes Secret을 만듭니다:

   ```shell
   kubectl create secret generic -n <namespace> gitlab-object-storage --from-file=connection=object_storage.yaml
   ```

1. Helm 값을 내보냅니다:

   ```shell
   helm get values gitlab > gitlab_values.yaml
   ```

1. `gitlab_values.yaml`을 편집합니다:

   ```yaml
   global:
     appConfig:
        artifacts:
          bucket: gitlab-artifacts
        ciSecureFiles:
          bucket: gitlab-ci-secure-files
          enabled: true
        dependencyProxy:
          bucket: gitlab-dependency-proxy
          enabled: true
        externalDiffs:
          bucket: gitlab-mr-diffs
          enabled: true
        lfs:
          bucket: gitlab-lfs
        object_store:
          connection:
            secret: gitlab-object-storage
          enabled: true
          proxy_download: false
        packages:
          bucket: gitlab-packages
        terraformState:
          bucket: gitlab-terraform-state
          enabled: true
        uploads:
          bucket: gitlab-uploads
   ```

1. 파일을 저장하고 새 값을 적용합니다:

   ```shell
   helm upgrade -f gitlab_values.yaml gitlab gitlab/gitlab
   ```

{{< /tab >}}

{{< tab title="Docker" >}}

1. `docker-compose.yml`을 편집합니다:

   ```yaml
   version: "3.6"
   services:
     gitlab:
       environment:
         GITLAB_OMNIBUS_CONFIG: |
           # Consolidated object storage configuration
           gitlab_rails['object_store']['enabled'] = true
           gitlab_rails['object_store']['proxy_download'] = false
           gitlab_rails['object_store']['connection'] = {
             'provider' => 'Google',
             'google_project' => '<GOOGLE PROJECT>',
             'google_json_key_location' => '<FILENAME>'
           }
           gitlab_rails['object_store']['objects']['artifacts']['bucket'] = 'gitlab-artifacts'
           gitlab_rails['object_store']['objects']['external_diffs']['bucket'] = 'gitlab-mr-diffs'
           gitlab_rails['object_store']['objects']['lfs']['bucket'] = 'gitlab-lfs'
           gitlab_rails['object_store']['objects']['uploads']['bucket'] = 'gitlab-uploads'
           gitlab_rails['object_store']['objects']['packages']['bucket'] = 'gitlab-packages'
           gitlab_rails['object_store']['objects']['dependency_proxy']['bucket'] = 'gitlab-dependency-proxy'
           gitlab_rails['object_store']['objects']['terraform_state']['bucket'] = 'gitlab-terraform-state'
           gitlab_rails['object_store']['objects']['ci_secure_files']['bucket'] = 'gitlab-ci-secure-files'
           gitlab_rails['object_store']['objects']['pages']['bucket'] = 'gitlab-pages'
   ```

   ADC를 사용하려면 `google_application_default`을 대신 사용합니다:

   ```ruby
   gitlab_rails['object_store']['connection'] = {
     'provider' => 'Google',
     'google_project' => '<GOOGLE PROJECT>',
     'google_application_default' => true
   }
   ```

   기본이 아닌 우주 도메인을 사용하려면 (예: [Google Cloud Dedicated](https://cloud.google.com/sovereign-cloud)):

   ```ruby
   gitlab_rails['object_store']['connection'] = {
     'provider' => 'Google',
     'google_project' => '<GOOGLE PROJECT>',
     'google_application_default' => true,
     'universe_domain' => '<UNIVERSE DOMAIN>'
   }
   ```

1. 파일을 저장하고 GitLab을 다시 시작합니다:

   ```shell
   docker compose up -d
   ```

{{< /tab >}}

{{< /tabs >}}

### Azure Blob 저장소 {#azure-blob-storage}

Azure는 `container`라는 단어를 사용하여 Blob 컬렉션을 나타내지만 GitLab은 `bucket`라는 용어를 표준화합니다. Azure 컨테이너 이름을 `bucket` 설정에 구성해야 합니다.

Azure Blob 저장소는 단일 자격 증명 집합이 여러 컨테이너에 액세스하는 데 사용되기 때문에 [통합 형식](#configure-a-single-storage-connection-for-all-object-types-consolidated-form)에서만 사용할 수 있습니다. [저장소 특화 형식](#configure-each-object-type-to-define-its-own-storage-connection-storage-specific-form)은 지원되지 않습니다. 자세한 내용은 [통합 형식으로 전환하는 방법](#transition-to-consolidated-form)을 참조하세요.

다음은 Azure의 유효한 연결 매개변수입니다. 자세한 내용은 [Azure Blob Storage 문서](https://learn.microsoft.com/en-us/azure/storage/blobs/storage-blobs-introduction)를 참조하세요.

| 설정                      | 설명    | 예제   |
|------------------------------|----------------|-----------|
| `provider`                   | 제공자 이름. | `AzureRM` |
| `azure_storage_account_name` | 저장소에 액세스하는 데 사용되는 Azure Blob Storage 계정의 이름. | `azuretest` |
| `azure_storage_access_key`   | 컨테이너에 액세스하는 데 사용되는 저장소 계정 액세스 키. 이는 일반적으로 base64로 인코딩된 비밀 512비트 암호화 키입니다. 이는 [Azure Workload 및 관리되는 ID](#azure-workload-and-managed-identities)에 선택 사항입니다. | `czV2OHkvQj9FKEgrTWJRZVRoV21ZcTN0Nnc5eiRDJkYpSkBOY1JmVWpYbjJy\nNHU3eCFBJUQqRy1LYVBkU2dWaw==\n` |
| `azure_storage_domain`       | Azure Blob Storage API에 연결하는 데 사용되는 도메인 이름 (선택 사항). 기본값은 `blob.core.windows.net`입니다. Azure 중국, Azure 독일, Azure US Government 또는 다른 사용자 지정 Azure 도메인을 사용하는 경우 이를 설정합니다. | `blob.core.windows.net` |

{{< tabs >}}

{{< tab title="Linux 패키지(Omnibus)" >}}

1. `/etc/gitlab/gitlab.rb`을 편집하고 원하는 값으로 대체하여 다음 줄을 추가합니다:

   ```ruby
   gitlab_rails['object_store']['connection'] = {
     'provider' => 'AzureRM',
     'azure_storage_account_name' => '<AZURE STORAGE ACCOUNT NAME>',
     'azure_storage_access_key' => '<AZURE STORAGE ACCESS KEY>',
     'azure_storage_domain' => '<AZURE STORAGE DOMAIN>'
   }
   gitlab_rails['object_store']['objects']['artifacts']['bucket'] = 'gitlab-artifacts'
   gitlab_rails['object_store']['objects']['external_diffs']['bucket'] = 'gitlab-mr-diffs'
   gitlab_rails['object_store']['objects']['lfs']['bucket'] = 'gitlab-lfs'
   gitlab_rails['object_store']['objects']['uploads']['bucket'] = 'gitlab-uploads'
   gitlab_rails['object_store']['objects']['packages']['bucket'] = 'gitlab-packages'
   gitlab_rails['object_store']['objects']['dependency_proxy']['bucket'] = 'gitlab-dependency-proxy'
   gitlab_rails['object_store']['objects']['terraform_state']['bucket'] = 'gitlab-terraform-state'
   gitlab_rails['object_store']['objects']['ci_secure_files']['bucket'] = 'gitlab-ci-secure-files'
   gitlab_rails['object_store']['objects']['pages']['bucket'] = 'gitlab-pages'
   ```

   [Workload Identity](#azure-workload-and-managed-identities)를 사용하는 경우 `azure_storage_access_key`를 생략합니다:

   ```ruby
   gitlab_rails['object_store']['connection'] = {
     'provider' => 'AzureRM',
     'azure_storage_account_name' => '<AZURE STORAGE ACCOUNT NAME>',
     'azure_storage_domain' => '<AZURE STORAGE DOMAIN>'
   }
   ```

1. 파일을 저장하고 GitLab을 재구성합니다:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

{{< /tab >}}

{{< tab title="Helm 차트(Kubernetes)" >}}

1. `object_storage.yaml`이라는 파일에 다음 내용을 넣어 [Kubernetes Secret](https://docs.gitlab.com/charts/charts/globals/#connection)으로 사용합니다:

   ```yaml
   provider: AzureRM
   azure_storage_account_name: <YOUR_AZURE_STORAGE_ACCOUNT_NAME>
   azure_storage_access_key: <YOUR_AZURE_STORAGE_ACCOUNT_KEY>
   azure_storage_domain: blob.core.windows.net
   ```

   [Workload 또는 관리되는 ID](#azure-workload-and-managed-identities)를 사용하는 경우 `azure_storage_access_key`를 생략합니다:

   ```yaml
   provider: AzureRM
   azure_storage_account_name: <YOUR_AZURE_STORAGE_ACCOUNT_NAME>
   azure_storage_domain: blob.core.windows.net
   ```

1. Kubernetes Secret을 만듭니다:

   ```shell
   kubectl create secret generic -n <namespace> gitlab-object-storage --from-file=connection=object_storage.yaml
   ```

1. Helm 값을 내보냅니다:

   ```shell
   helm get values gitlab > gitlab_values.yaml
   ```

1. `gitlab_values.yaml`을 편집합니다:

   ```yaml
   global:
     appConfig:
        artifacts:
          bucket: gitlab-artifacts
        ciSecureFiles:
          bucket: gitlab-ci-secure-files
          enabled: true
        dependencyProxy:
          bucket: gitlab-dependency-proxy
          enabled: true
        externalDiffs:
          bucket: gitlab-mr-diffs
          enabled: true
        lfs:
          bucket: gitlab-lfs
        object_store:
          connection:
            secret: gitlab-object-storage
          enabled: true
          proxy_download: false
        packages:
          bucket: gitlab-packages
        terraformState:
          bucket: gitlab-terraform-state
          enabled: true
        uploads:
          bucket: gitlab-uploads
   ```

1. 파일을 저장하고 새 값을 적용합니다:

   ```shell
   helm upgrade -f gitlab_values.yaml gitlab gitlab/gitlab
   ```

{{< /tab >}}

{{< tab title="Docker" >}}

1. `docker-compose.yml`을 편집합니다:

   ```yaml
   version: "3.6"
   services:
     gitlab:
       environment:
         GITLAB_OMNIBUS_CONFIG: |
           # Consolidated object storage configuration
           gitlab_rails['object_store']['enabled'] = true
           gitlab_rails['object_store']['proxy_download'] = false
           gitlab_rails['object_store']['connection'] = {
             'provider' => 'AzureRM',
             'azure_storage_account_name' => '<AZURE STORAGE ACCOUNT NAME>',
             'azure_storage_access_key' => '<AZURE STORAGE ACCESS KEY>',
             'azure_storage_domain' => '<AZURE STORAGE DOMAIN>'
           }
           gitlab_rails['object_store']['objects']['artifacts']['bucket'] = 'gitlab-artifacts'
           gitlab_rails['object_store']['objects']['external_diffs']['bucket'] = 'gitlab-mr-diffs'
           gitlab_rails['object_store']['objects']['lfs']['bucket'] = 'gitlab-lfs'
           gitlab_rails['object_store']['objects']['uploads']['bucket'] = 'gitlab-uploads'
           gitlab_rails['object_store']['objects']['packages']['bucket'] = 'gitlab-packages'
           gitlab_rails['object_store']['objects']['dependency_proxy']['bucket'] = 'gitlab-dependency-proxy'
           gitlab_rails['object_store']['objects']['terraform_state']['bucket'] = 'gitlab-terraform-state'
           gitlab_rails['object_store']['objects']['ci_secure_files']['bucket'] = 'gitlab-ci-secure-files'
           gitlab_rails['object_store']['objects']['pages']['bucket'] = 'gitlab-pages'
   ```

    [관리되는 ID](#azure-workload-and-managed-identities)를 사용하는 경우 `azure_storage_access_key`를 생략합니다.

   ```ruby
   gitlab_rails['object_store']['connection'] = {
     'provider' => 'AzureRM',
     'azure_storage_account_name' => '<AZURE STORAGE ACCOUNT NAME>',
     'azure_storage_domain' => '<AZURE STORAGE DOMAIN>'
   }
   ```

1. 파일을 저장하고 GitLab을 다시 시작합니다:

   ```shell
   docker compose up -d
   ```

{{< /tab >}}

{{< tab title="Self-compiled(source)" >}}

자체 컴파일된 설치의 경우 Workhorse도 Azure 자격 증명으로 구성해야 합니다. Linux 패키지 설치에서는 Workhorse 설정이 이전 설정에서 채워지기 때문에 필요하지 않습니다.

1. `/home/git/gitlab/config/gitlab.yml`을 편집하고 다음 줄을 추가하거나 수정합니다:

   ```yaml
   production: &base
     object_store:
       enabled: true
       proxy_download: false
       connection:
         provider: AzureRM
         azure_storage_account_name: '<AZURE STORAGE ACCOUNT NAME>'
         azure_storage_access_key: '<AZURE STORAGE ACCESS KEY>'
       objects:
         artifacts:
           bucket: gitlab-artifacts
         external_diffs:
           bucket: gitlab-mr-diffs
         lfs:
           bucket: gitlab-lfs
         uploads:
           bucket: gitlab-uploads
         packages:
           bucket: gitlab-packages
         dependency_proxy:
           bucket: gitlab-dependency-proxy
         terraform_state:
           bucket: gitlab-terraform-state
         ci_secure_files:
           bucket: gitlab-ci-secure-files
         pages:
           bucket: gitlab-pages
   ```

1. `/home/git/gitlab-workhorse/config.toml`을 편집하고 다음 줄을 추가하거나 수정합니다:

     ```toml
     [object_storage]
       provider = "AzureRM"

     [object_storage.azurerm]
       azure_storage_account_name = "<AZURE STORAGE ACCOUNT NAME>"
       azure_storage_access_key = "<AZURE STORAGE ACCESS KEY>"
     ```

   사용자 지정 Azure 저장소 도메인을 사용하는 경우 `azure_storage_domain`은 **not** Workhorse 구성에서 설정해야 합니다. 이 정보는 GitLab Rails와 Workhorse 간의 API 호출에서 교환됩니다.

1. 파일을 저장하고 GitLab을 다시 시작합니다:

   ```shell
   # For systems running systemd
   sudo systemctl restart gitlab.target

   # For systems running SysV init
   sudo service gitlab restart
   ```

{{< /tab >}}

{{< /tabs >}}

#### Azure Workload 및 관리되는 ID {#azure-workload-and-managed-identities}

{{< history >}}

- [GitLab 17.9에서 도입](https://gitlab.com/gitlab-org/gitlab/-/issues/242245)

{{< /history >}}

[Azure Workload Identity](https://azure.github.io/azure-workload-identity/docs/) 또는 [관리되는 ID](https://learn.microsoft.com/en-us/entra/identity/managed-identities-azure-resources/)를 사용하려면 구성에서 `azure_storage_access_key`을 생략합니다. `azure_storage_access_key`이 비어 있으면 GitLab이 다음을 시도합니다:

1. [Workload Identity](https://learn.microsoft.com/en-us/entra/workload-id/workload-identities-overview)로 임시 자격 증명을 얻습니다. `AZURE_TENANT_ID`, `AZURE_CLIENT_ID` 및 `AZURE_FEDERATED_TOKEN_FILE`은 환경에 있어야 합니다.
1. Workload Identity가 없으면 [Azure Instance Metadata Service](https://learn.microsoft.com/en-us/entra/identity/managed-identities-azure-resources/how-to-use-vm-token)에서 자격 증명을 요청합니다.
1. [User Delegation Key](https://learn.microsoft.com/en-us/rest/api/storageservices/get-user-delegation-key)를 얻습니다.
1. 해당 키로 SAS 토큰을 생성하여 저장소 계정 Blob에 액세스합니다.

ID에 `Storage Blob Data Contributor` 역할이 할당되어 있는지 확인합니다.

### 제공자별 구성 예시 {#provider-specific-configuration-examples}

다음 예시는 기본이 아닌 설정이 필요한 특정 S3 호환 제공자에 대한 구성을 보여줍니다. 여기에 나열되지 않은 모든 S3 호환 제공자의 경우 제공자의 적절한 `endpoint`와 함께 [기본 S3 호환 구성](#s3-compatible-providers)을 사용합니다.

#### Oracle Cloud Infrastructure {#oracle-cloud-infrastructure}

Oracle Cloud Infrastructure S3는 다음 설정이 필요합니다:

| 설정                         | 값 |
|:--------------------------------|:------|
| `enable_signature_v4_streaming` | `false` |
| `path_style`                    | `true` |

`enable_signature_v4_streaming`이 `true`로 설정되면 `production.log`에 다음 오류가 표시될 수 있습니다:

```plaintext
STREAMING-AWS4-HMAC-SHA256-PAYLOAD is not supported
```

#### Storj Gateway (SJ) {#storj-gateway-sj}

> [!note]
> Storj Gateway는 [다중 스레드 복사를 지원하지 않습니다](https://github.com/storj/gateway-st/blob/4b74c3b92c63b5de7409378b0d1ebd029db9337d/docs/s3-compatibility.md) (표의 `UploadPartCopy` 참조). 구현이 [계획 중](https://github.com/storj/roadmap/issues/40) 이지만 완료될 때까지 [다중 스레드 복사를 비활성화](#multi-threaded-copying)해야 합니다.

[Storj Network](https://www.storj.io/)는 S3 호환 API 게이트웨이를 제공합니다. 다음 구성 예시를 사용합니다:

```ruby
gitlab_rails['object_store']['connection'] = {
  'provider' => 'AWS',
  'endpoint' => 'https://gateway.storjshare.io',
  'path_style' => true,
  'region' => 'eu1',
  'aws_access_key_id' => 'ACCESS_KEY',
  'aws_secret_access_key' => 'SECRET_KEY',
  'aws_signature_version' => 2,
  'enable_signature_v4_streaming' => false
}
```

서명 버전은 `2`이어야 합니다. v4를 사용하면 HTTP 411 Length Required 오류가 발생합니다. 자세한 내용은 [이슈 #4419](https://gitlab.com/gitlab-org/gitlab/-/issues/4419)를 참조하세요.

#### Hitachi Vantara HCP {#hitachi-vantara-hcp}

> [!note]
> HCP로의 연결은 `SignatureDoesNotMatch - The request signature we calculated does not match the signature you provided. Check your HCP Secret Access key and signing method.`라는 오류를 반환할 수 있습니다. 이 경우 `endpoint`을 네임스페이스 대신 테넌트의 URL로 설정하고 버킷 경로가 `<namespace_name>/<bucket_name>`로 구성되어 있는지 확인합니다.

[HCP](https://docs.hitachivantara.com/r/en-us/content-platform/9.7.x/mk-95hcph001/hcp-management-api-reference/introduction-to-the-hcp-management-api/support-for-the-amazon-s3-api)는 S3 호환 API를 제공합니다. 다음 구성 예시를 사용합니다:

```ruby
gitlab_rails['object_store']['connection'] = {
  'provider' => 'AWS',
  'endpoint' => 'https://<tenant_endpoint>',
  'path_style' => true,
  'region' => 'eu1',
  'aws_access_key_id' => 'ACCESS_KEY',
  'aws_secret_access_key' => 'SECRET_KEY',
  'aws_signature_version' => 4,
  'enable_signature_v4_streaming' => false
}

# Example of <namespace_name/bucket_name> formatting
gitlab_rails['object_store']['objects']['artifacts']['bucket'] = '<namespace_name>/<bucket_name>'
```

#### Ceph RGW {#ceph-rgw}

[Ceph RGW](https://docs.ceph.com/en/reef/cephadm/services/rgw/)는 Ceph용 S3 호환 API입니다. 다음 구성 예시를 사용합니다:

```ruby
gitlab_rails['object_store']['connection'] = {
  'provider' => 'AWS',
  'endpoint' => 'https://rgw-ceph.example.com',
  'region' => 'us-west-1',
  'aws_access_key_id' => 'ACCESS_KEY',
  'aws_secret_access_key' => 'SECRET_KEY',
  'path_style': true
}
```

Ceph RGW를 통해 [서버 측 암호화](#server-side-encryption-headers)를 활성화하려면 HTTPS를 사용하여 연결해야 합니다. Ceph은 안전하지 않은 연결을 통해 암호화 요청을 거부합니다.

## 통합 형식 및 Amazon S3를 사용한 전체 예시 {#full-example-using-the-consolidated-form-and-amazon-s3}

다음 예시는 AWS S3를 사용하여 모든 지원되는 서비스에 대해 객체 저장소를 활성화합니다:

{{< tabs >}}

{{< tab title="Linux 패키지(Omnibus)" >}}

1. `/etc/gitlab/gitlab.rb`을 편집하고 원하는 값으로 대체하여 다음 줄을 추가합니다:

   ```ruby
   # Consolidated object storage configuration
   gitlab_rails['object_store']['enabled'] = true
   gitlab_rails['object_store']['proxy_download'] = false
   gitlab_rails['object_store']['connection'] = {
     'provider' => 'AWS',
     'region' => 'eu-central-1',
     'aws_access_key_id' => '<AWS_ACCESS_KEY_ID>',
     'aws_secret_access_key' => '<AWS_SECRET_ACCESS_KEY>'
   }
   # OPTIONAL: The following lines are only needed if server side encryption is required
   gitlab_rails['object_store']['storage_options'] = {
     'server_side_encryption' => '<AES256 or aws:kms>',
     'server_side_encryption_kms_key_id' => '<arn:aws:kms:xxx>'
   }
   gitlab_rails['object_store']['objects']['artifacts']['bucket'] = 'gitlab-artifacts'
   gitlab_rails['object_store']['objects']['external_diffs']['bucket'] = 'gitlab-mr-diffs'
   gitlab_rails['object_store']['objects']['lfs']['bucket'] = 'gitlab-lfs'
   gitlab_rails['object_store']['objects']['uploads']['bucket'] = 'gitlab-uploads'
   gitlab_rails['object_store']['objects']['packages']['bucket'] = 'gitlab-packages'
   gitlab_rails['object_store']['objects']['dependency_proxy']['bucket'] = 'gitlab-dependency-proxy'
   gitlab_rails['object_store']['objects']['terraform_state']['bucket'] = 'gitlab-terraform-state'
   gitlab_rails['object_store']['objects']['ci_secure_files']['bucket'] = 'gitlab-ci-secure-files'
   gitlab_rails['object_store']['objects']['pages']['bucket'] = 'gitlab-pages'
   ```

   [AWS IAM 프로필](#use-amazon-instance-profiles)을 사용하고 있다면 AWS 액세스 키 및 비밀 액세스 키/값 쌍을 생략합니다. 예를 들어:

   ```ruby
   gitlab_rails['object_store']['connection'] = {
     'provider' => 'AWS',
     'region' => 'eu-central-1',
     'use_iam_profile' => true
   }
   ```

1. 파일을 저장하고 GitLab을 재구성합니다:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

{{< /tab >}}

{{< tab title="Helm 차트(Kubernetes)" >}}

1. `object_storage.yaml`이라는 파일에 다음 내용을 넣어 [Kubernetes Secret](https://docs.gitlab.com/charts/charts/globals/#connection)으로 사용합니다:

   ```yaml
   provider: AWS
   region: us-east-1
   aws_access_key_id: <AWS_ACCESS_KEY_ID>
   aws_secret_access_key: <AWS_SECRET_ACCESS_KEY>
   ```

   [AWS IAM 프로필](#use-amazon-instance-profiles)을 사용하고 있다면 AWS 액세스 키 및 비밀 액세스 키/값 쌍을 생략합니다. 예를 들어:

   ```yaml
   provider: AWS
   region: us-east-1
   use_iam_profile: true
   ```

1. Kubernetes Secret을 만듭니다:

   ```shell
   kubectl create secret generic -n <namespace> gitlab-object-storage --from-file=connection=object_storage.yaml
   ```

1. Helm 값을 내보냅니다:

   ```shell
   helm get values gitlab > gitlab_values.yaml
   ```

1. `gitlab_values.yaml`을 편집합니다:

   ```yaml
   global:
     appConfig:
        artifacts:
          bucket: gitlab-artifacts
        ciSecureFiles:
          bucket: gitlab-ci-secure-files
          enabled: true
        dependencyProxy:
          bucket: gitlab-dependency-proxy
          enabled: true
        externalDiffs:
          bucket: gitlab-mr-diffs
          enabled: true
        lfs:
          bucket: gitlab-lfs
        object_store:
          connection:
            secret: gitlab-object-storage
          enabled: true
          proxy_download: false
        packages:
          bucket: gitlab-packages
        terraformState:
          bucket: gitlab-terraform-state
          enabled: true
        uploads:
          bucket: gitlab-uploads
   ```

1. 파일을 저장하고 새 값을 적용합니다:

   ```shell
   helm upgrade -f gitlab_values.yaml gitlab gitlab/gitlab
   ```

{{< /tab >}}

{{< tab title="Docker" >}}

1. `docker-compose.yml`을 편집합니다:

   ```yaml
   version: "3.6"
   services:
     gitlab:
       environment:
         GITLAB_OMNIBUS_CONFIG: |
           # Consolidated object storage configuration
           gitlab_rails['object_store']['enabled'] = true
           gitlab_rails['object_store']['proxy_download'] = false
           gitlab_rails['object_store']['connection'] = {
             'provider' => 'AWS',
             'region' => 'eu-central-1',
             'aws_access_key_id' => '<AWS_ACCESS_KEY_ID>',
             'aws_secret_access_key' => '<AWS_SECRET_ACCESS_KEY>'
           }
           # OPTIONAL: The following lines are only needed if server side encryption is required
           gitlab_rails['object_store']['storage_options'] = {
             'server_side_encryption' => '<AES256 or aws:kms>',
             'server_side_encryption_kms_key_id' => '<arn:aws:kms:xxx>'
           }
           gitlab_rails['object_store']['objects']['artifacts']['bucket'] = 'gitlab-artifacts'
           gitlab_rails['object_store']['objects']['external_diffs']['bucket'] = 'gitlab-mr-diffs'
           gitlab_rails['object_store']['objects']['lfs']['bucket'] = 'gitlab-lfs'
           gitlab_rails['object_store']['objects']['uploads']['bucket'] = 'gitlab-uploads'
           gitlab_rails['object_store']['objects']['packages']['bucket'] = 'gitlab-packages'
           gitlab_rails['object_store']['objects']['dependency_proxy']['bucket'] = 'gitlab-dependency-proxy'
           gitlab_rails['object_store']['objects']['terraform_state']['bucket'] = 'gitlab-terraform-state'
           gitlab_rails['object_store']['objects']['ci_secure_files']['bucket'] = 'gitlab-ci-secure-files'
           gitlab_rails['object_store']['objects']['pages']['bucket'] = 'gitlab-pages'
   ```

   [AWS IAM 프로필](#use-amazon-instance-profiles)을 사용하고 있다면 AWS 액세스 키 및 비밀 액세스 키/값 쌍을 생략합니다. 예를 들어:

   ```ruby
   gitlab_rails['object_store']['connection'] = {
     'provider' => 'AWS',
     'region' => 'eu-central-1',
     'use_iam_profile' => true
   }
   ```

1. 파일을 저장하고 GitLab을 다시 시작합니다:

   ```shell
   docker compose up -d
   ```

{{< /tab >}}

{{< tab title="Self-compiled(source)" >}}

1. `/home/git/gitlab/config/gitlab.yml`을 편집하고 다음 줄을 추가하거나 수정합니다:

   ```yaml
   production: &base
     object_store:
       enabled: true
       proxy_download: false
       connection:
         provider: AWS
         aws_access_key_id: <AWS_ACCESS_KEY_ID>
         aws_secret_access_key: <AWS_SECRET_ACCESS_KEY>
         region: eu-central-1
       storage_options:
         server_side_encryption: <AES256 or aws:kms>
         server_side_encryption_key_kms_id: <arn:aws:kms:xxx>
       objects:
         artifacts:
           bucket: gitlab-artifacts
         external_diffs:
           bucket: gitlab-mr-diffs
         lfs:
           bucket: gitlab-lfs
         uploads:
           bucket: gitlab-uploads
         packages:
           bucket: gitlab-packages
         dependency_proxy:
           bucket: gitlab-dependency-proxy
         terraform_state:
           bucket: gitlab-terraform-state
         ci_secure_files:
           bucket: gitlab-ci-secure-files
         pages:
           bucket: gitlab-pages
   ```

   [AWS IAM 프로필](#use-amazon-instance-profiles)을 사용하고 있다면 AWS 액세스 키 및 비밀 액세스 키/값 쌍을 생략합니다. 예를 들어:

   ```yaml
   connection:
     provider: AWS
     region: eu-central-1
     use_iam_profile: true
   ```

1. `/home/git/gitlab-workhorse/config.toml`을 편집하고 다음 줄을 추가하거나 수정합니다:

   ```toml
   [object_storage]
     provider = "AWS"

   [object_storage.s3]
     aws_access_key_id = "<AWS_ACCESS_KEY_ID>"
     aws_secret_access_key = "<AWS_SECRET_ACCESS_KEY>"
   ```

   [AWS IAM 프로필](#use-amazon-instance-profiles)을 사용하고 있다면 AWS 액세스 키 및 비밀 액세스 키/값 쌍을 생략합니다. 예를 들어:

   ```yaml
   [object_storage.s3]
     use_iam_profile = true
   ```

1. 파일을 저장하고 GitLab을 다시 시작합니다:

   ```shell
   # For systems running systemd
   sudo systemctl restart gitlab.target

   # For systems running SysV init
   sudo service gitlab restart
   ```

{{< /tab >}}

{{< /tabs >}}

## 객체 저장소로 마이그레이션 {#migrate-to-object-storage}

기존 로컬 데이터를 객체 저장소로 마이그레이션하려면 다음 가이드를 참조하세요:

- [작업 아티팩트](cicd/job_artifacts.md#migrating-to-object-storage) (아카이브된 작업 로그 포함)
- [LFS 객체](lfs/_index.md#migrating-to-object-storage)
- [업로드](raketasks/uploads/migrate.md#migrate-to-object-storage)
- [머지 리퀘스트 diff](merge_request_diffs.md#using-object-storage)
- [패키지](packages/_index.md#migrate-packages-between-object-storage-and-local-storage) (선택 사항 기능)
- [종속성 프록시](packages/dependency_proxy.md#migrate-local-dependency-proxy-blobs-and-manifests-to-object-storage)
- [Terraform 상태 파일](terraform_state.md#migrate-to-object-storage)
- [Pages 콘텐츠](pages/_index.md#migrate-pages-deployments-to-object-storage)
- [프로젝트 수준 Secure Files](cicd/secure_files.md#migrate-to-object-storage)

## 통합 형식으로 전환 {#transition-to-consolidated-form}

저장소 특화 구성에서:

- CI/CD 아티팩트, LFS 파일, 업로드 첨부 파일 등 모든 유형의 객체에 대한 객체 저장소 구성이 독립적으로 구성됩니다.
- 암호 및 엔드포인트 URL과 같은 객체 저장소 연결 매개변수는 각 유형에 대해 복제됩니다.

예를 들어, Linux 패키지 설치에는 다음 구성이 있을 수 있습니다:

```ruby
# Original object storage configuration
gitlab_rails['artifacts_object_store_enabled'] = true
gitlab_rails['artifacts_object_store_direct_upload'] = true
gitlab_rails['artifacts_object_store_proxy_download'] = false
gitlab_rails['artifacts_object_store_remote_directory'] = 'artifacts'
gitlab_rails['artifacts_object_store_connection'] = { 'provider' => 'AWS', 'aws_access_key_id' => 'access_key', 'aws_secret_access_key' => 'secret' }
gitlab_rails['uploads_object_store_enabled'] = true
gitlab_rails['uploads_object_store_direct_upload'] = true
gitlab_rails['uploads_object_store_proxy_download'] = false
gitlab_rails['uploads_object_store_remote_directory'] = 'uploads'
gitlab_rails['uploads_object_store_connection'] = { 'provider' => 'AWS', 'aws_access_key_id' => 'access_key', 'aws_secret_access_key' => 'secret' }
```

이는 GitLab이 서로 다른 클라우드 제공자 간에 객체를 저장할 수 있다는 점에서 유연성을 제공하지만 추가 복잡성과 불필요한 중복을 생성합니다. GitLab Rails와 Workhorse 구성 요소 모두 객체 저장소에 액세스해야 하므로 통합 형식은 과도한 자격 증명 중복을 방지합니다.

통합 형식은 원본 형식의 모든 줄이 생략된 경우에만 사용됩니다. 통합 형식으로 이동하려면 원본 구성 (예: `artifacts_object_store_enabled` 또는 `uploads_object_store_connection`)을 제거합니다.

## 객체를 다른 객체 저장소 제공자로 마이그레이션 {#migrate-objects-to-a-different-object-storage-provider}

GitLab 데이터를 객체 저장소에서 다른 객체 저장소 제공자로 마이그레이션해야 할 수 있습니다. 다음 단계는 [Rclone](https://rclone.org/)을 사용하여 이를 수행하는 방법을 보여줍니다.

단계에서는 `uploads` 버킷을 이동하고 있다고 가정하지만 동일한 프로세스가 다른 버킷에 적용됩니다.

전제 조건:

- Rclone을 실행할 컴퓨터를 선택합니다. 마이그레이션하는 데이터의 양에 따라 Rclone이 오랜 시간 동안 실행되어야 할 수 있으므로 절전 모드로 전환될 수 있는 랩톱 또는 데스크톱 컴퓨터 사용을 피해야 합니다. GitLab 서버를 사용하여 Rclone을 실행할 수 있습니다.

1. [Rclone을 설치](https://rclone.org/downloads/)합니다.
1. 다음을 실행하여 Rclone을 구성합니다:

   ```shell
   rclone config
   ```

   구성 프로세스는 대화형입니다. 최소 2개의 "원격": 데이터가 현재 있는 객체 저장소 제공자용 (`old`) 및 이동 중인 제공자용 (`new`)을 추가합니다.

1. 이전 데이터를 읽을 수 있는지 확인합니다. 다음 예시는 `uploads` 버킷을 나타내지만 버킷의 이름이 다를 수 있습니다:

   ```shell
   rclone ls old:uploads | head
   ```

   현재 `uploads` 버킷에 저장된 객체의 부분 목록을 인쇄해야 합니다. 오류가 발생하거나 목록이 비어 있으면 돌아가 `rclone config`를 사용하여 Rclone 구성을 업데이트합니다.

1. 초기 복사를 수행합니다. 이 단계에서는 GitLab 서버를 오프라인으로 전환할 필요가 없습니다.

   ```shell
   rclone sync -P old:uploads new:uploads
   ```

1. 첫 번째 동기화가 완료된 후 새 객체 저장소 제공자의 웹 UI 또는 명령줄 인터페이스를 사용하여 새 버킷에 객체가 있는지 확인합니다. 없거나 `rclone sync`을 실행하는 동안 오류가 발생하면 Rclone 구성을 확인하고 다시 시도합니다.

이전 위치에서 새 위치로 성공적인 Rclone 복사를 최소 한 번 수행한 후 유지보수를 예약하고 GitLab 서버를 오프라인으로 전환합니다. 유지보수 기간 동안 두 가지를 수행해야 합니다:

1. 최종 `rclone sync` 실행을 수행합니다. 사용자가 새 객체를 추가할 수 없으므로 이전 버킷에 객체를 남기지 않습니다.
1. GitLab 서버의 객체 저장소 구성을 업데이트하여 `uploads`에 새 제공자를 사용합니다.

## 파일 시스템 저장소의 대안 {#alternatives-to-file-system-storage}

GitLab 구현을 [확장](reference_architectures/_index.md)하거나 내결함성 및 중복을 추가하려는 경우 블록 또는 네트워크 파일 시스템에 대한 종속성 제거를 고려할 수 있습니다. 다음 추가 가이드를 참조하세요:

1. [`git` 사용자 홈 디렉토리](https://docs.gitlab.com/omnibus/settings/configuration/#move-the-home-directory-for-a-user)가 로컬 디스크에 있는지 확인합니다.
1. [SSH 키의 데이터베이스 조회](operations/fast_ssh_key_lookup.md)를 구성하여 공유 `authorized_keys` 파일의 필요성을 제거합니다.
1. [작업 로그에 대한 로컬 디스크 사용 방지](cicd/job_logs.md#prevent-local-disk-usage).
1. [Pages 로컬 저장소 비활성화](pages/_index.md#disable-pages-local-storage).

## 문제 해결 {#troubleshooting}

### GitLab 백업에 객체 포함 안 됨 {#objects-are-not-included-in-gitlab-backups}

[백업 문서](backup_restore/backup_gitlab.md#object-storage)에 언급된 대로 GitLab 백업에 객체가 포함되지 않습니다. 대신 객체 저장소 제공자로 백업을 활성화할 수 있습니다.

### 별도 버킷 사용 {#use-separate-buckets}

각 데이터 유형에 별도 버킷을 사용하는 것이 GitLab에 권장되는 방법입니다. 이렇게 하면 GitLab이 저장하는 다양한 유형의 데이터 간에 충돌이 없습니다. [이슈 292958](https://gitlab.com/gitlab-org/gitlab/-/issues/292958)은 단일 버킷 사용을 활성화할 것을 제안합니다.

Linux 패키지 및 자체 컴파일된 설치를 사용하면 단일 실제 버킷을 여러 가상 버킷으로 분할할 수 있습니다. 객체 저장소 버킷이 `my-gitlab-objects`이라고 하면 업로드가 `my-gitlab-objects/uploads`, 아티팩트가 `my-gitlab-objects/artifacts` 등으로 이동하도록 구성할 수 있습니다. 응용 프로그램은 이것이 별도 버킷인 것처럼 작동합니다. 버킷 접두사 사용은 [Helm 백업에서 제대로 작동하지 않을 수 있습니다](https://gitlab.com/gitlab-org/charts/gitlab/-/issues/3376).

Helm 기반 설치는 [백업 복원을 처리](https://docs.gitlab.com/charts/advanced/external-object-storage/#lfs-artifacts-uploads-packages-external-diffs-terraform-state-dependency-proxy-secure-files)하기 위해 별도 버킷이 필요합니다.

### S3 API 호환성 문제 {#s3-api-compatibility-issues}

S3 호환 제공자에서 오류가 발생하면 일반적인 원인 및 구성 조정을 위해 [S3 호환성 및 알려진 실패 모드](#s3-compatibility-and-known-failure-modes)를 참조하세요. `411 Length Required` 오류는 `production.log`에서 일반적으로 서명 스트리밍으로 인해 발생합니다. `enable_signature_v4_streaming: false`를 설정하여 해결합니다.

### 아티팩트는 항상 파일 이름 `download`로 다운로드됨 {#artifacts-always-downloaded-with-filename-download}

다운로드한 아티팩트 파일 이름은 [GetObject 요청](https://docs.aws.amazon.com/AmazonS3/latest/API/API_GetObject.html)의 `response-content-disposition` 헤더로 설정됩니다. S3 제공자가 이 헤더를 지원하지 않으면 다운로드된 파일은 항상 `download`으로 저장됩니다.

### 프록시 다운로드 {#proxy-download}

클라이언트는 사전 서명된 시간 제한 URL을 수신하거나 GitLab이 객체 저장소에서 클라이언트로 데이터를 프록시하여 객체 저장소의 파일을 다운로드할 수 있습니다. 객체 저장소에서 직접 파일을 다운로드하면 GitLab이 처리해야 하는 송신 트래픽의 양을 줄이는 데 도움이 됩니다.

파일이 로컬 블록 저장소 또는 NFS에 저장된 경우 GitLab이 프록시로 작동해야 합니다. 이는 객체 저장소의 기본 동작이 아닙니다.

`proxy_download` 설정은 이 동작을 제어합니다. 기본값은 `false`입니다. 각 사용 사례의 문서에서 이를 확인합니다.

GitLab이 파일을 프록시하도록 하려면 `proxy_download`을 `true`로 설정합니다. `proxy_download`이 `true`로 설정된 경우 GitLab 서버에 큰 성능 영향이 있을 수 있습니다. GitLab의 서버 배포는 `proxy_download`를 `false`으로 설정했습니다.

`proxy_download`을 `false`로 설정하면 GitLab은 [사전 서명된 시간 제한 객체 저장소 URL을 사용한 HTTP 302 리다이렉트](https://gitlab.com/gitlab-org/gitlab/-/issues/32117#note_218532298)를 반환합니다. 이로 인해 다음과 같은 문제가 발생할 수 있습니다:

- GitLab이 안전하지 않은 HTTP를 사용하여 객체 저장소에 액세스하는 경우 클라이언트가 `https->http` 다운그레이드 오류를 생성하고 리다이렉트 처리를 거부할 수 있습니다. 이 해결책은 GitLab이 HTTPS를 사용하는 것입니다. 예를 들어 LFS는 다음 오류를 생성합니다:

  ```plaintext
  LFS: lfsapi/client: refusing insecure redirect, https->http
  ```

- 클라이언트는 객체 저장소 인증서를 발급한 인증 기관을 신뢰하거나 다음과 같은 일반적인 TLS 오류를 반환해야 합니다:

  ```plaintext
  x509: certificate signed by unknown authority
  ```

- 클라이언트는 객체 저장소에 대한 네트워크 액세스가 필요합니다. 네트워크 방화벽이 액세스를 차단할 수 있습니다. 이 액세스가 제대로 작동하지 않으면 다음과 같은 오류가 발생할 수 있습니다:

  ```plaintext
  Received status code 403 from server: Forbidden
  ```

- 객체 저장소 버킷은 GitLab 인스턴스의 URL에서 Cross-Origin Resource Sharing (CORS) 액세스를 허용해야 합니다. 저장소 페이지에서 PDF를 로드하려고 하면 다음 오류가 표시될 수 있습니다:

  ```plaintext
  An error occurred while loading the file. Please try again later.
  ```

  자세한 내용은 [LFS 문서](lfs/_index.md#error-viewing-a-pdf-file)를 참조하세요.

> [!warning]
> 사전 서명된 URL은 시간 제한이 있지만 특정 사용자에게 연결되어 있지 않습니다. 사전 서명된 URL을 얻은 모든 사용자는 URL의 유효 기간 동안 인증 없이 객체에 액세스할 수 있습니다. 직접 다운로드는 객체 저장소 제공자와 클라이언트 간의 대역폭 요금을 발생시킬 수도 있습니다.

### ETag 불일치 {#etag-mismatch}

기본 GitLab 설정을 사용하면 [Alibaba](https://gitlab.com/gitlab-org/charts/gitlab/-/issues/1564)와 같은 일부 S3 호환 객체 저장소 백엔드가 `ETag mismatch` 오류를 생성할 수 있습니다.

#### Amazon S3 암호화 {#amazon-s3-encryption}

Amazon Web Services S3에서 이 ETag 불일치 오류가 표시되면 [버킷의 암호화 설정](https://docs.aws.amazon.com/AmazonS3/latest/API/RESTCommonResponseHeaders.html)으로 인한 것일 수 있습니다. 이 문제를 해결하려면 두 가지 옵션이 있습니다:

- [통합 형식을 사용](#configure-a-single-storage-connection-for-all-object-types-consolidated-form)합니다.
- [Amazon 인스턴스 프로필을 사용](#use-amazon-instance-profiles)합니다.

통합 형식은 S3 호환 서비스에 권장됩니다. 일부 서비스는 호환성 모드 활성화와 같은 추가 서버 측 구성이 필요할 수도 있으므로 ETag 불일치 오류를 해결합니다.

통합 형식 또는 인스턴스 프로필을 활성화하지 않으면 GitLab Workhorse는 `Content-MD5` HTTP 헤더가 계산되지 않은 사전 서명된 URL을 사용하여 S3에 파일을 업로드합니다. 데이터 손상을 방지하기 위해 Workhorse는 전송된 데이터의 MD5 해시가 S3 서버에서 반환된 ETag 헤더와 같은지 확인합니다. 암호화가 활성화되면 이는 해당되지 않으므로 Workhorse는 업로드 중에 `ETag mismatch` 오류를 보고합니다.

통합 형식이:

- S3 호환 객체 저장소 또는 인스턴스 프로필과 함께 사용되면 Workhorse는 `Content-MD5` 헤더를 계산할 수 있도록 S3 자격 증명을 가진 내부 S3 클라이언트를 사용합니다. 이렇게 하면 S3 서버에서 반환된 ETag 헤더를 비교할 필요가 없습니다.
- S3 호환 객체 저장소와 함께 사용되지 않으면 Workhorse는 사전 서명된 URL을 사용하는 것으로 돌아갑니다.

#### Google Cloud Storage 암호화 {#google-cloud-storage-encryption}

{{< history >}}

- [GitLab 16.11에서 도입](https://gitlab.com/gitlab-org/gitlab/-/issues/441782).

{{< /history >}}

ETag 불일치 오류는 [고객이 관리하는 암호화 키 (CMEK)를 사용한 데이터 암호화](https://cloud.google.com/storage/docs/encryption/using-customer-managed-keys)를 활성화할 때도 Google Cloud Storage (GCS)에서 발생합니다.

CMEK를 사용하려면 [통합 형식](#configure-a-single-storage-connection-for-all-object-types-consolidated-form)을 사용합니다.

### 다중 스레드 복사 {#multi-threaded-copying}

GitLab은 [S3 Upload Part Copy API](https://docs.aws.amazon.com/AmazonS3/latest/API/API_UploadPartCopy.html)를 사용하여 버킷 내 파일 복사를 가속화합니다. 이 기능은 일부 S3 호환 제공자에서 지원되지 않으며 [업로드 중에 404 오류를 반환](https://gitlab.com/gitlab-org/gitlab/-/issues/300604)합니다.

다중 스레드 복사를 비활성화하려면 [Rails 콘솔 액세스](feature_flags/_index.md#how-to-enable-and-disable-features-behind-flags)가 있는 GitLab 관리자에게 다음 명령을 실행하도록 요청합니다:

```ruby
Feature.disable(:s3_multithreaded_uploads)
```

### Rails 콘솔을 통한 수동 테스트 {#manual-testing-through-rails-console}

구성 오류를 의심할 때 이 접근 방식을 사용하여 객체 저장소 연결을 확인합니다. 다음 예시는 연결을 테스트하고 테스트 객체를 작성한 다음 읽으로 돌아갑니다.

1. [Rails 콘솔](operations/rails_console.md)을 시작합니다.
1. `/etc/gitlab/gitlab.rb`에 설정한 것과 동일한 매개변수를 사용하여 객체 저장소 연결을 설정합니다. 다음 예시 형식에서:

   기존 업로드 구성을 사용한 예시 연결:

   ```ruby
   settings = Gitlab.config.uploads.object_store.connection.deep_symbolize_keys
   connection = Fog::Storage.new(settings)
   ```

   액세스 키를 사용한 예시 연결:

   ```ruby
   connection = Fog::Storage.new(
     {
       provider: 'AWS',
       region: 'eu-central-1',
       aws_access_key_id: '<AWS_ACCESS_KEY_ID>',
       aws_secret_access_key: '<AWS_SECRET_ACCESS_KEY>'
     }
   )
   ```

   AWS IAM 프로필을 사용한 예시 연결:

   ```ruby
   connection = Fog::Storage.new(
     {
       provider: 'AWS',
       use_iam_profile: true,
       region: 'us-east-1'
     }
   )
   ```

1. 테스트할 버킷 이름을 지정하고 테스트 파일을 작성한 후 마지막으로 읽습니다.

   ```ruby
   dir = connection.directories.new(key: '<bucket-name-here>')
   f = dir.files.create(key: 'test.txt', body: 'test')
   pp f
   pp dir.files.head('test.txt')
   ```

#### 추가 디버깅 활성화 {#enable-additional-debugging}

{{< history >}}

- `AWS_DEBUG` 환경 변수 지원은 GitLab 18.3에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/198651)되었습니다.

{{< /history >}}

또한 HTTP 요청을 보기 위해 추가 디버깅을 활성화할 수 있습니다. 로그 파일에서 자격 증명이 유출되는 것을 피하기 위해 [Rails 콘솔](operations/rails_console.md)에서 이를 수행해야 합니다. 다음은 다양한 제공자에 대한 요청 디버깅을 활성화하는 방법을 보여줍니다:

{{< tabs >}}

{{< tab title="Amazon S3" >}}

`EXCON_DEBUG` 환경 변수를 설정합니다:

```ruby
ENV['EXCON_DEBUG'] = "1"
```

`AWS_DEBUG` 환경 변수를 `1`로 설정하여 GitLab Workhorse 로그에서 S3 HTTP 요청 및 응답 헤더 로깅을 활성화할 수도 있습니다. Linux 패키지(Omnibus)의 경우:

1. `/etc/gitlab/gitlab.rb`을 편집하고 다음 줄을 추가합니다:

   ```ruby
   gitlab_workhorse['env'] = {
     'AWS_DEBUG' => '1'
   }
   ```

1. 파일을 저장하고 GitLab을 재구성합니다:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

   S3 호환 스토리지 요청 및 응답 헤더는 `/var/log/gitlab/gitlab-workhorse/current`에 기록됩니다.

{{< /tab >}}

{{< tab title="Google Cloud Storage" >}}

로거가 `STDOUT`에 기록하도록 구성합니다:

```ruby
Google::Apis.logger = Logger::new(STDOUT)
```

{{< /tab >}}

{{< tab title="Azure Blob Storage" >}}

`DEBUG` 환경 변수를 설정합니다:

```ruby
ENV['DEBUG'] = "1"
```

{{< /tab >}}

{{< /tabs >}}

### Geo 추적 데이터베이스를 재설정하여 개체 일관성 보장 {#reset-the-geo-tracking-database-to-ensure-full-objects-consistency}

다음 Geo 시나리오를 가정합니다:

- 환경은 Geo 주 노드와 보조 노드로 구성됩니다.
- 주 노드에서 [객체 스토리지로 마이그레이션](#migrate-to-object-storage)했습니다.
  - 보조 노드는 별도의 객체 스토리지 버킷을 사용합니다.
  - "이 보조 사이트가 객체 스토리지에서 콘텐츠를 복제하도록 허용" 옵션이 활성화됩니다.

이러한 마이그레이션으로 인해 개체가 추적 데이터베이스에서 동기화된 것으로 표시될 수 있지만 객체 스토리지에는 실제로 없을 수 있습니다. 이 경우 [Geo 보조 사이트 복제를 재설정](geo/replication/troubleshooting/synchronization_verification.md#resetting-geo-secondary-site-replication)하여 마이그레이션 후 개체 상태가 일관성 있게 유지되도록 합니다.

### 객체 스토리지로 마이그레이션 후 불일치 {#inconsistencies-after-migrating-to-object-storage}

로컬에서 객체 스토리지로 마이그레이션할 때 데이터 불일치가 발생할 수 있습니다. 특히 [Geo](geo/replication/object_storage.md)와 함께 마이그레이션 전에 파일이 수동으로 삭제된 경우입니다.

예를 들어 인스턴스 관리자가 로컬 파일 시스템에서 여러 아티팩트를 수동으로 삭제합니다. 이러한 변경 사항은 데이터베이스에 제대로 전파되지 않아 불일치가 발생합니다. 객체 스토리지로 마이그레이션한 후 이러한 불일치가 유지되어 문제가 발생할 수 있습니다. Geo 보조 노드는 데이터베이스에서 여전히 참조되지만 더 이상 존재하지 않는 파일을 복제하려고 계속 시도할 수 있습니다.

#### Geo를 사용할 때 불일치 파악 {#identify-inconsistencies-when-using-geo}

다음 Geo 시나리오를 가정합니다:

- 환경은 Geo 주 노드와 보조 노드로 구성됩니다.
- 두 시스템 모두 객체 스토리지로 마이그레이션되었습니다.
  - 보조 노드는 주 노드와 동일한 객체 스토리지를 사용합니다.
  - `Allow this secondary site to replicate content on Object Storage` 옵션이 비활성화됩니다.
- 여러 업로드는 객체 스토리지 마이그레이션 전에 수동으로 삭제되었습니다.
  - 이 예에서는 이슈에 업로드된 두 개의 이미지입니다.

이러한 시나리오에서 보조 노드는 주 노드와 동일한 객체 스토리지를 사용하므로 더 이상 데이터를 복제할 필요가 없습니다. 불일치로 인해 관리자는 보조 노드가 여전히 데이터를 복제하려고 시도하는 것을 관찰할 수 있습니다:

주 사이트에서:

1. 오른쪽 위 모서리에서 **Admin**을 선택합니다.
1. 왼쪽 사이드바에서 **Geo** > **사이트**를 선택합니다.
1. **primary site**를 확인하고 검증 정보를 확인합니다. 모든 업로드가 검증되었습니다:  ![주 사이트의 성공적인 검증을 표시하는 Geo 사이트 대시보드입니다.](img/geo_primary_uploads_verification_v17_11.png)
1. **secondary site**를 확인하고 검증 정보를 확인합니다. 보조 노드가 동일한 객체 스토리지를 사용해야 하지만 두 개의 업로드가 여전히 동기화되고 있습니다. 즉, 업로드를 동기화할 필요가 없어야 합니다:  ![보조 사이트의 불일치를 표시하는 Geo 사이트 대시보드입니다.](img/geo_secondary_uploads_inconsistencies_v17_11.png)

#### 불일치 정리 {#clean-up-inconsistencies}

> [!warning]
> 삭제 명령을 실행하기 전에 최근의 작동하는 백업이 있는지 확인하십시오.

이전 시나리오를 기반으로 여러 **업로드**로 인해 불일치가 발생하고 있으며, 이는 아래의 예로 사용됩니다.

남은 파일을 제대로 삭제하려면 다음과 같이 진행합니다:

1. 파악된 불일치를 해당 모델 이름으로 매핑합니다. 모델 이름은 다음 단계에서 필요합니다.

   | 객체 저장소 유형      | 모델 이름                                              |
   |--------------------------|---------------------------------------------------------|
   | 백업                  | 해당 없음                                          |
   | 컨테이너 레지스트리       | 해당 없음                                          |
   | Mattermost               | 해당 없음                                          |
   | 자동 스케일 러너 캐싱 | 해당 없음                                          |
   | Secure Files             | `Ci::SecureFile`                                        |
   | 작업 아티팩트            | `Ci::JobArtifact` 및 `Ci::PipelineArtifact`            |
   | LFS 객체              | `LfsObject`                                             |
   | 업로드                  | `Upload`                                                |
   | 머지 리퀘스트 diff      | `MergeRequestDiff`                                      |
   | 패키지                 | `Packages::PackageFile`                                 |
   | 종속성 프록시         | `DependencyProxy::Blob` 및 `DependencyProxy::Manifest` |
   | Terraform 상태 파일    | `Terraform::StateVersion`                               |
   | Pages 콘텐츠            | `PagesDeployment`                                       |

1. [Rails 콘솔](operations/rails_console.md)을 시작합니다.
1. 이전 단계의 모델 이름을 기반으로 객체 스토리지 대신 로컬에 저장된 모든 "파일"을 쿼리합니다. 이 경우 업로드가 영향을 받으므로 모델 이름 `Upload`이 사용됩니다. `openbao.png`이 여전히 로컬에 저장되어 있는 방식을 관찰합니다:

   ```ruby
   Upload.with_files_stored_locally
   ```

   ```ruby
   #<Upload:0x00007d35b69def68
     id: 108,
     size: 13346,
     path: "c95c1c9bf91a34f7d97346fd3fa6a7be/openbao.png",
     checksum: "db29d233de49b25d2085dcd8610bac787070e721baa8dcedba528a292b6e816b",
     model_id: 2,
     model_type: "Project",
     uploader: "FileUploader",
     created_at: Wed, 02 Apr 2025 05:56:47.941319000 UTC +00:00,
     store: 1,
     mount_point: nil,
     secret: "[FILTERED]",
     version: 2,
     uploaded_by_user_id: 1,
     organization_id: nil,
     namespace_id: nil,
     project_id: 2,
     verification_checksum: nil>]
   ```

1. 파악된 리소스의 `id`을 사용하여 적절히 삭제합니다. 먼저 `find`을 사용하여 올바른 리소스인지 확인한 후 `destroy`을 실행합니다:

   ```ruby
   Upload.find(108)
   Upload.find(108).destroy
   ```

1. 선택적으로 `find`을 다시 실행하여 리소스가 올바르게 삭제되었는지 확인합니다. 이제 더 이상 찾을 수 없어야 합니다:

   ```ruby
   Upload.find(108)
   ```

   ```ruby
   ActiveRecord::RecordNotFound: Couldn't find Upload with 'id'=108
   ```

영향을 받는 모든 객체 스토리지 유형에 대해 단계를 반복합니다.

### 작업 로그가 다중 노드 GitLab 인스턴스에서 누락됨 {#job-logs-are-missing-in-a-multi-node-gitlab-instance}

둘 이상의 Rails 노드(웹 서비스 또는 Sidekiq을 실행하는 서버)가 있는 GitLab 인스턴스에서는 러너에서 전송된 후 모든 노드에서 작업 로그를 사용할 수 있도록 하는 메커니즘이 필요합니다. 작업 로그는 로컬 디스크 또는 객체 스토리지에 저장할 수 있습니다.

NFS를 사용하지 않고 [증분 로깅 기능](cicd/job_logs.md#incremental-logging)이 활성화되지 않은 경우 작업 로그가 손실될 수 있습니다:

1. 러너로부터 로그를 수신하는 노드가 로그를 로컬 디스크에 쓰기합니다.
1. GitLab이 로그를 보관하려고 할 때 작업이 로그에 액세스할 수 없는 다른 서버에서 실행되는 경우가 많습니다.
1. 객체 스토리지로 업로드하기가 실패합니다.

다음 오류가 `/var/log/gitlab/gitlab-rails/exceptions_json.log`에도 기록될 수 있습니다:

```yaml
{
  "severity": "ERROR",
  "exception.class": "Ci::AppendBuildTraceService::TraceRangeError",
  "extra.build_id": 425187,
  "extra.body_end": 12955,
  "extra.stream_size": 720,
  "extra.stream_class": {},
  "extra.stream_range": "0-12954"
}
```

CI 아티팩트를 다중 노드 환경의 객체 스토리지에 쓰는 경우 [증분 로깅 기능을 활성화](cicd/job_logs.md#configure-incremental-logging)해야 합니다.
