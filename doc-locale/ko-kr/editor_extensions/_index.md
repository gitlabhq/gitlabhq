---
stage: AI-powered
group: Editor Extensions
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "GitLab의 기능을 Visual Studio Code, JetBrains IDE, Visual Studio, Eclipse 및 Neovim으로 확장합니다."
title: 에디터 확장
---

GitLab 에디터 확장은 GitLab과 GitLab Duo의 강력한 기능을 선호하는 개발 환경으로 직접 가져옵니다. GitLab 기능과 GitLab Duo AI 기능을 사용하여 에디터를 떠나지 않고 일상적인 작업을 처리합니다. 예를 들어:

- 프로젝트를 관리합니다.
- 코드를 작성하고 검토합니다.
- 이슈를 추적합니다.
- 파이프라인을 최적화합니다.

저희 확장은 코딩 환경과 GitLab 사이의 간격을 좁혀 생산성을 높이고 개발 프로세스를 개선합니다.

## 사용 가능한 확장 {#available-extensions}

GitLab은 GitLab Duo 및 프로젝트와 애플리케이션을 관리하는 데 사용되는 다른 GitLab 기능에 액세스할 수 있는 다음 IDE 확장을 제공합니다.

| 확장                                                       | GitLab Duo Chat      | Code Suggestions | Software Development<br> 플로우 | 에이전트      | 기타<br> GitLab 기능 |
|-----------------------------------------------------------------|----------------------|------------------|------------------------------|-------------|--------------------------|
| [GitLab for VS Code](visual_studio_code/_index.md)              | {{< yes >}}          | {{< yes >}}      | {{< yes >}}                  | {{< yes >}} | {{< yes >}}              |
| [JetBrains IDE용 GitLab Duo 플러그인](jetbrains_ide/_index.md) | {{< yes >}}          | {{< yes >}}      | {{< yes >}}                  | {{< yes >}} | {{< no >}}               |
| [GitLab for Visual Studio](visual_studio/_index.md)   | {{< yes >}}          | {{< yes >}}      | {{< yes >}}                  | {{< no >}}  | {{< no >}}               |
| [GitLab for Eclipse plugin](eclipse/_index.md)                  | {{< yes >}}(비에이전트) | {{< yes >}}      | {{< no >}}                   | {{< no >}}  | {{< no >}}               |

명령줄 인터페이스를 선호하면 다음을 시도하세요:

| 확장                                                       | GitLab Duo Chat      | Code Suggestions | Software Development<br> 플로우 | 에이전트      | 기타<br> GitLab 기능 |
|-----------------------------------------------------------------|----------------------|------------------|------------------------------|-------------|--------------------------|
| [GitLab CLI(`glab`)](gitlab_cli/_index.md)                | {{< yes >}} | {{< no >}}                  | {{< no >}}                | {{< no >}} | {{< yes >}}           |
| [GitLab Duo CLI(`duo`)](../user/gitlab_duo_cli/_index.md) | {{< yes >}}<br>(에이전트) | {{< no >}}                  | {{< no >}}                | {{< no >}} | {{< no >}}            |
| [GitLab.nvim for Neovim](neovim/_index.md)                     | {{< no >}}            | {{< yes >}}                 | {{< no >}}                | {{< no >}} | {{< no >}}            |

## 보안 고려사항 {#security-considerations}

에디터 확장에서 로컬로 에이전트를 실행할 때의 보안 위험과 로컬 개발 환경을 보호하는 방법을 알아보려면 [에디터 확장 보안 고려 사항](security_considerations.md)을 참조하세요.

## 에디터 확장 팀 런북 {#editor-extensions-team-runbook}

[에디터 확장 팀 런북](https://gitlab.com/gitlab-com/runbooks/-/tree/master/docs/editor-extensions)을 사용하여 지원되는 모든 에디터 확장의 디버깅에 대해 자세히 알아보세요. 내부 사용자의 경우 이 런북에는 내부 도움말을 요청하기 위한 지침이 포함되어 있습니다.

## 피드백 및 기여 {#feedback-and-contributions}

저희는 기존 기능과 AI 네이티브 기능 모두에 대한 의견을 소중히 여깁니다. 제안이 있거나 문제가 발생했거나 저희 확장 개발에 기여하고 싶다면:

- 해당 GitLab 프로젝트에서 이슈를 보고합니다.
- [`editor-extensions` 프로젝트](https://gitlab.com/gitlab-org/editor-extensions/product/-/issues/)에서 새 이슈를 생성하여 기능 요청을 제출합니다.
- 각 GitLab 프로젝트에 머지 리퀘스트를 제출합니다.

## 관련 항목 {#related-topics}

- [GitLab Duo Agent Platform](../user/duo_agent_platform/_index.md)
- [GitLab Duo (non-agentic)](../user/gitlab_duo/feature_summary.md)
- [VS Code용 확장을 만드는 방법](https://about.gitlab.com/blog/use-gitlab-with-vscode/)
- [GitLab for Visual Studio](https://about.gitlab.com/blog/gitlab-visual-studio-extension/)
- [JetBrains 및 Neovim용 GitLab](https://about.gitlab.com/blog/gitlab-jetbrains-neovim-plugins/)
- [`glab`를 GitLab CLI로 간편하게 사용하기](https://about.gitlab.com/blog/introducing-the-gitlab-cli/)
