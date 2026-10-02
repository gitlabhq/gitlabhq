---
title: "Prise en charge des expressions de licence SPDX dans l'analyse des dépendances et des licences"
tier: [ Ultimate ]
offering: [ gitlab_com, self_managed, gitlab_dedicated ]
stage: software_supply_chain_security
documentation_link: ../../../user/compliance/license_scanning_of_cyclonedx_files/
work_item: https://gitlab.com/groups/gitlab-org/-/work_items/16801
categories: [ "Software Composition Analysis" ]
level: primary
---

Les données de licence GitLab contiennent désormais des expressions de licence SPDX, y compris des déclarations composites telles que `MIT OR Apache-2.0` ou `GPL-2.0-only WITH Classpath-exception-2.0`. Auparavant, ces éléments étaient signalés comme `unknown` dans la liste des dépendances et n'étaient pas visibles par les politiques d'approbation des licences.

Les licences composites apparaissent désormais dans la liste des dépendances avec leur opérateur (`AND`, `OR`, `WITH`), et les politiques d'approbation des licences peuvent les autoriser ou les refuser de la même manière qu'elles traitent les dépendances à licence unique.

Les expressions déclarées dans un SBOM CycloneDX sont prises en charge depuis GitLab 19.3. Cette release les ajoute aux données de licence que GitLab synchronise. Les instances hors ligne reçoivent les expressions uniquement après [téléchargement des données de licence v3](../../../topics/offline/quick_start_guide.md#download-v3-license-data).
