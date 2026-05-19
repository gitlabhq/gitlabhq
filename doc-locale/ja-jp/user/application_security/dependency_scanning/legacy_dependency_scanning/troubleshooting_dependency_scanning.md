---
stage: Application Security Testing
group: Composition Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: 依存関係スキャンのトラブルシューティング
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

依存関係スキャンを使用していると、次の問題が発生することがあります。

## デバッグレベルのログを生成する {#debug-level-logging}

デバッグレベルでログを生成しておくと、トラブルシューティングに役立ちます。詳細については、[デバッグレベルのログを生成する](../troubleshooting_application_security.md#debug-level-logging)を参照してください。

## ローカル環境でアナライザーを実行する {#run-the-analyzer-in-a-local-environment}

パイプラインを実行せずに問題をデバッグしたり、動作を確認したりするために、ローカルで依存関係スキャンアナライザーを実行できます。

たとえば、Pythonアナライザーを実行するには、次のようにします:

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

このコマンドは、デバッグレベルのロギングでアナライザーを実行し、ローカルリポジトリをマウントして依存関係を分析します。プロジェクトの言語および依存関係マネージャーに適したスキャナーの`registry.gitlab.com/security-products/gemnasium-python:5``image:tag`の組み合わせに置き換えることができます。

### 特定の言語またはパッケージマネージャーのサポートがない場合の回避策 {#working-around-missing-support-for-certain-languages-or-package-managers}

[サポートされている言語](_index.md#supported-languages-and-package-managers)に記載されているように、一部の依存関係定義ファイルはまだサポートされていません。ただし、言語、パッケージマネージャー、またはサードパーティツールが定義ファイルをサポートされている形式に変換できる場合は、依存関係スキャンを実現できます。

一般に、アプローチは次のとおりです:

1. `.gitlab-ci.yml`ファイルに専用のコンバータージョブを定義します。適切なDockerイメージ、スクリプト、またはその両方を使用して、変換を容易にします。
1. そのジョブに、変換されたサポート対象ファイルをアーティファクトとしてアップロードさせます。
1. 変換された定義ファイルを利用するには、`dependency_scanning`ジョブに[`dependencies: [<your-converter-job>]`](../../../ci/yaml/_index.md#dependencies)を追加します。

たとえば、`pyproject.toml`ファイルのみを持つPoetryプロジェクトでは、次のように`poetry.lock`ファイルを生成できます。

```yaml
include:
  - template: Jobs/Dependency-Scanning.gitlab-ci.yml

stages:
  - test

gemnasium-python-dependency_scanning:
  # Work around https://gitlab.com/gitlab-org/gitlab/-/issues/32774
  before_script:
    - pip install "poetry>=1,<2"  # Or via another method: https://python-poetry.org/docs/#installation
    - poetry update --lock # Generates the lock file to be analyzed.
```

## 依存関係スキャンジョブが予期せずに実行されている {#dependency-scanning-jobs-are-running-unexpectedly}

[依存関係スキャンCIテンプレート](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Jobs/Dependency-Scanning.gitlab-ci.yml)は、[`rules:exists`](../../../ci/yaml/_index.md#rulesexists)構文を使用します。このディレクティブは10000件のチェックに制限されており、この数に達すると常に`true`を返します。このため、リポジトリ内のファイルの数によっては、スキャナーがプロジェクトをサポートしていなくても、依存関係スキャンジョブがトリガーされる可能性があります。この制限の詳細については、[`rules:exists`ドキュメント](../../../ci/yaml/_index.md#rulesexists)を参照してください。

## エラー: `dependency_scanning is used for configuration only, and its script should not be executed` {#error-dependency_scanning-is-used-for-configuration-only-and-its-script-should-not-be-executed}

詳細については、[アプリケーションセキュリティテストのトラブルシューティング](../troubleshooting_application_security.md#error-job-is-used-for-configuration-only-and-its-script-should-not-be-executed)を参照してください。

## Javaベースのプロジェクトの複数の証明書をインポートする {#import-multiple-certificates-for-java-based-projects}

`gemnasium-maven`アナライザーは、`ADDITIONAL_CA_CERT_BUNDLE`変数のコンテンツを`keytool`を使用して読み取ります。これにより、単一の証明書または証明書チェーンのいずれかがインポートされます。関連のない複数の証明書は無視され、最初の証明書のみが`keytool`によってインポートされます。

アナライザーに複数の無関係な証明書を追加するには、`gemnasium-maven-dependency_scanning`ジョブの定義で、このような`before_script`を宣言できます:

```yaml
gemnasium-maven-dependency_scanning:
  before_script:
    - . $HOME/.bashrc # make the java tools available to the script
    - OIFS="$IFS"; IFS=""; echo $ADDITIONAL_CA_CERT_BUNDLE > multi.pem; IFS="$OIFS" # write ADDITIONAL_CA_CERT_BUNDLE variable to a PEM file
    - csplit -z --digits=2 --prefix=cert multi.pem "/-----END CERTIFICATE-----/+1" "{*}" # split the file into individual certificates
    - for i in `ls cert*`; do keytool -v -importcert -alias "custom-cert-$i" -file $i -trustcacerts -noprompt -storepass changeit -keystore /opt/asdf/installs/java/adoptopenjdk-11.0.7+10.1/lib/security/cacerts 1>/dev/null 2>&1 || true; done # import each certificate using keytool (note the keystore location is related to the Java version being used and should be changed accordingly for other versions)
    - unset ADDITIONAL_CA_CERT_BUNDLE # unset the variable so that the analyzer doesn't duplicate the import
```

## 依存関係スキャンジョブがメッセージ`strconv.ParseUint: parsing "0.0": invalid syntax`で失敗する {#dependency-scanning-job-fails-with-message-strconvparseuint-parsing-00-invalid-syntax}

Docker-in-Dockerはサポートされておらず、それを実行しようとすることが、このエラーの原因である可能性があります。

このエラーを修正するには、依存関係スキャンのDocker-in-Dockerを無効にします。個々の`<analyzer-name>-dependency_scanning`ジョブは、CI/CDパイプラインで実行される各アナライザーに対して作成されます。

```yaml
include:
  - template: Dependency-Scanning.gitlab-ci.yml

variables:
  DS_DISABLE_DIND: "true"
```

## メッセージ`<file> does not exist in <commit SHA>` {#message-file-does-not-exist-in-commit-sha}

ファイル内の依存関係の`Location`が表示されると、リンク内のパスは特定のGit SHAに移動します。

ただし、依存関係スキャンツールがレビューしたロックファイルがキャッシュされている場合は、そのリンクを選択すると、次のメッセージが表示されてリポジトリルートにリダイレクトされます。`<file> does not exist in <commit SHA>`。

ロックファイルはビルドフェーズ中にキャッシュされ、スキャンの前に依存関係スキャンジョブに渡されます。キャッシュはアナライザーの実行前にダウンロードされるため、`CI_BUILDS_DIR`ディレクトリにロックファイルが存在すると、依存関係スキャンジョブがトリガーされます。

この警告を防ぐには、ロックファイルをコミットする必要があります。

## `DS_MAJOR_VERSION`または`DS_ANALYZER_IMAGE`を設定した後、最新のDockerイメージを取得できなくなった {#you-no-longer-get-the-latest-docker-image-after-setting-ds_major_version-or-ds_analyzer_image}

特定の理由で`DS_MAJOR_VERSION`または`DS_ANALYZER_IMAGE`を手動で設定していて、設定を更新してアナライザーの最新のパッチバージョンを再度取得する必要がある場合は、`.gitlab-ci.yml`ファイルを編集して、次のいずれかを実行します:

- [依存関係スキャンテンプレート](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Jobs/Dependency-Scanning.gitlab-ci.yml#L17)で参照されているバージョンと一致するように、`DS_MAJOR_VERSION`を設定します。
- `DS_ANALYZER_IMAGE`変数を直接ハードコードした場合は、[依存関係スキャンテンプレート](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Jobs/Dependency-Scanning.gitlab-ci.yml)にある最新の行と一致するように変更します。行番号は、編集したスキャンジョブによって異なります。

  たとえば、`gemnasium-maven-dependency_scanning`ジョブは、`DS_ANALYZER_IMAGE`が`"$SECURE_ANALYZERS_PREFIX/gemnasium-maven:$DS_MAJOR_VERSION"`に設定されているため、最新の`gemnasium-maven`Dockerイメージをプルします。

## `use_2to3 is invalid`エラーでsetuptoolsプロジェクトの依存関係スキャンが失敗する {#dependency-scanning-of-setuptools-project-fails-with-use_2to3-is-invalid-error}

[2to3](https://docs.python.org/3/library/2to3.html)のサポートは、`setuptools`バージョン`v58.0.0`で[削除](https://setuptools.pypa.io/en/latest/history.html#v58-0-0)されました。依存関係スキャン（`python 3.9`を実行）は、`setuptools`バージョン`58.1.0+`を使用しますが、これは`2to3`をサポートしていません。したがって、`lib2to3`に依存する`setuptools`は、このメッセージで失敗します:

```plaintext
error in <dependency name> setup command: use_2to3 is invalid
```

このエラーを回避するには、アナライザーのバージョンの`setuptools`をダウングレードします（たとえば、`v57.5.0`）:

```yaml
gemnasium-python-dependency_scanning:
  before_script:
    - pip install setuptools==57.5.0
```

## `pg_config executable not found`エラーでpsycopg2を使用するプロジェクトの依存関係スキャンが失敗する {#dependency-scanning-of-projects-using-psycopg2-fails-with-pg_config-executable-not-found-error}

`psycopg2`に依存するPythonプロジェクトをスキャンすると、このメッセージで失敗する可能性があります:

```plaintext
Error: pg_config executable not found.
```

[psycopg2](https://pypi.org/project/psycopg2/)は、`libpq-dev`Debianパッケージに依存しており、これは`gemnasium-python`Dockerイメージにインストールされていません。このエラーを回避するには、`libpq-dev`パッケージを`before_script`にインストールします:

```yaml
gemnasium-python-dependency_scanning:
  before_script:
    - apt-get update && apt-get install -y libpq-dev
```

## `NoSuchOptionException`（`poetry config http-basic`と`CI_JOB_TOKEN`を使用する場合） {#nosuchoptionexception-when-using-poetry-config-http-basic-with-ci_job_token}

このエラーは、自動的に生成された`CI_JOB_TOKEN`がハイフン（`-`）で始まる場合に発生する可能性があります。このエラーを回避するには、[Poetryの設定に関するアドバイス](https://python-poetry.org/docs/repositories/#configuring-credentials)に従ってください。

## エラー：プロジェクトに未解決の依存関係があります {#error-project-has-unresolved-dependencies}

次のエラーメッセージは、`build.gradle`ファイルまたは`build.gradle.kts`ファイルが原因で発生したGradle依存関係の解決の問題を示しています:

- `Project has <number> unresolved dependencies`（GitLab 16.7～16.9）
- `project has unresolved dependencies: ["dependency_name:version"]`（GitLab 17.0以降）

GitLab 16.7〜16.9では、`gemnasium-maven`は、未解決の依存関係が発生した場合、処理を続行できません。

GitLab 17.0以降、`gemnasium-maven`は`DS_GRADLE_RESOLUTION_POLICY`環境変数をサポートしています。これを使用して、未解決の依存関係の処理方法を制御できます。デフォルトでは、未解決の依存関係が発生すると、スキャンは失敗します。ただし、スキャンが続行され、部分的な結果が生成されるようにするには、環境変数`DS_GRADLE_RESOLUTION_POLICY`を`"none"`に設定できます。

`build.gradle`ファイルを修正する方法については、[Gradle依存関係解決ドキュメント](https://docs.gradle.org/current/userguide/dependency_resolution.html)を参照してください。詳細については、[issue 482650](https://gitlab.com/gitlab-org/gitlab/-/issues/482650)を参照してください。

さらに、Kotlin 2.0.0には依存関係の解決に影響を与える既知の問題があり、Kotlin 2.0.20で修正される予定です。詳細については、[このイシュー](https://github.com/gradle/github-dependency-graph-gradle-plugin/issues/140#issuecomment-2230255380)を参照してください。

## Goプロジェクトをスキャンするときにビルド制約を設定する {#setting-build-constraints-when-scanning-go-projects}

依存関係スキャンは、`linux/amd64`コンテナで実行されます。その結果、Go言語プロジェクト用に生成されたビルドリストには、この環境と互換性のある依存関係が含まれています。デプロイ環境が`linux/amd64`でない場合、依存関係の最終リストには、互換性のない追加のモジュールが含まれている可能性があります。依存関係リストには、デプロイ環境とのみ互換性のあるモジュールが除外されている場合もあります。この問題を回避するには、`GOOS`および`GOARCH` `.gitlab-ci.yml`ファイルの[環境変数](https://go.dev/ref/mod#minimal-version-selection)を設定して、デプロイ環境のオペレーティングシステムとアーキテクチャをターゲットとするようにビルドプロセスを設定できます。

例: 

```yaml
variables:
  GOOS: "darwin"
  GOARCH: "arm64"
```

`GOFLAGS`変数を使用して、ビルドタグの制約を指定することもできます:

```yaml
variables:
  GOFLAGS: "-tags=test_feature"
```

## Go言語プロジェクトの依存関係スキャンが誤検出を返す {#dependency-scanning-of-go-projects-returns-false-positives}

`go.sum`ファイルには、プロジェクトの[ビルドリスト](https://go.dev/ref/mod#glos-build-list)の生成中に検討されたすべてのモジュールのエントリが含まれています。モジュールの複数のバージョンが`go.sum`ファイルに含まれていますが、`go build`が使用する[MVS](https://go.dev/ref/mod#minimal-version-selection)アルゴリズムは1つしか選択しません。その結果、依存関係スキャンが`go.sum`を使用すると、誤検出がレポートされる可能性があります。

誤検出を防ぐために、GemnasiumはGo言語プロジェクトのビルドリストを生成できない場合にのみ`go.sum`を使用します。`go.sum`が選択されている場合は、警告が表示されます:

```shell
[WARN] [Gemnasium] [2022-09-14T20:59:38Z] ▶ Selecting "go.sum" parser for "/test-projects/gitlab-shell/go.sum". False positives may occur. See https://gitlab.com/gitlab-org/gitlab/-/issues/321081.
```

## `ssh`を使用しようとしたときに`Host key verification failed` {#host-key-verification-failed-when-trying-to-use-ssh}

任意の`gemnasium`イメージに`openssh-client`をインストールした後、`ssh`を使用すると、`Host key verification failed`メッセージが表示されることがあります。これは、イメージのビルド時に`$HOME`を`/tmp`に設定したため、セットアップ中にユーザーディレクトリを表すために`~`を使用する場合に発生する可能性があります。この問題については、[`gemnasium-python`イメージを使用するとSSH経由でのプロジェクトのクローン作成が失敗する](https://gitlab.com/gitlab-org/gitlab/-/issues/374571)で説明されています。`openssh-client`は`/root/.ssh/known_hosts`を検索することを想定していますが、このパスは存在しません。`/tmp/.ssh/known_hosts`が代わりに存在します。

これは、`openssh-client`がプリインストールされている`gemnasium-python`で解決されていますが、他のイメージに`openssh-client`を最初からインストールすると、問題が発生する可能性があります。これを解決するには、次のいずれかを実行します:

1. キーとホストをセットアップするときは、絶対パス（`/root/.ssh/known_hosts`の代わりに`~/.ssh/known_hosts`）を使用します。
1. 関連する`known_hosts`ファイルを指定する`ssh`設定に`UserKnownHostsFile`を追加します。例：`echo 'UserKnownHostsFile /tmp/.ssh/known_hosts' >> /etc/ssh/ssh_config`。

## `ERROR: THESE PACKAGES DO NOT MATCH THE HASHES FROM THE REQUIREMENTS FILE` {#error-these-packages-do-not-match-the-hashes-from-the-requirements-file}

このエラーは、`requirements.txt`ファイル内のパッケージのハッシュが、ダウンロードされたパッケージのハッシュと一致しない場合に発生します。セキュリティ対策として、`pip`はパッケージが改ざんされたとみなし、インストールを拒否します。これを修正するには、要件ファイルに含まれるハッシュが正しいことを確認します。[`pip-compile`](https://pip-tools.readthedocs.io/en/stable/)によって生成された要件ファイルの場合は、`pip-compile --generate-hashes`を実行して、ハッシュが最新であることを確認します。[`pipenv`](https://pipenv.pypa.io/)によって生成された`Pipfile.lock`を使用している場合は、`pipenv verify`を実行して、ロックファイルに最新のパッケージのハッシュが含まれていることを確認します。

## `ERROR: In --require-hashes mode, all requirements must have their versions pinned with ==` {#error-in---require-hashes-mode-all-requirements-must-have-their-versions-pinned-with-}

このエラーは、要件ファイルがGitLab Runnerで使用されているものとは異なるプラットフォームで生成された場合に発生します。他のプラットフォームをターゲットとするためのサポートは、[イシュー416376](https://gitlab.com/gitlab-org/gitlab/-/issues/416376)で追跡されています。

## 編集可能なフラグがPythonの依存関係スキャンをハングさせる可能性がある {#editable-flags-can-cause-dependency-scanning-for-python-to-hang}

現在のディレクトリをターゲットとするために`requirements.txt`ファイルで[`-e/--editable`](https://pip.pypa.io/en/stable/cli/pip_install/#install-editable)フラグを使用すると、`pip3 download`を実行したときにGemnasium Python依存関係スキャナーがハングする問題が発生する可能性があります。このコマンドは、ターゲットプロジェクトをビルドするために必要です。

この問題を解決するには、Pythonの依存関係スキャンを実行するときに`-e/--editable`フラグを使用しないでください。

## SBTでのメモリ不足エラーの処理 {#handling-out-of-memory-errors-with-sbt}

Scalaプロジェクトで依存関係スキャンを使用中にSBTでメモリ不足エラーが発生した場合は、[`SBT_CLI_OPTS`](_index.md#analyzer-specific-settings)環境変数を設定することで、これに対処できます。設定例を以下に示します:

```yaml
variables:
  SBT_CLI_OPTS: "-J-Xmx8192m -J-Xms4192m -J-Xss2M"
```

Kubernetesexecutorを使用している場合は、デフォルトのKubernetesリソース設定をオーバーライドする必要がある場合があります。メモリの問題を防ぐためにコンテナリソースを調整する方法の詳細については、[Kubernetesexecutorドキュメント](https://docs.gitlab.com/runner/executors/kubernetes/#overwrite-container-resources)を参照してください。

## NPMプロジェクトに`package-lock.json`ファイルがない {#no-package-lockjson-file-in-npm-projects}

デフォルトでは、依存関係スキャンジョブは、リポジトリに`package-lock.json`ファイルがある場合にのみ実行されます。ただし、一部のNPMプロジェクトでは、Gitリポジトリに保存する代わりに、ビルドプロセス中に`package-lock.json`ファイルが生成されます。

これらのプロジェクトで依存関係をスキャンするには:

1. ビルドジョブで`package-lock.json`ファイルを生成します。
1. 生成されたファイルをアーティファクトとして保存します。
1. アーティファクトを使用し、そのルールを調整するように依存関係スキャンジョブを変更します。

たとえば、設定は次のようになります:

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

## パイプラインに依存関係スキャンジョブが追加されていません {#no-dependency-scanning-job-added-to-the-pipeline}

依存関係スキャンジョブは、依存関係を含むロックファイルまたはビルドツール関連ファイルが存在するかどうかを確認するためにルールを使用します。これらのファイルが検出されない場合、パイプライン内の別のジョブによってロックファイルが生成された場合でも、ジョブはパイプラインに追加されません。

この状況が発生した場合は、リポジトリに[サポートされているファイル](https://gitlab.com/gitlab-org/security-products/analyzers/dependency-scanning#supported-files)、またはサポートされているファイルがランタイム時に生成されることを示すファイルが含まれていることを確認してください。依存関係スキャンジョブをトリガーするために、そのようなファイルをリポジトリに追加できるかどうかを検討してください。

リポジトリにそのようなファイルが含まれており、ジョブがまだトリガーされないと思われる場合は、次の情報とともに[イシューをオープン](https://gitlab.com/gitlab-org/gitlab/-/issues/new)してください:

- 使用する言語とビルドツール。
- 提供するロックファイルの種類と、それが生成される場所。

[依存関係スキャンテンプレート](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Jobs/Dependency-Scanning.latest.gitlab-ci.yml#L269-270)に直接コントリビュートすることもできます。

## `gradlew: permission denied`で依存関係スキャンが失敗する {#dependency-scanning-fails-with-gradlew-permission-denied}

`gradlew`の`permission denied`エラーは、通常、`gradlew`が実行可能ビットセットなしでリポジトリにチェックインされたことを示します。エラーは、次のメッセージとともにジョブに表示される場合があります:

```plaintext
[FATA] [gemnasium-maven] [2024-11-14T21:55:59Z] [/go/src/app/cmd/gemnasium-maven/main.go:65] ▶ fork/exec /builds/path/to/gradlew: permission denied
```

ローカルで`chmod +ux gradlew`を実行し、それをGitリポジトリにプッシュして、ファイルを実行可能にします。

## サポートされていないGradleバージョンが原因で、依存関係スキャンのネビュラロック作成が失敗する {#dependency-scanning-nebula-lock-creation-fails-due-to-unsupported-gradle-version}

サポートされていないGradleバージョン（9.0以降）で[依存関係.lockファイル](dependency_scanning_sbom/_index.md#dependency-lock-plugin)を作成しようとすると、次のエラーが発生します:

```plaintext
FAILURE: Build failed with an exception.
* Where:
Initialization script '/builds/gitlab-org/app/app/nebula.gradle' line: 11
* What went wrong:
Failed to notify build listener.
> org/gradle/util/NameMatcher
```

gradleビルドをGradle 8.10.2にダウングレードしてみてください。

## 依存関係スキャンスキャナーが`Gemnasium`でなくなった {#dependency-scanning-scanner-is-no-longer-gemnasium}

これまで、依存関係スキャンで使用されていたスキャナーは`Gemnasium`であり、これはユーザーが[脆弱性](../vulnerabilities/_index.md)ページで確認できるものです。

[SBOMを使用した依存関係スキャン](dependency_scanning_sbom/_index.md)のロールアウトにより、`Gemnasium`スキャナーが組み込みの`GitLab SBoM Vulnerability Scanner`に置き換えられます。この新しいスキャナーはCI/CDジョブでは実行されなくなり、GitLabプラットフォーム内で実行されるようになります。2つのスキャナーは同じ結果を提供することが期待されますが、SBOMスキャンは既存の依存関係スキャンCI/CDジョブの後に発生するため、既存の脆弱性は、`GitLab SBoM Vulnerability Scanner`でスキャナー値が更新されます。

ロールアウトを進め、最終的に既存のGemnasiumアナライザーを置き換えるにつれて、`GitLab SBoM Vulnerability Scanner`がGitLab組み込みの依存関係スキャン機能に期待される唯一の値になります。

## プロジェクトの依存関係リストが最新のSBOMに基づいて更新されていません {#dependency-list-for-project-not-being-updated-based-on-latest-sbom}

パイプラインにSBOMを生成するジョブの失敗がある場合、`DeleteNotPresentOccurrencesService`が実行されないため、依存関係リストが変更または更新されません。これは、他のジョブがSBOMをアップロードしてパイプライン全体が成功した場合でも発生する可能性があります。これは、関連するセキュリティスキャンジョブが失敗した場合に、誤って依存関係リストから依存関係を削除することを防ぐように設計されています。プロジェクトの依存関係リストが期待どおりに更新されない場合は、パイプラインで失敗した可能性のあるSBOM関連のジョブを確認し、それらを修正するか削除してください。

## 依存関係スキャンが`open /etc/ssl/certs/ca-certificates.crt: permission denied`で失敗する {#dependency-scanning-fails-with-open-etcsslcertsca-certificatescrt-permission-denied}

このエラーは通常、コンテナを実行しているユーザーが`root`グループのメンバーではないことを示しています。ユーザーが`id`を実行してグループのメンバーであることを確認してください。

```shell
$ id
uid=1000(node) gid=0(root) groups=0(root),1000(node)
```

OpenShiftを実行している場合、またはKubernetesエグゼキューターを使用している場合は、グループID（GID）0を使用して実行するようにRunnerを設定していることを確認してください。

```toml
[[runners]]
[runners.kubernetes]
    [runners.kubernetes.pod_security_context]
    run_as_non_root = true
    run_as_group = 0
```

## エラー: `node with package name <package_name> does not exist` {#error-node-with-package-name-package_name-does-not-exist}

このイシューは、通常NuGetであるパッケージマネージャーがパッケージを見つけられない場合に発生します。これは、アプリケーションのビルドに使用されるイメージが、依存関係スキャンの実行に使用されるイメージと異なるために発生する可能性があります。

このイシューを解決するには、依存関係スキャナーがアプリケーションのビルドに使用するのと同じ.NET SDKイメージを使用します。正確なイメージは、次を実行して見つけることができます:

```shell
curl --silent "https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium/-/raw/master/build/gemnasium/alpine/Dockerfile" | grep "vrange-nuget-build" | grep "FROM"
```

上記のリンク先のDockerfileで、現在のイメージバージョンを確認してください。
