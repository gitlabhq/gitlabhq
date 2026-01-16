---
stage: AI-powered
group: Duo Chat
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitLab Duoをカスタマイズする
---

ワークフロー、コーディング標準、またはプロジェクト要件に合わせてGitLab Duoをカスタマイズできます。

## カスタマイズオプション {#customization-options}

| 方法    | AI機能 | ユースケース    |
|-----------|------------|--------------|
| 指示を提供するには、[カスタムルールを使用](custom_rules.md)します。 | \- GitLab Duo Chat | \- 個人的な設定を適用します。<br>\- チーム標準を適用します。 |
| 指示を提供するには、[AGENTS.mdファイルを作成](agents_md.md)します。 | \- GitLab Duo Chat<br>\- フロー<br>\- その他の非GitLab人工知能コーディングツール | \- プロジェクト固有のコンテキストを考慮します。<br>\- モノレポを編成します。<br>\- ディレクトリ固有の規則を適用します。 |
| プロジェクトで一貫性のある特定のコードレビュー標準を確保するには、[MRレビュー指示を作成](review_instructions.md)します。 | \- GitLab Duoコードレビュー（クラシック）<br>\- コードレビューフロー | 適用:<br>\- 言語固有のレビュー規則。<br>\- セキュリティ標準。<br>\- コード品質要件。<br>\- ファイル固有のガイドライン。 |

## ベストプラクティス {#best-practices}

GitLab Duoをカスタマイズする場合は、次のベストプラクティスを適用します:

- 最小限で明確かつ簡単な指示から始め、必要に応じて追加します。指示ファイルはできるだけ短くしてください。
- 指示が具体的で実行可能であることを確認してください。必要に応じて例を示してください。
- ユースケースに合った方法を選択してください。
- 複数の方法を組み合わせて、GitLab Duoの動作を調整および制御します。
- 特定の指示が存在する理由を説明するために、コメントで選択内容をドキュメント化します。
- 変更を管理するには、[コードオーナー](../../project/codeowners/_index.md)でカスタマイズファイルを保護します。
