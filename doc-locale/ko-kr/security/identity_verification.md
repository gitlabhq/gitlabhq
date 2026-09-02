---
stage: Software Supply Chain Security
group: Authorization
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 본인 인증
---

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com

{{< /details >}}

본인 인증은 GitLab 계정 보안의 여러 계층을 제공합니다. [위험 점수](../integration/arkose.md)에 따라 계정을 등록하기 위해 최대 3개의 스테이지를 완료해야 할 수도 있습니다:

- **모든 사용자** \- 이메일 인증
- **Medium-risk users** \- 전화번호 인증
- **High-risk users** \- 신용카드 인증

기본적으로 SAML 또는 SCIM으로 프로비전된 사용자는 이메일 인증을 완료해야 합니다. 사용자 정의 도메인을 추가하여 [이메일 인증을 건너뛸](../user/group/saml_sso/_index.md#bypass-user-email-confirmation-with-verified-domains) 수 있습니다. GitLab은 사용자의 이메일 도메인이 일치할 때 자동으로 사용자 계정을 확인합니다.

CI/CD 파이프라인 실행 중에 본인 인증 오류가 발생하면 [파이프라인 오류 디버깅](../ci/debugging.md#error-identity-verification-is-required-in-order-to-run-ci-jobs)을 참조하세요.

## 이메일 인증 {#email-verification}

계정을 등록하려면 유효한 이메일 주소를 입력해야 합니다. [새 사용자가 이메일을 확인하도록 설정](user_email_confirmation.md)을 참조하세요.

## 전화번호 인증 {#phone-number-verification}

이메일 인증 외에도 유효한 전화번호를 입력하고 일회성 비밀번호(OTP) 코드를 인증해야 할 수도 있습니다.

> [!note]
> 차단된 사용자와 연결된 전화번호로 계정을 인증할 수 없습니다.

### 국가별 지원 {#country-support}

일부 국가에서는 전화번호 인증을 제한적으로 지원하거나 지원하지 않습니다:

- 지원 안 함: 전화 인증을 사용할 수 없습니다.
- 부분 지원: 지역 규정이나 집행 정책으로 인해 전화 인증이 작동하지 않을 수 있습니다.

전화 인증을 사용할 수 없는 경우 [신용카드 인증](#credit-card-verification)을 시도하거나 [지원 티켓](https://support.gitlab.com/)을 생성하세요.

| 국가 | 지원 수준 |
|---------|---------------|
| 아르메니아 | 부분 지원 |
| 방글라데시 | 지원 안 함 |
| 벨라루스 | 부분 지원 |
| 캄보디아 | 부분 지원 |
| 중국 | 지원 안 함 |
| 쿠바 | 지원 안 함 |
| 에스와티니 | 부분 지원 |
| 아이티 | 부분 지원 |
| 홍콩 | 지원 안 함 |
| 인도네시아 | 지원 안 함 |
| 이란 | 지원 안 함 |
| 카자흐스탄 | 부분 지원 |
| 케냐 | 부분 지원 |
| 쿠웨이트 | 부분 지원 |
| 마카오 | 지원 안 함 |
| 말레이시아 | 지원 안 함 |
| 멕시코 | 부분 지원 |
| 미얀마 | 부분 지원 |
| 나이지리아 | 부분 지원 |
| 북한 | 지원 안 함 |
| 오만 | 부분 지원 |
| 파키스탄 | 지원 안 함 |
| 필리핀 | 부분 지원 |
| 카타르 | 부분 지원 |
| 러시아 | 지원 안 함 |
| 사우디아라비아 | 지원 안 함 |
| 남아프리카 | 부분 지원 |
| 시리아 | 지원 안 함 |
| 탄자니아 | 부분 지원 |
| 태국 | 부분 지원 |
| 터키 | 부분 지원 |
| 우간다 | 부분 지원 |
| 우크라이나 | 부분 지원 |
| 아랍에미리트 | 지원 안 함 |
| 우즈베키스탄 | 부분 지원 |
| 베트남 | 지원 안 함 |

## 신용카드 인증 {#credit-card-verification}

이메일 주소 및 전화번호 외에도 계정을 인증하기 위해 유효한 신용카드 번호를 입력해야 할 수도 있습니다.

GitLab은 카드 정보를 직접 저장하거나 요금을 청구하지 않습니다. 이 프로세스는 그룹에 대한 청구 정보와 연결되지 않습니다.

차단된 사용자와 연결된 신용카드 번호로 계정을 인증할 수 없습니다.
