---
stage: Application Security Testing
group: Secret Detection
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: 'チュートリアル: シークレットプッシュ保護でプロジェクトを保護する'
---

アプリケーションが外部リソースを使用する場合、通常はトークンやキーなどの**secret**（シークレット）を使用してアプリケーションを認証する必要があります。シークレットがリモートリポジトリにプッシュされた場合、そのリポジトリへのアクセス権を持つ人は誰でも、あなたまたはあなたのアプリケーションになりすますことができます。

シークレットプッシュ保護では、GitLabがコミット履歴内のシークレットを検出すると、リークを防ぐためにプッシュをブロックできます。シークレットプッシュ保護を有効にすると、機密データに関するコミットのレビューや、リークが発生した場合の修正にかかる時間を短縮できます。

このチュートリアルでは、シークレットプッシュ保護を設定し、偽のシークレットをコミットしようとした場合にどうなるかを確認します。誤検出を回避する必要がある場合に備えて、シークレットプッシュ保護をスキップする方法も学習します。

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i>このチュートリアルは、次のGitLab Unfilteredビデオを参考にしたものです:

- [シークレットのプッシュ保護の概要](https://www.youtube.com/watch?v=SFVuKx3hwNI)
<!-- Video published on 2024-06-21 -->
- [プロジェクトのシークレットプッシュ保護の構成 - 有効化](https://www.youtube.com/watch?v=t1DJN6Vsmp0)
<!-- Video published on 2024-06-23 -->
- [シークレットプッシュ保護](https://www.youtube.com/watch?v=wBAhe_d2DkQ)
<!-- Video published on 2024-06-04 -->

## はじめる前 {#before-you-begin}

このチュートリアルを開始する前に、以下を確認してください:

- GitLab Ultimateサブスクリプション。
- テストプロジェクト。任意のプロジェクトを使用できますが、このチュートリアル専用のテストプロジェクトを作成することを検討してください。
- コマンドラインGitにある程度の知識。

さらに、GitLabセルフマネージド版のみで、シークレットプッシュ保護が[インスタンスで有効になっている](secret_push_protection/_index.md#allow-the-use-of-secret-push-protection-in-your-gitlab-instance)ことを確認してください。

## シークレットプッシュ保護を有効にする {#enable-secret-push-protection}

シークレットプッシュ保護を使用するには、保護するプロジェクトごとに有効にする必要があります。まず、テストプロジェクトで有効にしてみましょう。

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. 左側のサイドバーで、**セキュリティ** > **セキュリティ設定**を選択します。
1. **シークレットのプッシュ保護**切替をオンにします。

次に、シークレットプッシュ保護をテストします。

## シークレットをプロジェクトにプッシュしてみてください {#try-pushing-a-secret-to-your-project}

GitLabは、文字、数字、記号の特定のパターンに一致させることでシークレットを識別します。これらのパターンは、シークレットのタイプを識別するためにも使用されます。この機能をテストするために、偽のシークレット`glpat-12345678901234567890`をプロジェクトに追加してみましょう: <!-- gitleaks:allow -->

1. プロジェクトで、新しいブランチをチェックアウトします:

   ```shell
   git checkout -b push-protection-tutorial
   ```

1. 次の内容で新しいファイルを作成します。パーソナルアクセストークンの正確な形式に一致させるには、`-`の前後のスペースを必ず削除してください:

   ```plaintext
   hello, world!

   # To make the example work, remove
   # the spaces before and after the dash:
   glpat - 12345678901234567890
   ```

1. ファイルをブランチにコミットします:

   ```shell
   git add .
   git commit -m "Add fake secret"
   ```

   シークレットがコミット履歴に入力されました。シークレットプッシュ保護は、シークレットをコミットすることをブロックしません。 プッシュ時にのみアラートが表示されます。

1. 変更をGitLabにプッシュします。次のようなものが表示されるはずです:

   ```shell
   $ git push
   remote: GitLab:
   remote: PUSH BLOCKED: Secrets detected in code changes
   remote:
   remote: Secret push protection found the following secrets in commit: 123abc
   remote: -- myFile.txt:2 | GitLab Personal Access Token
   remote:
   remote: To push your changes you must remove the identified secrets.
   To gitlab.com:
    ! [remote rejected] push-protection-tutorial -> main (pre-receive hook declined)
   ```

   GitLabがシークレットを検出し、プッシュをブロックします。エラーレポートから、以下を確認できます:

   - シークレットを含むコミット (`123abc`)
   - シークレットを含むファイルと行番号 (`myFile.txt:2`)
   - シークレットのタイプ (`GitLab Personal Access Token`)

変更を正常にプッシュした場合、シークレットを失効して置き換えるためにかなりの時間と労力を費やす必要があります。代わりに、[コミット履歴からシークレットを削除](remove_secrets_tutorial.md)して、シークレットのリークを阻止したことを安心して知ることができます。

## シークレットプッシュ保護をスキップする {#skip-secret-push-protection}

シークレットプッシュ保護がシークレットを識別した場合でも、コミットをプッシュする必要がある場合があります。これは、GitLabが誤検出を検出した場合に発生する可能性があります。説明するために、最後のコミットをGitLabにプッシュします。

### プッシュオプション付き {#with-a-push-option}

プッシュオプションを使用して、シークレット検出をスキップできます:

- `secret_detection.skip_all`オプションを使用して、コミットをプッシュします:

  ```shell
  git push -o secret_detection.skip_all
  ```

シークレット検出はスキップされ、変更がプッシュ先のリモートリポジトリにプッシュされます。

### コミットメッセージを使用する {#with-a-commit-message}

コマンドラインにアクセスできない場合、またはプッシュオプションを使用したくない場合:

- 文字列`[skip secret push protection]`をコミットメッセージに追加します。例: 

  ```shell
  git commit --amend -m "Add fake secret [skip secret push protection]"
  ```

複数のコミットがある場合でも、変更をプッシュするには、コミットメッセージの1つに`[skip secret push protection]`を追加するだけで済みます。

## 次の手順 {#next-steps}

プロジェクトのセキュリティをさらに向上させるために、[パイプラインシークレット検出](pipeline/_index.md)を有効にすることを検討してください。
