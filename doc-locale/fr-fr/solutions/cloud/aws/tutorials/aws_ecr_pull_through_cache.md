---
stage: Solutions Architecture
group: Solutions Architecture
info: This page is owned by the Solutions Architecture team.
description: "Index des solutions d'intégration pour GitLab et AWS."
title: 'Tutoriel : configuration des règles de cache pull-through AWS ECR pour un accès authentifié aux projets GitLab.com'
---

1. Ouvrez la console Amazon ECR à l'adresse <https://console.aws.amazon.com/ecr/>.
1. Dans la barre de navigation, choisissez la région dans laquelle configurer les paramètres de votre registre de conteneurs privé.
1. Dans le volet de navigation, choisissez Private registry, puis Pull through cache.
1. Sur la page de configuration Pull through cache, choisissez Add rule.

À l'étape 1 : sur la page Specify a source, pour Registry, choisissez GitLab Container Registry, puis Next.

À l'étape 2 : sur la page Configure authentication, pour Upstream credentials, vous devez stocker vos informations d'authentification pour le registre de conteneurs GitLab dans un secret AWS Secrets Manager. Vous pouvez spécifier un secret existant ou utiliser la console Amazon ECR pour créer un nouveau secret.

Pour utiliser un secret existant, choisissez Use an existing AWS secret. Pour Secret name, utilisez la liste déroulante pour sélectionner votre secret existant, puis choisissez Next. Pour plus d'informations sur la création d'un secret Secrets Manager à l'aide de la console Secrets Manager, consultez Storing your upstream repository credentials in an AWS Secrets Manager secret.

> [!note]
> La console AWS Management Console affiche uniquement les secrets Secrets Manager dont le nom utilise le préfixe ecr-pullthroughcache/. Le secret doit également se trouver dans le même compte et la même région que ceux dans lesquels la règle pull through cache est créée.

Pour créer un nouveau secret, choisissez Create an AWS secret, effectuez les opérations suivantes, puis choisissez Next.

Pour Secret name, spécifiez un nom descriptif pour le secret. Les noms de secrets doivent contenir entre 1 et 512 caractères Unicode.

Pour GitLab Container Registry username, spécifiez votre nom d'utilisateur du registre de conteneurs GitLab.

Pour GitLab Container Registry access token, spécifiez votre jeton d'accès au registre de conteneurs GitLab. Pour respecter les principes du moindre privilège, créez un jeton d'accès de groupe avec le rôle Invité et uniquement la portée `read_registry`.

À l'étape 3 : sur la page Specify a destination, pour Amazon ECR repository prefix, spécifiez le préfixe de l'espace de nommage du dépôt à utiliser lors de la mise en cache des images extraites du registre de conteneurs public source, puis choisissez Next.

Par défaut, un espace de nommage est renseigné, mais un espace de nommage personnalisé peut également être spécifié.

À l'étape 4 : sur la page Review and create, vérifiez la configuration de la règle pull through cache, puis choisissez Create.

Répétez l'étape précédente pour chaque pull through cache que vous souhaitez créer. Les règles pull through cache sont créées séparément pour chaque région.

Pour valider que votre règle ECR Pull Through Cache a bien été créée, vous pouvez exécuter la commande suivante via l'AWS CLI afin de valider la règle :

```shell
aws ecr validate-pull-through-cache-rule \
     --ecr-repository-prefix ecr-public \
     --region us-east-2
```

Pour valider que votre règle ECR Pull Through Cache fournit un accès pull-through au registre de conteneurs upstream GitLab.com, vous pouvez effectuer la validation en exécutant une commande `docker pull` :

```shell
docker pull aws_account_id.dkr.ecr.region.amazonaws.com/{destination-namespace e.g. gitlab-ef1b}/{path to Gitlab.com project/group where image is hosted}/image_name:tag
```

Exemple de commande `docker pull` :

```shell
docker pull aws_account_id.dkr.ecr.region.amazonaws.com/gitlab-ef1b/guided-explorations/ci-components/working-code-examples/kaniko-component-multiarch-build:latest
```
