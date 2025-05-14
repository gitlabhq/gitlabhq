---
stage: Package
group: Package Registry
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: パッケージレジストリのPyPIパッケージ
---

{{< details >}}

- プラン:Free、Premium、Ultimate
- 提供:GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

Python Package Index（PyPI）は、Python の公式サードパーティソフトウェアリポジトリです。GitLab PyPI パッケージレジストリを使用して、GitLabプロジェクト、グループ、および組織で Python パッケージを公開および共有します。このインテグレーションにより、コードとともに Python の依存関係を管理し、GitLab 内での Python 開発のためのシームレスなワークフローを提供できます。

パッケージレジストリは以下と連携します。

- [pip](https://pypi.org/project/pip/)
- [twine](https://pypi.org/project/twine/)

`pip` クライアントと `twine` クライアントが使用する特定の API エンドポイントのドキュメントについては、[PyPI API ドキュメント](../../../api/packages/pypi.md)を参照してください。

[PyPI パッケージをビルドする](../workflows/build_packages.md#pypi)方法について説明します。

## パッケージリクエストの転送に関するセキュリティ通知

GitLab PyPI パッケージレジストリを使用する場合、GitLab レジストリに見つからないパッケージリクエストは、自動的に pypi.org に転送されます。この動作により、`--index-url` フラグを使用している場合でも、pypi.org からパッケージがダウンロードされる可能性があります。

プライベートパッケージを使用する場合は、最大限のセキュリティを確保するために以下を実行します。

- グループ設定でパッケージ転送をオフにします。
  - インスタンス管理者は、**管理者**エリアの[**継続的インテグレーション**セクション](../../../administration/settings/continuous_integration.md#package-registry-configuration)で転送を無効にできます。
  - グループオーナーは、グループ設定の**パッケージとレジストリ**セクションで転送を無効にできます。
- パッケージのインストール時に、[`--index-url` フラグと `--no-index` フラグの両方を使用します。](#security-implications)

## GitLab パッケージレジストリで認証する

GitLab パッケージレジストリを操作する前に、認証する必要があります。

次の方法で認証できます:

- スコープが `api` に設定された[パーソナルアクセストークン](../../profile/personal_access_tokens.md)。
- スコープが `read_package_registry`、`write_package_registry`、またはその両方に設定された[デプロイトークン](../../project/deploy_tokens/_index.md)。
- [CI/CD ジョブトークン](../../../ci/jobs/ci_job_token.md)。

ここにドキュメント化されている方法以外の認証方法は使用しないでください。ドキュメント化されていない認証方法は、将来削除される可能性があります。

GitLab トークンで認証するには:

- `TWINE_USERNAME` 環境変数と `TWINE_PASSWORD` 環境変数を更新します。

次に例を示します。

{{< tabs >}}

{{< tab title="パーソナルアクセストークンを使用する場合" >}}

```yaml
run:
  image: python:latest
  variables:
    TWINE_USERNAME: <personal_access_token_name>
    TWINE_PASSWORD: <personal_access_token>
  script:
    - pip install build twine
    - python -m build
    - python -m twine upload --repository-url ${CI_API_V4_URL}/projects/${CI_PROJECT_ID}/packages/pypi dist/*
```

{{< /tab >}}

{{< tab title="デプロイトークンを使用する場合" >}}

```yaml
run:
  image: python:latest
  variables:
    TWINE_USERNAME: <deploy_token_username>
    TWINE_PASSWORD: <deploy_token>
  script:
    - pip install build twine
    - python -m build
    - python -m twine upload --repository-url ${CI_API_V4_URL}/projects/${CI_PROJECT_ID}/packages/pypi dist/*
```

{{< /tab >}}

{{< tab title="CI/CD ジョブトークンを使用する場合" >}}

```yaml
run:
  image: python:latest
  variables:
    TWINE_USERNAME: gitlab-ci-token
    TWINE_PASSWORD: $CI_JOB_TOKEN
  script:
    - pip install build twine
    - python -m build
    - python -m twine upload --repository-url ${CI_API_V4_URL}/projects/${CI_PROJECT_ID}/packages/pypi dist/*
```

{{< /tab >}}

{{< /tabs >}}

### グループの認証

グループのパッケージレジストリで認証するには:

- パッケージレジストリに対して認証しますが、プロジェクト URL の代わりにグループ URL を使用します:

```shell
https://gitlab.example.com/api/v4/groups/<group_id>/-/packages/pypi
```

## PyPI パッケージを発行する

twine を使用してパッケージを公開できます。

前提要件:

- [パッケージレジストリで認証](#authenticate-with-the-gitlab-package-registry)する必要があります。
- [バージョン文字列が有効](#use-valid-version-strings)である必要があります。
- パッケージ:
  - 5 GB 以下です。
  - `description` は 4000 文字以下です。長い `description` 文字列は切り詰められます。
  - パッケージレジストリにまだ公開されていません。同じバージョンのパッケージを公開しようとすると、`400 Bad Request` が返されます。

PyPI パッケージは、プロジェクト ID を使用して公開されます。プロジェクトがグループにある場合、プロジェクトレジストリに公開された PyPI パッケージはグループレジストリでも利用できます。詳細については、[グループからインストールする](#install-from-a-group)を参照してください。

パッケージを公開するには:

1. リポジトリソースを定義し、`~/.pypirc` ファイルを編集して、以下を追加します:

   ```ini
   [distutils]
   index-servers =
       gitlab

   [gitlab]
   repository = https://gitlab.example.com/api/v4/projects/<project_id>/packages/pypi
   ```

1. twine でパッケージをアップロードします:

   ```shell
   python3 -m twine upload --repository gitlab dist/*
   ```

   パッケージが正常に公開されると、次のようなメッセージが表示されます:

   ```plaintext
   Uploading distributions to https://gitlab.example.com/api/v4/projects/<project_id>/packages/pypi
   Uploading mypypipackage-0.0.1-py3-none-any.whl
   100%|███████████████████████████████████████████████████████████████████████████████████████████| 4.58k/4.58k [00:00<00:00, 10.9kB/s]
   Uploading mypypipackage-0.0.1.tar.gz
   100%|███████████████████████████████████████████████████████████████████████████████████████████| 4.24k/4.24k [00:00<00:00, 11.0kB/s]
   ```

パッケージはパッケージレジストリに公開され、**パッケージとレジストリ**ページに表示されます。

### インライン認証で公開する

`.pypirc` ファイルを使用してリポジトリソースを定義しなかった場合は、インライン認証でリポジトリに公開できます:

```shell
TWINE_PASSWORD=<personal_access_token, deploy_token, or $CI_JOB_TOKEN> \
TWINE_USERNAME=<username, deploy_token_username, or gitlab-ci-token> \
python3 -m twine upload --repository-url https://gitlab.example.com/api/v4/projects/<project_id>/packages/pypi dist/*
```

### 同じ名前とバージョンのパッケージの公開

同じ名前とバージョンのパッケージがすでに存在する場合、パッケージを公開できません。まず[既存のパッケージを削除](../package_registry/reduce_package_registry_storage.md#delete-a-package)する必要があります。同じパッケージを複数回公開しようとすると、`400 Bad Request` エラーが発生します。

## PyPI パッケージをインストールする

デフォルトでは、PyPI パッケージが GitLab パッケージレジストリに見つからない場合、リクエストは [pypi.org](https://pypi.org/) に転送されます。この動作:

- すべての GitLab インスタンスでデフォルトで有効になっています
- グループの*パッケージとレジストリ*設定でConfigureできます
- `--index-url` フラグを使用している場合でも適用されます

管理者は、[継続的インテグレーション設定](../../../administration/settings/continuous_integration.md#package-registry-configuration)でこの動作をグローバルに無効にできます。グループオーナーは、グループ設定の**パッケージとレジストリ**セクションで、特定のグループに対してこの動作を無効にできます。

{{< alert type="note" >}}

`--index-url` オプションを使用する場合は、デフォルトポートの場合はポートを指定しないでください。`http` URL はデフォルトで 80 になり、`https` URL はデフォルトで 443 になります。

{{< /alert >}}

### プロジェクトからインストール

パッケージの最新バージョンをインストールするには、次のコマンドを使用します:

```shell
pip install --index-url https://<personal_access_token_name>:<personal_access_token>@gitlab.example.com/api/v4/projects/<project_id>/packages/pypi/simple --no-deps <package_name>
```

- `<package_name>` はパッケージ名です。
- `<personal_access_token_name>` は、`read_api` スコープを持つパーソナルアクセストークン名です。
- `<personal_access_token>` は、`read_api` スコープを持つパーソナルアクセストークンです。
- `<project_id>` は、プロジェクトの[URL エンコード](../../../api/rest/_index.md#namespaced-paths)されたパス（たとえば、`group%2Fproject`）またはプロジェクトの ID（たとえば `42`）です。

これらのコマンドでは、`--index-url` の代わりに `--extra-index-url` を使用できます。ガイドに従っていて、`MyPyPiPackage` パッケージをインストールする場合は、次を実行します:

```shell
pip install mypypipackage --no-deps --index-url https://<personal_access_token_name>:<personal_access_token>@gitlab.example.com/api/v4/projects/<project_id>/packages/pypi/simple
```

このメッセージは、パッケージが正常にインストールされたことを示しています:

```plaintext
Looking in indexes: https://<personal_access_token_name>:****@gitlab.example.com/api/v4/projects/<project_id>/packages/pypi/simple
Collecting mypypipackage
  Downloading https://gitlab.example.com/api/v4/projects/<project_id>/packages/pypi/files/d53334205552a355fee8ca35a164512ef7334f33d309e60240d57073ee4386e6/mypypipackage-0.0.1-py3-none-any.whl (1.6 kB)
Installing collected packages: mypypipackage
Successfully installed mypypipackage-0.0.1
```

### グループからインストール

グループからパッケージの最新バージョンをインストールするには、次のコマンドを使用します:

```shell
pip install --index-url https://<personal_access_token_name>:<personal_access_token>@gitlab.example.com/api/v4/groups/<group_id>/-/packages/pypi/simple --no-deps <package_name>
```

このコマンドでは:

- `<package_name>` はパッケージ名です。
- `<personal_access_token_name>` は、`read_api` スコープを持つパーソナルアクセストークン名です。
- `<personal_access_token>` は、`read_api` スコープを持つパーソナルアクセストークンです。
- `<group_id>` はグループ ID です。

これらのコマンドでは、`--index-url` の代わりに `--extra-index-url` を使用できます。ガイドに従っていて、`MyPyPiPackage` パッケージをインストールする場合は、次を実行します:

```shell
pip install mypypipackage --no-deps --index-url https://<personal_access_token_name>:<personal_access_token>@gitlab.example.com/api/v4/groups/<group_id>/-/packages/pypi/simple
```

### パッケージ名

GitLab は、[Python 正規化名 (PEP-503)](https://www.python.org/dev/peps/pep-0503/#normalized-names)を使用するパッケージを探します。文字 `-`、`_`、および `.` はすべて同じように扱われ、繰り返される文字は削除されます。

`my.package` の `pip install` リクエストは、`my-package`、`my_package`、および `my....package` など、3 つの文字のいずれかに一致するパッケージを探します。

### セキュリティに関する注意点

PyPI パッケージのインストール時に `--extra-index-url` と `--index-url` を使用することによるセキュリティへの影響は重大であり、詳細に理解する価値があります。

- `--index-url`:このオプションは、デフォルトの PyPI インデックス URL を指定された URL に置き換えます。デフォルトでオンになっている GitLab パッケージ転送設定では、パッケージレジストリに見つからないパッケージが PyPI からダウンロードされる可能性があります。パッケージが GitLab からのみインストールされるようにするには、次のいずれかを実行します:
  - グループ設定でパッケージ転送を無効にする
  - `--index-url` フラグと `--no-index` フラグを一緒に使用する
- `--extra-index-url`:このオプションは、デフォルトの PyPI インデックスに加えて、検索する追加のインデックスを追加します。デフォルトの PyPI と追加のインデックスの両方でパッケージがチェックされるため、セキュリティが低く、依存関係に関する混乱攻撃を受けやすくなります。

プライベートパッケージを使用する場合は、次のベストプラクティスに留意してください:

- グループのパッケージ転送設定を確認します。
- プライベートパッケージをインストールするときは、`--no-index` フラグと `--index-url` フラグを一緒に使用します。
- `pip debug` を使用してパッケージソースを定期的に監査します。

## `requirements.txt` の使用

pip でパブリックレジストリにアクセスする場合は、レジストリの URL とともに `--extra-index-url` パラメーターを `requirements.txt` ファイルに追加します。

```plaintext
--extra-index-url https://gitlab.example.com/api/v4/projects/<project_id>/packages/pypi/simple
package-name==1.0.0
```

これがプライベートレジストリである場合は、いくつかの方法で認証できます。次に例を示します。

- `requirements.txt` ファイルの使用:

  ```plaintext
  --extra-index-url https://__token__:<personal_token>@gitlab.example.com/api/v4/projects/<project_id>/packages/pypi/simple
  package-name==1.0.0
  ```

- `~/.netrc` ファイルの使用:

  ```plaintext
  machine gitlab.example.com
  login __token__
  password <personal_token>
  ```

## PyPI パッケージのバージョニング

PyPI パッケージを効果的に管理するには、適切なバージョニングが重要です。パッケージが正しくバージョニングされるように、これらのベストプラクティスに従ってください。

### セマンティックバージョニング（SemVer）を使用する

パッケージにセマンティックバージョニングを採用します。バージョン番号は `MAJOR.MINOR.PATCH` 形式にする必要があります:

- 互換性のない API 変更の場合は、`MAJOR` バージョンをインクリメントします。
- 下位互換性のある新機能の場合は、`MINOR` バージョンをインクリメントします。
- 下位互換性のあるバグ修正の場合は、`PATCH` バージョンをインクリメントします。

次に例を示します。1.0.0、1.1.0、1.1.1。

新しいプロジェクトの場合は、バージョン 0.1.0 から開始します。これは、API がまだ安定していない初期開発段階を示しています。

### 有効なバージョン文字列を使用する

バージョン文字列が PyPI 規格に従って有効であることを確認してください。GitLab は、特定の正規表現を使用してバージョン文字列を検証します:

```ruby
\A(?:
    v?
    (?:([0-9]+)!)?                                                 (?# epoch)
    ([0-9]+(?:\.[0-9]+)*)                                          (?# release segment)
    ([-_\.]?((a|b|c|rc|alpha|beta|pre|preview))[-_\.]?([0-9]+)?)?  (?# pre-release)
    ((?:-([0-9]+))|(?:[-_\.]?(post|rev|r)[-_\.]?([0-9]+)?))?       (?# post release)
    ([-_\.]?(dev)[-_\.]?([0-9]+)?)?                                (?# dev release)
    (?:\+([a-z0-9]+(?:[-_\.][a-z0-9]+)*))?                         (?# local version)
)\z}xi
```

この[正規表現エディタ](https://rubular.com/r/FKM6d07ouoDaFV)を使用して、正規表現を実験したり、バージョン文字列を試したりできます。

正規表現の詳細については、[Python ドキュメント](https://www.python.org/dev/peps/pep-0440/#appendix-b-parsing-version-strings-with-regular-expressions)を参照してください。

## サポートされている CLI コマンド

GitLab PyPI リポジトリは、次の CLI コマンドをサポートしています:

- `twine upload`:パッケージをレジストリにアップロードします。
- `pip install`:レジストリから PyPI パッケージをインストールします。

## トラブルシューティング

パフォーマンスを向上させるため、pip コマンドはパッケージに関連するファイルをキャッシュします。Pip はデータを自動的に削除しません。新しいパッケージがインストールされるにつれて、キャッシュは増加します。イシューが発生した場合は、次のコマンドでキャッシュをクリアします:

```shell
pip cache purge
```

### 複数の `index-url` パラメーターまたは `extra-index-url` パラメーター

複数の `index-url` パラメーターと `extra-index-url` パラメーターを定義できます。

異なる認証トークンを使用して同じドメイン名（`gitlab.example.com` など）を複数回使用すると、`pip` がパッケージを見つけられない場合があります。この問題は、コマンド実行中に `pip` が[トークンをregisterおよび保存](https://github.com/pypa/pip/pull/10904#issuecomment-1126690115)する方法が原因です。

このイシューを回避するには、`index-url` 値と `extra-index-url` 値をターゲットとするすべてのプロジェクトまたはグループの共通の親グループから、スコープ `read_package_registry` を持つ[グループデプロイトークン](../../project/deploy_tokens/_index.md)を使用できます。

### 予期しないパッケージソース

GitLab レジストリのみを使用する予定だった場合に、パッケージが PyPI からインストールされている場合:

- グループのパッケージ転送設定を確認します。
- PyPI フォールバックを防ぐために、`--no-index` フラグと `--index-url` フラグを組み合わせて使用します。
- `pip debug` を使用してパッケージソースを定期的に監査します。
