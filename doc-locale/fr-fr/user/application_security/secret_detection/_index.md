---
stage: Application Security Testing
group: Secret Detection
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Détection des secrets
description: "Détection, prévention, surveillance, stockage, révocation et signalement."
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Votre application peut utiliser des ressources externes, notamment un service CI/CD, une base de données ou un stockage externe. L'accès à ces ressources nécessite une authentification, généralement à l'aide de méthodes statiques telles que des clés privées et des jetons. Ces méthodes sont appelées « secrets » car elles ne sont pas destinées à être partagées avec quiconque.

Pour minimiser le risque d'exposition de vos secrets, [stockez toujours les secrets en dehors du dépôt](../../../ci/secrets/_index.md). Cependant, des secrets sont parfois accidentellement commités dans des dépôts Git. Après qu'une valeur sensible est poussée vers un dépôt distant, toute personne ayant accès au dépôt peut utiliser le secret pour usurper l'identité de l'utilisateur autorisé.

La détection des secrets surveille votre activité afin de :

- Contribuer à empêcher la fuite de vos secrets.
- Vous aider à réagir en cas de fuite d'un secret.

Vous devez adopter une approche de sécurité multicouche et activer toutes les méthodes de détection des secrets disponibles :

- [La protection push des secrets](secret_push_protection/_index.md) analyse les commits à la recherche de secrets lorsque vous poussez des modifications vers GitLab. Le push est bloqué si des secrets sont détectés, sauf si vous ignorez la protection push des secrets. Cette méthode réduit le risque de fuite des secrets.
- [La détection des secrets par pipeline](pipeline/_index.md) s'exécute dans le cadre du pipeline CI/CD d'un projet. Les commits vers la branche par défaut du dépôt sont analysés à la recherche de secrets. Si la détection des secrets par pipeline est activée dans les pipelines de merge request, les commits vers la branche de développement sont analysés à la recherche de secrets, ce qui vous permet de réagir avant qu'ils ne soient commités dans la branche par défaut.
- [La détection des secrets côté client](client/_index.md) analyse les descriptions et les commentaires des tickets et des merge requests à la recherche de secrets avant qu'ils ne soient enregistrés dans GitLab. Lorsqu'un secret est détecté, vous pouvez choisir de modifier la saisie et de supprimer le secret ou, s'il s'agit d'un faux positif, d'enregistrer la description ou le commentaire.

Si un secret est commité dans un dépôt, GitLab enregistre l'exposition dans le rapport de vulnérabilité. Pour certains types de secrets, GitLab peut même révoquer automatiquement le secret exposé. Vous devez toujours révoquer et remplacer les secrets exposés dès que possible. Pour obtenir des conseils de remédiation spécifiques aux secrets, consultez les détails fournis dans le rapport de vulnérabilité.

## Réduire les faux positifs avec GitLab Duo {#reducing-false-positives-with-gitlab-duo}

Les scanners de détection des secrets peuvent générer des faux positifs qui créent du bruit dans vos rapports de vulnérabilité. La fonctionnalité [de détection des faux positifs GitLab Duo](../vulnerabilities/secret_false_positive_detection.md) analyse automatiquement les résultats de détection des secrets afin d'identifier les faux positifs probables. Cela permet à votre équipe de sécurité de se concentrer sur les véritables secrets et de réduire le temps consacré au triage manuel.

Pour les clients GitLab Ultimate disposant d'un module complémentaire GitLab Duo, la détection des faux positifs s'exécute automatiquement après chaque analyse de sécurité et fournit des scores de confiance avec des explications pour chaque évaluation.

## Sujets connexes {#related-topics}

- [Exclusions de détection des secrets](exclusions.md)
- [Rapport de vulnérabilités](../vulnerability_report/_index.md)
- [Réponse automatique aux secrets divulgués](automatic_response.md)
- [Règles de push](../../project/repository/push_rules.md)
- [Secret false positive detection](../vulnerabilities/secret_false_positive_detection.md)
