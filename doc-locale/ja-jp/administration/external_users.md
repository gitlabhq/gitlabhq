---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: 外部ユーザー
description: 特定のリソースに対する権限が制限された外部メンバーへのアクセスを制限付きで許可します。
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

インスタンス内の内部またはプライベートのグループとプロジェクトに対し、外部ユーザーはアクセスが制限されています。通常のユーザーとは異なり、外部ユーザーはグループまたはプロジェクトに明示的に追加する必要があります。ただし、通常のユーザーと同様に、外部ユーザーにはメンバーロールが割り当てられ、関連するすべての[権限](../user/permissions.md#project-members-permissions)が付与されます。

外部ユーザー:

- パブリックグループ、プロジェクト、およびスニペットにアクセスできます。
- メンバーである内部またはプライベートのグループとプロジェクトにアクセスできます。
- メンバーであるすべてのトップレベルグループで、サブグループ、プロジェクト、およびスニペットを作成できます。
- 個人のネームスペースでグループ、プロジェクト、またはスニペットを作成することはできません。

外部ユーザーは、組織外のユーザーが特定のプロジェクトへのアクセスのみを必要とする場合に一般的に作成されます。外部ユーザーにロールを割り当てる場合、ロールに関連付けられた[プロジェクトの表示レベル](../user/public_access.md#change-project-visibility)と[権限](../user/project/settings/_index.md#configure-project-features-and-permissions)に注意する必要があります。たとえば、外部ユーザーがプライベートプロジェクトのゲストロールを割り当てられている場合、コードにアクセスできません。

{{< alert type="note" >}}

外部ユーザーは請求対象ユーザーとしてカウントされ、ライセンスシートを消費します。

{{< /alert >}}

## 外部ユーザーの作成 {#create-an-external-user}

新しい外部ユーザーを作成するには:

1. 左側のサイドバーの下部で、**管理者**を選択します。
1. **概要** > **ユーザー**を選択します。
1. **新規ユーザー**を選択します。
1. **アカウント**セクションで、必要なアカウント情報を入力します。
1. オプション。**アクセス**セクションで、プロジェクトの制限またはユーザータイプ設定を構成します。
1. **外部**チェックボックスを選択します。
1. **ユーザーの作成**を選択します。

次の方法でも外部ユーザーを作成できます:

- [SAMLグループ](../integration/saml.md#external-groups)。
- [LDAPグループ](auth/ldap/ldap_synchronization.md#external-groups)。
- [外部プロバイダーリスト](../integration/omniauth.md#create-an-external-providers-list)。
- [ユーザーAPI](../api/users.md)。

## デフォルトで、新規ユーザーを外部ユーザーにする {#make-new-users-external-by-default}

すべての新規ユーザーをデフォルトで外部ユーザーにするようにインスタンスを構成できます。これらのユーザーアカウントは、後で変更して外部の指定を削除できます。

この機能を構成すると、メールアドレスの識別に使用される正規表現を定義することもできます。一致するメールを持つ新しいユーザーは除外され、外部ユーザーとしてマークされません。この正規表現は、以下を満たす必要があります:

- Ruby形式を使用します。
- JavaScriptに変換可能であること。
- 大文字と小文字を区別しないフラグを設定します（`/regex pattern/i`）。

次に例を示します: 

- `\.int@example\.com$`: `.int@domain.com`で終わるメールアドレスに一致します。
- `^(?:(?!\.ext@example\.com).)*$\r?`: `.ext@example.com`を含まないメールアドレスに一致します。

{{< alert type="warning" >}}

正規表現を追加すると、正規表現サービス拒否（ReDoS）攻撃のリスクが高まる可能性があります。

{{< /alert >}}

前提要件:

- GitLab Self-Managedインスタンスの管理者である必要があります。

デフォルトで新しいユーザーを外部ユーザーにするには:

1. 左側のサイドバーの下部で、**管理者**を選択します。
1. **設定** > **一般**を選択します。
1. **アカウントと制限**セクションを展開します。
1. **デフォルトで、新規ユーザーを外部ユーザーにする**チェックボックスを選択します。
1. オプション。**メール除外パターン**フィールドに、正規表現を入力します。
1. **変更を保存**を選択します。
