---
stage: Verify
group: Pipeline Authoring
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: GitLab CI Lintツールを使用してCI/CD設定を検証し、ジョブの実行前にエラーを見つけるためにパイプラインをシミュレートします。
title: GitLab CI/CDの設定を検証する
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

CI Lintツールを使用して、GitLab CI/CDの設定が有効かどうかを確認します。`.gitlab-ci.yml`ファイル、またはその他のサンプルCI/CD設定の構文を検証できます。このツールは、構文エラーとロジックエラーをチェックし、パイプラインの作成をシミュレートすることで、設定におけるより複雑な問題がないか確認できます。

[パイプラインエディタ](../pipeline_editor/_index.md)を使用している場合、設定の構文は自動的に検証されます。

VS Codeを使用している場合は、[VS Code用GitLab Workflow拡張機能](../../editor_extensions/visual_studio_code/_index.md)でCI/CD設定を検証できます。

## CI/CD構文をチェックする {#check-cicd-syntax}

CI Lintツールは、[`includes`キーワード](_index.md#include)で追加された設定を含め、GitLab CI/CD設定の構文チェックを実行します。

CI LintツールでCI/CD設定をチェックするには:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **ビルド** > **パイプラインエディタ**を選択します。
1. **検証**タブを選択します。
1. **Lint CI/CDサンプル**を選択します。
1. チェックするCI/CD設定のコピーをテキストボックスに貼り付けます。
1. **検証**を選択します。

## パイプラインをシミュレートする {#simulate-a-pipeline}

GitLab CI/CDパイプラインの作成をシミュレートして、[`needs`](_index.md#needs)および[`rules`](_index.md#rules)設定に関する問題など、より複雑な問題を見つけることができます。シミュレーションは、デフォルトブランチでGit `push`イベントとして実行されます。

前提要件:

- シミュレーションで検証するには、このブランチでパイプラインを作成する[権限](../../user/permissions.md#project-members-permissions)が必要です。

パイプラインをシミュレートするには:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **ビルド** > **パイプラインエディタ**を選択します。
1. **検証**タブを選択します。
1. **Lint CI/CDサンプル**を選択します。
1. チェックするCI/CD設定のコピーをテキストボックスに貼り付けます。
1. **Simulate pipeline creation for the default branch**（デフォルトブランチのパイプライン作成をシミュレートする）を選択します。
1. **検証**を選択します。
