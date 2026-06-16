---
stage: Application Security Testing
group: Composition Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: GitLab에 SPDX 라이선스 목록을 가져와서 정책 준수를 위한 정확한 라이선스 일치를 활성화합니다
title: SPDX 라이선스 목록 가져오기 Rake 작업
---

{{< details >}}

- 계층:  Ultimate
- 제공:  GitLab Self-Managed

{{< /details >}}

GitLab은 [SPDX 라이선스 목록](https://spdx.org/licenses/)의 새로운 사본을 GitLab 인스턴스에 업로드하기 위한 Rake 작업을 제공합니다. 이 목록은 [라이선스 승인 정책](../../user/compliance/license_approval_policies.md)의 이름과 일치시키기 위해 필요합니다.

PDX 라이선스 목록의 새로운 사본을 가져오려면 다음을 실행하세요:

```shell
# omnibus-gitlab
sudo gitlab-rake gitlab:spdx:import

# source installations
bundle exec rake gitlab:spdx:import RAILS_ENV=production
```

[오프라인 환경](../../user/application_security/offline_deployments/_index.md#defining-offline-environments) 에서 이 작업을 수행하려면 [`licenses.json`](https://spdx.org/licenses/licenses.json)에 대한 아웃바운드 연결이 허용되어야 합니다.
