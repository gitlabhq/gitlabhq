---
title: Disponibilité sélective de GitLab Duo pour les sous-groupes
tier: [ Ultimate ]
offering: [ gitlab_dedicated, gitlab_dedicated_for_government ]
stage: software_supply_chain_security
documentation_link: "../../../user/gitlab_duo/turn_on_off/#lock-gitlab-duo-off-for-selected-subgroups"
work_item: https://gitlab.com/groups/gitlab-org/-/work_items/22389
categories: [ AI Agents ]
level: primary
weight: 50
---

Les administrateurs des instances GitLab Dedicated peuvent rendre GitLab Duo et GitLab Duo Agent Platform indisponibles pour certains sous-groupes, tandis que d'autres sous-groupes conservent la possibilité de les activer.

Auparavant, vous pouviez soit désactiver GitLab Duo et Agent Platform pour l'ensemble d'une instance, soit les rendre potentiellement disponibles pour tous.

Vous pouvez désormais appliquer une liste d'autorisation par sous-groupe avec refus par défaut. Marquez des sous-groupes spécifiques comme **Always off (locked)** afin que leurs groupes et projets descendants ne puissent jamais activer GitLab Duo et Agent Platform, tout en laissant les autres sous-groupes à la discrétion des utilisateurs disposant du rôle Owner. Seuls les administrateurs peuvent appliquer ou supprimer le verrouillage, et les Owners concernés voient un message clair indiquant que GitLab Duo est verrouillé par un groupe parent.

Cette fonctionnalité aide les équipes de conformité et de gouvernance des plateformes à répondre aux exigences strictes en matière de classification des données.
