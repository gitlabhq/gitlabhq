---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: アップグレード前に
description: アップグレードの前に実行する手順。
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

アップグレードする前に、[GitLabリリースおよびメンテナンスポリシー](../policy/maintenance.md)を確認してください。

次に、以下を文書化したアップグレードプランを作成する必要があります。

- [アップグレードパス](upgrade_paths.md)など、インスタンスをアップグレードするために実行する手順。[アップグレードパスツール](upgrade_paths.md#upgrade-path-tool)を使用して、必須のアップグレードストップがアップグレードに含まれるかどうかを判断します。アップグレードストップにより、複数のアップグレードを実行するよう求められる場合があります。該当する場合は、[GitLab対象バージョンとのOSの互換性](../administration/package_information/supported_os.md)を確認してください。
- アップグレードがスムーズに進まない場合に実行する手順。

アップグレードプランには、次の内容を含める必要があります。

- GitLabをアップグレードする方法（可能な場合、および必要な場合は、[ダウンタイムなしのアップグレード](zero_downtime.md)を含む）。
- 必要に応じて、[GitLabをロールバック](#rollback-plan)する方法。

## アップグレード前の手順 {#pre-upgrade-steps}

アップグレードの前に、次のことを行う必要があります。

1. [バックグラウンド移行](background_migrations.md)を確認します。すべての移行は、各アップグレードの前に完了する必要があります。バックグラウンド移行を完了する時間を確保するために、メジャーリリースとマイナーリリースの間でアップグレードを分散させる必要があります。
1. 最初にテスト環境でアップグレードをテストし、[ロールバックプラン](#rollback-plan)を用意して、計画外の停止や長期ダウンタイムのリスクを軽減してください。
1. アップグレードする前に、さまざまなバージョンのGitLabの[GitLabアップグレードノート](versions/_index.md)を参照して、互換性を確認してください。

## サポートと連携する {#working-with-support}

[サポートと連携](https://about.gitlab.com/support/scheduling-upgrade-assistance/)してアップグレードプランをレビューする場合は、レビューと次の質問への回答を文書化して共有してください。

- GitLabはどのようにインストールされていますか？
- ノードのオペレーティングシステムは何ですか？[サポートされているプラットフォーム](../install/package/_index.md#supported-platforms)をチェックして、新しい更新が利用できることを確認してください。
- シングルノードのセットアップですか、それともマルチノードのセットアップですか？マルチノードの場合は、各ノードに関するアーキテクチャの詳細を文書化して共有してください。どの外部コンポーネントが使用されていますか？たとえば、Gitaly、PostgreSQL、またはRedisですか？
- [Geo](../administration/geo/_index.md)を使用していますか？使用している場合は、各セカンダリノードに関するアーキテクチャの詳細を文書化して共有してください。
- セットアップで他にどのようなユニークな点または興味深い点が重要になる可能性がありますか？
- 現在のバージョンのGitLabで既知の問題が発生していますか？

## ロールバックプラン {#rollback-plan}

アップグレード中に問題が発生する可能性があるため、そのシナリオに対応したロールバックプランを用意することが重要です。適切なロールバックプランを作成することで、インスタンスを最後に動作していた状態に戻すための明確な道筋ができます。これは、インスタンスをバックアップする方法と、インスタンスを復元する方法で構成されています。ロールバックプランは、実際に必要になる前にテストする必要があります。ロールバックに必要な手順の概要については、[ダウングレード](package/downgrade.md)を参照してください。

### GitLabのバックアップ {#back-up-gitlab}

GitLabとそのすべてのデータ（データベース、リポジトリ、アップロード、ビルド、アーティファクト、LFSオブジェクト、レジストリ、ページ）のバックアップを作成します。これは、アップグレードに問題が発生した場合に、GitLabを動作状態にロールバックできるようにするために不可欠です。

- [GitLabのバックアップ](../administration/backup_restore/_index.md)を作成します。インストール方法に応じた手順に従ってください。[シークレットと設定ファイル](../administration/backup_restore/backup_gitlab.md#storing-configuration-files)をバックアップすることを忘れないでください。
- 代替方法として、インスタンスのスナップショットを作成します。これがマルチノードインストールである場合は、すべてのノードのスナップショットを作成する必要があります。**このプロセスは、GitLabサポートの範囲外です。**

### GitLabを復元する {#restore-gitlab}

本番環境を模倣したテスト環境がある場合は、復元をテストして、すべてが期待どおりに動作することを確認してください。

GitLabのバックアップを復元するには:

- 復元する前に、[前提要件](../administration/backup_restore/_index.md#restore-gitlab)について必ずお読みください。もっとも重要なことは、バックアップされたGitLabインスタンスと新しいGitLabインスタンスのバージョンが同じであることです。
- [GitLabを復元](../administration/backup_restore/_index.md#restore-gitlab)します。インストール方法に応じた手順に従ってください。[シークレットと設定ファイル](../administration/backup_restore/backup_gitlab.md#storing-configuration-files)も復元されていることを確認してください。
- スナップショットから復元する場合は、それを行うための手順を知っている必要があります。**このプロセスは、GitLabサポートの範囲外です。**
