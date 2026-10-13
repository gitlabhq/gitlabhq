---
stage: Application Security Testing
group: Composition Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Analyse des dépendances comparée au scanning de conteneurs
description: Analyse des dépendances comparée au scanning de conteneurs.
---

GitLab propose à la fois l'[analyse des dépendances](dependency_scanning/_index.md) et le [scanning de conteneurs](container_scanning/_index.md) pour assurer la couverture de tous ces types de dépendances. Pour couvrir autant que possible votre surface de risque, vous devez utiliser tous les outils de scanning de sécurité disponibles :

- L'analyse des dépendances analyse votre projet et vous indique quelles dépendances logicielles, y compris les dépendances en amont, ont été incluses dans votre projet, ainsi que les risques connus que ces dépendances contiennent.
- Le scanning de conteneurs analyse vos conteneurs et vous informe des risques connus dans les paquets du système d'exploitation (OS).

Le tableau suivant résume les types de dépendances que chaque outil de scanning peut détecter :

| Fonctionnalité                                                                                      | Analyse des dépendances | Scanning de conteneurs |
|----------------------------------------------------------------------------------------------|---------------------|--------------------|
| Identifier le manifeste, le fichier de verrouillage ou le fichier statique ayant introduit la dépendance              | {{< yes >}}         | {{< no >}}         |
| Dépendances de développement                                                                     | {{< yes >}}         | {{< no >}}         |
| Dépendances dans un fichier de verrouillage commité dans votre dépôt                                     | {{< yes >}}         | {{< yes >}} <sup>1</sup> |
| Binaires compilés par Go                                                                         | {{< no >}}          | {{< yes >}} <sup>2</sup> |
| Dépendances liées dynamiquement spécifiques au langage, installées par le système d'exploitation          | {{< no >}}          | {{< yes >}}        |
| Dépendances du système d'exploitation                                                                | {{< no >}}          | {{< yes >}}        |
| Dépendances spécifiques au langage installées sur le système d'exploitation (non compilées par votre projet) | {{< no >}}          | {{< yes >}}        |

1. Le fichier de verrouillage doit être présent dans l'image pour être détecté.
1. [Report language-specific findings](container_scanning/_index.md#report-language-specific-findings) doit être activé, et les binaires doivent être présents dans l'image pour être détectés.
