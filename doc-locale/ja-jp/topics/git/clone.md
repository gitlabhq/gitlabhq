---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: さまざまなプロトコル（SSHまたはHTTPS）とさまざまなIDEを使用して、GitLabサーバーからGitリポジトリのクローンを作成する方法を学びます。
title: Gitリポジトリのクローンをローカルコンピューターに作成する
---

Gitリポジトリのクローンをローカルコンピューターに作成できます。このアクションにより、リポジトリのコピーが作成され、コンピューターとGitLabサーバー間で変更を同期する接続が確立されます。この接続には認証情報を追加する必要があります。[SSHを使用してクローンを作成する](#clone-with-ssh)か、[HTTPSを使用してクローンを作成する](#clone-with-https)ことができます。認証方法として推奨されるのは、SSHです。

リポジトリのクローンを作成:

- すべてのプロジェクトファイル、履歴、メタデータをローカルマシンにダウンロードします。
- ファイルの最新バージョンを使用して作業ディレクトリを作成します。
- 今後の変更を同期するために、リモート追跡を設定します。
- 完全なコードベースへのオフラインアクセスを提供します。
- プロジェクトにコードをコントリビュートする基盤を確立します。

## SSHを使用してクローンを作成する {#clone-with-ssh}

認証を1回のみにする場合は、SSHを使用してクローンを作成します。

1. [SSHのドキュメント](../../user/ssh.md)の手順に従って、GitLabで認証します。
1. 左側のサイドバーで、**検索または移動先**を選択して、クローンを作成するプロジェクトを見つけます。
1. プロジェクトの概要ページの右上隅で、**コード**を選択し、**SSHでクローン**のURLをコピーします。
1. ターミナルを開いて、ファイルのクローンを作成するディレクトリに移動します。Gitはリポジトリ名を使用してフォルダーを自動的に作成し、そのフォルダーにファイルをダウンロードします。
1. 以下のコマンドを実行します。

   ```shell
   git clone <copied URL>
   ```

1. ファイルを表示するには、次のとおり、新しいディレクトリに移動します。

   ```shell
   cd <new directory>
   ```

## HTTPSを使用してクローンを作成する {#clone-with-https}

コンピューターとGitLabの間でオペレーションを実行するたびに認証を行う場合は、HTTPSを使用してクローンを作成します。[OAuth認証情報ヘルパー](../../user/profile/account/two_factor_authentication.md#oauth-credential-helpers)を使用すると、手動で認証する回数を低減できるため、HTTPSエクスペリエンスがシームレスになります。

1. 左側のサイドバーで、**検索または移動先**を選択して、クローンを作成するプロジェクトを見つけます。
1. プロジェクトの概要ページの右上隅で、**コード**を選択し、**HTTPSでクローン**のURLをコピーします。
1. ターミナルを開いて、ファイルのクローンを作成するディレクトリに移動します。
1. 以下のコマンドを実行します。Gitはリポジトリ名を使用してフォルダーを自動的に作成し、そのフォルダーにファイルをダウンロードします。

   ```shell
   git clone <copied URL>
   ```

1. GitLabがユーザー名とパスワードを要求します。

   アカウントで2要素認証（2FA）を有効にしている場合、アカウントのパスワードは使用できません。代わりに、以下のいずれかを実行できます。

   - `read_repository`権限または`write_repository`権限がある[トークンを使用してクローンを作成](#clone-using-a-token)します。
   - [OAuth認証情報ヘルパー](../../user/profile/account/two_factor_authentication.md#oauth-credential-helpers)をインストールします。

   2FAを有効にしていない場合は、アカウントのパスワードを使用します。

1. ファイルを表示するには、次のとおり、新しいディレクトリに移動します。

   ```shell
   cd <new directory>
   ```

{{< alert type="note" >}}

Windowsでパスワードを複数回間違って入力し、`Access denied`メッセージが表示される場合は、`git clone https://namespace@gitlab.com/gitlab-org/gitlab.git`のパスにネームスペース（ユーザー名またはグループ）を追加します。

{{< /alert >}}

### トークンを使用してクローンを作成する {#clone-using-a-token}

次の場合、トークンを使用してHTTPSでクローンを作成します。

- 2FAを使用する場合
- 単数または複数のリポジトリをスコープとする、取り消し可能な認証情報セットが必要な場合

HTTPS経由でクローンを作成する場合、次のいずれかのトークンを使用して認証できます。

- [パーソナルアクセストークン](../../user/profile/personal_access_tokens.md)
- [デプロイトークン](../../user/project/deploy_tokens/_index.md)
- [プロジェクトアクセストークン](../../user/project/settings/project_access_tokens.md)
- [グループアクセストークン](../../user/group/settings/group_access_tokens.md)

例は次のとおりです。

```shell
git clone https://<username>:<token>@gitlab.example.com/tanuki/awesome_project.git
```

## Apple Xcodeでクローンを作成して開く {#clone-and-open-in-apple-xcode}

`.xcodeproj`ディレクトリまたは`.xcworkspace`ディレクトリがあるプロジェクトの場合、macOSのXcodeにクローンを作成できます。

1. GitLab UIからプロジェクトの概要ページに移動します。
1. 右上隅で**コード**を選択します。
1. **Xcode**を選択します。

プロジェクトのクローンがコンピューターに作成され、Xcodeを開くように求めるプロンプトが表示されます。

## Visual Studio Codeでクローンを作成して開く {#clone-and-open-in-visual-studio-code}

すべてのプロジェクトについて、GitLabユーザーインターフェースからVisual Studio Codeにクローンを作成できます。別の方法として、[VS Code用GitLab Workflow拡張機能](../../editor_extensions/visual_studio_code/_index.md)をインストールして、Visual Studio Codeからクローンを作成することもできます。

前提要件:

- [Visual Studio Code](https://code.visualstudio.com/)をローカルマシンにインストールする必要があります。他のバージョンのVS Code、たとえばVS Code InsidersやVSCodiumなどはサポートされていません。
- [ブラウザをIDEプロトコル用に設定](#configure-browsers-for-ide-protocols)します。

- GitLabインターフェースから:
  1. プロジェクトの概要ページに移動します。
  1. 右上隅で**コード**を選択します。
  1. **IDEで開く** で、**Visual Studio Code (SSH)** または **Visual Studio Code (HTTPS)** を選択します。
  1. プロジェクトのクローンを作成するフォルダーを選択します。

     Visual Studio Codeがプロジェクトのクローンを作成すると、作成先のフォルダーが開きます。
- [拡張機能](../../editor_extensions/visual_studio_code/_index.md)をインストールしたVisual Studio Codeから、拡張機能の[`Git: Clone`コマンド](https://marketplace.visualstudio.com/items?itemName=GitLab.gitlab-workflow#clone-gitlab-projects)を使用します。

## IntelliJ IDEAでクローンを作成して開く {#clone-and-open-in-intellij-idea}

すべてのプロジェクトについて、GitLabユーザーインターフェースから[IntelliJ IDEA](https://www.jetbrains.com/idea/)にクローンを作成できます。

前提要件:

- [IntelliJ IDEA](https://www.jetbrains.com/idea/)がローカルマシンにインストールされている必要があります。
- [ブラウザをIDEプロトコル用に設定](#configure-browsers-for-ide-protocols)します。

これを行うには、次の手順に従います。

1. プロジェクトの概要ページに移動します。
1. 右上隅で**コード**を選択します。
1. **IDEで開く** で、**IntelliJ IDEA (SSH)** または **IntelliJ IDEA (HTTPS)** を選択します。

## ブラウザーをIDEプロトコル用に設定する {#configure-browsers-for-ide-protocols}

**IDEで開く**機能が動作するようにするには、ブラウザが`vscode://`や`jetbrains://`などのカスタムアプリケーションプロトコルを処理するように設定する必要があります。

### Firefox {#firefox}

必要なアプリケーションがシステムにインストールされている場合、Firefoxはカスタムプロトコルを自動的に処理します。カスタムプロトコルリンクを最初に選択すると、ダイアログが開き、アプリケーションを開くかどうかの確認を求められます。**リンクを開く**を選択して、Firefoxでアプリケーションを開けるようにします。

今後プロンプトを表示しないようにするには、チェックボックスをオンにして選択内容を記憶させます。

プロンプトダイアログが開かない場合は、Firefoxを手動で設定する必要があります。

1. Firefoxを開きます。
1. 右上にある**アプリケーションメニューを開く**（{{< icon name="hamburger" >}}）を選択します。
1. **アプリケーション**セクションを検索するか、そこに移動します。
1. リストから目的のアプリケーションを見つけて選択します。たとえば、`vscode`や`jetbrains`です。
1. ドロップダウンリストからVisual Studio CodeまたはIntelliJ IDEAを選択するか、**その他を使用...** を選択して実行可能ファイルを見つけます。

優先するIDEがリストにない場合は、対応するリンクを最初に選択したときに、アプリケーションを選択するように求められます。

### Chrome {#chrome}

必要なアプリケーションがシステムにインストールされている場合、Chromeはカスタムプロトコルを自動的に処理します。Chromeでカスタムプロトコルリンクを最初に選択すると、ダイアログが開き、アプリケーションを開くかどうかの確認を求められます。**オープン**を選択して、Chromeでアプリケーションを開けるようにします。

今後プロンプトを表示しないようにするには、チェックボックスをオンにして選択内容を記憶させます。

## クローンのサイズを小さくする {#reduce-clone-size}

Gitリポジトリはサイズが大きくなるにつれて、以下の理由で処理しづらくなる可能性があります。

- ダウンロードが必要な履歴の量が多い。
- 必要なディスク容量が多い。

[部分的なクローン作成](https://git-scm.com/docs/partial-clone)は、リポジトリの完全なコピーがなくてもGitが機能できるようにする、パフォーマンスの最適化です。このような対処は、Gitが非常にサイズの大きいリポジトリをより適切に処理できるようにすることを目的に提供されています。

Git 2.22.0以降が必要です。

### ファイルサイズでフィルタリングする {#filter-by-file-size}

通常、Gitにサイズの大きいバイナリファイルを保存することは推奨されません。追加されたサイズが大きいファイルはすべて、その後クローン作成または変更のフェッチを行うすべてのユーザーによってダウンロードされるためです。このようなファイルのダウンロードは時間がかかり、特に低速であったり不安定であったりするインターネット接続から作業を行う場合には問題になります。

ファイルサイズでのフィルターを使用して部分的なクローン作成を使用すると、問題のあるサイズの大きいファイルをクローン作成やフェッチ対象から除外することで、この問題を解決できます。Gitは、見つからないファイルがあると、オンデマンドでのダウンロードとして処理します。

リポジトリのクローンを作成する際に、`--filter=blob:limit=<size>`引数を使用します。たとえば、1メガバイトを超えるファイルを除外してリポジトリのクローンを作成するには、以下を実行します。

```shell
git clone --filter=blob:limit=1m git@gitlab.com:gitlab-com/www-gitlab-com.git
```

これにより、次のとおりの出力が生成されます。

```shell
Cloning into 'www-gitlab-com'...
remote: Enumerating objects: 832467, done.
remote: Counting objects: 100% (832467/832467), done.
remote: Compressing objects: 100% (207226/207226), done.
remote: Total 832467 (delta 585563), reused 826624 (delta 580099), pack-reused 0
Receiving objects: 100% (832467/832467), 2.34 GiB | 5.05 MiB/s, done.
Resolving deltas: 100% (585563/585563), done.
remote: Enumerating objects: 146, done.
remote: Counting objects: 100% (146/146), done.
remote: Compressing objects: 100% (138/138), done.
remote: Total 146 (delta 8), reused 144 (delta 8), pack-reused 0
Receiving objects: 100% (146/146), 471.45 MiB | 4.60 MiB/s, done.
Resolving deltas: 100% (8/8), done.
Updating files: 100% (13008/13008), done.
Filtering content: 100% (3/3), 131.24 MiB | 4.65 MiB/s, done.
```

出力が長くなるのは、Gitが以下の処理を行うためです。

1. 1メガバイトを超えるファイルを除外してリポジトリのクローンを作成する。
1. デフォルトのブランチをチェックアウトするために必要となる、見つからないサイズの大きいファイルをダウンロードする。

ブランチを変更すると、Gitはさらに見つからないファイルをダウンロードする可能性があります。

### オブジェクトタイプでフィルタリングする {#filter-by-object-type}

数百万におよぶファイルや長い履歴があるリポジトリの場合、すべてのファイルを除外し、[`git sparse-checkout`](https://git-scm.com/docs/git-sparse-checkout)を使用して、実行コピーのサイズを低減できます。

```shell
# Clone the repo excluding all files
$ git clone --filter=blob:none --sparse git@gitlab.com:gitlab-com/www-gitlab-com.git
Cloning into 'www-gitlab-com'...
remote: Enumerating objects: 678296, done.
remote: Counting objects: 100% (678296/678296), done.
remote: Compressing objects: 100% (165915/165915), done.
remote: Total 678296 (delta 472342), reused 673292 (delta 467476), pack-reused 0
Receiving objects: 100% (678296/678296), 81.06 MiB | 5.74 MiB/s, done.
Resolving deltas: 100% (472342/472342), done.
remote: Enumerating objects: 28, done.
remote: Counting objects: 100% (28/28), done.
remote: Compressing objects: 100% (25/25), done.
remote: Total 28 (delta 0), reused 12 (delta 0), pack-reused 0
Receiving objects: 100% (28/28), 140.29 KiB | 341.00 KiB/s, done.
Updating files: 100% (28/28), done.

$ cd www-gitlab-com

$ git sparse-checkout set data --cone
remote: Enumerating objects: 301, done.
remote: Counting objects: 100% (301/301), done.
remote: Compressing objects: 100% (292/292), done.
remote: Total 301 (delta 16), reused 102 (delta 9), pack-reused 0
Receiving objects: 100% (301/301), 1.15 MiB | 608.00 KiB/s, done.
Resolving deltas: 100% (16/16), done.
Updating files: 100% (302/302), done.
```

詳細については、[`sparse-checkout`](https://git-scm.com/docs/git-sparse-checkout)のGitドキュメントを参照してください。

### ファイルパスでフィルタリングする {#filter-by-file-path}

`--filter=sparse:oid=<blob-ish>`フィルター仕様を使用すると、部分的なクローン作成とスパースチェックアウト間のインテグレーションがより緊密になります。このフィルタリングモードでは、`.gitignore`ファイルと同様の形式を使用して、クローン作成やフェッチ時の対象とするファイルを指定できます。

{{< alert type="warning" >}}

`sparse`フィルターを使用した部分的なクローン作成は、現時点では実験段階です。クローン作成時やフェッチ時にスピードが落ちて[Gitaly](../../administration/gitaly/_index.md)リソースの使用率が大幅に増大する可能性があります。代わりに[すべてのblobをフィルタリングしてスパースチェックアウトを使用](#filter-by-object-type)します。[`git-sparse-checkout`](https://git-scm.com/docs/git-sparse-checkout)により、このようなタイプの部分的なクローン作成が簡素化され、この制限を克服できるためです。

{{< /alert >}}

詳細については、[`rev-list-options`](https://git-scm.com/docs/git-rev-list#Documentation/git-rev-list.txt---filterltfilter-specgt)のGitドキュメントを参照してください。

1. フィルター仕様を作成します。たとえば、数多くのアプリケーションがそれぞれルートのさまざまなサブディレクトリに存在する、モノリシックなリポジトリを想定します。次のとおり`shiny-app/.filterspec`ファイルを作成します。

   ```plaintext
   # Only the paths listed in the file will be downloaded when performing a
   # partial clone using `--filter=sparse:oid=shiny-app/.gitfilterspec`

   # Explicitly include filterspec needed to configure sparse checkout with
   # git config --local core.sparsecheckout true
   # git show master:snazzy-app/.gitfilterspec >> .git/info/sparse-checkout
   shiny-app/.gitfilterspec

   # Shiny App
   shiny-app/

   # Dependencies
   shimmery-app/
   shared-component-a/
   shared-component-b/
   ```

1. パスを使用してクローンを作成し、フィルタリングします。cloneコマンドを使用する`--filter=sparse:oid`のサポートは、スパースチェックアウトと完全には統合されていません。

   ```shell
   # Clone the filtered set of objects using the filterspec stored on the
   # server. WARNING: this step may be very slow!
   git clone --sparse --filter=sparse:oid=master:shiny-app/.gitfilterspec <url>

   # Optional: observe there are missing objects that we have not fetched
   git rev-list --all --quiet --objects --missing=print | wc -l
   ```

   {{< alert type="warning" >}}

   `bash`、ZshなどのGitインテグレーション、Git状態情報を自動的に表示するエディタは多くの場合、`git fetch`を実行して、リポジトリ全体をフェッチします。このようなインテグレーションは無効にするか、再設定する必要がある場合があります。

   {{< /alert >}}

### 部分的なクローン作成のフィルタリングを削除する {#remove-partial-clone-filtering}

部分的なクローン作成のフィルタリングを使用したGitリポジトリのフィルタリングは削除できます。フィルタリングを削除するには以下を実行します。

1. フィルターが除外した内容をすべてフェッチして、リポジトリが完全であることを確認します。`git sparse-checkout`を使用している場合は、`git sparse-checkout disable`を使用して無効にします。詳細については、[`disable`のドキュメント](https://git-scm.com/docs/git-sparse-checkout#Documentation/git-sparse-checkout.txt-emdisableem)を参照してください。

   次に、通常どおり`fetch`を実行して、リポジトリが完全であることを確認します。特に`git sparse-checkout`を使用していない場合に、フェッチするオブジェクトが不足していないかを確認します。以下のコマンドを使用できます。

   ```shell
   # Show missing objects
   git rev-list --objects --all --missing=print | grep -e '^\?'

   # Show missing objects without a '?' character before them (needs GNU grep)
   git rev-list --objects --all --missing=print | grep -oP '^\?\K\w+'

   # Fetch missing objects
   git fetch origin $(git rev-list --objects --all --missing=print | grep -oP '^\?\K\w+')

   # Show number of missing objects
   git rev-list --objects --all --missing=print | grep -e '^\?' | wc -l
   ```

1. すべてをリパックします。これはたとえば、`git repack -a -d`を使用して実行できます。これにより、`.git/objects/pack/`に残るのは以下の3つのファイルのみとなります。
   - `pack-<SHA1>.pack`ファイル
   - 対応する`pack-<SHA1>.idx`ファイル
   - `pack-<SHA1>.promisor`ファイル

1. `.promisor`ファイルを削除します。上記のステップでは、`pack-<SHA1>.promisor`ファイルが1つだけ残っているはずです。これは空であるはずであり、削除する必要があります。

1. 部分的なクローン作成の設定を削除します。部分的なクローン作成に関連する設定変数は、Git設定ファイルから削除する必要があります。通常、削除する必要がある設定は次のとおりです。
   - `remote.origin.promisor`
   - `remote.origin.partialclonefilter`
