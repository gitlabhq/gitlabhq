---
stage: Systems
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: Latest version instructions.
title: アップグレードパス
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 製品: GitLab Self-Managed

{{< /details >}}

複数のGitLabバージョンを一度にアップグレードするには、*ダウンタイムを受け入れる必要があります*。ダウンタイムを発生させたくない場合は、[ダウンタイムなしでアップグレードする](zero_downtime.md)方法をお読みください。

アップグレードパスには、必須アップグレード経由地点、つまり、より新しいバージョンにアップグレードする前にアップグレードする必要があるGitLabのバージョンが含まれます。アップグレードパスでは:

1. 現在のバージョンの次の必須アップグレード経由地点にアップグレードします。
1. アップグレードのバックグラウンド移行が完了するまで待ちます。
1. 次の必須アップグレード経由地点にアップグレードします。

インスタンス管理者に予測可能なアップグレードスケジュールを提供するために、GitLab 17.5以降、必要なアップグレード経由地点は、バージョン`x.2.z`、`x.5.z`、`x.8.z`、`x.11.z`で発生します。

アップグレードパスを決定するには:

1. 必須アップグレード経由地点を含め、現在のバージョンがアップグレードパスのどこにあるかを確認します。

   - GitLab 15には、次の必須アップグレード経由地点が含まれています。
     - [`15.0.5`](versions/gitlab_15_changes.md#1500)。
     - [`15.1.6`](versions/gitlab_15_changes.md#1510)。複数のWebノードを持つGitLabインスタンス。
     - [`15.4.6`](versions/gitlab_15_changes.md#1540)。
     - [`15.11.13`](versions/gitlab_15_changes.md#15110)。
   - GitLab 16には、次の必須アップグレード経由地点が含まれています。
     - [`16.0.10`](versions/gitlab_16_changes.md#1600)。[多数のユーザー](versions/gitlab_16_changes.md#long-running-user-type-data-change)または[大規模なパイプライン変数の履歴](versions/gitlab_16_changes.md#1610)を持つインスタンス。
     - [`16.1.8`](versions/gitlab_16_changes.md#1610)。パッケージレジストリにNPMパッケージを持つインスタンス。
     - [`16.2.11`](versions/gitlab_16_changes.md#1620)。[大規模なパイプライン変数の履歴](versions/gitlab_16_changes.md#1630)を持つインスタンス。
     - [`16.3.9`](versions/gitlab_16_changes.md#1630)。
     - [`16.7.10`](versions/gitlab_16_changes.md#1670)。
     - [`16.11.10`](https://gitlab.com/gitlab-org/gitlab/-/releases)。
   - GitLab 17には、次の必須アップグレード経由地点が含まれています。
     - [`17.1.8`](versions/gitlab_17_changes.md#long-running-pipeline-messages-data-change)。大規模な`ci_pipeline_messages`テーブルを持つインスタンス。
     - [`17.3.7`](versions/gitlab_17_changes.md#1730)。最新のGitLab 17.3リリース。
     - [`17.5.z`](versions/gitlab_17_changes.md#1750)。最新のGitLab 17.5リリース。
     - [`17.8.z`](versions/gitlab_17_changes.md#1780)。最新のGitLab 17.8リリース。
     - `17.11.z`。まだリリースされていません。

1. バージョン固有のアップグレード手順を参照してください。
   - [GitLab 17の変更点](versions/gitlab_17_changes.md)
   - [GitLab 16の変更点](versions/gitlab_16_changes.md)
   - [GitLab 15の変更点](versions/gitlab_15_changes.md)

明示的に指定されていない場合でも、GitLabを最初のパッチリリースではなく、`major`.`minor`リリースの利用可能な最新パッチリリースにアップグレードしてください。たとえば、`16.8.7`の代わりに`16.8.0`を使用します。

これには、アップグレードパスで経由する必要がある `major`.`minor`バージョンが含まれます。アップグレードプロセスに関連するイシューの修正が含まれている可能性があるためです。

特にメジャーバージョンでは、重要なデータベーススキーマと移行パッチが最新のパッチリリースに含まれている可能性があります。

## アップグレードパスツール

現在のGitLabバージョンとアップグレードしたいGitLabバージョンに基づいて、必要なアップグレード経由地点をすばやく計算するには、[アップグレードパスツール](https://gitlab-com.gitlab.io/support/toolbox/upgrade-path/)を参照してください。このツールは、[GitLabサポートチーム](https://handbook.gitlab.com/handbook/support/#about-the-support-team)によって保持されています。

フィードバックの共有とツールの改善にご協力いただくため、[アップグレードパスプロジェクト](https://gitlab.com/gitlab-com/support/toolbox/upgrade-path)でイシューまたはマージリクエストを作成してください。

## 以前のGitLabバージョン

以前のGitLabバージョンへのアップグレードについては、[ドキュメントアーカイブ](https://archives.docs.gitlab.com)を参照してください。アーカイブ内のドキュメントのバージョンには、さらに以前のバージョンのGitLabに関するバージョン固有の情報が含まれています。

たとえば、[GitLab 15.11のドキュメント](https://archives.docs.gitlab.com/15.11/ee/update/#upgrade-paths)には、GitLab 12までのバージョンに関する情報が含まれています。
