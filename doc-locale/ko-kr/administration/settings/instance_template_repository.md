---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
gitlab_dedicated: yes
description: 모든 프로젝트에 사용할 수 있는 파일 템플릿 모음을 구성합니다.
title: 인스턴스 템플릿 리포지토리
---

{{< details >}}

- 티어:  Premium, Ultimate
- 제공 서비스: GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

호스팅 시스템에서는 기업이 팀 전체에서 자신의 템플릿을 공유해야 할 필요가 있습니다. 이 기능을 통해 관리자는 프로젝트를 인스턴스 전체 파일 템플릿 모음으로 선택할 수 있습니다. 이 템플릿은 [Web Editor](../../user/project/repository/web_editor.md)를 통해 모든 사용자에게 노출되며 프로젝트는 안전하게 유지됩니다.

## 구성 {#configuration}

프로젝트를 커스텀 템플릿 리포지토리로 사용하도록 선택하려면:

1. 오른쪽 위 모서리에서 **Admin**을 선택합니다.
1. 왼쪽 사이드바에서 **설정** > **텝플릿**을 선택합니다.
1. **텝플릿**을 확장합니다
1. 드롭다운 목록에서 템플릿 리포지토리로 사용할 프로젝트를 선택합니다.
1. **변경 사항 저장**을 선택합니다.
1. 선택한 리포지토리에 커스텀 템플릿을 추가합니다.

템플릿을 추가한 후 전체 인스턴스에 사용할 수 있습니다. [Web Editor](../../user/project/repository/web_editor.md) 및 [API 설정](../../api/settings.md)을 통해 사용할 수 있습니다.

이 템플릿은 [`include:template`](../../ci/yaml/_index.md#includetemplate) 키의 값으로 `.gitlab-ci.yml`에서 사용할 수 없습니다.

## 지원되는 파일 유형 및 위치 {#supported-file-types-and-locations}

GitLab은 이슈 및 머지 리퀘스트 템플릿과 기타 파일 유형 템플릿용 Markdown 파일을 지원합니다.

지원되는 Markdown 설명 템플릿은 다음과 같습니다:

| 유형               | 디렉터리                         | 확장자         |
| :---------------:  | :-----------:                     | :-----------:     |
| 이슈              | `.gitlab/issue_templates`         | `.md`             |
| 머지 리퀘스트      | `.gitlab/merge_request_templates` | `.md`             |

자세한 내용은 [설명 템플릿](../../user/project/description_templates.md)을 참고하세요.

지원되는 기타 파일 유형 템플릿은 다음과 같습니다:

| 유형                    | 디렉터리            | 확장자     |
| :---------------:       | :-----------:        | :-----------: |
| `Dockerfile`            | `Dockerfile`         | `.dockerfile` |
| `.gitignore`            | `gitignore`          | `.gitignore`  |
| `.gitlab-ci.yml`        | `gitlab-ci`          | `.yml`        |
| `LICENSE`               | `LICENSE`            | `.txt`        |

각 템플릿은 해당 하위 디렉터리에 있어야 하며 올바른 확장자를 가져야 하고 비어 있지 않아야 합니다. 계층 구조는 다음과 같이 표시되어야 합니다:

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

GitLab UI를 통해 새 파일을 추가할 때 커스텀 템플릿이 드롭다운 목록에 표시됩니다:

![선택할 수 있는 Dockerfile 템플릿을 표시하는 드롭다운 목록이 있는 새 파일을 만들기 위한 GitLab UI입니다.](img/file_template_user_dropdown_v17_10.png)

이 기능이 비활성화되었거나 템플릿이 없으면 선택 드롭다운 목록에 **커스텀** 섹션이 표시되지 않습니다.
