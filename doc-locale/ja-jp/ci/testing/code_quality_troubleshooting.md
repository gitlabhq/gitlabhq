---
stage: Application Security Testing
group: Static Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Code Qualityのトラブルシューティング
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

Code Qualityを使用する際に、次のイシューが発生する可能性があります。

## コードが見つからず、パイプラインが常にデフォルトの設定で実行される {#the-code-cannot-be-found-and-the-pipeline-runs-always-with-default-configuration}

プライベートRunnerとDocker-in-Dockerソケットバインディング設定を使用している可能性があります。Code Qualityチェックをワーカーで実行するように設定する必要があります。[プライベートRunnerの使用](code_quality_codeclimate_scanning.md#use-private-runners)にドキュメントされているとおりです。

## デフォルトの設定を変更しても効果がない {#changing-the-default-configuration-has-no-effect}

一般的なイシューは、`Code Quality`（GitLab固有）と`Code Climate`（GitLabが使用するエンジン）という用語が非常によく似ていることです。デフォルトの設定を変更するには、`.codequality.yml`ファイルではなく、**`.codeclimate.yml`** ファイルを追加する必要があります。間違ったファイル名を使用すると、[デフォルトの`.codeclimate.yml`](https://gitlab.com/gitlab-org/ci-cd/codequality/-/blob/master/codeclimate_defaults/.codeclimate.yml.template)が引き続き使用されます。

## Code Qualityレポートがマージリクエストに表示されない {#no-code-quality-report-is-displayed-in-a-merge-request}

マージリクエストでの比較のために、ソースブランチまたはターゲットブランチからのCode Qualityレポートが欠落している場合があり、情報が表示されないことがあります。

ソースブランチでのレポートの欠落は、次の原因が考えられます:

1. [`REPORT_STDOUT`環境変数](https://gitlab.com/gitlab-org/ci-cd/codequality#environment-variables)の使用により、レポートファイルが生成されず、マージリクエストに何も表示されません。

ターゲットブランチでのレポートの欠落は、次の原因が考えられます:

- あなたの`.gitlab-ci.yml`に新しく追加されたCode Qualityジョブ。
- あなたのパイプラインが、ターゲットブランチでCode Qualityジョブを実行するように設定されていません。
- Code Qualityジョブを実行しないコミットがデフォルトブランチに対して行われました。
- [`artifacts:expire_in`](../yaml/_index.md#artifactsexpire_in) CI/CD設定により、Code Qualityアーティファクトが意図したよりも早く期限切れになることがあります。

[マージリクエストAPI](../../api/merge_requests.md#retrieve-a-merge-request)を使用して`base_sha`を取得し、ベースコミットにレポートが存在することを確認し、[`sha`属性を持つパイプラインAPI](../../api/pipelines.md#list-project-pipelines)を使用してパイプラインが実行されたかを確認します。

## 変更ビューにCode Qualityシンボルがない {#no-code-quality-symbol-in-the-changes-view}

[変更ビュー](code_quality.md#merge-request-changes-view)にシンボルが表示されない場合は、コード品質レポート内の`location.path`が次のようになっていることを確認してください:

- コード品質違反を含むファイルへの相対パスを使用していること。
- `./`でプレフィックスが付いていないこと。例えば、`path`は`./somedir/file1.rb`ではなく`somedir/file1.rb`である必要があります。

## 複数のCode Qualityレポートが定義されているのに、1つしか表示されない {#only-a-single-code-quality-report-is-displayed-but-more-are-defined}

Code Qualityは複数のレポートを自動的に[結合](code_quality.md#scan-code-for-quality-violations)します。

## RuboCopエラー {#rubocop-errors}

RubyプロジェクトでCode Qualityジョブを使用している場合、RuboCopの実行で問題が発生する可能性があります。例えば、非常に新しいバージョンまたは非常に古いRubyのバージョンを使用している場合に、次のエラーが表示されることがあります:

```plaintext
/usr/local/bundle/gems/rubocop-0.52.1/lib/rubocop/config.rb:510:in `check_target_ruby':
Unknown Ruby version 2.7 found in `.ruby-version`. (RuboCop::ValidationError)
Supported versions: 2.1, 2.2, 2.3, 2.4, 2.5
```

これは、チェックエンジンで使用されるRuboCopのデフォルトバージョンが、使用中のRubyバージョンのサポートをカバーしていないことが原因です。

プロジェクトで使用されているRubyのバージョンを[サポートする](https://docs.rubocop.org/rubocop/compatibility.html#support-matrix)カスタムバージョンのRuboCopを使用するには、プロジェクトリポジトリに作成された[`.codeclimate.yml`ファイル](https://docs.codeclimate.com/docs/rubocop#using-rubocops-newer-versions)を通じて設定を上書きできます。

例えば、RuboCopリリース**0.67**を使用することを指定するには:

```yaml
version: "2"
plugins:
  rubocop:
    enabled: true
    channel: rubocop-0-67
```

## カスタムツールを使用しているときにCode Qualityがマージリクエストに表示されない {#no-code-quality-appears-on-merge-requests-when-using-custom-tool}

カスタムツールを使用しているときに、マージリクエストにCode Qualityの変更が表示されない場合は、JSON内の行プロパティが*すべて* `integer`であることを確認してください。

## エラー: `Could not analyze code quality` {#error-could-not-analyze-code-quality}

次のエラーが表示されることがあります:

```shell
error: (CC::CLI::Analyze::EngineFailure) engine pmd ran for 900 seconds and was killed
Could not analyze code quality for the repository at /code
```

Code Climateプラグインのいずれかを有効にしていて、Code Quality CI/CDジョブがこのエラーメッセージで失敗する場合、ジョブの実行がデフォルトの900秒のタイムアウトを超えている可能性があります:

この問題を回避策するために、`.gitlab-ci.yml`ファイルで`TIMEOUT_SECONDS`をより高い値に設定してください。

例: 

```yaml
code_quality:
  variables:
    TIMEOUT_SECONDS: 3600
```

## KubernetesまたはOpenShift RunnerでCode Qualityを使用する {#using-code-quality-with-a-kubernetes-or-openshift-runner}

CodeClimateベースのスキャンには特別な要件があります。スキャンが正常に機能する前に、[KubernetesまたはOpenShift RunnerをCodeClimateベースのスキャン用に設定](code_quality_codeclimate_scanning.md#configure-kubernetes-or-openshift-runners)する必要がある場合があります。

## エラー: `x509: certificate signed by unknown authority` {#error-x509-certificate-signed-by-unknown-authority}

`CODE_QUALITY_IMAGE`を、自己署名証明書など、信頼されていないTLS証明書を使用するDockerレジストリでホストされているイメージに設定すると、次のエラーが表示されることがあります:

```shell
$ docker pull --quiet "$CODE_QUALITY_IMAGE"
Error response from daemon: Get https://gitlab.example.com/v2/: x509: certificate signed by unknown authority
```

これを修正するには、証明書を`/etc/docker/certs.d`ディレクトリ内に配置して、Dockerデーモンが[証明書を信頼](https://distribution.github.io/distribution/about/insecure/#use-self-signed-certificates)するように設定してください。

このDockerデーモンは、[GitLab Code Qualityテンプレート](https://gitlab.com/gitlab-org/gitlab/-/blob/v13.8.3-ee/lib/gitlab/ci/templates/Jobs/Code-Quality.gitlab-ci.yml#L41)内の後続のCode Quality Dockerコンテナに公開され、証明書設定を適用したい他のコンテナにも公開される必要があります。

### Docker {#docker}

GitLab Runnerの設定にアクセスできる場合は、ディレクトリを[ボリュームマウント](https://docs.gitlab.com/runner/configuration/advanced-configuration/#volumes-in-the-runnersdocker-section)として追加します。

`gitlab.example.com`をレジストリの実際のドメインに置き換えます。

例: 

```toml
[[runners]]
  ...
  executor = "docker"
  [runners.docker]
    ...
    privileged = true
    volumes = ["/cache", "/etc/gitlab-runner/certs/gitlab.example.com.crt:/etc/docker/certs.d/gitlab.example.com/ca.crt:ro"]
```

### Kubernetes {#kubernetes}

GitLab Runnerの設定とKubernetesクラスターにアクセスできる場合は、[ConfigMapをマウント](https://docs.gitlab.com/runner/executors/kubernetes/#configmap-volume)できます。

`gitlab.example.com`をレジストリの実際のドメインに置き換えます。

1. 証明書を含むConfigMapを作成します:

   ```shell
   kubectl create configmap registry-crt --namespace gitlab-runner --from-file /etc/gitlab-runner/certs/gitlab.example.com.crt
   ```

1. GitLab Runnerの`config.toml`を更新してConfigMapを指定します:

   ```toml
   [[runners]]
     ...
     executor = "kubernetes"
     [runners.kubernetes]
       image = "alpine:3.12"
       privileged = true
       [[runners.kubernetes.volumes.config_map]]
         name = "registry-crt"
         mount_path = "/etc/docker/certs.d/gitlab.example.com/ca.crt"
         sub_path = "gitlab.example.com.crt"
   ```

## Code Qualityレポートの読み込みに失敗しました {#failed-to-load-code-quality-report}

アーティファクトファイルからのデータ解析にイシューがある場合、Code Qualityレポートの読み込みが失敗することがあります。エラーに関するインサイトを得るには、次の手順でGraphQLクエリを実行できます:

1. パイプラインの詳細ページに移動します。
1. URLに`.json`を追加します。
1. パイプラインの`iid`をコピーします。
1. [インタラクティブGraphQLエクスプローラー](../../api/graphql/_index.md#interactive-graphql-explorer)に移動します。
1. 次のクエリを実行します。

   ```graphql
   {
     project(fullPath: "<fullpath-to-your-project>") {
       pipeline(iid: "<iid>") {
         codeQualityReports {
           count
           nodes {
             line
             description
             path
             fingerprint
             severity
           }
           pageInfo {
             hasNextPage
             hasPreviousPage
             startCursor
             endCursor
           }
         }
       }
     }
   }
   ```

## レポートアーティファクトが作成されない {#no-report-artifact-is-created}

特定のRunner設定では、Code Qualityスキャンジョブがソースコードにアクセスできない場合があります。この場合、`gl-code-quality-report.json`アーティファクトは作成されません。

このイシューを解決するには、次のいずれかの操作を行います:

- Dockerソケットバインディングではなく特権モードを使用する、[Docker-in-DockerのドキュメントされたRunner設定](../docker/using_docker_build.md#use-docker-in-docker)を使用します。
- Dockerソケットバインディングの使用を継続したい場合は、[イシュー32027でのコミュニティによる回避策](https://gitlab.com/gitlab-org/gitlab/-/issues/32027#note_1318822628)を適用します。

詳細については、[Runner設定の変更](code_quality_codeclimate_scanning.md#change-runner-configuration)を参照してください。
