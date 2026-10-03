---
stage: GitLab Dedicated
group: Geo
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Dépannage des erreurs de code de réponse SSH de Geo
---

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed

{{< /details >}}

## Les opérations SSH pull et push se bloquent indéfiniment sur les déploiements Cloud Native utilisant NGINX Ingress {#ssh-pull-and-push-hang-indefinitely-on-cloud-native-deployments-using-nginx-ingress}

> [!note]
> Ce problème affecte uniquement les déploiements GitLab Cloud Native utilisant le NGINX Ingress intégré. Les déploiements utilisant Envoy comme contrôleur Ingress ne sont pas affectés par ce problème.

Les opérations SSH push et pull depuis un site secondaire déployé à l'aide de Helm Chart peuvent se bloquer indéfiniment lorsque les feature flags suivants sont activés :

- `geo_proxy_fetch_ssh_to_primary`
- `geo_proxy_push_ssh_to_primary`

Ces flags modifient le chemin du proxy SSH pour les opérations Git initiées contre un site secondaire Geo. Ils sont activés par défaut dans GitLab version 19.4.0 et ultérieure.

Le problème est causé par la mise en mémoire tampon des requêtes NGINX sur l'Ingress du service web. GitLab Shell envoie un corps de requête en streaming tandis que le client Git attend l'annonce des références ; NGINX attend le corps de la requête et le client Git attend la réponse, de sorte que la requête n'atteint pas Workhorse.

Pour corriger ce problème, choisissez l'option qui correspond à votre déploiement :

- Pour GitLab 18.11 et versions antérieures : désactivez les deux feature flags :
  - `geo_proxy_fetch_ssh_to_primary`
  - `geo_proxy_push_ssh_to_primary`
- Pour GitLab 19.0 et versions ultérieures :
  - Mettez à niveau pour utiliser [Envoy Gateway](https://docs.gitlab.com/charts/installation/migration/envoy_gateway_migration/) comme contrôleur Ingress.

Ne laissez pas les deux feature flags activés lorsque vous utilisez le NGINX Ingress intégré. Dans le cas contraire, les utilisateurs pourraient ne pas être en mesure d'effectuer des opérations SSH fetch ou push via les sites secondaires Geo.

Pour les détails techniques, consultez [Erreur de fetch Git via le proxy Geo : fatal: the remote end hung up unexpectedly](https://gitlab.com/gitlab-org/gitlab/-/work_items/454707).

## Erreur : `Net::ReadTimeout` lors d'un push via SSH sur un site secondaire Geo {#error-netreadtimeout-when-pushing-through-ssh-on-a-geo-secondary}

Lorsque vous poussez de grands dépôts via SSH sur un site secondaire Geo, vous pouvez rencontrer un délai d'attente dépassé. Cela est dû au fait que Rails proxie le push vers le site primaire et dispose d'un délai d'attente par défaut de 60 secondes, [comme décrit dans ce ticket Geo](https://gitlab.com/gitlab-org/gitlab/-/issues/7405). Ce problème se produit uniquement lorsque le feature flag `geo_proxy_push_ssh_to_primary` est désactivé.

Les solutions de contournement actuelles sont :

- Poussez via HTTP à la place, où Workhorse proxie la requête vers le site primaire (ou redirige vers le site primaire si le proxy Geo n'est pas activé).
- Poussez directement vers le site primaire.

Exemple de log (`gitlab-shell.log`) :

```plaintext
Failed to contact primary https://primary.domain.com/namespace/push_test.git\\nError: Net::ReadTimeout\",\"result\":null}" code=500 method=POST pid=5483 url="http://127.0.0.1:3000/api/v4/geo/proxy_git_push_ssh/push"
```
