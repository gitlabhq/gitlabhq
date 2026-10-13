---
title: Le widget de merge request est désormais plus précis
tier: [ Free, Premium, Ultimate ]
offering: [ gitlab_com, self_managed, gitlab_dedicated ]
stage: ai_coding
co_create: true
documentation_link: "../../../user/project/merge_requests/widgets/"
work_item: https://gitlab.com/gitlab-org/gitlab/-/merge_requests/251657
categories: [ Code Review Workflow ]
level: secondary
weight: 20
---

Lorsque GitLab vérifie une merge request, le widget vous en informe désormais. **Les conflits de merge doivent être résolus** devient **Vérification des conflits de merge** jusqu'à la fin de la vérification. Lorsqu'un rebase est refusé, vous voyez la raison précise, par exemple **La branche source est protégée contre les poussées forcées**, au lieu d'une invite de nouvelle tentative générique. Vous pouvez agir en fonction de l'état actuel de la merge request.

La barre de titre persistante qui reste visible lors du défilement d'une merge request se met également à jour immédiatement lorsque vous la marquez comme brouillon ou comme prête, sans nécessiter de rechargement de la page.

Merci aux utilisateurs suivants pour ces contributions !

- [Amartya Mishra](https://gitlab.com/Gamezordd) ([MR 1](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/253806) [MR 2](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/251657))
- [Gerardo Navarro](https://gitlab.com/gerardo-navarro) ([MR](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/252050))
- [Mahaveer A](https://gitlab.com/Mahaveer1013) ([MR](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/251290))
