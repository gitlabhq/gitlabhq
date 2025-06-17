---
stage: Foundations
group: Import and Integrate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: インタラクティブAPIドキュメント
---

[OpenAPI仕様](https://swagger.io/specification/)（以前はSwaggerと呼ばれていました）は、RESTful APIに対して、言語に依存しない標準的なインターフェースを定義します。OpenAPI定義ファイルはYAML形式で記述されており、GitLabブラウザによって、人間が判読しやすいインターフェースに自動的にレンダリングされます。

GitLab APIの一般的な情報については、[GitLabを使用して拡張](../_index.md)を参照してください。

<!--
The following link is absolute rather than relative because it needs to be viewed through the GitLab
Open API file viewer: https://docs.gitlab.com/ee/user/project/repository/#openapi-viewer.
-->
[インタラクティブAPIドキュメントツール](https://gitlab.com/gitlab-org/gitlab/-/blob/master/doc/api/openapi/openapi_v2.yaml)を使用すると、GitLab.com WebサイトでAPIテストを直接実行できます。OpenAPI仕様でドキュメント化されているのは、使用可能なエンドポイントのほんの一部ですが、現在のリストはツールの機能を示しています。

![利用可能なGitLab APIエンドポイントのリスト。](img/apiviewer01-fs8_v13_9.png)

## エンドポイントパラメーター

エンドポイントリストを展開すると、説明、入力パラメーター（必要な場合）、サーバーの応答例が表示されます。一部のパラメーターには、デフォルト値、または許可される値のリストが含まれています。

![エンドポイント情報と試用オプションが表示されている展開されたビュー。](img/apiviewer04-fs8_v13_9.png)

## インタラクティブセッションの開始

[パーソナルアクセストークン（PAT）](../../user/profile/personal_access_tokens.md)は、インタラクティブセッションを開始する方法の1つです。インタラクティブセッションを開始するには、メインページから**認証**を選択します。そうすると、ダイアログボックスが表示され、現在のWebセッションで有効なPATを入力するよう求められます。

エンドポイントをテストするには、まずエンドポイント定義ページで**試用**を選択します。必要に応じてパラメーターを入力し、**実行**を選択します。次の例では、`version`エンドポイントのリクエストを実行しました（パラメーターは不要）。ツールには、`curl`コマンドとリクエストのURLに続いて、返されたサーバーの応答が表示されます関連するパラメーターを編集して、もう一度**実行**を選択すると、新しい応答を作成することができます。

![リクエストと応答が含まれたエンドポイントテストビュー。](img/apiviewer03-fs8_v13_9.png)

## ビジョン

APIコードは信頼できる唯一の情報源であり、APIドキュメントは、その実装に緊密に結び付けられている必要があります。OpenAPI仕様は、APIをドキュメント化するための標準化された包括的な方法を提供します。これは、GitLab REST APIをドキュメント化するための最適な形式である必要があります。これにより、より正確で信頼性が高く、ユーザーフレンドリーなドキュメントが実現し、GitLab REST APIを使用する際の全体的なエクスペリエンスが向上します。

それを実現するには、APIコードの変更ごとにOpenAPI仕様を更新する必要があります。そのように更新することで、ドキュメントが常に最新で正確なものとなり、ユーザーの混乱やエラーのリスクを軽減することができます。

OpenAPIドキュメントをAPIコードから自動生成して、簡単に最新かつ正確な状態に保てるようにする必要があります。その結果、ドキュメントチームの時間と労力を節約できるようになります。

[OpenAPI V2エピックでREST APIをドキュメント化する](https://gitlab.com/groups/gitlab-org/-/epics/8926)で、このビジョンの現在の進捗状況を追跡できます。
