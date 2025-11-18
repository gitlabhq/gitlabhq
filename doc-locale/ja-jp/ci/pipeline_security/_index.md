---
stage: Software Supply Chain Security
group: Pipeline Security
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: パイプラインセキュリティ
description: シークレット管理、ジョブトークン、セキュアファイル、クラウドセキュリティ。
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

## シークレット管理 {#secrets-management}

シークレット管理は、厳格なアクセス制御を備えた安全な環境で機密データを安全に保存するためにデベロッパーが使用するシステムです。**シークレット**は、機密保持が必要な機密性の高い認証情報です。シークレットには、次のようなものがあります:

- パスワード
- SSHキー
- アクセストークン
- 公開されると組織にとって有害となる可能性のあるその他の種類の認証情報

## シークレットの保存 {#secrets-storage}

### シークレット管理プロバイダー {#secrets-management-providers}

最も機密性が高く、最も厳格なポリシーが適用されるシークレットは、シークレットマネージャーに保存する必要があります。シークレットマネージャーのソリューションを使用する場合、シークレットはGitLabインスタンスの外部に保存されます。この分野には、[HashiCorpのVault](https://www.vaultproject.io) 、[Azure Key Vault](https://azure.microsoft.com/en-us/products/key-vault) 、[Google CloudのSecret Manager](https://cloud.google.com/security/products/secret-manager)など、多くのプロバイダーが存在します。

特定の[外部シークレット管理プロバイダー](../secrets/_index.md)にGitLabネイティブインテグレーションを使用すると、必要なときにCI/CDパイプラインでそれらのシークレットを取得できます。

### CI/CD変数 {#cicd-variables}

[CI/CD変数](../variables/_index.md)はCI/CDパイプラインでデータを保存および再利用するのに便利な方法ですが、変数はシークレット管理プロバイダーほど安全ではありません。変数の値は次のように処理されます:

- GitLabプロジェクト、グループ、またはインスタンスの設定に保存されます。設定へのアクセス権を持つユーザーは、[非表示](../variables/_index.md#hide-a-cicd-variable)になっていない変数の値にアクセスできます。
- [上書き](../variables/_index.md#use-pipeline-variables)できるため、どの値が使用されたかを判断するのが困難になります。
- 偶発的なパイプラインの設定ミスによって公開される可能性があります。

情報として変数への保存に適するのは、悪用のリスクなしに公開できるデータ（機密性の低い情報）です。

機密データは、シークレット管理ソリューションに保存することをお勧めします。シークレット管理ソリューションがなく、機密データをCI/CD変数に保存する場合は、必ず次のことを行ってください:

- [変数をマスクする](../variables/_index.md#mask-a-cicd-variable)。
- [変数を非表示にする](../variables/_index.md#hide-a-cicd-variable)。
- 可能な場合は[変数を保護する](../variables/_index.md#protect-a-cicd-variable)。

## CI/CDパイプラインにパラメータを渡す {#pass-parameters-to-cicd-pipelines}

CI/CDパイプラインにパラメータを渡すには、パイプライン変数の代わりに[CI/CD入力](../inputs/_index.md)を使用します。

入力は以下を提供します:

- パイプライン作成時の型安全検証。
- 明示的なパラメータコントラクト。
- セキュリティを強化する、スコープされた可用性。

入力を実装してセキュリティの脆弱性を防ぐ場合は、[パイプライン変数の無効化](../variables/_index.md#restrict-pipeline-variables)を検討してください。パイプライン変数は、次の理由で使用すべきではありません:

- 型検証がありません。
- 定義済み変数をオーバーライドして、予期しない動作を引き起こす可能性があります。
- 機密シークレットと同じ許可スコープを共有します。

## パイプラインの整合性 {#pipeline-integrity}

パイプラインの整合性を確保するための主要なセキュリティ原則には、以下が含まれます:

- **サプライチェーンセキュリティ**: アセットは信頼できるソースから入手し、その整合性を検証する必要があります。
- **再現性**: パイプラインは、同じインプットを使用するときに一貫した結果を生成する必要があります。
- **可監査性**: パイプラインのすべての依存関係を追跡可能にし、その出所を検証可能にする必要があります。
- **バージョン管理**: パイプラインの依存関係への変更は、追跡および管理する必要があります。

### Dockerイメージ {#docker-images}

クライアント側の整合性検証を確実にするために、Dockerイメージには常にSHAダイジェストを使用してください。次に例を示します:

- Node:
  - 使用: `image: node@sha256:0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef`
  - 使用しない: `image: node:latest`
- Python:
  - 使用: `image: python@sha256:9876543210abcdef9876543210abcdef9876543210abcdef9876543210abcdef`
  - 使用しない: `image: python:3.9`

特定のタグが付いたイメージのSHAダイジェストは、次を使用して見つけることができます:

```shell
docker pull node:18.17.1
docker images --digests node:18.17.1
```

イメージの整合性を保護するコンテナレジストリからプルすることをお勧めします:

- [保護されたコンテナリポジトリ](../../user/packages/container_registry/container_repository_protection_rules.md)を使用して、コンテナリポジトリ内のコンテナイメージを変更できるユーザーを制限します。
- [保護タグ](../../user/packages/container_registry/protected_container_tags.md)を使用して、コンテナタグをプッシュおよび削除できるユーザーを制御します。

可能な場合は、悪意のあるイメージを指すように変更される可能性があるため、コンテナ参照で変数を使用しないでください。次に例を示します:

- 推奨:
  - `image: my-registry.example.com/node:18.17.1`
- 使用しない:
  - `image: ${CUSTOM_REGISTRY}/node:latest`
  - `image: node:${VERSION}`

### パッケージの依存関係 {#package-dependencies}

ジョブでパッケージの依存関係をロックダウンする必要があります。ロックファイルで定義された正確なバージョンを使用してください:

- npm:
  - 使用: `npm ci`
  - 使用しない: `npm install`
- yarn:
  - 使用: `yarn install --frozen-lockfile`
  - 使用しない: `yarn install`
- Python:
  - 使用方法:
    - `pip install -r requirements.txt --require-hashes`
    - `pip install -r requirements.lock`
  - 使用しない: `pip install -r requirements.txt`
- Go:
  - `go.sum`からの正確なバージョンを使用:
    - `go mod verify`
    - `go mod download`
  - 使用しない: `go get ./...`

たとえば、CI/CDジョブでは、次のようになります:

```yaml
javascript-job:
  script:
    - npm ci
```

### Shellコマンドとスクリプト {#shell-commands-and-scripts}

ジョブにツールをインストールするときは、常に正確なバージョンを指定して確認してください。たとえば、Terraformジョブでは、次のように指定します:

```yaml
terraform_job:
  script:
    # Download specific version
    - |
      wget https://releases.hashicorp.com/terraform/1.5.7/terraform_1.5.7_linux_amd64.zip
      # IMPORTANT: Always verify checksums
      echo "c0ed7bc32ee52ae255af9982c8c88a7a4c610485cf1d55feeb037eab75fa082c terraform_1.5.7_linux_amd64.zip" | sha256sum -c
      unzip terraform_1.5.7_linux_amd64.zip
      mv terraform /usr/local/bin/
    # Use the installed version
    - terraform init
    - terraform plan
```

### バージョン管理ツール {#version-management-tools}

可能な場合はバージョンマネージャーを使用してください:

```yaml
node_build:
  script:
    # Use nvm to install and use a specific Node version
    - |
      nvm install 16.15.1
      nvm use 16.15.1
    - node --version  # Verify version
    - npm ci
    - npm run build
```

### インクルード対象の設定 {#included-configurations}

パイプラインに設定またはCI/CDコンポーネントを追加するために[`include`キーワード](../yaml/_index.md#include)を使用する場合は、可能な限り特定のrefを使用してください。次に例を示します:

```yaml
include:
  - project: 'my-group/my-project'
    ref: 8b0c8b318857c8211c15c6643b0894345a238c4e  # Pin to a specific commit
    file: '/templates/build.yml'
  - project: 'my-group/security'
    ref: v2.1.0                                    # Pin to a protected tag
    file: '/templates/scan.yml'
  - component: 'my-group/security-scans'           # Pin to a specific version
    version: '1.2.3'
```

バージョンレスのインクルードは避けてください:

```yaml
include:
  - project: 'my-group/my-project'                   # Unsafe
    file: '/templates/build.yml'
  - component: 'my-group/security-scans'             # Unsafe
  - remote: 'https://example.com/security-scan.yml'  # Unsafe
```

リモートファイルをインクルードするのではなく、ファイルをダウンロードしてリポジトリに保存します。その後、ローカルコピーをインクルードします:

```yaml
include:
  - local: '/ci/security-scan.yml'  # Verified and stored in the repository
```

### 関連トピック {#related-topics}

1. [CISのDockerベンチマーク](https://www.cisecurity.org/benchmark/docker)
1. Google Cloud: [安全なデプロイパイプラインをデザインする](https://cloud.google.com/architecture/design-secure-deployment-pipelines-bp)
