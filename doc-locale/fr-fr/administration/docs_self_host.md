---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Héberger la documentation produit GitLab
description: Hébergez vous-même la documentation produit.
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed

{{< /details >}}

Si vous ne pouvez pas accéder à la documentation produit GitLab sur `docs.gitlab.com`, vous pouvez héberger vous-même la documentation à la place.

> [!note]
> L'aide locale de votre instance n'inclut pas toute la documentation (par exemple, elle n'inclut pas la documentation pour GitLab Runner ou GitLab Operator) et n'est ni consultable ni navigable. Elle est uniquement destinée à prendre en charge les liens directs vers des pages spécifiques depuis votre instance.

## URL du registre de conteneurs {#container-registry-url}

L'URL de l'image de conteneur souhaitée dépend de la version de la documentation GitLab dont vous avez besoin. Consultez le tableau suivant comme guide pour l'URL à utiliser dans les sections suivantes.

| Version de GitLab | Registre de conteneurs                                                                           | URL de l'image de conteneur |
|:---------------|:---------------------------------------------------------------------------------------------|:--------------------|
| 17.8 et versions ultérieures | <https://gitlab.com/gitlab-org/technical-writing/docs-gitlab-com/container_registry/8244403> | `registry.gitlab.com/gitlab-org/technical-writing/docs-gitlab-com/archives:<version>` |
| 15.5 - 17.7    | <https://gitlab.com/gitlab-org/gitlab-docs/container_registry/3631228>                       | `registry.gitlab.com/gitlab-org/gitlab-docs/archives:<version>` |
| 10.3 - 15.4    | <https://gitlab.com/gitlab-org/gitlab-docs/container_registry/631635>                        | `registry.gitlab.com/gitlab-org/gitlab-docs:<version>` |

## Options d'auto-hébergement de la documentation {#documentation-self-hosting-options}

Pour héberger la documentation produit GitLab, vous pouvez utiliser :

- Un conteneur Docker
- GitLab Pages
- Votre propre serveur web

Les exemples suivants utilisent GitLab 17.8, mais veillez à utiliser la version qui correspond à votre instance GitLab.

### Auto-héberger la documentation produit avec Docker {#self-host-the-product-documentation-with-docker}

Le site web de documentation est servi sur le port `4000` à l'intérieur du conteneur. Dans l'exemple suivant, nous l'exposons sur l'hôte sous le même port.

Assurez-vous de faire l'une des opérations suivantes :

- Autoriser le port `4000` dans votre pare-feu.
- Utiliser un port différent. Dans les exemples suivants, remplacez le `4000` le plus à gauche par un numéro de port différent.

Pour exécuter le site web de documentation produit GitLab dans un conteneur Docker :

1. Sur le serveur où vous hébergez GitLab, ou sur tout autre serveur avec lequel votre instance GitLab peut communiquer :

   - Si vous utilisez Docker simple, exécutez :

     ```shell
     docker run --detach --name gitlab_docs -it --rm -p 4000:4000 registry.gitlab.com/gitlab-org/technical-writing/docs-gitlab-com/archives:17.8
     ```

   - Si vous hébergez votre instance GitLab avec [Docker compose](../install/docker/installation.md#install-gitlab-by-using-docker-compose), ajoutez ce qui suit à votre fichier `docker-compose.yaml` existant :

     ```yaml
     version: '3.6'
     services:
       gitlab_docs:
         image: registry.gitlab.com/gitlab-org/technical-writing/docs-gitlab-com/archives:17.8
         hostname: 'docs.gitlab.example.com'
         ports:
           - '4000:4000'
     ```

     Ensuite, récupérez les modifications :

     ```shell
     docker-compose up -d
     ```

1. Visitez `http://0.0.0.0:4000` pour afficher le site web de documentation et vérifier qu'il fonctionne.
1. [Redirigez les liens d'aide vers le nouveau site de documentation](#redirect-the-help-links-to-the-new-docs-site).

### Auto-héberger la documentation produit avec GitLab Pages {#self-host-the-product-documentation-with-gitlab-pages}

Vous pouvez utiliser GitLab Pages pour héberger la documentation produit GitLab.

Prérequis :

- Assurez-vous que l'URL du site Pages n'utilise pas de sous-dossier. En raison de la façon dont le site est précompilé, les fichiers CSS et JavaScript sont relatifs au domaine principal ou au sous-domaine. Par exemple, les URL telles que `https://example.com/docs/` ne sont pas prises en charge.

Pour héberger le site de documentation produit avec GitLab Pages :

1. [Créez un projet vide](../user/project/_index.md#create-a-blank-project).
1. Créez un nouveau fichier `.gitlab-ci.yml` ou modifiez votre fichier existant, et ajoutez le job `pages` suivant, en vous assurant que la version est la même que celle de votre installation GitLab :

   ```yaml
   pages:
     image: registry.gitlab.com/gitlab-org/technical-writing/docs-gitlab-com/archives:17.8
     script:
       - mkdir public
       - cp -a /usr/share/nginx/html/* public/
     artifacts:
       paths:
       - public
   ```

1. Facultatif. Définissez le nom de domaine GitLab Pages. Selon le type de site web GitLab Pages, vous avez deux options :

   | Type de site web         | [Domaine par défaut](../user/project/pages/getting_started_part_one.md#gitlab-pages-default-domain-names) | [Domaine personnalisé](../user/project/pages/custom_domains_ssl_tls_certification/_index.md) |
   |-------------------------|----------------|---------------|
   | [Site web de projet](../user/project/pages/getting_started_part_one.md#project-website-examples) | Non pris en charge | Pris en charge |
   | [Site web d'utilisateur ou de groupe](../user/project/pages/getting_started_part_one.md#user-and-group-website-examples) | Pris en charge | Pris en charge |

1. [Redirigez les liens d'aide vers le nouveau site de documentation](#redirect-the-help-links-to-the-new-docs-site).

### Auto-héberger la documentation produit sur votre propre serveur web {#self-host-the-product-documentation-on-your-own-web-server}

> [!note]
> Le site web que vous créez doit être hébergé sous un sous-répertoire qui correspond à votre version de GitLab installée (par exemple, `17.8/`). Les [images Docker](https://gitlab.com/gitlab-org/technical-writing/docs-gitlab-com/container_registry/8244403) utilisent cette version par défaut.

Comme le site de documentation produit est statique, vous pouvez prendre le contenu de `/usr/share/nginx/html` depuis l'intérieur du conteneur et utiliser votre propre serveur web pour héberger la documentation où vous le souhaitez.

Le répertoire `html` doit être servi tel quel et possède la structure suivante :

```plaintext
├── 17.8/
├── index.html
```

Dans cet exemple :

- `17.8/` est le répertoire où la documentation est hébergée.
- `index.html` est un fichier HTML simple qui redirige vers le répertoire contenant la documentation. Dans ce cas, `17.8/`.

Pour extraire les fichiers HTML du site de documentation :

1. Créez le conteneur qui contient les fichiers HTML du site web de documentation :

   ```shell
   docker create -it --name gitlab_docs registry.gitlab.com/gitlab-org/technical-writing/docs-gitlab-com/archives:17.8
   ```

1. Copiez le site web sous `/srv/gitlab/` :

   ```shell
   docker cp gitlab-docs:/usr/share/nginx/html /srv/gitlab/
   ```

   Vous obtenez un répertoire `/srv/gitlab/html/` qui contient le site web de documentation.

1. Supprimez le conteneur :

   ```shell
   docker rm -f gitlab_docs
   ```

1. Configurez votre serveur web pour servir le contenu de `/srv/gitlab/html/`.
1. [Redirigez les liens d'aide vers le nouveau site de documentation](#redirect-the-help-links-to-the-new-docs-site).

## Rediriger les liens `/help` vers le nouveau site de documentation {#redirect-the-help-links-to-the-new-docs-site}

Une fois votre site de documentation produit local en cours d'exécution, [redirigez les liens d'aide](settings/help_page.md#redirect-help-pages) dans l'application GitLab vers votre site local, en utilisant le nom de domaine complet comme URL de documentation. Par exemple, si vous avez utilisé la [méthode Docker](#self-host-the-product-documentation-with-docker), saisissez `http://0.0.0.0:4000`.

Vous n'avez pas besoin d'ajouter la version. GitLab la détecte et l'ajoute aux requêtes d'URL de documentation selon les besoins. Par exemple, si votre version de GitLab est 17.8 :

- L'URL de documentation GitLab devient `http://0.0.0.0:4000/17.8/`.
- Le lien dans GitLab s'affiche comme `<instance_url>/help/administration/settings/help_page#destination-requirements`.
- Lorsque vous sélectionnez le lien, vous êtes redirigé vers `http://0.0.0.0:4000/17.8/administration/settings/help_page/#destination-requirements`.

Pour tester le paramètre, dans GitLab, sélectionnez un lien **En savoir plus**. Par exemple :

1. Dans le coin supérieur droit, sélectionnez votre avatar.
1. Sélectionnez **Préférences**.
1. Dans la section **Syntax highlighting theme**, sélectionnez **En savoir plus**.

## Mettre à niveau la documentation produit vers une version ultérieure {#upgrade-the-product-documentation-to-a-later-version}

La mise à niveau du site de documentation vers une version ultérieure nécessite le téléchargement du tag d'image Docker plus récent.

### Mise à niveau avec Docker {#upgrade-using-docker}

Pour mettre à niveau vers une version ultérieure [avec Docker](#self-host-the-product-documentation-with-docker) :

- Si vous utilisez Docker :

  1. Arrêtez le conteneur en cours d'exécution :

     ```shell
     sudo docker stop gitlab_docs
     ```

  1. Supprimez le conteneur existant :

     ```shell
     sudo docker rm gitlab_docs
     ```

  1. Téléchargez la nouvelle image. Par exemple, 17.8 :

     ```shell
     docker run --detach --name gitlab_docs -it --rm -p 4000:4000 registry.gitlab.com/gitlab-org/technical-writing/docs-gitlab-com/archives:17.8
     ```

- Si vous utilisez Docker Compose :

  1. Modifiez la version dans `docker-compose.yaml`, par exemple 17.8 :

     ```yaml
     version: '3.6'
     services:
       gitlab_docs:
         image: registry.gitlab.com/gitlab-org/technical-writing/docs-gitlab-com/archives:17.8
         hostname: 'docs.gitlab.example.com'
         ports:
           - '4000:4000'
     ```

  1. Récupérez les modifications :

     ```shell
     docker-compose up -d
     ```

### Mise à niveau avec GitLab Pages {#upgrade-using-gitlab-pages}

Pour mettre à niveau vers une version ultérieure [avec GitLab Pages](#self-host-the-product-documentation-with-gitlab-pages) :

1. Modifiez votre fichier `.gitlab-ci.yml` existant et remplacez le numéro de version de `image` :

   ```yaml
   image: registry.gitlab.com/gitlab-org/technical-writing/docs-gitlab-com/archives:17.8
   ```

1. Validez les modifications, poussez-les, et GitLab Pages récupère la nouvelle version du site de documentation.

### Mise à niveau avec votre propre serveur web {#upgrade-using-your-own-web-server}

Pour mettre à niveau vers une version ultérieure [avec votre propre serveur web](#self-host-the-product-documentation-on-your-own-web-server) :

1. Copiez les fichiers HTML du site de documentation :

   ```shell
   docker create -it --name gitlab_docs registry.gitlab.com/gitlab-org/technical-writing/docs-gitlab-com/archives:17.8
   docker cp gitlab_docs:/usr/share/nginx/html /srv/gitlab/
   docker rm -f gitlab_docs
   ```

1. Facultatif. Supprimez l'ancien site :

   ```shell
   rm -r /srv/gitlab/html/17.8/
   ```

## Dépannage {#troubleshooting}

### La recherche ne fonctionne pas {#search-does-not-work}

La recherche locale est incluse dans les versions 15.6 et ultérieures. Si vous utilisez une version antérieure, la recherche ne fonctionne pas.

Pour plus d'informations, consultez les [différents types de recherches](https://gitlab.com/gitlab-org/technical-writing/docs-gitlab-com/-/blob/main/doc/search.md) utilisés par la documentation GitLab.

### L'image Docker est introuvable {#the-docker-image-is-not-found}

Si vous obtenez une erreur indiquant que l'image Docker est introuvable, vérifiez que vous utilisez la [bonne URL de registre](#container-registry-url).

### Le site de documentation hébergé dans Docker ne parvient pas à rediriger {#docker-hosted-documentation-site-fails-to-redirect}

Lors de la prévisualisation de la documentation GitLab dans Docker sur macOS, vous pouvez rencontrer un problème empêchant la redirection vers la documentation, affichant le message `If you are not redirected automatically, click here.`

Pour contourner la redirection, vous devez ajouter le numéro de version à l'URL, par exemple `http://127.0.0.1:4000/16.8/`.
