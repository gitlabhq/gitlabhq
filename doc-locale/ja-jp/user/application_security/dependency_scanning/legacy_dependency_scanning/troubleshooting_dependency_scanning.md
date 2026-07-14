---
stage: Application Security Testing
group: Composition Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 依存関係スキャンのトラブルシューティング
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

依存関係スキャンを使用する際に、次のイシューが発生する可能性があります。

## デバッグレベルのログを生成する {#debug-level-logging}

デバッグレベルでログを生成しておくと、トラブルシューティングに役立ちます。詳細については、[デバッグレベルのログを生成する](../../troubleshooting_application_security.md#turn-on-debug-level-logging)を参照してください。

## ローカル環境でアナライザーを実行する {#run-the-analyzer-in-a-local-environment}

依存関係スキャンアナライザーをローカルで実行して、パイプラインを実行せずに問題のデバッグや動作の検証を行うことができます。

例: Pythonアナライザーを実行するには:

```shell
cd project-git-repository

docker run \
   --interactive --tty --rm \
   --volume "$PWD":/tmp/app \
   --env CI_PROJECT_DIR=/tmp/app \
   --env SECURE_LOG_LEVEL=debug \
   -w /tmp/app \
   registry.gitlab.com/security-products/gemnasium-python:5 /analyzer run
```

このコマンドは、デバッグレベルのロギングでアナライザーを実行し、ローカルリポジトリをマウントして依存関係を分析します。`registry.gitlab.com/security-products/gemnasium-python:5`を、プロジェクトの言語とパッケージマネージャーに適したスキャナーの`image:tag`の組み合わせに置き換えることができます。

### 特定の言語またはパッケージマネージャーのサポート不足を回避する {#working-around-missing-support-for-certain-languages-or-package-managers}

[Supported languages](_index.md#supported-languages-and-package-managers)に記載されているように、一部の依存関係定義ファイルはまだサポートされていません。ただし、言語、パッケージマネージャー、またはサードパーティツールが定義ファイルをサポートされている形式に変換できれば、依存関係スキャンを実現できます。

一般的なアプローチは次のとおりです:

1. `.gitlab-ci.yml`ファイルで専用のコンバータージョブを定義します。変換を容易にするために、適切なDockerイメージ、スクリプト、またはその両方を使用します。
1. そのジョブに変換されたサポートファイルをアーティファクトとしてアップロードさせます。
1. 変換された定義ファイルを使用するために、[`dependencies: [<your-converter-job>]`](../../../../ci/yaml/_index.md#dependencies)を`dependency_scanning`ジョブに追加します。

例えば、`pyproject.toml`ファイルのみを持つPoetryプロジェクトは、次のように`poetry.lock`ファイルを生成できます。

```yaml
include:
  - template: Jobs/Dependency-Scanning.gitlab-ci.yml

stages:
  - test

gemnasium-python-dependency_scanning:
  # Work around https://gitlab.com/gitlab-org/gitlab/-/issues/32774
  before_script:
    - pip install "poetry>=1,<2"  # Or via another method: https://python-poetry.org/docs/#installation
    - poetry update --lock # Generates the lockfile to be analyzed.
```

## 依存関係スキャンジョブが予期せず実行されている {#dependency-scanning-jobs-are-running-unexpectedly}

The [dependency scanning CI template](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Jobs/Dependency-Scanning.gitlab-ci.yml)は、[`rules:exists`](../../../../ci/yaml/_index.md#rulesexists)構文を使用します。このディレクティブは10000回のチェックに制限されており、この数に達すると常に`true`を返します。このため、リポジトリ内のファイルの数によっては、スキャナーがプロジェクトをサポートしていなくても、依存関係スキャンジョブがトリガーされる場合があります。この制限の詳細については、[`rules:exists` documentation](../../../../ci/yaml/_index.md#rulesexists)を参照してください。

## エラー: `dependency_scanning is used for configuration only, and its script should not be executed` {#error-dependency_scanning-is-used-for-configuration-only-and-its-script-should-not-be-executed}

詳細については、[application security testing troubleshooting](../../troubleshooting_application_security.md#error-job-is-used-for-configuration-only-and-its-script-should-not-be-executed)を参照してください。

## Javaベースのプロジェクトで複数の証明書をインポートする {#import-multiple-certificates-for-java-based-projects}

`gemnasium-maven`アナライザーは、`keytool`を使用して`ADDITIONAL_CA_CERT_BUNDLE`変数の内容を読み取ります。これは、単一の証明書または証明書チェーンをインポートします。複数の無関係な証明書は無視され、最初のものだけが`keytool`によってインポートされます。

複数の無関係な証明書をアナライザーに追加するには、`gemnasium-maven-dependency_scanning`ジョブの定義で、次のような`before_script`を宣言します:

```yaml
gemnasium-maven-dependency_scanning:
  before_script:
    - . $HOME/.bashrc # make the java tools available to the script
    - OIFS="$IFS"; IFS=""; echo $ADDITIONAL_CA_CERT_BUNDLE > multi.pem; IFS="$OIFS" # write ADDITIONAL_CA_CERT_BUNDLE variable to a PEM file
    - csplit -z --digits=2 --prefix=cert multi.pem "/-----END CERTIFICATE-----/+1" "{*}" # split the file into individual certificates
    - for i in `ls cert*`; do keytool -v -importcert -alias "custom-cert-$i" -file $i -trustcacerts -noprompt -storepass changeit -keystore /opt/asdf/installs/java/adoptopenjdk-11.0.7+10.1/lib/security/cacerts 1>/dev/null 2>&1 || true; done # import each certificate using keytool (note the keystore location is related to the Java version being used and should be changed accordingly for other versions)
    - unset ADDITIONAL_CA_CERT_BUNDLE # unset the variable so that the analyzer doesn't duplicate the import
```

## 依存関係スキャンジョブが`strconv.ParseUint: parsing "0.0": invalid syntax`メッセージで失敗する {#dependency-scanning-job-fails-with-message-strconvparseuint-parsing-00-invalid-syntax}

Docker-in-Dockerはサポートされておらず、これを実行することがこのエラーの主な原因と考えられます。

このエラーを修正するには、依存関係スキャンのためにDocker-in-Dockerを無効にします。CI/CDパイプラインで実行される各アナライザーに対して、個別の`<analyzer-name>-dependency_scanning`ジョブが作成されます。

```yaml
include:
  - template: Dependency-Scanning.gitlab-ci.yml

variables:
  DS_DISABLE_DIND: "true"
```

## メッセージ`<file> does not exist in <commit SHA>` {#message-file-does-not-exist-in-commit-sha}

ファイル内の依存関係の`Location`が表示されると、リンク内のパスは特定のGit SHAを指します。

しかし、依存関係スキャンツールがレビューしたロックファイルがキャッシュされている場合、そのリンクを選択すると、リポジトリのルートにリダイレクトされ、`<file> does not exist in <commit SHA>`というメッセージが表示されます。

ロックファイルはビルドフェーズ中にキャッシュされ、スキャンが実行される前に依存関係スキャンジョブに渡されます。キャッシュはアナライザーの実行前にダウンロードされるため、`CI_BUILDS_DIR`ディレクトリ内にロックファイルが存在すると、依存関係スキャンジョブがトリガーされます。

この警告を防ぐには、ロックファイルをコミットする必要があります。

## `DS_MAJOR_VERSION`または`DS_ANALYZER_IMAGE`を設定した後、最新のDockerイメージが取得されない {#you-no-longer-get-the-latest-docker-image-after-setting-ds_major_version-or-ds_analyzer_image}

特定の理由で`DS_MAJOR_VERSION`または`DS_ANALYZER_IMAGE`を手動で設定し、アナライザーの最新のパッチ適用済みバージョンを再び取得するために設定を更新する必要がある場合は、`.gitlab-ci.yml`ファイルを編集して、次のいずれかを行います:

- `DS_MAJOR_VERSION`を、[dependency scanning template](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Jobs/Dependency-Scanning.gitlab-ci.yml#L17)で参照されているバージョンと一致するように設定します。
- `DS_ANALYZER_IMAGE`変数を直接ハードコードする場合は、[dependency scanning template](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Jobs/Dependency-Scanning.gitlab-ci.yml)にある最新の行と一致するように変更します。行番号は、編集したスキャンジョブによって異なります。

  例えば、`gemnasium-maven-dependency_scanning`ジョブは`DS_ANALYZER_IMAGE`が`"$SECURE_ANALYZERS_PREFIX/gemnasium-maven:$DS_MAJOR_VERSION"`に設定されているため、最新の`gemnasium-maven` Dockerイメージをプルします。

## setuptoolsプロジェクトの依存関係スキャンが`use_2to3 is invalid`エラーで失敗する {#dependency-scanning-of-setuptools-project-fails-with-use_2to3-is-invalid-error}

`setuptools`バージョン`v58.0.0`で、[2to3](https://docs.python.org/3/library/2to3.html)のサポートが[削除](https://setuptools.pypa.io/en/latest/history.html#v58-0-0)されました。依存関係スキャン（`python 3.9`の実行）は、`2to3`をサポートしない`setuptools`バージョン`58.1.0+`を使用します。したがって、`lib2to3`に依存する`setuptools`依存関係は、次のメッセージで失敗します:

```plaintext
error in <dependency name> setup command: use_2to3 is invalid
```

このエラーを回避するには、アナライザーの`setuptools`のバージョンをダウングレードします（例: `v57.5.0`）:

```yaml
gemnasium-python-dependency_scanning:
  before_script:
    - pip install setuptools==57.5.0
```

## psycopg2を使用するプロジェクトの依存関係スキャンが`pg_config executable not found`エラーで失敗する {#dependency-scanning-of-projects-using-psycopg2-fails-with-pg_config-executable-not-found-error}

`psycopg2`に依存するPythonプロジェクトのスキャンは、次のメッセージで失敗する可能性があります:

```plaintext
Error: pg_config executable not found.
```

[psycopg2](https://pypi.org/project/psycopg2/)は`libpq-dev` Debianパッケージに依存しますが、これは`gemnasium-python` Dockerイメージにはインストールされていません。このエラーを回避するには、`libpq-dev`パッケージを`before_script`にインストールします:

```yaml
gemnasium-python-dependency_scanning:
  before_script:
    - apt-get update && apt-get install -y libpq-dev
```

## `poetry config http-basic`を`CI_JOB_TOKEN`とともに使用するときの`NoSuchOptionException` {#nosuchoptionexception-when-using-poetry-config-http-basic-with-ci_job_token}

このエラーは、自動生成された`CI_JOB_TOKEN`がハイフン（`-`）で始まる場合に発生する可能性があります。このエラーを回避するには、[Poetry's configuration advice](https://python-poetry.org/docs/repositories/#configuring-credentials)に従ってください。

## エラー: プロジェクトに未解決の依存関係があります {#error-project-has-unresolved-dependencies}

次のエラーメッセージは、`build.gradle`または`build.gradle.kts`ファイルによって引き起こされるGradle依存関係解決の問題を示しています:

- `Project has <number> unresolved dependencies` (GitLab 16.7から16.9)
- `project has unresolved dependencies: ["dependency_name:version"]` (GitLab 17.0以降)

GitLab 16.7から16.9では、未解決の依存関係が検出された場合、`gemnasium-maven`は処理を続行できません。

GitLab 17.0以降では、`gemnasium-maven`は`DS_GRADLE_RESOLUTION_POLICY`環境変数をサポートしており、これを使用して未解決の依存関係の処理方法を制御できます。デフォルトでは、未解決の依存関係が検出されると、スキャンは失敗します。ただし、`DS_GRADLE_RESOLUTION_POLICY`環境変数を`"none"`に設定すると、スキャンを続行して部分的な結果を生成できます。

`build.gradle`ファイルを修正するためのガイダンスについては、[Gradle dependency resolution documentation](https://docs.gradle.org/current/userguide/dependency_resolution.html)を参照してください。詳細については、[issue 482650](https://gitlab.com/gitlab-org/gitlab/-/issues/482650)を参照してください。

さらに、Kotlin 2.0.0には依存関係解決に影響する既知のイシューがあり、Kotlin 2.0.20で修正される予定です。詳細については、[this issue](https://github.com/gradle/github-dependency-graph-gradle-plugin/issues/140#issuecomment-2230255380)を参照してください。

## Goプロジェクトをスキャンする際のビルド制約を設定する {#setting-build-constraints-when-scanning-go-projects}

依存関係スキャンは、`linux/amd64`コンテナ内で実行されます。結果として、Goプロジェクト用に生成されたビルドリストには、この環境と互換性のある依存関係が含まれています。デプロイ環境が`linux/amd64`でない場合、最終的な依存関係リストには、追加の互換性のないモジュールが含まれる可能性があります。依存関係リストは、デプロイ環境と互換性のあるモジュールのみを省略する場合もあります。この問題を防止するには、`.gitlab-ci.yml`ファイルの`GOOS`および`GOARCH` [environment variables](https://go.dev/ref/mod#minimal-version-selection)を設定することで、ビルドプロセスがデプロイ環境のオペレーティングシステムとアーキテクチャをターゲットにするように設定できます。

例: 

```yaml
variables:
  GOOS: "darwin"
  GOARCH: "arm64"
```

`GOFLAGS`変数を使用して、ビルドタグ制約を供給することもできます:

```yaml
variables:
  GOFLAGS: "-tags=test_feature"
```

## Goプロジェクトの依存関係スキャンが誤検出を返す {#dependency-scanning-of-go-projects-returns-false-positives}

`go.sum`ファイルには、プロジェクトの[build list](https://go.dev/ref/mod#glos-build-list)を生成する際に考慮されたすべてのモジュールのエントリが含まれています。`go.sum`ファイルにはモジュールの複数のバージョンが含まれていますが、`go build`が使用する[MVS](https://go.dev/ref/mod#minimal-version-selection)アルゴリズムは1つだけを選択します。その結果、依存関係スキャンが`go.sum`を使用すると、誤検出を報告する可能性があります。

誤検出を防ぐために、GemnasiumはGoプロジェクトのビルドリストを生成できない場合にのみ`go.sum`を使用します。`go.sum`が選択されている場合、警告が発生します:

```shell
[WARN] [Gemnasium] [2022-09-14T20:59:38Z] ▶ Selecting "go.sum" parser for "/test-projects/gitlab-shell/go.sum". False positives may occur. See https://gitlab.com/gitlab-org/gitlab/-/issues/321081.
```

## `ssh`を使用しようとするときの`Host key verification failed` {#host-key-verification-failed-when-trying-to-use-ssh}

いずれかの`gemnasium`イメージに`openssh-client`をインストールした後、`ssh`を使用すると`Host key verification failed`メッセージが表示される場合があります。これは、イメージをビルドする際に`$HOME`を`/tmp`に設定したため、セットアップ中に`~`を使用してユーザーディレクトリを表すと発生する可能性があります。このイシューは、[Cloning project over SSH fails when using `gemnasium-python` image](https://gitlab.com/gitlab-org/gitlab/-/issues/374571)で説明されています。`openssh-client`は`/root/.ssh/known_hosts`を見つけることを期待しますが、このパスは存在せず、代わりに`/tmp/.ssh/known_hosts`が存在します。

これは、`openssh-client`がプリインストールされている`gemnasium-python`で解決済みですが、他のイメージに`openssh-client`をゼロからインストールする場合にイシューが発生する可能性があります。これを解決するには、次のいずれかの方法があります:

1. キーとホストを設定する際に、絶対パス（`~/.ssh/known_hosts`の代わりに`/root/.ssh/known_hosts`）を使用します。
1. 関連する`known_hosts`ファイルを指定する`UserKnownHostsFile`を`ssh`設定に追加します（例: `echo 'UserKnownHostsFile /tmp/.ssh/known_hosts' >> /etc/ssh/ssh_config`）。

## `ERROR: THESE PACKAGES DO NOT MATCH THE HASHES FROM THE REQUIREMENTS FILE` {#error-these-packages-do-not-match-the-hashes-from-the-requirements-file}

このエラーは、`requirements.txt`ファイル内のパッケージのハッシュが、ダウンロードされたパッケージのハッシュと一致しない場合に発生します。セキュリティ対策として、`pip`はパッケージが改ざんされたとみなし、インストールを拒否します。これを修正するには、要件ファイルに含まれるハッシュが正しいことを確認します。[`pip-compile`](https://pip-tools.readthedocs.io/en/stable/)で生成された要件ファイルの場合は、`pip-compile --generate-hashes`を実行してハッシュが最新であることを確認します。[`pipenv`](https://pipenv.pypa.io/)で生成された`Pipfile.lock`を使用している場合は、`pipenv verify`を実行して、ロックファイルに最新のパッケージハッシュが含まれていることを確認します。

## `ERROR: In --require-hashes mode, all requirements must have their versions pinned with ==` {#error-in---require-hashes-mode-all-requirements-must-have-their-versions-pinned-with-}

このエラーは、要件ファイルがRunnerが使用するプラットフォームとは異なるプラットフォームで生成された場合に発生します。他のプラットフォームをターゲットにするためのサポートは、[issue 416376](https://gitlab.com/gitlab-org/gitlab/-/issues/416376)で追跡されています。

## 編集可能なフラグがPythonの依存関係スキャンをハングさせる可能性がある {#editable-flags-can-cause-dependency-scanning-for-python-to-hang}

`requirements.txt`ファイルで[`-e/--editable`](https://pip.pypa.io/en/stable/cli/pip_install/#install-editable)フラグを使用して現在のディレクトリをターゲットにすると、Gemnasium Python依存関係スキャナーが`pip3 download`を実行するときにハングするイシューが発生する可能性があります。このコマンドは、ターゲットプロジェクトをビルドするために必要です。

このイシューを解決するには、Pythonの依存関係スキャンを実行するときに`-e/--editable`フラグを使用しないでください。

## SBTでのメモリ不足エラーの処理 {#handling-out-of-memory-errors-with-sbt}

Scalaプロジェクトで依存関係スキャンを使用中にSBTでメモリ不足エラーが発生した場合は、[`SBT_CLI_OPTS`](_index.md#analyzer-specific-settings)環境変数を設定することで対処できます。設定例は次のとおりです:

```yaml
variables:
  SBT_CLI_OPTS: "-J-Xmx8192m -J-Xms4192m -J-Xss2M"
```

Kubernetes executorを使用している場合、デフォルトのKubernetesリソース設定を上書きする必要がある場合があります。メモリイシューを防止するためのコンテナリソースの調整方法の詳細については、[Kubernetes executor documentation](https://docs.gitlab.com/runner/executors/kubernetes/#overwrite-container-resources)を参照してください。

## NPMプロジェクトに`package-lock.json`ファイルがない {#no-package-lockjson-file-in-npm-projects}

デフォルトでは、依存関係スキャンジョブは、リポジトリに`package-lock.json`ファイルがある場合にのみ実行されます。しかし、一部のNPMプロジェクトは、Gitリポジトリに格納する代わりに、ビルドプロセス中に`package-lock.json`ファイルを生成します。

これらのプロジェクトで依存関係をスキャンするには:

1. ビルドジョブで`package-lock.json`ファイルを生成します。
1. 生成されたファイルをアーティファクトとして保存します。
1. アーティファクトを使用し、そのルールを調整するように依存関係スキャンジョブを変更します。

例えば、設定は次のようになります:

```yaml
include:
  - template: Dependency-Scanning.gitlab-ci.yml

build:
  script:
    - npm i
  artifacts:
    paths:
      - package-lock.json  # Store the generated package-lock.json as an artifact

gemnasium-dependency_scanning:
  needs: ["build"]
  rules:
    - if: "$DEPENDENCY_SCANNING_DISABLED == 'true' || $DEPENDENCY_SCANNING_DISABLED == '1'"
      when: never
    - if: "$DS_EXCLUDED_ANALYZERS =~ /gemnasium([^-]|$)/"
      when: never
    - if: $CI_COMMIT_BRANCH && $GITLAB_FEATURES =~ /\bdependency_scanning\b/ && $CI_GITLAB_FIPS_MODE == "true"
      variables:
        DS_IMAGE_SUFFIX: "-fips"
        DS_REMEDIATE: 'false'
    - if: "$CI_COMMIT_BRANCH && $GITLAB_FEATURES =~ /\\bdependency_scanning\\b/"
```

## パイプラインに依存関係スキャンジョブが追加されない {#no-dependency-scanning-job-added-to-the-pipeline}

依存関係スキャンジョブは、依存関係のあるロックファイルまたはビルドツール関連ファイルが存在するかどうかを確認するルールを使用します。これらのファイルが検出されない場合、パイプライン内の別のジョブによってロックファイルが生成されていても、そのジョブはパイプラインに追加されません。

この状況が発生した場合は、リポジトリに[supported file](https://gitlab.com/gitlab-org/security-products/analyzers/dependency-scanning#supported-files)、またはサポートされているファイルがランタイムで生成されることを示すファイルが含まれていることを確認してください。そのようなファイルをリポジトリに追加して、依存関係スキャンジョブをトリガーできるかどうかを検討してください。

リポジトリにそのようなファイルが含まれており、ジョブがまだトリガーされないと思われる場合は、次の情報とともに[open an issue](https://gitlab.com/gitlab-org/gitlab/-/issues/new)してください:

- 使用している言語とビルドツール。
- 提供するロックファイルの種類と、それがどこで生成されるか。

[dependency scanning template](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Jobs/Dependency-Scanning.latest.gitlab-ci.yml#L269-270)に直接コントリビュートすることもできます。

## 依存関係スキャンが`gradlew: permission denied`で失敗する {#dependency-scanning-fails-with-gradlew-permission-denied}

`gradlew`での`permission denied`エラーは、通常、`gradlew`が実行可能ビットが設定されていない状態でリポジトリにチェックインされたことを示します。エラーは、ジョブに次のメッセージとともに表示される場合があります:

```plaintext
[FATA] [gemnasium-maven] [2024-11-14T21:55:59Z] [/go/src/app/cmd/gemnasium-maven/main.go:65] ▶ fork/exec /builds/path/to/gradlew: permission denied
```

`chmod +ux gradlew`をローカルで実行し、Gitリポジトリにプッシュして、ファイルを実行可能にします。

## サポートされていないGradleバージョンのため、依存関係スキャンのnebulaロック作成が失敗する {#dependency-scanning-nebula-lock-creation-fails-due-to-unsupported-gradle-version}

サポートされていないGradleバージョン（9.0以上）で[dependency.lockfiles](../dependency_scanning_sbom/_index.md#dependency-lock-plugin)を作成しようとすると、次のエラーが発生します:

```plaintext
FAILURE: Build failed with an exception.
* Where:
Initialization script '/builds/gitlab-org/app/app/nebula.gradle' line: 11
* What went wrong:
Failed to notify build listener.
> org/gradle/util/NameMatcher
```

gradleビルドをGradle 8.10.2にダウングレードしてみてください。

## 依存関係スキャンスキャナーが`Gemnasium`ではなくなった {#dependency-scanning-scanner-is-no-longer-gemnasium}

過去には、依存関係スキャンで使用されるスキャナーは`Gemnasium`であり、これはユーザーが[vulnerability page](../../vulnerabilities/_index.md)で見ることができるものです。

[SBOMを使用した依存関係スキャン](../dependency_scanning_sbom/_index.md)の展開により、`Gemnasium`スキャナーは組み込みの`GitLab SBoM Vulnerability Scanner`に置き換えられます。この新しいスキャナーは、CI/CDジョブではなく、GitLabプラットフォーム内で実行されます。2つのスキャナーは同じ結果を提供すると予想されますが、SBOMスキャンは既存の依存関係スキャンCI/CDジョブの後に発生するため、既存の脆弱性は、新しい`GitLab SBoM Vulnerability Scanner`でスキャナーの値が更新されます。

`GitLab SBoM Vulnerability Scanner`は、GitLab組み込みの依存関係スキャン機能の唯一の期待される値です。

## 最新のSBOMに基づいてプロジェクトの依存関係リストが更新されない {#dependency-list-for-project-not-being-updated-based-on-latest-sbom}

パイプラインにSBOMを生成する失敗したジョブがある場合、`DeleteNotPresentOccurrencesService`は実行されず、依存関係リストの変更または更新が妨げられます。これは、SBOMをアップロードする他の成功したジョブがあり、パイプライン全体が成功している場合でも発生する可能性があります。これは、関連するセキュリティスキャンジョブが失敗した場合に、依存関係リストから依存関係が誤って削除されるのを防ぐように設計されています。プロジェクトの依存関係リストが期待どおりに更新されない場合は、パイプラインで失敗した可能性のあるSBOM関連のジョブを確認し、それらを修正または削除してください。

## 依存関係スキャンが`open /etc/ssl/certs/ca-certificates.crt: permission denied`で失敗する {#dependency-scanning-fails-with-open-etcsslcertsca-certificatescrt-permission-denied}

このエラーは、通常、コンテナを実行しているユーザーが`root`グループに属していないことを示します。`id`を実行して、ユーザーがグループに属していることを確認します。

```shell
$ id
uid=1000(node) gid=0(root) groups=0(root),1000(node)
```

OpenShiftを実行している場合、またはKubernetes executorを使用している場合は、RunnerがグループID（GID）0を使用して実行するように設定されていることを確認してください。

```toml
[[runners]]
[runners.kubernetes]
    [runners.kubernetes.pod_security_context]
    run_as_non_root = true
    run_as_group = 0
```

## カスタムまたはマージされたCycloneDX SBOMに対して脆弱性スキャンが結果を生成しない {#vulnerability-scanning-produces-no-results-for-custom-or-merged-cyclonedx-sboms}

依存関係スキャンCI/CDジョブは成功し、SBOMコンポーネントは依存関係リストに表示されますが、パイプラインのセキュリティータブには脆弱性は報告されません。

GitLab 18.10以降では、セキュリティータブに次のメッセージが表示されます: 「SBOMレポートには、脆弱性スキャンに必要なGitLabメタデータプロパティが不足しています。」

このイシューは、SBOMに必要な[GitLab CycloneDX properties](../../../../development/sec/cyclonedx_property_taxonomy.md)が不足している場合に発生します。これらのプロパティがないと、脆弱性スキャナーはSBOMのコンポーネントの検出結果を構築できません。依存関係リストはまだ入力された状態ですが、脆弱性は報告されません。

これは通常、次の場合に発生します:

- 複数のSBOMが`cyclonedx merge`を使用してマージされ、メタデータプロパティが削除される場合。
- サードパーティのSBOMジェネレーターがGitLab固有のプロパティを含んでいない場合。
- `metadata.properties`から`gitlab:meta:schema_version`プロパティ（`1`である必要があります）が不足している場合。

### 脆弱性スキャンに必要なプロパティ {#required-properties-for-vulnerability-scanning}

| プロパティ | 場所 | 説明 |
|---|---|---|
| `gitlab:meta:schema_version` | `metadata.properties` | `1`に設定する必要があります。 |
| `gitlab:dependency_scanning:input_file:path` | `metadata.properties`または各コンポーネントの`properties` | 依存関係を生成するために分析されたロックファイルへのパス。どちらも存在しない場合、これらのコンポーネントに対して脆弱性の検出結果は生成されません。GitLab 18.10以降では、パイプラインのセキュリティータブにエラーが表示されます。 |

この問題を解決するには、次のいずれかのアプローチを選択してください:

- 各SBOMを個別にアップロードします。

  マージする代わりに、各SBOMを個別の[`artifacts: reports: cyclonedx:`](../../../../ci/yaml/artifacts_reports.md#artifactsreportscyclonedx)エントリとしてアップロードします。これにより、各ファイル内のGitLab固有のプロパティが保持されます。
- サードパーティのSBOMにプロパティを追加します。

  サードパーティツールによって生成されたSBOMには、通常、GitLab固有のプロパティは含まれていません。脆弱性スキャンを有効にするには、SBOMに`metadata.properties`に次のものが含まれていることを確認してください:

  - `gitlab:meta:schema_version`が`1`に設定されていること
  - `gitlab:dependency_scanning:input_file:path`がロックファイルのリポジトリ相対パスに設定されていること（例: `package-lock.json`または`src/Gemfile.lock`）

  SBOMに複数のロックファイルからのコンポーネントが含まれている場合は、各コンポーネントが正しいソースファイルを指すように、メタデータ内ではなく、各コンポーネントの`properties`配列に個別に`input_file:path`を設定します。サポートされているプロパティの完全なリストについては、[GitLab CycloneDX property taxonomy](../../../../development/sec/cyclonedx_property_taxonomy.md)を参照してください。

詳細については、[イシュー542813](https://gitlab.com/gitlab-org/gitlab/-/work_items/542813)と[マージリクエスト221549](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/221549)を参照してください。

## 脆弱性スキャンがすべての依存関係に対して誤った入力ファイルを表示する {#vulnerability-scanning-shows-wrong-input-file-for-all-dependencies}

脆弱性レポートまたは依存関係リスト内のすべての依存関係は、異なるロックファイルから発生しているにもかかわらず、同じ入力ファイルパスを示しています。

このイシューは、`gitlab:dependency_scanning:input_file:path`プロパティがコンポーネントごとではなく`metadata.properties`に設定されている場合に発生します。[property taxonomy](../../../../development/sec/cyclonedx_property_taxonomy.md)によると、メタデータレベルのプロパティはドキュメント内のすべてのオブジェクトに適用されるため、単一の値がすべてのコンポーネントを上書きします。

このイシューを解決するには、トップレベルのメタデータ内ではなく、各コンポーネントの`properties`配列に個別に`input_file:path`を設定します。`input_file:path`プロパティは、異なるロックファイルからのコンポーネントを含むマージされたSBOMにとって特に重要です。

## エラー: `node with package name <package_name> does not exist` {#error-node-with-package-name-package_name-does-not-exist}

このイシューは、パッケージマネージャー（通常はnuget）がパッケージを見つけられない場合に発生します。これは、アプリケーションのビルドに使用されたイメージが、依存関係スキャンの実行に使用されたイメージと異なるために発生する可能性があります。

このイシューを解決するには、依存関係スキャナーがアプリケーションをビルドするために使用するのと同じ.NET SDKイメージを使用してください。正確なイメージは、次を実行して見つけることができます:

```shell
curl --silent "https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium/-/raw/master/build/gemnasium/alpine/Dockerfile" | grep "vrange-nuget-build" | grep "FROM"
```

上記のDockerfileで現在のイメージバージョンを確認してください。
