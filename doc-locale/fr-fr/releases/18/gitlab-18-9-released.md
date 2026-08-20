---
stage: Release Notes
group: Monthly Release
date: 2026-02-19
title: "Notes de release de GitLab 18.9"
description: "GitLab 18.9 est disponible avec les modèles Self-Hosted de GitLab Duo Agent Platform désormais disponibles pour les licences cloud"
---

<!-- markdownlint-disable -->
<!-- vale off -->

Le 19 février 2026, GitLab 18.9 a été publié avec les fonctionnalités suivantes.

Nous souhaitons également remercier tous nos contributeurs, dont le contributeur remarquable de ce mois-ci.

## Contributeur notable du mois : Pooja Ghanghas {#this-months-notable-contributor-pooja-ghanghas}

Pooja a apporté des contributions significatives aux efforts continus de GitLab visant à migrer les composants déroulants hérités vers notre architecture déroulante moderne. Ces migrations requièrent une attention minutieuse aux détails ainsi qu'une compréhension des anciens et des nouveaux systèmes de composants. Pooja a régulièrement fourni un travail de haute qualité dans le cadre de plusieurs migrations, notamment des mises à jour du [diff file header](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/189621), du [code block bubble menu](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/194129), du [oncall schedules rotation assignee component](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/186247), et du [new resource dropdown](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/209598).

