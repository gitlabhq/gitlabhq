---
title: "Autres ajouts à l'interface"
tier: [ Free, Premium, Ultimate ]
offering: [ gitlab_com, self_managed, gitlab_dedicated ]
stage: plan
co_create: true
documentation_link: "../../../user/project/issues/managing_issues/#filter-the-list-of-issues"
work_item: https://gitlab.com/gitlab-org/gitlab/-/merge_requests/250014
categories: [ Team Planning ]
level: secondary
---

Cette release inclut également les ajouts suivants à l'interface :

- Le filtrage de la liste des tickets par date de création, de fermeture, d'échéance et de mise à jour est désormais disponible pour tous.
- La création d'une merge request à partir d'un commit cherry-pick dispose désormais d'une case à cocher permettant de copier la description de la merge request source à la place du modèle de projet.
- `/internal_note` marque un commentaire comme interne au moment de sa création, ce qui permet d'intégrer des notes internes dans les modèles de commentaires et les réponses enregistrées.
- `/type Epic` promeut un ticket en epic, de la même façon que `/promote_to Epic`.
- Les liens dans les diagrammes de flux Mermaid s'ouvrent désormais, et les diagrammes s'affichent sans être tronqués dans Chrome sur iOS.

Merci aux utilisateurs suivants pour leurs contributions !

- [Radek Antoniuk](https://gitlab.com/rantoniuk) ([MR](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/250014))
- [Viktor Chekryzhov](https://gitlab.com/Vchekryzhov1) ([MR](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/248574))
- [Priyansh Garg](https://gitlab.com/priyansh3133) ([MR](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/243383))
- [Aryann Dwivedi](https://gitlab.com/aryanndwivedi2403) ([MR](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/241880))
- [skkzsh](https://gitlab.com/skkzsh) ([MR](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/253987))
- [Jordan Labrosse](https://gitlab.com/Jorgagu) ([MR](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/250484))
