---
stage: Application Security Testing
group: Dynamic Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Configuration hors ligne
---

{{< details >}}

- Édition : Ultimate
- Offre : GitLab Self-Managed

{{< /details >}}

Pour les instances dans un environnement avec un accès limité, restreint ou intermittent aux ressources externes via Internet, certains ajustements sont nécessaires pour que le job de test de fuzz de l'API web s'exécute correctement.

Étapes :

1. Hébergez l'image Docker dans un registre de conteneurs local.
1. Définissez `SECURE_ANALYZERS_PREFIX` sur le registre de conteneurs local.

L'image Docker pour le fuzz d'API doit être extraite (téléchargée) depuis le registre public, puis poussée (importée) dans un registre local. Le registre de conteneurs GitLab peut être utilisé pour héberger localement l'image Docker. Ce processus peut être effectué à l'aide d'un modèle spécial. Consultez [le chargement des images Docker sur votre hôte hors ligne](../../offline_deployments/_index.md#loading-docker-images-onto-your-offline-host) pour obtenir des instructions.

Une fois l'image Docker hébergée localement, la variable `SECURE_ANALYZERS_PREFIX` est définie avec l'emplacement du registre local. La variable doit être définie de sorte que la concaténation de `/api-security:2` aboutisse à un emplacement d'image valide.

Par exemple, la ligne ci-dessous définit un registre pour l'image `registry.gitlab.com/security-products/api-security:2` :

`SECURE_ANALYZERS_PREFIX: "registry.gitlab.com/security-products"`

> [!note]
> La définition de `SECURE_ANALYZERS_PREFIX` modifie l'emplacement du registre d'images Docker pour tous les modèles sécurisés GitLab.

Pour plus d'informations, consultez [Environnements hors ligne](../../offline_deployments/_index.md).
