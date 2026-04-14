---
stage: AI-powered
group: AI Framework
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: GitLab Duoのコンテキスト認識
---

GitLab Duoが判断し、提案を行うために役立つさまざまな情報が利用できます。

情報は、以下のいずれかの状況で利用可能です:

- 常時。
- お客様の場所に基づく（移動するとコンテキストが変化します）。
- 明示的に参照される場合。たとえば、URL、ID、またはパスで情報を記述する場合。

## 常に利用可能 {#always-available}

- GitLabドキュメント。
- 一般的なプログラミング知識、ベストプラクティス、および言語固有の情報。
- カーソルの前後のコードを含め、表示または編集しているファイルの内容。
- GitLab UIでChatを使用する場合、現在のページタイトルとURL。
- `/refactor`、`/fix`、`/tests`、および`/explain`スラッシュコマンドは、コード提案からの最新のリポジトリX-Rayレポートにアクセスできます。

## 場所に基づく {#based-on-location}

これらのリソースのいずれかを開いている場合、GitLab Duoはそれらについて認識します。

- チャットに伝えたファイル（以下のいずれかの方法による）:
  - 直接ファイルパスを提供する。
  - お使いのIDEで、`/include`コマンドを含めて。
- ファイル内で選択されたコード。
- イシュー（GitLab Duo Enterpriseのみ）。
- エピック（GitLab Duo Enterpriseのみ）。
- [その他の作業アイテムの種類](../work_items/_index.md#work-item-types)（GitLab Duo Enterpriseのみ）。

> [!note]
> IDEでは、既知の形式に一致するシークレットおよび機密性の高い値は、GitLab Duo Chatに送信される前に削除されます。

マージリクエストにいる場合、UIでは、GitLab Duoは次のことも認識します:

- マージリクエスト自体（GitLab Duo Enterpriseのみ）。
- マージリクエスト内のコミット（GitLab Duo Enterpriseのみ）。
- マージリクエストパイプラインのCI/CDジョブ（GitLab Duo Enterpriseのみ）。

### 明示的に参照される場合 {#when-referenced-explicitly}

場所に基づいて利用可能なすべてのリソースは、IDまたはURLで明示的に参照する場合にも利用できます。

## コードレビューからコンテキストを除外する {#exclude-context-from-code-review}

{{< details >}}

- プラン: Premium、Ultimate
- アドオン: GitLab Duo ProまたはEnterprise

{{< /details >}} {{< history >}}

- GitLab 18.2で`use_duo_context_exclusion`[フラグ](../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/groups/gitlab-org/-/epics/17124)されました。デフォルトでは無効になっています。
- GitLab 18.4でベータ版に変更されました。
- GitLab 18.5でデフォルトで有効になりました。

{{< /history >}}

コードレビューがコンテキストとして使用するプロジェクトコンテンツを除外できます。パスワードや設定ファイルなどの機密情報を保護するために、コンテキストを除外します。

コードレビューが除外するコンテンツを指定するには:

1. 上部のバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **設定** > **一般**を選択します。
1. **GitLab Duo**の**GitLab Duoコンテキスト除外**セクションで、**除外の管理**を選択します。
1. GitLab Duoコンテキストから除外するプロジェクトファイルとディレクトリを指定し、**除外を保存**を選択します。
1. オプション。既存の除外を削除するには、該当する除外の**削除**（{{< icon name="remove" >}}）を選択します。
1. **変更を保存**を選択します。
