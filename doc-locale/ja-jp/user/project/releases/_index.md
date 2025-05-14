---
stage: Deploy
group: Environments
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: リリース
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

重要なマイルストーンでプロジェクトをパッケージ化するには、リリースを作成します。リリースは、コード、バイナリ、ドキュメント、リリースノートを組み合わせて、プロジェクトの完全なスナップショットを作成します。リリースを作成すると、GitLabは自動的にコードにタグ付けして、スナップショットをアーカイブし、監査に適したエビデンスを生成します。これにより、コンプライアンス要件に最適な永続的なレコードが作成され、開発プロセスへのユーザーの信頼を向上させることができます。

ユーザーが得られるメリット:

- 最新の安定したバージョンとインストールパッケージへの簡単なアクセス
- 新機能と修正に関する分かりやすいドキュメント
- 対応するアセットを使用して特定のバージョンをダウンロードする機能
- プロジェクトの経時的な進化を追跡するためのシンプルな方法

{{< alert type="warning" >}}

リリースに関連付けられたGitタグを削除すると、リリースも削除されます。

{{< /alert >}}

リリースを作成する際、または作成後に、以下を実行できます。

- リリースノートを追加する。
- リリースに関連付けられたGitタグにメッセージを追加する。
- [マイルストーンを関連付ける](#associate-milestones-with-a-release)。
- 手順書やパッケージなどの[リリースアセット](release_fields.md#release-assets)をアタッチする。

## リリースを表示する

リリースのリストを表示するには、以下を実行します。

- 左側のサイドバーで、**デプロイ > リリース**を選択します。または、

- プロジェクトの概要ページに1つ以上のリリースが存在する場合は、リリースの数を選択します。

  ![リリースの数](img/releases_count_v13_2.png "リリースの増分カウンター")

  - 公開プロジェクトでは、すべてのユーザーにこの数字が表示されます。
  - プライベートプロジェクトでは、この数はレポーター以上の[ロール](../../permissions.md#project-members-permissions)を持つユーザーに表示されます。

### リリースを並べ替える

リリースを**リリース日**または**作成日**で並べ替えるには、並べ替えドロップダウンリストから選択します。昇順と降順を切り替えるには、**並べ替え**を選択します。

![リリースの並べ替えドロップダウンリストのオプション](img/releases_sort_v13_6.png)

### 最新リリースへの永続リンク

永続リンクを使用して、最新のリリースページにアクセスできます。GitLabは、永続リンクのURLを常に最新のリリースページのアドレスにリダイレクトします。

URLの形式は次のとおりです。

```plaintext
https://gitlab.example.com/namespace/project/-/releases/permalink/latest
```

永続リンクのURLにサフィックスを追加することもできます。たとえば、最新のリリースが`v17.7.0#release`の`gitlab-org`ネームスペースと`gitlab-runner`プロジェクトにある場合、判読可能なリンクは次のようになります。

```plaintext
https://gitlab.com/gitlab-org/gitlab-runner/-/releases/v17.7.0#release
```

次の永続リンクを使用して、最新のリリースのURLにアクセスできます。

```plaintext
https://gitlab.com/gitlab-org/gitlab-runner/-/releases/permalink/latest#release
```

リリースアセットへの永続リンクの追加については、「[最新のリリースアセットへの永続リンク](release_fields.md#permanent-links-to-latest-release-assets)」を参照してください。

#### 並べ替えを設定する

GitLabは、デフォルトでは`released_at`時間を使用してリリースを取得します。クエリパラメータ`?order_by=released_at`の使用はオプションであり、`?order_by=semver`のサポートは[このイシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/352945)で追跡されます。

### RSSフィードを使用してリリースを追跡する

GitLabは、プロジェクトのリリースに関するRSSフィードをAtom形式で提供します。フィードを表示するには、以下を実行します。

1. 自分がメンバーになっているプロジェクトの場合:
   1. 左側のサイドバーで、**検索または移動**を選択して、プロジェクトを検索します。
   1. **デプロイ>リリース**を選択します。
1. すべてのプロジェクトの場合:
   1. **プロジェクトの概要**ページに移動します。
   1. 右側のサイドバーで、**リリース**（{{< icon name="rocket-launch" >}}）を選択します。
1. 右上隅で、フィードシンボル（{{< icon name="rss" >}}）を選択します。

## リリースを作成する

リリースは、次の方法で作成できます。

- [CI/CDパイプラインのジョブを使用する](#creating-a-release-by-using-a-cicd-job)。
- [リリースページで作成する](#create-a-release-in-the-releases-page)。
- [リリースAPI](../../../api/releases/_index.md#create-a-release)を使用する。

### リリースページでリリースを作成する

前提要件:

- プロジェクトのデベロッパーロール以上を持っている必要があります。詳細については、「[リリース権限](#release-permissions)」を参照してください。

リリースページでリリースを作成するには、以下を実行します。

1. 左側のサイドバーで、**検索または移動**を選択して、プロジェクトを検索します。
1. **デプロイ>リリース**を選択し、**新規リリース**を選択します。
1. [**タグ名**](release_fields.md#tag-name)ドロップダウンリストから、次のいずれかを行います。
   - 既存のGitタグを選択します。リリースにすでに関連付けられている既存のタグを選択すると、検証エラーが発生します。
   - 新しいGitタグ名を入力します。
     1. **タグを作成**ポップオーバーで、新しいタグを作成する際に使用するブランチまたはコミットSHAを選択します。
     1. （オプション）**タグメッセージを設定**テキストボックスに、[注釈付きタグ](https://git-scm.com/book/en/v2/Git-Basics-Tagging#_annotated_tags)を作成するためのメッセージを入力します。
     1. **保存**を選択します。
1. （オプション）リリースに関する以下の追加情報を入力します。
   - [タイトル](release_fields.md#title)。
   - [マイルストーン](#associate-milestones-with-a-release)。
   - [リリースノート](release_fields.md#release-notes-description)。
   - [タグメッセージ](../repository/tags/_index.md)を含めるかどうか。
   - [資産リンク](release_fields.md#links)。
1. **リリースを作成**を選択します。

### CI/CDジョブを使用してリリースを作成する

ジョブ定義で[`release`キーワード](../../../ci/yaml/_index.md#release)を使用することで、GitLab CI/CDパイプラインの一部として直接リリースを作成することができます。CI/CDパイプラインの最後のステップの1つとして、リリースを作成する必要があります。

リリースが作成されるのは、ジョブがエラーなしで処理された場合のみです。リリース作成中にAPIがエラーを返した場合、リリースジョブは失敗します。

次のリンクから、CI/CDジョブを使用してリリースを作成するための一般的な設定例を表示できます。

- [Gitタグの作成時にリリースを作成する](release_cicd_examples.md#create-a-release-when-a-git-tag-is-created)。
- [コミットがデフォルトブランチにマージされたときにリリースを作成する](release_cicd_examples.md#create-a-release-when-a-commit-is-merged-to-the-default-branch)。
- [カスタムスクリプトでリリースメタデータを作成する](release_cicd_examples.md#create-release-metadata-in-a-custom-script)。

### カスタムSSL/CA公開認証局（CA）を使用する

`ADDITIONAL_CA_CERT_BUNDLE`CI/CD変数を使用して、カスタムSSL/CA公開認証局（CA）を設定することができます。これは、`release-cli`がカスタム証明書を使用してHTTPS経由でAPI経由でリリースを作成する際のピア検証に使用されます。`ADDITIONAL_CA_CERT_BUNDLE`の値には、[X.509 PEM公開キー証明書のテキスト表現](https://www.rfc-editor.org/rfc/rfc7468#section-5.1)または公開認証局（CA）を含む`path/to/file`が含まれている必要があります。たとえば、`.gitlab-ci.yml`ファイルでこの値を設定するには、以下を使用します。

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

`ADDITIONAL_CA_CERT_BUNDLE`値は、証明書へのパスを必要とする`file`として、または証明書のテキスト表現を必要とする変数として、[UIでカスタム変数として](../../../ci/variables/_index.md#for-a-project)設定することもできます。

### 単一のパイプラインで複数のリリースを作成する

パイプラインには、複数の`release`ジョブを含めることができます。以下に例を示します。

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

### 汎用パッケージとしてのリリースアセット

[汎用パッケージ](../../packages/generic_packages/_index.md)を使用して、リリースアセットをホストできます。完全な例については、[汎用パッケージとしてのリリースアセット](https://gitlab.com/gitlab-org/release-cli/-/tree/master/docs/examples/release-assets-as-generic-package/)プロジェクトを参照してください。

パッケージ化された資産を含むリリースを作成するには、以下を実行します。

1. CI/CDパイプラインから、パッケージファイルをビルドします。
1. パッケージファイルを[汎用パッケージリポジトリ](../../packages/generic_packages/_index.md)にアップロードします。

   ```yaml
   Upload Package:
     stage: deploy
   script:
     - |
       curl --header "JOB-TOKEN: ${CI_JOB_TOKEN}" \
        --upload-file path/to/your/file \
        ${CI_API_V4_URL}/projects/${CI_PROJECT_ID}/packages/generic/${PACKAGE_NAME}/${VERSION}/filename
   ```

1. `release-cli`ジョブでリリースを作成します。

   ```yaml
   Create Release:
     stage: release
     image: registry.gitlab.com/gitlab-org/release-cli:latest
     rules:
       - if: $CI_COMMIT_TAG
     script:
       - |
         release-cli create \
         --name "Release ${VERSION}" \
         --tag-name $CI_COMMIT_TAG \
         --description "Your release notes here" \
         --assets-link "{\"name\":\"Asset Name\",\"url\":\"${PACKAGE_REGISTRY_URL}/filename\"}"
   ```

   含める資産ごとに、追加の`--assets-link`リンクを設定します。

## 次のリリース

[リリースAPI](../../../api/releases/_index.md#upcoming-releases)を使用すると、事前にリリースを作成できます。未来の日付`released_at`を設定すると、リリースタグの横に**次のリリース**バッジが表示されます。`released_at`の日時が経過すると、バッジは自動的に削除されます。

![次のリリース](img/upcoming_release_v12_7.png)

## 過去のリリース

{{< history >}}

- GitLab 15.2で[導入されました](https://gitlab.com/gitlab-org/gitlab/-/issues/199429)。

{{< /history >}}

[リリースAPI](../../../api/releases/_index.md#historical-releases)またはUIを使用して、過去のリリースを作成できます。過去の日付`released_at`を設定すると、リリースタグの横に**過去のリリース**バッジが表示されます。過去にリリースされているため、[リリースエビデンス](release_evidence.md)は利用できません。

## リリースを編集する

リリース作成後にリリースの詳細を編集するには、[リリースAPIの更新](../../../api/releases/_index.md#update-a-release)またはUIを使用します。

前提要件:

- デベロッパー以上のロールを持っている必要があります。

UIで、以下を実行します。

1. 左側のサイドバーで、**デプロイ > リリース**を選択します。
1. 変更するリリースの右上隅の**このリリースを編集**（鉛筆アイコン）を選択します。
1. **リリースを編集**ページで、リリースの詳細を変更します。
1. **変更を保存**を選択します。

## リリースを削除する

{{< history >}}

- GitLab 15.2で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/213862)されました。

{{< /history >}}

リリースを削除すると、その資産も削除されます。ただし、関連付けられたGitタグは削除されません。リリースに関連付けられたGitタグを削除すると、リリースも削除されます。

前提要件:

- デベロッパー以上のロールを持っている必要があります。詳細については、「[リリース権限](#release-permissions)」を参照してください。

リリースを削除するには、[リリースAPIの削除](../../../api/releases/_index.md#delete-a-release)またはUIを使用します。

UIで、以下を実行します。

1. 左側のサイドバーで、**検索または移動**を選択して、プロジェクトを検索します。
1. **デプロイ>リリース**を選択します。
1. 削除するリリースの右上隅で、**このリリースを編集**（{{< icon name="pencil" >}}）を選択します。
1. **リリースを編集**ページで、**削除**を選択します。
1. **リリースを削除**を選択します。

## マイルストーンをリリースに関連付ける

リリースを1つ以上の[プロジェクトのマイルストーン](../milestones/_index.md#project-milestones-and-group-milestones)に関連付けることができます。

[GitLab Premium](https://about.gitlab.com/pricing/)のお客様は、リリースに関連付ける[グループマイルストーン](../milestones/_index.md#project-milestones-and-group-milestones)を指定できます。

これを行うには、ユーザーインターフェイスを使用するか、[リリースAPI](../../../api/releases/_index.md#create-a-release)へのリクエストに`milestones`配列を含めます。

ユーザーインターフェイスで、マイルストーンをリリースに関連付けるには、以下を実行します。

1. 左側のサイドバーで、**デプロイ > リリース**を選択します。
1. 変更するリリースの右上隅の**このリリースを編集**（鉛筆アイコン）を選択します。
1. **マイルストーン**リストから、関連付けるマイルストーンを選択します。複数のマイルストーンを選択できます。
1. **変更を保存**を選択します。

**デプロイ > リリース**ページの上部に、**マイルストーン**とマイルストーン内のイシューに関する統計が表示されます。

![関連付けられたマイルストーンが1つあるリリース](img/release_with_milestone_v12_9.png)

リリースは、**プラン > マイルストーン**ページや、このページでマイルストーンを選択したときに表示されます。

以下は、リリースなしのマイルストーン、1つのリリースを含むマイルストーン、2つのリリースを含むマイルストーンの例です。

![リリースが関連付けられたマイルストーンと関連付けられていないマイルストーン](img/milestone_list_with_releases_v12_5.png)

{{< alert type="note" >}}

サブグループのプロジェクトリリースを親グループのマイルストーンに関連付けることはできません。詳細については、イシュー#328054「[リリースをスーパーグループのマイルストーンに関連付けることはできません](https://gitlab.com/gitlab-org/gitlab/-/issues/328054)」を参照してください。

{{< /alert >}}

## リリースが作成されたときに通知を受け取る

プロジェクトの新しいリリースが作成されたときに、メールで通知を受け取ることができます。

リリースの通知をサブスクライブするには、以下を実行します。

1. 左側のサイドバーで、**プロジェクトの概要**を選択します。
1. **通知設定**（ベルのアイコン）を選択します。
1. リストで、**カスタム**を選択します。
1. **新規リリース**チェックボックスをオンにします。
1. ダイアログボックスを閉じて保存します。

## デプロイフリーズを設定して意図しないリリースを防ぐ

[*デプロイフリーズ*期間](../../../ci/environments/deployment_safety.md)を設定することで、指定した期間の意図しない本番環境リリースを防ぐことができます。デプロイフリーズは、デプロイを自動化する際の不確実性とリスクを軽減するのに役立ちます。

メンテナーは、ユーザーインターフェイスでデプロイフリーズウィンドウを設定するか、[フリーズ期間API](../../../api/freeze_periods.md)を使用して、[crontab](https://crontab.guru/)エントリとして定義される`freeze_start`と`freeze_end`を設定できます。

実行中のジョブがフリーズ期間にある場合、GitLab CI/CDは`$CI_DEPLOY_FREEZE`という名前の環境変数を作成します。

グループ内の複数のプロジェクトでデプロイジョブの実行を防止するには、グループ全体で共有されるファイルに`.freezedeployment`ジョブを定義します。[`includes`](../../../ci/yaml/includes.md)キーワードを使用して、プロジェクトの`.gitlab-ci.yml`ファイルにテンプレートを組み込みます。

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

デプロイジョブが実行されないようにするには、`.gitlab-ci.yml`ファイルの`deploy_to_production`ジョブで[`extends`](../../../ci/yaml/_index.md#extends)キーワードを使用し、`.freezedeployment`テンプレートジョブから設定を継承します。

```yaml
deploy_to_production:
  extends: .freezedeployment
  script: deploy_to_prod.sh
  environment: production
```

この設定により、条件付きでデプロイジョブをブロックし、パイプラインの継続性を維持します。フリーズ期間が定義されている場合、ジョブは失敗し、パイプラインはデプロイなしで続行されます。フリーズ期間の後は、手動デプロイが可能になります。

このアプローチは、重要なメンテナンス中のデプロイ制御を提供し、CI/CDパイプラインの中断のないフローを実現します。

UIでデプロイフリーズウィンドウを設定するには、以下の手順を実行します。

1. メンテナーロールを持つユーザーとしてGitLabにサインインします。
1. 左側のサイドバーで、**検索または移動**を選択して、プロジェクトを検索します。
1. **設定 > CI/CD**を選択します。
1. **デプロイフリーズ**までスクロールします。
1. **展開**を選択して、デプロイフリーズのテーブルを表示します。
1. **デプロイフリーズを追加**を選択して、デプロイフリーズモーダルを開きます。
1. 希望するデプロイフリーズ期間の開始時間、終了時間、タイムゾーンを入力します。
1. モーダルで**デプロイフリーズを追加**を選択します。
1. デプロイフリーズを保存した後は、編集ボタン（{{< icon name="pencil" >}}）を選択して編集し、削除ボタン（{{< icon name="remove" >}}）を選択して削除できます。![デプロイフリーズ期間を設定するためのデプロイフリーズモーダル](img/deploy_freeze_v14_3.png)

プロジェクトに複数のフリーズ期間がある場合は、すべての期間が適用されます。期間がオーバーラップしている場合は、オーバーラップするすべての期間がフリーズの対象となります。

詳細については、「[デプロイの安全性](../../../ci/environments/deployment_safety.md)」を参照してください。

## リリース権限

### リリースを表示して資産をダウンロードする

- レポーター以上のロールを持つユーザーには、プロジェクトリリースへの読み取り権限とダウンロード権限が付与されています。
- ゲストロールのユーザーは、プロジェクトリリースへの読み取りアクセス権とダウンロードアクセス権が付与されています。これには、関連するGitタグ名、リリースの説明、リリースの作成者情報が含まれます。ただし、[ソースコード](release_fields.md#source-code)や[リリースエビデンス](release_evidence.md)など、リポジトリに関連するその他の情報は削除されています。

### ソースコードへのアクセス権を付与せずにリリースを公開する

{{< history >}}

- GitLab 15.6で[導入されました](https://gitlab.com/gitlab-org/gitlab/-/issues/216485)。

{{< /history >}}

[ソースコード](release_fields.md#source-code)や[リリースエビデンス](release_evidence.md)などのリポジトリに関連する情報をプロジェクトメンバーのみが利用できるようにしたまま、プロジェクトメンバー以外のユーザーがリリースにアクセスすることができます。これらの設定は、リリースを使用してソフトウェアの新しいバージョンにアクセスできるようにする一方、ソースコードは公開したくないプロジェクトに最適です。

リリースを[公開](../settings/_index.md#configure-project-features-and-permissions)するには、次の[プロジェクト設定](../settings/_index.md#configure-project-features-and-permissions)を行います。

- **プロジェクトの表示レベル**を**公開**に設定する。
- **リポジトリ**を有効にして、**プロジェクトメンバーのみ**に設定する。
- **リリース**を有効にして、**アクセスできる人すべて**に設定する。

### リリースとリリースの資産を作成、更新、削除する

- デベロッパー以上のロールを持つユーザーには、プロジェクトのリリースと資産に対する書き込み権限があります。
- リリースが[保護タグ](../protected_tags.md)に関連付けられている場合、ユーザーは[保護タグの作成](../protected_tags.md#configuring-protected-tags)も許可されている必要があります。

リリースの権限制御の例として、ワイルドカード（`*`）を使用してタグを保護し、**作成が許可されています**列で**メンテナー**に設定すると、メンテナー以上のロールのユーザーのみがリリースを作成、更新、削除することを許可できます。

## リリースメトリクス

{{< details >}}

- プラン: Ultimate
- 提供: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab Premium 13.9で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/259703)されました。

{{< /history >}}

**グループ > 分析 > CI/CD**に移動すると、グループレベルのリリースメトリクスを利用できます。これらのメトリクスには以下が含まれます。

- グループ内のリリースの合計数
- 1つ以上のリリースがあるグループ内のプロジェクトの割合

## 実際のプロジェクトの例

Guided Explorationプロジェクトの[GitVersionを使用した完全に自動化されたソフトウェアとアーティファクトのバージョニング](https://gitlab.com/guided-explorations/devops-patterns/utterly-automated-versioning)では、以下について実証しています。

- GitLabリリースを使用する。
- GitLab`release-cli`を使用する。
- 汎用パッケージを作成する。
- パッケージをリリースに関連付ける。
- [GitVersion](https://gitversion.net/)というツールを使用して、複雑なリポジトリのバージョンを自動的に決定し、インクリメントする。

サンプルプロジェクトを自分のグループやインスタンスにコピーしてテストできます。実証されているその他のGitLab CIパターンの詳細については、プロジェクトページを参照してください。

## トラブルシューティング

### リリースとその資産の作成、更新、削除時のエラー

リリースが[保護タグ](../protected_tags.md)に関連付けられている場合、UI/APIリクエストで次のような認証エラーが発生することがあります。

- `403 Forbidden`
- `Something went wrong while creating a new release`

ユーザーまたはサービス/ボットアカウントが、[保護タグの作成](../protected_tags.md#configuring-protected-tags)も許可されていることを確認してください。

詳細については、「[リリース権限](#release-permissions)」を参照してください。

### ストレージに関する注意

この機能はGitタグの上に構築されているため、リリース自体を作成する場合以外に、追加のデータが必要になることはほとんどありません。追加の資産と自動的に生成されるリリースエビデンスは、ストレージを消費します。

### GitLab CLIのバージョン要件

[`release`キーワード](../../../ci/yaml/_index.md#release)の使用方法は変更される予定です。`release-cli`ツールは、[GitLab CLIツール](https://gitlab.com/gitlab-org/cli/)に[置き換えられます](https://gitlab.com/groups/gitlab-org/-/epics/15437)。

GitLab CLIツール`v1.53.0`以降を使用する必要があります。それ以外では、次のいずれかのエラーメッセージが表示される可能性があります。

- `Error: glab command not found. Please install glab v1.53.0 or higher.`
- `Error: Please use glab v1.53.0 or higher.`

GitLab CLIツールを入手する方法は2つあります。

- `registry.gitlab.com/gitlab-org/release-cli:<version>`コンテナイメージを使用する場合は、`glab` `v1.53.0`を含む`registry.gitlab.com/gitlab-org/cli:v1.53.0`または`registry.gitlab.com/gitlab-org/release-cli:v0.22.0`のいずれかの使用を開始できます。
- release-cliまたはGitLab CLIツールを手動でRunnerにインストールした場合は、GitLab CLIのバージョンが`v1.53.0`以降であることを確認してください。
