---
stage: Release Notes
group: Monthly Release
date: 2025-04-17
title: "Notes de release de GitLab 17.11"
description: "GitLab 17.11 est disponible avec la personnalisation des frameworks de conformité grâce aux exigences et aux contrôles de conformité"
---

<!-- markdownlint-disable -->
<!-- vale off -->

Le 17 avril 2025, GitLab 17.11 a été lancé avec les fonctionnalités suivantes.

Nous souhaitons également remercier tous nos contributeurs, dont le contributeur remarquable de ce mois-ci.

## Contributeur notable du mois : Heidi Berry {#this-months-notable-contributor-heidi-berry}

Pour la version 17.11, nous sommes ravis de désigner [Heidi Berry](https://gitlab.com/heidi.berry) comme contributrice notable !

Heidi s'est démarquée en tant que contributrice pour les projets [GitLab Terraform Provider](https://gitlab.com/gitlab-org/terraform-provider-gitlab) et [client-go](https://gitlab.com/gitlab-org/api/client-go). Au cours des dernières releases, elle a régulièrement livré des fonctionnalités très demandées, notamment la possibilité d'utiliser des [rôles personnalisés avec des liens SAML de groupe](https://gitlab.com/gitlab-org/terraform-provider-gitlab/-/merge_requests/1949), la prise en charge de la définition des [valeurs par défaut de protection de branche pour les groupes](https://gitlab.com/gitlab-org/terraform-provider-gitlab/-/merge_requests/2113) et la [rotation automatique des jetons pour les jetons de compte de service](https://gitlab.com/gitlab-org/terraform-provider-gitlab/-/merge_requests/2206).

Au-delà du développement de fonctionnalités, Heidi a joué un rôle déterminant dans les activités de maintenance, notamment en [contribuant à l'affinage du backlog des tickets](https://gitlab.com/gitlab-org/terraform-provider-gitlab/-/issues/1035#note_2305643918), en [mettant à jour d'anciens tests pour améliorer leur lisibilité](https://gitlab.com/gitlab-org/terraform-provider-gitlab/-/merge_requests/2298) et en [enrichissant la documentation avec de meilleurs exemples](https://gitlab.com/gitlab-org/terraform-provider-gitlab/-/merge_requests/2201). Ses contributions à client-go sont particulièrement précieuses, car cette bibliothèque alimente de nombreux projets en aval utilisés par les clients et GitLab pour interagir avec GitLab, notamment le provider Terraform et glab.

« Si vous avez toujours voulu vous essayer à la contribution open source, essayez client-go et terraform-provider-GitLab », dit Heidi. « Ils disposent d'une excellente documentation pour vous aider à démarrer, et de mainteneurs bienveillants prêts à vous aider. J'ai apprécié utiliser ces projets pour apprendre le langage Go de manière pratique. »

Heidi a été nommée par un autre contributeur de la communauté, [Patrick Rice](https://gitlab.com/PatrickRice), architecte d'entreprise chez Kingland et membre de l'équipe Core de la communauté GitLab. Patrick déclare : « Avec plus de 100 contributions fusionnées sur le cycle de la release 17 et de nombreux commentaires sur les tickets, Heidi a été d'une grande aide pour GitLab et Terraform. Merci infiniment pour vos contributions ! »

« Heidi fait un travail phénoménal », a déclaré [Timo Furrer](https://gitlab.com/timofurrer), ingénieur backend senior dans l'équipe Deploy::Environments chez GitLab. « Elle fait régulièrement des efforts supplémentaires et implémente le code SDK nécessaire dans client-go. Heidi ne se contente pas de contribuer beaucoup de code, elle aide également au triage des tickets. C'est une aide immense et c'est la raison pour laquelle des projets portés par la communauté comme ceux-ci peuvent perdurer. »

Heidi est ingénieure logicielle principale chez The Co-operative Group, où elle contribue à rendre l'expérience des développeurs efficace, sécurisée et aussi fluide que possible.

Merci, Heidi, pour vos formidables contributions à GitLab !

## Fonctionnalités principales {#primary-features}

### Personnaliser les frameworks de conformité avec des exigences et des contrôles de conformité {#customize-compliance-frameworks-with-requirements-and-compliance-controls}

<!-- categories: Compliance Management -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/compliance/compliance_center/compliance_status_report.md)

{{< /details >}}

Auparavant, les frameworks de conformité dans GitLab pouvaient être créés sous forme de label pour identifier que votre projet présente certaines exigences de conformité ou nécessite une supervision supplémentaire. Ce label pouvait ensuite être utilisé comme mécanisme de périmètre pour s'assurer que les politiques de sécurité pouvaient être appliquées à tous les projets d'un groupe.

Dans cette release, nous introduisons une nouvelle façon pour les responsables de la conformité d'obtenir un suivi de conformité plus approfondi dans GitLab grâce aux « exigences ».

Grâce aux exigences, dans le cadre d'un framework de conformité personnalisé, vous pouvez définir des exigences spécifiques issues d'un certain nombre de normes de conformité, de lois et de réglementations différentes que l'organisation doit respecter.

Nous élargissons également le nombre de contrôles de conformité (anciennement appelés vérifications de conformité) que nous proposons, passant de cinq à plus de 50 ! Ces 50 contrôles prêts à l'emploi (OOTB) peuvent être associés aux exigences du framework de conformité.

Ces contrôles vérifient des paramètres spécifiques de projet, de sécurité et de merge request sur votre instance GitLab pour vous aider à répondre aux exigences de différentes normes de conformité, lois et réglementations telles que SOC2, NIST, ISO 27001 et le benchmark GitLab CIS.

La conformité à ces contrôles est reflétée dans le rapport de conformité standard, qui a été repensé pour prendre en compte les exigences et la correspondance des contrôles avec celles-ci.

En plus d'élargir nos contrôles OOTB, nous permettons désormais aux utilisateurs d'associer des exigences à des contrôles externes, qui peuvent concerner des éléments, des programmes ou des systèmes existant en dehors de la plateforme GitLab. Ces correspondances vous permettent d'utiliser le centre de conformité GitLab comme source unique de vérité pour votre suivi de conformité et vos besoins en preuves d'audit.

### Plugin GitLab Eclipse disponible en version bêta {#gitlab-eclipse-plugin-available-in-beta}

<!-- categories: Editor Extensions -->

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Modules complémentaires : Duo Pro, Duo Enterprise
- Liens : [Documentation](https://docs.gitlab.com/editor_extensions/eclipse/setup/) \| [Epic associé](https://gitlab.com/groups/gitlab-org/editor-extensions/-/epics/89)

{{< /details >}}

Nous sommes ravis d'annoncer la sortie en version bêta du plugin GitLab Eclipse, désormais disponible sur l'[Eclipse Marketplace](https://marketplace.eclipse.org/content/gitlab-eclipse). Ce puissant nouveau plugin intègre les fonctionnalités Duo de GitLab directement dans votre IDE Eclipse, vous offrant un accès transparent à Duo Chat et aux suggestions de code alimentées par l'IA.

Le plugin étant actuellement en version bêta, nous améliorons activement les fonctionnalités, notamment en élargissant les options d'authentification et en affinant l'expérience utilisateur finale. Vos retours sont précieux. Partagez vos impressions pour nous aider à améliorer encore le plugin GitLab Eclipse en ajoutant vos retours [dans le ticket 162](https://gitlab.com/gitlab-org/editor-extensions/gitlab-eclipse-plugin/-/issues/162).

### Plus de fonctionnalités GitLab Duo désormais disponibles sur GitLab Duo Self-Hosted {#more-gitlab-duo-features-now-available-on-gitlab-duo-self-hosted}

<!-- categories: Self-Hosted Models -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab Self-Managed
- Modules complémentaires : Duo Enterprise
- Liens : [Documentation](../../administration/gitlab_duo_self_hosted/_index.md#feature-versions-and-status) \| [Epic associé](https://gitlab.com/groups/gitlab-org/-/epics/17072)

{{< /details >}}

Vous pouvez désormais utiliser davantage de fonctionnalités [GitLab Duo](https://about.gitlab.com/gitlab-duo/) avec GitLab Duo Self-Hosted dans votre instance GitLab Self-Managed. Les fonctionnalités suivantes sont disponibles en version bêta :

- [Root Cause Analysis](../../user/gitlab_duo_chat/examples.md#troubleshoot-failed-cicd-jobs-with-root-cause-analysis)
- [Vulnerability Explanation](../../user/application_security/analyze/duo.md)
- [Vulnerability Resolution](../../user/application_security/vulnerabilities/_index.md#vulnerability-resolution)
- [AI Impact Dashboard](../../user/analytics/duo_and_sdlc_trends.md)
- [Discussion Summary](../../user/discussions/_index.md#summarize-issue-discussions-with-gitlab-duo-chat)
- [Merge Request Commit Message](../../user/project/merge_requests/duo_in_merge_requests.md#generate-a-merge-commit-message)
- [Merge Request Summary](../../user/project/merge_requests/duo_in_merge_requests.md#generate-a-description-by-summarizing-code-changes)
- [GitLab Duo for the CLI](https://docs.gitlab.com/editor_extensions/gitlab_cli/#gitlab-duo-for-the-cli)

[Code Review Summary](../../user/project/merge_requests/duo_in_merge_requests.md#summarize-a-code-review) est également disponible sur GitLab Duo Self-Hosted en version expérimentale.

### Marketplace d'extensions pour le Web IDE sur les instances self-managed {#extension-marketplace-for-web-ide-on-self-managed-instances}

<!-- categories: Web IDE -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../administration/settings/vscode_extension_marketplace.md)

{{< /details >}}

Nous sommes ravis d'annoncer le lancement du marketplace d'extensions dans le Web IDE pour les utilisateurs self-managed. Grâce au marketplace d'extensions, vous pouvez découvrir, installer et gérer des extensions tierces pour améliorer votre expérience de développement.

Par défaut, l'instance GitLab est configurée pour utiliser le registre d'extensions Open VSX. Pour l'activer, suivez les étapes [d'activation avec le registre d'extensions par défaut](../../administration/settings/vscode_extension_marketplace.md#enable-the-extension-registry).

Si vous souhaitez utiliser votre propre registre ou un registre personnalisé, vous avez également la possibilité de [connecter un registre d'extensions personnalisé](../../administration/settings/vscode_extension_marketplace.md#modify-the-extension-registry). Cela vous offre plus de flexibilité pour gérer les extensions disponibles.

Après avoir activé le marketplace d'extensions, les utilisateurs individuels doivent encore accepter de l'utiliser. Ils peuvent le faire en accédant à la section **Intégrations** dans leurs paramètres de [Préférences](https://gitlab.com/-/profile/preferences).

Il est important de noter que certaines extensions nécessitent un environnement d'exécution local et ne sont pas compatibles avec la version web uniquement. Malgré cela, vous pouvez toujours choisir parmi des milliers d'extensions disponibles pour améliorer votre productivité et personnaliser votre workflow.

### GitLab Duo avec Amazon Q est en disponibilité générale {#gitlab-duo-with-amazon-q-is-generally-available}

<!-- categories: Code Suggestions -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab Self-Managed
- Liens : [Documentation](../../user/duo_amazon_q/_index.md) \| [Epic associé](https://gitlab.com/groups/gitlab-org/-/epics/16879)

{{< /details >}}

Nous sommes ravis d'annoncer la disponibilité générale de GitLab Duo avec Amazon Q, une offre conjointe qui réunit la plateforme DevSecOps complète de GitLab alimentée par l'IA avec des agents d'IA Amazon Q autonomes dans une solution unique et intégrée. GitLab Duo avec Amazon Q intègre des agents d'IA directement dans les workflows de développement, permettant aux développeurs d'accélérer les tâches clés sans changer d'outil. Agissant comme des assistants intelligents au sein de la plateforme GitLab DevSecOps, ces agents automatisent des processus chronophages tels que la génération de code, les tests, les revues et la modernisation Java, aidant les équipes à se concentrer sur l'innovation tout en maintenant des normes de sécurité et de qualité.

GitLab Duo avec Amazon Q offre des avantages majeurs aux équipes de développement :

- Rationalisez le développement de fonctionnalités de l'idée au code : utilisez `/q dev`, qui convertira directement la description d'un ticket en code prêt à fusionner en quelques minutes.
- Modernisez le code hérité sans tracas : utilisez `/q transform` pour automatiser l'ensemble du processus de modernisation Java.
- Accélérez les revues de code sans sacrifier la qualité : utilisez `/q review` pour obtenir un retour instantané et intelligent sur la qualité du code et la sécurité directement dans les merge requests.
- Automatisez les tests pour livrer en toute confiance : utilisez `/q test` pour générer des tests unitaires complets qui comprennent la logique de votre application.

### Renforcez la sécurité avec des tags de conteneur protégés {#enhance-security-with-protected-container-tags}

<!-- categories: Container Registry -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed
- Liens : [Documentation](../../user/packages/container_registry/protected_container_tags.md) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/523893)

{{< /details >}}

Les registres de conteneurs sont une infrastructure critique pour les équipes DevSecOps modernes. Jusqu'à présent, les utilisateurs GitLab ayant le rôle Développeur ou supérieur pouvaient pousser et supprimer n'importe quel tag de conteneur dans leurs projets, créant des risques de modifications accidentelles ou non autorisées des images de conteneur critiques en production.

Avec les tags de conteneur protégés, vous disposez désormais d'un contrôle précis sur les personnes autorisées à pousser ou supprimer des tags de conteneur spécifiques. Vous pouvez :

- Créez jusqu'à cinq règles de protection par projet.
- Utilisez des expressions régulières RE2 pour protéger des tags tels que `latest`, les versions sémantiques (par exemple, `v1.0.0`), ou les tags de release stables (par exemple, `main-stable`).
- Restreignez les opérations de push et de suppression aux rôles Maintainer, Owner ou Administrator.
- Empêchez la suppression des tags protégés par les politiques de nettoyage.

Cette fonctionnalité nécessite le registre de conteneurs de nouvelle génération, qui est déjà activé par défaut sur GitLab.com. Pour une instance GitLab Self-Managed, vous devrez activer la [base de données de métadonnées](../../administration/packages/container_registry_metadata_database.md) pour utiliser les tags de conteneur protégés.

### Protégez votre registre avec des paquets Maven protégés {#safeguard-your-registry-with-protected-maven-packages}

<!-- categories: Package Registry -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/packages/package_registry/package_protection_rules.md) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/323969)

{{< /details >}}

Nous sommes ravis d'introduire la prise en charge des paquets Maven protégés pour renforcer la sécurité et la stabilité de votre registre de paquets GitLab. La modification accidentelle de paquets peut perturber l'ensemble du processus de développement. Avec les paquets protégés, vous pouvez protéger vos dépendances les plus importantes contre les modifications involontaires.

Dans GitLab 17.11, vous pouvez désormais protéger les paquets Maven en créant des règles de protection. Si un paquet correspond à une règle de protection, seuls les utilisateurs spécifiés peuvent pousser de nouvelles versions du paquet. Les règles de protection des paquets préviennent les écrasements accidentels, améliorent la conformité aux exigences réglementaires et réduisent le besoin de supervision manuelle.

La prise en charge des [paquets protégés](https://gitlab.com/groups/gitlab-org/-/epics/5574) pour Maven et d'autres formats de paquets sont toutes des contributions de la communauté de `gerardo-navarro` et de l'équipe Siemens. Merci, Gerardo, et au reste de l'équipe de Siemens pour leurs nombreuses contributions à GitLab ! Si vous souhaitez en savoir plus sur la façon dont Gerardo et l'équipe Siemens ont contribué à ce changement, regardez cette [vidéo](https://www.youtube.com/watch?v=5-nQ1_Mi7zg) dans laquelle Gerardo partage ses apprentissages et ses meilleures pratiques pour contribuer à GitLab d'après son expérience en tant que contributeur externe.

### Champs personnalisés pour les epics, tickets et tâches {#epic-issue-and-task-custom-fields}

<!-- categories: Team Planning -->

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/work_items/custom_fields.md) \| [Epic associé](https://gitlab.com/groups/gitlab-org/-/epics/14904)

{{< /details >}}

Avec cette release, vous pouvez configurer des champs personnalisés de type texte, nombre, sélection unique et sélection multiple pour les tickets, epics, tâches, objectifs et résultats clés. Alors que les labels ont été le principal moyen de catégoriser les éléments de travail jusqu'à présent, les champs personnalisés offrent une approche plus conviviale pour ajouter des métadonnées structurées à vos artefacts de planification.

Les champs personnalisés sont configurés dans votre groupe principal et se propagent à tous les sous-groupes et projets. Vous pouvez associer des champs à un ou plusieurs types d'éléments de travail et filtrer par valeurs de champs personnalisés dans les listes de tickets et d'epics.

### Nouveau look des tickets désormais en disponibilité générale {#new-issue-look-now-generally-available}

<!-- categories: Team Planning -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/project/issues/_index.md) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/525547)

{{< /details >}}

À partir de cette release, le nouveau look des tickets est en disponibilité générale et remplace l'expérience de ticket héritée. Les tickets partagent désormais un cadre commun avec les epics et les tâches, avec des mises à jour en temps réel et des améliorations du workflow :

- **Drawer view:** Vous pouvez ouvrir des éléments depuis des listes ou des tableaux dans un tiroir pour une consultation rapide sans quitter votre contexte actuel. Un bouton en haut vous permet de passer à une vue pleine page.
- **Change type:** Convertissez les types entre epics, tickets et tâches à l'aide de l'action « Changer le type » (remplace « Promouvoir en epic »)
- **Date de début :** Les tickets prennent désormais en charge les dates de début, alignant leur fonctionnalité avec les epics et les tâches.
- **Ancestry:** La hiérarchie complète est affichée au-dessus du titre et le champ Parent figure dans la barre latérale. Pour gérer les relations, utilisez les nouvelles commandes d'action rapide `/set_parent`, `/remove_parent`, `/add_child` et `/remove_child`.
- **Controls:** Toutes les actions sont désormais accessibles depuis le menu supérieur (points de suspension verticaux), qui reste visible dans l'en-tête épinglé lors du défilement.
- **Development:** Tous les éléments de développement (merge requests, branches et feature flags) liés à un ticket ou une tâche sont désormais regroupés dans une liste unique et pratique.
- **Layout:** Les améliorations de l'interface créent une expérience plus fluide entre les tickets, les epics, les tâches et les merge requests, vous aidant à naviguer dans votre workflow plus efficacement.
- **Linked items:** Créez des relations entre tâches, tickets et epics grâce à des options de liaison améliorées. Glissez-déposez pour modifier les types de lien et basculer la visibilité des labels et des éléments fermés.

### Interface utilisateur des comptes de service {#service-accounts-ui}

<!-- categories: System Access -->

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/profile/service_accounts.md) \| [Epic associé](https://gitlab.com/groups/gitlab-org/-/epics/9965)

{{< /details >}}

Vous pouvez désormais utiliser un espace dédié pour créer et gérer des comptes de service dans l'interface GitLab. Cette interface vous permet de créer, surveiller et contrôler l'accès automatisé à vos ressources GitLab. Auparavant, cette fonctionnalité n'était disponible que via l'API.

### Attribution automatique de sièges Duo Pro et Duo Enterprise {#automated-duo-pro-and-duo-enterprise-seat-assignment}

<!-- categories: System Access -->

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Modules complémentaires : Duo Pro, Duo Enterprise
- Liens : [Documentation](../../user/group/saml_sso/group_sync.md#manage-gitlab-duo-seat-assignment) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/502496)

{{< /details >}}

Vous pouvez désormais attribuer automatiquement un siège Duo Pro ou Duo Enterprise aux utilisateurs via SAML Group Sync. Tant que le groupe GitLab dispose de sièges Duo Pro ou Duo Enterprise disponibles, tout utilisateur mappé depuis le fournisseur d'identité se voit automatiquement attribuer un siège. Cela réduit l'effort nécessaire pour gérer les attributions de sièges.

### Entrées de pipeline CI/CD {#cicd-pipeline-inputs}

<!-- categories: Pipeline Composition -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed
- Liens : [Documentation](../../ci/inputs/_index.md#for-a-pipeline)

{{< /details >}}

Les variables CI/CD sont essentielles pour les workflows CI/CD dynamiques et sont utilisées pour de nombreuses choses, notamment comme variables d'environnement, variables de contexte, configuration d'outils et variables de matrice. Mais les développeurs s'appuient parfois sur des variables CI/CD pour injecter des [variables de pipeline](../../ci/variables/_index.md#use-pipeline-variables) dans les pipelines afin de modifier manuellement le comportement du pipeline, ce qui comporte certains risques en raison de la priorité plus élevée des variables de pipeline.

Dans GitLab 17.11 et les versions ultérieures, vous pouvez désormais utiliser `inputs` pour modifier en toute sécurité le comportement du pipeline au lieu d'utiliser des variables de pipeline, notamment dans les pipelines planifiés, les pipelines downstream, les pipelines déclenchés et d'autres cas. Les entrées offrent aux développeurs une solution plus structurée et flexible pour injecter du contenu dynamique au moment de l'exécution des jobs CI/CD. Après avoir basculé vers les entrées, vous pouvez entièrement [désactiver l'accès aux variables de pipeline](../../ci/variables/_index.md#restrict-pipeline-variables).

Nous vous serions très reconnaissants d'essayer cette fonctionnalité et de partager vos retours via ce [ticket](https://gitlab.com/gitlab-org/gitlab/-/issues/533802) dédié.

## Agentic Core {#agentic-core}

### GitLab Duo Chat utilise désormais Anthropic Claude Sonnet 3.7 {#gitlab-duo-chat-now-uses-anthropic-claude-sonnet-37}

<!-- categories: Duo Chat -->

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Modules complémentaires : Duo Pro, Duo Enterprise
- Liens : [Documentation](../../user/gitlab_duo_chat/examples.md) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/521034)

{{< /details >}}

GitLab Duo Chat utilise désormais Anthropic Claude Sonnet 3.7 comme modèle de base, remplaçant Claude 3.5 Sonnet pour répondre à la plupart des questions.

Claude 3.7 Sonnet présente des capacités de codage et de raisonnement nettement améliorées, ce qui le rend encore plus performant pour expliquer du code, générer du code, traiter des données textuelles et répondre à des questions DevSecOps complexes. Vous remarquerez des réponses Chat plus détaillées et plus précises dans ces domaines.

Cette mise à niveau s'applique à toutes les fonctionnalités Chat et garantit une expérience cohérente et améliorée sur l'ensemble de l'interface Chat.

### Les fichiers ouverts comme contexte sont désormais disponibles sur GitLab Duo Self-Hosted Code Suggestions {#open-files-as-context-now-available-on-gitlab-duo-self-hosted-code-suggestions}

<!-- categories: Self-Hosted Models -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab Self-Managed
- Modules complémentaires : Duo Enterprise
- Liens : [Documentation](../../user/project/repository/code_suggestions/context.md#using-open-files-as-context) \| [Epic associé](https://gitlab.com/groups/gitlab-org/-/epics/16611)

{{< /details >}}

Sur GitLab Duo Self-Hosted, vous pouvez désormais utiliser les [fichiers ouverts dans des onglets de votre IDE](../../user/project/repository/code_suggestions/context.md#using-open-files-as-context) comme contexte lors de l'utilisation de Code Suggestions.

### Sélectionner des modèles individuels pour les fonctionnalités alimentées par l'IA sur GitLab Duo Self-Hosted {#select-individual-models-for-ai-powered-features-on-gitlab-duo-self-hosted}

<!-- categories: Self-Hosted Models -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab Self-Managed
- Modules complémentaires : Duo Enterprise
- Liens : [Documentation](../../administration/gitlab_duo_self_hosted/configure_duo_features.md#select-a-self-hosted-model-for-a-feature) \| [Epic associé](https://gitlab.com/groups/gitlab-org/-/epics/17099)

{{< /details >}}

Sur GitLab Duo Self-Hosted, vous pouvez désormais sélectionner et configurer des modèles pris en charge individuellement pour chaque fonctionnalité et sous-fonctionnalité GitLab Duo sur votre instance GitLab Self-Managed.

Pour laisser un retour, accédez au [ticket 524175](https://gitlab.com/gitlab-org/gitlab/-/issues/524175).

### Les modèles Llama 3 sont en disponibilité générale pour GitLab Duo Chat et Code Suggestions {#llama-3-models-generally-available-for-gitlab-duo-chat-and-code-suggestions}

<!-- categories: Self-Hosted Models -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab Self-Managed
- Modules complémentaires : Duo Enterprise
- Liens : [Documentation](../../administration/gitlab_duo_self_hosted/supported_models_and_hardware_requirements.md#supported-models) \| [Epic associé](https://gitlab.com/groups/gitlab-org/-/epics/15678)

{{< /details >}}

Les modèles Llama 3 sont désormais en disponibilité générale avec GitLab Duo Self-Hosted pour prendre en charge GitLab Duo Chat et Code Suggestions.

Pour laisser un retour sur l'utilisation de ces modèles avec GitLab Duo Self-Hosted, consultez le [ticket 523918](https://gitlab.com/gitlab-org/gitlab/-/issues/523918).

### Gérer plusieurs conversations dans GitLab Duo Chat {#manage-multiple-conversations-in-gitlab-duo-chat}

<!-- categories: Duo Chat -->

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Modules complémentaires : Duo Pro, Duo Enterprise
- Liens : [Documentation](../../user/gitlab_duo_chat/_index.md#have-multiple-conversations) \| [Epic associé](https://gitlab.com/groups/gitlab-org/-/epics/16108)

{{< /details >}}

La gestion de plusieurs conversations avec GitLab Duo Chat est désormais disponible dans les instances GitLab Self-Managed via l'interface web. Vous pouvez créer de nouvelles conversations, parcourir votre historique de conversations et passer d'une conversation à l'autre sans perdre le contexte.

Pour protéger votre vie privée, les conversations sans activité pendant 30 jours sont automatiquement supprimées, et vous pouvez supprimer manuellement n'importe quelle conversation à tout moment. Sur GitLab Self-Managed, les administrateurs peuvent réduire la durée de conservation des conversations.

Partagez votre expérience avec nous dans le [ticket 526013](https://gitlab.com/gitlab-org/gitlab/-/issues/526013).

## Mise à l'échelle et déploiements {#scale-and-deployments}

### Tous les webhooks auto-désactivés se réactivent désormais automatiquement {#all-auto-disabled-webhooks-now-automatically-re-enable}

<!-- categories: Notifications -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/project/integrations/webhooks.md#auto-disabled-webhooks) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/396577)

{{< /details >}}

Avec cette release, les webhooks qui renvoient des erreurs `4xx` sont désormais réactivés automatiquement. Toutes les erreurs (`4xx`, `5xx` ou erreurs serveur) sont traitées de la même façon, ce qui permet un comportement plus prévisible et un dépannage plus facile. Ce changement a été annoncé dans [cet article de blog](https://about.gitlab.com/blog/gitlab-webhooks-get-smarter-with-self-healing-capabilities/).

Les webhooks défaillants sont temporairement désactivés pendant une minute, avec une extension jusqu'à un maximum de 24 heures. Après 40 échecs consécutifs d'un webhook, celui-ci est désormais définitivement désactivé.

Les webhooks définitivement désactivés dans GitLab 17.10 et versions antérieures ont subi une migration de données.

- Pour GitLab.com, ces modifications s'appliquent automatiquement.
- Pour GitLab Self-Managed et GitLab Dedicated, ces modifications n'affectent que les instances où le drapeau `auto_disabling_webhooks``ops` est activé.

Merci à [Phawin](https://gitlab.com/lifez) pour [cette contribution communautaire](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/166329) !

### Contributions des utilisateurs fantômes automatiquement mappées lors des imports {#ghost-user-contributions-auto-mapped-during-imports}

<!-- categories: Importers -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/import/mapping/post_migration_mapping.md) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/514014)

{{< /details >}}

Auparavant, les contributions des utilisateurs fantômes créaient des références de substitution nécessitant une réattribution manuelle, générant un travail supplémentaire lors des migrations. Désormais, les importeurs utilisant la nouvelle [fonctionnalité de mappage des contributions et des membres](../../user/import/mapping/post_migration_mapping.md), la migration par transfert direct, ainsi que les importeurs GitHub, Bitbucket Server et Gitea, gèrent les contributions des utilisateurs fantômes de manière plus intelligente. Lors de l'importation de contenu dans GitLab, les contributions précédemment effectuées par l'utilisateur fantôme sur l'instance source sont désormais automatiquement mappées vers l'utilisateur fantôme sur l'instance de destination.

Cette amélioration élimine la création d'utilisateurs de substitution inutiles pour les contributions des utilisateurs fantômes, réduisant l'encombrement dans l'interface de mappage des utilisateurs et simplifiant le processus de migration.

### Vérification SAML pour la réattribution des contributions lors de l'importation vers GitLab.com {#saml-verification-for-contribution-reassignment-when-importing-to-gitlabcom}

<!-- categories: Importers -->

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/import/mapping/reassignment.md) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/513686)

{{< /details >}}

Dans ce jalon, nous avons ajouté des vérifications SAML à la réattribution des contributions lors de l'importation vers GitLab.com. Ces vérifications préviennent les erreurs de réattribution dans les groupes où le SSO SAML est activé.

Si vous importez vers GitLab.com et utilisez le SSO SAML pour les groupes GitLab.com, tous les utilisateurs doivent lier leur identité SAML à leur compte GitLab.com avant de pouvoir réattribuer les contributions et les appartenances. Lorsque vous réattribuez des contributions à des utilisateurs qui n'ont pas vérifié leur identité SAML, vous recevrez des messages d'erreur. Ces messages expliquent les étapes à suivre pour garantir que les appartenances à vos groupes sont correctement attribuées.

### Filtrer les utilisateurs de substitution dans la zone Admin {#filter-placeholder-users-in-admin-area}

<!-- categories: Importers -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../administration/admin_area.md#administering-users) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/521974)

{{< /details >}}

Auparavant, les utilisateurs de substitution créés lors des imports apparaissaient mélangés aux utilisateurs réguliers sans distinction claire dans la page **Utilisateurs** de la zone **Admin**.

Avec cette release, les administrateurs peuvent désormais filtrer les comptes de substitution depuis la barre de recherche de la page **Utilisateurs** dans la zone **Admin**. Pour ce faire, sélectionnez `Type` dans la liste déroulante, puis choisissez `Placeholder`.

### Les limites d'utilisateurs de substitution apparaissent dans les quotas d'utilisation des groupes {#placeholder-user-limits-appear-in-group-usage-quotas}

<!-- categories: Importers -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/import/mapping/post_migration_mapping.md#placeholder-user-limits) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/486691)

{{< /details >}}

Pour les imports vers GitLab.com, les utilisateurs de substitution sont limités par groupe principal. Ces limites dépendent de votre licence GitLab et du nombre de sièges. Avec cette release, il est possible de vérifier votre utilisation et vos limites d'utilisateurs de substitution pour un groupe principal dans l'interface.

Pour afficher votre utilisation et vos limites actuelles :

1. Dans la barre latérale gauche, sélectionnez **Rechercher ou accéder à** et trouvez votre groupe. Ce groupe doit être au niveau principal.
1. Sélectionnez **Paramètres > Usage Quotas**.
1. Sélectionnez l'onglet **Importer**.

### Geo - Nouvelle vue des réplicables {#geo---new-replicables-view}

<!-- categories: Disaster Recovery, Geo Replication -->

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed
- Liens : [Documentation](../../administration/geo/_index.md)

{{< /details >}}

Nous introduisons un nouveau look pour la vue des réplicables dans Geo. La nouvelle expérience s'aligne mieux avec le reste de GitLab et fournit une interface plus rationalisée et moins encombrée pour examiner le statut de synchronisation et de vérification des sites Geo secondaires. De plus, il existe désormais une vue détaillée accessible par clic pour chaque élément réplicable, fournissant des informations telles que les sommes de contrôle primaires et secondaires, les détails des erreurs et bien plus encore. Ces informations faciliteront grandement le dépannage des problèmes de synchronisation Geo.

### Améliorations du paquet Linux {#linux-package-improvements}

<!-- categories: Omnibus Package -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed
- Liens : [Documentation](https://docs.gitlab.com/omnibus/) \| [Ticket associé](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/8504)

{{< /details >}}

Dans GitLab 18.0, la version minimale prise en charge de PostgreSQL sera la version 16. Pour préparer ce changement, sur les instances qui n'utilisent pas le [cluster PostgreSQL](../../administration/postgresql/replication_and_failover.md), les mises à niveau vers GitLab 17.11 tenteront de mettre à niveau automatiquement PostgreSQL vers la version 16.

Si vous utilisez le [cluster PostgreSQL](../../administration/postgresql/replication_and_failover.md) ou si vous [refusez cette mise à niveau automatique](https://docs.gitlab.com/omnibus/settings/database/#opt-out-of-automatic-postgresql-upgrades), vous devez [mettre à niveau manuellement vers PostgreSQL 16](https://docs.gitlab.com/omnibus/settings/database/#upgrade-packaged-postgresql-server) pour pouvoir mettre à niveau vers GitLab 18.0.

### Bascule de désinscription avant déploiement pour désactiver le partage de données d'événements {#pre-deployment-opt-out-toggle-to-disable-event-data-sharing}

<!-- categories: Application Instrumentation -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../administration/settings/event_data.md) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/510333)

{{< /details >}}

Dans GitLab 18.0, nous prévoyons d'activer la collecte de données d'utilisation produit au niveau des événements depuis les instances GitLab Self-Managed et GitLab Dedicated. Contrairement aux données agrégées, les données au niveau des événements fournissent à GitLab des informations plus approfondies sur l'utilisation, nous permettant d'améliorer l'expérience utilisateur sur la plateforme et d'augmenter l'adoption des fonctionnalités.

À partir de GitLab 17.11, vous aurez la possibilité de vous désinscrire de la collecte de données d'événements avant qu'elle ne commence, vous permettant ainsi de choisir votre participation à l'avance. Pour plus d'informations et des détails sur la désinscription, veuillez consulter notre documentation.

## DevOps et sécurité unifiés {#unified-devops-and-security}

### Couverture accrue des règles pour la protection contre les push de secrets et la détection des secrets dans les pipelines {#increased-rule-coverage-for-secret-push-protection-and-pipeline-secret-detection}

<!-- categories: Secret Detection -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/application_security/secret_detection/detected_secrets.md) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/534106)

{{< /details >}}

La détection des secrets GitLab a reçu des mises à jour importantes, notamment 17 nouvelles règles de protection contre les push de secrets et 12 nouvelles règles de détection des secrets dans les pipelines. Certaines règles existantes ont également été mises à jour pour améliorer la qualité et réduire les faux positifs. Pour plus de détails, consultez la version v0.9.0 dans le [journal des modifications](https://gitlab.com/gitlab-org/security-products/secret-detection/secret-detection-rules/-/blob/main/CHANGELOG.md#v090).

### Version bêta de l'accessibilité statique avec prise en charge de Python {#static-reachability-beta-with-python-support}

<!-- categories: Software Composition Analysis -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/application_security/dependency_scanning/static_reachability.md) \| [Epic associé](https://gitlab.com/groups/gitlab-org/-/epics/15781)

{{< /details >}}

L'équipe Composition Analysis a publié la prise en charge en version bêta de l'accessibilité statique pour Python. Cette version bêta se concentre sur l'amélioration de la stabilité, de l'observabilité et offre une meilleure expérience utilisateur grâce à une configuration plus facile.

L'accessibilité statique enrichit les résultats de l'analyse de composition logicielle (SCA). Alimentée par GitLab Advanced SAST, l'accessibilité statique analyse le code source du projet pour identifier les dépendances open source utilisées.

Vous pouvez utiliser les données produites par l'accessibilité statique dans votre processus de triage et de remédiation. Les données d'accessibilité statique peuvent également être utilisées avec les scores CVSS et EPSS, ainsi que les indicateurs KEV pour fournir une vue plus ciblée de vos vulnérabilités.

Nous accueillons avec plaisir vos retours sur cette fonctionnalité. Si vous avez des questions, des commentaires ou souhaitez interagir avec notre équipe, consultez ce [ticket de retour](https://gitlab.com/gitlab-org/gitlab/-/issues/535498).

### Prise en charge de l'analyse dynamique pour les vérifications XSS réfléchies {#dynamic-analysis-support-for-reflected-xss-checks}

<!-- categories: DAST -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/application_security/dast/browser/checks/_index.md) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/525861)

{{< /details >}}

L'équipe d'analyse dynamique a introduit une vérification pour [CWE-79](https://cwe.mitre.org/data/definitions/79.html). Ce travail permet à notre scanner DAST de vérifier les attaques XSS réfléchies.

La vérification des XSS réfléchies est activée par défaut. Pour désactiver cette vérification, dans votre configuration, définissez `DAST_FF_XSS_ATTACK: false`. Si vous avez des questions ou des retours, consultez le [ticket 525861](https://gitlab.com/gitlab-org/gitlab/-/issues/525861).

### Utiliser des fichiers importés comme contexte dans Code Suggestions {#use-imported-files-as-context-in-code-suggestions}

<!-- categories: Code Suggestions -->

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Modules complémentaires : Duo Pro, Duo Enterprise
- Liens : [Documentation](../../user/project/repository/code_suggestions/context.md#using-imported-files-as-context) \| [Epic associé](https://gitlab.com/groups/gitlab-org/editor-extensions/-/epics/58)

{{< /details >}}

GitLab Duo Code Suggestions peut désormais utiliser des fichiers importés dans votre IDE pour enrichir et améliorer la qualité des suggestions. Les fichiers importés fournissent un contexte supplémentaire sur votre projet. Le contexte de fichiers importés est pris en charge pour les fichiers JavaScript et TypeScript.

### Assigner des projets lors de la création de frameworks de conformité {#assign-projects-when-creating-compliance-frameworks}

<!-- categories: Compliance Management -->

{{< details >}}

- Édition : Ultimate, Premium
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/compliance/compliance_frameworks/_index.md#apply-a-compliance-framework-to-a-project) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/500520)

{{< /details >}}

Auparavant, il n'était pas possible d'assigner de nouveaux frameworks de conformité à des projets sans naviguer vers l'onglet **Projets** dans le centre de conformité après avoir créé le framework de conformité. Cette situation créait une friction inutile lors de la création de nouveaux frameworks de conformité dans vos groupes.

Dans GitLab 17.11, lors de la création d'un framework de conformité, nous avons introduit une nouvelle étape qui offre la possibilité d'assigner plusieurs projets au framework de conformité avant sa création.

Cette nouvelle fonctionnalité :

- Vous aide à rester dans le workflow de création du framework de conformité.
- Vous guide pour comprendre que les frameworks de conformité fonctionnent en collaboration avec les projets d'un groupe pour surveiller et appliquer la conformité pour l'ensemble du groupe.

### Prise en charge de Kubernetes 1.32 {#kubernetes-132-support}

<!-- categories: Deployment Management -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/clusters/agent/_index.md#supported-kubernetes-versions-for-gitlab-features) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/509283)

{{< /details >}}

Cette release ajoute la prise en charge complète de Kubernetes version 1.32, publiée en décembre 2024. Si vous déployez vos applications sur Kubernetes, vous pouvez désormais mettre à niveau vos clusters connectés vers la version la plus récente et profiter de toutes ses fonctionnalités.

Vous pouvez en savoir plus sur [notre politique de prise en charge Kubernetes et les autres versions Kubernetes prises en charge](../../user/clusters/agent/_index.md#supported-kubernetes-versions-for-gitlab-features).

### Configurer l'authentification unique SAML avec plusieurs fournisseurs d'identité dans Switchboard {#configure-saml-single-sign-on-with-multiple-identity-providers-in-switchboard}

<!-- categories: GitLab Dedicated, Switchboard -->

{{< details >}}

- Édition : Gold
- Liens : [Documentation](../../administration/dedicated/configure_instance/authentication/saml.md)

{{< /details >}}

Vous pouvez désormais configurer l'authentification unique (SSO) SAML pour votre instance GitLab Dedicated pour jusqu'à dix fournisseurs d'identité (IdP).

Toutes les options de configuration SAML disponibles pour les instances GitLab Dedicated peuvent être configurées pour chaque IdP individuel.

Si vous aviez précédemment configuré plusieurs IdP, vous pouvez désormais consulter et modifier toutes les configurations SAML existantes directement dans Switchboard.

### Interface d'authentification Docker Hub pour le proxy de dépendances {#docker-hub-authentication-ui-for-the-dependency-proxy}

<!-- categories: Container Registry -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed
- Liens : [Documentation](../../user/packages/dependency_proxy/_index.md#authenticate-with-docker-hub) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/521954)

{{< /details >}}

Nous sommes ravis d'annoncer la prise en charge de l'interface pour l'authentification Docker Hub dans le proxy de dépendances GitLab. Cette fonctionnalité a été initialement introduite dans GitLab 17.10 avec la seule prise en charge de l'API GraphQL, et inclut désormais une interface utilisateur pour une configuration plus facile.

Grâce à cette amélioration, vous pouvez désormais configurer l'authentification Docker Hub directement depuis la page des paramètres de votre groupe, ce qui vous aide à :

- Éviter les échecs de pipeline dus aux limites de débit.
- Accéder aux images Docker Hub privées.
- Stocker en toute sécurité vos identifiants Docker Hub, votre [jeton d'accès personnel](https://docs.docker.com/security/for-developers/access-tokens/) ou vos [jetons d'accès d'organisation](https://docs.docker.com/security/for-admins/access-tokens/).

Cette approche rationalisée facilite le maintien d'un accès ininterrompu aux images Docker Hub dans vos pipelines CI/CD sans utiliser l'API GraphQL.

### Définir des limites de travaux en cours par poids {#set-work-in-progress-limits-by-weight}

<!-- categories: Team Planning -->

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/project/issue_board.md#work-in-progress-limits) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/119208)

{{< /details >}}

Vous pouvez désormais définir des limites de travaux en cours par poids en plus du nombre de tickets, ce qui vous offre plus de flexibilité dans la gestion de la charge de travail de votre équipe.

Contrôlez le flux de travail en fonction de la complexité ou de l'effort de chaque tâche, plutôt que du simple nombre de tickets. Les équipes qui utilisent le poids des tickets pour représenter l'effort peuvent désormais éviter la surcharge en limitant le poids total des tickets dans une liste de tableau donnée.

Utilisez cette fonctionnalité pour optimiser la productivité de votre équipe et créer un workflow plus équilibré qui tient compte de la complexité variable des tâches.

### Amélioration du style de la barre latérale du wiki {#improved-wiki-sidebar-styling}

<!-- categories: Wiki -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/project/wiki/_index.md#customize-sidebar)

{{< /details >}}

La barre latérale de wiki personnalisée présente désormais un style amélioré avec des tailles de titre réduites et un meilleur rembourrage gauche pour les listes. Ces améliorations ergonomiques améliorent la lisibilité de la navigation personnalisée créée via la page wiki `_sidebar`.

Les barres latérales personnalisées aident les équipes à organiser le contenu de leur wiki d'une manière adaptée à la structure unique de leur base de connaissances. Avec cette mise à jour de style, la barre latérale est désormais plus facile à parcourir, créant une hiérarchie visuelle plus claire qui aide les membres de l'équipe à trouver des informations pertinentes plus rapidement.

### Afficher le dernier commentaire en tant que colonne dans les vues GLQL {#display-last-comment-as-a-column-in-glql-views}

<!-- categories: Wiki, Team Planning -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/glql/fields.md) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/512154)

{{< /details >}}

Les vues GLQL prennent désormais en charge l'affichage du dernier commentaire sur un ticket ou une merge request en tant que colonne. En incluant `lastComment` comme champ dans votre requête GLQL, vous pouvez voir les mises à jour les plus récentes sans quitter votre contexte actuel.

Auparavant, vous deviez ouvrir chaque ticket ou merge request individuellement pour voir le dernier commentaire, ce qui était chronophage et rendait difficile l'obtention d'un aperçu rapide de l'avancement. Cette amélioration aide les équipes à maintenir leur élan en offrant une visibilité instantanée sur les conversations en cours et les mises à jour de statut.

Nous accueillons avec plaisir vos retours sur cette amélioration et sur les vues GLQL en général dans notre [ticket de retour](https://gitlab.com/gitlab-org/gitlab/-/issues/509791).

### Modèle de projet Nuxt pour GitLab Pages {#nuxt-project-template-for-gitlab-pages}

<!-- categories: Pages -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/project/pages/getting_started/pages_new_project_template.md)

{{< /details >}}

GitLab fournit des modèles pour les générateurs de sites statiques (SSG) les plus populaires, et vous pouvez désormais créer un site GitLab Pages avec Nuxt, un puissant framework basé sur Vue.js. Nuxt est particulièrement utile pour les équipes souhaitant créer des applications web modernes et performantes avec moins de configuration préalable.

Cet ajout élargit vos options pour lancer rapidement un site Pages avec des pipelines CI/CD intégrés et une expérience de développement moderne, sans passer du temps sur la configuration initiale.

### Export CycloneDX pour la liste des dépendances du projet {#cyclonedx-export-for-the-project-dependency-list}

<!-- categories: Dependency Management -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/application_security/dependency_list/_index.md#export) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/524733)

{{< /details >}}

De nombreuses organisations exigent désormais une nomenclature logicielle (SBOM) pour répondre aux exigences réglementaires et contribuer à renforcer davantage la sécurité de la chaîne d'approvisionnement logicielle. Auparavant, vous pouviez uniquement exporter votre liste de dépendances en tant que fichier JSON ou CSV depuis GitLab. Désormais, GitLab peut générer votre SBOM en exportant votre liste de dépendances dans le format CycloneDX largement adopté.

Pour télécharger un SBOM directement en tant que fichier CycloneDX, dans la liste des dépendances, sélectionnez **Exporter** > **Exporter au format CycloneDX (JSON)**.

### Envoi par e-mail de l'export de la liste des dépendances et du rapport de vulnérabilité {#email-delivery-for-dependency-list-and-vulnerability-report-export}

<!-- categories: Dependency Management -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/application_security/dependency_list/_index.md#export) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/513149)

{{< /details >}}

Auparavant, lors de l'export de la liste des dépendances ou du rapport de vulnérabilité, vous deviez rester sur la page jusqu'à la fin de l'export avant de pouvoir télécharger le rapport.

Désormais, vous êtes notifié par e-mail avec un lien de téléchargement lorsque l'export de la liste des dépendances ou du rapport de vulnérabilité est terminé.

### Exporter la liste des dépendances au format CSV {#export-dependency-list-in-csv-format}

<!-- categories: Dependency Management -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/application_security/dependency_list/_index.md#export) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/435843)

{{< /details >}}

Auparavant, il n'était pas possible d'exporter une liste de dépendances depuis GitLab au format CSV. Désormais, lorsque vous téléchargez une liste de dépendances, vous pouvez sélectionner la nouvelle option CSV pour exporter la liste dans ce format.

### Le filtre Outil remplacé par les filtres Scanner et Type de rapport {#tool-filter-replaced-with-scanner-and-report-type-filters}

<!-- categories: Vulnerability Management -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/application_security/vulnerability_report/_index.md#report-type-filter) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/503371)

{{< /details >}}

Auparavant, le filtre de recherche **tool** dans le rapport de vulnérabilité vous permettait de filtrer les résultats sur la base d'un seul groupe d'outils comprenant le type de scanner (comme ESLint ou Gemnasium) et le type de rapport (comme SAST ou l'analyse de conteneurs).

Pour vous aider à trouver plus facilement les outils appropriés, nous avons remplacé le filtre **tool** par le filtre **scanner** et le filtre **report type**. Vous pouvez désormais filtrer votre recherche en fonction de chacun de ces types d'outils séparément.

### Stocker et filtrer une valeur `source` pour les jobs CI/CD {#store-and-filter-a-source-value-for-cicd-jobs}

<!-- categories: Security Policy Management -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../api/jobs.md#retrieve-a-job-by-job-id) \| [Epic associé](https://gitlab.com/groups/gitlab-org/-/epics/11796)

{{< /details >}}

GitLab 17.11 introduit une nouvelle fonctionnalité permettant aux utilisateurs de vérifier l'origine des artefacts de build en suivant l'attribut source des jobs CI/CD. Cette amélioration est particulièrement précieuse pour les workflows de sécurité et de conformité. Par exemple, les organisations peuvent mettre en œuvre des mesures de sécurité de la chaîne d'approvisionnement logicielle ou exiger des preuves vérifiables des analyses de sécurité à des fins de conformité.

Les jobs dans GitLab stockent et affichent désormais une valeur `source` qui identifie s'ils sont issus de :

- Une politique d'exécution de scan
- Une politique d'exécution de pipeline
- Un pipeline ordinaire

Vous pouvez accéder à l'attribut `source` sur la page **Version** > **Jobs** avec une nouvelle option de filtre, via l'API Jobs ou via les `claims` du jeton d'identifiant pour la vérification des artefacts.

Avec cette nouvelle fonctionnalité, vous pouvez désormais :

- Vérifier l'authenticité des résultats des analyses de sécurité.
- Filtrer les jobs par type de source pour identifier rapidement les analyses imposées par les politiques.
- Implémenter la vérification cryptographique des artefacts à l'aide des nouvelles revendications de jeton d'identifiant.
- S'assurer que les exigences de conformité sont respectées avec des pistes d'audit appropriées.

Les équipes de sécurité et de conformité peuvent exploiter cette fonctionnalité pour :

- Afficher uniquement les jobs imposés par les politiques à l'aide du nouveau filtre sur la page Jobs.
- Automatiser les tâches en accédant au champ `source` dans l'API Jobs.
- Implémenter la vérification des artefacts à l'aide des nouvelles revendications de jeton d'identifiant :
  - `job_source` : identifie l'origine du job.
  - `job_policy_ref_uri` : pointe vers le fichier de politique (pour les jobs définis par une politique).
  - `job_policy_ref_sha` : contient le SHA du commit git de la politique.

### Options de tri améliorées pour les jetons d'accès {#enhanced-sorting-options-for-access-tokens}

<!-- categories: System Access -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/profile/personal_access_tokens.md) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/519716)

{{< /details >}}

De nouvelles options de tri pour les jetons d'accès sont désormais disponibles dans l'interface et l'API. Ces options de tri complètent les capacités existantes de gestion des jetons de GitLab, vous offrant un meilleur contrôle sur votre inventaire de jetons d'accès et vous aidant à mieux maintenir la sécurité des jetons d'accès. Les nouvelles options de tri comprennent :

- Trier par date d'expiration (croissant) : affichez les jetons qui expirent le plus tôt.
- Trier par date d'expiration (décroissant) : affichez les jetons avec la durée de vie restante la plus longue.
- Trier par date de dernière utilisation (croissant) : affichez les jetons qui n'ont pas été utilisés récemment.
- Trier par date de dernière utilisation (décroissant) : affichez les jetons utilisés le plus récemment.

### Statistiques des jetons pour la gestion des comptes de service {#token-statistics-for-service-account-management}

<!-- categories: System Access -->

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/profile/service_accounts.md) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/520472)

{{< /details >}}

L'interface de gestion des jetons pour les comptes de service inclut désormais un tableau de bord de statistiques utile qui fournit des informations instantanées sur votre inventaire de jetons. Ces informations peuvent vous aider à évaluer l'état de vos jetons et à identifier ceux qui nécessitent une attention particulière. Le tableau de bord de statistiques comprend quatre indicateurs clés :

- Jetons actifs : affichez le nombre total de jetons actifs
- Jetons arrivant à expiration : identifiez les jetons qui expirent dans les deux prochaines semaines
- Jetons révoqués : suivez les jetons révoqués manuellement
- Jetons expirés : surveillez les jetons précédemment expirés. Merci [Chaitanya Sonwane](https://gitlab.com/chaitanyason9) pour votre contribution !

### Amélioration de la visualisation du graphe de pipeline pour les jobs en échec {#improved-pipeline-graph-visualization-for-failed-jobs}

<!-- categories: Pipeline Composition -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../ci/pipelines/_index.md#view-pipelines)

{{< /details >}}

Vous pouvez désormais identifier rapidement les jobs en échec dans le graphe de pipeline grâce à de nouveaux indicateurs visuels. Les groupes de jobs en échec sont mis en évidence dans le graphe de pipeline, et les jobs en échec sont regroupés en haut de chaque étape. Cette visualisation améliorée vous aide à dépanner les échecs de pipeline sans avoir à parcourir des structures de pipeline complexes.

### Forcer l'annulation des jobs CI/CD bloqués dans l'état d'annulation {#force-cancel-cicd-jobs-stuck-in-canceling-state}

<!-- categories: Continuous Integration (CI) -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../ci/jobs/_index.md#force-cancel-a-job) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/467107)

{{< /details >}}

Les jobs CI/CD peuvent parfois se bloquer dans l'état « annulation », bloquant les déploiements ou l'accès aux ressources partagées.

Les utilisateurs ayant le [rôle](../../user/permissions.md) Maintainer peuvent désormais forcer l'annulation de ces jobs bloqués directement depuis la page des job logs, garantissant que les jobs problématiques peuvent être correctement terminés.

### Amélioration de la gestion des runners dans les projets {#improved-runner-management-in-projects}

<!-- categories: Fleet Visibility -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../ci/runners/runners_scope.md#project-runners)

{{< /details >}}

Vous pouvez désormais gérer les runners plus efficacement dans vos projets. Les runners sont affichés dans une disposition en colonne unique et organisés dans leurs propres listes au lieu de la vue précédente à deux colonnes.

Cette organisation améliorée facilite la recherche et la gestion des runners, avec de nouvelles fonctionnalités incluant une liste des projets assignés, des gestionnaires de runners et les jobs qu'un runner a exécutés. Pour en savoir plus sur les améliorations supplémentaires de la gestion des runners prévues pour GitLab 18.0, consultez le [ticket 33803](https://gitlab.com/gitlab-org/gitlab/-/issues/33803).

### GitLab Runner 17.11 {#gitlab-runner-1711}

<!-- categories: GitLab Runner Core -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed
- Liens : [Documentation](https://docs.gitlab.com/runner)

{{< /details >}}

Nous publions également GitLab Runner 17.11 aujourd'hui ! GitLab Runner est l'agent de build hautement évolutif qui exécute vos jobs CI/CD et envoie les résultats à une instance GitLab. GitLab Runner fonctionne en conjonction avec GitLab CI/CD, le service d'intégration continue open source inclus avec GitLab.

#### Nouveautés {#whats-new}

- [Signature du code des exécutables GitLab Runner Windows](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/2483)

#### Corrections de bugs {#bug-fixes}

- [Le nettoyage de la configuration Git dans GitLab Runner 17.10.0 génère une erreur](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/38681)
- [L'indicateur `FF_DISABLE_UMASK_FOR_KUBERNETES_EXECUTOR` ne désactive pas la commande `umask`](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/38382)

La liste de toutes les modifications se trouve dans le [CHANGELOG](https://gitlab.com/gitlab-org/gitlab-runner/blob/17-11-stable/CHANGELOG.md) de GitLab Runner.

## Sujets connexes {#related-topics}

- [Correctifs de bugs](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=type%3A%3Abug&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=17.11)
- [Améliorations des performances](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=bug%3A%3Aperformance&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=17.11)
- [Améliorations de l'interface utilisateur](https://papercuts.gitlab.com/?milestone=17.11)
- [Dépréciations et suppressions](../../update/deprecations.md)
- [Notes de mise à niveau](../../update/versions/_index.md)
