---
title: "Merge requests empilées dans l'interface utilisateur"
offering: [ gitlab_com, self_managed, gitlab_dedicated ]
tier: [ Free, Premium, Ultimate ]
stage: create
documentation_link: "../../../user/project/merge_requests/reviews/stacked_merge_requests"
work_item: https://gitlab.com/groups/gitlab-org/-/work_items/22211
categories: [ Code Review Workflow ]
level: secondary
---

<!-- categories: Code Review Workflow -->

Auparavant, lorsque vous divisiez une modification importante en plusieurs merge requests plus petites s'appuyant les unes sur les autres, l'interface utilisateur ne donnait aucun signal indiquant qu'elles étaient liées. Les auteurs et les relecteurs devaient suivre manuellement la séquence.

GitLab détecte désormais automatiquement les merge requests empilées et les affiche dans l'en-tête de la merge request. Une merge request rejoint une pile lorsqu'elle cible la branche source d'une autre merge request ouverte, ou lorsqu'une autre merge request ouverte cible sa branche source. Le contrôle de pile situé à côté de la branche source affiche la position actuelle (par exemple, **1 of 2**) et vous permet d'accéder à n'importe quelle autre merge request dans la pile.

Pour créer des merge requests empilées depuis la ligne de commande, utilisez les diffs empilés dans la CLI GitLab.
