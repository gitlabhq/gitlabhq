---
stage: Application Security Testing
group: Dynamic Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "브라우저와 도구를 사용하여 HAR 파일을 생성하고 웹 API 퍼징 테스트를 위해 HTTP 트래픽을 캡처하며, 민감한 데이터를 검토하는 방법을 알아봅니다."
title: HAR 파일 생성
---

{{< details >}}

- 티어:  Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

HTTP 아카이브(HAR) 형식 파일은 HTTP 요청 및 HTTP 응답에 대한 정보를 교환하기 위한 업계 표준입니다. HAR 파일의 콘텐츠는 JSON 형식이며, 웹 사이트와의 브라우저 상호 작용을 포함합니다. 파일 확장자 `.har`는 일반적으로 사용됩니다.

HAR 파일은 [웹 API 퍼징 테스트](configuration/enabling_the_analyzer.md#http-archive-har)를 수행하기 위해 CI/CD 파이프라인에서 사용할 수 있습니다.

> [!warning]
> HAR 파일은 웹 클라이언트와 웹 서버 간에 교환되는 정보를 저장합니다. 인증 토큰, API 키 및 세션 쿠키와 같은 민감한 정보도 저장될 수 있습니다. 리포지토리에 추가하기 전에 HAR 파일 콘텐츠를 검토하시기 바랍니다.

## HAR 파일 생성 {#har-file-creation}

HAR 파일을 수동으로 생성하거나 웹 세션을 기록하기 위해 특화된 도구를 사용하여 생성할 수 있습니다. 특화된 도구를 사용하시기 바랍니다. 다만 이러한 도구로 생성된 파일이 민감한 정보를 노출하지 않으며 안전하게 사용할 수 있는지 확인하는 것이 중요합니다.

다음 도구를 사용하여 네트워크 활동을 기반으로 HAR 파일을 생성할 수 있습니다. 이 도구들은 네트워크 활동을 자동으로 기록하고 HAR 파일을 생성합니다:

- GitLab HAR 레코더
- Insomnia API 클라이언트
- Fiddler 디버깅 프록시
- Safari 웹 브라우저
- Chrome 웹 브라우저
- Firefox 웹 브라우저

> [!warning]
> HAR 파일에는 인증 토큰, API 키 및 세션 쿠키와 같은 민감한 정보가 포함될 수 있습니다. 리포지토리에 추가하기 전에 HAR 파일 콘텐츠를 검토해야 합니다.

### GitLab HAR 레코더 {#gitlab-har-recorder}

[GitLab HAR Recorder](https://gitlab.com/gitlab-org/security-products/har-recorder)는 HTTP 메시지를 기록하고 HAR 파일에 저장하는 명령줄 도구입니다.

#### GitLab HAR 레코더 설치 {#install-gitlab-har-recorder}

전제 조건:

- Python 3.6 이상을 설치합니다.
- Microsoft Windows의 경우 `Microsoft Visual C++ 14.0`도 설치해야 합니다. [Visual Studio Downloads page](https://visualstudio.microsoft.com/downloads/)의 Visual Studio용 Build Tools에 포함되어 있습니다.
- HAR Recorder를 설치합니다.

GitLab HAR 레코더를 설치합니다:

  ```shell
  pip install gitlab-har-recorder --extra-index-url https://gitlab.com/api/v4/projects/22441624/packages/pypi/simple
  ```

#### GitLab HAR 레코더로 HAR 파일 생성 {#create-a-har-file-with-gitlab-har-recorder}

1. 프록시 포트 및 HAR 파일명으로 레코더를 시작합니다.
1. 프록시를 사용하여 브라우저 작업을 완료합니다.
   1. 프록시가 사용되었는지 확인하세요!
1. 레코더를 중지합니다.

### Insomnia API 클라이언트 {#insomnia-api-client}

[Insomnia API 클라이언트](https://insomnia.rest/)는 다양한 용도로 API를 설계, 설명 및 테스트할 수 있는 API 설계 도구입니다. CI/CD 파이프라인에서 [웹 API 퍼징 테스트](configuration/enabling_the_analyzer.md#http-archive-har)에 사용할 수 있는 HAR 파일을 생성할 수도 있습니다.

#### Insomnia API 클라이언트로 HAR 파일 생성 {#create-a-har-file-with-the-insomnia-api-client}

1. API를 정의하거나 가져옵니다.
   - Postman v2
   - Curl.
   - OpenAPI v2, v3.
1. 각 API 호출이 작동하는지 확인합니다.
   - OpenAPI 사양을 가져온 경우 진행하면서 작동 데이터를 추가합니다.
1. **API** > **Import/Export**를 선택합니다.
1. **Export Data** > **Current Workspace**를 선택합니다.
1. HAR 파일에 포함할 요청을 선택합니다.
1. **내보내기**를 선택합니다.
1. **Select Export Type** 드롭다운 목록에서 **HAR -- HTTP Archive Format**을 선택합니다.
1. **완료**을 선택합니다.
1. HAR 파일의 위치 및 파일명을 입력합니다.

### Fiddler 디버깅 프록시 {#fiddler-debugging-proxy}

[Fiddler](https://www.telerik.com/fiddler)는 웹 디버거 도구입니다. HTTP 및 HTTP(S) 네트워크 트래픽을 캡처하고 각 요청을 검사할 수 있습니다. 요청과 응답을 HAR 형식으로 내보낼 수 있습니다.

#### Fiddler로 HAR 파일 생성 {#create-a-har-file-with-fiddler}

1. [Fiddler home page](https://www.telerik.com/fiddler)로 이동하여 로그인합니다. 아직 계정이 없으면 계정을 생성합니다.
1. API를 호출하는 페이지를 봅니다. Fiddler가 자동으로 요청을 캡처합니다.
1. 하나 이상의 요청을 선택한 후 컨텍스트 메뉴에서 **내보내기** > **Selected Sessions**를 선택합니다.
1. **Choose Format** 드롭다운 목록에서 **HTTPArchive v1.2**를 선택합니다.
1. 파일명을 입력하고 **저장**를 선택합니다.

Fiddler는 내보내기가 성공했음을 확인하는 팝업 메시지를 표시합니다.

### Safari 웹 브라우저 {#safari-web-browser}

[Safari](https://www.apple.com/safari/)는 Apple에서 유지 관리하는 웹 브라우저입니다. 웹 개발이 진화함에 따라 브라우저는 새로운 기능을 지원합니다. Safari를 사용하면 네트워크 트래픽을 탐색하고 HAR 파일로 내보낼 수 있습니다.

#### Safari로 HAR 파일 생성 {#create-a-har-file-with-safari}

전제 조건:

- `Develop` 메뉴 항목을 활성화합니다.
  1. Safari의 환경설정을 엽니다. <kbd>Command</kbd>+<kbd>,</kbd>를 누르거나 메뉴에서 **Safari** > **환경설정**를 선택합니다.
  1. **고급** 탭을 선택한 후 `Show Develop menu item in menu bar`를 선택합니다.
  1. **환경설정** 창을 닫습니다.

1. **Web Inspector**를 엽니다. <kbd>Option</kbd>+<kbd>Command</kbd>+<kbd>i</kbd>를 누르거나 메뉴에서 **Develop** > **Show Web Inspector**를 선택합니다.
1. **네트워크** 탭을 선택하고 **Preserve Log**를 선택합니다.
1. API를 호출하는 페이지를 봅니다.
1. **Web Inspector**를 열고 **네트워크** 탭을 선택합니다
1. 내보낼 요청을 마우스 오른쪽 단추로 클릭하고 **Export HAR**를 선택합니다.
1. 파일명을 입력하고 **저장**를 선택합니다.

### Chrome 웹 브라우저 {#chrome-web-browser}

[Chrome](https://www.google.com/chrome/)은 Google에서 유지 관리하는 웹 브라우저입니다. 웹 개발이 진화함에 따라 브라우저는 새로운 기능을 지원합니다. Chrome을 사용하면 네트워크 트래픽을 탐색하고 HAR 파일로 내보낼 수 있습니다.

#### Chrome으로 HAR 파일 생성 {#create-a-har-file-with-chrome}

1. Chrome 컨텍스트 메뉴에서 **Inspect**를 선택합니다.
1. **네트워크** 탭을 선택합니다.
1. **Preserve log**를 선택합니다.
1. API를 호출하는 페이지를 봅니다.
1. 하나 이상의 요청을 선택합니다.
1. 마우스 오른쪽 단추를 클릭하고 **Save all as HAR with content**를 선택합니다.
1. 파일명을 입력하고 **저장**를 선택합니다.
1. 추가 요청을 추가하려면 요청을 선택하여 같은 파일에 저장합니다.

### Firefox 웹 브라우저 {#firefox-web-browser}

[Firefox](https://www.mozilla.org/en-US/firefox/new/)는 Mozilla에서 유지 관리하는 웹 브라우저입니다. 웹 개발이 진화함에 따라 브라우저는 새로운 기능을 지원합니다. Firefox를 사용하면 네트워크 트래픽을 탐색하고 HAR 파일로 내보낼 수 있습니다.

#### Firefox로 HAR 파일 생성 {#create-a-har-file-with-firefox}

1. Firefox 컨텍스트 메뉴에서 **Inspect**를 선택합니다.
1. **네트워크** 탭을 선택합니다.
1. API를 호출하는 페이지를 봅니다.
1. **네트워크** 탭을 확인하고 요청이 기록되고 있는지 확인합니다. `Perform a request or Reload the page to see detailed information about network activity` 메시지가 있으면 **새로고침**를 선택하여 요청 기록을 시작합니다.
1. 하나 이상의 요청을 선택합니다.
1. 마우스 오른쪽 단추를 클릭하고 **Save All As HAR**를 선택합니다.
1. 파일명을 입력하고 **저장**를 선택합니다.
1. 추가 요청을 추가하려면 요청을 선택하여 같은 파일에 저장합니다.

## HAR 검증 {#har-verification}

HAR 파일을 사용하기 전에 민감한 정보를 노출하지 않도록 하는 것이 중요합니다.

각 HAR 파일에 대해 다음을 수행해야 합니다:

- HAR 파일의 콘텐츠 보기
- 민감한 정보에 대해 HAR 파일 검토
- 민감한 정보 편집 또는 제거

### HAR 파일 콘텐츠 보기 {#view-har-file-contents}

구조화된 방식으로 콘텐츠를 표시할 수 있는 도구에서 HAR 파일의 콘텐츠를 보시기 바랍니다. 여러 HAR 파일 뷰어를 온라인에서 사용할 수 있습니다. HAR 파일을 업로드하지 않으려면 컴퓨터에 설치된 도구를 사용할 수 있습니다. HAR 파일은 JSON 형식을 사용하므로 텍스트 편집기에서도 볼 수 있습니다.

HAR 파일을 보기 위해 권장되는 도구는 다음과 같습니다:

- [HAR Viewer](http://www.softwareishard.com/har/viewer/) \- (온라인)
- [Google Admin Toolbox HAR Analyzer](https://toolbox.googleapps.com/apps/har_analyzer/) \- (온라인)
- [Fiddler](https://www.telerik.com/fiddler) \- 로컬
- [Insomnia API 클라이언트](https://insomnia.rest/) \- 로컬

## HAR 파일 콘텐츠 검토 {#review-har-file-content}

다음 항목 중 하나에 대해 HAR 파일을 검토합니다:

- 응용 프로그램에 대한 액세스를 부여하는 데 도움이 될 수 있는 정보(예: 인증 토큰, 인증 토큰, 쿠키, API 키).
- [개인 식별 정보(PII)](https://en.wikipedia.org/wiki/Personal_data).

민감한 정보를 [편집하거나 제거](#edit-or-remove-sensitive-information)할 것을 강력히 권장합니다.

다음을 체크리스트로 사용합니다. 완전한 목록은 아닙니다.

- 비밀을 찾습니다. 예를 들어 응용 프로그램에 인증이 필요한 경우 인증 정보의 공통 위치를 확인합니다:
  - 인증 관련 헤더 예: 쿠키, 인증. 이 헤더에는 유효한 정보가 포함될 수 있습니다.
  - 인증 관련 요청 이러한 요청의 본문에는 사용자 자격 증명이나 토큰 같은 정보가 포함될 수 있습니다.
  - 세션 토큰. 세션 토큰이 응용 프로그램에 액세스할 수 있습니다. 이 토큰의 위치가 달라질 수 있습니다. 헤더, 쿼리 매개변수 또는 본문에 있을 수 있습니다.
- 개인 식별 정보 찾기
  - 예를 들어 응용 프로그램이 사용자 목록과 해당 개인 데이터(전화, 이름, 이메일)를 검색하는 경우.
  - 인증 정보에도 개인 정보가 포함될 수 있습니다.

## 민감한 정보 편집 또는 제거 {#edit-or-remove-sensitive-information}

[HAR 파일 콘텐츠 검토](#review-har-file-content) 중에 발견된 민감한 정보를 편집하거나 제거합니다. HAR 파일은 JSON 파일이므로 모든 텍스트 편집기에서 편집할 수 있습니다.

HAR 파일을 편집한 후 HAR 파일 뷰어에서 열어 형식 및 구조가 그대로 유지되는지 확인합니다.
