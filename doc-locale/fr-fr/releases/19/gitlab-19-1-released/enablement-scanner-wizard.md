---
title: "Combler les lacunes de couverture avec l'assistant d'activation des scanners"
tier: [ Ultimate ]
offering: [ gitlab_com, self_managed, gitlab_dedicated ]
stage: security_risk_management
documentation_link: "../../../user/application_security/configuration/scanner_enablement_wizard"
work_item: https://gitlab.com/groups/gitlab-org/-/work_items/21626
categories: [ Security Asset Inventories ]
level: secondary
weight: 50
---

<!-- Category: Security Asset Inventories -->

Vous pouvez désormais utiliser l'assistant d'activation des scanners pour combler les lacunes de couverture des scanners dans vos projets, sans avoir à identifier manuellement les projets qui nécessitent une attention particulière.

Les profils de configuration de sécurité définissent les scanners qui s'exécutent et la manière dont ils le font. L'inventaire de sécurité affiche la couverture des scanners dans vos projets et vous permet d'appliquer des profils en masse à des projets ou sous-groupes sélectionnés. L'assistant y ajoute un workflow orienté objectifs : vous définissez l'objectif, et il identifie les projets dont la couverture est insuffisante et comble uniquement ces lacunes.
