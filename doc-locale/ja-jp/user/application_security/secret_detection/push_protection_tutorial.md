---
stage: Application Security Testing
group: Secret Detection
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 'チュートリアル: シークレットプッシュ保護でプロジェクトを保護する'
---

アプリケーションが外部リソースを使用する場合、通常、トークンやキーなどの**secret**でアプリケーションを認証する必要があります。もしシークレットがリモートリポジトリにプッシュされると、リポジトリへのアクセス権を持つ人は誰でも、あなたまたはあなたのアプリケーションになりすますことができます。

シークレットプッシュ保護を使用すると、GitLabがコミット履歴でシークレットを検出した場合、プッシュをブロックして漏洩を防ぐことができます。シークレットプッシュ保護を有効にすることは、機密データのコミットをレビューしたり、漏洩が発生した場合に修復したりする時間を減らす良い方法です。

このチュートリアルでは、シークレットプッシュ保護を設定し、偽のシークレットをコミットしようとするとどうなるかを確認します。シークレットプッシュ保護をスキップする方法についても学びます。これは、誤検出をバイパスする必要がある場合に役立ちます。

<i class="fa-youtube-play" aria-hidden="true"></i>このチュートリアルは、以下のGitLab Unfilteredのビデオから抜粋したものです:

- [シークレットプッシュ保護の概要](https://www.youtube.com/watch?v=SFVuKx3hwNI)
  <!-- Video published on 2024-06-21 -->
- [設定 - プロジェクトのシークレットプッシュ保護の有効化](https://www.youtube.com/watch?v=t1DJN6Vsmp0)
  <!-- Video published on 2024-06-23 -->
- [スキップシークレットプッシュ保護](https://www.youtube.com/watch?v=wBAhe_d2DkQ)
  <!-- Video published on 2024-06-04 -->

## はじめる前 {#before-you-begin}

このチュートリアルを開始する前に、以下のものがあることを確認してください:

- Ultimateプランのサブスクリプション。
- テストプロジェクト。お好みのプロジェクトを使用できますが、このチュートリアル専用のテストプロジェクトを作成することをご検討ください。
- コマンドラインGitに関するある程度の知識。

さらに、GitLab Self-Managedの場合のみ、シークレットプッシュ保護が[インスタンスで有効](secret_push_protection/_index.md#allow-the-use-of-secret-push-protection-in-your-gitlab-instance)になっていることを確認してください。

## シークレットプッシュ保護を有効にする {#enable-secret-push-protection}

シークレットプッシュ保護を使用するには、保護したい各プロジェクトでそれを有効にする必要があります。まず、テストプロジェクトでそれを有効にすることから始めましょう。

1. 上部のバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. 左サイドバーで、**セキュリティ** > **セキュリティ設定**を選択します。
1. **シークレットプッシュ保護**切替をオンにします。

次に、シークレットプッシュ保護をテストします。

## プロジェクトへのシークレットのプッシュを試す {#try-pushing-a-secret-to-your-project}

GitLabは、文字、数字、記号の特定のパターンを照合することでシークレットを識別します。これらのパターンは、シークレットのタイプを識別するためにも使用されます。偽のシークレット`glpat-12345678901234567890`をプロジェクトに追加して、この機能をテストしてみましょう: <!-- gitleaks:allow -->

1. プロジェクトで、新しいブランチをチェックアウトします:

   ```shell
   git checkout -b push-protection-tutorial
   ```

1. 以下の内容で新しいファイルを作成します。パーソナルアクセストークンの正確なフォーマットと一致させるために、`-`の前後のスペースを必ず削除してください:

   ```plaintext
   hello, world!

   # To make the example work, remove
   # the spaces before and after the dash:
   glpat - 12345678901234567890
   ```

1. ファイルをあなたのブランチにコミットします:

   ```shell
   git add .
   git commit -m "Add fake secret"
   ```

   シークレットがコミット履歴に入力されました。シークレットプッシュ保護は、シークレットのコミットを止めませんが、プッシュしたときにのみアラートを発します。

1. GitLabに変更をプッシュします。次のような表示がされます:

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

   GitLabはシークレットを検出し、プッシュをブロックします。エラーレポートから、以下のことがわかります:

   - シークレットを含むコミット (`123abc`)
   - シークレットを含むファイルと行番号 (`myFile.txt:2`)
   - シークレットのタイプ (`GitLab Personal Access Token`)

変更を正常にプッシュできていれば、シークレットを失効するし、置き換えるためにかなりの時間と労力を費やす必要がありました。その代わりに、[コミット履歴からシークレットを削除する](remove_secrets_tutorial.md)ことで、シークレットの漏洩を阻止したことを安心して知ることができます。

## シークレットプッシュ保護をスキップする {#skip-secret-push-protection}

場合によっては、シークレットプッシュ保護がシークレットを識別した場合でも、コミットをプッシュする必要があります。これは、GitLabが誤検出を検出した場合に発生する可能性があります。デモンストレーションとして、最後のコミットをGitLabにプッシュします。

### プッシュオプションを使用する {#with-a-push-option}

プッシュオプションを使用してシークレット検出をスキップできます:

- `secret_detection.skip_all`オプションでコミットをプッシュします:

  ```shell
  git push -o secret_detection.skip_all
  ```

シークレット検出はスキップされ、変更はリモートにプッシュされます。

### コミットメッセージを使用する {#with-a-commit-message}

コマンドラインにアクセスできない場合、またはプッシュオプションを使用しない場合は:

- 文字列`[skip secret push protection]`をコミットメッセージに追加します。例: 

  ```shell
  git commit --amend -m "Add fake secret [skip secret push protection]"
  ```

複数のコミットがある場合でも、変更をプッシュするには、いずれかのコミットメッセージに`[skip secret push protection]`を追加するだけで済みます。

## 次の手順 {#next-steps}

プロジェクトのセキュリティをさらに向上させるために、[パイプラインシークレット検出](pipeline/_index.md)の有効化を検討してください。
