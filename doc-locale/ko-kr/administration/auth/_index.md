---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "LDAP, OmniAuth, SAML, SCIM, OIDC, OAuth 등의 방법"
title: 사용자 ID
---

GitLab은 다양한 타사 도구 및 프로토콜과 통합되어 인증 및 권한 부여를 더 잘 지원합니다.

GitLab을 조직의 기존 ID 인프라에 연결하여 사용자 관리를 중앙화하고 보안 정책을 적용합니다. LDAP, SAML, OAuth 또는 SCIM ID 공급자 및 디렉터리 서비스와 통합하여 인증 및 권한 부여를 수행할 수 있습니다.

GitLab Self-Managed 및 GitLab Dedicated에서 관리자는 Active Directory, Google Workspace, Azure AD와 같은 ID 공급자와 통합하여 사용자를 자동으로 프로비저닝하고, 그룹 멤버십을 동기화하며, 단일 로그인을 활성화할 수 있습니다. GitLab.com 그룹은 SAML ID 공급자와 통합하여 중앙화된 인증 및 사용자 프로비저닝을 수행할 수 있습니다.

조직의 필요에 따라 여러 통합 방법 중에서 선택하세요:

- 디렉터리 동기화를 위한 LDAP
- 단일 로그인을 위한 SAML
- 타사 인증을 위한 OAuth
- 자동화된 사용자 프로비저닝 및 프로비저닝 해제를 위한 SCIM

## 핵심 개념 {#core-concepts}

{{< cards >}}

- [LDAP](ldap/_index.md)
- [OmniAuth](../../integration/omniauth.md)
- [SAML](../../integration/saml.md)
- [SAML Group Sync](../../user/group/saml_sso/group_sync.md)
- [SCIM](../settings/scim_setup.md)

{{< /cards >}}

## GitLab.com과 GitLab Self-Managed 비교 {#gitlabcom-compared-to-gitlab-self-managed}

외부 인증 및 권한 부여 공급자는 다음과 같은 기능을 지원할 수 있습니다. 자세한 내용은 이 페이지에서 각 외부 공급자에 대해 표시된 링크를 참조하세요.

| 기능                                      | GitLab.com                              | GitLab Self-Managed                       |
|-------------------------------------------------|-----------------------------------------|------------------------------------|
| **User Provisioning**                           | SCIM<br>SAML <sup>1</sup> | LDAP <sup>1</sup><br>SAML <sup>1</sup><br>[OmniAuth 공급자](../../integration/omniauth.md#supported-providers) <sup>1</sup><br>SCIM  |
| **User Detail Updating** (그룹 관리 제외) | 이용 불가                           | LDAP 동기화                          |
| **인증**                              | 최상위 그룹의 SAML (1개 공급자)    | LDAP (여러 공급자)<br>일반 OAuth 2.0<br>SAML (고유 공급자당 1개만 허용)<br>Kerberos<br>JWT<br>스마트 카드<br>[OmniAuth 공급자](../../integration/omniauth.md#supported-providers) (고유 공급자당 1개만 허용) |
| **Provider-to-GitLab Role Sync**                | SAML Group Sync                         | LDAP Group Sync<br>SAML Group Sync ([GitLab 15.1](https://gitlab.com/gitlab-org/gitlab/-/issues/285150) 이상) |
| **User Removal**                                | SCIM (최상위 그룹에서 사용자 제거) | LDAP (그룹에서 사용자 제거 및 인스턴스에서 차단)<br>SCIM |

**각주**:

1. Just-In-Time (JIT) 프로비저닝을 사용하여 사용자가 처음 로그인할 때 사용자 계정이 생성됩니다.
