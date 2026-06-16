---
stage: Create
group: Import
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 임포트용 Sidekiq 구성
description: GitLab으로 임포트하거나 마이그레이션하기 위해 Sidekiq 구성을 최적화합니다.
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed

{{< /details >}}

임포터는 그룹 및 프로젝트의 임포트 및 내보내기를 처리하기 위해 Sidekiq 작업에 크게 의존합니다. 이러한 작업 중 일부는 상당한 리소스(CPU 및 메모리)를 소비할 수 있으며 완료하는 데 오랜 시간이 걸릴 수 있으므로 다른 작업의 실행에 영향을 미칠 수 있습니다.

이 이슈를 해결하려면 임포터 작업을 전용 Sidekiq 큐로 라우팅하고 해당 큐를 처리할 전용 Sidekiq 프로세스를 할당해야 합니다.

예를 들어 다음 구성을 사용할 수 있습니다:

```conf
sidekiq['concurrency'] = 20

sidekiq['routing_rules'] = [
  # Route import and export jobs to the importer queue
  ['feature_category=importers', 'importers'],

  # Route all other jobs to the default queue by using wildcard matching
  ['*', 'default']
]

sidekiq['queue_groups'] = [
  # Run a dedicated process for the importer queue
  'importers',

  # Run a separate process for the default and mailer queues
  'default,mailers'
]
```

이 설정에서:

- 전용 Sidekiq 프로세스는 임포터 큐를 통해 임포트 및 내보내기 작업을 처리합니다.
- 다른 Sidekiq 프로세스는 다른 모든 작업(기본 및 메일러 큐)을 처리합니다.
- 두 Sidekiq 프로세스는 기본적으로 20개의 동시 스레드로 실행되도록 구성됩니다. 메모리 제약이 있는 환경의 경우 이 숫자를 줄일 수 있습니다.

## 추가 프로세스 구성 {#configure-additional-processes}

인스턴스에 더 많은 동시 작업을 지원할 수 있는 충분한 리소스가 있으면 추가 Sidekiq 프로세스를 구성하여 마이그레이션 속도를 높일 수 있습니다.

Sidekiq 프로세스의 최대 개수를 염두에 두고 다음을 고려하세요:

- 프로세스 수는 사용 가능한 CPU 코어 수를 초과하면 안 됩니다.
- 각 프로세스는 최대 2GB의 메모리를 사용할 수 있으므로 인스턴스에 추가 프로세스에 충분한 메모리가 있는지 확인하세요.
- 각 프로세스는 `sidekiq['concurrency']`에 정의된 대로 스레드당 하나의 데이터베이스 연결을 추가합니다.

예를 들어:

```conf
sidekiq['queue_groups'] = [
  # Run three processes for importer jobs
  'importers',
  'importers',
  'importers',

  # Run a separate process for the default and mailer queues
  'default,mailers'
]
```

이 설정에서는 여러 Sidekiq 프로세스가 임포트 및 내보내기 작업을 동시에 처리하므로 인스턴스에 충분한 리소스가 있는 한 마이그레이션 속도를 높입니다.

## 관련 항목 {#related-topics}

- [GitLab으로 임포트 및 마이그레이션](../../user/import/_index.md).
- [임포트 및 내보내기 설정](../settings/import_and_export_settings.md).
- [여러 Sidekiq 프로세스 실행](extra_sidekiq_processes.md).
- [특정 작업 클래스 처리](processing_specific_job_classes.md).
