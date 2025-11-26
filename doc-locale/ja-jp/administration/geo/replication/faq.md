---
stage: Runtime
group: Geo
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
gitlab_dedicated: no
title: Geoに関するよくある質問
---

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

## Geoを実行するための最小要件は何ですか？ {#what-are-the-minimum-requirements-to-run-geo}

要件は[インデックスページ](../_index.md#requirements-for-running-geo)に記載されています

## Geoはどのプロジェクトを同期するかをどのように認識するのですか？ {#how-does-geo-know-which-projects-to-sync}

各**セカンダリ**サイトには、読み取り専用でレプリケーションされたGitLabデータベースのコピーがあります。**セカンダリ**サイトには、どのプロジェクトが同期されたかを保存するトラッキングデータベースもあります。Geoは2つのデータベースを比較して、まだ追跡されていないプロジェクトを検索します。

開始時、このトラッキングデータベースは空であるため、GeoはGitLabデータベースで確認できるすべてのプロジェクトから更新を試みます。

同期する各プロジェクトについて:

1. Geoは`git fetch geo --mirror`を発行して、**プライマリ**サイトから最新の情報を取得します。変更がない場合、同期は高速です。それ以外の場合は、最新のコミットをプルする必要があります。
1. **セカンダリ**サイトは、プロジェクトを名前で同期したという事実を保存するために、トラッキングデータベースを更新します。
1. すべてのプロジェクトが同期されるまで繰り返します。

誰かが**プライマリ**サイトにコミットをプッシュすると、リポジトリが変更されたというイベントがGitLabデータベースで生成されます。**セカンダリ**サイトはこのイベントを確認し、問題のプロジェクトをダーティとしてマークして、プロジェクトを再度同期するようにスケジュールします。

（たとえば、同期が何度も失敗したり、ジョブが失われたりするなど）パイプラインの問題によってプロジェクトの同期が完全に停止しないようにするために、Geoはダーティとしてマークされているプロジェクトのトラッキングデータベースも定期的にチェックします。このチェックは、同時同期の数が`repos_max_capacity`を下回り、同期を待機している新しいプロジェクトがない場合に発生します。

Geoには、すべてのGit参照をSHA値に対してSHA256サムを実行するチェックサム機能もあります。**プライマリ**サイトと**セカンダリ**サイト間でrefsが一致しない場合、**セカンダリ**サイトはそのプロジェクトをダーティとしてマークし、再度同期を試みます。そのため、検証は、トラッキングデータベースが古くなっていても、リポジトリの状態の不一致をアクティブにして検出し、再度同期する必要があります。

## ディザスターリカバリーの状況でGeoを使用できますか？ {#can-you-use-geo-in-a-disaster-recovery-situation}

はい、ただし、レプリケーションする内容には制限があります（[**セカンダリ**サイトにレプリケーションされるデータ](#what-data-is-replicated-to-a-secondary-site)を参照）。

[ディザスターリカバリー](../disaster_recovery/_index.md)のドキュメントをお読みください。

## **セカンダリ**サイトにレプリケーションされるデータは何ですか？ {#what-data-is-replicated-to-a-secondary-site}

レールデータベース全体、プロジェクトリポジトリ、LFSオブジェクト、生成された添付ファイル、アバターなどをレプリケーションします。これは、ユーザーアカウント、イシュー、マージリクエスト、グループ、プロジェクトデータなどの情報をクエリに使用できることを意味します。

Geoによってレプリケーションされるデータの包括的なリストについては、[サポートされているGeoデータ型のページ](datatypes.md)を参照してください。

## `git push`を**セカンダリ**サイトにプッシュできますか？ {#can-i-git-push-to-a-secondary-site}

**セカンダリ**サイトへの直接プッシュ（Git LFSを含むHTTPとSSHの両方）がサポートされています。

## コミットが**セカンダリ**サイトにレプリケーションされるまでにどれくらい時間がかかりますか？ {#how-long-does-it-take-to-have-a-commit-replicated-to-a-secondary-site}

すべてのレプリケーション操作は非同期であり、ディスパッチされるようにキューに入れられます。したがって、トラフィック量、コミットのサイズ、サイト間の接続、ハードウェアなど、多くの要因によって異なります。

## SSHサーバーが別のポートで実行されている場合はどうなりますか？ {#what-if-the-ssh-server-runs-at-a-different-port}

それは全く問題ありません。HTTP（S）を使用して、**プライマリ**サイトからすべての**セカンダリ**サイトにリポジトリの変更をフェッチします。

## プライマリをミラーするために、セカンダリサイト用のコンテナレジストリを作成できますか？ {#can-i-make-a-container-registry-for-a-secondary-site-to-mirror-the-primary}

はい、ただし、これはディザスターリカバリーのシナリオでのみサポートしています。[コンテナレジストリ（**セカンダリ**）サイト](container_registry.md)を参照してください。

## セカンダリサイトにサインインできますか？ {#can-you-sign-in-to-a-secondary-site}

はい、ただし、セカンダリサイトは、すべての認証データ（ユーザーアカウントやログインなど）をプライマリインスタンスから受信します。これは、認証のためにプライマリにリダイレクトされ、その後ルーティングされることを意味します。

## すべてのGeoサイトはプライマリと同じである必要がありますか？ {#do-all-geo-sites-need-to-be-the-same-as-the-primary}

いいえ、Geoサイトは異なるリファレンスアーキテクチャに基づくことができます。たとえば、プライマリサイトを3Kリファレンスアーキテクチャ、1つのセカンダリサイトを3Kリファレンスアーキテクチャ、別のサイトを1Kリファレンスアーキテクチャにすることができます。

## Geoはアーカイブされたプロジェクトをレプリケートしますか？ {#does-geo-replicate-archived-projects}

はい、[選択的な同期](selective_synchronization.md)によって除外されていない場合に限ります。

## Geoは個人プロジェクトをレプリケートしますか？ {#does-geo-replicate-personal-projects}

はい、[選択的な同期](selective_synchronization.md)によって除外されていない場合に限ります。

## 遅延削除プロジェクトはセカンダリサイトにレプリケーションされますか？ {#are-delayed-deletion-projects-replicated-to-secondary-sites}

はい、[遅延削除](../../settings/visibility_and_access_controls.md#deletion-protection)によって削除がスケジュールされているプロジェクトは、まだ完全に削除されていませんが、セカンダリサイトにレプリケーションされます。

## プライマリサイトがダウンすると、セカンダリサイトはどうなりますか？ {#what-happens-to-my-secondary-sites-with-when-my-primary-site-goes-down}

プライマリサイトがダウンした場合、[プライマリのサービスを復元するか、セカンダリサイトで昇格を実行しない限り、セカンダリはUIからアクセスできなくなります](../secondary_proxy/_index.md#behavior-of-secondary-sites-when-the-primary-geo-site-is-down)。
