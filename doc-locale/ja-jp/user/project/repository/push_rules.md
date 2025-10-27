---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: プッシュルールを使用して、リポジトリが受け入れるGitコミットの内容と形式を制御します。コミットメッセージの標準を設定し、シークレットや認証情報が誤って追加されないようにします。
title: プッシュルール
---

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 16.3で、プッシュルールの正規表現の最大長が255文字から511文字に[変更されました](https://gitlab.com/gitlab-org/gitlab/-/issues/411901)。

{{< /history >}}

プッシュルールは、使いやすいインターフェースで有効にできる[`pre-receive` Gitフック](https://git-scm.com/book/en/v2/Customizing-Git-Git-Hooks#:~:text=pre%2Dreceive,with%20the%20push.)です。プッシュルールを使用すると、リポジトリにプッシュできるものとプッシュできないものをより詳細に制御できます。GitLabには[保護ブランチ](branches/protected.md)がありますが、次のような、より具体的なルールが必要になる場合があります:

- コミットの内容を評価する。
- コミットメッセージが期待される形式に一致することを確認する。
- [ブランチ名のルール](branches/_index.md#name-your-branch)を適用する。
- ファイルの詳細を評価する。
- Gitタグの削除を防ぐ。
- 署名されたコミットが必要です。

GitLabのプッシュルールの正規表現では、[RE2構文](https://github.com/google/re2/wiki/Syntax)が使用されます。[regex101正規表現テスター](https://regex101.com/)でテストできます。各正規表現は511文字に制限されています。

カスタムプッシュルールには、[サーバーフック](../../../administration/server_hooks.md)を使用します。

{{< alert type="note" >}}

プッシュルールは、フォークした同期中は回避されます。アップストリームプロジェクトから[フォークを更新](forking_workflow.md#update-your-fork)すると、変更はフォークしたのプッシュルールに対する検証なしに直接適用されます。

{{< /alert >}}

## グローバルプッシュルールを有効にする {#enable-global-push-rules}

すべての新しいプロジェクトが継承するプッシュルールを作成できますが、プロジェクトまたは[グループ](../../group/access_and_permissions.md#group-push-rules)でオーバーライドできます。グローバルプッシュルールを設定した後に作成されたすべてのプロジェクトは、この設定を継承します。ただし、既存の各プロジェクトは、[プロジェクトごとにグローバルプッシュルールをオーバーライド](#override-global-push-rules-per-project)で説明されているプロセスを使用して手動で更新する必要があります。

前提要件:

- 管理者である必要があります。

グローバルプッシュルールを作成するには:

1. 左側のサイドバーの下部で、**管理者**を選択します。
1. **プッシュルール**を選択します。
1. **プッシュルール**を展開します。
1. 必要なルールを設定します。
1. **プッシュルールを保存**を選択します。

## プロジェクトごとにグローバルプッシュルールをオーバーライドする {#override-global-push-rules-per-project}

個々のプロジェクトのプッシュルールは、グローバルプッシュルールをオーバーライドします。特定のプロジェクトのグローバルプッシュルールをオーバーライドするか、既存のプロジェクトのルールを更新して新しいグローバルプッシュルールに一致させるには:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **設定** > **リポジトリ**を選択します。
1. **プッシュルール**を展開します。
1. 必要なルールを設定します。
1. **プッシュルールを保存**を選択します。

## ユーザーを検証する {#verify-users}

これらのルールを使用して、コミットを行うユーザーを検証します。

{{< alert type="note" >}}

これらのプッシュルールは、[タグ](tags/_index.md)ではなく、コミットにのみ適用されます。

{{< /alert >}}

- **未認証のユーザーを拒否する**: コミッターのメールは、ユーザーの[確認済みのメールアドレス](../../profile/_index.md#add-emails-to-your-user-profile)または[プライベートコミットメールアドレス](../../profile/_index.md#use-an-automatically-generated-private-commit-email)のいずれかと一致する必要があります。
- **一貫性のないユーザー名を拒否**: コミット作成者の名前は、ユーザーのGitLabアカウント名と一致する必要があります。
- **コミットの作成者がGitLabのユーザーであるかどうかを確認します**: コミットの作成者とコミッターのメールアドレスは、両方ともGitLabユーザーの[確認済みのメールアドレス](../../profile/_index.md#add-emails-to-your-user-profile)と一致する必要があります。
- **コミットの作成者のメール**: 作成者とコミッターの両方のメールアドレスが、正規表現と一致する必要があります。任意のメールアドレスを許可するには、空のままにします。

[プロジェクトのボットユーザー](../../project/settings/project_access_tokens.md#bot-users-for-projects)または[グループのボットユーザー](../../group/settings/group_access_tokens.md#bot-users-for-groups)を使用する場合は、生成されたメールサフィックスを追加して、ボットトークンが変更をコミットしてプッシュできるようにする必要があります。

## コミットメッセージを検証する {#validate-commit-messages}

コミットメッセージにこれらのルールを使用します:

- **コミットメッセージ内に必要な表現**: メッセージは、その表現と一致する必要があります。任意のコミットメッセージを許可するには、空のままにします。マルチラインモードを使用します。`(?-m)`を使用すると無効にできます。検証の例は、次のとおりです:

  - `JIRA\-\d+`は、すべてのコミットが`Refactored css. Fixes JIRA-123`のようにJiraイシューを参照することを要求します。
  - `[[:^punct:]]\b$`は、最後の文字が句読点である場合、コミットを拒否します。Gitがコミットメッセージの最後に改行文字（`\n`）を追加するため、単語境界文字（`\b`）は偽陰性を防ぎます。

  GitLab UIで作成されたコミットメッセージは、改行文字として`\r\n`を設定します。正規表現で`\n`の代わりに`(\r\n?|\n)`を使用して、正しく一致させてください。

  たとえば、次の複数行のコミットの説明があるとします:

  ```plaintext
  JIRA:
  Description
  ```

  正規表現`JIRA:(\r\n?|\n)\w+`で検証できます。

- **コミットメッセージ内の拒否する表現**: コミットメッセージは、その表現と一致してはなりません。任意のコミットメッセージを許可するには、空のままにします。マルチラインモードを使用します。`(?-m)`を使用すると無効にできます。

## ブランチ名を検証する {#validate-branch-names}

ブランチ名を検証するには、**ブランチ名**の正規表現を入力します。任意のブランチ名を許可するには、空のままにします。[デフォルトブランチ](branches/default.md)は常に許可されます。特定の形式のブランチ名は、セキュリティ上の目的でデフォルトで制限されています。Gitコミットハッシュと同様の40個の16進文字の名前は禁止されています。

検証の例は、次のとおりです:

- ブランチは`JIRA-`で始まる必要があります。

  ```plaintext
  ^JIRA-
  ```

- ブランチは`-JIRA`で終わる必要があります。

  ```plaintext
  -JIRA$
  ```

- ブランチの長さは`4`文字から`15`文字の間で、小文字、数字、ダッシュのみを受け入れる必要があります。

  ```plaintext
  ^[a-z0-9\\-]{4,15}$
  ```

## 意図しない結果を防ぐ {#prevent-unintended-consequences}

これらのルールを使用して、意図しない結果を防ぎます。

- **署名されていないコミットを拒否**: コミットは[署名](signed_commits/_index.md)されている必要があります。このルールは、[Web IDE](#reject-unsigned-commits-push-rule-disables-web-ide)で作成された一部の正当なコミットをブロックし、[署名なしコミットが履歴に表示](#unsigned-commits-appear-in-commit-history)される可能性があります。
- **Do not allow users to remove Git tags with `git push`**（でGitタグを削除することをユーザーに許可しない）: ユーザーは、`git push`を使用してGitタグを削除できません。

## ファイルを検証する {#validate-files}

これらのルールを使用して、コミットに含まれるファイルを検証します。

- **シークレットファイルのプッシュを防止**: ファイルに[シークレット](#prevent-pushing-secrets-to-the-repository)が含まれていてはなりません。
- **Prohibited filenames**（禁止されているファイル名）: リポジトリに存在しないファイルは、正規表現と一致してはなりません。すべてのファイル名を許可するには、空のままにします。[一般的な例](#prohibit-files-by-name)を参照してください。
- **Maximum file size**（最大ファイルサイズ）: 追加または更新されたファイルは、このファイルサイズ（MB単位）を超えてはなりません。任意のサイズのファイルを許可するには、`0`に設定します。Git LFSによって追跡されるファイルは除外されます。

### リポジトリへのシークレットのプッシュを防止する {#prevent-pushing-secrets-to-the-repository}

認証情報ファイルやSSHシークレットキーなどのシークレットをバージョン管理システムにコミットしないでください。GitLabでは、定義済みのファイルリストを使用して、それらのファイルがリポジトリに保存されないようにブロックできます。リストに一致するファイルを含むマージリクエストはブロックされます。このプッシュルールは、リポジトリにすでにコミットされているファイルを制限しません。[プロジェクトごとにグローバルプッシュルールをオーバーライド](#override-global-push-rules-per-project)で説明されているプロセスを使用して、ルールを使用するように既存のプロジェクトの設定を更新する必要があります。

このルールによってブロックされるファイルは、以下にリストされています。条件の完全なリストについては、[`files_denylist.yml`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/lib/gitlab/checks/files_denylist.yml)を参照してください。

- AWS CLI認証情報blob:

  - `.aws/credentials`
  - `aws/credentials`
  - `homefolder/aws/credentials`

- プライベートRSA SSHキー:

  - `/ssh/id_rsa`
  - `/.ssh/personal_rsa`
  - `/config/server_rsa`
  - `id_rsa`
  - `.id_rsa`

- プライベートDSA SSHキー:

  - `/ssh/id_dsa`
  - `/.ssh/personal_dsa`
  - `/config/server_dsa`
  - `id_dsa`
  - `.id_dsa`

- プライベートED25519 SSHキー:

  - `/ssh/id_ed25519`
  - `/.ssh/personal_ed25519`
  - `/config/server_ed25519`
  - `id_ed25519`
  - `.id_ed25519`

- プライベートECDSA SSHキー:

  - `/ssh/id_ecdsa`
  - `/.ssh/personal_ecdsa`
  - `/config/server_ecdsa`
  - `id_ecdsa`
  - `.id_ecdsa`

- プライベートECDSA_SK SSHキー:

  - `/ssh/id_ecdsa_sk`
  - `/.ssh/personal_ecdsa_sk`
  - `/config/server_ecdsa_sk`
  - `id_ecdsa_sk`
  - `.id_ecdsa_sk`

- プライベートED25519_SK SSHキー:

  - `/ssh/id_ed25519_sk`
  - `/.ssh/personal_ed25519_sk`
  - `/config/server_ed25519_sk`
  - `id_ed25519_sk`
  - `.id_ed25519_sk`

- これらのサフィックスで終わるファイル:

  - `*.pem`
  - `*.key`
  - `*.history`
  - `*_history`

### ファイル名による禁止 {#prohibit-files-by-name}

Gitでは、ファイル名にはファイルの名前と、名前の前にあるすべてのディレクトリが含まれます。`git push`すると、プッシュ内の各ファイル名が**Prohibited filenames**（禁止されているファイル名）の正規表現と比較されます。

{{< alert type="note" >}}

この機能では、[RE2構文](https://github.com/google/re2/wiki/Syntax)が使用されます。RE2構文は、肯定先読みまたは否定先読みをサポートしていません。

{{< /alert >}}

正規表現は次のことができます:

- リポジトリ内の任意の場所にあるファイル名と一致します。
- 特定の場所にあるファイル名と一致します。
- 部分的なファイル名と一致します。
- 拡張子によって特定のファイルタイプを除外します。
- 複数の式を組み合わせて、複数のパターンを除外します。

### 正規表現の例 {#regular-expression-examples}

これらの例では、一般的な正規表現文字列の境界パターンを使用します:

- `^`: 文字列の先頭に一致します。
- `$`: 文字列の末尾に一致します。
- `\.`: リテラルピリオド文字に一致します。バックスラッシュはピリオドをエスケープします。
- `\/`: リテラルフォワードスラッシュと一致します。バックスラッシュはフォワードスラッシュをエスケープします。

#### 特定のファイルタイプの防止 {#prevent-specific-file-types}

- `.exe`ファイルをリポジトリ内の任意の場所にプッシュするのを防ぐには、次のようにします:

  ```plaintext
  \.exe$
  ```

#### 特定のファイルの防止 {#prevent-specific-files}

- 特定の設定ファイルのプッシュを防ぐには、次のようにします:

  - リポジトリルート内:

    ```plaintext
    ^config\.yml$
    ```

  - 特定のディレクトリ内:

    ```plaintext
    ^directory-name\/config\.yml$
    ```

- 任意の場所 - この例では、`install.exe`という名前のファイルのプッシュを防ぎます:

  ```plaintext
  (^|\/)install\.exe$
  ```

#### パターンの結合 {#combine-patterns}

複数のパターンを1つの式に結合できます。この例では、以前のすべての式を結合します:

```plaintext
(\.exe|^config\.yml|^directory-name\/config\.yml|(^|\/)install\.exe)$
```

## 署名されたコミットを要求する {#require-signed-commits}

[署名されたコミット](signed_commits/_index.md)は、信頼性を検証するために使用されるデジタル署名です。すべてのコミットに暗号学的署名を含めるように要求するには、**署名されていないコミットを拒否**プッシュルールを使用します。

このルールを有効にすると、次のようになります:

- リポジトリにプッシュされるすべての新しいコミットには、有効な暗号学的署名が含まれている必要があります。
- 署名は、サポートされている署名方法（GPG、SSH、またはX.509）を使用して作成する必要があります。
- 署名のないコミットは、プッシュ時に拒否されます。
- 無効または破損した署名を持つコミットは拒否されます。

**署名されていないコミットを拒否**プッシュルールを有効にするには、次のようにします:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **設定** > **リポジトリ**を選択します。
1. **プッシュルール**を展開します。
1. **署名されていないコミットを拒否**を選択します。
1. **プッシュルールを保存**を選択します。

## DCO認定されていないコミットを拒否する {#reject-commits-that-arent-dco-certified}

[Developer Certificate of Origin](https://developercertificate.org/)（DCO）で署名されたコミットは、コントリビューターがそのコミットでコントリビュートされたコードを作成したか、または送信する権利を有することを証明します。プロジェクトへのすべてのコミットがDCOに準拠するように要求できます。このプッシュルールでは、すべてのコミットメッセージに`Signed-off-by:`トレーラーが必要であり、それがないコミットは拒否されます。

## 関連トピック {#related-topics}

- [リポジトリを保護する](protect.md)
- 複雑なカスタムプッシュルールを作成するための[Gitサーバーフック](../../../administration/server_hooks.md)
- [署名されたコミット](signed_commits/_index.md)
- [保護ブランチ](branches/protected.md)
- [シークレット検出](../../application_security/secret_detection/_index.md)

## トラブルシューティング {#troubleshooting}

### 署名なしコミットを拒否するプッシュルールはWeb IDEを無効にする {#reject-unsigned-commits-push-rule-disables-web-ide}

プロジェクトに**署名されていないコミットを拒否**プッシュルールがある場合、ユーザーはGitLab Web IDEを介してコミットを作成できません。

このプッシュルールを使用してプロジェクトでWeb IDEを介してコミットできるようにするには、GitLab管理者は[フラグを使用して](../../../administration/feature_flags/_index.md)`reject_unsigned_commits_by_gitlab`機能フラグを無効にする必要があります。

```ruby
Feature.disable(:reject_unsigned_commits_by_gitlab)
```

### 署名なしコミットが履歴に表示される {#unsigned-commits-appear-in-commit-history}

**署名なしコミットを拒否**プッシュルールは、GitLabによって（UIまたはAPIを介して）認証および作成されたコミットを無視します。このプッシュルールが有効になっている場合、GitLab自体でコミットが作成された場合でも、署名なしコミットがコミットの履歴に表示されることがあります。

予想どおり、GitLabの外部で作成され、リポジトリにプッシュされたコミットは拒否されます。詳細については、[イシュー #5361](https://gitlab.com/gitlab-org/gitaly/-/issues/5361)を参照してください。

### すべてのプロジェクトのプッシュルールの一括更新 {#bulk-update-push-rules-for-all-projects}

すべてのプロジェクトでプッシュルールを同じにするように更新するには、[Railsコンソール](../../../administration/operations/rails_console.md#starting-a-rails-console-session)を使用するか、[プッシュルールAPIエンドポイント](../../../api/project_push_rules.md)を使用して各プロジェクトを更新するスクリプトを作成します。

たとえば、**コミットの作成者がGitLabのユーザーであるかどうかを確認します**チェックボックスと**Do not allow users to remove Git tags with `git push`**（でGitタグを削除することをユーザーに許可しない）チェックボックスを有効にし、Railsコンソールを介して特定のEメールのドメインからのコミットのみを許可するフィルターを作成するには、次のようにします:

{{< alert type="warning" >}}

データを変更するコマンドは、正しく実行されなかった場合、または適切な条件下で実行されなかった場合、損害を与える可能性があります。最初にテスト環境でコマンドを実行し、復元できるバックアップインスタンスを準備してください。

{{< /alert >}}

``` ruby
Project.find_each do |p|
  pr = p.push_rule || PushRule.new(project: p)
  # Check whether the commit author is a GitLab user
  pr.member_check = true
  # Do not allow users to remove Git tags with `git push`
  pr.deny_delete_tag = true
  # Commit author's email
  pr.author_email_regex = '@domain\.com$'
  pr.save!
end
```
