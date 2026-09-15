---
stage: Release Notes
group: Monthly Release
date: 2025-01-16
title: "Notes de release de GitLab 17.8"
description: "GitLab 17.8 publié avec Renforcer la sécurité grâce aux dépôts de conteneurs protégés"
---

<!-- markdownlint-disable -->
<!-- vale off -->

Le 16 janvier 2025, GitLab 17.8 a été publié avec les fonctionnalités suivantes.

Nous souhaitons également remercier tous nos contributeurs, dont le contributeur remarquable de ce mois-ci.

## Contributeur remarquable du mois {#this-months-notable-contributor}

Tout le monde peut [nommer des contributeurs de la communauté GitLab](https://gitlab.com/gitlab-org/developer-relations/contributor-success/team-task/-/issues/490) ! Montrez votre soutien à nos candidats actifs ou ajoutez une nouvelle nomination ! 🙌

Dans le cadre du programme Co-Create, [Océane Legrand](https://gitlab.com/oceane_scania) a dirigé les efforts visant à améliorer l'ensemble des fonctionnalités du registre de paquets Conan, en collaboration avec Juan Pablo Gonzalez. Leur travail s'est concentré sur la préparation de la fonctionnalité pour la disponibilité générale, tout en mettant en œuvre la prise en charge de Conan version 2. Cette collaboration illustre la façon dont le programme Co-Create peut favoriser des améliorations significatives des capacités du registre de paquets de GitLab.

Leur nomination a été faite par [Raimund Hook](https://gitlab.com/stingrayza), Senior Fullstack Engineer, Contributor Success chez GitLab, qui a mis en avant leur collaboration persistante et leur itération continue sur les fonctionnalités du registre de paquets Conan. Leur travail illustre les valeurs de GitLab et bénéficiera à tous les utilisateurs et toutes les utilisatrices de Conan sur la plateforme.

Océane Legrand est développeuse Full Stack chez Scania, où elle travaille à la maintenance de leur instance GitLab auto-hébergée sur AWS. « Le travail que je fais en open source a un impact à la fois sur GitLab et sur Scania », déclare Océane. « Contribuer via le programme Co-Create m'a permis d'acquérir de nouvelles compétences, comme l'expérience avec Ruby et les migrations en arrière-plan. Quand mon équipe chez Scania a rencontré un problème lors d'une mise à niveau, j'ai pu aider à le résoudre parce que je l'avais déjà rencontré dans le cadre du programme. »

[En savoir plus sur le programme Co-Create de GitLab](https://about.gitlab.com/community/co-create/) dans lequel les clients et clientes travaillent directement avec nos équipes produit et ingénierie pour développer de nouvelles fonctionnalités et améliorer les fonctionnalités existantes.

## Fonctionnalités principales {#primary-features}

### Renforcer la sécurité grâce aux dépôts de conteneurs protégés {#enhance-security-with-protected-container-repositories}

<!-- categories: Container Registry -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed
- Liens : [Documentation](../../user/packages/container_registry/container_repository_protection_rules.md) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/480385)

{{< /details >}}

Nous sommes ravis d'annoncer le déploiement des dépôts de conteneurs protégés, une nouvelle fonctionnalité du registre de conteneurs de GitLab qui répond aux défis de sécurité et de contrôle liés à la gestion des images de conteneurs. Les organisations peinent souvent à gérer les accès non autorisés à des dépôts de conteneurs sensibles, les modifications accidentelles, le manque de contrôle granulaire et les difficultés à maintenir la conformité. Cette solution offre une sécurité renforcée grâce à des contrôles d'accès stricts, des permissions granulaires pour les opérations de push, pull et de gestion, ainsi qu'une intégration fluide avec les pipelines CI/CD de GitLab.

Les dépôts de conteneurs protégés apportent de la valeur aux utilisateurs et utilisatrices en réduisant le risque de failles de sécurité et de modifications accidentelles des ressources critiques. Cette fonctionnalité rationalise les workflows en maintenant la sécurité sans sacrifier la vitesse de développement, améliore la gouvernance globale du registre de conteneurs et offre la tranquillité d'esprit de savoir que les ressources de conteneurs importantes sont protégées conformément aux besoins organisationnels.

Cette fonctionnalité et la fonctionnalité [paquets protégés](https://gitlab.com/groups/gitlab-org/-/epics/5574) sont toutes deux des contributions communautaires de `gerardo-navarro` et de l'équipe Siemens. Merci à Gerardo et au reste de l'équipe de Siemens pour leurs nombreuses contributions à GitLab ! Si vous souhaitez en savoir plus sur la façon dont Gerardo et l'équipe Siemens ont contribué à ce changement, regardez cette [vidéo](https://www.youtube.com/watch?v=5-nQ1_Mi7zg) dans laquelle Gerardo partage ses apprentissages et ses bonnes pratiques pour contribuer à GitLab, basés sur son expérience en tant que contributeur externe.

### Lister les déploiements liés à une release {#list-the-deployments-related-to-a-release}

<!-- categories: Environment Management, Deployment Management -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/project/releases/_index.md) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/501169)

{{< /details >}}

Bien que GitLab ait longtemps pris en charge la création de releases à partir de tags Git et le suivi des déploiements, ces informations se trouvaient auparavant dans plusieurs endroits distincts, difficiles à assembler. Désormais, vous pouvez voir tous les déploiements liés à une release directement sur la page de release. Les gestionnaires de release peuvent rapidement vérifier où une release a été déployée et quels environnements sont en attente de déploiement. Cela complète l'intégration existante de la page de déploiement qui affiche les notes de release pour les déploiements taggés.

Nous souhaitons exprimer notre gratitude à [Anton Kalmykov](https://gitlab.com/antonkalmykov) pour avoir contribué ces deux fonctionnalités à GitLab.

### Suivi des expériences de modèles d'apprentissage automatique en disponibilité générale {#machine-learning-model-experiments-tracking-in-ga}

<!-- categories: MLOps -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed
- Liens : [Documentation](../../user/project/ml/experiment_tracking/_index.md) \| [Epic associé](https://gitlab.com/groups/gitlab-org/-/epics/9341)

{{< /details >}}

Lors de la création de modèles d'apprentissage automatique, les data scientists expérimentent souvent avec différents paramètres, configurations et techniques d'ingénierie des features pour améliorer les performances du modèle. Assurer le suivi de toutes ces métadonnées et des artefacts associés pour que la data scientist puisse reproduire l'expérience ultérieurement n'est pas trivial. Le suivi des expériences d'apprentissage automatique leur permet d'enregistrer des paramètres, des métriques et des artefacts directement dans GitLab, facilitant l'accès ultérieur tout en conservant toutes les données expérimentales dans votre environnement GitLab. Cette fonctionnalité est désormais généralement disponible avec des affichages de données améliorés, des permissions renforcées, une intégration plus poussée avec GitLab et des corrections de bugs.

### Les runners hébergés sur Linux pour GitLab Dedicated désormais en disponibilité limitée {#hosted-runners-on-linux-for-gitlab-dedicated-now-in-limited-availability}

<!-- categories: GitLab Dedicated, GitLab Hosted Runners -->

{{< details >}}

- Édition : Gold
- Liens : [Documentation](../../administration/dedicated/hosted_runners.md) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/509142)

{{< /details >}}

Nous sommes ravis d'introduire la disponibilité limitée des runners hébergés sur Linux pour GitLab Dedicated.

La gestion de flottes de runners peut s'avérer complexe et nécessite une expérience significative pour garantir que tous les jobs CI/CD peuvent s'adapter à la demande des équipes de développement.

Les runners hébergés pour GitLab Dedicated vous permettent d'utiliser des runners entièrement gérés pour vos jobs CI/CD. Ils éliminent le besoin de maintenir votre propre infrastructure de runners et offrent la même sécurité, flexibilité et efficacité de GitLab Dedicated aux runners.

Les runners hébergés s'adaptent automatiquement à vos besoins CI/CD pour garantir des performances optimales lors des pics d'activité et pour les grands projets. La release en disponibilité limitée inclut des runners Linux de différentes tailles, allant de 2 à 32 vCPU, avec 8 à 128 Go de mémoire.

Pour demander l'accès aux runners hébergés pour GitLab Dedicated pendant la phase de disponibilité limitée, contactez votre représentant(e) GitLab.

### Grands runners hébergés M2 Pro sur macOS (version bêta) {#large-m2-pro-hosted-runners-on-macos-beta}

<!-- categories: GitLab Hosted Runners -->

{{< details >}}

- Édition : Silver, Gold
- Offre : GitLab.com
- Liens : [Documentation](../../ci/runners/hosted_runners/macos.md) \| [Epic associé](https://gitlab.com/groups/gitlab-org/ci-cd/shared-runners/-/epics/19)

{{< /details >}}

Nous apportons les performances du M2 Pro aux équipes DevOps mobiles !

Avec jusqu'à 2 fois les performances des runners M1 et 6 fois celles des runners macOS x86-64, vous pouvez accroître la vélocité de votre équipe de développement lors de la création et du déploiement d'applications.

Entièrement intégrées à GitLab CI/CD et disponibles à la demande, les équipes peuvent désormais créer, tester et déployer des applications plus rapidement pour l'écosystème Apple.

Essayez dès aujourd'hui les nouveaux runners M2 Pro en utilisant `saas-macos-large-m2pro` comme tag dans votre fichier `.gitlab-ci.yml`.

## Agentic Core {#agentic-core}

### GitLab MLOps Python Client version bêta {#gitlab-mlops-python-client-beta}

<!-- categories: MLOps -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed
- Liens : [Documentation](https://gitlab.com/gitlab-org/modelops/mlops/gitlab-mlops) \| [Ticket associé](https://gitlab.com/groups/gitlab-org/-/epics/16193)

{{< /details >}}

Les data scientists et les ingénieurs et ingénieures en apprentissage automatique travaillent principalement dans des environnements Python, mais l'intégration de leurs workflows d'apprentissage automatique avec les fonctionnalités MLOps de GitLab nécessite souvent des changements de contexte et une compréhension de la structure de l'API de GitLab. Cela peut créer des frictions dans leur processus de développement et ralentir leur capacité à suivre les expériences, gérer les artefacts de modèles et collaborer avec les membres de l'équipe.

Le nouveau client Python GitLab MLOps fournit une interface fluide et pythonique aux fonctionnalités MLOps de GitLab. Les data scientists peuvent désormais interagir avec les capacités de [suivi des expériences](../../user/project/ml/experiment_tracking/_index.md) et de [registre de modèles](../../user/project/ml/model_registry/_index.md) de GitLab directement depuis leurs scripts et notebooks Python. Le client inclut :

- **GitLab Experiment Tracking** : suivez facilement les expériences d'apprentissage automatique dans GitLab.
- **Model Registry Integration** : enregistrez et gérez les modèles dans le registre de modèles de GitLab.
- **Experiment Management** : créez et gérez des expériences directement depuis le client.
- **Run Tracking** : initiez et surveillez les exécutions d'entraînement en toute simplicité.

Cette intégration permet aux data scientists de se concentrer sur le développement de modèles tout en capturant automatiquement leurs métadonnées du cycle de vie ML dans GitLab. Le client Python s'intègre parfaitement aux workflows ML existants et nécessite une configuration minimale, rendant les fonctionnalités MLOps de GitLab plus accessibles à la communauté data science.

Nous invitons la communauté Python et data science au sens large à contribuer et à partager leurs retours directement dans le [dépôt de notre projet](https://gitlab.com/gitlab-org/modelops/mlops/gitlab-mlops)

## Mise à l'échelle et déploiements {#scale-and-deployments}

### Afficher les sous-groupes et projets en attente de suppression {#view-subgroups-and-projects-pending-deletion}

<!-- categories: Groups & Projects -->

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/group/_index.md#view-inactive-groups) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/457718)

{{< /details >}}

Lorsque vous marquez un groupe pour suppression, vous avez besoin d'une visibilité sur tous les sous-groupes et projets affectés. Auparavant, seul le groupe marqué pour suppression affichait un label « En attente de suppression », mais pas ses sous-groupes et projets, ce qui rendait difficile l'identification du contenu planifié pour la suppression.

Désormais, lorsqu'un groupe est marqué pour suppression, tous ses sous-groupes et projets afficheront un label « En attente de suppression ». Cette visibilité améliorée vous aide à distinguer rapidement le contenu actif du contenu sur le point d'être supprimé dans l'ensemble de votre hiérarchie de groupes.

### Suivre plusieurs éléments de la liste de tâches dans un ticket ou une merge request {#track-multiple-to-do-items-in-an-issue-or-merge-request}

<!-- categories: Notifications -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/todos.md#actions-that-create-to-do-items) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/28355)

{{< /details >}}

Vous pouvez désormais suivre plusieurs discussions et mentions au sein d'un seul ticket ou d'une seule merge request. Avec la nouvelle fonctionnalité d'éléments de la liste de tâches multiples, vous recevrez des éléments de la liste de tâches distincts pour chaque mention ou action, vous permettant de ne manquer aucune mise à jour importante ni aucune demande nécessitant votre attention. Cette amélioration vous aide à gérer votre travail plus efficacement et à répondre aux besoins de votre équipe de manière plus efficiente.

### La protection de la création de projets pour les groupes inclut désormais les Owners {#project-creation-protection-for-groups-now-includes-owners}

<!-- categories: Groups & Projects -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/group/_index.md#specify-who-can-add-projects-to-a-group) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/354355)

{{< /details >}}

La création de projets peut être restreinte à des rôles spécifiques dans un groupe à l'aide du paramètre **Allowed to create projects**. Le rôle Owner est désormais disponible comme option, vous permettant de restreindre la création de nouveaux projets aux utilisateurs et utilisatrices ayant le rôle Owner pour le groupe. Ce rôle n'était auparavant pas disponible dans les options de sélection.

Merci à [@yasuk](https://gitlab.com/yasuk) pour cette contribution communautaire !

## DevOps et sécurité unifiés {#unified-devops-and-security}

### La détection des secrets inclut désormais des étapes de remédiation {#secret-detection-now-includes-remediation-steps}

<!-- categories: Secret Detection -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/application_security/secret_detection/_index.md) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/505757)

{{< /details >}}

Il est important de corriger rapidement les secrets exposés pour minimiser le risque que des attaquants utilisent des identifiants exposés pour s'introduire dans vos systèmes. Une remédiation appropriée nécessite plusieurs étapes au-delà de la simple suppression du secret, comme la rotation des identifiants et l'investigation des accès non autorisés potentiels. Pour vous aider à maintenir la sécurité de vos systèmes, la détection des secrets inclut désormais des étapes de remédiation spécifiques pour chaque type de secret détecté. Ces conseils vous aident à traiter systématiquement les expositions et à réduire le risque de failles de sécurité. Les étapes de remédiation apparaîtront sur toutes les vulnérabilités à l'issue d'un pipeline.

### Trouver le commit qui a résolu une vulnérabilité {#find-the-commit-that-resolved-a-vulnerability}

<!-- categories: Vulnerability Management -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/application_security/vulnerabilities/_index.md#vulnerability-resolution) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/372799)

{{< /details >}}

Auparavant, lorsqu'une vulnérabilité n'était plus détectée, nous ne fournissions pas aux utilisateurs et utilisatrices un moyen de voir quand ou où elle avait été résolue. Désormais, nous affichons un lien vers le SHA du commit où la vulnérabilité a été résolue, offrant une meilleure traçabilité et une meilleure compréhension du processus de résolution. Cela facilite la collaboration entre les équipes de sécurité et de développement et leur permet de gérer les vulnérabilités plus efficacement.

### Utiliser des rôles pour définir des membres de projet en tant que propriétaires du code {#use-roles-to-define-project-members-as-code-owners}

<!-- categories: Source Code Management -->

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/project/codeowners/reference.md#add-a-role-as-a-code-owner) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/282438)

{{< /details >}}

Vous pouvez désormais utiliser des rôles en tant que propriétaires du code dans votre fichier `CODEOWNERS` pour gérer plus efficacement les expertises et les approbations basées sur les rôles. Au lieu de lister des utilisateurs et utilisatrices individuels ou de créer des groupes, vous pouvez utiliser la syntaxe suivante :

- `@@developers` - Référence tous les utilisateurs et utilisatrices ayant le rôle Developer.
- `@@maintainers` - Référence tous les utilisateurs et utilisatrices ayant le rôle Maintainer.
- `@@owners` - Référence tous les utilisateurs et utilisatrices ayant le rôle Owner.

Par exemple, ajoutez `* @@maintainers` pour exiger l'approbation de n'importe quel mainteneur pour toutes les modifications dans le dépôt.

Cela simplifie la gestion des propriétaires du code lorsque les membres de l'équipe rejoignent le projet, le quittent ou changent de rôle. Le fichier `CODEOWNERS` reste à jour sans mises à jour manuelles, car GitLab inclut automatiquement tous les utilisateurs et utilisatrices ayant le rôle spécifié.

### Afficher les réconciliations Flux en pause sur le tableau de bord pour Kubernetes {#view-paused-flux-reconciliations-on-the-dashboard-for-kubernetes}

<!-- categories: Deployment Management -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../ci/environments/kubernetes_dashboard.md) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/501339)

{{< /details >}}

Auparavant, lorsque vous suspendiez la réconciliation Flux depuis le tableau de bord pour Kubernetes, il n'y avait aucun indicateur clair de l'état suspendu. Nous avons ajouté un nouveau statut « En pause » à l'ensemble des indicateurs de statut existants, indiquant clairement quand la réconciliation Flux est suspendue et offrant une meilleure visibilité sur l'état de vos déploiements.

### Rechercher des pods sur le tableau de bord pour Kubernetes {#search-for-pods-on-the-dashboard-for-kubernetes}

<!-- categories: Environment Management, Deployment Management -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../ci/environments/kubernetes_dashboard.md) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/508010)

{{< /details >}}

Sur le tableau de bord pour Kubernetes, trouver des pods spécifiques dans des déploiements de grande envergure peut prendre du temps. Une nouvelle barre de recherche vous permet de filtrer rapidement les pods par nom. La recherche fonctionne sur tous les pods disponibles et vous pouvez la combiner avec des filtres de statut pour trouver exactement les pods que vous devez surveiller ou dépanner.

### Prendre en charge plusieurs actions d'approbation distinctes dans les politiques d'approbation des merge requests {#support-multiple-distinct-approval-actions-in-merge-request-approval-policies}

<!-- categories: Security Policy Management -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/application_security/policies/merge_request_approval_policies.md) \| [Epic associé](https://gitlab.com/groups/gitlab-org/-/epics/12319)

{{< /details >}}

Auparavant, les politiques d'approbation des merge requests ne prenaient en charge qu'une seule règle d'approbation par politique, permettant un seul ensemble d'approbateurs avec une condition « OU ». Par conséquent, il était plus difficile d'imposer des approbations de sécurité en couches provenant de rôles variés, d'approbateurs individuels ou de groupes distincts.

Avec cette mise à jour, vous pouvez créer jusqu'à cinq règles d'approbation pour chaque politique d'approbation des merge requests, permettant des politiques d'approbation plus flexibles et plus robustes. Chaque règle peut spécifier différents approbateurs ou rôles, et chaque règle est évaluée indépendamment. Par exemple, les équipes de sécurité peuvent définir des workflows d'approbation complexes, tels que l'exigence d'un approbateur du Groupe A et d'un approbateur du Groupe B, ou d'un approbateur d'un rôle spécifique et d'un autre d'un groupe spécifié, garantissant la conformité et un contrôle renforcé dans les workflows sensibles.

Voici des exemples d'utilisation de cette amélioration :

- **Distinct role approvals:** Une approbation d'un rôle Developer et une autre d'un rôle Maintainer.
- **Role and group approvals** : une approbation d'un Developer ou d'un Maintainer et une approbation distincte d'un membre du groupe Security.
- **Distinct group approvals:** Une approbation d'un membre du groupe Python Experts et une autre approbation distincte d'un membre du groupe Security.

### Redirection vers le domaine principal pour GitLab Pages {#primary-domain-redirect-for-gitlab-pages}

<!-- categories: Pages -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/project/pages/_index.md#primary-domain)

{{< /details >}}

Vous pouvez désormais définir un domaine principal dans GitLab Pages pour rediriger automatiquement toutes les requêtes des domaines personnalisés vers votre domaine principal. Cela permet de maintenir le classement SEO et d'offrir une expérience de marque cohérente en dirigeant les visiteurs et visiteuses vers votre domaine préféré, quel que soit l'URL qu'ils utilisent initialement pour accéder à votre site.

### Protégez vos dépendances avec des paquets protégés {#safeguard-your-dependencies-with-protected-packages}

<!-- categories: Package Registry -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/packages/package_registry/package_protection_rules.md) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/323971)

