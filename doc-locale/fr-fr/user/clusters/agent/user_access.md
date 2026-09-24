---
stage: Verify
group: Runner Core
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: "Accorder aux utilisateurs l'accès à Kubernetes"
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Statut : version bêta

{{< /details >}}

{{< history >}}

- La [limite de partage des connexions d'agent a été relevée](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/149844) de 100 à 500 dans GitLab 17.0
- Le paramètre `user_access` `access_as` [est désormais facultatif](https://gitlab.com/gitlab-org/cluster-integration/gitlab-agent/-/merge_requests/2749) dans GitLab 18.3. Par défaut, l'emprunt d'identité de l'agent est utilisé.
- [Modification](https://gitlab.com/gitlab-org/gitlab/-/issues/557818) pour autoriser les projets et les groupes appartenant à des groupes principaux différents dans GitLab 18.4.

{{< /history >}}

En tant qu'administrateur de clusters Kubernetes dans une organisation, vous pouvez accorder l'accès à Kubernetes aux membres d'un projet ou d'un groupe spécifique.

L'octroi de l'accès active également [le Dashboard pour Kubernetes](../../../ci/environments/kubernetes_dashboard.md) pour un projet ou un groupe.

Pour les instances GitLab Self-Managed, assurez-vous de l'une des conditions suivantes :

- Hébergez votre instance GitLab et [KAS](../../../administration/clusters/kas.md) sur le même domaine.
- Hébergez KAS sur un sous-domaine de GitLab. Par exemple, GitLab sur `gitlab.com` et KAS sur `kas.gitlab.com`.

## Configurer l'accès à Kubernetes {#configure-kubernetes-access}

Configurez l'accès lorsque vous souhaitez accorder aux utilisateurs l'accès à un cluster Kubernetes.

Prérequis :

- L'agent pour Kubernetes est installé dans le cluster Kubernetes.
- Vous devez disposer du rôle Développeur ou d'un rôle supérieur.

Pour configurer l'accès :

- Dans le fichier de configuration de l'agent, définissez un mot-clé `user_access` avec les paramètres suivants :

  - `projects` : une liste de projets dont les membres doivent avoir accès. Vous pouvez autoriser jusqu'à 500 projets.
  - `groups` : une liste de groupes dont les membres doivent avoir accès. Vous pouvez autoriser jusqu'à 500 groupes. L'accès est accordé au groupe et à tous ses descendants.
  - `access_as` : pour l'accès avec l'identité de l'agent, la valeur est `{ agent: {...} }`.

Les projets et groupes autorisés doivent avoir le même groupe principal ou espace de nommage utilisateur que le projet de configuration de l'agent, sauf si le paramètre d'application [d'autorisation au niveau de l'instance](ci_cd_workflow.md#authorize-all-projects-in-your-gitlab-instance-to-access-the-agent) est activé.

Une fois l'accès configuré, les requêtes sont transmises au serveur d'API à l'aide du compte de service de l'agent. Par exemple :

```yaml
# .gitlab/agents/my-agent/config.yaml

user_access:
  access_as:
    agent: {}
  projects:
    - id: group-1/project-1
    - id: group-2/project-2
  groups:
    - id: group-2
    - id: group-3/subgroup
```

## Configurer l'accès avec emprunt d'identité utilisateur {#configure-access-with-user-impersonation}

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Vous pouvez accorder l'accès à un cluster Kubernetes et transformer les requêtes en requêtes d'emprunt d'identité pour les utilisateurs authentifiés.

Prérequis :

- L'agent pour Kubernetes est installé dans le cluster Kubernetes.
- Vous devez disposer du rôle Développeur ou d'un rôle supérieur.

Pour configurer l'accès avec emprunt d'identité utilisateur :

- Dans le fichier de configuration de l'agent, définissez un mot-clé `user_access` avec les paramètres suivants :

  - `projects` : une liste de projets dont les membres doivent avoir accès.
  - `groups` : une liste de groupes dont les membres doivent avoir accès.
  - `access_as` : pour l'emprunt d'identité utilisateur, la valeur est `{ user: {...} }`.

Une fois l'accès configuré, les requêtes sont transformées en requêtes d'emprunt d'identité pour les utilisateurs authentifiés.

### Workflow d'emprunt d'identité utilisateur {#user-impersonation-workflow}

Le `agentk` installé emprunte l'identité des utilisateurs donnés comme suit :

- `UserName` est `gitlab:user:<username>`
- `Groups` est :
  - `gitlab:user` : commun à toutes les requêtes provenant des utilisateurs GitLab.
  - `gitlab:project_role:<project_id>:<role>` pour chaque rôle dans chaque projet autorisé.
  - `gitlab:group_role:<group_id>:<role>` pour chaque rôle dans chaque groupe autorisé.
- `Extra` contient des informations supplémentaires sur la requête :
  - `agent.gitlab.com/id` : L'ID de l'agent.
  - `agent.gitlab.com/username` : le nom d'utilisateur de l'utilisateur GitLab.
  - `agent.gitlab.com/config_project_id` : L'ID du projet de configuration de l'agent.
  - `agent.gitlab.com/access_type` : l'une des valeurs `personal_access_token` ou `session_cookie`. GitLab Ultimate uniquement.

Seuls les projets et groupes directement listés sous `user_access` dans le fichier de configuration font l'objet d'un emprunt d'identité. Par exemple :

```yaml
# .gitlab/agents/my-agent/config.yaml

user_access:
  access_as:
    user: {}
  projects:
    - id: group-1/project-1 # group_id=1, project_id=1
    - id: group-2/project-2 # group_id=2, project_id=2
  groups:
    - id: group-2 # group_id=2
    - id: group-3/subgroup # group_id=3, group_id=4
```

Dans cette configuration :

- Si un utilisateur est membre uniquement de `group-1`, il reçoit uniquement les groupes RBAC Kubernetes `gitlab:project_role:1:<role>`.
- Si un utilisateur est membre de `group-2`, il reçoit les deux groupes RBAC Kubernetes :
  - `gitlab:project_role:2:<role>`,
  - `gitlab:group_role:2:<role>`.

### Autorisation RBAC {#rbac-authorization}

Les requêtes avec emprunt d'identité nécessitent `ClusterRoleBinding` ou `RoleBinding` pour identifier les permissions sur les ressources dans Kubernetes. Consultez [l'autorisation RBAC](https://kubernetes.io/docs/reference/access-authn-authz/rbac/) pour la configuration appropriée.

Par exemple, si vous autorisez les mainteneurs du projet `awesome-org/deployment` (ID : 123) à lire les workloads Kubernetes, vous devez ajouter une ressource `ClusterRoleBinding` à votre configuration Kubernetes :

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: my-cluster-role-binding
roleRef:
  name: view
  kind: ClusterRole
  apiGroup: rbac.authorization.k8s.io
subjects:
  - name: gitlab:project_role:123:maintainer
    kind: Group
```

## Accéder à un cluster avec l'API Kubernetes {#access-a-cluster-with-the-kubernetes-api}

Vous pouvez configurer un agent pour permettre aux utilisateurs GitLab d'accéder à un cluster avec l'API Kubernetes.

Prérequis :

- Vous disposez d'un agent configuré avec l'entrée `user_access`.

### Configurer l'accès local avec la CLI GitLab (recommandé) {#configure-local-access-with-the-gitlab-cli-recommended}

Vous pouvez utiliser la [CLI GitLab `glab`](../../../editor_extensions/gitlab_cli/_index.md) pour créer ou mettre à jour un fichier de configuration Kubernetes afin d'accéder à l'API Kubernetes de l'agent.

Utilisez les commandes `glab cluster agent` pour gérer les connexions au cluster :

1. Affichez la liste de tous les agents associés à votre projet :

```shell
glab cluster agent list --repo '<group>/<project>'

# If your current working directory is the Git repository of the project with the agent, you can omit the --repo option:
glab cluster agent list
```

1. Utilisez l'ID numérique de l'agent affiché dans la première colonne de la sortie pour mettre à jour votre `kubeconfig` :

```shell
glab cluster agent update-kubeconfig --repo '<group>/<project>' --agent '<agent-id>' --use-context
```

1. Vérifiez la mise à jour avec `kubectl` ou votre outil Kubernetes préféré :

```shell
kubectl get nodes
```

La commande `update-kubeconfig` définit `glab cluster agent get-token` comme [plugin de credential](https://kubernetes.io/docs/reference/access-authn-authz/authentication/#client-go-credential-plugins) pour que les outils Kubernetes récupèrent un jeton. La commande `get-token` crée et retourne un jeton d'accès personnel valide jusqu'à la fin de la journée en cours. Les outils Kubernetes mettent le jeton en cache jusqu'à son expiration, jusqu'à ce que l'API retourne une erreur d'autorisation ou que le processus se termine. Attendez-vous à ce que tous les appels suivants à vos outils Kubernetes créent un nouveau jeton.

La commande `glab cluster agent update-kubeconfig` prend en charge plusieurs indicateurs de ligne de commande. Vous pouvez afficher tous les indicateurs pris en charge avec `glab cluster agent update-kubeconfig --help`.

Quelques exemples :

```shell
# When the current working directory is the Git repository where the agent is registered the --repo / -R flag can be omitted
glab cluster agent update-kubeconfig --agent '<agent-id>'

# When the --use-context option is specified the `current-context` of the kubeconfig file is changed to the agent context
glab cluster agent update-kubeconfig --agent '<agent-id>' --use-context

# The --kubeconfig flag can be used to specify an alternative kubeconfig path
glab cluster agent update-kubeconfig --agent '<agent-id>' --kubeconfig ~/gitlab.kubeconfig
```

### Configurer l'accès local manuellement à l'aide d'un jeton d'accès personnel {#configure-local-access-manually-using-a-personal-access-token}

Vous pouvez configurer l'accès à un cluster Kubernetes à l'aide d'un jeton d'accès personnel à longue durée de vie :

1. Dans la barre supérieure, sélectionnez **Rechercher ou accéder à**, puis recherchez votre projet.
1. Dans la barre latérale gauche, sélectionnez **Opération** > **Clusters Kubernetes** et récupérez l'ID numérique de l'agent auquel vous souhaitez accéder. Vous aurez besoin de cet ID pour construire le jeton d'API complet.
1. Créez un [jeton d'accès personnel](../../profile/personal_access_tokens.md) avec la portée `k8s_proxy`. Vous aurez besoin du jeton d'accès pour construire le jeton d'API complet.
1. Construisez des entrées `kubeconfig` pour accéder au cluster :
   1. Assurez-vous que le bon `kubeconfig` est sélectionné. Par exemple, vous pouvez définir la variable d'environnement `KUBECONFIG`.
   1. Ajoutez le cluster proxy GitLab KAS au `kubeconfig` :

      ```shell
      kubectl config set-cluster <cluster_name> --server "https://kas.gitlab.com/k8s-proxy"
      ```

      L'argument `server` pointe vers l'adresse KAS de votre instance GitLab. Sur GitLab.com, il s'agit de `https://kas.gitlab.com/k8s-proxy`. Vous pouvez obtenir l'adresse KAS de votre instance lors de l'enregistrement d'un agent.

   1. Utilisez votre ID d'agent numérique et votre jeton d'accès personnel pour construire un jeton d'API :

      ```shell
      kubectl config set-credentials <gitlab_user> --token "pat:<agent-id>:<token>"
      ```

   1. Ajoutez le contexte pour combiner le cluster et l'utilisateur :

      ```shell
      kubectl config set-context <gitlab_agent> --cluster <cluster_name> --user <gitlab_user>
      ```

   1. Activez le nouveau contexte :

      ```shell
      kubectl config use-context <gitlab_agent>
      ```

1. Vérifiez que la configuration fonctionne :

   ```shell
   kubectl get nodes
   ```

L'utilisateur configuré peut accéder à votre cluster avec l'API Kubernetes.

## Sujets connexes {#related-topics}

- [Blueprint architectural](https://gitlab.com/gitlab-org/cluster-integration/gitlab-agent/-/blob/master/doc/kubernetes_user_access.md)
- [Tableau de bord pour Kubernetes](https://gitlab.com/groups/gitlab-org/-/work_items/2493)
