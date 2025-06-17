---
stage: Application Security Testing
group: Secret Detection
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: パイプラインシークレット検出
---

<!-- markdownlint-disable MD025 -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

パイプラインシークレット検出は、ファイルがGitリポジトリにコミットされ、GitLabにプッシュされた後にファイルをスキャンします。

[パイプラインシークレット検出を有効にする](#enable-the-analyzer)と、`secret_detection`という名前のCI/CDジョブでスキャンが実行されます。スキャンを実行して、任意のGitLabプランで[JSONレポートアーティファクトのパイプラインシークレット検出](../../../../ci/yaml/artifacts_reports.md#artifactsreportssecret_detection)を表示できます。

GitLab Ultimateでは、パイプラインシークレット検出の結果も処理されるため、次のことが可能です。

- [マージリクエストウィジェット](../../detect/security_scan_results.md#merge-request)、[パイプラインセキュリティレポート](../../vulnerability_report/pipeline.md)、および[脆弱性レポート](../../vulnerability_report/_index.md)で確認する。
- 承認ワークフローでそれらを使用する。
- セキュリティダッシュボードで確認する。
- 自動的に対応パブリックリポジトリ内のリークに[自動的に対応する。](../automatic_response.md)
- [セキュリティポリシー](../../policies/_index.md)を使用して、プロジェクト全体で一貫したシークレット検出ルールを適用する。

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i> このパイプラインシークレット検出ドキュメントのインタラクティブな読み取りおよびハウツーデモについては、以下をご覧ください。

- [GitLabアプリケーションセキュリティパート1/2でシークレット検出を有効にする方法](https://youtu.be/dbMxeO6nJCE?feature=shared)
- [GitLabアプリケーションセキュリティパート2/2でシークレット検出を有効にする方法](https://youtu.be/VL-_hdiTazo?feature=shared)

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i> その他のインタラクティブな読み取りおよびハウツーデモについては、[GitLabアプリケーションセキュリティ入門プレイリスト](https://www.youtube.com/playlist?list=PL05JrBw4t0KrUrjDoefSkgZLx5aJYFaF9)をご覧ください。

## 可用性

[GitLabプラン](https://about.gitlab.com/pricing/)ごとに、利用できる機能が異なります。

| 機能                                                                                           | FreeおよびPremiumの場合      | Ultimateの場合            |
|:-----------------------------------------------------------------------------------------------------|:-----------------------|:-----------------------|
| [アナライザー設定をカスタマイズする](configure.md#customize-analyzer-settings)                                          | {{< icon name="check-circle" >}}はい | {{< icon name="check-circle" >}}はい |
| [出力](#output)をダウンロードする                                                                           | {{< icon name="check-circle" >}}はい | {{< icon name="check-circle" >}}はい |
| マージリクエストウィジェットで新しい発見を確認する                                                         | {{< icon name="dotted-circle" >}}いいえ | {{< icon name="check-circle" >}}はい |
| パイプラインの**Security(セキュリティ)**タブで識別されたシークレットを表示する                                           | {{< icon name="dotted-circle" >}}いいえ | {{< icon name="check-circle" >}}はい |
| [脆弱性を管理する](../../vulnerability_report/_index.md)                                        | {{< icon name="dotted-circle" >}}いいえ | {{< icon name="check-circle" >}}はい |
| [セキュリティダッシュボードにアクセスする](../../security_dashboard/_index.md)                                   | {{< icon name="dotted-circle" >}}いいえ | {{< icon name="check-circle" >}}はい |
| [アナライザールールセットをカスタマイズする](configure.md#customize-analyzer-rulesets)                                          | {{< icon name="dotted-circle" >}}いいえ | {{< icon name="check-circle" >}}はい |
| [セキュリティポリシーを有効にする](../../policies/_index.md)                                                  | {{< icon name="dotted-circle" >}}いいえ | {{< icon name="check-circle" >}}はい |

## カバレッジ

パイプラインシークレット検出は、カバレッジと実行時間のバランスを取るように最適化されています。リポジトリの現在の状態と将来のコミットのみがシークレットについてスキャンされます。リポジトリの履歴に既に存在するシークレットを特定するには、パイプラインシークレット検出を有効にした後、履歴スキャンを1回実行します。スキャン結果は、パイプラインが完了した後にのみ利用可能です。

シークレットについてスキャンされる内容は、パイプラインの種類と、追加の設定が設定されているかどうかによって異なります。

デフォルトでは、パイプラインを実行すると、

- **デフォルトブランチ**では、Gitワークツリーがスキャンされます。つまり、リポジトリ全体が典型的なディレクトリであるかのようにスキャンされます。
- **新しいデフォルト以外のブランチ**では、親ブランチの最新のコミットから最新のコミットまでのすべてのコミットの内容がスキャンされます。
- **既存のデフォルト以外のブランチ**では、最新のブランチコミットから最新のコミットまでのすべてのコミットの内容がスキャンされます。
- **マージリクエスト**では、ブランチ上のすべてのコミットの内容がスキャンされます。アナライザーがすべてのコミットにアクセスできない場合、親から最新のコミットまでのすべてのコミットの内容がスキャンされます。マージリクエストパイプラインを使用するには、[`latest`パイプラインシークレット検出テンプレート](../../detect/roll_out_security_scanning.md#use-security-scanning-tools-with-merge-request-pipelines)を使用する必要があります。

デフォルトの動作をオーバーライドするには、[利用可能なCI/CD変数](configure.md#available-cicd-variables)を使用します。

### 全履歴のパイプラインシークレット検出

デフォルトでは、パイプラインシークレット検出は、Gitリポジトリの現在の状態のみをスキャンします。リポジトリの履歴に含まれるシークレットは検出されません。Gitリポジトリで全コミットとブランチのシークレットをチェックするには、履歴スキャンを実行します。

履歴スキャンは、パイプラインシークレット検出を有効にした後、1回だけ実行する必要があります。履歴スキャンには、特にGit履歴が長い大規模なリポジトリの場合、長い時間がかかることがあります。最初の全履歴スキャンが完了したら、パイプラインの一部として標準のパイプラインシークレット検出のみを使用します。

### 高度な脆弱性追跡

{{< details >}}

- プラン: Ultimate
- 提供: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 17.0で[導入されました](https://gitlab.com/gitlab-org/gitlab/-/issues/434096)。

{{< /history >}}

デベロッパーが識別されたシークレットを含むファイルに変更を加えると、たいてい、これらのシークレットの位置も変更されます。パイプラインシークレット検出が、これらのシークレットを[脆弱性レポート](../../vulnerability_report/_index.md)で追跡された脆弱性としてすでにフラグを立てている可能性があります。これらの脆弱性は、簡単に識別して対応できるように、特定のシークレットに関連付けられています。ただし、検出されたシークレットが移動しても正確に追跡されない場合、脆弱性の管理が困難になり、脆弱性レポートが重複する可能性があります。

パイプラインシークレット検出は、高度な脆弱性追跡アルゴリズムを使用して、同じシークレットがリファクタコードまたは無関係な変更によってファイル内で移動した場合、より正確に特定します。

詳細については、機密プロジェクト`https://gitlab.com/gitlab-org/security-products/post-analyzers/tracking-calculator`を参照してください。このプロジェクトの内容は、GitLabチームメンバーのみが利用できます。

#### サポートされていないワークフロー

- このアルゴリズムは、既存の発見に追跡署名がなく、新しく検出された発見と同じ場所を共有していないワークフローをサポートしていません。
- 暗号化キーなど、一部のルールタイプでは、パイプラインシークレット検出は、シークレット値全体ではなく、シークレットのプレフィックスを照合してリークを識別します。このシナリオでは、アルゴリズムは、ファイル内の同じルールタイプの異なるシークレットを個別の発見として扱うのではなく、単一の発見に統合します。たとえば、[SSHプライベートキーのルールタイプ](https://gitlab.com/gitlab-org/security-products/analyzers/secrets/-/blob/d2919f65f1d8001755015b5d790af620676b97ea/gitleaks.toml#L138)は、値の`-----BEGIN OPENSSH PRIVATE KEY-----`プレフィックスのみを照合して、SSHプライベートキーの存在を確認します。同じファイル内に2つの異なるSSHプライベートキーがある場合、アルゴリズムは両方の値を同一とみなし、2つではなく1つの発見のみを報告します。
- アルゴリズムのスコープはファイル単位に限定されています。つまり、異なる2つのファイルに同じシークレットが表示されている場合、2つの異なる発見として扱われます。

### 検出されたシークレット

パイプラインシークレット検出は、リポジトリのコンテンツを特定パターンでスキャンします。各パターンは特定のタイプのシークレットに一致し、TOML構文を使用してルールで指定されます。GitLabは、デフォルトのルールセットを管理しています。

GitLab Ultimateを使用すると、これらのルールをニーズに合わせて拡張できます。たとえば、カスタムプレフィックスを使用するパーソナルアクセストークンはデフォルトでは検出されませんが、ルールをカスタマイズしてこれらのトークンを識別できます。詳細については、[アナライザールールセットのカスタマイズ](configure.md#customize-analyzer-rulesets)をご覧ください。

パイプラインシークレット検出によって検出されるシークレットを確認するには、[検出されたシークレット](../detected_secrets.md)をご覧ください。信頼性の高い、信頼性の高い結果を提供するために、パイプラインシークレット検出は、URLなどの特定のコンテキストでのみ、パスワードまたはその他の非構造化シークレットを検索します。

シークレットが検出されると、そのシークレットに対して脆弱性が作成されます。脆弱性は、シークレットがスキャンされたファイルから削除され、パイプラインシークレット検出が再度実行された場合でも、「検出されたまま」になります。これは、シークレットがGitリポジトリの履歴に残っているためです。Gitリポジトリの履歴からシークレットを削除するには、[リポジトリからテキストを削除する](../../../project/merge_requests/revert_changes.md#redact-text-from-repository)をご覧ください。

## アナライザーを有効にする

パイプラインシークレット検出を使用するには、アナライザーを有効にします。有効にすると、[アナライザー設定をカスタマイズ](configure.md)できます。

前提要件:

- [`docker`](https://docs.gitlab.com/runner/executors/docker.html)または[`kubernetes`](https://docs.gitlab.com/runner/install/kubernetes.html) executorを使用した、LinuxベースのGitLab Runner。GitLab.comのホストRunnerを使用している場合、これはデフォルトで有効になっています。
  - Windows Runnerはサポートされていません。
  - amd64以外のCPUアーキテクチャはサポートされていません。
- GitLab CI/CD設定(`.gitlab-ci.yml`)には、`test`ステージを含める必要があります。

パイプラインシークレット検出を有効にするには、次のいずれかを実行します。

- [Auto DevOps](../../../../topics/autodevops/_index.md)を有効にします。これには、[自動シークレット検出](../../../../topics/autodevops/stages.md#auto-secret-detection)が含まれています。
- [`.gitlab-ci.yml`ファイルを編集](#edit-the-gitlab-ciyml-file-manually)します。`.gitlab-ci.yml`ファイルが複雑な場合は、この方法を使用してください。
- [自動的に設定されたマージリクエストを使用](#use-an-automatically-configured-merge-request)します。

### `.gitlab-ci.yml`ファイルを手動で編集する

この方法では、既存の`.gitlab-ci.yml`ファイルを手動で編集する必要があります。GitLab CI/CD設定ファイルが複雑な場合は、この方法を使用してください。

1. 左側のサイドバーで、**検索または移動**を選択して、プロジェクトを見つけます。
1. **ビルド > パイプラインエディタ**を選択します。
1. 次の内容をコピーして、`.gitlab-ci.yml`ファイルの末尾に貼り付けます。

   ```yaml
   include:
     - template: Jobs/Secret-Detection.gitlab-ci.yml
   ```

1. **検証**タブを選択し、**パイプラインの検証**を選択します。メッセージ**Simulation completed successfully(シミュレーションが正常に完了しました)**は、ファイルが有効であることを示しています。
1. **編集**タブを選択します。
1. （オプション）**コミットメッセージ**テキストボックスで、コミットメッセージをカスタマイズします。
1. **ブランチ**テキストボックスに、デフォルトブランチの名前を入力します。
1. **変更をコミットする**を選択します。

これで、パイプラインにパイプラインシークレット検出ジョブが含まれるようになります。

### 自動的に設定されたマージリクエストを使用する

{{< history >}}

- GitLab 13.11で[導入されました。](https://gitlab.com/groups/gitlab-org/-/epics/4496)機能フラグの背後にデプロイされ、デフォルトで有効となっています。
- GitLab 14.1で[機能フラグが削除されました](https://gitlab.com/gitlab-org/gitlab/-/issues/329886)。

{{< /history >}}

このメソッドは、`.gitlab-ci.yml`ファイルに含まれるパイプラインシークレット検出テンプレートを使用して、マージリクエストを自動的に準備します。次に、マージリクエストをマージして、パイプラインシークレット検出を有効にします。

{{< alert type="note" >}}

この方法は、既存の`.gitlab-ci.yml`ファイルがない場合、または最小限の設定ファイルの場合に最適です。複雑なGitLab設定ファイルがある場合、正常に解析されず、エラーが発生する可能性があります。その場合は、代わりに[手動](#edit-the-gitlab-ciyml-file-manually)での方法を用いてください。

{{< /alert >}}

パイプラインシークレット検出を有効にするには、次の手順に従います。

1. 左側のサイドバーで、**検索または移動**を選択して、プロジェクトを見つけます。
1. **セキュリティ > セキュリティ設定**を選択します。
1. **Pipeline secret detection(パイプラインシークレット検出)**行で、**マージリクエスト経由で設定**を選択します。
1. （オプション）フィールドに入力します。
1. **マージリクエストの作成**を選択します。
1. マージリクエストをレビューしてマージします。

これで、パイプラインにパイプラインシークレット検出ジョブが含まれるようになります。

## 出力する

パイプラインシークレット検出は、ファイル`gl-secret-detection-report.json`をジョブアーティファクトとして出力します。ファイルには、検出されたシークレットが含まれています。ファイルを[ダウンロード](../../../../ci/jobs/job_artifacts.md#download-job-artifacts)して、GitLabの外部で処理できます。

詳細については、以下を参照してください。

- [レポートファイルをスキーマする](https://gitlab.com/gitlab-org/security-products/security-report-schemas/-/blob/master/dist/secret-detection-report-format.json)
- [レポートファイルの例](https://gitlab.com/gitlab-org/security-products/analyzers/secrets/-/blob/master/qa/expect/secrets/gl-secret-detection-report.json)

## FIPS対応イメージ

{{< history >}}

- GitLab 14.10で[導入されました](https://gitlab.com/groups/gitlab-org/-/epics/6479)。

{{< /history >}}

デフォルトのスキャナーイメージは、サイズと保守性の観点からベースのAlpineイメージから構築されています。GitLabは、FIPS対応のイメージの[Red Hat UBI](https://www.redhat.com/en/blog/introducing-red-hat-universal-base-image)バージョンを提供しています。

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

## トラブルシューティング

### デバッグレベルのログを生成する

デバッグレベルでログを生成しておくと、トラブルシューティングに役立ちます。詳細については、[デバッグレベルのログを生成する](../../troubleshooting_application_security.md#debug-level-logging)を参照してください。

#### 警告: `gl-secret-detection-report.json: no matching files`

これに関する情報については、[一般的なアプリケーションセキュリティのトラブルシューティングセクション](../../../../ci/jobs/job_artifacts_troubleshooting.md#error-message-no-files-to-upload)を参照してください。

#### エラー: `Couldn't run the gitleaks command: exit status 2`

パイプラインシークレット検出アナライザーが、コミット間のパッチを生成して、シークレットのコンテンツをスキャンすることに依存しています。マージリクエストのコミット数が[`GIT_DEPTH` CI/CD変数](../../../../ci/runners/configure_runners.md#shallow-cloning)の値より大きい場合、シークレット検出は[シークレットの検出に失敗](#error-couldnt-run-the-gitleaks-command-exit-status-2)します。

たとえば、60件のコミットを含むマージリクエストからトリガーされたパイプラインがあり、`GIT_DEPTH`変数が60未満に設定されているとします。その場合、クローンに関連するすべてのコミットを含めるのに十分な深さがないため、パイプラインシークレット検出ジョブは失敗します。現在の値を確認するには、[パイプライン設定](../../../../ci/pipelines/settings.md#limit-the-number-of-changes-fetched-during-clone)を参照してください。

これをエラーの原因として確認するには、[デバッグレベルのログ生成](../../troubleshooting_application_security.md#debug-level-logging)を有効にしてから、パイプラインを再実行します。ログは次の例のようになります。テキスト「object not found」は、このエラーの兆候です。

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

#### エラー: `ERR fatal: ambiguous argument`

リポジトリのデフォルトブランチが、ジョブがトリガーされたブランチと無関係である場合、パイプラインシークレット検出が`ERR fatal: ambiguous argument`エラーで失敗する可能性があります。詳細については、イシュー[!352014](https://gitlab.com/gitlab-org/gitlab/-/issues/352014)を参照してください。

問題を解決するには、リポジトリで[デフォルトブランチを正しく設定](../../../project/repository/branches/default.md#change-the-default-branch-name-for-a-project)してください。`secret-detection`ジョブを実行するブランチと関連する履歴を持つブランチに設定する必要があります。

#### ジョブログの`exec /bin/sh: exec format error`メッセージ

GitLabパイプラインシークレット検出アナライザーは、 `amd64`CPUアーキテクチャでの実行[のみサポートしています。](#enable-the-analyzer)このメッセージは、ジョブが`arm`などの異なるアーキテクチャで実行されていることを示しています。

#### エラー: `fatal: detected dubious ownership in repository at '/builds/<project dir>'`

シークレット検出が終了ステータス128で失敗する可能性があります。これは、Dockerイメージのユーザーへの変更が原因であることがあります。

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

## 警告

### 流出したシークレットに対応する

シークレットが検出された場合は、直ちにローテーションする必要があります。GitLabは、一部のタイプの流出したシークレットを[自動的に失効](../automatic_response.md)しようとします。自動的に失効しないものについては、手動で失効させる必要があります。

[リポジトリの履歴からシークレットをパージする](../../../project/repository/repository_size.md#purge-files-from-repository-history)だけでは、リークに完全に対応できません。元のシークレットは、リポジトリの既存のフォークまたはクローンにすべて残ります。

<!-- markdownlint-enable MD025 -->
