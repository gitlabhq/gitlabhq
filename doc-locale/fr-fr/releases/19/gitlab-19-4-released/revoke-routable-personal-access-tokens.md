---
title: "Révocation automatique pour les jetons d'accès personnels routables"
tier: [ Ultimate ]
offering: [ gitlab_com, self_managed, gitlab_dedicated ]
stage: application_security_testing
documentation_link: "../../../user/application_security/secret_detection/automatic_response"
work_item: https://gitlab.com/gitlab-org/gitlab/-/work_items/623418
categories: [ Secret Detection ]
---

Lorsque la détection des secrets trouve un jeton d'accès personnel GitLab divulgué dans un projet public, la réponse automatique le révoque. Dans les versions de GitLab antérieures à la version 19.4, la révocation n'utilisait qu'une seule règle de détection et ne révoquait que le format de jeton hérité. Les jetons créés sur GitLab 18.3 et versions ultérieures utilisent le format routable ou le format routable versionné. GitLab détectait et signalait ces jetons sans les révoquer.

Dans GitLab 19.4 et versions ultérieures, la révocation reconnaît les trois règles de détection de jeton d'accès personnel GitLab :

- `gitlab_personal_access_token`
- `gitlab_personal_access_token_routable`
- `gitlab_personal_access_token_routable_versioned`

La révocation couvre également les résultats de [GitLab Secret Scanning for Source Code](../../../user/application_security/secret_detection/gitlab_secret_scanner/_index.md) et de l'[analyseur basé sur Gitleaks](../../../user/application_security/secret_detection/pipeline/_index.md). Vous n'avez pas besoin de modifier la configuration. Les instances pour lesquelles la réponse automatique est activée bénéficient immédiatement de cette couverture étendue.
