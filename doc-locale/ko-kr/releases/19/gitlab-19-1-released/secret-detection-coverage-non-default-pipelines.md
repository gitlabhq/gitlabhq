---
title: 기능 브랜치 파이프라인의 시크릿 검색 커버리지 개선
tier: [ Free, Premium, Ultimate ]
offering: [ gitlab_com, self_managed, gitlab_dedicated, gitlab_dedicated_for_government ]
stage: application_security_testing
documentation_link: "../../../user/application_security/secret_detection/pipeline/#coverage"
work_item: https://gitlab.com/gitlab-org/gitlab/-/work_items/588910
categories: [ Secret Detection ]
level: primary
---

<!-- categories: Secret Detection -->

GitLab 19.1 이전 버전에서는 기능 브랜치 파이프라인을 신뢰할 수 없었습니다. 브랜치의 모든 시크릿을 드러낼 수 없었기 때문입니다. 새로운 브랜치는 최신 커밋만 스캔했습니다. 기존 브랜치는 가장 최근 푸시만 스캔했습니다. 이전 커밋에서 유출된 자격 증명은 감지되지 않은 상태로 남아 있다가 공유 브랜치나 프로덕션에 도달하기 전에 플래그되었습니다.

이제 수정 비용이 가장 저렴한 곳에서 이런 시크릿을 포착할 수 있습니다. GitLab 19.1에서 시크릿 검색은 브랜치의 기본 브랜치와의 분기점부터 최신 커밋까지 모든 커밋을 스캔합니다. 즉, 더 적은 시크릿이 나중 스테이지로 누출되고, 노출된 자격 증명을 사후에 교체하는 데 소요되는 시간이 줄어들며, 브랜치 전체에서 일관되고 예측 가능한 커버리지를 제공합니다.
