---
stage: Application Security Testing
group: Static Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Security Review Flow
description: "Identifiez les vulnérabilités de logique métier dans les merge requests avec l'IA."
---

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Statut : version bêta

{{< /details >}}

{{< history >}}

- [Introduction](https://gitlab.com/gitlab-org/gitlab/-/work_items/600301) dans GitLab 19.1. Cette fonctionnalité est en [version bêta](../../../../policy/development_stages_support.md#beta).

{{< /history >}}

Security Review Flow détecte les vulnérabilités de logique métier dans les merge requests. Contrairement aux outils d'analyse statique qui recherchent des patterns connus, Security Review Flow raisonne sur l'intention de votre code. Il identifie les vulnérabilités qui émergent d'hypothèses incorrectes concernant l'autorisation, l'exposition des données et le flux de contrôle.

Security Review Flow est un [flow par défaut](_index.md) développé sur la plateforme GitLab Duo Agent. Il fonctionne en parallèle avec [GitLab Duo Code Review](../../../gitlab_duo/code_review.md) et publie les résultats sous forme de commentaires diff en fil de discussion, chacun accompagné d'une classification CWE, d'une note de gravité, d'une explication et, lorsque c'est possible, d'une suggestion de correction en ligne que vous pouvez appliquer en une seule action.

> [!note]
> Les résultats de Security Review Flow sont générés par l'IA et constituent une contribution consultative, non une évaluation de sécurité faisant autorité ou exhaustive. Une revue qui ne signale aucun résultat ne prouve pas qu'une merge request est sécurisée, et les résultats peuvent inclure des faux positifs qui nécessitent un jugement humain. Pour plus d'informations, consultez [Limitations connues](#known-limitations).

Utilisez Security Review Flow lorsque vous avez besoin d'aide pour :

- Revue du contrôle d'accès : identifiez les vérifications d'autorisation manquantes ou mal configurées sur les opérations qui modifient l'état.
- Détection des lacunes d'autorisation : mettez en évidence les problèmes d'autorisation au niveau des objets et des fonctions.
- Analyse de la logique métier : détectez les failles dans les workflows applicatifs susceptibles d'être exploitées, comme les conditions de course dans les opérations financières ou avec état.
- Divulgation d'informations : identifiez les chemins de code susceptibles de faire fuiter des données sensibles vers des appelants non autorisés.
- Risque d'assignation de masse : signalez les endpoints ou les modèles susceptibles d'exposer des champs non intentionnels aux entrées utilisateur.

## Prérequis {#prerequisites}

Pour utiliser Security Review Flow :

- Disposer du rôle Développeur, Chargé de maintenance ou Propriétaire pour le projet.
- [Activez](_index.md#turn-foundational-flows-on-or-off) les flows par défaut et **Revue de sécurité** pour le groupe principal.
- [Activez GitLab Duo](../../../gitlab_duo/turn_on_off.md) pour le groupe ou l'instance.
- Si vous ne disposez pas de GitLab Duo Pro ou Enterprise, [activez GitLab Duo Core](../../../gitlab_duo/turn_on_off.md#turn-gitlab-duo-core-on-or-off) pour le groupe principal ou l'instance.
- Pour GitLab Self-Managed, [configurez GitLab Duo](../../../../administration/gitlab_duo/configure/_index.md) pour l'instance.
- Dans GitLab 18.8 et versions ultérieures, [activez Agent Platform](../../turn_on_off.md#turn-gitlab-duo-agent-platform-on-or-off) pour le groupe principal. Dans GitLab 18.7 et versions antérieures, [activez les fonctionnalités bêta et expérimentales](../../turn_on_off.md#turn-on-beta-and-experimental-features).

## Coût {#cost}

Security Review Flow utilise des [GitLab Credits](../../../../subscriptions/gitlab_credits.md) à chaque fois qu'il effectue une revue. L'utilisation des crédits évolue en fonction de la complexité du diff et du modèle que vous sélectionnez.

Les estimations suivantes s'appliquent au [modèle par défaut](../../../../user/duo_agent_platform/model_selection.md#default-models) :

| Complexité de la revue                        | Nombre approximatif d'appels LLM | Crédits estimés |
|------------------------------------------|-----------------------|-------------------|
| Petit diff ou quelques fichiers modifiés        | ~16                   | ~8                |
| Branche de fonctionnalité standard                  | ~28                   | ~14               |
| Modification multi-fichiers volumineuse ou à forte logique   | ~40                   | ~20               |

Pendant la version bêta, vous démarrez toujours les revues manuellement. Cela vous permet d'évaluer l'utilisation typique des crédits dans votre base de code avant une adoption plus large.

## Utiliser Security Review Flow {#use-security-review-flow}

### Demander une revue {#request-a-review}

Vous pouvez demander une revue à tout moment après la création d'une merge request. Lorsque vous demandez une revue, le flow analyse le diff de la merge request et son contexte environnant.

Le compte de service **Duo Security Review** est créé pour votre groupe principal lorsque le flow Security Review est activé, et est disponible pour tous les projets et sous-groupes qui en font partie. Le nom de chaque compte de service inclut le groupe principal associé, par exemple `duo-security-review-gitlab-org`.

Pour demander une revue :

1. Dans la barre latérale gauche, sélectionnez **Rechercher ou accéder à** et repérez votre projet.
1. Sélectionnez **Code** > **Requêtes de fusion** et ouvrez votre merge request.
1. Dans la section **Relecteur** de la barre latérale droite, sélectionnez **Éditer**.
1. Dans la zone de recherche, saisissez `Duo Security Review` et sélectionnez le compte dans la liste.

Une fois la revue terminée, le flow publie une note interne. La note résume les résultats éventuels et la portée de la revue. Si la revue ne produit aucun résultat, le flow l'indique dans la note interne.

Pour chaque résultat, le flow ouvre un fil de discussion diff à la ligne concernée. Si vous répondez à un fil de discussion (par exemple, pour accepter le risque ou contester l'évaluation), le flow lit votre réponse et réagit en conséquence. Sur les projets publics, les résultats sont publiés uniquement dans la note interne, sans commentaires diff en ligne. La publication privée des résultats évite d'exposer des détails de sécurité.

Le flow définit l'état du relecteur en fonction de la gravité des résultats. Le flow ne définit jamais l'état **Approuver**, même lorsqu'il ne trouve aucun problème :

| Gravité             | État du relecteur |
| -------------------- | -------------- |
| `critical` ou `high` | **Demander des modifications** |
| `medium` ou `low`    | **Commentaire**    |
| Aucune                 | **Commentaire**    |

### Répondre à un résultat {#respond-to-a-finding}

{{< history >}}

- La remise des réponses aux mentions a [changé](https://gitlab.com/gitlab-org/gitlab/-/work_items/604317) dans GitLab 19.2 [avec un flag](../../../../administration/feature_flags/_index.md) nommé `ai_use_messaging_adapter_for_mentions`. Désactivés par défaut.

{{< /history >}}

> [!flag]
> Un feature flag contrôle la disponibilité de cette fonctionnalité. Pour plus d'informations, consultez l'historique. Lorsque le flag est désactivé, une mention déclenche une revue complète au lieu d'une réponse ciblée. Pour plus d'informations, consultez [une mention déclenche une revue complète au lieu d'une réponse](#a-mention-starts-a-full-review-instead-of-a-reply).

Mentionnez le flow dans un fil de discussion pour poser des questions de clarification sur un résultat, discuter des approches de remédiation ou signaler un résultat comme faux positif. Le flow n'effectue pas de nouvelle revue complète lorsqu'il est mentionné.

Pour répondre à un résultat :

1. Dans la barre latérale gauche, sélectionnez **Rechercher ou accéder à** et repérez votre projet.
1. Sélectionnez **Code** > **Requêtes de fusion** et ouvrez votre merge request.
1. Dans n'importe quel fil de commentaires, saisissez `@duo-security-review` et sélectionnez **Duo Security Review** dans la liste.
1. Ajoutez votre message et sélectionnez **Commentaire**.

Security Review Flow lit le contexte du fil de discussion et répond directement.

### Examiner un résultat {#review-a-finding}

Security Review Flow se concentre sur les vulnérabilités au niveau logique fréquemment ignorées par les analyseurs statiques. Chaque résultat est publié sous forme de fil de discussion diff sur le code modifié. Chaque fil de discussion comprend :

- Le type de vulnérabilité (CWE) avec un lien vers la définition MITRE.
- Une note de gravité : `critical`, `high`, `medium` ou `low`.
- Une classification par niveau : niveau 1 (Exploitable), Niveau 2 (Faille logique) ou Niveau 3 (Problème de conception).
- Une explication de la faille logique.
- Une suggestion de correction, lorsque c'est possible.

> [!note]
> Les résultats ne sont pas suivis dans le [rapport de vulnérabilité](../../../application_security/vulnerability_report/_index.md) et ne sont pas pris en compte dans les [politiques d'approbation des merge requests](../../../application_security/policies/merge_request_approval_policies.md). Ils complètent les résultats de l'analyse statique (SAST), mais ne les remplacent pas.

Les classifications CWE suivantes peuvent apparaître dans les résultats :

| CWE | Description |
|-----|-------------|
| [CWE-639](https://cwe.mitre.org/data/definitions/639.html) | Contournement d'autorisation par clé contrôlée par l'utilisateur (BOLA / IDOR) |
| [CWE-862](https://cwe.mitre.org/data/definitions/862.html) | Autorisation manquante |
| [CWE-284](https://cwe.mitre.org/data/definitions/284.html) | Contrôle d'accès inapproprié |
| [CWE-200](https://cwe.mitre.org/data/definitions/200.html) | Exposition d'informations sensibles |
| [CWE-840](https://cwe.mitre.org/data/definitions/840.html) | Erreurs de logique métier |
| [CWE-915](https://cwe.mitre.org/data/definitions/915.html) | Modification incorrectement contrôlée des attributs d'objets déterminés dynamiquement (assignation de masse) |
| [CWE-362](https://cwe.mitre.org/data/definitions/362.html) | Conditions de course et vérification temporelle / utilisation temporelle (TOCTOU) |

### Résoudre un résultat {#resolve-a-finding}

Pour résoudre un résultat :

- Pour appliquer la correction, sélectionnez **Appliquer la suggestion**. Pour valider la suggestion dans une nouvelle branche, sélectionnez la liste déroulante à côté de **Appliquer la suggestion**.
- Pour ignorer le résultat, sélectionnez **Résoudre le fil de conversation** si vous avez examiné le résultat et déterminé qu'il s'agit d'un faux positif ou d'un risque accepté.
- Pour suivre la vulnérabilité en vue d'une remédiation future, utilisez les [actions de fil de discussion](../../../../user/project/merge_requests/_index.md#move-open-threads-to-an-issue) standard de GitLab pour créer un ticket à partir du résultat.
- Pour évaluer l'utilité du résultat, sélectionnez **thumbs up** ou **thumbs down**. Ce retour aide à améliorer le modèle. Vous pouvez également partager un retour détaillé dans [le ticket de retour](https://gitlab.com/gitlab-org/gitlab/-/issues/600304).

Pour demander une nouvelle revue après avoir résolu les résultats, réassignez le flow en tant que relecteur. Le flow analyse le diff mis à jour et effectue une action en fonction de l'état du résultat :

- Résultats résolus : le flow confirme la correction et résout le fil de discussion d'origine.
- Corrections incorrectes ou incomplètes : le flow identifie les modifications supplémentaires requises dans le fil de discussion d'origine.
- Résultats non traités : le fil de discussion d'origine reste ouvert sans commentaire supplémentaire.
- Nouveaux résultats : le flow détecte les nouvelles vulnérabilités par la correction et crée de nouveaux fils de commentaires pour celles-ci.

## Limitations connues {#known-limitations}

Prenez connaissance des limitations suivantes avant de vous fier aux résultats de Security Review Flow.

- Les résultats sont consultatifs, pas une garantie de couverture. Les résultats de Security Review Flow sont générés par l'IA. Le flow peut ne pas détecter chaque vulnérabilité dans une modification : son analyse fonctionne dans un budget de recherche et de lecture délimité, de sorte que les fichiers ou diffs très volumineux pourraient ne pas être entièrement examinés. Une revue qui ne signale aucun résultat ne prouve pas que la merge request est sécurisée.
- Les résultats peuvent inclure des faux positifs. Traitez les résultats comme des contributions nécessitant un jugement humain, et non comme un verdict définitif.
- Security Review Flow complète les autres outils. Il ne remplace pas la revue de sécurité humaine ni les autres outils de sécurité GitLab, tels que [SAST](../../../application_security/sast/_index.md) et [GitLab Advanced SAST](../../../application_security/sast/gitlab_advanced_sast.md).

## Dépannage {#troubleshooting}

Lorsque vous utilisez Security Review Flow, vous pouvez rencontrer les problèmes suivants.

### Le flow n'est pas disponible pour l'assignation {#the-flow-is-not-available-to-assign}

Le compte de service **Duo Security Review** est créé pour votre groupe principal lorsque le flow Security Review est activé. Le nom du compte de service inclut le nom du groupe principal, par exemple `duo-security-review-gitlab-org`.

Confirmez le statut du flow Security Review.

### Le flow ne fournit pas de résultats {#the-flow-does-not-provide-findings}

Confirmez que vous remplissez toutes les [conditions préalables](#prerequisites), puis vérifiez que le flow a été correctement assigné.

- Vérifiez que vous avez mentionné le compte **Duo Security Review** (son nom d'utilisateur commence par `@duo-security-review-`).
- Vérifiez que les paramètres [**Autoriser les flows par défaut**](_index.md#turn-foundational-flows-on-or-off) et [**Revue de code**](code_review.md) sont activés pour le groupe principal.
- Pour GitLab Self-Managed, vérifiez que votre instance est [configurée pour GitLab Duo](../../../../administration/gitlab_duo/configure/_index.md).

### Le flow n'examine pas chaque merge request {#the-flow-does-not-review-every-merge-request}

Pour exécuter ce scan de sécurité, vous devez déclencher manuellement le flow sur une merge request. Il ne s'exécutera pas automatiquement sur chaque merge request. Si vous avez assigné le flow mais n'avez reçu aucun résultat, consultez [Le flow ne fournit pas de résultats](#the-flow-does-not-provide-findings).

Lorsque le flow examine une merge request, un rapport sans résultats signifie généralement :

- Aucun problème de sécurité détecté : la logique du code a été analysée et aucune vulnérabilité n'a été identifiée.
- Aucune logique de sécurité pertinente : la modification ne contient pas de code ayant un impact sur la sécurité (par exemple, des mises à jour de documentation uniquement).

Remarque sur les modifications volumineuses : pour les merge requests volumineuses, le flow fonctionne dans un budget de recherche et de lecture délimité. Dans ces cas, le flow peut ne signaler aucun résultat ou produire des résultats tout en ne couvrant pas la totalité de la merge request, ce qui signifie que des vulnérabilités importantes pourraient être ignorées. Une revue complète ne garantit pas une couverture totale. Pour plus d'informations, consultez [Limitations connues](#known-limitations).

### Une mention déclenche une revue complète au lieu d'une réponse {#a-mention-starts-a-full-review-instead-of-a-reply}

Le flow répond à une mention par une réponse ciblée uniquement lorsque le feature flag `ai_use_messaging_adapter_for_mentions` est activé. Lorsque le flag est désactivé, une mention déclenche une revue complète de la merge request.

- Sur GitLab Self-Managed et GitLab Dedicated, un administrateur peut activer le feature flag nommé `ai_use_messaging_adapter_for_mentions`.
- Sur GitLab.com, ce flag est désactivé pendant que GitLab déploie la prise en charge des réponses. Jusqu'à la fin du déploiement, une mention déclenche une revue complète. Pour connaître l'état du déploiement, consultez [le ticket 602269](https://gitlab.com/gitlab-org/gitlab/-/issues/602269).

### Les modifications suggérées ne s'appliquent pas correctement {#suggested-changes-do-not-apply-cleanly}

Les suggestions sont générées par rapport au diff au moment de la revue. Si vous avez poussé de nouveaux commits après la revue, les numéros de ligne ont peut-être changé. Demandez une nouvelle revue pour obtenir des suggestions mises à jour par rapport au diff actuel.

### J'ai reçu une erreur concernant les GitLab Credits {#i-received-an-error-about-gitlab-credits}

Votre instance ou groupe a peut-être épuisé les [GitLab Credits](../../../../subscriptions/gitlab_credits.md) pour la période de facturation en cours. Contactez votre administrateur pour acheter des crédits supplémentaires, ou attendez que les crédits soient réinitialisés au début de la prochaine période de facturation.
