---
stage: Package
group: Package Registry
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: 'チュートリアル: CI/CDでパッケージを自動的にビルドして公開する'
---

CI/CDを使用してPyPIパッケージをビルドし、プッシュできます。自動ビルドは、パッケージを常に最新の状態に保ち、他のユーザーが利用できるようにするのに役立ちます。

このチュートリアルでは、新しいCI/CD設定を作成して、サンプルPyPIパッケージをビルド、テスト、およびプッシュします。完了すると、パイプラインの各ステージの動作をより良く理解できるようになり、CI/CDを独自のパッケージレジストリワークフローに統合することに抵抗がなくなるはずです。

CI/CDでパッケージを自動的にビルドして公開するには、次のようにします:

1. [.gitlab-ci.yml`.gitlab-ci.yml`ファイルを作成する](#create-a-gitlab-ciyml-file)
   1. オプション。[CI/CD変数なしで認証する](#authenticate-without-a-cicd-variable)
1. [パイプラインを確認](#check-the-pipeline)

## はじめる前 {#before-you-begin}

このチュートリアルを完了する前に、以下を確認してください:

- テストプロジェクト。任意のPythonプロジェクトを使用できますが、このチュートリアル専用のプロジェクトを作成することを検討してください。
- PyPIとGitLabパッケージレジストリに関する知識。

## `.gitlab-ci.yml`ファイルを作成する {#create-a-gitlab-ciyml-file}

すべてのCI/CD設定には、`.gitlab-ci.yml`が必要です。このファイルは、CI/CDパイプラインの各ステージを定義します。この例では、ステージは次のとおりです:

- `build` - PyPIパッケージをビルドします。
- `test` - テストフレームワーク`pytest`でパッケージを検証します。
- `publish` - パッケージをパッケージレジストリに公開します。

`.gitlab-ci.yml`ファイルを作成するには、次のようにします:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。[新しいナビゲーションをオン](../../interface_redesign.md#turn-new-navigation-on-or-off)にしている場合、このフィールドは上部のバーにあります。
1. **コード** > **リポジトリ**を選択します。
1. ファイルリストの上部で、コミット先のブランチを選択します。
1. **新規作成**（{{< icon name="plus" >}}）と**新しいファイル**を選択します。[新しいナビゲーションをオンにした](../../interface_redesign.md#turn-new-navigation-on-or-off)場合、このボタンは右上隅にあります。
1. ファイルに`.gitlab-ci.yml`という名前を付けます。大きなウィンドウに、このサンプル設定を貼り付けます:

   ```yaml
   default:
     image: python:3.9
     cache:
       paths:
         - .pip-cache/
     before_script:
       - python --version
       - pip install --upgrade pip
       - pip install build twine

   stages:
     - build
     - test
     - publish

   variables:
     PIP_CACHE_DIR: "$CI_PROJECT_DIR/.pip-cache"

   build:
     stage: build
     script:
       - python -m build
     artifacts:
       paths:
         - dist/

   test:
     stage: test
     script:
       - pip install pytest
       - pip install dist/*.whl
       - pytest

   publish:
     stage: publish
     script:
       - TWINE_PASSWORD=${CI_JOB_TOKEN} TWINE_USERNAME=gitlab-ci-token python -m twine upload --repository-url ${CI_API_V4_URL}/projects/${CI_PROJECT_ID}/packages/pypi dist/*
     rules:
       - if: $CI_COMMIT_TAG
   ```

1. **変更をコミットする**を選択します。

以下は、コミットされたコードの簡単な説明です:

- `image` - 使用するDockerイメージを指定します。
- `stages` - このパイプラインの3つのステージを定義します。
- `variables`と`cache`-キャッシュを使用するようにPipを設定します。これにより、後続のパイプラインの実行が少し速くなる可能性があります。
- `before_script` - 3つのステージを完了するために必要なツールをインストールします。
- `build` - パッケージをビルドし、結果をアーティファクトとして保存します。
- `test` - pytestをインストールして実行し、パッケージを検証します。
- `publish` - 新しいタグがプッシュされた場合にのみ、twineを使用してパッケージをパッケージレジストリにアップロードします。`CI_JOB_TOKEN`を使用して、パッケージレジストリで認証します。

### CI/CD変数なしで認証する {#authenticate-without-a-cicd-variable}

パッケージレジストリで認証するために、設定では`CI_JOB_TOKEN`を使用します。これはGitLab CI/CDによって自動的に提供されます。外部PyPIレジストリにプッシュするには、プロジェクト設定でシークレット変数を設定する必要があります:

1. 左側のサイドバーで、**設定** > **CI/CD** > **変数**を選択します。
1. PyPI APIトークンを値として持つ`PYPI_TOKEN`という名前の新しい変数を追加します。
1. `.gitlab-ci.yml`ファイルで、`publish:script`を次のように置き換えます:

   ```yaml
   script:
   - TWINE_PASSWORD=${PYPI_TOKEN} TWINE_USERNAME=__token__ python -m twine upload dist/*
   ```

## パイプラインを確認 {#check-the-pipeline}

変更をコミットすると、パイプラインが正しく実行されることを確認する必要があります:

- 左側のサイドバーで、**ビルド** > **パイプライン**を選択します。最新のパイプラインには、以前に定義した3つのステージが必要です。

パイプラインが実行されていない場合は、新しいパイプラインを手動で実行し、正常に完了することを確認してください。

## ベストプラクティス {#best-practices}

パッケージのセキュリティと安定性を確保するために、パッケージレジストリへのプッシュに関するベストプラクティスに従う必要があります。追加した設定:

- パイプラインを高速化するために、キャッシュを実装します。
- アーティファクトを使用して、ビルドされたパッケージをステージ間で渡します。
- 公開前にパッケージを検証するためのテストステージが含まれています。
- 認証トークンなどの機密情報にGitLab CI/CD変数を使用します。
- 新しいGitタグがプッシュされた場合にのみプッシュします。これにより、適切にバージョニングされたリリースのみが公開されるようになります。

おつかれさまでした。GitLab CI/CDを使用して、パッケージのビルド、テスト、およびプッシュに成功しました。同様の設定を使用して、独自の開発プロセスを効率化できるはずです。
