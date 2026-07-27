---
stage: Verify
group: Runner Core
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "Déployer un projet GitLab sur Amazon ECS. Conteneuriser l'application et configurer le déploiement continu, les environnements éphémères et les tests de sécurité."
title: Déployer sur Amazon Elastic Container Service
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Ce guide étape par étape vous aide à déployer un projet hébergé sur GitLab.com vers l'[Elastic Container Service (ECS)](https://aws.amazon.com/ecs/) d'Amazon.

Dans ce guide, vous commencez par créer un cluster ECS manuellement à l'aide de la console AWS. Vous créez et déployez une application simple à partir d'un modèle GitLab.

Ces instructions fonctionnent pour les instances GitLab.com et GitLab Self-Managed. Assurez-vous que vos propres [runners sont configurés](../../runners/_index.md).

## Prérequis {#prerequisites}

- Un [compte AWS](https://repost.aws/knowledge-center/create-and-activate-aws-account). Connectez-vous avec un compte AWS existant ou créez-en un nouveau.
- Dans ce guide, vous créez une infrastructure dans la [région `us-east-2`](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/using-regions-availability-zones.html). Vous pouvez utiliser n'importe quelle région, mais ne la modifiez pas après avoir commencé.

## Créer une infrastructure et un déploiement initial sur AWS {#create-an-infrastructure-and-initial-deployment-on-aws}

Pour déployer une application depuis GitLab, vous devez d'abord créer une infrastructure et un déploiement initial sur AWS. Cela inclut un [cluster ECS](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/clusters.html) et les composants associés, tels que les [définitions de tâches ECS](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task_definitions.html), les [services ECS](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/ecs_services.html) et une image d'application conteneurisée.

Pour la première étape, vous créez une application de démonstration à partir d'un modèle de projet.

### Créer un nouveau projet à partir d'un modèle {#create-a-new-project-from-a-template}

Utilisez un modèle de projet GitLab pour commencer. Comme leur nom l'indique, ces projets fournissent une application minimaliste reposant sur des frameworks bien connus.

1. Dans le coin supérieur droit, sélectionnez **Créer un nouveau** ({{< icon name="plus" >}}) et **Nouveau projet/dépôt**.
1. Sélectionnez **Créer à partir d'un modèle**, où vous pouvez choisir parmi un projet Ruby on Rails, Spring ou NodeJS Express. Pour ce guide, utilisez le modèle Ruby on Rails.
1. Donnez un nom à votre projet. Dans cet exemple, il est nommé `ecs-demo`. Rendez-le public pour profiter des fonctionnalités disponibles dans le [plan GitLab Ultimate](https://about.gitlab.com/pricing/).
1. Sélectionnez **Créer le projet**.

Maintenant que vous avez créé un projet de démonstration, vous devez conteneuriser l'application et la pousser vers le registre de conteneurs.

### Pousser une image d'application conteneurisée vers le registre de conteneurs GitLab {#push-a-containerized-application-image-to-gitlab-container-registry}

[ECS](https://aws.amazon.com/ecs/) est un service d'orchestration de conteneurs, ce qui signifie que vous devez fournir une image d'application conteneurisée lors de la construction de l'infrastructure. Pour ce faire, vous pouvez utiliser [Auto Build](../../../topics/autodevops/stages.md#auto-build) et le [registre de conteneurs](../../../user/packages/container_registry/_index.md) de GitLab.

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et trouvez votre projet `ecs-demo`.
1. Sélectionnez **Configuration CI/CD**. Cela vous amène à un formulaire de création `.gitlab-ci.yml`.
1. Copiez et collez le contenu suivant dans le fichier `.gitlab-ci.yml` vide. Cela définit un pipeline pour le déploiement continu vers ECS.

   ```yaml
   include:
     - template: AWS/Deploy-ECS.gitlab-ci.yml
   ```

1. Sélectionnez **Valider les modifications**. Cela déclenche automatiquement un nouveau pipeline. Dans ce pipeline, le job `build` conteneurise l'application et pousse l'image vers le [registre de conteneurs GitLab](../../../user/packages/container_registry/_index.md).

1. Accédez à **Déploiement** > **Registre de conteneurs**. Assurez-vous que l'image de l'application a bien été poussée.

   ![Une image d'application conteneurisée dans le registre de conteneurs GitLab.](img/registry_v13_10.png)

Vous disposez maintenant d'une image d'application conteneurisée qui peut être extraite depuis AWS. Ensuite, vous définissez les spécifications d'utilisation de cette image d'application dans AWS.

Le job `production_ecs` échoue car le cluster ECS n'est pas encore connecté. Vous pouvez résoudre ce problème plus tard.

### Créer une définition de tâche ECS {#create-an-ecs-task-definition}

[Les définitions de tâches ECS](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task_definitions.html) sont une spécification concernant la façon dont l'image d'application est démarrée par un [service ECS](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/ecs_services.html).

1. Accédez à **ECS** > **Task Definitions** sur la [console AWS](https://aws.amazon.com/).
1. Sélectionnez **Create new Task Definition**.

   ![Page des définitions de tâches avec un bouton « Create new task definition ».](img/ecs-task-definitions_v13_10.png)

1. Choisissez **EC2** comme type de lancement. Sélectionnez **Next Step**.
1. Définissez `ecs_demo` dans **Task Definition Name**.
1. Définissez `512` dans **Task Size** > **Task memory** et **Task CPU**.
1. Sélectionnez **Container Definitions** > **Add container**. Cela ouvre un formulaire d'enregistrement de conteneur.
1. Définissez `web` dans **Container name**.
1. Définissez `registry.gitlab.com/<your-namespace>/ecs-demo/master:latest` dans **Image**. Vous pouvez également copier et coller le chemin de l'image depuis la [page du registre de conteneurs GitLab](#push-a-containerized-application-image-to-gitlab-container-registry).

   ![Champs du nom du conteneur et de l'image complétés.](img/container-name_v13_10.png)

1. Ajoutez un mappage de ports. Définissez `80` dans **Host Port** et `5000` dans **Container port**.

   ![Champs des mappages de ports complétés.](img/container-port-mapping_v13_10.png)

1. Sélectionnez **Créer**.

Vous disposez maintenant de la définition de tâche initiale. Ensuite, vous créez une infrastructure réelle pour exécuter l'image d'application.

### Créer un cluster ECS {#create-an-ecs-cluster}

Un [cluster ECS](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/clusters.html) est un groupe virtuel de [services ECS](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/ecs_services.html). Il est également associé à EC2 ou Fargate en tant que ressource de calcul.

1. Accédez à **ECS** > **Clusters** sur la [console AWS](https://aws.amazon.com/).
1. Sélectionnez **Create Cluster**.
1. Sélectionnez **EC2 Linux + Networking** comme modèle de cluster. Sélectionnez **Next Step**.
1. Définissez `ecs-demo` dans **Cluster Name**.
1. Choisissez le [VPC](https://aws.amazon.com/vpc/?vpc-blogs.sort-by=item.additionalFields.createdDate&vpc-blogs.sort-order=desc) par défaut dans **Networking**. S'il n'existe aucun VPC, vous pouvez laisser le champ tel quel pour en créer un nouveau.
1. Définissez tous les sous-réseaux disponibles du VPC dans **Subnets**.
1. Sélectionnez **Créer**.
1. Assurez-vous que le cluster ECS a bien été créé.

   ![Cluster ECS créé avec succès avec toutes les instances en cours d'exécution.](img/ecs-launch-status_v13_10.png)

Vous pouvez maintenant enregistrer un service ECS dans le cluster ECS à l'étape suivante.

Notez les points suivants :

- Vous pouvez éventuellement définir une paire de clés SSH dans le formulaire de création. Cela vous permet de vous connecter en SSH à l'instance EC2 à des fins de débogage.
- Si vous ne choisissez pas un VPC existant, un nouveau VPC est créé par défaut. Cela peut entraîner une erreur si le nombre maximal autorisé de passerelles Internet sur votre compte est atteint.
- Le cluster nécessite une instance EC2, ce qui implique des coûts [selon le type d'instance](https://aws.amazon.com/ec2/pricing/on-demand/).

### Créer un service ECS {#create-an-ecs-service}

[Le service ECS](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/ecs_services.html) est un démon qui crée un conteneur d'application basé sur la [définition de tâche ECS](#create-an-ecs-task-definition).

1. Accédez à **ECS** > **Clusters** > **ecs-demo** > **Services** sur la [console AWS](https://aws.amazon.com/)
1. Sélectionnez **Déploiement**. Cela ouvre un formulaire de création de service.
1. Sélectionnez `EC2` dans **Launch Type**.
1. Définissez `ecs_demo` dans **Task definition**. Cela correspond à [la définition de tâche créée précédemment](#create-an-ecs-task-definition).
1. Définissez `ecs_demo` dans **Nom du service**.
1. Définissez `1` dans **Desired tasks**.

   ![Page des services avec tous les champs complétés.](img/service-parameter_v13_10.png)

1. Sélectionnez **Déploiement**.
1. Assurez-vous que le service créé est actif.

   ![Un service actif en cours d'exécution avec des tâches.](img/service-running_v13_10.png)

L'interface utilisateur de la console AWS change de temps en temps. Si vous ne trouvez pas un composant pertinent dans les instructions, sélectionnez le plus proche.

### Voir l'application de démonstration {#view-the-demo-application}

L'application de démonstration est maintenant accessible depuis Internet.

1. Accédez à **EC2** > **Instances** sur la [console AWS](https://aws.amazon.com/)
1. Recherchez par `ECS Instance` pour trouver l'instance EC2 correspondante que [le cluster ECS a créée](#create-an-ecs-cluster).
1. Sélectionnez l'ID de l'instance EC2. Cela vous amène à la page de détails de l'instance.
1. Copiez **Public IPv4 address** et collez-la dans le navigateur. Vous pouvez maintenant voir l'application de démonstration en cours d'exécution.

   ![L'application de démonstration en cours d'exécution dans un navigateur.](img/view-running-app_v13_10.png)

Dans ce guide, HTTPS/SSL n'est pas configuré. Vous pouvez accéder à l'application uniquement via HTTP (par exemple, `http://<ec2-ipv4-address>`).

## Configurer le déploiement continu depuis GitLab {#set-up-continuous-deployment-from-gitlab}

Maintenant que vous avez une application en cours d'exécution sur ECS, vous pouvez configurer le déploiement continu depuis GitLab.

### Créer un nouvel utilisateur IAM en tant que déployeur {#create-a-new-iam-user-as-a-deployer}

Pour que GitLab puisse accéder au cluster ECS, au service et à la définition de tâche que vous avez créés précédemment, vous devez créer un utilisateur déployeur sur AWS :

1. Accédez à **IAM** > **Utilisateurs** sur la [console AWS](https://aws.amazon.com/).
1. Sélectionnez **Ajouter un utilisateur ou une utilisatrice**.
1. Définissez `ecs_demo` dans **User name**.
1. Activez la case à cocher **Programmatic access**. Sélectionnez **Next: Permissions**.
1. Sélectionnez `Attach existing policies directly` dans **Set permissions**.
1. Sélectionnez `AmazonECS_FullAccess` dans la liste des politiques. Sélectionnez **Next: Tags** et **Next: Review**.

   ![Une politique `AmazonECS_FullAccess` sélectionnée.](img/ecs-policy_v13_10.png)

1. Sélectionnez **Créer un utilisateur**.
1. Notez l'**Access key ID** et la **Secret access key** de l'utilisateur créé.

> [!note]
> Ne partagez pas la clé d'accès secrète dans un endroit public. Vous devez la conserver dans un endroit sécurisé.

### Configurer les identifiants dans GitLab pour permettre aux jobs de pipeline d'accéder à ECS {#setup-credentials-in-gitlab-to-let-pipeline-jobs-access-to-ecs}

Vous pouvez enregistrer les informations d'accès dans les [variables CI/CD GitLab](../../variables/_index.md). Ces variables CI/CD sont injectées dans les jobs de pipeline et peuvent accéder à l'API ECS.

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et trouvez votre projet `ecs-demo`.
1. Accédez à **Paramètres** > **CI/CD** > **Variables**.
1. Sélectionnez **Add Variable** et définissez les paires clé-valeur suivantes.

   | Clé                          | Valeur                                 | Remarque |
   |------------------------------|---------------------------------------|------|
   | `AWS_ACCESS_KEY_ID`          | `<Access key ID of the deployer>`     | Pour l'authentification de l'interface de ligne de commande `aws`. |
   | `AWS_SECRET_ACCESS_KEY`      | `<Secret access key of the deployer>` | Pour l'authentification de l'interface de ligne de commande `aws`. |
   | `AWS_DEFAULT_REGION`         | `us-east-2`                           | Pour l'authentification de l'interface de ligne de commande `aws`. |
   | `CI_AWS_ECS_CLUSTER`         | `ecs-demo`                            | Le cluster ECS est accessible par le job `production_ecs`. |
   | `CI_AWS_ECS_SERVICE`         | `ecs_demo`                            | Le service ECS du cluster est mis à jour par le job `production_ecs`. Assurez-vous que cette variable CI/CD est limitée à l'environnement approprié (`production`, `staging`, `review/*`). |
   | `CI_AWS_ECS_TASK_DEFINITION` | `ecs_demo`                            | La définition de tâche ECS est mise à jour par le job `production_ecs`. |

### Apporter une modification à l'application de démonstration {#make-a-change-to-the-demo-application}

Modifiez un fichier dans le projet et vérifiez si la modification est reflétée dans l'application de démonstration sur ECS :

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et trouvez votre projet `ecs-demo`.
1. Ouvrez le fichier `app/views/welcome/index.html.erb`.
1. Sélectionnez **Éditer**.
1. Remplacez le texte par `You're on ECS!`.
1. Sélectionnez **Valider les modifications**. Cela déclenche automatiquement un nouveau pipeline. Attendez qu'il se termine.
1. [Accédez à l'application en cours d'exécution sur le cluster ECS](#view-the-demo-application). Vous devriez voir ceci :

   ![Application en cours d'exécution sur ECS avec un message de confirmation.](img/view-running-app-2_v13_10.png)

Félicitations ! Vous avez correctement configuré le déploiement continu vers ECS.

> [!note]
> Les jobs de déploiement ECS attendent que le déploiement soit terminé avant de se fermer. Pour désactiver ce comportement, définissez `CI_AWS_ECS_WAIT_FOR_ROLLOUT_COMPLETE_DISABLED` sur une valeur non vide.

## Configurer les environnements éphémères {#set-up-review-apps}

Pour utiliser les environnements éphémères avec ECS :

1. Configurez un nouveau [service](#create-an-ecs-service).
1. Utilisez la variable CI/CD `CI_AWS_ECS_SERVICE` pour définir le nom.
1. Définissez la portée de l'environnement sur `review/*`.

Un seul environnement éphémère peut être déployé à la fois, car ce service est partagé par tous les environnements éphémères.

## Configurer les tests de sécurité {#set-up-security-testing}

### Configurer SAST {#configure-sast}

Pour utiliser [SAST](../../../user/application_security/sast/_index.md) avec ECS, ajoutez ce qui suit à votre fichier `.gitlab-ci.yml` :

```yaml
include:
   - template: Jobs/SAST.gitlab-ci.yml
```

Pour plus de détails et d'options de configuration, consultez la [documentation SAST](../../../user/application_security/sast/_index.md#configuration).

### Configurer DAST {#configure-dast}

Pour utiliser [DAST](../../../user/application_security/dast/_index.md) sur les branches non par défaut, [configurez des environnements éphémères](#set-up-review-apps) et ajoutez ce qui suit à votre fichier `.gitlab-ci.yml` :

```yaml
include:
  - template: Security/DAST.gitlab-ci.yml
```

Pour utiliser DAST sur la branche par défaut :

1. Configurez un nouveau [service](#create-an-ecs-service). Ce service sera utilisé pour déployer un environnement DAST temporaire.
1. Utilisez la variable CI/CD `CI_AWS_ECS_SERVICE` pour définir le nom.
1. Définissez la portée sur l'environnement `dast-default`.
1. Ajoutez ce qui suit à votre fichier `.gitlab-ci.yml` :

```yaml
include:
  - template: Security/DAST.gitlab-ci.yml
  - template: Jobs/DAST-Default-Branch-Deploy.gitlab-ci.yml
```

Pour plus de détails et d'options de configuration, consultez la [documentation DAST](../../../user/application_security/dast/_index.md).

## Pour aller plus loin {#further-reading}

- Si vous souhaitez en savoir plus sur les déploiements continus vers le cloud, consultez [les déploiements cloud](../_index.md).
- Si vous souhaitez configurer rapidement DevSecOps dans votre projet, consultez [Auto DevOps](../../../topics/autodevops/_index.md).
- Si vous souhaitez configurer rapidement l'environnement de qualité production, consultez [l'application de production en 5 minutes](https://gitlab.com/gitlab-org/5-minute-production-app/deploy-template/-/blob/master/README.md).
