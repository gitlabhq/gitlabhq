---
stage: Verify
group: Runner Core
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Migrer depuis les applications gérées par GitLab vers les projets de gestion de cluster (déprécié)
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Les applications gérées par GitLab ont été dépréciées en faveur des projets de gestion de cluster contrôlés par les utilisateurs. La gestion de vos applications de cluster via un projet vous offre bien plus de flexibilité pour gérer votre cluster qu'avec les anciennes applications gérées par GitLab. Pour migrer vers le projet de gestion de cluster, vous devez disposer de [GitLab Runners](../../ci/runners/_index.md) et être familiarisé avec [Helm](https://helm.sh/).

## Migrer vers un projet de gestion de cluster {#migrate-to-a-cluster-management-project}

Pour migrer depuis les applications gérées par GitLab vers un projet de gestion de cluster, suivez les étapes ci-dessous. Consultez également les [vidéos de présentation](#video-walk-throughs) avec des exemples.

1. Créez un nouveau projet basé sur le [modèle de projet de gestion de cluster](management_project_template.md#create-a-project-based-on-the-cluster-management-project-template).
1. [Installez un agent](agent/install/_index.md) pour ce projet dans votre cluster.
1. Définissez la variable CI/CD `KUBE_CONTEXT` sur le contexte de l'agent nouvellement installé, comme indiqué dans le fichier `.gitlab-ci.yml` du modèle de projet.
1. Détectez les applications déployées via des releases Helm v2 en utilisant le fichier [`.gitlab-ci.yml`](management_project_template.md#the-gitlab-ciyml-file) préconfiguré :

   - Si vous avez écrasé l'espace de nommage par défaut des applications gérées par GitLab, modifiez `.gitlab-ci.yml` et assurez-vous que le script reçoit l'espace de nommage correct en argument :

     ```yaml
     script:
       - gl-fail-if-helm2-releases-exist <your_custom_namespace>
     ```

   - Si vous avez conservé le nom par défaut (`gitlab-managed-apps`), le script est déjà configuré.

   Dans tous les cas, [exécutez un pipeline manuellement](../../ci/pipelines/_index.md#run-a-pipeline-manually) et lisez les logs du job `detect-helm2-releases` pour connaître les releases Helm v2 dont vous disposez, le cas échéant.

1. Si vous n'avez aucune release Helm v2, ignorez cette étape. Sinon, suivez la documentation officielle de Helm sur [la migration de Helm v2 vers Helm v3](https://helm.sh/blog/migrate-from-helm-v2-to-helm-v3/), et nettoyez les releases Helm v2 une fois que vous êtes certain qu'elles ont été migrées avec succès.

1. À cette étape, vous ne devriez avoir que des releases Helm v3. Décommentez depuis le fichier principal [`./helmfile.yaml`](management_project_template.md#the-main-helmfileyml-file) les chemins des applications que vous souhaitez gérer avec ce projet. Bien que vous puissiez décommenter en une seule fois toutes celles que vous souhaitez gérer, vous devriez répéter les étapes suivantes séparément pour chaque application, afin de ne pas vous perdre durant le processus.
1. Modifiez le fichier `applications/{app}/helmfiles.yaml` associé pour qu'il corresponde à la version du chart déployée pour votre application. Prenons comme exemple une release GitLab Runner Helm v3 :

   La commande suivante liste les releases et leurs versions :

   ```shell
   helm ls -n gitlab-managed-apps

   NAME NAMESPACE REVISION UPDATED STATUS CHART APP VERSION
   runner gitlab-managed-apps 1 2021-06-09 19:36:55.739141644 +0000 UTC deployed gitlab-runner-0.28.0 13.11.0
   ```

   Récupérez la version depuis la colonne `CHART`, qui est au format `{release}-v{chart_version}`, puis modifiez l'attribut `version:` dans le fichier `./applications/gitlab-runner/helmfile.yaml` afin qu'il corresponde à la version que vous avez déployée. Il s'agit d'une étape sécurisée permettant d'éviter toute mise à niveau de version durant cette migration. Assurez-vous de remplacer `gitlab-managed-apps` dans la commande précédente si vos applications sont déployées dans un espace de nommage différent.

1. Modifiez le fichier `applications/{app}/values.yaml` associé à votre application pour qu'il corresponde aux valeurs déployées. Par exemple, pour GitLab Runner :

   1. Copiez la sortie de la commande suivante (elle peut être volumineuse) :

      ```shell
      helm get values runner -n gitlab-managed-apps -a --output yaml
      ```

   1. Écrasez `applications/gitlab-runner/values.yaml` avec la sortie de la commande précédente.

   Cette étape sécurisée garantit qu'aucune valeur par défaut inattendue n'écrase vos valeurs déployées. Par exemple, les valeurs `gitlabUrl` ou `runnerRegistrationToken` de votre GitLab Runner pourraient être écrasées par erreur.

1. Certaines applications nécessitent une attention particulière :

   - Ingress : en raison d'un [problème de chart](https://github.com/helm/charts/pull/13646) existant, vous pourriez voir `spec.clusterIP: Invalid value` lorsque vous tentez d'exécuter la commande [`./gl-helmfile`](management_project_template.md#the-gitlab-ciyml-file). Pour contourner ce problème, après avoir écrasé les valeurs de la release dans `applications/ingress/values.yaml`, vous pourriez avoir besoin d'écraser toutes les occurrences de `omitClusterIP: false`, en les remplaçant par `omitClusterIP: true`. Une autre approche consiste à collecter ces adresses IP en exécutant `kubectl get services -n gitlab-managed-apps`, puis à écraser chaque `ClusterIP` signalé avec la valeur obtenue depuis cette commande.

   - Vault : cette application introduit un changement incompatible entre le chart utilisé dans Helm v2 et celui utilisé dans Helm v3. Ainsi, la seule façon de l'intégrer à ce projet de gestion de cluster est de désinstaller cette application et d'accepter la version du chart proposée dans `applications/vault/values.yaml`.

   - Cert-manager :

     - Pour les utilisateurs de Kubernetes version 1.20 ou ultérieure, le cert-manager v0.10 déprécié n'est plus valide et la mise à niveau inclut un changement incompatible. Vous devez donc [sauvegarder et désinstaller cert-manager v0.10](#backup-and-uninstall-cert-manager-v010), puis installer la dernière version de cert-manager à la place. Pour installer cette version, décommentez `applications/cert-manager/helmfile.yaml` depuis [`./helmfile.yaml`](management_project_template.md#the-main-helmfileyml-file). Cela déclenche un pipeline pour installer la nouvelle version.
     - Pour les utilisateurs de Kubernetes en version inférieure à 1.20, vous pouvez rester sur la v0.10 en décommentant `applications/cert-manager-legacy/helmfile.yaml` dans le Helmfile principal de votre projet ([`./helmfile.yaml`](management_project_template.md#the-main-helmfileyml-file)).

       > [!warning]
       > Cert-manager v0.10 cesse de fonctionner lorsque Kubernetes est mis à niveau vers la version 1.20 ou ultérieure.

1. Après avoir suivi toutes les étapes précédentes, [exécutez un pipeline manuellement](../../ci/pipelines/_index.md#run-a-pipeline-manually) et consultez les job logs du job `apply` pour vérifier si vos applications ont été correctement détectées, installées, et si elles ont reçu des mises à jour inattendues.

   Certaines sommes de contrôle d'annotations sont susceptibles d'être mises à jour, ainsi que cet attribut :

   ```diff
   --- heritage: Tiller
   +++ heritage: Tiller
   ```

Après l'obtention d'un pipeline réussi, répétez ces étapes pour toute autre application déployée que vous souhaitez gérer avec le projet de gestion de cluster.

## Sauvegarder et désinstaller cert-manager v0.10 {#backup-and-uninstall-cert-manager-v010}

1. Suivez la [documentation officielle](https://cert-manager.io/docs/devops-tips/backup/) pour savoir comment sauvegarder vos données cert-manager v0.10.
1. Désinstallez cert-manager en modifiant le fichier `applications/cert-manager/helmfile.yaml` et en remplaçant toutes les occurrences de `installed: true` par `installed: false`.
1. Recherchez les ressources résiduelles en exécutant la commande suivante : `kubectl get Issuers,ClusterIssuers,Certificates,CertificateRequests,Orders,Challenges,Secrets,ConfigMaps -n gitlab-managed-apps | grep certmanager`.
1. Pour chacune des ressources trouvées à l'étape précédente, supprimez-les avec `kubectl delete -n gitlab-managed-apps {ResourceType} {ResourceName}`. Par exemple, si vous avez trouvé une ressource de type `ConfigMap` nommée `cert-manager-controller`, supprimez-la en exécutant : `kubectl delete configmap -n gitlab-managed-apps cert-manager-controller`.

## Vidéos de présentation {#video-walk-throughs}

Vous pouvez visionner ces vidéos avec des exemples illustrant la migration depuis les GMA vers un projet de gestion de cluster :

- [Migration depuis zéro en utilisant un tout nouveau projet de gestion de cluster](https://youtu.be/jCUFGWT0jS0). Couvre également la migration des applications Helm v2.
- [Migration depuis un projet CI/CD d'applications gérées par GitLab existant](https://youtu.be/U2lbBGZjZmc).
