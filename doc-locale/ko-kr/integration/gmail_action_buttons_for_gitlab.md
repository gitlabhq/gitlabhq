---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Gmail 작업
description: "GitLab 알림을 위해 Gmail 작업을 구성합니다."
---

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

GitLab은 [이메일의 Google 작업](https://developers.google.com/gmail/markup/actions/actions-overview)을 지원합니다. 이 통합을 구성하면 작업이 필요한 이메일이 Gmail에 표시됩니다.

이를 작동시키려면 Google에 등록되어 있어야 합니다. 지침은 [Google에 등록](https://developers.google.com/gmail/markup/registering-with-google)을 참조하세요.

이 프로세스에는 많은 단계가 있습니다. Google에서 설정한 모든 요구 사항을 충족하여 애플리케이션이 Google에 거부되지 않도록 하세요.

특히 다음에 유의하세요:

<!-- vale gitlab_base.InclusiveLanguage = NO -->

- GitLab에서 알림 이메일을 보내는 데 사용하는 이메일 계정은 다음을 충족해야 합니다:
  - "도메인에서 대량의 메일을 보낸 일관된 기록(최소 일일 수백 개의 이메일을 Gmail로 보냄)이 최소 몇 주 이상 있어야 합니다".
  - 사용자로부터의 스팸 불만 비율이 매우 낮아야 합니다.
- 이메일은 DKIM 또는 SPF를 통해 인증되어야 합니다.
- 최종 양식(**Gmail Schema Whitelist Request**)을 보내기 전에 프로덕션 서버에서 실제 이메일을 보내야 합니다. 이는 등록 중인 이메일 주소에서 이 이메일을 보낼 방법을 찾아야 함을 의미합니다. 등록 중인 이메일 주소에서 실제 이메일을 전달하여 이를 수행할 수 있습니다. GitLab 서버의 Rails 콘솔로 이동하여 거기에서 이메일 전송을 트리거할 수도 있습니다.

<!-- vale gitlab_base.InclusiveLanguage = YES -->

"Google에 등록" 문서에 나열된 모든 단계를 거쳐 어떻게 보이는지 [이 GitLab.com 이슈](https://gitlab.com/gitlab-org/gitlab-foss/-/issues/1517)에서 확인할 수 있습니다.
