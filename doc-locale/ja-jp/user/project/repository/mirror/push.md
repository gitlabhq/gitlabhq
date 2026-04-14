---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: プッシュミラーを作成して、アップストリームリポジトリから変更を受動的に受信します。
title: プッシュミラーリング
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

_プッシュミラー_は、アップストリームリポジトリに対して行われたコミットを[ミラーリング](_index.md)するダウンストリームリポジトリです。プッシュミラーは、アップストリームリポジトリに対して行われたコミットのコピーを受動的に受け取ります。ミラーがアップストリームリポジトリから分岐するのを防ぐために、ダウンストリームミラーにコミットを直接プッシュしないでください。代わりに、コミットをアップストリームリポジトリにプッシュしてください。

[プルミラーリング](pull.md)はアップストリームリポジトリから定期的に更新を取得しますが、プッシュミラーは次の場合にのみ変更を受信します。

- コミットがアップストリームのGitLabリポジトリにプッシュされた場合
- 管理者が[ミラーを強制的に更新](_index.md#force-an-update)した場合

変更をアップストリームリポジトリにプッシュすると、**保護ブランチのみをミラーリング**設定がオンの場合、プッシュミラーは5分後、または1分後に変更を受信します。

ブランチがデフォルトブランチにマージされ、ソースプロジェクトで削除された場合、次のプッシュ時にリモートミラーから削除されます。マージされていない変更があるブランチは保持されます。ブランチが分岐すると、**リポジトリのミラーリング**セクションにエラーが表示されます。

[GitLab Silent Mode](../../../../administration/silent_mode/_index.md)は、リモートミラーへのプッシュおよびリモートミラーからのプルを無効にします。

## プッシュミラーの制限 {#push-mirror-limits}

各プロジェクトは、最大10個の有効なプッシュミラーを持つことができます。詳細については、[プロジェクトプッシュミラーの最大数](../../../../administration/instance_limits.md#maximum-number-of-project-push-mirrors)を参照してください。

## プッシュミラーリングを設定する {#configure-push-mirroring}

既存のプロジェクトにプッシュミラーリングをセットアップするには:

1. 上部のバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **設定** > **リポジトリ**を選択します。
1. **リポジトリのミラーリング**を展開します。
1. リポジトリURLを入力します。
1. **ミラーの方向**ドロップダウンリストで、**プッシュ**を選択します。
1. **認証方法**を選択します。詳細については、[ミラーの認証方法](_index.md#authentication-methods-for-mirrors)を参照してください。
1. 必要に応じて、**保護ブランチのみをミラーリング**を選択します。
1. 必要に応じて、**分岐した参照を保持**を選択します。
1. 設定を保存するには、**リポジトリのミラーリング**を選択します。

### APIを使用してプッシュミラーを構成する {#configure-push-mirrors-through-the-api}

[リモートミラーAPI](../../../../api/remote_mirrors.md)を使用して、プロジェクトのプッシュミラーを作成および変更することもできます。

## 分岐した参照を保持する {#keep-divergent-refs}

デフォルトでは、リモート（ダウンストリーム）ミラー上の任意のref（ブランチまたはタグ）がローカルリポジトリから分岐した場合、アップストリームリポジトリはリモートの変更を上書きします。

1. リポジトリは、`main`および`develop`ブランチをリモートにミラーリングします。
1. リモートミラーの`develop`に新しいコミットが追加されます。
1. 次のプッシュは、アップストリームリポジトリと一致するようにリモートミラーを更新します。
1. リモートミラーの`develop`に追加された新しいコミットは失われます。

**分岐したrefsを保持**を選択した場合、変更は異なる方法で処理されます。

1. リモートミラーの`develop`ブランチへの更新はスキップされます。
1. リモートミラーの`develop`ブランチは、アップストリームリポジトリに存在しないコミットを保持します。リモートミラーに存在するが、アップストリームには存在しないrefsはすべてそのまま残されます。
1. 更新は失敗としてマークされます。

ミラーを作成した後、**分岐した参照を保持する**の値は、[リモートミラーAPI](../../../../api/remote_mirrors.md)からのみ変更できます。

## GitLabからGitHubへのプッシュミラーを設定する {#set-up-a-push-mirror-from-gitlab-to-github}

GitLabからGitHubへコミットをプッシュすると、GitHubはメールアドレスに基づいてコミットの帰属を決定します。コミットのメールアドレスがGitHubユーザーアカウント上の確認済みメールと一致する場合、GitHubはそのユーザーにコミットを割り当てます。そうでない場合、コミットは、コミットメタデータからの名前とメールのみで、帰属なしとして表示されます。

前提条件: 

- GitHubの[きめ細かなパーソナルアクセストークン](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/managing-your-personal-access-tokens#fine-grained-personal-access-tokens)で、[リポジトリコンテンツ](https://docs.github.com/en/rest/authentication/permissions-required-for-fine-grained-personal-access-tokens?apiVersion=2022-11-28#repository-permissions-for-contents)の読み取りおよび書き込み権限を持つもの。お使いのリポジトリに`.github/workflows`ディレクトリが含まれている場合、[ワークフロー](https://docs.github.com/en/rest/authentication/permissions-required-for-fine-grained-personal-access-tokens?apiVersion=2022-11-28#repository-permissions-for-workflows)への読み取りおよび書き込みアクセスも許可する必要があります。よりきめ細かなアクセスについては、特定のリポジトリにのみ適用されるようにトークンを設定してください。

ミラーを設定するには:

1. **GitリポジトリのURL**には、この形式でURLを入力してください:

   ```plaintext
   https://github.com/GROUP/PROJECT.git
   ```

   - `GROUP`: GitHubのグループ。
   - `PROJECT`: GitHubのプロジェクト。

1. **ユーザー名**には、パーソナルアクセストークンのオーナーのユーザー名を入力します。
1. **パスワード**には、GitHubのパーソナルアクセストークンを入力します。
1. **ミラーリポジトリ**を選択します。

ミラーリングされたリポジトリが一覧表示されます。例: 

```plaintext
https://*****:*****@github.com/<your_github_group>/<your_github_project>.git
```

リポジトリはその後すぐにプッシュされます。プッシュを強制するには、**今すぐ更新**（{{< icon name="retry" >}}）を選択します。

## GitLabからAWS CodeCommitへのプッシュミラーを設定する {#set-up-a-push-mirror-from-gitlab-to-aws-codecommit}

AWS CodeCommitのプッシュミラーリングは、GitLabリポジトリをAWS CodePipelineに接続するための最良の方法です。GitLabはまだ、ソースコード管理（SCM）プロバイダーの1つとしてサポートされていません。新しいAWS CodePipelineごとに、重要なAWSインフラストラクチャの設定が必要です。また、ブランチごとに個別のパイプラインが必要です。

AWS CodeDeployがCodePipelineの最終ステップである場合は、代わりに次のツールを組み合わせてデプロイを作成できます。

- GitLab CI/CDパイプライン。
- `.gitlab-ci.yml`の最後のジョブでAWS CLIを使用してCodeDeployにデプロイ。

GitLabからAWS CodeCommitへのミラーを設定するには、次の手順に従います。

1. AWS IAMコンソールで、IAMユーザーを作成します。
1. **インラインポリシー**として、リポジトリのミラーリングに対する最小権限の権限を次のように追加します。

   Amazonリソース名（ARN）には、リージョンとアカウントを明示的に含める必要があります。このIAMポリシーは、2つのサンプルリポジトリへのミラーリングアクセスに権限を付与します。これらの権限はテスト済みで、ミラーリングに必要な最小限（最小権限）の権限になっています。

   ```json
   {
       "Version": "2012-10-17",
       "Statement": [
           {
               "Sid": "MinimumGitLabPushMirroringPermissions",
               "Effect": "Allow",
               "Action": [
                   "codecommit:GitPull",
                   "codecommit:GitPush"
               ],
               "Resource": [
                 "arn:aws:codecommit:us-east-1:111111111111:MyDestinationRepo",
                 "arn:aws:codecommit:us-east-1:111111111111:MyDemo*"
               ]
           }
       ]
   }
   ```

1. ユーザーを作成したら、AWS IAMユーザー名を選択します。
1. **セキュリティ認証情報**タブを選択します。
1. **HTTPS Git認証情報（AWS CodeCommit用）**で、**認証情報を生成**を選択します。

   > [!note]
   > このGitユーザーIDとパスワードは、CodeCommitとの通信に特化したものです。このユーザーのIAMユーザーIDまたはAWSキーと混同しないでください。

1. 特別なGit HTTPSユーザーIDとパスワードをコピーまたはダウンロードします。
1. AWS CodeCommitコンソールで、GitLabリポジトリからミラーリングする新しいリポジトリを作成します。
1. 新しいリポジトリを開き、右上隅で**コード** > **Clone HTTPS** (**Clone HTTPS (GRC)**ではない) を選択します。
1. GitLabで、プッシュミラーリングするリポジトリを開きます。
1. **設定** > **リポジトリ**を選択し、**リポジトリのミラーリング**を展開する。
1. 次の形式を使用し、`<aws-region>`をAWSリージョンに、`<your_codecommit_repo>`をCodeCommit内のリポジトリの名前に置き換えて、**GitリポジトリのURL**に入力します。

   ```plaintext
   https://git-codecommit.<aws-region>.amazonaws.com/v1/repos/<your_codecommit_repo>
   ```

1. **認証方法**に、**ユーザー名とパスワード**を選択します。
1. **ユーザー名**には、AWSの**特別なHTTPS GitユーザーID**を入力します。
1. **パスワード**には、AWSで以前に作成した特別なIAM GitクローンユーザーIDのパスワードを入力します。
1. CodeCommitについては**保護ブランチのみをミラーリング**オプションはそのままにします。（5分ごとから1分ごとに）プッシュの間隔が短くなります。

   CodePipelineでは、AWS CI設定が必要な名前付きブランチに個別のパイプラインの設定が必要です。動的な名前のフィーチャーブランチはサポートされていないため、**保護ブランチのみをミラーリング**を設定しても、CodePipelineのインテグレーションに関して柔軟性の問題は発生しません。また、CodePipelineをビルドする名前付きブランチをすべて保護する必要があります。

1. **ミラーリポジトリ**を選択します。ミラーリングされたリポジトリが表示されるはずです。

   ```plaintext
   https://*****:*****@git-codecommit.<aws-region>.amazonaws.com/v1/repos/<your_codecommit_repo>
   ```

プッシュを強制してミラーリングをテストするには、**今すぐ更新**（半円の矢印）を選択します。**最後に成功した更新**に日付が表示される場合、ミラーリングは正しく設定されています。正しく機能していない場合は、赤い`error`タグが表示され、ホバーテキストとしてエラーメッセージが表示されます。

## 2FAが有効な別のGitLabインスタンスへのプッシュミラーを設定する {#set-up-a-push-mirror-to-another-gitlab-instance-with-2fa-activated}

1. ミラーリング先のGitLabインスタンスで、`write_repository`スコープを持つ[パーソナルアクセストークン](../../../profile/personal_access_tokens.md)を作成します。
1. ミラーリング元のGitLabインスタンスで、次の手順を実行します。
   1. `https://<destination host>/<your_gitlab_group_or_name>/<your_gitlab_project>.git`の形式を使用して、**GitリポジトリのURL**を入力します。
   1. **ユーザー名**`oauth2`を入力します。
   1. **パスワード**を入力します。ミラーリング先のGitLabインスタンスで作成されたGitLabのパーソナルアクセストークンを使用します。
   1. **ミラーリポジトリ**を選択します。

## 関連トピック {#related-topics}

- リポジトリのミラーリングに関する[トラブルシューティング](troubleshooting.md)。
- [リモートミラーAPI](../../../../api/remote_mirrors.md)
