---
stage: Application Security Testing
group: Composition Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: コンテナスキャン
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab15.0で、主要なアナライザーのバージョンが`4`から`5`に[変更](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/86092)されました。
- 15.0で、GitLab UltimateからGitLab Freeに[移行](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/86783)しました。
- GitLab 15.4で、Dockerを参照するコンテナスキャン変数の[名前が変更](https://gitlab.com/gitlab-org/gitlab/-/issues/357264)されました。
- GitLab15.6で、コンテナスキャンテンプレートが`Security/Container-Scanning.gitlab-ci.yml`から`Jobs/Container-Scanning.gitlab-ci.yml`に[移動](https://gitlab.com/gitlab-org/gitlab/-/issues/381665)しました。

{{< /history >}}

コンテナイメージのセキュリティの脆弱性は、アプリケーションライフサイクル全体にリスクをもたらします。コンテナスキャンは、本番環境に到達する前に、これらのリスクを早期に検出します。ベースイメージまたはオペレーティングシステムのパッケージに脆弱性がある場合、コンテナスキャンはそれらを特定し、可能な場合は修正パスを提供します。

- <i class="fa fa-youtube-play youtube" aria-hidden="true"></i>概要については、「[Container Scanning](https://www.youtube.com/watch?v=C0jn2eN5MAs)（コンテナスキャン）」をご覧ください。
- <i class="fa fa-youtube-play youtube" aria-hidden="true"></i>ビデオによるチュートリアルについては、「[How to set up Container Scanning using GitLab](https://youtu.be/h__mcXpil_4?si=w_BVG68qnkL9x4l1)（GitLabを使用してコンテナスキャンを設定する方法）」をご覧ください。
- 入門チュートリアルについては、「[Dockerコンテナの脆弱性スキャン](../../../tutorials/container_scanning/_index.md)」を参照してください。

コンテナスキャンは、ソフトウェアコンポジション解析（SCA）の一部と見なされることがよくあります。SCAには、コードで使用するアイテムの検査の側面が含まれる場合があります。これらのアイテムには通常、アプリケーションやシステムの依存関係が含まれており、ほとんどの場合、これらはユーザーが記述したアイテムからではなく外部ソースからインポートされます。

GitLabは、これらのすべての依存関係タイプを確実に網羅するために、コンテナスキャンと[依存関係スキャン](../dependency_scanning/_index.md)の両方を提供しています。リスク領域をできるだけ広くカバーするために、すべてのセキュリティスキャナーを使用することをおすすめします。これらの機能の比較については、「[依存関係スキャンとコンテナスキャンの比較](../comparison_dependency_and_container_scanning.md)」を参照してください。

GitLabは、[Trivy](https://github.com/aquasecurity/trivy)セキュリティスキャナーと統合して、コンテナ内の脆弱性の静的な解析を実行します。

{{< alert type="warning" >}}

Grypeアナライザーは、[サポートステートメント](https://about.gitlab.com/support/statement-of-support/#version-support)で説明されているように、限定的な修正を除き、メンテナンスされなくなりました。Grypeアナライザーイメージの現在の主要バージョンは、GitLab 19.0まで最新のアドバイザリーデータベースとオペレーティングシステムパッケージの更新が継続され、その後アナライザーは動作を停止します。

{{< /alert >}}

GitLabは、ソースブランチとターゲットブランチの間で見つかった脆弱性を比較し、次の処理を実行します。

- 結果をマージリクエストウィジェットに表示します。
- 結果を[コンテナスキャンレポートアーティファクト](../../../ci/yaml/artifacts_reports.md#artifactsreportscontainer_scanning)として保存します。これはダウンロードして後で分析できます。ダウンロードすると、常に最新のアーティファクトを受け取ります。
- 検出されたコンポーネントをリストする[CycloneDX SBOM JSONレポート](#cyclonedx-software-bill-of-materials)を保存します。

![コンテナスキャンウィジェット](img/container_scanning_v13_2.png)

## 機能

| 機能 | FreeとPremium | Ultimate |
| --- | ------ | ------ |
| 設定のカスタマイズ（[変数](#available-cicd-variables)、[オーバーライド](#overriding-the-container-scanning-template)、[オフライン環境のサポート](#running-container-scanning-in-an-offline-environment)など） | {{< icon name="check-circle" >}} 可 | {{< icon name="check-circle" >}} 可 |
| CIジョブアーティファクトとして[JSONレポートを表示](#reports-json-format) | {{< icon name="check-circle" >}} 可 | {{< icon name="check-circle" >}} 可 |
| CIジョブアーティファクトとして[CycloneDX SBOM JSONレポート](#cyclonedx-software-bill-of-materials)を生成 | {{< icon name="check-circle" >}} 可 | {{< icon name="check-circle" >}} 可 |
| GitLab UIのMR 経由でコンテナスキャンを有効にする機能 | {{< icon name="check-circle" >}} 可 | {{< icon name="check-circle" >}} 可 |
| [UBIイメージのサポート](#fips-enabled-images) | {{< icon name="check-circle" >}} 可 | {{< icon name="check-circle" >}} 可 |
| Trivyのサポート | {{< icon name="check-circle" >}} 可 | {{< icon name="check-circle" >}} 可 |
| GitLab Advisory Databaseの組み込み | GitLab [advisories-communities](https://gitlab.com/gitlab-org/advisories-community/)プロジェクトからの時間差コンテンツに限定 | 可 - [Gemnasium DB](https://gitlab.com/gitlab-org/security-products/gemnasium-db)からのすべての最新コンテンツ |
| CIパイプラインジョブのマージリクエストタブとセキュリティタブでのレポートデータの表示 | {{< icon name="dotted-circle" >}} 不可 | {{< icon name="check-circle" >}} 可 |
| [脆弱性のソリューション（自動修正）](#solutions-for-vulnerabilities-auto-remediation) | {{< icon name="dotted-circle" >}} 不可 | {{< icon name="check-circle" >}} 可 |
| [脆弱性許可リスト](#vulnerability-allowlisting)のサポート | {{< icon name="dotted-circle" >}} 不可 | {{< icon name="check-circle" >}} 可 |
| [依存関係リストページへのアクセス](../dependency_list/_index.md) | {{< icon name="dotted-circle" >}} 不可 | {{< icon name="check-circle" >}} 可 |

## 設定

CI/CDパイプラインでコンテナスキャンアナライザーを有効にします。パイプラインが実行されると、アプリケーションが依存するイメージの脆弱性がスキャンされます。CI/CD変数を使用してコンテナスキャンをカスタマイズできます。

### アナライザーを有効にする

前提要件:

- `.gitlab-ci.yml`ファイルにはtestステージが必要です。
- Self-Managed Runner では、Linux/amd64上で`docker`または`kubernetes` executorを備えたGitLab Runner が必要です。GitLab.comのインスタンスRunnerを使用している場合、これはデフォルトで有効になっています。
- [サポートされているディストリビューション](#supported-distributions)に一致するイメージ。
- プロジェクトのコンテナレジストリに対して、Dockerイメージを[ビルドしてプッシュ](../../packages/container_registry/build_and_push_images.md#use-gitlab-cicd)していること。
- サードパーティのコンテナレジストリを使用している場合は、`CS_REGISTRY_USER`および`CS_REGISTRY_PASSWORD`の[設定変数](#available-cicd-variables)を使用して認証情報を提供する必要がある場合があります。これらの変数の使用方法の詳細については、「[リモートレジストリに対して認証する](#authenticate-to-a-remote-registry)」を参照してください。

アナライザーを有効にするには、次のいずれかの方法を使用します。

- 依存関係スキャンを含め、Auto DevOpsを有効にします。
- 事前設定されたマージリクエストを使用します。
- コンテナスキャンを実行する[スキャン実行ポリシー](../policies/scan_execution_policies.md)を作成します。
- `.gitlab-ci.yml`ファイルを手動で編集します。

#### 事前設定されたマージリクエストを使用する

この方法は、`.gitlab-ci.yml`ファイルにコンテナスキャンテンプレートが含まれているマージリクエストを自動的に準備します。次に、マージリクエストをマージして、依存関係スキャンを有効にします。

{{< alert type="note" >}}

この方法は、既存の`.gitlab-ci.yml`ファイルがない場合、または最小限の設定ファイルがある場合に最適です。複雑なGitLab設定ファイルがある場合は、正常に解析されず、エラーが発生する可能性があります。その場合は、代わりに[手動](#edit-the-gitlab-ciyml-file-manually)の方法を使用してください。

{{< /alert >}}

コンテナスキャンを有効にするには:

1. 左側のサイドバーで、**検索または移動**を選択し、プロジェクトを検索します。
1. **セキュリティ>セキュリティ設定**を選択します。
1. **コンテナスキャン**行で、**マージリクエスト経由で設定**を選択します。
1. **マージリクエストの作成**を選択します。
1. マージリクエストをレビューして、**マージ**を選択します。

これで、パイプラインにコンテナスキャンジョブが含まれるようになります。

#### `.gitlab-ci.yml`ファイルを手動で編集する

この方法では、既存の`.gitlab-ci.yml`ファイルを手動で編集する必要があります。GitLab CI/CD設定ファイルが複雑な場合や、デフォルト以外のオプションを使用する必要がある場合は、この方法を使用します。

コンテナスキャンを有効にするには:

1. 左側のサイドバーで、**検索または移動**を選択し、プロジェクトを検索します。
1. **ビルド>パイプラインエディタ**を選択します。
1. `.gitlab-ci.yml`ファイルが存在しない場合は、**パイプラインの設定**を選択し、例のコンテンツを削除します。
1. 次の内容をコピーして、`.gitlab-ci.yml`ファイルの末尾に貼り付けます。`include`行がすでに存在する場合は、その下に`template`行のみを追加します。

   ```yaml
   include:
     - template: Jobs/Container-Scanning.gitlab-ci.yml
   ```

1. **検証**タブを選択し、**パイプラインの検証**を選択します。

   **シミュレーションが正常に完了しました**というメッセージは、ファイルが有効であることを裏付けています。
1. **編集**タブを選択します。
1. フィールドに入力します。**ブランチ**フィールドにデフォルトブランチを使用しないでください。
1. **これらの変更で新しいマージリクエストを開始**チェックボックスをオンにし、**変更をコミットする**を選択します。
1. 標準のワークフローに従ってフィールドに入力し、**マージリクエストの作成**を選択します。
1. 標準のワークフローに従ってマージリクエストをレビューおよび編集し、パイプラインがパスするまで待ってから**マージ**を選択します。

これで、パイプラインにコンテナスキャンジョブが含まれるようになります。

### アナライザーの動作をカスタマイズする

コンテナスキャンをカスタマイズするには、[CI/CD変数](#available-cicd-variables)を使用します。

#### 冗長な出力を有効にする

トラブルシューティング時など、依存関係スキャン ジョブの動作を詳細に確認する必要がある場合は、冗長な出力を有効にします。

次の例では、コンテナスキャンテンプレートが含まれており、冗長な出力が有効になっています。

```yaml
include:
  - template: Jobs/Container-Scanning.gitlab-ci.yml

variables:
    SECURE_LOG_LEVEL: 'debug'
```

#### リモートレジストリ内のイメージをスキャンする

プロジェクト以外のレジストリにあるイメージをスキャンするには、次の`.gitlab-ci.yml`を使用します。

```yaml
include:
  - template: Jobs/Container-Scanning.gitlab-ci.yml

container_scanning:
  variables:
    CS_IMAGE: example.com/user/image:tag
```

##### リモートレジストリに対して認証する

プライベートレジストリ内のイメージをスキャンするには、認証が必要です。`CS_REGISTRY_USER`変数にユーザー名を、`CS_REGISTRY_PASSWORD`設定変数にパスワードを指定します。

たとえば、AWS Elasticコンテナレジストリからイメージをスキャンするには、次のようにします。

```yaml
container_scanning:
  before_script:
    - ruby -r open-uri -e "IO.copy_stream(URI.open('https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip'), 'awscliv2.zip')"
    - unzip awscliv2.zip
    - sudo ./aws/install
    - aws --version
    - export AWS_ECR_PASSWORD=$(aws ecr get-login-password --region region)

include:
  - template: Jobs/Container-Scanning.gitlab-ci.yml

variables:
    CS_IMAGE: <aws_account_id>.dkr.ecr.<region>.amazonaws.com/<image>:<tag>
    CS_REGISTRY_USER: AWS
    CS_REGISTRY_PASSWORD: "$AWS_ECR_PASSWORD"
    AWS_DEFAULT_REGION: <region>
```

[FIPSモード](../../../development/fips_gitlab.md#enable-fips-mode)が有効になっている場合、リモートレジストリに対する認証はサポートされていません。

#### 言語固有の検出結果をレポートする

`CS_DISABLE_LANGUAGE_VULNERABILITY_SCAN` CI/CD変数は、スキャンでプログラミング言語に関連する検出結果をレポートするかどうかを制御します。サポートされている言語の詳細については、Trivyドキュメントの[言語固有のパッケージ](https://aquasecurity.github.io/trivy/latest/docs/coverage/language/#supported-languages)を参照してください。

デフォルトでは、レポートにはオペレーティングシステム（OS）パッケージマネージャー（`yum`、`apt`、`apk`、`tdnf`など）によって管理されるパッケージのみが含まれます。OS以外のパッケージのセキュリティ検出結果を報告するには、`CS_DISABLE_LANGUAGE_VULNERABILITY_SCAN`を`"false"`に設定します。

```yaml
include:
  - template: Jobs/Container-Scanning.gitlab-ci.yml

container_scanning:
  variables:
    CS_DISABLE_LANGUAGE_VULNERABILITY_SCAN: "false"
```

この機能を有効にすると、プロジェクトで[依存関係スキャン](../dependency_scanning/_index.md)が有効になっている場合、[脆弱性レポート](../vulnerability_report/_index.md)に[重複する検出結果](../terminology/_index.md#duplicate-finding)が表示されることがあります。これは、GitLabが種類の異なるスキャンツール間で検出結果を自動的に重複排除できないために発生します。重複する可能性がある依存関係の種類については、「[依存関係スキャンとコンテナスキャンの比較](../comparison_dependency_and_container_scanning.md)」を参照してください。

#### マージリクエストパイプラインでジョブを実行する

「[マージリクエストパイプラインでセキュリティスキャンツールを使用する](../detect/roll_out_security_scanning.md#use-security-scanning-tools-with-merge-request-pipelines)」を参照してください。

#### 利用可能なCI/CD変数

コンテナスキャンをカスタマイズするには、CI/CD変数を使用します。次の表に、コンテナスキャンに固有のCI/CD変数を示します。[事前定義されたCI/CD変数](../../../ci/variables/predefined_variables.md)も使用できます。

{{< alert type="warning" >}}

これらの変更をデフォルトブランチにマージする前に、マージリクエストでGitLabアナライザーのカスタマイズをテストします。そうしないと、誤検出が多数発生するなど、予期しない結果が生じる可能性があります。

{{< /alert >}}

| CI/CD変数                 | デフォルト       | 説明 |
| ------------------------------ | ------------- | ----------- |
| `ADDITIONAL_CA_CERT_BUNDLE`    | `""`          | 信頼するCA証明書のバンドル。詳細については、「[カスタムSSL CA公開認証局を使用する](#using-a-custom-ssl-ca-certificate-authority)」を参照してください。 |
| `CI_APPLICATION_REPOSITORY`    | `$CI_REGISTRY_IMAGE/$CI_COMMIT_REF_SLUG` | スキャンするイメージのDockerリポジトリURL。 |
| `CI_APPLICATION_TAG`           | `$CI_COMMIT_SHA` | スキャンするイメージのDockerリポジトリタグ。 |
| `CS_ANALYZER_IMAGE`            | `registry.gitlab.com/security-products/container-scanning:7` | アナライザーのDockerイメージ。GitLabが提供するアナライザーイメージで`:latest`タグを使用しないでください。 |
| `CS_DEFAULT_BRANCH_IMAGE`      | `""` | デフォルトブランチの`CS_IMAGE`の名前。詳細については、「[デフォルトブランチイメージを設定する](#setting-the-default-branch-image)」を参照してください。 |
| `CS_DISABLE_DEPENDENCY_LIST`   | `"false"`      | {{< icon name="warning" >}}GitLab 17.0で[削除](https://gitlab.com/gitlab-org/gitlab/-/issues/439782)されました。 |
| `CS_DISABLE_LANGUAGE_VULNERABILITY_SCAN` | `"true"` | スキャンされたイメージにインストールされている言語固有パッケージのスキャンを無効にします。 |
| `CS_DOCKER_INSECURE`           | `"false"`     | 証明書を検証せずに、HTTPSを使用してセキュアなDocker レジストリへのアクセスを許可します。 |
| `CS_DOCKERFILE_PATH`           | `Dockerfile`  | 修正の生成に使用する`Dockerfile`へのパス。デフォルトでは、スキャナーはプロジェクトのルートディレクトリにある`Dockerfile`という名前のファイルを探します。この変数は、`Dockerfile`がサブディレクトリなどの標準以外の場所にある場合にのみ設定する必要があります。詳細については、「[脆弱性のソリューション](#solutions-for-vulnerabilities-auto-remediation)」を参照してください。 |
| `CS_IGNORE_STATUSES`           | `""` | アナライザーに、コンマ区切りのリストで指定されたステータスの検出結果を無視するように強制します。次の値が許可されています: `unknown,not_affected,affected,fixed,under_investigation,will_not_fix,fix_deferred,end_of_life`。<sup>1</sup> |
| `CS_IGNORE_UNFIXED`            | `"false"`     | 修正されていない検出結果を無視します。無視された検出結果はレポートに含まれません。 |
| `CS_IMAGE`                 | `$CI_APPLICATION_REPOSITORY:$CI_APPLICATION_TAG` | スキャンするDockerイメージ。設定されている場合、この変数は`$CI_APPLICATION_REPOSITORY`変数と`$CI_APPLICATION_TAG`変数をオーバーライドします。 |
| `CS_IMAGE_SUFFIX`              | `""`          | `CS_ANALYZER_IMAGE`に追加されたサフィックス。`-fips`に設定すると、`FIPS-enabled`イメージがスキャンに使用されます。詳細については、「[FIPS対応イメージ](#fips-enabled-images)」を参照してください。 |
| `CS_QUIET`                     | `""`          | 設定されている場合、この変数はジョブログの[脆弱性テーブル](#container-scanning-job-log-format)の出力を無効にします。GitLab 15.1で[導入](https://gitlab.com/gitlab-org/security-products/analyzers/container-scanning/-/merge_requests/50)されました。 |
| `CS_REGISTRY_INSECURE`         | `"false"`     | 脆弱なレジストリへのアクセスを許可します（HTTPのみ）。ローカルでイメージをテストする場合は、`true`にのみ設定する必要があります。すべてのスキャナーで動作しますが、Trivyを動作させるには、レジストリがポート`80/tcp`でリッスンする必要があります。 |
| `CS_REGISTRY_PASSWORD`         | `$CI_REGISTRY_PASSWORD` | 認証が必要なDockerレジストリにアクセスするためのパスワード。デフォルトは、`$CS_IMAGE`が[`$CI_REGISTRY`](../../../ci/variables/predefined_variables.md)に存在する場合にのみ設定されます。[FIPSモード](../../../development/fips_gitlab.md#enable-fips-mode)が有効になっている場合はサポートされていません。 |
| `CS_REGISTRY_USER`                  | `$CI_REGISTRY_USER` | 認証が必要なDockerレジストリにアクセスするためのユーザー名。デフォルトは、`$CS_IMAGE`が[`$CI_REGISTRY`](../../../ci/variables/predefined_variables.md)に存在する場合にのみ設定されます。[FIPSモード](../../../development/fips_gitlab.md#enable-fips-mode)が有効になっている場合はサポートされていません。 |
| `CS_SEVERITY_THRESHOLD`        | `UNKNOWN`     | 重大度レベルのしきい値。スキャナーは、このしきい値以上の重大度レベルの脆弱性を出力します。サポートされているレベルは、`UNKNOWN`、`LOW`、`MEDIUM`、`HIGH`、`CRITICAL`です。{{< icon name="warning" >}}GitLab 17.8で、**[デフォルト値が`MEDIUM`に変更](https://gitlab.com/gitlab-org/gitlab/-/issues/439782)**されました。 |
| `CS_TRIVY_JAVA_DB`             | `"registry.gitlab.com/gitlab-org/security-products/dependencies/trivy-java-db"` | [trivy-java-db](https://github.com/aquasecurity/trivy-java-db)脆弱性データベースの代替場所を指定します。 |
| `SECURE_LOG_LEVEL`             | `info`        | 最小ログ生成レベルを設定します。このログ生成レベル以上のメッセージが出力されます。重大度が最も高いものから最も低いものへ順に、ログ生成レベルは、`fatal`、`error`、`warn`、`info`、`debug`です。 |
| `TRIVY_TIMEOUT`                | `5m0s`        | スキャンのタイムアウトを設定します。 |

**脚注:**

1. 修正ステータスの情報は、ソフトウェアベンダーからの正確な修正可用性データとコンテナイメージのオペレーティングシステムパッケージメタデータに大きく依存します。また、個々のコンテナスキャナーによる解釈の影響も受けます。コンテナスキャナーが脆弱性に対して修正されたパッケージの可用性を誤って報告している場合、`CS_IGNORE_STATUSES`を使用すると、この設定が有効になっている場合に、検出結果の誤検出または誤判定フィルタリングにつながる可能性があります。

### サポートされているディストリビューション

次のLinuxディストリビューションがサポートされています。

- Alma Linux
- alpine Linux
- Amazon Linux
- CentOS
- CBL-Mariner
- Debian
- Distroless
- Oracle Linux
- Photon OS
- Red Hat（RHEL）
- Rocky Linux
- SUSE
- Ubuntu

#### FIPS対応イメージ

GitLabは、コンテナスキャンイメージの[FIPS対応Red Hat UBI](https://www.redhat.com/en/blog/introducing-red-hat-universal-base-image)バージョンも提供しています。したがって、標準イメージをFIPS対応イメージに置き換えることができます。イメージを設定するには、`CS_IMAGE_SUFFIX`を`-fips`に設定するか、`CS_ANALYZER_IMAGE`変数を標準タグに`-fips`拡張子を加えたものに変更します。

{{< alert type="note" >}}

GitLabインスタンスでFIPSモードが有効になっている場合、`-fips`フラグは`CS_ANALYZER_IMAGE`に自動的に追加されます。

{{< /alert >}}

[FIPSモード](../../../development/fips_gitlab.md#enable-fips-mode)が有効になっている場合、認証済みレジストリのイメージのコンテナスキャンはサポートされません。`CI_GITLAB_FIPS_MODE`が`"true"`で、`CS_REGISTRY_USER`または`CS_REGISTRY_PASSWORD`が設定されている場合、アナライザーはエラーで終了し、スキャンを実行しません。

### コンテナスキャンテンプレートをオーバーライドする

ジョブ定義をオーバーライドする場合（`variables`のようなプロパティを変更する場合など）は、テンプレートを含めた後でジョブを宣言してオーバーライドし、追加のキーを指定する必要があります。

この例では、`GIT_STRATEGY`を`fetch`に設定します。

```yaml
include:
  - template: Jobs/Container-Scanning.gitlab-ci.yml

container_scanning:
  variables:
    GIT_STRATEGY: fetch
```

### デフォルトブランチイメージを設定する

デフォルトでは、コンテナスキャンは、イメージの命名規則が、ブランチ固有の識別子をイメージ名ではなくイメージタグに格納することを想定しています。イメージ名がデフォルトブランチと非デフォルトブランチで異なる場合、以前に検出された脆弱性は、マージリクエストで新しく検出されたものとして表示されます。

デフォルトブランチと非デフォルトブランチで同じイメージに異なる名前が付けられている場合は、`CS_DEFAULT_BRANCH_IMAGE`変数を使用すると、そのイメージのデフォルトブランチでの名前を示すことができます。これにより、GitLabは、非デフォルトブランチでスキャンを実行するときに、脆弱性がすでに存在するかどうかを正しく判断します。

例として、以下を想定します。

- 非デフォルトブランチは、命名規則`$CI_REGISTRY_IMAGE/$CI_COMMIT_BRANCH:$CI_COMMIT_SHA`でイメージを公開します。
- デフォルトブランチは、命名規則`$CI_REGISTRY_IMAGE:$CI_COMMIT_SHA`でイメージを公開します。

この例では、次のCI/CD設定を使用して、脆弱性が複製されないようにすることができます。

```yaml
include:
  - template: Jobs/Container-Scanning.gitlab-ci.yml

container_scanning:
  variables:
    CS_DEFAULT_BRANCH_IMAGE: $CI_REGISTRY_IMAGE:$CI_COMMIT_SHA
  before_script:
    - export CS_IMAGE="$CI_REGISTRY_IMAGE/$CI_COMMIT_BRANCH:$CI_COMMIT_SHA"
    - |
      if [ "$CI_COMMIT_BRANCH" == "$CI_DEFAULT_BRANCH" ]; then
        export CS_IMAGE="$CI_REGISTRY_IMAGE:$CI_COMMIT_SHA"
      fi
```

`CS_DEFAULT_BRANCH_IMAGE`は、特定の`CS_IMAGE`に対して同じである必要があります。変更された場合、重複する脆弱性のセットが作成され、手動で無視する必要があります。

[Auto DevOps](../../../topics/autodevops/_index.md)を使用している場合、`CS_DEFAULT_BRANCH_IMAGE`は自動的に`$CI_REGISTRY_IMAGE/$CI_DEFAULT_BRANCH:$CI_APPLICATION_TAG`に設定されます。

### カスタムSSL CA公開認証局を使用する

`ADDITIONAL_CA_CERT_BUNDLE` CI/CD変数を使用して、カスタムSSL CA公開認証局を設定できます。これは、HTTPSを使用するレジストリからDockerイメージをフェッチするときに、ピアを検証するために使用されます。`ADDITIONAL_CA_CERT_BUNDLE`値には、[X.509 PEM公開鍵証明書のテキスト表現](https://www.rfc-editor.org/rfc/rfc7468#section-5.1)が含まれている必要があります。たとえば、`.gitlab-ci.yml`ファイルでこの値を設定するには、以下を実行します。

```yaml
container_scanning:
  variables:
    ADDITIONAL_CA_CERT_BUNDLE: |
        -----BEGIN CERTIFICATE-----
        MIIGqTCCBJGgAwIBAgIQI7AVxxVwg2kch4d56XNdDjANBgkqhkiG9w0BAQsFADCB
        ...
        jWgmPqF3vUbZE0EyScetPJquRFRKIesyJuBFMAs=
        -----END CERTIFICATE-----
```

`ADDITIONAL_CA_CERT_BUNDLE`値は、[UIのカスタム変数](../../../ci/variables/_index.md#for-a-project)として設定することもできます。`file`として設定する場合は、証明書のパスが必要です。変数として設定する場合は、証明書のテキスト表現が必要です。

### 脆弱性の許可リスト

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

特定の脆弱性を許可リストに登録するには、次の手順に従います。

1. 「[コンテナスキャンテンプレートをオーバーライドする](#overriding-the-container-scanning-template)」の手順に従って、`.gitlab-ci.yml`ファイルに`GIT_STRATEGY: fetch`を設定します。
1. `vulnerability-allowlist.yml`という名前のYAMLファイルで、許可リストに登録されている脆弱性を定義します。これは、[`vulnerability-allowlist.yml`データ形式](#vulnerability-allowlistyml-data-format)で説明されている形式を使用する必要があります。
1. `vulnerability-allowlist.yml`ファイルをプロジェクトのGitリポジトリのルートフォルダーに追加します。

#### `vulnerability-allowlist.yml`データ形式

`vulnerability-allowlist.yml`ファイルはYAMLファイルで、_誤検出_であるか_適用されない_ため存在が**許可**されている脆弱性のCVE IDリストを指定します。

`vulnerability-allowlist.yml`ファイルに一致するエントリが見つかった場合、次のようになります。

- アナライザーが`gl-container-scanning-report.json`ファイルを生成する際、脆弱性は**含まれません**。
- パイプラインのセキュリティタブに脆弱性が**表示されません**。セキュリティタブの信頼できる情報源であるJSONファイルに含まれていないからです。

`vulnerability-allowlist.yml`ファイルの例:

```yaml
generalallowlist:
  CVE-2019-8696:
  CVE-2014-8166: cups
  CVE-2017-18248:
images:
  registry.gitlab.com/gitlab-org/security-products/dast/webgoat-8.0@sha256:
    CVE-2018-4180:
  your.private.registry:5000/centos:
    CVE-2015-1419: libxml2
    CVE-2015-1447:
```

この例では、以下が`gl-container-scanning-report.json`から除外されます。

1. CVE IDを持つすべての脆弱性: _CVE-2019-8696_、_CVE-2014-8166_、_CVE-2017-18248_
1. CVE ID _CVE-2018-4180_を持つ`registry.gitlab.com/gitlab-org/security-products/dast/webgoat-8.0@sha256` コンテナイメージで見つかったすべての脆弱性
1. CVE ID _CVE-2015-1419_、_CVE-2015-1447_ を持つ`your.private.registry:5000/centos`コンテナで見つかったすべての脆弱性

##### ファイル形式

- `generalallowlist`ブロックを使用すると、CVE IDをグローバルに指定できます。一致するCVE IDを持つすべての脆弱性は、スキャンレポートから除外されます。

- `images`ブロックを使用すると、コンテナイメージごとにCVE IDを個別に指定できます。一致するCVE IDを持つ特定のイメージからのすべての脆弱性は、スキャンレポートから除外されます。イメージ名は、スキャンするDockerイメージを指定するために使用される環境変数の1つ（`$CI_APPLICATION_REPOSITORY:$CI_APPLICATION_TAG`や`CS_IMAGE`など）から取得されます。このブロックで指定されたイメージは、この値と一致**する必要があり**、タグの値を含**めてはなりません**。たとえば、`CS_IMAGE=alpine:3.7`を使用してスキャンするイメージを指定する場合、`images`ブロックで`alpine`を使用しますが、`alpine:3.7`は使用できません。

  コンテナイメージは、複数の方法で指定できます。

  - イメージ名のみ（`centos`など）
  - レジストリホスト名を含む完全なイメージ名として（`your.private.registry:5000/centos`など）
  - レジストリホスト名とsha256ラベルを含む完全なイメージ名として（`registry.gitlab.com/gitlab-org/security-products/dast/webgoat-8.0@sha256`など）

{{< alert type="note" >}}

CVE IDの後の文字列（前の例の`cups`および`libxml2`）は、オプションのコメント形式です。脆弱性の処理には**影響しません**。コメントを含めて脆弱性を説明できます。

{{< /alert >}}

##### コンテナスキャンジョブログ形式

`container_scanning`ジョブの詳細で、コンテナスキャンアナライザーによって生成されたログを見ることで、スキャンの結果と`vulnerability-allowlist.yml`ファイルの正確性を確認できます。

ログには、検出された脆弱性のリストがテーブルとして含まれます。次に例を示します。

```plaintext
+------------+-------------------------+------------------------+-----------------------+------------------------------------------------------------------------+
|   STATUS   |      CVE SEVERITY       |      PACKAGE NAME      |    PACKAGE VERSION    |                            CVE DESCRIPTION                             |
+------------+-------------------------+------------------------+-----------------------+------------------------------------------------------------------------+
|  Approved  |   High CVE-2019-3462    |          apt           |         1.4.8         | Incorrect sanitation of the 302 redirect field in HTTP transport metho |
|            |                         |                        |                       | d of apt versions 1.4.8 and earlier can lead to content injection by a |
|            |                         |                        |                       |  MITM attacker, potentially leading to remote code execution on the ta |
|            |                         |                        |                       |                             rget machine.                              |
+------------+-------------------------+------------------------+-----------------------+------------------------------------------------------------------------+
| Unapproved |  Medium CVE-2020-27350  |          apt           |         1.4.8         | APT had several integer overflows and underflows while parsing .deb pa |
|            |                         |                        |                       | ckages, aka GHSL-2020-168 GHSL-2020-169, in files apt-pkg/contrib/extr |
|            |                         |                        |                       | acttar.cc, apt-pkg/deb/debfile.cc, and apt-pkg/contrib/arfile.cc. This |
|            |                         |                        |                       |  issue affects: apt 1.2.32ubuntu0 versions prior to 1.2.32ubuntu0.2; 1 |
|            |                         |                        |                       | .6.12ubuntu0 versions prior to 1.6.12ubuntu0.2; 2.0.2ubuntu0 versions  |
|            |                         |                        |                       | prior to 2.0.2ubuntu0.2; 2.1.10ubuntu0 versions prior to 2.1.10ubuntu0 |
|            |                         |                        |                       |                                  .1;                                   |
+------------+-------------------------+------------------------+-----------------------+------------------------------------------------------------------------+
| Unapproved |  Medium CVE-2020-3810   |          apt           |         1.4.8         | Missing input validation in the ar/tar implementations of APT before v |
|            |                         |                        |                       | ersion 2.1.2 could result in denial of service when processing special |
|            |                         |                        |                       |                         ly crafted deb files.                          |
+------------+-------------------------+------------------------+-----------------------+------------------------------------------------------------------------+
```

対応するCVE IDが`vulnerability-allowlist.yml`ファイルに追加されると、ログ内の脆弱性は`Approved`としてマークされます。

### オフライン環境でコンテナスキャンを実行する

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

インターネット経由での外部リソースへのアクセスが制限されている環境やアクセスが断続的な環境のインスタンスでは、コンテナスキャンジョブを正常に実行するためにいくつかの調整が必要です。詳細については、「[オフライン環境](../offline_deployments/_index.md)」を参照してください。

#### オフラインコンテナスキャンの要件

オフライン環境でコンテナスキャンを実行するには、以下が必要です。

- [`docker`または`kubernetes`executor](#enabling-the-analyzer)を備えたGitLab Runner
- コンテナスキャンイメージのコピーを含む、ローカルDockerコンテナレジストリを設定すること。これらのイメージは、それぞれのレジストリにあります。

| GitLabアナライザー | コンテナレジストリ |
| --- | --- |
| [Container-Scanning](https://gitlab.com/gitlab-org/security-products/analyzers/container-scanning) | [Container-Scanningコンテナレジストリ](https://gitlab.com/security-products/container-scanning/container_registry/) |

GitLab Runnerでは、[デフォルトで`pull policy`が`always`](https://docs.gitlab.com/runner/executors/docker.html#using-the-always-pull-policy)になっています。つまり、ローカルコピーが利用可能な場合でも、RunnerはGitLabコンテナレジストリからDockerイメージをプルしようとします。ローカルで利用可能なDockerイメージのみを使用する場合は、オフライン環境でGitLab Runnerの[`pull_policy`を`if-not-present`に設定できます](https://docs.gitlab.com/runner/executors/docker.html#using-the-if-not-present-pull-policy)。ただし、オフライン環境でない場合は、プルポリシーの設定を`always`のままにしておくことをおすすめします。これにより、CI/CDパイプラインで更新されたスキャナーを使用できるようになります。

##### カスタム公開認証局（CA）のサポート

バージョン[4.0.0](https://gitlab.com/gitlab-org/security-products/analyzers/container-scanning/-/releases/4.0.0)で、Trivyのカスタム公開認証局（CA）のサポートが導入されました。

#### Dockerレジストリ内でGitLabコンテナスキャンアナライザーイメージを利用できるようにする

コンテナスキャンでは、`registry.gitlab.com`から次のイメージを[ローカルDockerコンテナレジストリ](../../packages/container_registry/_index.md)にインポートします。

```plaintext
registry.gitlab.com/security-products/container-scanning:7
registry.gitlab.com/security-products/container-scanning/trivy:7
```

DockerイメージをローカルのオフラインDockerレジストリにインポートするプロセスは、**ネットワークのセキュリティポリシー**によって異なります。IT部門に相談して、外部リソースをインポートまたは一時的にアクセスするための承認済みプロセスを確認してください。これらのスキャナーは[定期的に更新](../_index.md#vulnerability-scanner-maintenance)されています。また、自分で随時更新できる場合もあります。

詳細については、[パイプラインでイメージを更新する方法に関する特定の手順](#automating-container-scanning-vulnerability-database-updates-with-a-pipeline)を参照してください。

Dockerイメージをファイルとして保存および転送する方法の詳細については、[`docker save`](https://docs.docker.com/reference/cli/docker/image/save/)、[`docker load`](https://docs.docker.com/reference/cli/docker/image/load/)、[`docker export`](https://docs.docker.com/reference/cli/docker/container/export/)、[`docker import`](https://docs.docker.com/reference/cli/docker/image/import/)に関するDockerドキュメントを参照してください。

#### ローカルコンテナスキャナーアナライザーを使用するようにコンテナスキャンCI/CD変数を設定する

1. `.gitlab-ci.yml`ファイルで[コンテナスキャンテンプレートをオーバーライド](#overriding-the-container-scanning-template)して、ローカルDockerコンテナレジストリでホストされているDockerイメージを参照します。

   ```yaml
   include:
     - template: Jobs/Container-Scanning.gitlab-ci.yml

   container_scanning:
     image: $CI_REGISTRY/namespace/container-scanning
   ```

1. ローカルDockerコンテナレジストリが`HTTPS`経由で安全に実行されているが、自己署名証明書を使用している場合は、`.gitlab-ci.yml`の上記の`container_scanning`セクションで`CS_DOCKER_INSECURE: "true"`を設定する必要があります。

#### パイプラインを使用したコンテナスキャンの脆弱性データベース更新を自動化する

プリセットスケジュールで最新の脆弱性データベースをフェッチするように、[スケジュールされたパイプライン](../../../ci/pipelines/schedules.md)を設定することをおすすめします。パイプラインでこれを自動化すると、毎回手動で実行する必要がなくなります。テンプレートとして、次の`.gitlab-ci.yml`の例を使用できます。

```yaml
variables:
  SOURCE_IMAGE: registry.gitlab.com/security-products/container-scanning:7
  TARGET_IMAGE: $CI_REGISTRY/namespace/container-scanning

image: docker:latest

update-scanner-image:
  services:
    - docker:dind
  script:
    - docker pull $SOURCE_IMAGE
    - docker tag $SOURCE_IMAGE $TARGET_IMAGE
    - echo "$CI_REGISTRY_PASSWORD" | docker login $CI_REGISTRY --username $CI_REGISTRY_USER --password-stdin
    - docker push $TARGET_IMAGE
```

上記のテンプレートは、ローカルインストールで実行されているGitLab Dockerレジストリで機能します。ただし、GitLab以外のDockerレジストリを使用している場合は、ローカルレジストリの詳細に合わせて`$CI_REGISTRY`の値と`docker login`の認証情報を変更する必要があります。

#### 外部プライベートレジストリのイメージをスキャンする

外部プライベートレジストリ内のイメージをスキャンするには、スキャンするイメージにアクセスする前にコンテナスキャンアナライザーが自身を認証できるように、アクセス認証情報を設定する必要があります。

GitLab[コンテナレジストリ](../../packages/container_registry/_index.md)を使用する場合は、`CS_REGISTRY_USER`および`CS_REGISTRY_PASSWORD`の[設定変数](#available-cicd-variables)が自動的に設定されるため、この設定をスキップできます。

次の例は、プライベート[Google Container Registry](https://cloud.google.com/artifact-registry)でイメージをスキャンするために必要な設定を示しています。

```yaml
include:
  - template: Jobs/Container-Scanning.gitlab-ci.yml

container_scanning:
  variables:
    CS_REGISTRY_USER: _json_key
    CS_REGISTRY_PASSWORD: "$GCP_CREDENTIALS"
    CS_IMAGE: "gcr.io/path-to-you-registry/image:tag"
```

この設定をコミットする前に、[Google Cloud Platform Container Registryドキュメント](https://cloud.google.com/container-registry/docs/advanced-authentication#json-key)の説明に従って、JSONキーを含む`GCP_CREDENTIALS`の[CI/CD変数](../../../ci/variables/_index.md#for-a-project)を追加します。また、次のようになります。

- 変数の値が**変数をマスク**オプションのマスキング要件に適合しない場合があるため、値がジョブログに公開される可能性があります。
- **変数の保護**オプションを選択すると、保護されていないフィーチャーブランチでスキャンが実行されない場合があります。
- オプションが選択されていない場合は、読み取り専用権限を持つ認証情報を作成し、定期的にローテーションすることを検討してください。

[FIPSモード](../../../development/fips_gitlab.md#enable-fips-mode)が有効になっている場合、外部プライベートレジストリのイメージのスキャンはサポートされません。

#### Trivy Javaデータベースミラーを作成および使用する

`trivy`スキャナーが使用され、スキャンされるコンテナイメージで`jar`ファイルが検出されると、`trivy`は追加の`trivy-java-db`脆弱性データベースをダウンロードします。デフォルトでは、`trivy-java-db`データベースは`ghcr.io/aquasecurity/trivy-java-db:1`で[OCIアーティファクト](https://oras.land/docs/quickstart/)としてホストされます。このレジストリに[アクセスできない](#running-container-scanning-in-an-offline-environment)場合、または`TOOMANYREQUESTS`という応答が返ってくる場合は、`trivy-java-db`をよりアクセスしやすいコンテナレジストリにミラーリングするという解決策があります。

```yaml
mirror trivy java db:
  image:
    name: ghcr.io/oras-project/oras:v1.1.0
    entrypoint: [""]
  script:
    - oras login -u $CI_REGISTRY_USER -p $CI_REGISTRY_PASSWORD $CI_REGISTRY
    - oras pull ghcr.io/aquasecurity/trivy-java-db:1
    - oras push $CI_REGISTRY_IMAGE:1 --config /dev/null:application/vnd.aquasec.trivy.config.v1+json javadb.tar.gz:application/vnd.aquasec.trivy.javadb.layer.v1.tar+gzip
```

脆弱性データベースは通常のDockerイメージではないため、`docker pull`を使用してプルすることはできません。GitLab UIでイメージに移動すると、エラーが表示されます。

上記のコンテナレジストリが`gitlab.example.com/trivy-java-db-mirror`の場合、コンテナスキャンジョブは次の方法で設定する必要があります。末尾にタグ`:1`を追加しないでください。`trivy`によって追加されます。

```yaml
include:
  - template: Jobs/Container-Scanning.gitlab-ci.yml

container_scanning:
  variables:
    CS_TRIVY_JAVA_DB: gitlab.example.com/trivy-java-db-mirror
```

## スタンドアロンのコンテナスキャンツールを実行する

[GitLabコンテナスキャンツール](https://gitlab.com/gitlab-org/security-products/analyzers/container-scanning)をDockerコンテナに対して実行できます。CIジョブのコンテキスト内で実行する必要はありません。イメージを直接スキャンするには、次の手順に従います。

1. [Docker Desktop](https://www.docker.com/products/docker-desktop/)または[Docker Machine](https://github.com/docker/machine)を実行します。

1. アナライザーのDockerイメージを実行し、`CI_APPLICATION_REPOSITORY`および`CI_APPLICATION_TAG`変数で分析するイメージとタグを渡します。

   ```shell
   docker run \
     --interactive --rm \
     --volume "$PWD":/tmp/app \
     -e CI_PROJECT_DIR=/tmp/app \
     -e CI_APPLICATION_REPOSITORY=registry.gitlab.com/gitlab-org/security-products/dast/webgoat-8.0@sha256 \
     -e CI_APPLICATION_TAG=bc09fe2e0721dfaeee79364115aeedf2174cce0947b9ae5fe7c33312ee019a4e \
     registry.gitlab.com/security-products/container-scanning
   ```

結果は`gl-container-scanning-report.json`に保存されます。

## JSON形式のレポート

コンテナスキャンツールはJSONレポートを出力します。これは、CI設定ファイルの[`artifacts:reports`](../../../ci/yaml/_index.md#artifactsreports)キーワードを介して[GitLab Runner](https://docs.gitlab.com/runner/)が認識します。

CIジョブが完了すると、RunnerはこれらのレポートをGitLabにアップロードし、CIジョブアーティファクトで使用できるようになります。GitLab Ultimateでは、対応する[パイプライン](../vulnerability_report/pipeline.md)でこれらのレポートを確認できます。また、これらのレポートは[脆弱性レポート](../vulnerability_report/_index.md)の一部になります。

これらのレポートは、[セキュリティレポートスキーマ](https://gitlab.com/gitlab-org/security-products/security-report-schemas/)で定義された形式に従う必要があります。以下を参照してください。

- [コンテナスキャンレポートの最新のスキーマ](https://gitlab.com/gitlab-org/security-products/security-report-schemas/-/blob/master/dist/container-scanning-report-format.json)
- [コンテナスキャンレポートの例](https://gitlab.com/gitlab-examples/security/security-reports/-/blob/master/samples/container-scanning.json)

詳細については、「[セキュリティスキャナーのインテグレーション](../../../development/integrations/secure.md)」を参照してください。

### CycloneDXソフトウェア部品表

{{< history >}}

- GitLab 15.11で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/396381)されました。

{{< /history >}}

[JSONレポートファイル](#reports-json-format)に加えて、[コンテナスキャン](https://gitlab.com/gitlab-org/security-products/analyzers/container-scanning)ツールは、スキャンされたイメージの[CycloneDX](https://cyclonedx.org/)ソフトウェア部品表（SBOM）を出力します。このCycloneDX SBOMは`gl-sbom-report.cdx.json`という名前で、`JSON report file`と同じディレクトリに保存されます。この機能は、`Trivy`アナライザーが使用されている場合にのみサポートされます。

このレポートは、[依存関係リスト](../dependency_list/_index.md)で確認できます。

[他のジョブアーティファクトと同じ方法](../../../ci/jobs/job_artifacts.md#download-job-artifacts)でCycloneDX SBOMをダウンロードできます。

## レジストリのコンテナスキャン

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 17.1で、`enable_container_scanning_for_registry`という名前の[フラグとともに](../../../administration/feature_flags.md)[導入](https://gitlab.com/groups/gitlab-org/-/epics/2340)されました。デフォルトでは無効になっています。
- GitLab 17.2の[GitLab Self-ManagedおよびGitLab Dedicatedで有効](https://gitlab.com/gitlab-org/gitlab/-/issues/443827)になりました。
- GitLab 17.2で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/443827)になりました。機能フラグ`enable_container_scanning_for_registry`が削除されました。

{{< /history >}}

コンテナイメージが`latest`タグでプッシュされると、セキュリティポリシーボットによって、デフォルトブランチに対して新しいパイプラインでコンテナスキャンジョブが自動的にトリガーされます。

通常のコンテナスキャンとは異なり、スキャン結果にセキュリティレポートは含まれません。代わりに、レジストリのコンテナスキャンは、[継続的脆弱性スキャン](../continuous_vulnerability_scanning/_index.md)を利用して、スキャンによって検出されたコンポーネントを検査します。

セキュリティ検出が特定されると、GitLabはこれらの検出結果を[脆弱性レポート](../vulnerability_report/_index.md)に入力します。脆弱性は、脆弱性レポートページの**コンテナレジストリの脆弱性**タブで確認できます。

{{< alert type="note" >}}

レジストリのコンテナスキャンは、新しいアドバイザリーが[GitLab Advisory Database](../gitlab_advisory_database/_index.md)に公開された場合にのみ、脆弱性レポートに情報を入力します。新しく検出されたデータだけでなく、存在するすべてのアドバイザリデータを脆弱性レポートに入力するためのサポートは、[エピック11219](https://gitlab.com/groups/gitlab-org/-/epics/11219)で提案されています。

{{< /alert >}}

### 前提要件

- レジストリのコンテナスキャンを有効にするには、プロジェクトのメンテナーロール以上を持っている必要があります。
- 使用するプロジェクトが空であってはなりません。コンテナイメージの保存のみを目的として空のプロジェクトを利用している場合、この機能は意図したとおりに機能しません。回避策として、プロジェクトにデフォルトブランチへの最初のコミットが含まれていることを確認してください。
- デフォルトでは、1日あたり1プロジェクトにつき`50`回のスキャンに制限されています。
- [コンテナレジストリ通知を設定する](../../../administration/packages/container_registry.md#configure-container-registry-notifications)必要があります。

### レジストリのコンテナスキャンを有効にする

GitLabコンテナレジストリのコンテナスキャンを有効にするには:

1. 左側のサイドバーで、**検索または移動**を選択し、プロジェクトを検索します。
1. **セキュリティ>セキュリティ設定**を選択します。
1. **レジストリのコンテナスキャン**セクションまでスクロールし、切替をオンにします。

## 脆弱性データベース

すべてのアナライザーイメージは[毎日更新](https://gitlab.com/gitlab-org/security-products/analyzers/container-scanning/-/blob/master/README.md#image-updates)されます。

次のイメージは、アップストリームのアドバイザリーデータベースからのデータを使用します。

- AlmaLinux Security Advisory
- Amazon Linux Security Center
- Arch Linux Security Tracker
- SUSE CVRF
- CWE Advisories
- Debian Security Bug Tracker
- GitHub Security Advisory
- Go Vulnerability Database
- CBL-Mariner Vulnerability Data
- NVD
- OSV
- Red Hat OVAL v2
- Red Hat Security Data API
- Photon Security Advisories
- Rocky Linux UpdateInfo
- Ubuntu CVE Tracker（2021年半ば以降のデータソースのみ）

GitLabでは、これらのスキャナーが提供するソースに加えて、次の脆弱性データベースを保持しています。

- プロプライエタリな[GitLab Advisory Database](https://gitlab.com/gitlab-org/security-products/gemnasium-db)
- オープンソースの[GitLab Advisory Database（オープンソースエディション）](https://gitlab.com/gitlab-org/advisories-community)

GitLab Ultimateプランでは、[GitLab Advisory Database](https://gitlab.com/gitlab-org/security-products/gemnasium-db)のデータがマージされ、外部ソースからのデータが拡張されます。GitLab PremiumプランとFreeプランでは、[GitLab Advisory Database（オープンソースエディション）](https://gitlab.com/gitlab-org/advisories-community)のデータがマージされ、外部ソースからのデータが拡張されます。この拡張は現在、Trivyスキャナーのアナライザーイメージにのみ適用されます。

他のアナライザーのデータベース更新情報については、[メンテナンステーブル](../_index.md#vulnerability-scanner-maintenance)を参照してください。

## 脆弱性のソリューション（自動修正）

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

GitLabが自動的に生成するソリューションを適用することで、一部の脆弱性を修正できます。

修正サポートを有効にするには、スキャンツールが[`CS_DOCKERFILE_PATH`](#available-cicd-variables) CI/CD変数で指定された`Dockerfile`にアクセスできる_必要があります_。スキャンツールがこのファイルにアクセスできるようにするには、このドキュメントの「[コンテナスキャンテンプレートをオーバーライドする](#overriding-the-container-scanning-template)」セクションの説明に従って、`.gitlab-ci.yml`ファイルで[`GIT_STRATEGY: fetch`](../../../ci/runners/configure_runners.md#git-strategy)を設定する必要があります。

「[脆弱性のソリューション](../vulnerabilities/_index.md#resolve-a-vulnerability)」の詳細を参照してください。

## トラブルシューティング

### `docker: Error response from daemon: failed to copy xattrs`

Runnerが`docker` executorを使用し、NFSが使用されている場合（`/var/lib/docker`がNFSマウント上にある場合など）は、コンテナスキャンが次のようなエラーで失敗する可能性があります。

```plaintext
docker: Error response from daemon: failed to copy xattrs: failed to set xattr "security.selinux" on /path/to/file: operation not supported.
```

これはDockerのバグの結果であり、現在[修正されています（）](https://github.com/containerd/continuity/pull/138 "fs: add WithAllowXAttrErrors CopyOpt")。エラーを防ぐには、Runnerが使用しているDockerのバージョンが`18.09.03`以上であることを確認してください。詳細については、[イシュー10241（）](https://gitlab.com/gitlab-org/gitlab/-/issues/10241 "コンテナスキャンがNFSマウントで動作しない理由を調査する")を参照してください。

### 警告メッセージ`gl-container-scanning-report.json: no matching files`が表示される

これに関する情報については、[一般的なアプリケーションセキュリティのトラブルシューティングセクション](../../../ci/jobs/job_artifacts_troubleshooting.md#error-message-no-files-to-upload)を参照してください。

### AWS ECRからイメージをスキャンする際に`unexpected status code 401 Unauthorized: Not Authorized`が発生する

このエラーは、AWSリージョンが設定されておらず、スキャナーが認証トークンを取得できない場合に発生する可能性があります。`SECURE_LOG_LEVEL`を`debug`に設定すると、次のようなログメッセージが表示されます。

```shell
[35mDEBUG[0m failed to get authorization token: MissingRegion: could not find region configuration
```

これを解決するには、`AWS_DEFAULT_REGION`をCI/CD変数に追加します。

```yaml
variables:
  AWS_DEFAULT_REGION: <AWS_REGION_FOR_ECR>
```

### `unable to open a file: open /home/gitlab/.cache/trivy/ee/db/metadata.json: no such file or directory`

圧縮されたTrivyデータベースはコンテナの`/tmp`フォルダーに保存され、ランタイム時に`/home/gitlab/.cache/trivy/{ee|ce}/db`に展開されます。このエラーは、Runner設定に`/tmp`ディレクトリのボリュームマウントがある場合に発生する可能性があります。

これを解決するには、`/tmp`フォルダーをバインドする代わりに、`/tmp`内の特定のファイルまたはフォルダー（`/tmp/myfile.txt`など）をバインドします。

### `context deadline exceeded`エラーを解決する

このエラーは、タイムアウトが発生したことを意味します。これを解決するには、十分な長さの期間で、`TRIVY_TIMEOUT`環境変数を`container_scanning`ジョブに追加します。

## 変更

コンテナスキャンアナライザーへの変更は、プロジェクトの[変更履歴](https://gitlab.com/gitlab-org/security-products/analyzers/container-scanning/-/blob/master/CHANGELOG.md)に表示されています。
