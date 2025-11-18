---
stage: Create
group: Import
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
gitlab_dedicated: yes
title: インポートとエクスポートの設定
description: "インポートソース、エクスポートの制限、ファイルサイズ、ユーザーマッピング、プレースホルダユーザーの設定を、GitLab Self-Managedインスタンスで構成します。"
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

インポートおよびエクスポート関連機能の設定。

## 許可するインポートソースを設定する {#configure-allowed-import-sources}

他のシステムからプロジェクトをインポートするには、そのシステムの[インポートソース](../../user/gitlab_com/_index.md#default-import-sources)を有効にする必要があります。

1. 管理者アクセスレベルを持つユーザーとしてGitLabにサインインします。
1. 左側のサイドバーの下部で、**管理者**を選択します。
1. **設定** > **一般**を選択します。
1. **インポートとエクスポートの設定**セクションを展開します。
1. 許可する**ソースをインポート**を選択します。
1. **変更を保存**を選択します。

## プロジェクトのエクスポートを有効にする {#enable-project-export}

[プロジェクトとそのデータ](../../user/project/settings/import_export.md#export-a-project-and-its-data)のエクスポートを有効にするには、次の手順に従います。

1. 管理者アクセスレベルを持つユーザーとしてGitLabにサインインします。
1. 左側のサイドバーの下部で、**管理者**を選択します。
1. **設定** > **一般**を選択します。
1. **インポートとエクスポートの設定**セクションを展開します。
1. **プロジェクトのエクスポート**までスクロールします。
1. **有効**チェックボックスをオンにします。
1. **変更を保存**を選択します。

## 直接転送によるグループとプロジェクトの移行を有効にする {#enable-migration-of-groups-and-projects-by-direct-transfer}

{{< history >}}

- GitLab 15.8で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/383268)されました。
- GitLab 18.3で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/461326)になりました。

{{< /history >}}

{{< alert type="warning" >}}

GitLab 16.1以前では、[スケジュールされたスキャン実行ポリシー](../../user/application_security/policies/scan_execution_policies.md)で直接転送を**使用しないでください**。直接転送を使用する場合は、まずGitLab 16.2にアップグレードし、適用対象のプロジェクトでセキュリティポリシーボットが有効になっていることを確認してください。

{{< /alert >}}

直接転送によるグループとプロジェクトの移行は、デフォルトでは無効になっています。直接転送によるグループとプロジェクトの移行を有効にするには、次の手順に従います。

1. 管理者アクセスレベルを持つユーザーとしてGitLabにサインインします。
1. 左側のサイドバーの下部で、**管理者**を選択します。
1. **設定** > **一般**を選択します。
1. **インポートとエクスポートの設定**セクションを展開します。
1. **GitLabグループとプロジェクトを直接転送して移行できるようにする**までスクロールします。
1. **有効**チェックボックスをオンにします。
1. **変更を保存**を選択します。

この設定は、APIでは`bulk_import_enabled`属性として[使用できます](../../api/settings.md#available-settings)。

## 管理者によるサイレントエクスポートを有効にする {#enable-silent-admin-exports}

{{< history >}}

- GitLab 17.0で`export_audit_events`[フラグ](../feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/151278)されました。デフォルトでは無効になっています。
- GitLab 17.1で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/153351)になりました。機能フラグ`export_audit_events`は削除されました。
- GitLab 17.1でファイルエクスポートのダウンロード用に[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/152143)されました。

{{< /history >}}

インスタンス管理者が[プロジェクトまたはグループファイルのエクスポート](../../user/project/settings/import_export.md)をトリガーするか、エクスポートファイルをダウンロードした際に、[監査イベント](../compliance/audit_event_reports.md)が生成されないように、管理者によるサイレントエクスポートを有効にします。管理者以外のユーザーによるエクスポートは、引き続き監査イベントを生成します。

管理者によるプロジェクトおよびグループファイルのサイレントエクスポートを有効にするには、次の手順に従います。

1. 左側のサイドバーの下部で、**管理者**を選択します。
1. **設定** > **一般**を選択し、**設定のインポートとエクスポート**を展開します。
1. **管理者によるサイレントエクスポート**までスクロールします。
1. **有効**チェックボックスをオンにします。

## 管理者へのコントリビュートのマッピングを許可する {#allow-contribution-mapping-to-administrators}

{{< history >}}

- GitLab 17.5で`importer_user_mapping`[フラグ](../feature_flags/_index.md)とともに導入されました。デフォルトでは無効になっています。
- GitLab 17.7の[GitLab.comおよびGitLab Self-Managedで有効](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/175371)になりました。
- GitLab 18.3で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/508944)になりました。機能フラグ`importer_user_mapping`は削除されました。

{{< /history >}}

インポートされたユーザーのコントリビュートを管理者にマッピングできるようにします。

インポートされたユーザーのコントリビュートを管理者にマッピングできるようにするには、次の手順に従います。

