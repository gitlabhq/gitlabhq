---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: "Lister les règles de branche pour un projet à l'aide de GraphQL"
---

{{< details >}}

- Édition :  Gratuite, GitLab Premium, GitLab Ultimate
- Offre :  GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Vous pouvez interroger les règles de branche dans un projet donné en utilisant :

- GraphiQL.
- [`cURL`](getting_started.md#command-line).
- [Le GitLab Development Kit (GDK)](#use-the-gdk).

## Utiliser GraphiQL {#use-graphiql}

Vous pouvez utiliser GraphiQL pour lister les règles de branche d'un projet.

1. Ouvrez GraphiQL :
   - Pour GitLab.com, utilisez : `https://gitlab.com/-/graphql-explorer`
   - Pour GitLab Self-Managed, utilisez : `https://gitlab.example.com/-/graphql-explorer`
1. Copiez le texte suivant et collez-le dans la fenêtre de gauche. Cette requête recherche un projet par son chemin complet, par exemple `gitlab-org/gitlab-docs`. Elle demande toutes les règles de branche configurées pour le projet.

   ```graphql
   query {
     project(fullPath: "gitlab-org/gitlab-docs") {
       branchRules {
         nodes {
           name
           isDefault
           isProtected
           matchingBranchesCount
           createdAt
           updatedAt
           branchProtection {
             allowForcePush
             codeOwnerApprovalRequired
             mergeAccessLevels {
               nodes {
                 accessLevel
                 accessLevelDescription
                 user {
                   name
                 }
                 group {
                   name
                 }
               }
             }
             pushAccessLevels {
               nodes {
                 accessLevel
                 accessLevelDescription
                 user {
                   name
                 }
                 group {
                   name
                 }
               }
             }
             unprotectAccessLevels {
               nodes {
                 accessLevel
                 accessLevelDescription
                 user {
                   name
                 }
                 group {
                   name
                 }
               }
             }
           }
           externalStatusChecks {
             nodes {
               id
               name
               externalUrl
             }
           }
           approvalRules {
             nodes {
               id
               name
               type
               approvalsRequired
               eligibleApprovers {
                 nodes {
                   name
                 }
               }
             }
           }
         }
       }
     }
   }
   ```

1. Sélectionnez **Play**.

Si aucune règle de branche n'est affichée, cela peut être dû aux raisons suivantes :

- Aucune règle de branche n'est configurée.
- Votre rôle ne dispose pas de l'autorisation d'afficher les règles de branche. Les administrateurs ont accès à toutes les ressources.

## Utiliser le GDK {#use-the-gdk}

Plutôt que de demander un accès, il peut être plus simple pour vous d'exécuter la requête dans le [GitLab Development Kit (GDK)](https://gitlab.com/gitlab-org/gitlab-development-kit).

1. Connectez-vous en tant qu'administrateur par défaut, `root`, avec les identifiants issus de [la documentation GDK](https://gitlab-org.gitlab.io/gitlab-development-kit/gdk_commands/#get-the-login-credentials).
1. Assurez-vous d'avoir des règles de branche configurées pour le projet `flightjs/Flight`.
1. Dans votre instance GDK, ouvrez GraphiQL : `http://gdk.test:3000/-/graphql-explorer`.
1. Copiez la requête et collez-la dans la fenêtre de gauche.
1. Remplacez le chemin complet par le chemin suivant :

   ```graphql
   query {
     project(fullPath: "flightjs/Flight") {
   ```

1. Sélectionnez **Play**.

## Sujets connexes {#related-topics}

- [Référence de l'API GraphQL](reference/_index.md)
