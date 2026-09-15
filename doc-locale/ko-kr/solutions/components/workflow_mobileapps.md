---
stage: Solutions Architecture
group: Solutions Architecture
info: This page is owned by the Solutions Architecture team.
description: "하이브리드 React Native 모바일 앱을 위한 GitLab DevSecOps 워크플로우에 대해 알아봅니다. CI/CD 설정, Snyk 보안 스캔, Sauce Labs 기능 테스트, ServiceNow 통합이 포함됩니다."
title: DevSecOps 워크플로우 - 모바일 앱
---

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

이 문서는 하이브리드(React Native) 모바일 앱을 구축하고 제공하기 위한 GitLab DevSecOps 워크플로우 솔루션의 지침과 기능 세부 정보를 제공합니다.

fastlane을 사용하는 네이티브 모바일 애플리케이션의 경우 제품 설명서를 참조하세요.

지침에는 [**React Native**](https://reactnative.dev) 샘플 애플리케이션이 포함되어 있으며, `react-native-community/cli`를 사용하여 부트스트랩되었으며, iOS 및 Android 디바이스 모두에서 크로스 플랫폼 솔루션을 제공합니다. GitLab CI/CD 파이프라인을 사용하여 모바일 애플리케이션을 구축, 테스트 및 배포하기 위한 엔드투엔드 솔루션을 제공합니다.

## 시작하기 {#getting-started}

GitLab을 사용하여 모바일 애플리케이션 제공을 빠르게 시작하기 위해 이 React Native 모바일 앱 샘플 프로젝트를 사용하는 방법을 알아보려면 아래 단계를 따르세요.

### 솔루션 구성 요소 다운로드 {#download-the-solution-component}

1. 계정 팀으로부터 초대 코드를 입수합니다.
1. 초대 코드를 사용하여 [솔루션 구성 요소 웹스토어](https://cloud.gitlab-accelerator-marketplace.com)에서 솔루션 구성 요소를 다운로드합니다.

### 솔루션 구성 요소 프로젝트 설정 {#set-up-the-solution-component-project}

- Product Accelerator 마켓플레이스의 모바일 앱 솔루션 구성 요소가 다운로드되었습니다. 솔루션 팩에는 CI/CD 파일이 포함된 모바일 앱 샘플 프로젝트가 포함됩니다.
- 새 GitLab CI/CD 카탈로그 프로젝트를 만들어 환경에서 Snyk 구성 요소를 호스팅합니다. 모바일 앱 솔루션 팩에는 Snyk CI/CD 구성 요소 프로젝트 파일이 포함되어 있어 Snyk CI/CD 카탈로그 프로젝트를 설정할 수 있습니다.
  1. 이 Snyk CI/CD 카탈로그 프로젝트를 호스팅하기 위해 새 GitLab 프로젝트를 만드세요.
  1. 제공된 파일을 프로젝트에 복사하세요.
  1. 프로젝트 설정에서 필요한 CI/CD 변수를 구성합니다.
  1. 프로젝트가 CI/CD 카탈로그 프로젝트로 표시되었는지 확인하세요. 자세한 내용은 [구성 요소 프로젝트 게시](../../ci/components/_index.md#publish-a-component-project)를 참조하세요.

  > [!note]
  > GitLab.com에서 공개 GitLab Snyk 구성 요소를 사용할 수 있습니다. 공개 GitLab Snyk 구성 요소에 액세스할 수 있다면, 자신의 Snyk CI/CD 카탈로그 프로젝트를 설정할 필요가 없습니다. 대신 설명서에 따라 공개 구성 요소를 직접 사용하세요.

- ServiceNow 솔루션 팩으로 Change Control 워크플로우를 사용하여 GitLab과의 DevOps Change Velocity 통합을 구성하면, 변경 제어가 필요한 배포에 대해 ServiceNow에서 변경 요청 생성을 자동화할 수 있습니다. [ServiceNow 솔루션 구성 요소가 있는 Change Control 워크플로우](integrated_servicenow.md)의 설명서를 참조하고, 계정 팀과 함께 ServiceNow 솔루션 패키지가 있는 Change Control 워크플로우를 다운로드할 액세스 코드를 받으세요.
- CI/CD YAML 파일을 프로젝트에 복사합니다:
  - `.gitlab-ci.yml`
  - `build-android.yml`는 pipelines 디렉토리에 있습니다. `build-android.yml` 파일이 /pipeline이 아닌 다른 위치에 있는 경우, `.gitlab-ci.yml`에서 파일 경로를 업데이트해야 합니다. 메인 `.gitlab-ci.yml` 파일은 빌드 작업을 위해 `build-android.yml` 파일을 참조하기 때문입니다.
  - `build-ios.yml`는 pipelines 디렉토리에 있습니다. `build-ios.yml` 파일이 /pipeline이 아닌 다른 위치에 있는 경우, `.gitlab-ci.yml`에서 파일 경로를 업데이트해야 합니다. 메인 `.gitlab-ci.yml` 파일은 빌드 작업을 위해 `build-ios.yml` 파일을 참조하기 때문입니다.

  ```yaml
  include:
    - local: "pipelines/build-ios.yml"
      inputs:
        image: macos-15-xcode-16
        tag: saas-macos-medium-m1
    - local: "pipelines/build-android.yml"
      inputs:
        image: reactnativecommunity/react-native-android
  ```

- 프로젝트 설정에서 필요한 CI/CD 변수를 구성합니다. 파이프라인이 어떻게 작동하는지 알아보려면 다음 섹션을 참조하세요.

## 파이프라인이 어떻게 작동하는지 {#how-the-pipeline-works}

이 파이프라인은 React Native 프로젝트를 위해 설계되었으며, iOS 및 Android 빌드를 처리하고, 모바일 앱을 테스트하고 배포합니다.

이 프로젝트에는 iOS 및 Android 모두를 위한 React Native 빌드를 위한 간단한 reactCounter 데모 앱이 포함됩니다. 이 버전은 아직 아티팩트에 서명하지 않으므로 TestFlight 또는 Play Store에 업로드할 수 없습니다.

각 변경 사항은 시멘틱 버전 관리 범프를 위한 구성 요소를 사용하며, 해당 버전은 패키지 레지스트리에 제네릭 패키지를 커밋하는 데 사용되는 임시 변수로 저장됩니다.

## 파이프라인 구조 {#pipeline-structure}

파이프라인은 다음 스테이지와 작업으로 구성됩니다:

1. `prebuild`
   - `unit test`
   - `Snyk scans`
1. `build`
   - `build IoS package`
   - `build Android package`
1. `test`
   - `dependency scanning`
   - `SAST scanning`
1. `functional-test`
   - `upload_ios/android_app_to_sauce_labs`
   - `automated_test_appium_saucelabs`
1. `app-distribution`
   - `app_distribution_sauce_android`
   - `app_distribution_sauce_ios`
1. `beta-release`
   - `beta-release-dev`
   - `beta-release-approval`

## 전제 조건 {#prerequisites}

모바일 파이프라인 워크플로우에는 여러 타사 도구가 통합되어 있습니다. 파이프라인을 성공적으로 실행하려면, 다음 필수 조건이 충족되었는지 확인합니다.

### 구성 요소를 사용한 Snyk 통합 {#snyk-integration-using-the-component}

보안 스캔을 위해 GitLab Snyk CI/CD 구성 요소를 사용하려면, GitLab의 그룹 또는 프로젝트가 이미 Snyk과 연결되어 있는지 확인합니다. 그렇지 않으면, 구성하려면 [이 튜토리얼](https://docs.snyk.io/scm-ide-and-ci-cd-integrations/snyk-scm-integrations/gitlab)을 따르세요.

모바일 앱 프로젝트에서, Snyk 통합을 위해 필요한 변수를 추가합니다.

#### 필요한 CI/CD 변수 {#required-cicd-variables}

| 변수 | 설명 | 예시 값 |
|----------|-------------|---------------|
| `SNYK_TOKEN` | Snyk에 액세스하기 위한 API 토큰 | `d7da134c-xxxxxxxxxx` |

이 모바일 앱 데모 프로젝트는 프라이빗 Snyk 구성 요소를 사용하므로, 모바일 앱 프로젝트이 프라이빗 Snyk 구성 요소 프로젝트에 액세스할 수 있도록 하기 위해 다음 추가 변수를 추가한 이유이지만, Snyk 구성 요소가 공개이거나 그룹 내에서 액세스 가능한 경우에는 필요하지 않습니다.

```yaml
SNYK_PROJECT_ACCESS_USERNAME: "MOBILE_APP_SNYK_COMPONENT_ACCESS"
DOCKER_AUTH_CONFIG: '{"auths":{"registry.gitlab.com":{"username":"$SNYK_PROJECT_ACCESS_USERNAME","password":"$SNYK_PROJECT_ACCESS_TOKEN"}}}'
```

#### 구성 요소 경로 업데이트 {#update-the-component-path}

`.gitlab-ci.yml` 파일의 구성 요소 경로를 업데이트하여 파이프라인이 Snyk 구성 요소를 성공적으로 참조할 수 있도록 합니다.

```yaml
 - component: $CI_SERVER_FQDN/gitlab-com/product-accelerator/work-streams/packaging/snyk/snyk@1.0.0 #snky sast scan, this examples uses the component in GitLab the product accelerator group. Please update the path and stage accordingly.
    inputs:
      stage: prebuild
      token: $SNYK_TOKEN
```

### Sauce Labs 통합 {#sauce-labs-integration}

이 모바일 앱 데모 프로젝트 CI/CD는 자동화된 기능 테스트를 위해 Sauce Labs과 통합됩니다. Sauce Labs에서 자동화된 테스트를 실행하려면, 애플리케이션을 Sauce Labs 앱 스토리지에 업로드해야 합니다. GitLab의 프로젝트에 대해 필요한 변수를 설정하여 Sauce Labs에 액세스하고 아티팩트를 업로드해야 합니다.

#### 필요한 CI/CD 변수 {#required-cicd-variables-1}

| 변수 | 설명 | 예시 값 |
|----------|-------------|---------------|
| `SAUCE_USERNAME` | Sauce Labs 사용자 이름| `rz` |
| `SAUCE_ACCESS_KEY` | Sauce Labs에 액세스하기 위한 API 키  | `9f5wewwc-xxxxxxx` |
| `APP_FILE_PATH_IOS` | 빌드 아티팩트를 찾기 위한 파일 경로 | `ios/build/reactCounter.ipa` |
| `APP_FILE_PATH_ANDROID` | 빌드 아티팩트를 찾기 위한 파일 경로 | `android/app/build/outputs/apk/release/app-release.apk` |

#### 자동화된 테스트를 위해 Appium 사용 {#use-appium-for-automated-testing}

자동화된 테스트를 위해 SauceLabs를 사용하려면, 앱을 SauceLab App Management에 업로드해야 합니다. 파이프라인은 API 끝점을 사용하여 앱을 SauceLabs에 업로드하고 테스트에 사용할 수 있도록 합니다.

`tests/appium`에 Appium 테스트 스크립트 파일을 추가하여 WebdriverIO 및 Sauce Labs를 사용하여 React Native 모바일 애플리케이션을 테스트합니다. 테스트 스크립트는 다음 환경 변수를 사용하여 SauceLabs에 액세스합니다.

``` bash
# Using the variables defined in the project

const SAUCE_USERNAME = process.env.SAUCE_USERNAME;
const SAUCE_ACCESS_KEY = process.env.SAUCE_ACCESS_KEY;

```

#### 앱 배포(Android 및 iOS) {#app-distribution-android-and-ios}

GitLab 파이프라인은 앱 빌드를 SauceLabs TestFairy에 배포합니다(데모 목적). SauceLabs TestFairy를 사용하면 테스터가 검토 및 테스트를 위해 앱의 새 버전을 받을 수 있습니다.

### ServiceNow 통합 {#servicenow-integration}

이 모바일 앱 데모 프로젝트 CI/CD는 변경 제어를 위해 ServiceNow과 통합됩니다. 파이프라인이 ServiceNow에서 변경 제어가 활성화된 배포 작업에 도달하면, 자동으로 변경 요청을 만듭니다. 변경 요청이 승인되면, 배포 작업이 재개됩니다. 이 데모 프로젝트에서는 베타 릴리스 승인 작업이 ServiceNow에서 제어되며 계속하려면 수동 승인이 필요합니다.

#### CI/CD 변수 {#cicd-variables}

파이프라인이 ServiceNow과 통신하려면, 웹후크 통합을 생성해야 합니다. ServiceNow과 통신하기 위해 API 끝점을 사용하는 경우, 다음 변수를 포함해야 합니다. 그러나 ServiceNow DevOps Change Velocity 통합을 사용할 때는 필수가 아닙니다. ServiceNow DevOps Change Velocity 온보딩의 일부로, 웹후크가 생성됩니다.

| 변수 | 설명 | 예시 값 |
|----------|-------------|---------------|
| `SNOW_URL` | ServiceNow 인스턴스의 URL| `https://<SNOW_INSTANCE>.com/` |
| `SNOW_TOOLID` | ServiceNow 인스턴스 ID  | `3b5w345629212105c5ddaccwonworw2` |
| `SNOW_TOKEN` | ServiceNow에 액세스하기 위한 API 토큰| `Oxxxxxxxxxx` |

## 포함된 파일 및 구성 요소 {#included-files-and-components}

모바일 앱 프로젝트 파이프라인에는 여러 외부 구성 및 구성 요소가 포함됩니다:

- iOS 및 Android용 로컬 빌드 구성
- SAST(정적 애플리케이션 보안 테스트) 구성 요소
- 자동 시멘틱 버전 관리 구성 요소
- 종속성 검사
- Snyk SAST 스캔 구성 요소

## 참고 {#notes}

솔루션 구성 요소에 액세스하기 위한 초대 코드를 얻기 위해 또는 추가 질문이 있으면 계정 팀에 문의하세요.
