---
stage: Solutions Architecture
group: Solutions Architecture
info: This page is owned by the Solutions Architecture team.
description: "Guide de provisionnement d'une instance GitLab unique sur AWS à l'aide d'abonnements Marketplace ou d'AMI GitLab officielles, incluant les éditions CE/EE et les considérations de licence."
title: Provisionner GitLab sur une instance EC2 unique dans AWS
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed

{{< /details >}}

Si vous souhaitez provisionner une instance GitLab unique sur AWS, vous disposez de deux options :

- L'abonnement Marketplace
- Les AMI GitLab officielles

## Abonnement Marketplace {#marketplace-subscription}

GitLab propose un abonnement de 5 utilisateurs en tant qu'abonnement AWS Marketplace pour aider les équipes de toutes tailles à démarrer avec une instance sous licence GitLab Ultimate en un temps record. L'abonnement Marketplace peut être mis à niveau vers n'importe quelle licence GitLab via une offre privée AWS Marketplace, avec la commodité d'une facturation AWS continue. Aucune migration n'est nécessaire pour obtenir une licence plus large et non limitée dans le temps de la part de GitLab. La licence à la minute est automatiquement supprimée lorsque vous acceptez l'offre privée.

Pour un tutoriel sur le provisionnement d'une instance GitLab via un abonnement Marketplace, [utilisez ce tutoriel](https://gitlab.awsworkshop.io/040_partner_setup.html). Le tutoriel renvoie vers la [GitLab Ultimate Marketplace Listing](https://aws.amazon.com/marketplace/pp/prodview-g6ktjmpuc33zk), mais vous pouvez également utiliser la [GitLab Premium Marketplace Listing](https://aws.amazon.com/marketplace/pp/prodview-amk6tacbois2k) pour provisionner une instance.

## Releases GitLab officielles en tant qu'AMI {#official-gitlab-releases-as-amis}

GitLab produit des Amazon Machine Images (AMI) lors du processus de release régulier. Les AMI peuvent être utilisées pour une installation GitLab sur une instance unique ou, en configurant `/etc/gitlab/gitlab.rb`, peuvent être spécialisées pour des rôles de service GitLab spécifiques (par exemple un serveur Gitaly). Les anciennes releases restent disponibles et peuvent être utilisées pour migrer un ancien serveur GitLab vers AWS.

La licence initiale peut être soit la licence Enterprise gratuite (EE), soit la Community Edition (CE) open source. L'édition Enterprise offre le chemin le plus simple vers une version sous licence si le besoin se présente.

Actuellement, l'AMI Amazon utilise l'AMI Ubuntu préparée par Amazon (x86 et ARM sont disponibles) comme point de départ.

> [!note]
> Lors du déploiement d'une instance GitLab à l'aide de l'AMI officielle, le mot de passe root de l'instance est l'ID **Instance** EC2 (et non l'ID AMI). Cette méthode de définition du mot de passe du compte root est spécifique aux AMI publiées officiellement par GitLab UNIQUEMENT.

Les instances fonctionnant sous Community Edition (CE) nécessitent une migration vers Enterprise Edition (EE) pour s'abonner au plan GitLab Premium ou GitLab Ultimate. Si vous souhaitez souscrire un abonnement, l'utilisation du plan gratuit permanent de l'Enterprise Edition est la méthode la moins perturbatrice.

> [!note]
> Étant donné que toute mise à niveau GitLab peut impliquer des mises à jour du disque de données ou des mises à niveau du schéma de base de données, le remplacement de l'AMI n'est pas suffisant pour effectuer les mises à niveau.

1. Connectez-vous à la AWS Web Console, afin que la sélection des liens à l'étape suivante vous amène directement à la liste des AMI.
1. Choisissez l'édition souhaitée :

   - [GitLab Enterprise Edition](https://console.aws.amazon.com/ec2/v2/home?region=us-east-1#Images:visibility=public-images;owner=782774275127;search=GitLab%20EE;sort=desc:name) : si vous souhaitez débloquer les fonctionnalités enterprise, une licence est nécessaire.
   - [GitLab Community Edition](https://console.aws.amazon.com/ec2/v2/home?region=us-east-1#Images:visibility=public-images;owner=782774275127;search=GitLab%20CE;sort=desc:name) : la version open source de GitLab.
   - [GitLab Premium ou Ultimate Marketplace (pré-licencié)](https://console.aws.amazon.com/ec2/v2/home?region=us-east-1#Images:visibility=public-images;source=Marketplace;search=GitLab%20EE;sort=desc:name) : licence 5 utilisateurs intégrée à la facturation à la minute.

1. Les ID AMI sont uniques par région. Après avoir chargé l'une de ces éditions, dans le coin supérieur droit, sélectionnez la région cible souhaitée de la console pour afficher les AMI appropriées.
1. Une fois la console chargée, vous pouvez ajouter des critères de recherche supplémentaires pour affiner davantage les résultats. Par exemple, saisissez `13.` pour trouver uniquement les versions 13.x.
1. Pour lancer une machine EC2 avec l'une des AMI répertoriées, cochez la case au début de la ligne correspondante et sélectionnez **Launch** en haut à gauche de la page.
