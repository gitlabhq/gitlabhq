---
stage: Application Security Testing
group: Composition Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 依存関係スキャン自動修正
description: 脆弱な依存関係を修正するためのマージリクエストを自動的に開きます。
---

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- ステータス: ベータ版

{{< /details >}}

{{< history >}}

- GitLab 19.0で[導入](https://gitlab.com/groups/gitlab-org/-/work_items/17403)され、[実験](../../../policy/development_stages_support.md#experiment)的な[機能フラグ](../../../administration/feature_flags/_index.md) `dependency_management_auto_remediation`として提供。デフォルトでは無効になっています。
- GitLab 19.2で[ベータ版](https://gitlab.com/groups/gitlab-org/-/work_items/604588)に[移行](../../../policy/development_stages_support.md#beta)しました。この`dependency_management_auto_remediation`機能フラグはデフォルトで有効になっています。
- GitLab 19.2でエージェント型の破壊的な変更の解決策が[導入](https://gitlab.com/gitlab-org/gitlab/-/work_items/603392)され、[機能フラグ](../../../administration/feature_flags/_index.md) `enable_dependency_bump_breaking_changes`として提供。デフォルトでは無効になっています。

{{< /history >}}

依存関係スキャンの自動修正機能は、脆弱な依存関係を脆弱性がないバージョンに更新するためのマージリクエストを、利用可能な場合に開きます。サービスアカウントが人の入力なしでマージリクエストを作成し、その後標準のレビューおよび承認プロセスを経ます。

ベータ版では、依存関係スキャンの自動修正は、個別に設定可能な2つの機能をサポートしています:

- 依存バージョンの更新: GitLabは、脆弱な依存関係を更新するマージリクエストを開きます。
- エージェント型の破壊的な変更の解決: バージョンの更新が破壊的な変更によってパイプラインの失敗を引き起こした場合、GitLab Duoはそれを解決することを試みます。詳細については、[エージェント型の破壊的な変更の解決を有効にする](#enable-agentic-breaking-change-resolution)を参照してください。

一般公開されているロードマップについては、[エピック19244](https://gitlab.com/groups/gitlab-org/-/work_items/19244)を参照してください。

## 依存関係スキャンの自動修正をオンにする {#turn-on-dependency-scanning-auto-remediation}

前提条件: 

- プロジェクトで`dependency_management_auto_remediation`[機能フラグ](../../../administration/feature_flags/_index.md)を有効にする必要があります。このフラグはGitLab 19.2でデフォルトで有効になっています。
- [依存関係スキャン](../dependency_scanning/_index.md)が有効になっていて、結果を生成している必要があります。
- プロジェクトは[サポートされているパッケージマネージャー](#supported-package-managers)を使用する必要があります。
- 依存関係スキャンの自動修正プロファイルをプロジェクトにアタッチする必要があります。手順については、[依存関係スキャン自動修正プロファイル](../configuration/security_configuration_profiles.md#dependency-scanning-auto-remediation-profile)を参照してください。

脆弱性の検出と自動修正をトリガーするには、パイプラインを実行します。利用可能な修正がある脆弱性をGitLabが検出すると、依存関係スキャンの自動修正が自動的にトリガーされます。

## 依存バージョンの更新のしくみ {#how-dependency-version-bumps-work}

依存関係スキャンの自動修正プロファイルがこの動作を制御します。デフォルトプロファイルでは:

- 重大度しきい値: GitLabは、`high`重大度以上の脆弱性を修正します。
- クールダウン期間: GitLabは、過去7日間にリリースされた修正バージョンを除外します。
- アップグレードポリシー: GitLabは、[エージェント型の破壊的な変更の解決](#enable-agentic-breaking-change-resolution)が有効になっている場合を除き、パッチおよびマイナーバージョンの更新のみを提案します。
- オープンマージリクエストの制限: プロジェクトごとに、自動修正マージリクエストは同時に最大10個まで開くことができます。既存のマージリクエストがマージされるかクローズされるまで、GitLabは新しいマージリクエストを作成しません。

各パイプラインの実行後、GitLabはこれらの値に対して依存スキャン結果をチェックします。各対象脆弱性について:

1. GitLabは、最も近い非破壊的な変更アップグレードパスを決定します。
1. サービスアカウントが関連するマニフェストファイルを更新するマージリクエストを開きます。
1. GitLabは、プロジェクトのアクティブなメンテナーをレビュアーとして割り当てます。アクティブなメンテナーが存在しない場合、マージリクエストはレビュアーなしで開いたままになります。
1. マージリクエストは、プロジェクトの標準承認ワークフローを経ます。

ベータ期間中、GitLabは一度に3つの脆弱性を処理し、最も高い重大度の検出から開始します。

## エージェント型の破壊的な変更の解決を有効にする {#enable-agentic-breaking-change-resolution}

バージョンの更新が破壊的な変更によってパイプラインの失敗を引き起こした場合、GitLab Duoは自動的にその破壊的な変更を解決することを試みることができます。この機能は、依存バージョンの更新機能とは別であり、独自の切替があります。

前提条件: 

- プロジェクトで[GitLab Duo](../../../user/gitlab_duo/_index.md)が利用可能である必要があります。
- プロジェクトのルートネームスペースで`enable_dependency_bump_breaking_changes`[機能フラグ](../../../administration/feature_flags/_index.md)を有効にする必要があります。

エージェント型の破壊的な変更の解決を有効にするには、[プロジェクトAPI](../../../api/projects.md#update-a-project)を使用して、プロジェクトの`duo_dependency_bump_breaking_changes_enabled`を`true`に設定します。

## スケジューラーの並行処理を設定する {#configure-scheduler-concurrency}

管理者は、Sidekiqフリート全体で同時に実行される自動修正スケジューラージョブの数を制限できます。`security_update_scheduler_max_concurrency`[アプリケーション設定](../../../api/settings.md)を使用して上限を設定します。デフォルトは`30`で、値の上限は`200`です。スケジューリングを一時停止するには、値を`0`に設定します。

## サポートされているパッケージマネージャー {#supported-package-managers}

依存関係スキャンの自動修正は、以下のパッケージマネージャーをサポートしています:

| 言語                | パッケージマネージャー                     | ファイル                                                                          |
| ----------------------- | ------------------------------------ | ------------------------------------------------------------------------------ |
| Ruby                    | Bundler                             | `Gemfile`、`Gemfile.lock`                                                      |
| Java                    | Maven                               | `pom.xml`                                                                      |
| Java                    | Gradle                              | `build.gradle`、`build.gradle.kts`                                             |
| Python                  | Pip、pipenv、poetry、setuptools、uv | `requirements.txt`、`Pipfile`、`pyproject.toml`、`setup.py`、`uv.lock`         |
| JavaScript / TypeScript | NPM、yarn、pnpm、bun                | `package.json`、`package-lock.json`、`yarn.lock`、`pnpm-lock.yaml`、`bun.lock` |

追加のエコシステムに関するサポートは、[エピック19244](https://gitlab.com/groups/gitlab-org/-/work_items/19244)で提案されています。

## 既知の問題 {#known-issues}

ベータ期間中:

- クールダウン期間: GitLabは、後に破損または悪意のあるものであることが判明したバージョンへの修正のリスクを減らすため、過去7日間にリリースされた修正バージョンを提案しません。
- バージョンの更新スコープ: パッチおよびマイナーバージョンの更新のみが提案されます。エージェント型の破壊的な変更の解決が有効になっていない限り、破壊的な変更を導入する可能性が高いメジャーバージョンアップグレードは試行されません。
- パイプライン実行ごとに1つの脆弱性: 各パイプライン実行は、利用可能な修正がある単一の脆弱性を対象とします。複数の修正を1つのマージリクエストにまとめることは、[エピック19244](https://gitlab.com/groups/gitlab-org/-/work_items/19244)で提案されています。
- 利用可能な修正なし: 脆弱性に対して非破壊的な変更の修正バージョンが存在しない場合、その検出結果に対してマージリクエストは作成されません。
