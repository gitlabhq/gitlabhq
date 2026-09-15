---
stage: Release Notes
group: Monthly Release
date: 2025-03-20
title: "Notes de release de GitLab 17.10"
description: "GitLab 17.10 est disponible avec Duo Code Review en version bêta"
---

<!-- markdownlint-disable -->
<!-- vale off -->

Le 20 mars 2025, GitLab 17.10 a été publié avec les fonctionnalités suivantes.

Nous souhaitons également remercier tous nos contributeurs, dont le contributeur remarquable de ce mois-ci.

## Contributeur notable du mois : Alexey Butkeev {#this-months-notable-contributor-alexey-butkeev}

Tout le monde peut [nommer des contributeurs de la communauté GitLab](https://gitlab.com/gitlab-org/developer-relations/contributor-success/team-task/-/issues/490) ! Montrez votre soutien à nos candidats actifs ou ajoutez une nouvelle nomination ! 🙌

[Alexey Butkeev](https://gitlab.com/abutkeev) est un précieux contributeur de la communauté dont les contributions élargissent notre portée mondiale et améliorent l'expérience utilisateur. Ses contributions marquantes en matière de localisation et de traduction illustrent notre valeur de diversité, d'inclusion et d'appartenance.

« Je suis honoré d'être sélectionné comme MVP de la version 17.10 et de contribuer à rendre GitLab plus accessible et inclusif », déclare Alexey. « La localisation est un effort collectif, et je suis reconnaissant de faire partie d'une communauté aussi solidaire. »

En plus de ses contributions au code, Alexey a pris l'initiative de trouver, documenter et corriger des erreurs de traduction via GitLab et Crowdin. Ses recherches approfondies et sa capacité à résoudre des problèmes font de lui notre MVP de la version 17.10.

Alexey a été nommé par [Oleksandr Pysaryuk](https://gitlab.com/opysaryuk), Senior Manager, Globalization Technology chez GitLab, et soutenu par [Daniel Sullivan](https://gitlab.com/djsulliv), Director of Globalization & Localization chez GitLab. « Nous apprécions énormément votre travail et votre soutien ici chez GitLab », déclare Daniel. « Merci pour votre contribution à nous aider à devenir une entreprise mieux soutenue à l'échelle mondiale ! »

Merci Alexey pour avoir rendu GitLab plus inclusif et transparent !

## Fonctionnalités principales {#primary-features}

### Duo Code Review disponible en version bêta {#duo-code-review-available-in-beta}

<!-- categories: Code Review Workflow -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Modules complémentaires : Duo Enterprise
- Liens : [Documentation](../../user/project/merge_requests/duo_in_merge_requests.md#use-gitlab-duo-to-review-your-code)

{{< /details >}}

La revue de code est une activité essentielle du développement logiciel. Elle garantit que les contributions à un projet maintiennent et améliorent la qualité du code et la sécurité, et constitue une voie de mentorat et de retour d'information pour les ingénieurs. C'est également l'une des activités les plus chronophages du processus de développement logiciel.

Duo Code Review représente la prochaine évolution du processus de revue de code.

Duo Code Review peut accélérer votre processus de développement. Lorsqu'il effectue une revue initiale de votre merge request, il peut aider à identifier les bugs potentiels et à suggérer d'autres améliorations, dont certaines peuvent être appliquées directement depuis votre navigateur. Utilisez-le pour itérer et améliorer vos modifications avant d'impliquer une autre personne dans le processus.

**Try it out:**

- Pour démarrer immédiatement une revue de code, ajoutez `@GitLabDuo` comme relecteur à votre merge request.
- Pour affiner le retour sur vos modifications, mentionnez `@GitLabDuo` dans un commentaire.

Vous pouvez suivre la progression future de Duo Code Review dans l'epic [13008](https://gitlab.com/groups/gitlab-org/-/epics/13008) et les epics enfants associés. Les retours peuvent être soumis dans le ticket [517386](https://gitlab.com/gitlab-org/gitlab/-/issues/517386).

### Root Cause Analysis disponible sur GitLab Duo Self-Hosted {#root-cause-analysis-available-on-gitlab-duo-self-hosted}

<!-- categories: Self-Hosted Models -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab Self-Managed
- Modules complémentaires : Duo Enterprise
- Liens : [Documentation](../../administration/gitlab_duo_self_hosted/_index.md#feature-versions-and-status) \| [Epic associé](https://gitlab.com/groups/gitlab-org/-/epics/13759)

{{< /details >}}

Vous pouvez désormais utiliser [GitLab Duo Root Cause Analysis](https://about.gitlab.com/blog/developing-gitlab-duo-blending-ai-and-root-cause-analysis-to-fix-ci-cd/) sur GitLab Duo Self-Hosted. Cette fonctionnalité est en version bêta pour les instances GitLab Self-Managed utilisant GitLab Duo Self-Hosted, avec prise en charge des familles de modèles Mistral, Anthropic et OpenAI GPT.

Avec Root Cause Analysis sur GitLab Duo Self-Hosted, vous pouvez résoudre plus rapidement les problèmes liés aux jobs échoués dans les pipelines CI/CD sans compromettre la souveraineté des données. Root Cause Analysis analyse le job log du job échoué, détermine rapidement la cause première de l'échec et vous suggère un correctif.

Remarque : cette fonctionnalité dispose actuellement de fonctionnalités limitées ; les fonctionnalités complètes sont prévues pour la version 17.11. Des informations complémentaires sont disponibles dans la [documentation de dépannage](../../administration/gitlab_duo_self_hosted/troubleshooting.md#feature-not-accessible-or-feature-button-not-visible) et dans le ticket [527128](https://gitlab.com/gitlab-org/gitlab/-/issues/527128).

Merci de laisser vos retours sur Root Cause Analysis pour GitLab Duo Self-Hosted dans le [ticket 523912](https://gitlab.com/gitlab-org/gitlab/-/issues/523912).

### Régions AWS supplémentaires disponibles pour les instances de basculement GitLab Dedicated {#expanded-aws-regions-available-for-gitlab-dedicated-failover-instances}

<!-- categories: GitLab Dedicated, Switchboard -->

{{< details >}}

- Édition : Gold
- Liens : [Documentation](../../administration/dedicated/create_instance/data_residency_high_availability.md)

{{< /details >}}

Les clients de GitLab Dedicated peuvent désormais sélectionner dans une liste élargie de régions AWS l'emplacement où héberger leur instance de basculement pour la [reprise après sinistre](../../administration/dedicated/disaster_recovery.md).

L'extension de la prise en charge du basculement à des régions supplémentaires permet aux clients de GitLab Dedicated d'utiliser pleinement les fonctionnalités de reprise après sinistre de GitLab Dedicated, quelle que soit la région AWS qu'ils doivent utiliser pour satisfaire leurs besoins en matière de résidence des données.

Ces régions nouvellement disponibles sont uniquement destinées à l'hébergement d'instances de basculement, car elles ne prennent pas entièrement en charge certaines fonctionnalités AWS dont GitLab Dedicated dépend.

### Vues GitLab Query Language en version bêta {#gitlab-query-language-views-beta}

<!-- categories: Wiki, Team Planning -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/glql/_index.md#embedded-views) \| [Epic associé](https://gitlab.com/groups/gitlab-org/-/epics/14938)

{{< /details >}}

Le suivi et la compréhension des travaux en cours dans GitLab nécessitaient auparavant de naviguer entre plusieurs emplacements, ce qui réduisait l'efficacité des équipes et consommait un temps précieux.

Cette release introduit les vues GitLab Query Language (GLQL) en version bêta, vous permettant de créer un suivi du travail dynamique et en temps réel directement dans vos workflows existants.

Les vues GLQL intègrent des requêtes de données en direct dans des blocs de code Markdown dans les pages Wiki, les descriptions d'epics, les commentaires de tickets et les merge requests.

Précédemment disponibles en version expérimentale, les vues GLQL entrent désormais en version bêta avec la prise en charge d'un filtrage sophistiqué utilisant des expressions logiques et des opérateurs sur des champs clés, notamment le cessionnaire, l'auteur, le label et le jalon. Vous pouvez personnaliser la présentation de votre vue sous forme de tableaux ou de listes, contrôler les champs affichés et définir des limites de résultats pour créer des informations exploitables et ciblées pour votre équipe.

Les équipes peuvent désormais maintenir le contexte tout en accédant aux informations dont elles ont besoin, en créant une compréhension partagée et en améliorant la collaboration, le tout sans quitter leur workflow actuel.

[Nous accueillons vos retours](https://gitlab.com/gitlab-org/gitlab/-/issues/509791) sur les vues GLQL, car nous continuons à améliorer cette fonctionnalité.

### Expérience Markdown améliorée {#enhanced-markdown-experience}

<!-- categories: Markdown -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/markdown.md) \| [Epic associé](https://gitlab.com/groups/gitlab-org/-/epics/7654)

{{< /details >}}

GitLab Flavored Markdown a été enrichi de plusieurs améliorations importantes :

- **Improved math and image handling** :
  - Désactivez les limites de [rendu des formules mathématiques](../../user/markdown.md#math-equations) dans votre groupe ou votre instance auto-hébergée pour gérer des expressions mathématiques plus complexes.
  - Contrôlez précisément les [dimensions des images](../../user/markdown.md#change-image-or-video-dimensions) à l'aide de valeurs en pixels ou en pourcentages pour mieux gérer la mise en page du contenu.
- **Enhanced editor experience** :
  - Continuez automatiquement les listes en appuyant sur Entrée/Retour.
  - Décalez le texte vers la gauche ou la droite à l'aide de raccourcis clavier.
  - Créez des paires terme-définition claires en utilisant la syntaxe des listes de description.
  - Ajustez la largeur des vidéos de manière flexible.
- **Better content organization** :
  - Naviguez plus facilement dans le contenu grâce aux [vues rapides de résumé](../../user/markdown.md#show-item-summary) à expansion automatique (ajoutez `+s` aux URL).
  - Affichez automatiquement le rendu des [titres de tickets](../../user/markdown.md#show-item-title) référencés (ajoutez `+` aux URL).
  - Organisez le contenu de manière modulaire à l'aide de la [syntaxe `include`](../../user/markdown.md#includes).
  - Créez des légendes et des avertissements visuellement distincts à l'aide des [boîtes d'alerte](../../user/markdown.md#alerts).

Ces améliorations rendent GitLab Flavored Markdown plus puissant pour les équipes qui créent et maintiennent de la documentation, tout en offrant une plus grande flexibilité dans la façon dont le contenu est présenté et organisé.

### Nouvelle visualisation des performances DevOps avec les métriques DORA sur les projets {#new-visualization-of-devops-performance-with-dora-metrics-across-projects}

<!-- categories: Value Stream Management, DORA Metrics -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/analytics/value_streams_dashboard.md#projects-by-dora-metric) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/408516)

{{< /details >}}

Nous sommes ravis d'introduire le panneau **Projects by DORA metric**, un nouvel ajout au [tableau de bord Value Streams](https://www.youtube.com/watch?v=EA9Sbks27g4). Ce tableau répertorie tous les projets dans le groupe principal, avec une répartition en [quatre métriques DORA](https://about.gitlab.com/solutions/value-stream-management/dora/#overview). Les responsables peuvent utiliser ce tableau pour identifier les projets à performance élevée, moyenne et faible. Ces informations peuvent également aider à prendre des décisions basées sur les données, à allouer les ressources efficacement et à se concentrer sur les initiatives qui améliorent la vitesse, la stabilité et la fiabilité de la livraison logicielle.

Les [métriques DORA](../../user/analytics/dora_metrics.md) sont disponibles de manière native dans GitLab, et désormais, combinées au panneau [**DORA Performers score**](https://about.gitlab.com/blog/inside-dora-performers-score-in-gitlab-value-streams-dashboard/), les dirigeants disposent d'une vue complète sur la santé DevOps de leur organisation, de haut en bas.

### Le nouveau look des tickets est désormais en version bêta {#new-issues-look-now-in-beta}

<!-- categories: Team Planning -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/project/issues/_index.md)

{{< /details >}}

Les tickets partagent désormais un cadre commun avec les epics et les tâches, avec des mises à jour en temps réel et des améliorations du workflow :

- **Drawer view:** Ouvrez des éléments depuis des listes ou des tableaux dans un tiroir pour une consultation rapide sans quitter votre contexte actuel. Un bouton en haut vous permet de passer en affichage pleine page.
- **Change type:** Convertissez les types entre epics, tickets et tâches à l'aide de l'action « Changer le type » (remplace « Promouvoir en epic »)
- **Date de début :** Les tickets prennent désormais en charge les dates de début, alignant leur fonctionnalité avec les epics et les tâches.
- **Ancestry:** La hiérarchie complète est affichée au-dessus du titre et le champ Parent figure dans la barre latérale. Pour gérer les relations, utilisez les nouvelles commandes d'[action rapide](../../user/project/quick_actions.md) `/set_parent`, `/remove_parent`, `/add_child` et `/remove_child`.
- **Controls:** Toutes les actions sont désormais accessibles depuis le menu supérieur (points de suspension verticaux), qui reste visible dans l'en-tête épinglé lors du défilement.
- **Development:** Tous les éléments de développement (merge requests, branches et feature flags) liés à un ticket ou une tâche sont désormais regroupés dans une liste unique et pratique.
- **Layout:** Les améliorations de l'interface créent une expérience plus fluide entre les tickets, les epics, les tâches et les merge requests, vous aidant à naviguer dans votre workflow plus efficacement.
- **Linked items:** Créez des relations entre tâches, tickets et epics grâce à des options de liaison améliorées. Glissez-déposez pour modifier les types de lien et basculer la visibilité des labels et des éléments fermés.

### Modèles de description pour les epics, tickets, tâches, objectifs et résultats clés {#description-templates-for-epics-issues-tasks-objectives-and-key-results}

<!-- categories: Portfolio Management -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/project/description_templates.md) \| [Epic associé](https://gitlab.com/groups/gitlab-org/-/epics/16088)

{{< /details >}}

Vous pouvez désormais simplifier votre workflow et maintenir la cohérence dans vos projets grâce aux modèles de description pour les éléments de travail (epics, tâches, objectifs et résultats clés).

Cet ajout puissant vous permet de créer des modèles standardisés, vous faisant gagner du temps et garantissant que toutes les informations essentielles sont incluses à chaque fois que vous créez un nouvel élément de travail.

### Modifier la gravité d'une vulnérabilité {#change-the-severity-of-a-vulnerability}

<!-- categories: Vulnerability Management -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/application_security/vulnerability_report/_index.md#change-or-override-vulnerability-severity) \| [Ticket associé](https://gitlab.com/groups/gitlab-org/-/epics/16157)

{{< /details >}}

Lors du triage des vulnérabilités, vous avez besoin de la flexibilité nécessaire pour ajuster les niveaux de gravité en fonction du contexte de sécurité unique de votre organisation et de sa tolérance au risque. Jusqu'à présent, vous deviez vous fier aux niveaux de gravité par défaut attribués par les scanners de sécurité, qui pouvaient ne pas refléter avec précision le niveau de risque pour votre environnement spécifique.

Vous pouvez désormais modifier manuellement la gravité d'occurrences de vulnérabilités spécifiques pour mieux l'aligner avec les besoins de sécurité de votre organisation. Cela vous permet de :

- Ajuster le niveau de gravité de toute vulnérabilité à **Critique**, **Niveau élevé**, **Niveau moyen**, **Niveau faible**, **Infos** ou **Inconnu(e)**.
- Modifier la gravité de plusieurs vulnérabilités à la fois depuis le rapport de vulnérabilités.
- Identifier facilement les vulnérabilités dont les niveaux de gravité sont personnalisés grâce à des indicateurs visuels.

Toutes les modifications de gravité sont suivies dans l'historique des vulnérabilités et les événements d'audit, et ne peuvent être remplacées que par les membres de votre équipe disposant au minimum du rôle Maintainer pour le projet, ou d'un rôle personnalisé avec la permission `admin_vulnerability`. Cette fonctionnalité offre aux équipes de sécurité plus de flexibilité et de contrôle sur la priorisation des vulnérabilités.

## Agentic Core {#agentic-core}

### GitLab Duo Chat est désormais redimensionnable {#gitlab-duo-chat-is-now-resizable}

<!-- categories: Duo Chat -->

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Modules complémentaires : Duo Pro, Duo Enterprise
- Liens : [Documentation](../../user/gitlab_duo_chat/_index.md#use-gitlab-duo-chat-in-the-gitlab-ui) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/499849)

{{< /details >}}

Dans l'interface GitLab, vous pouvez désormais redimensionner le tiroir Duo Chat. Cela facilite la consultation des sorties de code, ou le maintien de Chat ouvert tout en travaillant avec GitLab en arrière-plan.

### Gérer plusieurs conversations dans GitLab Duo Chat {#manage-multiple-conversations-in-gitlab-duo-chat}

<!-- categories: Duo Chat -->

{{< details >}}

- Édition : Silver, Gold
- Offre : GitLab.com
- Modules complémentaires : Duo Pro, Duo Enterprise
- Liens : [Documentation](../../user/gitlab_duo_chat/_index.md#have-multiple-conversations) \| [Epic associé](https://gitlab.com/groups/gitlab-org/-/epics/16108)

{{< /details >}}

Il est désormais plus facile de maintenir le contexte sur différents sujets dans GitLab Duo Chat grâce aux conversations multiples. Vous pouvez créer de nouvelles conversations, parcourir votre historique de conversations et passer d'une conversation à l'autre.

Auparavant, démarrer une nouvelle conversation signifiait perdre le contexte de votre conversation existante. Désormais, vous pouvez gérer plusieurs conversations sur différents sujets. Chaque conversation maintient son propre contexte, de sorte que, par exemple, vous pouvez poser des questions de suivi sur des explications de code dans une conversation, tout en préparant un plan de travail dans une autre conversation.

Lorsque vous avez besoin de revenir sur des discussions précédentes, sélectionnez la nouvelle icône d'historique des discussions pour voir toutes vos conversations récentes. Les conversations sont automatiquement organisées par activité la plus récente, ce qui facilite la reprise là où vous vous étiez arrêté.

Pour protéger votre vie privée, les conversations sans activité pendant 30 jours sont automatiquement supprimées, et vous pouvez supprimer manuellement n'importe quelle conversation à tout moment.

Cette fonctionnalité est actuellement disponible uniquement sur GitLab.com dans l'interface web. Elle n'est pas disponible dans les instances GitLab Self-Managed ni dans les intégrations IDE.

Partagez votre expérience avec nous dans le [ticket 526013](https://gitlab.com/gitlab-org/gitlab/-/issues/526013).

### Sélectionner des modèles pour les fonctionnalités basées sur l'IA sur GitLab Duo Self-Hosted {#select-models-for-ai-powered-features-on-gitlab-duo-self-hosted}

<!-- categories: Self-Hosted Models -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab Self-Managed
- Modules complémentaires : Duo Enterprise
- Liens : [Documentation](../../administration/gitlab_duo_self_hosted/configure_duo_features.md#select-a-self-hosted-model-for-a-feature) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/524174)

{{< /details >}}

Sur GitLab Duo Self-Hosted, vous pouvez désormais sélectionner des modèles pris en charge individuellement pour chaque sous-fonctionnalité de GitLab Duo Chat sur votre instance auto-hébergée. La sélection et la configuration des modèles pour les sous-fonctionnalités de Chat sont désormais en version bêta.

Pour laisser un retour, accédez au [ticket 524175](https://gitlab.com/gitlab-org/gitlab/-/issues/524175).

### Tableau de bord AI Impact disponible sur GitLab Duo Self-Hosted Code Suggestions {#ai-impact-dashboard-available-on-gitlab-duo-self-hosted-code-suggestions}

<!-- categories: Self-Hosted Models, Value Stream Management, DORA Metrics -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab Self-Managed
- Liens : [Documentation](../../user/analytics/duo_and_sdlc_trends.md) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/523807)

{{< /details >}}

Vous pouvez désormais utiliser le tableau de bord AI Impact avec GitLab Duo Self-Hosted Code Suggestions sur votre instance auto-hébergée pour vous aider à comprendre l'impact de GitLab Duo sur votre productivité. Le tableau de bord AI Impact est en version bêta avec GitLab Duo Self-Hosted, et vous pouvez utiliser cette fonctionnalité avec votre instance auto-hébergée et les IDE Visual Studio Code, Microsoft Visual Studio, JetBrains et Neovim.

Utilisez le tableau de bord AI Impact pour comparer les tendances d'utilisation de l'IA avec des métriques telles que le délai de réalisation, le temps de cycle, DORA et les vulnérabilités. Cela vous permet de mesurer le temps économisé dans votre flux de travail de bout en bout à l'aide de GitLab Duo Self-Hosted, tout en restant concentré sur les résultats métier plutôt que sur l'activité des développeurs.

Merci de laisser vos retours sur le tableau de bord AI Impact dans le [ticket 456105](https://gitlab.com/gitlab-org/gitlab/-/issues/456105).

### Modèles Meta Llama 3 disponibles pour GitLab Duo Self-Hosted Code Suggestions et Chat {#meta-llama-3-models-available-for-gitlab-duo-self-hosted-code-suggestions-and-chat}

<!-- categories: Self-Hosted Models -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab Self-Managed
- Modules complémentaires : Duo Enterprise
- Liens : [Documentation](../../administration/gitlab_duo_self_hosted/supported_models_and_hardware_requirements.md#supported-models) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/523917)

{{< /details >}}

Vous pouvez désormais utiliser certains modèles Meta Llama 3 avec GitLab Duo Self-Hosted. Ces modèles sont en version bêta pour GitLab Duo Self-Hosted afin de prendre en charge GitLab Duo Chat et Code Suggestions.

Merci de laisser vos retours sur l'utilisation de ces modèles avec GitLab Duo Self-Hosted dans le [ticket 523912](https://gitlab.com/gitlab-org/gitlab/-/issues/523917).

## Mise à l'échelle et déploiements {#scale-and-deployments}

### Horodatages de création des utilisateurs temporaires {#timestamps-of-when-placeholder-users-were-created}

<!-- categories: Importers -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/import/mapping/post_migration_mapping.md#placeholder-user-attributes) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/507297)

{{< /details >}}

Auparavant, lorsque vous importiez des groupes ou des projets, vous ne pouviez pas voir quand les [utilisateurs temporaires](../../user/import/mapping/post_migration_mapping.md#placeholder-users) avaient été créés. Avec cette release, nous avons ajouté des horodatages pour vous permettre de suivre la progression de votre migration et de résoudre les problèmes au fur et à mesure qu'ils surviennent.

### Modification en masse des éléments de la liste de tâches {#bulk-edit-to-do-items}

<!-- categories: Notifications -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/todos.md#bulk-edit-to-do-items) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/16564)

{{< /details >}}

Vous pouvez désormais gérer efficacement votre liste de tâches grâce à notre fonctionnalité de modification en masse améliorée. Sélectionnez plusieurs éléments de la liste de tâches et marquez-les comme terminés ou mettez-les en attente en une seule fois, ce qui vous donne plus de contrôle sur vos tâches et vous aide à rester organisé avec moins d'effort.

### Mettre en attente des éléments de la liste de tâches {#snooze-to-do-items}

<!-- categories: Notifications -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/todos.md#snooze-to-do-items) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/17712)

{{< /details >}}

Vous pouvez désormais mettre en attente les notifications dans votre liste de tâches, ce qui vous permet de masquer temporairement des éléments et de vous concentrer sur ce qui est le plus important à ce moment. Que vous ayez besoin d'une heure pour vous concentrer ou que vous souhaitiez revenir sur une tâche demain, vous disposez d'un contrôle précis sur le moment où les notifications réapparaissent, ce qui vous aide à gérer votre workflow plus efficacement.

### Demander une réaffectation à l'aide d'un fichier CSV {#request-reassignment-by-using-a-csv-file}

<!-- categories: Importers -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/import/mapping/reassignment.md#request-reassignment-by-using-a-csv-file) \| [Epic associé](https://gitlab.com/groups/gitlab-org/-/epics/16765)

{{< /details >}}

Avec cette release, le mappage des contributions des utilisateurs prend désormais en charge la réaffectation en masse à l'aide d'un fichier CSV. Si vous avez une large base d'utilisateurs avec de nombreux utilisateurs temporaires, les membres du groupe disposant du rôle Owner peuvent :

1. Télécharger un modèle CSV prérempli.
1. Ajouter des noms d'utilisateur GitLab ou des e-mails publics de l'instance de destination.
1. Téléverser le fichier complété pour réaffecter toutes les contributions en une seule fois.

Cette méthode élimine la réaffectation manuelle fastidieuse via l'interface utilisateur. Pour simplifier davantage les migrations à grande échelle, la prise en charge de l'API pour la réaffectation basée sur CSV est désormais également disponible.

### Nouvelle expérience de navigation pour les projets dans Votre travail {#new-navigation-experience-for-projects-in-your-work}

<!-- categories: Groups & Projects -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/project/working_with_projects.md) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/465889)

{{< /details >}}

Nous sommes ravis d'annoncer des améliorations significatives de la vue d'ensemble des projets dans **Your Work**, conçues pour simplifier la façon dont vous découvrez et accédez à vos projets. Cette mise à jour introduit un système de navigation par onglets plus intuitif qui reflète mieux la façon dont les utilisateurs interagissent avec leurs projets.

- Le nouvel onglet **Contribué** (anciennement **Yours**) affiche désormais tous les projets auxquels vous avez contribué, y compris vos projets personnels, ce qui facilite le suivi de votre activité de développement.
- Retrouvez vos projets individuels plus rapidement avec l'onglet **Personnel**, désormais mis en avant dans la navigation principale.
- Accédez aux projets d'équipe via l'onglet **Membre** (anciennement **Tous**), affichant tous les projets dont vous êtes membre.
- L'onglet **Inactif** (anciennement **Suppression en attente**) offre désormais une vue complète des projets archivés et de ceux en attente de suppression.

De plus, si vous disposez des permissions appropriées, vous pouvez désormais modifier ou supprimer un projet directement depuis la vue d'ensemble des projets de **Your Work**. Ces changements témoignent de notre engagement à créer une expérience GitLab plus efficace et conviviale. La nouvelle mise en page vous aide à vous concentrer sur les projets les plus importants pour votre travail, en réduisant le temps passé à naviguer entre les différentes catégories de projets.

Nous apprécions vos commentaires sur cette mise à jour ! Rejoignez la discussion dans l'[epic 16662](https://gitlab.com/groups/gitlab-org/-/epics/16662) pour partager votre expérience avec le nouveau système de navigation.

### Amélioration des paramètres d'autorisation de création de projets {#improved-project-creation-permission-settings}

<!-- categories: Groups & Projects -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../administration/settings/visibility_and_access_controls.md#define-which-roles-can-create-projects) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/507410)

{{< /details >}}

Nous avons amélioré les paramètres d'autorisation de création de projets pour les rendre plus clairs, plus intuitifs et mieux alignés avec nos principes de sécurité. Les paramètres améliorés incluent :

- Renommer la liste déroulante « Protection de création de projet par défaut » en « Rôle minimum requis pour la création de projet » afin de mieux refléter l'objectif du paramètre.
- Renommer l'option de liste déroulante « Developers + Maintainers » en « Developers » pour plus de cohérence sur la plateforme.
- Réordonner les options de la liste déroulante du niveau d'accès le plus restrictif au moins restrictif.

Ces changements facilitent la compréhension et la configuration des rôles pouvant créer des projets dans vos groupes, aidant les administrateurs à appliquer les contrôles d'accès appropriés avec plus de confiance.

Merci à [@yasuk](https://gitlab.com/yasuk) pour cette contribution communautaire !

## DevOps et sécurité unifiés {#unified-devops-and-security}

### Prise en charge de l'analyse des dépendances pour le gestionnaire de paquets pub (Dart) {#dependency-scanning-support-for-pub-dart-package-manager}

<!-- categories: Software Composition Analysis -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/application_security/dependency_scanning/legacy_dependency_scanning/_index.md#supported-languages-and-package-managers) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/342468)

{{< /details >}}

L'analyse des dépendances a ajouté la prise en charge de pub, le gestionnaire de paquets officiel pour Dart. Cette prise en charge a été ajoutée à notre [dernier modèle](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Jobs/Dependency-Scanning.latest.gitlab-ci.yml) d'analyse des dépendances et au [composant CI/CD](https://gitlab.com/explore/catalog/components/dependency-scanning).

Cet ajout est une contribution de la communauté de l'un de nos utilisateurs, Alexandre Laroche. L'équipe GitLab Composition Analysis apprécie cette contribution pour améliorer notre produit, un grand merci, Alexandre. Si vous souhaitez en savoir plus sur la contribution à GitLab, consultez notre [programme de contribution communautaire](https://about.gitlab.com/community/contribute/).

### Sélectionner un cadre de conformité par défaut depuis la liste déroulante sur la page Frameworks {#select-a-compliance-framework-as-default-from-the-dropdown-list-on-the-frameworks-page}

<!-- categories: Compliance Management -->

{{< details >}}

- Édition : Ultimate, Premium
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/compliance/compliance_center/compliance_frameworks_report.md#set-and-remove-a-compliance-framework-as-default) \| [Epic associé](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/181500)

{{< /details >}}

Les utilisateurs peuvent définir un cadre de conformité par défaut dans le centre de conformité GitLab, qui est appliqué à tous les nouveaux projets et aux projets importés créés dans ce groupe. Un cadre de conformité par défaut possède un label **par défaut** pour aider les utilisateurs à l'identifier.

Pour faciliter la définition d'un cadre de conformité par défaut, nous introduisons la possibilité pour les utilisateurs de définir un cadre par défaut en utilisant la liste déroulante des frameworks sur la page de liste des frameworks dans le centre de conformité d'un groupe principal. Cette fonctionnalité n'est pas disponible dans le centre de conformité des sous-groupes ni des projets.

### Ignorer des révisions spécifiques dans Git blame {#ignore-specific-revisions-in-git-blame}

<!-- categories: Source Code Management -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/project/repository/files/git_blame.md#ignore-specific-revisions)

{{< /details >}}

Lors de la consultation de l'historique d'un dépôt, il peut y avoir des commits qui ne sont pas pertinents pour des modifications autrement significatives dans le projet. Cela peut se produire lors de :

- Refactorisations où vous passez d'une bibliothèque à une autre sans modifier les fonctionnalités.
- Implémentation de formateurs de code ou de linters qui nécessitent la standardisation de l'ensemble de la base de code.

Lorsque vous parcourez l'historique d'un projet avec `blame`, ce type de commits rend difficile la compréhension des modifications survenues. Git prend en charge l'identification de ces commits avec un fichier `.git-blame-ignore-revs` dans votre projet. GitLab vous permet désormais de basculer la vue blame pour afficher ou masquer ces révisions spécifiques dans la liste déroulante « Blame preferences », ce qui facilite la compréhension de l'historique de votre projet.

### Exclusions de chemins pour CODEOWNERS {#path-exclusions-for-codeowners}

<!-- categories: Source Code Management, Code Review Workflow -->

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/project/codeowners/reference.md#exclusion-patterns)

{{< /details >}}

Lorsque les équipes configurent un fichier `CODEOWNERS`, il est courant d'inclure des modèles de correspondance larges pour les chemins et les types de fichiers. Ces configurations larges peuvent être problématiques si votre documentation, vos fichiers de build automatisés ou d'autres modèles ne nécessitent pas de propriétaire du code spécifié.

Vous pouvez désormais configurer le fichier `CODEOWNERS` avec des exclusions de chemins pour ignorer certains chemins. Cela est utile lorsque vous souhaitez exclure des fichiers ou des chemins spécifiques de l'obligation d'approbation d'un propriétaire du code.

### Paramètres de squash configurables dans les règles de branche {#configurable-squash-settings-in-branch-rules}

<!-- categories: Source Code Management, Code Review Workflow -->

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/project/repository/branches/branch_rules.md#edit-squash-commits-option)

{{< /details >}}

Différents workflows Git nécessitent différentes stratégies pour gérer les commits lors de la fusion entre branches. Dans les versions précédentes de GitLab, vous ne pouviez définir qu'une seule stratégie pour décider si les commits devaient être regroupés lors de la fusion et dans quelle mesure cela devait être appliqué. Cette configuration pouvait être source d'erreurs ou obliger les développeurs à faire des choix spécifiques pour respecter les conventions du projet selon les cibles de branche.

Vous pouvez désormais configurer les paramètres de squash pour chaque branche protégée via les règles de branche. Par exemple, vous pouvez :

- Exiger le squash lors de la fusion depuis votre branche `feature` vers la branche `develop` pour conserver un historique propre.
- Désactiver le squash lors de la fusion depuis la branche `develop` vers la branche `main` lorsque vous souhaitez que l'historique des commits reste intact.

Cette flexibilité garantit un historique de commits cohérent dans votre projet tout en respectant les besoins spécifiques de chaque branche dans votre workflow, sans nécessiter d'intervention manuelle de la part des développeurs.

### Distribution élargie pour les notifications d'expiration de jetons {#wider-distribution-for-token-expiration-notifications}

<!-- categories: System Access -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/group/manage.md#expiry-emails-for-group-and-project-access-tokens) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/463016)

{{< /details >}}

Auparavant, les e-mails de notification d'expiration de jeton d'accès n'étaient envoyés qu'aux membres directs du groupe et du projet dans lequel le jeton expirait. Désormais, ces notifications sont également envoyées aux membres de groupe et de projet hérités, si le paramètre est activé. Cette distribution élargie facilite la gestion du jeton avant son expiration.

### Gestion des instructions `needs` dans les politiques d'exécution de pipeline pour la conformité {#handling-of-needs-statements-in-pipeline-execution-policies-for-compliance}

<!-- categories: Security Policy Management -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/application_security/policies/pipeline_execution_policies.md#pipeline_execution_policy-schema) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/469256)

{{< /details >}}

Pour renforcer votre contrôle sur l'exécution du pipeline, les jobs appliqués dans l'étape réservée `.pipeline-policy-pre` doivent désormais se terminer avant que les jobs des étapes suivantes puissent commencer, que le job définisse ou non des instructions `needs`. Auparavant, les jobs définis dans l'étape `.pipeline-policy-pre` et les jobs dans les pipelines suivants avec une instruction `needs` démarraient tous dès que le pipeline s'exécutait. Grâce à cette amélioration, les jobs dans les étapes suivantes doivent attendre que `.pipeline-policy-pre` soit terminé avant de démarrer tout autre job sans dépendances, vous aidant à appliquer une exécution ordonnée et à garantir la conformité dans les politiques de sécurité.

Nos clients s'appuient sur les étapes réservées pour appliquer les contrôles de conformité et de sécurité avant l'exécution des jobs des développeurs. Un cas d'utilisation courant est l'application d'un contrôle de sécurité ou de conformité qui fait échouer l'ensemble du pipeline si le contrôle ne réussit pas. Permettre aux jobs de s'exécuter dans le désordre pourrait contourner cette application et affaiblir l'intention de la politique. Cette amélioration vous offre une approche plus cohérente de l'application de la conformité.

Pour injecter des jobs au début du pipeline sans remplacer le comportement de `needs`, configurez les jobs pour qu'ils utilisent une étape personnalisée avec la nouvelle fonctionnalité d'étapes personnalisées que nous avons introduite dans la version 17.9.

### S'authentifier aux Pages privées avec un jeton d'accès {#authenticate-to-private-pages-with-an-access-token}

<!-- categories: Pages -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/project/pages/pages_access_control.md#authenticate-with-an-access-token)

{{< /details >}}

Vous pouvez désormais vous authentifier aux sites GitLab Pages privés de manière programmatique à l'aide de jetons d'accès, ce qui facilite l'automatisation des interactions avec le contenu de vos Pages. Auparavant, l'accès aux sites Pages restreints nécessitait une authentification interactive via l'interface GitLab.

Cette amélioration puissante augmente la productivité tout en maintenant la sécurité, offrant aux développeurs plus de flexibilité dans la façon dont ils interagissent avec et distribuent le contenu des Pages privées.

### Nouvelles informations sur les tendances de GitLab Duo Code Suggestions et GitLab Duo Chat {#new-insights-into-gitlab-duo-code-suggestions-and-gitlab-duo-chat-trends}

<!-- categories: Value Stream Management -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Modules complémentaires : Duo Enterprise
- Liens : [Documentation](../../user/analytics/duo_and_sdlc_trends.md) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/477246)

{{< /details >}}

Le panneau de métriques de comparaison IA sur le tableau de bord AI Impact fournit désormais un suivi mois par mois (MoM) pour le taux d'acceptation de GitLab Duo Code Suggestions et l'utilisation de GitLab Duo Chat (MoM%). Ces nouvelles informations basées sur les tendances complètent les tuiles Duo Code Suggestions et Duo Chat existantes, qui fournissent un instantané de 30 jours de ces métriques. Grâce à ces métriques supplémentaires, les responsables peuvent mieux mesurer l'impact de l'IA sur leurs processus de développement logiciel et identifier des tendances, en comparant le taux d'acceptation de Code Suggestions et l'utilisation de Duo Chat avec d'autres métriques SDLC dans le temps.

### Authentification Docker Hub pour le proxy de dépendances {#docker-hub-authentication-for-the-dependency-proxy}

<!-- categories: Container Registry -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed
- Liens : [Documentation](../../user/packages/dependency_proxy/_index.md#authenticate-with-docker-hub) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/331741)

{{< /details >}}

Le proxy de dépendances GitLab pour les images de conteneurs prend désormais en charge l'authentification avec Docker Hub, vous aidant à éviter les échecs de pipeline dus aux limites de débit et vous donnant accès aux images privées.

À partir du 1er avril 2025, Docker Hub appliquera des limites de téléchargement plus strictes (100 par fenêtre de 6 heures par adresse IPv4 ou sous-réseau IPv6 /64) pour les utilisateurs non authentifiés. Sans authentification, vos pipelines pourraient échouer une fois ces limites atteintes.

Avec cette release, vous pouvez configurer l'authentification Docker Hub via l'API GraphQL en utilisant vos identifiants Docker Hub, votre [jeton d'accès personnel](https://docs.docker.com/security/access-tokens/) ou vos [jetons d'accès d'organisation](https://docs.docker.com/enterprise/security/access-tokens/). La prise en charge de la configuration via l'interface utilisateur sera disponible dans GitLab 17.11.

### Le registre de paquets ajoute des événements d'audit {#package-registry-adds-audit-events}

<!-- categories: Package Registry -->

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/compliance/audit_event_types.md) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/329588)

{{< /details >}}

Les opérations du registre de paquets sont désormais enregistrées comme événements d'audit afin que les équipes puissent suivre quand les paquets sont publiés ou supprimés pour respecter les exigences de conformité.

Avant cette release, il n'existait aucun moyen intégré de suivre qui publiait ou modifiait les paquets. Les équipes devaient créer leurs propres systèmes de suivi ou documenter manuellement les modifications de paquets pour maintenir des journaux de ces activités. Désormais, chaque événement d'audit indique qui a effectué une modification, quand cela s'est produit, comment ils ont été authentifiés et exactement ce qui a changé dans le paquet.

Les événements d'audit pour les projets sont stockés soit dans un espace de nommage de groupe, soit dans le projet lui-même pour les propriétaires de projets individuels. Les groupes peuvent désactiver les événements d'audit pour gérer les besoins de stockage.

### Trier les jetons d'accès dans l'inventaire des identifiants {#sort-access-tokens-in-credentials-inventory}

<!-- categories: System Access -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../administration/credentials_inventory.md) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/513181)

{{< /details >}}

Vous pouvez désormais trier les jetons d'accès personnels, de projets et de groupes dans l'inventaire des identifiants par propriétaire, date de création et date de dernière utilisation. Cela vous aide à localiser et identifier vos jetons d'accès plus rapidement. Merci à [Chaitanya Sonwane](https://gitlab.com/chaitanyason9) pour votre contribution !

### Identifier et révoquer des jetons avec l'API d'informations sur les jetons {#identify-and-revoke-tokens-with-token-information-api}

<!-- categories: System Access -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed
- Liens : [Documentation](../../api/admin/token.md) \| [Epic associé](https://gitlab.com/groups/gitlab-org/-/epics/15777)

{{< /details >}}

Les administrateurs GitLab peuvent désormais utiliser une API unifiée pour identifier et révoquer des jetons. Auparavant, les administrateurs devaient utiliser des points de terminaison liés au type spécifique de jeton. Cette API permet la révocation quel que soit le type. Pour obtenir la liste des types de jetons pris en charge, consultez l'[API d'informations sur les jetons](../../api/admin/token.md).

Merci à [Nicholas Wittstruck](https://gitlab.com/nwittstruck) et à l'équipe de Siemens pour votre contribution !

### Durée de jeton configurable avec le fournisseur GitLab OIDC {#configurable-token-duration-with-gitlab-oidc-provider}

<!-- categories: System Access -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed
- Liens : [Documentation](../../administration/auth/oidc.md#configure-a-custom-duration-for-id-tokens) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/377654)

{{< /details >}}

Lorsque vous utilisez GitLab comme fournisseur OpenID Connect (OIDC), vous pouvez désormais configurer la durée des jetons d'identification avec l'attribut `id_token_expiration`. Auparavant, les jetons d'identification avaient une durée d'expiration fixe de 120 secondes.

Merci à [Henry Sachs](https://gitlab.com/DerAstronaut) pour votre contribution !

### Mapper les attributs de profil OmniAuth à l'utilisateur {#map-omniauth-profile-attributes-to-user}

<!-- categories: User Management -->

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed
- Liens : [Documentation](../../integration/omniauth.md#keep-omniauth-user-profiles-up-to-date) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/505575)

{{< /details >}}

Vous pouvez désormais mapper les attributs de profil Organisation et Titre d'un fournisseur d'identité (IdP) OmniAuth vers le profil GitLab d'un utilisateur. Cela permet à l'IdP d'être la source unique de vérité pour ces attributs, et les utilisateurs ne peuvent plus les modifier.

### Déclencheurs de webhook étendus pour les jetons expirant {#extended-webhook-triggers-for-expiring-tokens}

<!-- categories: System Access -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/group/manage.md#add-additional-webhook-triggers-for-group-access-token-expiration) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/499732)

{{< /details >}}

Vous pouvez désormais déclencher des événements de webhook 60 et 30 jours avant l'expiration d'un jeton d'accès de projet ou de groupe. Auparavant, ces événements de webhook ne se déclenchaient que 7 jours avant l'expiration. Il s'agit d'un paramètre facultatif qui correspond au calendrier de notification par e-mail existant pour les jetons expirant.

### GitLab Runner 17.10 {#gitlab-runner-1710}

<!-- categories: GitLab Runner Core -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed
- Liens : [Documentation](https://docs.gitlab.com/runner)

{{< /details >}}

Nous publions également GitLab Runner 17.10 aujourd'hui ! GitLab Runner est l'agent de build hautement évolutif qui exécute vos jobs CI/CD et envoie les résultats à une instance GitLab. GitLab Runner fonctionne en conjonction avec GitLab CI/CD, le service d'intégration continue open source inclus avec GitLab.

#### Nouveautés {#whats-new}

- [Effectuer un contrôle d'état de l'exécuteur Autoscaler avant l'utilisation de l'instance](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/38271)
- [Développer les volumes de l'exécuteur Docker](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/38249)
- [Ajouter une configuration de l'exécuteur Docker pour l'ajout de périphériques pour les services](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/6208)

#### Corrections de bugs {#bug-fixes}

- [L'image Windows `gitlab-runner-helper` échoue en raison d'une spécification de volume invalide pour le chemin `/opt/step-runner'](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/38632)
- [La mise en miroir du dépôt pour les paquets RPM ne fonctionne pas correctement dans GitLab Runner 17.7.0 et versions ultérieures](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/38409)
- [L'exécution de `git submodule update --remote` dans GitLab CI/CD retourne une erreur](https://gitlab.com/gitlab-org/gitlab/-/issues/359825)

La liste de toutes les modifications se trouve dans le [CHANGELOG](https://gitlab.com/gitlab-org/gitlab-runner/blob/17-10-stable/CHANGELOG.md) de GitLab Runner.

## Sujets connexes {#related-topics}

- [Correctifs de bugs](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=type%3A%3Abug&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=17.10)
- [Améliorations des performances](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=bug%3A%3Aperformance&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=17.10)
- [Améliorations de l'interface utilisateur](https://papercuts.gitlab.com/?milestone=17.10)
- [Dépréciations et suppressions](../../update/deprecations.md)
- [Notes de mise à niveau](../../update/versions/_index.md)
