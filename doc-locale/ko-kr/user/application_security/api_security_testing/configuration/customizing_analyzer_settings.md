---
stage: Application Security Testing
group: Dynamic Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 분석기 설정 사용자 정의
---

## 인증 {#authentication}

인증은 헤더 또는 쿠키로 인증 토큰을 제공하여 처리합니다. 인증 플로우를 수행하거나 토큰을 계산하는 스크립트를 제공할 수 있습니다.

### HTTP 기본 인증 {#http-basic-authentication}

[HTTP 기본 인증](https://en.wikipedia.org/wiki/Basic_access_authentication) 은 HTTP 프로토콜에 내장된 인증 방법이며 [전송 계층 보안(TLS)](https://en.wikipedia.org/wiki/Transport_Layer_Security)과 함께 사용됩니다.

비밀번호용 [CI/CD 변수](../../../../ci/variables/_index.md#for-a-project)를 생성합니다(예: `TEST_API_PASSWORD`). 그리고 마스킹되도록 설정합니다. GitLab 프로젝트 페이지의 **설정** > **CI/CD**의 **변수** 섹션에서 CI/CD 변수를 생성할 수 있습니다. [마스킹된 변수의 제한](../../../../ci/variables/_index.md#mask-a-cicd-variable)으로 인해, 변수로 추가하기 전에 비밀번호를 Base64로 인코딩해야 합니다.

마지막으로 `.gitlab-ci.yml` 파일에 두 개의 CI/CD 변수를 추가합니다:

- `APISEC_HTTP_USERNAME`:  인증을 위한 사용자 이름입니다.
- `APISEC_HTTP_PASSWORD_BASE64`:  인증을 위한 Base64로 인코딩된 비밀번호입니다.

```yaml
stages:
  - dast

include:
  - template: API-Security.gitlab-ci.yml

variables:
  APISEC_PROFILE: Quick
  APISEC_HAR: test-api-recording.har
  APISEC_TARGET_URL: http://test-deployment/
  APISEC_HTTP_USERNAME: testuser
  APISEC_HTTP_PASSWORD_BASE64: $TEST_API_PASSWORD
```

#### 원본 비밀번호 {#raw-password}

비밀번호를 Base64로 인코딩하지 않으려는 경우(또는 GitLab 15.3 이전 버전을 사용 중인 경우) `APISEC_HTTP_PASSWORD` 원본 비밀번호를 제공할 수 있습니다. `APISEC_HTTP_PASSWORD_BASE64` 대신에 사용합니다.

### Bearer 토큰 {#bearer-tokens}

Bearer 토큰은 OAuth2 및 JSON 웹 토큰(JWT)을 포함한 여러 가지 인증 메커니즘에서 사용됩니다. Bearer 토큰은 `Authorization` HTTP 헤더를 사용하여 전송됩니다. API 보안 테스트에서 Bearer 토큰을 사용하려면 다음 중 하나가 필요합니다:

- 만료되지 않는 토큰입니다.
- 테스트 기간 동안 지속되는 토큰을 생성하는 방법입니다.
- API 보안 테스트가 호출하여 토큰을 생성할 수 있는 Python 스크립트입니다.

#### 토큰이 만료되지 않음 {#token-doesnt-expire}

Bearer 토큰이 만료되지 않으면 `APISEC_OVERRIDES_ENV` 변수를 사용하여 제공합니다. 이 변수의 콘텐츠는 API 보안 테스트를 위한 아웃바운드 HTTP 요청에 추가할 헤더 및 쿠키를 제공하는 JSON 스니펫입니다.

`APISEC_OVERRIDES_ENV`를 사용하여 Bearer 토큰을 제공하려면 다음 단계를 따르세요:

1. [CI/CD 변수를 생성하세요](../../../../ci/variables/_index.md#for-a-project). 예를 들어 `TEST_API_BEARERAUTH`에서 값 `{"headers":{"Authorization":"Bearer dXNlcm5hbWU6cGFzc3dvcmQ="}}`(토큰을 대체하세요)으로 설정합니다. GitLab 프로젝트 페이지의 **설정** > **CI/CD**의 **변수** 섹션에서 CI/CD 변수를 생성할 수 있습니다. `TEST_API_BEARERAUTH`의 형식 때문에 변수를 마스킹할 수 없습니다. 토큰의 값을 마스킹하려면 토큰 값으로 두 번째 변수를 생성하고 `TEST_API_BEARERAUTH`을 값 `{"headers":{"Authorization":"Bearer $MASKED_VARIABLE"}}`으로 정의할 수 있습니다.
1. `.gitlab-ci.yml` 파일에서 `APISEC_OVERRIDES_ENV`를 방금 생성한 변수로 설정합니다:

   ```yaml
   stages:
     - dast

   include:
     - template: API-Security.gitlab-ci.yml

   variables:
     APISEC_PROFILE: Quick
     APISEC_OPENAPI: test-api-specification.json
     APISEC_TARGET_URL: http://test-deployment/
     APISEC_OVERRIDES_ENV: $TEST_API_BEARERAUTH
   ```

1. 인증이 작동하는지 확인하려면 API 보안 테스트를 실행하고 작업 로그와 테스트 API 애플리케이션 로그를 검토합니다.

#### 테스트 런타임에 생성된 토큰 {#token-generated-at-test-runtime}

Bearer 토큰을 생성해야 하고 테스트 중에 만료되지 않으면 토큰이 있는 파일을 API 보안 테스트에 제공할 수 있습니다. 이전 스테이지 및 작업이거나 API 보안 테스트 작업의 일부에서 이 파일을 생성할 수 있습니다.

API 보안 테스트는 다음 구조로 JSON 파일을 받을 것으로 예상합니다:

```json
{
  "headers" : {
    "Authorization" : "Bearer dXNlcm5hbWU6cGFzc3dvcmQ="
  }
}
```

이 파일은 이전 스테이지에서 생성할 수 있으며 `APISEC_OVERRIDES_FILE` CI/CD 변수를 통해 API 보안 테스트에 제공합니다.

`APISEC_OVERRIDES_FILE`를 `.gitlab-ci.yml` 파일에 설정합니다:

```yaml
stages:
  - dast

include:
  - template: API-Security.gitlab-ci.yml

variables:
  APISEC_PROFILE: Quick
  APISEC_OPENAPI: test-api-specification.json
  APISEC_TARGET_URL: http://test-deployment/
  APISEC_OVERRIDES_FILE: dast-api-overrides.json
```

인증이 작동하는지 확인하려면 API 보안 테스트를 실행하고 작업 로그와 테스트 API 애플리케이션 로그를 검토합니다.

#### 토큰의 만료 기간이 짧음 {#token-has-short-expiration}

Bearer 토큰을 생성해야 하고 스캔 완료 전에 만료되면 API 보안 테스팅 스캐너가 제공된 간격으로 실행할 프로그램 또는 스크립트를 제공할 수 있습니다. 제공된 스크립트는 Python 3과 Bash가 설치된 Alpine Linux 컨테이너에서 실행됩니다. Python 스크립트가 추가 패키지를 필요로 하면 이를 감지하고 런타임에 패키지를 설치해야 합니다.

스크립트는 특정 형식의 Bearer 토큰을 포함하는 JSON 파일을 생성해야 합니다:

```json
{
  "headers" : {
    "Authorization" : "Bearer dXNlcm5hbWU6cGFzc3dvcmQ="
  }
}
```

올바른 작동을 위해 세 개의 CI/CD 변수를 각각 제공해야 합니다:

- `APISEC_OVERRIDES_FILE`:  제공된 명령이 생성한 JSON 파일입니다.
- `APISEC_OVERRIDES_CMD`:  JSON 파일을 생성하는 명령입니다.
- `APISEC_OVERRIDES_INTERVAL`:  명령을 실행할 간격(초)입니다.

예를 들어:

```yaml
stages:
  - dast

include:
  - template: API-Security.gitlab-ci.yml

variables:
  APISEC_PROFILE: Quick
  APISEC_OPENAPI: test-api-specification.json
  APISEC_TARGET_URL: http://test-deployment/
  APISEC_OVERRIDES_FILE: dast-api-overrides.json
  APISEC_OVERRIDES_CMD: renew_token.py
  APISEC_OVERRIDES_INTERVAL: 300
```

인증이 작동하는지 확인하려면 API 보안 테스트를 실행하고 작업 로그와 테스트 API 애플리케이션 로그를 검토합니다. 오버라이드 명령에 대한 자세한 내용은 [오버라이드 섹션](#overrides)을 참조하세요.

## 오버라이드 {#overrides}

API 보안 테스팅은 요청의 특정 항목을 추가하거나 오버라이드하는 방법을 제공합니다. 예를 들어:

- 헤더
- 쿠키
- 쿼리 문자열
- 양식 데이터
- JSON 노드
- XML 노드

이를 사용하여 의미 있는 버전 헤더, 인증 등을 주입할 수 있습니다. [인증 섹션](#authentication)에는 해당 목적으로 오버라이드를 사용하는 예제가 포함되어 있습니다.

오버라이드는 JSON 문서를 사용하며, 각 유형의 오버라이드는 JSON 객체로 표현됩니다:

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

단일 헤더 설정의 예:

```json
{
  "headers": {
    "Authorization": "Bearer dXNlcm5hbWU6cGFzc3dvcmQ="
  }
}
```

헤더와 쿠키 모두 설정의 예:

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

`body-form` 오버라이드 설정의 예:

```json
{
  "body-form":  {
    "username": "john.doe"
  }
}
```

오버라이드 엔진은 요청 본문에 양식 데이터 콘텐츠만 있을 때 `body-form`을 사용합니다.

`body-json` 오버라이드 설정의 예:

```json
{
  "body-json":  {
    "$.credentials.access-token": "iddqd!42.$"
  }
}
```

객체 `body-json`의 각 JSON 속성 이름은 [JSON 경로](https://goessner.net/articles/JsonPath/) 표현식으로 설정됩니다. JSON 경로 표현식 `$.credentials.access-token`은 값 `iddqd!42.$`으로 오버라이드될 노드를 식별합니다. 오버라이드 엔진은 요청 본문에 [JSON](https://www.json.org/json-en.html) 콘텐츠만 있을 때 `body-json`를 사용합니다.

예를 들어, 본문이 다음 JSON으로 설정된 경우:

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

`body-xml` 오버라이드 설정의 예입니다. 첫 번째 항목은 XML 속성을 오버라이드하고 두 번째 항목은 XML 요소를 오버라이드합니다:

```json
{
  "body-xml" :  {
    "/credentials/@isEnabled": "true",
    "/credentials/access-token/text()" : "iddqd!42.$"
  }
}
```

객체 `body-xml`의 각 JSON 속성 이름은 [XPath v2](https://www.w3.org/TR/xpath20/) 표현식으로 설정됩니다. XPath 표현식 `/credentials/@isEnabled`은 값 `true`으로 오버라이드될 속성 노드를 식별합니다. XPath 표현식 `/credentials/access-token/text()`은 값 `iddqd!42.$`으로 오버라이드될 요소 노드를 식별합니다. 오버라이드 엔진은 요청 본문에 [XML](https://www.w3.org/XML/) 콘텐츠만 있을 때 `body-xml`을 사용합니다.

예를 들어, 본문이 다음 XML로 설정된 경우:

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

이 JSON 문서를 파일 또는 환경 변수로 제공할 수 있습니다. JSON 문서를 생성하는 명령을 제공할 수도 있습니다. 명령은 만료되는 값을 지원하기 위해 간격으로 실행할 수 있습니다.

### 파일 사용 {#using-a-file}

오버라이드 JSON을 파일로 제공하려면 `APISEC_OVERRIDES_FILE` CI/CD 변수를 설정합니다. 경로는 작업 현재 작업 디렉터리에 상대적입니다.

`.gitlab-ci.yml`의 예입니다:

```yaml
stages:
  - dast

include:
  - template: API-Security.gitlab-ci.yml

variables:
  APISEC_PROFILE: Quick
  APISEC_OPENAPI: test-api-specification.json
  APISEC_TARGET_URL: http://test-deployment/
  APISEC_OVERRIDES_FILE: dast-api-overrides.json
```

### CI/CD 변수 사용 {#using-a-cicd-variable}

오버라이드 JSON을 CI/CD 변수로 제공하려면 `APISEC_OVERRIDES_ENV` 변수를 사용합니다. 이를 통해 JSON을 마스킹하고 보호할 수 있는 변수로 배치할 수 있습니다.

이 `.gitlab-ci.yml` 예에서 `APISEC_OVERRIDES_ENV` 변수는 JSON으로 직접 설정됩니다:

```yaml
stages:
  - dast

include:
  - template: API-Security.gitlab-ci.yml

variables:
  APISEC_PROFILE: Quick
  APISEC_OPENAPI: test-api-specification.json
  APISEC_TARGET_URL: http://test-deployment/
  APISEC_OVERRIDES_ENV: '{"headers":{"X-API-Version":"2"}}'
```

이 `.gitlab-ci.yml` 예에서 `SECRET_OVERRIDES` 변수는 JSON을 제공합니다. 이는 [UI에서 정의된 그룹 또는 인스턴스 CI/CD 변수](../../../../ci/variables/_index.md#define-a-cicd-variable-in-the-ui)입니다:

```yaml
stages:
  - dast

include:
  - template: API-Security.gitlab-ci.yml

variables:
  APISEC_PROFILE: Quick
  APISEC_OPENAPI: test-api-specification.json
  APISEC_TARGET_URL: http://test-deployment/
  APISEC_OVERRIDES_ENV: $SECRET_OVERRIDES
```

### 명령 사용 {#using-a-command}

값을 생성하거나 만료 시 재생성해야 하는 경우, API 보안 테스팅 스캐너가 지정된 간격으로 실행할 프로그램 또는 스크립트를 제공할 수 있습니다. 제공된 명령은 Python 3과 Bash가 설치된 Alpine Linux 컨테이너에서 실행됩니다.

환경 변수 `APISEC_OVERRIDES_CMD`을 실행하려는 프로그램 또는 스크립트로 설정해야 합니다. 제공된 명령은 이전에 정의된 대로 오버라이드 JSON 파일을 생성합니다.

NodeJS 또는 Ruby와 같은 다른 스크립팅 런타임을 설치하거나 오버라이드 명령에 대한 종속성을 설치해야 할 수도 있습니다. 이 경우 `APISEC_PRE_SCRIPT`을 해당 전제 조건을 제공하는 스크립트의 파일 경로로 설정해야 합니다. `APISEC_PRE_SCRIPT`에서 제공한 스크립트는 분석기가 시작되기 전에 한 번 실행됩니다.

> [!note]
> 높은 권한이 필요한 작업을 수행할 때 `sudo` 명령을 사용하세요. 예를 들어, `sudo apk add nodejs`입니다.

Alpine Linux 패키지 설치에 대한 정보는 [Alpine Linux 패키지 관리](https://wiki.alpinelinux.org/wiki/Alpine_Linux_package_management) 페이지를 참조하세요.

올바른 작동을 위해 세 개의 CI/CD 변수를 각각 제공해야 합니다:

- `APISEC_OVERRIDES_FILE`:  제공된 명령에서 생성한 파일입니다.
- `APISEC_OVERRIDES_CMD`:  주기적으로 오버라이드 JSON 파일을 생성하는 오버라이드 명령입니다.
- `APISEC_OVERRIDES_INTERVAL`:  명령을 실행할 간격(초)입니다.

선택 사항:

- `APISEC_PRE_SCRIPT`:  스캔이 시작되기 전에 런타임 또는 종속성을 설치하는 스크립트입니다.

> [!warning]
> Alpine Linux에서 스크립트를 실행하려면 먼저 [`chmod`](https://www.gnu.org/software/coreutils/manual/html_node/chmod-invocation.html) 명령을 사용하여 [실행 권한](https://www.gnu.org/software/coreutils/manual/html_node/Setting-Permissions.html)을 설정해야 합니다. 예를 들어 `script.py`의 실행 권한을 모두에게 설정하려면 `sudo chmod a+x script.py` 명령을 사용합니다. 필요한 경우 실행 권한이 이미 설정된 `script.py`을 버전으로 관리할 수 있습니다.

```yaml
stages:
  - dast

include:
  - template: API-Security.gitlab-ci.yml

variables:
  APISEC_PROFILE: Quick
  APISEC_OPENAPI: test-api-specification.json
  APISEC_TARGET_URL: http://test-deployment/
  APISEC_OVERRIDES_FILE: dast-api-overrides.json
  APISEC_OVERRIDES_CMD: renew_token.py
  APISEC_OVERRIDES_INTERVAL: 300
```

### 오버라이드 디버깅 {#debugging-overrides}

기본적으로 오버라이드 명령의 출력은 숨겨집니다. 선택 사항으로 변수 `APISEC_OVERRIDES_CMD_VERBOSE`을 임의의 값으로 설정하여 오버라이드 명령 출력을 `gl-api-security-scanner.log` 작업 아티팩트 파일에 기록할 수 있습니다. 이는 오버라이드 스크립트를 테스트할 때 유용하지만 이후에는 테스트 속도를 저하시키므로 비활성화해야 합니다.

스크립트에서 메시지를 로그 파일에 작성하여 작업이 완료되거나 실패할 때 수집할 수도 있습니다. 로그 파일은 특정 위치에 생성되어야 하며 명명 규칙을 따라야 합니다.

오버라이드 스크립트에 기본 로깅을 추가하는 것은 작업의 표준 실행 중에 스크립트가 예기치 않게 실패할 경우 유용합니다. 로그 파일은 작업의 아티팩트로 자동으로 포함되므로 작업이 완료된 후 다운로드할 수 있습니다.

예제는 환경 변수 `APISEC_OVERRIDES_CMD`에서 `renew_token.py`을 제공합니다. 스크립트에서 두 가지에 주의하세요:

- 로그 파일은 환경 변수 `CI_PROJECT_DIR`에서 표시한 위치에 저장됩니다.
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
overrides_file_name = os.environ.get('APISEC_OVERRIDES_FILE', 'dast-api-overrides.json')
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

# In the example, access token is retrieved from a given endpoint
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

    # overwrites the file with the updated dictionary
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

오버라이드 명령 예제에서 Python 스크립트는 `backoff` 라이브러리에 따라 다릅니다. Python 스크립트를 실행하기 전에 라이브러리가 설치되어 있는지 확인하려면 `APISEC_PRE_SCRIPT`을 오버라이드 명령의 종속성을 설치하는 스크립트로 설정합니다. 예를 들어 다음 스크립트 `user-pre-scan-set-up.sh`

```shell
#!/bin/bash

# user-pre-scan-set-up.sh
# Ensures python dependencies are installed

echo "**** install python dependencies ****"

sudo pip3 install --no-cache --upgrade --break-system-packages \
    backoff

echo "**** python dependencies installed ****"

# end
```

구성을 업데이트하여 `APISEC_PRE_SCRIPT`을 새 `user-pre-scan-set-up.sh` 스크립트로 설정해야 합니다. 예를 들어:

```yaml
stages:
  - dast

include:
  - template: API-Security.gitlab-ci.yml

variables:
  APISEC_PROFILE: Quick
  APISEC_OPENAPI: test-api-specification.json
  APISEC_TARGET_URL: http://test-deployment/
  APISEC_PRE_SCRIPT: ./user-pre-scan-set-up.sh
  APISEC_OVERRIDES_FILE: dast-api-overrides.json
  APISEC_OVERRIDES_CMD: renew_token.py
  APISEC_OVERRIDES_INTERVAL: 300
```

이전 샘플에서 `user-pre-scan-set-up.sh` 스크립트를 사용하여 새로운 런타임 또는 애플리케이션을 설치할 수 있습니다. 그런 다음 오버라이드 명령에서 해당 런타임 또는 애플리케이션을 사용합니다.

## 요청 헤더 {#request-headers}

요청 헤더 기능을 사용하면 스캔 세션 중에 헤더에 고정 값을 지정할 수 있습니다. 예를 들어 구성 변수 `APISEC_REQUEST_HEADERS`을 사용하여 `Cache-Control` 헤더에 고정 값을 설정할 수 있습니다. `Authorization` 헤더와 같은 민감한 값을 포함해야 하는 헤더의 경우 [마스킹된 변수](../../../../ci/variables/_index.md#mask-a-cicd-variable) 기능을 [`APISEC_REQUEST_HEADERS_BASE64` 변수](#base64)와 함께 사용합니다.

`Authorization` 헤더 또는 다른 헤더를 스캔 진행 중에 업데이트해야 하는 경우 [오버라이드](#overrides) 기능 사용을 고려하세요.

변수 `APISEC_REQUEST_HEADERS`을 사용하면 쉼표로 구분된(`,`) 헤더 목록을 지정할 수 있습니다. 이러한 헤더는 스캐너가 수행하는 각 요청에 포함됩니다. 목록의 각 헤더 항목은 콜론(`:`) 뒤에 이름으로 구성되고 그 다음에 값이 옵니다. 키 또는 값 앞의 공백은 무시됩니다. 예를 들어 헤더 이름 `Cache-Control`를 값 `max-age=604800`로 선언하려면 헤더 항목은 `Cache-Control: max-age=604800`입니다. 두 개의 헤더 `Cache-Control: max-age=604800` 및 `Age: 100`을 사용하려면 `APISEC_REQUEST_HEADERS` 변수를 `Cache-Control: max-age=604800, Age: 100`으로 설정합니다.

변수 `APISEC_REQUEST_HEADERS`에 제공되는 다른 헤더의 순서는 결과에 영향을 주지 않습니다. `APISEC_REQUEST_HEADERS`를 `Cache-Control: max-age=604800, Age: 100`으로 설정하는 것은 `Age: 100, Cache-Control: max-age=604800`로 설정하는 것과 같은 결과를 생성합니다.

### Base64 {#base64}

`APISEC_REQUEST_HEADERS_BASE64` 변수는 `APISEC_REQUEST_HEADERS`와 동일한 헤더 목록을 허용하며, 유일한 차이점은 변수의 전체 값을 Base64로 인코딩해야 한다는 것입니다. 예를 들어 `APISEC_REQUEST_HEADERS_BASE64` 변수를 `Authorization: QmVhcmVyIFRPS0VO, Cache-control: bm8tY2FjaGU=`로 설정하려면 목록을 Base64 등가로 변환하세요: `QXV0aG9yaXphdGlvbjogUW1WaGNtVnlJRlJQUzBWTywgQ2FjaGUtY29udHJvbDogYm04dFkyRmphR1U9`, Base64 인코딩된 값을 사용해야 합니다. 이는 [마스킹된 변수](../../../../ci/variables/_index.md#mask-a-cicd-variable)에 비밀 헤더 값을 저장할 때 유용하며, 문자 집합 제한이 있습니다.

> [!warning]
> Base64는 [마스킹된 변수](../../../../ci/variables/_index.md#mask-a-cicd-variable) 기능을 지원하는 데 사용됩니다. Base64 인코딩 자체는 민감한 값을 디코딩할 수 있으므로 보안 방법이 아닙니다.

### 예:  일반 텍스트를 사용하여 각 요청에서 헤더 목록 추가 {#example-adding-a-list-of-headers-on-each-request-using-plain-text}

다음 `.gitlab-ci.yml` 예에서 `APISEC_REQUEST_HEADERS` 구성 변수는 [요청 헤더](#request-headers)에서 설명한 대로 두 개의 헤더 값을 제공하도록 설정됩니다.

```yaml
stages:
  - dast

include:
  - template: API-Security.gitlab-ci.yml

variables:
  APISEC_PROFILE: Quick
  APISEC_OPENAPI: test-api-specification.json
  APISEC_TARGET_URL: http://test-deployment/
  APISEC_REQUEST_HEADERS: 'Cache-control: no-cache, Save-Data: on'
```

### 예:  마스킹된 CI/CD 변수 사용 {#example-using-a-masked-cicd-variable}

다음 `.gitlab-ci.yml` 샘플은 [마스킹된 변수](../../../../ci/variables/_index.md#mask-a-cicd-variable) `SECRET_REQUEST_HEADERS_BASE64`이 [UI에서 정의된 그룹 또는 인스턴스 CI/CD 변수](../../../../ci/variables/_index.md#define-a-cicd-variable-in-the-ui)로 정의되어 있다고 가정합니다. `SECRET_REQUEST_HEADERS_BASE64`의 값은 `WC1BQ01FLVNlY3JldDogc31jcnt0ISwgWC1BQ01FLVRva2VuOiA3MDVkMTZmNWUzZmI=`으로 설정되며, `X-ACME-Secret: s3cr3t!, X-ACME-Token: 705d16f5e3fb`의 Base64 인코딩된 텍스트 버전입니다. 그런 다음 다음과 같이 사용할 수 있습니다:

```yaml
stages:
  - dast

include:
  - template: API-Security.gitlab-ci.yml

variables:
  APISEC_PROFILE: Quick
  APISEC_OPENAPI: test-api-specification.json
  APISEC_TARGET_URL: http://test-deployment/
  APISEC_REQUEST_HEADERS_BASE64: $SECRET_REQUEST_HEADERS_BASE64
```

[마스킹된 변수](../../../../ci/variables/_index.md#mask-a-cicd-variable)에서 비밀 헤더 값을 저장할 때 `APISEC_REQUEST_HEADERS_BASE64`를 사용하는 것이 좋습니다. 이 변수는 문자 집합 제한이 있습니다.

## 경로 제외 {#exclude-paths}

API를 테스트할 때 특정 경로를 제외하는 것이 유용할 수 있습니다. 예를 들어 인증 서비스 또는 구 버전의 API 테스트를 제외할 수 있습니다. 경로를 제외하려면 `APISEC_EXCLUDE_PATHS` CI/CD 변수를 사용합니다. 이 변수는 `.gitlab-ci.yml` 파일에서 지정됩니다. 여러 경로를 제외하려면 `;` 문자를 사용하여 항목을 구분합니다. 제공된 경로에서 단일 문자 와일드카드 `?` 및 여러 문자 와일드카드 `*`를 사용할 수 있습니다.

경로가 제외되는지 확인하려면 작업 출력의 `Tested Operations` 및 `Excluded Operations` 부분을 검토합니다. `Tested Operations` 아래에 제외된 경로가 나열되지 않아야 합니다.

```plaintext
2021-05-27 21:51:08 [INF] API SECURITY: --[ Tested Operations ]-------------------------
2021-05-27 21:51:08 [INF] API SECURITY: 201 POST http://target:7777/api/users CREATED
2021-05-27 21:51:08 [INF] API SECURITY: ------------------------------------------------
2021-05-27 21:51:08 [INF] API SECURITY: --[ Excluded Operations ]-----------------------
2021-05-27 21:51:08 [INF] API SECURITY: GET http://target:7777/api/messages
2021-05-27 21:51:08 [INF] API SECURITY: POST http://target:7777/api/messages
2021-05-27 21:51:08 [INF] API SECURITY: ------------------------------------------------
```

### 예제 {#examples}

이 예제는 `/auth` 리소스를 제외합니다. 이는 자식 리소스(`/auth/child`)를 제외하지 않습니다.

```yaml
variables:
  APISEC_EXCLUDE_PATHS: /auth
```

`/auth`을 제외하고 자식 리소스(`/auth/child`)를 제외하려면 와일드카드를 사용합니다.

```yaml
variables:
  APISEC_EXCLUDE_PATHS: /auth*
```

여러 경로를 제외하려면 `;` 문자를 사용합니다. 다음 예제는 `/auth*` 및 `/v1/*`을 제외합니다.

```yaml
variables:
  APISEC_EXCLUDE_PATHS: /auth*;/v1/*
```

경로 내에서 하나 이상의 중첩 수준을 제외하려면 `**`을 사용합니다. 다음 예제는 `/api/v1/` 및 `/api/v2/` API 엔드포인트를 테스트합니다. `mass`, `brightness` 및 `coordinates` 데이터에 대한 데이터 쿼리로 `planet`, `moon`, `star` 및 `satellite` 객체를 요청합니다. 스캔할 수 있는 경로 예:

- `/api/v2/planet/coordinates`
- `/api/v1/star/mass`
- `/api/v2/satellite/brightness`

이 예제는 `brightness` 엔드포인트만 테스트합니다:

```yaml
variables:
  APISEC_EXCLUDE_PATHS: /api/**/mass;/api/**/coordinates
```

### 매개 변수 제외 {#exclude-parameters}

API를 테스트할 때 매개 변수(쿼리 문자열, 헤더 또는 본문 요소)를 테스트에서 제외하려고 할 수 있습니다. 매개 변수가 항상 실패를 일으키거나, 테스트 속도를 저하시키거나, 다른 이유로 인해 필요할 수 있습니다. 매개 변수를 제외하려면 다음 변수 중 하나를 설정할 수 있습니다: `APISEC_EXCLUDE_PARAMETER_ENV` 또는 `APISEC_EXCLUDE_PARAMETER_FILE`

`APISEC_EXCLUDE_PARAMETER_ENV`은 제외된 매개 변수가 포함된 JSON 문자열을 제공할 수 있습니다. JSON이 짧고 자주 변경되지 않으면 좋은 선택입니다. 또 다른 옵션은 변수 `APISEC_EXCLUDE_PARAMETER_FILE`입니다. 이 변수는 리포지토리에 체크인할 수 있는 파일 경로, 다른 작업의 아티팩트로 생성하거나 `APISEC_PRE_SCRIPT`을 사용하는 사전 스크립트로 런타임에 생성되는 파일 경로로 설정됩니다.

#### JSON 문서를 사용하여 매개 변수 제외 {#exclude-parameters-using-a-json-document}

JSON 문서는 JSON 객체를 포함하며, 이 객체는 제외할 매개 변수를 식별하기 위해 특정 속성을 사용합니다. 스캔 프로세스 중에 특정 매개 변수를 제외하기 위해 다음 속성을 제공할 수 있습니다:

- `headers`:  이 속성을 사용하여 특정 헤더를 제외합니다. 속성의 값은 제외할 헤더 이름의 배열입니다. 이름은 대소문자를 구분하지 않습니다.
- `cookies`:  이 속성의 값을 사용하여 특정 쿠키를 제외합니다. 속성의 값은 제외할 쿠키 이름의 배열입니다. 이름은 대소문자를 구분합니다.
- `query`:  이 속성을 사용하여 쿼리 문자열에서 특정 필드를 제외합니다. 속성의 값은 제외할 쿼리 문자열의 필드 이름 배열입니다. 이름은 대소문자를 구분합니다.
- `body-form`:  이 속성을 사용하여 미디어 유형 `application/x-www-form-urlencoded`을 사용하는 요청에서 특정 필드를 제외합니다. 속성의 값은 본문에서 제외할 필드 이름의 배열입니다. 이름은 대소문자를 구분합니다.
- `body-json`:  이 속성을 사용하여 미디어 유형 `application/json`을 사용하는 요청에서 특정 JSON 노드를 제외합니다. 속성의 값은 배열이며, 배열의 각 항목은 [JSON 경로](https://goessner.net/articles/JsonPath/) 표현식입니다.
- `body-xml`:  이 속성을 사용하여 미디어 유형 `application/xml`을 사용하는 요청에서 특정 XML 노드를 제외합니다. 속성의 값은 배열이며, 배열의 각 항목은 [XPath v2](https://www.w3.org/TR/xpath20/) 표현식입니다.

따라서 다음 JSON 문서는 매개 변수를 제외하는 예상 구조의 예입니다.

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

#### 예제 {#examples-1}

##### 단일 헤더 제외 {#excluding-a-single-header}

헤더 `Upgrade-Insecure-Requests`를 제외하려면 `header` 속성의 값을 헤더 이름이 포함된 배열로 설정합니다: `[ "Upgrade-Insecure-Requests" ]` 예를 들어 JSON 문서는 다음과 같습니다:

```json
{
  "headers": [ "Upgrade-Insecure-Requests" ]
}
```

헤더 이름은 대소문자를 구분하지 않으므로 헤더 이름 `UPGRADE-INSECURE-REQUESTS`은 `Upgrade-Insecure-Requests`과 동일합니다.

##### 헤더 및 두 개의 쿠키 제외 {#excluding-both-a-header-and-two-cookies}

헤더 `Authorization`을 제외하고 쿠키 `PHPSESSID` 및 `csrftoken`을 제외하려면 `headers` 속성의 값을 헤더 이름 `[ "Authorization" ]`이 포함된 배열로 설정하고 `cookies` 속성의 값을 쿠키 이름 `[ "PHPSESSID", "csrftoken" ]`이 포함된 배열로 설정합니다. 예를 들어 JSON 문서는 다음과 같습니다:

```json
{
  "headers": [ "Authorization" ],
  "cookies": [ "PHPSESSID", "csrftoken" ]
}
```

##### `body-form` 매개 변수 제외 {#excluding-a-body-form-parameter}

`application/x-www-form-urlencoded`을 사용하는 요청에서 `password` 필드를 제외하려면 `body-form` 속성의 값을 필드 이름 `[ "password" ]`이 포함된 배열로 설정합니다. 예를 들어 JSON 문서는 다음과 같습니다:

```json
{
  "body-form":  [ "password" ]
}
```

제외 매개 변수는 요청이 콘텐츠 유형 `application/x-www-form-urlencoded`을 사용할 때 `body-form`을 사용합니다.

##### JSON 경로를 사용하여 특정 JSON 노드 제외 {#excluding-a-specific-json-nodes-using-json-path}

루트 객체에서 `schema` 속성을 제외하려면 `body-json` 속성의 값을 JSON 경로 표현식 `[ "$.schema" ]`이 포함된 배열로 설정합니다.

JSON 경로 표현식은 JSON 노드를 식별하기 위해 특수 구문을 사용합니다: `$`은 JSON 문서의 루트를 참조하고 `.`은 현재 객체(이 경우 루트 객체)를 참조하며 텍스트 `schema`은 속성 이름을 참조합니다. 따라서 JSON 경로 표현식 `$.schema`은 루트 객체의 속성 `schema`을 참조합니다. 예를 들어 JSON 문서는 다음과 같습니다:

```json
{
  "body-json": [ "$.schema" ]
}
```

제외 매개 변수는 요청이 콘텐츠 유형 `application/json`을 사용할 때 `body-json`을 사용합니다. `body-json`의 각 항목은 [JSON 경로 표현식](https://goessner.net/articles/JsonPath/)이어야 합니다. JSON 경로에서 `$`, `*`, `.` 등의 문자는 특수한 의미를 가집니다.

##### JSON 경로를 사용하여 여러 JSON 노드 제외 {#excluding-multiple-json-nodes-using-json-path}

루트 수준에서 `users` 배열의 각 항목에 대해 `password` 속성을 제외하려면 `body-json` 속성의 값을 JSON 경로 표현식 `[ "$.users[*].password" ]`이 포함된 배열로 설정합니다.

JSON 경로 표현식은 `$`로 시작하여 루트 노드를 참조하고 `.`을 사용하여 현재 노드를 참조합니다. 그런 다음 `users`을 사용하여 속성을 참조하고 `[` 및 `]` 문자를 사용하여 사용하려는 배열의 인덱스를 포함하며, 인덱스로 숫자를 제공하는 대신 `*`을 사용하여 모든 인덱스를 지정합니다. 인덱스 참조 후 `.` 문자는 배열에서 선택된 모든 인덱스를 참조하고 그 뒤에 속성 이름 `password`이 옵니다.

예를 들어 JSON 문서는 다음과 같습니다:

```json
{
  "body-json": [ "$.users[*].password" ]
}
```

제외 매개 변수는 요청이 콘텐츠 유형 `application/json`을 사용할 때 `body-json`을 사용합니다. `body-json`의 각 항목은 [JSON 경로 표현식](https://goessner.net/articles/JsonPath/)이어야 합니다. JSON 경로에서 `$`, `*`, `.` 등의 문자는 특수한 의미를 가집니다.

##### XML 속성 제외 {#excluding-a-xml-attribute}

`credentials` 루트 요소에 위치한 `isEnabled`이라는 속성을 제외하려면 `body-xml` 속성의 값을 XPath 표현식 `[ "/credentials/@isEnabled" ]`이 포함된 배열로 설정합니다.

XPath 표현식 `/credentials/@isEnabled`은 `/`로 시작하여 XML 문서의 루트를 표시한 다음 일치할 요소의 이름을 나타내는 단어 `credentials`이 옵니다. 이전 XML 요소의 노드를 참조하기 위해 `/`을 사용하고 `@` 문자를 사용하여 이름 `isEnable`이 속성임을 나타냅니다.

예를 들어 JSON 문서는 다음과 같습니다:

```json
{
  "body-xml": [
    "/credentials/@isEnabled"
  ]
}
```

제외 매개 변수는 요청이 콘텐츠 유형 `application/xml`을 사용할 때 `body-xml`을 사용합니다. `body-xml`의 각 항목은 [XPath v2 표현식](https://www.w3.org/TR/xpath20/)이어야 합니다. XPath 표현식에서 `@`, `/`, `:`, `[`, `]` 등의 문자는 특수한 의미를 가집니다.

##### XML 텍스트 요소 제외 {#excluding-a-xml-texts-element}

루트 노드 `credentials`에 포함된 `username` 요소의 텍스트를 제외하려면 `body-xml` 속성의 값을 XPath 표현식 `[/credentials/username/text()" ]`이 포함된 배열로 설정합니다.

XPath 표현식 `/credentials/username/text()`에서 첫 번째 문자 `/`은 루트 XML 노드를 참조하고 그 뒤에 XML 요소의 이름 `credentials`을 표시합니다. 마찬가지로 `/` 문자는 현재 요소를 참조하고 그 뒤에 새 XML 요소의 이름 `username`이 옵니다. 마지막 부분에는 현재 요소를 참조하고 현재 요소의 텍스트를 식별하는 XPath 함수 `text()`을 사용하는 `/`이 있습니다.

예를 들어 JSON 문서는 다음과 같습니다:

```json
{
  "body-xml": [
    "/credentials/username/text()"
  ]
}
```

제외 매개 변수는 요청이 콘텐츠 유형 `application/xml`을 사용할 때 `body-xml`을 사용합니다. `body-xml`의 각 항목은 [XPath v2 표현식](https://www.w3.org/TR/xpath20/)이어야 합니다. XPath 표현식에서 `@`, `/`, `:`, `[`, `]` 등의 문자는 특수한 의미를 가집니다.

##### XML 요소 제외 {#excluding-an-xml-element}

루트 노드 `credentials`에 포함된 `username` 요소를 제외하려면 `body-xml` 속성의 값을 XPath 표현식 `[/credentials/username" ]`이 포함된 배열로 설정합니다.

XPath 표현식 `/credentials/username`에서 첫 번째 문자 `/`은 루트 XML 노드를 참조하고 그 뒤에 XML 요소의 이름 `credentials`을 표시합니다. 마찬가지로 `/` 문자는 현재 요소를 참조하고 그 뒤에 새 XML 요소의 이름 `username`이 옵니다.

예를 들어 JSON 문서는 다음과 같습니다:

```json
{
  "body-xml": [
    "/credentials/username"
  ]
}
```

제외 매개 변수는 요청이 콘텐츠 유형 `application/xml`을 사용할 때 `body-xml`을 사용합니다. `body-xml`의 각 항목은 [XPath v2 표현식](https://www.w3.org/TR/xpath20/)이어야 합니다. XPath 표현식에서 `@`, `/`, `:`, `[`, `]` 등의 문자는 특수한 의미를 가집니다.

##### 네임스페이스를 사용한 XML 노드 제외 {#excluding-an-xml-node-with-namespaces}

`s` 네임스페이스에서 정의되고 `credentials` 루트 노드에 포함된 `login` XML 요소를 제외하려면 `body-xml` 속성의 값을 XPath 표현식 `[ "/credentials/s:login" ]`이 포함된 배열로 설정합니다.

XPath 표현식 `/credentials/s:login`에서 첫 번째 문자 `/`은 루트 XML 노드를 참조하고 그 뒤에 XML 요소의 이름 `credentials`을 표시합니다. 마찬가지로 `/` 문자는 현재 요소를 참조하고 그 뒤에 새 XML 요소의 이름 `s:login`이 옵니다. 이름에 `:` 문자가 포함되어 있으므로 이 문자는 네임스페이스와 노드 이름을 구분합니다.

네임스페이스 이름은 본문 요청의 일부인 XML 문서에서 정의되었어야 합니다. 사양 문서 HAR, OpenAPI 또는 Postman Collection 파일에서 네임스페이스를 확인할 수 있습니다.

```json
{
  "body-xml": [
    "/credentials/s:login"
  ]
}
```

제외 매개 변수는 요청이 콘텐츠 유형 `application/xml`을 사용할 때 `body-xml`을 사용합니다. `body-xml`의 각 항목은 [XPath v2 표현식](https://www.w3.org/TR/xpath20/)이어야 합니다. XPath 표현식에서 `@`, `/`, `:`, `[`, `]` 등의 문자는 특수한 의미를 가집니다.

#### JSON 문자열 사용 {#using-a-json-string}

제외 JSON 문서를 제공하려면 변수 `APISEC_EXCLUDE_PARAMETER_ENV`을 JSON 문자열로 설정합니다. 다음 예에서 `.gitlab-ci.yml`는 `APISEC_EXCLUDE_PARAMETER_ENV` 변수가 JSON 문자열로 설정됩니다:

```yaml
stages:
  - dast

include:
  - template: API-Security.gitlab-ci.yml

variables:
  APISEC_PROFILE: Quick
  APISEC_OPENAPI: test-api-specification.json
  APISEC_TARGET_URL: http://test-deployment/
  APISEC_EXCLUDE_PARAMETER_ENV: '{ "headers": [ "Upgrade-Insecure-Requests" ] }'
```

#### 파일 사용 {#using-a-file-1}

제외 JSON 문서를 제공하려면 변수 `APISEC_EXCLUDE_PARAMETER_FILE`을 JSON 파일 경로로 설정합니다. 파일 경로는 작업 현재 작업 디렉터리에 상대적입니다. 다음 예 `.gitlab-ci.yml` 콘텐츠에서 `APISEC_EXCLUDE_PARAMETER_FILE` 변수는 JSON 파일 경로로 설정됩니다:

```yaml
stages:
  - dast

include:
  - template: API-Security.gitlab-ci.yml

variables:
  APISEC_PROFILE: Quick
  APISEC_OPENAPI: test-api-specification.json
  APISEC_TARGET_URL: http://test-deployment/
  APISEC_EXCLUDE_PARAMETER_FILE: dast-api-exclude-parameters.json
```

`dast-api-exclude-parameters.json`은 [매개 변수 문서 제외](#exclude-parameters-using-a-json-document) 구조를 따르는 JSON 문서입니다.

### URL 제외 {#exclude-urls}

경로별 제외 대신에 `APISEC_EXCLUDE_URLS` CI/CD 변수를 사용하여 URL의 다른 구성 요소로 필터링할 수 있습니다. 이 변수는 `.gitlab-ci.yml` 파일에서 설정할 수 있습니다. 변수는 쉼표(`,`)로 구분된 여러 값을 저장할 수 있습니다. 각 값은 정규 표현식입니다. 각 항목이 정규 표현식이므로 `.*`와 같은 항목은 모든 URL과 일치하는 정규 표현식이므로 모든 URL을 제외합니다.

작업 출력에서 `APISEC_EXCLUDE_URLS`에서 제공한 정규 표현식과 일치하는 URL이 있는지 확인할 수 있습니다. 일치하는 작업은 **Excluded Operations** 섹션에 나열됩니다. **Excluded Operations**에 나열된 작업은 **Tested Operations** 섹션에 나열되지 않아야 합니다. 예를 들어 작업 출력의 다음 부분:

```plaintext
2021-05-27 21:51:08 [INF] API SECURITY: --[ Tested Operations ]-------------------------
2021-05-27 21:51:08 [INF] API SECURITY: 201 POST http://target:7777/api/users CREATED
2021-05-27 21:51:08 [INF] API SECURITY: ------------------------------------------------
2021-05-27 21:51:08 [INF] API SECURITY: --[ Excluded Operations ]-----------------------
2021-05-27 21:51:08 [INF] API SECURITY: GET http://target:7777/api/messages
2021-05-27 21:51:08 [INF] API SECURITY: POST http://target:7777/api/messages
2021-05-27 21:51:08 [INF] API SECURITY: ------------------------------------------------
```

> [!note]
> `APISEC_EXCLUDE_URLS`의 각 값은 정규 표현식입니다. `.` , `*` 및 `$`와 같은 문자는 [정규 표현식](https://en.wikipedia.org/wiki/Regular_expression#Standards)에서 특수한 의미를 가집니다.

#### 예제 {#examples-2}

##### URL 및 자식 리소스 제외 {#excluding-a-url-and-child-resources}

다음 예제는 URL `http://target/api/auth` 및 자식 리소스를 제외합니다.

```yaml
stages:
  - dast

include:
  - template: API-Security.gitlab-ci.yml

variables:
  APISEC_TARGET_URL: http://target/
  APISEC_OPENAPI: test-api-specification.json
  APISEC_EXCLUDE_URLS: http://target/api/auth
```

##### 두 URL을 제외하고 자식 리소스 허용 {#excluding-two-urls-and-allow-their-child-resources}

URL `http://target/api/buy` 및 `http://target/api/sell`을 제외하지만 자식 리소스를 스캔할 수 있도록 허용합니다. 예를 들어: `http://target/api/buy/toy` 또는 `http://target/api/sell/chair` 값 `http://target/api/buy/$,http://target/api/sell/$`을 사용할 수 있습니다. 이 값은 `,` 문자로 구분된 두 개의 정규 표현식을 사용하고 있습니다. 따라서 `http://target/api/buy$` 및 `http://target/api/sell$`을 포함합니다. 각 정규 표현식에서 후행 `$` 문자는 일치하는 URL이 끝나야 할 위치를 나타냅니다.

```yaml
stages:
  - dast

include:
  - template: API-Security.gitlab-ci.yml

variables:
  APISEC_TARGET_URL: http://target/
  APISEC_OPENAPI: test-api-specification.json
  APISEC_EXCLUDE_URLS: http://target/api/buy/$,http://target/api/sell/$
```

##### 두 URL 및 자식 리소스 제외 {#excluding-two-urls-and-their-child-resources}

URL을 제외합니다: `http://target/api/buy` 및 `http://target/api/sell`, 그리고 자식 리소스입니다. 여러 URL을 제공하려면 `,` 문자를 다음과 같이 사용합니다:

```yaml
stages:
  - dast

include:
  - template: API-Security.gitlab-ci.yml

variables:
  APISEC_TARGET_URL: http://target/
  APISEC_OPENAPI: test-api-specification.json
  APISEC_EXCLUDE_URLS: http://target/api/buy,http://target/api/sell
```

##### 정규 표현식을 사용하여 URL 제외 {#excluding-url-using-regular-expressions}

정확히 `https://target/api/v1/user/create` 및 `https://target/api/v2/user/create` 또는 다른 버전(`v3`, `v4` 등)을 제외하려면 `https://target/api/v.*/user/create$`을 사용합니다. 정규 표현식에서 `.`은 모든 문자를 나타내고 `*`은 0번 이상을 나타냅니다. `$`은 URL이 그곳에서 끝나야 함을 나타냅니다.

```yaml
stages:
  - dast

include:
  - template: API-Security.gitlab-ci.yml

variables:
  APISEC_TARGET_URL: http://target/
  APISEC_OPENAPI: test-api-specification.json
  APISEC_EXCLUDE_URLS: https://target/api/v.*/user/create$
```
