---
stage: Verify
group: Runner Core
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "Déployez des applications de GitLab CI/CD vers AWS, notamment ECS et EC2, en utilisant les images Docker et les modèles CloudFormation fournis par GitLab."
title: Déployer vers AWS depuis GitLab CI/CD
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

GitLab fournit des images Docker avec les bibliothèques et les outils dont vous avez besoin pour déployer vers AWS. Vous pouvez référencer ces images dans votre pipeline CI/CD.

Si vous utilisez GitLab.com et que vous déployez vers [Amazon Elastic Container Service](https://aws.amazon.com/ecs/) (ECS), consultez [le déploiement vers ECS](ecs/deploy_to_aws_ecs.md).

> [!note]
> Si vous êtes à l'aise avec la configuration d'un déploiement par vous-même et que vous avez simplement besoin de récupérer des informations d'identification AWS, envisagez d'utiliser [les jetons d'identification et OpenID Connect](../cloud_services/aws/_index.md). Les jetons d'identification sont plus sécurisés que le stockage des informations d'identification dans des variables CI/CD, mais ne fonctionnent pas avec les instructions de cette page.

## Authentifier GitLab avec AWS {#authenticate-gitlab-with-aws}

Pour utiliser GitLab CI/CD afin de vous connecter à AWS, vous devez vous authentifier. Une fois l'authentification configurée, vous pouvez configurer CI/CD pour le déploiement.

1. Connectez-vous à votre compte AWS.
1. Créez [un utilisateur IAM](https://console.aws.amazon.com/iam/home#/home).
1. Sélectionnez votre utilisateur pour accéder à ses détails. Accédez à **Security credentials** > **Create a new access key**.
1. Notez l'**Access key ID** et la **Secret access key**.
1. Dans votre projet GitLab, accédez à **Paramètres** > **CI/CD**. Définissez les [variables CI/CD](../variables/_index.md) suivantes :

   | Nom de la variable d'environnement | Valeur |
   |:--------------------------|:------|
   | `AWS_ACCESS_KEY_ID`       | Votre Access key ID. |
   | `AWS_SECRET_ACCESS_KEY`   | Votre Secret access key. |
   | `AWS_DEFAULT_REGION`      | Le code de votre région. Vous pouvez vérifier que le service AWS que vous comptez utiliser est [disponible dans la région choisie](https://aws.amazon.com/about-aws/global-infrastructure/regional-product-services/). |

1. Les variables sont [protégées par défaut](../variables/_index.md#protect-a-cicd-variable). Pour utiliser GitLab CI/CD avec des branches ou des tags qui ne sont pas protégés, décochez la case **Protéger la variable**.

## Utiliser une image pour exécuter des commandes AWS {#use-an-image-to-run-aws-commands}

Si une image contient l'[AWS Command Line Interface](https://aws.amazon.com/cli/), vous pouvez référencer l'image dans le fichier `.gitlab-ci.yml` de votre projet. Vous pouvez ensuite exécuter des commandes `aws` dans vos jobs CI/CD.

Par exemple :

```yaml
deploy:
  stage: deploy
  image: registry.gitlab.com/gitlab-org/cloud-deploy/aws-base:latest
  script:
    - aws s3 ...
    - aws create-deployment ...
  environment: production
```

GitLab fournit une image Docker qui inclut l'AWS CLI :

- Les images sont hébergées dans le registre de conteneurs GitLab. La dernière image est `registry.gitlab.com/gitlab-org/cloud-deploy/aws-base:latest`.
- [Les images sont stockées dans un dépôt GitLab](https://gitlab.com/gitlab-org/cloud-deploy/-/tree/master/aws).

Vous pouvez également utiliser une image d'[Amazon Elastic Container Registry (ECR)](https://aws.amazon.com/ecr/). [Découvrez comment envoyer une image vers votre dépôt ECR](https://docs.aws.amazon.com/AmazonECR/latest/userguide/docker-push-ecr-image.html).

Vous pouvez également utiliser une image provenant d'un registre tiers.

## Déployer votre application vers ECS {#deploy-your-application-to-ecs}

Vous pouvez automatiser les déploiements de votre application vers votre cluster [Amazon ECS](https://aws.amazon.com/ecs/).

Prérequis :

- [Authentifiez AWS avec GitLab](#authenticate-gitlab-with-aws).
- Créez un cluster sur Amazon ECS.
- Créez les composants associés, comme un service ECS ou une base de données sur Amazon RDS.
- Créez une définition de tâche ECS dans laquelle la valeur de l'attribut `containerDefinitions[].name` est identique au `Container name` défini dans votre service ECS ciblé. La définition de tâche peut être :
  - Une définition de tâche existante dans ECS.
  - Un fichier JSON dans votre projet GitLab. Utilisez le [modèle de la documentation AWS](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/create-task-definition.html#task-definition-template) et enregistrez le fichier dans votre projet. Par exemple `<project-root>/ci/aws/task-definition.json`.

Pour déployer vers votre cluster ECS :

1. Dans votre projet GitLab, accédez à **Paramètres** > **CI/CD**. Définissez les [variables CI/CD](../variables/_index.md) suivantes. Vous pouvez trouver ces noms en sélectionnant le cluster ciblé dans votre [tableau de bord Amazon ECS](https://console.aws.amazon.com/ecs/home).

   | Nom de la variable d'environnement         | Valeur |
   |:----------------------------------|:------|
   | `CI_AWS_ECS_CLUSTER`              | Le nom du cluster AWS ECS que vous ciblez pour vos déploiements. |
   | `CI_AWS_ECS_SERVICE`              | Le nom du service ciblé associé à votre cluster AWS ECS. Assurez-vous que cette variable est limitée à la portée de l'environnement approprié (`production`, `staging`, `review/*`). |
   | `CI_AWS_ECS_TASK_DEFINITION`      | Si la définition de tâche est dans ECS, le nom de la définition de tâche associée au service. |
   | `CI_AWS_ECS_TASK_DEFINITION_FILE` | Si la définition de tâche est un fichier JSON dans GitLab, le nom du fichier, y compris le chemin d'accès. Par exemple, `ci/aws/my_task_definition.json`. Si le nom de la définition de tâche dans votre fichier JSON est identique au nom d'une définition de tâche existante dans ECS, une nouvelle révision est créée lors de l'exécution de CI/CD. Sinon, une toute nouvelle définition de tâche est créée, à partir de la révision 1. |

   > [!warning]
   > Si vous définissez à la fois `CI_AWS_ECS_TASK_DEFINITION_FILE` et `CI_AWS_ECS_TASK_DEFINITION`, `CI_AWS_ECS_TASK_DEFINITION_FILE` est prioritaire.

1. Incluez ce modèle dans `.gitlab-ci.yml` :

   ```yaml
   include:
     - template: AWS/Deploy-ECS.gitlab-ci.yml
   ```

   Le modèle `AWS/Deploy-ECS` est fourni avec GitLab et est disponible [sur GitLab.com](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/AWS/Deploy-ECS.gitlab-ci.yml).

1. Commitez et envoyez votre `.gitlab-ci.yml` mis à jour vers le dépôt de votre projet.

L'image Docker de votre application est reconstruite et envoyée vers le registre de conteneurs GitLab. Si votre image se trouve dans un registre privé, assurez-vous que votre définition de tâche est [configurée avec un attribut `repositoryCredentials`](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/private-auth.html).

La définition de tâche ciblée est mise à jour avec l'emplacement de la nouvelle image Docker, et une nouvelle révision est créée dans ECS en conséquence.

Enfin, votre service AWS ECS est mis à jour avec la nouvelle révision de la définition de tâche, ce qui fait extraire au cluster la version la plus récente de votre application.

Les jobs de déploiement ECS attendent que le déploiement soit terminé avant de se terminer. Pour désactiver ce comportement, définissez `CI_AWS_ECS_WAIT_FOR_ROLLOUT_COMPLETE_DISABLED` sur une valeur non vide.

> [!warning]
> Le modèle [`AWS/Deploy-ECS.gitlab-ci.yml`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/AWS/Deploy-ECS.gitlab-ci.yml) inclut deux modèles : [`Jobs/Build.gitlab-ci.yml`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Jobs/Build.gitlab-ci.yml) et [`Jobs/Deploy/ECS.gitlab-ci.yml`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Jobs/Deploy/ECS.gitlab-ci.yml). N'incluez pas ces modèles séparément. Incluez uniquement le modèle `AWS/Deploy-ECS.gitlab-ci.yml`. Ces autres modèles sont conçus pour être utilisés uniquement avec le modèle principal. Ils peuvent être déplacés ou modifiés de manière inattendue. De plus, les noms des jobs dans ces modèles peuvent changer. Ne remplacez pas ces noms de jobs dans votre propre pipeline, car le remplacement cesse de fonctionner lorsque le nom change.

## Déployer votre application vers EC2 {#deploy-your-application-to-ec2}

GitLab fournit un modèle, appelé `AWS/CF-Provision-and-Deploy-EC2`, pour vous aider à déployer vers Amazon EC2.

Lorsque vous configurez les objets JSON associés et utilisez le modèle, le pipeline :

1. **Creates the stack** : Votre infrastructure est provisionnée à l'aide de l'API [AWS CloudFormation](https://aws.amazon.com/cloudformation/).
1. **Pushes to an S3 bucket** : Lors de l'exécution de votre build, un artefact est créé. L'artefact est envoyé vers un bucket [AWS S3](https://aws.amazon.com/s3/).
1. **Deploys to EC2** : Le contenu est déployé sur une instance [AWS EC2](https://aws.amazon.com/ec2/), comme illustré dans ce schéma :

![Représentation du pipeline CF-Provision-and-Deploy-EC2, incluant les étapes de provisionnement de l'infrastructure, d'envoi des artefacts vers S3 et de déploiement vers EC2.](img/cf_ec2_diagram_v13_5.png)

### Configurer le modèle et le JSON {#configure-the-template-and-json}

Pour déployer vers EC2, effectuez les étapes suivantes.

1. Créez le JSON pour votre stack. Utilisez le [modèle AWS](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/template-anatomy.html).
1. Créez le JSON pour l'envoi vers S3. Incluez les détails suivants.

   ```json
   {
     "applicationName": "string",
     "source": "string",
     "s3Location": "s3://your/bucket/project_built_file...]"
   }
   ```

   Le champ `source` correspond à l'emplacement où un job `build` a compilé votre application. Le build est enregistré dans [`artifacts:paths`](../yaml/_index.md#artifactspaths).

1. Créez le JSON pour le déploiement vers EC2. Utilisez le [modèle AWS](https://docs.aws.amazon.com/codedeploy/latest/APIReference/API_CreateDeployment.html).
1. Rendez les objets JSON accessibles à votre pipeline :
   - Si vous souhaitez enregistrer ces objets JSON dans votre dépôt, enregistrez les objets sous la forme de trois fichiers distincts.

     Dans votre fichier `.gitlab-ci.yml`, ajoutez des [variables CI/CD](../variables/_index.md) pointant vers les chemins de fichiers relatifs à la racine du projet. Par exemple, si vos fichiers JSON se trouvent dans un dossier `<project_root>/aws` :

     ```yaml
     variables:
       CI_AWS_CF_CREATE_STACK_FILE: 'aws/cf_create_stack.json'
       CI_AWS_S3_PUSH_FILE: 'aws/s3_push.json'
       CI_AWS_EC2_DEPLOYMENT_FILE: 'aws/create_deployment.json'
     ```

   - Si vous ne souhaitez pas enregistrer ces objets JSON dans votre dépôt, ajoutez chaque objet en tant que [variable CI/CD de type fichier](../variables/_index.md#use-file-type-cicd-variables) distincte dans les paramètres du projet. Utilisez les mêmes noms de variables que précédemment.

1. Dans votre fichier `.gitlab-ci.yml`, créez une variable CI/CD pour le nom de la stack. Par exemple :

   ```yaml
   variables:
     CI_AWS_CF_STACK_NAME: 'YourStackName'
   ```

1. Dans votre fichier `.gitlab-ci.yml`, ajoutez le modèle CI :

   ```yaml
   include:
     - template: AWS/CF-Provision-and-Deploy-EC2.gitlab-ci.yml
   ```

1. Exécutez le pipeline.

   - Votre stack AWS CloudFormation est créée en fonction du contenu de votre variable `CI_AWS_CF_CREATE_STACK_FILE`. Si votre stack existe déjà, cette étape est ignorée, mais le job `provision` auquel elle appartient s'exécute quand même.
   - Votre application compilée est envoyée vers votre bucket S3 puis déployée vers votre instance EC2, en fonction du contenu de l'objet JSON associé. Le job de déploiement se termine lorsque le déploiement vers EC2 est terminé ou a échoué.

## Dépannage {#troubleshooting}

### Erreur `'ascii' codec can't encode character '\uxxxx'` {#error-ascii-codec-cant-encode-character-uxxxx}

Cette erreur peut se produire lorsque la réponse de l'utilitaire `aws-cli` utilisé par les images Cloud Deploy contient un caractère Unicode. Les images Cloud Deploy n'ont pas de paramètre régional défini et utilisent par défaut l'ASCII. Pour résoudre cette erreur, ajoutez la variable CI/CD suivante :

```yaml
variables:
  LANG: "UTF-8"
```
