---
stage: AI-powered
group: AI Framework
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: AI Gateway
---

L'AI Gateway est un service autonome qui donne accès aux fonctionnalités GitLab Duo natives de l'IA.

GitLab exploite une instance de l'AI Gateway, hébergée dans le cloud. Cette instance est utilisée par GitLab.com, [GitLab Self-Managed](configure/gitlab_self_managed.md) et GitLab Dedicated.

Vous pouvez également utiliser une instance d'AI Gateway auto-hébergée sur GitLab Self-Managed via [GitLab Duo Self-Hosted](../gitlab_duo_self_hosted/_index.md).

## Prise en charge des régions {#region-support}

### GitLab.com {#gitlabcom}

Pour GitLab.com, le mécanisme de routage est basé sur l'emplacement de l'instance GitLab plutôt que sur l'emplacement de l'instance de l'utilisateur.

GitLab.com étant à domicile unique dans `us-east1`, les requêtes adressées à l'AI Gateway sont acheminées vers `us-east4` dans presque tous les cas. Le routage ne permet pas toujours d'obtenir le déploiement le plus proche pour chaque utilisateur.

### GitLab Self-Managed et GitLab Dedicated {#gitlab-self-managed-and-gitlab-dedicated}

Pour GitLab Self-Managed et GitLab Dedicated, GitLab gère la sélection de la région. Vous ne pouvez pas choisir la région de déploiement de l'AI Gateway. Pour plus d'informations, consultez [les régions disponibles](https://schemas.runway.gitlab.com/RunwayService/#spec_regions) dans le manifeste de service [Runway](https://gitlab.com/gitlab-com/gl-infra/platform/runway).

Runway est la plateforme interne pour les développeurs de GitLab et n'est pas disponible pour les clients externes.

## Routage automatique des données {#automatic-data-routing}

GitLab utilise les équilibreurs de charge Cloudflare et Google Cloud Platform (GCP) pour acheminer automatiquement les requêtes de l'AI Gateway vers le déploiement disponible le plus proche. Ce mécanisme de routage donne la priorité à la faible latence et au traitement efficace des requêtes des utilisateurs.

Vous ne pouvez pas contrôler manuellement ce processus de routage. Les facteurs suivants influencent le routage des données :

- Latence réseau : Le mécanisme de routage principal vise à minimiser la latence. Les données peuvent être traitées dans une région autre que la plus proche si les conditions du réseau l'exigent.
- Disponibilité du service : En cas de pannes régionales ou d'interruptions de service, les requêtes peuvent être automatiquement reroutées pour garantir la continuité du service.
- Dépendances tierces : L'infrastructure IA de GitLab s'appuie sur des fournisseurs de modèles tiers, comme Google Vertex AI, qui ont leurs propres pratiques de gestion des données.

### Connexions directes et indirectes {#direct-and-indirect-connections}

L'IDE communique directement avec l'AI Gateway par défaut, en contournant le monolithe GitLab. Cette connexion directe améliore l'efficacité du routage.

Pour modifier ce comportement, configurez les [connexions directes et indirectes](../../user/project/repository/code_suggestions/_index.md#direct-and-indirect-connections) pour les suggestions de code.

### Traçage des requêtes vers des régions spécifiques {#tracing-requests-to-specific-regions}

Vous ne pouvez pas tracer directement vos requêtes IA vers des régions spécifiques.

Si vous avez besoin d'aide pour tracer une requête particulière, le support GitLab peut accéder aux journaux contenant les en-têtes Cloudflare et les UUID d'instance et les analyser. Ces journaux fournissent des informations sur le chemin de routage et peuvent aider à identifier la région dans laquelle une requête a été traitée.

## Souveraineté des données {#data-sovereignty}

Le déploiement multi-région de l'AI Gateway n'impose pas une souveraineté stricte des données. Il n'est pas garanti que les requêtes soient acheminées vers une région particulière ou y restent.

Ce service n'est pas une solution de résidence des données.

### Régions de déploiement {#deployment-regions}

GitLab déploie l'AI Gateway dans les régions suivantes :

- Amérique du Nord (`us-east4`)
- Europe (`europe-west2`, `europe-west3` et `europe-west9`)
- Asie-Pacifique (`asia-northeast1` et `asia-northeast3`)

Pour obtenir les informations les plus récentes, consultez le [fichier de configuration Runway](https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/-/blob/main/.runway/runway.yml?ref_type=heads#L12).

L'emplacement exact des modèles LLM utilisés par l'AI Gateway est déterminé par des fournisseurs de modèles tiers. Il n'est pas garanti que les modèles résident dans les mêmes régions géographiques que les déploiements de l'AI Gateway. Les données peuvent transiter vers d'autres régions où le fournisseur de modèles opère, même si l'AI Gateway traite la requête initiale dans une région différente. Les données sont acheminées vers la région la plus optimale en fonction des performances et de la disponibilité.
