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

複数のGitLabバージョンを経由して一気にアップグレードするには、ダウンタイムを受け入れる必要があります。ダウンタイムを発生させたくない場合は、[ダウンタイムなしでアップグレード](zero_downtime.md)する方法をお読みください。

アップグレードパスには、必須アップグレードストップが含まれます。これは、GitLabのバージョンのことであり、このバージョンにアップグレードしてから、より新しいバージョンにアップグレードする必要があります。アップグレードパスを進むときは、次のようにします。

1. 現在のバージョン以降の必須アップグレードストップにアップグレードします。
1. アップグレードのバックグラウンド移行が完了するまで待ちます。
1. 次の必須アップグレードストップにアップグレードします。

インスタンス管理者に予測可能なアップグレードスケジュールを提供するために、GitLab 17.5以降では、必須アップグレードストップは、バージョン`x.2.z`、`x.5.z`、`x.8.z`、`x.11.z`で発生します。

アップグレードパスを決定するには:

1. 必須アップグレードストップを含めて、現在のバージョンがアップグレードパスのどこにあるかを確認します。

   - GitLab 15には、次の必須アップグレードストップが含まれています。
     - [`15.0.5`](versions/gitlab_15_changes.md#1500)。
     - [`15.1.6`](versions/gitlab_15_changes.md#1510)。複数のWebノードを持つGitLabインスタンス。
     - [`15.4.6`](versions/gitlab_15_changes.md#1540)。
     - [`15.11.13`](versions/gitlab_15_changes.md#15110)。
   - GitLab 16には、次の必須アップグレードストップが含まれています。
     - [`16.0.10`](versions/gitlab_16_changes.md#1600)。[多数のユーザー](versions/gitlab_16_changes.md#long-running-user-type-data-change)または[大規模なパイプライン変数履歴](versions/gitlab_16_changes.md#1610)を持つインスタンス。
     - [`16.1.8`](versions/gitlab_16_changes.md#1610)。パッケージレジストリにNPMパッケージを持つインスタンス。
     - [`16.2.11`](versions/gitlab_16_changes.md#1620)。[大規模なパイプライン変数履歴](versions/gitlab_16_changes.md#1630)を持つインスタンス。
     - [`16.3.9`](versions/gitlab_16_changes.md#1630)。
     - [`16.7.10`](versions/gitlab_16_changes.md#1670)。
     - [`16.11.10`](https://gitlab.com/gitlab-org/gitlab/-/releases)。
   - GitLab 17には、次の必須アップグレードストップが含まれています。
     - [`17.1.8`](versions/gitlab_17_changes.md#long-running-pipeline-messages-data-change)。大規模な`ci_pipeline_messages`テーブルを持つインスタンス。
     - [`17.3.7`](versions/gitlab_17_changes.md#1730)。最新のGitLab 17.3リリース。
     - [`17.5.z`](versions/gitlab_17_changes.md#1750)。最新のGitLab 17.5リリース。
     - [`17.8.z`](versions/gitlab_17_changes.md#1780)。最新のGitLab 17.8リリース。
     - [`17.11.z`](versions/gitlab_17_changes.md#17110)。最新のGitLab 17.11リリース。

1. [GitLabアップグレードノート](versions/_index.md)を参照してください。

明示的に指定されていない場合でも、GitLabを、最初のパッチリリースではなく、`major`.`minor`リリースの利用可能な最新パッチリリースにアップグレードしてください。たとえば、`16.8.0`ではなく、`16.8.7`にアップグレードします。

アップグレードストップには、アップグレードパスで経由する必要がある`major`.`minor`バージョンが含まれます。アップグレードプロセスに関連する問題の修正が含まれている可能性があるためです。

特にメジャーバージョン周辺では、最新のパッチリリースに重要なデータベーススキーマと移行パッチが含まれている可能性があります。

## アップグレードパスツール {#upgrade-path-tool}

現在のGitLabバージョンとアップグレード先のGitLabバージョンに基づいて、必要なアップグレードストップをすばやく計算するには、[アップグレードパスツール](https://gitlab-com.gitlab.io/support/toolbox/upgrade-path/)を参照してください。このツールは、GitLabサポートチームによってメンテナンスされています。

フィードバックの共有とツールの改善のために、[upgrade-pathプロジェクト](https://gitlab.com/gitlab-com/support/toolbox/upgrade-path)でイシューまたはマージリクエストを作成してください。

## 以前のGitLabバージョン {#earlier-gitlab-versions}

以前のGitLabバージョンへのアップグレードについては、[ドキュメントアーカイブ](https://archives.docs.gitlab.com)を参照してください。アーカイブ内のドキュメントのバージョンには、さらに以前のバージョンのGitLabに関するバージョン固有の情報が含まれています。

たとえば、[GitLab 15.11のドキュメント](https://archives.docs.gitlab.com/15.11/ee/update/#upgrade-paths)には、GitLab 12以降のバージョンに関する情報が含まれています。
