---
stage: Application Security Testing
group: Secret Detection
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: パイプラインシークレット検出
---

<!-- markdownlint-disable MD025 -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

パイプラインシークレット検出は、ファイルがGitリポジトリにコミットされ、GitLabにプッシュされた後、ファイルをスキャンします。

[パイプラインシークレット検出を有効にする](#getting-started)と、`secret_detection`という名前のCI/CDジョブでスキャンが実行されます。スキャンを実行して、任意のGitLabプランで[パイプラインシークレット検出のJSONレポートアーティファクト](../../../../ci/yaml/artifacts_reports.md#artifactsreportssecret_detection)を表示できます。

GitLab Ultimateでは、パイプラインシークレット検出の結果も処理されるため、次のことが可能です。

- [マージリクエストウィジェット](../../detect/security_scanning_results.md)、[パイプラインセキュリティレポート](../../detect/security_scanning_results.md)、および[脆弱性レポート](../../vulnerability_report/_index.md)で結果を確認する。
- 承認ワークフローで結果を使用する。
- セキュリティダッシュボードで結果を確認する。
- パブリックリポジトリ内のリークに[自動的に対応する](../automatic_response.md)。
- [セキュリティポリシー](../../policies/_index.md)を使用して、プロジェクト全体で一貫したシークレット検出ルールを適用する。

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i> このパイプラインシークレット検出ドキュメントのインタラクティブな読み取りおよびハウツーデモについては、以下をご覧ください。

- [How to enable secret detection in GitLab Application Security Part 1/2](https://youtu.be/dbMxeO6nJCE?feature=shared)（GitLabアプリケーションセキュリティでシークレット検出を有効にする方法: パート1/2）
- [How to enable secret detection in GitLab Application Security Part 2/2](https://youtu.be/VL-_hdiTazo?feature=shared)（GitLabアプリケーションセキュリティでシークレット検出を有効にする方法: パート2/2）

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i> その他のインタラクティブな読み取りおよびハウツーデモについては、[Get Started With GitLab Application Security Playlist](https://www.youtube.com/playlist?list=PL05JrBw4t0KrUrjDoefSkgZLx5aJYFaF9)（GitLabアプリケーションセキュリティ入門プレイリスト）をご覧ください。

## 可用性 {#availability}

[GitLabプラン](https://about.gitlab.com/pricing/)ごとに、利用できる機能が異なります。

| 機能                                                              | FreeおよびPremiumの場合                    | Ultimateの場合 |
|:------------------------------------------------------------------------|:-------------------------------------|:------------|
| [アナライザーの動作をカスタマイズする](configure.md#customize-analyzer-behavior) | {{< icon name="check-circle" >}} 対応 | {{< icon name="check-circle" >}} 対応 |
| [出力](#secret-detection-results)をダウンロードする                            | {{< icon name="check-circle" >}} 対応 | {{< icon name="check-circle" >}} 対応 |
| マージリクエストウィジェットで新しい発見を確認する                            | {{< icon name="dotted-circle" >}} 非対応 | {{< icon name="check-circle" >}} 対応 |
| パイプラインの**セキュリティ**タブで特定されたシークレットを表示する              | {{< icon name="dotted-circle" >}} 非対応 | {{< icon name="check-circle" >}} 対応 |
| [脆弱性を管理する](../../vulnerability_report/_index.md)          | {{< icon name="dotted-circle" >}} 非対応 | {{< icon name="check-circle" >}} 対応 |
| [セキュリティダッシュボードにアクセスする](../../security_dashboard/_index.md)     | {{< icon name="dotted-circle" >}} 非対応 | {{< icon name="check-circle" >}} 対応 |
| [アナライザールールセットをカスタマイズする](configure.md#customize-analyzer-rulesets) | {{< icon name="dotted-circle" >}} 非対応 | {{< icon name="check-circle" >}} 対応 |
| [セキュリティポリシーを有効にする](../../policies/_index.md)                    | {{< icon name="dotted-circle" >}} 非対応 | {{< icon name="check-circle" >}} 対応 |

## はじめに {#getting-started}

パイプラインシークレット検出の使用を開始するには、パイロットプロジェクトを選択してアナライザーを有効にします。

前提要件:

- [`docker`](https://docs.gitlab.com/runner/executors/docker.html)または[`kubernetes`](https://docs.gitlab.com/runner/install/kubernetes.html) executorを備えたLinuxベースのRunnerが必要です。GitLab.comのためにホスティングされたRunnerを使用している場合は、デフォルトで有効になっています。
  - Windows Runnerはサポートされていません。
  - amd64以外のCPUアーキテクチャはサポートされていません。
- `test`ステージが含まれた`.gitlab-ci.yml`ファイルが必要です。

シークレット検出アナライザーを有効にするには、次のいずれかの方法を使用します。

- `.gitlab-ci.yml`ファイルを手動で編集します。CI/CDの設定が複雑な場合は、この方法を使用します。
- 自動的に設定されたマージリクエストを使用します。CI/CD設定がない場合、または設定が最小限である場合は、この方法を使用します。
- [スキャン実行ポリシー](../../policies/scan_execution_policies.md)でパイプラインシークレット検出を有効にします。

プロジェクトでシークレット検出スキャンを初めて実行する場合は、アナライザーを有効にした後、直ちに履歴スキャンを実行する必要があります。

パイプラインシークレット検出を有効にした後、[アナライザーの設定をカスタマイズ](configure.md)できます。

### `.gitlab-ci.yml`ファイルを手動で編集する {#edit-the-gitlab-ciyml-file-manually}

この方法では、既存の`.gitlab-ci.yml`ファイルを手動で編集する必要があります。

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **ビルド > パイプラインエディタ**を選択します。
1. 次の内容をコピーして、`.gitlab-ci.yml`ファイルの末尾に貼り付けます。

   ```yaml
   include:
     - template: Jobs/Secret-Detection.gitlab-ci.yml
   ```

1. **検証**タブを選択し、**パイプラインの検証**を選択します。メッセージ**シミュレーションが正常に完了しました**は、ファイルが有効であることを示しています。
1. **編集**タブを選択します。
1. （オプション）**コミットメッセージ**テキストボックスで、コミットメッセージをカスタマイズします。
1. **ブランチ**テキストボックスに、デフォルトブランチの名前を入力します。
1. **変更をコミットする**を選択します。

これで、パイプラインにパイプラインシークレット検出ジョブが含まれるようになります。アナライザーを有効にした後で[履歴スキャンを実行](#run-a-historic-scan)することを検討してください。

### 自動的に設定されたマージリクエストを使用する {#use-an-automatically-configured-merge-request}

このメソッドは、、マージリクエストを自動的に準備して、パイプラインシークレット検出テンプレートが含まれた`.gitlab-ci.yml`ファイルを追加します。マージリクエストをマージして、パイプラインシークレット検出を有効にします。

パイプラインシークレット検出を有効にするには、次の手順に従います。

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **セキュリティ > セキュリティ設定**を選択します。
1. **パイプラインのシークレット検出**行で、**マージリクエスト経由で設定**を選択します。
1. （オプション）フィールドに入力します。
1. **マージリクエストの作成**を選択します。
1. マージリクエストをレビューしてマージします。

これで、パイプラインにパイプラインシークレット検出ジョブが含まれるようになります。

## カバレッジ {#coverage}

パイプラインシークレット検出は、カバレッジと実行時間のバランスを取るように最適化されています。シークレットがないかスキャンされるのは、リポジトリの現在の状態と将来のコミットのみです。リポジトリの履歴にすでに存在するシークレットを特定するには、パイプラインシークレット検出を有効にした後、履歴スキャンを1回実行します。スキャン結果は、パイプラインが完了した後にのみ利用可能です。

シークレットについてスキャンされる内容は、パイプラインの種類と、設定が追加されているかどうかによって異なります。

デフォルトでは、パイプラインを実行すると、次のようになります。

- ブランチの場合:
  - **デフォルトブランチ**では、Gitワークツリーがスキャンされます。つまり、現在のリポジトリの状態が、通常のディレクトリであるかのようにスキャンされます。
  - **新しいデフォルト以外のブランチ**では、親ブランチの直近のコミットから最新のコミットに至るまでのすべてのコミットの内容がスキャンされます。
  - **既存のデフォルト以外のブランチ**では、最後にプッシュされたコミットから最新のコミットに至るまでのすべてのコミットの内容がスキャンされます。
- **マージリクエスト**では、ブランチ上のすべてのコミットの内容がスキャンされます。アナライザーがすべてのコミットにアクセスできない場合、親から最新のコミットに至るまでのすべてのコミットの内容がスキャンされます。すべてのコミットをスキャンするには、[マージリクエストパイプライン](../../detect/security_configuration.md#use-security-scanning-tools-with-merge-request-pipelines)を有効にする必要があります。

デフォルトの動作をオーバーライドするには、[利用可能なCI/CD変数](configure.md#available-cicd-variables)を使用します。

### 履歴スキャンを実行する {#run-a-historic-scan}

デフォルトでは、パイプラインシークレット検出は、Gitリポジトリの現在の状態のみをスキャンします。リポジトリの履歴に含まれるシークレットは検出されません。Gitリポジトリで全コミットとブランチのシークレットをチェックするには、履歴スキャンを実行します。

履歴スキャンは、パイプラインシークレット検出を有効にした後、1回だけ実行する必要があります。履歴スキャンには、特に長いGit履歴がある大規模なリポジトリの場合、長時間がかかることがあります。最初の履歴スキャンが完了したら、パイプラインの一部として標準のパイプラインシークレット検出のみを使用します。

[スキャン実行ポリシー](../../policies/scan_execution_policies.md#scanner-behavior)でパイプラインシークレット検出を有効にすると、デフォルトでは、最初にスケジュールされるスキャンは履歴スキャンになります。

履歴スキャンを実行するには、次の手順に従います。

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **ビルド > パイプライン**を選択します。
1. **パイプラインを新規作成**を選択します。
1. CI/CD変数を追加します。
   1. ドロップダウンリストから**変数**を選択します。
   1. **変数キーを入力**ボックスに、`SECRET_DETECTION_HISTORIC_SCAN`と入力します。
   1. **変数値を入力**ボックスに、`true`と入力します。
1. **パイプラインを新規作成**を選択します。

### 重複する脆弱性の追跡 {#duplicate-vulnerability-tracking}

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 17.0で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/434096)されました。

{{< /history >}}

シークレット検出は、高度な脆弱性追跡アルゴリズムを使用して、ファイルがリファクタリングされたり、移動したりしたときに、発見と脆弱性が重複して作成されるのを防ぎます。

次の場合、新しい発見は作成されません。

- ファイル内でシークレットが移動した場合。
- ファイル内に重複するシークレットが表示される場合。

重複する脆弱性の追跡は、ファイルごとに行われます。同じシークレットが2つの異なるファイルに表示される場合、2つの発見が作成されます。

詳細については、機密プロジェクト`https://gitlab.com/gitlab-org/security-products/post-analyzers/tracking-calculator`を参照してください。このプロジェクトは、GitLabチームメンバーのみが利用できます。

#### サポートされていないワークフロー {#unsupported-workflows}

重複した脆弱性の追跡は、以下の場合、ワークフローをサポートしません。

- 既存の発見に追跡署名がなく、新しい発見と同じ場所を共有していない。
- シークレットが、シークレット値全体ではなく、プレフィックスを検索することで検出される。これらのシークレットタイプでは、同じファイル内にある同じタイプの検出すべてが、単一の発見としてレポートされます。

  たとえば、SSH秘密キーは、プレフィックス`-----BEGIN OPENSSH PRIVATE KEY-----`によって検出されます。同じファイルに複数のSSH秘密キーがある場合、パイプラインシークレット検出は1つの発見のみを作成します。

### 検出されたシークレット {#detected-secrets}

パイプラインシークレット検出は、リポジトリのコンテンツを特定のパターンでスキャンします。各パターンは特定のタイプのシークレットに一致し、TOML構文を使用してルールで指定されます。GitLabは、デフォルトのルールセットを管理しています。

GitLab Ultimateを使用すると、これらのルールをニーズに合わせて拡張できます。たとえば、カスタムプレフィックスを使用するパーソナルアクセストークンはデフォルトでは検出されませんが、ルールをカスタマイズして、これらのトークンを識別できます。詳細については、[アナライザールールセットをカスタマイズする](configure.md#customize-analyzer-rulesets)をご覧ください。

パイプラインシークレット検出によって検出されるシークレットを確認するには、[検出されたシークレット](../detected_secrets.md)をご覧ください。パイプラインシークレット検出は、信頼性の高い結果を提供するために、URLなどの特定のコンテキストで、パスワードやその他の非構造化シークレットのみを検索します。

シークレットが検出されると、そのシークレットに対して脆弱性が作成されます。スキャンされたファイルからシークレットが削除され、パイプラインシークレット検出が再度実行された場合でも、脆弱性は「検出されたまま」になります。これは、流出したシークレットは、失効するまでセキュリティ上のリスクであり続けるためです。削除されたシークレットもGit履歴に残り続けます。Gitリポジトリの履歴からシークレットを削除するには、[リポジトリからテキストを削除する](../../../project/merge_requests/revert_changes.md#redact-text-from-repository)をご覧ください。

### 除外されたアイテム {#excluded-items}

パフォーマンスの向上のために、パイプラインシークレット検出は、シークレットが含まれる可能性が低い特定のファイルタイプとディレクトリを自動的に除外します。

次のアイテムは除外されます。

| カテゴリ                            | 除外されるアイテム                                                                                                                                                                                                                                                                                                                                                                                                                                             |
|-------------------------------------|------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| 設定ファイル             | ファイル: `gitleaks.toml`、`verification-metadata.xml`、`Database.refactorlog`、`.editorconfig`、`.gitattributes`                                                                                                                                                                                                                                                                                                                                             |
| メディアファイルとバイナリファイル           | 拡張子: `.bmp`、`.gif`、`.svg`、`.jpg/.jpeg`、`.png`、`.tiff/.tif`、`.webp`、`.ico`、`.heic`<br/>フォント: `.eot`、`.otf`、`.ttf`、`.woff`、`.woff2`<br/>ドキュメント: `.doc/.docx`、`.xls/.xlsx`、`.ppt/.pptx`、`.pdf`<br/>オーディオ/ビデオ: `.mp3`、`.mp4`、`.wav`、`.flac`、`.aac`、`.ogg`、`.avi`、`.mkv`、`.mov`、`.wmv`、`.flv`、`.webm`<br/>アーカイブ: `.zip`、`.rar`、`.7z`、`.tar`、`.gz`、`.bz2`、`.xz`、`.dmg`、`.iso`<br/>実行可能ファイル: `.exe`、`.gltf` |
| Visual Studioファイル             | 拡張子: `.socket`、`.vsidx`、`.suo`、`.wsuo`、`.dll`、`.pdb`                                                                                                                                                                                                                                                                                                                                                                                           |
| パッケージロックファイル              | ファイル: `deno.lock`、`npm-shrinkwrap.json`、`package-lock.json`、`pnpm-lock.yaml`、`yarn.lock`、`Pipfile.lock`、`poetry.lock`、`gradle.lockfile`、`Cargo.lock`、`composer.lock`                                                                                                                                                                                                                                                                             |
| Go言語ファイル               | 拡張子: `go.mod`、`go.sum`、`go.work`、`go.work.sum`<br/>ディレクトリ: `vendor/`（`github.com`、`golang.org`、`google.golang.org`、`gopkg.in`、`istio.io`、`k8s.io`、`sigs.k8s.io`からのGoモジュールのみ）<br/>ファイル: `vendor/modules.txt`                                                                                                                                                                                                            |
| Rubyファイル                      | ディレクトリ: `.bundle/`、`gems/`、`specifications/`<br/>拡張子: `gems/`ディレクトリの`.gem`ファイル、`specifications/`ディレクトリの`.gemspec`ファイル                                                                                                                                                                                                                                                                                                     |
| ビルドツールのラッパー             | ファイル: `gradlew`、`gradlew.bat`、`mvnw`、`mvnw.cmd`<br/>ディレクトリ: `.mvn/wrapper/`<br/>特定のアイテム: Mavenラッパーディレクトリの`MavenWrapperDownloader.java`                                                                                                                                                                                                                                                                                                |
| 依存関係ディレクトリ          | ディレクトリ: `node_modules/`、`bower_components/`、`packages/`                                                                                                                                                                                                                                                                                                                                                                                             |
| ビルド出力ディレクトリ        | ディレクトリ: `target/`、`build/`、`bin/`、`obj/`                                                                                                                                                                                                                                                                                                                                                                                                           |
| ベンダーディレクトリ             | ディレクトリ: `vendor/bundle/`、`vendor/ruby/`、`vendor/composer/`                                                                                                                                                                                                                                                                                                                                                                                          |
| Pythonキャッシュファイル              | 拡張子: `.pyc`、`.pyo`<br/>ディレクトリ: `__pycache__/`                                                                                                                                                                                                                                                                                                                                                                                                 |
| Pythonツールキャッシュ              | ディレクトリ: `.pytest_cache/`、`.mypy_cache/`、`.tox/`                                                                                                                                                                                                                                                                                                                                                                                                     |
| Python仮想環境     | ディレクトリ: `venv/`、`virtualenv/`、`.venv/`、`env/`                                                                                                                                                                                                                                                                                                                                                                                                      |
| Pythonインストールディレクトリ | ディレクトリ: `lib/python[version]/`、`lib64/python[version]/`、`python[version]/lib/`、`python[version]/Lib/`                                                                                                                                                                                                                                                                                                                                              |
| Pythonパッケージメタデータ        | バージョンと`.dist-info`で終わるパッケージ名                                                                                                                                                                                                                                                                                                                                                                                                         |
| JavaScriptライブラリ            | ファイル: `angular*.js`、`bootstrap*.js`、`jquery*.js`、`jquery-ui*.js`、`plotly*.js`、`swagger-ui*.js`<br/>ソースマップ: 対応する`.js.map`ファイル                                                                                                                                                                                                                                                                                                       |
| 最小化/バンドルされたアセット         | 拡張子: `.min.js`、`.min.css`、`.bundle.js`、`.bundle.css`、`.map`（ソースマップファイル）                                                                                                                                                                                                                                                                                                                                                                  |
| コンパイルされたファイル                  | 拡張子: `.class`、`.o`、`.obj`、`.jar`、`.war`（Webアーカイブ）、`.ear`                                                                                                                                                                                                                                                                                                                                                                                   |
| キャッシュディレクトリ             | ディレクトリ: `.cache/`、`.coverage/`、`.pytest_cache/`、`.mypy_cache/`、`.tox/`                                                                                                                                                                                                                                                                                                                                                                            |
| 生成されたドキュメント         | ディレクトリ: `htmlcov/`、`coverage/`、`_build/`、`_site/`、`docs/_build/`                                                                                                                                                                                                                                                                                                                                                                                  |
| バージョン管理とIDE           | ディレクトリ: `.git/`、`.svn/`、`.hg/`、`.bzr/`（バージョン管理）、`.vscode/`、`.idea/`、`.eclipse/`、`.vs/`（IDE）                                                                                                                                                                                                                                                                                                                                         |
| オペレーティングシステムファイル          | ファイル: `.DS_Store`、`Thumbs.db`                                                                                                                                                                                                                                                                                                                                                                                                                            |

## シークレット検出の結果 {#secret-detection-results}

パイプラインシークレット検出は、ファイル`gl-secret-detection-report.json`をジョブアーティファクトとして出力します。ファイルには、検出されたシークレットが含まれています。ファイルを[ダウンロード](../../../../ci/jobs/job_artifacts.md#download-job-artifacts)して、GitLabの外部で処理できます。

詳細については、[レポートファイルスキーマ](https://gitlab.com/gitlab-org/security-products/security-report-schemas/-/blob/master/dist/secret-detection-report-format.json)と[レポートファイルの例](https://gitlab.com/gitlab-org/security-products/analyzers/secrets/-/blob/master/qa/expect/secrets/gl-secret-detection-report.json)を参照してください。

### 追加の出力 {#additional-output}

{{< details >}}

- プラン: Ultimate

{{< /details >}}

ジョブの結果は、以下でもレポートされます。

- [マージリクエストウィジェット](../../detect/security_scanning_results.md#merge-request-security-widget): マージリクエストに取り込まれた新しい発見を表示します。
- [パイプラインセキュリティレポート](../../vulnerability_report/pipeline.md): 最新のパイプライン実行から得られたすべての発見を表示します。
- [脆弱性レポート](../../vulnerability_report/_index.md): すべてのセキュリティ検出の一元管理を提供します。
- セキュリティダッシュボード: プロジェクトとグループのすべての脆弱性を組織全体が把握できるようにします。

## 結果について理解する {#understanding-the-results}

パイプラインシークレット検出は、リポジトリで見つかった潜在的なシークレットに関する詳細情報を提供します。各シークレットには、流出したシークレットのタイプと修正のガイドラインが含まれています。

結果をレビューするときは、次の手順に従います。

1. 周囲のコードを調べて、検出されたパターンが実際にシークレットであるかどうかを判断します。
1. 検出された値が有効な認証情報であるかどうかをテストします。
1. リポジトリの表示レベルとシークレットのスコープについて検討します。
1. アクティブな権限の高いシークレットに最初に対処します。

### 一般的な検出カテゴリ {#common-detection-categories}

パイプラインシークレット検出による検出は、多くの場合、次の3つのカテゴリに分類されます。

- **真陽性**: ローテーションして削除する必要がある正当なシークレット。次に例を示します。
  - アクティブなAPIキー、データベースパスワード、認証トークン
  - 秘密キーと証明書
  - サービスアカウントの認証情報
- **誤検出**: 実際のシークレットではない、検出されたパターン。次に例を示します。
  - ドキュメント内のサンプル値
  - テストデータまたはモック認証情報
  - プレースホルダー値が含まれた設定テンプレート
- **過去の発見**: 以前にコミット済みであるが、アクティブではない可能性のあるシークレット。これらの検出には、以下が必要です。
  - 調査して現在の状態を判定する必要があります
  - 念のため、ローテーションする必要があります

## 流出したシークレットを修正する {#remediate-a-leaked-secret}

シークレットが検出された場合は、直ちにローテーションする必要があります。GitLabは、一部のタイプの流出したシークレットを[自動的に失効](../automatic_response.md)しようとします。自動的に失効しないものについては、手動で失効させる必要があります。

[リポジトリの履歴からシークレットをパージ](../../../project/repository/repository_size.md#purge-files-from-repository-history)するだけでは、流出に完全に対応できません。元のシークレットは、リポジトリの既存のフォークまたは複製に残ります。

流出したシークレットに対応する方法の手順については、脆弱性レポートで脆弱性を選択してください。

## 最適化 {#optimization}

組織全体にパイプラインシークレット検出をデプロイする前に、設定を最適化して誤検出を減らし、特定の環境の精度を向上させます。

誤検出は、アラート疲れを引き起こし、ツールに対する信頼を低下させる可能性があります。次のようなカスタムルールセット設定（Ultimateのみ）の使用を検討してください。

- コードベースに固有の既知の安全なパターンを除外します。
- シークレット以外で頻繁にトリガーされるルールの感度を調整します。
- 組織固有のシークレット形式のカスタムルールを追加します。

大規模なリポジトリ、または多数のプロジェクトがある組織でパフォーマンスを最適化するには、以下をレビューしてください。

- スキャンスコープの管理:
  - プロジェクトで履歴スキャンを実行した後、履歴スキャンをオフにします。
  - 使用率の低い期間中に履歴スキャンを行うようにスケジュールします。
- リソースの割り当て:
  - より大きなリポジトリに対して十分なRunnerリソースを割り当てます。
  - セキュリティスキャンのワークロードに対して専用のRunnerを使用することを検討してください。
  - スキャンの期間をモニタリングし、リポジトリのサイズに基づいて最適化します。

### 最適化の変更をテストする {#testing-optimization-changes}

組織全体に最適化を適用する前に、以下を実行します。

1. 最適化が正当なシークレットを見逃していないことを検証します。
1. 誤検出の削減とスキャンパフォーマンスの向上を追跡します。
1. 効果的な最適化パターンのレコードを維持します。

## ロールアウトする {#roll-out}

パイプラインシークレット検出を段階的に実装する必要があります。組織全体に機能をロールアウトする前に、小規模なパイロットから始めて、ツールの動作を理解してください。

パイプラインシークレット検出をロールアウトするときは、次のガイドラインに従ってください。

1. パイロットプロジェクトを選択します。適切なプロジェクトは、以下を備えています。
   - コミットが定期的に行われるアクティブな開発。
   - 管理可能なコードベースサイズ。
   - GitLab CI/CDに精通しているチーム。
   - 設定でイテレーションを行う意欲。
1. 簡単なことから始めます。パイロットプロジェクトのデフォルトの設定でパイプラインシークレット検出を有効にします。
1. 結果をモニタリングします。1～2週間アナライザーを実行して、一般的な発見について理解します。
1. 検出されたシークレットに対処します。見つかった正当なシークレットを修正します。
1. 設定を調整します。初期結果に基づいて設定を調整します。
1. 実装を文書化します。一般的な誤検出と修正パターンを記録します。

## FIPS対応イメージ {#fips-enabled-images}

{{< history >}}

- GitLab 14.10で[導入](https://gitlab.com/groups/gitlab-org/-/epics/6479)されました。

{{< /history >}}

デフォルトのスキャナーイメージは、サイズと保守性の観点からベースのAlpineイメージから構築されています。GitLabは、FIPS対応イメージの[Red Hat UBI](https://www.redhat.com/en/blog/introducing-red-hat-universal-base-image)バージョンを提供しています。

FIPS対応イメージを使用するには、次のいずれかを実行します。

- `SECRET_DETECTION_IMAGE_SUFFIX` CI/CD変数を`-fips`に設定します。
- デフォルトのイメージ名に`-fips`拡張子を追加します。

次に例を示します。

```yaml
variables:
  SECRET_DETECTION_IMAGE_SUFFIX: '-fips'

include:
  - template: Jobs/Secret-Detection.gitlab-ci.yml
```

## トラブルシューティング {#troubleshooting}

### デバッグレベルのログを生成する {#debug-level-logging}

デバッグレベルでログを生成しておくと、トラブルシューティングに役立ちます。詳細については、[デバッグレベルのログを生成する](../../troubleshooting_application_security.md#debug-level-logging)を参照してください。

#### 警告: `gl-secret-detection-report.json: no matching files` {#warning-gl-secret-detection-reportjson-no-matching-files}

この警告に関する情報については、[アプリケーションセキュリティの一般的なトラブルシューティングのセクション](../../../../ci/jobs/job_artifacts_troubleshooting.md#error-message-no-files-to-upload)を参照してください。

#### エラー: `Couldn't run the gitleaks command: exit status 2` {#error-couldnt-run-the-gitleaks-command-exit-status-2}

パイプラインシークレット検出アナライザーが、コミット間のパッチを生成して、シークレットのコンテンツをスキャンすることに依存しています。マージリクエストのコミット数が[`GIT_DEPTH` CI/CD変数](../../../../ci/runners/configure_runners.md#shallow-cloning)の値より大きい場合、シークレット検出は、[シークレットの検出に失敗](#error-couldnt-run-the-gitleaks-command-exit-status-2)します。

たとえば、60件のコミットを含むマージリクエストからトリガーされたパイプラインがあり、`GIT_DEPTH`変数が60未満に設定されているとします。その場合、関連するすべてのコミットを含めるのに十分な深さがクローンにないため、パイプラインシークレット検出ジョブは失敗します。現在の値を確認するには、[パイプライン設定](../../../../ci/pipelines/settings.md#limit-the-number-of-changes-fetched-during-clone)を参照してください。

これがエラーの原因であることを確認するには、[デバッグレベルのログ生成](../../troubleshooting_application_security.md#debug-level-logging)を有効にしてから、パイプラインを再実行します。ログは次の例のようになります。テキスト「object not found」は、このエラーの兆候です。

```plaintext
ERRO[2020-11-18T18:05:52Z] object not found
[ERRO] [secrets] [2020-11-18T18:05:52Z] ▶ Couldn't run the gitleaks command: exit status 2
[ERRO] [secrets] [2020-11-18T18:05:52Z] ▶ Gitleaks analysis failed: exit status 2
```

問題を解決するには、[`GIT_DEPTH` CI/CD変数](../../../../ci/runners/configure_runners.md#shallow-cloning)をより高い値に設定します。これをパイプラインシークレット検出ジョブのみに適用するには、次の内容を`.gitlab-ci.yml`ファイルに追加します。

```yaml
secret_detection:
  variables:
    GIT_DEPTH: 100
```

#### エラー: `ERR fatal: ambiguous argument` {#error-err-fatal-ambiguous-argument}

リポジトリのデフォルトブランチが、ジョブがトリガーされた対象のブランチと無関係である場合、パイプラインシークレット検出が`ERR fatal: ambiguous argument`エラーで失敗する可能性があります。詳細については、イシュー[!352014](https://gitlab.com/gitlab-org/gitlab/-/issues/352014)を参照してください。

問題を解決するには、リポジトリで[デフォルトブランチを正しく設定](../../../project/repository/branches/default.md#change-the-default-branch-name-for-a-project)してください。これは、`secret-detection`ジョブを実行するブランチと関連する履歴を持つブランチに設定する必要があります。

#### ジョブログの`exec /bin/sh: exec format error`メッセージ {#exec-binsh-exec-format-error-message-in-job-log}

GitLabパイプラインシークレット検出アナライザーは、`amd64` CPUアーキテクチャでの実行[のみをサポートしています。](#getting-started)このメッセージは、ジョブが`arm`などの異なるアーキテクチャで実行されていることを示しています。

#### エラー: `fatal: detected dubious ownership in repository at '/builds/<project dir>'` {#error-fatal-detected-dubious-ownership-in-repository-at-buildsproject-dir}

シークレット検出が終了ステータス128で失敗する場合があります。これは、Dockerイメージのユーザーへの変更が原因である可能性があります。

次に例を示します。

```shell
$ /analyzer run
[INFO] [secrets] [2024-06-06T07:28:13Z] ▶ GitLab secrets analyzer v6.0.1
[INFO] [secrets] [2024-06-06T07:28:13Z] ▶ Detecting project
[INFO] [secrets] [2024-06-06T07:28:13Z] ▶ Analyzer will attempt to analyze all projects in the repository
[INFO] [secrets] [2024-06-06T07:28:13Z] ▶ Loading ruleset for /builds....
[WARN] [secrets] [2024-06-06T07:28:13Z] ▶ /builds/....secret-detection-ruleset.toml not found, ruleset support will be disabled.
[INFO] [secrets] [2024-06-06T07:28:13Z] ▶ Running analyzer
[FATA] [secrets] [2024-06-06T07:28:13Z] ▶ get commit count: exit status 128
```

この問題を回避するには、次のように`before_script`を追加します。

```yaml
before_script:
    - git config --global --add safe.directory "$CI_PROJECT_DIR"
```

この問題の詳細については、[イシュー465974](https://gitlab.com/gitlab-org/gitlab/-/issues/465974)をご覧ください。

<!-- markdownlint-enable MD025 -->
