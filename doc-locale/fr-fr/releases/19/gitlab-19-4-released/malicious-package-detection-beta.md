---
title: "Détection de packages malveillants dans l'analyse des dépendances (version bêta)"
tier: [ Ultimate ]
offering: [ gitlab_com, self_managed, gitlab_dedicated ]
stage: application_security_testing
documentation_link: ../../../user/application_security/gitlab_advisory_database/
work_item: https://gitlab.com/gitlab-org/gitlab/-/work_items/606037
categories: [ Software Composition Analysis ]
level: secondary
---

Dans les versions précédentes de GitLab, l'analyse des dépendances ne signalait que les packages avec des CVE connus. Les packages malveillants, conçus pour nuire par typosquattage, comptes de mainteneurs compromis ou logiciels malveillants intégrés, ne produisaient aucun résultat.

GitLab 19.4 introduit la détection de packages malveillants en version bêta. L'analyse des dépendances vérifie désormais vos dépendances par rapport aux [avis GitLab sur les logiciels malveillants](../../../user/application_security/gitlab_advisory_database/_index.md#gitlab-malware-advisories), afin que les menaces puissent être détectées avant d'être largement connues. Les résultats apparaissent dans votre liste de dépendances et votre rapport de vulnérabilités avec un badge rouge **Logiciel malveillant**, toujours de gravité Critique, identifiés par un ID `GLAM-`, et non par un CVE.

Vous pouvez également bloquer les packages malveillants avant leur fusion, en utilisant la [règle de logiciel malveillant](../../../user/application_security/policies/merge_request_approval_policies.md#block-malicious-packages-with-the-malware-rule) dans les politiques d'approbation des merge requests.

Aucune configuration supplémentaire n'est nécessaire. La couverture s'applique aux [types de packages pris en charge](../../../user/application_security/gitlab_advisory_database/_index.md#supported-package-types) : npm, PyPI, Maven, Go, NuGet, Cargo et RubyGems. Les mêmes avis alimentent l'[analyse continue des vulnérabilités](../../../user/application_security/continuous_vulnerability_scanning/_index.md#malicious-packages), et les [instances hors ligne](../../../topics/offline/quick_start_guide.md) les téléchargent manuellement.

Partagez vos commentaires sur le [ticket 606036](https://gitlab.com/gitlab-org/gitlab/-/work_items/606036).
