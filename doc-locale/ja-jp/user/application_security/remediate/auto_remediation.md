---
stage: Application Security Testing
group: Composition Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 自動修正
description: 脆弱な依存関係を修正するために、マージリクエストを自動的に開きます。
---

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- ステータス: 実験的機能

{{< /details >}}

{{< history >}}

- GitLab 19.0で`dependency_management_auto_remediation`[機能フラグ](../../../administration/feature_flags/_index.md)とともに[実験的機能](../../../policy/development_stages_support.md#experiment)として[導入](https://gitlab.com/groups/gitlab-org/-/work_items/17403)されました。デフォルトでは無効になっています。

{{< /history >}}

自動修正は、脆弱性のある依存関係に対して、脆弱性のないバージョンが利用可能な場合に、それを引き上げるマージリクエストを自動的に開きます。サービスアカウントが、人手を介さずにマージリクエストを作成し、その後、標準的なレビューおよび承認プロセスを経ます。

ベータロードマップと計画されている改善点については、[エピック18236](https://gitlab.com/groups/gitlab-org/-/work_items/18236)を参照してください。

## 自動修正を有効にする {#turn-on-auto-remediation}

前提条件: 

- プロジェクトに少なくとも1人のメンテナーが必要です。
- `dependency_management_auto_remediation` [機能フラグ](../../../administration/feature_flags/_index.md)が有効になっている必要があります。
- [依存関係スキャン](../dependency_scanning/_index.md)が有効になっていて、結果を生成している必要があります。
- プロジェクトは、[サポートされているパッケージマネージャー](#supported-package-managers)を使用する必要があります。

脆弱性検出と自動修正をトリガーするには、パイプラインを実行します。自動修正は、利用可能な修正を含む脆弱性が検出された場合に自動的にトリガーされます。

## 自動修正の仕組み {#how-auto-remediation-works}

各パイプラインの実行後、GitLabは依存関係スキャン結果を、既知の修正バージョンを持つ脆弱性についてチェックします。対象となる各脆弱性について:

1. GitLabは、最も近い非破壊的な変更を伴わないアップグレードパス（パッチまたはマイナーバージョンの引き上げ）を決定します。
1. サービスアカウントは、関連するマニフェストファイルを更新するマージリクエストを開きます。
1. そのマージリクエストは、プロジェクトの標準的な承認ワークフローを経ます。

実験フェーズ中、GitLabは一度に3つの脆弱性を、最も高い重大度の発見から開始して処理します。

## サポートされているパッケージマネージャー {#supported-package-managers}

自動修正は、以下のパッケージマネージャーをサポートしています:

| 言語 | パッケージマネージャー | ファイル                     |
| -------- | --------------- | ------------------------- |
| Ruby     | Bundler         | `Gemfile`、`Gemfile.lock` |

追加のエコシステムへのサポートが計画されています。詳細については、[エピック21643](https://gitlab.com/groups/gitlab-org/-/work_items/21643)を参照してください。

## 既知の問題 {#known-issues}

実験フェーズ中:

- オープンなマージリクエストの制限: プロジェクトごとに最大3つの自動修正マージリクエストを開くことができます。新しいマージリクエストは、既存のものがマージされるか閉じられるまで作成されません。
- バージョン引き上げのスコープ: パッチおよびマイナーバージョンの引き上げのみが提案されます。メジャーバージョンのアップグレードは、破壊的な変更をもたらす可能性がありますが、試みられません。
- パイプライン実行あたりの脆弱性数: 各パイプラインの実行は、利用可能な修正を含む単一の脆弱性を対象とします。複数の修正を1つのマージリクエストにまとめることは、ベータ版で計画されています。
- 修正なし: ある脆弱性に対して非破壊的な変更を伴わない修正バージョンが存在しない場合、その発見に対してマージリクエストは作成されません。
