---
stage: Verify
group: Runner Core
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: "Connexion d'un cluster Kubernetes à GitLab"
description: "Intégration Kubernetes, GitOps, CI/CD, déploiement d'agent et gestion de cluster."
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Vous pouvez connecter votre cluster Kubernetes à GitLab pour déployer, gérer et surveiller vos solutions cloud-native.

Pour connecter un cluster Kubernetes à GitLab, vous devez d'abord [installer un agent dans votre cluster](install/_index.md).

L'agent s'exécute dans le cluster et vous pouvez l'utiliser pour :

- Communiquer avec un cluster se trouvant derrière un pare-feu ou un NAT.
- Accéder aux endpoints d'API d'un cluster en temps réel.
- Envoyer des informations sur les événements survenant dans le cluster.
- Activer un cache d'objets Kubernetes, maintenu à jour avec une latence très faible.

Pour plus de détails sur l'objectif et l'architecture de l'agent, consultez la [documentation sur l'architecture](https://gitlab.com/gitlab-org/cluster-integration/gitlab-agent/-/blob/master/doc/architecture.md).

Vous devez déployer un agent distinct pour chaque cluster que vous souhaitez connecter à GitLab. L'agent a été conçu avec un solide support multi-locataire. Pour simplifier la maintenance et les opérations, vous devriez exécuter un seul agent par cluster.

Un agent est toujours enregistré dans un projet GitLab. Une fois un agent enregistré et installé, la connexion de l'agent au cluster peut être partagée avec d'autres projets, groupes et utilisateurs. Cette approche signifie que vous pouvez gérer et configurer vos instances d'agent depuis GitLab lui-même, et vous pouvez faire évoluer une installation unique vers plusieurs locataires.

## Versions Kubernetes prises en charge pour les fonctionnalités GitLab {#supported-kubernetes-versions-for-gitlab-features}

GitLab prend en charge les versions Kubernetes suivantes. Si vous souhaitez exécuter GitLab dans un cluster Kubernetes, vous aurez peut-être besoin d'une version différente de Kubernetes :

- Pour le [Helm Chart](https://docs.gitlab.com/charts/installation/cloud/).
- Pour [GitLab Operator](https://docs.gitlab.com/operator/installation/).

Vous pouvez mettre à niveau votre version Kubernetes vers une version prise en charge à tout moment :

- 1.36 (la prise en charge prend fin lors de la release de GitLab version 20.2 ou lorsque la version 1.39 devient prise en charge)
- 1.35 (la prise en charge prend fin lors de la release de GitLab version 19.10 ou lorsque la version 1.38 devient prise en charge)
- 1.34 (la prise en charge prend fin lors de la release de GitLab version 19.7 ou lorsque la version 1.37 devient prise en charge)

GitLab vise à prendre en charge une nouvelle version mineure de Kubernetes trois mois après sa release initiale. GitLab prend en charge au moins trois versions mineures de Kubernetes prêtes pour la production à tout moment.

Lorsqu'une nouvelle version de Kubernetes est publiée :

- Cette page est mise à jour avec les résultats des premiers tests de fumée dans un délai d'environ quatre semaines.
- Si la prise en charge d'une nouvelle version Kubernetes est retardée, cette page est mise à jour avec la version GitLab de prise en charge attendue dans un délai d'environ huit semaines.

Lors de l'installation de l'agent, utilisez une version de Helm compatible avec votre version Kubernetes. D'autres versions de Helm pourraient ne pas fonctionner. Pour obtenir la liste des versions compatibles, consultez la [politique de prise en charge des versions Helm](https://helm.sh/docs/topics/version_skew/).

La prise en charge des API obsolètes peut être supprimée de la base de code GitLab lorsque GitLab ne prend plus en charge la version Kubernetes qui ne prend en charge que l'API obsolète.

Certaines fonctionnalités GitLab pourraient fonctionner sur des versions non répertoriées ici. [Cet epic](https://gitlab.com/groups/gitlab-org/-/epics/4827) suit la prise en charge des versions Kubernetes.

## Workflows de déploiement Kubernetes {#kubernetes-deployment-workflows}

Vous pouvez choisir parmi deux workflows principaux. Le workflow GitOps est recommandé.

### Workflow GitOps {#gitops-workflow}

GitLab recommande d'utiliser [Flux pour GitOps](gitops.md). Pour commencer, consultez [Tutoriel : configurer Flux pour GitOps](getting_started.md).

### Workflow GitLab CI/CD {#gitlab-cicd-workflow}

Dans un [workflow **CI/CD**](ci_cd_workflow.md), vous configurez GitLab CI/CD pour utiliser l'API Kubernetes afin d'interroger et de mettre à jour votre cluster.

Ce workflow est considéré comme **push-based**, car GitLab envoie des requêtes depuis GitLab CI/CD vers votre cluster.

Utilisez ce workflow :

- Lorsque vous avez des processus pilotés par pipeline.
- Lorsque vous devez migrer vers l'agent, mais que le workflow GitOps ne prend pas en charge votre cas d'usage.

Ce workflow présente un modèle de sécurité plus faible. Vous ne devriez pas utiliser un workflow CI/CD pour les déploiements en production.

## Détails techniques de la connexion de l'agent {#agent-connection-technical-details}

L'agent ouvre un canal bidirectionnel vers KAS pour la communication. Ce canal est utilisé pour toutes les communications entre l'agent et KAS :

- Chaque agent peut maintenir jusqu'à 500 flux gRPC logiques, y compris les flux actifs et inactifs.
- Le nombre de connexions TCP utilisées par les flux gRPC est déterminé par gRPC lui-même.
- Chaque connexion a une durée de vie maximale de deux heures, avec une période de grâce d'une heure.
  - Un proxy devant KAS peut influencer la durée de vie maximale des connexions. Sur GitLab.com, celle-ci est de [deux heures](https://gitlab.com/gitlab-cookbooks/gitlab-haproxy/-/blob/68df3484087f0af368d074215e17056d8ab69f1c/attributes/default.rb#L217). La période de grâce représente 50 % de la durée de vie maximale.

Pour des informations détaillées sur le routage des canaux, consultez [Routage des requêtes KAS dans l'agent](https://gitlab.com/gitlab-org/cluster-integration/gitlab-agent/-/blob/master/doc/kas_request_routing.md).

## Agents réceptifs {#receptive-agents}

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab Self-Managed

{{< /details >}}

{{< history >}}

- [Introduit](https://gitlab.com/groups/gitlab-org/-/work_items/12180) dans GitLab 17.4.

{{< /history >}}

Les agents réceptifs permettent à GitLab de s'intégrer aux clusters Kubernetes qui ne peuvent pas établir de connexion réseau vers l'instance GitLab, mais auxquels GitLab peut se connecter. Par exemple, cela peut se produire lorsque :

1. GitLab s'exécute dans un réseau privé ou derrière un pare-feu, et n'est accessible que via VPN.
1. Le cluster Kubernetes est hébergé par un fournisseur cloud, mais est exposé à Internet ou est accessible depuis le réseau privé.

Lorsque cette fonctionnalité est activée, GitLab se connecte à l'agent avec l'URL fournie. Vous pouvez utiliser des agents et des agents réceptifs simultanément.

## Glossaire de l'intégration Kubernetes {#kubernetes-integration-glossary}

Ce glossaire fournit des définitions pour les termes relatifs à l'intégration GitLab Kubernetes.

| Terme | Définition | Portée |
| --- | --- | --- |
| Agent GitLab pour Kubernetes | L'offre globale, incluant les fonctionnalités associées et les composants sous-jacents `agentk` et `kas`. | GitLab, Kubernetes, Flux |
| `agentk` | Le composant côté cluster qui maintient une connexion sécurisée à GitLab pour la gestion de Kubernetes et l'automatisation des déploiements. | GitLab |
| Serveur d'agent GitLab pour Kubernetes (`kas`) | Le composant côté GitLab qui gère les opérations et la logique pour l'intégration de l'agent Kubernetes. Gère la connexion et la communication entre GitLab et les clusters Kubernetes. | GitLab |
| Déploiement basé sur le pull | Une méthode de déploiement où Flux vérifie les modifications dans un dépôt Git et applique automatiquement ces modifications au cluster. | GitLab, Kubernetes |
| Déploiement basé sur le push | Méthode de déploiement dans laquelle les mises à jour sont envoyées depuis les pipelines CI/CD GitLab vers le cluster Kubernetes. | GitLab |
| Flux | Un outil GitOps open source qui s'intègre à l'agent pour les déploiements basés sur le pull. | GitOps, Kubernetes |
| GitOps | Un ensemble de pratiques qui impliquent l'utilisation de Git pour le contrôle de version et la collaboration dans la gestion et l'automatisation des ressources cloud et Kubernetes. | DevOps, Kubernetes |
| Espace de nommage Kubernetes | Une partition logique dans un cluster Kubernetes qui divise les ressources du cluster entre plusieurs utilisateurs ou environnements. | Kubernetes |

## Sujets connexes {#related-topics}

- [Workflow GitOps](gitops.md)
- [Exemples et ressources d'apprentissage GitOps](gitops.md#related-topics)
- [Workflow GitLab CI/CD](ci_cd_workflow.md)
- [Installer l'agent](install/_index.md)
- [Utiliser l'agent](work_with_agent.md)
- [Migrer vers l'agent pour Kubernetes depuis l'intégration basée sur les certificats héritée](../../infrastructure/clusters/migrate_to_gitlab_agent.md)
- [Dépannage](troubleshooting.md)
- [Explorations guidées pour une configuration GitOps prête pour la production](https://gitlab.com/groups/guided-explorations/gl-k8s-agent/gitops/-/wikis/home#gitlab-agent-for-kubernetes-gitops-working-examples)
- [Exemples et ressources d'apprentissage CI/CD pour Kubernetes](ci_cd_workflow.md#related-topics)
- [Contribuer au développement de l'agent](https://gitlab.com/gitlab-org/cluster-integration/gitlab-agent/-/tree/master/doc)