1. 左側のサイドバーの下部で、**管理者**を選択します。
1. **設定** > **一般**を選択し、**設定のインポートとエクスポート**を展開します。
1. **管理者へのコントリビュートのマッピングを許可する**までスクロールします。
1. **有効**チェックボックスをオンにします。

## 管理者がプレースホルダーユーザーを再割り当てする際に確認をスキップする {#skip-confirmation-when-administrators-reassign-placeholder-users}

{{< history >}}

- GitLab 18.1で`importer_user_mapping_allow_bypass_of_confirmation`[フラグ](../feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/534330)されました。デフォルトでは無効になっています。

{{< /history >}}

{{< alert type="flag" >}}

この機能の利用可否は、機能フラグによって制御されます。詳細については、履歴を参照してください。

{{< /alert >}}

前提要件:

- GitLabインスタンスで、[ユーザー代理が無効になっていない](../../api/rest/authentication.md#disable-impersonation)ことを確認してください。

管理者がプレースホルダーユーザーを再割り当てする際に確認をスキップするには、次の手順に従います。

1. 左側のサイドバーの下部で、**管理者**を選択します。
1. **設定** > **一般**を選択します。
1. **インポートとエクスポートの設定**を展開します。
1. **管理者がプレースホルダーユーザーを再割り当てする際に確認をスキップする**で**有効**チェックボックスをオンにします。

この設定を有効にすると、管理者は、次のいずれかの状態の非ボットユーザーにコントリビュートとメンバーシップを再割り当てできます。

- `active`
- `banned`
- `blocked`
- `blocked_pending_approval`
- `deactivated`
- `ldap_blocked`

## 最大エクスポートサイズ {#max-export-size}

{{< history >}}

- GitLab 15.0で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/86124)されました。

{{< /history >}}

GitLabでのエクスポート時の最大ファイルサイズを変更するには、次の手順に従います。

1. 左側のサイドバーの下部で、**管理者**を選択します。
1. **設定** > **一般**を選択し、**設定のインポートとエクスポート**を展開します。
1. **最大エクスポートサイズ(MiB)**の値を変更し、サイズを増減させます。

## 最大インポートサイズ {#max-import-size}

GitLabでのインポート時の最大ファイルサイズを変更するには、次の手順に従います。

1. 左側のサイドバーの下部で、**管理者**を選択します。
1. **設定** > **一般**を選択します。
1. **インポートとエクスポートの設定**を展開します。
1. **最大インポートサイズ(MiB)**の値を変更して、サイズを増減させます。

この設定は、[GitLabエクスポートファイルからインポート](../../user/project/settings/import_export.md#import-a-project-and-its-data)されたリポジトリにのみ適用されます。

Webサーバーに設定されている値よりも大きいサイズを選択した場合、エラーが発生することがあります。詳細については、[トラブルシューティングセクション](account_and_limit_settings.md#troubleshooting)を参照してください。

GitLab.comのリポジトリサイズの制限については、[アカウントと制限の設定](../../user/gitlab_com/_index.md#account-and-limit-settings)を参照してください。

## インポートできるリモートファイルの最大サイズ {#maximum-remote-file-size-for-imports}

{{< history >}}

- GitLab 16.3で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/384976)されました。

{{< /history >}}

デフォルトでは、外部オブジェクトストレージ（AWSなど）からインポートできるリモートファイルの最大サイズは10 GiBです。

この設定を変更するには、次の手順に従います。

1. 左側のサイドバーの下部で、**管理者**を選択します。
1. **設定** > **一般**を選択します。
1. **インポートとエクスポートの設定**を展開します。
1. **インポートできるリモートファイルの最大サイズ(MiB)**に値を入力します。ファイルサイズの制限がない場合は`0`に設定します。

## 直接転送によりインポートできるダウンロードファイルの最大サイズ {#maximum-download-file-size-for-imports-by-direct-transfer}

{{< history >}}

- GitLab 16.3で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/384976)されました。

{{< /history >}}

デフォルトでは、直接転送によりインポートできるダウンロードファイルの最大サイズは5 GiBです。

この設定を変更するには、次の手順に従います。

1. 左側のサイドバーの下部で、**管理者**を選択します。
1. **設定** > **一般**を選択します。
1. **インポートとエクスポートの設定**を展開します。
1. **最大ダウンロードファイルサイズ(MiB)**に値を入力します。ファイルサイズの制限がない場合は`0`に設定します。

## インポートされたアーカイブの最大解凍ファイルサイズ {#maximum-decompressed-file-size-for-imported-archives}

{{< history >}}

- GitLab 16.3で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/128218)されました。
- GitLab 16.4で、**最大解凍サイズ**フィールドの名前が、**インポートからのアーカイブの最大解凍ファイルサイズ**に[変更](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/130081)されました。

{{< /history >}}

[ファイルのエクスポート](../../user/project/settings/import_export.md)または[直接転送](../../user/group/import/_index.md)を使用してプロジェクトをインポートする場合、インポートされたアーカイブの最大解凍ファイルサイズを指定できます。デフォルト値は25 GiBです。

