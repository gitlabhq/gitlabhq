---
title: Le flow Fix CI/CD Pipeline suggère des correctifs ciblés
tier: [ Free, Premium, Ultimate ]
offering: [ gitlab_com, self_managed, gitlab_dedicated, gitlab_dedicated_for_government ]
stage: verify
documentation_link: "../../../user/duo_agent_platform/flows/foundational_flows/fix_pipeline"
work_item: https://gitlab.com/groups/gitlab-org/-/work_items/21837
categories: [ Continuous Integration (CI) ]
level: secondary
weight: 10
---

Le flow Fix CI/CD Pipeline de GitLab Duo apporte désormais deux améliorations essentielles :

- Lorsque les fichiers concernés sont déjà présents dans le diff de votre merge request, vous recevez des correctifs sous forme de suggestions de code directement sur cette merge request.
- Le flow classe les échecs de pipeline avant d'agir, ce qui vous permet d'obtenir un diagnostic plus ciblé.

Le flow analyse également les échecs de pipeline enfant dans l'ensemble de la hiérarchie de pipeline, vous permet de personnaliser son comportement pour votre projet avec un fichier `AGENTS.md`, et réduit le raisonnement de l'IA par défaut pour garder les commentaires de votre merge request clairs.

Partagez vos commentaires dans le [ticket de feedback](https://gitlab.com/gitlab-org/gitlab/-/work_items/601991).
