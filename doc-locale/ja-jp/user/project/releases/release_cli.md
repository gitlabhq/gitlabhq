---
stage: Deploy
group: Environments
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitLab Release CLIツール
---

{{< alert type="warning" >}}

**現在、`release-cli`はメンテナンスモードです**。`release-cli`に新しい機能は追加されません。新しい機能の開発は、すべて`glab`コマンドラインインターフェース（CLI）で行われるため、可能な限り[`glab` CLI](../../../editor_extensions/gitlab_cli/_index.md)を使用してください。[イシュー cli#7450](https://gitlab.com/gitlab-org/cli/-/issues/7450)では`glab` CLIの成熟に伴い、`release-cli`をメンテナンスモードから非推奨へ移行することが提案されています。

{{< /alert >}}

[GitLab Release CLI（`release-cli`）](https://gitlab.com/gitlab-org/release-cli)は、コマンドラインまたはCI/CDパイプラインからリリースを管理するためのコマンドラインツールです。Release CLIを使用することで、リリースの作成、更新、変更、削除を行うことができます。

[CI/CDジョブを使用してリリースを作成する](_index.md#creating-a-release-by-using-a-cicd-job)と、`release`キーワードエントリがBashコマンドに変換され、`release-cli`ツールを含むDockerコンテナに送信されます。その後、ツールがリリースを作成します。

`release-cli`ツールを[`script`](../../../ci/yaml/_index.md#script)から直接呼び出すこともできます。次に例を示します。

```shell
release-cli create --name "Release $CI_COMMIT_SHA" --description \
  "Created using the release-cli $EXTRA_DESCRIPTION" \
  --tag-name "v${MAJOR}.${MINOR}.${REVISION}" --ref "$CI_COMMIT_SHA" \
  --released-at "2020-07-15T08:00:00Z" --milestone "m1" --milestone "m2" --milestone "m3" \
  --assets-link "{\"name\":\"asset1\",\"url\":\"https://example.com/assets/1\",\"link_type\":\"other\"}"
```

## Shell executor用の`release-cli`をインストールする

{{< details >}}

- プラン: Free、Premium、Ultimate
- 製品: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

`release-cli`バイナリは、[パッケージレジストリ](https://gitlab.com/gitlab-org/release-cli/-/packages)から入手できます。

Shell executorでRunnerを使用する場合、[サポートされているOSおよびアーキテクチャ](https://gitlab.com/gitlab-org/release-cli/-/packages)用に`release-cli`を手動でダウンロードしてインストールできます。インストールすると、[`release`キーワード](../../../ci/yaml/_index.md#release)をCI/CDジョブで使用できるようになります。

### Unix/Linuxにインストールする

1. GitLabパッケージレジストリから該当するシステム用のバイナリをダウンロードします。たとえば、amd64システムの場合、以下によりダウンロードできます。

   ```shell
   curl --location --output /usr/local/bin/release-cli "https://gitlab.com/api/v4/projects/gitlab-org%2Frelease-cli/packages/generic/release-cli/latest/release-cli-linux-amd64"
   ```

1. 実行権限を付与します。

   ```shell
   sudo chmod +x /usr/local/bin/release-cli
   ```

1. `release-cli`が使用できることを確認します。

   ```shell
   $ release-cli -v

   release-cli version 0.15.0
   ```

### PowerShellでWindowsにインストールする

1. システム内の任意の場所（`C:\GitLab\Release-CLI\bin`など）にフォルダーを作成します。

   ```shell
   New-Item -Path 'C:\GitLab\Release-CLI\bin' -ItemType Directory
   ```

1. 実行可能ファイルをダウンロードします。

   ```shell
   PS C:\> Invoke-WebRequest -Uri "https://gitlab.com/api/v4/projects/gitlab-org%2Frelease-cli/packages/generic/release-cli/latest/release-cli-windows-amd64.exe" -OutFile "C:\GitLab\Release-CLI\bin\release-cli.exe"

       Directory: C:\GitLab\Release-CLI
   Mode                LastWriteTime         Length Name
   ----                -------------         ------ ----
   d-----        3/16/2021   4:17 AM                bin
   ```

1. ディレクトリを`$env:PATH`に追加します。

   ```shell
   $env:PATH += ";C:\GitLab\Release-CLI\bin"
   ```

1. `release-cli`が使用できることを確認します。

   ```shell
   PS C:\> release-cli -v

   release-cli version 0.15.0
   ```
