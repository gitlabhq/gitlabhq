---
stage: Analytics
group: Platform Insights
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "Configurez les limites de débit pour les alertes entrantes de gestion des incidents. Définissez le nombre maximum de requêtes par projet et les périodes de temps pour éviter la surcharge d'alertes."
gitlab_dedicated: yes
title: Limites de débit de la gestion des incidents
---

{{< details >}}

- Niveau :  Ultimate
- Offre :  GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Vous pouvez limiter le nombre d'alertes entrantes pour les [incidents](../../operations/incident_management/incidents.md) pouvant être créées au cours d'une période donnée. La limite de débit des alertes de [gestion des incidents](../../operations/incident_management/_index.md) entrantes peut aider à éviter de surcharger vos intervenants en réduisant le nombre d'alertes ou de tickets en double.

Par exemple, si vous définissez une limite de débit de `10` requêtes toutes les `60` secondes et que `11` requêtes sont envoyées à un [point de terminaison d'intégration des alertes](../../operations/incident_management/integrations.md) en l'espace d'une minute, la onzième requête est bloquée. L'accès au point de terminaison est à nouveau autorisé après une minute.

Cette limite est :

- Appliquée indépendamment par projet.
- Non appliquée par adresse IP.
- Désactivé par défaut.

Les requêtes qui dépassent la limite sont journalisées dans `auth.log`.

## Définir une limite sur les alertes entrantes {#set-a-limit-on-inbound-alerts}

Prérequis :

- Accès administrateur.

Pour définir les limites de débit des alertes de gestion des incidents entrantes :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Réseau**.
1. Développez **Limites de la gestion des incidents**.
1. Cochez la case **Enable Incident Management inbound alert limit**.
1. Facultatif. Saisissez une valeur personnalisée pour **Maximum requests per project per rate limit period**. La valeur par défaut est 3600.
1. Facultatif. Saisissez une valeur personnalisée pour **Rate limit period**. La valeur par défaut est 3600 secondes.
