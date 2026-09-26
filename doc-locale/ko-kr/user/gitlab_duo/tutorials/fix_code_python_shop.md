---
stage: Tutorials
group: Tutorials
description: GitLab Duo를 사용하여 Python에서 쇼핑 애플리케이션을 만드는 방법에 관한 튜토리얼입니다.
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: '튜토리얼: GitLab Duo를 사용하여 Python에서 쇼핑 애플리케이션 만들기'
---

<!-- vale gitlab_base.FutureTense = NO -->

온라인 서점의 개발자로 입사했습니다. 현재 재고 관리 시스템은 스프레드시트와 수동 프로세스가 혼합되어 있어 재고 오류 및 업데이트 지연이 발생합니다. 팀에서 다음을 수행할 수 있는 웹 애플리케이션을 만들어야 합니다:

- 실시간으로 도서 재고를 추적합니다.
- 직원이 도착하는 새 책을 추가할 수 있습니다.
- 음수 가격이나 수량 같은 일반적인 데이터 항목 오류를 방지합니다.
- 향후 고객 대면 기능의 기초를 제공합니다.

이 튜토리얼은 시리즈의 첫 번째 부분이며, [Python](https://www.python.org/) 웹 애플리케이션을 만들고 디버깅하면서 이러한 요구사항을 충족하는 데이터베이스 백엔드를 사용하는 과정을 안내합니다.

[GitLab Duo Agentic Chat](../../gitlab_duo_chat/agentic_chat.md)과 [GitLab Duo Code Suggestions](../../duo_agent_platform/code_suggestions/_index.md)을 사용하여 다음을 수행할 수 있습니다:

- 표준 디렉토리 및 필수 파일로 정렬된 Python 프로젝트를 설정합니다.
- Python 가상 환경을 구성합니다.
- [Flask](https://flask.palletsprojects.com/en/stable/) 프레임워크를 웹 애플리케이션의 기초로 설치합니다.
- 필수 종속성을 설치하고 개발을 위해 프로젝트를 준비합니다.
- Flask 애플리케이션 개발을 위해 Python 구성 파일 및 환경 변수를 설정합니다.
- 기사 모델, 데이터베이스 작업, API 경로 및 재고 관리 기능을 포함한 핵심 기능을 구현합니다.
- 애플리케이션이 의도한 대로 작동하는지 테스트하고 코드를 예제 코드 파일과 비교합니다.

## 시작하기 전에 {#before-you-begin}

- 시스템에 [최신 버전의 Python을 설치](https://www.python.org/downloads/)합니다. Chat에 운영 체제에 대해 어떻게 수행하는지 물어볼 수 있습니다.
- GitLab Duo에 액세스할 수 있는지 관리자, 그룹 소유자 또는 프로젝트 소유자에게 확인합니다.
- 선호하는 IDE에 확장을 설치합니다:
  - [웹 IDE](../../project/web_ide/_index.md): GitLab 인스턴스를 통해 액세스
  - [VS Code](../../../editor_extensions/visual_studio_code/setup.md)
  - [Visual Studio](../../../editor_extensions/visual_studio/setup.md)
  - [JetBrains IDE](../../../editor_extensions/jetbrains_ide/_index.md)
  - [Neovim](../../../editor_extensions/neovim/setup.md)
- IDE에서 [OAuth](../../../integration/google.md) 또는 [`api` 범위를 가진 개인 액세스 토큰](../../profile/personal_access_tokens.md#create-a-personal-access-token)을 사용하여 GitLab으로 인증합니다.

## GitLab Duo Chat 및 Code Suggestions 사용 {#use-gitlab-duo-chat-and-code-suggestions}

이 튜토리얼에서는 Chat과 Code Suggestions을 사용하여 Python 웹 애플리케이션을 만듭니다. 이러한 기능을 사용하는 방법은 여러 가지입니다.

### GitLab Duo Chat 사용 {#use-gitlab-duo-chat}

구독 추가 기능에 따라 GitLab UI, 웹 IDE 또는 IDE에서 Chat을 사용할 수 있습니다.

#### GitLab UI에서 Chat 사용 {#use-chat-in-the-gitlab-ui}

1. 상단 바에서 **검색 또는 이동**을 선택하고 프로젝트를 찾습니다.
1. GitLab Duo 사이드바에서 **새 채팅 추가**({{< icon name="pencil-square" >}})를 선택합니다.
1. 드롭다운 목록에서 에이전트를 선택합니다.

   화면 오른쪽의 GitLab Duo 사이드바에서 Chat 대화창이 열립니다.
1. 채팅 텍스트 상자에 질문을 입력하고 <kbd>Enter</kbd> 키를 누르거나 **보내기**를 선택합니다. 대화형 AI 채팅이 답변을 생성하는 데 몇 초가 걸릴 수 있습니다.

#### 웹 IDE에서 Chat 사용 {#use-chat-in-the-web-ide}

1. 웹 IDE를 엽니다:
   1. GitLab UI의 상단 표시줄에서 **검색 또는 이동**을 선택하고 프로젝트를 찾습니다.
   1. 파일을 선택합니다. 그런 다음 오른쪽 위에서 **편집** > **웹 IDE에서 열기**를 선택합니다.
1. 다음 방법 중 하나를 사용하여 Chat을 엽니다:
   - 왼쪽 사이드바에서 **GitLab Duo Chat**을 선택합니다.
   - 편집기에서 열려 있는 파일에서 일부 코드를 선택합니다.
     1. 마우스 오른쪽 버튼을 클릭하고 **GitLab Duo Chat**을 선택합니다.
     1. **선택된 코드 설명**, **테스트 생성** 또는 **리팩터**를 선택합니다.
   - 키보드 단축키를 사용합니다: <kbd>ALT</kbd>+<kbd>d</kbd> (Windows 및 Linux) 또는 <kbd>Option</kbd>+<kbd>d</kbd> (Mac).
1. 메시지 상자에 질문을 입력합니다. **Enter**를 누르거나 **전송**을 선택합니다.

#### IDE에서 Chat 사용 {#use-chat-in-your-ide}

IDE에서 Chat을 사용하는 방식은 사용하는 IDE에 따라 다릅니다.

{{< tabs >}}

{{< tab title="VS Code" >}}

1. VS Code에서 파일을 엽니다. 파일이 Git 리포지토리의 파일일 필요는 없습니다.
1. 왼쪽 사이드바에서 **GitLab Duo Chat** ({{< icon name="duo-chat" >}})을 선택합니다.
1. 메시지 상자에 질문을 입력합니다. **Enter**를 누르거나 **전송**을 선택합니다.
1. 채팅 창의 오른쪽 위 모서리에서 **상태 표시**를 선택하여 명령 팔레트에 정보를 표시합니다.

코드의 일부분으로 작업하는 동안 GitLab Duo Chat과 상호 작용할 수도 있습니다.

1. VS Code에서 파일을 엽니다. 파일이 Git 리포지토리의 파일일 필요는 없습니다.
1. 파일에서 일부 코드를 선택합니다.
1. 마우스 오른쪽 버튼을 클릭하고 **GitLab Duo Chat**을 선택합니다.
1. 옵션을 선택하거나 **빠른 Chat 열기**를 선택하고 `Can you simplify this code?` 같은 질문을 한 후 <kbd>Enter</kbd>를 누릅니다.

자세한 내용은 [VS Code에서 GitLab Duo Chat 사용](../../gitlab_duo_chat/agentic_chat.md#use-gitlab-duo-chat-in-vs-code)을 참조하세요.

{{< /tab >}}

{{< tab title="JetBrains IDE" >}}

1. [PyCharm](https://www.jetbrains.com/pycharm/) 또는 [IntelliJ IDEA](https://www.jetbrains.com/idea/) 같이 Python을 지원하는 JetBrains IDE에서 프로젝트를 엽니다.
1. [GitLab Duo Chat 사용](../../gitlab_duo_chat/agentic_chat.md#use-gitlab-duo-chat-in-jetbrains-ides).

{{< /tab >}}

{{< /tabs >}}

### Code Suggestions 사용 {#use-code-suggestions}

Code Suggestions을 사용하려면:

1. [지원되는 IDE](../../project/repository/code_suggestions/supported_extensions.md#supported-editor-extensions)에서 Git 프로젝트를 엽니다.

   로컬 프로젝트는 GitLab의 리포지토리를 가리키는 Git 원격 구성이 있어야 합니다. 없으면 [`git remote add`](../../../topics/git/commands.md#git-remote-add)를 사용하여 프로젝트를 연결합니다.
1. 코드를 작성합니다. 입력할 때 제안이 표시됩니다. Code Suggestions는 커서 위치에 따라 코드 스니펫을 제공하거나 현재 줄을 완성합니다.

1. 자연어로 요구사항을 설명합니다. Code Suggestions는 제공된 컨텍스트를 기반으로 함수와 코드 스니펫을 생성합니다.

1. 제안을 받으면 다음 중 하나를 수행할 수 있습니다:
   - 제안을 수락하려면 <kbd>Tab</kbd> 키를 누릅니다.
   - 부분 제안을 수락하려면 <kbd>Control</kbd>+<kbd>오른쪽 화살표</kbd> 또는 <kbd>Command</kbd>+<kbd>오른쪽 화살표</kbd>를 누릅니다.
   - 제안을 거부하려면 <kbd>Esc</kbd> 키를 누릅니다.
   - 제안을 무시하려면 평소대로 계속 입력합니다.

자세한 내용은 [Code Suggestions](../../duo_agent_platform/code_suggestions/_index.md) 설명서를 참조하세요.

Chat 및 Code Suggestions 사용 방법을 알았으니 웹 애플리케이션을 만들기 시작하겠습니다. 먼저 정렬된 Python 프로젝트 구조를 만듭니다.

## 프로젝트 구조 만들기 {#create-the-project-structure}

먼저 Python 모범 사례를 따르는 정렬된 프로젝트 구조가 필요합니다. 적절한 구조는 코드를 더 유지 관리 가능하고 테스트 가능하게 만들고 다른 개발자가 이해하기 쉽게 합니다.

Chat을 사용하여 Python 프로젝트 조직 규칙을 이해하고 적절한 파일을 생성할 수 있습니다. 이렇게 하면 모범 사례를 연구하는 시간이 절약되고 중요한 구성 요소를 놓치지 않을 수 있습니다.

1. IDE에서 Chat을 열고 다음을 입력합니다:

   ```plaintext
   What is the recommended project structure for a Python web application? Include
   common files, and explain the purpose of each file.
   ```

   이 프롬프트는 파일을 만들기 전에 Python 프로젝트 조직을 이해하는 데 도움이 됩니다.

1. Python 프로젝트에 대한 새 폴더를 만들고 Chat 응답을 기반으로 디렉토리 및 파일 구조를 만듭니다. 다음과 유사할 것입니다:

   ```plaintext
   python-shop-app/
   ├── LICENSE
   ├── README.md
   ├── requirements.txt
   ├── setup.py
   ├── .gitignore
   ├── .env
   ├── app/
   │   ├── __init__.py
   │   ├── models/
   │   │   ├── __init__.py
   │   │   └── article.py
   │   ├── routes/
   │   │   ├── __init__.py
   │   │   └── shop.py
   │   └── database.py
   └── tests/
       ├── __init__.py
       └── test_shop.py
   ```

1. `.gitignore` 파일을 채워야 합니다. Chat에 다음을 입력합니다:

   ```plaintext
   Generate a .gitignore file for a Python project that uses Flask, SQLite, and
   virtual environments. Include common IDE files.
   ```

1. 응답을 `.gitignore` 파일에 복사합니다.
1. `README` 파일의 경우 Chat에 다음을 입력합니다:

   ```plaintext
   Generate a README.md file for a Python web application that manages a bookstore
   inventory. Make sure that it includes all sections for requirements, setup, and usage.
   ```

이제 업계 모범 사례를 따르는 적절히 구조화된 Python 프로젝트를 만들었습니다. 이 조직은 코드를 유지 관리하고 테스트하기 쉽게 합니다. 다음으로 개발 환경을 설정하여 코드를 작성할 준비를 합니다.

## 개발 환경 설정 {#set-up-the-development-environment}

적절히 격리된 개발 환경은 종속성 충돌을 방지하고 애플리케이션을 배포 가능하게 만듭니다.

Chat을 사용하여 Python 가상 환경을 설정하고 올바른 종속성을 포함한 `requirements.txt` 파일을 만듭니다. 이렇게 하면 개발을 위한 안정적인 기초를 확보할 수 있습니다.

```plaintext
   python-shop-app/
   ├── LICENSE
   ├── README.md
   ├── requirements.txt <= File you are updating
   ├── setup.py
   ├── .gitignore
   ├── .env
   ├── app/
   │   ├── __init__.py
   │   ├── models/
   │   │   ├── __init__.py
   │   │   └── article.py
   │   ├── routes/
   │   │   ├── __init__.py
   │   │   └── shop.py
   │   └── database.py
   └── tests/
       ├── __init__.py
       └── test_shop.py
```

1. 선택 사항입니다. Chat에 Python과 Flask가 함께 웹 애플리케이션을 생성하는 방식에 대해 물어봅니다.

1. Chat을 사용하여 Python 환경 설정의 모범 사례를 이해합니다:

   ```plaintext
   What are the recommended steps for setting up a Python virtual environment with
   Flask? Include information about requirements.txt and pip.
   ```

   필요한 후속 질문을 합니다. 예를 들어:

   ```plaintext
   What does the requirements.txt do in a Python web app?
   ```

1. 응답을 기반으로 먼저 가상 환경을 만들고 활성화합니다 (예를 들어, Homebrew의 `python3` 패키지를 사용하는 MacOS):

   ```plaintext
   python3 -m venv myenv
   source myenv/bin/activate
   ```

1. `requirements.txt` 파일도 만들어야 합니다. Chat에 다음을 물어봅니다:

   ```plaintext
   What should be included in requirements.txt for a Flask web application with
   SQLite database and testing capabilities? Include specific version numbers.
   ```

   응답을 `requirements.txt` 파일에 복사합니다.

1. `requirements.txt` 파일에 명명된 종속성을 설치합니다:

   ```plaintext
   pip install -r requirements.txt
   ```

개발 환경은 이제 충돌을 방지하기 위해 가상 환경에 격리된 모든 필수 종속성으로 구성됩니다. 다음으로 프로젝트의 패키지 및 환경 설정을 구성합니다.

## 프로젝트 구성 {#configure-the-project}

적절한 구성은 환경 변수를 포함하여 애플리케이션이 다양한 환경에서 일관되게 실행되도록 합니다.

Code Suggestions을 사용하여 구성을 생성하고 개선할 수 있습니다. 그런 다음 Chat에 각 설정의 목적을 설명해달라고 요청하여 구성하는 대상과 이유를 이해합니다.

1. 이미 프로젝트 폴더에 `setup.py`라고 불리는 Python 구성 파일을 만들었습니다:

   ```plaintext
      python-shop-app/
      ├── LICENSE
      ├── README.md
      ├── requirements.txt
      ├── setup.py <= File you are updating
      ├── .gitignore
      ├── .env
      ├── app/
      │   ├── __init__.py
      │   ├── models/
      │   │   ├── __init__.py
      │   │   └── article.py
      │   ├── routes/
      │   │   ├── __init__.py
      │   │   └── shop.py
      │   └── database.py
      └── tests/
          ├── __init__.py
          └── test_shop.py
   ```

   이 파일을 열고 파일 맨 위에 이 주석을 입력합니다:

   ```plaintext
   # Populate this setup.py configuration file for a Flask web application
   # Include dependencies for Flask, testing, and database functionality
   # Use semantic versioning
   ```

   Code Suggestions는 구성을 생성합니다.

1. 선택 사항입니다. 생성된 구성 코드를 선택하고 다음 [슬래시 명령](../../gitlab_duo_chat/examples.md#gitlab-duo-chat-slash-commands)을 사용합니다:

   - [`/explain`](../../gitlab_duo_chat/examples.md#explain-selected-code)을 사용하여 각 구성 설정의 역할을 이해합니다.
   - [`/refactor`](../../gitlab_duo_chat/examples.md#refactor-code-in-the-ide)을 사용하여 구성 구조의 잠재적 개선 사항을 확인합니다.

1. 필요에 따라 생성된 코드를 검토하고 조정합니다.

   구성 파일에서 조정할 수 있는 항목이 확실하지 않으면 Chat에 물어봅니다.

   Chat에 조정할 사항을 물어보려면 GitLab UI 대신 `setup.py` 파일의 IDE에서 수행합니다. 이렇게 하면 Chat에 [작업 중인 컨텍스트](../../duo_agent_platform/context.md#gitlab-duo-agentic-chat)를 제공할 수 있으며, 방금 만든 `setup.py` 파일도 포함합니다.

   ```plaintext
   You have used Code Suggestions to generate a Python configuration file, `setup.py`,
   for a Flask web application. This file includes dependencies for Flask, testing,
   and database functionality. If I were to review this file, what might I want
   to change and adjust?
   ```

1. 파일을 저장합니다.

### 환경 변수 설정 {#set-the-environment-variables}

이제 Chat과 Code Suggestions을 모두 사용하여 환경 변수를 설정합니다.

1. Chat에서 다음을 물어봅니다:

   ```plaintext
   In a Python project, what environment variables should be set for a Flask application in development mode? Include database configuration.
   ```

1. 이미 환경 변수를 저장할 `.env` 파일을 만들었습니다.

   ```plaintext
      python-shop-app/
      ├── LICENSE
      ├── README.md
      ├── requirements.txt
      ├── setup.py
      ├── .gitignore
      ├── .env <= File you are updating
      ├── app/
      │   ├── __init__.py
      │   ├── models/
      │   │   ├── __init__.py
      │   │   └── article.py
      │   ├── routes/
      │   │   ├── __init__.py
      │   │   └── shop.py
      │   └── database.py
      └── tests/
          ├── __init__.py
          └── test_shop.py
   ```

   이 파일을 열고 파일 맨 위에 다음 주석을 입력하고 Chat에서 권장한 환경 변수를 포함합니다:

   ```plaintext
   # Populate this .env file to store environment variables
   # Include the following
   # ...
   # Use semantic versioning
   ```

1. 필요에 따라 생성된 코드를 검토하고 조정한 후 파일을 저장합니다.

프로젝트를 구성하고 환경 변수를 설정했습니다. 이렇게 하면 애플리케이션을 다양한 환경에서 일관되게 배포할 수 있습니다. 다음으로 재고 시스템용 애플리케이션 코드를 만듭니다.

## 애플리케이션 코드 만들기 {#create-the-application-code}

Flask 웹 프레임워크는 세 가지 핵심 구성 요소를 포함합니다:

- 모델: 데이터와 비즈니스 로직 및 데이터베이스 모델을 포함합니다. `article.py` 파일에서 지정됩니다.
- 보기: HTTP 요청 및 응답을 처리합니다. `shop.py` 파일에서 지정됩니다.
- 컨트롤러: 데이터 저장소 및 검색을 관리합니다. `database.py` 파일에서 지정됩니다.

Chat과 Code Suggestions을 사용하여 Python 프로젝트 구조의 세 파일에 이 세 구성 요소 각각을 정의할 수 있습니다:

- `article.py`는 모델 구성 요소를 정의하며, 특히 데이터베이스 모델입니다.
- `shop.py`는 보기 구성 요소를 정의하며, 특히 API 경로입니다.
- `database.py`는 컨트롤러 구성 요소를 정의합니다.

### 기사 파일을 만들어 데이터베이스 모델 정의 {#create-the-article-file-to-define-the-database-model}

서점은 재고를 효과적으로 관리하기 위해 데이터베이스 모델과 작업이 필요합니다.

서점 재고 시스템용 애플리케이션 코드를 만들려면 기사용 데이터베이스 모델을 정의하는 기사 파일을 사용합니다.

Code Suggestions을 사용하여 코드를 생성하고 Chat을 사용하여 데이터 모델링 및 데이터베이스 관리의 모범 사례를 구현합니다.

1. 이미 `article.py` 파일을 만들었습니다:

   ```plaintext
      python-shop-app/
      ├── LICENSE
      ├── README.md
      ├── requirements.txt
      ├── setup.py
      ├── .gitignore
      ├── .env
      ├── app/
      │   ├── __init__.py
      │   ├── models/
      │   │   ├── __init__.py
      │   │   └── article.py <= File you are updating
      │   ├── routes/
      │   │   ├── __init__.py
      │   │   └── shop.py
      │   └── database.py
      └── tests/
          ├── __init__.py
          └── test_shop.py
   ```

   이 파일에서 Code Suggestions을 사용하고 다음을 입력합니다:

   ```plaintext
   # Create an Article class for a bookstore inventory system
   # Include fields for: name, price, quantity
   # Add data validation for each field
   # Add methods to convert to/from dictionary format
   ```

1. 선택 사항입니다. 다음 [슬래시 명령](../../gitlab_duo_chat/examples.md#gitlab-duo-chat-slash-commands)을 사용합니다:

   - [`/explain`](../../gitlab_duo_chat/examples.md#explain-selected-code)을 사용하여 기사 클래스의 작동 방식과 디자인 패턴을 이해합니다.
   - [`/refactor`](../../gitlab_duo_chat/examples.md#refactor-code-in-the-ide)을 사용하여 클래스 구조 및 메서드의 잠재적 개선 사항을 확인합니다.

1. 필요에 따라 생성된 코드를 검토하고 조정한 후 파일을 저장합니다.

다음으로 API 경로를 정의합니다.

### 쇼핑 파일을 만들어 API 경로 정의 {#create-the-shop-file-to-define-the-api-routes}

데이터베이스 모델을 정의할 기사 파일을 만들었으니 이제 API 경로를 만듭니다.

API 경로는 웹 애플리케이션에 중요합니다:

- 클라이언트가 애플리케이션과 상호 작용할 수 있는 공개 API를 정의합니다.
- HTTP 요청을 애플리케이션의 적절한 코드에 매핑합니다.
- 입력 유효성 검사 및 오류 응답을 처리합니다.
- 내부 모델과 API 클라이언트에서 예상하는 JSON 형식 간에 데이터를 변환합니다.

서점 재고 시스템의 경우 이러한 경로를 통해 직원이 다음을 수행할 수 있습니다:

- 재고의 모든 책을 봅니다.
- ID별로 특정 책을 찾습니다.
- 도착할 때 새 책을 추가합니다.
- 가격이나 수량 같은 책 정보를 업데이트합니다.
- 더 이상 필요하지 않은 책을 제거합니다.

Flask에서 경로는 특정 URL 엔드포인트에 대한 요청을 처리하는 함수입니다. 예를 들어 `GET /books`에 대한 경로는 모든 책의 목록을 반환하고, `POST /books`는 새 책을 재고에 추가합니다.

Chat과 Code Suggestions을 사용하여 프로젝트 구조에서 이미 설정한 `shop.py` 파일에 이러한 경로를 만듭니다:

```plaintext
python-shop-app/
├── LICENSE
├── README.md
├── requirements.txt
├── setup.py
├── .gitignore
├── .env
├── app/
│   ├── __init__.py
│   ├── models/
│   │   ├── __init__.py
│   │   └── article.py
│   ├── routes/
│   │   ├── __init__.py
│   │   └── shop.py <= File you are updating
│   └── database.py
└── tests/
   ├── __init__.py
   └── test_shop.py
```

#### Flask 애플리케이션 및 경로 만들기 {#create-the-flask-application-and-routes}

1. `shop.py` 파일을 엽니다. Code Suggestions을 사용하려면 파일 맨 위에 이 주석을 입력합니다:

   ```plaintext
   # Create Flask routes for a bookstore inventory system
   # Include routes for:
   # - Getting all books (GET /books)
   # - Getting a single book by ID (GET /books/<id>)
   # - Adding a new book (POST /books)
   # - Updating a book (PUT /books/<id>)
   # - Deleting a book (DELETE /books/<id>)
   # Use the Article class from models.article and database from database.py
   # Include proper error handling and HTTP status codes
   ```

1. 생성된 코드를 검토합니다. 다음을 포함해야 합니다:

   - Flask, request 및 `jsonify`에 대한 import 문입니다.
   - Article 클래스 및 데이터베이스 모듈에 대한 import 문입니다.
   - 모든 CRUD 작업(만들기, 읽기, 업데이트, 삭제)에 대한 경로 정의입니다.
   - 적절한 오류 처리 및 HTTP 상태 코드입니다.

1. 선택 사항입니다. 다음 슬래시 명령을 사용합니다:

   - [`/explain`](../../gitlab_duo_chat/examples.md#explain-selected-code)을 사용하여 Flask 라우팅의 작동 방식을 이해합니다.
   - [`/refactor`](../../gitlab_duo_chat/examples.md#refactor-code-in-the-ide)을 사용하여 잠재적 개선 사항을 확인합니다.

1. 생성된 코드가 완전히 요구 사항을 충족하지 않거나 개선 방법을 이해하려면 `shop.py` 파일 내에서 Chat에 물어볼 수 있습니다:

   ```plaintext
   Can you suggest improvements for my Flask routes in this shop.py file?
   I want to ensure that:
   1. The routes follow RESTful API design principles
   2. Responses include appropriate HTTP status codes
   3. Input validation is handled properly
   4. The code follows Flask best practices
   ```

1. 또한 `app` 디렉토리 내의 `__init__.py` 파일에서 Flask 애플리케이션 인스턴스를 만들어야 합니다. 이 파일을 열고 Code Suggestions을 사용하여 적절한 코드를 생성합니다:

   ```plaintext
   # Create a Flask application factory
   # Configure the app with settings from environment variables
   # Register the shop blueprint
   # Return the configured app
   ```

1. 두 파일을 모두 저장합니다.

### 데이터베이스 파일을 만들어 데이터 저장 및 검색 관리 {#create-the-database-file-to-manage-data-storage-and-retrieval}

마지막으로 데이터베이스 작업 코드를 만듭니다. 이미 `database.py` 파일을 만들었습니다:

```plaintext
   python-shop-app/
   ├── LICENSE
   ├── README.md
   ├── requirements.txt
   ├── setup.py
   ├── .gitignore
   ├── .env
   ├── app/
   │   ├── __init__.py
   │   ├── models/
   │   │   ├── __init__.py
   │   │   └── article.py
   │   ├── routes/
   │   │   ├── __init__.py
   │   │   └── shop.py
   │   └── database.py <= File you are updating
   └── tests/
       ├── __init__.py
       └── test_shop.py
```

1. Chat에 다음을 입력합니다:

   ```plaintext
   Generate a Python class that manages SQLite database operations for a bookstore inventory. Include:
   - Context manager for connections
   - Table creation
   - CRUD operations
   - Error handling
   Show the complete code with comments.
   ```

1. 필요에 따라 생성된 코드를 검토하고 조정한 후 파일을 저장합니다.

Flask 프레임워크를 사용하여 구축한 재고 관리 시스템의 기초 코드를 성공적으로 만들었고 Python 웹 애플리케이션의 핵심 구성 요소를 정의했습니다.

다음으로 만든 코드를 예제 코드 파일과 비교합니다.

## 코드를 예제 코드 파일과 비교 {#check-your-code-against-example-code-files}

다음 예제는 튜토리얼을 따른 후 얻을 코드와 유사해야 하는 완전하고 작동하는 코드를 보여줍니다.

{{< tabs >}}

{{< tab title="`.gitignore`" >}}

이 파일은 표준 Python 프로젝트 제외 항목을 보여줍니다:

```plaintext
# Virtual Environment
myenv/
venv/
ENV/
env/
.venv/

# Python
__pycache__/
*.py[cod]
*$py.class
*.so
.Python
build/
develop-eggs/
dist/
downloads/
eggs/
.eggs/
lib/
lib64/
parts/
sdist/
var/
wheels/
*.egg-info/
.installed.cfg
*.egg

# SQLite database files
*.db
*.sqlite
*.sqlite3

# Environment variables
.env
.env.local
.env.*.local

# IDE specific files
.idea/
.vscode/
*.swp
*.swo
.DS_Store
```

{{< /tab >}}

{{< tab title="`README.md`" >}}

설정 및 사용 지침이 포함된 포괄적인 `README` 파일입니다.

````markdown
# Bookstore Inventory Management System

A Python web application for managing bookstore inventory, built with Flask and SQLite.

## Features

- Track book inventory in real time.
- Add, update, and remove books.
- Data validation to prevent common errors.
- RESTful API for inventory management.

## Requirements

- Python 3.8 or higher.
- Flask 2.2.0 or higher.
- SQLite 3.

## Installation

1. Clone the repository:

   ```shell
   git clone https://gitlab.com/your-username/python-shop-app.git
   cd python-shop-app
   ```

2. Create and activate a virtual environment:

   ```shell
   python -m venv myenv
   source myenv/bin/activate  # On Windows: myenv\Scripts\activate
   ```

3. Install dependencies:

   ```shell
   pip install -r requirements.txt
   ```

4. Set up environment variables:

   Copy `.env.example` to `.env` and modify as needed.

## Usage

1. Start the Flask application:

   ```shell
   flask run
   ```

2. The API will be available at `http://localhost:5000/`

## API Endpoints

- `GET /books` - Get all books
- `GET /books/<id>` - Get a specific book
- `POST /books` - Add a new book
- `PUT /books/<id>` - Update a book
- `DELETE /books/<id>` - Delete a book

## Testing

Run tests with `pytest`:

```python
python -m pytest
```
````

{{< /tab >}}

{{< tab title="`requirements.txt`" >}}

모든 필수 Python 패키지를 버전과 함께 나열합니다.

```plaintext
Flask==2.2.3
pytest==7.3.1
pytest-flask==1.2.0
Flask-SQLAlchemy==3.0.3
SQLAlchemy==2.0.9
python-dotenv==1.0.0
Werkzeug==2.2.3
requests==2.28.2
```

{{< /tab >}}

{{< tab title="`setup.py`" >}}

패키징용 프로젝트 구성입니다.

```python
from setuptools import setup, find_packages

setup(
    name="bookstore-inventory",
    version="0.1.0",
    packages=find_packages(),
    include_package_data=True,
    install_requires=[
        "Flask>=2.2.0",
        "Flask-SQLAlchemy>=3.0.0",
        "SQLAlchemy>=2.0.0",
        "pytest>=7.0.0",
        "pytest-flask>=1.2.0",
        "python-dotenv>=1.0.0",
    ],
    python_requires=">=3.8",
    author="Your Name",
    author_email="your.email@example.com",
    description="A Flask web application for managing bookstore inventory",
    keywords="flask, inventory, bookstore",
    url="https://gitlab.com/your-username/python-shop-app",
    classifiers=[
        "Development Status :: 3 - Alpha",
        "Environment :: Web Environment",
        "Framework :: Flask",
        "Intended Audience :: Developers",
        "License :: OSI Approved :: MIT License",
        "Programming Language :: Python :: 3",
        "Programming Language :: Python :: 3.8",
        "Programming Language :: Python :: 3.9",
        "Programming Language :: Python :: 3.10",
    ],
)
```

{{< /tab >}}

{{< tab title="`.env`" >}}

애플리케이션의 환경 변수를 포함합니다.

```plaintext
# Flask configuration
FLASK_APP=app
FLASK_ENV=development
FLASK_DEBUG=1
SECRET_KEY=your-secret-key-change-in-production

# Database configuration
DATABASE_URL=sqlite:///bookstore.db
TEST_DATABASE_URL=sqlite:///test_bookstore.db

# Application settings
BOOK_TITLE_MAX_LENGTH=100
MAX_PRICE=1000.00
MAX_QUANTITY=1000
```

{{< /tab >}}

{{< tab title="`app/models/article.py`" >}}

완전한 유효성 검사가 포함된 기사 클래스입니다.

```python
class Article:
    """Article class for a bookstore inventory system."""

    def __init__(self, name, price, quantity, article_id=None):
        """
        Initialize an article with validation.

        Args:
            name (str): The name/title of the book
            price (float): The price of the book
            quantity (int): The quantity in stock
            article_id (int, optional): The unique identifier for the article

        Raises:
            ValueError: If any of the fields fail validation
        """
        self.id = article_id
        self.set_name(name)
        self.set_price(price)
        self.set_quantity(quantity)

    def set_name(self, name):
        """
        Set the name with validation.

        Args:
            name (str): The name/title of the book

        Raises:
            ValueError: If name is empty or too long
        """
        if not name or not isinstance(name, str):
            raise ValueError("Book title cannot be empty and must be a string")

        if len(name) > 100:  # Max length validation
            raise ValueError("Book title cannot exceed 100 characters")

        self.name = name.strip()

    def set_price(self, price):
        """
        Set the price with validation.

        Args:
            price (float): The price of the book

        Raises:
            ValueError: If price is negative or not a number
        """
        try:
            price_float = float(price)
        except (ValueError, TypeError):
            raise ValueError("Price must be a number")

        if price_float < 0:
            raise ValueError("Price cannot be negative")

        if price_float > 1000:  # Max price validation
            raise ValueError("Price cannot exceed 1000")

        # Ensure price has at most 2 decimal places
        self.price = round(price_float, 2)

    def set_quantity(self, quantity):
        """
        Set the quantity with validation.

        Args:
            quantity (int): The quantity in stock

        Raises:
            ValueError: If quantity is negative or not an integer
        """
        try:
            quantity_int = int(quantity)
        except (ValueError, TypeError):
            raise ValueError("Quantity must be an integer")

        if quantity_int < 0:
            raise ValueError("Quantity cannot be negative")

        if quantity_int > 1000:  # Max quantity validation
            raise ValueError("Quantity cannot exceed 1000")

        self.quantity = quantity_int

    def to_dict(self):
        """
        Convert the article to a dictionary.

        Returns:
            dict: Dictionary representation of the article
        """
        return {
            "id": self.id,
            "name": self.name,
            "price": self.price,
            "quantity": self.quantity
        }

    @classmethod
    def from_dict(cls, data):
        """
        Create an article from a dictionary.

        Args:
            data (dict): Dictionary with article data

        Returns:
            Article: New article instance
        """
        article_id = data.get("id")
        return cls(
            name=data["name"],
            price=data["price"],
            quantity=data["quantity"],
            article_id=article_id
        )
```

{{< /tab >}}

{{< tab title="`app/routes/shop.py`" >}}

오류 처리가 포함된 완전한 API 엔드포인트입니다.

```python
from flask import Blueprint, request, jsonify, current_app
from app.models.article import Article
from app import database
import logging

# Create a blueprint for the shop routes
shop_bp = Blueprint('shop', __name__, url_prefix='/books')

# Set up logging
logger = logging.getLogger(__name__)

@shop_bp.route('', methods=['GET'])
def get_all_books():
    """Get all books from the inventory."""
    try:
        books = database.get_all_articles()
        return jsonify([book.to_dict() for book in books]), 200
    except Exception as e:
        logger.error(f"Error getting all books: {str(e)}")
        return jsonify({"error": "Failed to retrieve books"}), 500

@shop_bp.route('/<int:book_id>', methods=['GET'])
def get_book(book_id):
    """Get a specific book by ID."""
    try:
        book = database.get_article_by_id(book_id)
        if book:
            return jsonify(book.to_dict()), 200
        return jsonify({"error": f"Book with ID {book_id} not found"}), 404
    except Exception as e:
        logger.error(f"Error getting book {book_id}: {str(e)}")
        return jsonify({"error": f"Failed to retrieve book {book_id}"}), 500

@shop_bp.route('', methods=['POST'])
def add_book():
    """Add a new book to the inventory."""
    data = request.get_json()

    if not data:
        return jsonify({"error": "No data provided"}), 400

    required_fields = ['name', 'price', 'quantity']
    for field in required_fields:
        if field not in data:
            return jsonify({"error": f"Missing required field: {field}"}), 400

    try:
        # Validate data by creating an Article object
        new_book = Article(
            name=data['name'],
            price=data['price'],
            quantity=data['quantity']
        )

        # Save to database
        book_id = database.add_article(new_book)

        # Return the created book
        created_book = database.get_article_by_id(book_id)
        return jsonify(created_book.to_dict()), 201

    except ValueError as e:
        return jsonify({"error": str(e)}), 400
    except Exception as e:
        logger.error(f"Error adding book: {str(e)}")
        return jsonify({"error": "Failed to add book"}), 500

@shop_bp.route('/<int:book_id>', methods=['PUT'])
def update_book(book_id):
    """Update an existing book."""
    data = request.get_json()

    if not data:
        return jsonify({"error": "No data provided"}), 400

    try:
        # Check if book exists
        existing_book = database.get_article_by_id(book_id)
        if not existing_book:
            return jsonify({"error": f"Book with ID {book_id} not found"}), 404

        # Update book properties
        if 'name' in data:
            existing_book.set_name(data['name'])
        if 'price' in data:
            existing_book.set_price(data['price'])
        if 'quantity' in data:
            existing_book.set_quantity(data['quantity'])

        # Save updated book
        database.update_article(existing_book)

        # Return the updated book
        updated_book = database.get_article_by_id(book_id)
        return jsonify(updated_book.to_dict()), 200

    except ValueError as e:
        return jsonify({"error": str(e)}), 400
    except Exception as e:
        logger.error(f"Error updating book {book_id}: {str(e)}")
        return jsonify({"error": f"Failed to update book {book_id}"}), 500

@shop_bp.route('/<int:book_id>', methods=['DELETE'])
def delete_book(book_id):
    """Delete a book from the inventory."""
    try:
        # Check if book exists
        existing_book = database.get_article_by_id(book_id)
        if not existing_book:
            return jsonify({"error": f"Book with ID {book_id} not found"}), 404

        # Delete the book
        database.delete_article(book_id)

        return jsonify({"message": f"Book with ID {book_id} deleted successfully"}), 200

    except Exception as e:
        logger.error(f"Error deleting book {book_id}: {str(e)}")
        return jsonify({"error": f"Failed to delete book {book_id}"}), 500
```

{{< /tab >}}

{{< tab title="`app/database.py`" >}}

연결 관리가 포함된 데이터베이스 작업입니다.

```python
import sqlite3
import os
import logging
from contextlib import contextmanager
from app.models.article import Article

# Set up logging
logger = logging.getLogger(__name__)

# Get database path from environment variable or use default
DATABASE_PATH = os.environ.get('DATABASE_PATH', 'bookstore.db')

@contextmanager
def get_db_connection():
    """
    Context manager for database connections.
    Automatically handles connection opening, committing, and closing.

    Yields:
        sqlite3.Connection: Database connection object
    """
    conn = None
    try:
        conn = sqlite3.connect(DATABASE_PATH)
        # Configure connection to return rows as dictionaries
        conn.row_factory = sqlite3.Row
        yield conn
        conn.commit()
    except sqlite3.Error as e:
        if conn:
            conn.rollback()
        logger.error(f"Database error: {str(e)}")
        raise
    finally:
        if conn:
            conn.close()

def initialize_database():
    """
    Initialize the database by creating the articles table if it doesn't exist.
    """
    try:
        with get_db_connection() as conn:
            cursor = conn.cursor()

            # Create articles table
            cursor.execute('''
                CREATE TABLE IF NOT EXISTS articles (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    name TEXT NOT NULL,
                    price REAL NOT NULL,
                    quantity INTEGER NOT NULL
                )
            ''')

            logger.info("Database initialized successfully")
    except sqlite3.Error as e:
        logger.error(f"Failed to initialize database: {str(e)}")
        raise

def add_article(article):
    """
    Add a new article to the database.

    Args:
        article (Article): Article object to add

    Returns:
        int: ID of the newly added article
    """
    try:
        with get_db_connection() as conn:
            cursor = conn.cursor()

            cursor.execute(
                "INSERT INTO articles (name, price, quantity) VALUES (?, ?, ?)",
                (article.name, article.price, article.quantity)
            )

            # Get the ID of the newly inserted article
            article_id = cursor.lastrowid
            logger.info(f"Added article with ID {article_id}")
            return article_id
    except sqlite3.Error as e:
        logger.error(f"Failed to add article: {str(e)}")
        raise

def get_article_by_id(article_id):
    """
    Get an article by its ID.

    Args:
        article_id (int): ID of the article to retrieve

    Returns:
        Article: Article object if found, None otherwise
    """
    try:
        with get_db_connection() as conn:
            cursor = conn.cursor()

            cursor.execute("SELECT * FROM articles WHERE id = ?", (article_id,))
            row = cursor.fetchone()

            if row:
                return Article(
                    name=row['name'],
                    price=row['price'],
                    quantity=row['quantity'],
                    article_id=row['id']
                )
            return None
    except sqlite3.Error as e:
        logger.error(f"Failed to get article {article_id}: {str(e)}")
        raise

def get_all_articles():
    """
    Get all articles from the database.

    Returns:
        list: List of Article objects
    """
    try:
        with get_db_connection() as conn:
            cursor = conn.cursor()

            cursor.execute("SELECT * FROM articles")
            rows = cursor.fetchall()

            articles = []
            for row in rows:
                article = Article(
                    name=row['name'],
                    price=row['price'],
                    quantity=row['quantity'],
                    article_id=row['id']
                )
                articles.append(article)

            return articles
    except sqlite3.Error as e:
        logger.error(f"Failed to get all articles: {str(e)}")
        raise

def update_article(article):
    """
    Update an existing article in the database.

    Args:
        article (Article): Article object with updated values

    Returns:
        bool: True if successful, False if article not found
    """
    try:
        with get_db_connection() as conn:
            cursor = conn.cursor()

            cursor.execute(
                "UPDATE articles SET name = ?, price = ?, quantity = ? WHERE id = ?",
                (article.name, article.price, article.quantity, article.id)
            )

            # Check if an article was actually updated
            if cursor.rowcount == 0:
                logger.warning(f"No article found with ID {article.id}")
                return False

            logger.info(f"Updated article with ID {article.id}")
            return True
    except sqlite3.Error as e:
        logger.error(f"Failed to update article {article.id}: {str(e)}")
        raise

def delete_article(article_id):
    """
    Delete an article from the database.

    Args:
        article_id (int): ID of the article to delete

    Returns:
        bool: True if successful, False if article not found
    """
    try:
        with get_db_connection() as conn:
            cursor = conn.cursor()

            cursor.execute("DELETE FROM articles WHERE id = ?", (article_id,))

            # Check if an article was actually deleted
            if cursor.rowcount == 0:
                logger.warning(f"No article found with ID {article_id}")
                return False

            logger.info(f"Deleted article with ID {article_id}")
            return True
    except sqlite3.Error as e:
        logger.error(f"Failed to delete article {article_id}: {str(e)}")
        raise
```

{{< /tab >}}

{{< tab title="`app/__init__.py`" >}}

Flask 애플리케이션 팩토리입니다.

```python
import os
from flask import Flask
from dotenv import load_dotenv

def create_app(test_config=None):
    """
    Application factory for creating the Flask app.

    Args:
        test_config (dict, optional): Test configuration to override default config

    Returns:
        Flask: Configured Flask application
    """
    # Load environment variables from .env file
    load_dotenv()

    # Create and configure the app
    app = Flask(__name__, instance_relative_config=True)

    # Set default configuration
    app.config.from_mapping(
        SECRET_KEY=os.environ.get('SECRET_KEY', 'dev'),
        DATABASE_PATH=os.environ.get('DATABASE_URL', 'bookstore.db'),
        BOOK_TITLE_MAX_LENGTH=int(os.environ.get('BOOK_TITLE_MAX_LENGTH', 100)),
        MAX_PRICE=float(os.environ.get('MAX_PRICE', 1000.00)),
        MAX_QUANTITY=int(os.environ.get('MAX_QUANTITY', 1000))
    )

    # Override config with test config if provided
    if test_config:
        app.config.update(test_config)

    # Ensure the instance folder exists
    os.makedirs(app.instance_path, exist_ok=True)

    # Initialize database
    from app import database
    database.initialize_database()

    # Register blueprints
    from app.routes.shop import shop_bp
    app.register_blueprint(shop_bp)

    # Add a simple index route
    @app.route('/')
    def index():
        return {
            "message": "Welcome to the Bookstore Inventory API",
            "endpoints": {
                "books": "/books",
                "book_by_id": "/books/<id>"
            }
        }

    return app
```

{{< /tab >}}

{{< /tabs >}}

1. 코드 파일을 이러한 예제와 비교합니다.
1. 코드가 작동하는지 확인하려면 Chat에 로컬 애플리케이션 서버를 시작하는 방법을 물어봅니다:

   ```plaintext
   How do I start a local application server for my Python web application?
   ```

1. 지침을 따르고 애플리케이션이 작동하는지 확인합니다.

애플리케이션이 작동 중이면 축하합니다! GitLab Duo Chat 및 Code Suggestions을 사용하여 작동하는 온라인 쇼핑 애플리케이션을 성공적으로 만들었습니다.

작동하지 않으면 이유를 확인해야 합니다. Chat과 Code Suggestions는 테스트를 만들어 애플리케이션이 예상대로 작동하는지 확인하고 수정해야 할 문제를 식별하는 데 도움이 될 수 있습니다.

<!-- markdownlint-disable -->
<i class="fa-youtube-play" aria-hidden="true"></i> 자세한 내용은 [GitLab Duo /fix 사용](https://youtu.be/agTqx__j6Ko?si=vpLfVvmFVcBivB1g)을 참조하세요.
<!-- Video published on 2025-02-13 -->

## 관련 항목 {#related-topics}

- [GitLab Duo 사용 사례](../use_cases.md)
- [GitLab Duo 시작하기](../../get_started/getting_started_gitlab_duo.md).
- 블로그 게시물: [GitLab Duo로 DevSecOps 엔지니어링 워크플로우 간소화](https://about.gitlab.com/blog/streamline-devsecops-engineering-workflows-with-gitlab-duo/)
- <i class="fa-youtube-play" aria-hidden="true"></i> [GitLab Duo Chat (에이전틱)](https://youtu.be/uG9-QLAJrrg?si=c25SR7DoRAep7jvQ)
  <!-- Video published on 2025-06-02 -->
- <i class="fa-youtube-play" aria-hidden="true"></i> [GitLab Duo Chat (비에이전틱)](https://youtu.be/ZQBAuf-CTAY?si=0o9-xJ_ATTsL1oew)
  <!-- Video published on 2024-04-18 -->
- <i class="fa-youtube-play" aria-hidden="true"></i> [GitLab Duo Code Suggestions](https://youtu.be/ds7SG1wgcVM?si=MfbzPIDpikGhoPh7)
  <!-- Video published on 2025-03-18 -->
- <i class="fa-youtube-play" aria-hidden="true"></i> [GitLab Duo를 사용한 애플리케이션 현대화 (C++ to Java)](https://youtu.be/FjoAmt5eeXA?si=SLv9Mv8eSUAVwW5Z)
