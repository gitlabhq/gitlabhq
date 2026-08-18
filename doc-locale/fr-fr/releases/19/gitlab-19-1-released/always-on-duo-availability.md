---
title: Mode de disponibilité Toujours activé pour GitLab Duo
offering: [ gitlab_com, self_managed, gitlab_dedicated, gitlab_dedicated_for_government ]
tier: [ Premium, Ultimate ]
stage: software_supply_chain_security
documentation_link: "../../../user/gitlab_duo/turn_on_off/#lock-gitlab-duo-on-for-all-users"
work_item: https://gitlab.com/groups/gitlab-org/-/work_items/22382
categories: [ AI Abstraction Layer ]
level: primary
---

<!-- categories: AI Abstraction Layer -->

Les administrateurs peuvent désormais configurer GitLab Duo pour qu'il soit toujours activé pour tous les projets d'une instance entière ou d'un groupe principal. Lorsque GitLab Duo est configuré pour être toujours activé, les propriétaires de groupes, de sous-groupes et de projets ne peuvent pas désactiver GitLab Duo, ce qui offre aux entreprises une gouvernance centralisée de l'IA pour les environnements soumis à des exigences de conformité et de réglementation.

Ce nouveau paramètre est symétrique au paramètre [toujours désactivé](../../../user/gitlab_duo/turn_on_off.md) existant, comblant ainsi une lacune où GitLab Duo pouvait être verrouillé en mode désactivé mais ne pouvait pas être verrouillé en mode activé. Ce nouveau paramètre est particulièrement utile pour les organisations dotées de divisions autonomes ou de filiales qui doivent garantir une utilisation cohérente des outils d'IA pour l'ensemble de leurs activités.

Pour configurer GitLab Duo afin qu'il soit toujours activé, accédez aux paramètres GitLab Duo de l'instance ou du groupe principal et définissez **Disponibilité de GitLab Duo** sur **Toujours activé**.
