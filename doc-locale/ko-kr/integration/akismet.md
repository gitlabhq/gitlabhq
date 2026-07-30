---
stage: Software Supply Chain Security
group: Authorization
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Akismet
---

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

GitLab은 [Akismet](https://akismet.com/)을 사용하여 공개 프로젝트에서 스팸 이슈의 생성을 방지합니다. 웹 UI 또는 API를 통해 생성된 이슈를 Akismet에 검토를 위해 제출할 수 있으며, 인스턴스 관리자는 [스니펫을 스팸으로 표시](../user/snippets.md#mark-snippet-as-spam)할 수 있습니다.

감지된 스팸은 거부되며, **Spam log** 섹션의 **운영자** 영역에 항목이 추가됩니다.

개인정보 보호 참고: GitLab은 사용자의 IP와 사용자 에이전트를 Akismet에 제출합니다.

> [!note]
> GitLab은 모든 이슈를 Akismet에 제출합니다.

Akismet 구성은 GitLab Self-Managed 사용자가 이용할 수 있습니다. Akismet은 이미 GitLab.com에서 활성화되어 있으며, 여기서 구성 및 관리는 GitLab Inc.에서 처리합니다.

## Akismet 구성 {#configure-akismet}

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Akismet을 사용하려면:

1. [Akismet 로그인 페이지](https://akismet.com/account/)로 이동합니다.
1. 로그인하거나 새 계정을 생성합니다.
1. **표시**를 선택하여 API 키를 표시하고 API 키의 값을 복사합니다.
1. 관리자로 GitLab에 로그인합니다.
1. 오른쪽 위 모서리에서 **운영자**를 선택합니다.
1. 왼쪽 사이드바에서 **Settings** > **Reporting**을 선택합니다.
1. **Spam and Anti-bot Protection**을 펼칩니다.
1. **Akismet 활성화** 체크박스를 선택합니다.
1. 3단계의 API 키를 입력합니다.
1. 구성을 저장합니다.

## Akismet 필터 교육 {#train-the-akismet-filter}

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

스팸과 정상 메일을 더 잘 구분하기 위해 거짓 양성 또는 거짓 음성이 있을 때마다 Akismet 필터를 교육할 수 있습니다.

항목이 스팸으로 인식되면 거부되고 스팸 로그에 추가됩니다. 여기에서 항목이 실제로 스팸인지 검토할 수 있습니다. 항목이 실제로 스팸이 아닌 경우 **ham으로 제출**을 선택하여 Akismet에 항목이 거짓으로 스팸으로 인식되었음을 알립니다.

실제로 스팸인 항목이 인식되지 않은 경우 **스팸으로 제출**을 사용하여 이 정보를 Akismet에 제출합니다. **스팸으로 제출** 버튼은 관리자 사용자에게만 표시됩니다.

Akismet 교육은 향후 스팸을 더 정확하게 인식하는 데 도움이 됩니다.
