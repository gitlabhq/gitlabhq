---
title: Attribuer automatiquement le rôle de relecteur aux propriétaires du code
offering: [ gitlab_com, self_managed, gitlab_dedicated ]
tier: [ Premium, Ultimate ]
stage: create
documentation_link: "../../../user/project/merge_requests/reviews/automatic_reviewer_assignment"
work_item: https://gitlab.com/groups/gitlab-org/-/work_items/20708
categories: [ Code Review Workflow ]
level: primary
---

<!-- categories: Code Review Workflow -->

Auparavant, vous deviez sélectionner manuellement les relecteurs pour chaque merge request, même lorsqu'un fichier `CODEOWNERS` définissait déjà qui devait relire chaque fichier.

Vous pouvez désormais configurer un projet pour attribuer automatiquement le rôle de relecteur aux propriétaires du code. GitLab assigne chaque propriétaire du code correspondant aux fichiers modifiés. Cela se produit lorsqu'une merge request est créée à l'état prêt ou lorsqu'un brouillon est marqué comme prêt. Si vous avez déjà assigné un relecteur, GitLab ignore l'assignation automatique et conserve votre choix.

Pour activer l'assignation automatique des relecteurs, accédez à **Paramètres** > **Requêtes de fusion** > **Affectation automatique d'un relecteur ou d'une relectrice**, puis sélectionnez **Désigner automatiquement l'ensemble des propriétaires de code en tant que relecteurs ou relectrices**.
