---
stage: AI-powered
group: AI Framework
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitLab Duo with Amazon Q
---

{{< details >}}

- プラン: Ultimate
- アドオン: GitLab Duo with Amazon Q
- 提供形態: GitLab Self-Managed

{{< /details >}}

{{< history >}}

- GitLab 17.7で`amazon_q_integration`[フラグ](../../administration/feature_flags/_index.md)とともに[ベータ](../../policy/development_stages_support.md#beta)として導入されました。デフォルトでは無効になっています。
- 機能フラグ`amazon_q_integration`は、GitLab 17.8で削除されました。
- GitLab 17.11で、GitLab Duoの追加機能サポートとともに一般提供になりました。

{{< /history >}}

{{< alert type="note" >}}

GitLab Duo with Amazon Qは、他のGitLab Duoアドオンと組み合わせることはできません。

{{< /alert >}}

re:Invent 2024で、AmazonはGitLab Duo with Amazon Qインテグレーションを発表しました。このインテグレーションにより、タスクを自動化し、生産性を向上させることができます。

GitLab Duo with Amazon Q:

- イシューとマージリクエストでさまざまなタスクを実行できます。
- [他の多くのGitLab Duo機能を搭載](../gitlab_duo/feature_summary.md)。

クリック操作のデモについては、[GitLab Duo with Amazon Q製品ツアー](https://gitlab.navattic.com/duo-with-q)をご覧ください。
<!-- Demo published on 2025-04-23 -->

GitLab Duo with Amazon Qのサブスクリプションを入手するには、アカウントエグゼクティブにお問い合わせください。

または、トライアルをリクエストするには、[こちらのフォームにご記入ください](https://about.gitlab.com/partners/technology-partners/aws/#form)。

## GitLab Duo with Amazon Qを設定する {#set-up-gitlab-duo-with-amazon-q}

GitLab Duo with Amazon QサブスクリプションとGitLab 17.11バージョン以降をお持ちの場合は、[インスタンスにGitLab Duo with Amazon Qをセットアップ](setup.md)できます。

## イシューでGitLab Duo with Amazon Qを使用する {#use-gitlab-duo-with-amazon-q-in-an-issue}

イシューでGitLab Duo with Amazon Qを実行するには、[クイックアクション](../project/quick_actions.md)を使用します。

### アイデアをマージリクエストに変える {#turn-an-idea-into-a-merge-request}

イシューのアイデアを、提案された実装を含むマージリクエストに変えます。

Amazon Qは、イシューのタイトルと説明、およびプロジェクトのコンテキストを使用して、イシューに対処するためのコードを含むマージリクエストを作成します。

#### イシューの説明から {#from-the-issue-description}

1. 新しいイシューを作成するか、既存のイシューを開き、右上隅で**編集**を選択します。
1. 説明ボックスに、`/q dev`と入力します。
1. **変更を保存**を選択します。

#### コメントから {#from-a-comment}

1. イシューのコメントに、`/q dev`と入力します。
1. **コメント**を選択します。

### Javaのアップグレード {#upgrade-java}

Amazon Qは、Java 8または11のコードを分析し、コードをJava 17に更新するために必要なJavaの変更を判断できます。

[チュートリアルを見る](https://gitlab.navattic.com/duo-q-transform)。

前提要件: 

- プロジェクト用に[RunnerとCI/CDパイプラインが構成されている](../../ci/_index.md)必要があります。
- `pom.xml`ファイルに[ソースとターゲット](https://maven.apache.org/plugins/maven-compiler-plugin/examples/set-compiler-source-and-target.html)が必要です。

Javaをアップグレードするには:

1. イシューを作成します。
1. イシューのタイトルと説明で、Javaをアップグレードしたい理由を説明します。バージョンの詳細を入力する必要はありません。Amazon Qがバージョンを判断できます。
1. イシューを保存します。次に、コメントで、`/q transform`と入力します。
1. **コメント**を選択します。

CI/CDパイプラインジョブが開始されます。コメントには、詳細とジョブへのリンクが表示されます。

- ジョブが成功すると、アップグレードに必要なコード変更を含むマージリクエストが作成されます。
- ジョブが失敗した場合、コメントには潜在的な修正に関する詳細が表示されます。

## マージリクエストでGitLab Duo with Amazon Qを使用する {#use-gitlab-duo-with-amazon-q-in-a-merge-request}

マージリクエストでGitLab Duo with Amazon Qを実行するには、[クイックアクション](../project/quick_actions.md)を使用します。

### マージリクエストをレビューする {#review-a-merge-request}

Amazon Qは、マージリクエストを分析し、コードを改善するための提案をすることができます。セキュリティの問題、品質の問題、非効率性、その他のエラーなどを見つけることができます。

[Amazon Qにマージリクエストを開くか再度開くと自動的にレビューさせる](setup.md#enter-the-arn-in-gitlab-and-enable-amazon-q)か、手動でレビューを開始できます。

手動で開始するには:

1. マージリクエストを開きます。
1. **概要**タブのコメントで、`/q review`と入力します。
1. **コメント**を選択します。

Amazon Qは、マージリクエストの変更をレビューし、コメントで結果を表示します。

### フィードバックに基づいてコードを変更する {#make-code-changes-based-on-feedback}

Amazon Qは、レビュアーのフィードバックに基づいてコードを変更できます。

1. レビュアーのフィードバックがあるマージリクエストを開きます。
1. **概要**タブで、対処するコメントに移動します。
1. コメントの下の**返信**ボックスに、`/q dev`と入力します。
1. **今すぐコメントを追加**を選択します。

Amazon Qは、レビュアーのコメントとフィードバックに基づいて、マージリクエストへの変更を提案します。

### 単体テストの生成 {#generate-unit-tests}

Amazon Qを使用して、コードの新しい単体テストを生成します。

#### イシューから作成する {#from-an-issue}

1. イシューを作成します。
1. 次のいずれかのオプションを使用して、コードのテストが生成されるようにリクエストします:
   - イシューの説明で、リクエストを記述し、**変更を保存**を選択します。
   - コメントで、`/q dev`と入力し、**コメント**を選択します。

Amazon Qは、提案されたテストを含むマージリクエストを作成します。

#### マージリクエストから {#from-a-merge-request}

1. マージリクエストを開きます。
1. **変更**タブで、テストを追加するインラインコメントを残します。ファイル名、クラス名、行番号など、できるだけ詳細なフィードバックを含めます。
1. コメントで、新しい行に`/q dev`と入力し、**今すぐコメントを追加**を選択します。

Amazon Qは、提案されたテストでマージリクエストを更新します。

## 関連トピック {#related-topics}

- [GitLab Duo with Amazon Q](setup.md)を設定する
- [GitLab Duo with Amazon Q機能の完全なリストを表示](../gitlab_duo/feature_summary.md)。
- [GitLab Duo authentication and authorization](../gitlab_duo/security.md)
- <i class="fa fa-youtube-play youtube" aria-hidden="true"></i>[GitLab Duo with Amazon Q - アイデアからマージリクエストまで](https://youtu.be/jxxzNst3jpo?si=QHO8JnPgMoFIllbL)<!-- Video published on 2025-04-17 -->
- <i class="fa fa-youtube-play youtube" aria-hidden="true"></i>[GitLab Duo with Amazon Q - コードレビューの最適化](https://youtu.be/4gFIgyFc02Q?si=S-jO2M2jcXnukuN_)<!-- Video published on 2025-05-20 -->
- <i class="fa fa-youtube-play youtube" aria-hidden="true"></i>[GitLab Duo with Amazon Q - フィードバックに基づいてコードを変更する](https://youtu.be/31E9X9BrK5s?si=v232hBDmlGpv6fqC)<!-- Video published on 2025-05-30 -->
