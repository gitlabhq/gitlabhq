---
stage: Software Supply Chain Security
group: Pipeline Security
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: プロジェクトレベルのセキュアファイル
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 15.7で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/350748)になり、機能フラグ`ci_secure_files`が削除されました。

{{< /history >}}

この機能は、[GitLab Incubation Engineering](https://handbook.gitlab.com/handbook/engineering/development/incubation/)が開発した[Mobile DevOps](../mobile_devops/_index.md)の一部です。この機能はまだ開発中ですが、次のことができます。

- [機能のリクエスト](https://gitlab.com/gitlab-org/incubation-engineering/mobile-devops/feedback/-/issues/new?issuable_template=feature_request)
- [バグの報告](https://gitlab.com/gitlab-org/incubation-engineering/mobile-devops/feedback/-/issues/new?issuable_template=report_bug)
- [フィードバックの共有](https://gitlab.com/gitlab-org/incubation-engineering/mobile-devops/feedback/-/issues/new?issuable_template=general_feedback)

CI/CDパイプラインで使用するために最大100個のファイルをセキュアファイルとして安全に保存できます。これらのファイルは、プロジェクトのリポジトリの外部に安全に保存され、バージョン管理は行われません。これらのファイルに機密情報を安全に保存できます。セキュアファイルはプレーンテキストとバイナリの両方のファイルタイプをサポートしますが、5 MB以下である必要があります。

セキュアファイルは、プロジェクト設定、または[secure files API](../../api/secure_files.md)で管理できます。

セキュアファイルは、[download-secure-files](https://gitlab.com/gitlab-org/incubation-engineering/mobile-devops/download-secure-files)ツールを使用して[CI/CDジョブによってダウンロードして使用](#use-secure-files-in-cicd-jobs)できます。

## セキュアファイルをプロジェクトに追加する

セキュアファイルをプロジェクトに追加するには:

1. 左側のサイドバーで、**検索または移動**を選択し、プロジェクトを見つけます。
1. **設定 > CI/CD**を選択します。
1. **セキュアファイル**セクションを展開します。
1. **ファイルをアップロード**を選択します。
1. アップロードするファイルを見つけ、**オープン**を選択すると、すぐにファイルのアップロードが開始されます。アップロードが完了すると、ファイルがリストに表示されます。

## CI/CDジョブでセキュアファイルを使用する

CI/CDジョブでセキュアファイルを使用するには、[`download-secure-files`](https://gitlab.com/gitlab-org/incubation-engineering/mobile-devops/download-secure-files)ツールを使用して、ジョブでファイルをダウンロードする必要があります。ダウンロード後、他のスクリプトコマンドと一緒に使用できます。

`download-secure-files`ツールをダウンロードして実行するために、ジョブの`script`セクションにコマンドを追加します。ファイルは、プロジェクトのルートにある`.secure_files`ディレクトリにダウンロードされます。セキュアファイルのダウンロード場所を変更するには、`SECURE_FILES_DOWNLOAD_PATH`[CI/CD変数](../variables/_index.md)にパスを設定します。

次に例を示します。

```yaml
test:
  variables:
    SECURE_FILES_DOWNLOAD_PATH: './where/files/should/go/'
  script:
    - curl --silent "https://gitlab.com/gitlab-org/incubation-engineering/mobile-devops/download-secure-files/-/raw/main/installer" | bash
```

{{< alert type="warning" >}}

`download-secure-files`ツールで読み込まれたファイルの内容は、ジョブログの出力で[マスク](../variables/_index.md#mask-a-cicd-variable)されません。特に機密情報を含んでいる可能性のある出力をログに記録する場合は、ジョブログにセキュアファイルの内容を出力しないようにしてください。

{{< /alert >}}

## セキュリティの詳細

プロジェクトレベルのセキュアファイルは、[`Ci::SecureFileUploader`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/app/uploaders/ci/secure_file_uploader.rb)インターフェースを使用して、[Lockbox](https://github.com/ankane/lockbox) Ruby gemによってアップロード時に暗号化されます。このインターフェースは、アップロード中にソースファイルのSHA256チェックサムを生成します。このチェックサムは、ダウンロード時にファイルの内容を検証するときに使用できるようにレコードとともにデータベースに保持されます。

ファイルが作成されるたびに各ファイルに[一意の暗号化キー](https://gitlab.com/gitlab-org/gitlab/-/blob/master/app/models/ci/secure_file.rb#L27)が生成され、データベースに保持されます。暗号化されたアップロードファイルは、[GitLabインスタンスの設定](../../administration/cicd/secure_files.md)に応じて、ローカルストレージまたはオブジェクトストレージに保存されます。

個別のファイルは、[secure files download API](../../api/secure_files.md#download-secure-file)で取得できます。メタデータは、[リスト](../../api/secure_files.md#list-project-secure-files)または[表示](../../api/secure_files.md#show-secure-file-details)APIエンドポイントで取得できます。ファイルは、[`download-secure-files`](https://gitlab.com/gitlab-org/incubation-engineering/mobile-devops/download-secure-files)ツールでも取得できます。このツールは、各ファイルのチェックサムをダウンロード時に自動的に検証します。

デベロッパーロール以上を持つすべてのプロジェクトメンバーは、プロジェクトレベルのセキュアファイルにアクセスできます。プロジェクトレベルのセキュアファイルとのやり取りは監査イベントに含まれていませんが、[イシュー117](https://gitlab.com/gitlab-org/incubation-engineering/mobile-devops/readme/-/issues/117)でこの機能の追加が提案されています。
