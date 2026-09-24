---
stage: Verify
group: Runner Core
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: "Gestion de l'agent pour les instances Kubernetes"
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Utilisez les tâches suivantes lorsque vous travaillez avec l'agent pour Kubernetes.

## Afficher vos agents {#view-your-agents}

La version installée de `agentk` est affichée dans l'onglet **Agent**.

Prérequis :

- Vous devez disposer du rôle Développeur, Chargé de maintenance ou Propriétaire.

Pour afficher la liste des agents :

1. Dans la barre supérieure, sélectionnez **Rechercher ou accéder à** et trouvez le projet qui contient votre fichier de configuration de l'agent. Vous ne pouvez pas afficher les agents enregistrés depuis un projet qui ne contient pas le fichier de configuration de l'agent.
1. Sélectionnez **Opération** > **Clusters Kubernetes**.
1. Sélectionnez l'onglet **Agent** pour afficher les clusters connectés à GitLab via l'agent.

Sur cette page, vous pouvez afficher :

- Tous les agents enregistrés pour le projet actuel.
- Le statut de connexion.
- La version de `agentk` installée sur votre cluster.
- Le chemin d'accès à chaque fichier de configuration de l'agent.

### Configurer votre agent {#configure-your-agent}

Pour configurer votre agent :

- Ajoutez du contenu au fichier `config.yaml` créé de manière facultative [lors de l'installation](install/_index.md#create-an-agent-configuration-file).

Vous pouvez rapidement localiser un fichier de configuration de l'agent depuis la liste des agents. La colonne **Configuration** indique l'emplacement du fichier `config.yaml`, ou explique comment en créer un.

Le fichier de configuration de l'agent gère les différentes fonctionnalités de l'agent :

- Pour un workflow GitLab CI/CD. Vous devez [autoriser l'agent à accéder à vos projets](ci_cd_workflow.md#authorize-agent-access), puis [ajouter des commandes `kubectl` à votre fichier `.gitlab-ci.yml`](ci_cd_workflow.md#update-your-gitlab-ciyml-file-to-run-kubectl-commands).
- Pour l'[accès utilisateur](user_access.md) au cluster depuis l'interface utilisateur GitLab ou depuis le terminal local.
- Pour configurer l'[analyse des conteneurs opérationnels](vulnerabilities.md).
- Pour configurer les [workspaces distants](../../workspace/gitlab_agent_configuration.md).

### Champs disponibles du fichier de configuration {#available-configuration-file-fields}

Le format du fichier de configuration de l'agent est défini comme un [message de tampon de protocole](https://gitlab.com/gitlab-org/cluster-integration/gitlab-agent/-/blob/master/pkg/agentcfg/agentcfg.proto) dans le dépôt source.

Pour afficher tous les champs disponibles du fichier de configuration :

1. Accédez à [`ConfigurationFile`](https://gitlab.com/gitlab-org/cluster-integration/gitlab-agent/-/blob/master/pkg/agentcfg/agentcfg_proto_docs.md#configurationfile) dans la [documentation générée](https://gitlab.com/gitlab-org/cluster-integration/gitlab-agent/-/blob/master/pkg/agentcfg/agentcfg_proto_docs.md) pour afficher les champs de l'ensemble du fichier de configuration de l'agent.
1. Sélectionnez n'importe quel type de champ pour obtenir plus d'informations sur la structure du champ.

## Afficher les agents partagés {#view-shared-agents}

En plus des agents appartenant à votre projet, vous pouvez également afficher les agents partagés avec les mots-clés [`ci_access`](ci_cd_workflow.md) et [`user_access`](user_access.md). Une fois qu'un agent est partagé avec un projet, il apparaît automatiquement dans l'onglet des agents du projet.

Pour afficher la liste des agents partagés :

1. Dans la barre supérieure, sélectionnez **Rechercher ou accéder à**, puis recherchez votre projet.
1. Dans la barre latérale gauche, sélectionnez **Opération** > **Clusters Kubernetes**.
1. Sélectionnez l'onglet **Agent**.

La liste des agents partagés et leurs clusters s'affiche.

## Afficher les informations d'activité d'un agent {#view-an-agents-activity-information}

Les journaux d'activité vous aident à identifier les problèmes et à obtenir les informations dont vous avez besoin pour le dépannage. Vous pouvez consulter les événements survenus au cours de la semaine précédant la date actuelle. Pour afficher l'activité d'un agent :

1. Dans la barre supérieure, sélectionnez **Rechercher ou accéder à** et trouvez le projet qui contient votre fichier de configuration de l'agent.
1. Sélectionnez **Opération** > **Clusters Kubernetes**.
1. Sélectionnez l'agent dont vous souhaitez consulter l'activité.

La liste d'activités comprend :

- Événements d'enregistrement de l'agent. Lorsqu'un nouveau jeton est créé.
- Événements de connexion. Lorsqu'un agent est connecté avec succès à un cluster.

Le statut de connexion est enregistré lorsque vous connectez un agent pour la première fois ou après plus d'une heure d'inactivité.

Consultez et partagez vos commentaires sur l'interface utilisateur dans [cet epic](https://gitlab.com/groups/gitlab-org/-/epics/4739).

## Déboguer l'agent {#debug-the-agent}

Pour déboguer le composant côté cluster (`agentk`) de l'agent, définissez le niveau de journalisation en fonction des options disponibles :

- `error`
- `info`
- `debug`

L'agent dispose de deux journaliseurs :

- Un journaliseur à usage général, dont la valeur par défaut est `info`.
- Un journaliseur gRPC, dont la valeur par défaut est `error`.

Vous pouvez modifier vos niveaux de journalisation en utilisant une section `observability` de niveau supérieur dans le [fichier de configuration de l'agent](#configure-your-agent), par exemple en définissant les niveaux sur `debug` et `warn` :

```yaml
observability:
  logging:
    level: debug
    grpc_level: warn
```

Lorsque `grpc_level` est défini sur `info` ou en dessous, un grand nombre de journaux gRPC sont générés.

Commitez les modifications de configuration et inspectez les journaux du service de l'agent :

```shell
kubectl logs -f -l=app=gitlab-agent -n gitlab-agent
```

Pour plus d'informations sur le débogage, consultez la [documentation de dépannage](troubleshooting.md).

## Réinitialiser le jeton de l'agent {#reset-the-agent-token}

Un agent peut avoir au maximum deux jetons actifs simultanément.

Pour réinitialiser le jeton de l'agent sans interruption de service :

1. Créez un nouveau jeton :
   1. Dans la barre supérieure, sélectionnez **Rechercher ou accéder à**, puis recherchez votre projet.
   1. Sélectionnez **Opération** > **Clusters Kubernetes**.
   1. Sélectionnez l'agent pour lequel vous souhaitez créer un jeton.
   1. Dans l'onglet **Jetons d’accès**, sélectionnez **Créer un jeton**.
   1. Saisissez le nom et la description du jeton (facultatif) et sélectionnez **Créer un jeton**.
1. Stockez le jeton généré de manière sécurisée.
1. Utilisez le jeton pour [installer l'agent dans votre cluster](install/_index.md#install-the-agent-in-the-cluster) et pour [mettre à jour l'agent](install/_index.md#update-the-agent-version) vers une autre version.
1. Pour supprimer le jeton que vous n'utilisez plus, revenez à la liste des jetons et sélectionnez **Révoquer** ({{< icon name="remove" >}}).

## Supprimer un agent {#remove-an-agent}

Vous pouvez supprimer un agent via l'[interface utilisateur GitLab](#remove-an-agent-through-the-gitlab-ui) ou l'[API GraphQL](#remove-an-agent-with-the-gitlab-graphql-api). L'agent et tous les jetons associés sont supprimés de GitLab, mais aucune modification n'est apportée à votre cluster Kubernetes. Vous devez nettoyer ces ressources manuellement.

### Supprimer un agent via l'interface utilisateur GitLab {#remove-an-agent-through-the-gitlab-ui}

Pour supprimer un agent depuis l'interface utilisateur :

1. Dans la barre supérieure, sélectionnez **Rechercher ou accéder à** et trouvez le projet qui contient votre fichier de configuration de l'agent.
1. Sélectionnez **Opération** > **Clusters Kubernetes**.
1. Dans le tableau, dans la ligne correspondant à votre agent, dans la colonne **Options**, sélectionnez les points de suspension verticaux ({{< icon name="ellipsis_v" >}}).
1. Sélectionnez **Supprimer l'agent**.

### Supprimer un agent avec l'API GraphQL de GitLab {#remove-an-agent-with-the-gitlab-graphql-api}

1. Obtenez l'`<cluster-agent-token-id>` depuis une requête dans l'explorateur GraphQL interactif.
   - Pour GitLab.com, accédez à <https://gitlab.com/-/graphql-explorer> pour ouvrir l'explorateur GraphQL.
   - Pour GitLab Self-Managed, accédez à `https://gitlab.example.com/-/graphql-explorer`, en remplaçant `gitlab.example.com` par l'URL de votre instance.

   ```graphql
   query{
     project(fullPath: "<full-path-to-agent-configuration-project>") {
       clusterAgent(name: "<agent-name>") {
         id
         tokens {
           edges {
             node {
               id
             }
           }
         }
       }
     }
   }
   ```

1. Supprimez un enregistrement d'agent avec GraphQL en supprimant le `clusterAgentToken`.

   ```graphql
   mutation deleteAgent {
     clusterAgentDelete(input: { id: "<cluster-agent-id>" } ) {
       errors
     }
   }

   mutation deleteToken {
     clusterAgentTokenDelete(input: { id: "<cluster-agent-token-id>" }) {
       errors
     }
   }
   ```

1. Vérifiez si la suppression s'est effectuée correctement. Si la sortie dans les journaux du pod inclut `unauthenticated`, cela signifie que l'agent a été supprimé avec succès :

   ```json
   {
       "level": "warn",
       "time": "2021-04-29T23:44:07.598Z",
       "msg": "GetConfiguration.Recv failed",
       "error": "rpc error: code = Unauthenticated desc = unauthenticated"
   }
   ```

1. Supprimez l'agent dans votre cluster :

   ```shell
   kubectl delete -n gitlab-kubernetes-agent -f ./resources.yml
   ```

## Sujets connexes {#related-topics}

- [Gérer les workspaces d'un agent](../../workspace/_index.md#manage-workspaces-at-the-agent-level)
