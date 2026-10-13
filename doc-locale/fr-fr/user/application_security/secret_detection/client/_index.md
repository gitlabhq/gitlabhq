---
stage: Application Security Testing
group: Secret Detection
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Détection des secrets côté client
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [Introduite](https://gitlab.com/gitlab-org/gitlab/-/issues/368434) dans GitLab 15.11.
- La détection des jetons d'accès personnels avec un préfixe personnalisé a été [introduite](https://gitlab.com/gitlab-org/gitlab/-/issues/411146) dans GitLab 16.1. GitLab Self-Managed uniquement.
- La détection des préfixes de jetons à l'échelle de l'instance a été [introduite](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/220122) dans GitLab 18.11. GitLab Self-Managed uniquement.

{{< /history >}}

Lorsque vous créez un ticket, ajoutez une description à une merge request ou rédigez un commentaire, vous pouvez accidentellement publier un secret. Par exemple, vous pourriez coller les détails d'une requête API ou d'une variable d'environnement contenant un jeton d'authentification. Si un secret est divulgué, un adversaire peut l'utiliser pour usurper l'identité d'un utilisateur légitime.

La détection des secrets côté client aide à minimiser le risque d'exposition accidentelle de secrets. Lorsque vous modifiez une description ou rédigez un commentaire dans un ticket ou une merge request, GitLab analyse automatiquement le contenu à la recherche de secrets.

## Workflow de détection des secrets {#secret-detection-workflow}

La détection des secrets côté client fonctionne entièrement dans votre navigateur à l'aide de la correspondance de motifs. Cette approche garantit les éléments suivants :

- Les secrets sont détectés avant d'être soumis à GitLab.
- Aucune information sensible n'est transmise pendant le processus de détection.
- La fonctionnalité fonctionne de manière transparente sans nécessiter de configuration supplémentaire.

## Premiers pas {#getting-started}

La détection des secrets côté client est activée par défaut pour toutes les éditions de GitLab. Aucune installation ni configuration n'est requise.

Pour tester cette fonctionnalité :

1. Accédez à un ticket ou une merge request
1. Ajoutez un commentaire contenant un motif de secret de test, tel que `glpat-xxxxxxxxxxxxxxxxxxxx`
1. Observez le message d'avertissement qui s'affiche avant de soumettre

Utilisez toujours des valeurs fictives lors de vos tests afin d'éviter d'exposer de vrais secrets.

## Couverture {#coverage}

La détection des secrets côté client analyse le contenu suivant :

- Descriptions et commentaires des tickets
- Descriptions et commentaires des merge requests

Pour des informations détaillées sur les types spécifiques de secrets détectés, consultez la documentation [Secrets détectés](../detected_secrets.md).

## Comprendre les résultats {#understanding-the-results}

Lorsque la détection des secrets côté client identifie un secret potentiel, GitLab affiche un avertissement mettant en évidence le secret détecté. Vous pouvez choisir l'une des deux options suivantes :

- **Modifier** le contenu du commentaire ou de la description pour supprimer le secret.
- **Ajouter** du contenu sans effectuer de modifications. Faites preuve de prudence avant d'ajouter du contenu susceptible de contenir un secret potentiel.

La détection s'effectue entièrement dans votre navigateur. Aucune information n'est transmise, sauf si vous sélectionnez **Ajouter**.

## Optimisation {#optimization}

Pour maximiser l'efficacité de la détection des secrets côté client :

- Examinez attentivement les avertissements. Examinez toujours le contenu signalé avant de continuer.
- Utilisez des valeurs fictives. Remplacez les vrais secrets par un texte fictif tel que `[REDACTED]` ou `<API_KEY>`.
