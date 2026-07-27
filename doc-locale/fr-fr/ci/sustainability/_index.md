---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "Mesurez et réduisez l'empreinte carbone de vos pipelines CI/CD avec des outils de durabilité."
title: Durabilité des pipelines
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

> [!note]
> Les outils de durabilité décrits sur cette page sont des intégrations tierces. GitLab ne maintient pas ces outils, ne fournit pas de support pour ceux-ci et ne garantit pas qu'ils satisfont des exigences réglementaires ou de conformité.

Les pipelines CI/CD consomment des ressources informatiques qui génèrent des émissions de carbone. Vous pouvez intégrer des outils tiers pour mesurer et réduire les émissions de portée 3 issues de vos workflows de développement logiciel à des fins de reporting en matière de durabilité et de conformité réglementaire.

Les émissions de portée 3 sont des émissions indirectes provenant de votre chaîne d'approvisionnement et de vos fournisseurs, y compris l'infrastructure cloud qui exécute vos pipelines CI/CD.

L'intégration d'outils de durabilité dans vos pipelines offre les avantages suivants :

- Suivre et signaler les émissions de carbone issues de votre infrastructure CI/CD.
- Identifier les jobs gourmands en ressources et les opportunités d'optimisation.
- Prendre des décisions basées sur les données concernant la sélection des runners et la planification des jobs.
- Atteindre les objectifs de durabilité et les exigences réglementaires.

## Mesure des émissions {#emission-measurement}

Les émissions des pipelines CI/CD proviennent des ressources informatiques utilisées pour exécuter les jobs. L'empreinte carbone dépend de la consommation d'énergie liée à l'utilisation du processeur, à l'utilisation de la mémoire et au temps d'exécution. Elle varie également en fonction de l'intensité carbone, qui représente les émissions de carbone par unité d'électricité et varie selon la région et l'heure de la journée. Des facteurs d'infrastructure tels que les fournisseurs cloud, les emplacements des centres de données et l'efficacité matérielle contribuent également à l'impact global.

Les outils de durabilité utilisent différentes approches pour calculer les émissions :

- Les modèles d'estimation calculent la consommation d'énergie en fonction des modèles d'utilisation du processeur et des courbes de puissance précalculées.
- La mesure réelle utilise les API des fournisseurs cloud pour récupérer les données de consommation de ressources réelles.
- Les recherches d'intensité carbone interrogent des services tels que [Electricity Maps](https://app.electricitymaps.com/dashboard) pour appliquer les facteurs carbone régionaux et les variations temporelles.

## Mesurer les émissions avec Eco CI {#measure-emissions-with-eco-ci}

Eco CI mesure la consommation d'énergie et les émissions de carbone des pipelines CI/CD. Il s'exécute sous forme de scripts bash légers au sein des jobs de votre pipeline et ne nécessite pas de serveurs ni de bases de données distincts.

Pour plus d'informations, consultez [Eco CI](eco_ci.md).

## Bonnes pratiques {#best-practices}

Envisagez les stratégies suivantes pour réduire l'empreinte carbone de vos pipelines CI/CD.

### Optimiser l'exécution des jobs {#optimize-job-execution}

Pour optimiser l'exécution des jobs :

- Utilisez la mise en cache pour éviter les tâches redondantes.
- Au lieu d'effectuer des builds gourmands en ressources au début de plusieurs jobs, exécutez le build une seule fois dans un job précoce. Partagez ensuite la sortie en tant qu'artefact avec tous les jobs ultérieurs qui en ont besoin.
- Définissez des valeurs de délai d'attente appropriées pour éviter les jobs incontrôlés.
- Utilisez des images Docker plus légères pour réduire le temps de téléchargement et de démarrage.

### Choisir des runners efficaces {#choose-efficient-runners}

Pour choisir des runners efficaces :

- Sélectionnez des types d'instances de runner qui correspondent aux exigences de votre charge de travail.
- Évitez le surprovisionnement de ressources pour les jobs simples.
- Envisagez d'utiliser des instances spot pour les charges de travail non critiques.
- Utilisez la mise à l'échelle automatique pour adapter la capacité à la demande.

### Planifier de manière stratégique {#schedule-strategically}

Pour planifier de manière stratégique :

- Planifiez l'exécution des pipelines gourmands en ressources lorsque la majeure partie de l'énergie renouvelable est disponible dans la région de votre serveur CI. Consultez [Electricity Maps](https://app.electricitymaps.com/map/live/hourly) pour trouver les meilleurs moments et régions. Le milieu de la journée est généralement un bon choix par défaut.
- Envisagez une planification tenant compte du carbone pour les pipelines non urgents.
- Regroupez des jobs similaires pour améliorer l'utilisation des ressources.

### Surveiller et itérer {#monitor-and-iterate}

Pour surveiller et itérer sur vos efforts en matière de durabilité :

- Établissez des métriques de référence pour vos pipelines.
- Définissez des objectifs de réduction des émissions.
- Examinez régulièrement les jobs à fort impact pour identifier les opportunités d'optimisation.
- Partagez les métriques de durabilité avec votre équipe.

## Sujets connexes {#related-topics}

- [Efficacité des pipelines](../pipelines/pipeline_efficiency.md)
- [Mise en cache des dépendances](../caching/_index.md)
- [Pipelines planifiés](../pipelines/schedules.md)
