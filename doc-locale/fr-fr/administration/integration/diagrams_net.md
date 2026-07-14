---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: Configurer une intégration Diagrams.net pour GitLab.
gitlab_dedicated: yes
title: Diagrams.net
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- La prise en charge des environnements hors ligne a été [introduite](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/116281) dans GitLab 16.1.

{{< /history >}}

Utilisez l'intégration [diagrams.net](https://www.drawio.com/) pour créer et intégrer des diagrammes SVG dans les wikis. L'éditeur de diagrammes est disponible à la fois dans l'éditeur de texte brut et dans l'éditeur de texte enrichi.

Cette intégration est disponible pour tous les utilisateurs de GitLab.com et ne nécessite aucune configuration supplémentaire.

Pour GitLab Self-Managed et GitLab Dedicated, intégrez-vous au site web gratuit [diagrams.net](https://www.drawio.com/) ou hébergez votre propre site diagrams.net dans des environnements hors ligne.

Pour configurer l'intégration :

1. Choisissez d'intégrer le site web gratuit diagrams.net ou [configurez votre serveur diagrams.net](#configure-your-diagramsnet-server).
1. [Activez l'intégration](#enable-diagramsnet-integration).

Une fois l'intégration effectuée, l'éditeur diagrams.net s'ouvre avec l'URL que vous avez fournie.

## Configurer votre serveur diagrams.net {#configure-your-diagramsnet-server}

Vous pouvez configurer votre propre serveur diagrams.net pour générer des diagrammes. Pour les installations hors ligne de GitLab Self-Managed, cette étape est obligatoire.

Pour exécuter un conteneur diagrams.net dans Docker, exécutez la commande suivante :

```shell
docker run -it --rm --name="draw" -p 8006:8080 -p 8443:8443 jgraph/drawio
```

> [!note]
> Utilisez le port `8006` pour le point de terminaison HTTP. Vous devriez éviter le port par défaut `8080` car [Puma](../operations/puma.md) écoute sur le port `8080` pour les métriques.

Notez le nom d'hôte du serveur exécutant le conteneur. Vous utilisez ce nom d'hôte comme URL diagrams.net lorsque vous activez l'intégration.

Pour plus d'informations, voir [exécuter votre propre serveur diagrams.net avec Docker](https://www.drawio.com/blog/diagrams-docker-app).

## Activer l'intégration Diagrams.net {#enable-diagramsnet-integration}

1. Connectez-vous à GitLab en tant qu'utilisateur [Administrateur](../../user/permissions.md).
1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Général**.
1. Développez **Diagrams.net**.
1. Cochez la case **Activer Diagrams.net**.
1. Saisissez l'URL Diagrams.net. Pour vous connecter à :
   - L'instance publique gratuite : saisissez `https://embed.diagrams.net`.
   - Une instance diagrams.net hébergée localement : saisissez l'URL que vous avez [configurée précédemment](#configure-your-diagramsnet-server).
1. Sélectionnez **Sauvegarder les modifications**.
