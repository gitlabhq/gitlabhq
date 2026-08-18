---
stage: Verify
group: Mobile DevOps
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 모바일 DevOps
---

{{< details >}}

- 계층: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

GitLab CI/CD를 사용하여 Android 및 iOS용 네이티브 및 크로스 플랫폼 모바일 앱을 빌드, 서명 및 릴리스합니다. GitLab Mobile DevOps는 모바일 앱 개발 워크플로우를 자동화하기 위한 도구와 모범 사례를 제공합니다.

GitLab Mobile DevOps는 주요 모바일 개발 기능을 GitLab DevSecOps 플랫폼에 통합합니다:

- iOS 및 Android 개발을 위한 빌드 환경
- 안전한 코드 서명 및 인증서 관리
- Google Play 및 Apple App Store를 위한 앱 스토어 배포

## 빌드 환경 {#build-environments}

빌드 환경을 완벽하게 제어하려면 [GitLab 호스팅 러너](../runners/_index.md)를 사용하거나 [자체 관리형 러너](https://docs.gitlab.com/runner/#use-self-managed-runners)를 설정할 수 있습니다.

## 코드 서명 {#code-signing}

모든 Android 및 iOS 앱은 다양한 앱 스토어를 통해 배포되기 전에 안전하게 서명해야 합니다. 서명은 애플리케이션이 사용자의 기기에 도달하기 전에 변조되지 않도록 보장합니다.

[프로젝트 수준 보안 파일](../secure_files/_index.md)을 사용하면 GitLab에 다음을 저장하여 CI/CD 빌드에서 앱에 안전하게 서명하는 데 사용할 수 있습니다:

- 키스토어
- 프로비저닝 프로필
- 서명 인증서

<i class="fa-youtube-play" aria-hidden="true"></i> 개요를 보려면 [프로젝트 수준 보안 파일 데모](https://youtu.be/O7FbJu3H2YM)를 확인하세요.

## 배포 {#distribution}

서명된 빌드는 Mobile DevOps 배포 통합을 사용하여 Google Play Store 또는 Apple App Store에 업로드할 수 있습니다.

## 관련 항목 {#related-topics}

Mobile DevOps를 구현하는 방법에 대한 단계별 안내는 다음을 참조하세요:

- [튜토리얼: GitLab Mobile DevOps를 사용하여 Android 앱 빌드](mobile_devops_tutorial_android.md)
- [튜토리얼: GitLab Mobile DevOps를 사용하여 iOS 앱 빌드](mobile_devops_tutorial_ios.md)
