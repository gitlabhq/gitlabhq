---
stage: Runtime
group: Geo
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
gitlab_dedicated: no
title: Geoとオブジェクトストレージ
---

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

{{< history >}}

- オブジェクトストレージに保存されているファイルの検証は、GitLab 16.4で[導入](https://gitlab.com/groups/gitlab-org/-/epics/8056)されました。`geo_object_storage_verification`という[機能フラグ](../../feature_flags/_index.md)付き。デフォルトでは有効になっています。

{{< /history >}}

Geoは、オブジェクトストレージ（AWS S3、またはその他の互換性のあるオブジェクトストレージ）と組み合わせて使用できます。

**セカンダリ**サイトは、次のいずれかを使用できます:

- **プライマリ**サイトと同じストレージバケット。
- レプリケーションされたストレージバケット。
- プライマリがローカルストレージを使用している場合は、ローカルストレージ。

ファイルのストレージ方法（ローカルまたはオブジェクトストレージ）はデータベースに記録され、データベースは**プライマリ**Geoサイトから**セカンダリ**Geoサイトにレプリケーションされます。

アップロードされたオブジェクトにアクセスすると、ストレージ方法（ローカルまたはオブジェクトストレージ）がデータベースから取得されるため、**セカンダリ**Geoサイトは**プライマリ**Geoサイトのストレージ方法と一致する必要があります。

したがって、**プライマリ**Geoサイトがオブジェクトストレージを使用している場合、**セカンダリ**Geoサイトもそれを使用する必要があります。

利用するには:

- GitLabにレプリケーションを管理させるには、[GitLab管理のオブジェクトストレージレプリケーションの有効化](#enabling-gitlab-managed-object-storage-replication)に従ってください。
- サードパーティサービスにレプリケーションを管理させるには、[サードパーティのレプリケーションサービス](#third-party-replication-services)に従ってください。

[GitLabにおけるオブジェクトストレージの使用の詳細については、こちらをご覧ください](../../object_storage.md)。

## オブジェクトストレージの検証 {#object-storage-verification}

Geoは、オブジェクトストレージに保存されているファイルを検証して、プライマリサイトとセカンダリサイト間のデータ整合性を確保します。

{{< alert type="warning" >}}オブジェクトストレージの検証を無効にすることはお勧めできません。`geo_object_storage_verification`機能フラグを無効にすると、GitLabは既存のすべての検証状態レコードを非同期的に削除します。{{< /alert >}}

`geo_object_storage_verification`機能フラグが無効になっている場合:

- Geo検証ワーカー（`Geo::VerificationBatchWorker`）はSidekiqログに表示されることがありますが、検証は行われません。
- 検証レコードのクリーンアップ中に、残りのレコードを処理するためにワーカーがエンキューされる場合があります。

## GitLab管理のオブジェクトストレージレプリケーションの有効化 {#enabling-gitlab-managed-object-storage-replication}

{{< history >}}

- GitLab 15.1で[導入](https://gitlab.com/groups/gitlab-org/-/epics/5551)されました。

{{< /history >}}

{{< alert type="warning" >}}

問題が発生した場合は、個々のファイルを手動で削除しないでください。[データの不整合](#inconsistencies-after-the-migration)につながる可能性があります。

{{< /alert >}}

**セカンダリ**サイトは、ローカルファイルシステムまたはオブジェクトストレージに保存されているかどうかにかかわらず、**プライマリ**サイトによって保存されたファイルをレプリケートすることができます。

GitLabレプリケーションを有効にするには:

1. 左側のサイドバーの下部で、**管理者**を選択します。
1. **Geo** > **サイト**を選択します。
1. 左側のサイドバーの下部にある**セカンダリ**サイトで**編集**を選択します。
1. **Synchronization Settings**（同期設定）セクションで、**このセカンダリサイトで、オブェクトストレージ上のコンテンツの複製を許可します**チェックボックスを見つけて有効にします。

LFSについては、ドキュメントに従って[LFSオブジェクトストレージを設定](../../lfs/_index.md#storing-lfs-objects-in-remote-object-storage)します。

CIジョブアーティファクトについては、[ジョブアーティファクトオブジェクトストレージ](../../cicd/job_artifacts.md#using-object-storage)を設定するための同様のドキュメントがあります。

ユーザーのアップロードについては、[アップロードオブジェクトストレージ](../../uploads.md#using-object-storage)を設定するための同様のドキュメントがあります。

**プライマリ**サイトのファイルをオブジェクトストレージに移行する場合は、**セカンダリ**をいくつかの方法で設定できます:

- まったく同じオブジェクトストレージを使用します。
- 別のオブジェクトストアを使用しますが、オブジェクトストレージソリューションに組み込まれているレプリケーションを活用します。
- 別のオブジェクトストアを使用し、**このセカンダリサイトで、オブェクトストレージ上のコンテンツの複製を許可します**設定を有効にします。

**このセカンダリサイトで、オブェクトストレージ上のコンテンツの複製を許可します**設定が無効になっており、すべてのファイルをローカルストレージからオブジェクトストレージに移行した場合、多くの**管理者** > **Geo** > **サイト**の進行状況バーに**同期対象がありません**と表示されます。

{{< alert type="warning" >}}

データの損失を避けるために、**このセカンダリサイトで、オブェクトストレージ上のコンテンツの複製を許可します**設定は、プライマリサイトとセカンダリサイトに別々のオブジェクトストアを使用している場合にのみ有効にする必要があります。

{{< /alert >}}

GitLabは、次の両方のケースをサポートしていません:

- **プライマリ**サイトがローカルストレージを使用している。
- **セカンダリ**サイトがオブジェクトストレージを使用している。

### 移行後の不整合 {#inconsistencies-after-the-migration}

ローカルストレージからオブジェクトストレージに移行すると、データの不整合が発生する可能性があり、詳細については[オブジェクトストレージのトラブルシューティングセクション](../../object_storage.md#inconsistencies-after-migrating-to-object-storage)で説明されています。

## サードパーティのレプリケーションサービス {#third-party-replication-services}

Amazon S3を使用している場合は、[Cross-Region Replication（CRR）](https://docs.aws.amazon.com/AmazonS3/latest/dev/crr.html)を使用して、**プライマリ**サイトで使用されているバケットと**セカンダリ**サイトで使用されているバケット間で自動レプリケーションを行うことができます。

Google Cloud Storageを使用している場合は、[Multi-Regional Storage](https://cloud.google.com/storage/docs/storage-classes#multi-regional)の使用を検討してください。または、[Storage Transfer Service](https://cloud.google.com/storage-transfer/docs/overview)を使用することもできますが、これは毎日の同期のみをサポートしています。

手動同期の場合、または`cron`でスケジュールされている場合は、以下を参照してください:

- [`s3cmd sync`](https://s3tools.org/s3cmd-sync)
- [`gsutil rsync`](https://cloud.google.com/storage/docs/gsutil/commands/rsync)
