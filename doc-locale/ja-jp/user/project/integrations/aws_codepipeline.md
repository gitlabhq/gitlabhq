---
stage: Solutions Architecture
group: Solutions Architecture
info: This page is owned by the Solutions Architecture team.
title: AWS CodePipeline
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com

{{< /details >}}

{{< history >}}

- GitLab 16.5で[導入](https://gitlab.com/gitlab-com/alliances/aws/wip/aws-cs-collab/aws-gitlab-collaboration/-/issues/25)されました。

{{< /history >}}

GitLabプロジェクトを使用して、[AWS CodePipeline](https://aws.amazon.com/codepipeline/)を使用してビルド、テスト、デプロイコードの変更を行うことができます。これを行うには、次のものを使用します:

- AWS CodeStar Connectionsを使用して、GitLab.comアカウントをAWSに接続します。
- その接続を使用して、コードへの変更に基づいてパイプラインを自動的に開始します。

## AWS CodePipelineからGitLabへの接続を作成する {#create-a-connection-from-aws-codepipeline-to-gitlab}

前提要件: 

- AWS CodePipelineに接続しているGitLabプロジェクトでオーナーロールを持っている必要があります。
- AWSで接続を作成するための適切な認可を持っている必要があります。
- サポートされているAWSリージョンを使用する必要があります。サポートされていないAWSリージョン（[AWSドキュメント](https://docs.aws.amazon.com/codepipeline/latest/userguide/connections-gitlab.html)にも記載）は次のとおりです:
  - アジアパシフィック（香港）。
  - アフリカ（ケープタウン）。
  - 中東（バーレーン）。
  - ヨーロッパ（チューリッヒ）。
  - AWS GovCloud（米国西部および米国東部）。

GitLab.com上のプロジェクトへの接続を作成するには、AWS Management ConsoleまたはAWSコマンドラインインターフェイス（AWS CLI）を使用できます。

### AWS Management Consoleを使用する {#use-the-aws-management-console}

AWS CodePipelineで新規または既存のパイプラインをGitLab.comに接続するには、まず、GitLabアカウントを使用するようにAWSの接続を認可します。

1. AWS Management Consoleにサインインし、[AWS Developer Tools console](https://console.aws.amazon.com/codesuite/settings/connections)を開きます。
1. **設定** > **Connections**（接続） > **Create connection**（接続の作成）を選択します。
1. **Select a provider**（プロバイダーの選択）で、**GitLab**を選択します。
1. **Connection name**（接続名）に、作成する接続の名前を入力し、**Connect to GitLab**（GitLabに接続）を選択します。
1. GitLabのサインインページで、認証情報を入力し、**サインインする**を選択します。
1. GitLabアカウントへのアクセスをリクエストする認可をリクエストするメッセージとともに、認可ページが表示されます。**許可する**を選択します。
1. ブラウザが接続コンソールページに戻ります。**Create GitLab connection**（GitLab接続の作成）セクションで、新しい接続が**Connection name**（接続名）に表示されます。
1. **Connect to GitLab**（GitLabに接続）を選択します。接続が正常に作成されると、成功バナーが表示されます。接続の詳細は、**Connection settings**（接続設定）ページに表示されます。

これで、AWS CodeSuiteをGitLab.comに接続したので、GitLabプロジェクトを活用するAWS CodePipelineでパイプラインを作成または編集できます。

1. [AWS CodePipelineコンソール](https://console.aws.amazon.com/codesuite/codepipeline/start)にサインインします。
1. パイプラインを作成または編集します:
   - パイプラインを作成する場合:
     - 最初の画面でフィールドに入力し、**次へ**を選択します。
     - **ソース**ページの**Source Provider**（ソースプロバイダー）セクションで、**GitLab**を選択します。
   - 既存のパイプラインを編集する場合:
     - **編集** > **Edit stage**（ステージの編集）を選択して、ソースアクションを追加または編集します。
     - **Edit action**（アクションの編集）ページの**Action name**（アクション名）セクションに、アクションの名前を入力します。
     - **Action provider**（アクションプロバイダー）で、**GitLab**を選択します。
1. **接続**で、以前に作成した接続を選択します。
1. **リポジトリ名**で、GitLabプロジェクトの名前を選択するには、ネームスペースとすべてのサブグループを含む完全なプロジェクトパスを指定します。たとえば、グループレベルのプロジェクトの場合は、次の形式でプロジェクト名を入力します: `group-name/subgroup-name/project-name`。ネームスペースを含むプロジェクトパスは、GitLabのURLにあります。他の特別なURLセグメントが含まれているため、Web IDEまたはrawビューからURLをコピーしないでください。ダイアログからオプションを選択するか、新しいパスを手動で入力することもできます。詳細については、以下を参照してください:
   - パスとネームスペースについては、[projects API](../../../api/projects.md#get-a-single-project)の`path_with_namespace`フィールドを参照してください。
   - GitLabのネームスペースについては、[ネームスペース](../../namespace/_index.md)を参照してください。

1. **ブランチ名**で、パイプラインでソースの変更を検出するブランチを選択します。ブランチ名が自動的に入力されたない場合は、次のいずれかが原因である可能性があります:
   - プロジェクトのオーナーロールを持っていない。
   - プロジェクト名が無効である。
   - 使用されている接続に、プロジェクトへのアクセス権がない。

1. **Output artifact format**で、アーティファクトの形式を選択します。保存するには:
   - デフォルトのメソッドを使用してGitLabアクションから出力アーティファクトを保存するには、**CodePipeline default**を選択します。アクションはGitLabリポジトリからファイルにアクセスし、パイプラインアーティファクトストアにアーティファクトをZIPファイルに保存します。
   - ダウンストリームアクションがGitコマンドラインを直接実行できるように、リポジトリへのURL参照を含むJSONファイルで、**Full clone**（完全クローン）を選択します。このオプションは、CodeBuildダウンストリームアクションでのみ使用できます。このオプションを選択するには:
     - [CodeBuildプロジェクトサービスロールの権限を更新します](https://docs.aws.amazon.com/codepipeline/latest/userguide/troubleshooting.html#codebuild-role-connections)。
     - [GitHubパイプラインソースで完全なクローンを使用する方法については、AWS CodePipelineのチュートリアル](https://docs.aws.amazon.com/codepipeline/latest/userguide/tutorials-github-gitclone.html)に従ってください。
1. ソースアクションを保存して続行します。

### AWS CLIを使用する {#use-the-aws-cli}

AWS CLIを使用して接続を作成するには:

- `create-connection`コマンドを使用します。
- GitLab.comアカウントで認証するために、AWSコンソールに移動します。
- GitLabプロジェクトをAWS CodePipelineに接続します。

`create-connection`コマンドを使用するには:

1. ターミナル（Linux、macOS、またはUnix）またはコマンドラインプロンプト（Windows）を開きます。AWS CLIを使用して`create-connection`コマンドを実行し、接続の`--provider-type`と`--connection-name`を指定します。この例では、サードパーティプロバイダー名は`GitLab`で、指定された接続名は`MyConnection`です。

   ```shell
   aws codestar-connections create-connection --provider-type GitLab --connection-name MyConnection
   ```

   成功すると、このコマンドは接続のAmazonリソースネーム（ARN）情報を返します。例: 

   ```json
   {
   "ConnectionArn": "arn:aws:codestar-connections:us-west-2:account_id:connection/aEXAMPLE-8aad-4d5d-8878-dfcab0bc441f"
   }
   ```

1. 新しい接続は、デフォルトで`PENDING`ステータスで作成されます。コンソールを使用して、接続のステータスを`AVAILABLE`に変更します。

1. [AWSコンソールを使用して接続を完了します](#use-the-aws-management-console)。保留中のGitLabの接続を選択していることを確認してください。**Create connection**（接続の作成）を選択しないでください。

## 関連トピック {#related-topics}

- [AWS CodePipelineがGitLabをサポートするという発表](https://aws.amazon.com/about-aws/whats-new/2023/08/aws-codepipeline-supports-gitlab/)
- [GitLab接続-AWS CodePipeline](https://docs.aws.amazon.com/codepipeline/latest/userguide/connections-gitlab.html)
- [GitLabへの接続を作成する-Developer Tools console](https://docs.aws.amazon.com/dtconsole/latest/userguide/connections-create-gitlab.html)
- [Bitbucket、GitHub、GitHub Enterprise Server、およびGitLabアクションのCodeStarSourceConnection-AWS CodePipeline](https://docs.aws.amazon.com/codepipeline/latest/userguide/action-reference-CodestarConnectionSource.html)
