---
stage: Application Security Testing
group: Secret Detection
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 클라이언트 측 시크릿 검색
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 15.11에서 [도입되었습니다](https://gitlab.com/gitlab-org/gitlab/-/issues/368434).
- 사용자 지정 접두사가 있는 개인 액세스 토큰 검색이 GitLab 16.1에서 [도입되었습니다](https://gitlab.com/gitlab-org/gitlab/-/issues/411146). GitLab Self-Managed만 해당입니다.
- 인스턴스 전체 토큰 접두사 검색이 GitLab 18.11에서 [도입되었습니다](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/220122). GitLab Self-Managed만 해당입니다.

{{< /history >}}

이슈를 생성하거나 머지 리퀘스트에 설명을 추가하거나 댓글을 작성할 때 실수로 시크릿을 게시할 수 있습니다. 예를 들어 API 요청의 세부 정보나 인증 토큰을 포함하는 환경 변수를 붙여넣을 수 있습니다. 시크릿이 유출되면 공격자가 이를 사용하여 정당한 사용자를 사칭할 수 있습니다.

클라이언트 측 시크릿 검색은 실수로 인한 시크릿 노출의 위험을 최소화합니다. 이슈 또는 머지 리퀘스트에서 설명을 편집하거나 댓글을 작성할 때 GitLab은 자동으로 시크릿의 내용을 스캔합니다.

## 시크릿 검색 워크플로우 {#secret-detection-workflow}

클라이언트 측 시크릿 검색은 패턴 일치를 사용하여 브라우저 내에서 완전히 작동합니다. 이 접근 방식은 다음을 보장합니다.

- 시크릿은 GitLab에 제출되기 전에 검색됩니다.
- 검색 프로세스 중에 민감한 정보는 전송되지 않습니다.
- 이 기능은 추가 구성을 요구하지 않고도 원활하게 작동합니다.

## 시작하기 {#getting-started}

클라이언트 측 시크릿 검색은 모든 GitLab 티어에서 기본적으로 활성화됩니다. 설정 또는 구성이 필요하지 않습니다.

이 기능을 테스트하려면:

1. 임의의 이슈 또는 머지 리퀘스트로 이동합니다
1. `glpat-xxxxxxxxxxxxxxxxxxxx`와 같은 테스트 시크릿 패턴을 포함하는 댓글을 추가합니다
1. 제출하기 전에 나타나는 경고 메시지를 확인합니다

실제 시크릿 노출을 피하기 위해 테스트할 때는 항상 자리 표시자 값을 사용합니다.

## 보안 범위 {#coverage}

클라이언트 측 시크릿 검색은 다음 내용을 분석합니다:

- 이슈 설명 및 댓글
- 머지 리퀘스트 설명 및 댓글

검색된 시크릿의 특정 유형에 대한 자세한 정보는 [검색된 시크릿](../detected_secrets.md) 문서를 참조하세요.

## 결과를 이해하기 {#understanding-the-results}

클라이언트 측 시크릿 검색이 잠재적 시크릿을 식별하면 GitLab은 검색된 시크릿을 강조하는 경고를 표시합니다. 다음 중 하나를 수행할 수 있습니다.

- 시크릿을 제거하려면 댓글 또는 설명의 내용을 **편집**합니다.
- 변경하지 않고 내용을 **추가**합니다. 잠재적 시크릿을 포함하는 내용을 추가하기 전에 주의하세요.

검색은 브라우저에서 완전히 수행됩니다. **추가**를 선택하지 않는 한 정보가 전송되지 않습니다.

## 최적화 {#optimization}

클라이언트 측 시크릿 검색의 효과를 최대화하려면:

- 경고를 신중하게 검토합니다. 진행하기 전에 항상 플래그가 지정된 내용을 조사합니다.
- 자리 표시자를 사용합니다. 실제 시크릿을 `[REDACTED]` 또는 `<API_KEY>`와 같은 자리 표시자 텍스트로 바꿉니다.
