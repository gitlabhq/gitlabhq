---
title: Diagnostiquer les échecs de synchronisation des groupes LDAP
tier: [ Premium, Ultimate ]
offering: [ self_managed ]
stage: software_supply_chain_security
co_create: true
documentation_link: "../../../administration/auth/ldap/#ldap-sync-configuration-settings"
work_item: https://gitlab.com/gitlab-org/gitlab/-/merge_requests/250622
categories: [ System Access ]
level: secondary
weight: 10
---

Lorsqu'une synchronisation de groupe LDAP échoue, la raison vous est désormais communiquée. L'échec est enregistré au niveau du groupe, les membres qui en sont à l'origine sont identifiés (jusqu'à cinq), et une alerte de danger s'affiche sur la page des membres du groupe. Ainsi, une synchronisation bloquée par une restriction de domaine de messagerie peut être diagnostiquée depuis l'interface utilisateur. Un nouveau paramètre `group_filter` vous permet de définir quelles entrées LDAP sont considérées comme des groupes. Le journal d'audit distingue également les causes qui partageaient auparavant une seule entrée : les liens de groupe LDAP créés et supprimés, ainsi que les utilisateurs bloqués par la synchronisation LDAP, disposent désormais chacun de leur propre type d'événement d'audit.

Merci à [Sergey Pechenko](https://gitlab.com/tnt4brain) pour ces contributions ([MR 1](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/250622) [MR 2](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/253816) [MR 3](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/252957) [MR 4](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/247146)) !
