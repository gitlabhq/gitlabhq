---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 인증 및 권한 부여
description: "사용자 신원, 인증, 권한, 액세스 제어 및 보안 모범 사례."
---

GitLab은 협업을 제한하지 않으면서 리소스를 보호하기 위해 인증 및 권한 부여를 사용합니다.

인증은 비밀번호, 2단계 인증, SSH 키, 액세스 토큰, SAML 및 OAuth와 같은 외부 신원 공급자를 포함한 방법을 사용하여 본인 확인을 수행합니다. 권한 부여는 역할 및 세밀한 권한을 사용하여 그룹, 프로젝트 및 리소스에 대한 액세스를 제어하는 작업을 결정합니다. 이러한 시스템은 함께 개별 사용자부터 엔터프라이즈 조직까지 확장되는 보안 프레임워크를 만듭니다.

GitLab 보안 모델을 이해하면 보안 요구 사항과 운영 효율성의 균형을 맞추는 액세스 제어를 구현하는 데 도움이 됩니다.

{{< cards >}}

- [사용자 신원](../administration/auth/_index.md)
- [사용자 인증](user_authentication.md)
- [사용자 권한](user_permissions.md)
- [인증 및 권한 부여 모범 사례](auth_practices.md)
- [인증 및 권한 부여 용어집](auth_glossary.md)

{{< /cards >}}
