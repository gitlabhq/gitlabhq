---
stage: Package
group: Package Registry
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: 'チュートリアル: GitLabパッケージレジストリでソフトウェア部品表を生成する'
---

このチュートリアルでは、CI/CDパイプラインでCycloneDX形式のソフトウェア部品表（SBOM）を生成する方法を説明します。構築するパイプラインは、グループ内の複数のプロジェクトにわたってパッケージを収集し、関連プロジェクト内の依存関係の包括的なビューを提供します。

このチュートリアルを完了するには、仮想Python環境を作成しますが、同じアプローチを他のサポートされているパッケージタイプにも適用できます。

## ソフトウェア部品表とは何ですか？ {#what-is-a-software-bill-of-materials}

SBOMは、ソフトウェア製品を構成するすべてのソフトウェアコンポーネントの機械可読なインベントリです。SBOMには、次のものが含まれる場合があります:

- 直接および間接的な依存関係
- オープンソースのコンポーネントとライセンス
- パッケージのバージョンとそのorigin

ソフトウェア製品の使用に関心のある組織は、SBOMを採用する前に、製品がどれほど安全であるかを判断する必要がある場合があります。

GitLabパッケージレジストリに慣れている場合は、SBOMと[依存関係リスト](../../application_security/dependency_list/_index.md)の違いは何だろうと思われるかもしれません。次の表は、主な違いをまとめたものです:

| 相違点   | 依存関係リスト                                               | SBOM |
|---------------|---------------------------------------------------------------|------|
| スコープ     | 個々のプロジェクトまたはグループの依存関係を表示します。         | グループ全体で公開されているすべてのパッケージのインベントリを作成します。 |
| 方向 | プロジェクトが何に依存しているかを追跡します（受信依存関係）。  | グループが公開しているものを追跡します（送信パッケージ）。 |
| カバレッジ  | `package.json`や`pom.xml`などのパッケージマニフェストに基づいています。 | GitLabパッケージレジストリで実際に公開されたアーティファクトを対象としています。 |

## CycloneDXとは何ですか？ {#what-is-cyclonedx}

CycloneDXは、SBOMを作成するための軽量で標準化された形式です。CycloneDXは、組織を支援する明確に定義されたスキーマを提供します:

- ソフトウェアコンポーネントとその関係をドキュメント化します。
- ソフトウェアサプライチェーン全体の脆弱性を追跡します。
- オープンソースの依存関係について、ライセンスコンプライアンスを検証します。
- 一貫性のある機械可読なSBOM形式を確立します。

CycloneDXは、JSON、XML、Protocol Buffersなどの複数の出力形式をサポートしているため、さまざまなインテグレーションのニーズに対応できます。この仕様は、基本的なコンポーネントの識別からソフトウェアの出所に関する詳細なメタデータまで、すべてを網羅しつつ、効率的になるように設計されています。

## はじめる前 {#before-you-begin}

このチュートリアルを完了するには、以下が必要です:

