---
stage: Verify
group: Runner Core
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Premiers pas pour connecter un cluster Kubernetes à GitLab
---

Cette page vous guide à travers la configuration d'une intégration Kubernetes de base dans un projet unique. Si vous débutez avec l'agent GitLab pour Kubernetes, le déploiement pull-based ou Flux, vous devriez commencer ici.

Lorsque vous aurez terminé, vous serez en mesure de :

- Afficher le statut de votre cluster Kubernetes avec un tableau de bord Kubernetes en temps réel.
- Déployer des mises à jour sur votre cluster avec Flux.
- Déployer des mises à jour sur votre cluster avec GitLab CI/CD.

## Avant de commencer {#before-you-begin}

Assurez-vous de disposer des éléments suivants avant de terminer ce tutoriel :

- Un cluster Kubernetes auquel vous pouvez accéder localement avec `kubectl`. Pour connaître les versions de Kubernetes prises en charge par GitLab, consultez [Versions de Kubernetes prises en charge pour les fonctionnalités GitLab](_index.md#supported-kubernetes-versions-for-gitlab-features).

  Vous pouvez vérifier que tout est correctement configuré en exécutant :

  ```shell
  kubectl cluster-info
  ```

## Installer et configurer Flux {#install-and-configure-flux}

[Flux](https://fluxcd.io/flux/) est l'outil recommandé pour les déploiements GitOps (également appelés déploiements pull-based). Flux est un projet CNCF mature.

Pour installer Flux :

- Effectuez les étapes décrites dans [Installer le CLI Flux](https://fluxcd.io/flux/installation/#install-the-flux-cli) dans la documentation Flux.

Vérifiez que le CLI Flux est correctement installé en exécutant :

```shell
flux -v
```

### Créer un jeton d'accès personnel {#create-a-personal-access-token}

Pour vous authentifier avec le CLI Flux, créez un jeton d'accès personnel avec la portée `api` :

1. Dans le coin supérieur droit, sélectionnez votre avatar.
1. Sélectionnez **Modifier le profil**.
1. Dans la barre latérale gauche, sélectionnez **Accès** > **Jetons d'accès personnel**.
1. Saisissez un nom et, éventuellement, une date d'expiration pour le jeton.
1. Sélectionnez la portée `api`.
1. Sélectionnez **Créer un jeton d'accès personnel**.

Vous pouvez également utiliser un [jeton de projet](../../project/settings/project_access_tokens.md) ou un [jeton d'accès de groupe](../../group/settings/group_access_tokens.md) avec la portée `api` et le rôle `maintainer`.

### Bootstrapper Flux {#bootstrap-flux}

Dans cette section, vous allez bootstrapper Flux dans un dépôt GitLab vide avec la commande [`flux bootstrap`](https://fluxcd.io/flux/installation/bootstrap/gitlab/).

Pour bootstrapper une installation Flux :

- Exécutez la commande `flux bootstrap gitlab`. Par exemple :

  ```shell
  flux bootstrap gitlab \
  --hostname=gitlab.example.org \
  --owner=my-group/optional-subgroup \
  --repository=my-repository \
  --branch=main \
  --path=clusters/testing \
  --deploy-token-auth
  ```

Les arguments de `bootstrap` sont :

| Argument     | Description |
|--------------|-------------|
| `hostname`   | Nom d'hôte de votre instance GitLab. |
| `owner`      | Groupe GitLab contenant le dépôt Flux. |
| `repository` | Projet GitLab contenant le dépôt Flux. |
| `branch`     | Branche Git sur laquelle les modifications sont commitées. |
| `path`       | Chemin de fichier vers un dossier où la configuration Flux est stockée. |

Le script de bootstrap effectue les opérations suivantes :

1. Crée un jeton de déploiement et l'enregistre en tant que `secret` Kubernetes.
1. Crée un projet GitLab vide, si le projet spécifié par l'argument `--repository` n'existe pas.
1. Génère les fichiers de définition Flux pour votre projet dans un dossier spécifié par l'argument `--path`.
1. Commite les fichiers de définition sur la branche spécifiée par l'argument `--branch`.
1. Applique les fichiers de définition à votre cluster.

Une fois le script exécuté, Flux sera prêt à se gérer lui-même ainsi que toutes les autres ressources que vous ajoutez au projet et au chemin GitLab.

La suite de ce tutoriel suppose que votre chemin est `clusters/testing` et que votre projet se trouve sous `my-group/optional-subgroup/my-repository`.

## Configurer la connexion de l'agent {#set-up-the-agent-connection}

Pour connecter vos clusters, vous devez installer l'agent GitLab pour Kubernetes. Vous pouvez le faire en bootstrappant l'agent avec le CLI GitLab (`glab`).

1. [Installer le CLI GitLab](https://gitlab.com/gitlab-org/cli/#installation).

   Pour vérifier que le CLI GitLab est disponible, exécutez

   ```shell
   glab version
   ```

1. [Authentifiez `glab`](https://gitlab.com/gitlab-org/cli/#installation) auprès de votre instance GitLab.
1. Dans le dépôt où vous avez bootstrappé Flux, exécutez la commande `glab cluster agent bootstrap` :

   ```shell
   glab cluster agent bootstrap --manifest-path clusters/testing testing
   ```

Par défaut, la commande :

1. Enregistre l'agent avec `testing` comme nom.
1. Configure l'agent.
1. Configure un environnement appelé `testing` avec un tableau de bord pour l'agent.
1. Crée un jeton d'agent.
1. Dans le cluster, crée un secret Kubernetes avec le jeton d'agent.
1. Commite les ressources Flux Helm dans le dépôt Git.
1. Déclenche une réconciliation Flux.

Pour plus d'informations sur la configuration de l'agent, consultez [Installer l'agent pour Kubernetes](install/_index.md).

## Consulter le tableau de bord pour Kubernetes {#check-out-the-dashboard-for-kubernetes}

La commande `glab cluster agent bootstrap` a créé un environnement dans GitLab et [configuré un tableau de bord](../../../ci/environments/kubernetes_dashboard.md).

Pour afficher votre tableau de bord :

1. Dans la barre supérieure, sélectionnez **Rechercher ou accéder à**, puis recherchez votre projet.
1. Dans la barre latérale gauche, sélectionnez **Opération** > **Environnements**.
1. Sélectionnez votre environnement. Par exemple, `flux-system/gitlab-agent`.
1. Sélectionnez l'onglet **Présentation de Kubernetes**.

## Sécuriser le déploiement {#secure-the-deployment}

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate

{{< /details >}}

Jusqu'à présent, vous avez déployé un agent en utilisant le fichier `.gitlab/agents/testing/config.yaml`. Cette configuration active l'accès utilisateur à l'aide du compte de service configuré pour le déploiement de l'agent. L'accès utilisateur est utilisé par le tableau de bord pour Kubernetes et pour l'accès local.

Pour sécuriser vos déploiements, vous devriez modifier cette configuration pour emprunter l'identité d'un utilisateur GitLab. Dans ce cas, vous pouvez gérer votre accès aux ressources du cluster via le contrôle d'accès basé sur les rôles (RBAC) Kubernetes standard.

Pour activer l'emprunt d'identité utilisateur :

1. Dans votre fichier `.gitlab/agents/testing/config.yaml`, remplacez `user_access.access_as.agent: {}` par `user_access.access_as.user: {}`.
1. Accédez au tableau de bord configuré pour Kubernetes. Si l'accès est restreint, le tableau de bord affiche un message d'erreur.
1. Ajoutez le code suivant à `clusters/testing/gitlab-user-read.yaml` :

   ```yaml
   apiVersion: rbac.authorization.k8s.io/v1
   kind: ClusterRoleBinding
   metadata:
      name: gitlab-user-view
   roleRef:
      name: view
      kind: ClusterRole
      apiGroup: rbac.authorization.k8s.io
   subjects:
      - name: gitlab:user
        kind: Group
   ```

1. Attendez quelques secondes pour permettre à Flux d'appliquer le manifeste ajouté, puis vérifiez à nouveau le tableau de bord pour Kubernetes. Le tableau de bord devrait revenir à la normale, grâce à la liaison de rôle de cluster déployée qui accorde un accès en lecture à tous les utilisateurs GitLab.

Pour plus d'informations sur l'accès utilisateur, consultez [Accorder aux utilisateurs l'accès à Kubernetes](user_access.md).

## Maintenir tout à jour {#keep-everything-up-to-date}

Vous devrez peut-être mettre à niveau Flux et `agentk` après l'installation.

Pour cela :

- Réexécutez les commandes `flux bootstrap gitlab` et `glab cluster agent bootstrap`.

## Étapes suivantes {#next-steps}

Vous pouvez déployer directement sur votre cluster depuis le projet où vous avez enregistré l'agent et stocké vos manifestes Flux. L'agent est conçu pour prendre en charge la multilocation, et vous pouvez étendre votre configuration à d'autres projets et groupes avec l'agent configuré et l'installation Flux.

Envisagez de suivre le tutoriel de suivi, [Premiers pas pour déployer sur Kubernetes](getting_started_deployments.md). Pour en savoir plus sur l'utilisation de Kubernetes avec GitLab, consultez :

- [Bonnes pratiques pour l'utilisation de l'intégration GitLab avec Kubernetes](enterprise_considerations.md)
- Utilisation de l'agent pour [l'analyse des conteneurs opérationnels](vulnerabilities.md)
- Fournir des [workspaces distants](../../workspace/_index.md) à vos ingénieurs
