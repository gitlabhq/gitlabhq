---
title: "Couverture agrégée des scanners dans l'inventaire de sécurité"
tier: [ Ultimate ]
offering: [ gitlab_com, self_managed, gitlab_dedicated ]
stage: security_risk_management
documentation_link: "../../../user/application_security/security_inventory/"
work_item: https://gitlab.com/groups/gitlab-org/-/work_items/22124
categories: [ Security Asset Inventories ]
---

Vous pouvez désormais consulter la couverture des scanners pour l'ensemble d'une hiérarchie de groupes depuis une seule page. Dans les versions précédentes de GitLab, l'[inventaire de sécurité](../../../user/application_security/security_inventory/_index.md) affichait la couverture par sous-groupe, mais sans total pour l'ensemble du groupe. Un widget de couverture agrège désormais la couverture des scanners pour chaque projet du groupe et de ses sous-groupes, et affiche le pourcentage et le nombre de projets pour lesquels chaque scanner est activé, non activé, en échec ou obsolète. Pour vous concentrer sur un scanner spécifique, tel que SAST ou l'analyse des dépendances, utilisez la liste déroulante des scanners. Sélectionnez ensuite un statut pour filtrer la liste des projets, et activez les scanners pour les projets non couverts.

L'inventaire de sécurité vous permet également de contrôler les colonnes affichées. Pour afficher ou masquer les colonnes **Vulnérabilités**, **Couverture par les outils** et **Attributs de sécurité**, sélectionnez **Afficher**.
