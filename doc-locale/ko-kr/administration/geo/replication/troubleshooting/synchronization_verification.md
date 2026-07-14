---
stage: Tenant Scale
group: Geo
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Geo 동기화 및 검증 오류 문제 해결
description: "Geo 동기화 및 검증 실패를 문제 해결하고, 수동 재시도 절차, 대량 작업, 오류 진단 및 데이터 일관성 복원을 다룹니다."
---

{{< details >}}

- 계층:  Premium, Ultimate
- 제공:  GitLab Self-Managed

{{< /details >}}

`Admin > Geo > Sites`에서 복제 또는 검증 실패가 발생하거나 [Sync status Rake task](common.md#sync-status-rake-task)에서 이를 확인한 경우 다음 일반적인 단계로 실패를 해결할 수 있습니다:

1. Geo는 실패를 자동으로 재시도합니다. 실패가 최근에 발생하고 개수가 적거나 근본 원인이 이미 해결되었다고 의심되는 경우 실패가 해결될 때까지 기다릴 수 있습니다.
1. 실패가 오랫동안 존재했던 경우 이미 많은 재시도가 발생했으며, 자동 재시도 간격이 실패 유형에 따라 최대 4시간까지 증가했습니다. 근본 원인이 이미 해결되었다고 의심되는 경우 [수동으로 복제 또는 검증을 재시도](#manually-retry-replication-or-verification)할 수 있습니다.
1. 실패가 지속되면 다음 섹션을 사용하여 해결을 시도하세요.

## 진단 절차 {#diagnostic-procedures}

수동 재시도를 시도하기 전에 이 향상된 진단 절차를 사용하여 동기화 문제의 범위와 특성을 더 잘 이해할 수 있습니다.

### 모델 상태 확인 {#model-status-check}

이 절차는 모든 [Geo 데이터 유형 모델 클래스](#geo-data-type-model-classes)에 대한 자세한 상태 정보를 제공하고 체크섬 실패를 식별하는 데 도움이 됩니다. 이 실패는 복제 가능한 객체의 체크섬을 계산할 수 없을 때 발생합니다. "프라이머리 검증 실패"라고도 합니다.

UI 또는 Rails 콘솔에서 체크섬 실패를 볼 수 있습니다.

{{< tabs >}}

{{< tab title="UI" >}}

**프라이머리** 사이트에서 [데이터 관리](../../../admin_area.md#data-management) 페이지를 사용하세요.

{{< /tab >}}

{{< tab title="Rails 콘솔" >}}

다음 스크립트를 사용하여 각 모델 유형에 대한 자세한 정보를 출력할 수 있습니다:

- 레코드의 총 개수
- 실패, 검증됨 및 보류 중인 레코드의 수
- 조사할 실패한 레코드 샘플

> [!note]
> `ModelMapper` 클래스는 [GitLab 18.3](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/196293)에서 추가되었습니다. 이전 버전의 경우 [Geo 데이터 유형 모델 클래스](#geo-data-type-model-classes)의 목록을 수동으로 지정해야 합니다.

1. **프라이머리** 사이트에서 [Rails 콘솔 세션을 시작](../../../operations/rails_console.md#starting-a-rails-console-session)하세요.
1. 다음 스크립트를 실행하여 종합 개요를 얻으세요:

   ```ruby
   def output_geo_verification_failures
     model_classes = ::Gitlab::Geo::ModelMapper.available_models

     model_classes.each do |klass|
       total = klass.count
       state_klass = klass.verification_state_table_class
       failed_examples = []

       puts "\n=== #{klass.name} ==="
       puts "Total: #{total}"
       ::Geo::VerificationState::VERIFICATION_STATE_VALUES.each do |key, value|
         records = state_klass.where(verification_state: value)
         failed_examples = records if key == 'verification_failed'

         puts "#{key.gsub('verification_', '').camelize}: #{records.size}"
       end

       if failed_examples.any?
         puts "\nSample failed records:"
         failed_examples.limit(3).each { |record| puts "  ID: #{record.id}, Checksum: #{record.verification_checksum || 'nil'}, Error: #{record.verification_failure}" }
       end
     end

     nil
   end

   output_geo_verification_failures
   ```

{{< /tab >}}

{{< /tabs >}}

### 레지스트리 상태 확인 {#registry-status-check}

이 절차는 모든 Geo 레지스트리 유형에 대한 자세한 상태 정보를 제공하고 실패의 패턴을 식별하는 데 도움이 됩니다.

1. [Rails 콘솔 세션을 시작](../../../operations/rails_console.md#starting-a-rails-console-session)하고 **세컨더리** 사이트에서 실행합니다.
1. 다음 스크립트를 실행하여 종합 개요를 얻으세요:

   ```ruby
   def output_geo_failures()
     registry_classes = [
       Geo::UploadRegistry,
       Geo::JobArtifactRegistry,
       Geo::PackageFileRegistry,
       Geo::PagesDeploymentRegistry,
       Geo::ProjectRepositoryRegistry,
       Geo::TerraformStateVersionRegistry,
       Geo::MergeRequestDiffRegistry,
       Geo::LfsObjectRegistry,
       Geo::PipelineArtifactRegistry,
       Geo::CiSecureFileRegistry,
       Geo::ContainerRepositoryRegistry
     ]

     registry_classes.each do |klass|
       puts "\n=== #{klass.name} ==="
       puts "Total: #{klass.count}"
       puts "Failed: #{klass.failed.count}"
       puts "Synced: #{klass.synced.count}"
       puts "Pending: #{klass.pending.count}"
       puts "Started: #{klass.with_state(:started).count}"

       if klass.failed.count > 0
          puts "\nSample failed records:"
          klass.failed.limit(3).each { |record| puts "  ID: #{record.id}, Error: #{record.last_sync_failure}" }
       end
     end

     nil
   end

   output_geo_failures()
   ```

1. 이 스크립트는 다음을 포함한 각 레지스트리 유형에 대한 자세한 정보를 출력합니다:
   - 레코드의 총 개수
   - 실패, 동기화됨 및 보류 중인 레코드의 수
   - 조사할 실패한 레코드 샘플

## 복제 또는 검증 수동 재시도 {#manually-retry-replication-or-verification}

세컨더리 Geo 사이트의 [Rails 콘솔](../../../operations/rails_console.md#starting-a-rails-console-session)에서 다음을 수행할 수 있습니다:

- [개별 구성요소 수동 재동기화 및 재검증](#resync-and-reverify-individual-components)
- [여러 구성요소 수동 재동기화 및 재검증](#resync-and-reverify-multiple-components)

### 개별 구성요소 재동기화 및 재검증 {#resync-and-reverify-individual-components}

세컨더리 사이트에서 **운영자** > **Geo** > **Replication**을 방문하여 개별 항목의 재동기화 또는 재검증을 강제합니다.

그러나 이것이 작동하지 않으면 Rails 콘솔을 사용하여 동일한 작업을 수행할 수 있습니다. 다음 섹션에서는 [Rails 콘솔](../../../operations/rails_console.md#starting-a-rails-console-session)의 내부 애플리케이션 명령을 사용하여 개별 레코드에 대해 동기식 또는 비동기식으로 복제 또는 검증을 수행하는 방법을 설명합니다.

#### Replicator 인스턴스 획득 {#obtaining-a-replicator-instance}

> [!warning]
> 데이터를 변경하는 명령은 올바르게 실행되지 않거나 적절한 조건에서 실행되지 않으면 손상을 야기할 수 있습니다. 항상 테스트 환경에서 먼저 명령을 실행하고 복원할 수 있는 백업 인스턴스를 준비해 두세요.

동기화 또는 검증 작업을 수행하기 전에 Replicator 인스턴스를 획득해야 합니다.

먼저 [Rails 콘솔 세션을 시작](../../../operations/rails_console.md#starting-a-rails-console-session)합니다(수행하려는 작업에 따라 **프라이머리** 또는 **세컨더리** 사이트에서).

**프라이머리** 사이트:

- 리소스를 체크섬할 수 있습니다.

**세컨더리** 사이트:

- 리소스를 동기화할 수 있습니다.
- 리소스를 체크섬하고 해당 체크섬을 프라이머리 사이트의 체크섬과 비교하여 검증할 수 있습니다.

다음으로 다음 스니펫 중 하나를 실행하여 Replicator 인스턴스를 획득하세요.

##### 모델 레코드의 ID가 주어진 경우 {#given-a-model-records-id}

- `123`를 실제 ID로 바꾸세요.
- `Packages::PackageFile`를 [Geo 데이터 유형 모델 클래스](#geo-data-type-model-classes) 중 하나로 바꾸세요.

```ruby
model_record = Packages::PackageFile.find_by(id: 123)
replicator = model_record.replicator
```

##### 레지스트리 레코드의 ID가 주어진 경우 {#given-a-registry-records-id}

- `432`를 실제 ID로 바꾸세요. 레지스트리 레코드는 추적하는 모델 레코드와 동일한 ID 값을 가질 수도 있고 가지지 않을 수도 있습니다.
- `Geo::PackageFileRegistry`를 [Geo 레지스트리 클래스](#geo-registry-classes) 중 하나로 바꾸세요.

세컨더리 Geo 사이트에서:

```ruby
registry_record = Geo::PackageFileRegistry.find_by(id: 432)
replicator = registry_record.replicator
```

##### 레지스트리 레코드의 `last_sync_failure` 오류 메시지가 주어진 경우 {#given-an-error-message-in-a-registry-records-last_sync_failure}

- `Geo::PackageFileRegistry`를 [Geo 레지스트리 클래스](#geo-registry-classes) 중 하나로 바꾸세요.
- `error message here`를 실제 오류 메시지로 바꾸세요.

```ruby
registry = Geo::PackageFileRegistry.find_by("last_sync_failure LIKE '%error message here%'")
replicator = registry.replicator
```

##### 레지스트리 레코드의 `verification_failure` 오류 메시지가 주어진 경우 {#given-an-error-message-in-a-registry-records-verification_failure}

- `Geo::PackageFileRegistry`를 [Geo 레지스트리 클래스](#geo-registry-classes) 중 하나로 바꾸세요.
- `error message here`를 실제 오류 메시지로 바꾸세요.

```ruby
registry = Geo::PackageFileRegistry.find_by("verification_failure LIKE '%error message here%'")
replicator = registry.replicator
```

#### Replicator 인스턴스를 사용한 작업 수행 {#performing-operations-with-a-replicator-instance}

`replicator` 변수에 저장된 Replicator 인스턴스가 있으면 많은 작업을 수행할 수 있습니다:

##### 콘솔에서 동기화 {#sync-in-the-console}

이 스니펫은 **세컨더리** 사이트에서만 작동합니다.

이것은 동기화 코드를 콘솔에서 동기식으로 실행하므로 리소스를 동기화하는 데 걸리는 시간을 확인하거나 전체 오류 백트레이스를 볼 수 있습니다.

```ruby
replicator.sync
```

선택적으로 콘솔의 로그 수준을 구성된 로그 수준보다 더 자세하게 만든 후 동기화를 수행하세요:

```ruby
Rails.logger.level = :debug
```

##### 콘솔에서 체크섬 또는 검증 {#checksum-or-verify-in-the-console}

이 스니펫은 모든 **프라이머리** 또는 **세컨더리** 사이트에서 작동합니다.

**프라이머리** 사이트에서는 리소스를 체크섬하고 결과를 메인 GitLab 데이터베이스에 저장합니다. **세컨더리** 사이트에서는 리소스를 체크섬하고, 메인 GitLab 데이터베이스의 체크섬(**프라이머리** 사이트에서 생성)과 비교하며, 결과를 Geo 추적 데이터베이스에 저장합니다.

이것은 체크섬 및 검증 코드를 콘솔에서 동기식으로 실행하므로 소요 시간을 확인하거나 전체 오류 백트레이스를 볼 수 있습니다.

```ruby
replicator.verify
```

##### Sidekiq 작업에서 동기화 {#sync-in-a-sidekiq-job}

이 스니펫은 **세컨더리** 사이트에서만 작동합니다.

Sidekiq가 [동기화](#sync-in-the-console)를 수행하는 작업을 큐에 넣습니다.

```ruby
replicator.enqueue_sync
```

##### Sidekiq 작업에서 검증 {#verify-in-a-sidekiq-job}

이 스니펫은 모든 **프라이머리** 또는 **세컨더리** 사이트에서 작동합니다.

Sidekiq가 [체크섬 또는 검증](#checksum-or-verify-in-the-console)을 수행하는 작업을 큐에 넣습니다.

```ruby
replicator.verify_async
```

##### 모델 레코드 가져오기 {#get-a-model-record}

이 스니펫은 모든 **프라이머리** 또는 **세컨더리** 사이트에서 작동합니다.

```ruby
replicator.model_record
```

##### 레지스트리 레코드 가져오기 {#get-a-registry-record}

이 스니펫은 **세컨더리** 사이트에서만 작동합니다. 레지스트리 테이블은 Geo 추적 DB에 저장되기 때문입니다.

```ruby
replicator.registry
```

#### Geo 데이터 유형 모델 클래스 {#geo-data-type-model-classes}

Geo 데이터 유형은 GitLab 기능 중 하나 이상에서 관련 데이터를 저장하기 위해 필요하고 Geo에 의해 세컨더리 사이트로 복제되는 특정 데이터 클래스입니다.

- **Blob types**:
  - `Ci::JobArtifact`
  - `Ci::PipelineArtifact`
  - `Ci::SecureFile`
  - `LfsObject`
  - `MergeRequestDiff`
  - `Packages::PackageFile`
  - `PagesDeployment`
  - `Terraform::StateVersion`
  - `Upload`
  - `DependencyProxy::Manifest`
  - `DependencyProxy::Blob`
- **Git Repository types**:
  - `DesignManagement::Repository`
  - `ProjectRepository`
  - `ProjectWikiRepository`
  - `SnippetRepository`
  - `GroupWikiRepository`
- **Other types**:
  - `ContainerRepository`

주요 클래스의 종류는 Registry, Model 및 Replicator입니다. 이 클래스 중 하나의 인스턴스가 있으면 다른 클래스를 얻을 수 있습니다. Registry와 Model은 주로 PostgreSQL DB 상태를 관리합니다. Replicator는 비PostgreSQL 데이터(파일/Git 리포지토리/컨테이너 리포지토리)를 복제하거나 검증하는 방법을 알고 있습니다.

#### Geo 레지스트리 클래스 {#geo-registry-classes}

GitLab Geo의 맥락에서 **registry record**는 Geo 추적 데이터베이스의 레지스트리 테이블을 의미합니다. 각 레코드는 LFS 파일 또는 프로젝트 Git 리포지토리와 같은 메인 GitLab 데이터베이스의 단일 복제 가능 항목을 추적합니다. 쿼리할 수 있는 Geo 레지스트리 테이블에 해당하는 Rails 모델은 다음과 같습니다:

- **Blob types**:
  - `Geo::CiSecureFileRegistry`
  - `Geo::DependencyProxyBlobRegistry`
  - `Geo::DependencyProxyManifestRegistry`
  - `Geo::JobArtifactRegistry`
  - `Geo::LfsObjectRegistry`
  - `Geo::MergeRequestDiffRegistry`
  - `Geo::PackageFileRegistry`
  - `Geo::PagesDeploymentRegistry`
  - `Geo::PipelineArtifactRegistry`
  - `Geo::ProjectWikiRepositoryRegistry`
  - `Geo::SnippetRepositoryRegistry`
  - `Geo::TerraformStateVersionRegistry`
  - `Geo::UploadRegistry`
- **Git Repository types**:
  - `Geo::DesignManagementRepositoryRegistry`
  - `Geo::ProjectRepositoryRegistry`
  - `Geo::ProjectWikiRepositoryRegistry`
  - `Geo::SnippetRepositoryRegistry`
  - `Geo::GroupWikiRepositoryRegistry`
- **Other types**:
  - `Geo::ContainerRepositoryRegistry`

### 여러 구성요소 재동기화 및 재검증 {#resync-and-reverify-multiple-components}

{{< history >}}

- 대량 재동기화 및 재검증이 GitLab 16.5에서 [추가](https://gitlab.com/gitlab-org/gitlab/-/issues/364729)되었습니다.

{{< /history >}}

구성 요소 리소스가 동기화 또는 검증에 실패할 때 대량 작업을 트리거하여 복제 큐를 다시 시작할 수 있습니다. 이 작업은 재시도 횟수와 일정 시간을 0으로 재설정하여 시스템이 1시간까지 대기하지 않고 실패한 리소스를 더 빨리 처리하도록 합니다.

> [!note]
> 이 작업은 리소스를 즉시 처리하지 않습니다. 대신 동기화 및 검증을 처리하는 백그라운드 작업을 다시 큐에 넣습니다. 실제 복제 작업은 표준 Geo 복제 프로세스를 통해 비동기식으로 수행됩니다.

#### 재동기화 및 재검증의 작동 방식 {#how-resync-and-reverification-works}

재동기화 또는 재검증 작업을 트리거하면 시스템이 일치하는 레코드를 `pending`로 표시합니다. Geo 재동기화 및 재검증 백그라운드 워커는 이 레코드를 선택하여 정상적인 큐 우선순위에 따라 처리합니다. 이 메커니즘을 통해 작업을 즉시 차단하지 않으면서 실패한 리소스의 처리를 가속화할 수 있습니다.

> [!note]
> 성공적으로 동기화되지 않은 레코드를 재검증할 수 없습니다. 동기화된 레코드만 검증할 수 있습니다.

UI 또는 Rails 콘솔에서 대량 작업을 트리거할 수 있습니다.

#### UI에서 {#from-the-ui}

UI에서 한 구성 요소의 모든 리소스의 전체 재동기화를 예약할 수 있습니다:

1. 오른쪽 위 모서리에서 **운영자**를 선택하세요.
1. 왼쪽 사이드바에서 **Geo** > **사이트**를 선택하세요.
1. **Replication details** 아래에서 원하는 구성 요소를 선택하세요.

##### 선택한 구성 요소에 대한 리소스 재동기화 {#resync-resources-for-the-selected-component}

1. **전체 재동기화**를 선택하면 이미 동기화되었는지 여부와 관계없이 선택한 리소스의 모든 레코드 상태가 재설정됩니다.
1. **모든 재동기화에 실패함**을 선택하면 동기화에 실패한 모든 레코드가 재설정됩니다.

##### 선택한 구성 요소에 대한 리소스 재검증 {#reverify-resources-for-the-selected-component}

1. **전체 재인증**을 선택하면 이미 검증되었는지 여부와 관계없이 선택한 리소스의 모든 레코드 상태가 재설정됩니다.
1. **실패 항목 재검증**을 선택하면 검증에 실패했지만 동기화는 성공한 모든 레코드가 재설정됩니다.

##### 모든 사이트에서 한 구성 요소 재검증 {#reverify-one-component-on-all-sites}

**프라이머리** 사이트의 체크섬에 문제가 있으면 **프라이머리** 사이트에서 체크섬을 재계산해야 합니다. "전체 재검증"은 그 이후에 달성되는데, **프라이머리** 사이트에서 각 체크섬이 재계산된 후 이벤트가 생성되어 모든 **세컨더리** 사이트로 전파되어 체크섬을 재계산하고 값을 비교하기 때문입니다. 불일치는 레지스트리를 `sync failed`로 표시하여 동기화 재시도가 예약되도록 합니다.

UI에서 프라이머리 사이트의 체크섬을 재계산할 수 있습니다:

1. 오른쪽 위 모서리에서 **운영자**를 선택하세요.
1. 왼쪽 사이드바에서 **모니터링** > **데이터 관리**를 선택하세요.
1. 드롭다운 목록에서 원하는 구성 요소를 선택하세요.
1. **전체 체크섬**을 선택하세요.

> [!warning]
> **전체 재동기화**, **전체 재인증** 및 **전체 체크섬**은 이미 동기화되었거나 검증되었는지 여부와 관계없이 모든 리소스의 업데이트를 트리거합니다. 인스턴스에 있는 객체 유형이 수천 개인 경우(예: CI 작업 아티팩트)는 실행해서는 안 됩니다.

#### Rails 콘솔에서 {#from-the-rails-console}

> [!warning]
> 데이터를 변경하는 명령은 올바르게 실행되지 않거나 적절한 조건에서 실행되지 않으면 손상을 야기할 수 있습니다. 항상 테스트 환경에서 먼저 명령을 실행하고 복원할 수 있는 백업 인스턴스를 준비해 두세요.

다음 섹션에서는 [Rails 콘솔](../../../operations/rails_console.md#starting-a-rails-console-session)의 내부 애플리케이션 명령을 사용하여 대량 복제 또는 검증을 수행하는 방법을 설명합니다.

##### 동기화에 실패한 한 구성 요소의 모든 리소스 동기화 {#sync-all-resources-of-one-component-that-failed-to-sync}

다음 스크립트는:

- 실패한 모든 리포지토리를 반복합니다.
- 마지막 실패의 이유를 포함한 Geo 동기화 및 검증 메타데이터를 표시합니다.
- 리포지토리 재동기화를 시도합니다.
- 실패가 발생하고 그 이유를 보고합니다.
- 완료하는 데 시간이 걸릴 수 있습니다. 각 리포지토리 확인은 결과를 보고하기 전에 완료되어야 합니다. 세션이 시간 초과되면 `screen` 세션을 시작하거나 [Rails runner](../../../operations/rails_console.md#using-the-rails-runner) 및 `nohup`를 사용하여 실행하는 등의 조치를 취하여 프로세스가 계속 실행되도록 허용하세요.

이 스크립트를 **on the secondary Geo site** 실행하세요.

```ruby
Geo::ProjectRepositoryRegistry.failed.find_each do |registry|
   begin
     puts "ID: #{registry.id}, Project ID: #{registry.project_id}, Last Sync Failure: '#{registry.last_sync_failure}'"
     registry.replicator.sync
     puts "Sync initiated for registry ID: #{registry.id}"
   rescue => e
     puts "ID: #{registry.id}, Project ID: #{registry.project_id}, Failed: '#{e}'", e.backtrace.join("\n")
   end
end; nil
```

##### 프라이머리 사이트에서 체크섬에 실패한 모든 리소스 재검증 {#reverify-all-resources-that-failed-to-checksum-on-the-primary-site}

시스템은 프라이머리 사이트에서 체크섬에 실패한 모든 리소스를 자동으로 재검증하지만 과도한 실패 양을 피하기 위해 점진적 백오프 체계를 사용합니다.

선택적으로, 예를 들어 시도한 개입을 완료한 경우 수동으로 재검증을 더 빨리 트리거할 수 있습니다:

1. **프라이머리** 사이트의 GitLab Rails 노드에 SSH로 연결하세요.
1. [Rails 콘솔](../../../operations/rails_console.md#starting-a-rails-console-session)을 여세요.
1. `Upload`를 [Geo 데이터 유형 모델 클래스](#geo-data-type-model-classes) 중 하나로 바꾸고 모든 리소스를 `pending verification`로 표시하세요:

   ```ruby
   Upload.verification_state_table_class.where(verification_state: 3).each_batch do |relation|
     relation.update_all(verification_state: 0)
   end
   ```

## 오류 {#errors}

### 메시지: `The file is missing on the Geo primary site` {#message-the-file-is-missing-on-the-geo-primary-site}

동기화 실패 `The file is missing on the Geo primary site`은 처음으로 세컨더리 Geo 사이트를 설정할 때 일반적이며, 이는 프라이머리 사이트의 데이터 불일치로 인해 발생합니다.

데이터 불일치 및 누락된 파일은 GitLab을 운영할 때 시스템 또는 사용자 오류로 인해 발생할 수 있습니다. 예를 들어, 인스턴스 관리자가 로컬 파일 시스템의 여러 아티팩트를 수동으로 삭제합니다. 이러한 변경은 데이터베이스에 제대로 전파되지 않아 불일치가 발생합니다. 이 불일치는 남아 있으며 마찰을 일으킬 수 있습니다. Geo 세컨더리는 데이터베이스에서 여전히 참조되지만 더 이상 존재하지 않는 파일 복제를 계속 시도할 수 있습니다.

> [!note]
> 최근 로컬 스토리지에서 객체 스토리지로의 마이그레이션의 경우 전용 [객체 스토리지 문제 해결 섹션](../../../object_storage.md#inconsistencies-after-migrating-to-object-storage)을 참조하세요.

#### 불일치 식별 {#identify-inconsistencies}

누락된 파일이나 불일치가 있으면 `geo.log`에서 다음과 같은 항목을 만날 수 있습니다. `"primary_missing_file" : true` 필드를 참고하세요:

```json
{
   "bytes_downloaded" : 0,
   "class" : "Geo::BlobDownloadService",
   "correlation_id" : "01JT69C1ECRBEMZHA60E5SAX8E",
   "download_success" : false,
   "download_time_s" : 0.196,
   "gitlab_host" : "gitlab.example.com",
   "mark_as_synced" : false,
   "message" : "Blob download",
   "model_record_id" : 55,
   "primary_missing_file" : true,
   "reason" : "Not Found",
   "replicable_name" : "upload",
   "severity" : "WARN",
   "status_code" : 404,
   "time" : "2025-05-01T16:02:44.836Z",
   "url" : "http://gitlab.example.com/api/v4/geo/retrieve/upload/55"
}
```

동일한 오류가 **운영자** > **Geo** > **사이트** 아래의 UI에도 반영됩니다(특정 복제 가능 항목의 동기화 상태를 검토할 때). 이 시나리오에서는 특정 업로드가 누락되어 있습니다:

![모든 실패한 오류를 표시하는 Geo 업로드 복제 가능 대시보드.](img/geo_uploads_file_missing_v17_11.png)

![누락된 파일 오류를 표시하는 Geo 업로드 복제 가능 대시보드.](img/geo_uploads_file_missing_details_v17_11.png)

#### 불일치 정리 {#clean-up-inconsistencies}

> [!warning]
> 삭제 명령을 실행하기 전에 최근 작업 백업이 준비되어 있는지 확인하세요.

이 오류를 제거하려면 먼저 영향을 받는 특정 리소스를 식별하세요. 그런 다음 적절한 `destroy` 명령을 실행하여 모든 Geo 사이트 및 해당 데이터베이스에 삭제가 전파되는지 확인하세요. 이전 시나리오를 바탕으로 **upload**로 인한 오류가 아래 예에 사용됩니다.

1. 식별된 불일치를 해당 [Geo 모델 클래스](#geo-data-type-model-classes) 이름으로 매핑하세요. 클래스 이름은 다음 단계에서 필요합니다. 이 시나리오에서는 업로드의 경우 `Upload`에 해당합니다.
1. [프라이머리 Geo 사이트](../../../operations/rails_console.md#starting-a-rails-console-session)에서 **Geo primary site**을 시작하세요.
1. 이전 단계의 *Geo 모델 클래스*를 기반으로 파일 누락으로 인해 검증이 실패한 모든 리소스를 쿼리하세요. `limit(20)`를 조정하거나 제거하여 더 많은 결과를 표시하세요. 나열된 리소스가 UI에 표시된 실패한 리소스와 일치하는지 확인하세요:

   ```ruby
   Upload.verification_failed.where("verification_failure like '%File is not checksummable%'").limit(20)

   => #<Upload:0x00007b362bb6c4e8
    id: 55,
    size: 13346,
    path: "503d99159e2aa8a3ac23602058cfdf58/openbao.png",
    checksum: "db29d233de49b25d2085dcd8610bac787070e721baa8dcedba528a292b6e816b",
    model_id: 1,
    model_type: "Project",
    uploader: "FileUploader",
    created_at: Thu, 01 May 2025 15:54:10.549178000 UTC +00:00,
    store: 1,
    mount_point: nil,
    secret: "[FILTERED]",
    version: 2,
    uploaded_by_user_id: 1,
    organization_id: nil,
    namespace_id: nil,
    project_id: 1,
    verification_checksum: nil>
   ```

1. 선택적으로 영향을 받는 리소스의 `id`을 사용하여 이들이 아직 필요한지 결정하세요:

   ```ruby
   Upload.find(55)

   => #<Upload:0x00007b362bb6c4e8
    id: 55,
    size: 13346,
    path: "503d99159e2aa8a3ac23602058cfdf58/openbao.png",
    checksum: "db29d233de49b25d2085dcd8610bac787070e721baa8dcedba528a292b6e816b",
    model_id: 1,
    model_type: "Project",
    uploader: "FileUploader",
    created_at: Thu, 01 May 2025 15:54:10.549178000 UTC +00:00,
    store: 1,
    mount_point: nil,
    secret: "[FILTERED]",
    version: 2,
    uploaded_by_user_id: 1,
    organization_id: nil,
    namespace_id: nil,
    project_id: 1,
    verification_checksum: nil>
   ```

   - 영향을 받는 리소스를 복구해야 한다고 판단되면 다음 옵션(철저하지 않은)을 탐색하여 복구할 수 있습니다:
     - 세컨더리 사이트에 객체가 있는지 확인하고 프라이머리에 수동으로 복사하세요.
     - 이전 백업을 살펴보고 프라이머리 사이트에 객체를 수동으로 복사하세요.
     - 일부를 현장 확인하여 레코드 파괴가 가능한지 판단하세요. 예를 들어 모두 오래된 아티팩트인 경우 중요 데이터가 아닐 수 있습니다.

1. 식별된 리소스의 `id`를 사용하여 `destroy`를 사용하여 개별적으로 또는 대량으로 삭제하세요. 적절한 *Geo 모델 클래스* 이름을 사용하는지 확인하세요.
   - 개별 리소스 삭제:

     ```ruby
     Upload.find(55).destroy
     ```

   - 영향을 받는 모든 리소스 삭제:

     ```ruby
     def destroy_uploads_not_checksummable
       uploads = Upload.verification_failed.where("verification_failure like '%File is not checksummable%'");1
       puts "Found #{uploads.count} resources that failed verification with 'File is not checksummable'."
       puts "Enter 'y' to continue: "
       prompt = STDIN.gets.chomp
       if prompt != 'y'
         puts "Exiting without action..."
         return
       end

       puts "Destroying all..."
       uploads.destroy_all
     end

     destroy_uploads_not_checksummable
     ```

영향을 받는 모든 리소스 및 Geo 데이터 유형에 대해 단계를 반복하세요.

### 메시지: `"Error during verification","error":"File is not checksummable"` {#message-error-during-verificationerrorfile-is-not-checksummable}

오류 `"Error during verification","error":"File is not checksummable"`은 프라이머리 사이트의 불일치로 인해 발생합니다. GitLab 18.9부터 오류 메시지에 원인에 대한 추가 세부 정보가 포함됩니다:

- `File is not checksummable - file does not exist at: <path>`:  파일이 스토리지에서 누락되었습니다. 표시되는 경로는 누락된 파일을 식별하는 데 도움이 됩니다.
- `File is not checksummable - <ModelClass> <ID> is excluded from verification`:  레코드가 검증 범위에서 제외되었습니다.

[프라이머리 Geo 사이트에서 파일 누락](#message-the-file-is-missing-on-the-geo-primary-site)에서 제공하는 지시사항을 따르세요.

### 프라이머리 Geo 사이트에서 업로드의 검증 실패 {#failed-verification-of-uploads-on-the-primary-geo-site}

프라이머리 Geo 사이트에서 일부 업로드 검증이 `verification_checksum = nil`와 `verification_failure`이 ``Error during verification: undefined method `underscore' for NilClass:Class`` 또는 ``The model which owns this upload is missing.``를 포함하여 실패하면 고아 업로드 때문입니다. 업로드를 소유한 부모 레코드(업로드의 "모델")가 어떤 방식으로든 삭제되었지만 업로드 레코드는 여전히 존재합니다. 이는 일반적으로 "모델"의 대량 삭제를 구현하면서 관련 업로드 레코드의 대량 삭제를 잊어버린 애플리케이션의 버그로 인합니다. 따라서 이 검증 실패는 검증 실패가 아니라 Postgres의 잘못된 데이터로 인한 오류입니다.

프라이머리 Geo 사이트의 `geo.log` 파일에서 이 오류를 찾을 수 있습니다.

모델 레코드가 누락되었음을 확인하려면 프라이머리 Geo 사이트에서 Rake 작업을 실행할 수 있습니다:

```shell
sudo gitlab-rake gitlab:uploads:check
```

[Rails 콘솔](../../../operations/rails_console.md)에서 다음 스크립트를 실행하여 프라이머리 Geo 사이트의 이 업로드 레코드를 삭제할 수 있습니다:

```ruby
def delete_orphaned_uploads(dry_run: true)
  if dry_run
    p "This is a dry run. Upload rows will only be printed."
  else
    p "This is NOT A DRY RUN! Upload rows will be deleted from the DB!"
  end

  subquery = Geo::UploadState.where("(verification_failure LIKE 'Error during verification: The model which owns this upload is missing.%' OR verification_failure = 'Error during verification: undefined method `underscore'' for NilClass:Class') AND verification_checksum IS NULL")
  uploads = Upload.where(upload_state: subquery)
  p "Found #{uploads.count} uploads with a model that does not exist"

  uploads_deleted = 0
  begin
    uploads.each do |upload|

      if dry_run
        p upload
      else
        uploads_deleted=uploads_deleted + 1
        p upload.destroy!
      end
    rescue => e
      puts "checking upload #{upload.id} failed with #{e.message}"
    end
  end

  p "#{uploads_deleted} remote objects were destroyed." unless dry_run
end
```

이전 스크립트는 `delete_orphaned_uploads`라는 메서드를 정의하며 이를 호출하여 드라이 런을 수행할 수 있습니다:

```ruby
delete_orphaned_uploads(dry_run: true)
```

그리고 고아 업로드 행을 실제로 삭제하려면:

```ruby
delete_orphaned_uploads(dry_run: false)
```

### 리포지토리 동기화를 차단하는 고아 배타적 리스 키 {#orphaned-exclusive-lease-keys-blocking-repository-sync}

리포지토리 동기화는 배타적 리스 키가 고아가 되어 최대 8시간 동안 동기화 작업을 방지할 때 차단될 수 있습니다.

**Symptoms:**

- 리포지토리 동기화 차단: 영향을 받는 리포지토리의 복제 상태는 `pending` 및 `failed` 상태 사이에서 번갈아 나타납니다.
- `geo.log`에서 "배타적 리스를 획득할 수 없음" 메시지가 포함된 로그 라인의 개수가 증가했습니다.
- 영향을 받는 리포지토리에 대해 실행 중인 활성 동기화 작업이 없습니다.
- 리스가 만료될 때까지 최대 8시간 동안 단일 리포지토리에 영향을 미칩니다.

**Diagnosis:**

1. Geo 관리 인터페이스를 확인하여 리포지토리가 활발히 동기화되지 않는지 확인하세요.
1. `geo.log`에서 "배타적 리스를 획득할 수 없음" 메시지의 양이 증가했는지 확인하세요:

   ```shell
   grep "Cannot obtain an exclusive lease" /var/log/gitlab/geo/geo.log
   ```

1. 이 모든 로그 라인이 값이 `geo_sync_ssf_service:project_repository:<repository id>`인 `lease_key` 필드를 포함하는지 확인하세요. 여기서 `<repository id>`은 영향을 받는 리포지토리의 고유 ID입니다.
1. 영향을 받는 리포지토리에 대해 Sidekiq에서 실행 중인 활성 동기화 작업이 없는지 확인하세요.

**Workaround:**

> [!warning]
> 권장 방법은 8시간 리스 만료를 기다리는 것입니다. 수동 리스 릴리스는 즉시 동기화가 중요하고 활성 동기화 작업이 실행 중이지 않음을 확인한 경우에만 사용해야 합니다.

고아 리스 키를 수동으로 릴리스하려면:

1. [Rails 콘솔 세션을 시작](../../../operations/rails_console.md#starting-a-rails-console-session)하고 **세컨더리** 사이트에서 실행합니다.
1. 영향을 받는 리포지토리의 프로젝트 ID를 찾으세요(`<project-path>`를 실제 프로젝트 경로로 바꾸세요):

   ```ruby
   project = Project.find_by_full_path('<project-path>')
   project_id = project.id
   ```

1. 동일한 세션에서 고아 리스를 릴리스하세요:

   ```ruby
   replicator = Geo::ProjectRepositoryRegistry.find_by(project_id: project_id).replicator
   sync_service = Geo::FrameworkRepositorySyncService.new(replicator)
   uuid = Gitlab::ExclusiveLease.get_uuid(sync_service.lease_key)

   if uuid
     Gitlab::ExclusiveLease.cancel(sync_service.lease_key, uuid)
     puts "Lease released for project ID #{project_id}"
   else
     puts "No active lease found for project ID #{project_id}"
   end
   ```

1. 리스가 릴리스되었는지 확인하고 새 동기화를 트리거하세요:

   ```ruby
   replicator.sync
   ```

> [!note]
> 리스를 릴리스한 후 리포지토리 동기화가 정상 Geo 동기화 일정에 따라 재시도되거나 위에 표시된 대로 수동으로 동기화를 트리거할 수 있습니다.

### 오류: `Error syncing repository: 13:fatal: could not read Username` {#error-error-syncing-repository-13fatal-could-not-read-username}

`last_sync_failure` 오류 `Error syncing repository: 13:fatal: could not read Username for 'https://gitlab.example.com': terminal prompts disabled`는 Geo 작업 또는 페치 요청 중에 JWT 인증이 실패함을 나타냅니다.

먼저 시스템 클록이 동기화되어 있는지 확인하세요. [Health check Rake 작업](common.md#health-check-rake-task)을 실행하거나 `date`이 세컨더리 사이트의 모든 Sidekiq 노드와 프라이머리 사이트의 모든 Puma 노드에서 동일한지 수동으로 확인하세요.

시스템 클록이 동기화되면 JWT 토큰이 Git 페치가 두 개의 개별 HTTP 요청 사이에서 계산을 수행하는 동안 만료될 수 있습니다. [issue 464101](https://gitlab.com/gitlab-org/gitlab/-/issues/464101)을 참조하세요. 이는 GitLab 17.1.0, 17.0.5 및 16.11.7에서 수정되기까지 모든 GitLab 버전에 존재했습니다.

이 문제가 발생 중인지 확인하려면:

1. [Rails 콘솔](../../../operations/rails_console.md#starting-a-rails-console-session)의 코드에 몽키 패치를 하여 토큰의 유효 기간을 1분에서 10분으로 늘리세요. 세컨더리 사이트의 Rails 콘솔에서 이를 실행하세요:

   ```ruby
   module Gitlab; module Geo; class BaseRequest
     private
     def geo_auth_token(message)
       signed_data = Gitlab::Geo::SignedData.new(geo_node: requesting_node, validity_period: 10.minutes).sign_and_encode_data(message)

       "#{GITLAB_GEO_AUTH_TOKEN_TYPE} #{signed_data}"
     end
   end;end;end
   ```

1. 동일한 Rails 콘솔에서 영향을 받는 프로젝트를 재동기화하세요:

   ```ruby
   Project.find_by_full_path('<mygroup/mysubgroup/myproject>').replicator.resync
   ```

1. 동기화 상태를 살펴보세요:

   ```ruby
   Project.find_by_full_path('<mygroup/mysubgroup/myproject>').replicator.registry
   ```

1. `last_sync_failure`이 더 이상 `fatal: could not read Username` 오류를 포함하지 않으면 이 문제의 영향을 받는 것입니다. 상태는 이제 `2`이어야 하며, 이는 동기화되었음을 의미합니다. 그렇다면 수정 사항이 포함된 GitLab 버전으로 업그레이드해야 합니다. [issue 466681](https://gitlab.com/gitlab-org/gitlab/-/issues/466681)에 찬성표를 하거나 댓글을 달고 싶을 수도 있습니다. 이는 이 문제의 심각성을 줄였을 것입니다.

문제를 해결하려면 세컨더리 사이트의 모든 Sidekiq 노드에 핫 패치를 적용하여 JWT 만료 시간을 연장해야 합니다:

1. `/opt/gitlab/embedded/service/gitlab-rails/ee/lib/gitlab/geo/signed_data.rb`을 편집하세요.
1. `Gitlab::Geo::SignedData.new(geo_node: requesting_node)`을 찾고 `, validity_period: 10.minutes`을 추가하세요:

   ```diff
   - Gitlab::Geo::SignedData.new(geo_node: requesting_node)
   + Gitlab::Geo::SignedData.new(geo_node: requesting_node, validity_period: 10.minutes)
   ```

1. Sidekiq을 다시 시작하세요:

   ```shell
   sudo gitlab-ctl restart sidekiq
   ```

1. 수정 사항이 포함된 버전으로 업그레이드하지 않으면 모든 GitLab 업그레이드 후 이 해결 방법을 반복해야 합니다.

### 오류: `Error syncing repository: 13:creating repository: cloning repository: exit status 128` {#error-error-syncing-repository-13creating-repository-cloning-repository-exit-status-128}

이 오류는 성공적으로 동기화되지 않는 프로젝트에 대해 표시될 수 있습니다.

리포지토리 생성 중 종료 코드 128은 Git이 복제 중 치명적인 오류가 발생했음을 의미합니다. 이는 리포지토리 손상, 네트워크 문제, 인증 문제, 리소스 제한 또는 프로젝트에 관련된 Git 리포지토리가 없기 때문일 수 있습니다. 이러한 실패의 구체적인 원인에 대한 자세한 내용은 Gitaly 로그에서 확인할 수 있습니다.

확실하지 않을 때는 [`git fsck` 명령을 명령줄에서 수동으로 실행](../../../repository_checks.md#run-a-check-using-the-command-line)하여 프라이머리 사이트의 소스 리포지토리에 대해 무결성 검사를 실행하세요.

#### 로드 밸런서에서 HTTP 504로 인한 종료 상태 128 {#exit-status-128-caused-by-http-504-from-a-load-balancer}

큰 리포지토리의 경우 세컨더리 사이트의 Gitaly 로그에 다음이 표시될 수 있습니다:

```plaintext
error: RPC failed; HTTP 504 curl 22 The requested URL returned error: 504
fatal: expected 'packfile'
```

이 오류는 로드 밸런서 또는 프라이머리 사이트 앞의 프록시가 Git 클론 packfile 전송 중에 연결을 종료할 때 발생합니다. 이는 일반적으로 기본 유휴 시간 초과가 60초인 AWS Application Load Balancers(ALB)에서 발생합니다. 데이터 전송이 시작되기 전에 packfile을 준비하는 데 시간이 걸리는 큰 리포지토리의 경우 ALB가 데이터를 보내기 전에 연결을 끊고 오류를 트리거할 수 있습니다.

이 문제를 해결하려면:

1. 프라이머리 사이트 앞의 로드 밸런서에서 유휴 시간 초과를 증가시켜 큰 리포지토리 클론을 수용하세요. AWS ALB의 경우 AWS Management Console의 로드 밸런서 속성에서 유휴 시간 초과 설정을 업데이트하세요.
1. 실패한 레지스트리를 재설정하세요:
   1. [Rails 콘솔 세션을 시작](../../../operations/rails_console.md#starting-a-rails-console-session)하고 **세컨더리** 사이트에서 실행합니다.
   1. 영향을 받는 리포지토리를 식별하고 재설정하세요:

      ```ruby
      project_ids = Geo::ProjectRepositoryRegistry.failed
                      .where("last_sync_failure LIKE '%exit status 128%'")
                      .pluck(:project_id)

      puts "Found #{project_ids.count} repositories failing with exit status 128"

      # state: 0 sets the registry back to pending so Geo retries the sync
      Geo::ProjectRepositoryRegistry.where(project_id: project_ids).update_all(
        state: 0,
        retry_count: 0,
        retry_at: nil,
        last_sync_failure: nil
      )

      puts "Reset #{project_ids.count} registries to pending"
      ```

1. Geo가 자동으로 동기화를 재시도하기를 기다리거나 [수동으로 복제를 재시도](#manually-retry-replication-or-verification)하세요.

### 오류: `gitmodulesUrl: disallowed submodule url` {#error-gitmodulesurl-disallowed-submodule-url}

일부 프로젝트 리포지토리는 오류 `Error syncing repository: 13:creating repository: cloning repository: exit status 128`와 함께 지속적으로 동기화에 실패합니다. 그러나 일부 리포지토리의 경우 Gitaly 로그의 특정 오류 메시지가 다릅니다: `gitmodulesUrl: disallowed submodule url`. 이 실패는 `.gitmodules` 파일에 잘못된 서브모듈 URL이 포함되어 있을 때 발생합니다.

**Root Cause:** 이 문제는 **historical commits**에 `.gitmodules` 파일이 포함되어 있어 URL이 잘못되어 있기 때문입니다. 이 문제는 Geo가 프라이머리에서 세컨더리로 리포지토리를 복제하려고 할 때 실행되는 Git의 일관성 검사(`git fsck`)에서 발생합니다.

문제는 리포지토리의 커밋 히스토리에 있습니다. `.gitmodules` 파일의 서브모듈 URL은 경로에 `:` 대신 `/`을 사용하여 잘못된 형식을 포함합니다:

- 잘못됨: `https://example.gitlab.com:group/project.git`
- 올바름: `https://example.gitlab.com/group/project.git`

**Why this breaks Geo synchronization:**

1. **Git's strict validation**:  GitLab 17.0 및 최신 Git 버전부터 Git은 복제 작업 중에 더 엄격한 `fsck` 검사를 수행합니다.
1. **Historical data persistence**:  현재 `.gitmodules` 파일이 올바르더라도 Git은 모든 과거 버전을 리포지토리의 "blob"으로 저장합니다.
1. **Clone-time failure**:  Geo가 리포지토리를 복제하려고 할 때 Git의 `fsck`은 **all objects**(과거 포함)를 검사하고 잘못된 형식의 URL을 발견하면 실패합니다.
1. **Complete sync failure**:  전체 복제 작업이 실패하여 리포지토리가 세컨더리 사이트에 도달할 수 없게 됩니다.

**Important:** 현재 `.gitmodules` 파일을 편집하면 **not**. 왜냐하면 문제가 있는 데이터가 현재 버전뿐만 아니라 리포지토리의 Git 히스토리에 있기 때문입니다.

이 문제는 GitLab 17.0 이상에서 알려져 있으며, 더 엄격한 리포지토리 일관성 검사의 결과입니다. 이 새로운 동작은 이 검사가 추가된 Git 자체의 변경에서 비롯됩니다. 이는 GitLab Geo 또는 Gitaly에 특정되지 않습니다. 자세한 내용은 [issue 468560](https://gitlab.com/gitlab-org/gitlab/-/issues/468560)을 참조하세요.

#### 해결 방법 {#workaround}

1. **Backup projects**

   계속하기 전에 [프로젝트 내보내기 옵션](../../../../user/project/settings/import_export.md)을 사용하여 프로젝트를 미리 백업하도록 하세요.

1. **Identify problematic blob IDs**

   영향을 받는 각 프로젝트에 대해 다음 방법 중 하나를 사용하여 문제가 되는 blob ID를 식별하세요:

   - `git fsck`을 사용하세요:  리포지토리를 복제한 후 `git fsck`을 실행하여 문제를 확인하세요:

     ```shell
     git clone https://example.gitlab.com/group/project.git
     cd project
     git fsck
     ```

     출력은 문제가 되는 blob을 표시합니다:

     ```plaintext
     Checking object directories: 100% (256/256), done.
     error in blob <SHA>: gitmodulesUrl: disallowed submodule url: https://example.gitlab.com:group/project.git
     Checking objects: 100% (12/12), done.
     ```

   - Gitaly 로그를 확인하세요. `gitmodulesUrl`을 포함하는 오류 메시지를 찾아 특정 blob SHA를 찾으세요.

1. **Blob 제거**

   영향을 받는 각 프로젝트에 대해 이전 단계에서 식별된 [문제가 되는 blob ID를 제거](../../../../user/project/repository/repository_size.md#remove-blobs)하세요.

   **Important limitation:** 이 리포지토리 중 일부가 포크 네트워크의 일부인 경우 blob 제거 방법이 작동하지 않을 수 있습니다(객체 풀에 포함된 blob은 이런 방식으로 제거할 수 없습니다).

1. **Fix .gitmodules invalid URLs if required**

   영향을 받는 각 리포지토리의 `.gitmodules` 파일 상태를 확인하세요.

   `.gitmodules`에 `https://example.gitlab.com:foo/bar.git` 대신 `https://example.gitlab.com/foo/bar.git`과 같은 잘못된 URL이 여전히 포함되어 있으면 고객은 다음을 수행해야 합니다:

   - `.gitmodules` 파일의 URL을 수정하세요.
   - 올바른 URL이 포함된 커밋을 푸시하세요.

> [!warning]
> 수정 후 영향을 받는 프로젝트에서 작업하는 모든 개발자는 현재 로컬 복사본을 제거하고 새 리포지토리를 복제해야 합니다. 그렇지 않으면 변경 사항을 푸시할 때 위반 blob을 다시 도입할 수 있습니다.

### 오류: `fetch remote: signal: terminated: context deadline exceeded` 정확히 3시간에 {#error-fetch-remote-signal-terminated-context-deadline-exceeded-at-exactly-3-hours}

Git 페치가 Git 리포지토리를 동기화하는 동안 정확히 3시간에 실패하는 경우:

1. `/etc/gitlab/gitlab.rb`을 편집하여 Git 시간 초과를 기본값 10800초에서 증가시키세요:

   ```ruby
   # Git timeout in seconds
   gitlab_rails['gitlab_shell_git_timeout'] = 21600
   ```

1. GitLab을 다시 구성하세요:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

### 오류 `Failed to open TCP connection to localhost:5000` 레지스트리 복제를 구성할 때 세컨더리에서 {#error-failed-to-open-tcp-connection-to-localhost5000-on-secondary-when-configuring-registry-replication}

세컨더리 사이트에서 컨테이너 레지스트리 복제를 구성할 때 다음 오류가 발생할 수 있습니다:

```plaintext
Failed to open TCP connection to localhost:5000 (Connection refused - connect(2) for \"localhost\" port 5000)"
```

세컨더리 사이트에서 컨테이너 레지스트리가 활성화되지 않은 경우 발생합니다. 수정하려면 컨테이너 레지스트리가 [세컨더리 사이트에 활성화](../../../packages/container_registry.md#enable-the-container-registry)되어 있는지 확인하세요. [Let's Encrypt 통합이 비활성화](https://docs.gitlab.com/omnibus/settings/ssl/#configure-https-manually) 되어 있으면 컨테이너 레지스트리도 비활성화되며 [수동으로 구성](../../../packages/container_registry.md#configure-container-registry-under-its-own-domain)해야 합니다.

### 오류: `Verification timed out after 28800` {#error-verification-timed-out-after-28800}

**Possible Root Cause:** 다양한 레지스트리 유형에서 검증 충돌을 야기하는 중복 레지스트리 레코드.

**Diagnosis:**

1. [Rails 콘솔 세션을 시작](../../../operations/rails_console.md#starting-a-rails-console-session)하고 **세컨더리** 사이트에서 실행합니다.
1. 다양한 유형의 중복 레지스트리를 확인하세요:

   ```ruby
   # Check for duplicate upload registries
   upload_ids = Geo::UploadRegistry.group(:file_id).having('COUNT(*) > 1').pluck(:file_id)
   puts "Duplicate upload IDs count: #{upload_ids.size}"
   puts 'Duplicate Upload IDs:', upload_ids

   # Check for duplicate job artifact registries
   artifact_ids = Geo::JobArtifactRegistry.group(:artifact_id).having('COUNT(*) > 1').pluck(:artifact_id)
   puts "Duplicate artifact IDs count: #{artifact_ids.size}"
   puts 'Duplicate Artifact IDs:', artifact_ids

   # Check for duplicate package file registries
   package_file_ids = Geo::PackageFileRegistry.group(:package_file_id).having('COUNT(*) > 1').pluck(:package_file_id)
   puts "Duplicate package file IDs count: #{package_file_ids.size}"
   puts 'Duplicate Package File IDs:', package_file_ids

   # Check for duplicate LFS object registries
   lfs_object_ids = Geo::LfsObjectRegistry.group(:lfs_object_id).having('COUNT(*) > 1').pluck(:lfs_object_id)
   puts "Duplicate LFS object IDs count: #{lfs_object_ids.size}"
   puts 'Duplicate LFS Object IDs:', lfs_object_ids

   # Check for duplicate pages deployment registries
   pages_deployment_ids = Geo::PagesDeploymentRegistry.group(:pages_deployment_id).having('COUNT(*) > 1').pluck(:pages_deployment_id)
   puts "Duplicate pages deployment IDs count: #{pages_deployment_ids.size}"
   puts 'Duplicate Pages Deployment IDs:', pages_deployment_ids

   # Check for duplicate terraform state version registries
   terraform_state_ids = Geo::TerraformStateVersionRegistry.group(:terraform_state_version_id).having('COUNT(*) > 1').pluck(:terraform_state_version_id)
   puts "Duplicate terraform state version IDs count: #{terraform_state_ids.size}"
   puts 'Duplicate Terraform State Version IDs:', terraform_state_ids
   ```

**Resolution:**

1. [Rails 콘솔 세션을 시작](../../../operations/rails_console.md#starting-a-rails-console-session)하고 **세컨더리** 사이트에서 실행합니다.
1. 영향을 받는 각 유형에 대해 중복 레지스트리 항목을 제거하세요:

   ```ruby
   # Remove duplicate upload registries
   upload_ids = Geo::UploadRegistry.group(:file_id).having('COUNT(*) > 1').pluck(:file_id)
   if upload_ids.any?
     Geo::UploadRegistry.where(file_id: upload_ids).delete_all
     puts "Removed #{upload_ids.size} duplicate upload registry entries"
   end

   # Remove duplicate job artifact registries
   artifact_ids = Geo::JobArtifactRegistry.group(:artifact_id).having('COUNT(*) > 1').pluck(:artifact_id)
   if artifact_ids.any?
     Geo::JobArtifactRegistry.where(artifact_id: artifact_ids).delete_all
     puts "Removed #{artifact_ids.size} duplicate job artifact registry entries"
   end

   # Remove duplicate package file registries
   package_file_ids = Geo::PackageFileRegistry.group(:package_file_id).having('COUNT(*) > 1').pluck(:package_file_id)
   if package_file_ids.any?
     Geo::PackageFileRegistry.where(package_file_id: package_file_ids).delete_all
     puts "Removed #{package_file_ids.size} duplicate package file registry entries"
   end

   # Remove duplicate LFS object registries
   lfs_object_ids = Geo::LfsObjectRegistry.group(:lfs_object_id).having('COUNT(*) > 1').pluck(:lfs_object_id)
   if lfs_object_ids.any?
     Geo::LfsObjectRegistry.where(lfs_object_id: lfs_object_ids).delete_all
     puts "Removed #{lfs_object_ids.size} duplicate LFS object registry entries"
   end

   # Remove duplicate pages deployment registries
   pages_deployment_ids = Geo::PagesDeploymentRegistry.group(:pages_deployment_id).having('COUNT(*) > 1').pluck(:pages_deployment_id)
   if pages_deployment_ids.any?
     Geo::PagesDeploymentRegistry.where(pages_deployment_id: pages_deployment_ids).delete_all
     puts "Removed #{pages_deployment_ids.size} duplicate pages deployment registry entries"
   end

   # Remove duplicate terraform state version registries
   terraform_state_ids = Geo::TerraformStateVersionRegistry.group(:terraform_state_version_id).having('COUNT(*) > 1').pluck(:terraform_state_version_id)
   if terraform_state_ids.any?
     Geo::TerraformStateVersionRegistry.where(terraform_state_version_id: terraform_state_ids).delete_all
     puts "Removed #{terraform_state_ids.size} duplicate terraform state version registry entries"
   end
   ```

1. 모든 레지스트리 유형에서 정리를 확인하세요:

   ```ruby
   # Verify no remaining duplicates
   upload_duplicates = Geo::UploadRegistry.group(:file_id).having('COUNT(*) > 1').count
   artifact_duplicates = Geo::JobArtifactRegistry.group(:artifact_id).having('COUNT(*) > 1').count
   package_duplicates = Geo::PackageFileRegistry.group(:package_file_id).having('COUNT(*) > 1').count
   lfs_duplicates = Geo::LfsObjectRegistry.group(:lfs_object_id).having('COUNT(*) > 1').count
   pages_duplicates = Geo::PagesDeploymentRegistry.group(:pages_deployment_id).having('COUNT(*) > 1').count
   terraform_duplicates = Geo::TerraformStateVersionRegistry.group(:terraform_state_version_id).having('COUNT(*) > 1').count

   puts "Remaining duplicates:"
   puts "  Uploads: #{upload_duplicates.size}"
   puts "  Job Artifacts: #{artifact_duplicates.size}"
   puts "  Package Files: #{package_duplicates.size}"
   puts "  LFS Objects: #{lfs_duplicates.size}"
   puts "  Pages Deployments: #{pages_duplicates.size}"
   puts "  Terraform State Versions: #{terraform_duplicates.size}"
   ```

### 오류: `Checksum does not match the primary checksum` {#error-checksum-does-not-match-the-primary-checksum}

**Possible Root Cause:** 체크섬 불일치를 야기하는 리포지토리 또는 컨테이너 레지스트리 검증 간격 변경.

**Diagnosis:**

1. [Rails 콘솔 세션을 시작](../../../operations/rails_console.md#starting-a-rails-console-session)하고 **세컨더리** 사이트에서 실행합니다.
1. 실패한 리포지토리 또는 컨테이너 레지스트리를 확인하세요:

   ```ruby
   failed_repos = Geo::ProjectRepositoryRegistry.failed.limit(100)
   failed_repos.each do |repo|
     puts "Project ID: #{repo.project_id}"
     puts "Primary checksum: #{repo.verification_checksum_mismatched}"
     puts "Secondary checksum: #{repo.verification_checksum}"
     puts "Error: #{repo.last_sync_failure}"
     puts "---"
   end
   ```

   ```ruby
   failed_container_repos = Geo::ContainerRepositoryRegistry.failed.limit(100)
   failed_container_repos.each do |repo|
     puts "Container Repo Id: #{repo.model_record_id}"
     puts "Primary checksum: #{repo.verification_checksum_mismatched}"
     puts "Secondary checksum: #{repo.verification_checksum}"
     puts "Error: #{repo.last_sync_failure}"
     puts "---"
   end
   ```

**Resolution:**

1. [Rails 콘솔 세션을 시작](../../../operations/rails_console.md#starting-a-rails-console-session)하고 **프라이머리** 사이트에서 실행합니다.
1. 특정 프로젝트 또는 컨테이너 레지스트리에 대한 재검증을 강제합니다:

   ```ruby
   project_ids = [1, 2, 3] # Replace with actual failing project IDs

   project_ids.each do |project_id|
     project = Project.find(project_id)
     puts "Reverifying project: #{project.full_path}"

     project_state = project.project_state
     project_state.update!(verification_state: 0)

     puts "Project #{project_id} marked for reverification"
   end
   ```

   ```ruby
   container_repo_ids = [1, 2, 3]

   container_repo_ids.each do |repo_id|
     container_repo = ContainerRepository.find(repo_id)
     puts "Reverifying container repository: #{container_repo.path}"

     state = container_repo.container_repository_state
     state.update!(verification_state: 0)

     puts "Container Repo #{repo_id} marked for reverification"
   end
   ```

### `Error during verification: File is not checksummable`에 대한 객체 유형별 문제 해결 {#object-type-specific-troubleshooting-for-error-during-verification-file-is-not-checksummable}

다양한 Geo 데이터 유형은 고유한 특성과 공통 실패 패턴을 가지고 있습니다. 이 섹션에서는 특정 객체 유형에 대한 타겟팅된 문제 해결을 제공합니다.

#### 업로드 {#uploads}

**Diagnosis:**

1. [Rails 콘솔 세션을 시작](../../../operations/rails_console.md#starting-a-rails-console-session)하고 **프라이머리** 사이트에서 실행합니다.
1. 누락된 파일이 있는 업로드를 식별합니다. `limit(5)`을 필요에 따라 업데이트하여 더 많은 결과를 확인하세요:

   ```ruby
   checksummable_failures = Upload.verification_failed
                                   .where("verification_failure LIKE '%File is not checksummable%'")

   puts "Found #{checksummable_failures.count} uploads with missing files"

   checksummable_failures.limit(5).each_with_index do |record, index|
     puts "Record #{index + 1}:"
     puts "  ID: #{record.id}"
     puts "  Path: #{record.path}"
     puts "  Model: #{record.model_type} (ID: #{record.model_id})"
     puts "  Created: #{record.created_at}"
     puts "---"
   end
   ```

**Resolution:**

이 실패를 해결하려면 [프라이머리 Geo 사이트의 업로드 검증 실패](#failed-verification-of-uploads-on-the-primary-geo-site)의 단계를 따르세요.

#### 페이지 배포 {#pages-deployments}

**Diagnosis:**

1. [Rails 콘솔 세션을 시작](../../../operations/rails_console.md#starting-a-rails-console-session)하고 **프라이머리** 사이트에서 실행합니다.
1. 문제가 되는 페이지 배포를 검사합니다:

   ```ruby
   checksummable_failures = PagesDeployment.verification_failed
                                           .where("verification_failure LIKE '%File is not checksummable%'")

   checksummable_failures.each_with_index do |record, index|
     puts "Record #{index + 1}:"
     puts "  ID: #{record.id}"
     puts "  Project: #{record.project.full_path}"
     puts "  Created: #{record.created_at}"
     puts "  File exists: #{record.file.exists?}"
     puts "---"
   end
   ```

**Resolution:**

> [!warning]
> 페이지 배포 레코드를 삭제하기 전에 최근 작업 백업이 있는지 확인하세요. 팀에 이 배포가 제거해도 안전한지 확인하도록 조율하세요.

1. [Rails 콘솔 세션을 시작](../../../operations/rails_console.md#starting-a-rails-console-session)하고 **프라이머리** 사이트에서 실행합니다.
1. 팀에서 배포를 제거해도 안전하다고 확인한 후:

   ```ruby
   def destroy_pages_deployments_not_checksummable(dry_run: true)
     deployments = PagesDeployment.verification_failed.where("verification_failure LIKE '%File is not checksummable%'")
     puts "Found #{deployments.count} pages deployments that failed verification with 'File is not checksummable'."

     if dry_run
       puts "DRY RUN - No changes made"
       deployments.each { |d| puts "Would remove: ID #{d.id}, Project: #{d.project.full_path}" }
       return
     end

     puts "Enter 'y' to continue: "
     prompt = STDIN.gets.chomp
     if prompt != 'y'
       puts "Exiting without action..."
       return
     end

     puts "Destroying all..."
     deployments.destroy_all
     puts "Done!"
   end

   # Run in dry run mode first
   destroy_pages_deployments_not_checksummable(dry_run: true)
   ```

#### LFS 객체 {#lfs-objects}

**Diagnosis:**

1. [Rails 콘솔 세션을 시작](../../../operations/rails_console.md#starting-a-rails-console-session)하고 **프라이머리** 사이트에서 실행합니다.
1. 문제가 되는 LFS 객체를 검사합니다:

   ```ruby
   checksummable_failures = LfsObject.verification_failed
                                     .where("verification_failure LIKE '%File is not checksummable%'")

   checksummable_failures.each_with_index do |record, index|
     puts "Record #{index + 1}:"
     puts "  OID: #{record.oid}"
     puts "  Size: #{record.size} bytes"
     puts "  File Store: #{record.file_store}"
     puts "  Created: #{record.created_at}"

     # Show associated projects
     associations = record.lfs_objects_projects.includes(:project)
     puts "  Associated projects (#{associations.count}):"
     associations.each do |assoc|
       project = assoc.project
       if project
         puts "    - #{project.full_path}"
       else
         puts "    - Project ID: #{assoc.project_id} (not found)"
       end
     end
     puts "---"
   end
   ```

**Resolution:**

> [!warning]
> LFS 객체를 제거하면 이를 참조하는 모든 프로젝트에 영향을 미칩니다. 삭제 전에 백업이 있는지 확인하고 프로젝트 유지 관리자에게 조율하세요.

1. [Rails 콘솔 세션을 시작](../../../operations/rails_console.md#starting-a-rails-console-session)하고 **프라이머리** 사이트에서 실행합니다.
1. 누락된 파일이 있는 LFS 객체를 제거합니다:

   ```ruby
   def destroy_lfs_not_checksummable(dry_run: true)
     lfs_objects = LfsObject.verification_failed.where("verification_failure like '%File is not checksummable%'")
     puts "Found #{lfs_objects.count} LFS objects that failed verification with 'File is not checksummable'."

     if dry_run
       puts "DRY RUN - No changes made"
       lfs_objects.each { |obj| puts "Would remove: OID #{obj.oid}, Size: #{obj.size}" }
       return
     end

     puts "Enter 'y' to continue with deletion: "
     prompt = STDIN.gets.chomp
     if prompt != 'y'
       puts "Exiting without action..."
       return
     end

     puts "Destroying all..."
     lfs_objects.each do |lfs_object|
       lfs_object.lfs_objects_projects.destroy_all
       lfs_object.destroy!
     end
     puts "Done!"
   end

   # Run in dry run mode first
   destroy_lfs_not_checksummable(dry_run: true)
   ```

#### 작업 아티팩트 {#job-artifacts}

**Diagnosis:**

1. [Rails 콘솔 세션을 시작](../../../operations/rails_console.md#starting-a-rails-console-session)하고 **프라이머리** 사이트에서 실행합니다.
1. 누락된 파일이 있는 아티팩트를 확인합니다:

   ```ruby
   failed_artifacts = Ci::JobArtifact.verification_failed.where("verification_failure LIKE '%File is not checksummable%'")

   failed_artifacts.each do |registry|
     artifact = Ci::JobArtifact.find_by(id: registry.id)
     if artifact
       puts "Artifact ID: #{artifact.id}"
       puts "Job ID: #{artifact.job_id}"
       puts "Project ID: #{artifact.project_id}"
       puts "File exists: #{artifact.file.exists?}"
       puts "File path: #{artifact.file.path}"
     else
       puts "Artifact ID #{artifact.id} not found in database"
     end
     puts "---"
   end
   ```

**Resolution:**

> [!warning]
> 작업 아티팩트 레코드를 삭제하기 전에 최근 작업 백업이 있는지 확인하세요. 팀에 이 아티팩트가 제거해도 안전한지 확인하도록 조율하세요.

1. [Rails 콘솔 세션을 시작](../../../operations/rails_console.md#starting-a-rails-console-session)하고 **프라이머리** 사이트에서 실행합니다.
1. 누락된 파일이 있는 아티팩트를 정리합니다:

   ```ruby
   def cleanup_missing_artifacts(dry_run: true)
     missing_file_artifacts = []

     Ci::JobArtifact.find_each do |artifact|
       unless artifact.file.exists?
         missing_file_artifacts << artifact.id
         puts "Missing file for artifact #{artifact.id}" if dry_run
       end
     end

     puts "Found #{missing_file_artifacts.size} artifacts with missing files"

     unless dry_run
       Ci::JobArtifact.where(id: missing_file_artifacts).destroy_all
       puts "Removed #{missing_file_artifacts.size} artifacts with missing files"
     end
   end

   # Run in dry run mode first
   cleanup_missing_artifacts(dry_run: true)
   ```

#### 패키지 파일 {#package-files}

이 오류는 프라이머리 사이트의 스토리지에서 패키지 파일이 누락된 경우 발생합니다.

영향을 받는 패키지 파일을 식별하려면:

1. [Rails 콘솔 세션을 시작](../../../operations/rails_console.md#starting-a-rails-console-session)하고 **프라이머리** 사이트에서 실행합니다.
1. 영향을 받는 레코드를 쿼리합니다. `limit(5)`을 필요에 따라 업데이트하여 더 많은 결과를 확인하세요:

   ```ruby
   checksummable_failures = Packages::PackageFile.verification_failed
                                                  .where("verification_failure LIKE '%File is not checksummable%'")

   puts "Found #{checksummable_failures.count} package files with missing files"

   checksummable_failures.limit(5).each_with_index do |record, index|
     puts "Record #{index + 1}:"
     puts "  ID: #{record.id}"
     puts "  File Name: #{record.file_name}"
     puts "  Package ID: #{record.package_id}"
     puts "  Created: #{record.created_at}"
     puts "---"
   end
   ```

> [!warning]
> 패키지 파일 레코드를 삭제하기 전에 최근 작업 백업이 있는지 확인하세요. 팀에 이 패키지 파일이 제거해도 안전한지 확인하도록 조율하세요.

영향을 받는 패키지 파일을 제거하려면:

1. [Rails 콘솔 세션을 시작](../../../operations/rails_console.md#starting-a-rails-console-session)하고 **프라이머리** 사이트에서 실행합니다.
1. 영향을 받는 레코드를 삭제합니다:

   ```ruby
   def destroy_packages_not_checksummable(dry_run: true)
     packages = Packages::PackageFile.verification_failed
                  .where("packages_package_file_states.verification_failure LIKE '%File is not checksummable%'")
     puts "Found #{packages.count} packages that failed verification with 'File is not checksummable'."

     if dry_run
       puts "DRY RUN - No changes made"
       packages.each { |p| puts "Would remove: ID #{p.id}, File: #{p.file_name}" }
       return
     end

     puts "Enter 'y' to continue: "
     prompt = STDIN.gets.chomp
     if prompt != 'y'
       puts "Exiting without action..."
       return
     end

     puts "Destroying all..."
     packages.destroy_all
     puts "Done!"
   end

   # Run in dry run mode first
   destroy_packages_not_checksummable(dry_run: true)
   ```

#### 파이프라인 아티팩트 {#pipeline-artifacts}

**Diagnosis:**

1. [Rails 콘솔 세션을 시작](../../../operations/rails_console.md#starting-a-rails-console-session)하고 **프라이머리** 사이트에서 실행합니다.
1. 누락된 파일이 있는 아티팩트를 확인합니다:

   ```ruby
   failed_pipeline_artifacts = Ci::PipelineArtifact.verification_failed.where("verification_failure LIKE '%checksummable%'")

   failed_pipeline_artifacts.each do |registry|
     artifact = Ci::PipelineArtifact.find_by(id: registry.id)
     if artifact
       puts "Artifact ID: #{artifact.id}"
       puts "Pipeline ID: #{artifact.pipeline_id}"
       puts "Project ID: #{artifact.project_id}"
       puts "File exists: #{artifact.file.exists?}"
       puts "File path: #{artifact.file.path}"
     else
       puts "Artifact ID #{artifact.id} not found in database"
     end
     puts "---"
   end
   ```

**Resolution:**

> [!warning]
> 파이프라인 아티팩트 레코드를 삭제하기 전에 최근 작업 백업이 있는지 확인하세요. 팀에 이 아티팩트가 제거해도 안전한지 확인하도록 조율하세요.

1. [Rails 콘솔 세션을 시작](../../../operations/rails_console.md#starting-a-rails-console-session)하고 **프라이머리** 사이트에서 실행합니다.
1. 누락된 파일이 있는 파이프라인 아티팩트를 제거합니다:

   ```ruby
   def destroy_pipeline_artifacts_not_checksummable
     artifacts = Ci::PipelineArtifact.verification_failed.where("verification_failure like '%File is not checksummable%'")
     puts "Found #{artifacts.count} pipeline artifacts that failed verification with 'File is not checksummable'."
     puts "Enter 'y' to continue: "
     prompt = STDIN.gets.chomp
     if prompt != 'y'
       puts "Exiting without action..."
       return
     end

     puts "Destroying all..."
     artifacts.destroy_all
     puts "Done!"
   end

   destroy_pipeline_artifacts_not_checksummable
   ```

### 시간 초과로 인해 LFS 객체가 동기화되지 않음 {#lfs-objects-out-of-sync-due-to-timeout}

LFS 객체는 큰 파일이 기본 8시간 blob 다운로드 시간 초과를 초과할 때 `Sync timed out after 28800`로 동기화에 실패할 수 있습니다.

#### blob 다운로드 시간 초과 증가 {#increase-the-blob-download-timeout}

GitLab 18.10 이상에서는 blob 다운로드 시간 초과가 Geo 사이트당 구성 가능합니다.

blob 다운로드 시간 초과를 증가시키려면 `<secondary_id>`을 세컨더리 사이트 ID로, `<token>`을 관리 API 토큰으로 바꾸세요:

```shell
curl --header "PRIVATE-TOKEN: <token>" \
  --request PUT \
  --data '{"blob_download_timeout": 43200}' \
  "https://gitlab.example.com/api/v4/geo_nodes/<secondary_id>"
```

시간 초과를 증가시킨 후 Geo가 자동으로 재시도할 때까지 기다리거나 [수동으로 복제를 재시도](#manually-retry-replication-or-verification)하세요.

#### 시간 초과된 LFS 객체 식별 및 검증 {#identify-and-validate-timed-out-lfs-objects}

시간 초과를 증가시킨 후에도 LFS 객체가 계속 실패하면 영향을 받는 객체를 식별하고 프라이머리 사이트에 파일이 있는지 확인하세요.

1. **세컨더리** 사이트에서 영향을 받는 객체를 식별하세요:

   ```ruby
   registries = Geo::LfsObjectRegistry.failed.where("last_sync_failure LIKE '%timed out%'")

   puts "Found #{registries.count} LFS objects that failed with a timeout"
   registries.each do |registry|
     lfs_object = LfsObject.find_by(id: registry.lfs_object_id)
     size_gb = lfs_object ? (lfs_object.size / 1024.0 / 1024.0 / 1024.0).round(2) : 'unknown'
     puts "  Registry ID: #{registry.id}, LFS Object ID: #{registry.lfs_object_id}, Size: #{size_gb} GB, Failure: #{registry.last_sync_failure}, Retries: #{registry.retry_count}"
   end
   ```

1. 이전 단계의 `lfs_object_id` 값을 사용하여 **프라이머리** 사이트에 파일이 있는지 확인하세요:

   ```ruby
   [lfs_object_id1, lfs_object_id2, lfs_object_id3].each do |id|
     lfs_object = LfsObject.find_by(id: id)

     if lfs_object.nil?
       puts "LFS Object ID: #{id} not found"
       next
     end

     puts "LFS Object ID: #{id}, Size: #{(lfs_object.size / 1024.0 / 1024.0 / 1024.0).round(2)} GB, File exists?: #{lfs_object.file.exists?}, Path: #{lfs_object.file.path}"
   end
   ```

#### 프라이머리에서 세컨더리로 파일 복사 {#copy-files-from-primary-to-secondary}

파일이 프라이머리에는 있지만 세컨더리에는 없으면 이전 단계의 경로를 사용하여 파일을 찾으세요:

- 객체 스토리지의 경우 경로는 구성된 LFS 버킷 내의 객체 키입니다. 프라이머리 버킷에서 파일을 찾아 다운로드한 다음 세컨더리 버킷의 동일한 키에 업로드하세요.
- 로컬 스토리지의 경우 경로는 프라이머리 사이트의 `/var/opt/gitlab/gitlab-rails/shared/lfs-objects/`에 상대적입니다. 세컨더리 사이트에서 동일한 상대 경로로 파일을 복사하세요.

#### LFS 객체를 동기화됨으로 표시 {#mark-lfs-objects-as-synced}

파일이 세컨더리 사이트에 있으면 동기화됨으로 표시하고 검증을 트리거합니다:

```ruby
[lfs_object_id1, lfs_object_id2, lfs_object_id3].each do |lfs_object_id|
  begin
    registry = Geo::LfsObjectRegistry.find_by(lfs_object_id: lfs_object_id)

    if registry.nil?
      puts "Registry not found for LFS Object #{lfs_object_id}"
      next
    end

    registry.update!(
      state: 2,
      success: true,
      last_synced_at: Time.current,
      last_sync_failure: nil,
      retry_count: 0,
      retry_at: nil
    )
    registry.replicator.verify

    puts "LFS Object #{lfs_object_id}: marked as synced and verification triggered"
  rescue => e
    puts "Error processing LFS Object #{lfs_object_id}: #{e.message}"
  end
end
```

### 오류: `Projects - Error during verification: Repository does not exist` {#error-projects---error-during-verification-repository-does-not-exist}

**Root Cause:** Git 리포지토리가 없는 프로젝트로 인한 검증 실패.

**Symptoms:**

- 프로젝트는 검증 중에 "리포지토리가 없음" 오류를 표시합니다.
- 리포지토리가 없는 프로젝트에 대한 Geo UI의 거짓 오류 보고.
- 존재하지 않는 리포지토리에서 낭비되는 동기화 시도.

**Workaround:**

존재하지 않을 때 프라이머리에서 프로젝트 리포지토리를 만들어 보세요:

```ruby
failed_projects = Project.verification_failed.where("verification_failure LIKE '%Repository does not exist%'")
puts "Found #{failed_projects.count} project repos with 'Repository does not exist' verification failure"
failed_projects.find_each do |p|
  puts "#{p.full_path} #{p.ensure_repository.inspect}"
end
```

### 오류: `Expected(200) <=> Actual(403 Forbidden)` {#error-expected200--actual403-forbidden}

**Root Cause:** S3 API가 404 대신 403을 반환하도록 하는 누락된 `ListBucket` 권한.

**Symptoms:**

- S3 엔드포인트를 포함한 로그의 403 오류.
- S3 버킷에 대해 실패한 HEAD 요청.
- 객체 스토리지 지원 데이터 유형의 동기화 실패.

**Resolution:**

이를 위해서는 GitLab에서 사용하는 S3 IAM 정책에 `ListBucket` 권한을 추가하기 위한 인프라 팀의 개입이 필요합니다.

### 메시지: `Synchronization failed - Error syncing repository` {#message-synchronization-failed---error-syncing-repository}

> [!warning]
> 큰 리포지토리가 이 문제의 영향을 받으면 해당 리포지토리의 재동기화가 오래 걸릴 수 있으며 Geo 사이트, 스토리지 및 네트워크 시스템에 상당한 로드를 야기할 수 있습니다.

다음 오류 메시지는 리포지토리 동기화 시 일관성 검사 오류를 나타냅니다:

```plaintext
Synchronization failed - Error syncing repository [..] fatal: fsck error in packed object
```

여러 문제가 이 오류를 트리거할 수 있습니다. 예를 들어 이메일 주소의 문제:

```plaintext
Error syncing repository: 13:fetch remote: "error: object <SHA>: badEmail: invalid author/committer line - bad email
   fatal: fsck error in packed object
   fatal: fetch-pack: invalid index-pack output
```

이 오류를 트리거할 수 있는 또 다른 문제는 `object <SHA>: hasDotgit: contains '.git'`입니다. 모든 리포지토리에서 하나 이상의 문제가 있을 수 있으므로 특정 오류를 확인하세요.

두 번째 동기화 오류는 리포지토리 검사 문제로 인해 발생할 수도 있습니다:

```plaintext
Error syncing repository: 13:Received RST_STREAM with error code 2.
```

이 오류는 [즉시 실패한 모든 리포지토리를 동기화](#sync-all-resources-of-one-component-that-failed-to-sync)하여 확인할 수 있습니다.

일관성 오류를 야기하는 잘못된 형식의 객체를 제거하려면 리포지토리 히스토리를 다시 작성해야 하는데, 이는 보통 불가능합니다.

이 일관성 검사를 무시하려면 **on the secondary Geo sites**에서 Gitaly를 다시 구성하여 이 `git fsck` 문제를 무시합니다. 다음 구성 예:

- GitLab 16.0부터 필요한 [새 구성 구조를 사용](../../../../update/versions/gitlab_16_changes.md#gitaly-configuration-structure-change)합니다.
- 5가지 일반적인 검사 실패를 무시합니다.

[Gitaly 설명서에서 더 자세한 정보를 제공](../../../gitaly/consistency_checks.md)합니다(다른 Git 검사 실패 및 이전 GitLab 버전에 대해).

```ruby
gitaly['configuration'] = {
  git: {
    config: [
      { key: "fsck.duplicateEntries", value: "ignore" },
      { key: "fsck.badFilemode", value: "ignore" },
      { key: "fsck.missingEmail", value: "ignore" },
      { key: "fsck.badEmail", value: "ignore" },
      { key: "fsck.hasDotgit", value: "ignore" },
      { key: "fetch.fsck.duplicateEntries", value: "ignore" },
      { key: "fetch.fsck.badFilemode", value: "ignore" },
      { key: "fetch.fsck.missingEmail", value: "ignore" },
      { key: "fetch.fsck.badEmail", value: "ignore" },
      { key: "fetch.fsck.hasDotgit", value: "ignore" },
      { key: "receive.fsck.duplicateEntries", value: "ignore" },
      { key: "receive.fsck.badFilemode", value: "ignore" },
      { key: "receive.fsck.missingEmail", value: "ignore" },
      { key: "receive.fsck.badEmail", value: "ignore" },
      { key: "receive.fsck.hasDotgit", value: "ignore" },
    ],
  },
}
```

`fsck` 오류의 종합 목록은 [Git 설명서](https://git-scm.com/docs/git-fsck#_fsck_messages)에서 확인할 수 있습니다.

GitLab 16.1 이상 [이러한 문제를 해결할 수 있는 향상된 사항을 포함](https://gitlab.com/gitlab-org/gitaly/-/merge_requests/5879)합니다.

[Gitaly issue 5625](https://gitlab.com/gitlab-org/gitaly/-/issues/5625)는 소스 리포지토리에 문제가 있는 커밋이 포함되어 있더라도 Geo에서 리포지토리를 복제할 수 있도록 제안합니다.

### 관련 오류 `does not appear to be a git repository` {#related-error-does-not-appear-to-be-a-git-repository}

`Synchronization failed - Error syncing repository` 오류 메시지와 함께 다음 로그 메시지를 얻을 수도 있습니다. 이 오류는 예상된 Geo 원격이 세컨더리 Geo 사이트의 파일 시스템의 리포지토리의 `.git/config` 파일에 없음을 나타냅니다:

```json
{
  "created": "@1603481145.084348757",
  "description": "Error received from peer unix:/var/opt/gitlab/gitaly/gitaly.socket",
  …
  "grpc_message": "exit status 128",
  "grpc_status": 13
}
{  …
  "grpc.request.fullMethod": "/gitaly.RemoteService/FindRemoteRootRef",
  "grpc.request.glProjectPath": "<namespace>/<project>",
  …
  "level": "error",
  "msg": "fatal: 'geo' does not appear to be a git repository
          fatal: Could not read from remote repository. …",
}
```

이를 해결하려면:

1. 세컨더리 Geo 사이트의 웹 인터페이스에 로그인합니다.
1. [`.git` 폴더](../../../repository_storage_paths.md#translate-hashed-storage-paths)를 백업하세요.
1. 선택사항. [현장 확인](../../../logs/log_parsing.md#find-all-projects-affected-by-a-fatal-git-problem)을 수행하여 이러한 ID가 실제로 알려진 Geo 복제 실패가 있는 프로젝트에 해당하는지 확인합니다. `fatal: 'geo'`를 `grep` 항으로 사용하고 다음 API 호출을 사용합니다:

   ```shell
   curl --request GET --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/<first_failed_geo_sync_ID>"
   ```

1. [Rails 콘솔](../../../operations/rails_console.md)을 입력하고 실행합니다:

   ```ruby
   failed_project_registries = Geo::ProjectRepositoryRegistry.failed

   if failed_project_registries.any?
     puts "Found #{failed_project_registries.count} failed project repository registry entries:"

     failed_project_registries.each do |registry|
       puts "ID: #{registry.id}, Project ID: #{registry.project_id}, Last Sync Failure: '#{registry.last_sync_failure}'"
     end
   else
     puts "No failed project repository registry entries found."
   end
   ```

1. 각 프로젝트에 대해 새 동기화를 실행하는 다음 명령을 실행합니다:

   ```ruby
   failed_project_registries.each do |registry|
     registry.replicator.sync
     puts "Sync initiated for registry ID: #{registry.id}, Project ID: #{registry.project_id}"
   end
   ```

## 백필 중의 실패 {#failures-during-backfill}

[백필](../../_index.md#backfill) 중에는 실패가 백필 큐의 끝에서 재시도하도록 예약되므로 이 실패는 **after**에만 정리됩니다.

## 메시지: `unexpected disconnect while reading sideband packet` {#message-unexpected-disconnect-while-reading-sideband-packet}

불안정한 네트워킹 조건은 Gitaly가 프라이머리 사이트에서 큰 리포지토리 데이터를 페치하려고 할 때 실패를 야기할 수 있습니다. 이 조건은 다음 오류로 인해 발생할 수 있습니다:

```plaintext
curl 18 transfer closed with outstanding read data remaining & fetch-pack:
unexpected disconnect while reading sideband packet
```

이 오류는 리포지토리를 사이트 간에 처음부터 복제해야 하는 경우 더 가능성이 높습니다.

Geo는 여러 번 재시도하지만 전송이 네트워크 문제로 인해 지속적으로 중단되면 `rsync`과 같은 대체 방법을 사용하여 `git`을 우회하고 Geo로 인해 복제에 실패한 리포지토리의 초기 사본을 만들 수 있습니다.

각 실패한 리포지토리를 개별적으로 전송하고 각 전송 후 일관성을 확인하는 것을 권장합니다. [`rsync` 지침으로 다른 서버로](../../../operations/moving_repositories.md#use-rsync-to-another-server)를 따르세요. 프라이머리에서 세컨더리 사이트로 영향을 받는 각 리포지토리를 전송합니다.

## Geo 세컨더리 사이트에서 리포지토리 검사 실패 찾기 {#find-repository-check-failures-in-a-geo-secondary-site}

> [!note]
> 모든 리포지토리 데이터 유형이 GitLab 16.3에서 Geo Self-Service Framework로 마이그레이션되었습니다. [Geo Self-Service Framework에서 이 기능을 구현하기 위한 issue](https://gitlab.com/gitlab-org/gitlab/-/issues/426659)가 있습니다.

GitLab 16.2 이전의 경우:

[모든 프로젝트에 대해 활성화](../../../repository_checks.md#enable-repository-checks-for-all-projects) 되면 [리포지토리 검사](../../../repository_checks.md)도 Geo 세컨더리 사이트에서 수행됩니다. 메타데이터는 Geo 추적 데이터베이스에 저장됩니다.

Geo 세컨더리 사이트의 리포지토리 검사 실패는 반드시 복제 문제를 의미하지는 않습니다. 다음은 이 실패를 해결하는 일반적인 방법입니다.

1. 아래 언급된 대로 영향을 받는 리포지토리와 해당 [기록된 오류](../../../repository_checks.md#what-to-do-if-a-check-failed)를 찾습니다.
1. 특정 `git fsck` 오류를 진단하려고 시도합니다. 가능한 오류의 범위가 넓으므로 검색 엔진에 입력해 보세요.
1. 영향을 받는 리포지토리의 일반적인 기능을 테스트합니다. 세컨더리에서 끌어오기, 파일을 봅니다.
1. 프라이머리 사이트의 리포지토리 사본이 동일한 `git fsck` 오류를 가지는지 확인합니다. 장애 조치를 계획하는 경우 세컨더리 사이트가 프라이머리 사이트와 동일한 정보를 가지도록 우선순위를 지정합니다. 프라이머리의 백업이 있는지 확인하고 [계획된 장애 조치 지침](../../disaster_recovery/planned_failover.md)을 따릅니다.
1. 프라이머리로 푸시하고 변경 사항이 세컨더리 사이트로 복제되는지 확인합니다.
1. 복제가 자동으로 작동하지 않으면 리포지토리를 수동으로 동기화해 보세요.

[Rails 콘솔 세션을 시작](../../../operations/rails_console.md#starting-a-rails-console-session)하여 다음의 기본 문제 해결 단계를 수행합니다.

> [!warning]
> 데이터를 변경하는 명령은 올바르게 실행되지 않거나 적절한 조건에서 실행되지 않으면 손상을 야기할 수 있습니다. 항상 테스트 환경에서 먼저 명령을 실행하고 복원할 수 있는 백업 인스턴스를 준비해 두세요.

### 리포지토리 확인 실패 수 확인 {#get-the-number-of-repositories-that-failed-the-repository-check}

```ruby
Geo::ProjectRegistry.where(last_repository_check_failed: true).count
```

### 리포지토리 확인에 실패한 리포지토리 찾기 {#find-the-repositories-that-failed-the-repository-check}

```ruby
Geo::ProjectRegistry.where(last_repository_check_failed: true)
```

## Gitaly Cluster에서 리포지토리 강제 삭제 및 재동기화 {#hard-delete-a-repository-from-gitaly-cluster-and-resync}

> [!warning]
> 이 절차는 위험하고 과격합니다. 다른 문제 해결 방법이 실패한 경우에만 최후의 수단으로 사용하세요. 이 절차는 리포지토리가 재동기화될 때까지 일시적인 데이터 손실을 초래합니다.

이 절차는 세컨더리 사이트의 Gitaly 클러스터에서 리포지토리를 삭제한 후 다시 동기화합니다. 위험을 이해하고 있으며 다음 조건이 모두 충족되는 경우에만 사용을 고려해야 합니다:

- `git clone`은(는) 프라이머리 사이트의 리포지토리에서 작동 중입니다.
- `p.replicator.sync_repository`(여기서 `p`은(는) 프로젝트 모델 인스턴스)은 세컨더리 사이트에서 Gitaly 오류를 기록합니다.
- 표준 문제 해결 방법으로 문제를 해결하지 못했습니다.

전제 조건:

- 세컨더리 사이트의 Rails 콘솔과 Praefect 노드에 대한 관리 액세스 권한이 있는지 확인하세요.
- 리포지토리가 프라이머리 사이트에서 액세스 가능하고 올바르게 작동하는지 확인하세요.
- 이 절차를 취소해야 하는 경우를 대비한 백업 계획을 준비해 두세요.

다음 단계를 따르세요:

1. 세컨더리 사이트의 Rails 콘솔에 로그인하세요.
1. 프로젝트 모델을 인스턴스화하고 변수 `p`에 저장합니다. 다음 옵션 중 하나를 사용하세요:

   - 영향을 받는 프로젝트 ID를 알고 있으면 (예: `60087`) 다음을 수행합니다:

     ```ruby
     p = Project.find(60087)
     ```

   - GitLab에서 영향을 받는 프로젝트 경로를 알고 있으면 (예: `my-group/my-project`) 다음을 수행합니다:

     ```ruby
     p = Project.find_by_full_path('my-group/my-project')
     ```

1. 프로젝트 Git 리포지토리의 가상 스토리지를 출력하고 나중을 위해 기록해 두세요:

   ```ruby
   p.repository.storage
   ```

   출력 예:

   ```ruby
   irb(main):002:0> p.repository.storage
   => "default"
   ```

1. 프로젝트 Git 리포지토리의 상대 경로를 출력하고 나중을 위해 기록해 두세요:

   ```ruby
   p.repository.disk_path + '.git'
   ```

   출력 예:

   ```ruby
   irb(main):003:0> p.repository.disk_path + '.git'
   => "@hashed/66/b2/66b2fc8562b3432399acc2d0108fcd2782b32bd31d59226c7a03a20b32c76ee8.git"
   ```

1. 세컨더리 사이트의 Praefect 노드에 SSH로 연결하세요.
1. 이전 단계에서 기록한 가상 스토리지 및 상대 경로를 사용하여 [Gitaly Cluster에서 리포지토리 수동 제거](../../../gitaly/praefect/recovery.md#manually-remove-repositories) 절차를 따르세요.

   세컨더리 사이트의 Git 리포지토리가 이제 삭제되었습니다.

1. Rails 콘솔에서 재동기화하기 전에 상관 ID를 설정하세요. 이 ID를 사용하면 이 세션에서 실행하는 명령과 관련된 모든 로그를 검색할 수 있습니다:

   ```ruby
   Gitlab::ApplicationContext.push({})
   ```

   출력 예:

   ```ruby
   [2] pry(main)> Gitlab::ApplicationContext.push({})
   => #<Labkit::Context:0x0000000122aa4060 @data={"correlation_id"=>"53da64ae800bd4794a2b61ab1c80b028"}>
   ```

1. 프로젝트 Git 리포지토리를 동기화하세요:

   ```ruby
   p.replicator.sync_repository
   ```

Git 리포지토리가 이제 프라이머리 사이트에서 세컨더리 사이트로 재동기화됩니다. Geo 관리 인터페이스를 통하거나 Rails 콘솔에서 리포지토리의 동기화 상태를 확인하여 동기화 프로세스를 모니터링하세요.

## 인프라 및 성능 고려 사항 {#infrastructure-and-performance-considerations}

일부 동기화 문제는 인프라 수준의 문제 또는 성능 제약으로 인해 발생합니다.

### 높은 동시성 문제 {#high-concurrency-issues}

과도한 Geo 검증 동시성은 데이터베이스에 과부하를 주고 동기화 실패를 초래할 수 있습니다.

**Symptoms:**

- 데이터베이스 연결 시간 초과
- 데이터베이스 서버의 높은 CPU 사용
- 인프라가 정상인데도 동기화 진행이 느림

**Diagnosis and Resolution:**

**프라이머리** 사이트에서 동시성 설정을 줄이고 [UI](../tuning.md#changing-the-syncverification-concurrency-values)를 통해 설정합니다

## 수동 동기화 상태 업데이트 {#manual-sync-status-updates}

경우에 따라 기본 문제를 해결한 후 객체 유형을 수동으로 동기화된 것으로 표시해야 할 수 있습니다. 이 시나리오는 문제를 세컨더리 사이트의 객체 버킷에 파일을 수동으로 업로드하여야만 해결할 수 있는 경우에 발생합니다. 일반적으로 이 작업이 필요하지는 않지만 버전 버그로 인해 발생할 수 있습니다. 다음은 수동으로 업로드된 객체 유형(이 경우 업로드)을 동기화된 것으로 표시하는 방법을 보여줍니다.

> [!warning]
> 파일이 실제로 세컨더리 사이트에 있고 액세스 가능함을 확인한 후에만 객체를 동기화된 것으로 표시하세요.

```ruby
def mark_upload_synced(upload_id)
  upload = Upload.find(upload_id)
  registry = upload.replicator.registry
  registry.start
  registry.synced!
  puts "Marked upload #{upload_id} as synced"
end

# Mark specific uploads as synced
upload_ids = [107221, 107320] # Replace with actual IDs
upload_ids.each { |id| mark_upload_synced(id) }
```

## Geo **세컨더리** 사이트 복제 재설정 {#resetting-geo-secondary-site-replication}

**세컨더리** 사이트가 손상된 상태이고 복제 상태를 처음부터 다시 시작하고 싶으면 다음 몇 가지 단계가 도움이 될 수 있습니다:

1. Sidekiq과 Geo Log Cursor를 중지하세요.

   Sidekiq을 정상적으로 중지할 수 있지만 새 작업을 받지 않도록 중지하고 현재 작업이 처리 완료될 때까지 대기합니다.

   첫 번째 단계에서는 **SIGTSTP** 킬 신호를 보내고 모든 작업이 완료되었을 때는 **SIGTERM** 신호를 보냅니다. 아니면 `gitlab-ctl stop` 명령을 사용하세요.

   ```shell
   gitlab-ctl status sidekiq
   # run: sidekiq: (pid 10180) <- this is the PID you will use
   kill -TSTP 10180 # change to the correct PID

   gitlab-ctl stop sidekiq
   gitlab-ctl stop geo-logcursor
   ```

   [Sidekiq 로그](../../../logs/_index.md#sidekiq-logs)를 확인하여 Sidekiq 작업 처리가 완료된 시점을 알 수 있습니다:

   ```shell
   gitlab-ctl tail sidekiq
   ```

1. Gitaly 및 Gitaly Cluster(Praefect) 데이터를 정리하세요.

   {{< tabs >}}

   {{< tab title="Gitaly" >}}

   ```shell
   mv /var/opt/gitlab/git-data/repositories /var/opt/gitlab/git-data/repositories.old
   sudo gitlab-ctl reconfigure
   ```

   {{< /tab >}}

   {{< tab title="Gitaly Cluster(Praefect)" >}}

   1. 선택사항. Praefect 내부 로드 밸런서를 비활성화하세요.
   1. 각 Praefect 서버에서 Praefect를 중지하세요:

      ```shell
      sudo gitlab-ctl stop praefect
      ```

   1. Praefect 데이터베이스를 재설정하세요:

      ```shell
      sudo /opt/gitlab/embedded/bin/psql -U praefect -d template1 -h localhost -c "DROP DATABASE praefect_production WITH (FORCE);"
      sudo /opt/gitlab/embedded/bin/psql -U praefect -d template1 -h localhost -c "CREATE DATABASE praefect_production WITH OWNER=praefect ENCODING=UTF8;"
      ```

   1. 각 Gitaly 노드에서 리포지토리 데이터의 이름을 바꾸거나 삭제하세요:

      ```shell
      sudo mv /var/opt/gitlab/git-data/repositories /var/opt/gitlab/git-data/repositories.old
      sudo gitlab-ctl reconfigure
      ```

   1. Praefect 배포 노드에서 재구성을 실행하여 데이터베이스를 설정하세요:

      ```shell
      sudo gitlab-ctl reconfigure
      ```

   1. 각 Praefect 서버에서 Praefect를 시작하세요:

      ```shell
      sudo gitlab-ctl start praefect
      ```

   1. 선택사항. 비활성화한 경우 Praefect 내부 로드 밸런서를 다시 활성화하세요.

   {{< /tab >}}

   {{< /tabs >}}

   > [!note]
   > 나중에 더 이상 필요하지 않음이 확인되면 `/var/opt/gitlab/git-data/repositories.old`를 디스크 공간을 절약하기 위해 제거할 수 있습니다.

1. 선택사항. 다른 데이터 폴더의 이름을 바꾸고 새 폴더를 만드세요.

   > [!warning]
   > **세컨더리** 사이트에 여전히 **프라이머리** 사이트에서 제거된 파일이 있을 수 있지만 이 제거가 반영되지 않았습니다. 이 단계를 건너뛰면 Geo **세컨더리** 사이트에서 이러한 파일이 제거되지 않습니다.

   업로드된 콘텐츠(예: 파일 첨부, 아바타 또는 LFS 객체)는 다음 경로 중 하나의 하위 폴더에 저장됩니다:

   - `/var/opt/gitlab/gitlab-rails/shared`
   - `/var/opt/gitlab/gitlab-rails/uploads`

   모두 이름을 바꾸려면:

   ```shell
   gitlab-ctl stop

   mv /var/opt/gitlab/gitlab-rails/shared /var/opt/gitlab/gitlab-rails/shared.old
   mkdir -p /var/opt/gitlab/gitlab-rails/shared

   mv /var/opt/gitlab/gitlab-rails/uploads /var/opt/gitlab/gitlab-rails/uploads.old
   mkdir -p /var/opt/gitlab/gitlab-rails/uploads

   gitlab-ctl start postgresql
   gitlab-ctl start geo-postgresql
   ```

   폴더를 다시 만들고 권한 및 소유권이 올바른지 확인하도록 다시 구성하세요:

   ```shell
   gitlab-ctl reconfigure
   ```

1. 추적 데이터베이스를 재설정하세요.

   > [!warning]
   > 선택 사항 3단계를 건너뛴 경우 `geo-postgresql`과(와) `postgresql` 서비스가 모두 실행 중인지 확인하세요.

   ```shell
   gitlab-rake db:drop:geo DISABLE_DATABASE_ENVIRONMENT_CHECK=1   # on a secondary app node
   gitlab-ctl reconfigure     # on the tracking database node
   gitlab-rake db:migrate:geo # on a secondary app node
   ```

1. 이전에 중지된 서비스를 다시 시작하세요.

   ```shell
   gitlab-ctl start
   ```
