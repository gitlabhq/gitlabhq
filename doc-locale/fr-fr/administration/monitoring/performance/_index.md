---
stage: Shared responsibility based on functional area
group: Shared responsibility based on functional area
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
gitlab_dedicated: no
title: Surveillance des performances GitLab
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed

{{< /details >}}

Détectez les goulots d'étranglement des performances avant qu'ils n'affectent vos utilisateurs grâce à la surveillance des performances GitLab. Lorsque des temps de réponse lents ou des problèmes de mémoire surviennent, identifiez leur cause exacte grâce à des métriques détaillées sur les requêtes SQL, le traitement Ruby et les ressources système.

Les administrateurs qui mettent en œuvre la surveillance des performances reçoivent des alertes immédiates sur les problèmes potentiels avant qu'ils ne se propagent à l'ensemble de l'instance. Suivez les durées des transactions, les performances d'exécution des requêtes et l'utilisation de la mémoire pour maintenir des performances GitLab optimales pour votre organisation.

Pour plus d'informations sur la configuration de la surveillance des performances GitLab, consultez :

- [Documentation Prometheus](../prometheus/_index.md).
- [Configuration de Grafana](grafana_configuration.md).
- [Barre de performance](performance_bar.md).

Deux types de métriques sont collectées :

1. Métriques spécifiques aux transactions.
1. Métriques échantillonnées.

## Métriques de transaction {#transaction-metrics}

Les métriques de transaction sont des métriques pouvant être associées à une seule transaction. Cela inclut des statistiques telles que la durée de la transaction, les durées d'exécution des requêtes SQL et le temps passé à restituer les vues HAML. Ces métriques sont collectées pour chaque requête Rack et chaque job Sidekiq traité.

## Métriques échantillonnées {#sampled-metrics}

Les métriques échantillonnées sont des métriques ne pouvant pas être associées à une seule transaction. Les exemples incluent les statistiques de récupération de mémoire et les objets Ruby conservés. Ces métriques sont collectées à intervalles réguliers. Cet intervalle est composé de deux parties :

1. Un intervalle défini par l'utilisateur.
1. Un décalage généré aléatoirement ajouté en plus de l'intervalle ; le même décalage ne peut pas être utilisé deux fois de suite.

L'intervalle réel peut être compris entre la moitié de l'intervalle défini et une moitié au-dessus de l'intervalle. Par exemple, pour un intervalle défini par l'utilisateur de 15 secondes, l'intervalle réel peut être compris entre 7,5 et 22,5. L'intervalle est régénéré à chaque cycle d'échantillonnage au lieu d'être généré une seule fois et réutilisé pendant toute la durée de vie du processus.

Les intervalles définis par l'utilisateur peuvent être spécifiés au moyen de variables d'environnement. Les variables d'environnement suivantes sont reconnues :

- `RUBY_SAMPLER_INTERVAL_SECONDS`
- `DATABASE_SAMPLER_INTERVAL_SECONDS`
- `ACTION_CABLE_SAMPLER_INTERVAL_SECONDS`
- `PUMA_SAMPLER_INTERVAL_SECONDS`
- `THREADS_SAMPLER_INTERVAL_SECONDS`
- `GLOBAL_SEARCH_SAMPLER_INTERVAL_SECONDS`
