---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Proxying des assets
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Un problème de sécurité potentiel lors de la gestion d'une instance GitLab publique est la possibilité de voler l'adresse IP d'un utilisateur en référençant des images dans des tickets et des commentaires.

Par exemple, l'ajout de `![An example image.](http://example.com/example.png)` à la description d'un ticket entraîne le chargement de l'image depuis le serveur externe pour l'afficher. Cependant, cela permet également au serveur externe d'enregistrer l'adresse IP de l'utilisateur.

Une façon d'atténuer ce risque consiste à proxyer toutes les images externes vers un serveur que vous contrôlez.

GitLab peut être configuré pour utiliser un serveur proxy d'assets lors de la demande d'images/vidéos/fichiers audio externes dans les tickets et les commentaires. Cela permet de s'assurer que les images malveillantes n'exposent pas l'adresse IP de l'utilisateur lors de leur récupération.

Nous recommandons actuellement d'utiliser [cactus/go-camo](https://github.com/cactus/go-camo#how-it-works), car il prend en charge le proxying de vidéo et d'audio, et est plus configurable.

## Installation du serveur Camo {#installing-camo-server}

Un serveur Camo est utilisé pour jouer le rôle de proxy.

Pour installer un serveur Camo en tant que proxy d'assets :

1. Déployez un serveur `go-camo`. Des instructions utiles sont disponibles dans [building cactus/go-camo](https://github.com/cactus/go-camo#building).

   > [!warning]
   > Les serveurs Asset Proxy doivent être configurés pour utiliser des en-têtes Content Security Policy corrects, tels que `form-action 'none'` (en complément des en-têtes `go-camo` par défaut).

1. Assurez-vous que votre instance GitLab est en cours d'exécution et que vous avez créé un jeton d'API privé. À l'aide de l'API, configurez les paramètres du proxy d'assets sur votre instance GitLab. Par exemple :

   ```shell
   curl --request "PUT" "https://gitlab.example.com/api/v4/application/settings?\
   asset_proxy_enabled=true&\
   asset_proxy_url=https://proxy.gitlab.example.com&\
   asset_proxy_secret_key=<somekey>" \
   --header 'PRIVATE-TOKEN: <my_private_token>'
   ```

   Les paramètres suivants sont pris en charge :

   | Attribut                | Description                                                                                                                          |
   |:-------------------------|:-------------------------------------------------------------------------------------------------------------------------------------|
   | `asset_proxy_enabled`    | Active le proxying des assets. Si activé, nécessite : `asset_proxy_url`.                                                                  |
   | `asset_proxy_secret_key` | Secret partagé avec le serveur proxy d'assets.                                                                                           |
   | `asset_proxy_url`        | URL du serveur proxy d'assets.                                                                                                       |
   | `asset_proxy_whitelist`  | (Obsolète : utilisez `asset_proxy_allowlist` à la place) Les assets correspondant à ces domaines ne sont PAS proxiés. Les caractères génériques sont autorisés. L'URL d'installation de votre GitLab est automatiquement autorisée.         |
   | `asset_proxy_allowlist`  | Les assets correspondant à ces domaines ne sont PAS proxiés. Les caractères génériques sont autorisés. L'URL d'installation de votre GitLab est automatiquement autorisée.         |

1. Redémarrez le serveur pour que les modifications prennent effet. Chaque fois que vous modifiez des valeurs pour le proxy d'assets, vous devez redémarrer le serveur.

## Utilisation du serveur Camo {#using-the-camo-server}

Une fois le serveur Camo en cours d'exécution et les paramètres GitLab activés, toute image, vidéo ou fichier audio référençant une source externe est proxié vers le serveur Camo.

Par exemple, voici un lien vers une image en Markdown :

```markdown
![A GitLab logo.](https://about.gitlab.com/images/press/logo/jpg/gitlab-icon-rgb.jpg)
```

Voici un exemple de lien source qui pourrait en résulter :

```plaintext
http://proxy.gitlab.example.com/f9dd2b40157757eb82afeedbf1290ffb67a3aeeb/68747470733a2f2f61626f75742e6769746c61622e636f6d2f696d616765732f70726573732f6c6f676f2f6a70672f6769746c61622d69636f6e2d7267622e6a7067
```
