---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: "Migrer d'une URL relative vers un sous-domaine"
description: "Reconfigurer une instance GitLab pour utiliser un sous-domaine au lieu d'une URL relative."
---

{{< details >}}

- Niveau : Free, Premium, Ultimate
- Offre : GitLab Self-Managed

{{< /details >}}

Vous pouvez migrer GitLab d'une configuration d'URL relative vers un déploiement en sous-domaine.

Le temps d'arrêt lors de la migration dépend de votre architecture de déploiement et de la configuration de votre équilibreur de charge :

- Temps d'arrêt lors de la mise à niveau de GitLab :  Pour les installations à nœud unique, la reconfiguration de GitLab nécessite un temps d'arrêt. Pour les installations multi-nœuds avec équilibrage de charge, vous pouvez suivre le processus de [mise à niveau sans interruption](../../update/zero_downtime.md) pour minimiser le temps d'arrêt en mettant à jour les nœuds de manière séquentielle.
- Temps d'arrêt côté utilisateur lors du changement d'URL :  L'impact dépend de votre équilibreur de charge et de la configuration DNS. Avant d'appliquer les modifications de configuration GitLab, vous pouvez configurer votre équilibreur de charge ou votre DNS pour router les anciennes et les nouvelles URL vers le même backend, minimisant ainsi les perturbations côté utilisateur pendant la transition.

> [!warning]
> GitLab doit être configuré avec l'URL réelle qu'il utilisera. Vous ne pouvez pas configurer GitLab pour une URL et utiliser un équilibreur de charge pour présenter une URL différente aux utilisateurs, car GitLab génère des URL absolues en interne pour les réponses API, les e-mails et les éléments d'interface utilisateur.

## Migrer vers un sous-domaine {#migrate-to-a-subdomain}

Pour migrer d'une URL relative vers un sous-domaine :

1. Mettez à jour votre configuration GitLab pour désactiver la configuration d'URL relative en fonction de votre type d'installation.

   {{< tabs >}}

   {{< tab title="Linux package (Omnibus)" >}}

      Modifiez `/etc/gitlab/gitlab.rb` et mettez à jour `external_url` pour utiliser le nouveau sous-domaine :

      ```ruby
      external_url "https://gitlab.example.com"
      ```

   {{< /tab >}}

   {{< tab title="Helm chart (Kubernetes)" >}}

      Mettez à jour la configuration [`global.hosts`](https://docs.gitlab.com/charts/charts/globals/#configure-host-settings) pour utiliser votre nouveau sous-domaine.

   {{< /tab >}}

   {{< tab title="Self-compiled (source)" >}}

      Suivez [Désactiver l'URL relative dans GitLab](../../install/relative_url.md#disable-relative-url-in-gitlab).

   {{< /tab >}}

   {{< /tabs >}}

1. Pour appliquer la nouvelle configuration de sous-domaine, suivez le processus de mise à niveau pour [mettre à niveau une instance GitLab](../../update/_index.md) applicable à votre type d'installation.
1. La modification de l'URL modifie toutes les URL distantes, vous devez donc les modifier manuellement dans tout dépôt local pointant vers votre instance GitLab. Tout dépôt local cloné lors de l'utilisation de l'URL relative possède des URL distantes pointant vers l'ancien chemin, et les utilisateurs doivent les mettre à jour manuellement.
1. Si vous devez conserver les liens existants pendant une période de transition, [configurez votre équilibreur de charge pour rediriger](#configure-load-balancer-redirects) les URL relatives héritées vers le nouveau sous-domaine.

## Configurer les redirections de l'équilibreur de charge {#configure-load-balancer-redirects}

Après avoir migré GitLab d'une URL relative vers un sous-domaine, configurez votre équilibreur de charge pour rediriger les anciennes URL relatives vers le nouveau sous-domaine :

1. Assurez-vous que votre équilibreur de charge dispose de certificats SSL pour les anciens et les nouveaux domaines.
1. Configurez le DNS pour résoudre les deux domaines vers votre équilibreur de charge.
1. Ajoutez des règles de redirection à la configuration de votre équilibreur de charge qui :
   - Détectent les requêtes vers l'ancien domaine avec des chemins commençant par le préfixe d'URL relative (par exemple, `/gitlab/`).
   - Redirigent les requêtes vers le nouveau sous-domaine avec un statut 301 (redirection permanente).
   - Préservent le chemin et les paramètres de requête en supprimant le préfixe d'URL relative au début du chemin.
1. Si vous avez des composants GitLab avec des configurations d'URL séparées (comme le registre de conteneurs ou Pages), ajoutez des règles de redirection similaires pour ces chemins.
