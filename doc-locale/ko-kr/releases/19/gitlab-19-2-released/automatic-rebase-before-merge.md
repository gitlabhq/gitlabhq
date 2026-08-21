---
title: 머지하기 전에 자동 리베이스
offering: [ gitlab_com, self_managed, gitlab_dedicated ]
tier: [ Free, Premium, Ultimate ]
stage: ai_coding
documentation_link: "../../../user/project/merge_requests/methods/#automatic-rebase-before-merge"
work_item: https://gitlab.com/groups/gitlab-org/-/work_items/16803
categories: [ Code Review Workflow ]
---


이전 GitLab 버전에서는 프로젝트가 반선형 또는 빨리감기 머지 방법을 사용한 경우, 소스 브랜치가 대상 브랜치보다 뒤처졌을 때 추가 단계를 완료해야 했습니다. 머지하려면 **Rebase**를 선택하고 완료될 때까지 기다린 다음, 머지 리퀘스트로 돌아가서 **머지**를 선택해야 했습니다. 이 2단계 인수 인계는 모든 머지에 마찰을 더했습니다.

이제 프로젝트의 머지 리퀘스트 설정에서 **머지하기 전에 자동 리베이스 활성화**를 선택할 수 있습니다. 이 설정을 켜면 GitLab이 머지할 때 소스 브랜치를 대상 브랜치로 리베이스하며, 단일 작업으로 머지할 수 있습니다. 개별 커밋의 GPG 서명을 보존하는 것이 중요한 경우, 설정을 끌 수 있습니다.