{{< /details >}}

Nous sommes ravis d'introduire la prise en charge des paquets PyPI protégés, une nouvelle fonctionnalité conçue pour améliorer la sécurité et la stabilité de votre registre de paquets GitLab. Dans le monde du développement logiciel en constante évolution, la modification ou la suppression accidentelle de paquets peut perturber l'ensemble des processus de développement. Les paquets protégés résolvent ce problème en vous permettant de protéger vos dépendances les plus importantes contre des modifications involontaires.

À partir de GitLab 17.8, vous pouvez protéger les paquets PyPI en créant des règles de protection. Si un paquet correspond à une règle de protection, seuls les utilisateurs et utilisatrices spécifiés peuvent mettre à jour ou supprimer le paquet. Avec cette fonctionnalité, vous pouvez prévenir les modifications accidentelles, améliorer la conformité aux exigences réglementaires et rationaliser vos workflows en réduisant le besoin de supervision manuelle.

### Couleurs personnalisables pour les epics {#customizable-colors-for-epics}

<!-- categories: Portfolio Management -->

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/group/epics/manage_epics.md#epic-color) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/509924)

{{< /details >}}

Vous bénéficiez désormais de plus de flexibilité pour catégoriser vos epics grâce à un ensemble élargi d'options de couleurs, incluant des valeurs préexistantes et des codes RGB ou hexadécimaux personnalisés. Cette personnalisation visuelle améliorée vous permet d'associer facilement les epics à des squads, des initiatives d'entreprise ou des niveaux hiérarchiques, simplifiant ainsi la priorisation et l'organisation de votre travail sur les roadmaps et les tableaux d'epics.

