---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: "Tâches Rake pour les jetons d'accès"
---

{{< details >}}

- Niveau : Free, Premium, Ultimate
- Offre : GitLab Self-Managed

{{< /details >}}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/467416) dans GitLab 17.2.

{{< /history >}}

## Analyser les dates d'expiration des jetons {#analyze-token-expiration-dates}

Dans GitLab 16.0, une [migration en arrière-plan](https://gitlab.com/gitlab-org/gitlab/-/issues/369123) a attribué à tous les jetons d'accès personnels, de projet et de groupe non expirés une date d'expiration fixée à un an après la création de ces jetons.

Pour identifier les jetons susceptibles d'avoir été affectés par cette migration, vous pouvez exécuter une tâche Rake qui analyse tous les jetons d'accès et affiche les dix dates d'expiration les plus courantes :

   {{< tabs >}}

   {{< tab title="Paquet Linux (Omnibus)" >}}

   ```shell
   gitlab-rake gitlab:tokens:analyze
   ```

   {{< /tab >}}

   {{< tab title="Chart Helm (Kubernetes)" >}}

   ```shell
   # Find the toolbox pod
   kubectl --namespace <namespace> get pods -lapp=toolbox
   kubectl exec -it <toolbox-pod-name> -- sh -c 'cd /srv/gitlab && bin/rake gitlab:tokens:analyze'
   ```

   {{< /tab >}}

   {{< tab title="Docker" >}}

   ```shell
   sudo docker exec -it <container_name> /bin/bash
   gitlab-rake gitlab:tokens:analyze
   ```

   {{< /tab >}}

   {{< tab title="Auto-compilée (source)" >}}

   ```shell
   sudo RAILS_ENV=production -u git -H bundle exec rake gitlab:tokens:analyze
   ```

   {{< /tab >}}

   {{< /tabs >}}

Cette tâche analyse tous les jetons d'accès et les regroupe par date d'expiration. La colonne de gauche affiche la date d'expiration et la colonne de droite indique le nombre de jetons ayant cette date d'expiration. Exemple de sortie :

```plaintext
======= Personal/Project/Group Access Token Expiration Migration =======
Started at: 2023-06-15 10:20:35 +0000
Finished  : 2023-06-15 10:23:01 +0000
===== Top 10 Personal/Project/Group Access Token Expiration Dates =====
| Expiration Date | Count |
|-----------------|-------|
| 2024-06-15      | 1565353 |
| 2017-12-31      | 2508  |
| 2018-01-01      | 1008  |
| 2016-12-31      | 833   |
| 2017-08-31      | 705   |
| 2017-06-30      | 596   |
| 2018-12-31      | 548   |
| 2017-05-31      | 523   |
| 2017-09-30      | 520   |
| 2017-07-31      | 494   |
========================================================================
```

Dans cet exemple, vous pouvez constater que plus de 1,5 million de jetons d'accès ont une date d'expiration au 2024-06-15, soit un an après l'exécution de la migration le 2023-06-15. Cela suggère que la plupart de ces jetons ont été assignés par la migration. Cependant, il n'est pas possible de savoir avec certitude si d'autres jetons ont été créés manuellement avec la même date.

## Mettre à jour les dates d'expiration en masse {#update-expiration-dates-in-bulk}

Prérequis :

Vous devez :

- Être administrateur.
- Disposer d'un terminal interactif.

Exécutez la tâche Rake suivante pour étendre ou supprimer les dates d'expiration des jetons en masse :

1. Exécutez l'outil :

   {{< tabs >}}

   {{< tab title="Paquet Linux (Omnibus)" >}}

   ```shell
   gitlab-rake gitlab:tokens:edit
   ```

   {{< /tab >}}

   {{< tab title="Chart Helm (Kubernetes)" >}}

   ```shell
   # Find the toolbox pod
   kubectl --namespace <namespace> get pods -lapp=toolbox
   kubectl exec -it <toolbox-pod-name> -- sh -c 'cd /srv/gitlab && bin/rake gitlab:tokens:edit'
   ```

   {{< /tab >}}

   {{< tab title="Docker" >}}

   ```shell
   sudo docker exec -it <container_name> /bin/bash
   gitlab-rake gitlab:tokens:edit
   ```

   {{< /tab >}}

   {{< tab title="Auto-compilée (source)" >}}

   ```shell
   sudo RAILS_ENV=production -u git -H bundle exec rake gitlab:tokens:edit
   ```

   {{< /tab >}}

   {{< /tabs >}}

   Une fois l'outil démarré, il affiche le résultat de l'[étape d'analyse](#analyze-token-expiration-dates) ainsi qu'une invite supplémentaire concernant la modification des dates d'expiration :

   ```plaintext
   ======= Personal/Project/Group Access Token Expiration Migration =======
   Started at: 2023-06-15 10:20:35 +0000
   Finished  : 2023-06-15 10:23:01 +0000
   ===== Top 10 Personal/Project/Group Access Token Expiration Dates =====
   | Expiration Date | Count |
   |-----------------|-------|
   | 2024-05-14      | 1565353 |
   | 2017-12-31      | 2508  |
   | 2018-01-01      | 1008  |
   | 2016-12-31      | 833   |
   | 2017-08-31      | 705   |
   | 2017-06-30      | 596   |
   | 2018-12-31      | 548   |
   | 2017-05-31      | 523   |
   | 2017-09-30      | 520   |
   | 2017-07-31      | 494   |
   ========================================================================
   What do you want to do? (Press ↑/↓ arrow or 1-3 number to move and Enter to select)
   ‣ 1. Extend expiration date
     2. Remove expiration date
     3. Quit
   ```

### Étendre les dates d'expiration {#extend-expiration-dates}

Pour étendre les dates d'expiration de tous les jetons correspondant à une date d'expiration donnée :

1. Sélectionnez l'option 1, `Extend expiration date` :

   ```plaintext
   What do you want to do?
   ‣ 1. Extend expiration date
     2. Remove expiration date
     3. Quit
   ```

1. L'outil vous demande de sélectionner l'une des dates d'expiration listées. Par exemple :

   ```plaintext
   Select an expiration date (Press ↑/↓/←/→ arrow to move and Enter to select)
   ‣ 2024-05-14
     2017-12-31
     2018-01-01
     2016-12-31
     2017-08-31
     2017-06-30
   ```

   Utilisez les touches fléchées de votre clavier pour sélectionner une date. Pour abandonner, faites défiler jusqu'en bas et sélectionnez `--> Abort`. Appuyez sur <kbd>Entrée</kbd> pour confirmer votre sélection :

   ```plaintext
   Select an expiration date
     2017-06-30
     2018-12-31
     2017-05-31
     2017-09-30
     2017-07-31
   ‣ --> Abort
   ```

   Si vous sélectionnez une date, l'outil vous invite à saisir une nouvelle date d'expiration :

   ```plaintext
   What would you like the new expiration date to be? (2025-05-14) 2024-05-14
   ```

   La valeur par défaut est un an à partir de la date sélectionnée. Appuyez sur <kbd>Entrée</kbd> pour utiliser la valeur par défaut, ou saisissez manuellement une date au format `YYYY-MM-DD`.

1. Après avoir saisi une date valide, l'outil demande une dernière confirmation :

   ```plaintext
   Old expiration date: 2024-05-14
   New expiration date: 2025-05-14
   WARNING: This will now update 1565353 token(s). Are you sure? (y/N)
   ```

   Si vous saisissez `y`, l'outil étend la date d'expiration de tous les jetons ayant la date d'expiration sélectionnée.

   Si vous saisissez `N`, l'outil abandonne la tâche de mise à jour et retourne à la sortie d'analyse d'origine.

### Supprimer les dates d'expiration {#remove-expiration-dates}

Pour supprimer les dates d'expiration de tous les jetons correspondant à une date d'expiration donnée :

1. Sélectionnez l'option 2, `Remove expiration date` :

   ```plaintext
   What do you want to do?
     1. Extend expiration date
   ‣ 2. Remove expiration date
     3. Quit
   ```

1. L'outil vous demande de sélectionner la date d'expiration dans le tableau. Par exemple :

   ```plaintext
   Select an expiration date (Press ↑/↓/←/→ arrow to move and Enter to select)
   ‣ 2024-05-14
     2017-12-31
     2018-01-01
     2016-12-31
     2017-08-31
     2017-06-30
   ```

   Utilisez les touches fléchées de votre clavier pour sélectionner une date. Pour abandonner, faites défiler jusqu'en bas et sélectionnez `--> Abort`. Appuyez sur <kbd>Entrée</kbd> pour confirmer votre sélection :

   ```plaintext
   Select an expiration date
     2017-06-30
     2018-12-31
     2017-05-31
     2017-09-30
     2017-07-31
   ‣ --> Abort
   ```

1. Après avoir sélectionné une date, l'outil vous invite à confirmer la sélection :

   ```plaintext
   WARNING: This will remove the expiration for tokens that expire on 2024-05-14.
   This will affect 1565353 tokens. Are you sure? (y/N)
   ```

   Si vous saisissez `y`, l'outil supprime la date d'expiration de tous les jetons ayant la date d'expiration sélectionnée.

   Si vous saisissez `N`, l'outil abandonne la tâche de mise à jour et retourne au premier menu.

## Valider la configuration de l'URL d'émetteur personnalisée pour les jetons d'identité CI/CD {#validate-custom-issuer-url-configuration-for-cicd-id-tokens}

Si vous configurez une instance GitLab non publique avec [OpenID Connect dans AWS pour récupérer des informations d'identification temporaires](../../../ci/cloud_services/aws/_index.md#configure-a-non-public-gitlab-instance), utilisez la tâche Rake `ci:validate_id_token_configuration` pour valider la configuration du jeton :

```shell
bundle exec rake ci:validate_id_token_configuration
```
