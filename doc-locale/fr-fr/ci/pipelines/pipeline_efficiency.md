---
stage: Verify
group: Pipeline Execution
info: This page is maintained by Developer Relations, author @dnsmichi, see <https://handbook.gitlab.com/handbook/marketing/developer-relations/developer-advocacy/content/#maintained-documentation>
title: Efficacité des pipelines
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

[Les pipelines CI/CD](_index.md) sont les éléments fondamentaux de [GitLab CI/CD](../_index.md). Rendre les pipelines plus efficaces vous permet d'économiser du temps de développement, ce qui :

- Accélère vos processus DevOps
- Réduit les coûts
- Raccourcit la boucle de feedback du développement

Il est courant que les nouvelles équipes ou les nouveaux projets démarrent avec des pipelines lents et inefficaces, et améliorent leur configuration au fil du temps par essais et erreurs. Une meilleure approche consiste à utiliser les fonctionnalités de pipeline qui améliorent l'efficacité immédiatement et à bénéficier d'un cycle de vie de développement logiciel plus rapide plus tôt.

Assurez-vous d'abord de maîtriser les [fondamentaux de GitLab CI/CD](../_index.md) et de comprendre le [guide de démarrage rapide](../quick_start/_index.md).

## Identifier les goulots d'étranglement et les défaillances courantes {#identify-bottlenecks-and-common-failures}

Les indicateurs les plus faciles à vérifier pour détecter des pipelines inefficaces sont les durées d'exécution des jobs, des étapes et la durée totale d'exécution du pipeline lui-même. La durée totale du pipeline est fortement influencée par :

