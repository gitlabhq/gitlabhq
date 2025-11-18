---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: GitLabリポジトリを作成したり、そのクローンを作成したり、使用したりする方法について説明します。
title: リポジトリ
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

あなたの[リポジトリ](https://git-scm.com/book/en/v2/Git-Basics-Getting-a-Git-Repository)は、あなたのGitLabプロジェクトのコンポーネントです。コードはリポジトリに保存され、バージョン管理で変更を追跡します。

各リポジトリは[GitLabプロジェクト](../_index.md)の一部であり、GitLabプロジェクトなしでは存在できません。プロジェクトは、リポジトリの設定オプションを提供します。

## リポジトリを作成する {#create-a-repository}

リポジトリを作成するには、次のいずれかを行います:

- [プロジェクトを作成する](../_index.md)。
- [既存のプロジェクトをフォークする](forking_workflow.md)。

## リポジトリにファイルを追加する {#add-files-to-a-repository}

リポジトリにファイルを追加できます:

- [プロジェクトを作成する](../_index.md)場合、または
- プロジェクトの作成後、次のオプションを使用します:
  - [Webエディタ](web_editor.md#upload-a-file)
  - [ユーザーインターフェース（UI）](#add-a-file-from-the-ui)
  - [コマンドライン](../../../topics/git/add_files.md)

### UIからファイルを追加する {#add-a-file-from-the-ui}

GitLab UIからファイルを追加またはアップロードするには:

<!-- Original source for this list: doc/user/project/repository/web_editor.md#upload-a-file -->
<!-- For why we duplicated the info, see https://gitlab.com/gitlab-org/gitlab/-/merge_requests/111072#note_1267429478 -->

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. ファイルをアップロードするディレクトリに移動します。
1. ディレクトリ名の横にあるプラスアイコン（{{< icon name="plus" >}}）> **ファイルをアップロード**を選択します。
1. ファイルをドロップまたはアップロードします。
1. コミットメッセージを入力します。
1. オプション。変更を加えてマージリクエストを作成するには、**ターゲットブランチ**に、リポジトリの[デフォルトブランチ](branches/default.md)ではないブランチ名を入力します。
1. **ファイルをアップロード**を選択します。

## リポジトリへの変更をコミットする {#commit-changes-to-a-repository}

リポジトリ内のブランチへの変更をコミットできます。コマンドラインを使用する場合は、[`git commit`](../../../topics/git/commands.md#git-commit)を使用します。

コミットを使用してコミュニケーションとコラボレーションを改善する方法、パイプラインをトリガーまたはスキップする方法、変更を取り消す方法については、[コミット](../merge_requests/commits.md)を参照してください。

## リポジトリのクローンを作成する {#clone-a-repository}

以下を使用してリポジトリのクローンを作成できます:

- コマンドライン:
  - [SSHを使用してクローンを作成する](../../../topics/git/clone.md#clone-with-ssh)
  - [HTTPSを使用してクローンを作成する](../../../topics/git/clone.md#clone-with-https)
- GitLab UI:
  - [Apple Xcodeでクローンを作成して開く](../../../topics/git/clone.md#clone-and-open-in-apple-xcode)
  - [Visual Studio Codeでクローンを作成して開く](../../../topics/git/clone.md#clone-and-open-in-visual-studio-code)
  - [IntelliJ IDEAでクローンを作成して開く](../../../topics/git/clone.md#clone-and-open-in-intellij-idea)

## リポジトリのソースコードをダウンロードする {#download-repository-source-code}

リポジトリのソースコードを圧縮ファイルとしてダウンロードするには、次の手順に従います:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. ファイルリストの上にある**コード**を選択します。
1. オプションから、ダウンロードするファイルを選択します:

   - **Source code**（ソースコード）:

     表示している現在のブランチからソースコードをダウンロードします。利用可能な拡張子: `zip`、`tar`、`tar.gz`、`tar.bz2`。

   - **Directory**（ディレクトリ）:

     特定のディレクトリをダウンロードします。サブディレクトリを表示している場合にのみ表示されます。利用可能な拡張子: `zip`、`tar`、`tar.gz`、`tar.bz2`。

   - **アーティファクト**:

     最新のCI/CDジョブからアーティファクトをダウンロードします。

生成されたアーカイブのチェックサムは、リポジトリ自体が変更されていなくても変更される可能性があります。たとえば、GitまたはGitLabが使用するサードパーティライブラリが変更された場合に発生します。

## Gitリビジョンでリポジトリを表示 {#view-repository-by-git-revision}

特定のGitリビジョン（コミットSHA、ブランチ名、タグなど）のすべてのリポジトリファイルとフォルダーを表示するには、次の手順に従います:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. 上部にある**Gitリビジョンの選択**ドロップダウンリストを開くには、選択します。
1. Gitリビジョンを選択または検索します。

また、[commits](commits/_index.md)ページから、特定のGitリビジョンのファイルを表示したり、参照したりすることもできます。

## リポジトリの言語 {#repository-languages}

GitLabは、デフォルトブランチで使用されているプログラミング言語を検出します。この情報は、**Project overview**（プロジェクトの概要）ページに表示されます。

![リポジトリ言語バー](img/repository_languages_v15_2.png)

新しいファイルが追加されると、この情報の更新に最大5分かかる場合があります。

### リポジトリ言語を追加する {#add-repository-languages}

すべてのファイルが検出され、**Project overview**（プロジェクトの概要）ページにリストされるわけではありません。ドキュメント、ベンダーコード、[ほとんどのマークアップ言語](files/_index.md#supported-markup-languages)は除外されます。サポートされているファイルと言語のリストを表示するには、[サポートされているデータ型](https://github.com/github/linguist/blob/master/lib/linguist/languages.yml)を参照してください。

この動作を変更し、デフォルト設定に追加のファイルタイプを含めるには:

1. リポジトリのルートディレクトリに、`.gitattributes`という名前のファイルを作成します。
1. 特定のファイルタイプを含めるようにGitLabに指示する行を追加します。たとえば、`.proto`ファイルを有効にするには、以下を追加します:

   ```plaintext
   *.proto linguist-detectable=true
   ```

この機能は、過剰なCPUを使用する可能性があります。問題が発生した場合は、[リポジトリの言語: 過剰なCPU使用率](files/_index.md#repository-languages-excessive-cpu-use)のトラブルシューティングセクションを参照してください。

## リポジトリのコントリビューター分析 {#repository-contributor-analytics}

選択したプロジェクトブランチへのコミット数の経時的な折れ線グラフ、および各プロジェクトメンバーによるコミット数の折れ線グラフを表示できます。詳細については、[コントリビューター分析](../../analytics/contributor_analytics.md)を参照してください。

## リポジトリの履歴グラフ {#repository-history-graph}

リポジトリグラフには、ブランチやマージなど、リポジトリネットワークの視覚的な履歴が表示されます。このグラフは、リポジトリ内の変更の流れを確認するのに役立ちます。

リポジトリの履歴グラフを表示するには、プロジェクトの**コード** > **リポジトリグラフ**に移動します。

![リポジトリ内のコミットの流れを示すグラフ。](img/repo_graph_v17_9.png)

## リポジトリパスの変更 {#repository-path-changes}

リポジトリパスが変更されると、GitLabはリダイレクトを使用して、古い場所から新しい場所への移行を処理します。

[ユーザーの名前を変更](../../profile/_index.md#change-your-username)したり、[グループパスを変更](../../group/manage.md#change-a-groups-path)したり、[リポジトリの名前を変更](../working_with_projects.md#rename-a-repository)したりすると、次のようになります:

- ネームスペースのURLとその配下にあるすべて（プロジェクトなど）は、新しいURLにリダイレクトされます。
- ネームスペース配下のプロジェクトのGitリモートURLは、新しいリモートURLにリダイレクトされます。場所が変更されたリポジトリにプッシュまたはプルすると、リモートを更新するように促す警告メッセージが表示されます。名前変更後も、自動化スクリプトまたはGitクライアントは引き続き動作します。
- リダイレクトは、元のパスが別のグループ、ユーザー、またはプロジェクトによって要求されない限り使用できます。
- [APIリダイレクト](../../../api/rest/_index.md#redirects)は、明示的にフォローする必要がある場合があります。

パスを変更した後、次のリソースで既存のURLを更新する必要があります:

- [インクルードステートメント](../../../ci/yaml/includes.md) （[`include:component`](../../../ci/components/_index.md)を除く）: そうしないと、パイプラインは構文エラーで失敗します。CI/CDコンポーネントの参照は、リダイレクトに従うことができます。
- 数値のネームスペースおよびプロジェクトIDの代わりに[エンコードされたパス](../../../api/rest/_index.md#namespaced-paths)を使用するネームスペースAPIコール。
- [Dockerイメージ参照](../../../ci/yaml/_index.md#image)。
- プロジェクトまたはネームスペースを指定する変数。
- [CODEOWNERSファイル](../codeowners/_index.md#codeowners-file)。

## 関連トピック {#related-topics}

- [VS Code用GitLab Workflow拡張機能](../../../editor_extensions/visual_studio_code/_index.md)
- [ロックファイルを使用して変更の競合を防ぐ](../file_lock.md)
- [リポジトリAPI](../../../api/repositories.md)
- [ファイル](files/_index.md)
- [ブランチ](branches/_index.md)
- [ディレクトリを作成する](web_editor.md#create-a-directory)
- [ファイル履歴を検索する](files/git_history.md)
- [行ごとの変更を識別する（Git blame）](files/git_blame.md)

## トラブルシューティング {#troubleshooting}

### リポジトリへのプッシュのシーケンスを検索する {#search-sequence-of-pushes-to-a-repository}

コミットが「見つからない」と思われる場合は、リポジトリへのプッシュのシーケンスを検索します。[このStackOverflowの記事](https://stackoverflow.com/questions/13468027/the-mystery-of-the-missing-commit-across-merges)では、強制プッシュなしでこの状態になる方法が説明されています。別の原因として、`git reset`操作でHEAD refを変更する[サーバーフック](../../../administration/server_hooks.md)が誤って設定されていることが考えられます。

ターゲットブランチの以下のサンプルコードからの出力を確認すると、出力のステップ実行時に、from/toコミットに不連続性が見られます。新しいプッシュの`commit_from`は、前のプッシュの`commit_to`と等しくなければなりません。そのシーケンスの中断は、1つ以上のコミットがリポジトリの履歴から「失われた」ことを示します。

[Railsコンソール](../../../administration/operations/rails_console.md#starting-a-rails-console-session)を使用して、次の例では、最後の100件のプッシュをチェックし、`commit_from`エントリと`commit_to`エントリを出力します:

```ruby
p = Project.find_by_full_path('project/path')
p.events.pushed_action.last(100).each do |e|
  printf "%-20.20s %8s...%8s (%s)", e.push_event_payload[:ref], e.push_event_payload[:commit_from], e.push_event_payload[:commit_to], e.author.try(:username)
end ; nil
```

シーケンスの中断を示す出力例（4行目）:

```plaintext
master f21b07713251e04575908149bdc8ac1f105aabc3...6bc56c1f46244792222f6c85b11606933af171de root
master 6bc56c1f46244792222f6c85b11606933af171de...132da6064f5d3453d445fd7cb452b148705bdc1b root
master 132da6064f5d3453d445fd7cb452b148705bdc1b...a62e1e693150a2e46ace0ce696cd4a52856dfa65 root
master 58b07b719a4b0039fec810efa52f479ba1b84756...f05321a5b5728bd8a89b7bf530aa44043c951dce root
master f05321a5b5728bd8a89b7bf530aa44043c951dce...7d02e575fd790e76a3284ee435368279a5eb3773 root
```

### エラー: Xcodeがリポジトリのクローン作成に失敗する {#error-xcode-fails-to-clone-repository}

GitLabは、[許可されたSSHキーのリストを制限する](../../../security/ssh_keys_restrictions.md)オプションを提供します。SSHキーが許可リストにない場合は、`The repository rejected the provided credentials`のようなエラーが発生する可能性があります。

この問題を解決するには、[サポートされているSSHキータイプ](../../ssh.md#supported-ssh-key-types)のガイドラインに適合する新しいSSHキーペアを作成します。サポートされているSSHキーを生成したら、リポジトリのクローン作成を再度試してください。
