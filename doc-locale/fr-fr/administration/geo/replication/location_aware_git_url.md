---
stage: Tenant Scale
group: Geo
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: URL Git distante géolocalisée avec AWS Route53
---

{{< details >}}

- Niveau :  Premium, Ultimate
- Offre : GitLab Self-Managed

{{< /details >}}

> [!note]
> [GitLab Geo prend en charge le DNS géolocalisé, y compris le trafic de l'interface utilisateur web et de l'API.](../secondary_proxy/_index.md#configure-location-aware-dns) Cette configuration est recommandée plutôt que l'URL Git distante géolocalisée décrite dans ce document.

Vous pouvez fournir aux utilisateurs de GitLab une URL distante unique qui utilise automatiquement le site Geo le plus proche d'eux. Cela signifie que les utilisateurs n'ont pas besoin de mettre à jour leur configuration Git pour profiter des sites Geo plus proches lorsqu'ils se déplacent.

C'est possible parce que les requêtes Git push peuvent être automatiquement redirigées (HTTP) ou transmises par proxy (SSH) depuis les sites **secondaire** vers le site **principal**.

Bien que ces instructions utilisent [AWS Route53](https://aws.amazon.com/route53/), d'autres services tels que [Cloudflare](https://www.cloudflare.com/) peuvent également être utilisés.

## Prérequis {#prerequisites}

Dans cet exemple, nous avons déjà configuré :

- `primary.example.com` en tant que site Geo **principal**.
- `secondary.example.com` en tant que site Geo **secondaire**.

Nous créons un sous-domaine `git.example.com` qui dirige automatiquement les requêtes :

- Depuis l'Europe vers le site **secondaire**.
- Depuis tous les autres emplacements vers le site **principal**.

Dans tous les cas, vous avez besoin de :

- Un site GitLab **principal** fonctionnel accessible à sa propre adresse.
- Un site GitLab **secondaire** fonctionnel.
- Une zone hébergée Route53 gérant votre domaine.

Si vous n'avez pas encore configuré un site principal Geo et un site secondaire Geo, consultez les [instructions de configuration de Geo](../setup/_index.md).

## Créer une politique de trafic {#create-a-traffic-policy}

Dans une zone hébergée Route53, les politiques de trafic peuvent être utilisées pour configurer diverses configurations de routage.

1. Accédez au [tableau de bord Route53](https://console.aws.amazon.com/route53/home) et sélectionnez **Traffic policies**.

   ![Section Traffic policies du tableau de bord Route53](img/single_git_traffic_policies_v12_3.png)

1. Sélectionnez **Create traffic policy**.

   ![Nommage de la politique de trafic](img/single_git_name_policy_v12_3.png)

1. Renseignez le champ **Policy Name** avec `Single Git Host` et sélectionnez **Suivant**.

   ![Sélection du type DNS pour la politique de trafic](img/single_git_policy_diagram_v12_3.png)

1. Laissez **DNS type** sur `A: IP Address in IPv4 format`.
1. Sélectionnez **Connect to** et sélectionnez **Geolocation rule**.

   ![Ajout de la règle de géolocalisation](img/single_git_add_geolocation_rule_v12_3.png)

1. Pour le premier **Emplacement**, laissez-le sur `Default`.
1. Sélectionnez **Connect to** et sélectionnez **New endpoint**.
1. Choisissez **Type** `value` et renseignez-le avec `<your **primary** IP address>`.
1. Pour le second **Emplacement**, choisissez `Europe`.
1. Sélectionnez **Connect to** et sélectionnez **New endpoint**.
1. Choisissez **Type** `value` et renseignez-le avec `<your **secondary** IP address>`.

   ![Définition des emplacements et des points de terminaison pour la règle de géolocalisation](img/single_git_add_traffic_policy_endpoints_v12_3.png)

1. Sélectionnez **Create traffic policy**.

   ![Configuration des enregistrements de politique dans la politique de trafic](img/single_git_create_policy_records_with_traffic_policy_v12_3.png)

1. Renseignez **Policy record DNS name** avec `git`.
1. Sélectionnez **Create policy records**.

   ![Politique de trafic créée avec succès avec les enregistrements de politique](img/single_git_created_policy_record_v12_3.png)

Vous avez configuré avec succès un hôte unique, par exemple `git.example.com`, qui distribue le trafic vers vos sites Geo par géolocalisation !

## Configurer les URL de clone Git pour utiliser l'URL Git spéciale {#configure-git-clone-urls-to-use-the-special-git-url}

Lorsqu'un utilisateur clone un dépôt pour la première fois, il copie généralement l'URL Git distante depuis la page du projet. Par défaut, ces URL SSH et HTTP sont basées sur l'URL externe de l'hôte actuel. Par exemple :

- `git@secondary.example.com:group1/project1.git`
- `https://secondary.example.com/group1/project1.git`

![URL SSH et HTTPS du dépôt](img/single_git_clone_panel_v12_3.png)

Vous pouvez personnaliser les éléments suivants :

- L'URL distante SSH pour utiliser le `git.example.com` géolocalisé. Pour ce faire, modifiez l'hôte de l'URL distante SSH en définissant `gitlab_rails['gitlab_ssh_host']` dans `gitlab.rb` des nœuds web.
- L'URL distante HTTP comme indiqué dans [URL de clone Git personnalisée pour HTTP(S)](../../settings/visibility_and_access_controls.md#customize-git-clone-url-for-https).

## Exemple de comportement de traitement des requêtes Git {#example-git-request-handling-behavior}

Après avoir suivi les étapes de configuration décrites précédemment, le traitement des requêtes Git est désormais géolocalisé. Pour les requêtes :

- En dehors de l'Europe, toutes les requêtes sont dirigées vers le site **principal**.
- En Europe, via :
  - HTTP :
    - `git clone http://git.example.com/foo/bar.git` est dirigé vers le site **secondaire**.
    - `git push` est initialement dirigé vers le site **secondaire**, qui redirige automatiquement vers `primary.example.com`.
  - SSH :
    - `git clone git@git.example.com:foo/bar.git` est dirigé vers le site **secondaire**.
    - `git push` est initialement dirigé vers le site **secondaire**, qui transmet automatiquement la requête par proxy à `primary.example.com`.
