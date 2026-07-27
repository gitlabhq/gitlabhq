---
stage: AI-powered
group: Editor Extensions
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: GitLab Language Server에 대해 알아봅니다.
title: GitLab Language Server
---

[GitLab Language Server](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp)는 IDE 전체에서 다양한 GitLab 편집기 확장을 지원합니다.

## Language Server를 프록시 사용하도록 구성 {#configure-the-language-server-to-use-a-proxy}

`gitlab-lsp` 자식 프로세스는 [`proxy-from-env`](https://www.npmjs.com/package/proxy-from-env?activeTab=readme) NPM 모듈을 사용하여 다음 환경 변수에서 프록시 설정을 결정합니다:

- `NO_PROXY`
- `HTTPS_PROXY`
- `http_proxy`(소문자)

Language Server를 프록시 사용하도록 구성하려면:

{{< tabs >}}

{{< tab title="Visual Studio Code" >}}

1. Visual Studio Code에서 [사용자 또는 워크스페이스 설정](https://code.visualstudio.com/docs/getstarted/settings)을 엽니다.
1. [`http.proxy`](https://code.visualstudio.com/docs/setup/network#_legacy-proxy-server-support)를 HTTP 프록시로 지정하도록 구성합니다.
1. Visual Studio Code를 다시 시작하여 GitLab으로의 연결이 최신 프록시 설정을 사용하도록 합니다.

{{< /tab >}}

{{< tab title="JetBrains IDE" >}}

1. JetBrains IDE에서 [HTTP Proxy](https://www.jetbrains.com/help/idea/settings-http-proxy.html) 설정을 구성합니다.
1. IDE를 다시 시작하여 GitLab으로의 연결이 최신 프록시 설정을 사용하도록 합니다.
1. **도구** > **GitLab Duo** 메뉴에서 **Verify setup**을 선택합니다. 상태 확인이 통과하는지 확인합니다.

{{< /tab >}}

{{< /tabs >}}

## 문제 해결 {#troubleshooting}

### 편집기 확장 업데이트 {#update-your-editor-extension}

Language Server는 GitLab의 각 편집기 확장과 함께 번들로 제공됩니다. 최신 기능과 버그 수정을 사용할 수 있도록 하려면 확장의 최신 버전으로 업데이트합니다:

- 업데이트 지침 [Eclipse용](../eclipse/_index.md#update-the-plugin)
- 업데이트 지침 [JetBrains IDE용](../jetbrains_ide/_index.md#update-the-extension)
- 업데이트 지침 [Neovim용](../neovim/_index.md#update-the-extension)
- 업데이트 지침 [Visual Studio용](../visual_studio/_index.md#update-the-extension)
- 업데이트 지침 [Visual Studio Code용](../visual_studio_code/_index.md#update-the-extension)

### 프록시 인증 활성화 {#enable-proxy-authentication}

인증된 프록시를 사용할 때 `407 Access Denied (authentication_failed)` 오류가 발생할 수 있습니다:

```plaintext
Request failed: Can't add GitLab account for https://gitlab.com. Check your instance URL and network connection.
Fetching resource from https://gitlab.com/api/v4/personal_access_tokens/self failed
```

Language Server에서 프록시 인증을 활성화하려면 IDE에 따른 단계를 따릅니다:

{{< tabs >}}

{{< tab title="Visual Studio Code" >}}

1. Visual Studio Code에서 [사용자 또는 워크스페이스 설정](https://code.visualstudio.com/docs/getstarted/settings)을 엽니다.
1. 사용자 이름과 암호를 포함하여 [`http.proxy`](https://code.visualstudio.com/docs/setup/network#_legacy-proxy-server-support)를 구성하여 HTTP 프록시로 인증합니다.
1. Visual Studio Code를 다시 시작하여 GitLab으로의 연결이 최신 프록시 설정을 사용하도록 합니다.

> [!note]
> VS Code 확장은 VS Code의 [`http.proxyAuthorization`](https://code.visualstudio.com/docs/setup/network#_legacy-proxy-server-support) 레거시 설정을 지원하지 않으며 HTTP 프록시로 Language Server를 인증합니다. 지원은 [이슈 1672](https://gitlab.com/gitlab-org/gitlab-vscode-extension/-/issues/1672)에서 제안됩니다.

{{< /tab >}}

{{< tab title="JetBrains IDE" >}}

1. JetBrains IDE에서 [HTTP Proxy](https://www.jetbrains.com/help/idea/settings-http-proxy.html) 설정을 구성합니다.
   1. **Manual proxy configuration**을 사용하는 경우 **Proxy authentication**에 자격 증명을 입력하고 **Remember**를 선택합니다.
1. JetBrains IDE를 다시 시작하여 GitLab으로의 연결이 최신 프록시 설정을 사용하도록 합니다.
1. **도구** > **GitLab Duo** 메뉴에서 **Verify setup**을 선택합니다. 상태 확인이 통과하는지 확인합니다.

{{< /tab >}}

{{< /tabs >}}

> [!note]
> Bearer 인증은 [이슈 548](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/issues/548)에서 제안됩니다.

## 관련 항목 {#related-topics}

- [GitLab Language Server 릴리스](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/releases)
