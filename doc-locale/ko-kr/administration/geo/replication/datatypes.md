---
stage: Tenant Scale
group: Geo
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
gitlab_dedicated: no
title: 지원되는 Geo 데이터 유형
---

{{< details >}}

- 계층:  Premium, Ultimate
- 제공:  GitLab Self-Managed

{{< /details >}}

Geo 데이터 유형은 하나 이상의 GitLab 기능에서 관련 정보를 저장하기 위해 필요한 특정 데이터 클래스입니다.

Geo를 사용하여 이러한 기능에서 생성된 데이터를 복제하려면 액세스, 전송 및 확인하기 위해 여러 전략을 사용합니다.

## 데이터 유형 {#data-types}

다음의 서로 다른 데이터 유형을 구분합니다:

- [Git 리포지토리](#git-repositories)
- [컨테이너 리포지토리](#container-repositories)
- [Blob](#blobs)
- [데이터베이스](#databases)

복제하는 각 기능 또는 구성 요소, 해당 데이터 유형, 복제 및 확인 방법의 목록을 참조하세요:

| 유형                 | 기능 / 구성 요소                             | 복제 방법                           | 확인 방법           |
|:---------------------|:------------------------------------------------|:---------------------------------------------|:------------------------------|
| 데이터베이스             | PostgreSQL의 애플리케이션 데이터                  | 기본                                       | 기본                        |
| 데이터베이스             | Redis                                           | 해당 없음 <sup>1</sup>                  | 해당 없음                |
| 데이터베이스             | 고급 검색(Elasticsearch 또는 OpenSearch)   | 기본                                       | 기본                        |
| 데이터베이스             | 정확한 코드 검색(Zoekt)                       | 기본                                       | 기본                        |
| 데이터베이스             | SSH 공개 키                                 | PostgreSQL 복제                       | PostgreSQL 복제        |
| Git                  | 프로젝트 리포지토리                              | Gitaly를 사용한 Geo                              | Gitaly 체크섬               |
| Git                  | 프로젝트 위키 리포지토리                         | Gitaly를 사용한 Geo                              | Gitaly 체크섬               |
| Git                  | 프로젝트 설계 리포지토리                      | Gitaly를 사용한 Geo                              | Gitaly 체크섬               |
| Git                  | 프로젝트 스니펫                                | Gitaly를 사용한 Geo                              | Gitaly 체크섬               |
| Git                  | 개인 스니펫                               | Gitaly를 사용한 Geo                              | Gitaly 체크섬               |
| Git                  | 그룹 위키 리포지토리                           | Gitaly를 사용한 Geo                              | Gitaly 체크섬               |
| Blob                 | 사용자 업로드 _(파일 시스템)_                    | API를 사용한 Geo                                 | SHA256 체크섬               |
| Blob                 | 사용자 업로드 _(객체 스토리지)_                 | API/관리형을 사용한 Geo <sup>2</sup>            | SHA256 체크섬 <sup>3</sup>  |
| Blob                 | LFS 객체 _(파일 시스템)_                     | API를 사용한 Geo                                 | SHA256 체크섬               |
| Blob                 | LFS 객체 _(객체 스토리지)_                  | API/관리형을 사용한 Geo <sup>2</sup>            | SHA256 체크섬 <sup>3</sup>  |
| Blob                 | CI 작업 아티팩트 _(파일 시스템)_                | API를 사용한 Geo                                 | SHA256 체크섬               |
| Blob                 | CI 작업 아티팩트 _(객체 스토리지)_             | API/관리형을 사용한 Geo <sup>2</sup>            | SHA256 체크섬 <sup>3</sup>  |
| Blob                 | 보관된 CI 빌드 추적 _(파일 시스템)_        | API를 사용한 Geo                                 | 구현되지 않음             |
| Blob                 | 보관된 CI 빌드 추적 _(객체 스토리지)_     | API/관리형을 사용한 Geo <sup>2</sup>            | SHA256 체크섬 <sup>3</sup>  |
| Blob                 | 컨테이너 레지스트리 _(파일 시스템)_              | API/Docker API를 사용한 Geo                      | SHA256 체크섬               |
| Blob                 | 컨테이너 레지스트리 _(객체 스토리지)_           | API/관리형/Docker API를 사용한 Geo <sup>2</sup> | SHA256 체크섬 <sup>3</sup>  |
| Blob                 | 패키지 레지스트리 _(파일 시스템)_                | API를 사용한 Geo                                 | SHA256 체크섬               |
| Blob                 | 패키지 레지스트리 _(객체 스토리지)_             | API/관리형을 사용한 Geo <sup>2</sup>            | SHA256 체크섬 <sup>3</sup>  |
| Blob                 | 패키지 Helm 메타데이터 캐시 _(파일 시스템)_    | API를 사용한 Geo                                 | SHA256 체크섬               |
| Blob                 | 패키지 Helm 메타데이터 캐시 _(객체 스토리지)_ | API/관리형을 사용한 Geo <sup>2</sup>            | SHA256 체크섬 <sup>3</sup>  |
| Blob                 | Terraform 모듈 레지스트리 _(파일 시스템)_       | API를 사용한 Geo                                 | SHA256 체크섬               |
| Blob                 | Terraform 모듈 레지스트리 _(객체 스토리지)_    | API/관리형을 사용한 Geo <sup>2</sup>            | SHA256 체크섬 <sup>3</sup>  |
| Blob                 | 버전이 지정된 Terraform 상태 _(파일 시스템)_       | API를 사용한 Geo                                 | SHA256 체크섬               |
| Blob                 | 버전이 지정된 Terraform 상태 _(객체 스토리지)_    | API/관리형을 사용한 Geo <sup>2</sup>            | SHA256 체크섬 <sup>3</sup>  |
| Blob                 | 외부 머지 리퀘스트 차이 _(파일 시스템)_    | API를 사용한 Geo                                 | SHA256 체크섬               |
| Blob                 | 외부 머지 리퀘스트 차이 _(객체 스토리지)_ | API/관리형을 사용한 Geo <sup>2</sup>            | SHA256 체크섬 <sup>3</sup>  |
| Blob                 | 파이프라인 아티팩트 _(파일 시스템)_              | API를 사용한 Geo                                 | SHA256 체크섬               |
| Blob                 | 파이프라인 아티팩트 _(객체 스토리지)_           | API/관리형을 사용한 Geo <sup>2</sup>            | SHA256 체크섬 <sup>3</sup>  |
| Blob                 | 페이지 _(파일 시스템)_                           | API를 사용한 Geo                                 | SHA256 체크섬               |
| Blob                 | 페이지 _(객체 스토리지)_                        | API/관리형을 사용한 Geo <sup>2</sup>            | SHA256 체크섬 <sup>3</sup>  |
| Blob                 | CI 보안 파일 _(파일 시스템)_                 | API를 사용한 Geo                                 | SHA256 체크섬               |
| Blob                 | CI 보안 파일 _(객체 스토리지)_              | API/관리형을 사용한 Geo <sup>2</sup>            | SHA256 체크섬 <sup>3</sup>  |
| Blob                 | 인시던트 메트릭 이미지 _(파일 시스템)_          | API/관리형을 사용한 Geo                         | SHA256 체크섬               |
| Blob                 | 인시던트 메트릭 이미지 _(객체 스토리지)_       | API/관리형을 사용한 Geo <sup>2</sup>            | SHA256 체크섬 <sup>3</sup>  |
| Blob                 | 경고 메트릭 이미지 _(파일 시스템)_             | API를 사용한 Geo                                 | SHA256 체크섬               |
| Blob                 | 경고 메트릭 이미지 _(객체 스토리지)_          | API/관리형을 사용한 Geo <sup>2</sup>            | SHA256 체크섬 <sup>3</sup>  |
| Blob                 | 종속성 프록시 이미지 _(파일 시스템)_         | API를 사용한 Geo                                 | SHA256 체크섬               |
| Blob                 | 종속성 프록시 이미지 _(객체 스토리지)_      | API/관리형을 사용한 Geo <sup>2</sup>            | SHA256 체크섬 <sup>3</sup>  |
| Blob                 | 패키지 nuget 기호 _(파일 시스템)_      |  API를 사용한 Geo                                   | SHA256 체크섬 |
| Blob                 | 패키지 nuget 기호 _(객체 스토리지)_              |  API/Docker API를 사용한 Geo                           | SHA256 체크섬 <sup>3</sup> |
| 컨테이너 리포지토리 | 컨테이너 레지스트리 _(파일 시스템)_              | API/Docker API를 사용한 Geo                      | SHA256 체크섬               |
| 컨테이너 리포지토리 | 컨테이너 레지스트리 _(객체 스토리지)_           | API/관리형/Docker API를 사용한 Geo <sup>2</sup> | SHA256 체크섬 <sup>3</sup>  |

**각주**:

1. Redis 복제는 Redis 센티널을 사용한 HA의 일부로 사용할 수 있습니다. Geo 사이트 간에는 사용되지 않습니다.
1. 객체 스토리지 복제는 Geo 또는 객체 스토리지 제공자/어플라이언스 기본 복제 기능으로 수행할 수 있습니다.
1. 객체 스토리지 확인은 [기능 플래그](../../feature_flags/_index.md) `geo_object_storage_verification` 뒤에 있으며 [16.4에서 도입됨](https://gitlab.com/groups/gitlab-org/-/epics/8056)으로 기본적으로 활성화되어 있습니다. 파일 크기의 체크섬을 사용하여 파일을 확인합니다.

### Git 리포지토리 {#git-repositories}

GitLab 인스턴스는 하나 이상의 리포지토리 샤드를 가질 수 있습니다. 각 샤드에는 로컬로 저장된 Git 리포지토리에 대한 액세스 및 작업을 허용하는 책임이 있는 Gitaly 인스턴스가 있습니다. 머신에서 실행할 수 있습니다:

- 단일 디스크 포함.
- 단일 마운트 포인트로 마운트된 여러 디스크 포함(RAID 어레이처럼).
- LVM 사용.

GitLab은 특수 파일 시스템을 요구하지 않으며 마운트된 스토리지 어플라이언스와 함께 작동할 수 있습니다. 그러나 원격 파일 시스템을 사용할 때 성능 제한 및 일관성 문제가 발생할 수 있습니다.

Geo는 Geo 세컨더리 사이트에서 포크된 리포지토리를 중복 제거하기 위해 Gitaly에서 가비지 수집을 트리거합니다.

Gitaly gRPC API는 세 가지 가능한 동기화 방식으로 통신을 수행합니다:

- 한 Geo 사이트에서 다른 사이트로 일반 Git 클론/페치를 사용합니다(특수 인증 포함).
- 리포지토리 스냅숏을 사용합니다(첫 번째 방법이 실패하거나 리포지토리가 손상된 경우).
- **운영자** 영역에서 수동으로 트리거합니다(다른 나열된 가능한 방식을 결합함).

각 프로젝트는 최대 3개의 서로 다른 리포지토리를 가질 수 있습니다:

- 소스 코드가 저장되는 프로젝트 리포지토리.
- 위키 콘텐츠가 저장되는 위키 리포지토리.
- 설계 아티팩트가 인덱싱되는 설계 리포지토리(자산은 실제로 LFS에 있음).

모두 같은 샤드에 있으며 `-wiki` 및 `-design` 접미사로 같은 기본 이름을 공유합니다. 위키 및 설계 리포지토리의 경우입니다.

이 외에도 스니펫 리포지토리가 있습니다. 프로젝트 또는 특정 사용자에게 연결할 수 있습니다. 두 유형 모두 세컨더리 사이트에 동기화됩니다.

### 컨테이너 리포지토리 {#container-repositories}

컨테이너 리포지토리는 컨테이너 레지스트리에 저장됩니다. 이는 데이터 저장소로서 컨테이너 레지스트리 위에 구축된 GitLab 특정 개념입니다.

### Blob {#blobs}

GitLab은 이슈 첨부 파일 또는 LFS 객체와 같은 파일 및 blob을 다음 중 하나에 저장합니다:

- 특정 위치의 파일 시스템.
- [객체 스토리지](../../object_storage.md) 솔루션. 객체 스토리지 솔루션은 다음과 같을 수 있습니다:
  - Amazon S3 및 Google Cloud Storage와 같은 클라우드 기반.
  - 자체 호스팅 S3 호환 객체 스토리지.
  - 객체 스토리지 호환 API를 노출하는 스토리지 어플라이언스.

객체 스토리지 대신 파일 시스템 저장소를 사용할 때 네트워크 마운트 파일 시스템을 사용하여 둘 이상의 노드를 사용할 때 GitLab을 실행합니다.

복제 및 확인과 관련하여:

- 내부 API 요청을 사용하여 파일과 blob을 전송합니다.
- 객체 스토리지를 사용하면 다음 중 하나를 수행할 수 있습니다:
  - 클라우드 공급자 복제 기능을 사용합니다.
  - GitLab이 복제하도록 합니다.

### 데이터베이스 {#databases}

GitLab은 여러 데이터베이스에 저장된 데이터에 의존하며 여러 사용 사례가 있습니다. PostgreSQL은 이슈 콘텐츠, 댓글 및 권한과 자격 증명을 포함한 웹 인터페이스의 사용자 생성 콘텐츠의 단일 신뢰 지점입니다.

PostgreSQL은 또한 HTML로 렌더링된 Markdown 및 캐시된 머지 리퀘스트 차이와 같은 일부 수준의 캐시된 데이터를 보유할 수 있습니다. 이는 또한 객체 스토리지에 오프로드되도록 구성할 수 있습니다.

PostgreSQL의 자체 복제 기능을 사용하여 **프라이머리** 사이트에서 **세컨더리** 사이트로 데이터를 복제합니다.

캐시 저장소와 백그라운드 작업 시스템을 위한 지속 데이터를 모두 보유하기 위해 Redis를 사용합니다. 두 사용 사례 모두 같은 Geo 사이트에 배타적인 데이터를 가지고 있으므로 사이트 간에 복제하지 않습니다.

Elasticsearch는 고급 검색을 위한 선택적 데이터베이스입니다. 소스 코드 수준 및 이슈, 머지 리퀘스트 및 토론에서 사용자 생성 콘텐츠의 검색을 모두 개선할 수 있습니다. Elasticsearch는 Geo에서 지원되지 않습니다.

## 복제된 데이터 유형 {#replicated-data-types}

### 기능 플래그 뒤에 있는 복제된 데이터 유형 {#replicated-data-types-behind-a-feature-flag}

{{< history >}}

- 이들은 기능 플래그 뒤에 배포되며 기본적으로 활성화됩니다.
- GitLab.com에서 활성화되어 있습니다.
- 프로젝트별로 활성화하거나 비활성화할 수 없습니다.
- 프로덕션 사용에 권장됩니다.
- GitLab 자체 관리 인스턴스의 경우 GitLab 관리자가 [비활성화하도록](#enable-or-disable-replication-for-some-data-types) 선택할 수 있습니다.

{{< /history >}}

> [!flag]
> 이 기능의 가용성은 기능 플래그로 제어됩니다. 자세한 내용은 기록을 참조하세요.

#### 복제 활성화 또는 비활성화(일부 데이터 유형용) {#enable-or-disable-replication-for-some-data-types}

일부 데이터 유형에 대한 복제는 **enabled by default**된 기능 플래그 뒤에 릴리스됩니다. [GitLab Rails 콘솔에 액세스할 수 있는 GitLab 관리자](../../feature_flags/_index.md)는 인스턴스에 대해 이를 비활성화하도록 선택할 수 있습니다. 아래 테이블의 메모 열에서 각 데이터 유형의 기능 플래그 이름을 찾을 수 있습니다.

패키지 파일 복제를 비활성화하려면:

```ruby
Feature.disable(:geo_package_file_replication)
```

패키지 파일 복제를 활성화하려면:

```ruby
Feature.enable(:geo_package_file_replication)
```

> [!warning]
> 이 목록에 없는 기능 또는 **아니오**가 **Replicated** 열에 있는 기능은 **세컨더리** 사이트로 복제되지 않습니다. 수동으로 이러한 기능에서 데이터를 복제하지 않고 페일오버하면 데이터가 **lost**됩니다. **세컨더리** 사이트에서 이러한 기능을 사용하거나 페일오버를 성공적으로 실행하려면 다른 수단을 사용하여 데이터를 복제해야 합니다.

| 기능                                                                                                               | 복제됨(GitLab 버전에서 추가됨)                                          | 확인됨(GitLab 버전에서 추가됨)                                            | GitLab 관리형 객체 스토리지 복제(GitLab 버전에서 추가됨)             | GitLab 관리형 객체 스토리지 확인(GitLab 버전에서 추가됨)            | 참고 |
|:----------------------------------------------------------------------------------------------------------------------|:------------------------------------------------------------------------------|:------------------------------------------------------------------------------|:--------------------------------------------------------------------------------|:--------------------------------------------------------------------------------|:------|
| [PostgreSQL의 애플리케이션 데이터](../../postgresql/_index.md)                                                           | **예** (10.2)                                                                | **예** (10.2)                                                                | 해당 없음                                                                  | 해당 없음                                                                  |       |
| [프로젝트 리포지토리](../../../user/project/repository/_index.md)                                                       | **예** (10.2)                                                                | **예** (10.7)                                                                | 해당 없음                                                                  | 해당 없음                                                                  | 16.2에서 자체 서비스 프레임워크로 마이그레이션되었습니다. 자세한 내용은 GitLab 문제 [\#367925](https://gitlab.com/gitlab-org/gitlab/-/issues/367925)를 참조하세요.<br /><br />기능 플래그 `geo_project_repository_replication` 뒤에 있으며 (16.3)에서 기본적으로 활성화됩니다.<br /><br /> [보관된 프로젝트](../../../user/project/working_with_projects.md#archive-a-project)를 포함한 모든 프로젝트가 복제됩니다. |
| [프로젝트 위키 리포지토리](../../../user/project/wiki/_index.md)                                                        | **예** (10.2)<sup>2</sup>                                                    | **예** (10.7)<sup>2</sup>                                                    | 해당 없음                                                                  | 해당 없음                                                                  | 15.11에서 자체 서비스 프레임워크로 마이그레이션되었습니다. 자세한 내용은 GitLab 문제 [\#367925](https://gitlab.com/gitlab-org/gitlab/-/issues/367925)를 참조하세요.<br /><br />기능 플래그 `geo_project_wiki_repository_replication` 뒤에 있으며 (15.11)에서 기본적으로 활성화됩니다. |
| [그룹 위키 리포지토리](../../../user/project/wiki/group.md)                                                          | [**예** (13.10)](https://gitlab.com/gitlab-org/gitlab/-/issues/208147)       | [**예** (16.3)](https://gitlab.com/gitlab-org/gitlab/-/issues/323897)        | 해당 없음                                                                  | 해당 없음                                                                  | 기능 플래그 `geo_group_wiki_repository_replication` 뒤에 있으며 기본적으로 활성화됩니다. |
| [사용자 업로드](../../uploads.md)                                                                                           | **예** (10.2)                                                                | **예** (14.6)                                                                | [**예** (15.1)](https://gitlab.com/groups/gitlab-org/-/epics/5551)             | [**예** (16.4)<sup>3</sup>](https://gitlab.com/groups/gitlab-org/-/epics/8056) | 복제는 기능 플래그 `geo_upload_replication` 뒤에 있으며 기본적으로 활성화됩니다. 확인은 기능 플래그 `geo_upload_verification` 뒤에 있었으며 14.8에서 제거되었습니다. |
| [LFS 객체](../../lfs/_index.md)                                                                                     | **예** (10.2)                                                                | **예** (14.6)                                                                | [**예** (15.1)](https://gitlab.com/groups/gitlab-org/-/epics/5551)             | [**예** (16.4)<sup>3</sup>](https://gitlab.com/groups/gitlab-org/-/epics/8056) | GitLab 버전 11.11.x 및 12.0.x는 [새 LFS 객체가 복제되지 않도록 하는 버그](https://gitlab.com/gitlab-org/gitlab/-/issues/32696)의 영향을 받습니다.<br /><br />복제는 기능 플래그 `geo_lfs_object_replication` 뒤에 있으며 기본적으로 활성화됩니다. 확인은 기능 플래그 `geo_lfs_object_verification` 뒤에 있었으며 14.7에서 제거되었습니다. |
| [개인 스니펫](../../../user/snippets.md)                                                                        | **예** (10.2)                                                                | **예** (10.2)                                                                | 해당 없음                                                                  | 해당 없음                                                                  |       |
| [프로젝트 스니펫](../../../user/snippets.md)                                                                         | **예** (10.2)                                                                | **예** (10.2)                                                                | 해당 없음                                                                  | 해당 없음                                                                  |       |
| [CI 작업 아티팩트](../../../ci/jobs/job_artifacts.md)                                                                 | **예** (10.4)                                                                | **예** (14.10)                                                               | [**예** (15.1)](https://gitlab.com/groups/gitlab-org/-/epics/5551)             | [**예** (16.4)<sup>3</sup>](https://gitlab.com/groups/gitlab-org/-/epics/8056) | 확인은 기능 플래그 `geo_job_artifact_replication` 뒤에 있으며 14.10에서 기본적으로 활성화됩니다. |
| [파이프라인 아티팩트](https://gitlab.com/gitlab-org/gitlab/-/blob/master/app/models/ci/pipeline_artifact.rb)        | [**예** (13.11)](https://gitlab.com/gitlab-org/gitlab/-/issues/238464)       | [**예** (13.11)](https://gitlab.com/gitlab-org/gitlab/-/issues/238464)       | [**예** (15.1)](https://gitlab.com/groups/gitlab-org/-/epics/5551)             | [**예** (16.4)<sup>3</sup>](https://gitlab.com/groups/gitlab-org/-/epics/8056) | 파이프라인이 완료된 후 추가 아티팩트를 지속합니다. |
| [CI 보안 파일](https://gitlab.com/gitlab-org/gitlab/-/blob/master/app/models/ci/secure_file.rb)                    | [**예** (15.3)](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/91430) | [**예** (15.3)](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/91430) | [**예** (15.3)](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/91430)   | [**예** (16.4)<sup>3</sup>](https://gitlab.com/groups/gitlab-org/-/epics/8056) | 확인은 기능 플래그 `geo_ci_secure_file_replication` 뒤에 있으며 15.3에서 기본적으로 활성화됩니다. |
| [컨테이너 레지스트리](../../packages/container_registry.md)                                                            | **예** (12.3)<sup>1</sup>                                                    | **예** (15.10)                                                               | **예** (12.3)<sup>1</sup>                                                      | **예** (15.10)                                                                 | 컨테이너 레지스트리 복제를 설정하는 [지침](container_registry.md)을 참조하세요. |
| [Terraform 모듈 레지스트리](../../../user/packages/terraform_module_registry/_index.md)                                | **예** (14.0)                                                                | **예** (14.0)                                                                | [**예** (15.1)](https://gitlab.com/groups/gitlab-org/-/epics/5551)             | [**예** (16.4)<sup>3</sup>](https://gitlab.com/groups/gitlab-org/-/epics/8056) | 기능 플래그 `geo_package_file_replication` 뒤에 있으며 기본적으로 활성화됩니다. |
| [프로젝트 설계 리포지토리](../../../user/project/issues/design_management.md)                                       | **예** (12.7)                                                                | **예** (16.1)                                                                | [**예** (16.4)<sup>3</sup>](https://gitlab.com/groups/gitlab-org/-/epics/8056) | [**예** (16.4)<sup>3</sup>](https://gitlab.com/groups/gitlab-org/-/epics/8056) | 설계를 위해서는 LFS 객체 및 업로드의 복제도 필요합니다. |
| [패키지 레지스트리](../../../user/packages/package_registry/_index.md)                                                  | **예** (13.2)                                                                | **예** (13.10)                                                               | [**예** (15.1)](https://gitlab.com/groups/gitlab-org/-/epics/5551)             | [**예** (16.4)<sup>3</sup>](https://gitlab.com/groups/gitlab-org/-/epics/8056) | 기능 플래그 `geo_package_file_replication` 뒤에 있으며 기본적으로 활성화됩니다. |
| [패키지 Helm 메타데이터 캐시](../../../user/packages/helm_repository/_index.md)                                      | [**예** (18.10)](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/219409) | [**예** (18.10)](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/219409) | [**예** (18.10)](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/219409) | [**예** (18.10)](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/219409) | 기능 플래그 `geo_packages_helm_metadata_cache_replication` 뒤에 있으며 18.10에서 기본적으로 활성화됩니다. |
| [버전이 지정된 Terraform 상태](../../terraform_state.md)                                                                 | **예** (13.5)                                                                | **예** (13.12)                                                               | [**예** (15.1)](https://gitlab.com/groups/gitlab-org/-/epics/5551)             | [**예** (16.4)<sup>3</sup>](https://gitlab.com/groups/gitlab-org/-/epics/8056) | 복제는 기능 플래그 `geo_terraform_state_version_replication` 뒤에 있으며 기본적으로 활성화됩니다. 확인은 기능 플래그 `geo_terraform_state_version_verification` 뒤에 있었으며 14.0에서 제거되었습니다. |
| [외부 머지 리퀘스트 차이](../../merge_request_diffs.md)                                                          | **예** (13.5)                                                                | **예** (14.6)                                                                | [**예** (15.1)](https://gitlab.com/groups/gitlab-org/-/epics/5551)             | [**예** (16.4)<sup>3</sup>](https://gitlab.com/groups/gitlab-org/-/epics/8056) | 복제는 기능 플래그 `geo_merge_request_diff_replication` 뒤에 있으며 기본적으로 활성화됩니다. 확인은 기능 플래그 `geo_merge_request_diff_verification` 뒤에 있었으며 14.7에서 제거되었습니다. |
| [버전이 지정된 스니펫](../../../user/snippets.md#versioned-snippets)                                                    | [**예** (13.7)](https://gitlab.com/groups/gitlab-org/-/epics/2809)           | [**예** (14.2)](https://gitlab.com/groups/gitlab-org/-/epics/2810)           | [**예** (16.4)<sup>3</sup>](https://gitlab.com/groups/gitlab-org/-/epics/8056) | [**예** (16.4)<sup>3</sup>](https://gitlab.com/groups/gitlab-org/-/epics/8056) | 확인은 13.11에서 기능 플래그 `geo_snippet_repository_verification` 뒤에 구현되었으며 14.2에서 기능 플래그가 제거되었습니다. |
| [페이지](../../pages/_index.md)                                                                                  | [**예** (14.3)](https://gitlab.com/groups/gitlab-org/-/epics/589)            | **예** (14.6)                                                                | [**예** (15.1)](https://gitlab.com/groups/gitlab-org/-/epics/5551)             | [**예** (16.4)<sup>3</sup>](https://gitlab.com/groups/gitlab-org/-/epics/8056) | 기능 플래그 `geo_pages_deployment_replication` 뒤에 있으며 기본적으로 활성화됩니다. 확인은 기능 플래그 `geo_pages_deployment_verification` 뒤에 있었으며 14.7에서 제거되었습니다. |
| [프로젝트 수준 CI 보안 파일](../../../ci/secure_files/_index.md)                                                       | **예** (15.3)                                                                | **예** (15.3)                                                                | **예** (15.3)                                                                  | [**예** (16.4)<sup>3</sup>](https://gitlab.com/groups/gitlab-org/-/epics/8056) |       |
| [인시던트 메트릭 이미지](../../../operations/incident_management/incidents.md#metrics)                                | **예** (15.5)                                                                | **예** (15.5)                                                                | **예** (15.5)                                                                  | [**예** (16.4)<sup>3</sup>](https://gitlab.com/groups/gitlab-org/-/epics/8056) | 복제/확인은 업로드 데이터 유형을 통해 처리됩니다. |
| [경고 메트릭 이미지](../../../operations/incident_management/alerts.md#metrics-tab)                                  | **예** (15.5)                                                                | **예** (15.5)                                                                | **예** (15.5)                                                                  | [**예** (16.4)<sup>3</sup>](https://gitlab.com/groups/gitlab-org/-/epics/8056) | 복제/확인은 업로드 데이터 유형을 통해 처리됩니다. |
| [서버 측 Git 훅](../../server_hooks.md)                                                                        | [계획되지 않음](https://gitlab.com/groups/gitlab-org/-/epics/1867)              | 아니오                                                                            | 해당 없음                                                                  | 해당 없음                                                                  | 현재 구현 복잡성, 낮은 고객 관심 및 훅에 대한 대안의 가용성으로 인해 계획되지 않았습니다. |
| [Elasticsearch](../../../integration/advanced_search/elasticsearch.md)                                    | [계획되지 않음](https://gitlab.com/gitlab-org/gitlab/-/issues/1186)             | 아니오                                                                            | 아니오                                                                              | 아니오                                                                              | 추가 제품 발견이 필요하고 Elasticsearch(ES) 클러스터를 다시 빌드할 수 있으므로 계획되지 않았습니다. 세컨더리 사이트는 프라이머리 사이트와 같은 ES 클러스터를 사용합니다. |
| [종속성 프록시 이미지](../../../user/packages/dependency_proxy/_index.md)                                           | [**예** (15.7)](https://gitlab.com/groups/gitlab-org/-/epics/8833)           | [**예** (15.7)](https://gitlab.com/groups/gitlab-org/-/epics/8833)           | [**예** (15.7)](https://gitlab.com/groups/gitlab-org/-/epics/8833)             | [**예** (16.4)<sup>3</sup>](https://gitlab.com/groups/gitlab-org/-/epics/8056) |       |
| [패키지 NuGet 기호](../../../user/packages/nuget_repository/_index.md#symbol-packages)                                                                                                 | [**예** (18.10)](https://gitlab.com/gitlab-org/gitlab/-/issues/422929)           | [**예** (18.10)](https://gitlab.com/gitlab-org/gitlab/-/issues/422929)           | [**예** (15.7)](https://gitlab.com/groups/gitlab-org/-/epics/8833)             | [**예** (16.4)<sup>3</sup>](https://gitlab.com/groups/gitlab-org/-/epics/8056) | 기능 플래그 `geo_packages_nuget_symbol_replication` 뒤에 있으며 기본적으로 활성화됩니다.   |
| [취약성 내보내기](../../../user/application_security/vulnerability_report/_index.md#exporting) | [계획되지 않음](https://gitlab.com/groups/gitlab-org/-/epics/3111)              | 아니오                                                                            | 아니오                                                                              | 아니오                                                                              | 일시적이고 민감한 정보이므로 계획되지 않았습니다. 필요에 따라 다시 생성할 수 있습니다. |
| 패키지 NPM 메타데이터 캐시                                                                                           | [계획되지 않음](https://gitlab.com/gitlab-org/gitlab/-/issues/408278)           | 아니오                                                                            | 아니오                                                                              | 아니오                                                                              | 재해 복구 기능이나 세컨더리 사이트의 응답 시간을 크게 개선하지 않으므로 계획되지 않았습니다. |
| 패키지 Debian GroupComponentFile                                                                                    | [계획되지 않음](https://gitlab.com/gitlab-org/gitlab/-/issues/556945)           | 아니오                                                                            | 아니오                                                                              | 아니오                                                                              |       |
| 패키지 Debian ProjectComponentFile                                                                                  | [**예** (19.1)](https://gitlab.com/gitlab-org/gitlab/-/issues/333611)       | [**예** (19.1)](https://gitlab.com/gitlab-org/gitlab/-/issues/333611)       | [**예** (19.1)](https://gitlab.com/gitlab-org/gitlab/-/issues/333611)         | [**예** (19.1)](https://gitlab.com/gitlab-org/gitlab/-/issues/333611)         | 기능 플래그 `geo_packages_debian_project_component_file_replication` 뒤에 있으며 기본적으로 비활성화됩니다. |
| 패키지 Debian GroupDistribution                                                                                     | [계획되지 않음](https://gitlab.com/gitlab-org/gitlab/-/issues/556947)           | 아니오                                                                            | 아니오                                                                              | 아니오                                                                              |       |
| 패키지 Debian ProjectDistribution                                                                                   | [계획되지 않음](https://gitlab.com/gitlab-org/gitlab/-/issues/556946)           | 아니오                                                                            | 아니오                                                                              | 아니오                                                                              |       |
| 패키지 RPM RepositoryFile                                                                                           | [계획되지 않음](https://gitlab.com/gitlab-org/gitlab/-/issues/379055)           | 아니오                                                                            | 아니오                                                                              | 아니오                                                                              |       |
| VirtualRegistries Maven 캐시 항목                                                                                   | [계획되지 않음](https://gitlab.com/gitlab-org/gitlab/-/issues/473033)           | 아니오                                                                            | 아니오                                                                              | 아니오                                                                              |       |
| SBOM 취약성 스캔 데이터                                                                                           | [계획되지 않음](https://gitlab.com/gitlab-org/gitlab/-/issues/398199)           | 아니오                                                                            | 아니오                                                                              | 아니오                                                                              | 세컨더리 사이트의 재해 복구 기능에 대한 영향이 제한적인 단기 수명이 있는 임시 데이터이므로 계획되지 않았습니다. |

**각주**:

1. 15.5에서 자체 서비스 프레임워크로 마이그레이션되었습니다. 자세한 내용은 GitLab [\#337436](https://gitlab.com/gitlab-org/gitlab/-/issues/337436) 이슈를 참조하세요.
1. 15.11에서 자체 서비스 프레임워크로 마이그레이션되었습니다. 기능 플래그 `geo_project_wiki_repository_replication` 뒤에 있으며 기본적으로 활성화됩니다. 자세한 내용은 GitLab 문제 [\#367925](https://gitlab.com/gitlab-org/gitlab/-/issues/367925)를 참조하세요.
1. 객체 스토리지에 저장된 파일의 검증은 GitLab 16.4에서 [도입](https://gitlab.com/groups/gitlab-org/-/epics/8056) 되었으며 [기능 플래그](../../feature_flags/_index.md) `geo_object_storage_verification`(으)로 명명되어 기본적으로 활성화되어 있습니다.
