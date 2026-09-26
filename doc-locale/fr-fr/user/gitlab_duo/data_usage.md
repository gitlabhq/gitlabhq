---
stage: AI Platform
group: AI Core Infra
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: Fonctionnalités et fonctions natives IA.
title: Utilisation des données GitLab Duo
---

GitLab Duo utilise l'IA générative pour vous aider à augmenter votre vélocité et à améliorer votre productivité. Chaque fonctionnalité native IA fonctionne de manière indépendante et n'est pas requise pour que les autres fonctionnalités fonctionnent.

GitLab utilise les grands modèles de langage (LLM) adaptés à des tâches spécifiques. Ces LLM sont [Anthropic Claude](https://claude.com/product/overview), [Fireworks AI-hosted Codestral](https://mistral.ai/news/codestral/), [les modèles Gemini Enterprise Agent Platform](https://docs.cloud.google.com/gemini-enterprise-agent-platform/models/beginners-guide) et [les modèles OpenAI](https://platform.openai.com/docs/models).

## Amélioration progressive {#progressive-enhancement}

Les fonctionnalités natives IA de GitLab Duo sont conçues comme une amélioration progressive des fonctionnalités GitLab existantes sur l'ensemble de la plateforme DevSecOps. Ces fonctionnalités sont conçues pour échouer de manière progressive et ne doivent pas empêcher les fonctionnalités principales de la fonctionnalité sous-jacente. Notez que chaque fonctionnalité est soumise à son fonctionnement attendu tel que défini par la [politique de support des fonctionnalités](../../policy/development_stages_support.md) applicable.

## Stabilité et performances {#stability-and-performance}

Les fonctionnalités natives IA de GitLab Duo se trouvent dans différents [niveaux de support des fonctionnalités](../../policy/development_stages_support.md#beta). En raison de la nature de ces fonctionnalités, la demande d'utilisation peut être élevée, ce qui peut entraîner une dégradation des performances ou des interruptions inattendues de la fonctionnalité. Nous avons conçu ces fonctionnalités pour qu'elles se dégradent progressivement et nous disposons de contrôles permettant d'atténuer les abus ou les utilisations abusives. GitLab peut désactiver les fonctionnalités en version bêta et expérimentale pour tout ou partie des clients à tout moment, à sa discrétion.

## Confidentialité des données {#data-privacy}

Les fonctionnalités natives IA de GitLab Duo sont alimentées par des modèles d'IA générative. GitLab traite toute donnée personnelle conformément à la [Déclaration de confidentialité de GitLab](https://about.gitlab.com/privacy/).

Pour obtenir la liste des sous-traitants de modèles IA utilisés par GitLab pour fournir ces fonctionnalités, consultez [les sous-traitants tiers](https://about.gitlab.com/privacy/subprocessors/#third-party-sub-processors).

## Conservation des données {#data-retention}

### Sous-traitants de modèles {#model-sub-processors}

Pour les requêtes GitLab Duo, GitLab applique une politique de rétention zéro des données avec Fireworks AI. Fireworks AI supprime les données d'entrée et de sortie du modèle immédiatement après la fourniture des résultats et ne stocke pas les données d'entrée et de sortie à des fins de surveillance des abus. L'exception à cette politique s'applique lorsque la mise en cache des invites est activée pour GitLab Duo Code Suggestions et GitLab Duo Agentic Chat. Pour les modèles OpenAI, vous ne pouvez pas désactiver la mise en cache des invites.

Certains modèles Anthropic et OpenAI, y compris lorsqu'ils sont hébergés sur Amazon Bedrock et Gemini Enterprise Agent Platform, sont soumis à une conservation limitée des données côté fournisseur. Pour plus d'informations sur ces modèles, consultez [les modèles IA pris en charge pour GitLab Duo Agent Platform](../duo_agent_platform/model_selection.md#supported-models).

### GitLab {#gitlab}

GitLab Duo Chat et GitLab Duo Agent Platform conservent l'historique des discussions et des workflows pour vous permettre de retrouver rapidement des sujets abordés précédemment. Vous pouvez supprimer des discussions dans l'interface GitLab Duo Chat. Sur GitLab.com, GitLab conserve l'historique des discussions et des workflows à des fins de lutte contre les abus. GitLab ne conserve pas les données d'entrée et de sortie, sauf si les clients donnent leur consentement via un [ticket d'assistance GitLab](https://about.gitlab.com/support/portal/).

Lorsque vous activez la journalisation étendue pour GitLab Duo Agent Platform, GitLab conserve les données de trace. Les informations de journalisation relatives aux fonctionnalités IA sont distinctes de toute politique de rétention zéro des données avec les sous-traitants de modèles IA de GitLab. Pour plus d'informations, consultez [le système de journalisation GitLab](../../administration/logs/_index.md).

## Entraînement des modèles {#model-training}

GitLab n'entraîne pas de modèles d'IA générative.

Tous les sous-traitants de modèles IA de GitLab sont interdits d'utiliser les données d'entrée et de sortie des modèles pour entraîner des modèles. Ces sous-traitants sont liés à GitLab par des accords de protection des données qui interdisent l'utilisation du contenu client à leurs propres fins, sauf pour s'acquitter de leurs obligations légales indépendantes.

## Télémétrie {#telemetry}

GitLab Duo collecte des données d'utilisation agrégées ou anonymisées de première partie via un collecteur Snowplow. Ces données d'utilisation incluent les métriques suivantes :

- Nombre d'utilisateurs uniques
- Nombre d'instances uniques
- Longueurs des invites et des suffixes
- Modèle utilisé
- Réponses aux codes de statut
- Temps de réponse de l'API
- Code Suggestions collecte également :
  - Langage de la suggestion (par exemple, Python)
  - Éditeur utilisé (par exemple, VS Code)
  - Nombre de suggestions affichées, acceptées, rejetées ou ayant généré des erreurs
  - Durée d'affichage d'une suggestion

## Serveur GitLab Model Context Protocol {#gitlab-model-context-protocol-server}

Les informations suivantes s'appliquent à l'utilisation du [serveur GitLab Model Context Protocol (MCP)](../model_context_protocol/mcp_server.md) dans les instances GitLab Self-Managed.

GitLab ne transmet, ne stocke, ne conserve ni ne traite aucune donnée lorsque le serveur GitLab MCP est utilisé. Toutes les communications s'effectuent directement entre le client MCP et le serveur GitLab MCP dans votre environnement.

Les données et métadonnées du dépôt ne sont pas envoyées à GitLab.

Vous contrôlez quels clients MCP se connectent à votre instance. Les politiques de confidentialité et de conservation des données propres à chaque client s'appliquent.

## Précision et qualité des modèles {#model-accuracy-and-quality}

L'IA générative peut produire des résultats inattendus, qui peuvent être :

- De faible qualité
- Incohérents
- Incomplets
- Des pipelines en échec
- Du code non sécurisé
- Offensants ou insensibles
- Des informations obsolètes

GitLab itère activement sur toutes nos capacités assistées par IA pour améliorer la qualité du contenu généré. Nous améliorons la qualité grâce à l'ingénierie des invites, à l'évaluation de nouveaux modèles IA/ML pour alimenter ces fonctionnalités, et grâce à des heuristiques innovantes intégrées directement dans ces fonctionnalités.

## Détection des secrets et rédaction {#secret-detection-and-redaction}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/issues/632) dans GitLab 17.9.

{{< /history >}}

GitLab Duo inclut la [détection des secrets et la rédaction](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/blob/main/docs/developer/secret-redaction.md) lors de l'exécution des flows. Selon le scénario, GitLab Duo détecte et supprime automatiquement les informations sensibles telles que les clés API, les identifiants et les jetons de votre code avant de le traiter avec des grands modèles de langage.

Votre code est soumis à un workflow de sécurité de pré-analyse lors de l'utilisation de GitLab Duo :

1. Votre code est analysé pour détecter les informations sensibles à l'aide de Gitleaks.
1. Tout secret détecté est automatiquement supprimé de la requête.

L'analyse des secrets s'exécute dans les scénarios suivants :

- Transformation du contexte de complétion de code (avant l'envoi du contexte à l'IA)
- Transformation du contexte IA
- Résultats des outils de workflow
- Saisie utilisateur dans Agentic Chat
- Journalisation des commandes Git
- Journalisation de la configuration CLI

> [!note]
> L'analyse des secrets n'est pas effectuée lorsque vous interagissez avec GitLab Duo Chat via l'interface web.

### Exception : Secret false positive detection {#exception-secret-false-positive-detection}

[Secret false positive detection](../application_security/vulnerabilities/secret_false_positive_detection.md) est une fonctionnalité opt-in qui envoie des informations sur la vulnérabilité, y compris le contexte du code entourant les secrets détectés, aux LLM à des fins d'analyse. Il s'agit d'une exception délibérée au comportement de [détection des secrets et de rédaction](#secret-detection-and-redaction).

Cette fonctionnalité étant opt-in, vous devez l'activer explicitement au niveau du groupe et du projet avant que des données de vulnérabilité ne soient envoyées aux LLM. Passez en revue les politiques de données de votre organisation avant d'activer cette fonctionnalité.

## Partager les données d'utilisation du groupe avec GitLab {#share-group-usage-data-with-gitlab}

{{< history >}}

- [Introduction](https://gitlab.com/gitlab-org/gitlab/-/issues/587976) dans GitLab 18.9.1.

{{< /history >}}

Pour contribuer à améliorer la qualité du service, vous pouvez partager avec GitLab des données sur l'utilisation des fonctionnalités GitLab Duo Agent Platform.

Une fois la collecte de données activée, les interactions IA de tous les projets et sous-groupes de votre espace de nommage sont journalisées avec GitLab. Ces données servent exclusivement à améliorer le service et à en assurer le débogage, et non à entraîner des modèles d'IA.

Vous pouvez également activer la collecte des données d'utilisation [pour une instance](../../administration/gitlab_duo/configure/_index.md#share-usage-data-with-gitlab)

Prérequis :

- Disposer de GitLab 18.9.1 ou version ultérieure.
- Disposer du rôle Owner pour un groupe principal.
- Sur GitLab.com, votre groupe doit [avoir GitLab Duo activé](turn_on_off.md#turn-gitlab-duo-on-or-off).

Pour activer la collecte de données pour votre groupe :

1. Dans la barre supérieure, sélectionnez **Rechercher ou accéder à**, puis recherchez votre groupe.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **GitLab Duo**.
1. Sélectionnez **Modifier la configuration**.
1. Sous **Collecte de données**, cochez la case **Collecter les données d'utilisation**.
1. Sélectionnez **Enregistrer les modifications**.

### Données d'utilisation d'Agent Platform {#agent-platform-usage-data}

Lorsque vous activez la collecte de données, les données suivantes sont journalisées :

- Texte complet des invites et des réponses issues des interactions avec GitLab Duo.
- Contexte de session, y compris les sessions en cours au moment de l'activation du paramètre.
- Métadonnées du modèle (version du modèle, nombre de jetons, latence).
- Appels d'outils et leurs résultats.
- Identifiants de session pour la corrélation avec les retours utilisateurs.

Les informations suivantes ne sont pas incluses dans les journaux, sauf si les utilisateurs les incluent dans leurs propres invites :

- Identifiants utilisateur ou noms d'utilisateur.
- Adresses e-mail ou identifiants personnels.
- Identifiants de projet ou d'espace de nommage.

GitLab ne supprime pas les identifiants que les utilisateurs ont inclus dans leur invite.

## Mise en cache des prompts {#prompt-caching}

La mise en cache des invites améliore la latence en évitant le retraitement des données d'invite et d'entrée mises en cache. Lorsque vous activez la mise en cache des invites, le fournisseur du modèle stocke temporairement les données d'invite en mémoire. Les données mises en cache ne sont jamais enregistrées dans un stockage persistant.

Pour les fonctionnalités d'Agent Platform utilisant le registre d'invites et pour Code Suggestions, la mise en cache des jetons est automatiquement activée pour les modèles pris en charge.

### Désactiver la mise en cache des invites {#turn-off-prompt-caching}

Par défaut, la mise en cache des invites est activée. Vous pouvez désactiver la mise en cache des invites pour un groupe principal ou une instance.

{{< tabs >}}

{{< tab title="Pour un groupe principal" >}}

Prérequis :

- Disposer du rôle Propriétaire pour le groupe principal.

1. Dans la barre supérieure, sélectionnez **Rechercher ou accéder à**, puis recherchez votre groupe.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **GitLab Duo**.
1. Sélectionnez **Modifier la configuration**.
1. Dans la section **Données et vie privée**, sous **Cache d'invites**, décochez la case **Activer la mise en cache des invites**.
1. Sélectionnez **Enregistrer les modifications**.

{{< /tab >}}

{{< tab title="Pour une instance" >}}

Prérequis :

- Accès administrateur.

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **GitLab Duo**.
1. Sélectionnez **Modifier la configuration**.
1. Dans la section **Données et vie privée**, sous **Cache d'invites**, décochez la case **Activer la mise en cache des invites**.
1. Sélectionnez **Enregistrer les modifications**.

{{< /tab >}}

{{< /tabs >}}
