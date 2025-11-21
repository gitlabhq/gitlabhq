---
stage: Security Risk Management
group: Security Insights
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: 依存関係リスト
description: 脆弱性、ライセンス、フィルタリング、エクスポート
---

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- 依存関係リストが、`group_level_dependencies`という名前の[フラグ](../../../administration/feature_flags/_index.md) [で導入](https://gitlab.com/groups/gitlab-org/-/epics/8090)されました (GitLab 16.2内)。デフォルトでは無効になっています。
- グループの依存関係リストは、GitLab 16.4 [のGitLab.comおよびGitLab Self-Managedで有効](https://gitlab.com/gitlab-org/gitlab/-/issues/411257)になりました。
- グループの依存関係リストは、GitLab 16.5で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/132015)されています。機能フラグ`group_level_dependencies`は削除されました。

{{< /history >}}

依存関係リストを使用して、プロジェクトまたはグループの依存関係と、既知の脆弱性を含む、それらの依存関係に関する主要な詳細を確認します。このリストは、既存のスキャン結果と新しいスキャン結果を含む、プロジェクト内の依存関係のコレクションです。この情報は、ソフトウェア部品表（SBOM）またはBOMと呼ばれることがあります。

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i>概要については、[Project依存 - Advanced Security Testing](https://www.youtube.com/watch?v=ckqkn9Tnbw4)を参照してください。

## 依存関係リストを設定する {#set-up-the-dependency-list}

プロジェクトの依存関係をリストするには、プロジェクトのデフォルトブランチで[dependency scanning](../dependency_scanning/_index.md)または[container scanning](../container_scanning/_index.md)を実行します。

依存関係リストには、最新のデフォルトブランチパイプラインからアップロードされた、すべての[CycloneDX reports](../../../ci/yaml/artifacts_reports.md#artifactsreportscyclonedx)の依存関係も表示されます。CycloneDXレポートは、[CycloneDX specification](https://github.com/CycloneDX/specification)バージョン`1.4`、`1.5`、または`1.6`に準拠している必要があります。[CycloneDX Web Tool](https://cyclonedx.github.io/cyclonedx-web-tool/validate)を使用して、CycloneDXレポートを検証できます。

{{< alert type="note" >}}

依存関係リストを入力された状態にするためにこれは必須ではありませんが、一部のプロパティを提供し、一部のセキュリティ機能を有効にするには、SBOMドキュメントにGitLab CycloneDXプロパティタクソノミーを含めて準拠させる必要があります。

{{< /alert >}}

## プロジェクトの依存関係を表示する {#view-project-dependencies}

{{< history >}}

- GitLab 17.2では、機能フラグ`skip_sbom_occurrences_update_on_pipeline_id_change`が有効になっている場合、`location`フィールドは依存関係が最後に検出されたコミットにリンクされなくなりました。フラグはデフォルトで無効になっています。
- GitLab 17.3では、`location`フィールドは常に依存関係が最初に検出されたコミットにリンクされています。機能フラグ`skip_sbom_occurrences_update_on_pipeline_id_change`は削除されました。
- GitLab 17.11 [で導入](https://gitlab.com/gitlab-org/gitlab/-/issues/519965)された、`dependency_paths`という名前の[フラグ](../../../administration/feature_flags/_index.md)を使用した、依存関係パスオプションを表示します。デフォルトでは無効になっています。
- GitLab 18.2で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/197224)されている依存関係パスオプションを表示します。機能フラグ`dependency_paths`はデフォルトで有効になっています。

{{< /history >}}

{{< alert type="flag" >}}

この機能の利用可否は、機能フラグによって制御されます。詳細については、履歴を参照してください。

{{< /alert >}}

プロジェクトまたはグループ内のすべてのプロジェクトの依存関係を表示するには:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトまたはグループを見つけます。
1. 左側のサイドバーで、**セキュリティ** > **依存関係リスト**を選択します。
1. オプション。推移的依存関係がある場合は、すべての依存関係パスを表示することもできます:
   - プロジェクトの場合は、**ロケーション**列で**依存関係パスを表示**を選択します。
   - グループの場合は、**ロケーション**列でロケーションを選択し、**依存関係パスを表示**を選択します。

各依存関係の詳細は、脆弱性の重大度が高い順にリスト表示されます（存在する場合）。代わりに、リストをコンポーネント名、パッケージャー、またはライセンスでソートできます。

| フィールド                       | 説明 |
|-----------------------------|-------------|
| コンポーネント                   | 依存関係の名前とバージョン。 |
| パッケージャー                    | 依存関係のインストールに使用されるパッケージマネージャー。サポートされていないパッケージマネージャーの場合は、「不明」と表示されます。 |
| 場所                    | システムの依存関係の場合、このフィールドにはスキャンされたイメージがリストされます。アプリケーションの依存関係の場合、このフィールドには、依存関係を宣言したプロジェクト内のパッケージャー固有のロックファイルへのリンクが表示されます。また、直接の[dependents](#dependency-paths)（存在する場合）も表示されます。推移的依存関係がある場合は、**依存関係パスを表示**を選択すると、すべての依存関係のフルパスが表示されます。推移的依存関係は、祖先として直接の依存関係を持つ間接的な依存関係です。 |
| ライセンス (プロジェクトのみ) | 依存関係のソフトウェアライセンスへのリンク。依存関係で検出された脆弱性の数を示す警告バッジ。 |
| プロジェクト (グループのみ)  | 依存関係のあるプロジェクトへのリンク。複数のプロジェクトに同じ依存関係がある場合、これらのプロジェクトの合計数が表示されます。この依存関係を持つプロジェクトに移動するには、**プロジェクト**番号を選択し、その名前を検索して選択します。 |

## フィルター依存関係リスト {#filter-dependency-list}

{{< history >}}

- `group_level_dependencies_filtering`という名前の[フラグ](../../../administration/feature_flags/_index.md)を使用して、GitLab 16.7でグループの依存関係フィルターが[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/422356)されました。デフォルトでは無効になっています。
- GitLab 16.10でグループの依存関係フィルターが[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/422356)されました。機能フラグ`group_level_dependencies_filtering`は削除されました。
- [`project_component_filter`](../../../administration/feature_flags/_index.md)という名前のフラグを使用して、GitLab 17.9のプロジェクトの依存関係フィルターが[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/513320)されました。デフォルトでは有効になっています。
- GitLab 17.10で、[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/513321)になりました。機能フラグ`project_component_filter`は削除されました。
- GitLab 18.0で[プロジェクト](https://gitlab.com/gitlab-org/gitlab/-/issues/520771)と[グループ](https://gitlab.com/gitlab-org/gitlab/-/issues/523061)に導入された依存関係バージョンフィルター、`version_filtering_on_project_level_dependency_list`および`version_filtering_on_group_level_dependency_list`という名前の[フラグ](../../../administration/feature_flags/_index.md)を使用。デフォルトでは無効になっています。
- 依存関係バージョンフィルターがGitLab 18.1でGitLab.com、GitLab Self-Managed、およびGitLab Dedicatedで[有効](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/192291)になりました。
- 機能フラグ`version_filtering_on_project_level_dependency_list`および`version_filtering_on_group_level_dependency_list`は削除されました。

{{< /history >}}

依存関係のサブセットのみに焦点を当てるように、依存関係リストをフィルター処理できます。依存関係リストは、グループとプロジェクトで使用できます。

グループの場合、以下でフィルター処理できます:

- プロジェクト
- ライセンス
- コンポーネント
- コンポーネントのバージョン

プロジェクトの場合、以下でフィルター処理できます:

- コンポーネント
- コンポーネントのバージョン

コンポーネントバージョンでフィルター処理するには、最初に正確に1つのコンポーネントでフィルター処理する必要があります。

依存関係リストをフィルター処理するには:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトまたはグループを見つけます。
1. 左側のサイドバーで、**セキュリティ** > **依存関係リスト**を選択します。
1. フィルターバーを選択します。
1. フィルターを選択し、ドロップダウンリストから1つ以上の条件を選択します。ドロップダウンリストを閉じるには、その外側を選択します。さらにフィルターを追加するには、この手順を繰り返します。
1. 選択したフィルターを適用するには、<kbd>Enter</kbd>を押します。

依存関係リストには、フィルターに一致する依存関係のみが表示されます。

## 脆弱性 {#vulnerabilities}

{{< history >}}

- GitLab 17.9で`update_sbom_occurrences_vulnerabilities_on_cvs`[フラグ](../../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/500551)されました。デフォルトでは無効になっています。
- GitLab 17.9の[GitLab.comとGitLab Self-Managed](https://gitlab.com/gitlab-org/gitlab/-/issues/514223)で有効になりました。
- 依存関係リストが`detected`および`confirmed`状態のみを表示するように変更され、GitLab 18.5で導入されました。

{{< /history >}}

{{< alert type="flag" >}}

[SBOM](../dependency_scanning/dependency_scanning_sbom/_index.md)ベースの依存関係スキャンに関連付けられた脆弱性のサポートの可用性は、機能フラグによって制御されます。詳細については、履歴を参照してください。

{{< /alert >}}

依存関係に既知の脆弱性がある場合は、依存関係の名前の横にある矢印、または既知の脆弱性の数がいくつ存在するかを示すバッジを選択して表示します。脆弱性ごとに、その重大度と説明がその下に表示されます。脆弱性の詳細を表示するには、脆弱性の説明を選択します。[脆弱性の詳細](../vulnerabilities/_index.md)ページが開きます。依存関係リストには、`detected`状態と`confirmed`状態の脆弱性のみが表示されます。脆弱性の状態が変更されても、SBOMを含むデフォルトブランチで新しいパイプラインが実行されるまで、その変更は依存関係リストに反映されません。

## 依存関係パス {#dependency-paths}

{{< history >}}

- CycloneDX SBOMからの依存関係パス情報は、`project_level_sbom_occurrences`という名前の[フラグ](../../../administration/feature_flags/_index.md)を使用して、GitLab 16.9 [で導入](https://gitlab.com/gitlab-org/gitlab/-/issues/393061)されました。デフォルトでは無効になっています。
- CycloneDX SBOMからの依存関係パス情報は、GitLab 17.0 [のGitLab.com、GitLab Self-Managed、およびGitLab Dedicatedで有効](https://gitlab.com/gitlab-org/gitlab/-/issues/434371)になりました。
- GitLab 17.4で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/457633)されたCycloneDX SBOMからの依存関係パス情報。機能フラグ`project_level_sbom_occurrences`は削除されました。

{{< /history >}}

依存関係パスには、リストされたコンポーネントが一時的なコンポーネントであり、サポートされているパッケージマネージャーに属している場合、リストされたコンポーネントの直接の依存関係が表示されます。依存関係パスは、脆弱性がある依存関係に対してのみ表示されます。

依存関係パスは、次のパッケージマネージャーでサポートされています:

- [Conan](https://conan.io)
- [NuGet](https://www.nuget.org/)
- [sbt](https://www.scala-sbt.org)
- [Yarn 1.x](https://classic.yarnpkg.com/lang/en/)

依存関係パスは、[`dependency-scanning`](https://gitlab.com/components/dependency-scanning/-/tree/main/templates/main)コンポーネントを使用する場合にのみ、次のパッケージマネージャーでサポートされます:

- [Gradle](https://gradle.org/)
- [Maven](https://maven.apache.org/)
- [NPM](https://www.npmjs.com/)
- [Pipenv](https://pipenv.pypa.io/en/latest/)
- [pip-tools](https://pip-tools.readthedocs.io/en/latest/)
- [pnpm](https://pnpm.io/)
- [Poetry](https://python-poetry.org/)

### ライセンス {#licenses}

[dependency scanning](../dependency_scanning/_index.md) CI/CDジョブが構成されている場合、[検出されたライセンス](../../compliance/license_scanning_of_cyclonedx_files/_index.md)がこのページに表示されます。

## エクスポート {#export}

次の形式で依存関係リストをエクスポートできます:

- JSON
- CSV
- CycloneDX形式 (プロジェクトのみ)

依存関係リストをエクスポートするには:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトまたはグループを見つけます。
1. 左側のサイドバーで、**セキュリティ** > **依存関係リスト**を選択します。
1. **エクスポート**を選択し、ファイル形式を選択します。

依存関係リストは、メールアドレスに送信されます。依存関係リストをダウンロードするには、メール内のリンクを選択します。

## トラブルシューティング {#troubleshooting}

依存関係リストを操作する場合、次の問題が発生する可能性があります。

### ライセンスが「不明」と表示される {#license-appears-as-unknown}

特定の依存関係のライセンスが、いくつかの考えられる理由により、`unknown`として表示される場合があります。このセクションでは、特定の依存関係のライセンスが既知の理由で`unknown`として表示されるかどうかを判断する方法について説明します。

#### ライセンスがアップロードストリームに「不明」 {#license-is-unknown-upstream}

依存関係アップロードストリームに指定されたライセンスを確認します:

- C/C++ パッケージの場合は、[Conancenter](https://conan.io/center)を確認してください。
- npmパッケージの場合は、[npmjs.com](https://www.npmjs.com/)を確認してください。
- Pythonパッケージの場合は、[PyPi](https://pypi.org/)を確認してください。
- NuGetパッケージの場合は、[Nuget](https://www.nuget.org/packages)を確認してください。
- Goパッケージの場合は、[pkg.go.dev](https://pkg.go.dev/)を確認してください。

ライセンスがアップロードストリームに`unknown`として表示される場合、GitLabはその依存関係の**ライセンス**も`unknown`として表示することが予想されます。

#### ライセンスにSPDXライセンス式が含まれています {#license-includes-spdx-license-expression}

[SPDX license expressions](https://spdx.github.io/spdx-spec/v2.3/SPDX-license-expressions/)はサポートされていません。SPDXライセンス式を含む依存関係は、`unknown`である**ライセンス**とともに表示されます。SPDXライセンス式の例は、`(MIT OR CC0-1.0)`です。詳細については、[イシュー336878](https://gitlab.com/gitlab-org/gitlab/-/issues/336878)を参照してください。

#### パッケージバージョンがパッケージメタデータDBにありません {#package-version-not-in-package-metadata-db}

特定の依存関係パッケージのバージョンは、[Package Metadata Database](../../../topics/offline/quick_start_guide.md#enabling-the-package-metadata-database)に存在する必要があります。存在しない場合、その依存関係の**ライセンス**は`unknown`として表示されます。Goモジュールの詳細については、[イシュー440218](https://gitlab.com/gitlab-org/gitlab/-/issues/440218)を参照してください。

#### パッケージ名に特殊文字が含まれています {#package-name-contains-special-characters}

依存関係パッケージの名前にハイフン (`-`) が含まれている場合、**ライセンス**が`unknown`として表示されることがあります。これは、パッケージが手動で`requirements.txt`に追加された場合、または`pip-compile`が使用された場合に発生する可能性があります。これは、依存関係に関する情報をインジェストする際に、GitLabが[PEP 503の正規化された名前](https://peps.python.org/pep-0503/#normalized-names)に関するガイダンスに従ってPythonパッケージ名を正規化しないために発生します。詳細については、[イシュー440391](https://gitlab.com/gitlab-org/gitlab/-/issues/440391)を参照してください。
