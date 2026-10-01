---
stage: Security Risk Management
group: Security Platform Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: セキュリティ設定プロファイルを管理する
---

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 18.9で[導入](https://gitlab.com/groups/gitlab-org/-/work_items/19802)され、[機能フラグ](../../../administration/feature_flags/_index.md) `security_scan_profiles_feature`とともに提供されました。デフォルトでは有効になっています。
- シークレット検出プロファイルがGitLab 18.10で[追加](https://gitlab.com/groups/gitlab-org/-/epics/19903)されました。
- SASTプロファイルがGitLab 18.11で[追加](https://gitlab.com/groups/gitlab-org/-/epics/19951)されました。
- 依存関係スキャンプロファイルがGitLab 19.0で[導入](https://gitlab.com/groups/gitlab-org/-/epics/19952)され、[機能フラグ](../../../administration/feature_flags/_index.md) `security_scan_profiles_dependency_scanning`とともに提供されました。デフォルトでは有効になっています。
- 依存関係スキャン自動修正プロファイルがGitLab 19.2で[導入](https://gitlab.com/groups/gitlab-org/-/work_items/604588)され、[機能フラグ](../../../administration/feature_flags/_index.md) `security_remediation_profiles`とともに提供されました。デフォルトでは有効になっています。
- シークレット検出スキャンプロファイル設定は、GitLab 19.3で[導入](https://gitlab.com/gitlab-org/gitlab/-/work_items/606237)され、[実験](../../../policy/development_stages_support.md)としてGraphQL APIのみを通じて利用可能です。
- 機能フラグ`security_scan_profiles_feature`はGitLab 19.4で削除されました。
- 機能フラグ`security_remediation_profiles`はGitLab 19.4で削除されました。
- SASTスキャンプロファイル設定は、GitLab 19.4で[導入](https://gitlab.com/gitlab-org/gitlab/-/work_items/617070)され、[実験](../../../policy/development_stages_support.md)としてGraphQL APIのみを通じて利用可能です。

{{< /history >}}

セキュリティ設定プロファイルは、プロジェクト全体でセキュリティスキャナーをどのように、いつ実行するかを定義する集中化された設定です。セキュリティ設定プロファイルを使用して、組織全体のセキュリティスキャナーを効率的に管理します。プロファイルベースのアプローチでは、最小限の手動セットアップでベストプラクティスが適用されます。

<i class="fa-youtube-play" aria-hidden="true"></i>概要については、[セキュリティ設定プロファイルの紹介](https://www.youtube.com/watch?v=QbnLGzTEqGI)をご覧ください。

グループにプロファイルを適用すると、そのグループ内の個々のプロジェクトすべてに適用されます。プロファイルはグループ自体にはアタッチされず、プロファイル間やサブグループ間には継承はありません。

[デフォルトプロファイル](#default-profiles)を使用すると、数分で、最小限の設定で事前設定済みのセキュリティスキャンを有効にできます。

## セキュリティスキャナーを設定する {#configure-security-scanners}

プロファイルを評価および管理するには、グループの[セキュリティインベントリ](../security_inventory/_index.md#view-the-security-inventory)を中央ダッシュボードとして使用します。

### テストカバレッジをレビューする {#review-test-coverage}

SAST、依存関係スキャン、シークレット検出などのグループのスキャナーのハイレベルなステータス（**有効**、**無効**、または**失敗**）を表示するには:

1. 上部のバーで、**検索または移動先**を選択して、グループを見つけます。
1. 左側のサイドバーで、**セキュリティ** > **セキュリティインベントリ**を選択します。
1. セキュリティインベントリで、**テストカバレッジ**列をレビューします。

### 個々のプロジェクトのカバレッジを変更する {#change-individual-project-coverage}

特定のプロジェクトを設定するには、次の手順に従います:

1. 上部のバーで、**検索または移動先**を選択して、グループを見つけます。
1. 左側のサイドバーで、**セキュリティ** > **セキュリティインベントリ**を選択します。
1. プロジェクトの隣にある縦方向の省略記号（{{< icon name="ellipsis_v" >}}）を選択し、**ツールのカバレッジを管理**を選択します。
1. 個々のスキャナーをオンまたはオフにします。

### 複数のプロジェクトにプロファイルを適用する {#apply-a-profile-to-multiple-projects}

時間を節約するために、複数のプロジェクトにセキュリティ設定を一度に適用できます:

1. 上部のバーで、**検索または移動先**を選択して、グループを見つけます。
1. 左側のサイドバーで、**セキュリティ** > **セキュリティインベントリ**を選択します。
1. 複数のプロジェクトまたはサブグループ全体を選択して、設定を適用します。
1. **Bulk Action**ドロップダウンを選択し、**セキュリティスキャナーの管理**を選択します。
1. **デフォルトプロファイルをすべてに適用**を選択して、選択範囲全体のセキュリティ対策状況を標準化します。

## デフォルトプロファイル {#default-profiles}

GitLabには、事前設定済みのスキャナー設定であるデフォルトプロファイルが用意されているため、最小限の設定でセキュリティスキャンを有効にできます。

### シークレット検出プロファイル {#secret-detection-profile}

シークレット検出プロファイルを適用すると、開発ワークフロー全体でシークレットに対する推奨されるベースライン保護が有効になります。プロファイルは以下のスキャントリガーを有効にします:

- **プッシュ保護**: すべてのGitプッシュイベントをスキャンし、シークレットが検出されたプッシュをブロックすることで、シークレットがコードベースに侵入するのを防ぎます。
- **マージリクエストパイプライン**: 新しいコミットがオープンなマージリクエストのあるブランチにプッシュされるたびに、自動的にスキャンを実行します。結果は、マージリクエストによって導入された新しい脆弱性にスコープされます。すべてのブランチをターゲットにします。
- **ブランチパイプライン（デフォルトのみ）**: 変更がデフォルトブランチにマージまたはプッシュされると自動的に実行され、デフォルトブランチのシークレット検出の状況を完全に把握できます。すべてのブランチをターゲットにします。

### SASTプロファイル {#sast-profile}

SASTプロファイルを適用すると、推奨設定を使用して、すべてのプロジェクトで静的アプリケーションセキュリティテストを有効にできます。プロファイルは以下のスキャントリガーを有効にします:

- **マージリクエストパイプライン**: 新しいコミットが未解決のマージリクエストがあるブランチにプッシュされるたびに、SASTスキャンを自動的に実行します。結果には、マージリクエストによって導入された新しい脆弱性のみが含まれます。すべてのブランチをターゲットにします。
- **ブランチパイプライン（デフォルトのみ）**: 変更がデフォルトブランチにマージまたはプッシュされると自動的に実行され、デフォルトブランチのSASTの態勢を完全に把握できます。デフォルトブランチをターゲットにします。

### 依存関係スキャンプロファイル {#dependency-scanning-profile}

依存関係スキャンプロファイルを有効にすると、推奨設定を使用して、プロジェクトの依存関係が既知の脆弱性に対してスキャンされます。プロファイルは以下のスキャントリガーを有効にします:

- **マージリクエストパイプライン**: 新しいコミットが未解決のマージリクエストがあるブランチにプッシュされるたびに、依存スキャンを自動的に実行します。結果には、マージリクエストによって導入された新しい脆弱性のみが含まれます。すべてのブランチをターゲットにします。
- **ブランチパイプライン（デフォルトのみ）**: 変更がデフォルトブランチにマージまたはプッシュされると自動的に実行され、デフォルトブランチの依存関係における脆弱性の全体像を完全に把握できます。デフォルトブランチをターゲットにします。

### 依存関係スキャン自動修正プロファイル {#dependency-scanning-auto-remediation-profile}

{{< history >}}

- トリアージおよび修正プロファイルの自動修正サポートは、GitLab 19.4で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/253780)され、[機能フラグ](../../../administration/feature_flags/_index.md) `triage_and_remediation_profile`とともに提供されました。デフォルトでは有効になっています。

{{< /history >}}

依存関係スキャン自動修正プロファイルを有効にすると、GitLabは脆弱な依存関係を脆弱性のないバージョンに引き上げるマージリクエストを開きます。この機能の詳細については、[依存関係スキャン自動修正](../remediate/dependency_scanning_auto_remediation.md)を参照してください。

プロファイルをプロジェクトにアタッチするには、[GitLab CLI](../../../editor_extensions/gitlab_cli/_index.md)（`glab`）を使用します:

```shell
glab security config enable dependency_scanning_post_processing -R <project-path>
```

例えば、`my-group/my-project`のプロファイルを有効にするには:

```shell
glab security config enable dependency_scanning_post_processing -R my-group/my-project
```

> [!note]
> 1つのプロジェクトに両方のプロファイルを同時にアタッチできます。この状況では、GitLabは最初に適用されたプロファイルのみを使用します。他のプロファイルの設定は無視されます。

### 自動トリアージおよび修正プロファイル {#automated-triage-and-remediation-profile}

{{< history >}}

- トリアージおよび修正プロファイルは、GitLab 19.4で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/622469)され、[機能フラグ](../../../administration/feature_flags/_index.md) `triage_and_remediation_profile`とともに提供されました。デフォルトでは有効になっています。

{{< /history >}}

> [!flag]
> この機能の利用可否は、機能フラグによって制御されます。詳細については、履歴を参照してください。

トリアージおよび修正プロファイルを使用して、GitLab Duoトリアージフローと依存関係スキャン自動修正をプロジェクトおよびグループ全体で有効にします。GitLab DuoフローはAIを使用して結果を評価し、解決します。プロファイルは単独でフローを有効にすることも、既存のプロジェクトごとの同等の設定を置き換えることもできます。

GitLabは3つのプリセットを提供します: Conservative、Standard、およびProactive。それぞれが異なる設定を各フローに適用するため、フローがどの程度広範囲に、どの程度の頻度でトリガーされ実行されるかを選択できます。プロファイルを作成し、自分で設定することもできます。

前提条件: 

- [GitLab Duo Agent Platformの前提条件](../../duo_agent_platform/_index.md#prerequisites)を満たしている。
- **基本フローを許可**と、使用したい各フローを[トップレベルグループに](../../duo_agent_platform/flows/foundational_flows/_index.md#turn-foundational-flows-on-or-off)有効にします。フローは、プロジェクトごとではなく、トップレベルグループに対して一度有効にします。

> [!note]
> これらのフローのほとんどはAIを活用しており、[GitLabクレジット](../../../subscriptions/gitlab_credits.md)を消費します。消費量は検出結果の数に応じてスケールします。

#### プリセット {#presets}

| フロー | Conservative | Standard | Proactive |
| ---- | ------------ | -------- | --------- |
| SASTの誤検出判定 | `high`以上、オンデマンド | `medium`以上、自動 | `info`以上、自動 |
| SAST脆弱性の修正 | `high`以上、オンデマンド、最大5件の未解決のマージリクエスト | `medium`以上、自動、最大15件の未解決のマージリクエスト | `info`以上、自動、マージリクエストの制限なし |
| シークレット検出誤検出判定 | `high`以上、オンデマンド | `medium`以上、自動 | `info`以上、自動 |
| 依存関係スキャンの自動修正 | `high`以上、マイナーバージョンアップグレード、最大5件の未解決マージリクエスト、過去7日間の修正バージョンはスキップ | `high`以上、マイナーバージョンアップグレード、最大10件の未解決マージリクエスト、過去7日間の修正バージョンはスキップ | `info`以上、メジャーバージョンアップグレード、最大10件の未解決マージリクエスト、過去7日間の修正バージョンはスキップ |

プリセットを適用するには、[GraphQL API](#apply-a-profile-with-the-graphql-api)を使用します。プリセットは`Triage and Remediation (Conservative)`、`Triage and Remediation (Standard)`、および`Triage and Remediation (Proactive)`と名付けられています。

#### 関連トピック {#related-topics}

- [誤検出を自動的に検出する](../vulnerabilities/false_positive_detection.md)
- [エージェント型SAST脆弱性の修正](../vulnerabilities/agentic_vulnerability_resolution.md)
- [シークレット誤検出判定](../vulnerabilities/secret_false_positive_detection.md)
- [依存関係スキャンの自動修正](../remediate/dependency_scanning_auto_remediation.md)

### プロファイルの詳細を表示する {#view-details-about-a-profile}

シークレット検出プロファイルに関する技術的な詳細を表示するには、次の手順に従います:

1. 上部のバーで、**検索または移動先**を選択して、グループを見つけます。
1. 左側のサイドバーで、**セキュリティ** > **セキュリティインベントリ**を選択します。
1. **シークレット検出**プロファイルを選択します。
1. 次の情報をレビューします:
   - **アナライザーのタイプ**: プロファイルの種類（例: **シークレット検出**、**SAST**、**依存関係スキャン**）。
   - **スキャントリガー**: プロファイルがサポートするトリガー（例: **プッシュ保護**、**マージリクエストパイプライン**、**ブランチパイプライン**）。
   - **ステータス**: カバレッジステータスインジケーターを使用して、現在のコンテキストに対してプロファイルが現在**アクティブ**であるか**無効**であるかを表示します。

## スキャナー有効化ウィザードでスキャナーを有効にする {#enable-scanners-with-the-scanner-enablement-wizard}

スキャナーカバレッジのないプロジェクトにプロファイルを適用するには、[スキャナー有効化ウィザード](scanner_enablement_wizard.md)を使用します。ウィザードは未検出のプロジェクトを識別し、グループ全体にデフォルトまたはカスタムプロファイルを適用できます。

## GraphQL APIでプロファイルを適用する {#apply-a-profile-with-the-graphql-api}

GraphQL APIを使用して、UIではまだ利用できないプロファイルを含む、あらゆるセキュリティ設定プロファイルを適用します。これらのクエリは、[対話型GraphQLエクスプローラー](../../../api/graphql/_index.md#interactive-graphql-explorer)、または`/api/graphql`エンドポイントに直接リクエストを送信することで実行できます。

クエリの実行、認証、ページネーションの詳細については、[GraphQL APIクエリとミューテーションの実行](../../../api/graphql/getting_started.md)を参照してください。

前提条件: 

- 関連するプロジェクトまたはグループに対するメンテナーロールまたはセキュリティマネージャーロール以上。

セキュリティ設定プロファイルを適用するには:

1. グループで利用可能なプロファイルとそのIDを取得します:

```graphql
   query {
     group(fullPath: "my-group") {
       availableSecurityScanProfiles {
         id
         name
         scanType
       }
     }
   }
```

   まだ保存されていないデフォルトプロファイルは、そのスキャンタイプに基づいて仮想IDを返します。例: `gid://gitlab/Security::ScanProfile/dependency_scanning_post_processing`。

   詳細については、[`Group.availableSecurityScanProfiles`フィールド](../../../api/graphql/reference/_index.md#groupavailablesecurityscanprofiles)を参照してください。

1. 仮想IDまたは目的のプロファイルの実際のIDを使用して、`securityScanProfileAttach`ミューテーションでプロファイルを適用します:

```graphql
   mutation {
     securityScanProfileAttach(input: {
       securityScanProfileId: "gid://gitlab/Security::ScanProfile/dependency_scanning_post_processing",
       projectIds: ["gid://gitlab/Project/123"]
     }) {
       errors
     }
   }
```

   詳細については、[`securityScanProfileAttach`ミューテーション](../../../api/graphql/reference/_index.md#mutationsecurityscanprofileattach)を参照してください。

1. プロファイルを適用する場所を選択するには、以下の引数のいずれかまたは両方を設定します:
   - `projectIds`: 特定のプロジェクトにプロファイルを適用します。
   - `groupIds`: 1つ以上のグループ内のすべてのプロジェクトにプロファイルを適用します。

   指定されたすべてのプロジェクトとグループは、同じトップレベルグループに属している必要があります。単一のミューテーションは、プロジェクトとグループのIDを合わせて最大100個のIDを受け入れます。

1. プロファイルが適用されたことを確認するには、レスポンスの`errors`フィールドをチェックします。

## シークレット検出プロファイルをカスタマイズする {#customize-a-secret-detection-profile}

{{< details >}}

- ステータス: 実験的機能

{{< /details >}}

シークレット検出プロファイルをカスタマイズして、スキャナーが実行時に使用する設定を上書きします。各設定は、既存の[シークレット検出CI/CD変数](../secret_detection/_index.md)にマップされます。

この機能は、GraphQL APIのみを通じて利用可能です。

前提条件: 

- 関連するグループに対するメンテナーまたはセキュリティマネージャーロール。

シークレット検出プロファイルをカスタマイズするには、`securityScanProfileCreate`または`securityScanProfileUpdate`ミューテーションを使用します。カスタマイズするトリガーに`configuration.secretDetection`オブジェクトを設定します。

| フィールド | 説明 | 同等のCI/CD変数 |
| ----- | ----------- | ------------------------- |
| `secureAnalyzersPrefix` | アナライザーイメージがプルされるコンテナレジストリのプレフィックス。 | `SECURE_ANALYZERS_PREFIX` |
| `imageSuffix` | アナライザーイメージ名に追加されるサフィックス。`DEFAULT`または`FIPS`に設定します。 | `SECRET_DETECTION_IMAGE_SUFFIX` |
| `historicScan` | 現在の状態だけでなく、完全なGit履歴をスキャンするかどうか。 | `SECRET_DETECTION_HISTORIC_SCAN` |
| `logOptions` | スキャンするコミット範囲を制御するために`git log`に渡されるオプション。 | `SECRET_DETECTION_LOG_OPTIONS` |
| `excludedPaths` | スキャンから除外されるGlobパス。 | `SECRET_DETECTION_EXCLUDED_PATHS` |
| `rulesetGitReference` | 使用するリモートルールセット設定のGit参照。 | `SECRET_DETECTION_RULESET_GIT_REFERENCE` |

例えば、カスタマイズされたマージリクエストパイプラインのトリガーを持つシークレット検出プロファイルを作成するには:

```graphql
mutation {
  securityScanProfileCreate(input: {
    namespaceId: "gid://gitlab/Group/123",
    scanType: SECRET_DETECTION,
    name: "Custom secret detection profile",
    description: "Secret detection profile with a historic scan and path exclusions",
    triggers: [
      {
        triggerType: MERGE_REQUEST_PIPELINE,
        configuration: {
          secretDetection: {
            historicScan: true,
            excludedPaths: ["spec/**/*", "test/**/*"]
          }
        }
      }
    ]
  }) {
    scanProfile {
      id
      name
    }
    errors
  }
}
```

デフォルトでは、`stripDefaults`引数は、プロファイルを保存する前にデフォルトと一致するトリガー設定値を削除するため、上書きのみが永続化されます。

引数の完全なリストについては、[`securityScanProfileCreate`ミューテーション](../../../api/graphql/reference/_index.md#mutationsecurityscanprofilecreate)を参照してください。

## SASTプロファイルをカスタマイズする {#customize-a-sast-profile}

SASTプロファイルをカスタマイズして、プロファイル実行時に使用されるスキャナー設定を上書きします。各設定は、既存の[SAST CI/CD変数](../sast/_index.md)にマップされます。

この機能は[実験](../../../policy/development_stages_support.md)であり、GraphQL APIのみを通じて利用可能です。

前提条件: 

- 関連するグループに対するメンテナーまたはセキュリティマネージャーロール。

SASTプロファイルをカスタマイズするには、`securityScanProfileCreate`または`securityScanProfileUpdate`ミューテーションを使用します。カスタマイズするトリガーに`configuration.sast`オブジェクトを設定します。

| フィールド | 説明 | 同等のCI/CD変数 |
| ----- | ----------- | ------------------------- |
| `secureAnalyzersPrefix` | アナライザーイメージがプルされるコンテナレジストリのプレフィックス。 | `SECURE_ANALYZERS_PREFIX` |
| `imageSuffix` | アナライザーイメージ名に追加されるサフィックス。`DEFAULT`または`FIPS`に設定します。 | `SAST_IMAGE_SUFFIX` |
| `analyzerImageTag` | 使用するアナライザーイメージのタグ。すべてのSASTアナライザーの固定されたイメージタグを上書きします。これにより、特定のバージョンが必要な場合にアナライザーが失敗する可能性があります。 | `SAST_ANALYZER_IMAGE_TAG` |
| `excludedAnalyzers` | スキャンから除外されるアナライザー。 | `SAST_EXCLUDED_ANALYZERS` |
| `excludedPaths` | スキャンから除外されるGlobパス。 | `SAST_EXCLUDED_PATHS` |
| `advancedSastPartialScan` | GitLab高度なSASTの[差分ベースのスキャン](../sast/gitlab_advanced_sast.md)を制御します。`DIFFERENTIAL`または`DISABLED`に設定します。 | `ADVANCED_SAST_PARTIAL_SCAN` |
| `gitlabAdvSastIncrScan` | GitLab高度なSASTで[インクリメンタルスキャン](../sast/gitlab_advanced_sast.md)が有効になっているかどうか。 | `GITLAB_ADV_SAST_INCR_SCAN` |

例えば、カスタマイズされたマージリクエストパイプラインのトリガーを持つSASTプロファイルを作成するには:

```graphql
mutation {
  securityScanProfileCreate(input: {
    namespaceId: "gid://gitlab/Group/123",
    scanType: SAST,
    name: "Custom SAST profile",
    description: "SAST profile with custom analyzer exclusions and Advanced SAST settings",
    triggers: [
      {
        triggerType: MERGE_REQUEST_PIPELINE,
        configuration: {
          sast: {
            excludedAnalyzers: ["eslint"],
            excludedPaths: ["spec/**/*", "test/**/*"],
            advancedSastPartialScan: DIFFERENTIAL,
            gitlabAdvSastIncrScan: true
          }
        }
      }
    ]
  }) {
    scanProfile {
      id
      name
    }
    errors
  }
}
```

トリガーごとに1つの設定メンバーのみを設定でき、それはプロファイルのスキャンタイプと一致する必要があります。SASTプロファイルの場合、そのメンバーは`sast`です。

デフォルトでは、`stripDefaults`引数は、プロファイルを保存する前にデフォルトと一致するトリガー設定値を削除するため、上書きのみが永続化されます。

引数の完全なリストについては、[`securityScanProfileCreate`ミューテーション](../../../api/graphql/reference/_index.md#mutationsecurityscanprofilecreate)を参照してください。

## カバレッジステータスインジケーター {#coverage-status-indicators}

システムは、プロジェクトが保護されているかどうかを示すために、インベントリで視覚的なブロックを使用します:

- **緑色のバー（全面表示）**: スキャナーが完全に有効化され、稼働しています。
- **グレー/空のバー**: スキャナーはまだ設定されていないか、有効化されていません。
- **一部のみ表示されたバー**: 一部の保護がアクティブです（例: プロファイルで利用可能な一部のトリガーは有効になっていますが、その他は無効です）。
- **ツールチップ**: いずれかのカバレッジバーにカーソルを合わせると、パイプラインベースのスキャンと特定のパイプラインステータスの最終スキャン日が表示されます。

パイプラインベースのスキャンとは異なり、プッシュ保護はプッシュプロセス中にリアルタイムで実行されるため、最終スキャン日がありません。

## トラブルシューティング {#troubleshooting}

セキュリティ設定プロファイルを使用する際に、次の問題が発生する可能性があります。

### プッシュ保護の最終スキャン日が表示されない {#no-last-scan-date-appears-for-push-protection}

プッシュ保護はイベントベースであり、スケジュールベースではありません。これは`git push`プロセス中にシークレットをリアルタイムでインターセプトします。`push`コマンドの実行時に有効となるため、パイプラインベースのスキャナーのような最終スキャンの日付は存在しません。

### スキャナーのステータスがダッシュボードではアクティブだが、インベントリのツールチップでは有効になっていない {#scanner-status-is-active-in-the-dashboard-but-not-enabled-in-inventory-tooltip}

これは、プロジェクトがレガシー設定を使用していると同時に、新しいプロファイルが割り当てられている場合に発生する可能性があります。

この問題を解決するには、次の手順に従います:

1. 最も正確な現在のプロファイル状態については、**Security Configuration**ページを確認してください。
1. 必要に応じて、`.gitlab-ci.yml`ファイルからレガシースキャナーの設定を削除して、プロファイルベースの設定のみに依存するようにします。

> [!note]
> インベントリツールチップは、レガシー設定とプロファイルベース設定の両方の結合されたステータスを反映するように改良されています。

### レガシーとプロファイルベースの設定の違いについて {#understanding-legacy-versus-profile-based-configuration}

レガシースキャナーの設定からプロファイルベースの設定に移行する場合は、次の違いに注意してください:

- レガシー設定: スキャナーを有効にするには、YAMLファイルまたは個々のプロジェクト設定を手動で編集する必要があります。
- プロファイルベースの設定: 中央集権型システムを使用し、コードを修正することなく、複数のプロジェクトにデフォルトプロファイルを一度に適用できます。

プロファイルベースの設定を使用することで、プロジェクト間での管理が容易になり、一貫性も向上します。
