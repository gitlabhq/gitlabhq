---
stage: AI-powered
group: Duo Chat
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitLab Duo Agent Platformをカスタマイズする
---

エージェントプラットフォームをカスタマイズして、ワークフロー、コーディング標準、またはプロジェクト要件に合わせることができます。

## カスタマイズオプション {#customization-options}

| 方法    | AI機能 | ユースケース    |
|-----------|------------|--------------|
| [カスタムルールを使用](custom_rules.md)して指示を提供する。 | \- GitLab Duo Chat | \- 個人の設定を適用する。<br>\- チーム標準を適用する。 |
| [AGENTS.mdファイルを作成](agents_md.md)して指示を提供する。 | \- GitLab Duo Chat<br>\- フロー<br>\- GitLab以外のAIコーディングツール | \- プロジェクト固有のコンテキストを考慮する。<br>\- モノレポを整理する。<br>\- ディレクトリ固有の規約を適用する。 |
| [MRレビュー指示を作成](review_instructions.md)し、プロジェクト内で一貫性のある具体的なコードレビュー標準を確保する。 | \- コードレビューフロー | 適用:<br>\- 言語固有のレビュールール。<br>\- セキュリティ標準。<br>\- コード品質要件。<br>\- ファイル固有のガイドライン。 |

## ベストプラクティス {#best-practices}

エージェントプラットフォームをカスタマイズする際は、以下のベストプラクティスを適用してください:

- 最小限で明確かつ簡単な指示から始め、必要に応じて追加する。指示ファイルは最小限の長さに留める。
- 指示は具体的で、実行可能な内容にする。必要に応じて例を示す。
- ユースケースに合った方法を選択する。
- 複数の方法を組み合わせて、GitLab Duoの動作を調整および制御する。
- 複数の方法を使用する場合は、プロジェクトの次のファイル構造を検討してください:

  ```plaintext
  Project root directory
  |─ AGENTS.md                         # Applies to multiple Duo features
  |─ .gitlab/duo/
     |─ chat-rules.md                  # Custom Chat-specific rules
     |─ mr-review-instructions.yaml    # Custom code review standards
     |─ ...                            # Other configuration as needed
  ```

  `.gitlab/duo/`フォルダーに、他の設定ファイル（[custom flow definitions](../../duo_agent_platform/flows/custom.md)や、[MCPサーバー構成](../../gitlab_duo/model_context_protocol/mcp_server.md)ファイルなど）を含めることができます。
- 特定の指示を設けている理由がわかるよう、判断の根拠をコメントに記載する。
- 変更を管理するため、[コードオーナー](../../project/codeowners/_index.md)でカスタマイズファイルを保護する。