Votre administrateur ou administratrice doit activer [le nouveau look pour les epics](../../user/group/epics/_index.md#epics-as-work-items).

### Ancêtres d'epic {#epic-ancestors}

<!-- categories: Portfolio Management -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/group/epics/_index.md#relationships-between-epics-and-other-items) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/509920)

{{< /details >}}

La navigation dans votre [hiérarchie d'epics](../../user/group/epics/_index.md#relationships-between-epics-and-other-items) est désormais plus facile grâce au widget Ancestry repensé, maintenant affiché en évidence en haut de chaque epic dans un format de type fil d'Ariane. Vous pouvez rapidement saisir les relations entre les epics en voyant à la fois les parents immédiats et ultimes d'un coup d'œil, vous aidant à maintenir une vue d'ensemble claire de la structure de votre projet et à naviguer facilement entre les epics associés.

Votre administrateur ou administratrice doit activer [le nouveau look pour les epics](../../user/group/epics/_index.md#epics-as-work-items).

### Statut de santé d'un epic {#epic-health-status}

<!-- categories: Portfolio Management -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/group/epics/manage_epics.md#health-status) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/509922)

{{< /details >}}

Vous pouvez désormais communiquer facilement l'avancement de vos projets grâce à la nouvelle fonctionnalité de statut de santé pour les epics. En définissant le statut sur « On track », « Needs attention » ou « At risk », vous disposerez d'un indicateur visuel rapide de la santé de votre epic, vous permettant de gérer les risques et de tenir les parties prenantes informées du statut général du projet.

Votre administrateur ou administratrice doit activer [le nouveau look pour les epics](../../user/group/epics/_index.md#epics-as-work-items).

### Parent d'un epic {#epic-parent}

<!-- categories: Portfolio Management -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/group/epics/_index.md#relationships-between-epics-and-other-items) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/509923)

{{< /details >}}

Vous pouvez désormais gérer facilement votre hiérarchie d'epics en ajoutant un parent directement depuis un epic, comme vous le feriez pour un ticket. Ce processus rationalisé vous offre plus de flexibilité dans l'organisation de votre travail, vous permettant d'établir rapidement des relations entre les epics et de maintenir une structure claire pour vos projets.

Votre administrateur ou administratrice doit activer [le nouveau look pour les epics](../../user/group/epics/_index.md#epics-as-work-items).

### Suivre le temps passé sur les epics {#track-time-spent-on-epics}

<!-- categories: Portfolio Management -->

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/project/time_tracking.md) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/509930)

{{< /details >}}

Vous pouvez désormais suivre le temps directement dans les epics, vous offrant un contrôle plus granulaire sur la gestion du temps de votre projet. Cette nouvelle fonctionnalité vous permet d'enregistrer le temps passé sur différents aspects de votre projet, vous aidant à surveiller l'avancement, à respecter les délais et à maîtriser votre budget au fil des sprints et des jalons.

### Afficher le champ d'itération sur les éléments enfants dans les epics, les tickets et les objectifs {#show-iteration-field-on-child-items-in-epics-issues-and-objectives}

<!-- categories: Portfolio Management -->

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/group/iterations/_index.md) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/510005)

{{< /details >}}

Lors de la consultation du détail d'un epic, les planificateurs et planificatrices doivent pouvoir voir quels tickets enfants sont planifiés dans des itérations (sprints) et lesquels ne sont pas encore planifiés. Cela permettra aux équipes de s'assurer plus facilement que tout le travail défini est intégré dans des sprints.

Pour les epics, votre administrateur ou administratrice doit activer [le nouveau look pour les epics](../../user/group/epics/_index.md#epics-as-work-items).

### Webhooks pour les epics {#webhooks-for-epics}

<!-- categories: Portfolio Management -->

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/project/integrations/webhook_events.md) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/509928)

