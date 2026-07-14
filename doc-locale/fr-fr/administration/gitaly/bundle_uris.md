---
stage: Tenant Scale
group: Gitaly
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: URI de bundle
---

{{< details >}}

Édition : Gratuite, GitLab Premium, GitLab Ultimate

Offre : GitLab Self-Managed

{{< /details >}}

{{< history >}}

- [Introduit](https://gitlab.com/groups/gitlab-org/-/epics/8939) dans GitLab 17.0 [avec un flag](../feature_flags/_index.md) nommé `gitaly_bundle_uri`. Désactivé par défaut.

{{< /history >}}

Gitaly prend en charge les [URI de bundle](https://git-scm.com/docs/bundle-uri) Git. Les URI de bundle sont des emplacements où Git peut télécharger un ou plusieurs bundles pour initialiser la base de données d'objets avant de récupérer les objets restants depuis un remote. Les URI de bundle sont intégrés au protocole Git.

L'utilisation des URI de bundle peut :

- Accélérer les clones et les récupérations pour les utilisateurs disposant d'une mauvaise connexion réseau vers le serveur GitLab. Les bundles peuvent être stockés sur un CDN, les rendant disponibles partout dans le monde.
- Réduire la charge sur les serveurs qui exécutent des jobs CI/CD. Si les jobs CI/CD peuvent précharger des bundles depuis un autre emplacement, le travail restant pour récupérer de manière incrémentielle les objets et références manquants crée beaucoup moins de charge sur le serveur.

## Prérequis {#prerequisites}

Les prérequis pour l'utilisation des URI de bundle dépendent de si le clonage s'effectue dans un job CI/CD ou localement dans un terminal.

### Clonage dans des jobs CI/CD {#cloning-in-cicd-jobs}

Pour préparer l'utilisation des URI de bundle dans des jobs CI/CD :

1. Sélectionnez une [image helper GitLab Runner](https://gitlab.com/gitlab-org/gitlab-runner/container_registry/1472754) utilisée par GitLab Runner vers une version qui exécute :

   - Git version 2.49.0 ou ultérieure.
   - GitLab Runner helper version 18.0 ou ultérieure.

   Cette étape est requise car l'URI de bundle est un mécanisme qui vise à réduire la charge sur le serveur Git lors d'un `git clone`. Ainsi, lorsqu'un pipeline CI/CD s'exécute, le client `git` qui initie la commande `git clone` est le GitLab Runner. Le processus `git` s'exécute à l'intérieur de l'image helper.

   Assurez-vous de sélectionner une image correspondant à la distribution du système d'exploitation et à l'architecture que vous utilisez pour vos runners GitLab.

   Vous pouvez vérifier que l'image satisfait aux exigences en exécutant ces commandes :

   ```shell
   docker run -it <image:tag>
   $ git version
   $ gitlab-runner-helper -v
   ```

   Nous nous appuyons sur le gestionnaire de paquets de la distribution du système d'exploitation pour gérer la version de Git dans l'image `gitlab-runner-helper`. Par conséquent, certaines des dernières images disponibles pourraient ne pas encore exécuter Git 2.49.

   Si vous ne trouvez pas d'image répondant aux exigences, utilisez `gitlab-runner-helper` comme image de base pour votre propre image personnalisée. Vous pouvez héberger votre image personnalisée en utilisant le [registre de conteneurs GitLab](../../user/packages/container_registry/_index.md).

1. Configurez vos instances GitLab Runner pour utiliser l'image sélectionnée en mettant à jour votre fichier `config.toml` :

   ```toml
   [[runners]]
     (...)
     executor = "docker"
     [runners.docker]
       (...)
       helper_image = "image:tag" ## <-- put the image name and tag here
   ```

    Pour plus de détails, consultez les [informations sur l'image helper](https://docs.gitlab.com/runner/configuration/advanced-configuration/#helper-image).

1. Redémarrez les runners pour que la nouvelle configuration prenne effet.
1. Activez le feature flag `FF_USE_GIT_NATIVE_CLONE` [GitLab Runner](https://docs.gitlab.com/runner/configuration/feature-flags/) dans votre fichier `.gitlab-ci.yml` en le définissant à `true` :

   ```yaml
   variables:
     FF_USE_GIT_NATIVE_CLONE: "true"
   ```

### Clonage localement dans votre terminal {#cloning-locally-in-your-terminal}

Pour préparer l'utilisation des URI de bundle pour le clonage localement dans votre terminal, activez `bundle-uri` dans votre configuration Git locale :

```shell
git config --global transfer.bundleuri true
```

## Configuration du serveur {#server-configuration}

Vous devez configurer l'emplacement de stockage des bundles. Gitaly prend en charge les services de stockage suivants :

- Google Cloud Storage
- AWS S3 (ou compatible)
- Azure Blob Storage
- Stockage de fichiers local (non recommandé)

### Configurer le stockage Azure Blob {#configure-azure-blob-storage}

La façon dont vous configurez Azure Blob Storage pour les URI de bundle dépend du type d'installation que vous avez. Pour les installations compilées manuellement, vous devez définir les variables d'environnement `AZURE_STORAGE_ACCOUNT` et `AZURE_STORAGE_KEY` en dehors de GitLab.

{{< tabs >}}

{{< tab title="Linux package (Omnibus)" >}}

Modifiez `/etc/gitlab/gitlab.rb` et configurez le `bundle_uri.go_cloud_url` :

```ruby
gitaly['env'] = {
    'AZURE_STORAGE_ACCOUNT' => 'azure_storage_account',
    'AZURE_STORAGE_KEY' => 'azure_storage_key' # or 'AZURE_STORAGE_SAS_TOKEN'
}
gitaly['configuration'] = {
    bundle_uri: {
        go_cloud_url: 'azblob://<bucket>'
    }
}
```

{{< /tab >}}

{{< tab title="Self-compiled (source)" >}}

Modifiez `/home/git/gitaly/config.toml` et configurez `go_cloud_url` :

```toml
[bundle_uri]
go_cloud_url = "azblob://<bucket>"
```

{{< /tab >}}

{{< /tabs >}}

### Configurer le stockage Google Cloud {#configure-google-cloud-storage}

Le stockage Google Cloud (GCP) s'authentifie en utilisant les identifiants par défaut de l'application. Configurez les identifiants par défaut de l'application sur chaque serveur Gitaly en utilisant l'une des méthodes suivantes :

- La commande [`gcloud auth application-default login`](https://cloud.google.com/sdk/gcloud/reference/auth/application-default/login).
- La variable d'environnement `GOOGLE_APPLICATION_CREDENTIALS`. Pour les installations compilées manuellement, définissez la variable d'environnement en dehors de GitLab.

Pour plus d'informations, consultez [Application Default Credentials](https://cloud.google.com/docs/authentication/provide-credentials-adc).

Le bucket de destination est configuré à l'aide de l'option `go_cloud_url`.

{{< tabs >}}

{{< tab title="Linux package (Omnibus)" >}}

Modifiez `/etc/gitlab/gitlab.rb` et configurez le `go_cloud_url` :

```ruby
gitaly['env'] = {
    'GOOGLE_APPLICATION_CREDENTIALS' => '/path/to/service.json'
}
gitaly['configuration'] = {
    bundle_uri: {
        go_cloud_url: 'gs://<bucket>'
    }
}
```

{{< /tab >}}

{{< tab title="Self-compiled (source)" >}}

Modifiez `/home/git/gitaly/config.toml` et configurez `go_cloud_url` :

```toml
[bundle_uri]
go_cloud_url = "gs://<bucket>"
```

{{< /tab >}}

{{< /tabs >}}

### Configurer le stockage S3 {#configure-s3-storage}

Pour configurer l'authentification du stockage S3 :

- Si vous vous authentifiez avec l'AWS CLI, vous pouvez utiliser la session AWS par défaut.
- Sinon, vous pouvez utiliser les variables d'environnement `AWS_ACCESS_KEY_ID` et `AWS_SECRET_ACCESS_KEY`. Pour les installations compilées manuellement, définissez les variables d'environnement en dehors de GitLab.

Pour plus d'informations, consultez la [documentation de session AWS](https://docs.aws.amazon.com/sdk-for-go/api/aws/session/).

Le bucket et la région de destination sont configurés à l'aide de l'option `go_cloud_url`.

{{< tabs >}}

{{< tab title="Linux package (Omnibus)" >}}

Modifiez `/etc/gitlab/gitlab.rb` et configurez le `go_cloud_url` :

```ruby
gitaly['env'] = {
    'AWS_ACCESS_KEY_ID' => 'aws_access_key_id',
    'AWS_SECRET_ACCESS_KEY' => 'aws_secret_access_key'
}
gitaly['configuration'] = {
    bundle_uri: {
        go_cloud_url: 's3://<bucket>?region=us-west-1'
    }
}
```

{{< /tab >}}

{{< tab title="Self-compiled (source)" >}}

Modifiez `/home/git/gitaly/config.toml` et configurez `go_cloud_url` :

```toml
[bundle_uri]
go_cloud_url = "s3://<bucket>?region=us-west-1"
```

{{< /tab >}}

{{< /tabs >}}

#### Configurer les serveurs compatibles S3 {#configure-s3-compatible-servers}

{{< history >}}

- Les paramètres `use_path_style` et `disable_https` [introduits](https://gitlab.com/groups/gitlab-org/-/epics/8939) dans GitLab 17.4.

{{< /history >}}

Les serveurs compatibles S3 sont configurés de manière similaire à S3, avec l'ajout du paramètre `endpoint`.

Les paramètres suivants sont pris en charge :

- `region` : La région AWS.
- `endpoint` : L'URL du point de terminaison.
- `disableSSL` : Définir à `true` pour désactiver SSL. Disponible pour GitLab 17.4.0 et versions antérieures. Pour les versions de GitLab postérieures à 17.4.0, utilisez `disable_https`.
- `disable_https` : Définir à `true` pour désactiver HTTPS dans les options du point de terminaison.
- `s3ForcePathStyle` : Définir à `true` pour forcer les URL en style de chemin pour les objets S3. Non disponible dans les versions GitLab 17.4.0 à 17.4.3. Dans ces versions, utilisez `use_path_style` à la place.
- `use_path_style` : Définir à `true` pour activer les URL S3 en style de chemin (`https://<host>/<bucket>` au lieu de `https://<bucket>.<host>`).
- `awssdk` : Forcer une version particulière du SDK AWS. Définir à `v1` pour forcer AWS SDK v1 ou `v2` pour forcer AWS SDK v2. Si :
  - Défini à `v1`, vous devez utiliser `disableSSL` au lieu de `disable_https`.
  - Non défini, la valeur par défaut est `v2`.

`use_path_style` a été introduit lors de la mise à jour de la dépendance Go Cloud Development Kit de v0.38.0 à v0.39.0, qui est passé du SDK AWS v1 au v2. Cependant, le paramètre `s3ForcePathStyle` a été restauré dans GitLab 17.4.4 après que les mainteneurs de gocloud.dev ont ajouté la prise en charge de la compatibilité ascendante. Pour plus d'informations, consultez le [ticket 6489](https://gitlab.com/gitlab-org/gitaly/-/issues/6489).

`disable_https` a été introduit dans le Go Cloud Development Kit v0.40.0 (AWS SDK v2).

`awssdk` a été introduit dans le Go Cloud Development Kit v0.24.0.

{{< tabs >}}

{{< tab title="Linux package (Omnibus)" >}}

Modifiez `/etc/gitlab/gitlab.rb` et configurez le `go_cloud_url` :

```ruby
gitaly['env'] = {
    'AWS_ACCESS_KEY_ID' => '<your_access_key_id>',
    'AWS_SECRET_ACCESS_KEY' => '<your_secret_access_key>'
}
gitaly['configuration'] = {
    bundle_uri: {
        go_cloud_url: 's3://<bucket>?region=us-east-1&endpoint=s3.example.com:9000&disable_https=true&use_path_style=true'
    }
}
```

{{< /tab >}}

{{< tab title="Self-compiled (source)" >}}

Modifiez `/home/git/gitaly/config.toml` et configurez `go_cloud_url` :

```toml
[bundle_uri]
go_cloud_url = "s3://<bucket>?region=us-east-1&endpoint=s3.example.com:9000&disable_https=true&use_path_style=true"
```

{{< /tab >}}

{{< /tabs >}}

## Génération de bundles {#generating-bundles}

Une fois Gitaly configuré, Gitaly peut générer des bundles manuellement ou automatiquement.

### Génération manuelle {#manual-generation}

Cette commande génère le bundle et le stocke sur le service de stockage configuré.

```shell
sudo -u git -- /opt/gitlab/embedded/bin/gitaly bundle-uri \
                                               --config=<config-file> \
                                               --storage=<storage-name> \
                                               --repository=<relative-path>
```

Gitaly ne rafraîchit pas automatiquement le bundle généré. Lorsque vous souhaitez générer une version plus récente d'un bundle, vous devez exécuter la commande à nouveau.

Vous pouvez planifier cette commande avec un outil comme `cron(8)`.

### Génération automatique {#automatic-generation}

{{< history >}}

- [Introduit](https://gitlab.com/groups/gitlab-org/-/epics/16007) dans GitLab 18.0 [avec un flag](../feature_flags/_index.md) nommé `gitaly_bundle_generation`. Désactivé par défaut.

{{< /history >}}

> [!flag]
> La disponibilité de cette fonctionnalité est contrôlée par un feature flag. Pour plus d'informations, consultez l'historique.

Gitaly peut générer des bundles automatiquement en déterminant s'il traite des clones fréquents pour le même dépôt. L'heuristique actuelle suit le nombre de fois qu'une requête `git fetch` est émise pour chaque dépôt. Si le nombre de requêtes atteint un certain seuil dans un intervalle donné, Gitaly génère automatiquement un bundle.

Gitaly suit également la dernière fois qu'il a généré un bundle pour un dépôt. Lorsqu'un nouveau bundle doit être régénéré, en fonction de `threshold` et de `interval`, Gitaly examine la dernière fois qu'un bundle a été généré pour le dépôt concerné. Gitaly génère uniquement un nouveau bundle si le bundle existant est plus ancien que la configuration `maxBundleAge`, auquel cas l'ancien bundle est écrasé. Il ne peut y avoir qu'un seul bundle par dépôt dans le stockage cloud.

## Exemple d'URI de bundle {#bundle-uri-example}

Dans l'exemple suivant, nous démontrons la différence entre le clonage de `gitlab.com/gitlab-org/gitlab.git` avec et sans utilisation des URI de bundle.

```shell
$ git -c transfer.bundleURI=false clone https://gitlab.com/gitlab-org/gitlab.git
Cloning into 'gitlab'...
remote: Enumerating objects: 5271177, done.
remote: Total 5271177 (delta 0), reused 0 (delta 0), pack-reused 5271177
Receiving objects: 100% (5271177/5271177), 1.93 GiB | 32.93 MiB/s, done.
Resolving deltas: 100% (4140349/4140349), done.
Updating files: 100% (71304/71304), done.

$ git -c transfer.bundleURI=true clone https://gitlab.com/gitlab-org/gitlab.git
Cloning into 'gitlab'...
remote: Enumerating objects: 1322255, done.
remote: Counting objects: 100% (611708/611708), done.
remote: Total 1322255 (delta 611708), reused 611708 (delta 611708), pack-reused 710547
Receiving objects: 100% (1322255/1322255), 539.66 MiB | 22.98 MiB/s, done.
Resolving deltas: 100% (1026890/1026890), completed with 223946 local objects.
Checking objects: 100% (8388608/8388608), done.
Checking connectivity: 1381139, done.
Updating files: 100% (71304/71304), done.
```

Dans l'exemple précédent :

- Sans utilisation d'un URI de bundle, 5 271 177 objets ont été reçus depuis le serveur GitLab.
- Avec utilisation d'un URI de bundle, 1 322 255 objets ont été reçus depuis le serveur GitLab.

Cette réduction signifie que GitLab doit regrouper moins d'objets (dans l'exemple précédent, environ un quart du nombre d'objets) car le client a d'abord téléchargé le bundle depuis le serveur de stockage.

## Sécurisation des bundles {#securing-bundles}

Les bundles sont rendus accessibles au client à l'aide d'URL signées. Une URL signée est une URL qui fournit des autorisations limitées et un délai pour effectuer une requête. Pour savoir si votre service de stockage prend en charge les URL signées, consultez la documentation de votre service de stockage.
