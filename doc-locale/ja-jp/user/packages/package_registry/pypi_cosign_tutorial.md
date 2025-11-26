---
stage: Package
group: Package Registry
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: 'チュートリアル: GitLab CI/CDでPythonパッケージをビルドして署名する'
---

このチュートリアルでは、Pythonパッケージのセキュアなパイプラインを実装する方法について説明します。このパイプラインには、GitLab CI/CDと[Sigstore Cosign](https://docs.sigstore.dev/)を使用して、Pythonパッケージを暗号で署名および検証するステージが含まれています。

このチュートリアルを終えると、次の方法を習得できます:

- GitLab CI/CDを使用してPythonパッケージをビルドして署名します。
- 汎用パッケージレジストリを使用して、パッケージ署名を保存および管理します。
- エンドユーザーとしてパッケージ署名を検証します。

## パッケージ署名の利点とは何ですか？ {#what-are-the-benefits-of-package-signing}

パッケージ署名は、いくつかの重要なセキュリティ上の利点を提供します:

- 信頼性: ユーザーは、パッケージが信頼できるソースからのものであることを検証できます。
- データの整合性: 配布中にパッケージが改ざんされた場合、それが検出されます。
- 否認防止: パッケージのオリジンを暗号で証明できます。
- サプライチェーンセキュリティ: パッケージ署名は、サプライチェーン攻撃や侵害されたリポジトリから保護します。

## はじめる前 {#before-you-begin}

このチュートリアルを完了するには、以下が必要です:

- GitLabアカウントとテストGitLabプロジェクト。
- Pythonパッケージ、GitLab CI/CD、およびパッケージレジストリの概念に関する基本的な知識。

## ステップ {#steps}

以下は、実行する手順の概要です:

1. [Pythonプロジェクトをセットアップします。](#set-up-a-python-project)
1. [基本設定を追加します。](#add-base-configuration)
1. [ビルドステージを設定します。](#configure-the-build-stage)
1. [署名ステージを設定します。](#configure-the-sign-stage)
1. [検証ステージを設定します。](#configure-the-verify-stage)
1. [公開ステージを設定します。](#configure-the-publish-stage)
1. [署名公開ステージを設定します。](#configure-the-publish-signatures-stage)
1. [コンシューマー検証ステージを設定します。](#configure-the-consumer-verification-stage)
1. [ユーザーとしてパッケージを検証します。](#verify-packages-as-a-user)

### Pythonプロジェクトをセットアップします {#set-up-a-python-project}

まず、テストプロジェクトを作成します。プロジェクトのルートに`pyproject.toml`ファイルを追加します:

```toml
[build-system]
requires = ["setuptools>=45", "wheel"]
build-backend = "setuptools.build_meta"

[project]
name = "<my_package>"  # Will be dynamically replaced by CI/CD pipeline
version = "<1.0.0>"    # Will be dynamically replaced by CI/CD pipeline
description = "<Your package description>"
readme = "README.md"
requires-python = ">=3.7"
authors = [
    {name = "<Your Name>", email = "<your.email@example.com>"},
]

[project.urls]
"Homepage" = "<https://gitlab.com/my_package>"  # Will be replaced with actual project URL
```

`Your Name`と`your.email@example.com`を自分の個人詳細に置き換えてください。

以下の手順でCI/CDパイプラインのビルドを完了すると、パイプラインは自動的に次のようになります:

- `my_package`を、正規化されたバージョンのプロジェクト名に置き換えます。
- `version`をパイプラインのバージョンに一致するように変更します。
- `Homepage` URLをGitLabプロジェクトURLに一致するように変更します。

#### 基本設定を追加 {#add-base-configuration}

プロジェクトのルートに`.gitlab-ci.yml`ファイルを追加します。次の設定を追加します:

```yaml
variables:
  # Base Python version for all jobs
  PYTHON_VERSION: '3.10'
  # Package names and versions
  PACKAGE_NAME: ${CI_PROJECT_NAME}
  PACKAGE_VERSION: "1.0.0"  # Use semantic versioning
  # Sigstore service URLs
  FULCIO_URL: 'https://fulcio.sigstore.dev'
  REKOR_URL: 'https://rekor.sigstore.dev'
  # Identity for Sigstore verification
  CERTIFICATE_IDENTITY: 'https://gitlab.com/${CI_PROJECT_PATH}//.gitlab-ci.yml@refs/heads/${CI_DEFAULT_BRANCH}'
  CERTIFICATE_OIDC_ISSUER: 'https://gitlab.com'
  # Pip cache directory for faster builds
  PIP_CACHE_DIR: "$CI_PROJECT_DIR/.pip-cache"
  # Auto-accept prompts from Cosign
  COSIGN_YES: "true"
  # Base URL for generic package registry
  GENERIC_PACKAGE_BASE_URL: "${CI_API_V4_URL}/projects/${CI_PROJECT_ID}/packages/generic/${PACKAGE_NAME}/${PACKAGE_VERSION}"

default:
  before_script:
    # Normalize package name once at the start of any job
    - export NORMALIZED_NAME=$(echo "${CI_PROJECT_NAME}" | tr '-' '_')

# Template for Python-based jobs
.python-job:
  image: python:${PYTHON_VERSION}
  before_script:
    # First normalize package name
    - export NORMALIZED_NAME=$(echo "${CI_PROJECT_NAME}" | tr '-' '_')
    # Then install Python dependencies
    - pip install --upgrade pip
    - pip install build twine setuptools wheel
  cache:
    paths:
      - ${PIP_CACHE_DIR}

# Template for Python + Cosign jobs
.python+cosign-job:
  extends: .python-job
  before_script:
    # First normalize package name
    - export NORMALIZED_NAME=$(echo "${CI_PROJECT_NAME}" | tr '-' '_')
    # Then install dependencies
    - apt-get update && apt-get install -y curl wget
    - wget -O cosign https://github.com/sigstore/cosign/releases/download/v2.2.3/cosign-linux-amd64
    - chmod +x cosign && mv cosign /usr/local/bin/
    - export COSIGN_EXPERIMENTAL=1
    - pip install --upgrade pip
    - pip install build twine setuptools wheel
stages:
  - build
  - sign
  - verify
  - publish
  - publish_signatures
  - consumer_verification
```

この基本設定:

- 一貫性のために、Python `3.10`をベースイメージとして使用するようにパイプラインに指示します
- 2つの再利用可能なテンプレートをセットアップします。基本的なPython操作には`.python-job`、署名操作には`.python+cosign-job`。
- ビルドを高速化するためにPipキャッシュを実装します
- ハイフンをアンダースコアに変換して、Pythonとの互換性を実現することにより、パッケージ名を正規化します
- 管理を容易にするために、すべてのキー変数をパイプラインレベルで定義します

### ビルドステージを設定します {#configure-the-build-stage}

ビルドステージは、Pythonディストリビューションパッケージをビルドします。

`.gitlab-ci.yml`ファイルに、次の設定を追加します:

```yaml
build:
  extends: .python-job
  stage: build
  script:
    # Initialize git repo with actual content
    - git init
    - git config --global init.defaultBranch main
    - git config --global user.email "ci@example.com"
    - git config --global user.name "CI"
    - git add .
    - git commit -m "Initial commit"

    # Update package name, version, and homepage URL in pyproject.toml
    - sed -i "s/name = \".*\"/name = \"${NORMALIZED_NAME}\"/" pyproject.toml
    - sed -i "s/version = \".*\"/version = \"${PACKAGE_VERSION}\"/" pyproject.toml
    - sed -i "s|\"Homepage\" = \".*\"|\"Homepage\" = \"https://gitlab.com/${CI_PROJECT_PATH}\"|" pyproject.toml

    # Debug: show updated file
    - echo "Updated pyproject.toml contents:"
    - cat pyproject.toml

    # Build package
    - python -m build
  artifacts:
    paths:
      - dist/
      - pyproject.toml
```

ビルドステージの設定:

- ビルドコンテキストのGitリポジトリを初期化します
- `pyproject.toml`でパッケージメタデータを動的に更新します
- ホイール（`.whl`）とソース配布（`.tar.gz`）パッケージの両方を追加します
- 後続のステージのためにビルドアーティファクトを保持します
- トラブルシューティング用のデバッグ出力を提供します

### 署名ステージを設定します {#configure-the-sign-stage}

署名ステージは、Sigstore Cosignを使用してパッケージに署名します。

`.gitlab-ci.yml`ファイルに、次の設定を追加します:

```yaml
sign:
  extends: .python+cosign-job
  stage: sign
  id_tokens:
    SIGSTORE_ID_TOKEN:
      aud: sigstore
  script:
    - |
      for file in dist/*.whl dist/*.tar.gz; do
        if [ -f "$file" ]; then
          filename=$(basename "$file")

          cosign sign-blob --yes \
            --fulcio-url=${FULCIO_URL} \
            --rekor-url=${REKOR_URL} \
            --oidc-issuer $CI_SERVER_URL \
            --identity-token $SIGSTORE_ID_TOKEN \
            --output-signature "dist/${filename}.sig" \
            --output-certificate "dist/${filename}.crt" \
            "$file"

          # Debug: Verify files were created
          echo "Checking generated signature and certificate:"
          ls -l "dist/${filename}.sig" "dist/${filename}.crt"
        fi
      done
  artifacts:
    paths:
      - dist/
```

署名ステージの設定:

- セキュリティを強化するために、Sigstoreの[キーレス署名](https://docs.sigstore.dev/cosign/signing/overview/)を使用します
- ホイールとソース配布パッケージの両方に署名します
- 個別の署名（`.sig`）ファイルと証明書（`.crt`）ファイルを作成します
- 認証にOIDCインテグレーションを使用します
- 署名生成の詳細なログ記録が含まれています

### 検証ステージを設定します {#configure-the-verify-stage}

検証ステージは、ローカルで署名を検証します。

`.gitlab-ci.yml`ファイルに、次の設定を追加します:

```yaml
verify:
  extends: .python+cosign-job
  stage: verify
  script:
    - |
      failed=0

      for file in dist/*.whl dist/*.tar.gz; do
        if [ -f "$file" ]; then
          filename=$(basename "$file")

          echo "Verifying file: $file"
          echo "Using signature: dist/${filename}.sig"
          echo "Using certificate: dist/${filename}.crt"

          if ! cosign verify-blob \
            --signature "dist/${filename}.sig" \
            --certificate "dist/${filename}.crt" \
            --certificate-identity "${CERTIFICATE_IDENTITY}" \
            --certificate-oidc-issuer "${CERTIFICATE_OIDC_ISSUER}" \
            "$file"; then
            echo "Verification failed for $filename"
            failed=1
          fi
        fi
      done

      if [ $failed -eq 1 ]; then
        exit 1
      fi
```

検証ステージの設定:

- 署名直後に署名を検証します
- ホイールとソース配布パッケージの両方をチェックします
- 証明書のIDとOIDC発行者を検証します
- いずれかの検証がフェイルファストした場合は失敗します
- 詳細な検証ログを提供します

### 公開ステージを設定します {#configure-the-publish-stage}

公開ステージは、パッケージをGitLab PyPIパッケージレジストリにアップロードします。

`.gitlab-ci.yml`ファイルに、次の設定を追加します:

```yaml
publish:
  extends: .python-job
  stage: publish
  script:
    - |
      # Configure PyPI settings for GitLab package registry
      cat << EOF > ~/.pypirc
      [distutils]
      index-servers = gitlab
      [gitlab]
      repository = ${CI_API_V4_URL}/projects/${CI_PROJECT_ID}/packages/pypi
      username = gitlab-ci-token
      password = ${CI_JOB_TOKEN}
      EOF

      # Upload packages using twine
      TWINE_PASSWORD=${CI_JOB_TOKEN} TWINE_USERNAME=gitlab-ci-token \
        twine upload --repository-url ${CI_API_V4_URL}/projects/${CI_PROJECT_ID}/packages/pypi \
        dist/*.whl dist/*.tar.gz
```

公開ステージの設定:

- PyPIレジストリの認証を設定します
- GitLab組み込みのパッケージレジストリを使用します
- ホイールとソース配布の両方を公開します
- セキュアな認証にジョブトークンを使用します
- 再利用可能な`.pypirc`設定を作成します

### 署名公開ステージを設定します {#configure-the-publish-signatures-stage}

署名公開ステージは、GitLabの汎用パッケージレジストリに署名を保存します。

`.gitlab-ci.yml`ファイルに、次の設定を追加します:

```yaml
publish_signatures:
  extends: .python+cosign-job
  stage: publish_signatures
  script:
    - |
      for file in dist/*.whl dist/*.tar.gz; do
        if [ -f "$file" ]; then
          filename=$(basename "$file")

          ls -l "dist/${filename}.sig" "dist/${filename}.crt"

          echo "Publishing signatures for $filename"
          echo "Publishing to: ${GENERIC_PACKAGE_BASE_URL}/${filename}.sig"

          # Upload signature and certificate
          curl --header "JOB-TOKEN: ${CI_JOB_TOKEN}" \
               --fail \
               --upload-file "dist/${filename}.sig" \
               "${GENERIC_PACKAGE_BASE_URL}/${filename}.sig"

          curl --header "JOB-TOKEN: ${CI_JOB_TOKEN}" \
               --fail \
               --upload-file "dist/${filename}.crt" \
               "${GENERIC_PACKAGE_BASE_URL}/${filename}.crt"
        fi
      done
```

署名公開ステージの設定:

- 汎用パッケージレジストリに署名を保存します
- 署名とパッケージのマッピングを維持します
- アーティファクトに一貫性のある命名規則を使用します
- 署名のサイズ検証が含まれています
- 詳細なアップロードログを提供します

### コンシューマー検証ステージを設定します {#configure-the-consumer-verification-stage}

コンシューマー検証ステージは、エンドユーザーのパッケージ検証をシミュレートします。

`.gitlab-ci.yml`ファイルに、次の設定を追加します:

```yaml
consumer_verification:
  extends: .python+cosign-job
  stage: consumer_verification
  script:
    - |
      # Initialize git repo for setuptools_scm
      git init
      git config --global init.defaultBranch main

      # Create directory for downloading packages
      mkdir -p pkg signatures

      # Download the specific wheel version
      pip download --index-url "https://gitlab-ci-token:${CI_JOB_TOKEN}@gitlab.com/api/v4/projects/${CI_PROJECT_ID}/packages/pypi/simple" \
          "${NORMALIZED_NAME}==${PACKAGE_VERSION}" --no-deps -d ./pkg --verbose

      # Download the specific source distribution version
      pip download --no-binary :all: \
          --index-url "https://gitlab-ci-token:${CI_JOB_TOKEN}@gitlab.com/api/v4/projects/${CI_PROJECT_ID}/packages/pypi/simple" \
          "${NORMALIZED_NAME}==${PACKAGE_VERSION}" --no-deps -d ./pkg --verbose

      failed=0
      for file in pkg/*.whl pkg/*.tar.gz; do
        if [ -f "$file" ]; then
          filename=$(basename "$file")

          sig_url="${GENERIC_PACKAGE_BASE_URL}/${filename}.sig"
          cert_url="${GENERIC_PACKAGE_BASE_URL}/${filename}.crt"

          echo "Downloading signatures for $filename"
          echo "Signature URL: $sig_url"
          echo "Certificate URL: $cert_url"

          # Download signatures
          curl --fail --silent --show-error \
               --header "JOB-TOKEN: ${CI_JOB_TOKEN}" \
               --output "signatures/${filename}.sig" \
               "$sig_url"

          curl --fail --silent --show-error \
               --header "JOB-TOKEN: ${CI_JOB_TOKEN}" \
               --output "signatures/${filename}.crt" \
               "$cert_url"

          # Verify signature
          if ! cosign verify-blob \
            --signature "signatures/${filename}.sig" \
            --certificate "signatures/${filename}.crt" \
            --certificate-identity "${CERTIFICATE_IDENTITY}" \
            --certificate-oidc-issuer "${CERTIFICATE_OIDC_ISSUER}" \
            "$file"; then
            echo "Signature verification failed"
            failed=1
          fi
        fi
      done

      if [ $failed -eq 1 ]; then
        echo "Verification failed for one or more packages"
        exit 1
      fi
```

コンシューマー検証ステージの設定:

- 実際の本番環境へのパッケージインストールをシミュレートします
- 両方のパッケージ形式をダウンロードして検証します
- 一貫性のために正確なバージョン照合を使用します
- 包括的なエラー処理を実装します
- 完全な検証ワークフローをテストします

### ユーザーとしてパッケージを検証します {#verify-packages-as-a-user}

エンドユーザーとして、次の手順でパッケージ署名を検証できます:

1. Cosignをインストールします:

   ```shell
   wget -O cosign https://github.com/sigstore/cosign/releases/download/v2.2.3/cosign-linux-amd64
   chmod +x cosign && sudo mv cosign /usr/local/bin/
   ```

   Cosignには、グローバルインストールのための特別な権限が必要です。`sudo`を使用して、権限の問題を回避します。

1. パッケージとその署名をダウンロードします:

   ```shell
   # You can find your PROJECT_ID in your GitLab project's home page under the project name

   # Download the specific version of the package
   pip download your-package-name==1.0.0 --no-deps

   # The FILENAME will be the output from the pip download command
   # For example: your-package-name-1.0.0.tar.gz or your-package-name-1.0.0-py3-none-any.whl

   # Download signatures from GitLab's generic package registry
   # Replace these values with your project's details:
   # GITLAB_URL: Your GitLab instance URL (for example, https://gitlab.com)
   # PROJECT_ID: Your project's ID number
   # PACKAGE_NAME: Your package name
   # VERSION: Package version (for example, 1.0.0)
   # FILENAME: The exact filename of your downloaded package

   curl --output "${FILENAME}.sig" \
     "${GITLAB_URL}/api/v4/projects/${PROJECT_ID}/packages/generic/${PACKAGE_NAME}/${VERSION}/${FILENAME}.sig"

   curl --output "${FILENAME}.crt" \
     "${GITLAB_URL}/api/v4/projects/${PROJECT_ID}/packages/generic/${PACKAGE_NAME}/${VERSION}/${FILENAME}.crt"
   ```

1. 署名を検証します:

   ```shell
   # Replace CERTIFICATE_IDENTITY and CERTIFICATE_OIDC_ISSUER with the values from the project's pipeline
   export CERTIFICATE_IDENTITY="https://gitlab.com/your-group/your-project//.gitlab-ci.yml@refs/heads/main"
   export CERTIFICATE_OIDC_ISSUER="https://gitlab.com"

   # Verify wheel package
   FILENAME="your-package-name-1.0.0-py3-none-any.whl"
   COSIGN_EXPERIMENTAL=1 cosign verify-blob \
     --signature "${FILENAME}.sig" \
     --certificate "${FILENAME}.crt" \
     --certificate-identity "${CERTIFICATE_IDENTITY}" \
     --certificate-oidc-issuer "${CERTIFICATE_OIDC_ISSUER}" \
     "${FILENAME}"

   # Verify source distribution
   FILENAME="your-package-name-1.0.0.tar.gz"
   COSIGN_EXPERIMENTAL=1 cosign verify-blob \
     --signature "${FILENAME}.sig" \
     --certificate "${FILENAME}.crt" \
     --certificate-identity "${CERTIFICATE_IDENTITY}" \
     --certificate-oidc-issuer "${CERTIFICATE_OIDC_ISSUER}" \
     "${FILENAME}"
   ```

エンドユーザーとしてパッケージを検証する場合:

- パッケージのダウンロードが、検証するバージョンと正確に一致していることを確認してください。
- 各パッケージタイプ（ホイールとソース配布）を個別に検証します。
- 証明書のIDが、パッケージの署名に使用されたものと正確に一致していることを確認してください。
- すべてのURLコンポーネントが正しく設定されていることを確認してください。たとえば、`GITLAB_URL`または`PROJECT_ID`などです。
- パッケージファイル名が、レジストリにアップロードされたものと正確に一致していることを確認してください。
- キーレス検証には、`COSIGN_EXPERIMENTAL=1`機能フラグを使用します。このフラグは必須です。
- 失敗した検証は、改ざんまたは正しくない証明書と署名のペアを示している可能性があることを理解してください。
- プロジェクトのパイプラインからの証明書のIDと発行者の値を追跡します。

## トラブルシューティング {#troubleshooting}

このチュートリアルを完了すると、次のエラーが発生する可能性があります:

### エラー: `404 Not Found` {#error-404-not-found}

`404 Not Found`エラーページが発生した場合:

- すべてのURLコンポーネントを再確認してください。
- パッケージのバージョンがレジストリに存在することを検証します。
- ファイル名が、バージョンとプラットフォームタグ付けを含め、正確に一致していることを確認してください。

### 検証に失敗しました {#verification-failed}

署名の検証に失敗した場合は、以下を確認してください:

- `CERTIFICATE_IDENTITY`が署名パイプラインと一致している。
- `CERTIFICATE_OIDC_ISSUER`が正しい。
- 署名と証明書のペアがパッケージに対して正しい。

### アクセス拒否 {#permission-denied}

権限に関する問題が発生した場合:

- パッケージレジストリへのアクセス権があるかどうかを確認します。
- レジストリがプライベートの場合は、認証を検証します。
- Cosignをインストールするときは、正しいファイル権限を使用してください。

### 認証に関する問題 {#authentication-issues}

認証に関する問題が発生した場合:

- `CI_JOB_TOKEN`の権限を確認してください。
- レジストリの認証設定を検証します。
- プロジェクトのアクセス設定を検証します。

### パッケージの設定とパイプラインの設定を検証します {#verify-package-configuration-and-pipeline-settings}

パッケージの設定を確認してください。以下を確認してください:

- パッケージ名には、ハイフン（`-`）ではなく、アンダースコア（`_`）を使用します。
- バージョン文字列は有効な[PEP 440](https://peps.python.org/pep-0440/)を使用します。
- `pyproject.toml`ファイルが正しくフォーマットされている。

パイプラインの設定を確認してください。以下を確認してください:

- OIDCが正しく設定されている。
- ジョブの依存関係が正しく設定されている。
- 必要な権限が整っている。
