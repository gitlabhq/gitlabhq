---
title: "Configurer des jetons d'ID dans les flows"
tier: [ Free, Premium, Ultimate ]
offering: [ gitlab_com, self_managed, gitlab_dedicated, gitlab_dedicated_for_government ]
stage: ai-powered
documentation_link: "../../../user/duo_agent_platform/flows/execution/#configure-id-tokens"
work_item: https://gitlab.com/gitlab-org/gitlab/-/work_items/591140
categories: [ Runner Execution, System Access ]
level: secondary
weight: 50
---

Utilisez des jetons d'ID pour vous authentifier auprès de services OpenID Connect (OIDC) tiers sans stocker de credentials à longue durée de vie. Par exemple, utilisez des jetons d'ID pour la signature sans clé de binaires et de commits, ou pour récupérer des secrets depuis un gestionnaire de secrets.

Pour utiliser cette fonctionnalité, mettez à jour la configuration de votre agent pour inclure le mot-clé `id_tokens`, puis configurez le service pour qu'il fasse confiance aux jetons émis par GitLab Duo Agent Platform.
