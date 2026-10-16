---
title: GitLab Duo CLIのオートモード
tier: [ Premium, Ultimate ]
offering: [ gitlab_com, self_managed, gitlab_dedicated ]
stage: ai_clients
documentation_link: "../../../user/gitlab_duo_cli/use/#auto-mode"
work_item: https://gitlab.com/groups/gitlab-org/-/work_items/23697
categories: [ Duo CLI ]
level: secondary
weight: 50
---

GitLab Duo CLIに新しいオートモードが追加されました。
オートモードでは、GitLab Duoが事前に承認を求めることなくツールを使用するため、シェルコマンド、`git`操作、またはMCPツール呼び出しのたびに処理が停止することなく、長時間のタスクを実行できます。

オートモードは組織の管理設定に従います。

- オートモードはデフォルトでオフになっています。管理者、オーナー、メンテナーは、インスタンス、グループ、プロジェクトに対してこの設定をオンにできます。
  管理者およびグループオーナーは、インスタンスまたはグループ全体に対して**常にオフ**にロックすることもできます。
- エージェントツールのガバナンスは引き続き適用されます。**常に拒否**に設定されたツールはブロックされたままになります。

オートモードを使用するには、GitLab Duo CLI 9.22.0以降が必要です。
`>`プロンプトの下に表示されるモードが`auto`になるまで<kbd>Tab</kbd>キーを押してください。
オートモードは、信頼できるリポジトリおよび破棄可能なブランチでのみ使用してください。
