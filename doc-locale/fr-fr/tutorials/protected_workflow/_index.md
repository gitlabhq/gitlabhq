---
stage: Create
group: Code Review
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 'Tutoriel : Créer un workflow protégé pour votre projet'
description: "Configurez les protections de branches et les workflows d'approbation pour votre projet."
---

<!-- vale gitlab_base.FutureTense = NO -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Lorsque votre équipe démarre un nouveau projet, elle a besoin d'un workflow qui équilibre efficacité et revues appropriées. Dans GitLab, vous pouvez créer des groupes d'utilisateurs, combiner ces groupes avec des protections de branches, puis appliquer ces protections avec des règles d'approbation.

Ce tutoriel configure des protections pour les branches de release `1.x` et `1.x.x` d'un exemple de projet nommé « Excelsior », et crée un workflow d'approbation minimal pour le projet :

1. [Créer le groupe `engineering`](#create-the-engineering-group)
1. [Créer des sous-groupes dans `engineering`](#create-subgroups-in-engineering)
1. [Ajouter des utilisateurs aux sous-groupes](#add-users-to-the-subgroups)
1. [Créer le projet Excelsior](#create-the-excelsior-project)
1. [Ajouter un fichier CODEOWNERS de base](#add-a-basic-codeowners-file)
1. [Configurer les règles d'approbation](#configure-approval-rules)
1. [Appliquer l'approbation des propriétaires de code sur les branches](#enforce-codeowner-approval-on-branches)
1. [Créer les branches de release](#create-the-release-branches)

## Avant de commencer {#before-you-begin}

- Vous devez disposer du rôle Chargé de maintenance ou Propriétaire.
- Vous avez besoin d'une liste de responsables et de leurs adresses e-mail.
- Vous avez besoin d'une liste de vos ingénieurs backend et frontend, ainsi que de leurs adresses e-mail.
- Vous maîtrisez la [gestion sémantique de version](https://semver.org/) pour les noms de branches.

## Créer le groupe `engineering` {#create-the-engineering-group}

Avant de configurer le projet Excelsior, vous devez créer un groupe pour posséder le projet. Ici, vous allez configurer le groupe Engineering :

1. Dans le coin supérieur droit, sélectionnez **Créer un nouveau** ({{< icon name="plus" >}}) et **Nouveau groupe**.
1. Sélectionnez **Créer un groupe**.
1. Pour le **Nom du groupe**, saisissez `Engineering`.
1. Pour l'**URL du groupe**, saisissez `engineering`.
1. Définissez le **Niveau de visibilité** sur **Privé**.
1. Personnalisez votre expérience afin que GitLab vous affiche les informations les plus utiles :
   - Pour le **Rôle**, sélectionnez **Administrateur système**.
   - Pour **Qui utilisera ce groupe ?**, sélectionnez **Mon entreprise ou mon équipe**.
   - Pour **À quoi vous servira ce groupe ?**, sélectionnez **Je souhaite stocker mon code**.
1. Ignorez l'invitation de membres au groupe. Vous ajouterez des utilisateurs dans une section ultérieure de ce tutoriel.
1. Sélectionnez **Créer un groupe**.

Ensuite, vous allez ajouter des sous-groupes à ce groupe `engineering` pour un contrôle plus granulaire.

## Créer des sous-groupes dans `engineering` {#create-subgroups-in-engineering}

Le groupe `engineering` est un bon début, mais les ingénieurs backend, les ingénieurs frontend et les responsables du projet Excelsior ont des tâches différentes et des domaines de spécialité différents.

Ici, vous allez créer trois sous-groupes plus granulaires dans le groupe Engineering pour segmenter les utilisateurs par type de travail : `managers`, `frontend` et `backend`. Vous ajouterez ensuite ces nouveaux groupes comme membres du groupe `engineering`.

Commencez par créer le nouveau sous-groupe :

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et recherchez `engineering`.
1. Sélectionnez le groupe nommé `Engineering` :

   ![Le groupe engineering dans les résultats de recherche](img/search_engineering_v16_2.png)
1. Sur la page de présentation du groupe `engineering`, dans le coin supérieur droit, sélectionnez **Créer un sous-groupe**.
1. Pour le **Nom du sous-groupe**, saisissez `Managers`.
1. Définissez le **Niveau de visibilité** sur **Privé**.
1. Sélectionnez **Créer un sous-groupe**.

Ajoutez ensuite le sous-groupe comme membre du groupe `engineering` :

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et recherchez `engineering`.
1. Sélectionnez le groupe nommé `Engineering`.
1. Sélectionnez **Gérer** > **Membres**.
1. En haut à droite, sélectionnez **Inviter un groupe**.
1. Pour **Sélectionnez un groupe à inviter**, sélectionnez `Engineering / Managers`.
1. Lors de l'ajout des sous-groupes, sélectionnez le rôle **Chargé de maintenance**. Cela configure le rôle le plus élevé qu'un membre du sous-groupe peut hériter lors de l'accès au groupe `engineering` et à ses projets.
1. facultatif. Sélectionnez une date d'expiration.
1. Sélectionnez **Inviter**.

Répétez ce processus pour créer des sous-groupes pour `backend` et `frontend`. Lorsque vous avez terminé, recherchez à nouveau le groupe `engineering`. Sa page de présentation doit afficher trois sous-groupes, comme ceci :

![Le groupe engineering comporte trois sous-groupes](img/subgroup_structure_v16_1.png)

## Ajouter des utilisateurs aux sous-groupes {#add-users-to-the-subgroups}

À l'étape précédente, lorsque vous avez ajouté vos sous-groupes au groupe parent (`engineering`), vous avez limité les membres des sous-groupes au rôle de Chargé de maintenance. Il s'agit du rôle le plus élevé qu'ils peuvent hériter pour les projets appartenant à `engineering`. Par conséquent :

- L'utilisateur 1 est ajouté au sous-groupe `manager` avec le rôle Invité, et reçoit le rôle Invité sur les projets `engineering`.
- L'utilisateur 2 est ajouté au groupe `manager` avec le rôle Propriétaire. Ce rôle est supérieur au rôle maximum (Chargé de maintenance) que vous avez défini. L'utilisateur 2 reçoit donc le rôle Chargé de maintenance au lieu de Propriétaire.

Pour ajouter un utilisateur au sous-groupe `frontend` :

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et recherchez `frontend`.
1. Sélectionnez le groupe `Frontend`.
1. Sélectionnez **Gérer** > **Membres**.
1. Sélectionnez **Inviter des membres**.
1. Remplissez les champs. Sélectionnez le rôle **Développeur** par défaut, en l'augmentant à **Chargé de maintenance** si cet utilisateur passe en revue le travail des autres.
1. Sélectionnez **Inviter**.
1. Répétez ces étapes jusqu'à avoir ajouté tous les ingénieurs frontend dans le sous-groupe `frontend`.

Faites de même avec les groupes `backend` et `managers`. Le même utilisateur peut être membre de plusieurs sous-groupes.

## Créer le projet Excelsior {#create-the-excelsior-project}

Maintenant que votre structure de groupes est en place, créez le projet `excelsior` dans lequel les équipes pourront travailler. Comme les ingénieurs frontend et backend sont tous deux impliqués, `excelsior` doit appartenir à `engineering` plutôt qu'à l'un des sous-groupes plus petits que vous venez de créer.

Pour créer le nouveau projet `excelsior` :

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et recherchez `engineering`.
1. Sélectionnez le groupe nommé `Engineering`.
1. Sur la page de présentation du groupe `engineering`, dans le coin supérieur droit, sélectionnez **Créer un nouveau** ({{< icon name="plus" >}}) et **Dans ce groupe** > **Nouveau projet/dépôt**.
1. Sélectionnez **Créer un projet vide**.
1. Saisissez les détails du projet :
   - Dans le champ **Nom du projet**, saisissez `Excelsior`. L'**Identifiant « slug » du projet** devrait se remplir automatiquement avec `excelsior`.
   - Pour le **Niveau de visibilité**, sélectionnez **Public**.
   - Sélectionnez **Initialiser le dépôt avec un README** pour ajouter un fichier initial au dépôt.
1. Sélectionnez **Créer le projet**.

GitLab crée le projet `excelsior` pour vous et vous redirige vers sa page d'accueil. Il devrait ressembler à ceci :

![Votre nouveau projet excelsior, presque vide](img/new_project_v16_2.png)

Vous utiliserez une fonctionnalité de cette page à l'étape suivante.

## Ajouter un fichier CODEOWNERS de base {#add-a-basic-codeowners-file}

Ajoutez un fichier CODEOWNERS au répertoire racine de votre projet pour diriger les revues vers le bon sous-groupe. Cet exemple configure quatre règles :

- Toutes les modifications doivent être revues par quelqu'un dans le groupe `engineering`.
- Un responsable doit passer en revue toute modification apportée au fichier CODEOWNERS lui-même.
- Les ingénieurs frontend doivent passer en revue les modifications apportées aux fichiers frontend.
- Les ingénieurs backend doivent passer en revue les modifications apportées aux fichiers backend.

> [!note]
> GitLab Free ne prend en charge que les revues facultatives. Pour rendre les revues obligatoires, vous avez besoin de GitLab Premium ou Ultimate.

Pour ajouter un fichier CODEOWNERS à votre projet `excelsior` :

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et recherchez `Excelsior`.
1. Sélectionnez le projet nommé `Excelsior`.
1. À côté du nom de la branche, sélectionnez l'icône plus ({{< icon name="plus" >}}), puis **Nouveau fichier** : ![Créer un nouveau fichier dans le projet](img/new_file_v16_2.png)
1. Pour le **Nom du fichier**, saisissez `CODEOWNERS`. Cela créera un fichier nommé `CODEOWNERS` dans le répertoire racine de votre projet.
1. Collez cet exemple dans la zone d'édition en modifiant `@engineering/` si cela ne correspond pas à votre structure de groupe :

   ```plaintext
   # All changes should be reviewed by someone in the engineering group
   * @engineering

   # A manager should review any changes to this file
   CODEOWNERS @engineering/managers

   # Frontend files should be reviewed by FE engineers
   [Frontend] @engineering/frontend
   *.scss
   *.js

   # Backend files should be reviewed by BE engineers
   [Backend] @engineering/backend
   *.rb
   ```

1. Pour le **Message de commit**, collez :

   ```plaintext
   Adds a new CODEOWNERS file

   Creates a small CODEOWNERS file to:
   - Route backend and frontend changes to the right teams
   - Route CODEOWNERS file changes to managers
   - Request all changes be reviewed
   ```

1. Sélectionnez **Valider les modifications**.

Le fichier CODEOWNERS est maintenant en place dans la branche `main` de votre projet et disponible pour toutes les futures branches créées dans ce projet.

## Configurer les règles d'approbation {#configure-approval-rules}

Le fichier CODEOWNERS décrit les relecteurs appropriés pour les répertoires et les types de fichiers. Les règles d'approbation dirigent les merge requests vers ces relecteurs. Ici, vous allez configurer une règle d'approbation qui utilise les informations de votre nouveau fichier CODEOWNERS et ajoute une protection pour les branches de release :

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et recherchez `Excelsior`.
1. Sélectionnez le projet nommé `Excelsior`.
1. Sélectionnez **Paramètres** > **Merge requests**.
1. Dans la section **Approbations des requêtes de fusion**, faites défiler jusqu'à **Règles d'approbation**.
1. Sélectionnez **Ajouter une règle d'approbation**.
1. Créez une règle nommée `Enforce CODEOWNERS`.
1. Sélectionnez **Toutes les branches protégées**.
1. Pour rendre la règle obligatoire dans GitLab Premium et GitLab Ultimate, définissez l'**Approbation requise** sur `1`.
1. Ajoutez le groupe `managers` comme approbateurs.
1. Sélectionnez **Ajouter une règle d'approbation**.
1. Faites défiler jusqu'à **Paramètres d'approbation** et assurez-vous que **Empêcher la modification des règles d'approbation dans les requêtes de fusion** est sélectionné.
1. Sélectionnez **Sauvegarder les modifications**.

Une fois ajoutée, la règle `Enforce CODEOWNERS` ressemble à ceci :

![Nouvelle règle d'approbation en place](img/approval_rules_v16_2.png)

## Appliquer l'approbation des propriétaires de code sur les branches {#enforce-codeowner-approval-on-branches}

Vous avez configuré plusieurs protections pour votre projet et vous êtes maintenant prêt à combiner ces protections pour sécuriser les branches importantes de votre projet :

- Vos utilisateurs sont répartis dans des groupes et sous-groupes logiques.
- Votre fichier CODEOWNERS décrit les experts du domaine pour les types de fichiers et les répertoires.
- Votre règle d'approbation encourage (dans GitLab Free) ou impose (dans GitLab Premium et GitLab Ultimate) aux experts du domaine de passer en revue les modifications.

Votre projet `excelsior` utilise la [gestion sémantique de version](https://semver.org/) pour les noms de branches de release, vous savez donc que les branches de release suivent le modèle `1.x` et `1.x.x`. Vous souhaitez que tout le code ajouté à ces branches soit revu par des experts du domaine, et que les responsables prennent la décision finale sur le travail fusionné dans la branche de release.

Plutôt que de créer des protections pour une branche à la fois, configurez des règles de branches génériques pour protéger plusieurs branches :

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et recherchez `Excelsior`.
1. Sélectionnez le projet nommé `Excelsior`.
1. Sélectionnez **Paramètres** > **Dépôt**.
1. Développez **Règles des branches**.
1. Sélectionnez **Ajouter une règle de branche** > **Schéma ou nom de la branche**.
1. Dans la liste déroulante, saisissez `1.*`, puis sélectionnez **Create wildcard `1.*`**.
1. Pour obliger tout le monde à soumettre des merge requests plutôt que de pousser des commits directement :
   1. Dans la section **Autorisés à fusionner**, sélectionnez **Éditer**, définissez sur **Chargés de maintenance** et sélectionnez **Sauvegarder les modifications**.
   1. Dans la section **Autorisés à pousser et fusionner**, sélectionnez **Éditer**, définissez sur **Personne** et sélectionnez **Sauvegarder les modifications**.
   1. Laissez **Autorisé à forcer les poussées** désactivé.
1. Dans GitLab Premium et GitLab Ultimate, pour exiger que les propriétaires du code passent en revue les modifications apportées aux fichiers sur lesquels ils travaillent, activez **Exiger l'approbation des propriétaires du code**.
1. Dans le tableau des branches, trouvez la règle marquée comme `Default`. (Selon votre version de GitLab, cette branche peut être nommée `main` ou `master`.) Définissez les valeurs de cette branche pour qu'elles correspondent aux paramètres que vous avez utilisés pour la règle `1.*`.

Vos règles sont maintenant en place, même si aucune branche `1.*` n'existe encore :

![main et 1.x sont maintenant protégées](img/branch_list_v16_1.png)

## Créer les branches de release {#create-the-release-branches}

Maintenant que toutes les protections de branches sont en place, vous êtes prêt à créer votre branche de release 1.0.0 :

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et recherchez `Excelsior`.
1. Sélectionnez le projet nommé `Excelsior`.
1. Dans la barre latérale gauche, sélectionnez **Code** > **Branches**.
1. Dans le coin supérieur droit, sélectionnez **Nouvelle branche**. Nommez-la `1.0.0`.
1. Sélectionnez **Créer une branche**.

Les protections de branches sont maintenant visibles dans l'interface utilisateur :

- Dans la barre latérale gauche, sélectionnez **Code** > **Branches**. Dans la liste des branches, la branche `1.0.0` doit indiquer qu'elle est protégée :

  ![Liste des branches indiquant que 1.0.0 est protégée](img/branch_is_protected_v16_2.png)
- Dans la barre latérale gauche, sélectionnez **Paramètres** > **Dépôt**, puis développez **Règles des branches** pour afficher les détails de toutes les branches protégées :

  ![Liste des branches protégées et leurs protections](img/protections_in_place_v16_2.png)

Félicitations ! Vos ingénieurs peuvent travailler de façon indépendante dans leurs branches, et tout le code soumis pour la branche de release 1.0.0 sera revu par des experts du domaine.
