---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: アップグレードパスを計画する
description: 最新バージョンの手順。
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

アップグレードパスには、現在のGitLabのバージョンから、アップグレード先のGitLabのバージョンに移行するための手順が含まれます。アップグレードパスを決定するには:

1. 必要なアップグレードパスストップを含めて、現在のバージョンがアップグレードパスのどこにあるかを確認します。
1. [GitLabアップグレードノート](versions/_index.md)を参照してください。

明示的に指定されていない場合でも、GitLabを、最初のパッチリリースではなく、`major`.`minor`リリースの利用可能な最新パッチリリースにアップグレードしてください。たとえば、`16.8.0`の代わりに`16.8.7`を指定します。

一部の`major``minor`バージョンは、アップグレードプロセスに関連するイシューの修正があるため、一部またはすべての環境で必要な停止点です。

## 必須アップグレードストップ {#required-upgrade-stops}

アップグレードパスには、必須アップグレードストップが含まれます。これは、GitLabのバージョンのことであり、このバージョンにアップグレードしてから、より新しいバージョンにアップグレードする必要があります。アップグレードパスを進むときは、次のようにします:

1. 現在のバージョン以降の必須アップグレードストップにアップグレードします。
1. アップグレードのバックグラウンド移行が完了するまで待ちます。
1. 次の必須アップグレードストップにアップグレードします。

インスタンス管理者に予測可能なアップグレードスケジュールを提供するために、GitLab 17.5アップグレードパスストップは、`x.2.z`、`x.5.z`、`x.8.z`、`x.11.z`のバージョンで発生します。

