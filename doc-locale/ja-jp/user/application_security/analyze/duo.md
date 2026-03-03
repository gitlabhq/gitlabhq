---
stage: Security Risk Management
group: Security Insights
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: AIで脆弱性を説明
---

{{< details >}}

- プラン: Ultimate
- アドオン: GitLab Duo Enterprise、GitLab Duo with Amazon Q
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< collapsible title="モデル情報" >}}

- [デフォルトのLLM](../../gitlab_duo/model_selection.md#default-models)
- Amazon QのLLM: Amazon Q Developer
- [セルフホストモデル対応のGitLab Duo](../../../administration/gitlab_duo_self_hosted/_index.md)で利用可能

{{< /collapsible >}}

{{< history >}}

- [導入](https://gitlab.com/groups/gitlab-org/-/epics/10368) GitLab 16.0で、GitLab.comの[実験](../../../policy/development_stages_support.md#experiment)として導入されました。
- GitLab 16.2で[ベータ](../../../policy/development_stages_support.md#beta)ステータスにプロモートされました。
- GitLab 17.2で[一般提供](https://gitlab.com/groups/gitlab-org/-/epics/10642)になりました。
- GitLab 17.6以降、GitLab Duoアドオンが必須になりました。

{{< /history >}}

GitLab Duo脆弱性Explanationは、大規模言語モデルを使用して、脆弱性に関して以下の支援が可能です:

- 脆弱性を要約します。
- デベロッパーとセキュリティアナリストが、脆弱性、その悪用方法、修正方法を理解するのに役立ちます。
- 推奨される軽減策を提供します。

GitLab Duoは、重大度が高いクリティカルな重大度のSAST脆弱性を自動的に分析して、誤検出の可能性を特定することもできます。詳細については、[SAST誤検出の検出](../vulnerabilities/false_positive_detection.md)を参照してください。

<i class="fa-youtube-play" aria-hidden="true"></i> [概要を見る](https://www.youtube.com/watch?v=MMVFvGrmMzw&list=PLFGfElNsQthZGazU1ZdfDpegu0HflunXW)

前提条件: 

- [GitLab Duo](../../gitlab_duo/turn_on_off.md)は、グループまたはインスタンスに対して有効になっている必要があります。
- プロジェクトのメンバーである必要があります。
- 脆弱性はSASTスキャナーからのものでなければなりません。

脆弱性を説明するには:

1. 上部のバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **セキュリティ** > **脆弱性レポート**を選択します。
1. オプション。デフォルトのフィルターを削除するには、**クリア**（{{< icon name="clear" >}}）を選択します。
1. 脆弱性のリストの上にある、フィルターバーを選択します。
1. 表示されるドロップダウンリストで、**ツール**を選択し、次に**SAST**カテゴリのすべての値を選択します。
1. フィルターフィールドの外側を選択します。脆弱性の重大度の合計と、一致する脆弱性のリストが更新されます。
1. 説明してほしいSAST脆弱性を選択します。
1. 次のいずれかを実行します。

   - 脆弱性の説明の下にある「_GitLab Duo Chatにこの脆弱性の解説と修正案の提示を依頼することで、AIを使用することもできます_」というテキストを選択します。
   - 右上にある**マージリクエストで解決**ドロップダウンリストから、**脆弱性の説明**を選択し、**脆弱性の説明**を選択します。
   - GitLab Duo Chatを開き、`/vulnerability_explain`と入力して[explain a vulnerability](../../gitlab_duo_chat/examples.md#explain-a-vulnerability)コマンドを使用します。

応答はページの右側に表示されます。

GitLab.comでは、この機能が利用可能です。デフォルトでは、Anthropic [`claude-3-haiku`](https://docs.anthropic.com/en/docs/about-claude/models#claude-3-a-new-generation-of-ai)モデルを搭載しています。GitLabは、大規模言語モデルが正しい結果を生成することを保証できません。説明は注意して使用してください。

## 脆弱性の説明のためにサードパーティAI APIと共有されるデータ {#data-shared-with-third-party-ai-apis-for-vulnerability-explanation}

次のデータは、サードパーティのAI APIと共有されます:

- 脆弱性のタイトル（使用するスキャナーによっては、ファイル名が含まれる場合があります）。
- 脆弱性の識別子。
- ファイル名。