- 少なくともメンテナーロールを持つグループ。
- GitLab CI/CDへのアクセス。
- GitLab Self-Managedインスタンスを使用している場合は、構成済みの[GitLab Runner](../../../ci/runners/_index.md#runner-categories)。GitLab.comを使用している場合は、この手順を省略できます。
- オプション。パッケージレジストリへのリクエストを認証するための[グループデプロイトークン](../../project/deploy_tokens/_index.md)。

## ステップ {#steps}

このチュートリアルでは、完了するために2組のステップが必要です:

- CycloneDX形式でSBOMを生成するCI/CDパイプラインの設定
- 生成されたSBOMとパッケージ統計ファイルへのアクセスと操作

これから行うことの概要を以下に示します:

1. [ベースパイプラインの設定を追加](#add-the-base-pipeline-configuration)。
1. [`prepare`ステージを設定](#configure-the-prepare-stage)。
1. [`collect`ステージを設定](#configure-the-collect-stage)。
1. [`aggregate`ステージを設定](#configure-the-aggregate-stage)。
1. [`publish`ステージを設定](#configure-the-publish-stage)。
1. [生成されたSBOMおよび統計ファイルにアクセス](#access-the-generated-files)。

{{< alert type="note" >}}

このソリューションを実装する前に、次の点に注意してください:

- パッケージの依存関係は解決されません（直接パッケージのみがリストされます）。
- パッケージのバージョンが含まれていますが、脆弱性については分析されていません。

{{< /alert >}}

### ベースパイプラインの設定を追加 {#add-the-base-pipeline-configuration}

まず、パイプライン全体で使用される変数とステージングを定義するベースイメージをセットアップします。

次のセクションでは、各ステージングの設定を追加して、パイプラインを構築します。

プロジェクト内:

1. `.gitlab-ci.yml`ファイルを作成します。
1. ファイルに、次のベース設定を追加します:

   ```yaml
   # Base image for all jobs
   image: alpine:latest

   variables:
     SBOM_OUTPUT_DIR: "sbom-output"
     SBOM_FORMAT: "cyclonedx"
     OUTPUT_TYPE: "json"
     GROUP_PATH: ${CI_PROJECT_NAMESPACE}
     AUTH_HEADER: "${GROUP_DEPLOY_TOKEN:+Deploy-Token: $GROUP_DEPLOY_TOKEN}"

   before_script:
     - apk add --no-cache curl jq ca-certificates

   stages:
     - prepare
     - collect
     - aggregate
     - publish
   ```

この設定では:

- フットプリントが小さく、ジョブの起動が速いため、alpine Linuxを使用
- 認証のためのグループデプロイトークンをサポート
- 安全なHTTPS接続を確保するために、APIリクエスト用に`curl`、JSON処理用に`jq`、`ca-certificates`をインストール
- すべての出力を`sbom-output`ディレクトリに保存
- CycloneDX JSON形式でSBOMを生成

### `prepare`ステージを設定 {#configure-the-prepare-stage}

`prepare`ステージは、Python環境をセットアップし、必要な依存関係をインストールします。

`.gitlab-ci.yml`ファイルに、次の設定を追加します:

```yaml
# Set up Python virtual environment and install required packages
prepare_environment:
  stage: prepare
  script: |
    mkdir -p ${SBOM_OUTPUT_DIR}
    apk add --no-cache python3 py3-pip py3-virtualenv
    python3 -m venv venv
    source venv/bin/activate
    pip3 install cyclonedx-bom
  artifacts:
    paths:
      - ${SBOM_OUTPUT_DIR}/
      - venv/
    expire_in: 1 week
```

このステージング:

- ブロックするためのPython仮想環境を作成
- SBOM生成用のCycloneDXライブラリをインストール
- アーティファクトの出力ディレクトリを作成
- 後続のステージングのために仮想環境を永続化
- ストレージを管理するために、アーティファクトに1週間の有効期限を設定

### `collect`ステージを設定 {#configure-the-collect-stage}

`collect`ステージは、グループのパッケージレジストリからパッケージ情報を収集します。

`.gitlab-ci.yml`ファイルに、次の設定を追加します:

```yaml
# Collect package information and versions from GitLab registry
collect_group_packages:
  stage: collect
  script: |
    echo "[]" > "${SBOM_OUTPUT_DIR}/packages.json"

    GROUP_PATH_ENCODED=$(echo "${GROUP_PATH}" | sed 's|/|%2F|g')
    PACKAGES_URL="${CI_API_V4_URL}/groups/${GROUP_PATH_ENCODED}/packages"

    # Optional exclusion list - you can add package types you want to exclude
    # EXCLUDE_TYPES="terraform"

    page=1
    while true; do
      # Fetch all packages without specifying type, with pagination
      response=$(curl --silent --header "${AUTH_HEADER:-"JOB-TOKEN: $CI_JOB_TOKEN"}" \
                    "${PACKAGES_URL}?per_page=100&page=${page}")

      if ! echo "$response" | jq 'type == "array"' > /dev/null 2>&1; then
        echo "Error in API response for page $page"
        break
      fi

      count=$(echo "$response" | jq '. | length')
      if [ "$count" -eq 0 ]; then
        break
      fi

      # Filter packages if EXCLUDE_TYPES is set
      if [ -n "${EXCLUDE_TYPES:-}" ]; then
        filtered_response=$(echo "$response" | jq --arg types "$EXCLUDE_TYPES" '[.[] | select(.package_type | inside($types | split(" ")) | not)]')
        response="$filtered_response"
        count=$(echo "$response" | jq '. | length')
      fi

      # Merge this page of results with existing data
      jq -s '.[0] + .[1]' "${SBOM_OUTPUT_DIR}/packages.json" <(echo "$response") > "${SBOM_OUTPUT_DIR}/packages.tmp.json"
      mv "${SBOM_OUTPUT_DIR}/packages.tmp.json" "${SBOM_OUTPUT_DIR}/packages.json"

      # Move to next page if we got a full page of results
      if [ "$count" -lt 100 ]; then
        break
      fi

      page=$((page + 1))
    done
  artifacts:
    paths:
      - ${SBOM_OUTPUT_DIR}/
    expire_in: 1 week
  dependencies:
    - prepare_environment
```

このステージング:

- すべてのパッケージタイプを一度にフェッチするために、単一のAPIコールを実行します（タイプごとに個別のコールを実行する代わりに）。
- 不要なパッケージタイプを除外するためのオプションの除外リストをサポート
- 多数のパッケージを持つグループを処理するために、ページネーションを実装します（1ページネーションあたり100個）。
- サブグループを正しく処理するために、グループパスをURLエンコードします
- 無効な応答をスキップすることにより、APIエラーを正常に処理します

### `aggregate`ステージを設定 {#configure-the-aggregate-stage}

`aggregate`ステージは、収集されたデータを処理し、SBOMを生成します。

`.gitlab-ci.yml`ファイルに、次の設定を追加します:

```yaml
# Generate SBOM by aggregating package data
aggregate_sboms:
  stage: aggregate
  before_script:
    - apk add --no-cache python3 py3-pip py3-virtualenv
    - python3 -m venv venv
    - source venv/bin/activate
    - pip3 install --no-cache-dir cyclonedx-bom
  script: |
    cat > process_sbom.py << 'EOL'
    import json
    import os
    from datetime import datetime

    def analyze_version_history(packages_file):
        """Process version information by aggregating packages with same name and type"""
        version_history = {}
        package_versions = {}  # Dict to group packages by name and type

        try:
            with open(packages_file, 'r') as f:
                packages = json.load(f)
                if not isinstance(packages, list):
                    return version_history

                # First, group packages by name and type
                for package in packages:
                    key = f"{package.get('name')}:{package.get('package_type')}"
                    if key not in package_versions:
                        package_versions[key] = []

                    package_versions[key].append({
                        'id': package.get('id'),
                        'version': package.get('version', 'unknown'),
                        'created_at': package.get('created_at')
                    })

                # Then process each group to create version history
                for package_key, versions in package_versions.items():
                    # Sort versions by creation date, newest first
                    versions.sort(key=lambda x: x.get('created_at', ''), reverse=True)

                    # Use the first package's ID as the key (newest version)
                    if versions:
                        package_id = str(versions[0]['id'])
                        version_history[package_id] = {
                            'versions': [v['version'] for v in versions],
                            'latest_version': versions[0]['version'] if versions else None,
                            'version_count': len(versions),
                            'first_published': min((v.get('created_at') for v in versions if v.get('created_at')), default=None),
                            'last_updated': max((v.get('created_at') for v in versions if v.get('created_at')), default=None)
                        }
        except Exception as e:
            print(f"Error processing version history: {e}")
        return version_history

    def merge_package_data(package_file):
        """Combine package data and generate component list"""
        merged_components = {}
        package_stats = {
            'total_packages': 0,
            'package_types': {}
        }

        try:
            with open(package_file, 'r') as f:
                packages = json.load(f)
                if not isinstance(packages, list):
                    return [], package_stats

                for package in packages:
                    package_stats['total_packages'] += 1
                    pkg_type = package.get('package_type', 'unknown')
                    package_stats['package_types'][pkg_type] = package_stats['package_types'].get(pkg_type, 0) + 1

                    component = {
                        'type': 'library',
                        'name': package['name'],
                        'version': package.get('version', 'unknown'),
                        'purl': f"pkg:gitlab/{package['name']}@{package.get('version', 'unknown')}",
                        'package_type': pkg_type,
                        'properties': [{
                            'name': 'registry_url',
                            'value': package.get('_links', {}).get('web_path', '')
                        }]
                    }

                    key = f"{component['name']}:{component['version']}"
                    if key not in merged_components:
                        merged_components[key] = component
        except Exception as e:
            print(f"Error merging package data: {e}")
            return [], package_stats

        return list(merged_components.values()), package_stats

    # Main processing
    version_history = analyze_version_history(f"{os.environ['SBOM_OUTPUT_DIR']}/packages.json")
    components, stats = merge_package_data(f"{os.environ['SBOM_OUTPUT_DIR']}/packages.json")
    stats['version_history'] = version_history

    # Create final SBOM document
    sbom = {
        "bomFormat": os.environ['SBOM_FORMAT'],
        "specVersion": "1.4",
        "version": 1,
        "metadata": {
            "timestamp": datetime.utcnow().isoformat(),
            "tools": [{
                "vendor": "GitLab",
                "name": "Package Registry SBOM Generator",
                "version": "1.0.0"
            }],
            "properties": [{
                "name": "package_stats",
                "value": json.dumps(stats)
            }]
        },
        "components": components
    }

    # Write results to files
    with open(f"{os.environ['SBOM_OUTPUT_DIR']}/merged_sbom.{os.environ['OUTPUT_TYPE']}", 'w') as f:
        json.dump(sbom, f, indent=2)

    with open(f"{os.environ['SBOM_OUTPUT_DIR']}/package_stats.json", 'w') as f:
        json.dump(stats, f, indent=2)
    EOL

    python3 process_sbom.py
  artifacts:
    paths:
      - ${SBOM_OUTPUT_DIR}/
    expire_in: 1 week
  dependencies:
    - collect_group_packages
```

このステージング:

- `packages.json`ファイルと直接連携する最適化されたバージョン履歴分析を使用
- 同じパッケージの異なるバージョンを識別するために、名前とタイプでパッケージをグループ化
- JSON形式でCycloneDXじゅんきょSBOMを作成
- 次のパッケージ統計を計算します:
  - タイプ別のパッケージの合計数
  - 各パッケージのバージョン履歴
  - 最初に公開された日付と最後に更新された日付
- 各コンポーネントのパッケージURL（`purl`）を生成
- 適切な例外処理により、欠落または無効なデータを正常に処理します
- SBOMと個別の統計ファイルの両方を作成

### `publish`ステージを設定 {#configure-the-publish-stage}

`publish`ステージは、生成されたSBOMと統計ファイルをGitLabにアップロードします。

`.gitlab-ci.yml`ファイルに、次の設定を追加します:

```yaml
# Publish SBOM files to GitLab package registry
publish_sbom:
  stage: publish
  script: |
    STATS=$(cat "${SBOM_OUTPUT_DIR}/package_stats.json")

    # Upload generated files
    curl --header "${AUTH_HEADER:-"JOB-TOKEN: $CI_JOB_TOKEN"}" \
         --upload-file "${SBOM_OUTPUT_DIR}/merged_sbom.${OUTPUT_TYPE}" \
         "${CI_API_V4_URL}/projects/${CI_PROJECT_ID}/packages/generic/sbom/${CI_COMMIT_SHA}/merged_sbom.${OUTPUT_TYPE}"

    curl --header "${AUTH_HEADER:-"JOB-TOKEN: $CI_JOB_TOKEN"}" \
         --upload-file "${SBOM_OUTPUT_DIR}/package_stats.json" \
         "${CI_API_V4_URL}/projects/${CI_PROJECT_ID}/packages/generic/sbom/${CI_COMMIT_SHA}/package_stats.json"

    # Add package description
    curl --header "${AUTH_HEADER:-"JOB-TOKEN: $CI_JOB_TOKEN"}" \
         --header "Content-Type: application/json" \
         --request PUT \
         --data @- \
         "${CI_API_V4_URL}/projects/${CI_PROJECT_ID}/packages/generic/sbom/${CI_COMMIT_SHA}" << EOF
    {
      "description": "Group Package Registry SBOM generated on $(date -u)\nStats: ${STATS}"
    }
    EOF
  dependencies:
    - aggregate_sboms
```

このステージング:

- SBOMと統計ファイルをプロジェクトのパッケージレジストリに公開します
- ストレージに一般的なパッケージタイプを使用します
- 追跡可能性のために、コミットSHAをパッケージのバージョンとして使用
- 生成タイムスタンプと統計をパッケージの説明に追加

## 生成されたファイルへのアクセス {#access-the-generated-files}

パイプラインが完了すると、次のファイルが生成されます:

- `merged_sbom.json`: CycloneDX形式の完全なSBOM
- `package_stats.json`: パッケージに関する統計

生成されたファイルにアクセスするには:

1. プロジェクトで、**デプロイ** > **パッケージレジストリ**を選択します。
1. `sbom`という名前のパッケージを見つけます。
1. SBOMと統計ファイルをダウンロードします。

### SBOMファイルの使用 {#using-the-sbom-file}

SBOMファイルは[CycloneDX 1.4 JSON仕様](https://cyclonedx.org/docs/1.4/json/)に従い、グループのパッケージレジストリで公開されているパッケージ、パッケージのバージョン、およびアーティファクトに関する詳細を提供します。

コンプライアンスおよび監査目的で、SBOMファイルを使用することもできます。次に例を示します:

- 公開されたパッケージのレポートを生成する
- グループのパッケージレジストリの内容をドキュメント化する
- 経時的な公開アクティビティーを追跡する

CycloneDXファイルを操作する場合は、次のツールの使用を検討してください:

- [OWASP Dependency-Track](https://dependencytrack.org/)
- [CycloneDX CLI](https://github.com/CycloneDX/cyclonedx-cli)
- [OWASP CycloneDX Sunshine](https://cyclonedx.github.io/Sunshine/)
- [SBOM分析ツール](https://cyclonedx.org/tool-center/)

### 統計ファイルの使用 {#using-the-statistics-file}

統計ファイルは、パッケージレジストリの分析とアクティビティー追跡を提供します。

パッケージレジストリを分析するには、たとえば、次のことができます:

- タイプ別に公開されたパッケージの合計数を表示します。
- 各パッケージのバージョンの数を表示します。
- 最初に公開された日付と最後に更新された日付を追跡します。

パッケージレジストリのアクティビティーを追跡するには、次のことができます:

- パッケージの公開パターンを監視します。
- 最も頻繁に更新されるパッケージを特定します。
- 経時的なパッケージレジストリの増加を追跡します。

`jq`のようなCLIツールを統計ファイルとともに使用して、読みやすいJSON形式で分析またはアクティビティー情報を生成できます。

次のコードブロックに、一般的な分析またはレポートの目的で統計ファイルに対して実行できる`jq`コマンドのいくつかの例を示します:

```shell
# Get total package count in registry
jq '.total_packages' package_stats.json

# List package types and their counts
jq '.package_types' package_stats.json

# Find packages with most versions published
jq '.version_history | to_entries | sort_by(.value.version_count) | reverse | .[0:5]' package_stats.json
```

## パイプラインスケジュール {#pipeline-scheduling}

パッケージレジストリを頻繁に更新する場合は、それに応じてSBOMを更新する必要があります。パイプラインスケジュールを設定して、公開アクティビティーに基づいて更新されたSBOMを生成できます。

次の推奨事項を検討してください:

- 毎日の更新: パッケージを頻繁に公開する場合、または最新のレポートが必要な場合に推奨されます
- 毎週の更新: 適度なパッケージ公開アクティビティーを行うほとんどのチームに適しています
- 毎月の更新: パッケージの更新が少ないグループには十分です

パイプラインをスケジュールするには:

1. プロジェクトで、**ビルド** > **パイプラインスケジュール**に移動します。
1. **新しいパイプラインスケジュールを作成**を選択し、フォームに入力します:
   - **Cronのタイムゾーン**ドロップダウンリストで、タイムゾーンを選択します。
   - **間隔のパターン**を選択するか、**カスタム**パターンを[Cron構文](../../../ci/pipelines/schedules.md)を使用して追加します。
   - パイプラインのブランチまたはタグを選択します。
   - **変数**で、スケジュールに任意の数のCI/CD変数を入力します。
1. **パイプラインスケジュールを作成**を選択します。

## トラブルシューティング {#troubleshooting}

このチュートリアルを完了する際に、次のイシューが発生する可能性があります。

### 認証エラー {#authentication-errors}

認証エラーが発生した場合:

- グループデプロイトークンの権限を確認します。
- トークンに`read_package_registry`と`write_package_registry`の両方のスコープがあることを確認してください。
- トークンの有効期限が切れていないことを確認します。

### パッケージタイプが見つからない {#missing-package-types}

パッケージタイプが見つからない場合:

- すべてのパッケージタイプに[デプロイトークンがアクセスできる](../../project/deploy_tokens/_index.md#pull-packages-from-a-package-registry)ことを確認します。
- パッケージタイプがグループ設定で有効になっているかどうかを確認します。

### `aggregate`ステージでのメモリイシュー {#memory-issues-in-the-aggregate-stage}

メモリイシューが発生した場合:

- より多くのメモリを持つRunnerを使用します。
- パッケージタイプをフィルタリングして、一度に処理するパッケージの数を減らします。

### リソースの推奨事項 {#resource-recommendations}

最適なパフォーマンスを得るには:

- 少なくとも2GBのRAMを備えたRunnerを使用します。
- 1,000個のパッケージあたり5〜10分を許可します。
- 多数のパッケージを持つグループのジョブタイムアウトを増やします。

### ヘルプの入手 {#getting-help}

その他のイシューが発生した場合:

- 特定のAPIのエラーメッセージについてジョブログを確認します。
- `curl`コマンドを直接使用して、APIアクセスを確認します。
- 最初にパッケージタイプの小さいサブセットでテストします。
