---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
gitlab_dedicated: yes
description: すべてのプロジェクトで使用できるファイルテンプレートのコレクションを設定します。
title: インスタンステンプレートリポジトリ
---

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

ホスト型システムでは、企業は多くの場合、チーム間で独自のテンプレートを共有する必要があります。この機能を使用すると、管理者は、インスタンス全体のファイルテンプレートのコレクションとなるプロジェクトを選択できます。これらのテンプレートは、プロジェクトのセキュリティが維持されたまま、[Webエディタ](../../user/project/repository/web_editor.md)を介してすべてのユーザーに公開されます。

## 設定 {#configuration}

カスタムテンプレートリポジトリとして機能するプロジェクトを選択するには:

1. 左側のサイドバーの下部で、**管理者**を選択します。
1. 左側のサイドバーの下部にある**設定** > **テンプレート**を選択します。
1. **テンプレート**を展開します。
1. ドロップダウンリストから、テンプレートリポジトリとして使用するプロジェクトを選択します。
1. **変更を保存**を選択します。
1. 選択したリポジトリにカスタムテンプレートを追加します。

テンプレートを追加すると、インスタンス全体で使用できます。これらは、[Webエディタ](../../user/project/repository/web_editor.md)および[API設定](../../api/settings.md)で使用できます。

これらのテンプレートは、`.gitlab-ci.yml`の[`include:template`](../../ci/yaml/_index.md#includetemplate)キーの値として使用できません。

## サポートされているファイルの種類と場所 {#supported-file-types-and-locations}

GitLabは、イシュー、マージリクエストテンプレート、およびその他のファイルタイプのテンプレートにMarkdownファイルをサポートしています。

次のMarkdownの説明テンプレートがサポートされています:

| 型               | ディレクトリ                         | 拡張子         |
| :---------------:  | :-----------:                     | :-----------:     |
| イシュー              | `.gitlab/issue_templates`         | `.md`             |
| マージリクエスト      | `.gitlab/merge_request_templates` | `.md`             |

詳細については、[説明テンプレート](../../user/project/description_templates.md)を参照してください。

その他のサポートされているファイルタイプのテンプレートには、以下が含まれます:

| 型                    | ディレクトリ            | 拡張子     |
| :---------------:       | :-----------:        | :-----------: |
| `Dockerfile`            | `Dockerfile`         | `.dockerfile` |
| `.gitignore`            | `gitignore`          | `.gitignore`  |
| `.gitlab-ci.yml`        | `gitlab-ci`          | `.yml`        |
| `LICENSE`               | `LICENSE`            | `.txt`        |

各テンプレートは、それぞれのサブディレクトリにあり、正しい拡張子を持ち、空であってはなりません。階層は次のようになります:

```plaintext
|-- README.md
    |-- issue_templates
        |-- feature_request.md
    |-- merge_request_templates
        |-- default.md
|-- Dockerfile
    |-- custom_dockerfile.dockerfile
    |-- another_dockerfile.dockerfile
|-- gitignore
    |-- custom_gitignore.gitignore
    |-- another_gitignore.gitignore
|-- gitlab-ci
    |-- custom_gitlab-ci.yml
    |-- another_gitlab-ci.yml
|-- LICENSE
    |-- custom_license.txt
    |-- another_license.txt
```

新しいファイルがGitLab UIを介して追加されると、カスタムテンプレートがドロップダウンリストに表示されます:

![新しいファイルを作成するためのGitLab UI。選択できるDockerfileテンプレートを表示するドロップダウンリストがあります。](img/file_template_user_dropdown_v17_10.png)

この機能が無効になっている場合、またはテンプレートが存在しない場合、選択ドロップダウンリストに**カスタム**セクションは表示されません。
