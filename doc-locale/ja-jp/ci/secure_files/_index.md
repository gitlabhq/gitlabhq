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

- GitLab 15.7で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/350748)になり、機能フラグ`ci_secure_files`は削除されました。

{{< /history >}}

この機能は[Mobile DevOps](../mobile_devops/_index.md)の一部です。この機能はまだ開発中ですが、次のことができます:

- [機能のリクエスト](https://gitlab.com/gitlab-org/incubation-engineering/mobile-devops/feedback/-/issues/new?issuable_template=feature_request)。
- [バグの報告](https://gitlab.com/gitlab-org/incubation-engineering/mobile-devops/feedback/-/issues/new?issuable_template=report_bug)。
- [フィードバックの共有](https://gitlab.com/gitlab-org/incubation-engineering/mobile-devops/feedback/-/issues/new?issuable_template=general_feedback)。

CI/CDパイプラインで使用するために最大100個のファイルをセキュアファイルとして安全に保存できます。これらのファイルは、プロジェクトのリポジトリの外部に安全に保存され、バージョン管理は行われません。これらのファイルに機密情報を安全に保存できます。セキュアファイルは平文とバイナリの両方のファイル形式をサポートしますが、5 MB以下である必要があります。

セキュアファイルは、プロジェクト設定、または[セキュアファイルのAPI](../../api/secure_files.md)で管理できます。

セキュアファイルは、[CI/CDジョブでダウンロードおよび使用](#use-secure-files-in-cicd-jobs)できます。[`glab securefile`](https://gitlab.com/gitlab-org/cli/-/tree/main/docs/source/securefile)コマンドを使用します。

## セキュアファイルをプロジェクトに追加する {#add-a-secure-file-to-a-project}

セキュアファイルをプロジェクトに追加するには:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。[新しいナビゲーションをオンにした](../../user/interface_redesign.md#turn-new-navigation-on-or-off)場合、このフィールドは上部のバーに表示されます。
1. **設定** > **CI/CD**を選択します。
1. **Secure Files**（セキュアファイル）セクションを展開します。
1. **ファイルをアップロード**を選択します。
1. アップロードするファイルを見つけ、**オープン**を選択すると、すぐにファイルのアップロードが開始されます。アップロードが完了すると、ファイルがリストに表示されます。

## CI/CDジョブでセキュアファイルを使用する {#use-secure-files-in-cicd-jobs}

{{< alert type="warning" >}}

セキュアファイルの内容は、ジョブログ出力では[マスクされません](../variables/_index.md#mask-a-cicd-variable)。特に機密情報を含んでいる可能性のある出力をログに記録する場合は、ジョブログにセキュアファイルの内容を出力しないようにしてください。

{{< /alert >}}

### `glab`ツールを使用する {#with-the-glab-tool}

[`glab`](https://gitlab.com/gitlab-org/cli/)で1つまたは複数のセキュアファイルをダウンロードするには、CI/CDジョブで`cli` Dockerイメージを使用できます。

#### プロジェクト内のすべてのファイルをダウンロード {#download-all-the-files-in-a-project}

プロジェクト内のすべてのセキュアファイルをダウンロードするには:

```yaml
test:
  image: registry.gitlab.com/gitlab-org/cli:latest
  script:
    - glab auth login --job-token $CI_JOB_TOKEN --hostname $CI_SERVER_FQDN --api-protocol $CI_SERVER_PROTOCOL
    - glab -R $CI_PROJECT_PATH securefile download --all --output-dir="where/to/save"
```

この例では、すべての変数は自動的に利用可能な[定義済み変数](../variables/predefined_variables.md)です。

#### プロジェクト内の単一ファイルをダウンロード {#download-a-single-file-in-a-project}

```yaml
test:
  image: registry.gitlab.com/gitlab-org/cli:latest
  script:
    - glab auth login --job-token $CI_JOB_TOKEN --hostname $CI_SERVER_FQDN --api-protocol $CI_SERVER_PROTOCOL
    - glab -R $CI_PROJECT_PATH securefile download $SECURE_FILE_ID --path="where/to/save/file.txt"
```

`SECURE_FILE_ID` CI/CD変数は、たとえば[CI/CD設定](../variables/_index.md#define-a-cicd-variable-in-the-ui)や[パイプラインの手動実行](../pipelines/_index.md#run-a-pipeline-manually)などで、ジョブに明示的に渡す必要があります。他のすべての変数は、自動的に利用可能な[定義済み変数](../variables/predefined_variables.md)です。

または、Dockerイメージを使用する代わりに、[バイナリをダウンロード](https://gitlab.com/gitlab-org/cli/-/releases)してCI/CDジョブで使用できます。

### `download-secure-files`ツールを使用（非推奨） {#with-the-download-secure-files-tool-deprecated}

{{< history >}}

- GitLab 18.6で[非推奨](https://gitlab.com/gitlab-org/incubation-engineering/mobile-devops/download-secure-files/-/issues/45)になりました。

{{< /history >}}

{{< alert type="warning" >}}

この方法は非推奨です。

{{< /alert >}}

CI/CDジョブでセキュアファイルを使用する場合、[`download-secure-files`](https://gitlab.com/gitlab-org/incubation-engineering/mobile-devops/download-secure-files)ツールを使用して、ジョブでファイルをダウンロードできます。ダウンロード後、他のスクリプトコマンドと一緒に使用できます。

`download-secure-files`ツールをダウンロードして実行するために、ジョブの`script`セクションにコマンドを追加します。ファイルは、プロジェクトのルートにある`.secure_files`ディレクトリにダウンロードされます。セキュアファイルのダウンロード場所を変更するには、`SECURE_FILES_DOWNLOAD_PATH` [CI/CD変数](../variables/_index.md)にパスを設定します。

例: 

```yaml
test:
  variables:
    SECURE_FILES_DOWNLOAD_PATH: './where/files/should/go/'
  script:
    - curl --silent "https://gitlab.com/gitlab-org/incubation-engineering/mobile-devops/download-secure-files/-/raw/main/installer" | bash
```

## セキュリティの詳細 {#security-details}

プロジェクトレベルのセキュアファイルは、[`Ci::SecureFileUploader`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/app/uploaders/ci/secure_file_uploader.rb)インターフェースを使用して、[Lockbox](https://github.com/ankane/lockbox) Ruby gemによってアップロード時に暗号化されます。このインターフェースは、アップロード時にソースファイルのSHA256チェックサムを生成し、そのチェックサムをレコードとともにデータベースに保持します。これは、ダウンロード時にファイルの内容を検証する際に使用できます。

ファイルが作成されるたびに各ファイルに[一意の暗号化キー](https://gitlab.com/gitlab-org/gitlab/-/blob/master/app/models/ci/secure_file.rb#L27)が生成され、データベースに保持されます。暗号化されたアップロードファイルは、[GitLabインスタンスの設定](../../administration/cicd/secure_files.md)に応じて、ローカルストレージまたはオブジェクトストレージに保存されます。

個々のファイルは、[セキュアファイルダウンロードAPI](../../api/secure_files.md#download-secure-file)で取得できます。メタデータは、[リスト](../../api/secure_files.md#list-project-secure-files)または[表示](../../api/secure_files.md#show-secure-file-details)APIエンドポイントで取得できます。ファイルは、[`glab securefile`コマンド](https://gitlab.com/gitlab-org/cli/-/tree/main/docs/source/securefile)でも取得できます。このコマンドは、ダウンロード時に各ファイルのチェックサムを自動的に検証します。

デベロッパーロール以上を持つすべてのプロジェクトメンバーは、プロジェクトレベルのセキュアファイルにアクセスできます。プロジェクトレベルのセキュアファイルの操作は監査イベントに含まれていませんが、[イシュー117](https://gitlab.com/gitlab-org/incubation-engineering/mobile-devops/readme/-/issues/117)でこの機能の追加が提案されています。