特定のマイナーバージョンで利用可能なパッチリリースを確認するには、[GitLabパッケージレジストリ](https://packages.gitlab.com/gitlab)でマイナーバージョンを検索します。

GitLab Helmチャートインスタンスをアップグレードする場合は、[GitLab Helmチャートマッピング](https://docs.gitlab.com/charts/installation/version_mappings/#previous-chart-versions)のリストを参照してください。

### 必須のGitLab 18アップグレード停止 {#required-gitlab-18-upgrade-stops}

必要なアップグレード停止は、`18.2`、`18.5`、`18.8`、および`18.11`のバージョンで発生します。

より新しいバージョンにアップグレードする前に、これらのGitLab 18のバージョンにアップグレードする必要があります。アップグレードするバージョンごとに、[GitLab 18のアップグレードノート](versions/gitlab_18_changes.md)を参照してください。アップグレードノートにバージョンがない場合、注意すべきそのバージョンに固有のものは何もありません。

パッチリリースはGitLabパッケージリポジトリにあります。たとえば、最新のGitLab 18.2 Enterprise Editionバージョンを検索するには、<https://packages.gitlab.com/app/gitlab/gitlab-ee/search?q=18.2>にアクセスしてください。

### 必須のGitLab 17アップグレード停止 {#required-gitlab-17-upgrade-stops}

より新しいバージョンにアップグレードする前に、これらのGitLab 17のバージョンにアップグレードする必要があります。

| 必須バージョン | 備考 |
|:-----------------|:------|
| 17.11.7          | 最新のGitLab 17.11パッチリリースにアップグレードします。[GitLab 17.11.0のアップグレードノート](versions/gitlab_17_changes.md#upgrades-to-17110)を参照してください。 |
| 17.8.7           | 最新のGitLab 17.8パッチリリースにアップグレードします。[GitLab 17.8.0のアップグレードノート](versions/gitlab_17_changes.md#upgrades-to-1780)を参照してください。 |
| 17.5.5           | 最新のGitLab 17.5パッチリリースにアップグレードします。[GitLab 17.5.0のアップグレードノート](versions/gitlab_17_changes.md#upgrades-to-1750)を参照してください。 |
| 17.3.7           | 最新のGitLab 17.3リリースにアップグレードします。[GitLab 17.3.0のアップグレードノート](versions/gitlab_17_changes.md#upgrades-to-1730)を参照してください。 |
| 17.1.8           | [大規模な`ci_pipeline_messages`テーブル](versions/gitlab_17_changes.md#long-running-pipeline-messages-data-change)があるインスタンスにのみ必要です。[GitLab 17.1.0のアップグレードノート](versions/gitlab_17_changes.md#upgrades-to-1710)を参照してください。|

### 必須のGitLab 16アップグレード停止 {#required-gitlab-16-upgrade-stops}

より新しいバージョンにアップグレードする前に、これらのGitLab 16のバージョンにアップグレードする必要があります。

| 必須バージョン | 備考 |
|:-----------------|:------|
| 16.11.10         | [GitLab 16.11.0のアップグレードノート](versions/gitlab_16_changes.md#16110)を参照してください。 |
| 16.7.10          | [GitLab 16.8.0のアップグレードノート](versions/gitlab_16_changes.md#1670)およびそれ以降のGitLab 16.7バージョンを参照してください。 |
| 16.3.9           | [GitLab 16.3.0のアップグレードノート](versions/gitlab_16_changes.md#1630)およびそれ以降のGitLab 16.3バージョンを参照してください。 |
| 16.2.11          | [大規模なパイプライン変数履歴](versions/gitlab_16_changes.md#1630)を持つGitLabインスタンスにのみ必要です。[GitLab 16.2.0のアップグレードノート](versions/gitlab_16_changes.md#1620)を参照してください。 |
| 16.1.8           | [パッケージレジストリにNPMパッケージがある](versions/gitlab_16_changes.md#1610)GitLabインスタンスにのみ必要です。[GitLab 16.1.0のアップグレードノート](versions/gitlab_16_changes.md#1610)を参照してください。 |
| 16.0.10          | [多数のユーザー](versions/gitlab_16_changes.md#long-running-user-type-data-change)または[大規模なパイプライン変数履歴](versions/gitlab_16_changes.md#1610)を持つGitLabインスタンスにのみ必要です。[GitLab 16.0.0のアップグレードノート](versions/gitlab_16_changes.md#1600)およびそれ以降のGitLab 16.0バージョンを参照してください。 |

### 必須のGitLab 15アップグレード停止 {#required-gitlab-15-upgrade-stops}

より新しいバージョンにアップグレードする前に、これらのGitLab 15のバージョンにアップグレードする必要があります。

| 必須バージョン | 備考 |
|:-----------------|:------|
| 15.11.13         | [GitLab 15.11.0のアップグレードノート](versions/gitlab_15_changes.md#15110)およびそれ以降のGitLab 15.11バージョンを参照してください。 |
| 15.4.6           | [GitLab 15.4.0のアップグレードノート](versions/gitlab_15_changes.md#1540)およびそれ以降のGitLab 15.4バージョンを参照してください。 |
| 15.1.6           | 複数のWebノードを持つGitLabインスタンスにのみ必要です。[GitLab 15.1.0のアップグレードノート](versions/gitlab_15_changes.md#1510)を参照してください。 |
| 15.0.5           | [GitLab 15.0のアップグレードノート](versions/gitlab_15_changes.md#1500)を参照してください。 |

## アップグレードパスツール {#upgrade-path-tool}

現在のGitLabバージョンとアップグレード先のGitLabバージョンに基づいて、必要なアップグレードストップをすばやく計算するには、[アップグレードパスツール](https://gitlab-com.gitlab.io/support/toolbox/upgrade-path/)を参照してください。このツールは、GitLabサポートチームによってメンテナンスされています。

フィードバックを共有し、ツールの改善に協力するには、[`upgrade-path`プロジェクト](https://gitlab.com/gitlab-com/support/toolbox/upgrade-path)でイシューまたはマージリクエストを作成してください。

## 以前のGitLabバージョン {#earlier-gitlab-versions}

以前のGitLabバージョンへのアップグレードについては、[ドキュメントアーカイブ](https://archives.docs.gitlab.com)を参照してください。アーカイブ内のドキュメントのバージョンには、さらに以前のバージョンのGitLabに関するバージョン固有の情報が含まれています。
