---
stage: Solutions Architecture
group: Solutions Architecture
info: This page is owned by the Solutions Architecture team.
description: 一元化されたカスタムルールセットを使用してGitLabシークレット検出を構成し、トップレベルグループ内のすべてのプロジェクトでPIIと平文パスワードを自動的に検出します。
title: シークレット検出
---

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

## はじめに {#getting-started}

### ソリューションコンポーネントのダウンロード {#download-the-solution-component}

1. アカウントチームから招待コードを入手してください。
1. 招待コードを使用して、[ソリューションコンポーネントウェブストア](https://cloud.gitlab-accelerator-marketplace.com)からソリューションコンポーネントをダウンロードします。

### 前提要件 {#prerequisites}

- GitLab Ultimateプラン
- GitLabインスタンスまたはグループへの管理者アクセス
- プロジェクトに対して[シークレット検出](../../user/application_security/secret_detection/_index.md)が有効になっている

## シークレット検出カスタムルールの設定 {#configure-secret-detection-custom-rules}

このガイドは、グローバルレベルでシークレット検出セキュリティポリシーを実装するのに役立ちます。このソリューションは、デフォルトのシークレット検出ルールを拡張して、社会保障番号や平文パスワードなどのPIIデータエレメントの検出を含めます。ルール拡張は、リモートルールセットと見なされます。

### カスタムルールセットの設定 {#configure-custom-ruleset}

次の手順でカスタムルールセットをセットアップできます

1. トップレベルグループ`Secret Detection`を作成します
1. ダウンロードしたコンポーネントから、プロジェクト`Secret Detection Custom Ruleset`を新しく作成した`Secret Detection`グループにコピーします。

このカスタムルールセットは、GitLabのプリビルドルールを拡張します。この拡張機能は、以下を含むシークレットを検出してアラートを送信できます:

- PIIデータエレメント: 社会保障番号
- 平文のパスワード。

#### カスタムルールセットファイル {#custom-ruleset-file}

カスタムルールセットは`.gitlab/secret-detection-ruleset.toml`で定義されています。ルールは`regex`を使用して定義できます

#### PIIデータエレメントの検出 {#pii-data-element-detection}

PIIデータエレメント検出用の拡張ルール

```toml
[[rules]]
id = "ssn"
description = "Social Security Number"
regex = "[0-9]{3}-[0-9]{2}-[0-9]{4}"
tags = ["ssn", "social-security-number"]
keywords = ["ssn"]
```

#### 平文のパスワード {#password-in-plain-text}

平文のパスワードに対する拡張ルール

```toml
[[rules]]
id = "password-secret"
description = "Detect secrets starting with Password or PASSWORD"
regex = "(?i)Password[:=]\\s*['\"]?[^'\"]+['\"]?"
tags = ["password", "secret"]
keywords = ["password", "PASSWORD"]
```

### 定義済みカスタムルールセットへのアクセス {#access-defined-custom-ruleset}

カスタムルールセットにアクセスするには、ボットユーザーを生成するグループアクセストークンを作成する必要があります。ボットユーザーは、グローバルセキュリティポリシーでシークレット検出を実行するすべてのプロジェクトで、カスタムルールセットを認証してアクセスするために使用できます。

アクセスと認証を設定するには、次の手順に従います:

1. グループトークンを作成します: グループ`Secret Detection`で、`Settings`メニューオプションのグループアクセストークン`Secret Detection Group Token`を作成し、トークンに`reporter`ロールと`read_repository`アクセス権を付与します

![セキュリティダッシュボード](img/secret_detection_group_token_v17_9.png)

1. グループ変数を作成します: トークン値をコピーし、安全に保管してください。`Settings`メニューオプションのグループ変数を`SECRET_DETECTION_GROUP_TOKEN`というキーとしてトークン値とともに追加します。
1. グループトークンのボットユーザーを取得します: 同じグループで、`manage`メニューオプションに移動して`member`を選択し、グループアクセストークン`Secrete Detection Group Token`に対応するボットユーザーを調べ、`@group_[group_id]_bot_[random_number]`の形式でグループのボットユーザーを表す値をコピーします

![シークレット検出グループトークンボット](img/secret_detection_group_token_bot_v17_9.png)

## 実装ガイド {#implementation-guide}

このガイドでは、集中型のカスタムルールセットを使用して、すべてのプロジェクトに対してシークレット検出を実行するようにセキュリティポリシーを構成する手順について説明します。

### シークレット検出セキュリティポリシーの設定 {#configure-secret-detection-policy}

グローバルセキュリティポリシーとしてパイプラインでシークレット検出を自動的に実行するには、最上位レベル（この場合はトップレベルグループ）でセキュリティポリシーを設定します。新しいシークレット検出セキュリティポリシーを作成するには:

1. セキュリティポリシーを作成します: 同じグループ`Secret Detection`で、そのグループの**セキュリティ** > **ポリシー**ページに移動します。
1. **新規ポリシー**を選択します。
1. **スキャン実行ポリシー**を選択します。
1. セキュリティポリシーを構成します: セキュリティポリシー名`Secret Detection Policy`を入力し、説明を入力して`Secret Detection`スキャンを選択します
1. 「このグループ内のすべてのプロジェクト」（必要に応じて例外を設定）または「特定のプロジェクト」（ドロップダウンからプロジェクトを選択）を選択して、**ポリシーのスコープ**を設定します。
1. **アクション**セクションでは、デフォルトで「シークレット検出」が表示されます。
1. **条件**セクションでは、すべてのコミット時ではなく、スケジュールに基づいてスキャンを実行する場合は、必要に応じて「トリガー: 」を「スケジュール: 」に変更できます。
1. カスタムルールセットへのアクセスを設定します。ボットユーザー、グループ変数、およびカスタムルールセットプロジェクトのURLの値を持つCI変数を追加します。

   カスタムルールセットは別のプロジェクトでホストされ、リモートルールセットと見なされるため、`SECRET_DETECTION_RULESET_GIT_REFERENCE`を使用する必要があります。

   ```yaml
   variables:
     SECRET_DETECTION_RULESET_GIT_REFERENCE: "group_[group_id]_bot_[random_number]:$SECRET_DETECTION_GROUP_TOKEN@[custom ruleset project URL]"
     SECRET_DETECTION_HISTORIC_SCAN: "true"
   ```

UI設定は、次の画面に表示されます: ![セキュリティダッシュボード](img/secret_detection_policy_v17_9.png)このCI変数の詳細については、[詳細については、このドキュメントを参照してください](../../user/application_security/secret_detection/pipeline/configure.md#with-a-remote-ruleset)。

1. **ポリシーの作成**をクリックします。

### セキュリティポリシー構成の完了 {#complete-policy-configuration}

セキュリティポリシーの作成後、参照用に、完全なセキュリティポリシー設定を次に示します:

```yaml
---
scan_execution_policy:
- name: Scan Execution for Secret Detection with Custom Rules
  description: ''
  enabled: true
  policy_scope:
    projects:
      excluding: []
  rules:
  - type: pipeline
    branches:
    - "*"
  actions:
  - scan: secret_detection
    variables:
      SECRET_DETECTION_RULESET_GIT_REFERENCE: "@group_[group_id]_bot_[random_number]:$SECRET_DETECTION_GROUP_TOKEN@gitlab.com/example_group/secret-detection/secret-detection-custom-ruleset"
      SECRET_DETECTION_HISTORIC_SCAN: 'true'
  skip_ci:
    allowed: true
    allowlist:
      users: []
approval_policy: []
```

## 仕組み {#how-it-works}

セキュリティポリシーが実行されると、グローバルセキュリティポリシーに関連付けられているすべてのプロジェクトで、`secret detect`ジョブが`secret_detection_0`ジョブとしてパイプラインで自動的に実行されます。![セキュリティダッシュボード](img/secret_detection_job_v17_9.png)

シークレットが検出され、表面化されます。マージリクエストがある場合、ネット新規シークレットがMRウィジェットに表示されます。デフォルトブランチがマージされている場合、セキュリティ脆弱性レポートに次のように表示されます: ![パスワード脆弱性の結果をシークレット検出](img/secret_detection_pwd_vuln_v17_9.png)

以下は、平文のパスワードの例です: ![検出パスワードの調査結果をシークレット検出](img/secret_detection_pwd_v17_9.png)

## トラブルシューティング {#troubleshooting}

### セキュリティポリシーが適用されていません {#policy-not-applying}

変更したセキュリティポリシープロジェクトがグループに正しくリンクされていることを確認してください。詳細については、[セキュリティポリシープロジェクトへのリンク](../../user/application_security/policies/enforcement/security_policy_projects.md#link-to-a-security-policy-project)を参照してください。
