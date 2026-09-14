---
title: Amélioration de la couverture de détection des secrets pour les pipelines de branches de fonctionnalités
tier: [ Free, Premium, Ultimate ]
offering: [ gitlab_com, self_managed, gitlab_dedicated, gitlab_dedicated_for_government ]
stage: application_security_testing
documentation_link: "../../../user/application_security/secret_detection/pipeline/#coverage"
work_item: https://gitlab.com/gitlab-org/gitlab/-/work_items/588910
categories: [ Secret Detection ]
level: primary
---

<!-- categories: Secret Detection -->

Dans les versions de GitLab antérieures à 19.1, vous ne pouviez pas faire confiance à un pipeline de branche de fonctionnalité pour détecter chaque secret dans votre branche. Une nouvelle branche analysait uniquement le dernier commit. Une branche existante analysait uniquement votre push le plus récent. Une information d'identification compromise dans un commit antérieur pouvait rester indétectée et atteindre des branches partagées ou la production avant d'être signalée.

Vous pouvez désormais intercepter ces secrets là où il est le moins coûteux de les corriger. Dans GitLab 19.1, la détection des secrets analyse chaque commit depuis le point de divergence de la branche avec la branche par défaut jusqu'au dernier commit. Cela signifie que moins de secrets passent inaperçus jusqu'aux étapes ultérieures, moins de temps est consacré à la rotation des informations d'identification exposées après coup, et une couverture cohérente et prévisible est assurée dans toutes vos branches.
