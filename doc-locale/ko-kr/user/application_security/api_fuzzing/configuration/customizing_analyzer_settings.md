---
stage: Application Security Testing
group: Dynamic Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 분석기 설정 사용자 정의
---

API 퍼징 동작은 CI/CD 변수를 통해 변경할 수 있습니다.

API 퍼징 구성 파일은 리포지토리의 `.gitlab` 디렉토리에 있어야 합니다.

> [!warning]
> GitLab 보안 스캔 도구의 모든 사용자 정의는 변경 사항을 기본 브랜치에 병합하기 전에 머지 리퀘스트에서 테스트해야 합니다. 테스트를 거치지 않으면 수많은 거짓 양성을 포함하여 예상치 못한 결과가 발생할 수 있습니다.

## 인증 {#authentication}

인증은 인증 토큰을 헤더 또는 쿠키로 제공하여 처리됩니다. 인증 플로우를 수행하거나 토큰을 계산하는 스크립트를 제공할 수 있습니다.

### HTTP 기본 인증 {#http-basic-authentication}

[HTTP 기본 인증](https://en.wikipedia.org/wiki/Basic_access_authentication) 은 HTTP 프로토콜에 내장된 인증 방법으로, [전송 계층 보안(TLS)](https://en.wikipedia.org/wiki/Transport_Layer_Security)과 함께 사용됩니다.

[CI/CD 변수 생성](../../../../ci/variables/_index.md#for-a-project)을 권장합니다(예: `TEST_API_PASSWORD`). 마스킹되도록 설정하세요. GitLab 프로젝트 페이지의 **설정** > **CI/CD**에서 **변수** 섹션의 CI/CD 변수를 생성할 수 있습니다. [마스킹된 변수에 대한 제한](../../../../ci/variables/_index.md#mask-a-cicd-variable) 때문에 변수로 추가하기 전에 비밀번호를 Base64로 인코딩해야 합니다.

마지막으로 `.gitlab-ci.yml` 파일에 두 개의 CI/CD 변수를 추가합니다:

- `FUZZAPI_HTTP_USERNAME`:  인증을 위한 사용자 이름입니다.
- `FUZZAPI_HTTP_PASSWORD_BASE64`:  인증을 위한 Base64로 인코딩된 비밀번호입니다.

```yaml
stages:
    - fuzz

include:
  - template: API-Fuzzing.gitlab-ci.yml

variables:
  FUZZAPI_PROFILE: Quick-10
  FUZZAPI_HAR: test-api-recording.har
  FUZZAPI_TARGET_URL: http://test-deployment/
  FUZZAPI_HTTP_USERNAME: testuser
  FUZZAPI_HTTP_PASSWORD_BASE64: $TEST_API_PASSWORD
```

### 원본 비밀번호 {#raw-password}

비밀번호를 Base64로 인코딩하지 않으려면(또는 GitLab 15.3 이하를 사용 중인 경우) `FUZZAPI_HTTP_PASSWORD_BASE64` 대신 원본 비밀번호 `FUZZAPI_HTTP_PASSWORD`을 제공할 수 있습니다.

### Bearer 토큰 {#bearer-tokens}

Bearer 토큰은 OAuth2 및 JSON Web 토큰(JWT)을 포함한 여러 가지 인증 메커니즘에서 사용됩니다. Bearer 토큰은 `Authorization` HTTP 헤더를 사용하여 전송됩니다. API 퍼징에서 bearer 토큰을 사용하려면 다음 중 하나가 필요합니다:

- 만료되지 않는 토큰
- 테스트 기간 동안 유효한 토큰을 생성하는 방법
- 토큰을 생성하기 위해 API 퍼징이 호출할 수 있는 Python 스크립트

#### 토큰이 만료되지 않음 {#token-doesnt-expire}

Bearer 토큰이 만료되지 않으면 `FUZZAPI_OVERRIDES_ENV` 변수를 사용하여 제공합니다. 이 변수의 내용은 API 퍼징의 발신 HTTP 요청에 추가할 헤더 및 쿠키를 제공하는 JSON 스니펫입니다.

`FUZZAPI_OVERRIDES_ENV`을 사용하여 bearer 토큰을 제공하려면 다음 단계를 따릅니다:

1. [CI/CD 변수 생성](../../../../ci/variables/_index.md#for-a-project). 예: `TEST_API_BEARERAUTH`. `{"headers":{"Authorization":"Bearer dXNlcm5hbWU6cGFzc3dvcmQ="}}` 값을 설정합니다(토큰으로 대체하세요). GitLab 프로젝트 페이지의 **설정** > **CI/CD**에서 **변수** 섹션의 CI/CD 변수를 생성할 수 있습니다.

1. `.gitlab-ci.yml` 파일에서 `FUZZAPI_OVERRIDES_ENV`을 방금 생성한 변수로 설정합니다:

   ```yaml
   stages:
     - fuzz

   include:
     - template: API-Fuzzing.gitlab-ci.yml

   variables:
     FUZZAPI_PROFILE: Quick-10
     FUZZAPI_OPENAPI: test-api-specification.json
     FUZZAPI_TARGET_URL: http://test-deployment/
     FUZZAPI_OVERRIDES_ENV: $TEST_API_BEARERAUTH
   ```

1. 인증이 작동하는지 확인하려면 API 퍼징 테스트를 실행하고 퍼징 로그 및 테스트 API 애플리케이션 로그를 검토하세요. 재정의 명령에 대한 자세한 내용은 [재정의 섹션](#overrides)을 참조하세요.

#### 테스트 런타임에 생성된 토큰 {#token-generated-at-test-runtime}

Bearer 토큰을 생성해야 하고 테스트 중에 만료되지 않으면 토큰이 포함된 파일을 사용하여 API 퍼징을 제공할 수 있습니다. 이전 스테이지 및 작업, 또는 API 퍼징 작업의 일부가 이 파일을 생성할 수 있습니다.

API 퍼징은 다음 구조의 JSON 파일을 받을 것으로 예상합니다:

```json
{
  "headers" : {
    "Authorization" : "Bearer dXNlcm5hbWU6cGFzc3dvcmQ="
  }
}
```

이 파일은 이전 스테이지에서 생성되어 `FUZZAPI_OVERRIDES_FILE` CI/CD 변수를 통해 API 퍼징에 제공될 수 있습니다.

`FUZZAPI_OVERRIDES_FILE`을 `.gitlab-ci.yml` 파일에 설정합니다:

```yaml
stages:
     - fuzz

include:
  - template: API-Fuzzing.gitlab-ci.yml

variables:
  FUZZAPI_PROFILE: Quick
  FUZZAPI_OPENAPI: test-api-specification.json
  FUZZAPI_TARGET_URL: http://test-deployment/
  FUZZAPI_OVERRIDES_FILE: api-fuzzing-overrides.json
```

인증이 작동하는지 확인하려면 API 퍼징 테스트를 실행하고 퍼징 로그 및 테스트 API 애플리케이션 로그를 검토하세요.

#### 토큰의 만료 기간이 짧음 {#token-has-short-expiration}

Bearer 토큰을 생성해야 하고 스캔이 완료되기 전에 만료되면 제공된 간격에서 실행할 API 퍼저에 대한 프로그램 또는 스크립트를 제공할 수 있습니다. 제공된 스크립트는 Python 3 및 Bash가 설치된 Alpine Linux 컨테이너에서 실행됩니다. Python 스크립트에 추가 패키지가 필요한 경우 이를 감지하고 런타임에 패키지를 설치해야 합니다.

스크립트는 특정 형식의 bearer 토큰이 포함된 JSON 파일을 만들어야 합니다:

```json
{
  "headers" : {
    "Authorization" : "Bearer dXNlcm5hbWU6cGFzc3dvcmQ="
  }
}
```

올바른 작동을 위해 세 개의 CI/CD 변수를 각각 제공해야 합니다:

- `FUZZAPI_OVERRIDES_FILE`:  제공된 명령이 생성하는 JSON 파일입니다.
- `FUZZAPI_OVERRIDES_CMD`:  JSON 파일을 생성하는 명령입니다.
- `FUZZAPI_OVERRIDES_INTERVAL`:  명령을 실행할 간격(초)입니다.

예를 들어:

```yaml
stages:
     - fuzz

include:
  - template: API-Fuzzing.gitlab-ci.yml

variables:
  FUZZAPI_PROFILE: Quick-10
  FUZZAPI_OPENAPI: test-api-specification.json
  FUZZAPI_TARGET_URL: http://test-deployment/
  FUZZAPI_OVERRIDES_FILE: api-fuzzing-overrides.json
  FUZZAPI_OVERRIDES_CMD: renew_token.py
  FUZZAPI_OVERRIDES_INTERVAL: 300
```

인증이 작동하는지 확인하려면 API 퍼징 테스트를 실행하고 퍼징 로그 및 테스트 API 애플리케이션 로그를 검토하세요.

## API 퍼징 프로파일 {#api-fuzzing-profiles}

GitLab은 구성 파일 [`gitlab-api-fuzzing-config.yml`](https://gitlab.com/gitlab-org/security-products/analyzers/api-fuzzing/-/blob/master/gitlab-api-fuzzing-config.yml)을 제공합니다. 여기에는 특정 수의 테스트를 수행하는 여러 테스트 프로파일이 포함되어 있습니다. 각 프로파일의 런타임은 테스트 수가 증가함에 따라 증가합니다.

| 프로파일   | 퍼징 테스트(매개변수당) |
|:----------|:---------------------------|
| Quick-10  | 10 |
| Medium-20 | 20 |
| Medium-50 | 50 |
| Long-100  | 100 |

## 재정의 {#overrides}

API 퍼징은 요청의 특정 항목을 추가하거나 재정의하는 방법을 제공합니다. 예를 들면:

- 헤더
- 쿠키
- 쿼리 문자열
- 양식 데이터
- JSON 노드
- XML 노드

이를 사용하여 의미 체계 버전 헤더, 인증 등을 주입할 수 있습니다. [인증 섹션](#authentication)에는 이 목적으로 재정의를 사용하는 예제가 포함되어 있습니다.

재정의는 각 재정의 유형이 JSON 객체로 표현되는 JSON 문서를 사용합니다:

```json
{
  "headers": {
    "header1": "value",
    "header2": "value"
  },
  "cookies": {
    "cookie1": "value",
    "cookie2": "value"
  },
  "query":      {
    "query-string1": "value",
    "query-string2": "value"
  },
  "body-form":  {
    "form-param1": "value",
    "form-param2": "value"
  },
  "body-json":  {
    "json-path1": "value",
    "json-path2": "value"
  },
  "body-xml" :  {
    "xpath1":    "value",
    "xpath2":    "value"
  }
}
```

단일 헤더를 설정하는 예:

```json
{
  "headers": {
    "Authorization": "Bearer dXNlcm5hbWU6cGFzc3dvcmQ="
  }
}
```

헤더와 쿠키를 모두 설정하는 예:

```json
{
  "headers": {
    "Authorization": "Bearer dXNlcm5hbWU6cGFzc3dvcmQ="
  },
  "cookies": {
    "flags": "677"
  }
}
```

`body-form` 재정의를 설정하는 예시:

```json
{
  "body-form":  {
    "username": "john.doe"
  }
}
```

재정의 엔진은 요청 본문에 양식 데이터 콘텐츠만 있을 때 `body-form`을 사용합니다.

`body-json` 재정의를 설정하는 예시:

```json
{
  "body-json":  {
    "$.credentials.access-token": "iddqd!42.$"
  }
}
```

`body-json` 객체의 각 JSON 속성 이름은 [JSON Path](https://goessner.net/articles/JsonPath/) 표현식으로 설정됩니다. JSON Path 표현식 `$.credentials.access-token`은 `iddqd!42.$` 값으로 재정의할 노드를 식별합니다. 재정의 엔진은 요청 본문에 [JSON](https://www.json.org/json-en.html) 콘텐츠만 있을 때 `body-json`을 사용합니다.

예를 들어 본문이 다음 JSON으로 설정된 경우:

```json
{
    "credentials" : {
        "username" :"john.doe",
        "access-token" : "non-valid-password"
    }
}
```

다음과 같이 변경됩니다:

```json
{
    "credentials" : {
        "username" :"john.doe",
        "access-token" : "iddqd!42.$"
    }
}
```

`body-xml` 재정의를 설정하는 예를 들어보겠습니다. 첫 번째 항목은 XML 특성을 재정의하고 두 번째 항목은 XML 요소를 재정의합니다:

```json
{
  "body-xml" :  {
    "/credentials/@isEnabled": "true",
    "/credentials/access-token/text()" : "iddqd!42.$"
  }
}
```

`body-xml` 객체의 각 JSON 속성 이름은 [XPath v2](https://www.w3.org/TR/xpath20/) 표현식으로 설정됩니다. XPath 표현식 `/credentials/@isEnabled`은 `true` 값으로 재정의할 특성 노드를 식별합니다. XPath 표현식 `/credentials/access-token/text()`는 `iddqd!42.$` 값으로 재정의할 요소 노드를 식별합니다. 재정의 엔진은 요청 본문에 [XML](https://www.w3.org/XML/) 콘텐츠만 있을 때 `body-xml`을 사용합니다.

예를 들어 본문이 다음 XML로 설정된 경우:

```xml
<credentials isEnabled="false">
  <username>john.doe</username>
  <access-token>non-valid-password</access-token>
</credentials>
```

다음과 같이 변경됩니다:

```xml
<credentials isEnabled="true">
  <username>john.doe</username>
  <access-token>iddqd!42.$</access-token>
</credentials>
```

이 JSON 문서를 파일 또는 환경 변수로 제공할 수 있습니다. JSON 문서를 생성하는 명령을 제공할 수도 있습니다. 명령은 만료되는 값을 지원하기 위해 간격에서 실행할 수 있습니다.

### 파일 사용 {#using-a-file}

재정의 JSON을 파일로 제공하려면 `FUZZAPI_OVERRIDES_FILE` CI/CD 변수를 설정합니다. 경로는 현재 작업 디렉토리를 기준으로 합니다.

다음은 `.gitlab-ci.yml` 예입니다:

```yaml
stages:
     - fuzz

include:
  - template: API-Fuzzing.gitlab-ci.yml

variables:
  FUZZAPI_PROFILE: Quick
  FUZZAPI_OPENAPI: test-api-specification.json
  FUZZAPI_TARGET_URL: http://test-deployment/
  FUZZAPI_OVERRIDES_FILE: api-fuzzing-overrides.json
```

### CI/CD 변수 사용 {#using-a-cicd-variable}

재정의 JSON을 CI/CD 변수로 제공하려면 `FUZZAPI_OVERRIDES_ENV` 변수를 사용합니다. 이를 통해 JSON을 마스킹하고 보호할 수 있는 변수로 배치할 수 있습니다.

이 예 `.gitlab-ci.yml`에서는 `FUZZAPI_OVERRIDES_ENV` 변수가 JSON으로 직접 설정됩니다:

```yaml
stages:
     - fuzz

include:
  - template: API-Fuzzing.gitlab-ci.yml

variables:
  FUZZAPI_PROFILE: Quick
  FUZZAPI_OPENAPI: test-api-specification.json
  FUZZAPI_TARGET_URL: http://test-deployment/
  FUZZAPI_OVERRIDES_ENV: '{"headers":{"X-API-Version":"2"}}'
```

이 예 `.gitlab-ci.yml`에서 `SECRET_OVERRIDES` 변수가 JSON을 제공합니다. 이는 [UI에서 정의된 그룹 또는 인스턴스 수준 CI/CD 변수](../../../../ci/variables/_index.md#define-a-cicd-variable-in-the-ui)입니다:

```yaml
stages:
     - fuzz

include:
  - template: API-Fuzzing.gitlab-ci.yml

variables:
  FUZZAPI_PROFILE: Quick
  FUZZAPI_OPENAPI: test-api-specification.json
  FUZZAPI_TARGET_URL: http://test-deployment/
  FUZZAPI_OVERRIDES_ENV: $SECRET_OVERRIDES
```

### 명령 사용 {#using-a-command}

값을 생성하거나 만료 시 재생성해야 하는 경우 지정된 간격에서 실행할 API 퍼저에 대한 프로그램 또는 스크립트를 제공할 수 있습니다. 제공된 스크립트는 Python 3 및 Bash가 설치된 Alpine Linux 컨테이너에서 실행됩니다.

환경 변수 `FUZZAPI_OVERRIDES_CMD`을 실행하려는 프로그램 또는 스크립트로 설정해야 합니다. 제공된 명령은 이전에 정의된 대로 재정의 JSON 파일을 만듭니다.

NodeJS 또는 Ruby와 같은 다른 스크립팅 런타임을 설치하거나 재정의 명령에 대한 종속성을 설치해야 할 수 있습니다. 이 경우 `FUZZAPI_PRE_SCRIPT`을 해당 전제 조건을 제공하는 스크립트의 파일 경로로 설정해야 합니다. `FUZZAPI_PRE_SCRIPT`로 제공된 스크립트는 분석기가 시작되기 전에 한 번 실행됩니다.

> [!note]
> 승격된 권한이 필요한 작업을 수행할 때는 `sudo` 명령을 사용합니다. 예를 들어, `sudo apk add nodejs`입니다.

Alpine Linux 패키지 설치에 대한 정보는 [Alpine Linux 패키지 관리](https://wiki.alpinelinux.org/wiki/Alpine_Linux_package_management) 페이지를 참조하세요.

올바른 작동을 위해 세 개의 CI/CD 변수를 각각 제공해야 합니다:

- `FUZZAPI_OVERRIDES_FILE`:  제공된 명령이 생성하는 파일입니다.
- `FUZZAPI_OVERRIDES_CMD`:  정기적으로 재정의 JSON 파일을 생성하는 재정의 명령입니다.
- `FUZZAPI_OVERRIDES_INTERVAL`:  명령을 실행할 간격(초)입니다.

선택 사항:

- `FUZZAPI_PRE_SCRIPT`:  분석기가 시작되기 전에 런타임 또는 종속성을 설치하는 스크립트입니다.

> [!warning]
> Alpine Linux에서 스크립트를 실행하려면 먼저 [`chmod`](https://www.gnu.org/software/coreutils/manual/html_node/chmod-invocation.html) 명령을 사용하여 [실행 권한](https://www.gnu.org/software/coreutils/manual/html_node/Setting-Permissions.html)을 설정해야 합니다. 예를 들어, 모든 사용자에 대해 `script.py`의 실행 권한을 설정하려면 명령: `sudo chmod a+x script.py`을 사용합니다. 필요한 경우 이미 실행 권한이 설정된 `script.py`의 버전을 지정할 수 있습니다.

```yaml
stages:
     - fuzz

include:
  - template: API-Fuzzing.gitlab-ci.yml

variables:
  FUZZAPI_PROFILE: Quick
  FUZZAPI_OPENAPI: test-api-specification.json
  FUZZAPI_TARGET_URL: http://test-deployment/
  FUZZAPI_OVERRIDES_FILE: api-fuzzing-overrides.json
  FUZZAPI_OVERRIDES_CMD: renew_token.py
  FUZZAPI_OVERRIDES_INTERVAL: 300
```

### 재정의 디버깅 {#debugging-overrides}

기본적으로 재정의 명령의 출력은 숨겨집니다. 재정의 명령이 0이 아닌 종료 코드를 반환하면 명령이 작업 출력의 일부로 표시됩니다. 선택적으로 변수 `FUZZAPI_OVERRIDES_CMD_VERBOSE`을 임의의 값으로 설정하여 재정의 명령 출력을 생성되는 대로 표시할 수 있습니다. 이는 재정의 스크립트를 테스트할 때 유용하지만 테스트 속도를 저하시키므로 나중에 비활성화해야 합니다.

또한 작업이 완료되거나 실패할 때 수집되는 로그 파일에 스크립트에서 메시지를 작성할 수도 있습니다. 로그 파일은 특정 위치에 생성되어야 하고 명명 규칙을 따라야 합니다.

재정의 스크립트에 기본 로깅을 추가하면 작업의 일반적인 실행 중에 스크립트가 예기치 않게 실패하는 경우에 유용합니다. 로그 파일은 자동으로 작업의 결과물에 포함되므로 작업이 완료된 후에 다운로드할 수 있습니다.

이 예에 따라 환경 변수 `FUZZAPI_OVERRIDES_CMD`에 `renew_token.py`을 제공했습니다. 스크립트에서 두 가지 사항을 주목하세요:

- 로그 파일은 환경 변수 `CI_PROJECT_DIR`로 표시된 위치에 저장됩니다.
- 로그 파일 이름은 `gl-*.log`과 일치해야 합니다.

```python
#!/usr/bin/env python

# Example of an overrides command

# Override commands can update the overrides json file
# with new values to be used.  This is a great way to
# update an authentication token that will expire
# during testing.

import logging
import json
import os
import requests
import backoff

# [1] Store log file in directory indicated by env var CI_PROJECT_DIR
working_directory = os.environ.get( 'CI_PROJECT_DIR')
overrides_file_name = os.environ.get('FUZZAPI_OVERRIDES_FILE', 'api-fuzzing-overrides.json')
overrides_file_path = os.path.join(working_directory, overrides_file_name)

# [2] File name should match the pattern: gl-*.log
log_file_path = os.path.join(working_directory, 'gl-user-overrides.log')

# Set up logger
logging.basicConfig(filename=log_file_path, level=logging.DEBUG)

# Use `backoff` decorator to retry in case of transient errors.
@backoff.on_exception(backoff.expo,
                      (requests.exceptions.Timeout,
                       requests.exceptions.ConnectionError),
                       max_time=30)
def get_auth_response():
    authorization_url = 'https://authorization.service/api/get_api_token'
    return requests.get(
        f'{authorization_url}',
        auth=(os.environ.get('AUTH_USER'), os.environ.get('AUTH_PWD'))
    )

# In our example, access token is retrieved from a given endpoint
try:

    # Performs a http request, response sample:
    # { "Token" : "abcdefghijklmn" }
    response = get_auth_response()

    # Check that the request is successful. may raise `requests.exceptions.HTTPError`
    response.raise_for_status()

    # Gets JSON data
    response_body = response.json()

# If needed specific exceptions can be caught
# requests.ConnectionError                  : A network connection error problem occurred
# requests.HTTPError                        : HTTP request returned an unsuccessful status code. [Response.raise_for_status()]
# requests.ConnectTimeout                   : The request timed out while trying to connect to the remote server
# requests.ReadTimeout                      : The server did not send any data in the allotted amount of time.
# requests.TooManyRedirects                 : The request exceeds the configured number of maximum redirections
# requests.exceptions.RequestException      : All exceptions that related to Requests
except json.JSONDecodeError as json_decode_error:
    # logs errors related decoding JSON response
    logging.error(f'Error, failed while decoding JSON response. Error message: {json_decode_error}')
    raise
except requests.exceptions.RequestException as requests_error:
    # logs  exceptions  related to `Requests`
    logging.error(f'Error, failed while performing HTTP request. Error message: {requests_error}')
    raise
except Exception as e:
    # logs any other error
    logging.error(f'Error, unknown error while retrieving access token. Error message: {e}')
    raise

# computes object that holds overrides file content.
# It uses data fetched from request
overrides_data = {
    "headers": {
        "Authorization": f"Token {response_body['Token']}"
    }
}

# log entry informing about the file override computation
logging.info("Creating overrides file: %s" % overrides_file_path)

# attempts to overwrite the file
try:
    if os.path.exists(overrides_file_path):
        os.unlink(overrides_file_path)

    # overwrites the file with our updated dictionary
    with open(overrides_file_path, "wb+") as fd:
        fd.write(json.dumps(overrides_data).encode('utf-8'))
except Exception as e:
    # logs any other error
    logging.error(f'Error, unknown error when overwriting file {overrides_file_path}. Error message: {e}')
    raise

# logs informing override has finished successfully
logging.info("Override file has been updated")

# end
```

이 재정의 명령 예에서 Python 스크립트는 `backoff` 라이브러리에 따라 다릅니다. Python 스크립트를 실행하기 전에 라이브러리가 설치되었는지 확인하려면 `FUZZAPI_PRE_SCRIPT`을 재정의 명령의 종속성을 설치하는 스크립트로 설정합니다. 예를 들어, 다음 스크립트 `user-pre-scan-set-up.sh`:

```shell
#!/bin/bash

# user-pre-scan-set-up.sh
# Ensures python dependencies are installed

echo "**** install python dependencies ****"

sudo pip3 install --no-cache --upgrade --break-system-packages \
    requests \
    backoff

echo "**** python dependencies installed ****"

# end
```

`FUZZAPI_PRE_SCRIPT`을 새 `user-pre-scan-set-up.sh` 스크립트로 설정하려면 구성을 업데이트해야 합니다. 예를 들어:

```yaml
stages:
     - fuzz

include:
  - template: API-Fuzzing.gitlab-ci.yml

variables:
  FUZZAPI_PROFILE: Quick
  FUZZAPI_OPENAPI: test-api-specification.json
  FUZZAPI_TARGET_URL: http://test-deployment/
  FUZZAPI_PRE_SCRIPT: user-pre-scan-set-up.sh
  FUZZAPI_OVERRIDES_FILE: api-fuzzing-overrides.json
  FUZZAPI_OVERRIDES_CMD: renew_token.py
  FUZZAPI_OVERRIDES_INTERVAL: 300
```

이전 샘플에서는 `user-pre-scan-set-up.sh` 스크립트를 사용하여 나중에 재정의 명령에서 사용할 수 있는 새로운 런타임 또는 애플리케이션을 설치할 수도 있습니다.

## 경로 제외 {#exclude-paths}

API를 테스트할 때 특정 경로를 제외하면 도움이 될 수 있습니다. 예를 들어 인증 서비스 또는 이전 버전의 API에 대한 테스트를 제외할 수 있습니다. 경로를 제외하려면 `FUZZAPI_EXCLUDE_PATHS` CI/CD 변수를 사용합니다. 이 변수는 `.gitlab-ci.yml` 파일에 지정됩니다. 여러 경로를 제외하려면 `;` 문자를 사용하여 항목을 구분합니다. 제공된 경로에서 단일 문자 와일드카드 `?` 및 `*`를 여러 문자 와일드카드로 사용할 수 있습니다.

경로가 제외되었는지 확인하려면 작업 출력의 `Tested Operations` 및 `Excluded Operations` 부분을 검토합니다. `Tested Operations` 아래에 제외된 경로가 나열되지 않아야 합니다.

```plaintext
2021-05-27 21:51:08 [INF] API Fuzzing: --[ Tested Operations ]-------------------------
2021-05-27 21:51:08 [INF] API Fuzzing: 201 POST http://target:7777/api/users CREATED
2021-05-27 21:51:08 [INF] API Fuzzing: ------------------------------------------------
2021-05-27 21:51:08 [INF] API Fuzzing: --[ Excluded Operations ]-----------------------
2021-05-27 21:51:08 [INF] API Fuzzing: GET http://target:7777/api/messages
2021-05-27 21:51:08 [INF] API Fuzzing: POST http://target:7777/api/messages
2021-05-27 21:51:08 [INF] API Fuzzing: ------------------------------------------------
```

### 경로 제외 예 {#examples-of-excluding-paths}

이 예는 `/auth` 리소스를 제외합니다. 이는 자식 리소스(`/auth/child`)를 제외하지 않습니다.

```yaml
variables:
  FUZZAPI_EXCLUDE_PATHS: /auth
```

`/auth` 및 자식 리소스(`/auth/child`)를 제외하려면 와일드카드를 사용합니다:

```yaml
variables:
  FUZZAPI_EXCLUDE_PATHS: /auth*
```

여러 경로를 제외하려면 `;` 문자를 사용하여 경로를 구분합니다. 이 예는 `/auth*` 및 `/v1/*`을 제외하여 이를 수행하는 방법을 보여줍니다.

```yaml
variables:
  FUZZAPI_EXCLUDE_PATHS: /auth*;/v1/*
```

## 매개변수 제외 {#exclude-parameters}

API를 테스트할 때 테스트에서 매개변수(쿼리 문자열, 헤더 또는 본문 요소)를 제외하려고 할 수 있습니다. 매개변수가 항상 실패를 유발하거나 테스트를 느리게 하거나 기타 이유로 인해 필요할 수 있습니다. 매개변수를 제외하려면 다음 변수 중 하나를 사용할 수 있습니다: `FUZZAPI_EXCLUDE_PARAMETER_ENV` 또는 `FUZZAPI_EXCLUDE_PARAMETER_FILE`.

`FUZZAPI_EXCLUDE_PARAMETER_ENV`을 사용하면 제외된 매개변수를 포함하는 JSON 문자열을 제공할 수 있습니다. JSON이 짧고 자주 변경되지 않으면 좋은 옵션입니다. 또 다른 옵션은 변수 `FUZZAPI_EXCLUDE_PARAMETER_FILE`입니다. 이 변수는 리포지토리에 체크 인할 수 있는 파일 경로, 다른 작업의 결과물로 생성되거나 `FUZZAPI_PRE_SCRIPT`을 사용하여 사전 스크립트에서 런타임에 생성될 수 있습니다.

### JSON 문서를 사용하여 매개변수 제외 {#exclude-parameters-using-a-json-document}

JSON 문서에는 제외할 매개변수를 식별하기 위해 특정 속성을 사용하는 JSON 객체가 포함됩니다. 스캔 프로세스 중에 특정 매개변수를 제외하기 위해 다음 속성을 제공할 수 있습니다:

- `headers`:  이 속성을 사용하여 특정 헤더를 제외합니다. 속성 값은 제외할 헤더 이름의 배열입니다. 이름은 대소문자를 구분하지 않습니다.
- `cookies`:  이 속성 값을 사용하여 특정 쿠키를 제외합니다. 속성 값은 제외할 쿠키 이름의 배열입니다. 이름은 대소문자를 구분합니다.
- `query`:  이 속성을 사용하여 쿼리 문자열에서 특정 필드를 제외합니다. 속성 값은 제외할 쿼리 문자열의 필드 이름 배열입니다. 이름은 대소문자를 구분합니다.
- `body-form`:  이 속성을 사용하여 미디어 유형 `application/x-www-form-urlencoded`을 사용하는 요청에서 특정 필드를 제외합니다. 속성 값은 본문에서 제외할 필드 이름의 배열입니다. 이름은 대소문자를 구분합니다.
- `body-json`:  이 속성을 사용하여 미디어 유형 `application/json`을 사용하는 요청에서 특정 JSON 노드를 제외합니다. 속성 값은 배열이며, 배열의 각 항목은 [JSON Path](https://goessner.net/articles/JsonPath/) 표현식입니다.
- `body-xml`:  이 속성을 사용하여 미디어 유형 `application/xml`을 사용하는 요청에서 특정 XML 노드를 제외합니다. 속성 값은 배열이며, 배열의 각 항목은 [XPath v2](https://www.w3.org/TR/xpath20/) 표현식입니다.

다음 JSON 문서는 매개변수를 제외하기 위한 예상 구조의 예입니다.

```json
{
  "headers": [
    "header1",
    "header2"
  ],
  "cookies": [
    "cookie1",
    "cookie2"
  ],
  "query": [
    "query-string1",
    "query-string2"
  ],
  "body-form": [
    "form-param1",
    "form-param2"
  ],
  "body-json": [
    "json-path-expression-1",
    "json-path-expression-2"
  ],
  "body-xml" : [
    "xpath-expression-1",
    "xpath-expression-2"
  ]
}
```

### 예제 {#examples}

#### 단일 헤더 제외 {#excluding-a-single-header}

헤더 `Upgrade-Insecure-Requests`을 제외하려면 `header` 속성의 값을 헤더 이름 배열로 설정합니다: `[ "Upgrade-Insecure-Requests" ]`. 예를 들어 JSON 문서는 다음과 같습니다:

```json
{
  "headers": [ "Upgrade-Insecure-Requests" ]
}
```

헤더 이름은 대소문자를 구분하지 않으므로 헤더 이름 `UPGRADE-INSECURE-REQUESTS`은 `Upgrade-Insecure-Requests`와 동일합니다.

#### 헤더와 두 개의 쿠키 모두 제외 {#excluding-both-a-header-and-two-cookies}

헤더 `Authorization` 및 쿠키 `PHPSESSID` 및 `csrftoken`을 제외하려면 `headers` 속성의 값을 헤더 이름 `[ "Authorization" ]`인 배열로 설정하고 `cookies` 속성의 값을 쿠키 이름 `[ "PHPSESSID", "csrftoken" ]`인 배열로 설정합니다. 예를 들어 JSON 문서는 다음과 같습니다:

```json
{
  "headers": [ "Authorization" ],
  "cookies": [ "PHPSESSID", "csrftoken" ]
}
```

#### `body-form` 매개변수 제외 {#excluding-a-body-form-parameter}

`application/x-www-form-urlencoded`을 사용하는 요청에서 `password` 필드를 제외하려면 `body-form` 속성의 값을 필드 이름 `[ "password" ]`인 배열로 설정합니다. 예를 들어 JSON 문서는 다음과 같습니다:

```json
{
  "body-form":  [ "password" ]
}
```

제외 매개변수는 요청이 콘텐츠 유형 `application/x-www-form-urlencoded`을 사용할 때 `body-form`을 사용합니다.

#### JSON Path를 사용하여 특정 JSON 노드 제외 {#excluding-a-specific-json-nodes-using-json-path}

루트 객체에서 `schema` 속성을 제외하려면 `body-json` 속성의 값을 JSON Path 표현식 `[ "$.schema" ]`인 배열로 설정합니다.

JSON Path 표현식은 JSON 노드를 식별하기 위해 특수 구문을 사용합니다: `$`은 JSON 문서의 루트를 참조하고, `.`는 현재 객체(우리의 경우 루트 객체)를 참조하며, 텍스트 `schema`은 속성 이름을 참조합니다. 따라서 JSON 경로 표현식 `$.schema`는 루트 객체의 속성 `schema`을 참조합니다. 예를 들어 JSON 문서는 다음과 같습니다:

```json
{
  "body-json": [ "$.schema" ]
}
```

제외 매개변수는 요청이 콘텐츠 유형 `application/json`을 사용할 때 `body-json`을 사용합니다. `body-json`의 각 항목은 [JSON Path 표현식](https://goessner.net/articles/JsonPath/)으로 예상됩니다. JSON Path에서 `$`, `*`, `.` 등의 문자는 특별한 의미를 갖습니다.

#### JSON Path를 사용하여 여러 JSON 노드 제외 {#excluding-multiple-json-nodes-using-json-path}

루트 수준의 `users` 배열 항목 각각에서 `password` 속성을 제외하려면 `body-json` 속성의 값을 JSON Path 표현식 `[ "$.users[*].paswword" ]`인 배열로 설정합니다.

JSON Path 표현식은 `$`로 시작하여 루트 노드를 참조하고 `.`를 사용하여 현재 노드를 참조합니다. 다음으로 `users`을 사용하여 속성을 참조합니다. 문자 `[` 및 `]`는 사용하려는 배열 인덱스를 포함합니다. `*`을 사용하여 특정 번호를 제공하는 대신 모든 인덱스를 지정할 수 있습니다. 인덱스 참조 후 `.` 문자는 배열의 선택된 인덱스를 참조하고 속성 이름 `password`이 뒤따릅니다.

예를 들어 JSON 문서는 다음과 같습니다:

```json
{
  "body-json": [ "$.users[*].password" ]
}
```

제외 매개변수는 요청이 콘텐츠 유형 `application/json`을 사용할 때 `body-json`을 사용합니다. `body-json`의 각 항목은 [JSON Path 표현식](https://goessner.net/articles/JsonPath/)으로 예상됩니다. JSON Path에서 `$`, `*`, `.` 등의 문자는 특별한 의미를 갖습니다.

#### XML 특성 제외 {#excluding-an-xml-attribute}

`credentials` 루트 요소에 위치한 `isEnabled`이라는 특성을 제외하려면 `body-xml` 속성의 값을 XPath 표현식 `[ "/credentials/@isEnabled" ]`인 배열로 설정합니다.

XPath 표현식 `/credentials/@isEnabled`는 `/`로 시작하여 XML 문서의 루트를 나타내고, 그 뒤에는 일치시킬 요소의 이름을 나타내는 단어 `credentials`이 옵니다. `/`를 사용하여 이전 XML 요소의 노드를 참조하고 `@` 문자를 사용하여 이름 `isEnable`이 특성임을 나타냅니다.

예를 들어 JSON 문서는 다음과 같습니다:

```json
{
  "body-xml": [
    "/credentials/@isEnabled"
  ]
}
```

제외 매개변수는 요청이 콘텐츠 유형 `application/xml`을 사용할 때 `body-xml`을 사용합니다. `body-xml`의 각 항목은 [XPath v2 표현식](https://www.w3.org/TR/xpath20/)으로 예상됩니다. XPath 표현식에서 `@`, `/`, `:`, `[`, `]` 등의 문자는 특별한 의미를 갖습니다.

#### XML 요소 텍스트 제외 {#excluding-an-xml-elements-text}

루트 노드 `credentials`에 포함된 `username` 요소의 텍스트를 제외하려면 `body-xml` 속성의 값을 XPath 표현식 `[/credentials/username/text()" ]`인 배열로 설정합니다.

XPath 표현식 `/credentials/username/text()`에서 첫 문자 `/`은 루트 XML 노드를 참조하고, 그 뒤에는 XML 요소 이름 `credentials`을 나타냅니다. 마찬가지로 문자 `/`는 현재 요소를 참조하고 새 XML 요소 이름 `username`이 뒤따릅니다. 마지막 부분에는 현재 요소를 참조하는 `/`이 있으며, `text()` XPath 함수를 사용합니다. 이는 현재 요소의 텍스트를 식별합니다.

예를 들어 JSON 문서는 다음과 같습니다:

```json
{
  "body-xml": [
    "/credentials/username/text()"
  ]
}
```

제외 매개변수는 요청이 콘텐츠 유형 `application/xml`을 사용할 때 `body-xml`을 사용합니다. `body-xml`의 각 항목은 [XPath v2 표현식](https://www.w3.org/TR/xpath20/)으로 예상됩니다. XPath 표현식에서 `@`, `/`, `:`, `[`, `]` 등의 문자는 특별한 의미를 갖습니다.

#### XML 요소 제외 {#excluding-an-xml-element}

루트 노드 `credentials`에 포함된 `username` 요소를 제외하려면 `body-xml` 속성의 값을 XPath 표현식 `[/credentials/username" ]`인 배열로 설정합니다.

XPath 표현식 `/credentials/username`에서 첫 문자 `/`은 루트 XML 노드를 참조하고, 그 뒤에는 XML 요소 이름 `credentials`을 나타냅니다. 마찬가지로 문자 `/`는 현재 요소를 참조하고 새 XML 요소 이름 `username`이 뒤따릅니다.

예를 들어 JSON 문서는 다음과 같습니다:

```json
{
  "body-xml": [
    "/credentials/username"
  ]
}
```

제외 매개변수는 요청이 콘텐츠 유형 `application/xml`을 사용할 때 `body-xml`을 사용합니다. `body-xml`의 각 항목은 [XPath v2 표현식](https://www.w3.org/TR/xpath20/)으로 예상됩니다. XPath 표현식에서 `@`, `/`, `:`, `[`, `]` 등의 문자는 특별한 의미를 갖습니다.

#### 네임스페이스가 있는 XML 노드 제외 {#excluding-an-xml-node-with-namespaces}

`credentials` 루트 노드에 포함되고 `s` 네임스페이스에서 정의된 XML 요소 `login`을 제외하려면 `body-xml` 속성의 값을 XPath 표현식 `[ "/credentials/s:login" ]`인 배열로 설정합니다.

XPath 표현식 `/credentials/s:login`에서 첫 문자 `/`은 루트 XML 노드를 참조하고, 그 뒤에는 XML 요소 이름 `credentials`을 나타냅니다. 마찬가지로 문자 `/`는 현재 요소를 참조하고 새 XML 요소 이름 `s:login`이 뒤따릅니다. 이름에 문자 `:`이 포함되어 있습니다. 이 문자는 네임스페이스를 노드 이름에서 분리합니다.

네임스페이스 이름은 요청 본문의 일부인 XML 문서에서 정의되었어야 합니다. HAR, OpenAPI 또는 Postman Collection 파일의 사양 문서에서 네임스페이스를 확인할 수 있습니다.

```json
{
  "body-xml": [
    "/credentials/s:login"
  ]
}
```

제외 매개변수는 요청이 콘텐츠 유형 `application/xml`을 사용할 때 `body-xml`을 사용합니다. `body-xml`의 각 항목은 [XPath v2 표현식](https://www.w3.org/TR/xpath20/)으로 예상됩니다. XPath 표현식에서 `@`, `/`, `:`, `[`, `]` 등의 문자는 특별한 의미를 갖습니다.

### JSON 문자열 사용 {#using-a-json-string}

제외 JSON 문서를 설정하려면 변수 `FUZZAPI_EXCLUDE_PARAMETER_ENV`을 JSON 문자열로 설정합니다. 다음 예에서 `.gitlab-ci.yml`, `FUZZAPI_EXCLUDE_PARAMETER_ENV` 변수는 JSON 문자열로 설정됩니다:

```yaml
stages:
     - fuzz

include:
  - template: API-Fuzzing.gitlab-ci.yml

variables:
  FUZZAPI_PROFILE: Quick
  FUZZAPI_OPENAPI: test-api-specification.json
  FUZZAPI_TARGET_URL: http://test-deployment/
  FUZZAPI_EXCLUDE_PARAMETER_ENV: '{ "headers": [ "Upgrade-Insecure-Requests" ] }'
```

### 파일 사용 {#using-a-file-1}

제외 JSON 문서를 제공하려면 변수 `FUZZAPI_EXCLUDE_PARAMETER_FILE`을 JSON 파일 경로로 설정합니다. 파일 경로는 현재 작업 디렉토리를 기준으로 합니다. 다음 예 `.gitlab-ci.yml` 파일에서 `FUZZAPI_EXCLUDE_PARAMETER_FILE` 변수는 JSON 파일 경로로 설정됩니다:

```yaml
stages:
     - fuzz

include:
  - template: API-Fuzzing.gitlab-ci.yml

variables:
  FUZZAPI_PROFILE: Quick
  FUZZAPI_OPENAPI: test-api-specification.json
  FUZZAPI_TARGET_URL: http://test-deployment/
  FUZZAPI_EXCLUDE_PARAMETER_FILE: api-fuzzing-exclude-parameters.json
```

`api-fuzzing-exclude-parameters.json`은 [매개변수 문서 제외](#exclude-parameters-using-a-json-document)의 구조를 따르는 JSON 문서입니다.

## URL 제외 {#exclude-urls}

경로별로 제외하는 대신 `FUZZAPI_EXCLUDE_URLS` CI/CD 변수를 사용하여 URL의 다른 구성 요소로 필터링할 수 있습니다. 이 변수는 `.gitlab-ci.yml` 파일에 설정할 수 있습니다. 변수는 쉼표(`,`)로 구분된 여러 값을 저장할 수 있습니다. 각 값은 정규 표현식입니다. 각 항목이 정규 표현식이기 때문에 `.*` 같은 항목은 모든 항목과 일치하는 정규 표현식이므로 모든 URL을 제외합니다.

작업 출력에서 `FUZZAPI_EXCLUDE_URLS`에서 제공한 정규 표현식과 일치하는 URL이 있는지 확인할 수 있습니다. 일치하는 작업은 **Excluded Operations** 섹션에 나열됩니다. **Excluded Operations**에 나열된 작업은 **Tested Operations** 섹션에 나열되지 않아야 합니다. 예를 들어 작업 출력의 다음 부분을 참조하세요:

```plaintext
2021-05-27 21:51:08 [INF] API Fuzzing: --[ Tested Operations ]-------------------------
2021-05-27 21:51:08 [INF] API Fuzzing: 201 POST http://target:7777/api/users CREATED
2021-05-27 21:51:08 [INF] API Fuzzing: ------------------------------------------------
2021-05-27 21:51:08 [INF] API Fuzzing: --[ Excluded Operations ]-----------------------
2021-05-27 21:51:08 [INF] API Fuzzing: GET http://target:7777/api/messages
2021-05-27 21:51:08 [INF] API Fuzzing: POST http://target:7777/api/messages
2021-05-27 21:51:08 [INF] API Fuzzing: ------------------------------------------------
```

> [!note]
> `FUZZAPI_EXCLUDE_URLS`의 각 값은 정규 표현식입니다. `.` , `*` 및 `$` 등의 문자는 [정규 표현식](https://en.wikipedia.org/wiki/Regular_expression#Standards)에서 특별한 의미를 갖습니다.

### 예제 {#examples-1}

#### URL 및 자식 리소스 제외 {#excluding-a-url-and-child-resources}

다음 예는 URL `http://target/api/auth` 및 해당 자식 리소스를 제외합니다.

```yaml
stages:
  - fuzz

include:
  - template: API-Fuzzing.gitlab-ci.yml

variables:
  FUZZAPI_TARGET_URL: http://target/
  FUZZAPI_OPENAPI: test-api-specification.json
  FUZZAPI_EXCLUDE_URLS: http://target/api/auth
```

#### 두 개의 URL을 제외하고 자식 리소스 허용 {#excluding-two-urls-and-allow-their-child-resources}

URL `http://target/api/buy` 및 `http://target/api/sell`을 제외하되 자식 리소스는 스캔할 수 있도록 하려면 예: `http://target/api/buy/toy` 또는 `http://target/api/sell/chair`. 값 `http://target/api/buy/$,http://target/api/sell/$`을 사용할 수 있습니다. 이 값은 두 개의 정규 표현식을 사용하고 있으며 각각 `,` 문자로 구분됩니다. 따라서 `http://target/api/buy$` 및 `http://target/api/sell$`을 포함합니다. 각 정규 표현식에서 뒤따르는 `$` 문자는 일치하는 URL이 끝나야 하는 위치를 나타냅니다.

```yaml
stages:
  - fuzz

include:
  - template: API-Fuzzing.gitlab-ci.yml

variables:
  FUZZAPI_TARGET_URL: http://target/
  FUZZAPI_OPENAPI: test-api-specification.json
  FUZZAPI_EXCLUDE_URLS: http://target/api/buy/$,http://target/api/sell/$
```

#### 두 개의 URL 및 자식 리소스 제외 {#excluding-two-urls-and-their-child-resources}

URL `http://target/api/buy` 및 `http://target/api/sell`를 제외하고 자식 리소스를 포함합니다. 여러 URL을 제공하려면 `,` 문자를 다음과 같이 사용합니다:

```yaml
stages:
  - fuzz

include:
  - template: API-Fuzzing.gitlab-ci.yml

variables:
  FUZZAPI_TARGET_URL: http://target/
  FUZZAPI_OPENAPI: test-api-specification.json
  FUZZAPI_EXCLUDE_URLS: http://target/api/buy,http://target/api/sell
```

#### 정규 표현식을 사용하여 URL 제외 {#excluding-url-using-regular-expressions}

정확히 `https://target/api/v1/user/create` 및 `https://target/api/v2/user/create` 또는 다른 버전(`v3`,`v4` 등)을 제외하려면 `https://target/api/v.*/user/create$`을 사용할 수 있습니다. 이전 정규 표현식에서:

- `.`은 모든 문자를 나타냅니다.
- `*`은 0회 이상을 나타냅니다.
- `$`은 URL이 여기서 끝나야 함을 나타냅니다.

```yaml
stages:
  - fuzz

include:
  - template: API-Fuzzing.gitlab-ci.yml

variables:
  FUZZAPI_TARGET_URL: http://target/
  FUZZAPI_OPENAPI: test-api-specification.json
  FUZZAPI_EXCLUDE_URLS: https://target/api/v.*/user/create$
```

## 헤더 퍼징 {#header-fuzzing}

헤더 퍼징은 많은 기술 스택에서 발생하는 많은 수의 거짓 양성 때문에 기본적으로 비활성화됩니다. 헤더 퍼징이 활성화되면 퍼징에 포함할 헤더 목록을 지정해야 합니다.

기본 구성 파일의 각 프로파일에는 `GeneralFuzzingCheck`에 대한 항목이 있습니다. 이 확인은 헤더 퍼징을 수행합니다. `Configuration` 섹션에서 헤더 퍼징을 활성화하려면 `HeaderFuzzing` 및 `Headers` 설정을 변경해야 합니다.

이 스니펫은 헤더 퍼징이 비활성화된 `Quick-10` 프로파일의 기본 구성을 보여줍니다:

```yaml
- Name: Quick-10
  DefaultProfile: Empty
  Routes:
  - Route: *Route0
    Checks:
    - Name: FormBodyFuzzingCheck
      Configuration:
        FuzzingCount: 10
        UnicodeFuzzing: true
    - Name: GeneralFuzzingCheck
      Configuration:
        FuzzingCount: 10
        UnicodeFuzzing: true
        HeaderFuzzing: false
        Headers:
    - Name: JsonFuzzingCheck
      Configuration:
        FuzzingCount: 10
        UnicodeFuzzing: true
    - Name: XmlFuzzingCheck
      Configuration:
        FuzzingCount: 10
        UnicodeFuzzing: true
```

`HeaderFuzzing`은 헤더 퍼징을 켜고 끄는 부울입니다. 기본 설정은 `false` 입니다(꺼짐). 헤더 퍼징을 켜려면 이 설정을 `true`로 변경합니다:

```yaml
    - Name: GeneralFuzzingCheck
      Configuration:
        FuzzingCount: 10
        UnicodeFuzzing: true
        HeaderFuzzing: true
        Headers:
```

`Headers`은 퍼징할 헤더 목록입니다. 나열된 헤더만 퍼징됩니다. API에서 사용하는 헤더를 퍼징하려면 구문 `- Name: HeaderName`을 사용하여 항목을 추가합니다. 예를 들어, 사용자 정의 헤더 `X-Custom`을 퍼징하려면 `- Name: X-Custom`을 추가합니다:

```yaml
    - Name: GeneralFuzzingCheck
      Configuration:
        FuzzingCount: 10
        UnicodeFuzzing: true
        HeaderFuzzing: true
        Headers:
          - Name: X-Custom
```

이제 헤더 `X-Custom`을 퍼징하기 위한 구성이 있습니다. 동일한 표기법을 사용하여 추가 헤더를 나열합니다:

```yaml
    - Name: GeneralFuzzingCheck
      Configuration:
        FuzzingCount: 10
        UnicodeFuzzing: true
        HeaderFuzzing: true
        Headers:
          - Name: X-Custom
          - Name: X-AnotherHeader
```

필요에 따라 각 프로파일에 대해 이 구성을 반복합니다.