圧縮ファイルをインポートする場合、解凍後のサイズが最大解凍ファイルサイズの制限を超えないようにする必要があります。解凍後のサイズが設定された制限を超えると、次のエラーが返されます。

```plaintext
Decompressed archive size validation failed.
```

この設定を変更するには、次の手順に従います。

1. 左側のサイドバーの下部で、**管理者**を選択します。
1. **設定** > **一般**を選択します。
1. **インポートとエクスポートの設定**を展開します。
1. **インポートからのアーカイブの最大解凍ファイルサイズ(MiB)**に別の値を設定します。

## アーカイブファイル解凍のタイムアウト {#timeout-for-decompressing-archived-files}

{{< history >}}

- GitLab 16.4で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/128218)されました。

{{< /history >}}

[プロジェクトをインポート](../../user/project/settings/import_export.md)する場合、インポートされたアーカイブを解凍する際の最大タイムアウト時間を指定できます。デフォルト値は210秒です。

GitLabでのインポートの最大解凍ファイルサイズを変更するには、次の手順に従います。

1. 左側のサイドバーの下部で、**管理者**を選択します。
1. **設定** > **一般**を選択します。
1. **インポートとエクスポートの設定**を展開します。
1. **アーカイブファイルの解凍のタイムアウト(秒)**に別の値を設定します。

## 同時インポートジョブの最大数 {#maximum-number-of-simultaneous-import-jobs}

{{< history >}}

- GitLab 16.11で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/143875)されました。

{{< /history >}}

次のインポーターに対して、同時に実行されるインポートジョブの最大数を指定できます。

- [GitHubインポーター](../../user/project/import/github.md)
- [Bitbucket Cloudインポーター](../../user/project/import/bitbucket.md)
- [Bitbucket Serverインポーター](../../user/project/import/bitbucket_server.md)

サーバーの過負荷を避けるため、マージリクエストにはハードコードされた制限があります。そのため、マージリクエストのインポート時にはジョブ数の制限は適用されません。

デフォルトのジョブ数の制限は次のとおりです。

- GitHubインポーター: 1,000
- Bitbucket CloudおよびBitbucket Serverインポーター: 100。Bitbucketインポーターについては、適切なデフォルト値がまだ決定されていないため、制限が低めに設定されています。そのため、インスタンス管理者はより高い制限を試すことが推奨されます。

この設定を変更するには、次の手順に従います。

1. 左側のサイドバーの下部で、**管理者**を選択します。
1. **設定** > **一般**を選択します。
1. **インポートとエクスポートの設定**を展開します。
1. 目的のインポーターの**同時インポートジョブの最大数**に別の値を設定します。

## バッチエクスポートジョブの同時実行最大数 {#maximum-number-of-simultaneous-batch-export-jobs}

{{< history >}}

- GitLab 17.6で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/169122)されました。

{{< /history >}}

直接転送によるエクスポートは、大量のリソースを消費する可能性があります。データベースやSidekiqプロセスを使い果たさないように、管理者は`concurrent_relation_batch_export_limit`設定を調整できます。

デフォルト値は`8`ジョブで、これは[最大40 RPSまたは2,000ユーザーのリファレンスアーキテクチャ](../reference_architectures/2k_users.md)に対応しています。`PG::QueryCanceled: ERROR: canceling statement due to statement timeout`エラーが発生したり、Sidekiqのメモリ制限によってジョブが中断されたりする場合は、この数値を減らすことをおすすめします。十分なリソースがある場合は、この数値を増やすことで、より多くの同時エクスポートジョブを処理できます。

この設定を変更するには、`concurrent_relation_batch_export_limit`を指定して、`/api/v4/application/settings`にAPIリクエストを送信します。詳細については、[アプリケーション設定API](../../api/settings.md)を参照してください。

### エクスポートのバッチサイズ {#export-batch-size}

{{< history >}}

- GitLab 18.2で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/194607)されました。

{{< /history >}}

メモリ使用量とデータベースの負荷をさらに管理するには、`relation_export_batch_size`設定を使用して、エクスポートの際に各バッチで処理されるレコード数を制御します。

デフォルト値は、1バッチあたり`50`レコードです。この設定を変更するには、`relation_export_batch_size`を指定して、`/api/v4/application/settings`にAPIリクエストを送信します。詳細については、[アプリケーション設定API](../../api/settings.md)を参照してください。

## トラブルシューティング {#troubleshooting}

## エラー: `Help page documentation base url is blocked: execution expired` {#error-help-page-documentation-base-url-is-blocked-execution-expired}

[インポートソース](#configure-allowed-import-sources)などのアプリケーション設定を有効にしている場合、`Help page documentation base url is blocked: execution expired`エラーが発生する場合があります。このエラーを回避するには、次の手順に従います。

1. `docs.gitlab.com`、または[ヘルプドキュメントページのリダイレクトURL](help_page.md#redirect-help-pages)を[許可リスト](../../security/webhooks.md#allow-outbound-requests-to-certain-ip-addresses-and-domains)に追加します。
1. **変更を保存**を選択します。
