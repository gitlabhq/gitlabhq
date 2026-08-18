---
stage: Verify
group: Mobile DevOps
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: '튜토리얼: GitLab Mobile DevOps로 Android 앱 빌드'
---

이 튜토리얼에서는 GitLab CI/CD를 사용하여 을 생성하여 Android 모바일 앱을 빌드하고, 자격증으로 서명하며, 앱 스토어에 배포합니다.

Mobile DevOps를 설정하려면:

1. [빌드 환경 설정](#set-up-your-build-environment)
1. [fastlane 및 Gradle을 사용한 코드 서명 구성](#configure-code-signing-with-fastlane-and-gradle)
1. [Google Play 연동 및 fastlane을 사용한 Android 앱 배포 설정](#set-up-android-apps-distribution-with-google-play-integration-and-fastlane)

## 시작하기 전에 {#before-you-begin}

이 튜토리얼을 시작하기 전에 다음을 확인하세요:

- CI/CD 에 액세스할 수 있는 GitLab 계정
- GitLab 의 모바일 앱 코드
- Google Play 개발자 계정
- [`fastlane`](https://fastlane.tools) 로컬에 설치됨

## 빌드 환경 설정 {#set-up-your-build-environment}

[GitLab 호스팅](../runners/_index.md)를 사용하거나, 빌드 환경을 완전하게 제어하기 위해 [자체 관리](https://docs.gitlab.com/runner/#use-self-managed-runners)를 설정합니다.

Android 빌드는 Docker 이미지를 사용하여 여러 Android API 버전을 제공합니다.

1. `.gitlab-ci.yml` 파일을 리포지토리 루트에 생성합니다.
1. [Fabernovel](https://hub.docker.com/r/fabernovel/android/tags)에서 Docker 이미지를 추가합니다:

   ```yaml
   test:
     image: fabernovel/android:api-33-v1.7.0
     stage: test
     script:
       - fastlane test
   ```

## fastlane 및 Gradle을 사용한 코드 서명 구성 {#configure-code-signing-with-fastlane-and-gradle}

Android에 대한 코드 서명을 설정하려면:

1. 키스토어 생성:

   1. 다음 명령을 실행하여 키스토어 파일을 생성합니다:

      ```shell
      keytool -genkey -v -keystore release-keystore.jks -storepass password -alias release -keypass password \
      -keyalg RSA -keysize 2048 -validity 10000
      ```

   1. `release-keystore.properties` 파일에 키스토어 구성을 입력합니다:

      ```plaintext
      storeFile=.secure_files/release-keystore.jks
      keyAlias=release
      keyPassword=password
      storePassword=password
      ```

   1. 두 파일을 프로젝트 설정에서 [Secure Files](../secure_files/_index.md)로 업로드합니다.
   1. 두 파일을 `.gitignore` 파일에 추가하여 버전 제어에 되지 않도록합니다.
1. 새로 생성된 키스토어를 사용하도록 Gradle을 구성합니다. 앱의 `build.gradle` 파일에서:

   1. 플러그인 섹션 바로 뒤에 추가합니다:

      ```gradle
      def keystoreProperties = new Properties()
      def keystorePropertiesFile = rootProject.file('.secure_files/release-keystore.properties')
      if (keystorePropertiesFile.exists()) {
        keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
      }
      ```

   1. `android` 블록의 어디든지 추가합니다:

      ```gradle
      signingConfigs {
        release {
          keyAlias keystoreProperties['keyAlias']
          keyPassword keystoreProperties['keyPassword']
          storeFile keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
          storePassword keystoreProperties['storePassword']
        }
      }
      ```

   1. `signingConfig`을(를) 릴리스 빌드 타입에 추가합니다:

      ```gradle
      signingConfig signingConfigs.release
      ```

다음은 이 구성이 포함된 샘플 `fastlane/Fastfile` 및 `.gitlab-ci.yml` 파일입니다:

- `fastlane/Fastfile`:

  ```ruby
  default_platform(:android)

  platform :android do
    desc "Create and sign a new build"
    lane :build do
      gradle(tasks: ["clean", "assembleRelease", "bundleRelease"])
    end
  end
  ```

- `.gitlab-ci.yml`:

  ```yaml
  build:
    image: fabernovel/android:api-33-v1.7.0
    stage: build
    script:
      - apt update -y && apt install -y curl
      - wget https://gitlab.com/gitlab-org/cli/-/releases/v1.74.0/downloads/glab_1.74.0_linux_amd64.deb
      - apt install ./glab_1.74.0_linux_amd64.deb
      - glab auth login --hostname $CI_SERVER_FQDN --job-token $CI_JOB_TOKEN
      - glab securefile download --all --output-dir .secure_files/
      - fastlane build
  ```

## Google Play 연동 및 fastlane을 사용한 Android 앱 배포 설정 {#set-up-android-apps-distribution-with-google-play-integration-and-fastlane}

서명된 빌드는 Mobile DevOps Distribution 통합을 사용하여 Google Play 스토어에 업로드할 수 있습니다.

1. Google Cloud Platform에서 [Google 생성](https://docs.fastlane.tools/actions/supply/#setup)하고 Google Play의 프로젝트에 해당 계정 액세스 권한을 부여합니다.
1. 연동 활성화:
   1. 상단 표시줄에서 **검색 또는 이동**을 선택하고 프로젝트를 찾습니다.
   1. **설정** > **연동**을 선택합니다.
   1. **구글 플레이**를 선택합니다.
   1. **통합 활성화** 아래에서 **활성** 체크박스를 선택합니다.
   1. **Package name**에 앱의 패키지 이름을 입력합니다. 예를 들어, `com.gitlab.app_name`입니다.
   1. **서비스 계정 키(.JSON)**에서 키 파일을 드래그하거나 업로드합니다.
   1. **변경사항 저장**을 선택합니다.
1. 단계를 에 추가합니다.

다음은 샘플 `fastlane/Fastfile`입니다:

```ruby
default_platform(:android)

platform :android do
  desc "Submit a new Beta build to the Google Play store"
  lane :beta do
    upload_to_play_store(
      track: 'internal',
      aab: 'app/build/outputs/bundle/release/app-release.aab',
      release_status: 'draft'
    )
  end
end
```

다음은 샘플 `.gitlab-ci.yml`입니다:

```yaml
beta:
  image: fabernovel/android:api-33-v1.7.0
  stage: beta
  script:
    - fastlane beta
```

<i class="fa-youtube-play" aria-hidden="true"></i> 개요를 보려면 [Google Play 연동 데모](https://youtu.be/Fxaj3hna4uk)를 참조하세요.

축하합니다! 이제 앱이 자동 빌드, 서명 및 배포를 위해 설정되었습니다. 를 생성하여 첫 을 트리거해보세요.

## 관련 항목 {#related-topics}

Mobile DevOps [Android Demo](https://gitlab.com/gitlab-org/incubation-engineering/mobile-devops/demo-projects/android_demo) 프로젝트에서 Android의 완전한 빌드, 서명 및 예제를 확인하세요.

추가 참고 자료는 GitLab 블로그의 [DevSecOps 섹션](https://about.gitlab.com/blog/categories/devsecops/)을 참조하세요.
