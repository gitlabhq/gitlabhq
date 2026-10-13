---
stage: Security Risk Management
group: Security Insights
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: "Expliquer les vulnérabilités avec l'IA"
---

{{< details >}}

- Édition : GitLab Ultimate
- Module complémentaire : GitLab Duo Enterprise, GitLab Duo with Amazon Q
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< collapsible title="Informations sur le modèle" >}}

- [LLM par défaut](../../gitlab_duo/model_selection.md#default-models)
- LLM pour Amazon Q : Amazon Q Developer
- Disponible sur [GitLab Duo avec des modèles auto-hébergés](../../../administration/gitlab_duo_self_hosted/_index.md)

{{< /collapsible >}}

{{< history >}}

- [Introduit](https://gitlab.com/groups/gitlab-org/-/epics/10368) dans GitLab 16.0 en tant que [version expérimentale](../../../policy/development_stages_support.md#experiment) sur GitLab.com.
- Promu au statut de [version bêta](../../../policy/development_stages_support.md#beta) dans GitLab 16.2.
- [Disponibilité générale](https://gitlab.com/groups/gitlab-org/-/epics/10642) dans GitLab 17.2.
- À partir de GitLab 17.6, le module d'extension GitLab Duo est devenu obligatoire.

{{< /history >}}

GitLab Duo Vulnerability Explanation peut vous aider à gérer une vulnérabilité en utilisant un grand modèle de langage pour :

- Résumer la vulnérabilité.
- Aider les développeurs et les analystes en sécurité à comprendre la vulnérabilité, comment elle pourrait être exploitée et comment la corriger.
- Proposer une atténuation suggérée.

GitLab Duo peut également analyser automatiquement les vulnérabilités SAST de gravité critique et élevée pour identifier les faux positifs potentiels. Pour plus d'informations, consultez [Détection des faux positifs SAST](../vulnerabilities/false_positive_detection.md).

<i class="fa-youtube-play" aria-hidden="true"></i> [Visionner une présentation](https://www.youtube.com/watch?v=MMVFvGrmMzw&list=PLFGfElNsQthZGazU1ZdfDpegu0HflunXW)

Prérequis :

- Le rôle Développeur, Chargé de maintenance ou Propriétaire pour le projet.
- [GitLab Duo](../../gitlab_duo/turn_on_off.md) doit être activé pour le groupe ou l'instance.
- Vous devez être membre du projet.
- La vulnérabilité doit provenir d'un scanner SAST.

Pour expliquer la vulnérabilité :

1. Dans la barre supérieure, sélectionnez **Rechercher ou accéder à** et repérez votre projet.
1. Dans la barre latérale gauche, sélectionnez **Sécurisation** > **Rapport de vulnérabilités**.
1. Facultatif. Pour supprimer les filtres par défaut, sélectionnez **Effacer** ({{< icon name="clear" >}}).
1. Sélectionnez la barre de filtres située au-dessus de la liste des vulnérabilités.
1. Dans la liste déroulante qui apparaît, sélectionnez **Outil**, puis sélectionnez toutes les valeurs dans la catégorie **SAST**.
1. Cliquez en dehors du champ de filtre. Les totaux de vulnérabilités par niveau de gravité et la liste des vulnérabilités correspondantes sont mis à jour.
1. Sélectionnez la vulnérabilité SAST que vous souhaitez expliquer.
1. Effectuez l'une des opérations suivantes :

   - Sélectionnez le texte sous la description de la vulnérabilité qui indique _You can also use AI by asking GitLab Duo Chat to explain this vulnerability and a suggested fix._
   - En haut à droite, dans la liste déroulante **Résoudre avec une requête de fusion**, sélectionnez **Expliquer la vulnérabilité**, puis sélectionnez **Expliquer la vulnérabilité**.
   - Ouvrez GitLab Duo Chat et utilisez la commande [expliquer une vulnérabilité](../../gitlab_duo_chat/examples.md#explain-a-vulnerability) en saisissant `/vulnerability_explain`.

La réponse s'affiche sur le côté droit de la page.

Sur GitLab.com, cette fonctionnalité est disponible. Par défaut, cette fonctionnalité s'appuie sur le modèle [`claude-3-haiku`](https://docs.anthropic.com/en/docs/about-claude/models#claude-3-a-new-generation-of-ai) d'Anthropic. GitLab ne peut pas garantir que le grand modèle de langage produit des résultats corrects. Utilisez l'explication avec prudence.

## Données partagées avec les API d'IA tierces pour Vulnerability Explanation {#data-shared-with-third-party-ai-apis-for-vulnerability-explanation}

Les données suivantes sont partagées avec des API d'IA tierces :

- Titre de la vulnérabilité (qui peut contenir le nom de fichier, selon le scanner utilisé)
- Identifiants de la vulnérabilité
- Nom de fichier
