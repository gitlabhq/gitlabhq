---
stage: Application Security Testing
group: Composition Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: マルチコンテナスキャン
description: イメージの脆弱性スキャン、設定、カスタマイズ、レポート
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- ステータス: ベータ版

{{< /details >}}

{{< history >}}

- [導入](https://gitlab.com/groups/gitlab-org/-/epics/3139) GitLab 18.7の[実験](../../../policy/development_stages_support.md)として。

{{< /history >}}

マルチコンテナイメージスキャンを使用して、単一パイプラインで複数のコンテナイメージをスキャンします。この機能を使用すると、次のことが可能になります:

- 複数のイメージを並行してスキャンします。
- 単一の設定ファイルでスキャンターゲットを設定します。
- 既存のコンテナスキャンのワークフローと統合します。

マルチコンテナスキャンは、[動的な子パイプライン](../../../ci/pipelines/downstream_pipelines.md#dynamic-child-pipelines)を使用してスキャンを並行処理で実行し、パイプライン全体の実行時間を短縮します。

## サポートされているイメージ {#supported-images}

マルチコンテナスキャンは以下をサポートしています:

- パブリックレジストリからのイメージ（Docker Hub、GitLab Container Registryなど）
- プライベートレジストリからのイメージ（認証が設定されている場合）
- マルチアーキテクチャイメージ

## マルチコンテナスキャンを有効にする {#enable-multi-container-scanning}

前提条件: 

- Docker executorを備えたGitLab Runner。
- リポジトリのルートにある`.gitlab-multi-image.yml`設定ファイル。
- スキャンするコンテナイメージが少なくとも1つ。

マルチコンテナスキャンを有効にするには:

1. リポジトリのルートに`.gitlab-multi-image.yml`ファイルを作成します:

   ```yaml
      scanTargets:
        - name: alpine
          tag: latest
        - name: python
          tag: 3.9-slim
   ```

1. `.gitlab-ci.yml`にテンプレートを含めます:

   ```yaml
      include:
        - template: Jobs/Multi-Container-Scanning.latest.gitlab-ci.yml
   ```

1. 変更をコミットしてプッシュします。パイプラインはスキャンを自動的に実行します。

## 設定 {#configuration}

`.gitlab-multi-image.yml`ファイルを編集して、マルチコンテナスキャンを設定します。

### 基本的な設定例 {#basic-configuration-example}

```yaml
scanTargets:
  - name: alpine
    tag: "3.19"
  - name: ubuntu
    tag: "22.04"
```

### すべてのオプションを使用した設定例 {#complete-configuration-example}

```yaml
# Include license information in reports
includeLicenses: true

# Configure registry authentication
auths:
  registry.example.com:
    username: ${REGISTRY_USER}
    password: ${REGISTRY_PASSWORD}

# Allow insecure connections (not recommended for production)
allowInsecure: false

# Additional CA certificates for custom registries
additionalCaCertificateBundle: |
  -----BEGIN CERTIFICATE-----
  ...
  -----END CERTIFICATE-----

# Images to scan
scanTargets:
  - name: registry.example.com/myapp
    tag: "v1.2.3"
  - name: postgres
    tag: "15-alpine"
```

### 設定オプション {#configuration-options}

| オプション | 型 | 必須 | 説明 |
|--------|------|----------|-------------|
| `scanTargets` | 配列 | はい | スキャンするコンテナイメージのリスト |
| `scanTargets[].name` | 文字列 | はい | イメージ名（オプションのレジストリ付き） |
| `scanTargets[].tag` | 文字列 | いいえ | イメージタグ（デフォルト: `latest`） |
| `scanTargets[].registry` | 文字列 | いいえ | レジストリのオーバーライド |
| `includeLicenses` | ブール値 | いいえ | レポートにライセンス情報を含める |
| `auths` | オブジェクト | いいえ | レジストリの認証認証情報 |
| `allowInsecure` | ブール値 | いいえ | 安全でないHTTPS接続を許可する |
| `additionalCaCertificateBundle` | 文字列 | いいえ | PEM形式の追加のCA証明書 |

## 一般的なシナリオ {#common-scenarios}

次のセクションでは、ニーズに合わせて適用できるシナリオの例をいくつか説明します。

### 異なるレジストリからイメージをスキャンする {#scan-images-from-different-registries}

```yaml
scanTargets:
  - name: docker.io/library/nginx
    tag: "1.25"
  - name: registry.gitlab.com/mygroup/myapp
    tag: "main"
  - name: gcr.io/myproject/service
    tag: "prod"
```

### プライベートレジストリの認証を使用する {#use-private-registry-authentication}

```yaml
auths:
  registry.gitlab.com:
    username: ${CI_REGISTRY_USER}
    password: ${CI_REGISTRY_PASSWORD}
  docker.io:
    username: ${DOCKERHUB_USER}
    password: ${DOCKERHUB_TOKEN}

scanTargets:
  - name: registry.gitlab.com/private/image
    tag: latest
```

### コンプライアンスのために特定のバージョンをスキャンする {#scan-specific-versions-for-compliance}

```yaml
scanTargets:
  - name: postgres
    tag: "14.10"
  - name: redis
    tag: "7.2.3"
  - name: nginx
    tag: "1.25.3"
```

## CI/CD変数 {#cicd-variables}

CI/CD変数を使用して、マルチコンテナスキャンの動作をカスタマイズできます。

| 変数 | デフォルト | 説明 |
|----------|---------|-------------|
| `CONTAINER_SCANNING_DISABLED` | - | スキャンを無効にするには、`true`または`1`に設定します |
| `AST_ENABLE_MR_PIPELINES` | `true` | マージリクエストパイプラインでのスキャンを有効にする |
| `CS_SCANNER_IMAGE` | `registry.gitlab.com/.../multiple-container-scanner:0` | 使用するスキャナーイメージ |

### マルチコンテナスキャンを無効にする {#disable-multi-container-scanning}

スキャンを一時的に無効にするには:

```yaml
variables:
  CONTAINER_SCANNING_DISABLED: "true"
```

### MRパイプラインスキャンを無効にする {#disable-mr-pipeline-scanning}

```yaml
variables:
  AST_ENABLE_MR_PIPELINES: "false"
```

## スキャン結果を表示する {#view-scan-results}

パイプラインが完了した後:

1. 上部のバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. マージリクエストまたはパイプラインの詳細ページに移動します。
1. **セキュリティ**タブを選択します。
1. スキャンされたすべてのイメージから検出された脆弱性を表示します。

スキャンされた各イメージは以下を生成します:

- コンテナスキャンレポート。
- CycloneDX SBOM（ソフトウェア部品表）。
- ライセンス情報（`includeLicenses: true`の場合）。

### パイプラインの構造 {#pipeline-structure}

マルチコンテナスキャンは、2つのジョブを作成します:

- `multi-cs::generate-scan`: スキャン設定を生成します
- `multi-cs::trigger-scan`: 並行処理スキャンジョブで子パイプラインをトリガーします

子パイプラインには、`scanTargets`のイメージごとに1つのジョブが含まれています。

## トラブルシューティング {#troubleshooting}

マルチコンテナスキャンを使用する場合、次の問題が発生する可能性があります。

### パイプラインが「設定ファイルが見つかりません」というエラーで失敗する {#pipeline-fails-with-configuration-file-not-found}

原因: `.gitlab-multi-image.yml`ファイルが見つからないか、場所が間違っています。

解決策: `.gitlab-multi-image.yml`がリポジトリのルートに存在することを確認します。

### プライベートレジストリの認証が失敗する {#authentication-fails-for-private-registry}

原因: 無効な認証情報または認証設定が見つかりません。

解決策: 

1. 認証情報が正しく、正しく設定されていることを確認します。

   ```yaml
      auths:
        registry.example.com:
          username: ${REGISTRY_USER}
          password: ${REGISTRY_PASSWORD}
   ```

1. **設定** > \*\*CI/CD > **変数**に変数を定義します。

### スキャンに時間がかかりすぎる {#scan-takes-too-long}

原因: 複数の大きなイメージが順番にスキャンされています。

解決策: マルチコンテナスキャンは、すでにスキャンを並行処理で実行しています。

以下を検討してください:

- より小さなベースイメージを使用する
- 特定イメージのバージョンのみをスキャンする
- GitLab Runnerの並行処理設定を調整する

### 子パイプラインにレポートが表示されない {#child-pipeline-doesnt-show-reports}

原因: トリガー設定で`strategy: mirror`が見つかりません。

解決策: これは、テンプレートでデフォルトで設定されています。テンプレートをカスタマイズした場合は、トリガージョブに`strategy: mirror`が含まれていることを確認してください。
