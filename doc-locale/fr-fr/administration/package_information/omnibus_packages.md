---
stage: GitLab Delivery
group: Build
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Packages et images du package Linux
---

{{< details >}}

- Niveau : Free, Premium, Ultimate
- Offre : GitLab Self-Managed

{{< /details >}}

Vous trouverez ci-dessous des informations de base sur les raisons pour lesquelles GitLab fournit des packages et une image Docker avec des dépendances intégrées.

Ces méthodes sont idéales pour les installations sur machines physiques et virtuelles, ainsi que pour les installations Docker simples.

## Objectifs {#goals}

Nous avons quelques objectifs essentiels avec ces packages :

1. Extrêmement facile à installer, mettre à niveau et maintenir.
1. Prise en charge d'une grande variété de systèmes d'exploitation
1. Large prise en charge des fournisseurs de services cloud

## Architecture du package Linux {#linux-package-architecture}

GitLab est à la base un projet Ruby on Rails. Cependant, GitLab en tant qu'application complète est plus complexe et comporte plusieurs composants. Si ces composants sont absents ou mal configurés, GitLab ne fonctionne pas ou fonctionne de manière imprévisible.

La présentation de l'architecture GitLab dans la documentation de développement GitLab présente certains de ces composants et leurs interactions. Chacun de ces composants doit être configuré et maintenu à jour.

La plupart des composants ont également des dépendances externes. Par exemple, l'application Rails dépend d'un certain nombre de [gems Ruby](https://gitlab.com/gitlab-org/gitlab-foss/blob/master/Gemfile.lock). Certaines de ces dépendances ont également leurs propres dépendances externes qui doivent être présentes sur le système d'exploitation pour qu'elles fonctionnent correctement.

De plus, GitLab a un cycle de release mensuel qui nécessite une maintenance fréquente pour rester à jour.

Tous les éléments énumérés précédemment représentent un défi pour l'utilisateur qui maintient l'installation GitLab.

## Dépendances logicielles externes {#external-software-dependencies}

Pour des applications telles que GitLab, les dépendances externes entraînent généralement les défis suivants :

- Maintien de la synchronisation des versions entre les dépendances directes et indirectes
- Disponibilité d'une version sur un système d'exploitation spécifique
- Les changements de version peuvent introduire ou supprimer une configuration précédemment utilisée
- Implications en matière de sécurité lorsqu'une bibliothèque est marquée comme vulnérable mais qu'une nouvelle version n'a pas encore été publiée

Gardez à l'esprit que si une dépendance existe sur votre système d'exploitation, elle n'existe pas nécessairement sur les autres systèmes d'exploitation pris en charge.

## Avantages {#benefits}

Quelques avantages d'un package avec des dépendances intégrées :

1. Effort minimal requis pour installer GitLab.
1. Configuration minimale requise pour mettre GitLab en marche.
1. Effort minimal requis pour mettre à niveau entre les versions de GitLab.
1. Plusieurs plateformes prises en charge.
1. La maintenance sur les plateformes plus anciennes est grandement simplifiée.
1. Moins d'effort pour prendre en charge les problèmes potentiels.

## Inconvénients {#drawbacks}

Quelques inconvénients d'un package avec des dépendances intégrées :

1. Duplication avec des logiciels éventuellement existants.
1. Moins de flexibilité dans la configuration.

## Pourquoi installer un package à partir du package Linux quand vous pouvez utiliser un package système ? {#why-would-you-install-a-package-from-the-linux-package-when-you-can-use-a-system-package}

La réponse peut être simplifiée ainsi : moins de maintenance requise. Au lieu de gérer plusieurs packages qui peuvent casser des fonctionnalités existantes si les versions ne sont pas compatibles, n'en gérez qu'un seul.

Plusieurs packages nécessitent une configuration correcte à plusieurs endroits. Maintenir la configuration synchronisée peut être source d'erreurs.

Si vous avez les compétences nécessaires pour maintenir toutes les dépendances actuelles et suffisamment de temps pour gérer les futures dépendances qui pourraient être introduites, les raisons précédentes pourraient ne pas être suffisantes pour vous dissuader de ne pas utiliser un package du package Linux.

Deux éléments sont à garder à l'esprit avant de s'engager dans cette voie :

1. Obtenir du support pour les problèmes que vous rencontrez peut s'avérer plus difficile en raison du nombre de possibilités qui existent lors de l'utilisation d'une version de bibliothèque non testée par la majorité des utilisateurs.
1. Les packages du package Linux permettent également d'arrêter tous les services dont vous n'avez pas besoin, si vous devez exécuter un composant de manière indépendante. Par exemple, vous pouvez utiliser une [base de données PostgreSQL non intégrée](https://docs.gitlab.com/omnibus/settings/database/#using-a-non-packaged-postgresql-database-management-server) avec une installation du package Linux.

Gardez à l'esprit qu'une solution non standard comme le package Linux peut être mieux adaptée lorsque l'application comporte de nombreux éléments en mouvement.

## Image Docker avec plusieurs services {#docker-image-with-multiple-services}

L'[image Docker GitLab](../../install/docker/_index.md) est basée sur le package Linux.

Étant donné que le conteneur généré à partir de cette image contient plusieurs processus, ces types de conteneurs sont également appelés « fat containers ».

Il existe des arguments pour et contre une image de ce type, mais ils sont similaires à ce qui a été mentionné précédemment :

1. Très simple à démarrer.
1. La mise à niveau vers la dernière version est extrêmement simple.
1. L'exécution de services distincts dans plusieurs conteneurs et leur maintien en fonctionnement peut être plus complexe et peut ne pas être requise pour une installation donnée.

Cette méthode est utile pour les organisations qui débutent avec les conteneurs et les ordonnanceurs, et qui ne sont peut-être pas prêtes pour une installation plus complexe. Cette méthode est une excellente introduction et fonctionne bien pour les organisations de petite taille.
