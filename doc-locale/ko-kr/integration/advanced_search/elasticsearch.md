---
stage: AI-powered
group: Global Search
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: GitLab에서 고급 검색을 사용하도록 Elasticsearch를 설정하고 구성합니다.
title: Elasticsearch
---

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

이 페이지에서는 고급 검색을 활성화하는 방법을 설명합니다. 활성화되면 고급 검색은 더 빠른 검색 응답 시간과 [개선된 검색 기능](../../user/search/advanced_search.md)을 제공합니다.

고급 검색을 활성화하려면 다음을 수행해야 합니다:

1. [Elasticsearch 또는 AWS OpenSearch 클러스터 설치](#install-an-elasticsearch-or-aws-opensearch-cluster)
1. [고급 검색 활성화](#enable-advanced-search)

> [!note]
> 고급 검색은 모든 프로젝트를 동일한 Elasticsearch 인덱스에 저장합니다. 그러나 개인 프로젝트는 액세스 권한이 있는 사용자에게만 검색 결과에 표시됩니다.

## Elasticsearch 용어집 {#elasticsearch-glossary}

이 용어집은 Elasticsearch와 관련된 용어에 대한 정의를 제공합니다.

- **Lucene**: Java로 작성된 전체 텍스트 검색 라이브러리입니다.
- **Near real time (NRT)**: 문서를 인덱싱하는 시간부터 검색 가능해지는 시간까지의 약간의 지연 시간을 나타냅니다.
- **클러스터**: 함께 작동하여 모든 데이터를 보유하고 인덱싱 및 검색 기능을 제공하는 하나 이상의 노드 모음입니다.
- **Node**: 클러스터의 일부로 작동하는 단일 서버입니다.
- **인덱스**: 어느 정도 유사한 특성을 가진 문서의 모음입니다.
- **Document**: 인덱싱할 수 있는 기본 정보 단위입니다.
- **Shards**: 인덱스의 완벽하게 작동하는 독립적인 세분화입니다. 각 샤드는 실제로 Lucene 인덱스입니다.
- **Replicas**: 인덱스를 복제하는 장애 조치 메커니즘입니다.

## Elasticsearch 또는 AWS OpenSearch 클러스터 설치 {#install-an-elasticsearch-or-aws-opensearch-cluster}

Elasticsearch 및 AWS OpenSearch는 Linux 패키지에 포함되지 않습니다. 검색 클러스터를 직접 설치하거나 다음과 같은 클라우드 호스팅 제공 서비스를 사용할 수 있습니다:

- [Elasticsearch Service](https://www.elastic.co/elasticsearch/service) (Amazon Web Services, Google Cloud Platform, Microsoft Azure에서 사용 가능)
- [Amazon OpenSearch Service](https://docs.aws.amazon.com/opensearch-service/latest/developerguide/gsg.html)

검색 클러스터를 별도의 서버에 설치해야 합니다. 검색 클러스터를 GitLab과 동일한 서버에서 실행하면 성능 문제가 발생할 수 있습니다.

단일 노드를 가진 검색 클러스터의 경우 기본 샤드가 할당되어 있으므로 클러스터 상태는 항상 노란색입니다. 클러스터는 복제본 샤드를 기본 샤드와 동일한 노드에 할당할 수 없습니다.

> [!note]
> 새 Elasticsearch 클러스터를 프로덕션에 사용하기 전에 [중요 Elasticsearch 구성](https://www.elastic.co/guide/en/elasticsearch/reference/current/important-settings.html)을 참조하세요.

### 버전 호환성 {#version-compatibility}

#### Elasticsearch {#elasticsearch}

{{< history >}}

- Elasticsearch 6.8에 대한 지원이 GitLab 15.0에서 [제거되었습니다](https://gitlab.com/gitlab-org/gitlab/-/issues/350275).

{{< /history >}}

> [!warning]
> Elasticsearch 7.x에 대한 지원이 GitLab 18.10에서 [중단되었으며](https://gitlab.com/gitlab-org/gitlab/-/issues/583544) 20.0에서 제거될 계획입니다.

고급 검색은 다음 버전의 Elasticsearch와 호환됩니다.

| GitLab 버전  | Elasticsearch 버전 |
|-----------------|-----------------------|
| 19.1 이상  | 8.x 및 9.x           |
| 15.0 ~ 19.0    | 7.x 및 8.x           |
| 14.0 ~ 14.10   | 6.8 ~ 7.x            |

GitLab.com은 Elasticsearch 9.x를 사용합니다. 최적의 성능, 최신 기능 및 향후 호환성을 위해 Elasticsearch 9.x를 사용합니다.

고급 검색은 [Elasticsearch 수명 종료 정책](https://www.elastic.co/support/eol)을 따릅니다.

#### OpenSearch {#opensearch}

고급 검색은 다음 버전의 OpenSearch와 호환됩니다.

| GitLab 버전   | OpenSearch 버전 |
|------------------|--------------------|
| 18.1 이상   | 1.x 이상      |
| 17.6.3 ~ 18.0   | 1.x 및 2.x        |
| 15.5.3 ~ 17.6.2 | 1.x, 2.0 ~ 2.17   |
| 15.0 ~ 15.5.2   | 1.x                |

고급 검색은 [OpenSearch 유지보수 정책](https://opensearch.org/releases/)을 따릅니다.

### 시스템 요구사항 {#system-requirements}

Elasticsearch 및 AWS OpenSearch는 [GitLab 설치 요구사항](../../install/requirements.md)보다 더 많은 리소스를 필요로 합니다.

메모리, CPU 및 저장소 요구사항은 클러스터에 인덱싱하는 데이터 양에 따라 달라집니다. 많이 사용되는 Elasticsearch 클러스터는 더 많은 리소스가 필요할 수 있습니다. [`estimate_cluster_size`](#gitlab-advanced-search-rake-tasks) Rake 작업은 총 리포지토리 크기를 사용하여 고급 검색 저장소 요구사항을 추정합니다.

### 액세스 요구사항 {#access-requirements}

GitLab은 요구사항과 사용하는 백엔드 서비스에 따라 [HTTP 및 역할 기반 인증 방법](#advanced-search-configuration)을 모두 지원합니다.

#### Elasticsearch의 역할 기반 액세스 제어 {#role-based-access-control-for-elasticsearch}

Elasticsearch는 클러스터를 더욱 보호하기 위해 역할 기반 액세스 제어를 제공할 수 있습니다. Elasticsearch 클러스터에 액세스하고 작업을 수행하려면 **운영자** 영역에 구성된 `Username`이 다음 권한을 부여하는 역할을 가져야 합니다. `Username`은 GitLab에서 검색 클러스터로 요청을 합니다.

자세한 내용은 [Elasticsearch 역할 기반 액세스 제어](https://www.elastic.co/guide/en/elasticsearch/reference/current/authorization.html#roles) 및 [Elasticsearch 보안 권한](https://www.elastic.co/guide/en/elasticsearch/reference/current/security-privileges.html)을 참조하세요.

```json
{
  "cluster": ["monitor"],
  "indices": [
    {
      "names": ["gitlab-*"],
      "privileges": [
        "create_index",
        "delete_index",
        "view_index_metadata",
        "read",
        "manage",
        "write"
      ]
    }
  ]
}
```

#### AWS OpenSearch Service의 액세스 제어 {#access-control-for-aws-opensearch-service}

전제 조건:

- OpenSearch 도메인을 생성할 때 AWS 계정에 `AWSServiceRoleForAmazonOpenSearchService`라는 [서비스 연결 역할](https://docs.aws.amazon.com/opensearch-service/latest/developerguide/slr.html)이 있어야 합니다.
- AWS OpenSearch의 도메인 액세스 정책은 `es:ESHttp*` 작업을 허용해야 합니다.

`AWSServiceRoleForAmazonOpenSearchService`은 **전체** OpenSearch 도메인에서 사용됩니다. 대부분의 경우 AWS Management Console을 사용하여 첫 번째 OpenSearch 도메인을 생성할 때 이 역할이 자동으로 생성됩니다. 서비스 연결 역할을 수동으로 생성하려면 [AWS 설명서](https://docs.aws.amazon.com/opensearch-service/latest/developerguide/slr-aos.html#create-slr)를 참조하세요.

AWS OpenSearch Service는 세 가지 주요 보안 계층이 있습니다:

- [네트워크](#network)
- [도메인 액세스 정책](#domain-access-policy)
- [세분화된 액세스 제어](#fine-grained-access-control)

##### 네트워크 {#network}

이 보안 계층을 사용하면 도메인을 생성할 때 **Public access**를 선택하여 모든 클라이언트의 요청이 도메인 엔드포인트에 도달할 수 있습니다. **VPC access**를 선택하면 클라이언트가 VPC에 연결해야 요청이 엔드포인트에 도달할 수 있습니다.

자세한 내용은 [AWS 설명서](https://docs.aws.amazon.com/opensearch-service/latest/developerguide/fgac.html#fgac-access-policies)를 참조하세요.

##### 도메인 액세스 정책 {#domain-access-policy}

GitLab은 AWS OpenSearch의 다음 도메인 액세스 제어 방법을 지원합니다:

- [**Resource-based (domain) access policy**](https://docs.aws.amazon.com/opensearch-service/latest/developerguide/ac.html#ac-types-resource): AWS OpenSearch 도메인이 IAM 정책으로 구성되는 경우
- [**Identity-based policy**](https://docs.aws.amazon.com/opensearch-service/latest/developerguide/ac.html#ac-types-identity): 클라이언트가 IAM 주체와 액세스를 구성하는 정책을 사용하는 경우

###### 리소스 기반 정책 예제 {#resource-based-policy-examples}

`es:ESHttp*` 작업이 허용되는 리소스 기반(도메인) 액세스 정책의 예는 다음과 같습니다:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": "*",
      "Action": [
        "es:ESHttp*"
      ],
      "Resource": "arn:aws:es:us-west-1:987654321098:domain/test-domain/*"
    }
  ]
}
```

`es:ESHttp*` 작업이 특정 IAM 주체에만 허용되는 리소스 기반(도메인) 액세스 정책의 예는 다음과 같습니다:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": [
          "arn:aws:iam::123456789012:user/test-user"
        ]
      },
      "Action": [
        "es:ESHttp*"
      ],
      "Resource": "arn:aws:es:us-west-1:987654321098:domain/test-domain/*"
    }
  ]
}
```

> [!note]
> `aws_role_arn`은 [AWS `AssumeRole`](https://docs.aws.amazon.com/STS/latest/APIReference/API_AssumeRole.html)를 계정 전체에서 사용할 때 제공해야 합니다. ARN은 OpenSearch에 액세스할 수 있는 권한을 가진 역할이어야 합니다.

###### ID 기반 정책 예제 {#identity-based-policy-examples}

IAM 주체에 첨부된 ID 기반 액세스 정책의 예는 `es:ESHttp*` 작업이 허용되는 경우입니다:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "es:ESHttp*",
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
```

##### 세분화된 액세스 제어 {#fine-grained-access-control}

세분화된 액세스 제어를 활성화하면 다음 방법 중 하나로 [마스터 사용자](https://docs.aws.amazon.com/opensearch-service/latest/developerguide/fgac.html#fgac-master-user)를 설정해야 합니다:

- [마스터 사용자로 IAM ARN 설정](#set-an-iam-arn-as-a-master-user)
- [마스터 사용자 생성](#create-a-master-user)

###### 마스터 사용자로 IAM ARN 설정 {#set-an-iam-arn-as-a-master-user}

IAM 주체를 마스터 사용자로 사용하면 클러스터에 대한 모든 요청은 AWS Signature Version 4로 서명해야 합니다. EC2 인스턴스에 할당한 IAM 역할인 IAM ARN을 지정할 수도 있습니다. 자세한 내용은 [AWS 설명서](https://docs.aws.amazon.com/opensearch-service/latest/developerguide/fgac.html#fgac-master-user)를 참조하세요.

전제 조건:

- 관리자 액세스 권한이 있어야 합니다.

마스터 사용자로 IAM ARN을 설정하려면 GitLab 인스턴스에서 IAM 자격 증명으로 AWS OpenSearch Service를 사용해야 합니다:

1. 오른쪽 위 모서리에서 **운영자**를 선택합니다.
1. 왼쪽 사이드바에서 **설정** > **검색**을 선택하세요.
1. **고급 검색**을 확장하세요.
1. **AWS OpenSearch IAM 자격 증명** 섹션에서:
   1. **IAM 자격 증명으로 AWS OpenSearch Service 사용** 확인란을 선택합니다.
   1. **AWS 영역**에 OpenSearch 도메인이 위치한 AWS 영역을 입력합니다(예: `us-east-1`).
   1. **AWS access key** 및 **AWS secret access key**에 인증용 액세스 키를 입력합니다.

      > [!note]
      > EC2 인스턴스에서 직접 실행되는 GitLab 배포(컨테이너가 아님)는 액세스 키를 입력할 필요가 없습니다. GitLab 인스턴스는 [AWS Instance Metadata Service (IMDS)](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/configuring-instance-metadata-service.html)에서 이러한 키를 자동으로 가져옵니다.

1. **변경 사항 저장**을 선택합니다.

###### 마스터 사용자 생성 {#create-a-master-user}

내부 사용자 데이터베이스에서 마스터 사용자를 생성하면 HTTP 기본 인증을 사용하여 클러스터에 요청할 수 있습니다. 자세한 내용은 [AWS 설명서](https://docs.aws.amazon.com/opensearch-service/latest/developerguide/fgac.html#fgac-master-user)를 참조하세요.

전제 조건:

- 관리자 액세스 권한이 있어야 합니다.

마스터 사용자를 생성하려면 GitLab 인스턴스에서 OpenSearch 도메인 URL과 마스터 사용자 이름 및 비밀번호를 구성해야 합니다:

1. 오른쪽 위 모서리에서 **운영자**를 선택합니다.
1. 왼쪽 사이드바에서 **설정** > **검색**을 선택하세요.
1. **고급 검색**을 확장하세요.
1. **OpenSearch domain URL**에 OpenSearch 도메인 엔드포인트의 URL을 입력합니다.
1. **사용자명**에 마스터 사용자 이름을 입력합니다.
1. **비밀번호**에 마스터 비밀번호를 입력합니다.
1. **변경 사항 저장**을 선택합니다.

### 새 Elasticsearch 버전으로 업그레이드 {#upgrade-to-a-new-elasticsearch-version}

{{< history >}}

- Elasticsearch 6.8에 대한 지원이 GitLab 15.0에서 [제거되었습니다](https://gitlab.com/gitlab-org/gitlab/-/issues/350275).

{{< /history >}}

전제 조건:

- [고급 검색으로 검색 비활성화](#disable-search-with-advanced-search)하여 검색이 `HTTP 500` 오류로 실패하지 않도록 합니다.
- [인덱싱 일시정지](#pause-indexing)하여 변경사항이 계속 추적되도록 합니다.

Elasticsearch를 새로운 부 또는 주 버전으로 업그레이드할 때 GitLab 구성을 변경할 필요가 없습니다. Elasticsearch 클러스터가 완전히 업그레이드되고 활성 상태인 경우:

1. 클러스터 연결성, 인덱스 및 검색 작업의 유효성을 검사합니다:

   ```shell
   sudo gitlab-rake gitlab:elastic:index_and_search_validation
   ```

1. [인덱싱 재개](#resume-indexing)
1. 선택 사항. [인덱싱 상태 확인](#check-indexing-status)하세요. 올바른 검색 결과를 위해 특히 Elasticsearch 인스턴스가 한동안 오프라인 상태였던 경우 인덱싱이 완료되었는지 확인하세요.
1. [고급 검색으로 검색 활성화](#enable-search-with-advanced-search)

## Elasticsearch 리포지토리 인덱서 {#elasticsearch-repository-indexer}

Git 리포지토리 데이터를 인덱싱하기 위해 GitLab은 [`gitlab-elasticsearch-indexer`](https://gitlab.com/gitlab-org/gitlab-elasticsearch-indexer)를 사용합니다. 자체 컴파일된 설치의 경우 [인덱서 설치](#install-the-indexer)를 참조하세요.

### 인덱서 설치 {#install-the-indexer}

먼저 일부 종속 항목을 설치한 다음 인덱서 자체를 빌드하고 설치합니다.

#### 종속 항목 설치 {#install-dependencies}

이 프로젝트는 텍스트 인코딩을 위해 [International Components for Unicode](https://icu.unicode.org/) (ICU)에 의존하므로 `make`를 실행하기 전에 플랫폼의 개발 패키지가 설치되어 있는지 확인하세요.

##### Debian / Ubuntu {#debian--ubuntu}

Debian 또는 Ubuntu에 설치하려면 다음을 실행합니다:

```shell
sudo apt install libicu-dev
```

##### CentOS / RHEL {#centos--rhel}

CentOS 또는 RHEL에 설치하려면 다음을 실행합니다:

```shell
sudo yum install libicu-devel
```

##### macOS {#macos}

> [!note]
> 먼저 [Homebrew 설치](https://brew.sh/)해야 합니다.

macOS에 설치하려면 다음을 실행합니다:

```shell
brew install icu4c
export PKG_CONFIG_PATH="/usr/local/opt/icu4c/lib/pkgconfig:$PKG_CONFIG_PATH"
```

#### 빌드 및 설치 {#build-and-install}

인덱서를 빌드하고 설치하려면 다음을 실행합니다:

```shell
indexer_path=/home/git/gitlab-elasticsearch-indexer

# Run the installation task for gitlab-elasticsearch-indexer:
sudo -u git -H bundle exec rake gitlab:indexer:install[$indexer_path] RAILS_ENV=production
cd $indexer_path && sudo make install
```

`gitlab-elasticsearch-indexer`은 `/usr/local/bin`에 설치됩니다.

`PREFIX` 환경 변수를 사용하여 설치 경로를 변경할 수 있습니다. `-E` 플래그를 `sudo`에 전달해야 합니다.

예:

```shell
PREFIX=/usr sudo -E make install
```

설치 후 [Elasticsearch 활성화](#enable-advanced-search)를 확인하세요.

> [!note]
> 인덱싱 중에 `Permission denied - /home/git/gitlab-elasticsearch-indexer/`와 같은 오류가 표시되면 `production -> elasticsearch -> indexer_path` 설정을 `gitlab.yml` 파일에서 `/usr/local/bin/gitlab-elasticsearch-indexer`(바이너리가 설치된 위치)로 설정해야 할 수 있습니다.

### 인덱싱 오류 보기 {#view-indexing-errors}

[GitLab Elasticsearch 인덱서](https://gitlab.com/gitlab-org/gitlab-elasticsearch-indexer)의 오류는 [`elasticsearch.log`](../../administration/logs/_index.md#elasticsearchlog) 파일 및 [`sidekiq.log`](../../administration/logs/_index.md#sidekiqlog) 파일에 `json.exception.class`이(가) `Gitlab::Elastic::Indexer::Error`인 상태로 보고됩니다. 이러한 오류는 Git 리포지토리 데이터를 인덱싱할 때 발생할 수 있습니다.

## 고급 검색 활성화 {#enable-advanced-search}

전제 조건:

- 인스턴스에 대한 관리자 액세스 권한이 있어야 합니다.
- [인덱스당 샤드 수](#number-of-elasticsearch-shards)를 구성합니다.
- [인덱스당 복제본 수](#number-of-elasticsearch-replicas)를 구성합니다.
- 선택 사항. [대규모 인스턴스 인덱싱](#index-large-instances-efficiently)을 준비합니다.

고급 검색을 활성화하려면:

1. 오른쪽 위 모서리에서 **운영자**를 선택합니다.
1. 왼쪽 사이드바에서 **설정** > **검색**을 선택하세요.
1. Elasticsearch 클러스터에 대해 [고급 검색 설정](#advanced-search-configuration)을 구성합니다. **고급 검색으로 검색** 확인란을 아직 선택하지 마세요.
1. [인스턴스 인덱싱](#index-the-instance)
1. 선택 사항. [인덱싱 상태 확인](#check-indexing-status)하세요.
1. 인덱싱이 완료되면 **고급 검색으로 검색** 확인란을 선택한 다음 **변경사항 저장**을 선택합니다.

> [!note]
> Elasticsearch 클러스터가 다운된 상태에서 Elasticsearch가 활성화되면 인스턴스가 변경 사항을 인덱싱하는 작업을 큐에 넣지만 유효한 Elasticsearch 클러스터를 찾을 수 없기 때문에 이슈와 같은 문서를 업데이트하는 데 이슈가 발생할 수 있습니다.

리포지토리 데이터가 50GB 이상인 GitLab 인스턴스의 경우 [대규모 인스턴스 효율적으로 인덱싱](#index-large-instances-efficiently)을 참조하세요.

### 인스턴스 인덱싱 {#index-the-instance}

#### 사용자 인터페이스에서 {#from-the-user-interface}

{{< history >}}

- GitLab 17.3에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/271532)되었습니다.

{{< /history >}}

전제 조건:

- 인스턴스에 대한 관리자 액세스 권한이 있어야 합니다.

사용자 인터페이스에서 초기 인덱싱을 수행하거나 인덱스를 다시 생성할 수 있습니다.

사용자 인터페이스에서 고급 검색을 활성화하고 인스턴스를 인덱싱하려면:

1. 오른쪽 위 모서리에서 **운영자**를 선택합니다.
1. 왼쪽 사이드바에서 **설정** > **검색**을 선택하세요.
1. **고급 검색을 위한 인덱싱 켜기** 확인란을 선택한 다음 **변경사항 저장**을 선택합니다.
1. **인스턴스 인덱싱**을 선택합니다.

#### Rake 작업으로 {#with-a-rake-task}

전제 조건:

- 인스턴스에 대한 관리자 액세스 권한이 있어야 합니다.

전체 인스턴스를 인덱싱하려면 다음 Rake 작업을 사용합니다:

```shell
# WARNING: This task deletes all existing indices
# For installations that use the Linux package
sudo gitlab-rake gitlab:elastic:index

# WARNING: This task deletes all existing indices
# For self-compiled installations
bundle exec rake gitlab:elastic:index RAILS_ENV=production
```

특정 데이터를 인덱싱하려면 다음 Rake 작업을 사용합니다:

```shell
# For installations that use the Linux package
sudo gitlab-rake gitlab:elastic:index_work_items
sudo gitlab-rake gitlab:elastic:index_group_wikis
sudo gitlab-rake gitlab:elastic:index_namespaces
sudo gitlab-rake gitlab:elastic:index_projects
sudo gitlab-rake gitlab:elastic:index_snippets
sudo gitlab-rake gitlab:elastic:index_users

# For self-compiled installations
bundle exec rake gitlab:elastic:index_work_items RAILS_ENV=production
bundle exec rake gitlab:elastic:index_group_wikis RAILS_ENV=production
bundle exec rake gitlab:elastic:index_namespaces RAILS_ENV=production
bundle exec rake gitlab:elastic:index_projects RAILS_ENV=production
bundle exec rake gitlab:elastic:index_snippets RAILS_ENV=production
bundle exec rake gitlab:elastic:index_users RAILS_ENV=production
```

### 인덱싱 상태 확인 {#check-indexing-status}

전제 조건:

- 인스턴스에 대한 관리자 액세스 권한이 있어야 합니다.

인덱싱 상태를 확인하려면:

1. 오른쪽 위 모서리에서 **운영자**를 선택합니다.
1. 왼쪽 사이드바에서 **설정** > **검색**을 선택하세요.
1. **고급 검색 인덱싱 상태**를 확장합니다.

#### 백그라운드 작업의 상태 모니터링 {#monitor-the-status-of-background-jobs}

전제 조건:

- 인스턴스에 대한 관리자 액세스 권한이 있어야 합니다.

인덱싱 진행률을 모니터링하려면 백그라운드 작업의 상태를 확인할 수도 있습니다:

1. 오른쪽 위 모서리에서 **운영자**를 선택합니다.
1. 왼쪽 사이드바에서 **모니터링** > **백그라운드 작업**을 선택합니다.
1. Sidekiq 대시보드에서 **바쁨**을 선택하고 다음 인덱싱 작업을 감시합니다:
   - `Search::Elastic::CommitIndexerWorker` 코드 및 커밋의 경우.
   - `ElasticWikiIndexerWorker` wiki 데이터의 경우.

### 고급 검색으로 검색 활성화 {#enable-search-with-advanced-search}

전제 조건:

- 인스턴스에 대한 관리자 액세스 권한이 있어야 합니다.

GitLab에서 고급 검색으로 검색을 활성화하려면:

1. 오른쪽 위 모서리에서 **운영자**를 선택합니다.
1. 왼쪽 사이드바에서 **설정** > **검색**을 선택하세요.
1. **고급 검색으로 검색** 확인란을 선택합니다.
1. **변경 사항 저장**을 선택합니다.

### 고급 검색으로 코드 검색 활성화 {#enable-code-search-with-advanced-search}

전제 조건:

- 인스턴스에 대한 관리자 액세스 권한이 있어야 합니다.

GitLab에서 고급 검색으로 코드 검색을 활성화하려면:

1. 오른쪽 위 모서리에서 **운영자**를 선택합니다.
1. 왼쪽 사이드바에서 **설정** > **검색**을 선택하세요.
1. **고급 검색으로 코드 검색** 확인란을 선택합니다.
1. **변경 사항 저장**을 선택합니다.

### 고급 검색 구성 {#advanced-search-configuration}

다음 Elasticsearch 설정을 사용할 수 있습니다:

| 매개변수                                                   | 설명 |
|-------------------------------------------------------------|-------------|
| **고급 검색을 위한 인덱싱 켜기**                    | 인덱싱을 켜거나 끕니다. 인덱스가 아직 없으면 빈 인덱스를 생성합니다. 예를 들어 인덱싱을 켜되 검색을 꺼서 인덱스가 완전히 완료될 때까지 시간을 줄 수 있습니다. 또한 이 옵션이 기존 데이터에 영향을 미치지 않음을 기억하세요. 이것은 데이터 변경을 추적하고 새 데이터가 인덱싱되도록 하는 백그라운드 인덱서만 활성화/비활성화합니다. |
| **고급 검색을 위한 인덱싱 일시정지**                      | 고급 검색 인덱싱을 일시 정지합니다. 이는 클러스터 마이그레이션/재인덱싱에 유용합니다. 모든 변경사항은 계속 추적되지만 재개될 때까지 인덱스에 커밋되지 않습니다. |
| **고급 검색으로 검색**                             | 검색 및 [고급 취약성 관리](../../user/application_security/vulnerability_report/_index.md#advanced-vulnerability-management)에서 고급 검색 기능을 켜거나 끕니다. |
| **고급 검색으로 코드 검색**                        | 고급 검색으로 코드 검색을 켜거나 끕니다. 이 설정을 끄면 Elasticsearch 인스턴스에서 모든 코드가 삭제됩니다. 이 설정을 다시 켜려면 코드를 완전히 다시 인덱싱합니다. 정확한 코드 검색이 활성화된 경우 리소스를 절약하기 위해 이 설정을 꺼야 합니다. |
| **인덱싱 처리기 대기열 재조정**                                | 인덱싱 처리기의 자동 재큐잉을 켭니다. 이는 모든 문서가 처리될 때까지 Sidekiq 작업을 큐에 추가하여 비코드 인덱싱 처리량을 개선합니다. 인덱싱 처리기 재큐잉은 더 작은 인스턴스나 Sidekiq 프로세스가 적은 인스턴스에는 권장되지 않습니다. |
| **URL**                                                     | Elasticsearch 인스턴스의 URL입니다. 클러스터링을 지원하려면 쉼표로 구분된 목록을 사용합니다(예: `http://host1, https://host2:9200`). Elasticsearch 인스턴스가 비밀번호로 보호되는 경우 `Username` 및 `Password` 필드를 사용합니다. 또는 `http://<username>:<password>@<elastic_host>:9200/`와 같은 인라인 자격 증명을 사용합니다. [OpenSearch](https://docs.aws.amazon.com/opensearch-service/latest/developerguide/vpc.html)를 사용하는 경우 포트 `80` 및 `443`에서의 연결만 허용됩니다. |
| **사용자명**                                                | Elasticsearch 인스턴스의 `username`입니다. |
| **비밀번호**                                                | Elasticsearch 인스턴스의 비밀번호입니다. |
| **Number of Elasticsearch shards and replicas per index**   | 성능상의 이유로 Elasticsearch 인덱스가 여러 샤드로 분할됩니다. 일반적으로 최소 5개의 샤드를 사용해야 합니다. 수백만 개의 문서가 있는 인덱스는 더 많은 샤드가 필요합니다([지침 참조](#guidance-on-choosing-optimal-cluster-configuration)). 이 값을 변경하면 인덱스를 다시 생성할 때까지 적용되지 않습니다. 확장성 및 복원력에 대한 자세한 내용은 [Elasticsearch 설명서](https://www.elastic.co/guide/en/elasticsearch/reference/current/scalability.html)를 참조하세요. 각 Elasticsearch 샤드는 여러 개의 복제본을 가질 수 있습니다. 이러한 복제본은 샤드의 완전한 사본이며 쿼리 성능 향상 또는 하드웨어 장애에 대한 복원력을 제공할 수 있습니다. 이 값을 증가시키면 인덱스에 필요한 총 디스크 공간이 증가합니다. 각 인덱스에 대해 샤드 및 복제본의 수를 설정할 수 있습니다. |
| **인덱싱할 네임스페이스와 프로젝트 데이터의 양을 제한합니다.** | 이 설정을 활성화하면 인덱싱할 네임스페이스 및 프로젝트를 지정할 수 있습니다. 다른 모든 네임스페이스 및 프로젝트는 대신 데이터베이스 검색을 사용합니다. 이 설정을 활성화했지만 네임스페이스 또는 프로젝트를 지정하지 않은 경우 프로젝트 레코드만 인덱싱됩니다. 자세한 내용은 [인덱싱할 네임스페이스와 프로젝트 데이터의 양을 제한합니다.](#limit-the-amount-of-namespace-and-project-data-to-index)를 참조하세요. |
| **IAM 자격 증명으로 AWS OpenSearch Service 사용**         | [AWS IAM 권한 부여](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_access-keys.html), [AWS EC2 Instance Profile 자격 증명](https://docs.aws.amazon.com/codedeploy/latest/userguide/getting-started-create-iam-instance-profile.html#getting-started-create-iam-instance-profile-cli) 또는 [AWS ECS Tasks 자격 증명](https://docs.aws.amazon.com/AmazonECS/latest/userguide/task-iam-roles.html)을 사용하여 OpenSearch 요청에 서명합니다. AWS 호스팅 OpenSearch 도메인 액세스 정책 구성의 세부 정보는 [Amazon OpenSearch Service의 ID 및 액세스 관리](https://docs.aws.amazon.com/opensearch-service/latest/developerguide/ac.html)를 참조하세요. |
| **AWS Region**                                              | OpenSearch Service가 위치한 AWS 영역입니다. |
| **AWS 엑세스 키**                                          | AWS 액세스 키입니다. |
| **AWS 비밀 액세스 키**                                   | AWS 비밀 액세스 키입니다. |
| **Maximum file size indexed**                               | [인스턴스 제한의 설명 참조](../../administration/instance_limits.md#maximum-file-size-indexed). |
| **최대 필드 길이**                                    | [인스턴스 제한의 설명 참조](../../administration/instance_limits.md#maximum-field-length). |
| **인덱싱 타임아웃 (분)**                              | 프로젝트당 분 단위의 인덱싱 타임아웃입니다. |
| **비코드 인덱싱을 위한 샤드 수**                  | 인덱싱 처리기 샤드의 수입니다. 이는 더 많은 병렬 Sidekiq 작업을 큐에 추가하여 비코드 인덱싱 처리량을 개선합니다. 샤드 수를 증가시키는 것은 더 작은 인스턴스나 Sidekiq 프로세스가 적은 인스턴스에는 권장되지 않습니다. 기본값은 `2`입니다. |
| **최대 대량 요청 크기(MiB)**                         | GitLab Ruby 및 Go 기반 인덱서 프로세스에서 사용됩니다. 이 설정은 Elasticsearch Bulk API에 페이로드를 제출하기 전에 주어진 인덱싱 프로세스에서 수집하고 저장해야 할 데이터의 양(메모리)을 나타냅니다. GitLab Go 기반 인덱서의 경우 **대량 요청 동시처리**와 함께 이 설정을 사용해야 합니다. **최대 대량 요청 크기(MiB)**는 `gitlab-rake` 명령 또는 Sidekiq 작업에서 GitLab Go 기반 인덱서를 실행하는 호스트와 Elasticsearch 호스트의 리소스 제약을 모두 수용해야 합니다. |
| **대량 요청 동시처리**                                | 대량 요청 동시처리는 GitLab Go 기반 인덱서 프로세스(또는 스레드)가 Elasticsearch Bulk API에 제출할 데이터를 수집하기 위해 병렬로 실행할 수 있는 수를 나타냅니다. 이는 인덱싱 성능을 향상시키지만 Elasticsearch 대량 요청 큐를 더 빨리 채웁니다. 이 설정은 **최대 대량 요청 크기(MiB)** 설정과 함께 사용해야 하며 `gitlab-rake` 명령 또는 Sidekiq 작업에서 GitLab Go 기반 인덱서를 실행하는 호스트와 Elasticsearch 호스트의 리소스 제약을 모두 수용해야 합니다. |
| **클라이언트 요청 시간 초과**                                  | Elasticsearch HTTP 클라이언트 요청 타임아웃 값(초)입니다. `0`의 값은 기본 타임아웃인 30초를 사용합니다. 이 제한을 초과하는 검색 요청은 애플리케이션 서버가 요청을 종료한 후 `500`로 실패하는 대신 `HTTP 408`을 반환합니다. Elasticsearch 쿼리가 정기적으로 30초 이상 걸리는 경우 더 높은 값을 설정합니다. 애플리케이션 서버는 60초 후 요청을 종료하므로 `60`보다 높은 값을 설정하지 마세요. 더 긴 타임아웃을 원하면 `30`과(와) `55` 사이의 값을 설정해야 합니다. |
| **코드 인덱싱 동시성**                               | 동시에 실행할 수 있는 최대 Elasticsearch 코드 인덱싱 백그라운드 작업 수입니다. 이는 리포지토리 인덱싱 작업에만 적용됩니다. |
| **실패 시 재시도**                                        | Elasticsearch 검색 요청의 최대 재시도 횟수입니다. GitLab 17.6에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/486935)되었습니다. |
| **Index prefix**                                            | Elasticsearch 인덱스 이름의 사용자 정의 접두사입니다. `gitlab`로 기본값이 지정됩니다. 변경하면 모든 인덱스가 `gitlab` 대신 이 접두사를 사용합니다(예: `custom-production-issues` 대신 `gitlab-production-issues`). 1~100자여야 하며 소문자 영숫자, 하이픈 및 언더스코어만 포함할 수 있으며 하이픈 또는 언더스코어로 시작하거나 끝날 수 없습니다. GitLab 18.2에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/3421)되었습니다. |

> [!warning]
> **최대 대량 요청 크기(MiB)** 및 **대량 요청 동시처리**의 값을 증가시키면 Sidekiq 성능에 부정적인 영향을 미칠 수 있습니다. Sidekiq 로그에서 `scheduling_latency_s` 기간이 증가하면 기본값으로 복원합니다. 자세한 내용은 [이슈 322147](https://gitlab.com/gitlab-org/gitlab/-/issues/322147)을 참조하세요.

### 인덱싱할 네임스페이스와 프로젝트 데이터의 양을 제한합니다 {#limit-the-amount-of-namespace-and-project-data-to-index}

{{< history >}}

- 모든 프로젝트 레코드 인덱싱이 GitLab 16.7에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/428070)되었으며 [기능 플래그](../../administration/feature_flags/_index.md)가 `search_index_all_projects`로 지정되었습니다. 기본적으로 비활성화되었습니다.
- GitLab 16.11에서 [일반적으로 제공](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/148111)됩니다. `search_index_all_projects` 기능 플래그가 제거되었습니다.
- 취약성 레코드 인덱싱이 GitLab 18.1에서 GitLab.com 및 GitLab Dedicated에 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/536299)되었으며 [기능 플래그](../../administration/feature_flags/_index.md)가 `vulnerability_es_ingestion`로 지정되었습니다. 기본적으로 비활성화되었습니다.
- 취약성 레코드 인덱싱이 GitLab 18.2에서 GitLab.com 및 GitLab Dedicated에서 [일반적으로 제공](https://gitlab.com/gitlab-org/gitlab/-/issues/536299)됩니다. `vulnerability_es_ingestion` 기능 플래그가 제거되었습니다.

{{< /history >}}

> [!flag]
> 이 기능의 사용 가능 여부는 기능 플래그에 의해 제어됩니다. 자세한 내용은 이력을 참조하세요.

**인덱싱할 네임스페이스와 프로젝트 데이터의 양을 제한합니다.** 확인란을 선택하면 인덱싱할 네임스페이스 및 프로젝트를 지정할 수 있습니다. 네임스페이스가 그룹인 경우 이러한 서브그룹의 모든 서브그룹 및 프로젝트도 인덱싱됩니다.

이 설정을 활성화하면:

- 전체 인덱싱을 위해 네임스페이스 또는 프로젝트를 지정해야 합니다.
- 프로젝트 레코드(프로젝트 이름 및 설명과 같은 메타데이터)는 모든 프로젝트에 대해 항상 인덱싱됩니다.
- 취약성 레코드는 보안 보고서에서 필터링을 지원하도록 모든 프로젝트 및 네임스페이스에 대해 항상 인덱싱됩니다.
- [관련 데이터](#advanced-search-index-scopes)는 지정한 네임스페이스 및 프로젝트에 대해서만 인덱싱됩니다.

> [!warning]
> 이 설정을 활성화한 후 네임스페이스 또는 프로젝트를 지정하지 않으면 프로젝트 레코드만 인덱싱되고 관련 데이터는 검색할 수 없습니다.

#### 인덱싱된 네임스페이스 {#indexed-namespaces}

{{< history >}}

- 제한된 인덱싱을 위한 전역 검색이 GitLab 13.4에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/41041)되었으며 [기능 플래그](../../administration/feature_flags/_index.md)가 `advanced_global_search_for_limited_indexing`로 지정되었습니다. 기본적으로 비활성화되었습니다.
- GitLab 14.2에서 [GitLab.com에서 활성화됨](https://gitlab.com/gitlab-org/gitlab/-/issues/244276).
- 제한된 인덱싱을 위한 전역 검색이 GitLab 17.11에서 `advanced_global_search_for_limited_indexing` 플래그 대신 UI 옵션으로 [일반적으로 제공](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/186727)됩니다.

{{< /history >}}

모든 네임스페이스를 인덱싱하면 전역 코드 및 커밋 검색을 위해 고급 검색을 사용할 수 있습니다. 일부 네임스페이스만 인덱싱하는 경우:

- 전역 검색에는 코드 또는 커밋 검색 범위가 포함되지 않습니다.
- 코드 및 커밋 검색은 단일 인덱싱된 네임스페이스에서만 사용할 수 있습니다.
- 단일 코드 또는 커밋 검색은 여러 인덱싱된 네임스페이스에서 불가능합니다.
- 교차 프로젝트 검색은 인덱싱된 네임스페이스에서 사용할 수 있습니다.

예를 들어 두 개의 별도 그룹을 인덱싱하는 경우 각 그룹에서 개별적으로 별도의 코드 검색을 실행해야 합니다.

제한된 인덱싱을 위해 전역 검색을 활성화하려면:

1. 오른쪽 위 모서리에서 **운영자**를 선택합니다.
1. 왼쪽 사이드바에서 **설정** > **검색**을 선택하세요.
1. **고급 검색**을 확장합니다.
1. **Enable global search for limited indexing**를 선택합니다.
1. **변경 사항 저장**을 선택합니다.
1. 인스턴스를 이미 인덱싱했으면 [인스턴스 재인덱싱](#index-the-instance)해야 합니다. 필터링이 올바르게 작동하도록 기존 검색 데이터가 삭제됩니다.

## 사용자 정의 언어 분석기 활성화 {#enable-custom-language-analyzers}

전제 조건:

- 인스턴스에 대한 관리자 액세스 권한이 있어야 합니다.

[`smartcn`](https://www.elastic.co/guide/en/elasticsearch/plugins/current/analysis-smartcn.html) 및 [`kuromoji`](https://www.elastic.co/guide/en/elasticsearch/plugins/current/analysis-kuromoji.html) 분석 플러그인을 Elastic에서 사용하여 중국어 및 일본어 언어 지원을 개선할 수 있습니다.

사용자 정의 언어 분석기를 활성화하려면:

1. 원하는 플러그인을 설치하고 [Elasticsearch 설명서](https://www.elastic.co/guide/en/elasticsearch/plugins/7.9/installation.html)를 참조하여 플러그인 설치 지침을 확인합니다. 클러스터의 모든 노드에 플러그인을 설치해야 하며 설치 후 각 노드를 다시 시작해야 합니다. 플러그인 목록은 이 섹션의 뒷부분 표를 참조하세요.
1. 오른쪽 위 모서리에서 **운영자**를 선택합니다.
1. 왼쪽 사이드바에서 **설정** > **검색**을 선택하세요.
1. **커스텀 분석기: 언어 지원**을 찾으세요.
1. **Indexing**에 대해 플러그인 지원을 활성화합니다.
1. **변경사항 저장**을 선택하여 변경 사항을 적용합니다.
1. [무중단 재인덱싱](#zero-downtime-reindexing)을 트리거하거나 처음부터 다시 인덱싱하여 업데이트된 매핑으로 새 인덱스를 생성합니다.
1. 이전 단계가 완료된 후 **검색 중**에 대해 플러그인 지원을 활성화합니다.

설치할 항목에 대한 지침은 다음 Elasticsearch 언어 플러그인 옵션을 참조하세요:

| 매개변수                                             | 설명 |
|-------------------------------------------------------|-------------|
| `Enable Chinese (smartcn) custom analyzer: Indexing`   | [`smartcn`](https://www.elastic.co/guide/en/elasticsearch/plugins/current/analysis-smartcn.html) 사용자 정의 분석기를 사용한 중국어 언어 지원을 활성화하거나 비활성화합니다.|
| `Enable Chinese (smartcn) custom analyzer: Search`   | 고급 검색을 위해 [`smartcn`](https://www.elastic.co/guide/en/elasticsearch/plugins/current/analysis-smartcn.html) 필드 사용을 활성화하거나 비활성화합니다. [플러그인 설치](https://www.elastic.co/guide/en/elasticsearch/plugins/current/analysis-smartcn.html) 후, 사용자 정의 분석기 인덱싱을 활성화하고 인덱스를 다시 생성한 후에만 이를 활성화합니다.|
| `Enable Japanese (kuromoji) custom analyzer: Indexing`   | [`kuromoji`](https://www.elastic.co/guide/en/elasticsearch/plugins/current/analysis-kuromoji.html) 사용자 정의 분석기를 사용한 일본어 언어 지원을 활성화하거나 비활성화합니다.|
| `Enable Japanese (kuromoji) custom analyzer: Search`  | 고급 검색을 위해 [`kuromoji`](https://www.elastic.co/guide/en/elasticsearch/plugins/current/analysis-kuromoji.html) 필드 사용을 활성화하거나 비활성화합니다. [플러그인 설치](https://www.elastic.co/guide/en/elasticsearch/plugins/current/analysis-kuromoji.html) 후, 사용자 정의 분석기 인덱싱을 활성화하고 인덱스를 다시 생성한 후에만 이를 활성화합니다.|

## 고급 검색 비활성화 {#disable-advanced-search}

전제 조건:

- 인스턴스에 대한 관리자 액세스 권한이 있어야 합니다.

GitLab에서 고급 검색을 비활성화하려면:

1. 오른쪽 위 모서리에서 **운영자**를 선택합니다.
1. 왼쪽 사이드바에서 **설정** > **검색**을 선택하세요.
1. **고급 검색을 위한 인덱싱 켜기** 및 **고급 검색으로 검색** 확인란을 선택 해제합니다.
1. **변경 사항 저장**을 선택합니다.
1. 선택 사항. 여전히 온라인 상태인 Elasticsearch 인스턴스의 경우 기존 인덱스를 삭제합니다:

   ```shell
   # For installations that use the Linux package
   sudo gitlab-rake gitlab:elastic:delete_index

   # For self-compiled installations
   bundle exec rake gitlab:elastic:delete_index RAILS_ENV=production
   ```

### 고급 검색으로 검색 비활성화 {#disable-search-with-advanced-search}

전제 조건:

- 인스턴스에 대한 관리자 액세스 권한이 있어야 합니다.

GitLab에서 고급 검색으로 검색을 비활성화하려면:

1. 오른쪽 위 모서리에서 **운영자**를 선택합니다.
1. 왼쪽 사이드바에서 **설정** > **검색**을 선택하세요.
1. **고급 검색으로 검색** 확인란을 선택 해제합니다.
1. **변경 사항 저장**을 선택합니다.

### 고급 검색으로 코드 검색 비활성화 {#disable-code-search-with-advanced-search}

전제 조건:

- 인스턴스에 대한 관리자 액세스 권한이 있어야 합니다.

GitLab에서 고급 검색으로 코드 검색을 비활성화하려면:

1. 오른쪽 위 모서리에서 **운영자**를 선택합니다.
1. 왼쪽 사이드바에서 **설정** > **검색**을 선택하세요.
1. **고급 검색으로 코드 검색** 확인란을 선택 해제합니다.
1. **변경 사항 저장**을 선택합니다.

## 인덱싱 일시정지 {#pause-indexing}

전제 조건:

- 인스턴스에 대한 관리자 액세스 권한이 있어야 합니다.

인덱싱을 일시정지하려면:

1. 오른쪽 위 모서리에서 **운영자**를 선택합니다.
1. 왼쪽 사이드바에서 **설정** > **검색**을 선택하세요.
1. **고급 검색**을 확장하세요.
1. **고급 검색을 위한 인덱싱 일시정지** 확인란을 선택합니다.
1. **변경 사항 저장**을 선택합니다.

## 인덱싱 재개 {#resume-indexing}

전제 조건:

- 인스턴스에 대한 관리자 액세스 권한이 있어야 합니다.

인덱싱을 재개하려면:

1. 오른쪽 위 모서리에서 **운영자**를 선택합니다.
1. 왼쪽 사이드바에서 **설정** > **검색**을 선택하세요.
1. **고급 검색**을 확장하세요.
1. **고급 검색을 위한 인덱싱 일시정지** 확인란을 선택 해제합니다.
1. **변경 사항 저장**을 선택합니다.

## 무중단 재인덱싱 {#zero-downtime-reindexing}

이 재인덱싱 방법의 아이디어는 [Elasticsearch 재인덱싱 API](https://www.elastic.co/guide/en/elasticsearch/reference/current/docs-reindex.html)와 Elasticsearch 인덱스 별칭 기능을 사용하여 작업을 수행하는 것입니다. 인덱스 별칭이 GitLab이 읽기 및 쓰기에 사용하는 `primary` 인덱스에 연결됩니다. 재인덱싱 프로세스가 시작되면 `primary` 인덱스로의 쓰기가 임시로 일시 정지됩니다. 그런 다음 다른 인덱스를 생성하고 재인덱싱 API를 호출하여 인덱스 데이터를 새 인덱스로 마이그레이션합니다. 재인덱싱 작업이 완료되면 인덱스 별칭이 새 인덱스로 전환되어 새 `primary` 인덱스가 됩니다. 마지막으로 쓰기가 재개되고 일반적인 작업이 계속됩니다.

### 무중단 재인덱싱 사용 {#using-zero-downtime-reindexing}

무중단 재인덱싱을 사용하여 새 인덱스를 만들고 기존 데이터를 복사하지 않고는 변경할 수 없는 인덱스 설정 또는 매핑을 구성할 수 있습니다. 무중단 재인덱싱을 사용하여 누락된 데이터를 수정하면 안 됩니다. 무중단 재인덱싱은 데이터가 이미 인덱싱되지 않은 경우 검색 클러스터에 데이터를 추가하지 않습니다. 재인덱싱을 시작하기 전에 모든 [고급 검색 마이그레이션](#advanced-search-migrations)을 완료해야 합니다.

### 재인덱싱 트리거 {#trigger-reindexing}

전제 조건:

- 인스턴스에 대한 관리자 액세스 권한이 있어야 합니다.

재인덱싱을 트리거하려면:

1. 관리자로 GitLab 인스턴스에 로그인합니다.
1. 오른쪽 위 모서리에서 **운영자**를 선택합니다.
1. 왼쪽 사이드바에서 **설정** > **검색**을 선택하세요.
1. **고급 검색 무중단 재인덱싱**을 확장합니다.
1. **클러스터 재인덱싱 트리거**를 선택합니다.

재인덱싱은 Elasticsearch 클러스터의 크기에 따라 길어질 수 있는 프로세스입니다.

이 프로세스가 완료되면 원본 인덱스는 14일 후 삭제되도록 예약됩니다. 재인덱싱 프로세스를 트리거한 동일한 페이지에서 **취소** 버튼을 누르면 이 작업을 취소할 수 있습니다.

재인덱싱이 실행 중인 동안 동일한 섹션에서 진행률을 추적할 수 있습니다.

#### 무중단 재인덱싱 트리거 {#trigger-zero-downtime-reindexing}

전제 조건:

- 인스턴스에 대한 관리자 액세스 권한이 있어야 합니다.

무중단 재인덱싱을 트리거하려면:

1. 오른쪽 위 모서리에서 **운영자**를 선택합니다.
1. 왼쪽 사이드바에서 **설정** > **검색**을 선택하세요.
1. **고급 검색 무중단 재인덱싱**을 확장합니다. 다음 설정을 사용할 수 있습니다:

   - [슬라이스 승수](#slice-multiplier)
   - [최대 실행 슬라이스](#maximum-running-slices)

##### 슬라이스 승수 {#slice-multiplier}

슬라이스 승수는 [재인덱싱 중 슬라이스의 수](https://www.elastic.co/guide/en/elasticsearch/reference/current/docs-reindex.html#docs-reindex-slice)를 계산합니다.

GitLab은 [수동 슬라이싱](https://www.elastic.co/guide/en/elasticsearch/reference/current/docs-reindex.html#docs-reindex-manual-slice)을 사용하여 재인덱싱을 효율적이고 안전하게 제어하므로 사용자가 실패한 슬라이스만 재시도할 수 있습니다.

승수는 기본값으로 `2`이며 인덱스당 샤드 수에 적용됩니다. 예를 들어 이 값이 `2`이고 인덱스에 20개의 샤드가 있으면 재인덱싱 작업은 40개의 슬라이스로 분할됩니다.

##### 최대 실행 슬라이스 {#maximum-running-slices}

최대 실행 슬라이스 매개 변수는 기본값이 `60`이며 Elasticsearch 재인덱싱 중에 동시에 실행할 수 있는 최대 슬라이스 수에 해당합니다.

이 값을 너무 높게 설정하면 클러스터가 검색 및 쓰기로 과도하게 포화되어 부정적인 성능 영향을 미칠 수 있습니다. 이 값을 너무 낮게 설정하면 재인덱싱 프로세스를 완료하는 데 매우 오랜 시간이 걸릴 수 있습니다.

최적의 값은 클러스터 크기, 재인덱싱 중 성능 저하를 수용할 의지가 있는지, 재인덱싱이 빠르게 완료되고 인덱싱을 재개하는 것이 얼마나 중요한지에 따라 달라집니다.

### 가장 최근의 재인덱싱 작업을 실패했음으로 표시하고 인덱싱 재개 {#mark-the-most-recent-reindexing-job-as-failed-and-resume-indexing}

전제 조건:

- 인스턴스에 대한 관리자 액세스 권한이 있어야 합니다.

완료되지 않은 재인덱싱 작업을 포기하고 인덱싱을 재개하려면:

1. 가장 최근의 재인덱싱 작업을 실패했음으로 표시합니다:

   ```shell
   # For installations that use the Linux package
   sudo gitlab-rake gitlab:elastic:mark_reindex_failed

   # For self-compiled installations
   bundle exec rake gitlab:elastic:mark_reindex_failed RAILS_ENV=production
   ```

1. 오른쪽 위 모서리에서 **운영자**를 선택합니다.
1. 왼쪽 사이드바에서 **설정** > **검색**을 선택하세요.
1. **고급 검색**을 확장하세요.
1. **고급 검색을 위한 인덱싱 일시정지** 확인란을 선택 해제합니다.

## 인덱스 무결성 {#index-integrity}

{{< history >}}

- GitLab 15.10에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/112369)되었으며 [기능 플래그](../../administration/feature_flags/_index.md)가 `search_index_integrity`로 지정되었습니다. 기본적으로 비활성화되었습니다.
- GitLab 16.4에서 [일반적으로 제공](https://gitlab.com/gitlab-org/gitlab/-/issues/392981)됩니다. `search_index_integrity` 기능 플래그가 제거되었습니다.

{{< /history >}}

인덱스 무결성은 누락된 리포지토리 데이터를 감지하고 수정합니다. 이 기능은 그룹 또는 프로젝트로 범위가 지정된 코드 검색이 결과를 반환하지 않을 때 자동으로 사용됩니다.

## 고급 검색 마이그레이션 {#advanced-search-migrations}

재인덱싱 마이그레이션은 백그라운드에서 실행되므로 인스턴스를 수동으로 재인덱싱할 필요가 없습니다.

[GitLab 18.0 이상](https://gitlab.com/gitlab-org/gitlab/-/issues/352424)에서 `elastic_migration_worker_enabled` 애플리케이션 설정을 사용하여 마이그레이션 처리기를 활성화하거나 비활성화할 수 있습니다. 기본적으로 마이그레이션 처리기가 활성화되어 있습니다.

### 마이그레이션 사전 파일 {#migration-dictionary-files}

{{< history >}}

- GitLab 16.3에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/414674)되었습니다.

{{< /history >}}

모든 마이그레이션에는 `ee/elastic/docs/` 폴더에 다음 정보가 있는 해당 사전 파일이 있습니다:

```yaml
name:
version:
description:
group:
milestone:
introduced_by_url:
obsolete:
marked_obsolete_by_url:
marked_obsolete_in_milestone:
```

이 정보를 사용하여 예를 들어 마이그레이션이 도입되었을 때 또는 더 이상 사용되지 않음으로 표시되었을 때를 식별할 수 있습니다.

### 보류 중인 마이그레이션 확인 {#check-for-pending-migrations}

보류 중인 고급 검색 마이그레이션을 확인하려면 이 명령을 실행하세요:

```shell
curl "$CLUSTER_URL/gitlab-production-migrations/_search?size=100&q=*" | jq .
```

다음과 유사한 것을 반환해야 합니다:

```json
{
  "took": 14,
  "timed_out": false,
  "_shards": {
    "total": 1,
    "successful": 1,
    "skipped": 0,
    "failed": 0
  },
  "hits": {
    "total": {
      "value": 1,
      "relation": "eq"
    },
    "max_score": 1,
    "hits": [
      {
        "_index": "gitlab-production-migrations",
        "_type": "_doc",
        "_id": "20230209195404",
        "_score": 1,
        "_source": {
          "completed": true
        }
      }
    ]
  }
}
```

마이그레이션 이슈를 디버그하려면 [`elasticsearch.log`](../../administration/logs/_index.md#elasticsearchlog) 파일을 확인합니다.

### 중단된 마이그레이션 재시도 {#retry-a-halted-migration}

일부 마이그레이션은 재시도 제한으로 구축되었습니다. 마이그레이션이 재시도 제한 내에 완료될 수 없으면 중단되고 고급 검색 통합 설정에 알림이 표시됩니다.

마이그레이션이 중단된 이유를 디버그하고 재시도하기 전에 변경하려면 [`elasticsearch.log` 파일](../../administration/logs/_index.md#elasticsearchlog)을 확인하는 것이 좋습니다.

오류 원인을 해결했다고 확신하는 경우:

1. 오른쪽 위 모서리에서 **운영자**를 선택합니다.
1. 왼쪽 사이드바에서 **설정** > **검색**을 선택하세요.
1. **고급 검색**을 확장하세요.
1. **Elasticsearch migration halted** 경고 상자 내에서 **마이그레이션 재시도**를 선택합니다. 마이그레이션은 백그라운드에서 재시도되도록 예약됩니다.

마이그레이션을 성공하게 할 수 없으면 [마지막 수단으로 처음부터 인덱스 재생성](../elasticsearch/troubleshooting/indexing.md#last-resort-to-recreate-an-index)을 고려할 수 있습니다. 이렇게 하면 인덱스가 올바른 최신 스키마로 재생성되므로 새로 생성된 인덱스가 모든 마이그레이션을 건너뛰므로 문제를 무시할 수 있습니다.

### 주 버전 업그레이드 전에 모든 마이그레이션을 완료해야 함 {#all-migrations-must-be-finished-before-doing-a-major-upgrade}

주 GitLab 버전으로 업그레이드하기 전에 해당 주 버전 이전의 최신 부 버전까지 존재하는 모든 마이그레이션을 완료해야 합니다. 주 버전 업그레이드를 진행하기 전에 [중단된 모든 마이그레이션을 재시도](#retry-a-halted-migration)하여 해결해야 합니다. 자세한 내용은 [업그레이드를 위한 마이그레이션](../../update/background_migrations.md)을 참조하세요.

제거된 마이그레이션은 [더 이상 사용되지 않음으로 표시](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/63001)됩니다. 보류 중인 모든 고급 검색 마이그레이션이 완료되기 전에 GitLab을 업그레이드하면 새 버전에서 제거된 보류 중인 마이그레이션은 실행하거나 재시도할 수 없습니다. 이 경우 [인덱스를 처음부터 재생성](../elasticsearch/troubleshooting/indexing.md#last-resort-to-recreate-an-index)해야 합니다.

### 건너뛸 수 있는 마이그레이션 {#skippable-migrations}

건너뛸 수 있는 마이그레이션은 조건이 충족될 때만 실행됩니다. 예를 들어 마이그레이션이 특정 Elasticsearch 버전에 따라 달라지면 해당 버전에 도달할 때까지 건너뛸 수 있습니다.

건너뛸 수 있는 마이그레이션이 더 이상 사용되지 않음으로 표시될 때까지 실행되지 않으면 변경 사항을 적용하기 위해 [인덱스를 재생성](../elasticsearch/troubleshooting/indexing.md#last-resort-to-recreate-an-index)해야 합니다.

## GitLab 고급 검색 Rake 작업 {#gitlab-advanced-search-rake-tasks}

다음을 수행할 수 있는 Rake 작업이 있습니다:

- [인덱서 빌드 및 설치](#build-and-install)
- [Elasticsearch 비활성화](#disable-advanced-search) 시 인덱스 삭제.
- 인덱스에 GitLab 데이터를 추가합니다.

다음은 사용 가능한 일부 Rake 작업입니다:

| 작업                                                                                                                                                       | 설명 |
|:-----------------------------------------------------------------------------------------------------------------------------------------------------------|:------------|
| [`sudo gitlab-rake gitlab:elastic:info`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/lib/tasks/gitlab/elastic.rake)                              | 고급 검색 통합을 위한 디버깅 정보를 출력합니다. |
| [`sudo gitlab-rake gitlab:elastic:index`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/lib/tasks/gitlab/elastic.rake)                             | GitLab 17.0 이전에서는 고급 검색에 대한 인덱싱을 켜고 `gitlab:elastic:recreate_index`, `gitlab:elastic:clear_index_status`, `gitlab:elastic:index_group_entities`, `gitlab:elastic:index_projects`, `gitlab:elastic:index_snippets` 및 `gitlab:elastic:index_users`을 실행합니다.<br>GitLab 17.1 이상에서는 백그라운드에서 Sidekiq 작업을 큐에 넣습니다. 먼저 작업이 고급 검색에 대한 인덱싱을 켜고 모든 인덱스가 생성되도록 인덱싱을 일시 정지합니다. 그런 다음 작업이 모든 인덱스를 재생성하고 인덱싱 상태를 지우고 프로젝트 및 그룹 데이터, 스니펫 및 사용자를 인덱싱하기 위한 추가 Sidekiq 작업을 큐에 넣습니다. 마지막으로 고급 검색에 대한 인덱싱을 재개하여 완료합니다. GitLab 17.1에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/421298)되었으며 [기능 플래그](../../administration/feature_flags/_index.md)가 `elastic_index_use_trigger_indexing`로 지정되었습니다. 기본적으로 활성화되었습니다. GitLab 17.3에서 [일반적으로 사용 가능](https://gitlab.com/gitlab-org/gitlab/-/issues/434580)합니다. `elastic_index_use_trigger_indexing` 기능 플래그가 제거되었습니다. |
| [`sudo gitlab-rake gitlab:elastic:pause_indexing`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/lib/tasks/gitlab/elastic.rake)                    | 고급 검색 인덱싱을 일시정지합니다. 변경사항은 계속 추적됩니다. 클러스터/인덱스 마이그레이션에 유용합니다. |
| [`sudo gitlab-rake gitlab:elastic:resume_indexing`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/lib/tasks/gitlab/elastic.rake)                   | 고급 검색 인덱싱을 재개합니다. |
| [`sudo gitlab-rake gitlab:elastic:index_and_search_validation`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/lib/tasks/gitlab/elastic.rake)       | 모든 인덱스의 클러스터 연결성, 인덱스 및 검색 작업의 유효성을 검사합니다. [GitLab 18.3에서 도입됨](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/200664). |
| [`sudo gitlab-rake gitlab:elastic:index_projects`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/lib/tasks/gitlab/elastic.rake)                    | 모든 프로젝트를 반복하고 백그라운드에서 인덱싱할 Sidekiq 작업을 큐에 넣습니다. 인덱스를 생성한 후에만 사용할 수 있습니다. |
| [`sudo gitlab-rake gitlab:elastic:index_group_entities`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/lib/tasks/gitlab/elastic.rake)              | `gitlab:elastic:index_work_items` 및 `gitlab:elastic:index_group_wikis`을 호출합니다. |
| [`sudo gitlab-rake gitlab:elastic:index_work_items`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/lib/tasks/gitlab/elastic.rake)                  | Elasticsearch가 활성화된 그룹의 모든 작업 항목을 인덱싱합니다. |
| [`sudo gitlab-rake gitlab:elastic:index_namespaces`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/lib/tasks/gitlab/elastic.rake)                  | 모든 루트 네임스페이스를 인덱싱합니다. |
| [`sudo gitlab-rake gitlab:elastic:index_group_wikis`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/lib/tasks/gitlab/elastic.rake)                 | Elasticsearch가 활성화된 그룹의 모든 wiki를 인덱싱합니다. |
| [`sudo gitlab-rake gitlab:elastic:index_snippets`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/lib/tasks/gitlab/elastic.rake)                    | 스니펫 데이터를 인덱싱하는 Elasticsearch 가져오기를 수행합니다. |
| [`sudo gitlab-rake gitlab:elastic:index_users`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/lib/tasks/gitlab/elastic.rake)                       | 모든 사용자를 Elasticsearch로 가져옵니다. |
| [`sudo gitlab-rake gitlab:elastic:index_vulnerabilities`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/lib/tasks/gitlab/elastic.rake)             | 모든 취약성을 인덱싱합니다. |
| [`sudo gitlab-rake gitlab:elastic:index_projects_status`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/lib/tasks/gitlab/elastic.rake)             | 모든 프로젝트 리포지토리 데이터(코드, 커밋 및 wiki)의 전체 인덱싱 상태를 결정합니다. 상태는 인덱싱된 프로젝트 수를 총 프로젝트 수로 나누고 100을 곱하여 계산됩니다. 이 작업에는 이슈, 머지 리퀘스트 또는 마일스톤과 같은 비저장소 데이터가 포함되지 않습니다. |
| [`sudo gitlab-rake gitlab:elastic:index_groups_status`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/lib/tasks/gitlab/elastic.rake)               | 모든 그룹 리포지토리 데이터(그룹 wiki)의 전체 인덱싱 상태를 결정합니다. 상태는 인덱싱된 그룹 수를 총 그룹 수로 나누고 100을 곱하여 계산됩니다. 이 작업에는 에픽, 머지 리퀘스트 또는 마일스톤과 같은 비저장소 데이터가 포함되지 않습니다. |
| [`sudo gitlab-rake gitlab:elastic:clear_index_status`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/lib/tasks/gitlab/elastic.rake)                | 모든 프로젝트의 모든 IndexStatus 인스턴스를 삭제합니다. 이 명령은 인덱스의 완전한 삭제를 초래하므로 주의해서 사용해야 합니다. |
| [`sudo gitlab-rake gitlab:elastic:create_empty_index`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/lib/tasks/gitlab/elastic.rake)                | 빈 인덱스(기본 인덱스 및 별도의 이슈 인덱스)를 생성하고 Elasticsearch 측에서 아직 없으면 각각에 대해 별칭을 할당합니다. |
| [`sudo gitlab-rake gitlab:elastic:delete_index`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/lib/tasks/gitlab/elastic.rake)                      | Elasticsearch 인스턴스에서 GitLab 인덱스 및 별칭(있는 경우)을 제거합니다. |
| [`sudo gitlab-rake gitlab:elastic:recreate_index`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/lib/tasks/gitlab/elastic.rake)                    | `gitlab:elastic:delete_index` 및 `gitlab:elastic:create_empty_index`의 래퍼 작업입니다. 인덱싱 작업을 큐에 넣지 않습니다. |
| [`sudo gitlab-rake gitlab:elastic:projects_not_indexed`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/lib/tasks/gitlab/elastic.rake)              | 리포지토리 데이터가 인덱싱되지 않은 프로젝트를 표시합니다. 이 작업에는 이슈, 머지 리퀘스트 또는 마일스톤과 같은 비저장소 데이터가 포함되지 않습니다. |
| [`sudo gitlab-rake gitlab:elastic:groups_not_indexed`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/lib/tasks/gitlab/elastic.rake)                | 리포지토리 데이터가 인덱싱되지 않은 그룹을 표시합니다. 이 작업에는 이슈, 머지 리퀘스트 또는 마일스톤과 같은 비저장소 데이터가 포함되지 않습니다. |
| [`sudo gitlab-rake gitlab:elastic:reindex_cluster`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/lib/tasks/gitlab/elastic.rake)                   | 무중단 클러스터 재인덱싱 작업을 예약합니다. |
| [`sudo gitlab-rake gitlab:elastic:mark_reindex_failed`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/lib/tasks/gitlab/elastic.rake)               | 가장 최근의 재인덱싱 작업을 실패했음으로 표시합니다. |
| [`sudo gitlab-rake gitlab:elastic:list_pending_migrations`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/lib/tasks/gitlab/elastic.rake)           | 보류 중인 마이그레이션을 나열합니다. 보류 중인 마이그레이션에는 아직 시작되지 않은 마이그레이션, 시작되었지만 완료되지 않은 마이그레이션 및 중단된 마이그레이션이 포함됩니다. |
| [`sudo gitlab-rake gitlab:elastic:estimate_cluster_size`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/lib/tasks/gitlab/elastic.rake)             | 전체 리포지토리 크기를 기반으로 코드 및 wiki 인덱스 크기와 총 클러스터 크기를 추정합니다. |
| [`sudo gitlab-rake gitlab:elastic:estimate_shard_sizes`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/lib/tasks/gitlab/elastic.rake)              | 대략적인 데이터베이스 개수를 기반으로 각 인덱스의 샤드 크기를 추정합니다. 이 추정에는 리포지토리 데이터(코드, 커밋 및 wiki)가 포함되지 않습니다. GitLab 16.11에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/146108)되었습니다. |
| [`sudo gitlab-rake gitlab:elastic:enable_search_with_elasticsearch`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/lib/tasks/gitlab/elastic.rake)  | Elasticsearch로 고급 검색을 활성화합니다. |
| [`sudo gitlab-rake gitlab:elastic:disable_search_with_elasticsearch`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/lib/tasks/gitlab/elastic.rake) | Elasticsearch로 고급 검색을 비활성화합니다. |

### 환경 변수 {#environment-variables}

Rake 작업 외에도 프로세스를 수정하는 데 사용할 수 있는 몇 가지 환경 변수가 있습니다:

| 환경 변수 | 데이터 타입 | 역할                                                                 |
| -------------------- |:---------:| ---------------------------------------------------------------------------- |
| `ID_TO`              | 정수   | 인덱서가 값 이하의 프로젝트만 인덱싱하도록 지시합니다.    |
| `ID_FROM`            | 정수   | 인덱서가 값 이상의 프로젝트만 인덱싱하도록 지시합니다. |

### 프로젝트 범위 또는 특정 프로젝트 인덱싱 {#indexing-a-range-of-projects-or-a-specific-project}

`ID_FROM` 및 `ID_TO` 환경 변수를 사용하면 제한된 수의 프로젝트를 인덱싱할 수 있습니다. 이는 인덱싱 단계적 실행에 유용할 수 있습니다.

```shell
root@git:~# sudo gitlab-rake gitlab:elastic:index_projects ID_FROM=1 ID_TO=100
```

`ID_FROM` 및 `ID_TO`는 `or equal to` 비교를 사용하므로, 두 변수를 동일한 프로젝트 ID로 설정하여 하나의 프로젝트만 인덱싱할 수 있습니다:

```shell
root@git:~# sudo gitlab-rake gitlab:elastic:index_projects ID_FROM=5 ID_TO=5
Indexing project repositories...I, [2019-03-04T21:27:03.083410 #3384]  INFO -- : Indexing GitLab User / test (ID=33)...
I, [2019-03-04T21:27:05.215266 #3384]  INFO -- : Indexing GitLab User / test (ID=33) is done!
```

## 고급 검색 인덱스 범위 {#advanced-search-index-scopes}

검색을 수행할 때 GitLab 인덱스는 다음 범위를 사용합니다:

| 범위 이름       | 검색 대상       |
|------------------|------------------------|
| `commits`        | 커밋 데이터            |
| `projects`       | 프로젝트 데이터(기본값) |
| `blobs`          | 코드                   |
| `work_items`     | 작업 항목 데이터         |
| `merge_requests` | 머지 리퀘스트 데이터     |
| `milestones`     | 마일스톤 데이터         |
| `notes`          | 노트 데이터              |
| `snippets`       | 스니펫 데이터           |
| `wiki_blobs`     | 위키 내용          |
| `users`          | 사용자                  |

GitLab.com 및 GitLab Dedicated에서는 검색 외부의 기능을 지원하기 위해 모든 프로젝트 및 네임스페이스에 대해 취약성 기록이 항상 인덱싱됩니다. GitLab Self-Managed에서 취약성 기록 인덱싱은 [이슈 525484](https://gitlab.com/gitlab-org/gitlab/-/issues/525484)에서 제안됩니다.

## 튜닝 {#tuning}

### 최적의 클러스터 구성 선택에 대한 지침 {#guidance-on-choosing-optimal-cluster-configuration}

클러스터 구성을 선택하기 위한 기본 지침은 [Elastic Cloud Calculator](https://cloud.elastic.co/pricing)를 참조하세요.

- 일반적으로 하나의 복제본을 포함하는 최소 2개 노드 클러스터 구성을 사용하려고 합니다. 이를 통해 복원력을 가질 수 있습니다. 저장소 사용량이 빠르게 증가하는 경우 미리 수평 확장(더 많은 노드 추가)을 계획할 수 있습니다.
- 검색 클러스터에서 HDD 저장소를 사용하는 것은 성능에 영향을 미치므로 권장되지 않습니다. SSD 저장소(예: NVMe 또는 SATA SSD 드라이브)를 사용하는 것이 좋습니다.
- 대규모 인스턴스에서 [조정 전용 노드](https://www.elastic.co/guide/en/elasticsearch/reference/current/modules-node.html#coordinating-only-node)를 사용하면 안 됩니다. 조정 전용 노드는 [데이터 노드](https://www.elastic.co/guide/en/elasticsearch/reference/current/modules-node.html#data-node)보다 작으므로 성능과 [고급 검색 마이그레이션](#advanced-search-migrations)에 영향을 미칠 수 있습니다.
- [GitLab 성능 도구](https://gitlab.com/gitlab-org/quality/performance)를 사용하여 다양한 검색 클러스터 크기 및 구성으로 검색 성능을 벤치마킹할 수 있습니다.
- `Heap size`는 실제 RAM의 50% 이상으로 설정하면 안 됩니다. 또한 0 기반 압축 oops의 임계값 이상으로 설정하면 안 됩니다. 정확한 임계값은 다양하지만 26GB는 대부분의 시스템에서 안전하지만 일부 시스템에서는 30GB만큼 클 수 있습니다. 자세한 내용은 [힙 크기 설정](https://www.elastic.co/guide/en/elasticsearch/reference/current/important-settings.html#heap-size-settings) 및 [JVM 옵션 설정](https://www.elastic.co/guide/en/elasticsearch/reference/current/jvm-options.html)을 참조하세요.
- `refresh_interval`는 인덱스별 설정입니다. 실시간 데이터가 필요하지 않은 경우 기본값 `1s`에서 더 큰 값으로 조정할 수 있습니다. 이는 최신 결과를 표시하는 시간을 변경합니다. 중요하다면 기본값에 최대한 가깝게 유지해야 합니다.
- 많은 인덱싱 작업이 있는 경우 [`indices.memory.index_buffer_size`](https://www.elastic.co/guide/en/elasticsearch/reference/current/indexing-buffer.html)를 30% 또는 40%로 늘릴 수 있습니다.

### 고급 검색 설정 {#advanced-search-settings}

#### Elasticsearch 샤드 수 {#number-of-elasticsearch-shards}

{{< history >}}

- `gitlab:elastic:estimate_shard_sizes`은 GitLab 16.11에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/146108)되었습니다.
- `gitlab:elastic:estimate_shard_sizes`은 GitLab 18.3에서 리포지토리 데이터를 포함하는 인덱스에 대한 크기 지정을 포함하도록 [변경](https://gitlab.com/gitlab-org/gitlab/-/issues/348452)되었습니다.

{{< /history >}}

단일 노드 클러스터의 경우 인덱스당 Elasticsearch 샤드 수를 Elasticsearch 데이터 노드의 CPU 코어 수로 설정합니다.

다중 노드 클러스터의 경우 Rake 작업 `gitlab:elastic:estimate_shard_sizes`을 실행하여 각 인덱스의 샤드 수를 결정합니다. 작업은 데이터베이스 데이터를 포함하는 인덱스에 대한 샤드 및 복제본 크기와 대략적인 문서 수에 대한 권장 사항을 반환합니다.

평균 샤드 크기를 몇 GB에서 30GB 사이로 유지합니다. 평균 샤드 크기가 30GB를 초과하면 인덱스의 샤드 크기를 늘리고 [무중단 재인덱싱](#zero-downtime-reindexing)을 트리거합니다. 클러스터가 정상적이려면 노드당 샤드 수가 구성된 힙 크기의 20배를 초과하면 안 됩니다. 예를 들어 30GB 힙이 있는 노드는 최대 600개의 샤드를 가져야 합니다.

인덱스의 샤드 수를 업데이트하려면 설정을 변경하고 [무중단 재인덱싱](#zero-downtime-reindexing)을 트리거합니다.

#### Elasticsearch 복제본 수 {#number-of-elasticsearch-replicas}

단일 노드 클러스터의 경우 인덱스당 Elasticsearch 복제본 수를 `0`로 설정합니다.

다중 노드 클러스터의 경우 인덱스당 Elasticsearch 복제본 수를 `1`(각 샤드는 하나의 복제본을 가짐)로 설정합니다. 하나의 노드를 잃으면 인덱스가 손상되므로 수를 `0`로 설정하면 안 됩니다.

[샤드 할당 인식](https://www.elastic.co/docs/deploy-manage/distributed-architecture/shard-allocation-relocation-recovery/shard-allocation-awareness)이 활성화되면 샤드당 총 복사본 수가 인식 속성(일반적으로 노드 또는 영역) 수로 균등하게 나누어떨어져야 합니다. 모든 인식 속성 전체에서 샤드 복사본을 균등하게 배포하면 최적의 내결함성 및 부하 분산을 보장합니다.

```plaintext
(1 + `number_of_replicas`) / `number_of_awareness_attributes` = whole number
```

인덱스의 복제본 수를 업데이트하려면 설정을 변경하고 [무중단 재인덱싱](#zero-downtime-reindexing)을 트리거합니다.

### 대규모 인스턴스 효율적으로 인덱싱 {#index-large-instances-efficiently}

전제 조건:

- 인스턴스에 대한 관리자 액세스 권한이 있어야 합니다.

> [!warning]
> 대규모 인스턴스를 인덱싱하면 많은 수의 Sidekiq 작업이 생성됩니다. [확장 가능한 설정](../../administration/reference_architectures/_index.md)을 유지하거나 [추가 Sidekiq 프로세스](../../administration/sidekiq/extra_sidekiq_processes.md)를 생성하여 이 작업을 준비해야 합니다.
>
> Geo 주 및 보조 노드는 동일한 Elasticsearch 클러스터를 가리킵니다. 그러나 Elasticsearch 인덱싱 워커는 주 사이트의 Sidekiq 노드에서만 실행됩니다.
>
> 이러한 이유로 주 사이트의 Sidekiq 노드에서 [추가 Sidekiq 프로세스](../../administration/sidekiq/extra_sidekiq_processes.md)를 구성해야 합니다.

[고급 검색 활성화](#enable-advanced-search)로 인해 많은 데이터를 인덱싱하여 문제가 발생하는 경우:

1. [Elasticsearch 호스트 및 포트 구성](#enable-advanced-search).
1. 빈 인덱스 생성:

   ```shell
   # For installations that use the Linux package
   sudo gitlab-rake gitlab:elastic:create_empty_index

   # For self-compiled installations
   bundle exec rake gitlab:elastic:create_empty_index RAILS_ENV=production
   ```

1. GitLab 인스턴스의 재인덱싱인 경우 인덱스 상태를 지웁니다:

   ```shell
   # For installations that use the Linux package
   sudo gitlab-rake gitlab:elastic:clear_index_status

   # For self-compiled installations
   bundle exec rake gitlab:elastic:clear_index_status RAILS_ENV=production
   ```

1. [**고급 검색을 위한 인덱싱 켜기** 체크박스 선택](#enable-advanced-search).
1. 큰 Git 리포지토리를 인덱싱하는 데는 시간이 걸릴 수 있습니다. 프로세스 속도를 높이려면 [인덱싱 속도 튜닝](https://www.elastic.co/guide/en/elasticsearch/reference/current/tune-for-indexing-speed.html#tune-for-indexing-speed)을 수행할 수 있습니다:

   - [`refresh_interval`](https://www.elastic.co/guide/en/elasticsearch/reference/current/indices-refresh.html)을 임시로 늘릴 수 있습니다.

   - 복제본 수를 0으로 설정할 수 있습니다. 이 설정은 인덱스의 각 기본 샤드가 가진 복사본 수를 제어합니다. 따라서 0 복제본을 가지면 노드 전체에 샤드 복제가 효과적으로 비활성화되어 인덱싱 성능이 증가합니다. 이는 안정성 및 쿼리 성능 측면에서 중요한 절충입니다. 초기 인덱싱이 완료된 후 복제본을 고려한 값으로 설정해야 한다는 점을 기억해야 합니다.

   인덱싱 시간을 20% 단축할 수 있습니다. 인덱싱이 완료되면 `refresh_interval` 및 `number_of_replicas`을 원하는 값으로 다시 설정할 수 있습니다.

   > [!note]
   > 이 단계는 선택 사항이지만 대규모 인덱싱 작업 속도를 크게 높일 수 있습니다.

   ```shell
   curl --request PUT localhost:9200/gitlab-production/_settings --header 'Content-Type: application/json' \
        --data '{
          "index" : {
              "refresh_interval" : "30s",
              "number_of_replicas" : 0
          } }'
   ```

1. 프로젝트 및 관련 데이터 인덱싱:

   ```shell
   # For installations that use the Linux package
   sudo gitlab-rake gitlab:elastic:index_projects

   # For self-compiled installations
   bundle exec rake gitlab:elastic:index_projects RAILS_ENV=production
   ```

   이것은 인덱싱이 필요한 각 프로젝트에 대해 Sidekiq 작업을 큐에 넣습니다. Rake 작업으로 인덱싱 상태를 쿼리할 수 있습니다:

   ```shell
   # For installations that use the Linux package
   sudo gitlab-rake gitlab:elastic:index_projects_status

   # For self-compiled installations
   bundle exec rake gitlab:elastic:index_projects_status RAILS_ENV=production

   Indexing is 65.55% complete (6555/10000 projects). Considers only code, commits, and wikis.
   ```

   인덱스를 프로젝트 범위로 제한하려면 `ID_FROM` 및 `ID_TO` 매개변수를 제공할 수 있습니다:

   ```shell
   # For installations that use the Linux package
   sudo gitlab-rake gitlab:elastic:index_projects ID_FROM=1001 ID_TO=2000

   # For self-compiled installations
   bundle exec rake gitlab:elastic:index_projects ID_FROM=1001 ID_TO=2000 RAILS_ENV=production
   ```

   `ID_FROM` 및 `ID_TO`는 프로젝트 ID입니다. 두 매개변수는 모두 선택 사항입니다. 이전 예제는 ID `1001`부터 ID `2000`(포함)까지 모든 프로젝트를 인덱싱합니다.

   > [!note]
   > `gitlab:elastic:index_projects`로 큐에 들어간 프로젝트 인덱싱 작업이 중단될 수 있습니다. 이는 여러 가지 이유로 발생할 수 있지만 인덱싱 작업을 다시 실행하는 것은 항상 안전합니다.

   `gitlab:elastic:clear_index_status` Rake 작업을 사용하여 인덱서가 모든 진행 상황을 "잊도록" 강제할 수 있으므로 처음부터 인덱싱 프로세스를 다시 시도합니다.
1. 작업 항목, 그룹 위키, 개인 스니펫 및 사용자는 프로젝트와 연결되지 않으며 별도로 인덱싱해야 합니다:

   ```shell
   # For installations that use the Linux package
   sudo gitlab-rake gitlab:elastic:index_work_items
   sudo gitlab-rake gitlab:elastic:index_group_wikis
   sudo gitlab-rake gitlab:elastic:index_snippets
   sudo gitlab-rake gitlab:elastic:index_users

   # For self-compiled installations
   bundle exec rake gitlab:elastic:index_work_items RAILS_ENV=production
   bundle exec rake gitlab:elastic:index_group_wikis RAILS_ENV=production
   bundle exec rake gitlab:elastic:index_snippets RAILS_ENV=production
   bundle exec rake gitlab:elastic:index_users RAILS_ENV=production
   ```

1. 인덱싱 후 복제 및 새로 고침 다시 활성화(`refresh_interval`를 이전에 늘린 경우에만):

   ```shell
   curl --request PUT localhost:9200/gitlab-production/_settings --header 'Content-Type: application/json' \
        --data '{
          "index" : {
              "number_of_replicas" : 1,
              "refresh_interval" : "1s"
          } }'
   ```

   새로 고침을 활성화한 후 강제 병합을 호출해야 합니다.

   Elasticsearch 6.x 이상의 경우 강제 병합을 진행하기 전에 인덱스가 읽기 전용 모드인지 확인하세요:

   ```shell
   curl --request PUT localhost:9200/gitlab-production/_settings --header 'Content-Type: application/json' \
        --data '{
          "settings": {
            "index.blocks.write": true
          } }'
   ```

   그런 다음 강제 병합을 시작합니다:

   ```shell
   curl --request POST 'localhost:9200/gitlab-production/_forcemerge?max_num_segments=5'
   ```

   그런 다음 인덱스를 읽기-쓰기 모드로 변경합니다:

   ```shell
   curl --request PUT localhost:9200/gitlab-production/_settings --header 'Content-Type: application/json' \
        --data '{
          "settings": {
            "index.blocks.write": false
          } }'
   ```

1. 인덱싱이 완료되면 [**고급 검색으로 검색** 체크박스 선택](#enable-advanced-search).

### 전용 Sidekiq 노드 또는 프로세스를 사용한 대규모 인스턴스 인덱싱 {#index-large-instances-with-dedicated-sidekiq-nodes-or-processes}

> [!warning]
> 대부분의 인스턴스의 경우 전용 Sidekiq 노드 또는 프로세스를 구성할 필요가 없습니다. 다음 단계에서는 [라우팅 규칙](../../administration/sidekiq/processing_specific_job_classes.md#routing-rules)이라는 Sidekiq의 고급 설정을 사용합니다. 라우팅 규칙 사용의 의미를 완전히 이해하여 작업을 완전히 잃지 않도록 해야 합니다.

대규모 인스턴스를 인덱싱하는 것은 Sidekiq 노드 및 프로세스를 압도할 가능성이 있는 길고 리소스 집약적인 프로세스입니다. 이는 GitLab 성능 및 가용성에 부정적인 영향을 미칩니다.

GitLab을 사용하면 여러 Sidekiq 프로세스를 시작할 수 있으므로 큐 또는 큐 그룹 집합을 인덱싱하는 데 전용 추가 프로세스를 만들 수 있습니다. 이렇게 하면 인덱싱 큐는 항상 전용 워커를 가지고 나머지 큐는 다른 전용 워커를 가져 경합을 피할 수 있습니다.

이를 위해 [라우팅 규칙](../../administration/sidekiq/processing_specific_job_classes.md#routing-rules) 옵션을 사용하여 Sidekiq이 [워커 일치 쿼리](../../administration/sidekiq/processing_specific_job_classes.md#worker-matching-query)를 기반으로 특정 큐에 작업을 라우팅하도록 합니다.

> [!note]
> 라우팅 규칙(`sidekiq['routing_rules']`)은 모든 GitLab 노드(특히 GitLab Rails 및 Sidekiq 노드)에서 동일해야 합니다.

이를 처리하기 위해 다음 두 가지 옵션 중 하나를 선택할 수 있습니다:

- [단일 노드에서 두 개의 큐 그룹 사용](#single-node-two-processes).
- [각 노드에서 하나씩 두 개의 큐 그룹 사용](#two-nodes-one-process-for-each).

다음 단계의 경우 `sidekiq['routing_rules']`의 항목을 고려하세요:

- `["feature_category=global_search", "global_search"]`로 모든 인덱싱 작업이 `global_search` 큐로 라우팅됩니다.
- `["*", "default"]`로 다른 모든 비인덱싱 작업이 `default` 큐로 라우팅됩니다.

`sidekiq['queue_groups']`의 최소한 하나의 프로세스는 `mailers` 큐를 포함해야 합니다. 그렇지 않으면 메일러 작업이 처리되지 않습니다.

> [!warning]
> 여러 프로세스를 시작할 때 프로세스 수는 Sidekiq에 전용하려는 CPU 코어 수를 초과할 수 없습니다. 각 Sidekiq 프로세스는 사용 가능한 워크로드 및 동시성 설정에 따라 하나의 CPU 코어만 사용할 수 있습니다. 자세한 내용은 [여러 Sidekiq 프로세스 실행](../../administration/sidekiq/extra_sidekiq_processes.md) 방법을 참조하세요.

#### 단일 노드, 두 프로세스 {#single-node-two-processes}

한 노드에서 인덱싱 및 비인덱싱 Sidekiq 프로세스를 모두 생성하려면:

1. Sidekiq 노드에서 `/etc/gitlab/gitlab.rb` 파일을 다음과 같이 변경합니다:

   ```ruby
   sidekiq['enable'] = true

   sidekiq['routing_rules'] = [
      ["feature_category=global_search", "global_search"],
      ["*", "default"],
   ]

   sidekiq['queue_groups'] = [
      "global_search", # process that listens to global_search queue
      "default,mailers" # process that listens to default and mailers queue
   ]

   sidekiq['concurrency'] = 20
   ```

   GitLab 16.11 이전 버전을 사용하는 경우 [큐 선택기](https://archives.docs.gitlab.com/16.11/ee/administration/sidekiq/processing_specific_job_classes.html#queue-selectors-deprecated)를 명시적으로 비활성화합니다:

   ```ruby
   sidekiq['queue_selector'] = false
   ```

1. 파일을 저장하고 [GitLab 재구성](../../administration/restart_gitlab.md)하여 변경 사항을 적용합니다.
1. 다른 모든 Rails 및 Sidekiq 노드에서 `sidekiq['routing_rules']`이 이전 구성과 동일한지 확인합니다.
1. Rake 작업을 실행하여 [기존 작업 마이그레이션](../../administration/sidekiq/sidekiq_job_migration.md):

> [!note]
> GitLab을 재구성한 직후 Rake 작업을 실행하는 것이 중요합니다. GitLab을 재구성한 후 Rake 작업이 작업 마이그레이션을 시작할 때까지 기존 작업이 처리되지 않습니다.

#### 두 노드, 각 노드당 하나의 프로세스 {#two-nodes-one-process-for-each}

두 노드에서 이러한 큐 그룹을 처리하려면:

1. 인덱싱 Sidekiq 노드에서 `/etc/gitlab/gitlab.rb` 파일을 다음과 같이 변경합니다:

   ```ruby
   sidekiq['enable'] = true

   sidekiq['routing_rules'] = [
      ["feature_category=global_search", "global_search"],
      ["*", "default"],
   ]

   sidekiq['queue_groups'] = [
     "global_search", # process that listens to global_search queue
   ]

   sidekiq['concurrency'] = 20
   ```

   GitLab 16.11 이전 버전을 사용하는 경우 [큐 선택기](https://archives.docs.gitlab.com/16.11/ee/administration/sidekiq/processing_specific_job_classes.html#queue-selectors-deprecated)를 명시적으로 비활성화합니다:

   ```ruby
   sidekiq['queue_selector'] = false
   ```

1. 파일을 저장하고 [GitLab 재구성](../../administration/restart_gitlab.md)하여 변경 사항을 적용합니다.
1. 비인덱싱 Sidekiq 노드에서 `/etc/gitlab/gitlab.rb` 파일을 다음과 같이 변경합니다:

   ```ruby
   sidekiq['enable'] = true

   sidekiq['routing_rules'] = [
      ["feature_category=global_search", "global_search"],
      ["*", "default"],
   ]

   sidekiq['queue_groups'] = [
      "default,mailers" # process that listens to default and mailers queue
   ]

   sidekiq['concurrency'] = 20
   ```

   GitLab 16.11 이전 버전을 사용하는 경우 [큐 선택기](https://archives.docs.gitlab.com/16.11/ee/administration/sidekiq/processing_specific_job_classes.html#queue-selectors-deprecated)를 명시적으로 비활성화합니다:

   ```ruby
   sidekiq['queue_selector'] = false
   ```

1. 다른 모든 Rails 및 Sidekiq 노드에서 `sidekiq['routing_rules']`이 이전 구성과 동일한지 확인합니다.
1. 파일을 저장하고 [GitLab 재구성](../../administration/restart_gitlab.md)하여 변경 사항을 적용합니다.
1. Rake 작업을 실행하여 [기존 작업 마이그레이션](../../administration/sidekiq/sidekiq_job_migration.md):

   ```shell
   sudo gitlab-rake gitlab:sidekiq:migrate_jobs:retry gitlab:sidekiq:migrate_jobs:schedule gitlab:sidekiq:migrate_jobs:queued
   ```

> [!note]
> GitLab을 재구성한 직후 Rake 작업을 실행하는 것이 중요합니다. GitLab을 재구성한 후 Rake 작업이 작업 마이그레이션을 시작할 때까지 기존 작업이 처리되지 않습니다.

### 삭제된 문서 {#deleted-documents}

인덱싱된 GitLab 객체(머지 리퀘스트 설명이 변경되거나, 리포지토리의 기본 브랜치에서 파일이 삭제되거나, 프로젝트가 삭제되는 등)에 변경 또는 삭제가 이루어질 때마다 인덱스의 문서가 삭제됩니다. 그러나 이는 "소프트" 삭제이므로 "삭제된 문서"의 전체 수와 낭비된 공간이 증가합니다.

Elasticsearch는 이러한 삭제된 문서를 제거하기 위해 세그먼트의 지능형 병합을 수행합니다. 그러나 GitLab 설치에서 활동의 양과 유형에 따라 인덱스에서 최대 50%의 낭비된 공간을 볼 수 있습니다.

일반적으로 Elasticsearch가 기본 설정으로 자동으로 병합하고 공간을 회수하도록 하는 것이 좋습니다. [Lucene의 삭제된 문서 처리](https://www.elastic.co/blog/lucenes-handling-of-deleted-documents "Lucene의 삭제된 문서 처리")에서 _"전반적으로 최대 세그먼트 크기를 감소시키는 것 외에도 Lucene 기본값을 그대로 두고 삭제가 회수되는 시기를 너무 걱정하지 않는 것이 가장 좋습니다."_

그러나 일부 대규모 설치에서는 병합 정책 설정을 튜닝하려고 할 수 있습니다:

- `index.merge.policy.max_merged_segment` 크기를 기본값 5GB에서 2GB 또는 3GB로 줄이는 것을 고려하세요. 병합은 세그먼트에 최소 50%의 삭제가 있을 때만 발생합니다. 더 작은 세그먼트 크기를 사용하면 병합이 더 자주 발생할 수 있습니다.

  ```shell
  curl --request PUT localhost:9200/gitlab-production/_settings ---header 'Content-Type: application/json' \
       --data '{
         "index" : {
           "merge.policy.max_merged_segment": "2gb"
         }
       }'
  ```

- `index.merge.policy.reclaim_deletes_weight`을 조정할 수도 있으며 이는 삭제가 대상이 되는 정도를 제어합니다. 그러나 이로 인해 비용이 많이 드는 병합 결정이 발생할 수 있으므로 장단점을 이해하지 못하면 이를 변경하면 안 됩니다.

  ```shell
  curl --request PUT localhost:9200/gitlab-production/_settings ---header 'Content-Type: application/json' \
       --data '{
         "index" : {
           "merge.policy.reclaim_deletes_weight": "3.0"
         }
       }'
  ```

- 삭제된 문서를 제거하기 위해 [강제 병합](https://www.elastic.co/guide/en/elasticsearch/reference/current/indices-forcemerge.html "강제 병합")을 수행하면 안 됩니다. [설명서](https://www.elastic.co/guide/en/elasticsearch/reference/current/indices-forcemerge.html "강제 병합")의 경고에 따르면 이로 인해 회수되지 않을 매우 큰 세그먼트가 발생할 수 있으며 중대한 성능 또는 가용성 이슈를 야기할 수도 있습니다.

## 기본 검색으로 되돌리기 {#reverting-to-basic-search}

Elasticsearch 인덱스 데이터에 이슈가 있을 수 있으며, 이에 따라 GitLab을 사용하면 검색 결과가 없을 때 "기본 검색"으로 되돌릴 수 있고 해당 범위에서 기본 검색이 지원된다고 가정합니다. 이 "기본 검색"은 인스턴스에 고급 검색이 전혀 활성화되지 않은 것처럼 작동하며 다른 데이터 소스(예: PostgreSQL 데이터 및 Git 데이터)를 사용하여 검색합니다.

## 재해 복구 {#disaster-recovery}

Elasticsearch는 GitLab의 보조 데이터 저장소입니다. Elasticsearch에 저장된 모든 데이터는 다른 데이터 소스(특히 PostgreSQL 및 Gitaly)에서 다시 파생될 수 있습니다. Elasticsearch 데이터 저장소가 손상되면 처음부터 모든 내용을 재인덱싱할 수 있습니다.

Elasticsearch 인덱스가 너무 크면 모든 내용을 처음부터 재인덱싱하는 데 과도한 가동 중지 시간이 발생할 수 있습니다. Elasticsearch 인덱스의 불일치를 자동으로 찾고 재동기화할 수는 없지만 누락된 업데이트에 대한 로그를 검사할 수 있습니다. 데이터를 더 빠르게 복구하려면 다음을 재생할 수 있습니다:

1. [`elasticsearch.log`](../../administration/logs/_index.md#elasticsearchlog)에서 [`track_items`](https://gitlab.com/gitlab-org/gitlab/-/blob/1e60ea99bd8110a97d8fc481e2f41cab14e63d31/ee/app/services/elastic/process_bookkeeping_service.rb#L25)을 검색하여 동기화된 모든 비리포지토리 업데이트. `::Elastic::ProcessBookkeepingService.track!`을 통해 이러한 항목을 다시 보내야 합니다.
1. [`elasticsearch.log`](../../administration/logs/_index.md#elasticsearchlog)에서 [`indexing_commit_range`](https://gitlab.com/gitlab-org/gitlab/-/blob/6f9d75dd3898536b9ec2fb206e0bd677ab59bd6d/ee/lib/gitlab/elastic/indexer.rb#L41)을 검색하여 모든 리포지토리 업데이트. [`IndexStatus#last_commit/last_wiki_commit`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/app/models/index_status.rb)를 로그의 가장 오래된 `from_sha`로 설정한 다음 [`Search::Elastic::CommitIndexerWorker`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/app/workers/search/elastic/commit_indexer_worker.rb) 및 [`ElasticWikiIndexerWorker`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/app/workers/elastic_wiki_indexer_worker.rb)을 사용하여 프로젝트의 다른 인덱스를 트리거해야 합니다.
1. [`sidekiq.log`](../../administration/logs/_index.md#sidekiqlog)에서 [`ElasticDeleteProjectWorker`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/app/workers/elastic_delete_project_worker.rb)을 검색하여 모든 프로젝트 삭제. 다른 `ElasticDeleteProjectWorker`을 트리거해야 합니다.

또한 정기적인 [Elasticsearch 스냅샷](https://www.elastic.co/guide/en/elasticsearch/reference/current/snapshot-restore.html)을 생성하여 모든 내용을 재인덱싱하지 않고도 데이터 손실에서 복구하는 데 걸리는 시간을 줄일 수 있습니다.