- [La taille du dépôt](../../user/project/repository/monorepos/_index.md)
- Le nombre total d'étapes et de jobs.
- Les dépendances entre les jobs.
- Le [« chemin critique »](#needs-dependency-visualization), qui représente la durée minimale et maximale du pipeline.

Des points supplémentaires à prendre en compte concernent les [GitLab Runners](../runners/_index.md) :

- La disponibilité des runners et des ressources dont ils disposent.
- Les dépendances de build, leur temps d'installation et les besoins en espace de stockage.
- [La taille des images de conteneurs](#docker-images).
- La latence réseau et les connexions lentes.

Les pipelines qui échouent inutilement de façon répétée ralentissent également le cycle de vie de développement. Vous devez rechercher les schémas problématiques dans les jobs en échec :

- Les tests unitaires instables qui échouent aléatoirement ou produisent des résultats de test peu fiables.
- Les baisses de couverture de test et la qualité du code corrélées à ce comportement.
- Les échecs qui peuvent être ignorés sans risque, mais qui interrompent le pipeline à la place.
- Les tests qui échouent à la fin d'un long pipeline, alors qu'ils pourraient être placés dans une étape antérieure, ce qui provoque un feedback tardif.

## Analyse du pipeline {#pipeline-analysis}

Analysez les performances de votre pipeline pour trouver des moyens d'améliorer son efficacité. L'analyse peut aider à identifier les blocages potentiels dans l'infrastructure CI/CD. Cela inclut l'analyse de :

- Les charges de travail des jobs.
- Les goulots d'étranglement dans les temps d'exécution.
- L'architecture globale du pipeline.

Il est important de comprendre et de documenter les flux de travail du pipeline, et de discuter des actions et modifications possibles. La refactorisation des pipelines peut nécessiter une interaction attentive entre les équipes dans le cycle de vie DevSecOps.

L'analyse du pipeline peut aider à identifier les problèmes d'efficacité des coûts. Par exemple, les [runners](../runners/_index.md) hébergés sur un service cloud payant peuvent être provisionnés avec :

- Plus de ressources que nécessaire pour les pipelines CI/CD, ce qui entraîne un gaspillage d'argent.
- Pas assez de ressources, ce qui provoque des temps d'exécution lents et une perte de temps.

### Pipeline Insights {#pipeline-insights}

Les [graphiques de succès et de durée des pipelines](_index.md#pipeline-success-and-duration-charts) fournissent des informations sur le temps d'exécution des pipelines et le nombre de jobs en échec.

Des tests comme les [tests unitaires](../testing/unit_test_reports.md), les tests d'intégration, les tests de bout en bout, les tests de [qualité du code](../testing/code_quality.md) et autres garantissent que les problèmes sont automatiquement détectés par le pipeline CI/CD. De nombreuses étapes de pipeline peuvent être impliquées, entraînant des temps d'exécution longs.

Vous pouvez améliorer les temps d'exécution en lançant en parallèle des jobs qui testent différentes choses, dans la même étape, réduisant ainsi le temps d'exécution global. L'inconvénient est que vous avez besoin de davantage de runners fonctionnant simultanément pour prendre en charge les jobs parallèles.

### Visualisation des dépendances `needs` {#needs-dependency-visualization}

L'affichage des dépendances `needs` dans le [graphe de pipeline complet](_index.md#group-jobs-by-stage-or-needs-configuration) peut aider à analyser le chemin critique du pipeline et à comprendre les blocages potentiels.

### Surveillance du pipeline {#pipeline-monitoring}

La santé globale du pipeline est un indicateur clé à surveiller, tout comme la durée des jobs et des pipelines. Les [analyses CI/CD](_index.md#pipeline-success-and-duration-charts) offrent une représentation visuelle de la santé du pipeline.

Les administrateurs d'instance ont accès à des [métriques de performance et à l'auto-surveillance](../../administration/monitoring/_index.md) supplémentaires.

Vous pouvez récupérer des métriques de santé de pipeline spécifiques depuis l'[API](../../api/rest/_index.md). Les outils de surveillance externes peuvent interroger l'API et vérifier la santé du pipeline ou collecter des métriques pour des analyses SLA à long terme.

Par exemple, le [GitLab CI Pipelines Exporter](https://github.com/mvisonneau/gitlab-ci-pipelines-exporter) pour Prometheus récupère des métriques depuis l'API et les événements de pipeline. Il peut vérifier automatiquement les branches dans les projets et obtenir le statut et la durée du pipeline. En combinaison avec un tableau de bord Grafana, cela aide à construire une vue actionnable pour votre équipe des opérations. Les graphiques de métriques peuvent également être intégrés dans les incidents, facilitant ainsi la résolution des problèmes. De plus, il peut également exporter des métriques sur les jobs et les environnements.

Si vous utilisez le GitLab CI Pipelines Exporter, commencez par la [configuration d'exemple](https://github.com/mvisonneau/gitlab-ci-pipelines-exporter/blob/main/docs/configuration_syntax.md).

![Tableau de bord Grafana affichant les statuts d'exécution CI et les statistiques historiques, notamment la fréquence et le taux d'échec.](img/ci_efficiency_pipeline_health_grafana_dashboard_v13_7.png)

Vous pouvez également utiliser un outil de surveillance capable d'exécuter des scripts, comme [`check_gitlab`](https://gitlab.com/6uellerBpanda/check_gitlab) par exemple.

#### Surveillance des runners {#runner-monitoring}

Vous pouvez également [surveiller les runners CI](https://docs.gitlab.com/runner/monitoring/) sur leurs systèmes hôtes, ou dans des clusters comme Kubernetes. Cela inclut la vérification de :

- Le disque et les E/S disque
- L'utilisation du CPU
- La mémoire
- Les ressources du processus runner

Le [Prometheus Node Exporter](https://prometheus.io/docs/guides/node-exporter/) peut surveiller les runners sur des hôtes Linux, et [`kube-state-metrics`](https://github.com/kubernetes/kube-state-metrics) s'exécute dans un cluster Kubernetes.

Vous pouvez également tester la [mise à l'échelle automatique de GitLab Runner](https://docs.gitlab.com/runner/configuration/autoscale/) avec des fournisseurs cloud et définir des périodes hors ligne pour réduire les coûts.

#### Tableaux de bord et gestion des incidents {#dashboards-and-incident-management}

Utilisez vos outils de surveillance et tableaux de bord existants pour intégrer la surveillance des pipelines CI/CD, ou créez-les de zéro. Assurez-vous que les données d'exécution sont actionnables et utiles pour les équipes, et que les équipes opérations/SRE sont en mesure d'identifier les problèmes suffisamment tôt. La [gestion des incidents](../../operations/incident_management/_index.md) peut également être utile ici, avec des graphiques de métriques intégrés et tous les détails pertinents pour analyser le problème.

### Utilisation du stockage {#storage-usage}

Examinez l'utilisation du stockage des éléments suivants pour analyser les coûts et l'efficacité :

- Les [artefacts de job](../jobs/job_artifacts.md) et leur configuration [`expire_in`](../yaml/_index.md#artifactsexpire_in). S'ils sont conservés trop longtemps, l'utilisation du stockage augmente et peut ralentir les pipelines.
- L'utilisation du [registre de conteneurs](../../user/packages/container_registry/_index.md).
- L'utilisation du [registre de paquets](../../user/packages/package_registry/_index.md).

## Configuration du pipeline {#pipeline-configuration}

Faites des choix réfléchis lors de la configuration des pipelines pour les accélérer et réduire l'utilisation des ressources. Cela inclut l'utilisation des fonctionnalités intégrées de GitLab CI/CD qui permettent aux pipelines de s'exécuter plus rapidement et plus efficacement.

### Réduire la fréquence d'exécution des jobs {#reduce-how-often-jobs-run}

Essayez de déterminer quels jobs n'ont pas besoin de s'exécuter dans toutes les situations, et utilisez la configuration du pipeline pour les empêcher de s'exécuter :

- Utilisez le mot-clé [`interruptible`](../yaml/_index.md#interruptible) pour arrêter les anciens pipelines lorsqu'ils sont remplacés par un pipeline plus récent.
- Utilisez [`rules`](../yaml/_index.md#rules) pour ignorer les tests qui ne sont pas nécessaires. Par exemple, ignorez les tests backend lorsque seul le code frontend a été modifié.
- Exécutez moins fréquemment les [pipelines planifiés](schedules.md) non essentiels.
- Répartissez les planifications [`cron`](schedules.md#distribute-pipeline-schedules-to-prevent-system-load) uniformément dans le temps.

### Fail fast {#fail-fast}

Assurez-vous que les erreurs sont détectées tôt dans le pipeline CI/CD. Un job qui prend très longtemps à s'exécuter empêche le pipeline de renvoyer un statut d'échec jusqu'à la fin du job.

Concevez les pipelines de façon à ce que les jobs capables d'[échouer rapidement](../testing/fail_fast_testing.md) s'exécutent en premier. Par exemple, ajoutez une étape précoce et déplacez-y les jobs de vérification de la syntaxe, de linting du style, de vérification des messages de commit Git et les tâches similaires.

Décidez s'il est important que les jobs longs s'exécutent tôt, avant de recevoir un feedback rapide des jobs plus rapides. Les échecs initiaux peuvent indiquer clairement que le reste du pipeline ne devrait pas s'exécuter, ce qui permet d'économiser des ressources.

### Mot-clé `needs` {#needs-keyword}

Dans une configuration de base, les jobs attendent toujours que tous les autres jobs des étapes précédentes soient terminés avant de s'exécuter. C'est la configuration la plus simple, mais aussi la plus lente dans la plupart des cas. Les [pipelines avec le mot-clé `needs`](../yaml/needs.md) et les [pipelines parent-enfant](downstream_pipelines.md#parent-child-pipelines) sont plus flexibles et peuvent être plus efficaces, mais peuvent également rendre les pipelines plus difficiles à comprendre et à analyser.

### Mise en cache {#caching}

Une autre méthode d'optimisation consiste à mettre en [cache](../caching/_index.md) les dépendances. Si vos dépendances changent rarement, comme [NodeJS `/node_modules`](../caching/examples.md#nodejs), la mise en cache peut accélérer considérablement l'exécution du pipeline.

Vous pouvez utiliser [`cache:when`](../yaml/_index.md#cachewhen) pour mettre en cache les dépendances téléchargées même lorsqu'un job échoue.

### Images Docker {#docker-images}

Le téléchargement et l'initialisation des images Docker peuvent représenter une grande partie du temps d'exécution global des jobs.

Si une image Docker ralentit l'exécution des jobs, analysez la taille de l'image de base et la connexion réseau au registre de conteneurs. Si GitLab s'exécute dans le cloud, recherchez un registre de conteneurs cloud proposé par le fournisseur. En outre, vous pouvez utiliser le [registre de conteneurs GitLab](../../user/packages/container_registry/_index.md), auquel l'instance GitLab peut accéder plus rapidement que d'autres registres.

#### Optimiser les images Docker {#optimize-docker-images}

Créez des images Docker optimisées, car les images Docker volumineuses occupent beaucoup d'espace et prennent beaucoup de temps à télécharger avec des connexions plus lentes. Si possible, évitez d'utiliser une seule image volumineuse pour tous les jobs. Utilisez plusieurs images plus petites, chacune dédiée à une tâche spécifique, qui se téléchargent et s'exécutent plus rapidement.

Essayez d'utiliser des images Docker personnalisées avec le logiciel pré-installé. Il est généralement beaucoup plus rapide de télécharger une image préconfigurée plus volumineuse que d'utiliser une image commune et d'y installer des logiciels à chaque fois. L'[article sur les bonnes pratiques pour l'écriture de Dockerfiles](https://docs.docker.com/develop/develop-images/dockerfile_best-practices/) de Docker contient plus d'informations sur la création d'images Docker efficaces.

Méthodes pour réduire la taille des images Docker :

- Utilisez une petite image de base, par exemple `debian-slim`.
- N'installez pas d'outils pratiques comme vim ou curl s'ils ne sont pas strictement nécessaires.
- Créez une image de développement dédiée.
- Désactivez les pages de manuel et la documentation installées par les paquets pour économiser de l'espace.
- Réduisez les couches `RUN` et combinez les étapes d'installation des logiciels.
- Utilisez les [builds multi-étapes](https://blog.alexellis.io/mutli-stage-docker-builds/) pour fusionner plusieurs Dockerfiles qui utilisent le modèle builder en un seul Dockerfile, ce qui peut réduire la taille de l'image.
- Si vous utilisez `apt`, ajoutez `--no-install-recommends` pour éviter les paquets inutiles.
- Nettoyez les caches et les fichiers qui ne sont plus nécessaires à la fin. Par exemple `rm -rf /var/lib/apt/lists/*` pour Debian et Ubuntu, ou `yum clean all` pour RHEL et CentOS.
- Utilisez des outils comme [dive](https://github.com/wagoodman/dive) ou [DockerSlim](https://github.com/docker-slim/docker-slim) pour analyser et réduire la taille des images.

Pour simplifier la gestion des images Docker, vous pouvez créer un groupe dédié à la gestion des [images Docker](../docker/_index.md) et les tester, créer et publier avec des pipelines CI/CD.

## Tester, documenter et apprendre {#test-document-and-learn}

L'amélioration des pipelines est un processus itératif. Effectuez de petites modifications, surveillez l'effet, puis recommencez. De nombreuses petites améliorations peuvent se cumuler pour aboutir à une augmentation significative de l'efficacité du pipeline.

Il peut être utile de documenter la conception et l'architecture du pipeline. Vous pouvez le faire avec des [graphiques Mermaid en Markdown](../../user/markdown.md#mermaid) directement dans le dépôt GitLab.

Documentez les problèmes et les incidents de pipeline CI/CD dans des tickets, en incluant les recherches effectuées et les solutions trouvées. Cela facilite l'intégration des nouveaux membres de l'équipe et aide également à identifier les problèmes récurrents d'efficacité des pipelines CI.

### Sujets connexes {#related-topics}

- [Diapositives du webcast CI Monitoring](https://docs.google.com/presentation/d/1ONwIIzRB7GWX-WOSziIIv8fz1ngqv77HO1yVfRooOHM/edit?usp=sharing)
- Manuel de surveillance GitLab.com
- [Création de tableaux de bord pour la visibilité opérationnelle](https://aws.amazon.com/builders-library/building-dashboards-for-operational-visibility/)
