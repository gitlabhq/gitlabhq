---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: ジョブアーティファクト
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

ジョブはファイルやディレクトリのアーカイブを出力できます。この出力はジョブアーティファクトと呼ばれます。アーティファクトには、ビルドの出力ファイルやレポートファイルを含めることができます。デフォルトでは、以降のジョブは、以前のステージングのジョブのすべてのアーティファクトのコピーをフェッチします。

たとえば、初期のジョブでプロジェクトをビルドし、出力をアーティファクトとして保存できます。その後、以降のジョブがアーティファクトをフェッチし、保存されたビルドの出力に対してテストを実行します。

`artifacts`キーワードでサポートされている設定の完全なリストについては、[GitLab CI/CD YAML構文reference](../yaml/_index.md#artifacts)を参照してください。

関連トピック:

- [ジョブアーティファクトAPI](../../api/job_artifacts.md)
- [ジョブアーティファクトの管理](../../administration/cicd/job_artifacts.md)

## ジョブアーティファクトを作成する {#create-job-artifacts}

ジョブアーティファクトを作成するには、`.gitlab-ci.yml`ファイルで`artifacts`キーワードを使用します:

```yaml
pdf:
  script: xelatex mycv.tex
  artifacts:
    paths:
      - mycv.pdf
```

この例では、`pdf`という名前のジョブが`xelatex`コマンドを呼び出して、LaTeXソースファイル`mycv.tex`からPDFファイルを作成します。

`paths`キーワードは、ジョブアーティファクトに追加するファイルを指定します。ファイルやディレクトリのパスはすべて、ジョブが作成されたリポジトリを基準とした相対パスになります。

### ワイルドカードを使用する {#with-wildcards}

パスやディレクトリには、ワイルドカードを使用できます。たとえば、`xyz`で終わるディレクトリ内のすべてのファイルを含むアーティファクトを作成するには、次のようにします:

```yaml
job:
  script: echo "build xyz project"
  artifacts:
    paths:
      - path/*xyz/*
```

### 有効期限を設定する {#with-an-expiry}

`expire_in`キーワードは、`artifacts:paths`で定義されたアーティファクトをGitLabが保持する期間を指定します。次に例を示します:

```yaml
pdf:
  script: xelatex mycv.tex
  artifacts:
    paths:
      - mycv.pdf
    expire_in: 1 week
```

`expire_in`が定義されていない場合は、インスタンス設定の[**デフォルトのアーティファクトの有効期限**](../../administration/settings/continuous_integration.md#set-default-artifacts-expiration)が使用されます。

アーティファクトの有効期限が切れないようにするには、ジョブの詳細ページから**維持**を選択します。アーティファクトに有効期限が設定されていない場合、このオプションは使用できません。

デフォルトでは、各refにおける直近の成功したパイプラインのアーティファクトは常に保持されます。

### 明示的に定義したアーティファクト名を使用する {#with-an-explicitly-defined-artifact-name}

`artifacts:name`設定を使用して、アーティファクト名を明示的にカスタマイズできます:

```yaml
job:
  artifacts:
    name: "job1-artifacts-file"
    paths:
      - binaries/
```

### 除外ファイルを指定する {#without-excluded-files}

`artifacts:exclude`を使用して、ファイルがアーティファクトアーカイブに追加されないようにします。

たとえば、`binaries/`内のすべてのファイルを保存するが、`binaries/`のサブディレクトリにある`*.o`ファイルを除外するには、次のようにします:

```yaml
artifacts:
  paths:
    - binaries/
  exclude:
    - binaries/**/*.o
```

`artifacts:paths`とは異なり、`exclude`パスは再帰的ではありません。ディレクトリの内容をすべて除外するには、ディレクトリ自体を指定するのではなく、明示的に指定します。

たとえば、`binaries/`内のすべてのファイルを保存するが、`temp/`サブディレクトリ内のファイルはすべて除外するには、次のようにします:

```yaml
artifacts:
  paths:
    - binaries/
  exclude:
    - binaries/temp/**/*
```

### 追跡していないファイルを含める {#with-untracked-files}

`artifacts:untracked`を使用すると、`artifacts:paths`で定義したパスに加えて、Gitで追跡していないファイルをすべてアーティファクトとして追加できます。追跡していないファイルとは、リポジトリに追加されていないが、リポジトリのチェックアウトには存在するファイルのことです。

たとえば、Gitで追跡していないファイルと`binaries`内のファイルをすべて保存する場合、次のようにします:

```yaml
artifacts:
  untracked: true
  paths:
    - binaries/
```

たとえば、追跡していないファイルをすべて保存するが、`*.txt`ファイルは除外する場合、次のようにします:

```yaml
artifacts:
  untracked: true
  exclude:
    - "*.txt"
```

### 変数展開を使用する {#with-variable-expansion}

変数の展開は、`artifacts:name`、`artifacts:paths`、`artifacts:exclude`でサポートされています。

GitLab Runnerは、shellを使用せず、内部変数展開メカニズムを使用します。このコンテキストでは、CI/CD変数のみがサポートされています。

たとえば、現在のブランチまたはタグ名を使用してアーカイブを作成し、現在のプロジェクト名のディレクトリからのファイルのみを含めるには、次のようにします:

```yaml
job:
  artifacts:
    name: "$CI_COMMIT_REF_NAME"
    paths:
      - binaries/${CI_PROJECT_NAME}/
```

ブランチ名にスラッシュが含まれている場合（例: `feature/my-feature`）は、適切なアーティファクト名が付けられるように、`$CI_COMMIT_REF_NAME`ではなく`$CI_COMMIT_REF_SLUG`を使用します。

変数はglobより先に展開されます。

## アーティファクトをフェッチする {#fetching-artifacts}

デフォルトでは、ジョブは前のステージで定義されたジョブからすべてのアーティファクトをフェッチします。これらのアーティファクトは、ジョブの作業ディレクトリにダウンロードされます。

`dependencies`または`needs:artifacts`キーワードを使用して、ダウンロードするアーティファクトを制御できます。

これらのキーワードを使用すると、デフォルトの動作が変更され、指定したジョブからのみアーティファクトがフェッチされます。

### ジョブがアーティファクトをフェッチしないようにする {#prevent-a-job-from-fetching-artifacts}

ジョブがアーティファクトをダウンロードしないようにするには、`dependencies`を空の配列（`[]`）に設定します:

```yaml
job:
  stage: test
  script: make build
  dependencies: []
```

## プロジェクト内のすべてのジョブアーティファクトを表示する {#view-all-job-artifacts-in-a-project}

{{< history >}}

- GitLab 16.0で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/407475)になりました。機能フラグ`artifacts_management_page`は削除されました。

{{< /history >}}

**ビルド** > **アーティファクト**ページから、プロジェクトに保存されているすべてのアーティファクトを表示できます。このリストには、すべてのジョブとそれに関連するアーティファクトが表示されます。エントリを展開して、ジョブに関連するすべてのアーティファクトにアクセスできます。これには以下が含まれます:

- `artifacts:`キーワードで作成されたアーティファクト。
- レポートアーティファクト。
- 別々のアーティファクトとして内部的に保存されるジョブログとメタデータ。

このリストから個々のアーティファクトをダウンロードまたは削除できます。

## ジョブアーティファクトをダウンロードする {#download-job-artifacts}

ジョブアーティファクトは、GitLab UIまたはAPIを使用してダウンロードできます。

GitLab UIから、次の場所からジョブのアーティファクトをダウンロードできます:

- **パイプライン**一覧。パイプラインの右側で、**アーティファクトをダウンロード**（{{< icon name="download" >}}）を選択します。
- **ジョブ**一覧。ジョブの右側で、**アーティファクトをダウンロード**（{{< icon name="download" >}}）を選択します。
- ジョブの詳細ページ。ページの右側で、**ダウンロード**を選択します。
- マージリクエスト**概要**ページ。最新のパイプラインの右側で、**アーティファクト**（{{< icon name="download" >}}）を選択します。
- **アーティファクト**ページ。ジョブの右側で、**ダウンロード**（{{< icon name="download" >}}）を選択します。
- アーティファクトブラウザ。ページの上部で、**アーティファクトのアーカイブをダウンロード**（{{< icon name="download" >}}）を選択します。

[レポートアーティファクト](../yaml/artifacts_reports.md)は、**パイプライン**一覧または**アーティファクト**ページからのみダウンロードできます。

### URLからダウンロードする {#from-a-url}

公開URLを使用して、特定のジョブアーティファクトアーカイブをダウンロードできます。

GitLab.com上のプロジェクトの`main`ブランチにある、`build`という名前のジョブの最新アーティファクトをダウンロードする場合:

```plaintext
https://gitlab.com/api/v4/projects/<project-id>/jobs/artifacts/main/download?job=build
```

アーティファクトから特定のファイルをダウンロードする場合:

```plaintext
https://gitlab.com/api/v4/projects/<project-id>/jobs/artifacts/main/raw/review/index.html?job=build
```

このエンドポイントによって返されるファイルは、常に`plain/text`コンテンツタイプになります。

どちらの例でも、`<project-id>`を有効なプロジェクトIDに置き換えます。プロジェクトIDは、[プロジェクトの概要ページ](../../user/project/working_with_projects.md#find-the-project-id)で確認できます。

親パイプラインと子パイプラインのアーティファクトは、親から子への階層順に検索されます。たとえば、親パイプラインと子パイプラインの両方に同じ名前のジョブがある場合、親パイプラインのジョブアーティファクトが返されます。

### CI/CDジョブトークンを使用する {#with-a-cicd-job-token}

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

CI/CDジョブトークンを使用してジョブアーティファクトAPIエンドポイントに対して認証し、別のパイプラインからアーティファクトをフェッチできます。アーティファクトの取得元となるジョブを指定する必要があります。次に例を示します:

```yaml
build_submodule:
  stage: test
  script:
    - apt update && apt install -y unzip
    - curl --location --output artifacts.zip "https://gitlab.example.com/api/v4/projects/1/jobs/artifacts/main/download?job=test&job_token=$CI_JOB_TOKEN"
    - unzip artifacts.zip
```

同じパイプライン内のジョブからアーティファクトをフェッチするには、`needs:artifacts`キーワードを使用します。

### アーティファクトをダウンロードできるユーザーの制御 {#control-who-can-download-artifacts}

ジョブのアーティファクトをダウンロードできるユーザーを制限するには、`artifacts:access`ファイルで`.gitlab-ci.yml`キーワードを使用します。次に例を示します:

```yaml
job:
  artifacts:
    access: maintainer
    paths:
      - build/
```

## アーティファクトアーカイブの内容を閲覧する {#browse-the-contents-of-the-artifacts-archive}

UIからアーティファクトをローカルにダウンロードすることなく、次の場所からアーティファクトの内容を閲覧できます:

- **ジョブ**一覧。ジョブの右側で、**閲覧**（{{< icon name="folder-open" >}}）を選択します。
- ジョブの詳細ページ。ページの右側で、**閲覧**を選択します。
- **アーティファクト**ページ。ジョブの右側で、**閲覧**（{{< icon name="folder-open" >}}）を選択します。

GitLab Pagesがグローバルに有効な場合、プロジェクト設定で無効になっていても、一部のアーティファクトファイル拡張子をブラウザで直接プレビューできます。プロジェクトが内部または非公開の場合、プレビューを有効にするには、GitLab Pagesへのアクセス制御を有効にする必要があります。

次の拡張子がサポートされています:

| ファイル拡張子 | GitLab.com                           | NGINXが組み込まれたLinuxパッケージ |
| -------------- | ------------------------------------ | --------------------------------- |
| `.html`        | {{< icon name="check-circle" >}}可 | {{< icon name="check-circle" >}}可 |
| `.json`        | {{< icon name="check-circle" >}}可 | {{< icon name="check-circle" >}}可 |
| `.xml`         | {{< icon name="check-circle" >}}可 | {{< icon name="check-circle" >}}可 |
| `.txt`         | {{< icon name="dotted-circle" >}}不可 | {{< icon name="check-circle" >}}可 |
| `.log`         | {{< icon name="dotted-circle" >}}不可 | {{< icon name="check-circle" >}}可 |

### URLからダウンロードする {#from-a-url-1}

公開URLを使用して、特定のジョブを実行した直近の成功したパイプラインのジョブアーティファクトを閲覧できます。

GitLab.com上のプロジェクトの`main`ブランチにある、`build`という名前のジョブの最新アーティファクトを閲覧する場合:

```plaintext
https://gitlab.com/<full-project-path>/-/jobs/artifacts/main/browse?job=build
```

`<full-project-path>`を有効なプロジェクトパスに置き換えます。プロジェクトパスはプロジェクトのURLで確認できます。

## ジョブログとアーティファクトを削除する {#delete-job-log-and-artifacts}

{{< alert type="warning" >}}

ジョブログとアーティファクトの削除は、元に戻すことのできない破壊的な操作です。注意して使用してください。レポートアーティファクト、ジョブログ、メタデータファイルなど、特定のファイルを削除すると、これらのファイルをデータソースとして使用するGitLab機能に影響します。

{{< /alert >}}

ジョブのアーティファクトとログを削除できます。

前提要件: 

- ジョブのオーナーであるか、プロジェクトのメンテナーロール以上を持つユーザーである必要があります。

ジョブを削除するには、次のようにします:

1. ジョブの詳細ページに移動します。
1. ジョブのログの右上隅で、**ジョブのログとアーティファクトを消去**（{{< icon name="remove" >}}）を選択します。

**アーティファクト**ページから個々のアーティファクトを削除することもできます。

### アーティファクトを一括削除する {#bulk-delete-artifacts}

{{< history >}}

- GitLab 15.10で`ci_job_artifact_bulk_destroy`[フラグ](../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/33348)されました。デフォルトでは無効になっています。
- GitLab 16.1で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/398581)になりました。機能フラグ`ci_job_artifact_bulk_destroy`は削除されました。

{{< /history >}}

複数のアーティファクトを同時に削除するには、次の手順に従います:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。[新しいナビゲーションをオンにしている](../../user/interface_redesign.md#turn-new-navigation-on-or-off)場合、このフィールドは上部のバーにあります。
1. **ビルド** > **アーティファクト**を選択します。
1. 削除するアーティファクトの横にあるチェックボックスを選択します。最大100個のアーティファクトを選択できます。
1. **一括削除**を選択します。

## マージリクエストUIでジョブアーティファクトへのリンクを表示する {#link-to-job-artifacts-in-the-merge-request-ui}

`artifacts:expose_as`キーワードを使用して、マージリクエストUIからアーティファクトへの直接アクセスを提供します。

単一のファイルを含むアーティファクトの場合:

```yaml
test:
  script: ["echo 'test' > file.txt"]
  artifacts:
    expose_as: 'artifact 1'
    paths: ['file.txt']
```

この設定では、**公開されたアーティファクトを表示**セクションに、`file.txt`というラベルの付いた**artifact 1**へのリンクが表示されます。

![公開されたアーティファクトにリンクするマージリクエストウィジェットです。](img/mr_artifact_expose_v18_4.png)

## 直近の成功したジョブのアーティファクトを保持する {#keep-artifacts-from-most-recent-successful-jobs}

{{< history >}}

- GitLab 16.7で、[ブロック](https://gitlab.com/gitlab-org/gitlab/-/issues/387087)されたパイプラインまたは[失敗](https://gitlab.com/gitlab-org/gitlab/-/issues/266958)したパイプラインのアーティファクトは無期限に保持されなくなりました。

{{< /history >}}

デフォルトでは、各refにおける直近の成功したパイプラインのアーティファクトは常に保持されます。`expire_in`設定は、直近のアーティファクトには適用されません。

同じrefに対する新しいパイプラインが正常に完了すると、`expire_in`設定に従って前のパイプラインのアーティファクトが削除されます。新しいパイプラインのアーティファクトは自動的に保持されます。

パイプラインのアーティファクトは、同じrefに対して新しいパイプラインが実行され、次の条件が満たされた場合にのみ、`expire_in`設定に従って削除されます:

- 成功する。
- 手動ジョブによってブロックされたために実行が停止する。

最新のアーティファクトを保持すると、ジョブ数が多いプロジェクトや大きなアーティファクトを持つプロジェクトで、大量のストレージ容量を使用する可能性があります。プロジェクトで最新のアーティファクトが必要ない場合は、この動作を無効にして容量を節約できます:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。[新しいナビゲーションをオンにしている](../../user/interface_redesign.md#turn-new-navigation-on-or-off)場合、このフィールドは上部のバーにあります。
1. **設定** > **CI/CD**を選択します。
1. **アーティファクト**を展開します。
1. **成功した最新のジョブのアーティファクトを保持する**チェックボックスをオフにします。

この設定を無効にすると、すべての新しいアーティファクトは`expire_in`設定に従って有効期限が切れます。古いパイプラインのアーティファクトは、同じrefに対して新しいパイプラインが実行されるまで保持されます。新しいパイプラインが実行された時点で、そのrefの以前のパイプラインのアーティファクトも有効期限切れによって削除されるようになります。

GitLab Self-Managedのすべてのプロジェクトでこの動作を無効にするには、[**Keep artifacts from latest successful pipelines**（成功した最新のパイプラインのアーティファクトを保持する）](../../administration/settings/continuous_integration.md#keep-artifacts-from-latest-successful-pipelines)インスタンス設定を使用します。

GitLab Self-Managedでは、[インスタンスのCI/CD設定](../../administration/settings/continuous_integration.md#keep-artifacts-from-latest-successful-pipelines)でこの動作をすべてのプロジェクトに対して無効にできます。
