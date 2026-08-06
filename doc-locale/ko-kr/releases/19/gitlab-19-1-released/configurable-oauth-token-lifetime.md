---
title: OAuth 액세스 토큰 사용자 지정 수명 설정
tier: [ Free, Premium, Ultimate ]
offering: [ self_managed, gitlab_dedicated ]
stage: software_supply_chain_security
documentation_link: ../../../administration/settings/account_and_limit_settings/#limit-the-lifetime-of-oauth-access-tokens
work_item: https://gitlab.com/gitlab-org/gitlab/-/work_items/595570
categories: [ System Access ]
level: secondary
weight: 50
---


<!-- categories: System Access -->

기본적으로 GitLab의 OAuth 액세스 토큰은 2시간 후에 만료됩니다. GitLab 19.1부터 GitLab Self-Managed 및 GitLab Dedicated 인스턴스 운영자는 새로운 OAuth 액세스 토큰의 수명을 사용자 지정할 수 있습니다. 300초에서 7200초 사이의 값으로 설정할 수 있습니다. 이를 통해 기존 토큰의 동작 방식을 변경하지 않고도, MCP 클라이언트를 포함한 보안에 민감한 OAuth 연동 작업에 수명이 더 짧은 토큰을 강제로 적용할 수 있습니다.
