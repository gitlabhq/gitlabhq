---
stage: Security Risk Management
group: Security Insights
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: CVE ID 요청
description: 취약성 추적 및 보안 공개.
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab.com

{{< /details >}}

[Common Vulnerabilities and Exposures ID](https://cve.mitre.org/index.html) (CVE ID)는 공개적으로 공개된 소프트웨어 취약성에 할당된 고유 식별자입니다. GitLab은 [CVE Numbering Authority](<https://cve.mitre.org/cve/cna.html>) (CNA)이며, 이는 GitLab.com에서 호스팅되는 프로젝트의 취약성에 CVE 식별자를 할당할 수 있다는 의미입니다.

공개 프로젝트의 경우 보안 문제에 대해 사용자에게 알리기 위해 CVE 식별자를 요청할 수 있습니다. 예를 들어, GitLab [종속성 검사 도구](dependency_scanning/_index.md)는 프로젝트가 취약한 버전의 종속성을 사용하는 경우를 감지할 수 있습니다.

일반적인 취약성 워크플로우는 다음과 같습니다:

1. 취약성에 대해 CVE를 요청합니다.
1. 릴리스 정보에서 할당된 CVE 식별자를 참조합니다.
1. 수정 사항이 릴리스된 후 취약성의 세부 정보를 게시합니다.

## CVE ID 요청 {#submit-a-cve-id-request}

전제 조건:

- 프로젝트에 대한 Maintainer 또는 Owner 역할.
- 프로젝트는 GitLab.com에서 호스팅됩니다.
- 프로젝트는 공개입니다.
- 취약성 이슈는 [기밀](../project/issues/confidential_issues.md)입니다.

CVE ID 요청을 제출하려면 다음을 수행합니다:

1. 취약성 이슈로 이동하여 **CVE ID 요청 생성**을 선택합니다. [GitLab CVE 프로젝트](https://gitlab.com/gitlab-org/cves)의 새로운 이슈 페이지가 열립니다.
1. **제목** 상자에 취약성에 대한 간단한 설명을 입력합니다.
1. **설명** 상자에 다음 세부 정보를 입력합니다:

   - 취약성에 대한 자세한 설명
   - 프로젝트의 공급업체 및 이름
   - 영향을 받은 버전
   - 수정된 버전
   - 취약성 클래스 ([CWE](https://cwe.mitre.org/data/index.html) 식별자)
   - [CVSS v3 벡터](https://nvd.nist.gov/vuln-metrics/cvss/v3-calculator)

GitLab은 다음의 경우에 CVE ID 요청 이슈를 업데이트합니다:

- 제출 사항에 CVE가 할당됩니다.
- CVE가 게시됩니다.
- MITRE에 CVE가 게시되었음을 알립니다.
- MITRE가 NVD 피드에 CVE를 추가했습니다.

## CVE 할당 {#cve-assignment}

CVE 식별자가 할당된 후 필요에 따라 이를 참조할 수 있습니다. CVE ID 요청에 제출된 취약성의 세부 정보는 사용자의 일정에 따라 게시됩니다.
