---
stage: Verify
group: Mobile DevOps
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: '튜토리얼: GitLab Mobile DevOps로 iOS 앱 빌드하기'
---

이 튜토리얼에서는 GitLab CI/CD를 사용하여 파이프라인을 만들어 iOS 모바일 앱을 빌드하고, 자신의 자격증명으로 서명하고, 앱 스토어에 배포합니다.

모바일 DevOps를 설정하려면:

1. [빌드 환경 설정](#set-up-your-build-environment)
1. [fastlane으로 코드 서명 구성](#configure-code-signing-with-fastlane)
1. [Apple Store 연동 및 fastlane으로 앱 배포 설정](#set-up-app-distribution-with-apple-store-integration-and-fastlane)

## 시작하기 전에 {#before-you-begin}

이 튜토리얼을 시작하기 전에 다음을 확인하세요:

- CI/CD 파이프라인에 액세스할 수 있는 GitLab 계정
- GitLab 리포지토리에 있는 모바일 앱 코드
- Apple 개발자 계정
- [`fastlane`](https://fastlane.tools)이(가) 로컬에 설치됨

## 빌드 환경 설정 {#set-up-your-build-environment}

[GitLab 호스팅 러너](../runners/_index.md)를 사용하거나 빌드 환경을 완전히 제어하기 위해 [자체 관리 러너](https://docs.gitlab.com/runner/#use-self-managed-runners)를 설정합니다.

1. 리포지토리 루트에 `.gitlab-ci.yml` 파일을 만듭니다.
1. [지원되는 macOS 이미지](../runners/hosted_runners/macos.md#supported-macos-images)를 추가하여 [macOS GitLab 호스팅 러너](../runners/hosted_runners/macos.md)에서 작업을 실행합니다(베타):

   ```yaml
   test:
     image: macos-14-xcode-15
     stage: test
     script:
       - fastlane test
     tags:
       - saas-macos-medium-m1
   ```

## fastlane으로 코드 서명 구성 {#configure-code-signing-with-fastlane}

iOS용 코드 서명을 설정하려면 fastlane을 사용하여 서명된 인증서를 GitLab에 업로드합니다:

1. fastlane을 초기화합니다:

   ```shell
   fastlane init
   ```

1. 구성으로 `Matchfile`을(를) 생성합니다:

   ```shell
   fastlane match init
   ```

1. Apple Developer 포털에서 인증서 및 프로필을 생성하고 이러한 파일을 GitLab에 업로드합니다:

   ```shell
   PRIVATE_TOKEN=YOUR-TOKEN bundle exec fastlane match development
   ```

1. 선택 사항. 프로젝트에 대한 서명 인증서 및 프로비저닝 프로필을 이미 만든 경우 `fastlane match import`을(를) 사용하여 기존 파일을 GitLab에 로드합니다:

   ```shell
   PRIVATE_TOKEN=YOUR-TOKEN bundle exec fastlane match import
   ```

파일 경로를 입력하라는 메시지가 표시됩니다. 해당 정보를 입력한 후 파일이 업로드되고 프로젝트의 CI/CD 설정에 표시됩니다. 가져오는 중에 `git_url`에 대한 메시지가 표시되면 공백으로 두고 <kbd>Enter</kbd> 키를 누르는 것이 안전합니다.

다음은 이 구성을 포함한 샘플 `fastlane/Fastfile` 및 `.gitlab-ci.yml` 파일입니다:

- `fastlane/Fastfile`:

  ```ruby
  default_platform(:ios)

  platform :ios do
    desc "Build and sign the application for development"
    lane :build do
      setup_ci

      match(type: 'development', readonly: is_ci)

      build_app(
        project: "ios demo.xcodeproj",
        scheme: "ios demo",
        configuration: "Debug",
        export_method: "development"
      )
    end
  end
  ```

- `.gitlab-ci.yml`:

  ```yaml
  build_ios:
    image: macos-12-xcode-14
    stage: build
    script:
      - fastlane build
    tags:
      - saas-macos-medium-m1
  ```

## Apple Store 연동 및 fastlane으로 앱 배포 설정 {#set-up-app-distribution-with-apple-store-integration-and-fastlane}

서명된 빌드는 Mobile DevOps Distribution 연동을 사용하여 Apple App Store에 업로드할 수 있습니다.

전제 조건:

- Apple Developer Program에 등록된 Apple ID가 있어야 합니다.
- Apple App Store Connect 포털에서 프로젝트에 대한 새 개인 키를 생성해야 합니다.

Apple Store 연동 및 fastlane으로 iOS 배포를 만들려면:

1. App Store Connect API용 API 키를 생성합니다. Apple App Store Connect 포털에서 [프로젝트에 대한 새 개인 키를 생성](https://developer.apple.com/documentation/appstoreconnectapi/creating_api_keys_for_app_store_connect_api)합니다.
1. Apple App Store Connect 연동을 활성화합니다:
   1. 상단 표시줄에서 **검색 또는 이동**을 선택하고 프로젝트를 찾습니다.
   1. **설정** > **연동**을 선택합니다.
   1. **Apple App Store Connect**를 선택합니다.
   1. **통합 활성화** 아래에서 **활성** 확인란을 선택합니다.
   1. Apple App Store Connect 구성 정보를 제공합니다:
      - **Issuer ID**: Apple App Store Connect 발급자 ID입니다.
      - **Key ID**: 생성된 개인 키의 키 ID입니다.
      - **개인 키**: 생성된 개인 키입니다. 이 키는 한 번만 다운로드할 수 있습니다.
      - **보호된 브랜치 및 태그만**: 보호된 브랜치 및 태그에서만 변수를 설정하도록 활성화합니다.
   1. **변경사항 저장**을 선택합니다.
1. 릴리스 단계를 파이프라인 및 fastlane 구성에 추가합니다.

다음은 샘플 `fastlane/Fastfile`입니다:

```ruby
default_platform(:ios)

platform :ios do
  desc "Build and sign the application for distribution, upload to TestFlight"
  lane :beta do
    setup_ci

    match(type: 'appstore', readonly: is_ci)

    app_store_connect_api_key

    increment_build_number(
      build_number: latest_testflight_build_number(initial_build_number: 1) + 1,
      xcodeproj: "ios demo.xcodeproj"
    )

    build_app(
      project: "ios demo.xcodeproj",
      scheme: "ios demo",
      configuration: "Release",
      export_method: "app-store"
    )

    upload_to_testflight
  end
end
```

다음은 샘플 `.gitlab-ci.yml`입니다:

```yaml
beta_ios:
  image: macos-12-xcode-14
  stage: beta
  script:
    - fastlane beta
```

축하합니다! 이제 앱이 자동 빌드, 서명 및 배포에 대해 설정되었습니다. 첫 번째 파이프라인을 트리거하기 위해 머지 리퀘스트를 만들어 보세요.

## 샘플 프로젝트 {#sample-projects}

모바일 앱을 빌드, 서명 및 릴리스하도록 구성된 파이프라인을 사용하는 샘플 Mobile DevOps 프로젝트를 사용할 수 있습니다:

- Android
- Flutter
- iOS

[Mobile DevOps Demo Projects](https://gitlab.com/gitlab-org/incubation-engineering/mobile-devops/demo-projects/) 그룹에서 모든 프로젝트를 확인합니다.
