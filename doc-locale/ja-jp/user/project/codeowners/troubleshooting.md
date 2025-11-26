---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: コードオーナーを使用してコードベースのエキスパートを定義し、ファイルの種類または場所に基づいてレビュー要件を設定します。
title: コードオーナーのトラブルシューティング
---

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

コードオーナーを使用する場合、以下の問題が発生することがあります。

コードオーナー機能がエラーを処理する方法について詳しくは、[エラー処理](advanced.md#error-handling)を参照してください。

## CODEOWNERSファイルを検証します {#validate-your-codeowners-file}

{{< history >}}

- GitLab 17.11で`accessible_code_owners_validation`[フラグ](../../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/groups/gitlab-org/-/epics/15598)されました。デフォルトでは無効になっています。
- GitLab 18.1の[GitLab.comで有効](https://gitlab.com/gitlab-org/gitlab/-/issues/524437)になりました。
- GitLab 18.2で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/549626)になりました。機能フラグ`accessible_code_owners_validation`は削除されました。

{{< /history >}}

{{< alert type="flag" >}}

この機能の利用可否は、機能フラグによって制御されます。詳細については、履歴を参照してください。

{{< /alert >}}

[`CODEOWNERS`ファイル](_index.md#codeowners-file)を表示すると、GitLabは構文と権限のイシューを見つけるのに役立つように検証を実行します。構文のイシューが見つからない場合、GitLabは以下を行います:

- ファイルに対して検証をさらに実行しません。
- ファイルで見つかった最初の200件の一意のユーザーとグループ参照に対して、権限の検証をさらに実行します。

仕組みは次のとおりです:

1. プロジェクトにアクセスできるすべての参照を検索します。ユーザーまたはグループの参照が追加されても、プロジェクトへのアクセス権がない場合は、エラーを表示します。
1. 有効なユーザーの参照ごとに、ユーザーがプロジェクトでマージリクエストを承認する権限を持っていることを確認します。ユーザーがその権限を持っていない場合は、エラーを表示します。
1. 有効なグループの参照ごとに、最大のロールの値がデベロッパー以上であることを確認します。デベロッパーよりも低い値を持つグループの参照ごとに、エラーを表示します。
1. 有効なグループの参照ごとに、グループにマージリクエストを承認する権限を持つユーザーが少なくとも1人含まれていることを確認します。マージリクエストを承認する権限を持つユーザーが1人も含まれていないグループの参照については、エラーを表示します。

## 承認が表示されない {#approvals-do-not-show}

[`CODEOWNERS`ファイル](_index.md#codeowners-file)は、マージリクエストが作成される前に、ターゲットブランチに存在している必要があります。

コードオーナーの承認ルールは、マージリクエストが作成されたときにのみ更新されます。`CODEOWNERS`ファイルを更新する場合は、マージリクエストを閉じて、新しいマージリクエストを作成してください。

## 承認がオプションとして表示される {#approvals-shown-as-optional}

次のいずれかの条件に該当する場合、コードオーナーの承認ルールはオプションです:

- ユーザーまたはグループがプロジェクトのメンバーではありません。コードオーナーは、[親グループからメンバーを継承できません](https://gitlab.com/gitlab-org/gitlab/-/issues/288851/)。
- ユーザーまたはグループが[不正な形式であるか、アクセスできません](advanced.md#malformed-owners)。
- [保護ブランチでのコードオーナーの承認](../repository/branches/protected.md#require-code-owner-approval)が設定されていません。
- セクションが[オプションとしてマーク](reference.md#optional-sections)されています。
- 他の[マージリクエストのapproval設定](../merge_requests/approvals/settings.md)との競合により、マージリクエストを承認できる対象となるコードオーナーがいません。

## ユーザーが承認者の候補として表示されない {#user-not-shown-as-possible-approver}

次のいずれかの条件に該当する場合、ユーザーがコードオーナーのマージリクエストの承認ルールの承認者として表示されない場合があります:

- ルールが、特定のユーザーがマージリクエストを承認することを禁止しています。プロジェクトの[マージリクエストの承認](../merge_requests/approvals/settings.md#edit-merge-request-approval-settings)設定を確認してください。
- コードオーナーグループの表示レベルが非公開であり、現在のユーザーがコードオーナーグループのメンバーではありません。
- 特定のユーザー名のスペルが間違っているか、[`CODEOWNERS`ファイルで不正な形式です](advanced.md#malformed-owners)。
- 現在のユーザーは、内部のコードオーナーグループへの権限を持たない外部ユーザーです。

## ディレクトリのコードオーナーを表示すると、ユーザーまたはグループが表示されない {#user-or-group-not-visible-when-viewing-directory-code-owners}

コードオーナーは、ディレクトリを表示する際に、構成されたルールに基づいて目的のユーザーまたはグループを表示しない場合がありますが、ディレクトリの下にあるファイルのコードオーナーは正しく表示します。

例: 

```plaintext
* @dev-team
docs/ @tech-writer-team
```

`docs/`ディレクトリの下にあるすべてのファイルは、`@tech-writer-team`をコードオーナーとして表示しますが、ディレクトリ自体は`@dev-team`を表示します。

この動作は、ディレクトリを表示するときに、[構文ルール](reference.md#directory-paths)がディレクトリの下にあるすべてのファイルに適用され、ディレクトリ自体は含まれないために発生します。これを解決するには、`CODEOWNERS`ファイルを更新して、ディレクトリの下にあるすべてのファイルとともに、ディレクトリを具体的に含めます。例: 

```plaintext
* @dev-team
docs @tech-writer-team
docs/ @tech-writer-team
```

## 承認ルールが無効です {#approval-rule-is-invalid}

次のようなエラーが表示されることがあります:

```plaintext
Approval rule is invalid.
GitLab has approved this rule automatically to unblock the merge request.
```

このイシューは、承認ルールがプロジェクトの直接のメンバーではないコードオーナーを使用する場合に発生します。

回避策は、グループまたはユーザーがプロジェクトに招待されていることを確認することです。

## ユーザー名またはグループ名が変更されたときに`CODEOWNERS`が更新されない {#codeowners-not-updated-when-user-or-group-names-change}

ユーザーまたはグループが名前を変更すると、`CODEOWNERS`は新しい名前で自動的に更新されません。新しい名前を入力するには、ファイルを編集する必要があります。

SAML SSOを使用している組織は、ユーザーがユーザー名を変更できないように、[ユーザー名を設定](../../../integration/saml.md#set-a-username)できます。

## グローバルグループメンバーシップロックとの非互換性 {#incompatibility-with-global-group-memberships-locks}

コードオーナー機能には、プロジェクトへの直接のグループメンバーシップが必要です。グローバルグループメンバーシップロックが有効になっている場合、グループがプロジェクトに直接のメンバーとして招待されるのを防ぎます。これにより、2つの機能間に非互換性が生じます。

グローバルの[SAML](../../group/saml_sso/group_sync.md#global-saml-group-memberships-lock)または[LDAP](../../../administration/auth/ldap/ldap_synchronization.md#global-ldap-group-memberships-lock)グループメンバーシップロックが有効になっている場合、グループまたはサブグループをコードオーナーとして使用することはできません。

グローバルのSAMLまたはLDAPグループメンバーシップロックのいずれかを有効にした場合は、次のオプションがあります:

- グループの代わりに個々のユーザーをコードオーナーとして使用します。
- グループベースのコードオーナーを使用することがより優先度が高い場合は、グローバルグループメンバーシップロックを無効にします。

継承されたグループメンバーのサポートは、[イシュー288851](https://gitlab.com/gitlab-org/gitlab/-/issues/288851)で提案されています。
