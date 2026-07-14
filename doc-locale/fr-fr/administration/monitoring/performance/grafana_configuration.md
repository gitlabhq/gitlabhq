---
stage: Analytics
group: Platform Insights
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Configurer Grafana
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- Grafana intégré à GitLab a été [rendu obsolète](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/7772) dans GitLab 16.0.
- Grafana intégré à GitLab a été [supprimé](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/7772) dans GitLab 16.3.

{{< /history >}}

[Grafana](https://grafana.com/) est un outil qui vous permet de visualiser des métriques de séries temporelles sous forme de graphiques et de tableaux de bord. GitLab écrit les données de performance dans Prometheus, et Grafana vous permet d'interroger ces données pour afficher des graphiques.

## Intégrer à l'interface utilisateur GitLab {#integrate-with-gitlab-ui}

Prérequis :

- Accès administrateur.

Après avoir configuré Grafana, vous pouvez activer un lien pour y accéder depuis la barre latérale de GitLab :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Statistiques et rapports**.
1. Développez **Métriques : Grafana**.
1. Cochez la case **Ajouter un lien vers Grafana**.
1. Configurez l'**URL de Grafana**. Saisissez l'URL complète de l'instance Grafana.
1. Sélectionnez **Sauvegarder les modifications**.

GitLab affiche votre lien dans la zone **Admin** sous **Surveillance** > **Tableau de bord des métriques**.

## Portées requises {#required-scopes}

Lors de la configuration de Grafana via le processus précédent, aucune portée n'est affichée à l'écran dans la zone **Admin** sous **Applications** > **GitLab Grafana**. Cependant, la portée `read_user` est requise et est fournie automatiquement à l'application. Définir toute portée autre que `read_user` sans inclure également `read_user` entraîne cette erreur lorsque vous essayez de vous connecter en utilisant GitLab comme fournisseur OAuth :

```plaintext
The requested scope is invalid, unknown, or malformed.
```

Si vous voyez cette erreur, assurez-vous que l'une des conditions suivantes est vraie dans l'écran de configuration de GitLab Grafana :

- Aucune portée n'apparaît.
- La portée `read_user` est incluse.
