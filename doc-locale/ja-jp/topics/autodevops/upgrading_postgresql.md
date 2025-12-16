---
stage: Deploy
group: Environments
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Auto DevOpsのPostgreSQLのアップグレード
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

`POSTGRES_ENABLED`が`true`の場合、Auto DevOpsはアプリケーション用の[インクラスタ](customize.md#postgresql-database-support)をプロビジョニングします。

PostgreSQLのプロビジョニングに使用されるチャートのバージョン:

- 0.7.1から8.2.1に設定できます。

GitLabでは、データベースを新しいPostgreSQLチャートに移行することを推奨しています。

このガイドでは、PostgreSQLデータベースを移行する方法について説明します。これには次の手順が含まれます。:

1. データのデータベースダンプを取得します。
1. 新しいバージョン8.2.1のチャートを使用して新しいPostgreSQLデータベースをインストールし、古いPostgreSQLのインストールを削除します。
1. 新しいPostgreSQLにデータベースダンプを復元します。

## 前提要件 {#prerequisites}

1. [`kubectl`](https://kubernetes.io/docs/tasks/tools/)をインストールします。
1. `kubectl`を使用してKubernetesクラスタにアクセスできることを確認してください。これは、Kubernetesプロバイダーによって異なります。
1. ダウンタイムに備えてください。以下の手順では、データベースダンプの作成後にインクラスタデータベースが変更されないように、アプリケーションをオフラインにします。
1. この設定は既存のチャンネル1データベースを削除するため、`POSTGRES_ENABLED`を`false`に設定していないことを確認してください。詳細については、[既存のPostgreSQLデータベースが検出されました](troubleshooting.md#detected-an-existing-postgresql-database)を参照してください。

{{< alert type="note" >}}

Auto DevOpsをステージングするように設定している場合は、最初にステージングでバックアップと復元の手順を試すか、レビューアプリで試してみてください。

{{< /alert >}}

## アプリケーションをオフラインにする {#take-your-application-offline}

必要に応じて、データベースダンプの作成後にデータベースが変更されないように、アプリケーションをオフラインにします。

1. 環境のKubernetesネームスペースを取得します。通常は`<project-name>-<project-id>-<environment>`のようになります。この例では、ネームスペースは`minimal-ruby-app-4349298-production`と呼ばれています。

   ```shell
   $ kubectl get ns

   NAME                                                  STATUS   AGE
   minimal-ruby-app-4349298-production                   Active   7d14h
   ```

1. 使いやすくするために、ネームスペース名をエクスポートします。:

   ```shell
   export APP_NAMESPACE=minimal-ruby-app-4349298-production
   ```

1. 次のコマンドを使用して、アプリケーションのデプロイ名を取得します。この例では、デプロイメント名は`production`です。

   ```shell
   $ kubectl get deployment --namespace "$APP_NAMESPACE"
   NAME                  READY   UP-TO-DATE   AVAILABLE   AGE
   production            2/2     2            2           7d21h
   production-postgres   1/1     1            1           7d21h
   ```

1. データベースが変更されないようにするには、次のコマンドを使用して、デプロイメントのレプリカを0に設定します。前の手順 (`deployments/<DEPLOYMENT_NAME>`) からデプロイ名を使用します。

   ```shell
   $ kubectl scale --replicas=0 deployments/production --namespace "$APP_NAMESPACE"
   deployment.extensions/production scaled
   ```

1. もしもワーカーがある場合は、レプリカをゼロに設定する必要があります。

## バックアップ {#backup}

1. PostgreSQLのサービス名を取得します。サービスの名前は、`-postgres`で終わる必要があります。この例では、サービス名は`production-postgres`です。

   ```shell
   $ kubectl get svc --namespace "$APP_NAMESPACE"
   NAME                     TYPE        CLUSTER-IP    EXTERNAL-IP   PORT(S)    AGE
   production-auto-deploy   ClusterIP   10.30.13.90   <none>        5000/TCP   7d14h
   production-postgres      ClusterIP   10.30.4.57    <none>        5432/TCP   7d14h
   ```

1. 次のコマンドを使用して、PostgreSQLのポッド名を取得します。この例では、ポッド名は`production-postgres-5db86568d7-qxlxv`です。

   ```shell
   $ kubectl get pod --namespace "$APP_NAMESPACE" -l app=production-postgres
   NAME                                   READY   STATUS    RESTARTS   AGE
   production-postgres-5db86568d7-qxlxv   1/1     Running   0          7d14h
   ```

1. 次のコマンドを使用してポッドに接続します:

   ```shell
   kubectl exec -it production-postgres-5db86568d7-qxlxv --namespace "$APP_NAMESPACE" -- bash
   ```

1. 接続したら、次のコマンドでダンプファイルを作成します。

   - `SERVICE_NAME`は前の手順で取得したサービス名です。
   - `USERNAME`は、PostgreSQL用に構成したユーザー名です。デフォルトは`user`です。
   - `DATABASE_NAME`は通常、環境名です。

   - データベースパスワードの入力を求められた場合、デフォルトは`testing-password`です。

     ```shell
     ## Format is:
     # pg_dump -h SERVICE_NAME -U USERNAME DATABASE_NAME > /tmp/backup.sql

     pg_dump -h production-postgres -U user production > /tmp/backup.sql
     ```

1. バックアップダンプが完了したら、Kubernetes execプロセスを<kbd>Control</kbd>-<kbd>D</kbd>または`exit`で終了します。

1. 次のコマンドを使用して、ダンプファイルをダウンロードします。:

   ```shell
   kubectl cp --namespace "$APP_NAMESPACE" production-postgres-5db86568d7-qxlxv:/tmp/backup.sql backup.sql
   ```

## 永続ボリュームを保持する {#retain-persistent-volumes}

デフォルトでは、PostgreSQLの基盤となるデータを格納するために使用される[永続ボリューム](https://kubernetes.io/docs/concepts/storage/persistent-volumes/)は、ボリュームを使用するポッドとポッドクレームが削除されると、`Delete`としてマークされます。

これは、新しい8.2.1 PostgreSQLを選択すると、古い0.7.1 PostgreSQLが削除され、永続ボリュームも削除されるため、重要です。

これは、次のコマンドを使用して確認できます。:

```shell
$ kubectl get pv
NAME                                       CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS   CLAIM                                                     STORAGECLASS   REASON   AGE
pvc-0da80c08-5239-11ea-9c8d-42010a8e0096   8Gi        RWO            Delete           Bound    minimal-ruby-app-4349298-staging/staging-postgres         standard                7d22h
pvc-9085e3d3-5239-11ea-9c8d-42010a8e0096   8Gi        RWO            Delete           Bound    minimal-ruby-app-4349298-production/production-postgres   standard                7d22h
```

古い0.7.1 PostgreSQLが削除されても、永続ボリュームを保持するには、保持ポリシーを`Retain`に変更します。この例では、クレーム名を見て永続ボリューム名を見つけます。`minimal-ruby-app-4349298`アプリケーションのステージングと本番環境のボリュームを保持することに関心があるため、ここでのボリューム名は`pvc-0da80c08-5239-11ea-9c8d-42010a8e0096`と`pvc-9085e3d3-5239-11ea-9c8d-42010a8e0096`です:

```shell
$ kubectl patch pv  pvc-0da80c08-5239-11ea-9c8d-42010a8e0096 -p '{"spec":{"persistentVolumeReclaimPolicy":"Retain"}}'
persistentvolume/pvc-0da80c08-5239-11ea-9c8d-42010a8e0096 patched
$ kubectl patch pv  pvc-9085e3d3-5239-11ea-9c8d-42010a8e0096 -p '{"spec":{"persistentVolumeReclaimPolicy":"Retain"}}'
persistentvolume/pvc-9085e3d3-5239-11ea-9c8d-42010a8e0096 patched
$ kubectl get pv
NAME                                       CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS   CLAIM                                                     STORAGECLASS   REASON   AGE
pvc-0da80c08-5239-11ea-9c8d-42010a8e0096   8Gi        RWO            Retain           Bound    minimal-ruby-app-4349298-staging/staging-postgres         standard                7d22h
pvc-9085e3d3-5239-11ea-9c8d-42010a8e0096   8Gi        RWO            Retain           Bound    minimal-ruby-app-4349298-production/production-postgres   standard                7d22h
```

## 新しいPostgreSQLをインストールする {#install-new-postgresql}

{{< alert type="warning" >}}

新しいバージョンのPostgreSQLを使用すると、古い0.7.1 PostgreSQLが削除されます。基になるデータが削除されないようにするには、[永続ボリューム](#retain-persistent-volumes)を保持することを選択できます。

{{< /alert >}}

{{< alert type="note" >}}

`AUTO_DEVOPS_POSTGRES_CHANNEL`、`AUTO_DEVOPS_POSTGRES_DELETE_V1`、および`POSTGRES_VERSION`の変数の[スコープ](../../ci/environments/_index.md#limit-the-environment-scope-of-a-cicd-variable)を特定の環境（`staging`など）に設定することもできます。

{{< /alert >}}

1. `AUTO_DEVOPS_POSTGRES_CHANNEL`を`2`に設定します。これにより、新しい8.2.1ベースのPostgreSQLの使用が選択され、古い0.7.1ベースのPostgreSQLが削除されます。
1. `AUTO_DEVOPS_POSTGRES_DELETE_V1`を空でない値に設定します。このフラグは、データベースの誤った削除を防ぐための安全策です。
   <!-- DO NOT REPLACE when upgrading GitLab's supported version. This is NOT related to GitLab's PostgreSQL version support, but the one deployed by Auto DevOps. -->
1. `POSTGRES_VERSION`が設定されている場合は、`9.6.16`以降に設定されていることを確認してください。これは、Auto DevOpsでサポートされている最小PostgreSQLのバージョンです。[利用可能なタグ](https://hub.docker.com/r/bitnami/postgresql/tags)の一覧も参照してください。
1. `PRODUCTION_REPLICAS`を`0`に設定します。他の環境では、[環境スコープ](../../ci/environments/_index.md#limit-the-environment-scope-of-a-cicd-variable)で`REPLICAS`を使用します。
1. `DB_INITIALIZE`または`DB_MIGRATE`の変数を設定した場合は、変数を削除するか、変数の名前を一時的に`XDB_INITIALIZE`または`XDB_MIGRATE`に変更して、それらを効果的に無効にします。
1. ブランチの新しいCIパイプラインを実行します。この場合、`main`の新しいCIパイプラインを実行します。
1. パイプラインが成功すると、アプリケーションは新しいPostgreSQLがインストールされた状態でアップグレードされます。この時点ではレプリカは存在しないため、アプリケーションにトラフィックは提供されません (新しいデータが入力されないようにするため)。

## 復元する {#restore}

1. 新しいPostgreSQLのポッド名を取得します。この例では、ポッド名は`production-postgresql-0`です:

   ```shell
   $ kubectl get pod --namespace "$APP_NAMESPACE" -l app=postgresql
   NAME                      READY   STATUS    RESTARTS   AGE
   production-postgresql-0   1/1     Running   0          19m
   ````

1. バックアップ手順からポッドにダンプファイルをコピーします。:

   ```shell
   kubectl cp --namespace "$APP_NAMESPACE" backup.sql production-postgresql-0:/tmp/backup.sql
   ```

1. ポッドに接続します:

   ```shell
   kubectl exec -it production-postgresql-0 --namespace "$APP_NAMESPACE" -- bash
   ```

1. ポッドに接続したら、次のコマンドを実行してデータベースを復元します。

   - データベースパスワードの入力を求められた場合、デフォルトは`testing-password`です。
   - `USERNAME`は、PostgreSQL用に構成したユーザー名です。デフォルトは`user`です。
   - `DATABASE_NAME`は通常、環境名です。

   ```shell
   ## Format is:
   # psql -U USERNAME -d DATABASE_NAME < /tmp/backup.sql

   psql -U user -d production < /tmp/backup.sql
   ```

1. 復元が完了したら、データが正しく復元されたことを確認できます。`psql`を使用して、データのスポットチェックを実行できます。

## アプリケーションを元に戻す {#reinstate-your-application}

データベースが復元されたことに満足したら、次の手順を実行してアプリケーションを元に戻します:

1. 以前に削除または無効にした場合は、`DB_INITIALIZE`および`DB_MIGRATE`変数を復元します。
1. `PRODUCTION_REPLICAS`または`REPLICAS`変数を元の値に復元します。
1. ブランチの新しいCIパイプラインを実行します。この場合、`main`の新しいCIパイプラインを実行します。パイプラインが成功すると、アプリケーションは以前と同様にトラフィックを処理するようになります。
