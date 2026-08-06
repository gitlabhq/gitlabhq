---
title: 취약성 세부 정보에 더 명확한 보안 산업 표준 레이블 적용
stage: application_security_testing
level: secondary
tier: [ Ultimate ]
offering: [ gitlab_com, self_managed, gitlab_dedicated ]
documentation_link: "../../../user/application_security/vulnerabilities/"
work_item: "https://gitlab.com/groups/gitlab-org/-/work_items/21978"
categories: [ Vulnerability Management ]
---

<!-- categories: Vulnerability Management -->

GitLab 19.1에서는 취약성 검사 결과 세부 정보 페이지에 일관되고 설명이 명확하며, 보안 산업 표준에 맞는 용어를 사용합니다.

- 기존 **스캐너**는 **다음에 의해 검출됨**으로 변경됩니다.
- 기존 **EPSS**는 **악용 확률 (EPSS)**로 변경됩니다.
- 기존 **알려진 악용사례 (KEV)**는 **알려진 악용사례 (CISA KEV)**로 변경됩니다.
- 기존 **도달가능**은 **도달가능성**으로 변경됩니다.
- 기존 **이미지**는 **컨테이너 이미지**(컨테이너 스캐닝)로 변경됩니다.
- 기존 **위치**는 **영향을 받는 위치**로 변경됩니다.
- 기존 **URL**은 **영향을 받는 엔드포인트**(DAST, API 퍼징)로 변경됩니다.
- 기존 **메소드**는 **HTTP 메소드**(DAST, API 퍼징)로 변경됩니다.
- 기존 **솔루션**은 **해결 가이드라인**으로 변경됩니다.
- 기존 **링크**는 **참조**로 변경됩니다.
