---
stage: Solutions Architecture
group: Solutions Architecture
info: This page is owned by the Solutions Architecture team.
description: "GitLab에서 OSS 라이선스 준수 설정 가이드입니다. 종속성 검사, 승인 정책, 라이선스 목록을 최신 상태로 유지하는 방법을 포함합니다."
title: OSS 라이선스 확인
---

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

## 시작하기 {#getting-started}

### 솔루션 구성 요소 다운로드 {#download-the-solution-component}

1. 계정 팀으로부터 초대 코드를 입수합니다.
1. 초대 코드를 사용하여 [솔루션 구성 요소 웹스토어](https://cloud.gitlab-accelerator-marketplace.com)에서 솔루션 구성 요소를 다운로드합니다.

## OSS 라이브러리 라이선스 확인 - GitLab 정책 {#oss-library-license-check---gitlab-policy}

이 가이드는 Blue Oak Council 라이선스 등급을 기반으로 프로젝트에 라이선스 준수 정책을 구현하는 데 도움이 됩니다. 이 정책은 Blue Oak Council의 Gold, Silver, Bronze 티어에 포함되지 않는 라이선스를 사용하는 모든 종속성에 대해 자동으로 승인을 요구합니다.

또한 최신 승인된 라이선스를 가져오는 Python 스크립트 `update_licenses.py`로 [라이선스 목록을 최신 상태로 유지](#keeping-your-license-list-up-to-date)할 수 있습니다.

## 개요 {#overview}

OSS 라이브러리 라이선스 확인은 다음을 제공합니다:

- 프로젝트의 모든 종속성에 대한 자동화된 라이선스 스캔
- Blue Oak Council에서 [Gold](https://blueoakcouncil.org/list#gold), [Silver](https://blueoakcouncil.org/list#silver), [Bronze](https://blueoakcouncil.org/list#bronze)로 평가된 라이선스를 허용하는 사전 구성된 정책
- 이러한 티어에 없는 모든 라이선스에 대한 승인 워크플로우

## 전제 조건 {#prerequisites}

- GitLab Ultimate 티어
- GitLab 인스턴스 또는 그룹에 대한 관리자 액세스 권한
- 프로젝트에 [종속성 검사](../../user/application_security/dependency_scanning/_index.md)가 활성화되어 있습니다(옵션으로 [종속성 검사 설정](#setting-up-dependency-scanning-from-scratch) 지침에 따라 지정된 범위의 모든 프로젝트에 대해 활성화하고 적용할 수 있습니다)

## 구현 가이드 {#implementation-guide}

이 가이드는 두 가지 주요 시나리오를 다룹니다:

1. [처음부터 설정](#setting-up-from-scratch-using-the-ui) (기존 보안 정책 프로젝트 없음)
   - [종속성 검사 설정](#setting-up-dependency-scanning-from-scratch)
   - [라이선스 준수 설정](#setting-up-license-compliance-from-scratch)
1. [기존 정책에 추가](#adding-to-an-existing-policy) (기존 보안 정책 프로젝트)

### 처음부터 설정(UI 사용) {#setting-up-from-scratch-using-the-ui}

아직 보안 정책 프로젝트가 없다면, 하나를 만들고 종속성 검사 정책과 라이선스 준수 정책을 모두 설정해야 합니다.

#### 처음부터 종속성 검사 설정 {#setting-up-dependency-scanning-from-scratch}

1. 먼저 이 정책을 적용하려는 그룹을 식별합니다. 이것이 정책을 적용할 수 있는 최상위 그룹 수준입니다(이 그룹 내의 프로젝트를 포함하거나 제외할 수 있습니다).
1. 해당 그룹의 **보안** > **정책** 페이지로 이동합니다.
1. **새 정책**을 클릭합니다.
1. **검사 실행 정책**을 선택합니다.
1. 정책의 이름을 입력합니다(예: "종속성 검사 정책").
1. 설명을 입력합니다(예: "종속성 검사를 시행하여 사용된 OSS 라이선스 목록을 가져옵니다").
1. **정책 범위**를 "이 그룹의 모든 프로젝트"(옵션으로 예외 설정) 또는 "특정 프로젝트"(드롭다운에서 프로젝트 선택)을 선택하여 설정합니다.
1. **조치** 섹션에서 **시크릿 검색**(기본값) 대신 **종속성 검사**를 선택합니다.
1. **조건** 섹션에서, 모든 커밋마다 실행하는 대신 일정에 따라 스캔을 실행하려면 선택적으로 "Triggers:"를 "Schedules:"로 변경할 수 있습니다.
1. **정책 생성**을 클릭합니다.

#### 처음부터 라이선스 준수 설정 {#setting-up-license-compliance-from-scratch}

종속성 검사를 설정한 후 다음 단계를 따라 라이선스 준수 정책을 설정합니다:

1. 같은 그룹의 **보안** > **정책** 페이지로 다시 이동합니다.
1. **새 정책**을 클릭합니다.
1. **머지 리퀘스트 승인 정책**을 선택합니다.
1. 정책의 이름을 입력합니다(예: "OSS 준수 정책").
1. 설명을 입력합니다(예: "Blue Oak Council의 Gold, Silver, Bronze 티어에 포함되지 않는 모든 라이선스를 차단합니다").
1. **정책 범위**를 "이 그룹의 모든 프로젝트"(옵션으로 예외 설정) 또는 "특정 프로젝트"(드롭다운에서 프로젝트 선택)을 선택하여 설정합니다.
1. **규칙** 섹션에서 "Select scan type" 드롭다운을 클릭하고 **License Scan**을 선택합니다.
1. 대상 브랜치를 설정합니다(기본값은 모든 보호된 브랜치입니다).
1. "Status is:" 드롭다운을 **Newly detected** 또는 **사전에 존재하는**으로 변경합니다(새로운 종속성에만 정책을 적용할지, 기존 항목에도 적용할지에 따라).
1. **IMPORTANT**: "License is:" 드롭다운을 기본값 "Matching"에서 **예외**로 변경합니다(이렇게 하면 정책이 승인되지 않은 라이선스를 올바르게 차단합니다).
1. **조치** 섹션까지 아래로 스크롤하고 필요한 승인 수를 설정합니다.
1. "Choose approver type" 드롭다운에서 승인을 제공해야 하는 사용자, 그룹 또는 역할을 선택합니다("Add new approver"를 클릭하여 동일한 규칙에 여러 승인자 유형을 추가할 수 있습니다).
1. "프로젝트 승인 설정 오버라이드" 섹션을 구성하고 필요에 따라 기본 설정을 변경합니다.
1. 페이지 상단으로 스크롤한 후 `.yaml mode`을 클릭합니다.
1. YAML 편집기에서 `license_types` 섹션을 찾아 [완전한 정책 구성](#complete-policy-configuration) 섹션의 승인된 라이선스의 전체 목록으로 바꿉니다. 섹션은 다음과 같이 표시됩니다:

```yaml
rules:
  - type: license_finding
    match_on_inclusion_license: false
    license_types:
    # Replace this section with the full list of licenses from the Complete Policy Configuration section
    - MIT License
    - Apache License 2.0
    # etc...
```

1. **정책 생성**을 클릭합니다.

### 기존 정책에 추가 {#adding-to-an-existing-policy}

이미 보안 정책 프로젝트가 있지만 의존성 및/또는 라이선스 준수 정책이 없다면:

1. 그룹의 보안 정책 프로젝트로 이동합니다.
1. `.gitlab/security-policies/`에서 `policy.yml` 파일로 이동합니다.
1. **편집** > **단일 파일 편집**을 클릭합니다.
1. [완전한 정책 구성](#complete-policy-configuration)에서 `scan_execution_policy` 및 `approval_policy` 섹션을 추가합니다.
1. 다음을 확인하세요:
   - 기존 YAML 구조를 유지합니다
   - 이러한 섹션을 다른 최상위 섹션과 동일한 수준에 배치합니다
   - `user_approvers_ids` 및/또는 `group_approvers_ids` 및/또는 `role_approvers`을 설정합니다(하나만 필요)
     - `YOUR_USER_ID_HERE` 또는 `YOUR_GROUP_ID_HERE`를 적절한 사용자/그룹 ID로 바꿉니다(사용자 이름이 아니라 예: 1234567과 같은 사용자/그룹 ID를 붙여넣도록 하세요)
   - 정책에서 프로젝트를 제외하려면 `YOUR_PROJECT_ID_HERE`을 바꿉니다(프로젝트 이름/경로가 아니라 예: 1234와 같은 프로젝트 ID를 붙여넣도록 하세요)
   - `approvals_required: 1`을 필요한 승인 수로 설정합니다
   - `approval_settings` 섹션을 필요에 따라 수정합니다(`true`로 설정된 항목은 프로젝트 승인 설정을 재정의합니다)
1. **변경 사항 커밋**을 클릭하고 새로운 브랜치로 커밋합니다. 정책 변경을 병합할 수 있도록 **이 변경 사항에 대한 머지 리퀘스트를 만듭니다.**를 선택합니다.

## 완전한 정책 구성 {#complete-policy-configuration}

참고용으로 완전한 정책 구성은 다음과 같습니다:

```yaml
scan_execution_policy:
- name: License scan policy
  description: Enforces dependency scanning to get a list of OSS licenses used, in
    order to remain compliant with OSS usage guidance.
  enabled: true
  policy_scope:
    projects:
      excluding:
      - id: YOUR_PROJECT_ID_HERE
      - id: YOUR_PROJECT_ID_HERE
  rules:
  - type: pipeline
    branch_type: all
  actions:
  - scan: dependency_scanning
  skip_ci:
    allowed: true
    allowlist:
      users: []
approval_policy:
- name: OSS Compliance Policy
  description: |-
    Block any licenses that are not included in the Blue Oak Council's Gold, Silver, or Bronze tiers.
    https://blueoakcouncil.org/list
  enabled: true
  policy_scope:
    projects:
      excluding:
      - id: YOUR_PROJECT_ID_HERE
      - id: YOUR_PROJECT_ID_HERE
  rules:
  - type: license_finding
    match_on_inclusion_license: false
    license_types:
    - BSD-2-Clause Plus Patent License
    - Amazon Digital Services License
    - Apache License 2.0
    - Adobe Postscript AFM License
    - BSD 1-Clause License
    - BSD 2-Clause "Simplified" License
    - BSD 2-Clause FreeBSD License
    - BSD 2-Clause NetBSD License
    - BSD 2-Clause with Views Sentence
    - Boost Software License 1.0
    - DSDP License
    - Educational Community License v1.0
    - Educational Community License v2.0
    - hdparm License
    - ImageMagick License
    - Intel ACPI Software License Agreement
    - ISC License
    - Linux Kernel Variant of OpenIB.org license
    - MIT License
    - MIT License Modern Variant
    - MIT testregex Variant
    - MIT Tom Wu Variant
    - Microsoft Public License
    - Mulan Permissive Software License, Version 1
    - Mup License
    - PostgreSQL License
    - Solderpad Hardware License v0.5
    - Spencer License 99
    - Universal Permissive License v1.0
    - Xerox License
    - Xfig License
    - BSD Zero Clause License
    - Academic Free License v1.1
    - Academic Free License v1.2
    - Academic Free License v2.0
    - Academic Free License v2.1
    - Academic Free License v3.0
    - AMD's plpa_map.c License
    - Apple MIT License
    - Academy of Motion Picture Arts and Sciences BSD
    - ANTLR Software Rights Notice
    - ANTLR Software Rights Notice with license fallback
    - Apache License 1.0
    - Apache License 1.1
    - Artistic License 2.0
    - Bahyph License
    - Barr License
    - bcrypt Solar Designer License
    - BSD 3-Clause "New" or "Revised" License
    - BSD with attribution
    - BSD 3-Clause Clear License
    - Hewlett-Packard BSD variant license
    - Lawrence Berkeley National Labs BSD variant license
    - BSD 3-Clause Modification
    - BSD 3-Clause No Nuclear License 2014
    - BSD 3-Clause No Nuclear Warranty
    - BSD 3-Clause Open MPI Variant
    - BSD 3-Clause Sun Microsystems
    - BSD 4-Clause "Original" or "Old" License
    - BSD 4-Clause Shortened
    - BSD-4-Clause (University of California-Specific)
    - BSD Source Code Attribution
    - bzip2 and libbzip2 License v1.0.5
    - bzip2 and libbzip2 License v1.0.6
    - Creative Commons Zero v1.0 Universal
    - CFITSIO License
    - Clips License
    - CNRI Jython License
    - CNRI Python License
    - CNRI Python Open Source GPL Compatible License Agreement
    - Cube License
    - curl License
    - eGenix.com Public License 1.1.0
    - Entessa Public License v1.0
    - Freetype Project License
    - fwlw License
    - Historical Permission Notice and Disclaimer - Fenneberg-Livingston variant
    - Historical Permission Notice and Disclaimer - sell regexpr variant
    - HTML Tidy License
    - IBM PowerPC Initialization and Boot Software
    - ICU License
    - Info-ZIP License
    - Intel Open Source License
    - JasPer License
    - libpng License
    - PNG Reference Library version 2
    - libtiff License
    - LaTeX Project Public License v1.3c
    - LZMA SDK License (versions 9.22 and beyond)
    - MIT No Attribution
    - Enlightenment License (e16)
    - CMU License
    - enna License
    - feh License
    - MIT Open Group Variant
    - MIT +no-false-attribs license
    - Matrix Template Library License
    - Mulan Permissive Software License, Version 2
    - Multics License
    - Naumen Public License
    - University of Illinois/NCSA Open Source License
    - Net-SNMP License
    - NetCDF license
    - NICTA Public Software License, Version 1.0
    - NIST Software License
    - NTP License
    - Open Government Licence - Canada
    - Open LDAP Public License v2.0 (or possibly 2.0A and 2.0B)
    - Open LDAP Public License v2.0.1
    - Open LDAP Public License v2.1
    - Open LDAP Public License v2.2
    - Open LDAP Public License v2.2.1
    - Open LDAP Public License 2.2.2
    - Open LDAP Public License v2.3
    - Open LDAP Public License v2.4
    - Open LDAP Public License v2.5
    - Open LDAP Public License v2.6
    - Open LDAP Public License v2.7
    - Open LDAP Public License v2.8
    - Open Market License
    - OpenSSL License
    - PHP License v3.0
    - PHP License v3.01
    - Plexus Classworlds License
    - Python Software Foundation License 2.0
    - Python License 2.0
    - Ruby License
    - Saxpath License
    - SGI Free Software License B v2.0
    - Standard ML of New Jersey License
    - SunPro License
    - Scheme Widget Library (SWL) Software License Agreement
    - Symlinks License
    - TCL/TK License
    - TCP Wrappers License
    - UCAR License
    - Unicode License Agreement - Data Files and Software (2015)
    - Unicode License Agreement - Data Files and Software (2016)
    - UnixCrypt License
    - The Unlicense
    - Vovida Software License v1.0
    - W3C Software Notice and License (2002-12-31)
    - X11 License
    - XFree86 License 1.1
    - xlock License
    - X.Net License
    - XPP License
    - zlib License
    - zlib/libpng License with Acknowledgment
    - Zope Public License 2.0
    - Zope Public License 2.1
    license_states:
    - newly_detected
    branch_type: default
  actions:
  - type: require_approval
    approvals_required: 1
    user_approvers_ids:
    # Replace with the user IDs of your compliance approver(s)
    - YOUR_USER_ID_HERE
    - YOUR_USER_ID_HERE
    group_approvers_ids:
    # Replace with the group IDs of your compliance approver(s)
    - YOUR_GROUP_ID_HERE
    - YOUR_GROUP_ID_HERE
    role_approvers:
    # Replace with the roles of your compliance approver(s)
    - owner
    - maintainer
  - type: send_bot_message
    enabled: true
  approval_settings:
    block_branch_modification: true
    block_group_branch_modification: true
    prevent_pushing_and_force_pushing: true
    prevent_approval_by_author: true
    prevent_approval_by_commit_author: true
    remove_approvals_with_new_commit: true
    require_password_to_approve: false
  fallback_behavior:
    fail: closed
```

## 작동 방식 {#how-it-works}

1. `scan_execution_policy` 섹션은 모든 브랜치에서 종속성 검사를 실행하도록 GitLab을 구성하며, 라이선스 승인 정책에서 사용하는 CycloneDX 형식 SBOM 파일을 생성합니다.
1. `approval_policy` 섹션은 다음을 수행하는 규칙을 생성합니다:
   - Blue Oak Council의 [Gold](https://blueoakcouncil.org/list#gold), [Silver](https://blueoakcouncil.org/list#silver), [Bronze](https://blueoakcouncil.org/list#bronze) 티어의 승인된 라이선스 목록 포함
   - 이 목록에 없는 모든 라이선스에 대한 승인 필요
   - 승인되지 않은 라이선스가 감지되면 봇 메시지 전송
   - 승인이 허가될 때까지 병합 차단

## 사용자 정의 옵션 {#customization-options}

- **승인자**: 승인자를 세 가지 방식으로 지정할 수 있습니다:
  - `user_approvers_ids`: 라이선스를 승인해야 하는 개인의 사용자 ID로 바꿉니다(예: `1234567`)
  - `group_approvers_ids`: 승인자를 포함하는 그룹의 그룹 ID로 바꿉니다(예: `9876543`)
  - `role_approvers`: 승인할 수 있는 역할을 지정합니다. 옵션은 `developer`, `maintainer`, `owner`입니다
- **Project Exclusions**: 프로젝트 ID를 `policy_scope.projects.excluding` 섹션에 추가하여 정책에서 제외합니다
- **승인이 필수적임**: `approvals_required: 1`를 변경하여 더 많은 승인을 요구합니다
- **Bot messages**: `send_bot_message`에서 `enabled: false`을 설정하여 봇 알림을 비활성화합니다
- **프로젝트 승인 설정 오버라이드**: `approval_settings` 섹션을 필요에 따라 수정합니다(`true`로 설정된 항목은 프로젝트 설정을 재정의합니다)

## 라이선스 목록을 최신 상태로 유지 {#keeping-your-license-list-up-to-date}

승인된 라이선스 목록이 Blue Oak Council 등급과 일치하도록 유지하려면 다음 Python 스크립트를 사용하여 최신 라이선스 데이터를 가져올 수 있습니다:

```python
import requests

def fetch_license_data():
    url = "https://blueoakcouncil.org/list.json"
    try:
        response = requests.get(url)
        response.raise_for_status()  # Raise an exception for bad status codes
        return response.json()
    except requests.RequestException as e:
        print(f"Error fetching data: {e}")
        return None

# Fetch and print the data to verify it worked
data = fetch_license_data()
if data:
    # Look through each rating section
    target_tiers = ['Gold', 'Silver', 'Bronze']

    for rating in data['ratings']:
        if rating['name'] in target_tiers:
            # Print each license name in this tier
            for license in rating['licenses']:
                print(f"- {license['name']}")
```

이 스크립트를 사용하려면:

1. `update_licenses.py`로 저장합니다.
1. 아직 요청 라이브러리를 설치하지 않았다면 설치합니다: `pip install requests`.
1. 스크립트를 실행합니다: `python update_licenses.py`.
1. 출력(라이선스 목록)을 복사하고 `policy.yml` 파일의 기존 `license_types` 목록을 바꿉니다.

이렇게 하면 정책이 항상 최신 Blue Oak Council 라이선스 등급을 반영합니다.

## 문제 해결 {#troubleshooting}

### 정책이 적용되지 않음 {#policy-not-applying}

수정한 보안 정책 프로젝트가 그룹에 올바르게 연결되어 있는지 확인합니다. 자세한 내용은 [보안 정책 프로젝트에 링크](../../user/application_security/policies/enforcement/security_policy_projects.md#link-to-a-security-policy-project)를 참조하세요.

### 종속성 검사가 실행되지 않음 {#dependency-scan-not-running}

CI/CD 구성에서 종속성 검사가 활성화되어 있고 종속성 파일이 있는지 확인합니다. 자세한 내용은 [종속성 검사 문제 해결](../../user/application_security/dependency_scanning/dependency_scanning_sbom/troubleshooting_ds_sbom_analyzer.md)을 참조하세요.

## 추가 리소스 {#additional-resources}

- [Blue Oak Council 라이선스 목록](https://blueoakcouncil.org/list)
- [GitLab 라이선스 준수 설명서](../../user/compliance/license_scanning_of_cyclonedx_files/_index.md)
- [GitLab 머지 리퀘스트 승인 정책](../../user/compliance/license_approval_policies.md)
- [GitLab 종속성 검사](../../user/application_security/dependency_scanning/_index.md)
