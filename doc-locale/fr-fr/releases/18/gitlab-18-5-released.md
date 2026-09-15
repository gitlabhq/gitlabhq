---
stage: Release Notes
group: Monthly Release
date: 2025-10-16
title: "Notes de release de GitLab 18.5"
description: "GitLab 18.5 est disponible avec GitLab Duo Planner, un agent spécialisé et membre de l'équipe Product Manager (version bêta)"
---

<!-- markdownlint-disable -->
<!-- vale off -->

Le 16 octobre 2025, GitLab 18.5 a été publié avec les fonctionnalités suivantes.

Nous souhaitons également remercier tous nos contributeurs, dont le contributeur remarquable de ce mois-ci.

## Contributeur notable du mois : Jose Gabriel Companioni Benitez {#this-months-notable-contributor-jose-gabriel-companioni-benitez}

Dans son article de blog [« How GitLab Can Boost Your Professional Career »](https://compacompila.com/posts/gitlab-open-source-community/), Jose partage : « Pour moi, le principal avantage que GitLab offre, du point de vue du développement professionnel, est qu'il est open source. » Il ajoute : « Pour GitLab, il est important que tout le monde puisse contribuer, et pour cette raison, ils ont pris très au sérieux le processus d'intégration des contributeurs. »

Le parcours de Jose, de premier contributeur en septembre à contributeur notable en octobre, illustre la puissance de la communauté collaborative GitLab. Grâce à une participation active aux heures de permanence communautaires, aux discussions sur Discord et aux sessions de pair-programming, Jose a trouvé un environnement de soutien qui l'a aidé à évoluer rapidement jusqu'au niveau 3 de contributeur, avec des contributions diverses allant de la [documentation](https://gitlab.com/gitlab-org/cli/-/merge_requests/2392) au [code](https://gitlab.com/gitlab-org/terraform-provider-gitlab/-/merge_requests/2690), en passant par le soutien communautaire.

La communauté GitLab offre un espace accueillant où les contributeurs se soutiennent mutuellement et grandissent ensemble. Que vous débutiez votre parcours open source ou que vous cherchiez à approfondir vos compétences, notre communauté est là pour vous aider à réussir.

Pour en savoir plus sur la contribution, consultez la [plateforme des contributeurs GitLab](https://contributors.gitlab.com/).

Merci, Jose, pour votre travail remarquable ! 🚀

## Fonctionnalités principales {#primary-features}

### GitLab Duo Planner, un agent spécialisé et membre de l'équipe Product Manager (version bêta) {#gitlab-duo-planner-a-specialized-agent-and-product-manager-team-member-beta}

<!-- categories: Portfolio Management -->

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com
- Modules complémentaires : Duo Core, Duo Pro, Duo Enterprise
- Liens : [Documentation](../../user/duo_agent_platform/agents/foundational_agents/planner.md) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/576618)

{{< /details >}}

Collaborez avec GitLab Duo Planner, un agent GitLab Duo conçu pour accompagner les chefs de produit directement dans GitLab. Au lieu de relancer manuellement pour obtenir des mises à jour, de prioriser le travail ou de résumer les données de planification, GitLab Duo Planner vous aide à analyser les backlogs, à appliquer des frameworks tels que RICE ou MoSCoW, et à identifier ce qui nécessite vraiment votre attention. C'est comme avoir un coéquipier proactif qui comprend votre workflow de planification et travaille avec vous pour prendre de meilleures décisions, plus rapidement. Cette fonctionnalité est actuellement en version bêta. Partagez vos commentaires dans le [ticket 576622](https://gitlab.com/gitlab-org/gitlab/-/issues/576622).

### GitLab Security Analyst Agent pour le catalogue Duo Agent (version bêta) {#gitlab-security-analyst-agent-for-duo-agent-catalog-beta}

<!-- categories: Vulnerability Management, Dependency Management -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com
- Modules complémentaires : Duo Core, Duo Pro, Duo Enterprise
- Liens : [Documentation](../../user/duo_agent_platform/agents/_index.md) \| [Epic associé](https://gitlab.com/groups/gitlab-org/-/epics/19659)

{{< /details >}}

Les agents de GitLab Duo Agent Platform peuvent être utilisés pour effectuer des tâches et répondre à des questions complexes dans GitLab. Les utilisateurs peuvent soit créer des agents personnalisés pour accomplir des tâches spécifiques, comme créer des merge requests ou réviser du code, soit découvrir les agents GitLab via le catalogue d'IA.

Dans GitLab 18.5, nous publions l'agent Security Analyst Agent GitLab en tant que fonctionnalité en version bêta, disponible dans le catalogue d'IA. Pour utiliser l'agent Security Analyst Agent GitLab dans des projets spécifiques, sélectionnez et activez l'agent dans GitLab Duo Agentic Chat. L'agent peut effectuer les tâches suivantes :

- Lister toutes les vulnérabilités d'un projet donné.
- Obtenir des informations détaillées sur les vulnérabilités, notamment les données CVE et les scores EPSS.
- Confirmer et rejeter des vulnérabilités.
- Mettre à jour les niveaux de gravité des vulnérabilités.
- Rétablir le statut d'une vulnérabilité à `detected`.
- Créer des tickets de vulnérabilité, ou associer des vulnérabilités à des tickets existants.

Avec l'agent Security Analyst Agent GitLab, les utilisateurs peuvent exécuter des workflows de sécurité fastidieux grâce à l'automatisation optimisée par l'IA et à l'analyse intelligente, permettant aux équipes d'ingénierie de se concentrer sur les menaces réelles pendant que l'agent Security Analyst Agent GitLab gère les évaluations et la documentation répétitives. Veuillez noter que l'agent Security Analyst Agent GitLab utilisant GitLab Duo Chat est uniquement disponible pour les clients Ultimate disposant du module complémentaire GitLab Duo.

Cette fonctionnalité est en version bêta, et nous vous invitons à partager vos retours dans le [ticket 576916](https://gitlab.com/gitlab-org/gitlab/-/issues/576916).

### Le registre virtuel Maven est désormais disponible en version bêta {#maven-virtual-registry-now-available-in-beta}

<!-- categories: Virtual Registry -->

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Liens : [Documentation](../../user/packages/virtual_registry/maven/_index.md#manage-virtual-registries) \| [Epic associé](https://gitlab.com/groups/gitlab-org/-/epics/14137)

{{< /details >}}

GitLab 18.5 introduit une interface web complète pour la gestion des registres virtuels Maven. Auparavant, les ingénieurs de plateforme ne pouvaient configurer et gérer les registres virtuels que via des appels d'API, ce qui rendait les tâches de maintenance courantes fastidieuses et nécessitait des connaissances spécialisées.

Cette approche web réduit considérablement la charge opérationnelle des équipes d'ingénierie de plateforme. Les tâches courantes, telles que la suppression des entrées de cache obsolètes, la réorganisation des sources amont pour optimiser les performances et le test de connectivité, sont désormais des opérations réalisables en quelques clics. Les équipes de développement bénéficient d'une meilleure visibilité sur leur configuration de dépendances, ce qui permet des discussions plus éclairées sur les performances de build et les politiques de sécurité.

Le registre virtuel Maven reste en version bêta pour les clients GitLab Premium et Ultimate. Les limitations actuelles de la version bêta incluent un maximum de 20 registres virtuels par groupe principal et 20 sources amont par registre virtuel.

Nous invitons les clients entreprise à participer au programme bêta du registre virtuel Maven pour contribuer à façonner la release finale. N'hésitez pas à partager vos commentaires et suggestions dans le [ticket 543045](https://gitlab.com/gitlab-org/gitlab/-/issues/543045).

### Reprenez là où vous vous étiez arrêté sur la nouvelle page d'accueil personnelle {#pick-up-where-you-left-off-on-the-new-personal-homepage}

<!-- categories: Navigation -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Liens : [Documentation](../../tutorials/personal_homepage/_index.md) \| [Epic associé](https://gitlab.com/groups/gitlab-org/-/epics/16657)

{{< /details >}}

Vous pouvez désormais accéder à une nouvelle page d'accueil personnelle qui regroupe toutes vos activités GitLab importantes en un seul endroit, facilitant la reprise de votre travail là où vous l'avez laissé. La page d'accueil rassemble vos éléments de la liste de tâches, les tickets qui vous sont assignés, les merge requests, les demandes de révision et le contenu consulté récemment, vous aidant à naviguer dans le vaste espace de GitLab et à rester concentré sur ce qui vous importe le plus.

### GPT-5 est désormais disponible comme option de modèle pour GitLab Duo Agentic Chat {#gpt-5-now-available-as-a-model-option-for-gitlab-duo-agentic-chat}

<!-- categories: Model Personalization -->

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Modules complémentaires : Duo Pro, Duo Enterprise
- Liens : [Documentation](../../user/gitlab_duo_chat/agentic_chat.md#select-a-model) \| [Epic associé](https://gitlab.com/groups/gitlab-org/-/epics/19124)

{{< /details >}}

OpenAI GPT-5 est désormais disponible en tant que modèle GitLab AI Vendor lors de la sélection d'un modèle pour GitLab Duo Agent Platform. Lorsqu'il est configuré par les propriétaires d'un groupe principal sur GitLab.com et les administrateurs d'instance sur Self-Managed et Dedicated, les utilisateurs finaux peuvent choisir d'utiliser GPT-5 avec les fonctionnalités GitLab Duo. Les propriétaires de groupe principal et les administrateurs peuvent continuer à définir les préférences de modèle à l'échelle de l'organisation via les paramètres d'espace de nommage ou d'instance, ou autoriser les utilisateurs finaux à choisir parmi tous les modèles GitLab AI Vendor disponibles.

Pour commencer à utiliser GPT-5, sélectionnez votre modèle préféré dans la liste déroulante des modèles dans GitLab Duo Chat.

### Gestion des politiques de conformité et de sécurité à l'échelle de l'instance {#instance-wide-compliance-and-security-policy-management}

<!-- categories: Compliance Management, Security Policy Management -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab Self-Managed, GitLab Dedicated
- Liens : [Documentation](../../security/compliance_security_policy_management.md)

{{< /details >}}

Les utilisateurs entreprise souhaitent gérer leurs [frameworks de conformité](../../user/compliance/compliance_frameworks/centralized_compliance_frameworks.md) et leurs [politiques de sécurité](../../user/application_security/policies/enforcement/compliance_and_security_policy_groups.md) dans plusieurs groupes principaux. C'est souvent le cas lorsque tous les groupes d'une instance :

- Partagent les mêmes cadres de conformité. Par exemple, lorsque tous les projets d'un groupe doivent adhérer à la norme ISO 27001.
- Appliquent des politiques de sécurité similaires. Par exemple, lorsque tous les groupes partagent la même politique d'exécution de pipeline.

Avec GitLab 18.5, nous introduisons des groupes de politiques de conformité et de sécurité pour centraliser la gestion des politiques de sécurité et des frameworks de conformité sur une instance pour les instances GitLab Self-Managed et Dedicated. Avec cette release, vous pouvez désormais créer, configurer et allouer des frameworks de conformité et des politiques de sécurité depuis un seul groupe principal et les appliquer à tous les autres groupes principaux de votre instance.

Avec un groupe de politiques de conformité et de sécurité, vous disposez d'une source unique de vérité pour gérer et modifier vos frameworks de conformité et vos politiques de sécurité. Les utilisateurs chargés de la sécurité et de la conformité au sein du groupe peuvent ensuite appliquer des frameworks de conformité et des politiques de sécurité à tous les projets de l'instance.

Les groupes de politiques de conformité et de sécurité facilitent la gestion et l'application de vos exigences de conformité et de sécurité à l'échelle de votre instance. Cependant, les groupes conservent toujours la capacité de créer leurs propres cadres de conformité et politiques de sécurité pour répondre à des situations ou des flux de travail spécifiques pouvant survenir dans ces groupes.

Cette fonctionnalité est destinée aux clients GitLab Self-Managed et Dedicated. Les clients GitLab.com peuvent gérer les frameworks et les politiques de manière centralisée au sein d'un seul groupe principal ou espace de nommage en utilisant des projets de politiques de sécurité.

En savoir plus sur les groupes de politiques de conformité et de sécurité pour les [frameworks de conformité](../../user/compliance/compliance_frameworks/centralized_compliance_frameworks.md) et les [politiques de sécurité](../../user/application_security/policies/enforcement/compliance_and_security_policy_groups.md).

### Scripts d'authentification DAST {#dast-authentication-scripts}

<!-- categories: DAST -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Liens : [Documentation](../../user/application_security/dast/browser/configuration/authentication_scripts.md) \| [Epic associé](https://gitlab.com/groups/gitlab-org/-/epics/17018)

{{< /details >}}

Vous pouvez désormais ajouter des scripts à vos configurations CI/CD pour automatiser les workflows d'authentification DAST. Les scripts d'authentification permettent d'automatiser des flux d'authentification complexes, notamment la prise en charge des mots de passe à usage unique basés sur le temps (OTP MFA).

Cette amélioration aide votre équipe à maintenir des contrôles de sécurité critiques tout en effectuant des analyses de sécurité automatisées et approfondies. En prenant en charge des scénarios d'authentification du monde réel, les scripts réduisent les frictions et garantissent des évaluations de sécurité précises des logiciels en production.

## Agentic Core {#agentic-core}

### Déclencheurs supplémentaires pour les agents CLI {#additional-triggers-for-cli-agents}

<!-- categories: Duo Agent Platform -->

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Modules complémentaires : Duo Enterprise
- Liens : [Documentation](../../user/duo_agent_platform/triggers/_index.md) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/567787)

{{< /details >}}

Vous pouvez désormais déclencher des agents CLI à l'aide d'événements supplémentaires pour bénéficier d'une plus grande flexibilité et d'un meilleur contrôle sur où et quand vos agents agissent dans vos projets. En plus du déclencheur **mention** existant, vous pouvez utiliser :

- **Assigner** : déclencher des agents lorsqu'une merge request ou un ticket est assigné.
- **Assigner un relecteur** : déclencher des agents lorsqu'un relecteur est ajouté à une merge request.

### GitLab Duo Agent Platform pour GitLab Duo Self-Hosted est désormais en version bêta {#gitlab-duo-agent-platform-for-gitlab-duo-self-hosted-now-in-beta}

<!-- categories: Self-Hosted Models -->

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed
- Modules complémentaires : Duo Enterprise
- Liens : [Documentation](../../administration/gitlab_duo_self_hosted/configure_duo_features.md#configure-access-to-the-gitlab-duo-agent-platform) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/558083)

{{< /details >}}

GitLab Duo Agent Platform est désormais en version bêta pour GitLab Duo Self-Hosted. Cette fonctionnalité est disponible pour tous les clients Self-Managed GitLab Duo Enterprise. Les administrateurs d'instance Self-Managed utilisant AWS Bedrock ou Azure OpenAI peuvent configurer les modèles Anthropic Claude ou OpenAI GPT pour une utilisation avec GitLab Duo Agent Platform. Les administrateurs Self-Hosted peuvent également configurer

[les modèles compatibles](../../administration/gitlab_duo_self_hosted/supported_models_and_hardware_requirements.md#compatible-models)

pour une utilisation avec GitLab Duo Agent Platform.

### Codestral est désormais pris en charge pour GitLab Duo Chat (Classic) {#codestral-now-supported-for-gitlab-duo-chat-classic}

<!-- categories: Self-Hosted Models -->

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed
- Modules complémentaires : Duo Enterprise
- Liens : [Documentation](../../administration/gitlab_duo_self_hosted/supported_models_and_hardware_requirements.md#supported-models) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/550266)

{{< /details >}}

Vous pouvez désormais utiliser Mistral Codestral sur

GitLab Duo Self-Hosted

pour Duo Chat classic. Ce modèle est pris en charge pour les clients GitLab Duo Self-Hosted sur des instances GitLab Self-Managed.

### Les modèles GPT OSS compatibles avec GitLab Duo Agent Platform pour GitLab Duo Self-Hosted {#gpt-oss-models-compatible-with-gitlab-duo-agent-platform-for-gitlab-duo-self-hosted}

<!-- categories: Self-Hosted Models -->

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed
- Modules complémentaires : Duo Enterprise
- Liens : [Documentation](../../administration/gitlab_duo_self_hosted/supported_models_and_hardware_requirements.md#compatible-models) \| [Epic associé](https://gitlab.com/groups/gitlab-org/-/epics/19348)

{{< /details >}}

Vous pouvez désormais utiliser les modèles GPT OSS sur GitLab Duo Agent Platform avec GitLab Duo Self-Hosted.

## Mise à l'échelle et déploiements {#scale-and-deployments}

### Liste des groupes de la zone **Admin** améliorée {#enhanced-admin-area-groups-list}

<!-- categories: Groups & Projects -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed, GitLab Dedicated
- Liens : [Documentation](../../administration/admin_area.md#administering-groups) \| [Epic associé](https://gitlab.com/groups/gitlab-org/-/epics/17783)

{{< /details >}}

Nous avons amélioré la liste des groupes de la zone **Admin** pour offrir une expérience plus cohérente aux administrateurs GitLab :

- Protection contre la suppression différée : les suppressions de groupes suivent désormais le même flux de suppression sécurisée utilisé dans tout GitLab, évitant ainsi les pertes de données accidentelles.
- Interactions plus rapides : filtrez, triez et parcourez les groupes sans rechargement de page pour une expérience plus réactive.
- Interface cohérente : la liste des groupes correspond désormais à l'apparence et au comportement des autres listes de groupes dans GitLab.

Cette mise à jour aligne l'expérience administrateur sur les standards de conception de GitLab et ajoute d'importantes fonctionnalités de sécurité pour protéger vos données. Les futures améliorations de la gestion des groupes apparaîtront automatiquement dans toutes les listes de groupes de la plateforme.

### Expérience de navigation mise à jour pour les groupes {#updated-navigation-experience-for-groups}

<!-- categories: Groups & Projects -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Liens : [Documentation](../../user/group/_index.md#view-a-group) \| [Epic associé](https://gitlab.com/groups/gitlab-org/-/epics/13790)

{{< /details >}}

Nous avons apporté des modifications à la liste de vue d'ensemble des groupes pour offrir une expérience plus cohérente et efficace dans GitLab. Ces améliorations facilitent la navigation dans vos groupes et projets tout en fournissant des informations plus précieuses en un coup d'œil :

- Informations de projet enrichies : les projets affichent désormais les étoiles, les duplications, les tickets, les merge requests et les dates pertinentes, vous donnant un aperçu complet de l'activité en un coup d'œil.
- Actions simplifiées : modifiez ou supprimez des groupes et des projets directement depuis la vue d'ensemble à l'aide du menu d'actions. Les éléments archivés et en attente de suppression apparaissent dans l'onglet **Inactif**.
- Expérience cohérente : la vue d'ensemble des groupes correspond désormais à l'apparence et au comportement des autres listes de groupes et de projets dans GitLab pour une expérience plus intuitive.

Ces améliorations vous font gagner du temps en mettant plus d'informations et d'actions à portée de main. Cette mise à jour prépare également le terrain pour de futures fonctionnalités telles que l'édition en masse et les options de filtrage avancées.

### Amélioration de la gestion des éléments inactifs pour les groupes et les projets {#improved-inactive-item-management-for-groups-and-projects}

<!-- categories: Groups & Projects -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Liens : [Documentation](../../user/project/working_with_projects.md#view-inactive-projects) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/526211)

{{< /details >}}

L'onglet **Inactif** affiche désormais de manière cohérente tous les éléments inactifs en un emplacement unifié dans GitLab. Cela inclut les projets archivés, les projets en attente de suppression et les groupes en attente de suppression. Cet onglet est disponible sur la page de vue d'ensemble des groupes, ainsi que dans les listes de groupes et de projets dans **Votre travail**, **Explorer** et la zone **Admin**. Tous les utilisateurs disposant des autorisations appropriées peuvent consulter les éléments inactifs, tandis que seuls les propriétaires de groupes et les propriétaires et mainteneurs de projets peuvent effectuer des actions supplémentaires sur ces éléments. Dans le cadre de cette mise à jour, un nouveau paramètre `active` est désormais disponible dans les API REST Projects et Groups, ainsi que dans les API GraphQL.

La gestion du contenu inactif est une partie essentielle de la maintenance d'une instance GitLab. Cette mise à jour facilite la recherche et la récupération du contenu archivé ou en attente de suppression, vous permettant de mieux contrôler vos ressources GitLab tout en réduisant le risque de perdre accidentellement un travail de valeur. La séparation claire du contenu actif et inactif offre également une expérience de recherche plus ciblée lors de la navigation dans les groupes et projets de toutes les zones de GitLab.

## DevOps et sécurité unifiés {#unified-devops-and-security}

### Nouvelles fonctionnalités de gestion des vulnérabilités dans GitLab Duo Agentic Chat {#new-vulnerability-management-features-in-gitlab-duo-agentic-chat}

<!-- categories: Vulnerability Management, Dependency Management -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Modules complémentaires : Duo Core, Duo Pro, Duo Enterprise
- Liens : [Documentation](../../user/gitlab_duo_chat/agentic_chat.md) \| [Epic associé](https://gitlab.com/groups/gitlab-org/-/epics/19639)

{{< /details >}}

GitLab Duo Agentic Chat est une version améliorée de GitLab Duo Chat. Il recherche, récupère et combine des informations provenant de plusieurs sources dans vos projets GitLab pour fournir des réponses plus complètes et pertinentes. Parmi ses cas d'utilisation, on trouve notamment la capacité à rechercher dans des projets, à lire et lister des fichiers, et à créer et modifier des fichiers de manière autonome en fonction de la demande soumise à GitLab Duo Chat.

Dans GitLab 18.5, le cas d'utilisation d'Agentic Chat s'étend pour inclure la gestion des vulnérabilités de vos analyseurs de sécurité. En ajoutant des outils de gestion des vulnérabilités à Agentic Chat, cela transforme les workflows de sécurité fastidieux grâce à l'automatisation optimisée par l'IA et à l'analyse intelligente, permettant aux professionnels de la sécurité de trier, gérer et remédier efficacement aux vulnérabilités via des commandes en langage naturel. Cela élimine des heures de clics manuels dans les tableaux de bord de vulnérabilités et simplifie les opérations de masse complexes qui nécessitaient auparavant des scripts personnalisés ou un travail manuel fastidieux.

Avec les nouveaux outils de gestion des vulnérabilités ajoutés à GitLab Duo Chat, les utilisateurs Ultimate disposant de GitLab Duo peuvent effectuer les opérations suivantes :

- Lister toutes les vulnérabilités d'un projet donné.
- Obtenir des informations détaillées sur les vulnérabilités, notamment les données CVE et les scores EPSS.
- Confirmer et rejeter des vulnérabilités.
- Mettre à jour les niveaux de gravité des vulnérabilités.
- Rétablir le statut d'une vulnérabilité à `detected`.
- Créer des tickets de vulnérabilité, ou associer des vulnérabilités à des tickets existants.

Ces outils transforment les workflows de sécurité, passant d'un tri manuel réactif à une remédiation intelligente, permettant aux ingénieurs de se concentrer sur les menaces réelles pendant que l'IA gère les évaluations et la documentation répétitives. La gestion des vulnérabilités via GitLab Duo Chat est uniquement disponible pour les clients Ultimate disposant du module complémentaire GitLab Duo.

### Prise en charge de C/C++ pour Advanced SAST {#cc-support-for-advanced-sast}

<!-- categories: SAST -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Liens : [Documentation](../../user/application_security/sast/advanced_sast_cpp.md)

{{< /details >}}

Nous avons ajouté la prise en charge en version bêta de C/C++ pour GitLab Advanced SAST.

Pour utiliser cette nouvelle prise en charge de l'analyse inter-fichiers et inter-fonctions, [activez la prise en charge de C/C++](../../user/application_security/sast/advanced_sast_cpp.md).

Nous accueillons avec plaisir vos retours sur cette fonctionnalité. Si vous avez des questions, des commentaires ou souhaitez échanger avec notre équipe, consultez ce [ticket de feedback](https://gitlab.com/gitlab-org/gitlab/-/issues/575671).

### Les vérifications de validité des secrets sont en version bêta {#secret-validity-checks-is-in-beta}

<!-- categories: Secret Detection -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/application_security/vulnerabilities/validity_check.md) \| [Epic associé](https://gitlab.com/groups/gitlab-org/-/epics/16927)

{{< /details >}}

La détection des secrets de pipeline vous alerte des identifiants exposés, tels que les mots de passe ou les clés API, dans vos projets. Cependant, jusqu'à GitLab 18.5, vous deviez vérifier manuellement si chaque détection représentait un jeton actif. Cela pouvait rendre le tri efficace des détections difficile et chronophage.

Maintenant que les vérifications de validité sont en version bêta, activez-les pour afficher le statut des secrets GitLab détectés. Les secrets actifs peuvent être utilisés pour usurper une activité légitime, il convient donc de les renouveler dès que possible. Pour voir les vérifications de validité en action, consultez la [playlist des vérifications de validité](https://www.youtube.com/playlist?list=PL05JrBw4t0Ko8uOgubcYqmTTMGs0zWQRt).

### Couverture accrue des règles pour la protection contre les push de secrets et la détection des secrets dans les pipelines {#increased-rule-coverage-for-secret-push-protection-and-pipeline-secret-detection}

<!-- categories: Secret Detection -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Liens : [Documentation](../../user/application_security/secret_detection/detected_secrets.md) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/573973)

{{< /details >}}

De nouvelles règles ont été ajoutées à la détection des secrets de pipeline GitLab. Certaines règles existantes ont également été mises à jour pour améliorer la qualité et réduire les faux positifs. Ces modifications sont publiées dans la [version 7.15.0](https://gitlab.com/gitlab-org/security-products/analyzers/secrets/-/releases/v7.15.0) de l'analyseur de secrets.

### Logique de détection personnalisable pour Advanced SAST {#customizable-detection-logic-for-advanced-sast}

<!-- categories: SAST -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Liens : [Documentation](../../user/application_security/sast/customize_rulesets.md)

{{< /details >}}

Vous pouvez désormais créer des règles de détection de sécurité personnalisées adaptées aux exigences de sécurité spécifiques de votre organisation et à vos modèles de codage avec GitLab Advanced SAST. Cette fonctionnalité permet à vos équipes de sécurité de définir des modèles de vulnérabilités personnalisés au-delà de l'ensemble de règles prédéfini, leur permettant de détecter des problèmes de sécurité spécifiques aux applications.

Pour plus d'informations, consultez [Personnaliser les ensembles de règles](../../user/application_security/sast/customize_rulesets.md).

### Analyse différentielle Advanced SAST dans les merge requests {#advanced-sast-diff-based-scanning-in-merge-requests}

<!-- categories: SAST -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/application_security/sast/gitlab_advanced_sast.md#diff-based-scanning)

{{< /details >}}

Vous pouvez désormais effectuer des analyses différentielles qui n'analysent que les modifications de code dans une merge request avec GitLab Advanced SAST, réduisant considérablement les durées d'analyse par rapport aux analyses complètes du dépôt. En n'analysant que le diff Git plutôt que l'ensemble de la base de code, vos équipes peuvent intégrer les tests de sécurité de manière plus fluide dans leur workflow de développement sans sacrifier la vitesse ni ajouter des frictions au processus de merge request.

Nous travaillons à activer cette amélioration des performances par défaut ; cela est suivi dans le [ticket 546359](https://gitlab.com/gitlab-org/gitlab/-/issues/546359).

### Contrôle des requêtes pour les statuts de contrôle externe {#control-requests-for-external-control-statuses}

<!-- categories: Compliance Management -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Liens : [Documentation](../../user/compliance/compliance_frameworks/_index.md#ping-enabled-setting) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/521757)

{{< /details >}}

Des contrôles externes peuvent être associés aux exigences lors de la création de frameworks de conformité dans GitLab.

Par défaut, GitLab demande automatiquement le statut des contrôles externes aux systèmes externes toutes les 12 heures lors des analyses de conformité, en définissant le statut du contrôle sur « pending ». Les systèmes externes répondent ensuite en utilisant l'API des contrôles externes pour mettre à jour le statut sur « pass » ou « fail ».

Dans GitLab 18.5, vous pouvez désormais désactiver ce ping automatique de 12 heures en désactivant le paramètre **Ping enabled** lors de la configuration des contrôles externes. Lorsque le ping de 12 heures est désactivé :

- GitLab ne demande plus automatiquement les mises à jour de statut aux systèmes externes.
- Le contrôle externe affiche un badge **Désactivé** dans l'interface du framework de conformité.
- Vous avez un contrôle total sur le moment où les statuts des contrôles externes sont mis à jour via l'API des contrôles externes.

Cela empêche le système de réinitialiser les statuts des contrôles externes sur « pending » et vous donne un contrôle total sur le moment des mises à jour de statut.

### Analyse des dépendances en disponibilité limitée {#dependency-scanning-in-limited-availability}

<!-- categories: Software Composition Analysis -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Liens : [Documentation](../../user/application_security/dependency_scanning/dependency_scanning_sbom/_index.md) \| [Epic associé](https://gitlab.com/groups/gitlab-org/-/epics/15961)

{{< /details >}}

Dans GitLab 18.5, nous avons publié un nouveau template d'analyse des dépendances qui fonctionne avec l'analyseur d'analyse des dépendances. L'analyseur génère désormais un rapport d'analyse des dépendances contenant toutes les vulnérabilités des composants. La politique d'exécution de scan (SEP) et la politique d'exécution de pipeline (PEP) prennent en charge le nouveau template.

Pour utiliser le nouveau template, importez `Jobs/Dependency-Scanning.v2.gitlab-ci.yml`.

Cette fonctionnalité est disponible sur GitLab.com et les instances auto-hébergées, bien qu'elle soit marquée comme disponibilité limitée car la prise en charge officielle pour les instances auto-hébergées n'est pas encore disponible. Les utilisateurs de GitLab.com peuvent l'utiliser immédiatement.

Nous accueillons avec plaisir vos retours sur cette fonctionnalité. Si vous avez des questions, des commentaires ou souhaitez échanger avec notre équipe, consultez ce [ticket de feedback](https://gitlab.com/gitlab-org/gitlab/-/issues/523458).

### Expansion des variables dans l'environnement `deployment_tier` {#variable-expansion-in-environment-deployment_tier}

<!-- categories: Environment Management -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Liens : [Documentation](../../ci/yaml/_index.md#environmentdeployment_tier) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/365402)

{{< /details >}}

Vous pouvez désormais utiliser des variables CI/CD dans le champ `environment:deployment_tier`, ce qui facilite la configuration dynamique des niveaux de déploiement en fonction des conditions du pipeline.

### Configurer les cycles de vie des statuts pour les tickets et les tâches {#configure-status-lifecycles-for-issues-and-tasks}

<!-- categories: Team Planning -->

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Liens : [Documentation](../../user/work_items/status.md#lifecycles) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/555528)

{{< /details >}}

Auparavant, les tickets et les tâches devaient partager le même ensemble de statuts configurés. Dans cette release, nous avons ajouté la prise en charge de la configuration des cycles de vie des statuts, vous permettant de définir des workflows distincts pour les tickets et les tâches dans vos projets. Grâce au mappage des statuts intégré dans le workflow, vous pouvez faire passer un ticket ou une tâche vers un nouvel ensemble de statuts de manière transparente, sans nécessiter d'édition en masse lors du changement de types d'éléments de travail.

Partagez vos retours et aidez-nous à améliorer la fonctionnalité en [contribuant à notre ticket de feedback](https://gitlab.com/gitlab-com/www-gitlab-com/-/issues/35235) avec vos cas d'utilisation et vos suggestions.

### Formater les tableaux Markdown dans l'éditeur de texte brut {#format-markdown-tables-in-the-plain-text-editor}

<!-- categories: Markdown -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Liens : [Documentation](../../user/markdown.md#tables)

{{< /details >}}

Les tableaux Markdown mal alignés sont difficiles à lire et à modifier, même s'ils s'affichent correctement.

La nouvelle fonctionnalité **Reformater le tableau** dans la barre d'outils de l'éditeur de texte brut réaligne les colonnes du tableau en un seul clic, en préservant les paramètres d'alignement et l'indentation. Pour l'utiliser :

- Sélectionnez un tableau Markdown dans des pages wiki, des tickets ou des merge requests.
- Dans le menu **Plus d'options**, sélectionnez **Reformater le tableau**.

Cela accélère la maintenance de la documentation et facilite la collaboration lors de travaux sur des tableaux complexes.

### Afficher la progression des tâches enfants dans les tickets {#view-child-task-completion-in-issues}

<!-- categories: Team Planning -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Liens : [Documentation](../../user/tasks.md#view-tasks) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/520886)

{{< /details >}}

Vous pouvez désormais suivre la progression des tickets directement depuis le widget des éléments enfants, vous donnant un aperçu du statut en un coup d'œil. Cette amélioration offre une visibilité en temps réel sur les goulots d'étranglement potentiels lorsque le travail est déjà en cours, vous aidant à identifier rapidement les éléments à risque et à effectuer des ajustements opportuns avant que les délais de sprint ne soient menacés.

### Exposer la gravité originale depuis l'API des vulnérabilités {#expose-original-severity-from-the-vulnerabilities-api}

<!-- categories: Vulnerability Management -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Liens : [Documentation](../../api/graphql/reference/_index.md#pipelinesecurityreportfinding) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/557940)

{{< /details >}}

L'API GraphQL des vulnérabilités expose désormais la gravité originale des vulnérabilités. Cela vous permet de déterminer quelle était la gravité de la vulnérabilité avant l'application des remplacements de gravité.

### Fenêtres de temps pour les politiques d'approbation des merge requests {#time-windows-for-merge-request-approval-policies}

<!-- categories: Security Policy Management -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Liens : [Documentation](../../user/application_security/policies/merge_request_approval_policies.md#security_report_time_window) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/525509)

{{< /details >}}

Pour offrir plus de flexibilité dans les comparaisons de vulnérabilités de sécurité, nous avons introduit des fenêtres de temps dans les politiques d'approbation des merge requests. Si les rapports de sécurité pour la baseline la plus récente ne sont pas encore disponibles, cette nouvelle configuration de politique vous permet d'utiliser des rapports de sécurité précédemment complétés, à condition que les rapports ne soient pas plus anciens que la durée que vous spécifiez comme fenêtre de temps.

Les équipes de développement peuvent désormais éviter des délais inutiles lorsque les analyses de sécurité de baseline sont bloquées ou prennent trop de temps, notamment dans les projets très actifs. En configurant une fenêtre de temps, les merge requests qui n'introduisent pas de nouvelles vulnérabilités peuvent avancer sans attendre la fin du dernier pipeline, améliorant ainsi l'efficacité du workflow.

Pour utiliser cette fonctionnalité, créez ou modifiez une politique d'approbation des merge requests et spécifiez le paramètre `security_report_time_window` (en minutes) dans votre configuration de politique d'approbation

Le système comparera les résultats de sécurité de votre merge request avec le dernier pipeline en utilisant les rapports de sécurité créés dans la fenêtre de temps spécifiée, permettant des approbations plus rapides lorsqu'aucune nouvelle vulnérabilité n'est introduite.

### Statuts des résultats de sécurité actualisés dans l'onglet **Sécurité** du pipeline {#refreshed-security-finding-statuses-in-the-pipeline-security-tab}

<!-- categories: Vulnerability Management -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Liens : [Documentation](../../user/application_security/detect/security_scanning_results.md#change-status) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/554078)

{{< /details >}}

Auparavant, dans l'onglet **Sécurité** d'un pipeline, si vous rejetiez une vulnérabilité, celle-ci n'était pas immédiatement supprimée de la liste.

Les mises à jour de statut dans l'onglet de sécurité d'une page de pipeline sont désormais actualisées après leur modification.

### Exceptions pour contourner les politiques d'approbation des merge requests {#exceptions-to-bypass-merge-request-approval-policies}

<!-- categories: Security Policy Management -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Liens : [Documentation](../../user/application_security/policies/merge_request_approval_policies.md) \| [Epic associé](https://gitlab.com/groups/gitlab-org/-/epics/18114)

{{< /details >}}

Les organisations peuvent désormais désigner des utilisateurs, des groupes, des rôles ou des rôles personnalisés spécifiques qui peuvent contourner les politiques d'approbation des merge requests en cas de situations critiques. Cette capacité offre une flexibilité pour les réponses d'urgence, tout en maintenant des pistes d'audit complètes et des contrôles de gouvernance.

**Emergency bypass with accountability** : les utilisateurs désignés peuvent contourner les exigences d'approbation lors d'incidents critiques, de correctifs de sécurité ou de problèmes de production urgents. En cas d'urgence, le personnel autorisé peut fusionner ou pousser des modifications immédiatement pendant que le système capture la justification détaillée et les informations d'audit pour examen de conformité.

Les principales fonctionnalités incluent :

- **Documented bypass process** : lorsque des utilisateurs autorisés invoquent un contournement de politique, ils doivent fournir un raisonnement détaillé à l'aide d'une interface modale intuitive, garantissant que chaque exception est correctement documentée avec son contexte.
- **Comprehensive audit integration** : chaque contournement génère des événements d'audit détaillés incluant l'identité de l'utilisateur, le contexte de la politique, le raisonnement et les horodatages pour une visibilité complète des modèles d'utilisation des exceptions.
- **Flexible configuration** : définissez des autorisations d'exception pour les politiques à l'aide de la configuration YAML ou de l'interface utilisateur, en prenant en charge les utilisateurs individuels, les groupes GitLab, les rôles standard et les rôles personnalisés.
- **Git-based push exceptions** : les utilisateurs disposant d'exceptions de politique pré-approuvées peuvent pousser directement en invoquant l'option de contournement de push `security_policy.bypass_reason`.

Cette fonctionnalité élimine la nécessité de désactiver entièrement les politiques de sécurité lors des urgences, offrant une voie contrôlée pour les modifications urgentes tout en préservant la gouvernance organisationnelle et les exigences d'audit.

### Afficher uniquement les vulnérabilités actives dans la liste des dépendances {#show-only-active-vulnerabilities-in-the-dependency-list}

<!-- categories: Dependency Management -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Liens : [Documentation](../../user/application_security/dependency_list/_index.md#vulnerabilities) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/353487)

{{< /details >}}

Auparavant, la liste des dépendances incluait certaines vulnérabilités rejetées.

Pour vous fournir une représentation plus utile des vulnérabilités dans la liste des dépendances, la liste des dépendances du projet n'inclut désormais que les vulnérabilités actives dans les états `detected` et `confirmed`.

### Accessibilité statique en disponibilité limitée et prise en charge expérimentale de Java {#static-reachability-in-limited-availability-and-experimental-java-support}

<!-- categories: Software Composition Analysis -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Liens : [Documentation](../../user/application_security/dependency_scanning/static_reachability.md) \| [Epic associé](https://gitlab.com/groups/gitlab-org/-/epics/15780)

{{< /details >}}

Dans GitLab 18.5, nous avons publié une prise en charge en disponibilité limitée pour l'accessibilité statique. Cette release se concentre sur l'amélioration de la prise en charge de la couverture JS/TS, la correction de bugs et la fourniture d'une prise en charge expérimentale de Java. L'accessibilité statique enrichit les résultats de l'analyse de composition logicielle (SCA) en analysant le code source du projet pour identifier les dépendances open source utilisées. Les données produites par l'accessibilité statique peuvent être utilisées dans le cadre de la prise de décision de tri et de remédiation des utilisateurs. Les données d'accessibilité statique peuvent également être utilisées avec les scores CVSS et EPSS, ainsi que les indicateurs KEV pour fournir une vue plus ciblée des vulnérabilités identifiées.

Nous accueillons avec plaisir vos retours sur cette fonctionnalité. Si vous avez des questions, des commentaires ou souhaitez échanger avec notre équipe, consultez ce [ticket de feedback](https://gitlab.com/gitlab-org/gitlab/-/issues/535498).

### GitLab Runner 18.5 {#gitlab-runner-185}

<!-- categories: GitLab Runner Core -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Liens : [Documentation](https://docs.gitlab.com/runner) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/38976)

{{< /details >}}

Nous publions également GitLab Runner 18.5 aujourd'hui ! GitLab Runner est l'agent de build hautement évolutif qui exécute vos jobs CI/CD et envoie les résultats à une instance GitLab. GitLab Runner fonctionne en conjonction avec GitLab CI/CD, le service d'intégration continue open source inclus avec GitLab.

Correctifs de bugs :

- [La mise à jour du runner échoue sur Kubernetes vanilla après la mise à jour de l'opérateur runner de 1.39 à 1.41](https://gitlab.com/gitlab-org/gl-openshift/gitlab-runner-operator/-/issues/259)
- [Certains labels de conteneur ont des préfixes dupliqués](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/38674)

La liste de toutes les modifications se trouve dans le [CHANGELOG](https://gitlab.com/gitlab-org/gitlab-runner/blob/18-5-stable/[CHANGELOG](https://gitlab.com/gitlab-org/gitlab-runner/blob/18-5-stable/CHANGELOG.md).md) de GitLab Runner.

## Sujets connexes {#related-topics}

- [Correctifs de bugs](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=type%3A%3Abug&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=18.5)
- [Améliorations des performances](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=bug%3A%3Aperformance&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=18.5)
- [Améliorations de l'interface utilisateur](https://papercuts.gitlab.com/?milestone=18.5)
- [Dépréciations et suppressions](../../update/deprecations.md)
- [Notes de mise à niveau](../../update/versions/_index.md)