{{< /details >}}

Boostez l'automatisation de vos workflows avec les webhooks d'epics, vous permettant de recevoir des mises à jour en temps réel dans vos outils préférés chaque fois que des modifications surviennent dans vos epics. En intégrant GitLab à vos autres services, vous pouvez améliorer la collaboration, rester au courant des développements du projet et rationaliser vos processus sans passer constamment d'une application à l'autre.

Votre administrateur ou administratrice doit activer [le nouveau look pour les epics](../../user/group/epics/_index.md#epics-as-work-items).

### Ajouter les vulnérabilités comme événements webhook pris en charge {#add-vulnerabilities-as-supported-webhook-events}

<!-- categories: Notifications, Vulnerability Management -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/project/integrations/webhook_events.md#vulnerability-events) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/366770)

{{< /details >}}

Découvrez une intégration webhook qui génère des événements pour les actions liées aux vulnérabilités, vous permettant d'automatiser et d'intégrer des ressources externes. Par exemple, des événements sont générés lorsque des vulnérabilités sont créées ou lorsque le statut d'une vulnérabilité change.

### Appliquer des règles de workflow centralisées pour la stratégie `override_ci` {#enforce-centralized-workflow-rules-for-the-override_ci-strategy}

<!-- categories: Security Policy Management -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/application_security/policies/pipeline_execution_policies.md#override_project_ci) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/512123)

{{< /details >}}

Dans les politiques d'exécution de pipeline, la stratégie `override_ci` prend désormais en charge l'utilisation de règles de workflow pour faciliter l'application des politiques aux jobs définis dans la politique, ainsi qu'aux jobs définis dans la configuration du projet lors de l'utilisation de `include:project`. En définissant des règles de workflow dans la politique, vous pouvez filtrer les jobs exécutés par la politique d'exécution de pipeline en fonction de règles particulières, par exemple en configurant des règles qui empêchent l'utilisation de pipelines de branche dans les projets.

Pour isoler l'utilisation des règles de workflow afin de cibler uniquement les jobs définis dans votre politique, la bonne pratique consiste à définir les règles pour le job plutôt que de manière globale dans la politique. Vous pouvez également regrouper les jobs et les règles à l'aide d'un champ `include` distinct.

Auparavant, lors de l'utilisation de la stratégie `override_ci`, les règles de workflow ne pouvaient être appliquées qu'aux jobs définis dans la politique d'exécution de pipeline.

La stratégie `inject_ci` reste inchangée et les règles de workflow ne peuvent être utilisées que pour contrôler quand les jobs de politique sont appliqués, sans affecter les règles de workflow du projet.

### Rendre `skip_ci` configurable pour les politiques d'exécution de pipeline {#make-skip_ci-configurable-for-pipeline-execution-policies}

<!-- categories: Security Policy Management -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/application_security/policies/pipeline_execution_policies.md#skip_ci-type) \| [Epic associé](https://gitlab.com/groups/gitlab-org/-/epics/15647)

{{< /details >}}

Nous avons introduit une nouvelle option de configuration pour les politiques d'exécution de pipeline (PEP) qui permet plus de flexibilité dans la gestion de la directive `[skip ci]`. Cette fonctionnalité répond aux scénarios où certains processus automatisés, tels que les releases sémantiques, nécessitent de contourner l'exécution du pipeline tout en s'assurant que les vérifications critiques de sécurité et de conformité sont effectuées.

Pour utiliser cette fonctionnalité, définissez `skip_ci` sur `allowed: false` dans la configuration YAML de la politique d'exécution de pipeline ou activez **Empêcher les utilisateurs et utilisatrices d'ignorer des pipelines** dans l'éditeur de politique. Ensuite, spécifiez les utilisateurs et utilisatrices ou comptes de service autorisés à utiliser `[skip ci]`. Par défaut, tous les utilisateurs et toutes les utilisatrices seront bloqués pour ignorer les jobs d'exécution de pipeline, sauf s'ils sont exclus dans la configuration `skip_ci` en tant qu'exception.

### Gérer la simultanéité des pipelines d'exécution de scans planifiés {#manage-concurrency-of-scheduled-scan-execution-pipelines}

<!-- categories: Security Policy Management -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/application_security/policies/scan_execution_policies.md#concurrency-control) \| [Epic associé](https://gitlab.com/groups/gitlab-org/-/epics/13997)

{{< /details >}}

Pour améliorer la scalabilité des politiques d'exécution de scan planifiées globales, nous avons introduit une nouvelle capacité à configurer une fenêtre temporelle dans une politique d'exécution de scan. La propriété `time_window` définit la période de temps dans laquelle la politique crée et exécute de nouvelles planifications pour garantir des performances optimales.

Pour utiliser la nouvelle propriété, mettez à jour votre politique en mode YAML et suivez le [schéma `time_window`](../../user/application_security/policies/scan_execution_policies.md#time_window-schema). Vous pouvez fournir une valeur en secondes pour la fenêtre de temps dans laquelle les planifications doivent s'exécuter. Par exemple, `86400` pour une fenêtre de temps de 24 heures. Ensuite, fournissez le champ et la valeur `distribution: random` pour forcer les planifications à s'exécuter à des moments aléatoires dans la fenêtre de temps définie.

### Amélioration des performances de l'interface utilisateur pour l'onglet de rapport « Cadres » dans le centre de conformité {#scaling-ui-performance-for-the-frameworks-report-tab-in-the-compliance-center}

<!-- categories: Compliance Management -->

{{< details >}}

- Édition : Ultimate, Premium
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/compliance/compliance_center/compliance_frameworks_report.md) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/477394)

