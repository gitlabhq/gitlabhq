---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: 작업과 관련된 머지 리퀘스트 변경 사항만 실행하여 파이프라인 피드백을 더 빠르게 받습니다.
title: 빠른 실패 테스트
---

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

빠른 실패 테스트는 머지 리퀘스트 변경 사항과 가장 관련성이 높은 테스트 스펙을 나머지 스위트가 실행되기 전에 실행합니다. 해당 스펙이 실패하면 시간과 계산 리소스를 절약하기 위해 파이프라인이 즉시 중지됩니다.

RSpec을 사용하는 Ruby on Rails 프로젝트의 경우 [`Verify/FailFast` CI/CD 템플릿](https://gitlab.com/gitlab-org/gitlab/-/tree/master/lib/gitlab/ci/templates/Verify/FailFast.gitlab-ci.yml)이 관련 스펙만 선택하고 실행합니다. [`test_file_finder` (`tff`) gem](https://gitlab.com/gitlab-org/ruby/gems/test_file_finder)을 사용하며, 이는 변경된 파일을 관련 스펙 파일에 매핑합니다.

기본적으로 템플릿은 [`.pre` 스테이지](../yaml/_index.md#stage-pre)에서 실행되며, 다른 모든 파이프라인 스테이지 이전에 실행됩니다.

## 빠른 실패 테스트 구성 {#configure-fail-fast-testing}

전체 테스트 스위트가 실행되기 전에 머지 리퀘스트 변경 사항에 대한 더 빠른 피드백을 받으려면 빠른 실패 테스트를 구성합니다.

전제 조건:

- RSpec을 사용하는 Ruby on Rails 프로젝트
- [머지된 결과 파이프라인](../pipelines/merged_results_pipelines.md#enable-merged-results-pipelines)이 프로젝트 설정에서 활성화되어 있습니다. 또한 [머지 리퀘스트 파이프라인](../pipelines/merge_request_pipelines.md#prerequisites)이 활성화되어야 합니다.

빠른 실패 테스트를 구성하려면:

1. RSpec 작업을 추가하여 머지 리퀘스트 파이프라인에서 전체 스위트를 실행합니다:

   ```yaml
   rspec-complete:
     stage: test
     rules:
       - if: $CI_PIPELINE_SOURCE == "merge_request_event"
     script:
       - bundle install
       - bundle exec rspec
   ```

1. `Verify/FailFast` 템플릿을 CI/CD 구성에 포함합니다:

   ```yaml
   include:
     - template: Verify/FailFast.gitlab-ci.yml
   ```

1. 선택 사항. 다른 Docker 이미지를 사용하려면 CI/CD 구성 파일에서 `rspec-rails-modified-path-specs` 작업의 이미지를 설정합니다:

   ```yaml
   include:
     - template: Verify/FailFast.gitlab-ci.yml

   rspec-rails-modified-path-specs:
     image: custom-docker-image-with-ruby
   ```

## 빠른 실패 테스트 결과 {#fail-fast-test-results}

다음 예제는 10개 모델에 걸쳐 모델당 100개의 스펙(총 1000개 스펙)으로 구성된 스위트를 가정합니다.

| 변경된 파일                            | `rspec-rails-modified-path-specs` | `rspec-complete` |
| ---------------------------------------- | --------------------------------- | ---------------- |
| Ruby 파일 없음                            | 실행되지 않음                      | 1000개 스펙 모두 실행 |
| `app/models/example.rb` (모든 스펙 통과) | `example.rb`에 대해 100개 스펙 실행   | 1000개 스펙 모두 실행 |
| `app/models/example.rb` (어떤 스펙 실패) | `example.rb`에 대해 100개 스펙 실행   | 건너뜀          |
