---
stage: Deploy
group: Environments
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: リリース
description: リリース、バージョニング、アセット、タグ、マイルストーン、エビデンス
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

重要なマイルストーンでプロジェクトをパッケージ化するには、リリースを作成します。リリースは、コード、バイナリ、ドキュメント、リリースノートを組み合わせて、プロジェクトの完全なスナップショットを作成します。リリースを作成すると、GitLabは自動的にコードにタグを付けて、スナップショットをアーカイブし、監査に対応したリリースエビデンスを生成します。これにより、コンプライアンス要件に最適な永続的なレコードが作成され、開発プロセスに対するユーザーの信頼を向上させることができます。

ユーザーが得られるメリット:

- 最新の安定バージョンとインストールパッケージへの容易なアクセス
- 新機能と修正に関する明確なドキュメント
- 対応するアセットを含む特定のバージョンをダウンロードする機能
- プロジェクトの経時的な進化を追跡するシンプルな方法

{{< alert type="warning" >}}

リリースに関連付けられたGitタグを削除すると、リリースも削除されます。

{{< /alert >}}

リリースを作成する際、または作成後は、以下を実行できます:

- リリースノートを追加する。
- リリースに関連付けられたGitタグにメッセージを追加する。
- [マイルストーン](#associate-milestones-with-a-release)を関連付ける。
- [手順書](release_fields.md#release-assets)やパッケージなどのリリースアセットをアタッチする。

## リリースを表示する {#view-releases}

リリースのリストを表示するには:

- 左側のサイドバーで**デプロイ** > **リリース**を選択するか、または

- プロジェクトの概要ページに少なくとも1つのリリースがある場合は、リリースの数を選択します。

  ![リリースの数](img/releases_count_v13_2.png "リリースの増分カウンター")

  - 公開プロジェクトでは、すべてのユーザーにこの数が表示されます。
  - プライベートプロジェクトでは、この数は[レポーター](../../permissions.md#project-members-permissions)以上のロールが付与されたユーザーに表示されます。

### リリースを並べ替える {#sort-releases}

**リリース日**または**作成日**でリリースを並べ替えるには、並べ替え順序ドロップダウンリストから選択します。昇順と降順を切り替えるには、**Sort order**（並べ替え順序）を選択します。

![リリースの並べ替えドロップダウンリストのオプション](img/releases_sort_v13_6.png)

### 最新リリースへのパーマリンク {#permanent-link-to-latest-release}

最新のリリースページにパーマリンクを使用してアクセスできます。GitLabは常に、パーマリンクURLを最新のリリースページのURLにリダイレクトします。

URLの形式:

```plaintext
https://gitlab.example.com/namespace/project/-/releases/permalink/latest
```

パーマリンクURLには、サフィックスを追加することもできます。最新のリリースが`v17.7.0#release`で、`gitlab-org`のネームスペースおよび`gitlab-runner`プロジェクトにある場合の読み取り可能なリンクの例は、以下のとおりです:

```plaintext
https://gitlab.com/gitlab-org/gitlab-runner/-/releases/v17.7.0#release
```

以下のパーマリンクを使用して、最新のリリースURLにアクセスできます:

```plaintext
https://gitlab.com/gitlab-org/gitlab-runner/-/releases/permalink/latest#release
```

リリースアセットへのパーマリンクの追加の詳細については、[最新のリリースアセットへのパーマリンク](release_fields.md#permanent-links-to-latest-release-assets)を参照してください。

#### 並べ替えの設定 {#sorting-preferences}

GitLabはデフォルトでは、`released_at`時間を使用してリリースをフェッチします。クエリパラメータ`?order_by=released_at`の使用はオプションであり、`?order_by=semver`のサポートは[このイシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/352945)で追跡されています。

### RSSフィードを使用してリリースを追跡する {#track-releases-with-an-rss-feed}

GitLabは、プロジェクトのリリースに関するRSSフィードをAtom形式で提供します。フィードを表示する方法は、以下のとおりです:

1. メンバーになっているプロジェクトの場合:
   1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
   1. **デプロイ** > **リリース**を選択します。
1. すべてのプロジェクトについて:
   1. **Project overview**（プロジェクトの概要）ページに移動します。
   1. 右側のサイドバーで、**リリース**（{{< icon name="rocket-launch" >}}）を選択します。
1. 右上隅のフィードシンボル（{{< icon name="rss" >}}）をクリックします。

## リリースを作成する {#create-a-release}

リリースは、以下のとおり作成できます:

- [CI/CDパイプライン](#creating-a-release-by-using-a-cicd-job)のジョブを使用する。
- [リリースページ](#create-a-release-in-the-releases-page)で作成する。
- [リリースAPI](../../../api/releases/_index.md#create-a-release)を使用する。

### リリースページでリリースを作成する {#create-a-release-in-the-releases-page}

前提要件:

- プロジェクトのデベロッパー以上のロールが付与されている必要があります。詳細については、[リリースの権限](#release-permissions)を参照してください

リリースページでリリースを作成するには:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **デプロイ** > **リリース**を選択し、**新しいリリース**を選択します。
1. [**タグ名**](release_fields.md#tag-name)ドロップダウンリストから、以下のいずれかを選択します:
   - 既存のGitタグを選択します。リリースにすでに関連付けられている既存のタグを選択すると、検証エラーが発生します。
   - 新しいGitタグ名を入力します。
     1. **タグを作成**ポップオーバーで、新しいタグを作成する際に使用するブランチまたはコミットSHAを選択します。
     1. オプション。**タグメッセージを設定**[テキストボックス](https://git-scm.com/book/en/v2/Git-Basics-Tagging#_annotated_tags)に、注釈付きタグを作成するためのメッセージを入力します。
     1. **保存**をクリックします。
1. オプション。リリースに関する以下のような追加情報を入力します:
   - [タイトル](release_fields.md#title)
   - [マイルストーン](#associate-milestones-with-a-release)
   - [リリースノート](release_fields.md#release-notes-description)
   - [タグメッセージ](../repository/tags/_index.md)を含めるかどうか
   - [アセット](release_fields.md#links)のリンク
1. **リリースを作成**を選択します。

### CI/CDジョブを使用してリリースを作成する {#creating-a-release-by-using-a-cicd-job}

ジョブ定義で[`release`キーワード](../../../ci/yaml/_index.md#release)を使用すると、GitLab CI/CDパイプラインの一部としてリリースを直接作成できます。CI/CDパイプラインの最後のステップの一環としてリリースを作成する必要がある可能性があります。

リリースが作成されるのは、ジョブがエラーなしで処理された場合のみです。リリース作成中にAPIがエラーを返した場合、リリースジョブは失敗します。

以下のリンクは、CI/CDジョブを使用してリリースを作成するための一般的な設定例です:

- Gitタグの作成時に[リリース](release_cicd_examples.md#create-a-release-when-a-git-tag-is-created)を作成する。
- [コミット](release_cicd_examples.md#create-a-release-when-a-commit-is-merged-to-the-default-branch)がデフォルトブランチにマージされる際にリリースを作成する。
- カスタムスクリプトで[リリースメタデータ](release_cicd_examples.md#create-release-metadata-in-a-custom-script)を作成する。

### カスタムSSL CA認証局を使用する {#use-a-custom-ssl-ca-certificate-authority}

`ADDITIONAL_CA_CERT_BUNDLE` CI/CD変数を使用して、カスタムSSL認証局を設定できます。これは、`glab`コマンドラインインターフェースがカスタム証明書を使用してHTTPS経由でAPI経由でリリースを作成する際に、ピアを検証するために使用されます。`ADDITIONAL_CA_CERT_BUNDLE`の値には、[X.509 PEM公開キー証明書のテキスト表現](https://www.rfc-editor.org/rfc/rfc7468#section-5.1)、または公開認証局（CA）を含む`path/to/file`が含まれている必要があります。`.gitlab-ci.yml`ファイルでこの値を設定する例は、以下のとおりです:

```yaml
release:
  variables:
    ADDITIONAL_CA_CERT_BUNDLE: |
        -----BEGIN CERTIFICATE-----
        MIIGqTCCBJGgAwIBAgIQI7AVxxVwg2kch4d56XNdDjANBgkqhkiG9w0BAQsFADCB
        ...
        jWgmPqF3vUbZE0EyScetPJquRFRKIesyJuBFMAs=
        -----END CERTIFICATE-----
  script:
    - echo "Create release"
  release:
    name: 'My awesome release'
    tag_name: '$CI_COMMIT_TAG'
```

`ADDITIONAL_CA_CERT_BUNDLE`値は、[UI](../../../ci/variables/_index.md#for-a-project)のカスタム変数として設定することもできます。`file`として設定する場合は、証明書のパスが必要です。変数として設定する場合は、証明書のテキスト表現が必要です。

### 単一のパイプラインで複数のリリースを作成する {#create-multiple-releases-in-a-single-pipeline}

パイプラインには、複数の`release`ジョブを含めることができます。例は以下のとおりです:

```yaml
ios-release:
  script:
    - echo "iOS release job"
  release:
    tag_name: v1.0.0-ios
    description: 'iOS release v1.0.0'

android-release:
  script:
    - echo "Android release job"
  release:
    tag_name: v1.0.0-android
    description: 'Android release v1.0.0'
```

### 汎用パッケージとしてアセットをリリースする {#release-assets-as-generic-packages}

[汎用パッケージ](../../packages/generic_packages/_index.md)を使用して、リリースアセットをホスティングできます。

パッケージ化したアセットを使用してリリースを作成するには:

1. CI/CDパイプラインから、パッケージファイルをビルドします。
1. `glab`コマンドラインインターフェースジョブでリリースを作成するには、次の手順に従います:

   ```yaml
   Create Release:
     stage: release
     image: registry.gitlab.com/gitlab-org/cli:latest
     rules:
       - if: $CI_COMMIT_TAG
     script:
       - |
         glab release create "$CI_COMMIT_TAG" \
         --name "Release ${VERSION}" \
         --notes "Your release notes here" \
         path/to/your/release-asset-file \
         --use-package-registry
   ```

   含めるアセットごとに、追加の`--assets-link`リンクを追加します。

## 将来のリリース {#upcoming-releases}

[リリースAPI](../../../api/releases/_index.md#upcoming-releases)を使用すると、事前にリリースを作成できます。`released_at`で将来の日付を指定すると、**次のリリース**バッジがリリースタグの横に表示されます。`released_at`の日時が経過すると、バッジは自動的に削除されます。

![将来のリリース](img/upcoming_release_v12_7.png)

## 過去のリリース {#historical-releases}

{{< history >}}

- GitLab 15.2で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/199429)されました。

{{< /history >}}

[リリースAPI](../../../api/releases/_index.md#historical-releases)またはUIを使用して、過去の日付でリリースを作成できます。`released_at`で過去の日付を指定すると、**過去のリリース**バッジがリリースタグの横に表示されます。過去の日付のリリースであるため、[リリースエビデンス](release_evidence.md)は利用できません。

## リリースを編集する {#edit-a-release}

[リリース](../../../api/releases/_index.md#update-a-release)が作成された後に詳細を編集するには、リリースの更新APIまたはUIを使用できます。

前提要件:

- デベロッパー以上のロールが付与されている必要があります。

UIの場合:

1. 左側のサイドバーで、**デプロイ** > **リリース**を選択します。
1. 変更する**Edit this release**の右上隅のこのリリースを編集（鉛筆アイコン）をクリックします。
1. **リリースを編集**を編集ページで、リリースの詳細を変更します。
1. **変更を保存**を選択します。

## リリースを削除する {#delete-a-release}

{{< history >}}

- GitLab 15.2で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/213862)されました

{{< /history >}}

リリースを削除すると、リリースのアセットも削除されますが、関連付けられているGitタグは削除されません。リリースに関連付けられたGitタグを削除すると、リリースも削除されます。

前提要件:

- デベロッパー以上のロールが付与されている必要があります。詳細については、[リリースの権限](#release-permissions)を参照してください。

[リリース](../../../api/releases/_index.md#delete-a-release)を削除するには、リリースの削除APIか、UIを使用します。

UIの場合:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **デプロイ** > **リリース**を選択します。
1. 削除する**Edit this release**の右上隅のこのリリースを編集（{{< icon name="pencil" >}}）をクリックします。
1. **リリースを編集**を編集ページで、**削除**を選択します。
1. **リリースを削除**を選択します。

## マイルストーンをリリースに関連付ける {#associate-milestones-with-a-release}

[リリース](../milestones/_index.md#project-milestones-and-group-milestones)は、単一または複数のプロジェクトマイルストーンに関連付けることができます。

[GitLab Premium](https://about.gitlab.com/pricing/)のお客様は、[リリース](../milestones/_index.md#project-milestones-and-group-milestones)に関連付けるグループマイルストーンを指定できます。

これは、UIで実行することも、[リリースAPI](../../../api/releases/_index.md#create-a-release)へのリクエストに`milestones`配列を含めることでも実行できます。

UIで、マイルストーンをリリースに関連付けるには:

1. 左側のサイドバーで、**デプロイ** > **リリース**を選択します。
1. 変更する**Edit this release**の右上隅のこのリリースを編集（鉛筆アイコン）をクリックします。
1. **マイルストーン**リストから、関連付ける各マイルストーンを選択します。マイルストーンは複数選択できます。
1. **変更を保存**を選択します。

**デプロイ** > **リリース**ページの上部には、**マイルストーン**と、そのマイルストーンに関連するイシューの統計が表示されます。

![関連付けられたマイルストーンが1つあるリリース](img/release_with_milestone_v12_9.png)

リリースは、**Plan** > **マイルストーン**ページ、およびこのページでマイルストーンを選択した場合にも表示されます。

リリースがないマイルストーン、1つのリリースがあるマイルストーン、2つのリリースがあるマイルストーンの例は以下のとおりです。

![リリースが関連付けられたマイルストーンと関連付けられていないマイルストーン](img/milestone_list_with_releases_v12_5.png)

{{< alert type="note" >}}

サブグループのプロジェクトリリースを親グループのマイルストーンに関連付けることはできません。詳細については、イシュー#328054[リリースをスーパーグループマイルストーンに関連付けることができない](https://gitlab.com/gitlab-org/gitlab/-/issues/328054)を参照してください。

{{< /alert >}}

## リリース作成時に通知を受け取る {#get-notified-when-a-release-is-created}

プロジェクトの新しいリリースが作成される際に、メールで通知を受け取ることができます。

リリースの通知にサブスクライブするには:

1. 左側のサイドバーで**Project overview**（プロジェクトの概要）を選択します。
1. **Notification setting**（ベルのアイコン）をクリックします。
1. リストで、**カスタム**を選択します。
1. **新しいリリース**チェックボックスをオンにします。
1. ダイアログボックスを閉じて保存します。

## デプロイフリーズを設定して意図しないリリースを回避する {#prevent-unintentional-releases-by-setting-a-deploy-freeze}

[*デプロイフリーズ*期間](../../../ci/environments/deployment_safety.md)を設定して、指定した期間中の意図しない本番環境リリースを防ぐことができます。デプロイフリーズを使用すると、デプロイを自動化する際の不確実性とリスクの軽減につながります。

[メンテナー](../../../api/freeze_periods.md)は、UIでデプロイフリーズウィンドウを設定するか、[フリーズ期間API](https://crontab.guru/)を使用して、crontabエントリとして定義されている`freeze_start`と`freeze_end`を設定できます。

実行中のジョブがフリーズ期間内となる場合、GitLab CI/CDは`$CI_DEPLOY_FREEZE`という名前の環境変数を作成します。

グループ内の複数のプロジェクトでデプロイジョブの実行を防ぐには、グループ全体で共有されるファイルで`.freezedeployment`ジョブを定義します。[`includes`](../../../ci/yaml/includes.md)キーワードを使用して、プロジェクトの`.gitlab-ci.yml`ファイルにテンプレートを組み込みます。以下に例を示します:

```yaml
.freezedeployment:
  stage: deploy
  before_script:
    - '[[ ! -z "$CI_DEPLOY_FREEZE" ]] && echo "INFRASTRUCTURE OUTAGE WINDOW" && exit 1; '
  rules:
    - if: '$CI_DEPLOY_FREEZE'
      when: manual
      allow_failure: true
    - when: on_success
```

デプロイジョブが実行されないようにするには、`.gitlab-ci.yml`ファイルの`deploy_to_production`ジョブで[`extends`](../../../ci/yaml/_index.md#extends)キーワードを使用し、`.freezedeployment`テンプレートジョブから設定を継承します:

```yaml
deploy_to_production:
  extends: .freezedeployment
  script: deploy_to_prod.sh
  environment: production
```

この設定により、デプロイジョブが条件付きでブロックされ、パイプラインの継続性が維持されます。フリーズ期間が定義されている場合、ジョブは失敗し、パイプラインはデプロイなしで続行できます。フリーズ期間が終了すると、手動でデプロイできます。

このアプローチは、重要なメンテナンス中のデプロイを制御し、CI/CDパイプラインが中断することなく実行されるようにします。

UIでデプロイフリーズ期間を設定するには、次の手順を実行します:

1. メンテナーロールを持つユーザーとしてGitLabにサインインします。
1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **設定** > **CI/CD**を選択します。
1. **デプロイフリーズ**までスクロールします。
1. **全て展開**を選択して、デプロイフリーズテーブルを表示します。
1. **デプロイフリーズを追加**を選択して、デプロイフリーズモーダルを開きます。
1. 目的のデプロイフリーズ期間の開始時刻、終了時刻、およびタイムゾーンを入力します。
1. モーダルで**デプロイフリーズを追加**を選択します。
1. デプロイフリーズを保存したら、編集ボタン（{{< icon name="pencil" >}}）を選択して編集し、削除ボタン（{{< icon name="remove" >}}）を選択して削除できます。![デプロイフリーズ期間を設定するためのデプロイフリーズモーダル](img/deploy_freeze_v14_3.png)

プロジェクトに複数のフリーズ期間が含まれている場合、すべての期間が適用されます。それらがオーバーラップしている場合、フリーズは完全にオーバーラップしている期間を対象とします。

詳細については、[デプロイの安全性](../../../ci/environments/deployment_safety.md)を参照してください。

## リリースの権限 {#release-permissions}

### リリースを表示してアセットをダウンロードする {#view-a-release-and-download-assets}

- レポーター以上のロールを持つユーザーは、プロジェクトのリリースに対する読み取りおよびダウンロード権限を持っています。
- ゲストロールのユーザーは、プロジェクトのリリースへの読み取りおよびダウンロード権限を持っています。これには、関連付けられているGitタグ名、リリースの説明、リリースの作成者情報が含まれます。ただし、[ソースコード](release_fields.md#source-code)や[リリースエビデンス](release_evidence.md)などのリポジトリ関連情報は削除済みのです。

### ソースコードへのアクセス権を付与せずにリリースを公開する {#publish-releases-without-giving-access-to-source-code}

{{< history >}}

- GitLab 15.6で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/216485)されました。

{{< /history >}}

プロジェクトメンバー以外のメンバーがリリースにアクセスできるようにしながら、[ソースコード](release_fields.md#source-code)や[リリースエビデンス](release_evidence.md)などのリポジトリ関連情報はプロジェクトメンバーのみが利用できるようにすることができます。これらの設定は、ソフトウェアの新しいバージョンへのアクセス権限を付与するためにリリースを使用するが、ソースコードを一般公開したくないプロジェクトに最適です。

[リリース](../settings/_index.md#configure-project-features-and-permissions)を公開するには、次のプロジェクトの表示レベルを設定します:

- **プロジェクトの表示レベル**を**公開**に設定します。
- **リポジトリ**を有効にし、**プロジェクトメンバーのみ**に設定します。
- **リリース**を有効にして、**アクセスできる人すべて**に設定します。

### リリースとリリースのアセットを作成、更新、削除する {#create-update-and-delete-a-release-and-its-assets}

- デベロッパー以上のロールを持つユーザーは、プロジェクトのリリースとアセットに対する書き込み権限を持っています。
- リリースが[保護タグ](../protected_tags.md)に関連付けられている場合、ユーザーは[保護タグの作成が許可されている](../protected_tags.md#configuring-protected-tags)必要もあります。

リリースの**メンテナー**制御の例として、**作成が許可されています**（`*`）を使用してタグを保護し、作成が許可されていますコラムでメンテナーを設定することで、メンテナー以上のロールを持つユーザーのみにリリースを作成、更新、および削除することを許可できます。

## リリースのメトリクス {#release-metrics}

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab Premium 13.9で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/259703)されました。

{{< /history >}}

グループレベルのリリースのメトリクスは、**グループ** > **分析** > **CI/CD**に移動すると利用できます。これらのメトリクスには以下が含まれます:

- グループ内のリリースの合計数
- 少なくとも1つのリリースがあるグループ内のプロジェクトの割合

## 実際のプロジェクト例 {#working-example-project}

Guided Explorationプロジェクトの[GitVersionを使用した完全に自動化されたソフトウェアとアーティファクトのバージョニング](https://gitlab.com/guided-explorations/devops-patterns/utterly-automated-versioning)では、以下の実例が示されています:

- GitLabリリースの使用。
- [GitLab CLI](../../../editor_extensions/gitlab_cli/_index.md)の使用
- 汎用パッケージの作成。
- パッケージをリリースにリンクする。
- [GitVersion](https://gitversion.net/)という名前のツールを使用して、複雑なリポジトリのバージョンを自動的に決定して増分する。

テストの目的で、このプロジェクト例を独自のグループまたはインスタンスにコピーできます。他のGitLab CIパターンのデモについての詳細は、プロジェクトページをご覧ください。

## トラブルシューティング {#troubleshooting}

### リリースとそのアセットの作成、更新、または削除時のエラー {#errors-when-creating-updating-or-deleting-releases-and-their-assets}

[リリース](../protected_tags.md)が保護タグに関連付けられている場合、UI/APIリクエストが原因で、次の認証エラーが発生する可能性があります:

- `403 Forbidden`
- `Something went wrong while creating a new release`

ユーザーまたはサービス/[ボット](../protected_tags.md#configuring-protected-tags)アカウントに対して保護タグの作成が許可されていることを確認してください。

詳細については、[リリース](#release-permissions)の権限を参照してください。

### ストレージに関する注意 {#note-about-storage}

この機能はGitタグの上に構築されているため、リリース自体を作成する以外に、追加のデータはほぼ必要ありません。追加のアセットと自動的に生成されるリリースエビデンスはストレージを消費します。

### GitLab CLIのバージョン要件 {#gitlab-cli-version-requirement}

[`release`キーワード](../../../ci/yaml/_index.md#release)の使い方は変更される予定です。`release-cli`ツールは[GitLab CLI](https://gitlab.com/gitlab-org/cli/)ツールに[置き換え](https://gitlab.com/groups/gitlab-org/-/epics/15437)られます。

GitLab CLIツール`v1.58.0`以上を使用する必要があります。それ以外のバージョンの場合、以下のいずれかのエラーメッセージまたは警告が表示される可能性があります:

- `Error: glab command not found. Please install glab v1.58.0 or higher.`
- `Error: Please use glab v1.58.0 or higher.`
- `Warning: release-cli will not be supported after 19.0. Please use glab version >= 1.58.0.`

GitLab CLIツールを入手する2つの方法:

- `registry.gitlab.com/gitlab-org/release-cli:<version>`コンテナイメージを使用する場合、`glab` `v1.58.0`を含む`registry.gitlab.com/gitlab-org/cli:v1.58.0`または`registry.gitlab.com/gitlab-org/release-cli:v0.24.0`のどちらかの使用を開始できます。
- release-cliまたはGitLab CLIツールを手動でRunnerにインストールした場合は、GitLab CLIバージョンが`v1.58.0`以上であることを確認してください。
