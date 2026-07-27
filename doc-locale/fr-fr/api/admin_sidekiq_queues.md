---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: "API d'administration des files d'attente Sidekiq"
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

## Supprimer des jobs d'une file d'attente Sidekiq {#delete-jobs-from-a-sidekiq-queue}

Supprime les jobs d'une file d'attente Sidekiq correspondant aux métadonnées données.

La réponse comporte trois champs :

1. `deleted_jobs` - le nombre de jobs supprimés par la requête.
1. `queue_size` - la taille restante de la file d'attente après traitement de la requête.
1. `completed` - indique si la requête a pu traiter l'intégralité de la file d'attente dans le temps imparti. Si ce n'est pas le cas, une nouvelle tentative avec les mêmes paramètres peut supprimer d'autres jobs (y compris ceux ajoutés après l'émission de la première requête).

Ce point de terminaison d'API est uniquement disponible pour les administrateurs.

```plaintext
DELETE /admin/sidekiq/queues/:queue_name
```

| Attribut           | Type   | Obligatoire | Description |
|---------------------|--------|----------|-------------|
| `queue_name`        | string | oui      | Le nom de la file d'attente dont les jobs doivent être supprimés |
| `user`              | string | non       | Le nom d'utilisateur de l'utilisateur qui a planifié les jobs |
| `project`           | string | non       | Le chemin complet du projet à partir duquel les jobs ont été planifiés |
| `root_namespace`    | string | non       | L'espace de nommage racine du projet |
| `subscription_plan` | string | non       | Le plan d'abonnement de l'espace de nommage racine (GitLab.com uniquement) |
| `caller_id`         | string | non       | Le point de terminaison ou le job en arrière-plan qui a planifié le job (par exemple : `ProjectsController#create`, `/api/:version/projects/:id`, `PostReceive`) |
| `feature_category`  | string | non       | La catégorie de fonctionnalité du job en arrière-plan (par exemple : `team_planning` ou `code_review`) |
| `worker_class`      | string | non       | La classe du worker du job en arrière-plan (par exemple : `PostReceive` ou `MergeWorker`) |

Au moins un attribut, autre que `queue_name`, est requis.

Exemple de requête :

```shell
curl --request DELETE \
--header "PRIVATE-TOKEN: <your_access_token>" \
--url "https://gitlab.example.com/api/v4/admin/sidekiq/queues/:queue_name"
```

Exemple de réponse :

```json
{
  "completed": true,
  "deleted_jobs": 7,
  "queue_size": 14
}
```