[Peter Hegman](https://gitlab.com/peterhegman), Staff Frontend Engineer au sein de l'équipe Tenant Scale::Organizations chez GitLab, a nominé Pooja pour cette distinction, en précisant : « Ces migrations peuvent être assez complexes et elle en a réalisé un grand nombre. Merci pour vos contributions ! »

Au-delà de ces efforts de migration, Pooja a également contribué au développement de fonctionnalités, notamment [l'ajout de statuts aux jalons et aux itérations](https://gitlab.com/gitlab-org/gitlab/-/issues/524100), une fonctionnalité dans laquelle elle a investi des efforts considérables pour la faire fusionner. [Marc Saleiko](https://gitlab.com/msaleiko), Staff Fullstack Engineer au sein de l'équipe Plan:Project Management chez GitLab, a salué son travail : « Il s'agit d'une contribution précieuse et vous avez fait un excellent travail en livrant cette fonctionnalité ! » En réfléchissant à son expérience, Pooja a partagé : « Je suis fière du résultat obtenu et ce fut une excellente expérience d'apprentissage pour moi. »

Elle a également contribué à de nombreuses corrections de bugs et améliorations de maintenance dans l'ensemble de la base de code GitLab. Le travail de Pooja améliore directement la maintenabilité et la cohérence de l'interface utilisateur de GitLab, facilitant ainsi la tâche des contributeurs et des membres de l'équipe pour créer et maintenir des fonctionnalités, et contribuant à faire avancer l'architecture frontend de GitLab.

Merci, Pooja, pour vos contributions continues à l'amélioration de la base de code GitLab et pour être un membre aussi fiable de notre communauté de contributeurs !

Vous souhaitez en savoir plus sur les contributions de Pooja ? Consultez son [profil GitLab](https://gitlab.com/poojaghanghas479).

## Fonctionnalités principales {#primary-features}

### Les modèles Self-Hosted de GitLab Duo Agent Platform sont désormais disponibles pour les licences cloud {#gitlab-duo-agent-platform-self-hosted-models-now-available-for-cloud-licenses}

<!-- categories: Self-Hosted Models -->

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed
- Liens : [Documentation](../../administration/gitlab_duo_self_hosted/_index.md#gitLab-duo-agent-platform) \| [Epic associé](https://gitlab.com/groups/gitlab-org/-/work_items/20949)

{{< /details >}}

GitLab Duo Agent Platform est désormais généralement disponible pour les clients GitLab Self-Managed disposant d'une licence cloud. La facturation de cette fonctionnalité est [basée sur l'utilisation](../../subscriptions/gitlab_credits.md).

Les administrateurs peuvent configurer des [modèles compatibles](../../administration/gitlab_duo_self_hosted/supported_models_and_hardware_requirements.md#compatible-models) pour une utilisation avec GitLab Duo Agent Platform. Les administrateurs utilisant AWS Bedrock ou Azure OpenAI peuvent également configurer des modèles Anthropic Claude ou OpenAI GPT.

Pas encore sur GitLab Ultimate ? [Démarrez un essai gratuit avec Duo Agent Platform inclus](https://docs.gitlab.com/#gitlab-duo-agent-platform-available-in-ultimate-trials).

### Résolution des vulnérabilités avec GitLab Duo Agent Platform (version bêta) {#vulnerability-resolution-with-gitlab-duo-agent-platform-beta}

<!-- categories: Vulnerability Management -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- Liens : [Documentation](../../user/duo_agent_platform/flows/foundational_flows/agentic_sast_vulnerability_resolution.md) \| [Epic associé](https://gitlab.com/groups/gitlab-org/-/work_items/20150)

{{< /details >}}

Le triage et la remédiation des vulnérabilités SAST sont l'une des tâches les plus chronophages en matière de sécurité des applications. Après avoir identifié une vulnérabilité réelle, les développeurs doivent comprendre le résultat, localiser le code affecté et rédiger un correctif approprié. Tout cela demande du temps et des connaissances spécialisées. Dans GitLab 18.9, nous introduisons la résolution agentique des vulnérabilités SAST. Lorsque vous déclenchez la résolution d'une vulnérabilité SAST, GitLab Duo analyse de manière autonome le résultat, raisonne à travers le contexte du code environnant, génère un correctif tenant compte du contexte et crée une merge request sans aucune intervention manuelle.

Les principales fonctionnalités incluent :

- Résolution agentique multi-étapes : plutôt que de produire une seule suggestion de code, GitLab Duo Agent Platform raisonne à travers la vulnérabilité, évalue la base de code et produit un correctif bien documenté.
- Création automatique de merge request : génère une merge request prête à être examinée avec le correctif de code proposé pour les vulnérabilités SAST de gravité critique et élevée.
- Score de qualité : chaque correctif généré inclut une évaluation de la qualité afin que les relecteurs puissent rapidement évaluer le niveau de confiance dans la remédiation proposée.

La résolution des vulnérabilités SAST est disponible depuis le rapport de vulnérabilités et les pages de détails individuelles des vulnérabilités. Vous pouvez déclencher une résolution directement depuis la page de détails de la vulnérabilité individuelle.

Cette fonctionnalité est disponible en version bêta gratuite pour les clients GitLab Ultimate. Nous accueillons vos commentaires dans [le ticket 585626](https://gitlab.com/gitlab-org/gitlab/-/work_items/585626).

### Naviguer dans les dépôts avec une arborescence de fichiers réductible {#navigate-repositories-with-collapsible-file-tree}

<!-- categories: Source Code Management -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- Liens : [Documentation](../../user/project/repository/files/file_tree_browser.md) \| [Epic associé](https://gitlab.com/groups/gitlab-org/-/epics/17781)

{{< /details >}}

Vous pouvez désormais parcourir les fichiers d'un dépôt grâce à une arborescence de fichiers réductible. L'arborescence offre une vue complète de la structure de votre projet, vous permettant de développer et de réduire les répertoires en ligne, de naviguer entre les fichiers dans différentes parties de votre dépôt, et de maintenir le contexte pendant votre travail.

L'arborescence de fichiers apparaît sous forme de barre latérale redimensionnable lorsque vous affichez des fichiers ou des répertoires du dépôt. Vous pouvez activer ou désactiver la visibilité à l'aide de raccourcis clavier, filtrer les fichiers par nom ou par extension, et naviguer dans des hiérarchies de projets complexes. L'arborescence se synchronise avec votre emplacement actuel : lorsque vous sélectionnez un fichier dans la zone de contenu principale, l'arborescence se met à jour pour afficher ce fichier.

La structure existante de votre dépôt et l'organisation de vos fichiers restent inchangées. Avec moins de chargements de pages nécessaires pour naviguer entre les fichiers, cette fonctionnalité s'adapte aussi bien aux petits projets qu'aux grandes bases de code comprenant des milliers de fichiers.

### Inclure des entrées CI/CD depuis un fichier {#include-cicd-inputs-from-a-file}

<!-- categories: Pipeline Composition -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- Liens : [Documentation](../../ci/inputs/_index.md#define-pipeline-inputs-in-external-files) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/415636)

{{< /details >}}

Auparavant, les entrées CI/CD de pipeline ne pouvaient être définies que directement dans la section spec d'un pipeline. Cette limitation rendait difficile la réutilisation de la configuration des entrées dans plusieurs projets.

Dans cette release, vous pouvez désormais inclure des définitions d'entrées à partir de fichiers externes en utilisant le mot-clé familier `include`. La possibilité de maintenir une liste d'entrées dans un emplacement séparé vous aide à disposer d'une solution gérable pour de nombreux projets ou pipelines. Vous pouvez maintenir des configurations d'entrées centralisées et même gérer dynamiquement les valeurs d'entrées à partir de sources externes.

### Signature de commit basée sur le Web sur GitLab.com {#web-based-commit-signing-on-gitlabcom}

<!-- categories: Source Code Management -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com
- Liens : [Documentation](../../user/project/repository/signed_commits/web_commits.md) \| [Epic associé](https://gitlab.com/groups/gitlab-org/-/work_items/17775)

{{< /details >}}

S'assurer que les commits sont signés par chiffrement est essentiel pour l'intégrité du code et le respect des exigences de conformité. Auparavant, la signature de commit basée sur le Web n'était disponible que pour GitLab Self-Managed.

GitLab.com prend désormais en charge la signature de commit basée sur le Web. Lorsqu'elle est activée pour un groupe ou un projet, les commits créés via l'interface Web de GitLab sont automatiquement signés avec la clé de signature GitLab et affichés avec un badge **Vérifié**, fournissant une preuve cryptographique d'authenticité pour vos dépôts.

Détails clés :

- Activez la fonctionnalité dans les paramètres du groupe ou du projet selon vos besoins.
- Tous les commits basés sur le Web (modifications dans le Web IDE, fusions, opérations via l'API) sont automatiquement signés lorsque la fonctionnalité est activée.

Cela aligne les capacités de sécurité de GitLab.com sur celles de GitLab Self-Managed et pose les bases de politiques de signature de commit complètes au sein de votre organisation.

### Registre virtuel de conteneurs désormais disponible (version bêta) {#container-virtual-registry-now-available-beta}

<!-- categories: Virtual Registry -->

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/packages/virtual_registry/container/_index.md) \| [Epic associé](https://gitlab.com/groups/gitlab-org/-/work_items/20820)

{{< /details >}}

Le développement moderne basé sur les conteneurs nécessite d'accéder aux images provenant de plusieurs registres, notamment Docker Hub, Harbor, Quay et des registres privés. Sans registre virtuel de conteneurs, les ingénieurs de plateforme doivent configurer chaque projet et chaque pipeline CI/CD pour s'authentifier auprès de plusieurs registres et en extraire des images individuellement. Cela crée une complexité de configuration, ralentit les extractions avec des requêtes séquentielles vers les registres, et rend difficile la mise en œuvre de politiques de sécurité cohérentes sur l'ensemble des sources de conteneurs.

Le registre virtuel de conteneurs répond à ces défis en agrégeant plusieurs registres de conteneurs en amont derrière un point de terminaison unique. Les ingénieurs de plateforme peuvent configurer Docker Hub, Harbor, Quay et d'autres registres avec une authentification par jeton à longue durée de vie via une seule URL. La mise en cache intelligente améliore les performances d'extraction tout en s'intégrant aux systèmes d'authentification GitLab pour un contrôle d'accès centralisé et une journalisation des audits.

L'API du registre virtuel de conteneurs est actuellement disponible en version bêta pour les clients GitLab Premium et GitLab Ultimate. Les participants à la version bêta peuvent utiliser l'[API GitLab](../../api/container_virtual_registries.md) pour créer des registres virtuels de conteneurs, configurer plusieurs sources en amont avec des configurations partageables, et extraire des images de conteneurs via le registre virtuel. Veuillez noter que la version bêta ne prend pas en charge les registres qui nécessitent une authentification IAM. La prise en charge des registres de fournisseurs cloud nécessitant une authentification IAM est suivie dans [cet epic](https://gitlab.com/groups/gitlab-org/-/work_items/20919).

Sur GitLab.com, cette fonctionnalité est protégée par un feature flag. Pour demander l'accès ou partager vos commentaires, veuillez laisser un commentaire dans le [ticket de feedback](https://gitlab.com/gitlab-org/gitlab/-/work_items/589630).

### Nouveau graphique du tableau de bord de sécurité : vulnérabilités par âge {#new-security-dashboard-chart-vulnerabilities-by-age}

<!-- categories: Vulnerability Management -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- Liens : [Documentation](../../user/application_security/security_dashboard/_index.md#vulnerabilities-by-age) \| [Epic associé](https://gitlab.com/groups/gitlab-org/-/work_items/17417)

{{< /details >}}

Le nouveau graphique **Vulnérabilités par âge** vous aide à comprendre depuis combien de temps les vulnérabilités sont ouvertes dans votre environnement.

Le graphique montre la distribution des vulnérabilités non résolues en fonction du temps écoulé depuis leur première détection. Vous pouvez regrouper les vulnérabilités par gravité ou par type de rapport, ce qui vous aide à identifier les domaines où des activités de remédiation peuvent être nécessaires.

## Agentic Core {#agentic-core}

### Prise en charge d'OAuth dans les IDE JetBrains pour Self-Managed et Dedicated {#oauth-support-in-jetbrains-ides-for-self-managed-and-dedicated}

<!-- categories: Editor Extensions -->

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- Modules complémentaires : Duo Core, Duo Pro, Duo Enterprise
- Liens : [Documentation](https://docs.gitlab.com/editor_extensions/jetbrains_ide/setup/#authenticate-with-gitlab) \| [Ticket associé](https://gitlab.com/gitlab-org/editor-extensions/gitlab-jetbrains-plugin/-/issues/1337)

{{< /details >}}

Le plugin GitLab Duo pour les IDE JetBrains prend désormais en charge l'authentification OAuth pour GitLab Self-Managed et GitLab Dedicated. Cela signifie que tous les utilisateurs JetBrains peuvent désormais bénéficier d'une expérience de connexion plus rapide et plus sécurisée. Aucun jeton d'accès personnel requis.

## Mise à l'échelle et déploiements {#scale-and-deployments}

### Utilisateurs avec accès minimum non facturables {#non-billable-minimal-access-users}

<!-- categories: Seat Cost Management -->

{{< details >}}

- Édition : GitLab Premium
- Offre : GitLab Self-Managed
- Liens : [Documentation](../../user/permissions.md#users-with-minimal-access) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/584275)

{{< /details >}}

Auparavant, les organisations qui utilisaient des fournisseurs d'identité pour automatiser le provisionnement des utilisateurs sur GitLab Self-Managed GitLab Premium pouvaient rencontrer un problème potentiel. Lorsque les synchronisations des fournisseurs d'identité tentent d'ajouter des utilisateurs au-delà de la limite de sièges autorisés, les administrateurs doivent soit acheter des sièges supplémentaires pour des utilisateurs qui n'ont pas besoin d'un accès actif, soit intervenir manuellement pour éviter les échecs.

Désormais, les utilisateurs disposant du rôle d'accès minimum sur les abonnements GitLab Self-Managed GitLab Premium ne comptent plus comme des sièges facturables, les alignant ainsi sur le fonctionnement de l'accès minimum sur GitLab.com Premium, GitLab.com Ultimate et GitLab Self-Managed Ultimate. Ce changement déverrouille la fonctionnalité d'[accès restreint](../../subscriptions/manage_seats.md#restricted-access), qui attribue automatiquement le rôle d'accès minimum aux utilisateurs qui dépasseraient autrement la limite de sièges lors des synchronisations avec le fournisseur d'identité. Ce changement permet aux synchronisations de s'exécuter sans problème, sans dépassements de facturation inattendus ni intervention manuelle.

### Vue de gestion des données Geo sur le site principal {#geo-data-management-view-on-primary-site}

<!-- categories: Disaster Recovery, Geo Replication -->

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed, GitLab Dedicated
- Liens : [Documentation](../../administration/admin_area.md#data-management)

{{< /details >}}

Vous pouvez désormais résoudre les problèmes et vérifier l'intégrité des données directement depuis le site principal, grâce à la nouvelle vue de gestion des données qui apporte des informations détaillées sur le statut de vérification au site Geo principal. Cette amélioration élimine la nécessité d'accéder aux sites secondaires pour les tâches de vérification et de résolution de problèmes de base.

Auparavant, ce statut de vérification n'était accessible que via l'interface utilisateur du site secondaire. Désormais, avec la vue de gestion des données sur le site principal, vous pouvez :

- Afficher le statut de vérification détaillé pour tous les types de données réplicables sur le site principal
- Effectuer des tâches de nettoyage des données et de résolution de problèmes directement depuis l'interface principale
- Configurer et vérifier votre configuration Geo sur le site principal avant d'ajouter des sites secondaires

Cette amélioration est la première étape vers une résolution de problèmes en libre-service complète via l'interface utilisateur, réduisant la nécessité d'accéder à plusieurs sites pour la maintenance de routine et la résolution de problèmes.

### GitLab Duo Agent Platform disponible dans les essais Ultimate {#gitlab-duo-agent-platform-available-in-ultimate-trials}

<!-- categories: Acquisition, Duo Agent Platform -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../subscriptions/free_trials.md#gitlab-duo-agent-platform-trials) \| [Epic associé](https://gitlab.com/groups/gitlab-org/-/work_items/20353)

{{< /details >}}

Les équipes qui évaluent GitLab peuvent désormais tester les capacités d'IA agentique qui automatisent des workflows de développement complexes et réduisent les tâches manuelles. Inscrivez-vous à un essai de GitLab Ultimate et accédez à Duo Agent Platform avec 24 crédits d'évaluation par utilisateur, permettant une expérience pratique de l'exécution autonome de tâches et de l'orchestration de workflows multi-étapes pendant une évaluation de 30 jours. Les crédits d'évaluation sont disponibles pendant 30 jours à compter de la date de provisionnement, aussi envisagez la disponibilité de votre équipe avant de commencer.

[Démarrez votre essai gratuit](https://gitlab.com/-/trial_registrations/new). Les clients payants actuels peuvent accéder aux crédits d'évaluation via leur équipe de compte. [Contactez l'équipe commerciale](https://about.gitlab.com/sales/) pour en savoir plus.

### Les mises à niveau sans interruption de service sont désormais prises en charge pour les déploiements Cloud Native Hybrid {#zero-downtime-upgrades-now-supported-for-cloud-native-hybrid-deployments}

<!-- categories: Cloud Native Installation -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed
- Liens : [Documentation](https://docs.gitlab.com/charts/installation/upgrade/#upgrade-with-zero-downtime)

{{< /details >}}

Les mises à niveau sans interruption de service sont désormais officiellement prises en charge pour les déploiements Cloud Native Hybrid.

Les clients entreprise exigent que leur plateforme DevSecOps soit disponible à tout moment, ce qui fait des interruptions liées aux mises à niveau un problème opérationnel majeur. Jusqu'à présent, les mises à niveau sans interruption de service n'étaient prises en charge que pour les déploiements haute disponibilité basés sur des packages Linux, ce qui a conduit de nombreux clients à opter pour des architectures basées sur des machines virtuelles, même lorsque des déploiements Kubernetes natifs du cloud auraient mieux correspondu à leur stratégie d'infrastructure.

Nous mettons à niveau nos propres instances SaaS Cloud Native Hybrid sans interruption de service depuis des années. Avec cette release, nous apportons cette même expérience opérationnelle aux clients en mode self-managed qui exécutent GitLab sur Kubernetes.

La procédure de mise à niveau a été testée de manière exhaustive et est désormais entièrement documentée, vous donnant la confiance nécessaire pour maintenir la disponibilité lors des mises à niveau de version.

### Archiver un groupe et son contenu {#archive-a-group-and-its-content}

<!-- categories: Groups & Projects -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- Liens : [Documentation](../../user/group/manage.md#archive-a-group) \| [Epic associé](https://gitlab.com/groups/gitlab-org/-/epics/15019)

{{< /details >}}

La gestion des initiatives terminées et des projets abandonnés est désormais plus facile. Vous pouvez désormais archiver des groupes entiers, y compris tous les sous-groupes et projets, en une seule action, éliminant ainsi la nécessité d'archiver manuellement chaque projet individuellement.

Lorsque vous archivez un groupe :

- Tous les sous-groupes et projets imbriqués sont automatiquement archivés.
- Le contenu archivé est déplacé vers l'onglet **Inactif** avec des badges de statut clairs.
- Les données du groupe restent entièrement accessibles en mode lecture seule pour référence ou restauration.
- Les autorisations d'écriture sont désactivées pour le groupe archivé et son contenu.

Au-delà de la page **Paramètres**, vous pouvez archiver des groupes et des projets directement depuis le menu des actions dans les vues de liste. Plus besoin de naviguer à travers plusieurs écrans pour des tâches administratives simples. Cette fonctionnalité très demandée réduit considérablement la charge administrative tout en maintenant votre workspace organisé avec une séparation claire entre le travail actif et inactif. Partagez vos commentaires dans [l'epic 18616](https://gitlab.com/groups/gitlab-org/-/epics/18616).

### Valkey comme option de remplacement pour Redis (version bêta) {#valkey-as-replacement-option-for-redis-beta}

<!-- categories: Omnibus Package -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed
- Liens : [Documentation](../../administration/redis/_index.md#use-valkey-instead-of-redis)

{{< /details >}}

À partir de GitLab 18.9, Valkey est fourni en tant que remplacement optionnel de Redis dans le package Linux. Redis a modifié sa licence en AGPLv3, qui n'est pas adaptée aux clients open source. Pour garantir la sécurité et la maintenabilité pour nos clients GitLab Self-Managed, nous effectuons la transition de Redis vers Valkey, une duplication communautaire qui maintient la licence BSD permissive.

Calendrier de transition :

- GitLab 18.9 (cette release) : Valkey est fourni en tant que remplacement optionnel (version bêta). Vous pouvez passer de Redis à Valkey à votre convenance. La prise en charge de Valkey Sentinel est incluse.
- GitLab 19.0 (mai 2026) : Valkey devient le choix par défaut et les binaires Redis sont supprimés du package Linux. Les paramètres de configuration Redis existants restent fonctionnels et sont pris en compte pour la rétrocompatibilité.

Cette transition affecte uniquement le Redis fourni dans les packages Linux. Les clients utilisant des architectures à grande échelle avec des déploiements Redis externes peuvent continuer à utiliser Redis. Nous surveillons la divergence potentielle des fonctionnalités entre Redis et Valkey et fournirons des conseils à mesure que l'écosystème évolue.

## DevOps et sécurité unifiés {#unified-devops-and-security}

### Analyse des dépendances avec prise en charge SBOM pour les fichiers manifestes Java pom.xml {#dependency-scanning-with-sbom-support-for-java-pomxml-manifest-files}

<!-- categories: Software Composition Analysis -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- Liens : [Documentation](../../user/application_security/dependency_scanning/dependency_scanning_sbom/_index.md#manifest-fallback) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/585886)

{{< /details >}}

GitLab [analyse des dépendances via SBOM](../../user/application_security/dependency_scanning/dependency_scanning_sbom/_index.md) prend désormais en charge l'analyse des fichiers manifestes Java `pom.xml`. Auparavant, l'analyse des dépendances pour les projets Java utilisant Maven nécessitait la présence d'un fichier de graphe. Désormais, lorsqu'un fichier de graphe n'est pas disponible, l'analyseur revient automatiquement à l'analyse des fichiers `pom.xml`, en extrayant et en signalant uniquement les dépendances directes pour l'analyse des vulnérabilités. Cette amélioration facilite l'activation de l'analyse des dépendances pour les projets Java sans nécessiter de fichier de graphe.

Pour activer le repli sur le manifeste, définissez la variable CI/CD `DS_ENABLE_MANIFEST_FALLBACK` sur `"true"`.

### Analyse des dépendances avec prise en charge SBOM pour les fichiers manifestes Python requirements.txt {#dependency-scanning-with-sbom-support-for-python-requirementstxt-manifest-files}

<!-- categories: Software Composition Analysis -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- Liens : [Documentation](../../user/application_security/dependency_scanning/dependency_scanning_sbom/_index.md#manifest-fallback) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/586921)

{{< /details >}}

GitLab [analyse des dépendances via SBOM](../../user/application_security/dependency_scanning/dependency_scanning_sbom/_index.md) prend désormais en charge l'analyse des fichiers manifestes Python `requirements.txt`. Auparavant, l'analyse des dépendances pour les projets Python nécessitait la présence d'un fichier de verrouillage. Désormais, lorsqu'un fichier de verrouillage n'est pas disponible, l'analyseur revient automatiquement à l'analyse des fichiers `requirements.txt`, en extrayant et en signalant uniquement les dépendances directes pour l'analyse des vulnérabilités. Cette amélioration facilite l'activation de l'analyse des dépendances pour les projets Python sans nécessiter de fichier de verrouillage.

Pour activer le repli sur le manifeste, définissez la variable CI/CD `DS_ENABLE_MANIFEST_FALLBACK` sur `"true"`.

### Restreindre les extraits personnels pour les utilisateurs d'entreprise {#restrict-personal-snippets-for-enterprise-users}

<!-- categories: Source Code Management -->

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com
- Liens : [Documentation](../../user/group/manage.md#restrict-personal-snippets-for-enterprise-users)

{{< /details >}}

Les organisations utilisant GitLab.com doivent s'assurer que les utilisateurs d'entreprise n'exposent pas accidentellement du code sensible via des extraits personnels. Auparavant, il n'existait aucun moyen d'empêcher les utilisateurs de créer des extraits dans leur espace de nommage personnel, ce qui peut présenter un risque de sécurité si les extraits sont inadvertamment définis comme publics.

Les propriétaires de groupe peuvent désormais restreindre la création d'extraits personnels pour les utilisateurs d'entreprise, contribuant ainsi à un contrôle plus strict sur le lieu où le code est partagé. Lorsque la restriction est activée, les utilisateurs d'entreprise ne peuvent pas créer d'extraits dans leur espace de nommage personnel.

### Rapid Diffs améliore les performances pour les modifications de commits {#rapid-diffs-improves-performance-for-commit-changes}

<!-- categories: Source Code Management -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- Liens : [Documentation](../../user/project/repository/commits/_index.md) \| [Epic associé](https://gitlab.com/groups/gitlab-org/-/work_items/17804)

{{< /details >}}

L'examen des commits comportant de nombreux fichiers modifiés ou des modifications substantielles peut être lent. La technologie Rapid Diffs alimente désormais la page des commits (`/-/commits/<SHA>`), offrant des temps de chargement plus rapides, un défilement plus fluide et des interactions plus réactives.

Avec Rapid Diffs, vous remarquerez :

- Une expérience sans pagination.
- Un chargement initial plus rapide, pour commencer à travailler avec le code plus tôt.
- Une interface actualisée avec un nouveau navigateur de fichiers pour une navigation plus rapide entre les fichiers.
- Des interactions réactives, même avec un grand nombre de fichiers modifiés.

Toutes les fonctionnalités existantes sont préservées. À mesure que Rapid Diffs s'étend à d'autres domaines de GitLab, les mêmes avantages en termes de performances suivront.

### Prise en charge des jetons d'API Bitbucket Cloud dans l'API d'importation {#support-for-bitbucket-cloud-api-tokens-in-import-api}

<!-- categories: Importers -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- Liens : [Documentation](../../api/import.md#import-repository-from-bitbucket-cloud)

{{< /details >}}

L'API d'importation GitLab prend désormais en charge les jetons d'API Bitbucket Cloud, offrant un moyen plus sécurisé d'importer des dépôts depuis Bitbucket Cloud.

[Atlassian a déprécié les mots de passe d'application](https://www.atlassian.com/blog/bitbucket/bitbucket-cloud-transitions-to-api-tokens-enhancing-security-with-app-password-deprecation) au profit des jetons d'API, et nous prévoyons de supprimer la prise en charge des mots de passe d'application dans la version 19.0.

L'importation depuis Bitbucket Cloud via l'interface GitLab n'est pas affectée par ce changement.

### Gouvernance et configuration de sécurité centralisées {#centralized-security-governance-and-configuration}

<!-- categories: Vulnerability Management -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- Liens : [Documentation](../../user/application_security/configuration/security_configuration_profiles.md)

{{< /details >}}

Gérez et visualisez la couverture des scanners de sécurité au sein de votre organisation. Cette release introduit des profils de configuration de sécurité, en commençant par le profil de détection des secrets. Les équipes de sécurité disposent désormais d'un centre de commandement plus puissant pour sécuriser votre organisation à grande échelle.

**Profile-based security configuration**

Au lieu de modifier manuellement les fichiers YAML pour chaque projet, vous pouvez désormais utiliser des profils de configuration de sécurité préconfigurés qui offrent plusieurs avantages :

- Gouvernance standardisée : les profils préconfigurés appliquent des limites appropriées sans interrompre la productivité. Vous pouvez appliquer des bonnes pratiques de sécurité standardisées, sans nécessiter de configurations de rôles personnalisés.
- Gestion évolutive : appliquez le même profil à des centaines ou à des milliers de projets en une seule action.

Le profil de détection des secrets est le premier profil de configuration de sécurité disponible. Il offre les avantages suivants :

- Identifie et bloque activement les secrets qui sont committés dans vos dépôts.
- Un seul profil gère la détection des secrets sur l'ensemble de votre workflow de développement. Inutile de gérer des configurations séparées pour différents types de déclencheurs.

**Enhanced security inventory**

L'inventaire de sécurité a été amélioré pour servir de tableau de bord principal afin d'évaluer la posture de sécurité de chaque groupe :

- Hiérarchies de groupes et de projets : distinguez facilement les sous-groupes des projets dans l'inventaire grâce à une iconographie claire.
- Actions groupées : un nouveau menu **Bulk Action** vous permet d'appliquer ou de désactiver des profils de scanner de sécurité sur tous les projets et sous-groupes sélectionnés simultanément.
- Statut de couverture visuelle : identifiez rapidement les lacunes grâce à des barres de statut codées par couleur (Activé, Non activé ou Échec) avec des info-bulles pour les détails.
- Indicateurs de statut des profils : consultez les types de déclencheurs disponibles dans les détails du profil.

### Attributs de sécurité {#security-attributes}

<!-- categories: Security Asset Inventories -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- Liens : [Documentation](../../user/application_security/attributes/_index.md)

{{< /details >}}

Les attributs de sécurité, [introduits en version bêta dans GitLab 18.6](gitlab-18-6-released.md#security-attributes-beta), sont désormais généralement disponibles.

Les attributs de sécurité permettent aux équipes de sécurité d'appliquer un contexte métier à leurs projets, notamment l'impact métier, l'application, l'unité commerciale, l'exposition à Internet et l'emplacement. Vous pouvez également créer des catégories d'attributs personnalisées pour correspondre à la taxonomie de votre organisation. En appliquant ces attributs, vous pouvez filtrer et prioriser les éléments de votre inventaire de sécurité en fonction de la posture de risque et du contexte organisationnel.

### Tableaux de bord de sécurité : améliorations du graphique Vulnérabilités au fil du temps {#security-dashboards-vulnerabilities-over-time-chart-improvements}

<!-- categories: Vulnerability Management -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- Liens : [Documentation](../../user/application_security/security_dashboard/_index.md#vulnerabilities-over-time) \| [Epic associé](https://gitlab.com/groups/gitlab-org/-/work_items/19780)

{{< /details >}}

Le graphique **Vulnérabilités au fil du temps** est mis à jour pour offrir une vue plus précise de votre inventaire de vulnérabilités.

Le graphique incluait auparavant des vulnérabilités qui n'étaient plus détectées, entraînant des chiffres gonflés qui ne représentaient pas fidèlement l'état des vulnérabilités actives.

Nous avons connaissance de deux problèmes supplémentaires qui peuvent légèrement modifier les comptages dans certains cas. Suivez [le ticket 590022](https://gitlab.com/gitlab-org/gitlab/-/issues/590022) et [le ticket 590018](https://gitlab.com/gitlab-org/gitlab/-/issues/590018) pour les mises à jour.

### Afficher les métriques des jobs CI/CD pour les projets (disponibilité limitée) {#view-cicd-job-metrics-for-projects-limited-availability}

<!-- categories: Fleet Visibility -->

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Liens : [Documentation](../../user/analytics/ci_cd_analytics.md#cicd-job-performance-metrics) \| [Epic associé](https://gitlab.com/groups/gitlab-org/-/epics/18548)

{{< /details >}}

Les analyses CI/CD de GitLab combinent désormais les tendances de performances des pipelines CI/CD et des jobs CI/CD, ce qui permet aux développeurs d'identifier rapidement les jobs CI/CD inefficaces ou problématiques. Ces capacités sont directement intégrées dans l'interface GitLab, afin que les développeurs disposent des outils dont ils ont besoin en contexte pour identifier et corriger les problèmes de performance CI/CD qui peuvent avoir un impact significatif sur la vélocité des équipes de développement et la productivité globale. Pour les administrateurs de plateforme, les données des jobs CI/CD dans cette vue réduisent également la nécessité de s'appuyer sur des solutions d'observabilité CI/CD externes ou personnalisées lorsque vous exploitez GitLab à l'échelle d'une entreprise.

### Ajouter des horodatages aux job logs CI {#add-timestamps-to-ci-job-logs}

<!-- categories: Continuous Integration (CI) -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- Liens : [Documentation](../../ci/jobs/job_logs.md#timestamps) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/202293)

{{< /details >}}

Vous pouvez désormais afficher des horodatages sur chaque ligne de job log CI pour identifier les goulots d'étranglement de performance et déboguer les jobs à longue exécution. Les horodatages sont affichés au format UTC. Utilisez les horodatages pour résoudre les problèmes de performance, identifier les goulots d'étranglement et mesurer la durée d'étapes de build spécifiques. Nécessite GitLab Runner 18.7 ou une version ultérieure pour GitLab Self-Managed.

### Analyse du catalogue CI/CD des composants {#cicd-catalog-component-analytics}

<!-- categories: Pipeline Composition -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- Liens : [Documentation](../../ci/components/_index.md#view-cicd-catalog-project-analytics) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/579458)

{{< /details >}}

Auparavant, les équipes manquaient de visibilité sur la manière dont les projets de composants du catalogue CI/CD étaient utilisés au sein de leur organisation. Vous pouvez désormais afficher les comptages d'utilisation et les modèles d'adoption à un niveau élevé, vous aidant à comprendre quels projets de composants sont les plus précieux et à optimiser vos investissements dans le catalogue.

### Afficher les rapports de sécurité des pipelines enfants dans les merge requests {#view-security-reports-from-child-pipelines-in-merge-requests}

<!-- categories: Continuous Integration (CI) -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- Liens : [Documentation](../../ci/pipelines/downstream_pipelines.md#view-child-pipeline-reports-in-merge-requests) \| [Epic associé](https://gitlab.com/groups/gitlab-org/-/epics/18377)

{{< /details >}}

Vous pouvez désormais afficher les rapports de sécurité et de conformité des pipelines enfants directement dans les widgets de merge request. Auparavant, vous deviez naviguer manuellement à travers plusieurs pipelines pour identifier les problèmes de sécurité, créant des workflows inefficaces, notamment avec les monodépôts et les configurations de tests complexes.

Grâce à cette amélioration, le widget de merge request affiche les rapports des pipelines enfants directement à côté des résultats du pipeline parent, avec les rapports de chaque pipeline enfant présentés individuellement et les artefacts disponibles au téléchargement. Cela offre une vue unifiée de tous les contrôles de sécurité, réduisant considérablement le temps consacré à l'investigation des échecs et permettant des examens de merge request plus rapides lors de l'utilisation de pipelines parent-enfant.

## Sujets connexes {#related-topics}

- [Correctifs de bugs](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=type%3A%3Abug&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=18.9)
- [Améliorations des performances](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=bug%3A%3Aperformance&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=18.9)
- [Améliorations de l'interface utilisateur](https://papercuts.gitlab.com/?milestone=18.9)
- [Dépréciations et suppressions](../../update/deprecations.md)
- [Notes de mise à niveau](../../update/versions/_index.md)
