---
stage: Verify
group: Runner Core
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: "Bonnes pratiques pour l'utilisation de l'intégration GitLab avec Kubernetes"
---

L'agent pour Kubernetes et Flux offrent ensemble la meilleure expérience lors du déploiement vers Kubernetes via GitOps. GitLab recommande d'utiliser GitOps (également connu sous le nom de déploiement basé sur la récupération) pour les déploiements. Cependant, votre entreprise pourrait ne pas être en mesure de passer à GitOps, ou vous pourriez avoir certaines raisons (généralement hors production) d'utiliser une approche basée sur les pipelines. Cette page décrit les bonnes pratiques pour l'utilisation de GitOps en entreprise, avec quelques considérations pour les déploiements basés sur les pipelines.

Pour une description des avantages de GitOps, consultez [l'initiative OpenGitOps](https://opengitops.dev/about/).

## GitOps {#gitops}

- Bien que [Commencer à connecter un cluster Kubernetes à GitLab](getting_started.md) montre comment installer Flux à l'aide de la CLI Flux, pour mettre à l'échelle et automatiser les déploiements Flux, vous devez effectuer l'une des opérations suivantes :
  - Utilisez l'[opérateur Flux](https://github.com/controlplaneio-fluxcd/flux-operator).
  - Installez avec [Terraform](https://registry.terraform.io/providers/fluxcd/flux/latest/docs) ou [OpenTofu](https://search.opentofu.org/provider/fluxcd/flux/latest).
- Configurez Flux avec le [verrouillage multi-tenant](https://fluxcd.io/flux/installation/configuration/multitenancy/).
- Pour la mise à l'échelle, Flux prend en charge le partitionnement [vertical](https://fluxcd.io/flux/installation/configuration/vertical-scaling/) et [horizontal](https://fluxcd.io/flux/installation/configuration/sharding/).
- Pour des conseils spécifiques à Flux, consultez les [guides Flux](https://fluxcd.io/flux/guides/) dans la documentation Flux.
- Pour simplifier la maintenance, vous devriez exécuter une seule installation de l'agent GitLab pour Kubernetes par cluster. Vous pouvez partager la connexion de l'agent avec les fonctionnalités d'usurpation d'identité dans tout le domaine GitLab.
- Envisagez d'utiliser le `OCIRepository` Flux pour stocker et récupérer des manifestes. Vous pouvez utiliser les pipelines GitLab pour créer et envoyer les images OCI vers le registre de conteneurs.
- Pour raccourcir la boucle de rétroaction, déclenchez une réconciliation GitOps immédiate depuis le pipeline GitLab associé.
- Vous devriez signer les images OCI générées et déployer uniquement les images signées et vérifiées par Flux.
- Assurez-vous de faire régulièrement tourner les clés utilisées par Flux pour accéder aux manifestes. Vous devriez également faire régulièrement tourner votre jeton d'enregistrement d'agent.

### Conteneurs OCI {#oci-containers}

Lorsque vous utilisez des conteneurs OCI à la place de dépôts Git, la source de vérité pour les manifestes reste le dépôt Git. Vous pouvez considérer le conteneur OCI comme une couche de mise en cache entre le dépôt Git et le cluster.

L'utilisation de conteneurs OCI présente plusieurs avantages :

- OCI a été conçu pour la scalabilité. Bien que les dépôts Git de GitLab se mettent bien à l'échelle, ils n'ont pas été conçus pour ce cas d'utilisation.
- Un seul dépôt Git peut être la source de plusieurs conteneurs OCI, chacun regroupant un petit ensemble de manifestes. Ainsi, si vous avez besoin de récupérer un ensemble de manifestes, vous n'avez pas besoin de télécharger l'intégralité du dépôt Git.
- Les dépôts OCI peuvent suivre un schéma de versionnage bien connu, et Flux peut être configuré pour se mettre à jour automatiquement en suivant ce schéma. Par exemple, si vous utilisez la gestion sémantique de version, Flux peut déployer automatiquement toutes les modifications mineures et les correctifs, tandis que les versions majeures nécessitent une mise à jour manuelle.
- Les images OCI peuvent être signées, et la signature peut être vérifiée par Flux.
- Les dépôts OCI peuvent être analysés par le registre de conteneurs, même après la création de l'image.
- Le job qui crée le conteneur OCI permet d'utiliser des fonctionnalités bien connues de gestion des releases que les outils GitOps classiques ne prennent pas en charge, comme les [environnements protégés](../../../ci/environments/protected_environments.md), les [approbations de déploiement](../../../ci/environments/deployment_approvals.md) et les [fenêtres de gel du déploiement](../../project/releases/_index.md#prevent-unintentional-releases-by-setting-a-deploy-freeze).

## Déploiements basés sur les pipelines {#pipeline-based-deployments}

Si vous devez utiliser un déploiement basé sur les pipelines, suivez ces bonnes pratiques :

- Pour réduire le nombre d'agents déployés par cluster, partagez la connexion de l'agent entre vos groupes et projets. Si possible, n'utilisez qu'un seul déploiement d'agent par cluster.
- Utilisez l'usurpation d'identité et minimisez l'accès des jobs CI/CD dans le cluster en utilisant le RBAC Kubernetes standard.
