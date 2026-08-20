---
stage: Release Notes
group: Monthly Release
date: 2025-06-19
title: "Notes de release GitLab 18.1"
description: "GitLab 18.1 est disponible avec le registre virtuel Maven désormais en version bêta"
---

<!-- markdownlint-disable -->
<!-- vale off -->

Le 19 juin 2025, GitLab 18.1 a été publié avec les fonctionnalités suivantes.

Nous souhaitons également remercier tous nos contributeurs, dont le contributeur remarquable de ce mois-ci.

## Contributeur notable du mois : Chaitanya Sonwane {#this-months-notable-contributor-chaitanya-sonwane}

Chaitanya Sonwane renforce les capacités de sécurité de GitLab grâce à des améliorations continues en matière d'authentification. [Avec 13 contributions fusionnées en 2025](https://contributors.gitlab.com/users/chaitanyason9?fromDate=2025-01-01&toDate=2025-12-31), ses travaux ont amélioré le filtrage de l'inventaire des identifiants, la gestion des comptes de service et l'ergonomie des éléments de travail. Il a précédemment livré une [fonctionnalité clé dans GitLab 17.11](https://about.gitlab.com/releases/2025/04/17/gitlab-17-11-released/#token-statistics-for-service-account-management) avec des statistiques de jetons pour les comptes de service, qui fournit des informations « en un coup d'œil » facilitant la gestion des comptes de service. Chaitanya travaille actuellement à [l'amélioration des paramètres de tri de la liste des éléments de travail pour les rendre spécifiques au contexte](https://gitlab.com/gitlab-org/gitlab/-/issues/503587), améliorant ainsi davantage l'expérience utilisateur dans la planification produit de GitLab.

Les travaux de Chaitanya renforcent directement la sécurité des organisations GitLab et offrent une meilleure visibilité sur l'utilisation des comptes de service à travers les projets. Les équipes peuvent désormais suivre et faire pivoter les identifiants plus efficacement. Cela réduit le risque d'identifiants orphelins ou oubliés qui créent des vulnérabilités de sécurité.

« Les contributions de Chaitanya à l'inventaire des identifiants et aux comptes de service sont toutes deux des contributions très précieuses dans le domaine de la sécurité », déclare [Eduardo Sanz-Garcia](https://gitlab.com/eduardosanz), Senior Frontend Engineer pour le groupe Authentication, étape Software Supply Chain Security. Eduardo a soutenu la nomination de l'équipe Authentication de GitLab.

« Chaitanya a joué un rôle déterminant dans la mise en œuvre du concept de statistiques de jetons », ajoute Eduardo. « Son travail sur l'inventaire des identifiants a livré une fonctionnalité très demandée pour améliorer la traçabilité et la surveillance des identifiants. C'était une excellente contribution ! »

Chaitanya est ingénieur logiciel chez TATA AIG. Il traite les problèmes de sécurité de manière proactive et assure un suivi constant des améliorations apportées à ses propres contributions.

Merci à Chaitanya pour sa contribution aux fondations de sécurité de GitLab et au reste du produit !

## Fonctionnalités principales {#primary-features}

### Le registre virtuel Maven est désormais disponible en version bêta {#maven-virtual-registry-now-available-in-beta}

<!-- categories: Virtual Registry -->

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed
- Liens : [Documentation](../../user/packages/virtual_registry/maven/_index.md) \| [Epic associé](https://gitlab.com/groups/gitlab-org/-/epics/14137)

{{< /details >}}

Le registre virtuel Maven simplifie la gestion des dépendances Maven dans GitLab. Sans le registre virtuel Maven, vous devez configurer chaque projet pour accéder aux dépendances depuis Maven Central, des dépôts privés ou le registre de paquets GitLab. Cette approche ralentit les builds avec des requêtes séquentielles aux dépôts et complique l'audit de sécurité et le reporting de conformité.

Le registre virtuel Maven résout ces problèmes en agrégeant plusieurs dépôts en amont derrière un point de terminaison unique. Les ingénieurs de plateforme peuvent configurer Maven Central, des registres privés et des registres de paquets GitLab via une seule URL. La mise en cache intelligente améliore les performances de build et s'intègre aux systèmes d'authentification de GitLab. Les organisations bénéficient d'une réduction de la charge de configuration, de builds plus rapides et d'un contrôle d'accès centralisé pour une sécurité et une conformité améliorées.

Le registre virtuel Maven est actuellement disponible en version bêta pour les clients GitLab Premium et Ultimate sur GitLab.com et GitLab Self-Managed. La release GA comprendra des fonctionnalités supplémentaires, telles qu'une interface utilisateur web pour la configuration du registre, des fonctionnalités en amont partageables, des politiques de cycle de vie pour la gestion du cache et des analyses améliorées. Les limitations actuelles de la version bêta incluent un maximum de 20 registres virtuels par groupes principaux et 20 sources en amont par registre virtuel, avec une configuration exclusivement via API disponible pendant la période bêta.

Nous invitons les clients entreprise à participer au programme bêta du registre virtuel Maven pour contribuer à façonner la release finale. Les participants à la version bêta bénéficieront d'un accès anticipé aux fonctionnalités, d'une interaction directe avec les équipes produit GitLab et d'un support prioritaire pendant l'évaluation. Pour rejoindre le programme bêta, manifestez votre intérêt et fournissez les détails de votre cas d'utilisation dans le [ticket 498139](https://gitlab.com/gitlab-org/gitlab/-/issues/498139), et partagez vos retours et suggestions dans le [ticket 543045](https://gitlab.com/gitlab-org/gitlab/-/issues/543045).

### Duo Code Review est désormais disponible en disponibilité générale {#duo-code-review-is-now-generally-available}

<!-- categories: Code Review Workflow -->

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Modules complémentaires : Duo Enterprise
- Liens : [Documentation](../../user/project/merge_requests/duo_in_merge_requests.md)

{{< /details >}}

Duo Code Review est désormais disponible en disponibilité générale et prêt pour une utilisation en production. Cet assistant de revue de code basé sur l'IA transforme le processus traditionnel de revue de code en fournissant des retours intelligents et automatisés sur vos merge requests. Il aide à identifier les bugs potentiels, les vulnérabilités de sécurité et les problèmes de qualité du code avant que les relecteurs humains n'interviennent, rendant l'ensemble du processus de révision plus efficace et plus approfondi. Il comprend :

- **Automated initial review** : Duo Code Review analyse vos modifications de code et fournit des retours complets sur les problèmes potentiels, les améliorations et les bonnes pratiques.
- **Interactive refinement** : mentionnez `@GitLabDuo` dans les commentaires de la merge request pour obtenir des retours ciblés sur des modifications ou des questions spécifiques.
- **Actionable suggestions** : de nombreuses suggestions peuvent être appliquées directement depuis votre navigateur, simplifiant ainsi le processus d'amélioration.
- **Context-aware analysis** : tire parti de la compréhension des fichiers modifiés pour fournir des recommandations pertinentes et spécifiques au projet.

Pour demander une revue de code :

- Dans votre merge request, ajoutez `@GitLabDuo` en tant que relecteur en utilisant l'action rapide `/assign_reviewer @GitLabDuo`, ou assignez GitLab Duo directement comme relecteur.
- Mentionnez `@GitLabDuo` dans les commentaires pour poser des questions spécifiques ou demander des retours ciblés sur n'importe quel fil de discussion.
- Activez les revues automatiques dans les paramètres de votre projet pour que GitLab Duo examine automatiquement toutes les nouvelles merge requests.

Duo Code Review aide les équipes à maintenir des standards de qualité de code plus élevés tout en réduisant le temps consacré aux cycles de révision manuels. En détectant les problèmes tôt et en fournissant des retours pédagogiques, il sert à la fois de portail qualité et d'outil d'apprentissage pour les équipes de développement.

\*\*[Regardez un aperçu](https://www.youtube.com/watch?v=FlHqfMMfbzQ) de Duo Code Review en action depuis notre release bêta.

Partagez votre expérience et vos retours dans le [ticket 517386](https://gitlab.com/gitlab-org/gitlab/-/issues/517386) pour nous aider à continuer à améliorer cette fonctionnalité.

### Détection des mots de passe compromis pour les identifiants natifs GitLab {#compromised-password-detection-for-native-gitlab-credentials}

<!-- categories: System Access -->

{{< details >}}

- Édition : Free, Silver, Gold
- Offre : GitLab.com
- Liens : [Documentation](../../user/profile/user_passwords.md#compromised-password-detection) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/549865)

{{< /details >}}

GitLab.com effectue désormais une vérification sécurisée de vos identifiants de compte lorsque vous vous connectez à GitLab.com. Si votre mot de passe fait partie d'une fuite connue, GitLab affiche une bannière et vous envoie une notification par e-mail. Ces notifications incluent des instructions pour mettre à jour vos identifiants.

Pour une sécurité maximale, GitLab recommande d'utiliser un mot de passe unique et fort pour GitLab, d'activer l'authentification à deux facteurs et de consulter régulièrement l'activité de votre compte.

Remarque : cette fonctionnalité est uniquement disponible pour les noms d'utilisateur et mots de passe natifs GitLab. Les identifiants SSO ne sont pas vérifiés.

### Atteindre la conformité [SLSA](https://slsa.dev/) Niveau 1 avec des composants CI/CD {#achieve-slsa-level-1-compliance-with-cicd-components}

<!-- categories: Artifact Security -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Liens : [Documentation](../../ci/pipeline_security/slsa/_index.md#sign-and-verify-slsa-provenance-with-a-cicd-component) \| [Epic associé](https://gitlab.com/groups/gitlab-org/-/epics/15859)

{{< /details >}}

Vous pouvez désormais atteindre la conformité SLSA Niveau 1 en utilisant les nouveaux composants CI/CD de GitLab pour signer et vérifier les [métadonnées de provenance d'artefacts](../../ci/runners/configure_runners.md#artifact-provenance-metadata) conformes à SLSA générées par GitLab Runner. Les composants encapsulent les [fonctionnalités Sigstore Cosign](../../ci/yaml/signing_examples.md) dans des modules réutilisables pouvant être facilement intégrés dans des workflows CI/CD.

## Mise à l'échelle et déploiements {#scale-and-deployments}

### Correspondances multiples par fichier dans la recherche de code {#multiple-matches-per-file-in-code-search}

<!-- categories: Code Search -->

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Liens : [Documentation](../../integration/zoekt/_index.md) \| [Epic associé](https://gitlab.com/groups/gitlab-org/-/epics/13127)

{{< /details >}}

La recherche de code exacte (en version bêta) regroupe désormais plusieurs résultats de recherche du même fichier dans une vue unique. Cette amélioration :

- Préserve le contexte entre les correspondances adjacentes au lieu d'afficher des lignes isolées.
- Réduit l'encombrement visuel en éliminant le contenu dupliqué lorsque les correspondances sont proches les unes des autres.
- Améliore la navigation en affichant clairement le nombre de correspondances par fichier.
- Améliore la lisibilité en affichant le code tel que vous le verriez dans votre éditeur.

Grâce à cette modification, la recherche et la compréhension des modèles de code dans vos dépôts sont désormais plus efficaces.

### Nouvel argument `accessLevels` pour `projectMembers` dans l'API GraphQL {#new-accesslevels-argument-for-projectmembers-in-graphql-api}

<!-- categories: Groups & Projects -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Liens : [Documentation](../../api/graphql/reference/_index.md#projectprojectmembers) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/541386)

{{< /details >}}

Nous sommes heureux d'annoncer l'ajout de l'argument `accessLevels` au champ `projectMembers` dans notre API GraphQL. Utilisez cet argument pour filtrer les membres du projet par niveau d'accès directement depuis un appel API. Auparavant, vous deviez récupérer la liste complète des membres du projet et appliquer les filtres localement, ce qui ajoutait une charge de calcul significative. Désormais, l'analyse des permissions des projets et la génération de graphiques de propriété sont plus rapides et plus efficaces en termes de ressources. Cette amélioration est particulièrement précieuse pour les organisations gérant des déploiements à grande échelle avec des structures de permissions complexes.

## DevOps et sécurité unifiés {#unified-devops-and-security}

### Parité de détection DAST avec les règles par défaut de la détection des secrets {#dast-detection-parity-with-secret-detection-default-rules}

<!-- categories: DAST -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Liens : [Documentation](../../user/application_security/dast/browser/checks/_index.md) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/549990)

{{< /details >}}

L'analyseur DAST ingère désormais automatiquement les mêmes règles de détection des secrets par défaut que celles utilisées par l'analyseur Secret Detection de GitLab. Cette amélioration garantit la cohérence dans les types de secrets détectés par les deux.

### Définir un `Name` pour les contrôles personnalisés externes {#define-a-name-for-external-custom-controls}

<!-- categories: Compliance Management -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Liens : [Documentation](../../user/compliance/compliance_frameworks/_index.md#external-controls) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/527007)

{{< /details >}}

Auparavant, vous ne pouviez pas définir de nom pour un contrôle personnalisé externe lors de la création d'un framework de conformité personnalisé, ce qui rendait difficile l'identification des contrôles externes listés à côté des contrôles GitLab.

Nous avons maintenant ajouté un champ `Name` dans le workflow lors de la définition d'un contrôle personnalisé externe, afin que vous puissiez créer plusieurs contrôles personnalisés externes et définir clairement chacun avec son propre nom unique.

### Pagination des exigences dans l'interface des frameworks de conformité {#pagination-for-requirements-in-compliance-frameworks-ui}

<!-- categories: Compliance Management -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Liens : [Documentation](../../user/compliance/compliance_frameworks/_index.md#add-requirements) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/531039)

{{< /details >}}

Lors de la création d'un framework de conformité, vous pouvez spécifier un maximum de 50 exigences.

Cependant, il devient très difficile de naviguer dans un framework de conformité comportant autant d'exigences, car elles occupent beaucoup d'espace dans l'interface utilisateur.

Dans cette release, nous avons introduit la pagination des exigences pour faciliter la navigation, la recherche et la sélection des exigences lorsqu'un grand nombre d'entre elles sont attachées à un framework de conformité.

### Améliorations des performances de l'interface et du filtrage pour le centre de conformité {#ui-performance-and-filtering-improvements-for-compliance-center}

<!-- categories: Compliance Management -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Liens : [Documentation](../../user/compliance/compliance_center/_index.md)

{{< /details >}}

Nous avons continué à améliorer les performances de l'interface et les options de filtrage fournies par le centre de conformité. Dans cette release, nous avons :

- Amélioré la vitesse et les performances de l'interface de la page **Edit Framework**, notamment lorsqu'il y a de nombreuses exigences et projets sur la page.
- Introduit de nouvelles options de filtrage pour vous permettre de regrouper par exigence, projet ou framework dans l'onglet **Compliance status report** du centre de conformité.

En apportant ces améliorations, nous continuons à garantir que le centre de conformité et les fonctions associées continuent de fonctionner à grande échelle pour les clients qui utilisent régulièrement le centre de conformité.

### Pop-up de statut des contrôles dans le rapport de statut de conformité {#control-status-pop-up-in-the-compliance-status-report}

<!-- categories: Compliance Management -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Liens : [Documentation](../../user/compliance/compliance_center/compliance_status_report.md) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/521757)

{{< /details >}}

Les contrôles dans le rapport de statut de conformité ont trois statuts différents :

- Réussi
- Échec
- En attente

Quel que soit le nombre de contrôles attachés à l'exigence, si au moins un contrôle était « en attente », toute la ligne d'exigence était également affichée comme « en attente ». Cela s'écartait du modèle UX établi pour la visualisation des contrôles en échec, où l'exigence affichait le nombre de contrôles associés à l'exigence, même lorsqu'au moins un contrôle était en échec.

Pour fournir davantage de contexte et d'informations sur les contrôles « en attente », nous proposons désormais un pop-up au survol sur le statut de la ligne d'exigence, avec le statut de chaque contrôle listé. Vous pouvez désormais comprendre quels contrôles sont en attente, lesquels réussissent et lesquels échouent potentiellement, plutôt que de voir un seul statut « en attente ».

### Expérience de revue de merge request améliorée avec le panneau de revue {#enhanced-merge-request-review-experience-with-review-panel}

<!-- categories: Code Review Workflow -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Dedicated
- Liens : [Documentation](../../user/project/merge_requests/reviews/_index.md#submit-a-review) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/525841)

{{< /details >}}

Lorsque vous examinez une merge request, il peut être utile de voir tous les commentaires et retours que vous avez fournis avant de soumettre votre revue. Auparavant, cette expérience était fragmentée entre le commentaire final et un pop-up supplémentaire pour consulter vos commentaires en attente, ce qui rendait difficile l'obtention d'une vue d'ensemble complète.

Lors des revues de code, vous pouvez désormais accéder à un volet dédié qui regroupe tous vos commentaires brouillons en attente dans une vue organisée. Le panneau de revue amélioré déplace l'interface de soumission de revue vers un emplacement plus accessible et fournit un badge numéroté indiquant le nombre de commentaires en attente. Lorsque vous ouvrez le panneau, vous verrez tous vos commentaires brouillons organisés dans une liste défilante, ce qui facilite la révision et la gestion de vos retours avant la soumission.

### Validation améliorée du fichier CODEOWNERS avec vérifications des permissions {#enhanced-codeowners-file-validation-with-permission-checks}

<!-- categories: Source Code Management -->

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab Dedicated
- Liens : [Documentation](../../user/project/codeowners/troubleshooting.md#validate-your-codeowners-file) \| [Epic associé](https://gitlab.com/groups/gitlab-org/-/epics/15598)

{{< /details >}}

GitLab fournit désormais une validation améliorée pour les fichiers CODEOWNERS qui va au-delà de la vérification syntaxique de base. Lors de la consultation d'un fichier CODEOWNERS, GitLab exécute automatiquement des validations complètes pour vous aider à identifier les problèmes de syntaxe et de permissions avant qu'ils n'affectent vos workflows de merge request.

La validation améliorée vérifie les 200 premières références uniques d'utilisateurs et de groupes dans votre fichier CODEOWNERS, et s'assure que :

- Tous les utilisateurs et groupes référencés ont accès au projet.
- Les utilisateurs disposent des permissions nécessaires pour approuver les merge requests.
- Les groupes disposent au minimum d'un accès de niveau Développeur ou supérieur.
- Les groupes contiennent au moins un utilisateur disposant des permissions d'approbation de merge request.

Cette validation proactive aide à prévenir les perturbations dans les workflows d'approbation en détectant tôt les problèmes de configuration, garantissant que vos propriétaires du code peuvent effectivement remplir leurs responsabilités de revue lors de la création des merge requests.

### Initialisation personnalisée du workspace avec des événements `postStart` {#custom-workspace-initialization-with-poststart-events}

<!-- categories: Workspaces -->

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Liens : [Documentation](../../user/workspace/_index.md#user-defined-poststart-events)

{{< /details >}}

Le workspace GitLab prend désormais en charge les événements `postStart` personnalisés dans votre devfile, vous permettant de définir des commandes qui s'exécutent automatiquement après le démarrage du workspace. Utilisez ces événements pour :

- Configurer les dépendances de développement.
- Configurer votre environnement.
- Exécuter des scripts d'initialisation qui préparent votre projet pour une productivité immédiate sans intervention manuelle.

### Afficher les job logs des pipelines downstream dans VS Code {#view-downstream-pipeline-job-logs-in-vs-code}

<!-- categories: Editor Extensions -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Liens : [Documentation](https://docs.gitlab.com/editor_extensions/visual_studio_code/cicd/) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab-vscode-extension/-/issues/1895)

{{< /details >}}

L'extension GitLab Workflow pour VS Code affiche désormais les job logs des pipelines downstream directement dans votre éditeur. Auparavant, la consultation des logs des pipelines enfants nécessitait de basculer vers l'interface web de GitLab.

Cette fonctionnalité a été développée dans le cadre du [programme GitLab Co-create](https://about.gitlab.com/community/co-create/). Merci tout particulièrement à Tim Ryan pour cette contribution !

### Afficher les jetons d'accès personnels inactifs {#view-inactive-personal-access-tokens}

<!-- categories: System Access -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Liens : [Documentation](../../user/profile/personal_access_tokens.md) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/425053)

{{< /details >}}

GitLab désactive automatiquement les jetons d'accès après leur expiration ou révocation. Vous pouvez désormais consulter ces jetons inactifs. Auparavant, les jetons d'accès n'étaient plus visibles après leur désactivation. Cette modification améliore la traçabilité et la sécurité de ces types de jetons.

### Prise en charge des epics pour les vues GitLab Query Language en version bêta {#epic-support-for-gitlab-query-language-views-beta}

<!-- categories: Wiki, Team Planning -->

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Liens : [Documentation](../../user/glql/fields.md) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab-query-language/glql-rust/-/issues/30)

{{< /details >}}

Nous avons apporté une amélioration significative aux vues GitLab Query Language (GLQL). Vous pouvez désormais utiliser epic comme type dans vos requêtes pour rechercher des epics à travers des groupes, et effectuer des requêtes par epic parent !

Il s'agit d'une avancée majeure pour nos capacités de planification et de suivi, permettant plus que jamais d'interroger et d'organiser au niveau des epics.

### Prise en charge de PHP pour Advanced SAST {#php-support-for-advanced-sast}

<!-- categories: SAST -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Liens : [Documentation](../../user/application_security/sast/gitlab_advanced_sast.md#supported-languages) \| [Epic associé](https://gitlab.com/groups/gitlab-org/-/epics/14273)

{{< /details >}}

Nous avons ajouté la prise en charge de PHP à GitLab Advanced SAST. Pour utiliser cette nouvelle prise en charge de l'analyse inter-fichiers et inter-fonctions, [activez Advanced SAST](../../user/application_security/sast/gitlab_advanced_sast.md#turn-on-gitlab-advanced-sast). Si vous avez déjà activé Advanced SAST, la prise en charge de PHP est automatiquement activée.

Pour voir quels types de vulnérabilités Advanced SAST détecte dans chaque langage, consultez la [page de couverture d'Advanced SAST](../../user/application_security/sast/advanced_sast_coverage.md).

### Filtrer par version de composant dans la liste des dépendances {#filter-by-component-version-in-the-dependency-list}

<!-- categories: Dependency Management -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Liens : [Documentation](../../user/application_security/dependency_list/_index.md#filter-dependency-list) \| [Epic associé](https://gitlab.com/groups/gitlab-org/-/epics/16431)

{{< /details >}}

La liste des dépendances prend désormais en charge le filtrage par numéro de version d'un composant. Vous pouvez sélectionner plusieurs versions (par exemple, `version=1.1,1.2,1.4`) mais les plages ne sont pas prises en charge. Cette fonctionnalité est disponible pour les groupes et les projets.

### Contrôles de précédence des variables dans les politiques d'exécution de pipeline {#variable-precedence-controls-in-pipeline-execution-policies}

<!-- categories: Security Policy Management -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Liens : [Documentation](../../user/application_security/policies/pipeline_execution_policies.md#variables_override-type) \| [Epic associé](https://gitlab.com/groups/gitlab-org/-/epics/16430)

{{< /details >}}

Les équipes de sécurité cherchent souvent à maintenir un équilibre délicat entre l'assurance de sécurité et l'expérience développeur. Il est essentiel de veiller à ce que les analyses de sécurité soient correctement appliquées, mais les analyseurs de sécurité peuvent nécessiter des entrées spécifiques de la part des équipes de développement pour s'exécuter correctement. Grâce aux contrôles de précédence des variables, les équipes de sécurité disposent désormais d'un contrôle granulaire sur la façon dont les variables sont gérées dans les politiques d'exécution de pipeline via la nouvelle option de configuration `variables_override`.

Avec cette nouvelle configuration, vous pouvez désormais :

- Appliquer des politiques d'analyse de conteneurs qui autorisent des chemins d'images de conteneurs spécifiques au projet (`CS_IMAGE`).
- Autoriser les variables à faible risque comme `SAST_EXCLUDED_PATHS` tout en bloquant les variables à risque élevé comme `SAST_DISABLED`.
- Définir des identifiants partagés globalement qui sont sécurisés (masqués ou cachés) avec des variables CI/CD globales, tels que `AWS_CREDENTIALS`, tout en autorisant des remplacements spécifiques au projet là où cela est approprié via des variables CI/CD au niveau du projet.

Cette fonctionnalité puissante prend en charge deux approches :

- **Lock variables by default** (`allow: false`) : verrouiller toutes les variables sauf celles spécifiques que vous listez comme exceptions.
- **Allow variables by default** (`allow: true`) : autoriser la personnalisation des variables, mais restreindre les risques critiques en les listant comme exceptions.

Pour améliorer la traçabilité et le dépannage lorsqu'une politique d'exécution de pipeline est à l'origine d'un job CI/CD, nous introduisons également des job logs pour aider les développeurs et les équipes de sécurité à identifier les jobs exécutés par une politique. Les job logs fournissent des détails sur l'impact des remplacements de variables pour vous aider à comprendre si des variables sont remplacées ou verrouillées par des politiques.

**Real-world impact**

Cette amélioration comble l'écart entre les exigences de sécurité et la flexibilité pour les développeurs :

- Les équipes de sécurité peuvent appliquer des analyses standardisées tout en autorisant des personnalisations spécifiques aux projets.
- Les développeurs conservent le contrôle sur les variables spécifiques au projet sans avoir à demander des exceptions de politique.
- Les organisations peuvent mettre en œuvre des politiques de sécurité cohérentes sans perturber les workflows de développement.

En résolvant ce défi critique de contrôle des variables, GitLab permet aux organisations de mettre en œuvre des politiques de sécurité robustes sans sacrifier la flexibilité dont les équipes ont besoin pour livrer des logiciels efficacement.

### Filtrer les utilisateurs bots et humains {#filter-for-bot-and-human-users}

<!-- categories: System Access -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Dedicated
- Liens : [Documentation](../../administration/moderate_users.md#view-users-by-type) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/541186)

{{< /details >}}

Les instances GitLab établies peuvent souvent avoir un grand nombre d'utilisateurs humains et de bots. Vous pouvez désormais filtrer la liste des utilisateurs dans la zone Admin par type d'utilisateur. Le filtrage des utilisateurs peut vous aider à :

- Identifier et gérer rapidement les utilisateurs humains séparément des comptes automatisés.
- Effectuer des actions administratives ciblées sur des types d'utilisateurs spécifiques.
- Simplifier les workflows d'audit et de gestion des utilisateurs.

### Identifiant [ORCID](https://orcid.org/) dans le profil utilisateur {#orcid-identifier-in-user-profile}

<!-- categories: User Profile -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Liens : [Documentation](../../user/profile/_index.md) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/23543)

{{< /details >}}

GitLab prend désormais en charge les identifiants ORCID dans les profils utilisateurs, rendant GitLab plus accessible et utile pour les chercheurs et la communauté académique. [ORCID](https://orcid.org/) (Open Researcher and Contributor ID) fournit aux chercheurs un identifiant numérique persistant qui les distingue des autres chercheurs et prend en charge des liens automatisés entre les chercheurs et leurs activités professionnelles, garantissant que leurs travaux sont correctement reconnus.

Cette fonctionnalité a été développée comme une contribution communautaire par Thomas Labalette et Erwan Hivin, étudiants en master à l'Université d'Artois, sous la supervision de [Daniel Le Berre](https://www.ouvrirlascience.fr/appointment-of-daniel-le-berre-as-the-national-coordinator-for-higher-education-and-research-software-forges-in-france/), en réponse à une demande de longue date de la communauté académique.

### S'abonner aux notifications de pipeline de compte de service {#subscribe-to-service-account-pipeline-notifications}

<!-- categories: System Access -->

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Liens : [Documentation](../../user/profile/notifications.md#notifications-about-failed-pipeline-that-doesnt-exist) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/515629)

{{< /details >}}

Vous pouvez désormais vous abonner aux notifications pour les événements de pipeline déclenchés par des comptes de service. Les notifications sont envoyées lorsque le pipeline réussit, échoue ou est corrigé. Auparavant, ces notifications étaient uniquement envoyées à l'adresse e-mail du compte de service si celui-ci disposait d'une adresse e-mail personnalisée valide.

Merci à [Densett](https://gitlab.com/[Densett](https://gitlab.com/Densett)), [Gilles Dehaudt](https://gitlab.com/tonton1728), [Lenain](https://gitlab.com/lenaing), [Geoffrey McQuat](https://gitlab.com/gmcquat) et [Raphaël Bihoré](https://gitlab.com/rbihore) pour votre contribution !

### Couverture SAST étendue pour la résolution des vulnérabilités Duo {#increased-sast-coverage-for-duo-vulnerability-resolution}

<!-- categories: Vulnerability Management -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Liens : [Documentation](../../user/application_security/vulnerabilities/_index.md#supported-vulnerabilities-for-vulnerability-resolution) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/534307)

{{< /details >}}

Auparavant, vous deviez résoudre manuellement les vulnérabilités détectées avec ces identifiants Common Weakness Enumeration (CWE) :

- CWE-78 (Injection de commande)
- CWE-89 (Injection SQL)

Désormais, Duo Vulnerability Resolution peut corriger automatiquement ces vulnérabilités.

### GitLab Runner 18.1 {#gitlab-runner-181}

<!-- categories: GitLab Runner Core -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Dedicated
- Liens : [Documentation](https://docs.gitlab.com/runner)

{{< /details >}}

Nous publions également GitLab Runner 18.1 aujourd'hui ! GitLab Runner est l'agent de build hautement évolutif qui exécute vos jobs CI/CD et envoie les résultats à une instance GitLab. GitLab Runner fonctionne en conjonction avec GitLab CI/CD, le service d'intégration continue open source inclus avec GitLab.

#### Corrections de bugs {#bug-fixes}

- [Si vous effectuez une mise à niveau vers GitLab 17.10 ou 17.11, les runners peuvent recevoir une réponse `404` lorsqu'ils demandent des jobs](https://gitlab.com/gitlab-org/gitlab/-/issues/543351).

La liste de toutes les modifications se trouve dans le [CHANGELOG](https://gitlab.com/gitlab-org/gitlab-runner/blob/18-1-stable/[CHANGELOG](https://gitlab.com/gitlab-org/gitlab-runner/blob/18-1-stable/CHANGELOG.md).md) de GitLab Runner.

## Sujets connexes {#related-topics}

- [Correctifs de bugs](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=type%3A%3Abug&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=18.1)
- [Améliorations des performances](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=bug%3A%3Aperformance&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=18.1)
- [Améliorations de l'interface utilisateur](https://papercuts.gitlab.com/?milestone=18.1)
- [Dépréciations et suppressions](../../update/deprecations.md)
- [Notes de mise à niveau](../../update/versions/_index.md)
