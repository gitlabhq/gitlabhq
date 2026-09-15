---
title: Le rôle Responsable sécurité est désormais généralement disponible
offering: [ gitlab_com, self_managed, gitlab_dedicated ]
tier: [ Free, Premium, Ultimate ]
stage: security_risk_management
documentation_link: "../../../user/permissions/"
work_item: https://gitlab.com/groups/gitlab-org/-/work_items/16399
categories: [ Permissions ]
level: secondary
weight: 50
---

Le rôle Responsable sécurité est désormais généralement disponible et offre un accès complet aux fonctionnalités de sécurité, notamment la gestion des vulnérabilités, les tableaux de bord de sécurité, la configuration des politiques et les outils de conformité. Les équipes de sécurité n'ont plus besoin du rôle Developer ou du rôle Maintainer pour accéder aux fonctionnalités de sécurité, ce qui élimine les risques de surprivilégiation tout en maintenant la séparation des responsabilités.

Les utilisateurs disposant du rôle Responsable sécurité ont les accès suivants :

- Gestion des vulnérabilités : afficher, trier et gérer les vulnérabilités dans les groupes et les projets.
- Politiques de sécurité : afficher et gérer les politiques de sécurité au niveau du groupe, et contribuer au YAML des politiques au niveau du projet.
- Inventaire de sécurité : afficher la couverture des scanners dans tous les projets d'un groupe.
- Profils de configuration de sécurité : afficher les profils de configuration de sécurité pour les groupes et les projets.
- Outils de conformité : afficher et gérer les événements d'audit, le centre de conformité, les cadres de conformité, les rapports de statut de conformité et les listes de dépendances au niveau des groupes et des projets.
- Protection contre les secrets lors des pushs : activer la protection contre les secrets lors des pushs pour un groupe et un projet.
- DAST à la demande : créer et exécuter des scans DAST à la demande pour un projet.
- Visibilité des runners : afficher les runners pour un groupe et un projet.

Pour commencer, accédez à un groupe et sélectionnez **Gérer > Membres** pour inviter des membres et leur attribuer le rôle de Responsable sécurité.
