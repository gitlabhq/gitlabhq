---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: "API de statistiques d'application"
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Utilisez cette API pour récupérer des statistiques de votre instance GitLab.

Prérequis :

- Vous devez disposer d'un accès administrateur à l'instance.

## Récupérer les statistiques d'application {#retrieve-application-statistics}

Récupère les statistiques de votre instance GitLab.

> [!note]
> Pour les valeurs inférieures à 10 000, cet endpoint renvoie un nombre exact. Pour les valeurs supérieures ou égales à 10 000, cet endpoint ne renvoie que des données approximatives lorsque les stratégies [TablesampleCountStrategy](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/database/count/tablesample_count_strategy.rb?ref_type=heads#L16) et [ReltuplesCountStrategy](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/database/count/reltuples_count_strategy.rb?ref_type=heads) sont utilisées pour les calculs.

```plaintext
GET /application/statistics
```

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/application/statistics"
```

Exemple de réponse :

```json
{
   "forks": 10,
   "issues": 76,
   "merge_requests": 27,
   "notes": 954,
   "snippets": 50,
   "ssh_keys": 10,
   "milestones": 40,
   "users": 50,
   "groups": 10,
   "projects": 20,
   "active_users": 50
}
```
