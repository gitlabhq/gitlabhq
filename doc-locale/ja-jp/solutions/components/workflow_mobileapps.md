---
stage: Solutions Architecture
group: Solutions Architecture
info: This page is owned by the Solutions Architecture team.
description: ハイブリッドReact Nativeモバイルアプリ向けのGitLab DevSecOpsワークフローについて説明します。これには、CI/CDの設定、Snykセキュリティスキャン、Sauce Labsの機能テスト、ServiceNowインテグレーションが含まれます。
title: DevSecOps Workflow - モバイルアプリ
---

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

このドキュメントでは、ハイブリッド（React Native）モバイルアプリをビルドおよびデプロイするためのGitLab DevSecOpsワークフローソリューションの手順と機能テストの詳細について説明します。

fastlaneを使用するネイティブモバイルアプリケーションについては、製品ドキュメントを参照してください。

これらの手順には、`react-native-community/cli`を使用してブートストラップされたサンプル[**React Native**](https://reactnative.dev)アプリケーションが含まれており、iOSとAndroidの両方のデバイスでクロスプラットフォームソリューションを提供します。このサンプルプロジェクトでは、GitLab CI/CDパイプラインを使用して、モバイルアプリケーションをビルド、テスト、およびデプロイするためのエンドツーエンドソリューションを提供します。

## はじめに {#getting-started}

このReact Nativeモバイルアプリのサンプルプロジェクトを使用して、GitLabを使用したモバイルアプリケーションの配信を迅速に開始する方法について、以下の手順に従ってください。

### ソリューションコンポーネントのダウンロード {#download-the-solution-component}

1. アカウントチームから招待キーコードを入手してください。
1. 招待キーコードを使用して、[ソリューションコンポーネントウェブストア](https://cloud.gitlab-accelerator-marketplace.com)からソリューションコンポーネントをダウンロードします。

### ソリューションコンポーネントプロジェクトの設定 {#set-up-the-solution-component-project}

- Product Accelerator Marketplaceからモバイルアプリのソリューションコンポーネントがダウンロードされました。ソリューションパックには、CI/CDファイルを含むモバイルアプリのサンプルプロジェクトが含まれています。
- 新しいGitLab CI/CDカタログプロジェクトを作成して、環境内でSnykソリューションコンポーネントをホストします。モバイルアプリソリューションパックには、Snyk CI/CDコンポーネントプロジェクトファイルが含まれており、Snyk CI/CDカタログプロジェクトを設定できます。
  1. このSnyk CI/CDカタログプロジェクトをホストする新しいGitLabプロジェクトを作成します
  1. 提供されたファイルをプロジェクトにコピーします
  1. プロジェクト設定で、必要なCI/CD変数を設定します
  1. プロジェクトがCI/CDカタログとしてマークされていることを確認してください。詳細については、[コンポーネントプロジェクトの公開](../../ci/components/_index.md#publish-a-component-project)を参照してください。

  {{< alert type="note" >}}

  GitLab.comにパブリックGitLab Snykコンポーネントがあり、SaaSを使用している場合は、パブリックGitLab Snykコンポーネントにアクセスできるため、独自のSnyk CI/CDカタログプロジェクトを設定する必要はありません。また、GitLab.comのパブリックGitLab Snykコンポーネントのドキュメントに従って、コンポーネントを直接使用できます。

  {{< /alert >}}

- Change Control Workflow with ServiceNowソリューションパックを使用して、DevOps ChangeベロシティインテグレーションとGitLabを設定し、変更制御を必要とするデプロイのためにServiceNowでの変更リクエストの作成を自動化します。[ServiceNowソリューションコンポーネントとの変更制御ワークフロー](../../solutions/components/integrated_servicenow.md)のドキュメントを参照し、アカウントチームと協力して、ServiceNowソリューションパッケージを使用したChange Control Workflowをダウンロードするためのアクセスコードを入手してください。
- CI YAMLファイルをプロジェクトにコピーします:
  - `.gitlab-ci.yml`
  - `build-android.yml`（パイプラインディレクトリ内）。ビルドジョブの`build-android.yml`ファイルが参照されているメインの`.gitlab-ci.yml`ファイルがあるため、`build-android.yml`ファイルが/pipeline以外の別の場所に配置されている場合は、`.gitlab-ci.yml`のファイルパスを更新する必要があります。
  - `build-ios.yml`（パイプラインディレクトリ内）。ビルドジョブの`build-ios.yml`ファイルが参照されているメインの`.gitlab-ci.yml`ファイルがあるため、`build-ios.yml`ファイルが/pipeline以外の別の場所に配置されている場合は、`.gitlab-ci.yml`のファイルパスを更新する必要があります。

   ```yaml
   include:
  - local: "pipelines/build-ios.yml"
    inputs:
      image: macos-15-xcode-16
      tag: saas-macos-medium-m1
  - local: "pipelines/build-android.yml"
    inputs:
      image: reactnativecommunity/react-native-android
   ```

- プロジェクト設定で、必要なCI/CD変数を設定します。パイプラインの動作方法については、次のセクションを参照してください。

## パイプラインの仕組み {#how-the-pipeline-works}

このパイプラインは、iOSとAndroidの両方のビルド、テスト、モバイルアプリのデプロイを処理するReact Nativeプロジェクト向けに設計されています。

このプロジェクトには、iOSとAndroidの両方のReact Nativeビルド用の簡単なreactCounterデモアプリが含まれています。このバージョンはまだアーティファクトに署名していないため、TestFlightまたはPlayストアにアップロードできません。

各変更では、セマンティックバージョニングバンプのコンポーネントが使用されます。このコンポーネントには、汎用パッケージをパッケージレジストリにコミットするために使用される一時的な変数として、そのバージョンが格納されています。

## パイプライン構造 {#pipeline-structure}

このパイプラインは、次のステージとジョブで構成されています:

1. プリビルド
   - 単体テスト
   - Snykスキャン
1. build
   - IoSパッケージをビルドする
   - Androidパッケージをビルドする
1. test
   - 依存関係スキャン
   - SASTスキャン
1. 機能テスト
   - upload_ios/android_app_to_sauce_labs
   - automated_test_appium_saucelabs
1. アプリのディストリビューション
   - app_distribution_sauce_android
   - app_distribution_sauce_ios
1. ベータリリース
   - ベータリリース-dev
   - ベータリリース-承認

## 前提要件 {#prerequisites}

モバイルパイプラインワークフローには、複数のサードパーティツールが統合されています。パイプラインを正常に実行するには、次の前提条件が満たされていることを確認してください。

### ソリューションコンポーネントを使用したSnykインテグレーション {#snyk-integration-using-the-component}

セキュリティスキャンにGitLab Snyk CI/CDコンポーネントを使用するには、GitLabのグループまたはプロジェクトが既にSnykに接続されていることを確認してください。接続されていない場合は、[このチュートリアル](https://docs.snyk.io/scm-ide-and-ci-cd-integrations/snyk-scm-integrations/gitlab)に従って設定してください。

モバイルアプリプロジェクトで、Snykインテグレーションに必要な変数を追加します。

#### 必須CI/CD変数 {#required-cicd-variables}

| 変数 | 説明 | 値の例 |
|----------|-------------|---------------|
| `SNYK_TOKEN` | SnykにアクセスするためのAPIトークン | `d7da134c-xxxxxxxxxx` |

このモバイルアプリのデモプロジェクトでは、プライベートSnykコンポーネントを使用しているため、モバイルアプリプロジェクトがプライベートSnykコンポーネントプロジェクトにアクセスできるように、次の追加変数を追加しました。ただし、Snykコンポーネントがパブリックであるか、グループ内でアクセスできる場合は必要ありません。

```yaml
SNYK_PROJECT_ACCESS_USERNAME: "MOBILE_APP_SNYK_COMPONENT_ACCESS"
DOCKER_AUTH_CONFIG: '{"auths":{"registry.gitlab.com":{"username":"$SNYK_PROJECT_ACCESS_USERNAME","password":"$SNYK_PROJECT_ACCESS_TOKEN"}}}'
```

#### コンポーネントパスの更新 {#update-the-component-path}

パイプラインがSnykコンポーネントを正常に参照できるように、`.gitlab-ci.yml`ファイルのコンポーネントパスを更新します。

```yaml
 - component: $CI_SERVER_FQDN/gitlab-com/product-accelerator/work-streams/packaging/snyk/snyk@1.0.0 #snky sast scan, this examples uses the component in GitLab the product accelerator group. Please update the path and stage accordingly.
    inputs:
      stage: prebuild
      token: $SNYK_TOKEN
```

### Sauce Labsインテグレーション {#sauce-labs-integration}

このモバイルアプリのデモプロジェクトCI/CDは、自動機能テストのためにSauce Labsと統合されています。Sauce Labsで自動テストを実行するには、アプリケーションをSauce Labsアプリストレージにアップロードする必要があります。Sauce Labsにアクセスしてアーティファクトをアップロードするには、GitLabでプロジェクトに必要な変数を設定する必要があります。

#### 必須CI/CD変数 {#required-cicd-variables-1}

| 変数 | 説明 | 値の例 |
|----------|-------------|---------------|
| `SAUCE_USERNAME` | Sauce Labsのユーザー名| `rz` |
| `SAUCE_ACCESS_KEY` | Sauce LabsにアクセスするためのAPIキー  | `9f5wewwc-xxxxxxx` |
| `APP_FILE_PATH_IOS` | ビルドアーティファクトを見つけるためのファイルパス | `ios/build/reactCounter.ipa` |
| `APP_FILE_PATH_ANDROID` | ビルドアーティファクトを見つけるためのファイルパス | `android/app/build/outputs/apk/release/app-release.apk` |

#### 自動テストにAppiumを使用する {#use-appium-for-automated-testing}

自動テストにSauceLabsを使用するには、アプリをSauceLab App Managementにアップロードする必要があります。パイプラインは、APIエンドポイントを使用して、アプリをSauceLabsにアップロードし、テストに使用できるようにします。

WebdriverIOおよびSauce Labsを使用してReact Nativeモバイルアプリケーションをテストするために、`tests/appium`にAppiumテストスクリプトファイルを追加しました。テストスクリプトは、次の環境変数を使用してSauceLabsにアクセスします

``` bash
# Using the variables defined in the project

const SAUCE_USERNAME = process.env.SAUCE_USERNAME;
const SAUCE_ACCESS_KEY = process.env.SAUCE_ACCESS_KEY;

```

#### アプリの配信（AndroidおよびiOS） {#app-distribution-android-and-ios}

GitLabパイプラインは、デモ用にアプリのビルドアーティファクトをSauceLabs TestFairyに配信します。SauceLabs TestFairyを使用すると、ユーザーはアプリの新しいバージョンをテスターに提供して、レビューとテストを行うことができます。

### ServiceNowインテグレーション {#servicenow-integration}

このモバイルアプリのデモプロジェクトCI/CDは、変更制御のためにServiceNowと統合されています。パイプラインがServiceNowで変更制御が有効になっているデプロイメントジョブに到達すると、変更リクエストが自動的に作成されます。変更リクエストが承認されると、デプロイメントジョブが再開されます。このデモプロジェクトでは、ベータリリースの承認ジョブはServiceNowでゲートされており、続行するには手動による承認が必要です。

#### CI/CD変数 {#cicd-variables}

パイプラインがServiceNowと通信するためには、Webhookインテグレーションを作成する必要があります。APIエンドポイントを使用してServiceNowと通信する場合は、次の変数を含める必要があります。ただし、ServiceNow DevOps Changeベロシティインテグレーションを使用している場合は、これは必要ありません。ServiceNow DevOps Changeベロシティのオンボーディングの一環として、Webhookが作成されます。

| 変数 | 説明 | 値の例 |
|----------|-------------|---------------|
| `SNOW_URL` | SeriveNowインスタンスのURL| `https://<SNOW_INSTANCE>.com/` |
| `SNOW_TOOLID` | ServiceNowインスタンスID  | `3b5w345629212105c5ddaccwonworw2` |
| `SNOW_TOKEN` | ServiceNowにアクセスするためのAPIトークン| `Oxxxxxxxxxx` |

## 含まれるファイルとコンポーネント {#included-files-and-components}

モバイルアプリプロジェクトパイプラインには、いくつかの外部設定とコンポーネントが含まれています:

- iOSおよびAndroid用のローカルビルド設定
- SAST（静的アプリケーションセキュリティテスト）コンポーネント
- 自動セマンティックバージョニングコンポーネント
- 依存関係スキャン
- Snyk SASTスキャンコンポーネント

## 注 {#notes}

ソリューションコンポーネントにアクセスするための招待コードの取得、およびその他の質問については、アカウントチームにお問い合わせください。
