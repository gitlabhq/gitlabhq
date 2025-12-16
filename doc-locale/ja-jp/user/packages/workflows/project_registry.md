---
stage: Package
group: Package Registry
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: すべてのパッケージを1つのGitLabプロジェクトに保存
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

複数のソースからのパッケージを1つのプロジェクトのパッケージレジストリに保存し、リモートリポジトリがGitLabのこのプロジェクトを指すように設定します。

この方法を使用する場合:

- コードが保存されているプロジェクトとは別のGitLabプロジェクトにパッケージを公開します。
- すべてのパッケージを1つのプロジェクトにグループ化します（たとえば、すべてのnpmパッケージ、特定の部門のすべてのパッケージ、または同じプロジェクト内のすべてのプライベートパッケージ）。
- 他のプロジェクトのパッケージをインストールするときに、1つのリモートリポジトリを使用します。
- サードパーティのパッケージレジストリからパッケージをGitLabの1つの場所に移行します。
- CI/CDパイプラインですべてのパッケージを1つのプロジェクトにビルドし、同じ場所でパッケージを管理できるようにします。

## チュートリアル例 {#example-walkthrough}

各パッケージ管理システムを使用して、異なるパッケージタイプを同じ場所に公開します。

- <i class="fa fa-youtube-play youtube" aria-hidden="true"></i> Maven、npm、Conanのパッケージを[同じプロジェクト](https://youtu.be/ui2nNBwN35c)に追加する方法のビデオをご覧ください。
- [サンプルプロジェクトを見る](https://gitlab.com/sabrams/my-package-registry/-/packages)。

## 1つのGitLabプロジェクトに異なるパッケージタイプを保存 {#store-different-package-types-in-one-gitlab-project}

すべてのパッケージをホストするために1つのプロジェクトを作成する方法を見てみましょう:

1. GitLabで新しいプロジェクトを作成します。このプロジェクトには、コードやコンテンツは必要ありません。
1. 左側のサイドバーで**Project overview**（プロジェクトの概要）を選択し、プロジェクトIDを書き留めます。
1. 認証用のアクセストークンを作成します。パッケージレジストリ内のすべてのパッケージタイプは、次を使用して公開できます:

   - [パーソナルアクセストークン](../../profile/personal_access_tokens.md)。
   - [グループアクセストークン](../../../user/group/settings/group_access_tokens.md)または[プロジェクトアクセストークン](../../../user/project/settings/project_access_tokens.md)。
   - CI/CDジョブの[CI/CDジョブトークン](../../../ci/jobs/ci_job_token.md)（`CI_JOB_TOKEN`）。プロジェクトの[ジョブトークン許可リスト](../../../ci/jobs/ci_job_token.md#add-a-group-or-project-to-the-job-token-allowlist)には、このプロジェクトのレジストリに公開するすべてのプロジェクトをリストする必要があります。

   プロジェクトがプライベートの場合、パッケージをダウンロードするには認証も必要です。

1. ローカルプロジェクトを構成し、パッケージを公開します。

すべてのパッケージタイプを同じプロジェクトにアップロードするか、パッケージタイプまたは表示レベルに基づいてパッケージを分割できます。

### NPM {#npm}

NPMパッケージの場合:

- レジストリURLを構成するには、[`.npmrc`ファイル](../npm_registry/_index.md#with-the-npmrc-file)を作成します。
- プロジェクトの`package.json`ファイルで`publishConfig`オプションを使用してパッケージのスコープを設定します。
- `npm publish`でパッケージを公開します。

詳細については、[パッケージレジストリのnpmパッケージ](../npm_registry/_index.md)を参照してください。

### Maven {#maven}

Mavenパッケージの場合:

1. レジストリURLを構成するには、`pom.xml`ファイルを`repository`セクションと`distributionManagement`セクションで更新します。
1. `settings.xml`ファイルを追加して、アクセストークンを含めます。
1. `mvn deploy`でパッケージを公開します。

詳細については、[パッケージレジストリのMavenパッケージ](../maven_repository/_index.md)を参照してください。

### Conan 1 {#conan-1}

Conan 1の場合:

- GitLabパッケージレジストリをConanレジストリリモートとして追加します。
- プラス記号（`+`）で区切られたプロジェクトパスをConanユーザーとして使用して、[Conan 1パッケージを作成](build_packages.md#build-a-conan-1-package)します。たとえば、プロジェクトが`https://gitlab.com/foo/bar/my-proj`にある場合は、`conan create . foo+bar+my-proj/channel`を使用してConanパッケージを作成します。`channel`は`beta`や`stable`などのパッケージチャンネルです:

   ```shell
   CONAN_LOGIN_USERNAME=<gitlab-username> CONAN_PASSWORD=<personal_access_token> conan upload MyPackage/1.0.0@foo+bar+my-proj/channel --all --remote=gitlab
   ```

- `conan upload`またはパッケージレシピを使用して、パッケージを公開します。

詳細については、[パッケージレジストリのConan 1パッケージ](../conan_1_repository/_index.md)を参照してください。

### Conan 2 {#conan-2}

Conan 2の場合:

- GitLabパッケージレジストリをConanレジストリリモートとして追加します。
- [Conan 2パッケージを作成](build_packages.md#conan-2)します。
- `conan upload`またはパッケージレシピを使用して、パッケージを公開します。

詳細については、[パッケージレジストリのConan 2パッケージ](../conan_2_repository/_index.md)を参照してください。

### Composer {#composer}

Composerパッケージをそのプロジェクトの外部で公開することはできません。他のプロジェクトでのComposerパッケージの公開のサポートは、[イシュー250633](https://gitlab.com/gitlab-org/gitlab/-/issues/250633)で提案されています。

### その他すべてのパッケージタイプ {#all-other-package-types}

[GitLabでサポートされているすべてのパッケージタイプ](../_index.md)は、同じGitLabプロジェクトに公開できます。以前のリリースでは、すべてのパッケージタイプを同じプロジェクトに公開できませんでした。
