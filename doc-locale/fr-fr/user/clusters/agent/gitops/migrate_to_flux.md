---
stage: Verify
group: Runner Core
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Migrer de GitOps legacy vers Flux
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

La plupart des utilisateurs peuvent migrer de leur solution GitOps legacy basée sur un agent vers Flux sans travail supplémentaire ni temps d'arrêt. Dans la plupart des cas, Flux peut prendre en charge les workloads existants sans aucun redémarrage.

## Exemple de configuration GitOps {#example-gitops-configuration}

Votre configuration GitOps legacy peut contenir une configuration d'agent telle que :

```yaml
gitops:
  manifest_projects:
  - id: <your-group>/<your-repository>
    paths:
    - glob: 'manifests/*.yaml'
```

Le répertoire `manifests` référencé dans `paths.glob` peut contenir deux manifestes. Un manifeste définit un `Namespace` :

```yaml
# /manifests/namespace.yaml

---
apiVersion: v1
kind: Namespace
metadata:
  name: production
```

Et l'autre manifeste définit un `Deployment` :

```yaml
# /manifests/deployment.yaml

---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment
  namespace: production
  labels:
    app: nginx
spec:
  replicas: 3
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx:1.14.2
        ports:
        - containerPort: 80
```

Les rubriques de cette page utilisent cette configuration pour illustrer une migration vers Flux.

## Désactiver la fonctionnalité GitOps legacy dans l'agent {#disable-legacy-gitops-functionality-in-the-agent}

Lorsque la configuration GitOps est supprimée, l'agent ne supprime pas les workloads en cours d'exécution qu'il avait appliqués. Pour supprimer la fonctionnalité GitOps de votre agent :

- Supprimez la section `gitops` du fichier de configuration de l'agent.

Vous avez toujours besoin d'un agent fonctionnel, ne supprimez donc pas l'intégralité de votre fichier `config.yaml`.

Si vous avez plusieurs éléments sous `gitops.manifest_projects` ou sous la liste `paths`, vous pouvez migrer une partie à la fois en supprimant uniquement le projet ou le chemin spécifique.

## Bootstrap de Flux {#bootstrap-flux}

Avant de commencer :

- Vous avez désactivé la fonctionnalité GitOps dans votre agent.
- Vous avez installé l'interface CLI Flux dans un terminal ayant accès à votre cluster.

Pour effectuer le bootstrap de Flux :

- Dans votre terminal, exécutez la commande `flux bootstrap gitlab`. Par exemple :

  ```shell
  flux bootstrap gitlab \
  --owner=<your-group> \
  --repository=<your-repository> \
  --branch=main \
  --path=manifests/ \
  --deploy-token-auth
  ```

Flux est installé sur votre cluster et les fichiers de configuration Flux nécessaires sont commités dans `manifests/flux-system`, ce qui synchronise Flux et l'intégralité du répertoire `manifests`.

Étant donné que les workloads (les manifestes `Namespace` et `Deployment`) sont déjà déclarés dans le répertoire `manifests`, aucun travail supplémentaire n'est nécessaire.

Pour plus d'informations sur la configuration de Flux avec GitLab, consultez [Tutoriel : configurer Flux pour GitOps](../getting_started.md).

## Dépannage {#troubleshooting}

### `flux bootstrap` ne réconcilie pas correctement les manifestes {#flux-bootstrap-doesnt-reconcile-manifests-correctly}

La commande `flux bootstrap` crée une ressource `kustomizations.kustomize.toolkit.fluxcd.io` qui pointe vers le répertoire `manifests`. Cette ressource s'applique à tous les manifestes Kubernetes du répertoire, sans nécessiter de [fichier Kustomization](https://kubectl.docs.kubernetes.io/references/kustomize/glossary/#kustomization).

Ce processus peut ne pas fonctionner avec votre configuration. Pour résoudre le problème, vérifiez le statut de la Kustomization Flux pour identifier les éventuels problèmes :

```shell
kubectl get kustomizations.kustomize.toolkit.fluxcd.io -n flux-system
```

### Utiliser un `default_namespace` dans la configuration de l'agent {#use-a-default_namespace-in-the-agent-configuration}

Vous pouvez rencontrer un problème si votre configuration GitOps legacy basée sur un agent fait référence à un `default_namespace` dans la configuration de l'agent, mais omet cet espace de nommage dans les manifestes eux-mêmes. Cela provoque une erreur dans laquelle votre Flux bootstrappé ne sait pas que vos manifestes existants sont appliqués au `default_namespace`.

Pour résoudre ce problème, vous pouvez :

- Définir l'espace de nommage manuellement dans votre YAML de ressource existant.
- Déplacer vos ressources dans un répertoire dédié et pointer Flux vers celui-ci avec `kustomize.toolkit.fluxcd.io/Kustomization`, où `spec.targetNamespace` spécifie l'espace de nommage.
- Déplacer les ressources dans un sous-répertoire et ajouter un fichier `kustomization.yaml` qui définit la propriété `spec.namespace`.

Si vous préférez déplacer les ressources en dehors du chemin déjà configuré pour Flux, vous devez utiliser `kustomize.toolkit.fluxcd.io/Kustomization`. Si vous préférez déplacer les ressources dans un sous-répertoire d'un chemin déjà surveillé par Flux, vous devez utiliser un `kustomize.config.k8s.io/Kustomization`.
