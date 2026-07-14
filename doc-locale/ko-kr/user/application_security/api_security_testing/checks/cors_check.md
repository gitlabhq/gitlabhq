---
stage: Application Security Testing
group: Dynamic Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: CORS
---

## 설명 {#description}

지나치게 허용적인 Origin 헤더 화이트리스트나 Origin 헤더 검증 실패를 포함한 CORS 잘못된 구성을 확인합니다. 또한 잠재적으로 유효하지 않거나 위험한 Origin에 대한 자격 증명 허용 및 캐시 중독을 야기할 수 있는 누락된 헤더를 확인합니다.

## 수정 {#remediation}

잘못된 구성의 CORS 구현은 어떤 도메인을 신뢰해야 하고 어느 수준의 신뢰를 해야 하는지에 대해 지나치게 허용적일 수 있습니다. 이로 인해 신뢰할 수 없는 도메인이 Origin 헤더를 위조하고 사이트 간 요청 위조 또는 사이트 간 스크립팅과 같은 다양한 유형의 공격을 시작할 수 있습니다. 공격자는 잠재적으로 피해자의 자격 증명을 도용하거나 피해자를 대신하여 악의적인 요청을 보낼 수 있습니다. 피해자는 공격이 시작되고 있다는 것을 인식하지 못할 수도 있습니다.

## 링크 {#links}

- [OWASP](https://owasp.org/Top10/A01_2021-Broken_Access_Control/)
- [CWE](https://cwe.mitre.org/data/definitions/942.html)
