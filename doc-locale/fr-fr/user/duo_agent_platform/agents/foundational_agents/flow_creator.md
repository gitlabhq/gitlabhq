---
stage: Agent Foundations
group: AI Catalog
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Flow Creator
---

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [Introduit](https://gitlab.com/groups/gitlab-org/-/work_items/22644) dans GitLab 19.3.

{{< /history >}}

Le Flow Creator est un agent d'IA spécialisé qui vous aide à créer des [flows personnalisés](../../flows/custom.md) pour le catalogue d'IA. Décrivez le flow que vous souhaitez en langage courant, et l'agent génère un flow YAML complet que vous pouvez utiliser dans le catalogue d'IA.

L'agent comprend le framework Flow Registry, notamment les composants, les déclencheurs, les entrées et le routage. Il consulte la documentation du framework en cours avant de répondre, de sorte que ses réponses reflètent les capacités actuelles du framework plutôt qu'un instantané figé.

Utilisez le Flow Creator dans les situations suivantes :

- Créer un flow : générer un flow YAML complet à partir de votre description de ce que le flow doit faire et comment il doit être déclenché.
- Déboguer un flow : déterminer pourquoi une configuration de flow existante échoue à la validation ou ne se comporte pas comme prévu.
- Comprendre le framework : découvrir quels composants, paramètres et déclencheurs sont disponibles, et comment les connecter entre eux.

## Utiliser le Flow Creator {#use-the-flow-creator}

Prérequis :

- [Activez](_index.md#turn-foundational-agents-on-or-off) les agents par défaut.

Pour utiliser le Flow Creator dans l'interface GitLab :

1. Dans la barre supérieure, sélectionnez **Rechercher ou accéder à** et repérez votre projet ou groupe.
1. Dans la barre latérale GitLab Duo, sélectionnez **Ajouter une discussion** ({{< icon name="pencil-square" >}}).
1. Dans la liste déroulante, sélectionnez **Flow Creator**.

   Une conversation Chat s'ouvre dans la barre latérale GitLab Duo située à droite de l'écran.
1. Décrivez le flow que vous souhaitez créer. Pour obtenir les meilleurs résultats :

   - Décrivez ce qui doit déclencher le flow, par exemple, être assigné à un ticket ou la création d'une nouvelle merge request.
   - Décrivez le résultat souhaité, et non les composants dont vous pensez avoir besoin. L'agent sélectionne les composants appropriés.
   - Lors du débogage, collez le flow YAML complet afin que l'agent puisse le valider par rapport aux règles du framework.
1. Copiez le flow YAML depuis la réponse de l'agent, puis collez-le dans l'écran [nouveau flow](../../flows/custom.md) d'un projet pour lequel vous disposez de l'autorisation de créer des flows.

## Exemples de prompts {#example-prompts}

- Créer un flow :
  - « Créer un flow qui résume un ticket lorsqu'il m'est assigné. »
  - « Créer un flow qui ajoute un label aux nouveaux tickets en fonction de la description du ticket. »
  - « Créer un flow qui me demande une approbation avant de commenter une merge request. »
- Déboguer un flow :
  - « Pourquoi cette configuration de flow échoue-t-elle à la validation ? `<flow YAML>` »
  - « Ce flow ne s'arrête jamais de s'exécuter. Quel est le problème ? `<flow YAML>` »
- Comprendre le fonctionnement des flows :
  - « Comment transmettre le nom de la branche dans mon flow ? »
  - « Quel composant utiliser pour demander une entrée à l'utilisateur en cours d'exécution d'un flow ? »

## Problèmes connus {#known-issues}

- L'agent génère du YAML uniquement pour le schéma Flow Registry v1.
- L'agent consulte la documentation du framework avant de répondre. Par conséquent, les réponses peuvent prendre plus de temps que celles d'autres agents.
