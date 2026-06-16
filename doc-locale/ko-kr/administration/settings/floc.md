---
stage: Facilitated functionality
group: Facilitated functionality
info: For more information, see <https://handbook.gitlab.com/handbook/product/categories/#facilitated-functionality>
title: FLoC(Federated Learning of Cohort)
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

FLoC(Federated Learning of Cohort)는 Google Chrome의 제안된 기능으로, 관심 기반 광고를 위해 사용자를 다양한 코호트로 분류했습니다. FLoC는 [Topics API](https://patcg-individual-drafts.github.io/topics/)로 대체되었으며, 이는 광고주가 사용자를 타겟팅하고 추적하는 데 도움이 되는 유사한 기능을 제공합니다.

기본적으로 GitLab은 다음 헤더를 전송하여 관심 기반 광고에 대한 사용자 추적을 거부합니다:

```plaintext
Permissions-Policy: interest-cohort=()
```

이 헤더는 모든 GitLab 인스턴스에서 사용자가 추적되고 분류되는 것을 방지합니다. 이 헤더는 Topics API 및 더 이상 사용되지 않는 FLoC 시스템과 호환됩니다.

전제 조건:

- 관리자 액세스 권한이 있어야 합니다.

관심 기반 광고에 대한 사용자 추적을 활성화하려면:

1. 오른쪽 위 모서리에서 **Admin**을 선택합니다.
1. 왼쪽 사이드바에서 **Settings** > **General**을 선택합니다.
1. **FLoC(Federated Learning of Cohort)**를 확장합니다.
1. **FLoC에 참여** 체크박스를 선택합니다.
1. **변경 사항 저장**을 선택합니다.