{{< /details >}}

Avec GitLab 17.8, nous avons apporté des modifications au backend pour garantir que le centre de conformité reste rapide et réactif, même si vous avez des milliers de cadres de conformité dans l'onglet de rapport **Cadres** du centre de conformité.

De plus, lorsque vous cherchez plus d'informations et cliquez sur un cadre dans l'onglet **Cadres**, GitLab renvoie jusqu'à 1 000 projets associés à ce cadre particulier dans le menu contextuel du côté droit.

### Limites de pipeline disponibles dans GitLab Community Edition {#pipeline-limits-available-in-gitlab-community-edition}

<!-- categories: Continuous Integration (CI) -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed
- Liens : [Documentation](../../administration/cicd/limits.md#maximum-number-of-jobs-in-a-pipeline) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/287669)

{{< /details >}}

Les administrateurs et administratrices peuvent désormais contrôler l'utilisation des ressources de pipeline en définissant des limites CI/CD pour leurs installations GitLab Community Edition. Auparavant, cette fonctionnalité n'était disponible que dans GitLab Enterprise Edition.

## Sujets connexes {#related-topics}

- [Correctifs de bugs](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=type%3A%3Abug&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=17.8)
- [Améliorations des performances](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=bug%3A%3Aperformance&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=17.8)
- [Améliorations de l'interface utilisateur](https://papercuts.gitlab.com/?milestone=17.8)
- [Dépréciations et suppressions](../../update/deprecations.md)
- [Notes de mise à niveau](../../update/versions/_index.md)
