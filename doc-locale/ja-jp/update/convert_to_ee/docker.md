---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Docker CEインスタンスをEEに変換
---

Docker用の既存のGitLab Community Edition（CE）コンテナをGitLab [Enterprise Edition](https://about.gitlab.com/pricing/) （EE）コンテナに変換するには、[バージョンをアップグレード](../docker/_index.md)するのと同じ方法を使用します。

CEの同じバージョンからEEに変換することをおすすめします（たとえば、CE 18.1からEE 18.1）。ただし、これは必須ではありません。標準的なアップグレード（たとえば、CE 18.0からEE 18.1）はすべて機能するはずです。次の手順では、同じバージョンに変換することを前提としています。

1. [バックアップ](../../install/docker/backup.md)を作成します。最低限、[データベース](../../install/docker/backup.md#create-a-database-backup)とGitLabシークレットファイルをバックアップしてください。

1. 現在のCEコンテナを停止し、削除または名前を変更します。

1. GitLab EEで新しいコンテナを作成するには、`docker run`コマンドまたは`docker-compose.yml`ファイルで`ce`を`ee`に置き換えます。CEコンテナ名、ポートマッピング、ファイルマッピング、およびバージョンを再利用します。
