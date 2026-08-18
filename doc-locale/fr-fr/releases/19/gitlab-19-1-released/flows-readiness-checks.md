---
title: Vérifications de disponibilité des flows par défaut
offering: [ self_managed, gitlab_dedicated_for_government ]
tier: [ Premium, Ultimate ]
stage: ai-powered
documentation_link: "../../administration/gitlab_duo/configure/#run-a-health-check-for-gitlab-duo"
work_item: https://gitlab.com/gitlab-org/gitlab/-/work_items/599536
categories: [ Duo Agent Platform ]
level: secondary
---

<!-- categories: Duo Agent Platform  -->

Les contrôles d'intégrité de GitLab Duo incluent désormais des vérifications de disponibilité des flows par défaut, qui vérifient que :

- Le paramètre d'exécution des flows au niveau de l'instance est activé.
- Le paramètre des flows par défaut au niveau de l'instance est activé.
- Au moins un runner d'instance actif avec le tag `gitlab--duo` est enregistré et connecté, et qu'il utilise un exécuteur compatible Docker.
