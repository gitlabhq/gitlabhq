---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: コード変更に対するフィードバックをより迅速に得るために、フェイルファストテンプレートを使用して、関連するRSpecテストのみを実行します。
title: フェイルファストテスト
---

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

テストの実行にRSpecを使用するアプリケーション向けに、`Verify/Failfast`マージリクエストの変更に基づいて、[テストスイートのサブセットを実行するテンプレート](https://gitlab.com/gitlab-org/gitlab/-/tree/master/lib/gitlab/ci/templates/Verify/FailFast.gitlab-ci.yml)を導入しました。

[`test_file_finder`（`tff`）gem](https://gitlab.com/gitlab-org/ruby/gems/test_file_finder)は、ファイルのリストを入力として受け入れ、入力ファイルに関連すると考えられる仕様（テスト）ファイルのリストを返します。

`tff`はRuby on Railsプロジェクト向けに設計されているため、`Verify/FailFast`テンプレートは、Rubyファイルへの変更が検出されたときに実行されるように設定されています。デフォルトでは、すべてのステージより前のGitLab CI/CDパイプラインの[`.pre`ステージ](../yaml/_index.md#stage-pre)で実行されます。

## ユースケースの例 {#example-use-case}

フェイルファストテストは、プロジェクトに新しい機能を追加したり、新しい自動テストを追加したりする場合に役立ちます。

プロジェクトには、完了に時間がかかる数十万のテストがある可能性があります。新しいテストが合格することを期待するかもしれませんが、それを検証するには、すべてのテストが完了するのを待つ必要があります。並列化を使用している場合でも、これには1時間以上かかる可能性があります。

フェイルファストテストにより、パイプラインからのフィードバックループが高速化されます。新しいテストが合格し、新しい機能が他のテストを失敗させなかったことをすぐに知ることができます。

## 前提要件 {#prerequisites}

このテンプレートには、以下が必要です:

- RSpecをテストに使用するRailsでビルドされたプロジェクト。
- 設定されたCI/CD:
  - 利用可能なRubyを備えたDockerイメージを使用します。
  - [マージリクエストパイプライン](../pipelines/merge_request_pipelines.md#prerequisites)を使用
- プロジェクト設定で有効になっている[マージ結果パイプライン](../pipelines/merged_results_pipelines.md#enable-merged-results-pipelines)。
- 利用可能なRubyを備えたDockerイメージ。このテンプレートは、デフォルトで`image: ruby:2.6`を使用しますが、これを[オーバーライド](../yaml/includes.md#override-included-configuration-values)できます。

## 高速RSpec失敗の設定 {#configuring-fast-rspec-failure}

開始ポイントとして、次のプレーンなRSpec設定を使用します。プロジェクトのすべてのgemをインストールし、マージリクエストパイプラインでのみ`rspec`を実行します。

```yaml
rspec-complete:
  stage: test
  rules:
    - if: $CI_PIPELINE_SOURCE == "merge_request_event"
  script:
    - bundle install
    - bundle exec rspec
```

スイート全体ではなく、最初に関連性の高い仕様を実行するには、[`include`](../yaml/_index.md#include) CI/CDの設定に以下を追加してテンプレートを読み込む:

```yaml
include:
  - template: Verify/FailFast.gitlab-ci.yml
```

ジョブをカスタマイズするには、テンプレートをオーバーライドするために特定のオプションを設定できます。たとえば、デフォルトのDockerイメージをオーバーライドするには、次のようにします:

```yaml
include:
  - template: Verify/FailFast.gitlab-ci.yml

rspec-rails-modified-path-specs:
  image: custom-docker-image-with-ruby
```

### テスト読み込みの例 {#example-test-loads}

説明のために、当社のRailsアプリの仕様スイートは、10個のモデルに対してモデルごとに100個の仕様で構成されています。

Rubyファイルが変更されていない場合:

- `rspec-rails-modified-paths-specs`はテストを実行しません。
- `rspec-complete`は、1000件のテストのフルスイートを実行します。

1つのRubyモデルが変更された場合（たとえば、`app/models/example.rb`）、`rspec-rails-modified-paths-specs`は`example.rb`の100件のテストを実行します:

- これらの100件のテストがすべて合格した場合、1000件のテストのフル`rspec-complete`スイートの実行が許可されます。
- これらの100件のテストのいずれかが失敗した場合、それらはすぐに失敗し、`rspec-complete`はテストを実行しません。

最後のケースでは、完全な1000テストスイートが実行されないため、リソースと時間が節約されます。
