---
stage: Security Risk Management
group: Security Policies
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: 'チュートリアル: マージリクエスト承認ポリシーをセットアップする'
---

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

このチュートリアルでは、[マージリクエスト承認ポリシー](../../user/application_security/policies/merge_request_approval_policies.md)を作成および構成する方法を説明します。これらの承認ポリシーは、スキャン結果に基づいてアクションを実行するように設定できます。たとえば、このチュートリアルでは、脆弱性がマージリクエストで検出された場合に、指定された2人のユーザーからの承認を必要とするポリシーを設定します。

マージリクエスト承認ポリシーをセットアップするには、:

1. [テストプロジェクトを作成](#create-a-test-project)。
1. [マージリクエスト承認ポリシーを追加](#add-a-merge-request-approval-policy)。
1. [マージリクエスト承認ポリシーをテスト](#test-the-merge-request-approval-policy)。

## はじめる前 {#before-you-begin}

- このチュートリアルで使用するネームスペースには、あなた自身を含め、最低3人のユーザーが含まれている必要があります。他に2人のユーザーがいない場合は、最初に作成する必要があります。詳細については、[ユーザーの作成](../../user/profile/account/create_accounts.md)を参照してください。
- 既存のグループに新しいプロジェクトを作成するための権限が必要です。

## テストプロジェクトを作成 {#create-a-test-project}

1. 左側のサイドバーの上部で、**新規作成**（{{< icon name="plus" >}}）を選択し、**新規プロジェクト/リポジトリ**を選択します。
1. **空のプロジェクトの作成**を選択します。
1. フィールドに入力します。
   - **プロジェクト名**: `sast-scan-result-policy`
   - **静的アプリケーションセキュリティテスト (SAST) を有効にする**チェックボックスを選択します。
1. **プロジェクトを作成**を選択します。
1. 新しく作成したプロジェクトに移動し、[保護されたブランチ](../../user/project/repository/branches/protected.md)を作成します。

## マージリクエスト承認ポリシーを追加 {#add-a-merge-request-approval-policy}

次に、テストプロジェクトにマージリクエスト承認ポリシーを追加します:

1. 左側のサイドバーで、**検索または移動先**を選択し、`sast-scan-result-policy`プロジェクトを見つけます。
1. **セキュリティ** > **ポリシー**を選択します。
1. **新規ポリシー**を選択します。
1. **マージリクエスト承認ポリシー**で、**ポリシーの選択**を選択します。
1. フィールドに入力します。
   - **名前**: `sast-scan-result-policy`
   - **ポリシーステータス**: **有効**
1. 次のルールを追加します:

   ```plaintext
   IF |Security Scan| from |SAST| find(s) more than |0| |All severity levels| |All vulnerability states| vulnerabilities in an open merge request targeting |All protected branches|
   ```

1. **アクション**を次のように設定します:

   ```plaintext
   THEN Require approval from | 2 | of the following approvers:
   ```

1. 2人のユーザーを選択します。
1. **マージリクエスト経由で設定**を選択します。

   アプリケーションは、リンクされた承認ポリシーを格納するための新しいプロジェクトを作成し、承認ポリシーを定義するためのマージリクエストを作成します。

1. **マージ**を選択します。
1. 左側のサイドバーで、**検索または移動先**を選択し、`sast-scan-result-policy`プロジェクトを見つけます。
1. **セキュリティ** > **ポリシー**を選択します。

   前の手順で追加された承認ポリシーのリストを確認できます。

## マージリクエスト承認ポリシーをテスト {#test-the-merge-request-approval-policy}

よくできました。マージリクエスト承認ポリシーを作成しました。これをテストするには、いくつかの脆弱性を作成して結果を確認します:

1. 左側のサイドバーで、**検索または移動先**を選択し、`sast-scan-result-policy`プロジェクトを見つけます。
1. **コード** > **リポジトリ**を選択します。
1. **追加**（{{< icon name="plus" >}}）ドロップダウンリストから、**新しいファイル**を選択します。
1. **ファイル名**フィールドに、`main.ts`と入力します。
1. ファイルの内容に、以下をコピーします:

   ```typescript
   // Non-literal require - tsr-detect-non-literal-require
   var lib: String = 'fs'
   require(lib)

   // Eval with variable - tsr-detect-eval-with-expression
   var myeval: String = 'console.log("Hello.");';
   eval(myeval);

   // Unsafe Regexp - tsr-detect-unsafe-regexp
   const regex: RegExp = /(x+x+)+y/;

   // Non-literal Regexp - tsr-detect-non-literal-regexp
   var myregexpText: String = "/(x+x+)+y/";
   var myregexp: RegExp = new RegExp(myregexpText);
   myregexp.test("(x+x+)+y");

   // Markup escaping disabled - tsr-detect-disable-mustache-escape
   var template: Object = new Object;
   template.escapeMarkup = false;

   // Detects HTML injections - tsr-detect-html-injection
   var element: Element =  document.getElementById("mydiv");
   var content: String = "mycontent"
   Element.innerHTML = content;

   // Timing attack - tsr-detect-possible-timing-attacks
   var userInput: String = "Jane";
   var auth: String = "Jane";
   if (userInput == auth) {
     console.log(userInput);
   }
   ```

1. **コミットメッセージ**フィールドに、`Add vulnerable file`と入力します。
1. **Target Branch**（ターゲットブランチ）フィールドに、`test-branch`と入力します。
1. **変更をコミットする**を選択します。**新しいマージリクエスト**フォームが開きます。
1. **マージリクエストを作成**を選択します。
1. 新しいマージリクエストで、`Create merge request`を選択します。

   パイプラインが完了するまで待ちます。これには数分かかる場合があります。

マージリクエストセキュリティウィジェットは、セキュリティスキャンが1つの潜在的な脆弱性を検出したことを確認します。マージリクエスト承認ポリシーで定義されているように、マージリクエストはブロックされ、承認を待機しています。

脆弱性をキャッチするために、マージリクエスト承認ポリシーを設定して使用する方法を理解できました。
