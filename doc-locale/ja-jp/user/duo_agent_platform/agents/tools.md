---
stage: AI-powered
group: Workflow Catalog
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: エージェントツール
---

カスタムエージェントは、次のツールを使用できます。

<!-- markdownlint-disable MD044 -->

## Web UIとIDEで利用可能なツール {#tools-available-in-the-web-ui-and-ide}

| 名前 | ツール | 説明 |
|------|------|-------------|
| Add New Task | `add_new_task` | タスクを追加します。 |
| Build Review Merge Request Context | `build_review_merge_request_context` | コードレビュー向けに、包括的なマージリクエストコンテキストを構築します。 |
| Ci Linter | `ci_linter` | CI/CD構文ルールに基づいてCI/CDのYAML設定を検証します。 |
| Confirm Vulnerability | `confirm_vulnerability` | プロジェクト内の脆弱性のステータスを`CONFIRMED`に変更します。 |
| Create Commit | `create_commit` | リポジトリで、複数のファイルアクションを含むコミットを作成します。 |
| Create Epic | `create_epic` | グループにエピックを作成します。 |
| Create Issue | `create_issue` | プロジェクトにイシューを作成します。 |
| Create Issue Note | `create_issue_note` | イシューにノートを追加します。 |
| Create Merge Request | `create_merge_request` | プロジェクトにマージリクエストを作成します。 |
| Create Merge Request Note | `create_merge_request_note` | マージリクエストにノートを追加します。クイックアクションはサポートされていません。 |
| Create Plan | `create_plan` | タスクのリストを作成します。 |
| Create Vulnerability Issue | `create_vulnerability_issue` | プロジェクト内のセキュリティ脆弱性にリンクされたイシューを作成します。 |
| Create Work Item | `create_work_item` | グループまたはプロジェクトに作業アイテムを作成します。クイックアクションはサポートされていません。 |
| Create Work Item Note | `create_work_item_note` | 作業アイテムにノートを追加します。クイックアクションはサポートされていません。 |
| Dismiss Vulnerability | `dismiss_vulnerability` | プロジェクト内のセキュリティ脆弱性を無視します。 |
| Extract Lines From Text | `extract_lines_from_text` | テキストから特定の行を抽出します。 |
| Get Commit | `get_commit` | プロジェクトからコミットを取得します。 |
| Get Commit Comments | `get_commit_comments` | プロジェクト内のコミットのコメントを取得します。 |
| Get Commit Diff | `get_commit_diff` | プロジェクト内のコミットの差分を取得します。 |
| Get Current User | `get_current_user` | 現在のユーザーに関する次の情報を取得します: ユーザー名、役職、優先言語。 |
| Get Epic | `get_epic` | グループ内のエピックを取得します。 |
| Get Epic Note | `get_epic_note` | エピックからノートを取得します。 |
| Get Issue | `get_issue` | プロジェクトからイシューを取得します。 |
| Get Issue Note | `get_issue_note` | イシューからノートを取得します。 |
| Get Job Logs | `get_job_logs` | ジョブのトレースを取得します。 |
| Get Merge Request | `get_merge_request` | マージリクエストに関する詳細を取得します。 |
| Get Pipeline Errors | `get_pipeline_errors` | マージリクエストの最新パイプラインで失敗したジョブのログを取得します。 |
| Get Pipeline Failing Jobs | `get_pipeline_failing_jobs` | パイプラインで失敗したジョブのIDを取得します。 |
| Get Plan | `get_plan` | タスクのリストを取得します。 |
| Get Previous Session Context | `get_previous_session_context` | 以前のセッションからコンテキストを取得します。 |
| Get Project | `get_project` | プロジェクトに関する詳細を取得します。 |
| Get Repository File | `get_repository_file` | リモートリポジトリからファイルの内容を取得します。 |
| Get Security Finding Details | `get_security_finding_details` | 潜在的な脆弱性について、そのIDと、それを特定したパイプラインスキャンのIDを指定して詳細を取得します。 |
| Get Vulnerability Details | `get_vulnerability_details` | IDで指定された脆弱性に関する次の情報を取得します: 脆弱性の基本情報、位置情報の詳細、CVEエンリッチメントデータ、検出パイプライン情報、詳細な脆弱性レポートデータ。 |
| Get Wiki Page | `get_wiki_page` | すべてのコメントを含め、プロジェクトまたはグループからWikiページを取得します。 |
| Get Work Item | `get_work_item` | グループまたはプロジェクトから作業アイテムを取得します。 |
| Get Work Item Notes | `get_work_item_notes` | 作業アイテムのすべてのノートを取得します。 |
| GitLab API取得 | `gitlab_api_get` | 任意のREST APIエンドポイントに対して、読み取り専用のGETリクエストを行います。 |
| GitLab blob検索 | `gitlab_blob_search` | グループ、プロジェクト、またはインスタンス内のファイルのコンテンツを検索します。グループ全体またはインスタンスで検索するには、[advanced](../../../integration/advanced_search/elasticsearch.md#enable-code-search-with-advanced-search)検索または[完全一致コードの検索](../../../integration/zoekt/_index.md#enable-exact-code-search)をオンにする必要があります。  |
| GitLabコミット検索 | `gitlab_commit_search` | プロジェクトまたはグループ内のコミットを検索します。 |
| GitLabドキュメント検索 | `gitlab_documentation_search` | GitLabドキュメント内の情報を検索します。 |
| GitLab GraphQL | `gitlab_graphql` | GraphQL APIに対して、読み取り専用のGraphQLクエリを実行します。 |
| GitLabグループプロジェクト検索 | `gitlab_group_project_search` | グループ内のプロジェクトを検索します。 |
| GitLabイシュー検索 | `gitlab_issue_search` | プロジェクトまたはグループ内のイシューを検索します。 |
| GitLabマージリクエスト検索 | `gitlab_merge_request_search` | プロジェクトまたはグループ内のマージリクエストを検索します。 |
| GitLabマイルストーン検索 | `gitlab_milestone_search` | プロジェクトまたはグループ内のマイルストーンを検索します。 |
| GitLabノート検索 | `gitlab_note_search` | プロジェクト内のノートを検索します。 |
| GitLabユーザー検索 | `gitlab__user_search` | プロジェクトまたはグループ内のユーザーを検索します。 |
| GitLabウィキblobs検索 | `gitlab_wiki_blob_search` | プロジェクトまたはグループ内のWikiの内容を検索します。 |
| Link Vulnerability To Issue | `link_vulnerability_to_issue` | プロジェクト内のセキュリティ脆弱性にイシューをリンクします。 |
| Link Vulnerability To Merge Request | `link_vulnerability_to_merge_request` | GraphQLを使用して、プロジェクト内のマージリクエストにセキュリティ脆弱性をリンクします。 |
| List All Merge Request Notes | `list_all_merge_request_notes` | マージリクエストのすべてのノートをリストします。 |
| List Commits | `list_commits` | プロジェクト内のコミットをリストします。 |
| List Epic Notes | `list_epic_notes` | エピックのすべてのノートをリストします。 |
| List Epics | `list_epics` | グループとそのサブグループのすべてのエピックをリストします。 |
| List Group Audit Events | `list_group_audit_events` | グループ監査イベントをリストします。グループ監査イベントにアクセスするには、オーナーロールが必要です。 |
| List Instance Audit Events | `list_instance_audit_events` | インスタンスレベルの監査イベントをリストします。インスタンス監査イベントを表示するには、管理者である必要があります。 |
| List Issue Notes | `list_issue_notes` | イシューのすべてのノートをリストします。 |
| List Issues | `list_issues` | プロジェクト内のすべてのイシューをリストします。 |
| List Merge Request Diffs | `list_merge_request_diffs` | マージリクエストで変更されたファイルの差分をリストします。 |
| Project Audit Events | `list_project_audit_events` | プロジェクトの監査イベントをリストします。プロジェクト監査イベントにアクセスするには、オーナーロールが必要です。 |
| List Repository Tree | `list_repository_tree` | リポジトリ内のファイルとディレクトリをリストします。 |
| List Security Findings | `list_security_findings` | 特定のパイプラインのセキュリティスキャンから、一時的なセキュリティ検出結果をリストします。 |
| List Vulnerabilities | `list_vulnerabilities` | プロジェクト内のセキュリティ脆弱性をリストします。 |
| List Work Items | `list_work_items` | プロジェクトまたはグループ内の作業アイテムをリストします。 |
| GitLab Duoコードレビューの投稿 | `post_duo_code_review` | GitLab Duoコードレビューをマージリクエストに投稿します。 |
| SAST FP分析をGitLabに投稿 | `post_sast_fp_analysis_to_gitlab` | SASTの誤検出判定の分析結果を投稿します。 |
| Remove Task | `remove_task` | タスクのリストからタスクを削除します。 |
| Revert To Detected Vulnerability | `revert_to_detected_vulnerability` | 脆弱性のステータスを`detected`に戻します。 |
| GLQLクエリの実行 | `run_glql_query` | 作業アイテム、エピック、およびマージリクエストに対してGLQLクエリを実行します。 |
| Run Tests | `run_tests` | 任意の言語またはフレームワークのテストコマンドを実行します。 |
| Set Task Status | `set_task_status` | タスクのステータスを設定します。 |
| Update Epic | `update_epic` | グループ内のエピックを更新します。 |
| Update Issue | `update_issue` | プロジェクト内のイシューを更新します。 |
| Update Merge Request | `update_merge_request` | マージリクエストを更新します。ターゲットブランチの変更、タイトルの編集、MRのクローズも可能です。 |
| Update Task Description | `update_task_description` | タスクの説明を更新します。 |
| Update Vulnerability Severity | `update_vulnerability_severity` | プロジェクト内の脆弱性の重大度レベルを更新します。 |
| Update Work Item | `update_work_item` | グループまたはプロジェクト内の既存の作業アイテムを更新します。クイックアクションはサポートされていません。 |

## IDEのみで利用可能なツール {#tools-available-in-the-ide-only}

| 名前 | ツール | 説明 |
|------|------|-------------|
| Create File With Contents | `create_file_with_contents` | ファイルを作成し、内容を書き込みます。 |
| Edit File | `edit_file` | 既存のファイルを編集します。 |
| Find Files | `find_files` | プロジェクト内のファイルを再帰的に検索します。 |
| Grep | `grep` | ファイル内のテキストパターンを再帰的に検索します。このツールは`.gitignore`ファイルのルールを尊重します。 |
| List Dir | `list_dir` | プロジェクトのルートを基準とした相対パスで、ディレクトリ内のファイルをリストします。 |
| Mkdir | `mkdir` | 現在のワークツリーにディレクトリを作成します。 |
| Read File | `read_file` | ファイルの内容を読み取ります。 |
| Read Files | `read_files` | ファイルの内容を読み取ります。 |
| Run Command | `run_command` | 現在の作業ディレクトリでbashコマンドを実行します。Gitコマンドはサポートされていません。 |
| Run Git Command | `run_git_command` | 現在の作業ディレクトリでGitコマンドを実行します。 |
