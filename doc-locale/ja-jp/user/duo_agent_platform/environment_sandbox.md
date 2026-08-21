---
stage: Agent Foundations
group: Agent Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: リモート実行環境サンドボックス
---

{{< history >}}

- GitLab 18.7で`ai_duo_agent_platform_network_firewall`および`ai_dap_executor_connects_over_ws`[フラグ](../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/578048)されました。
- GitLab 18.7で機能フラグ`ai_duo_agent_platform_network_firewall`は[有効](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/215950)になりました。
- GitLab 18.7で機能フラグ`ai_dap_executor_connects_over_ws`は[有効](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/215774)になりました。
- GitLab 18.8で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/work_items/585273)になりました。
- `network_policy`設定がGitLab 18.10で[導入されました](https://gitlab.com/gitlab-org/gitlab/-/work_items/590021)。
- `allow_all_unix_sockets`ネットワークポリシー設定がGitLab 18.11で[導入されました](https://gitlab.com/gitlab-org/gitlab/-/work_items/590871)。
- インスタンスレベルとグループレベルのネットワークアクセス制御は、GitLab 18.11で[導入され](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/229531)、`dap_instance_network_access_controls`および`dap_group_network_access_controls`という名前の[機能フラグ](../../administration/feature_flags/_index.md)が付いています。デフォルトでは無効になっています。
- 機能フラグ`dap_instance_network_access_controls`および`dap_group_network_access_controls`は、GitLab 19.0で[有効化されました](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/235670)。
- 機能フラグ`dap_group_network_access_controls`は、19.2で[削除されました](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/243118)。
- 機能フラグ`dap_instance_network_access_controls`は、19.3で[削除されました](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/244957)。

{{< /history >}}

実行環境サンドボックスは、アプリケーションレベルのネットワークとファイルシステムの分離を実現し、GitLab Duo Agent Platformのリモートフローを不正なネットワークアクセスやデータ流出から保護します。このサンドボックスは、正当なフロー操作に必要な接続を維持しながら、データ流出の試み、外部ソースからの悪意のあるコードの読み込み、不正なデータ収集を防止するように設計されています。

## サンドボックスが適用される条件 {#when-the-sandbox-is-applied}

Anthropic Sandbox Runtime（SRT）がインストールされている互換性のあるDockerイメージを使用すると、実行環境サンドボックスが自動的に適用されます。これには、デフォルトのGitLab Dockerイメージ（リリース[v0.0.6](https://gitlab.com/gitlab-org/duo-workflow/default-docker-image/-/tags/v0.0.6)以降）または[カスタムイメージにSRTがインストールされたもの](#install-anthropic-sandbox-runtime-srt-on-a-custom-image)の使用が含まれます。

サンドボックスは、次の条件を満たす場合に有効になります:

- Anthropic Sandbox Runtime（SRT）はDockerイメージで利用可能です。
- GitLab Duo Agent PlatformのセッションがRunner上で実行されている（ローカル環境はサンドボックス化されません）。

デフォルトとカスタムイメージの設定におけるCI/CD変数の違いについては、[フロー実行変数](flows/execution/execution-variables.md)を参照してください。

## 前提条件 {#prerequisites}

実行環境サンドボックスを使用するには、次の条件を満たしている必要があります:

- プロジェクトでGitLab Duo Agent Platformが有効になっていること。
- 特権Runnerモードが有効になっていること。これは[サンドボックスを機能させるために必須](flows/execution/_index.md#configure-runners-to-execute-flows)です。
- 互換性のあるDockerイメージ: [デフォルトGitLab Docker](https://gitlab.com/gitlab-org/duo-workflow/default-docker-image/container_registry)イメージのバージョン`v0.0.6`以降、または[Anthropic Sandbox Runtime（SRT）がインストールされたカスタムイメージ](#install-anthropic-sandbox-runtime-srt-on-a-custom-image)が該当します。

## 仕組み {#how-it-works}

実行環境サンドボックスは、[Anthropic Sandbox Runtime（SRT）](https://github.com/anthropic-experimental/sandbox-runtime)を使用してフローの実行をラップし、次の保護を行います:

- ネットワーク分離: 実行環境から外部に送信される前にすべてのネットワークリクエストを傍受し、許可リストに登録されたドメインに対して検証します。
- ファイルシステムの制限: 特定のディレクトリへの読み取りおよび書き込みアクセスを制限し、機密ファイルへのアクセスをブロックします。
- グレースフルフォールバック: SRTが使用できない場合や必要なオペレーティングシステムの権限が不足している場合でも、警告メッセージを表示したうえでフローを直接実行します。

## カスタムイメージにAnthropic Sandbox Runtime（SRT）をインストールする {#install-anthropic-sandbox-runtime-srt-on-a-custom-image}

たとえば、[`agent-config.yml`](flows/execution/_index.md#create-the-agent-configuration-file)を使用するカスタムイメージを使用する場合、Anthropic SRTバージョン`0.0.20`以降がインストールされ、利用可能な状態になっている必要があります。

SRTは`npm`を介して`@anthropic-ai/sandbox-runtime`として利用できます。次の例は、Dockerfileでのインストールステージを示しています:

```dockerfile
# Install srt sandboxing with cache clearing and verification
ARG SANDBOX_RUNTIME_VERSION=0.0.20
RUN npm cache clean --force && \
    npm install -g @anthropic-ai/sandbox-runtime@${SANDBOX_RUNTIME_VERSION} && \
    test -s "$(npm root -g)/@anthropic-ai/sandbox-runtime/package.json" && \
    srt --version

```

ランタイム時に、RunnerはSRTが利用可能で動作していることを確認します:

```shell
$ if which srt > /dev/null; then
$ echo "SRT found, creating config..."
SRT found, creating config...
$ echo '{"network":{"allowedDomains":["host.docker.internal","localhost","gitlab.com","*.gitlab.com","duo-workflow-svc.runway.gitlab.net"],"deniedDomains":[],"allowAllUnixSockets":false},"filesystem":{"denyRead":["~/.ssh"],"allowWrite":["./","/tmp"],"denyWrite":["/var/tmp/.gitlab-sandbox"],"allowGitConfig":true}}' > /var/tmp/.gitlab-sandbox/srt-settings.json
$ echo "Testing SRT sandbox capabilities..."
Testing SRT sandbox capabilities...
```

次のエラーがランタイム時に発生する可能性があり、これはSRTの依存関係が利用できないことを示している場合があります:

```shell
Warning: SRT found but can't create sandbox (insufficient privileges), running command directly
```

これを解決するには、次の手順に従います:

1. 次のコマンドを使用して、bashでイメージを検証します:

   ```shell
   docker run --rm -it <image>:<tag> /bin/bash
   ```

1. `srt`を使用します: 

   ```shell
   srt ls
   ```

1. 次のエラーが表示された場合、カスタムイメージに追加の依存関係をインストールする必要があります:

   ```shell
   Error: Sandbox dependencies are not available on this system. Required: ripgrep (rg), bubblewrap (bwrap), and socat.
   ```

## ネットワークおよびファイルシステムの制限 {#network-and-filesystem-restrictions}

実行環境サンドボックスを適用すると、次の制限が適用されます。

### サンドボックス設定を構成する {#configure-sandbox-settings}

サンドボックスの設定の一部を構成するには、[`agent-config.yml`](flows/execution/_index.md#create-the-agent-configuration-file)ファイルを使用します。

デフォルトでは、サンドボックスは次の設定へのアクセスを許可します:

- デフォルトで許可されたドメイン。これらは自動的に設定され、変更または更新することはできません。

### 環境変数 {#environment-variables}

DAPおよびGit操作の実行に必要な環境変数とパラメータのみがサンドボックス環境からアクセス可能です。

### ファイルシステム設定 {#filesystem-configuration}

サンドボックスでは、次のファイルシステムの制限が適用されます:

- 読み取り制限: SSHキー（`~/.ssh`）へのアクセスはブロックされます。
- 書き込み許可: 現在のディレクトリ（`./`）および`/tmp`。
- 書き込み制限: `/var/tmp/.gitlab-sandbox`（サンドボックス設定などのプラットフォーム内部ファイルに使用されます）。
- Git設定へのアクセス: 許可されます。

### ネットワークポリシーを構成する {#configure-a-network-policy}

SRTはデフォルトでGitLabが提供するDockerイメージに含まれています。また、[カスタムイメージにSRTをインストールする](#install-anthropic-sandbox-runtime-srt-on-a-custom-image)こともできます。

SRTがインストールされている場合、フローはデフォルトで次のドメインのみにアクセスできます。これらのドメインは常に許可されており、削除することはできません:

- `localhost`
- `host.docker.internal`
- お使いのGitLabインスタンスドメイン（例: `gitlab.com`、`*.gitlab.com`）
- GitLab Duo Workflow Serviceドメイン

SRTを使用しないカスタムイメージを使用する場合、ネットワーク制限は適用されず、フローはRunnerから到達可能な任意のドメインにアクセスできます。

> [!note]
> `network_policy`では、`allowed_domains`または`denied_domains`に`"*"`を許可しません。SRTは、すべてのネットワークトラフィックを有効にすることをサポートしていません。ただし、ドメインの一部としてワイルドカードは許可されます。例: `"*.domain.com"`。

#### 管理者のネットワークアクセス制御 {#administrator-network-policy-controls}

GitLab.comのトップレベルグループオーナーまたはGitLab Self-Managedのインスタンス管理者がネットワークアクセス制御を構成すると、これらの設定がすべてのフローのベースラインポリシーを定義します。**プロジェクトがネットワークサンドボックス設定を拡張することを許可する**チェックボックスは、プロジェクトのオーナーが`agent-config.yml`で設定を構成する際に、どの設定が適用されるかを決定します。

**柔軟モード**（**プロジェクトがネットワークサンドボックス設定を拡張することを許可する**が有効）:

- `agent-config.yml`の`allowed_domains`は管理者の許可リストとマージされます。
- `agent-config.yml`の`denied_domains`は管理者の拒否リストとマージされます。
- `agent-config.yml`の`include_recommended_allowed`は、管理者の設定を上書きします。
- `agent-config.yml`の`allow_all_unix_sockets`は、管理者の設定を上書きします。

**厳格モード**（**プロジェクトがネットワークサンドボックス設定を拡張することを許可する**が無効）:

- `agent-config.yml`の`denied_domains`は管理者の拒否リストとマージされます。
- `include_recommended_allowed`は、管理者が有効にした設定を厳格化するためにのみ`false`に設定できます。管理者が無効にしている場合、これは効果がありません。
- `allow_all_unix_sockets`は、管理者が有効にした設定を厳格化するためにのみ`false`に設定できます。管理者が無効にしている場合、これは効果がありません。
- `agent-config.yml`からの`allowed_domains`は無視されます。

#### プロジェクトレベルの設定 {#configure-project-level-settings}

追加のドメインを許可または拒否するには、`agent-config.yml`ファイルに`network_policy`を追加します:

```yaml
network_policy:
  include_recommended_allowed: true # default: false
  allow_all_unix_sockets: true      # default: false
  allowed_domains:
    - my-own-site.com
  denied_domains:
    - malicious.com
```

#### Unixソケットアクセスを許可 {#allow-unix-socket-access}

`allow_all_unix_sockets`設定を使用して、ホスト上のすべてのUnixドメインソケットへのフローアクセスを許可します。これはデフォルトで無効になっています。

> [!warning]
> `allow_all_unix_sockets`を有効にすると、すべてのUnixソケットへのアクセスが許可されます。これは必要な場合、かつ信頼できる環境でのみ有効にしてください。

### インスタンスまたはグループのネットワークアクセス制御を構成する {#configure-network-access-controls-for-your-instance-or-group}

{{< history >}}

- インスタンスレベルとグループレベルのネットワークアクセス制御は、GitLab 18.11で[導入され](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/229531)、`dap_instance_network_access_controls`および`dap_group_network_access_controls`という名前の[機能フラグ](../../administration/feature_flags/_index.md)が付いています。デフォルトでは無効になっています。

{{< /history >}}

[プロジェクトレベルの`agent-config.yml`設定](#configure-a-network-policy)に加えて、管理者とトップレベルグループのオーナーは、GitLab UIを通じてネットワークアクセス制御を管理できます。これらの設定は、インスタンスレベル（GitLab Self-Managed）またはトップレベルグループレベル（GitLab.com）に保存され、その配下のすべてのプロジェクトに継承されます。

これらの設定とプロジェクトレベルの`agent-config.yml`を組み合わせる方法については、[管理者のネットワークポリシー制御](#administrator-network-policy-controls)を参照してください。

#### インスタンスレベルのネットワークアクセス制御を設定する {#configure-instance-level-network-access-controls}

前提条件: 

- 管理者である必要があります。

インスタンスレベルのネットワークアクセス制御を設定するには:

1. 右上隅で、**管理者**を選択します。
1. 左側のサイドバーで、**GitLab Duo**を選択します。
1. **設定の変更**を選択します。
1. **データとプライバシー**の下にある**ネットワークアクセス**セクションで、以下の設定を構成します:
   - **推奨ドメインを許可リストに含める**: 推奨ドメインの厳選された許可リストは、自動的に許可リストに含まれます。
   - **すべてのUnixソケットを許可する**: GitLab Duo Agent Platformの操作では、すべてのUnixソケットが許可されます。
   - **プロジェクトがネットワークサンドボックス設定を拡張することを許可する**: プロジェクトのメンテナーまたはオーナーロールを持つユーザーは、`agent-config.yml`ファイルを通じて推奨ドメインを含めたり、追加のドメインを追加したり、すべてのUnixソケットを許可したりできます。
1. オプション。**許可されたドメイン**の下で、許可リストからドメインを追加または削除します。**ブロックされたドメイン**の下で、拒否リストからドメインを追加または削除します。
1. **変更を保存**を選択します。

#### トップレベルグループのネットワークアクセス制御（GitLab.com）を構成する {#configure-top-level-group-network-access-controls-gitlabcom}

前提条件: 

- トップレベルグループのオーナーロールが必要です。
- グループはGitLab.comのトップレベルグループである必要があります。サブグループはトップレベルグループから設定を継承します。

グループレベルのネットワークアクセス制御を構成するには:

1. 上部のバーで、**検索または移動先**を選択して、トップレベルグループを見つけます。
1. 左側のサイドバーで**設定**を選択し、次に**GitLab Duo**を選択します。
1. **設定の変更**を選択します。
1. **データとプライバシー**にある**ネットワークアクセス**セクションで、[インスタンスレベルのネットワークアクセス制御を設定する](#configure-instance-level-network-access-controls)で説明されているのと同じ設定を行います。
1. **変更を保存**を選択します。

#### 関連するAPIリソース {#related-api-resources}

- インスタンスレベルのブール値: [`duoSettingsUpdate`](../../api/graphql/reference/_index.md#mutationduosettingsupdate) GraphQLミューテーション。
- グループレベルのブール値: `ai_settings_attributes`パラメータを使用して、[グループ属性を更新](../../api/groups.md#update-group-attributes) REST API。
- ドメインの許可リストと拒否リスト: [`aiDomainSettingsInstanceUpdate`](../../api/graphql/reference/_index.md#mutationaidomainsettingsinstanceupdate)および[`aiDomainSettingsNamespaceUpdate`](../../api/graphql/reference/_index.md#mutationaidomainsettingsnamespaceupdate) GraphQLミューテーション。

### 許可されたドメインを有効にする {#turn-on-allowed-domains}

パッケージレジストリや開発ツールで使用される外部ドメインへのフローアクセスを許可するには、`include_recommended_allowed`設定を有効にします。

この設定はデフォルトで無効になっています（`false`）。これを有効にするには、`agent-config.yml`ファイルで`include_recommended_allowed`を`true`に設定します。

ネットワークアクセス制御が厳格モード（**プロジェクトがネットワークサンドボックス設定を拡張することを許可する**が無効）で有効になっている場合、`include_recommended_allowed`のみを無効にできます。設定を`true`にしても、管理者が無効にしている場合は効果がありません。

> [!warning]
> `include_recommended_allowed`を有効にすると、広範な外部ドメインへのネットワークアクセスが許可されます。これらのエグレスエンドポイントは、環境からデータを抜き出すために悪用される可能性があります。これは必要な場合、かつ信頼できる環境でのみ有効にしてください。

この設定は、以下のドメインへのアクセスを有効にします:

- `github.com`
- `www.github.com`
- `api.github.com`
- `npm.pkg.github.com`
- `raw.githubusercontent.com`
- `pkg-npm.githubusercontent.com`
- `objects.githubusercontent.com`
- `codeload.github.com`
- `avatars.githubusercontent.com`
- `camo.githubusercontent.com`
- `gist.github.com`
- `gitlab.com`
- `www.gitlab.com`
- `registry.gitlab.com`
- `bitbucket.org`
- `www.bitbucket.org`
- `api.bitbucket.org`
- `registry-1.docker.io`
- `auth.docker.io`
- `index.docker.io`
- `hub.docker.com`
- `www.docker.com`
- `production.cloudflare.docker.com`
- `download.docker.com`
- `gcr.io`
- `*.gcr.io`
- `ghcr.io`
- `mcr.microsoft.com`
- `*.data.mcr.microsoft.com`
- `public.ecr.aws`
- `cloud.google.com`
- `accounts.google.com`
- `gcloud.google.com`
- `storage.googleapis.com`
- `compute.googleapis.com`
- `container.googleapis.com`
- `artifactregistry.googleapis.com`
- `cloudresourcemanager.googleapis.com`
- `oauth2.googleapis.com`
- `www.googleapis.com`
- `login.microsoftonline.com`
- `packages.microsoft.com`
- `dotnet.microsoft.com`
- `dot.net`
- `dev.azure.com`
- `s3.amazonaws.com`
- `*.s3.amazonaws.com`
- `*.codeartifact.amazonaws.com`
- `*.s3.api.aws`
- `*.codeartifact.api.aws`
- `download.oracle.com`
- `yum.oracle.com`
- `registry.npmjs.org`
- `www.npmjs.com`
- `www.npmjs.org`
- `npmjs.com`
- `npmjs.org`
- `yarnpkg.com`
- `registry.yarnpkg.com`
- `pypi.org`
- `www.pypi.org`
- `files.pythonhosted.org`
- `pythonhosted.org`
- `test.pypi.org`
- `pypi.python.org`
- `pypa.io`
- `www.pypa.io`
- `rubygems.org`
- `www.rubygems.org`
- `api.rubygems.org`
- `index.rubygems.org`
- `ruby-lang.org`
- `www.ruby-lang.org`
- `rubyonrails.org`
- `www.rubyonrails.org`
- `rvm.io`
- `get.rvm.io`
- `crates.io`
- `www.crates.io`
- `index.crates.io`
- `static.crates.io`
- `rustup.rs`
- `static.rust-lang.org`
- `www.rust-lang.org`
- `proxy.golang.org`
- `sum.golang.org`
- `index.golang.org`
- `golang.org`
- `www.golang.org`
- `goproxy.io`
- `pkg.go.dev`
- `maven.org`
- `repo.maven.org`
- `central.maven.org`
- `repo1.maven.org`
- `jcenter.bintray.com`
- `gradle.org`
- `www.gradle.org`
- `services.gradle.org`
- `plugins.gradle.org`
- `kotlin.org`
- `www.kotlin.org`
- `spring.io`
- `repo.spring.io`
- `packagist.org`
- `www.packagist.org`
- `repo.packagist.org`
- `nuget.org`
- `www.nuget.org`
- `api.nuget.org`
- `pub.dev`
- `api.pub.dev`
- `hex.pm`
- `www.hex.pm`
- `cpan.org`
- `www.cpan.org`
- `metacpan.org`
- `www.metacpan.org`
- `api.metacpan.org`
- `cocoapods.org`
- `www.cocoapods.org`
- `cdn.cocoapods.org`
- `haskell.org`
- `www.haskell.org`
- `hackage.haskell.org`
- `swift.org`
- `www.swift.org`
- `archive.ubuntu.com`
- `security.ubuntu.com`
- `ubuntu.com`
- `www.ubuntu.com`
- `*.ubuntu.com`
- `ppa.launchpad.net`
- `launchpad.net`
- `www.launchpad.net`
- `dl.k8s.io`
- `pkgs.k8s.io`
- `k8s.io`
- `www.k8s.io`
- `releases.hashicorp.com`
- `apt.releases.hashicorp.com`
- `rpm.releases.hashicorp.com`
- `archive.releases.hashicorp.com`
- `hashicorp.com`
- `www.hashicorp.com`
- `repo.anaconda.com`
- `conda.anaconda.org`
- `anaconda.org`
- `www.anaconda.com`
- `anaconda.com`
- `continuum.io`
- `apache.org`
- `www.apache.org`
- `archive.apache.org`
- `downloads.apache.org`
- `eclipse.org`
- `www.eclipse.org`
- `download.eclipse.org`
- `nodejs.org`
- `www.nodejs.org`
- `sourceforge.net`
- `*.sourceforge.net`
- `packagecloud.io`
- `*.packagecloud.io`
- `json-schema.org`
- `www.json-schema.org`
- `json.schemastore.org`
- `www.schemastore.org`
- `*.modelcontextprotocol.io`

## 警告およびフォールバック動作 {#warnings-and-fallback-behavior}

サンドボックスが利用できない、または適用できない場合:

- フローはサンドボックス保護なしで直接実行される
- CIジョブログ内に警告メッセージが表示され、Runner設定ガイダンスへのリンクが提示される

これにより、サンドボックスを有効にできない場合でもフローの実行が継続され、状況が通知されます。
