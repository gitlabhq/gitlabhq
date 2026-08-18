---
type: concepts, howto
stage: Software Supply Chain Security
group: Pipeline Security
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: '튜토리얼: GitLab과 함께 Fortanix Data Security Manager (DSM) 사용'
---

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

GitLab CI/CD 파이프라인을 위한 비밀 관리자로 Fortanix Data Security Manager (DSM)를 사용할 수 있습니다.

이 튜토리얼에서는 Fortanix DSM에서 새로운 비밀을 생성하거나 기존 비밀을 사용하고, GitLab CI/CD 작업에서 사용하는 데 필요한 단계를 설명합니다. 이 통합을 구현하고, 데이터 보안을 강화하며, CI/CD 파이프라인을 최적화하기 위해 지침을 주의 깊게 따릅니다.

## 시작하기 전에 {#before-you-begin}

다음을 보유하고 있는지 확인하세요:

- 적절한 관리 권한이 있는 Fortanix DSM 계정에 대한 액세스입니다. 자세한 내용은 [Fortanix Data Security Manager 시작하기](https://www.fortanix.com/start-your-free-trial)를 참조하세요.
- 통합을 설정하려는 프로젝트에 액세스할 수 있는 [GitLab 계정](https://gitlab.com/users/sign_up)입니다.
- 비밀번호 생성 및 가져오기를 포함한 Fortanix DSM에서 비밀번호를 저장하는 프로세스에 대한 지식입니다.
- 그룹, 애플리케이션, 플러그인, 변수 및 비밀번호 관리를 위해 Fortanix DSM 및 GitLab에서 필요한 권한에 대한 액세스입니다.

## 새 비밀번호 생성 및 가져오기 {#generate-and-import-a-new-secret}

Fortanix DSM에서 새 비밀번호를 생성하고 GitLab에서 사용하려면:

1. Fortanix DSM 계정에 로그인합니다.
1. Fortanix DSM에서 [새 그룹 및 애플리케이션 만들기](https://support.fortanix.com/hc/en-us/articles/360015809372-User-s-Guide-Getting-Started-with-Fortanix-Data-Security-Manager-UI)를 수행합니다.
1. [애플리케이션에 대한 인증 방법으로 API 키 구성](https://support.fortanix.com/hc/en-us/articles/360033272171-User-s-Guide-Authentication)을 수행합니다.
1. 다음 코드를 사용하여 Fortanix DSM에서 새 플러그인을 생성합니다:

   ```lua
   numericAlphabet = "0123456789"
   alphanumericAlphabet = numericAlphabet .. "abcdefghijklmnopqrstuvwxyz"
   alphanumericCapsAlphabet = alphanumericAlphabet .. "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
   alphanumericCapsSymbolsAlphabets = alphanumericCapsAlphabet .. "!@#$&*_%="

   function genPass(alphabet, len, name, import)
       local alphabetSize = #alphabet
       local password = ''

       for i = 1, len, 1 do
           local random_char = math.random(alphabetSize)
           password = password .. string.sub(alphabet, random_char, random_char)
       end

       local pass = Blob.from_bytes(password)

       if import == "yes" then
           local sobject = assert(Sobject.import { name = name, obj_type = "SECRET", value = pass, key_ops = {'APPMANAGEABLE', 'EXPORT'} })
           return password
       end

       return password;
   end

   function run(input)
       if input.type == "numeric" then
           return genPass(numericAlphabet, input.length, input.name, input.import)
       end

       if input.type == "alphanumeric" then
           return genPass(alphanumericAlphabet, input.length, input.name, input.import)
       end

       if input.type == "alphanumeric_caps" then
           return genPass(alphanumericCapsAlphabet, input.length, input.name, input.import)
       end

       if input.type == "alphanumeric_caps_symbols" then
           return genPass(alphanumericCapsSymbolsAlphabets, input.length, input.name, input.import)
       end
   end
   ```

   자세한 내용은 [Fortanix 사용자 가이드를 참조하세요: 플러그인 라이브러리](https://support.fortanix.com/hc/en-us/articles/360041950371-User-s-Guide-Plugin-Library)입니다.

   - Fortanix DSM에 비밀번호를 저장하려면 가져오기 옵션을 `yes`로 설정합니다:

     ```json
     {
         "type": "alphanumeric_caps",
         "length": 64,
         "name": "GitLab-Secret",
         "import": "yes"
     }
     ```

   - 회전을 위해 새 값만 생성하려면 가져오기 옵션을 `no`로 설정합니다:

     ```json
     {
         "type": "numeric",
         "length": 64,
         "name": "GitLab-Secret",
         "import": "no"
     }
     ```

1. 상단 표시줄에서 **검색 또는 이동**을 선택하고 프로젝트를 찾습니다.
1. 왼쪽 사이드바에서 **설정** > **CI/CD**를 선택합니다.
1. **변수**를 확장하고 다음 변수를 추가합니다:
   - `FORTANIX_API_ENDPOINT`
   - `FORTANIX_API_KEY`
   - `FORTANIX_PLUGIN_ID`

1. 프로젝트에서 `.gitlab-ci.yml` 구성 파일을 만들거나 편집하여 통합을 사용합니다:

   ```yaml
   stages:
     - build

   build:
     stage: build
     image: ubuntu
     script:
       - apt-get update
       - apt install --assume-yes jq
       - apt install --assume-yes curl
       - jq --version
       - curl --version
       - secret=$(curl --silent --request POST --header "Authorization:Basic ${FORTANIX_API_KEY}" ${FORTANIX_API_ENDPOINT}/sys/v1/plugins/${FORTANIX_PLUGIN_ID} --data "{\"type\":\"alphanumeric_caps\", \"name\":\"$CI_PIPELINE_ID\",\"import\":\"yes\", \"length\":\"48\"}" | jq --raw-output)
       - nsecret=$(curl --silent --request POST --header "Authorization:Basic ${FORTANIX_API_KEY}" ${FORTANIX_API_ENDPOINT}/sys/v1/plugins/${FORTANIX_PLUGIN_ID} --data "{\"type\":\"alphanumeric_caps\", \"import\":\"no\", \"length\":\"48\"}" | jq --raw-output)
       - encodesecret=$(echo $nsecret | base64)
       - rotate=$(curl --silent --request POST --header "Authorization:Basic ${FORTANIX_API_KEY}" ${FORTANIX_API_ENDPOINT}/crypto/v1/keys/rekey --data "{\"name\":\"$CI_PIPELINE_ID\", \"value\":\"$encodesecret\"}" | jq --raw-output .kid)
   ```

1. `.gitlab-ci.yml` 파일을 저장한 후 파이프라인이 자동으로 실행되어야 합니다. 자동으로 실행되지 않으면 **빌드** > **파이프라인** > **파이프라인 실행**을 선택합니다.
1. **빌드** > **작업**으로 이동하고 `build` 작업의 로그를 확인합니다:

   ![Fortanix DSM이 성공적으로 구성되었음을 보여주는 빌드 작업 로그입니다.](img/gitlab_build_result_1_v16_9.png)

![Fortanix Data Security Manager 비밀번호 보기입니다.](img/dsm_secrets_v16_9.png)

## Fortanix DSM에서 기존 비밀번호 사용 {#use-an-existing-secret-from-fortanix-dsm}

Fortanix DSM에서 이미 존재하는 비밀번호를 GitLab에서 사용하려면:

1. 비밀번호를 Fortanix에서 내보낼 수 있는 것으로 표시해야 합니다:

   ![Fortanix Data Security Manager에서 내보낼 수 있는 비밀번호 설정입니다.](img/dsm_secret_import_1_v16_9.png)

1. 상단 표시줄에서 **검색 또는 이동**을 선택하고 프로젝트를 찾습니다.
1. 왼쪽 사이드바에서 **설정** > **CI/CD**를 선택합니다.
1. **변수**를 확장하고 다음 변수를 추가합니다:
   - `FORTANIX_API_ENDPOINT`
   - `FORTANIX_API_KEY`
   - `FORTANIX_PLUGIN_ID`

1. 프로젝트에서 `.gitlab-ci.yml` 구성 파일을 만들거나 편집하여 통합을 사용합니다:

   ```yaml
   stages:
     - build

   build:
     stage: build
     image: ubuntu
     script:
     - apt-get update
     - apt install --assume-yes jq
     - apt install --assume-yes curl
     - jq --version
     - curl --version
     - secret=$(curl --silent --request POST --header "Authorization:Basic ${FORTANIX_API_KEY}" ${FORTANIX_API_ENDPOINT}/crypto/v1/keys/export --data "{\"name\":\"${FORTANIX_SECRET_NAME}\"}" | jq --raw-output .value)
   ```

1. `.gitlab-ci.yml` 파일을 저장한 후 파이프라인이 자동으로 실행되어야 합니다. 자동으로 실행되지 않으면 **빌드** > **파이프라인** > **파이프라인 실행**을 선택합니다.
1. **빌드** > **작업**으로 이동하고 `build` 작업의 로그를 확인합니다:

   - ![기존 Fortanix 비밀번호의 성공적인 검색을 보여주는 빌드 작업 로그입니다.](img/gitlab_build_result_2_v16_9.png)

## 코드 서명 {#code-signing}

GitLab 환경에서 코드 서명을 안전하게 설정하려면:

1. Fortanix DSM 계정에 로그인합니다.
1. `keystore_password`과 `key_password`을 Fortanix DSM의 비밀번호로 가져옵니다. 비밀번호를 내보낼 수 있는 것으로 표시되어 있는지 확인합니다.

   ![Fortanix Data Security Manager에 내보낼 수 있는 것으로 가져온 키저장소 및 키 비밀번호입니다.](img/dsm_secret_import_2_v16_9.png)

1. 상단 표시줄에서 **검색 또는 이동**을 선택하고 프로젝트를 찾습니다.
1. 왼쪽 사이드바에서 **설정** > **CI/CD**를 선택합니다.
1. **변수**를 확장하고 다음 변수를 추가합니다:
   - `FORTANIX_API_ENDPOINT`
   - `FORTANIX_API_KEY`
   - `FORTANIX_SECRET_NAME_1` (`keystore_password`의 경우)
   - `FORTANIX_SECRET_NAME_2` (`key_password`의 경우)

1. 프로젝트에서 `.gitlab-ci.yml` 구성 파일을 만들거나 편집하여 통합을 사용합니다:

   ```yaml
   stages:
     - build

   build:
     stage: build
     image: ubuntu
     script:
     - apt-get update -qy
     - apt install --assume-yes jq
     - apt install --assume-yes curl
     - apt-get install wget
     - apt-get install unzip
     - apt-get install --assume-yes openjdk-8-jre-headless openjdk-8-jdk   # Install Java
     - keystore_password=$(curl --silent --request POST --header "Authorization:Basic ${FORTANIX_API_KEY}" ${FORTANIX_API_ENDPOINT}/crypto/v1/keys/export --data "{\"name\":\"${FORTANIX_SECRET_NAME_1}\"}" | jq --raw-output .value)
     - key_password=$(curl --silent --request POST --header "Authorization:Basic ${FORTANIX_API_KEY}" ${FORTANIX_API_ENDPOINT}/crypto/v1/keys/export --data "{\"name\":\"${FORTANIX_SECRET_NAME_2}\"}" | jq --raw-output .value)
     - echo "yes" | keytool -genkeypair -alias mykey -keyalg RSA -keysize 2048 -keystore keystore.jks -storepass $keystore_password -keypass $key_password -dname "CN=test"
     - mkdir -p src/main/java
     - echo 'public class HelloWorld { public static void main(String[] args) { System.out.println("Hello, World!"); } }' > src/main/java/HelloWorld.java
     - javac src/main/java/HelloWorld.java
     - mkdir -p target
     - jar cfe target/HelloWorld.jar HelloWorld -C src/main/java HelloWorld.class
     - jarsigner -keystore keystore.jks -storepass $keystore_password -keypass $key_password -signedjar signed.jar target/HelloWorld.jar mykey
   ```

1. `.gitlab-ci.yml` 파일을 저장한 후 파이프라인이 자동으로 실행되어야 합니다. 자동으로 실행되지 않으면 **빌드** > **파이프라인** > **파이프라인 실행**을 선택합니다.
1. **빌드** > **작업**으로 이동하고 `build` 작업의 로그를 확인합니다:

   - ![Fortanix 비밀번호를 사용하는 코드 서명 프로세스를 보여주는 빌드 작업 로그입니다.](img/gitlab_build_result_3_v16_9.png)
