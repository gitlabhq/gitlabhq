---
stage: Production Engineering
group: Runners Platform
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: macOS의 호스팅 러너
---

{{< details >}}

- 계층: Premium, Ultimate
- 제공 서비스: GitLab.com
- 상태: 베타

{{< /details >}}

macOS의 호스팅 러너는 GitLab [CI/CD](../../_index.md)와 완전히 통합된 온디맨드 macOS 환경을 제공합니다. 이 러너를 사용하여 Apple 생태계(macOS, iOS, watchOS, tvOS)용 앱을 빌드, 테스트 및 배포할 수 있습니다. 당사의 [Mobile DevOps 섹션](../../mobile_devops/mobile_devops_tutorial_ios.md#set-up-your-build-environment)은 iOS용 모바일 애플리케이션 빌드 및 배포에 대한 기능, 설명서 및 지침을 제공합니다.

macOS의 호스팅 러너는 [베타](../../../policy/development_stages_support.md#beta) 상태이며 오픈소스 프로그램 및 Premium, Ultimate 플랜 고객에게 제공됩니다. macOS의 호스팅 러너의 [일반 공급](../../../policy/development_stages_support.md#generally-available)은 [에픽 8267](https://gitlab.com/groups/gitlab-org/-/epics/8267)에서 제안되었습니다.

macOS의 호스팅 러너를 사용하기 전에 이를 영향하는 [알려진 문제 및 사용 제약](#known-issues-and-usage-constraints) 목록을 검토하세요.

## macOS에서 사용 가능한 머신 유형 {#machine-types-available-for-macos}

GitLab은 macOS의 호스팅 러너를 위해 다음과 같은 머신 유형을 제공합니다. x86-64 대상으로 빌드하려면 Rosetta 2를 사용하여 Intel x86-64 환경을 에뮬레이트할 수 있습니다.

| 러너 태그               | vCPUS | 메모리 | 저장소 |
| ------------------------ | ----- | ------ | ------- |
| `saas-macos-medium-m1`   | 4     | 8 GB   | 50 GB   |
| `saas-macos-large-m2pro` | 6     | 16 GB  | 50 GB   |

## 지원되는 macOS 이미지 {#supported-macos-images}

Linux의 호스팅 러너와 달리 모든 Docker 이미지를 실행할 수 있으므로, GitLab은 macOS용 VM 이미지 세트를 제공합니다.

다음 이미지 중 하나에서 빌드를 실행할 수 있으며, 이를 `.gitlab-ci.yml` 파일에서 지정합니다. 각 이미지는 특정 버전의 macOS 및 Xcode를 실행합니다.

| VM 이미지                   | 상태       |              |
|----------------------------|--------------|--------------|
| `macos-14-xcode-15`        | `deprecated` | [사전 설치된 소프트웨어](https://gitlab-org.gitlab.io/ci-cd/shared-runners/images/macos-image-inventory/macos-14-xcode-15/) |
| `macos-15-xcode-16`        | `GA`         | [사전 설치된 소프트웨어](https://gitlab-org.gitlab.io/ci-cd/shared-runners/images/macos-image-inventory/macos-15-xcode-16/) |
| `macos-26-xcode-26`        | `GA`         | [사전 설치된 소프트웨어](https://gitlab-org.gitlab.io/ci-cd/shared-runners/images/macos-image-inventory/macos-26-xcode-26/) |

이미지가 지정되지 않으면 macOS 러너는 `macos-15-xcode-16`을 사용합니다.

## macOS의 이미지 업데이트 정책 {#image-update-policy-for-macos}

이미지 및 설치된 구성 요소는 각 GitLab 릴리스마다 업데이트되어 사전 설치된 소프트웨어를 최신 상태로 유지합니다. GitLab은 일반적으로 사전 설치된 소프트웨어의 여러 버전을 지원합니다. 자세한 내용은 [사전 설치된 소프트웨어의 전체 목록](https://gitlab.com/gitlab-org/ci-cd/shared-runners/images/job-images/-/tree/main/toolchain)을 참조하세요.

macOS 및 Xcode의 주요 및 부 릴리스는 Apple 릴리스 이후의 마일스톤에서 제공됩니다.

새로운 주요 릴리스 이미지는 처음에는 베타로 제공되며, 첫 번째 부 릴리스의 출시와 함께 일반 공급이 됩니다. 한 번에 두 개의 일반 공급 이미지만 지원되기 때문에, 가장 오래된 이미지는 더 이상 지원되며 [지원되는 이미지 수명 주기](_index.md#supported-image-lifecycle)에 따라 3개월 후에 제거됩니다.

새로운 주요 릴리스가 일반 공급되면, 모든 macOS 작업의 기본 이미지가 됩니다.

## `.gitlab-ci.yml` 파일 예시 {#example-gitlab-ciyml-file}

다음 샘플 `.gitlab-ci.yml` 파일은 macOS의 호스팅 러너를 사용하여 시작하는 방법을 보여줍니다:

```yaml
.macos_saas_runners:
  tags:
    - saas-macos-medium-m1
  image: macos-14-xcode-15
  before_script:
    - echo "started by ${GITLAB_USER_NAME} / @${GITLAB_USER_LOGIN}"

build:
  extends:
    - .macos_saas_runners
  stage: build
  script:
    - echo "running scripts in the build job"

test:
  extends:
    - .macos_saas_runners
  stage: test
  script:
    - echo "running scripts in the test job"
```

## fastlane을 사용한 iOS 프로젝트 코드 서명 {#code-signing-ios-projects-with-fastlane}

GitLab을 Apple 서비스와 통합하거나, 기기에 설치하거나, Apple App Store에 배포하기 전에 애플리케이션을 [코드 서명](https://developer.apple.com/documentation/security/code_signing_services)해야 합니다.

macOS VM 이미지의 각 러너에 포함된 것은 [fastlane](https://fastlane.tools/)이며, 모바일 앱 배포를 단순화하기 위한 오픈소스 솔루션입니다.

애플리케이션에 대한 코드 서명을 설정하는 방법에 대한 자세한 내용은 [Mobile DevOps 문서](../../mobile_devops/mobile_devops_tutorial_ios.md#configure-code-signing-with-fastlane)의 지침을 참조하세요.

관련 주제:

- [Apple 개발자 지원 - 코드 서명](https://forums.developer.apple.com/forums/thread/707080)
- [코드 서명 모범 사례 가이드](https://codesigning.guide/)
- [fastlane Apple Services 인증 가이드](https://docs.fastlane.tools/getting-started/ios/authentication/)

## Homebrew 최적화 {#optimizing-homebrew}

기본적으로 Homebrew는 모든 작업을 시작할 때 업데이트를 확인합니다. Homebrew는 GitLab macOS 이미지 릴리스 주기보다 더 자주 릴리스될 수 있는 릴리스 주기를 가지고 있습니다. 이 릴리스 주기의 차이로 인해 `brew`을 호출하는 단계가 Homebrew가 업데이트되는 동안 완료하는 데 추가 시간이 걸릴 수 있습니다.

의도하지 않은 Homebrew 업데이트로 인한 빌드 시간을 줄이려면 `HOMEBREW_NO_AUTO_UPDATE` 변수를 `.gitlab-ci.yml`에서 설정하세요:

```yaml
variables:
  HOMEBREW_NO_AUTO_UPDATE: 1
```

## CocoaPods 최적화 {#optimizing-cocoapods}

프로젝트에서 CocoaPods를 사용하는 경우 CI 성능을 개선하기 위해 다음과 같은 최적화를 고려해야 합니다.

**CocoaPods CDN**

콘텐츠 배포 네트워크(CDN) 액세스를 사용하여 전체 프로젝트 리포지토리를 복제하는 대신 CDN에서 패키지를 다운로드할 수 있습니다. CDN 액세스는 CocoaPods 1.8 이상에서 사용 가능하며 모든 GitLab macOS 호스팅 러너에서 지원됩니다.

CDN 액세스를 활성화하려면 Podfile이 다음으로 시작되는지 확인하세요:

```ruby
source 'https://cdn.cocoapods.org/'
```

**Use GitLab caching**

GitLab의 CocoaPods 패키지에서 캐싱을 사용하여 pods가 변경될 때만 `pod install`을 실행하면 빌드 성능을 향상시킬 수 있습니다.

프로젝트에 대해 [캐싱을 구성](../../caching/_index.md)하려면:

1. `cache` 구성을 `.gitlab-ci.yml` 파일에 추가하세요:

   ```yaml
   cache:
     key:
       files:
        - Podfile.lock
   paths:
     - Pods
   ```

1. [`cocoapods-check`](https://guides.cocoapods.org/plugins/optimising-ci-times.html) 플러그인을 프로젝트에 추가하세요.
1. 작업 스크립트를 업데이트하여 `pod install`을 호출하기 전에 설치된 종속성을 확인하세요:

   ```shell
   bundle exec pod check || bundle exec pod install
   ```

**Include pods in source control**

[소스 제어에 pods 디렉토리를 포함](https://guides.cocoapods.org/using/using-cocoapods.html#should-i-check-the-pods-directory-into-source-control)할 수도 있습니다. 이렇게 하면 CI 작업의 일부로 pods를 설치할 필요가 없지만 프로젝트의 리포지토리 전체 크기가 증가합니다.

## 알려진 문제 및 사용 제약 {#known-issues-and-usage-constraints}

- VM 이미지가 작업에 필요한 특정 소프트웨어 버전을 포함하지 않으면 필수 소프트웨어를 가져와서 설치해야 합니다. 이로 인해 작업 실행 시간이 증가합니다.
- 자신의 OS 이미지를 사용하는 것은 불가능합니다.
- `gitlab` 사용자의 키체인을 공개적으로 사용할 수 없습니다. 대신 키체인을 만들어야 합니다.
- macOS의 호스팅 러너는 헤드리스 모드에서 실행됩니다. `testmanagerd`과 같은 UI 상호 작용이 필요한 모든 워크로드는 지원되지 않습니다.
- Apple 실리콘 칩은 효율성 및 성능 코어를 가지고 있기 때문에 작업 실행 간 작업 성능이 달라질 수 있습니다. 코어 할당 또는 스케줄링을 제어할 수 없으며, 이로 인해 불일치가 발생할 수 있습니다.
- macOS의 호스팅 러너에 사용되는 AWS 베어 메탈 macOS 머신의 가용성이 제한되어 있습니다. 작업은 사용 가능한 머신이 없을 때 확장된 대기 시간을 경험할 수 있습니다.
- macOS의 호스팅 러너 인스턴스는 때때로 요청에 응답하지 않으며, 이로 인해 작업이 최대 작업 기간에 도달할 때까지 중단됩니다.
- macOS는 기본적으로 대소문자를 구분하지 않는 파일 시스템을 사용합니다. 대소문자를 제외하고는 동일한 중복 파일 경로가 있으면 예상치 못한 오류가 발생할 수 있습니다. 이러한 중복 경로는 Git 작업 트리 또는 브랜치와 태그가 저장되는 Git 참조에 있을 수 있습니다.
