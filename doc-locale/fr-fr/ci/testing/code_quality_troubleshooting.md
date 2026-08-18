---
stage: Application Security Testing
group: Static Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Dépannage de Code Quality
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Lorsque vous utilisez Code Quality, vous pouvez rencontrer les problèmes suivants.

## Le code est introuvable et le pipeline s'exécute toujours avec la configuration par défaut {#the-code-cannot-be-found-and-the-pipeline-runs-always-with-default-configuration}

Vous utilisez probablement un runner privé avec la configuration de liaison de socket Docker-in-Docker. Vous devez configurer les vérifications Code Quality pour qu'elles s'exécutent sur votre worker, comme indiqué dans [Use private runners](code_quality_codeclimate_scanning.md#use-private-runners).

## La modification de la configuration par défaut n'a aucun effet {#changing-the-default-configuration-has-no-effect}

Un problème courant est que les termes `Code Quality` (spécifique à GitLab) et `Code Climate` (moteur utilisé par GitLab) sont très similaires. Vous devez ajouter un fichier **`.codeclimate.yml`** pour modifier la configuration par défaut, et non un fichier `.codequality.yml`. Si vous utilisez le mauvais nom de fichier, le [`.codeclimate.yml` par défaut](https://gitlab.com/gitlab-org/ci-cd/codequality/-/blob/master/codeclimate_defaults/.codeclimate.yml.template) est toujours utilisé.

## Aucun rapport Code Quality n'est affiché dans un merge request {#no-code-quality-report-is-displayed-in-a-merge-request}

Les rapports Code Quality provenant de la branche source ou de la branche cible peuvent être manquants pour la comparaison dans le merge request, ce qui rend l'affichage d'informations impossible.

L'absence de rapport sur la branche source peut être due à :

1. L'utilisation de la [variable d'environnement `REPORT_STDOUT`](https://gitlab.com/gitlab-org/ci-cd/codequality#environment-variables) : aucun fichier de rapport n'est généré et rien ne s'affiche dans le merge request.

L'absence de rapport sur la branche cible peut être due à :

- Un job Code Quality nouvellement ajouté dans votre `.gitlab-ci.yml`.
- Votre pipeline n'est pas configuré pour exécuter le job Code Quality sur votre branche cible.
- Des commits sont effectués sur la branche par défaut sans exécuter le job Code Quality.
- Le paramètre CI/CD [`artifacts:expire_in`](../yaml/_index.md#artifactsexpire_in) peut entraîner l'expiration des artefacts Code Quality plus rapidement que souhaité.

Vérifiez la présence du rapport sur le commit de base en obtenant `base_sha` via l'[API merge request](../../api/merge_requests.md#retrieve-a-merge-request) et utilisez l'[API pipelines avec l'attribut `sha`](../../api/pipelines.md#list-project-pipelines) pour vérifier si des pipelines ont été exécutés.

## Aucun symbole Code Quality dans la vue des modifications {#no-code-quality-symbol-in-the-changes-view}

Si aucun symbole n'est affiché dans la [vue des modifications](code_quality.md#merge-request-changes-view), vérifiez que `location.path` dans le rapport Code Quality :

- Utilise un chemin relatif vers le fichier contenant la violation de qualité du code.
- N'est pas préfixé par `./`. Par exemple, `path` doit être `somedir/file1.rb` plutôt que `./somedir/file1.rb`.

## Un seul rapport Code Quality est affiché, mais d'autres sont définis {#only-a-single-code-quality-report-is-displayed-but-more-are-defined}

Code Quality [combine automatiquement plusieurs rapports](code_quality.md#scan-code-for-quality-violations).

## Erreurs RuboCop {#rubocop-errors}

Lorsque vous utilisez des jobs Code Quality sur un projet Ruby, vous pouvez rencontrer des problèmes lors de l'exécution de RuboCop. Par exemple, l'erreur suivante peut apparaître lors de l'utilisation d'une version de Ruby très récente ou très ancienne :

```plaintext
/usr/local/bundle/gems/rubocop-0.52.1/lib/rubocop/config.rb:510:in `check_target_ruby':
Unknown Ruby version 2.7 found in `.ruby-version`. (RuboCop::ValidationError)
Supported versions: 2.1, 2.2, 2.3, 2.4, 2.5
```

Ce problème est dû au fait que la version par défaut de RuboCop utilisée par le moteur de vérification ne prend pas en charge la version de Ruby utilisée.

Pour utiliser une version personnalisée de RuboCop qui [prend en charge la version de Ruby utilisée par le projet](https://docs.rubocop.org/rubocop/compatibility.html#support-matrix), vous pouvez [remplacer la configuration via un fichier `.codeclimate.yml`](https://docs.codeclimate.com/docs/rubocop#using-rubocops-newer-versions) créé dans le dépôt du projet.

Par exemple, pour spécifier l'utilisation de la release RuboCop **0.67** :

```yaml
version: "2"
plugins:
  rubocop:
    enabled: true
    channel: rubocop-0-67
```

## Aucune information Code Quality n'apparaît dans les merge requests lors de l'utilisation d'un outil personnalisé {#no-code-quality-appears-on-merge-requests-when-using-custom-tool}

Si vos merge requests n'affichent aucune modification Code Quality lors de l'utilisation d'un outil personnalisé, vérifiez que *toutes* les propriétés de ligne dans le JSON sont de type `integer`.

## Erreur : `Could not analyze code quality` {#error-could-not-analyze-code-quality}

Vous pourriez obtenir l'erreur suivante :

```shell
error: (CC::CLI::Analyze::EngineFailure) engine pmd ran for 900 seconds and was killed
Could not analyze code quality for the repository at /code
```

Si vous avez activé l'un des plugins Code Climate et que le job CI/CD Code Quality échoue avec ce message d'erreur, il est probable que le job prenne plus de temps que le délai d'expiration par défaut de 900 secondes :

Pour contourner ce problème, définissez `TIMEOUT_SECONDS` sur une valeur plus élevée dans votre fichier `.gitlab-ci.yml`.

Par exemple :

```yaml
code_quality:
  variables:
    TIMEOUT_SECONDS: 3600
```

## Utilisation de Code Quality avec un runner Kubernetes ou OpenShift {#using-code-quality-with-a-kubernetes-or-openshift-runner}

L'analyse basée sur CodeClimate présente des exigences particulières. Vous devrez peut-être [configurer les runners Kubernetes ou OpenShift pour l'analyse basée sur CodeClimate](code_quality_codeclimate_scanning.md#configure-kubernetes-or-openshift-runners) avant que les analyses fonctionnent correctement.

## Erreur : `x509: certificate signed by unknown authority` {#error-x509-certificate-signed-by-unknown-authority}

Si vous définissez `CODE_QUALITY_IMAGE` sur une image hébergée dans un registre Docker utilisant un certificat TLS non approuvé, tel qu'un certificat auto-signé, vous pourriez voir l'erreur suivante :

```shell
$ docker pull --quiet "$CODE_QUALITY_IMAGE"
Error response from daemon: Get https://gitlab.example.com/v2/: x509: certificate signed by unknown authority
```

Pour résoudre ce problème, configurez le daemon Docker pour qu'il [approuve les certificats](https://distribution.github.io/distribution/about/insecure/#use-self-signed-certificates) en plaçant le certificat dans le répertoire `/etc/docker/certs.d`.

Ce daemon Docker est exposé au conteneur Docker Code Quality suivant dans le [modèle GitLab Code Quality](https://gitlab.com/gitlab-org/gitlab/-/blob/v13.8.3-ee/lib/gitlab/ci/templates/Jobs/Code-Quality.gitlab-ci.yml#L41) et doit également être exposé à tous les autres conteneurs dans lesquels vous souhaitez que votre configuration de certificat s'applique.

### Docker {#docker}

Si vous avez accès à la configuration de GitLab Runner, ajoutez le répertoire en tant que [montage de volume](https://docs.gitlab.com/runner/configuration/advanced-configuration/#volumes-in-the-runnersdocker-section).

Remplacez `gitlab.example.com` par le domaine réel du registre.

Exemple :

```toml
[[runners]]
  ...
  executor = "docker"
  [runners.docker]
    ...
    privileged = true
    volumes = ["/cache", "/etc/gitlab-runner/certs/gitlab.example.com.crt:/etc/docker/certs.d/gitlab.example.com/ca.crt:ro"]
```

### Kubernetes {#kubernetes}

Si vous avez accès à la configuration de GitLab Runner et au cluster Kubernetes, vous pouvez [monter un ConfigMap](https://docs.gitlab.com/runner/executors/kubernetes/#configmap-volume).

Remplacez `gitlab.example.com` par le domaine réel du registre.

1. Créez un ConfigMap avec le certificat :

   ```shell
   kubectl create configmap registry-crt --namespace gitlab-runner --from-file /etc/gitlab-runner/certs/gitlab.example.com.crt
   ```

1. Mettez à jour le fichier `config.toml` de GitLab Runner pour spécifier le ConfigMap :

   ```toml
   [[runners]]
     ...
     executor = "kubernetes"
     [runners.kubernetes]
       image = "alpine:3.12"
       privileged = true
       [[runners.kubernetes.volumes.config_map]]
         name = "registry-crt"
         mount_path = "/etc/docker/certs.d/gitlab.example.com/ca.crt"
         sub_path = "gitlab.example.com.crt"
   ```

## Échec du chargement du rapport Code Quality {#failed-to-load-code-quality-report}

Le rapport Code Quality peut ne pas se charger lorsque des problèmes surviennent lors de l'analyse des données du fichier d'artefact. Pour obtenir des informations sur les erreurs, vous pouvez exécuter une requête GraphQL en suivant les étapes ci-dessous :

1. Accédez à la page de détails du pipeline.
1. Ajoutez `.json` à l'URL.
1. Copiez l'`iid` du pipeline.
1. Accédez à l'[explorateur GraphQL interactif](../../api/graphql/_index.md#interactive-graphql-explorer).
1. Exécutez la requête suivante :

   ```graphql
   {
     project(fullPath: "<fullpath-to-your-project>") {
       pipeline(iid: "<iid>") {
         codeQualityReports {
           count
           nodes {
             line
             description
             path
             fingerprint
             severity
           }
           pageInfo {
             hasNextPage
             hasPreviousPage
             startCursor
             endCursor
           }
         }
       }
     }
   }
   ```

## Aucun artefact de rapport n'est créé {#no-report-artifact-is-created}

Avec certaines configurations de runner, le job d'analyse Code Quality peut ne pas avoir accès à votre code source. Si cela se produit, l'artefact `gl-code-quality-report.json` ne sera pas créé.

Pour résoudre ce problème, vous pouvez :

- Utilisez la [configuration de runner documentée pour Docker-in-Docker](../docker/using_docker_build.md#use-docker-in-docker), qui utilise le mode privilégié au lieu de la liaison de socket Docker.
- Appliquez la [solution de contournement de la communauté dans le ticket 32027](https://gitlab.com/gitlab-org/gitlab/-/issues/32027#note_1318822628) si vous souhaitez continuer à utiliser la liaison de socket Docker.

Pour plus de détails, consultez [Change Runner configuration](code_quality_codeclimate_scanning.md#change-runner-configuration).
