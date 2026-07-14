---
stage: Software Supply Chain Security
group: Pipeline Security
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Gestion des clés de récupération
---

La clé de récupération est un identifiant d'urgence pour OpenBao. Utilisez-la pour générer un jeton root temporaire lorsque la méthode d'authentification JWT principale devient indisponible.

La clé de récupération n'est pas utilisée dans les opérations standard telles que les extractions de secrets ou l'approvisionnement d'espace de nommage. Traitez-la comme un identifiant à privilèges élevés et stockez-la en toute sécurité.

> [!warning]
> La clé de récupération ne peut pas déchiffrer les données stockées dans la base de données OpenBao. Toutes les données OpenBao sont protégées par le mécanisme de déscellement configuré, soit une clé statique stockée dans le secret Kubernetes `gitlab-openbao-unseal`, soit un KMS externe. Sauvegardez votre mécanisme de déscellement séparément de la clé de récupération.

Pour exécuter les commandes de cette page, vous avez besoin du nom de votre pod toolbox. Pour le trouver, exécutez :

```shell
kubectl get pods -n gitlab -lapp=toolbox
```

Utilisez le nom du pod à la place de `<toolbox-pod-name>` dans les commandes suivantes.

## Stocker la clé de récupération {#store-the-recovery-key}

Exécutez cette commande une fois lors de la configuration initiale, avant qu'un incident ne survienne :

```shell
kubectl exec -n gitlab -it -c toolbox <toolbox-pod-name> -- \
  gitlab-rake "gitlab:secrets_management:openbao:recovery_key:store"
```

La commande génère la clé de récupération dans OpenBao et la stocke chiffrée dans la base de données GitLab.

> [!warning]
> La clé de récupération ne peut être générée qu'une seule fois. Vous ne pouvez pas exécuter `recovery_key:store` une deuxième fois ni après avoir exécuté `recovery_key:fetch`.

Tant que vous n'exécutez pas cette commande, OpenBao enregistre un avertissement à chaque redémarrage du pod : `[WARN]  core: post-unseal upgrade seal keys failed: error="no recovery key found"`. L'avertissement s'arrête après que vous avez stocké la clé.

## Afficher la clé de récupération stockée {#view-the-stored-recovery-key}

Pour extraire et afficher la clé de récupération depuis la base de données GitLab, exécutez :

```shell
kubectl exec -n gitlab -it -c toolbox <toolbox-pod-name> -- \
  gitlab-rake "gitlab:secrets_management:openbao:recovery_key:show"
```

> [!warning]
> La commande demande confirmation avant d'afficher la clé en texte clair. Stockez le résultat en toute sécurité. Ne le consignez pas dans des journaux et ne le partagez pas en dehors d'un canal sécurisé.

## Extraire la clé de récupération sans la stocker {#fetch-the-recovery-key-without-storing-it}

Utilisez `recovery_key:fetch` pour générer et afficher la clé de récupération dans le terminal sans la stocker dans la base de données GitLab. Utilisez cette tâche lorsque vous stockez la clé dans un système externe, par exemple un gestionnaire de mots de passe ou un module de sécurité matériel.

> [!warning]
> La clé de récupération ne peut être générée qu'une seule fois. Vous ne pouvez pas exécuter `recovery_key:fetch` une deuxième fois ni après avoir exécuté `recovery_key:store`.

```shell
kubectl exec -n gitlab -it -c toolbox <toolbox-pod-name> -- \
  gitlab-rake "gitlab:secrets_management:openbao:recovery_key:fetch"
```

La tâche demande confirmation avant de générer et d'afficher la clé. La clé s'affiche en texte clair.

## Générer un jeton root à partir de la clé de récupération {#generate-a-root-token-from-the-recovery-key}

Utilisez la clé de récupération pour générer un jeton root temporaire lorsque vous devez effectuer des opérations OpenBao privilégiées, telles que la reconfiguration de l'authentification JWT ou la migration du scellement. Par exemple, lorsque vous basculez vers un site secondaire Geo avec un domaine différent. Pour plus d'informations, consultez [Configurer l'authentification JWT](../geo/disaster_recovery/_index.md#optional-configure-jwt-authentication).

> [!warning]
> Révoquez le jeton root immédiatement après avoir terminé les opérations requises. Un jeton root dispose d'un accès illimité à toutes les opérations et tous les espaces de nommage OpenBao.

Le binaire `bao` est disponible à l'intérieur du pod OpenBao. Exécutez toutes les commandes avec `kubectl exec`. Aucune redirection de port n'est requise.

1. Récupérez votre clé de récupération :

   ```shell
   kubectl exec -n gitlab -it -c toolbox <toolbox-pod-name> -- \
     gitlab-rake "gitlab:secrets_management:openbao:recovery_key:show"
   ```

   Si vous avez utilisé `recovery_key:fetch` et stocké la clé en externe, récupérez-la depuis cet emplacement à la place.

1. Obtenez le nom du pod OpenBao :

   ```shell
   kubectl get pods -n gitlab -l app.kubernetes.io/name=openbao -o name
   ```

   Remplacez `<openbao-pod-name>` dans les étapes suivantes par le résultat de cette commande. Par exemple, `pod/gitlab-openbao-0`.

1. Générez un OTP :

   ```shell
   kubectl exec -n gitlab <openbao-pod-name> -- \
     sh -c "BAO_ADDR=http://127.0.0.1:8200 bao operator generate-root -generate-otp"
   ```

   Remplacez `<otp>` dans les commandes suivantes par ce résultat.

1. Initialisez la génération du jeton root :

   ```shell
   kubectl exec -n gitlab <openbao-pod-name> -- \
     sh -c "BAO_ADDR=http://127.0.0.1:8200 bao operator generate-root -init -otp=<otp>"
   ```

   Une réponse réussie inclut `Started: true` et une valeur `Nonce`. Remplacez `<nonce>` dans les étapes suivantes par cette valeur `Nonce`.

1. Soumettez la clé de récupération :

   ```shell
   kubectl exec -n gitlab <openbao-pod-name> -- \
     sh -c "echo '<recovery_key>' | BAO_ADDR=http://127.0.0.1:8200 bao operator generate-root -nonce=<nonce>"
   ```

   OpenBao est configuré avec un seul partage de clé de récupération, de sorte que l'opération se termine immédiatement. Une réponse réussie inclut `Complete: true` et une valeur `Encoded Token`. Remplacez `<encoded_token>` à l'étape suivante par cette valeur de jeton.

1. Décodez le jeton root :

   ```shell
   kubectl exec -n gitlab <openbao-pod-name> -- \
     sh -c "BAO_ADDR=http://127.0.0.1:8200 bao operator generate-root -decode=<encoded_token> -otp=<otp>"
   ```

   Remplacez `<root_token>` dans les étapes suivantes par le jeton root décodé.

1. Vérifiez que le jeton root fonctionne :

   ```shell
   kubectl exec -n gitlab <openbao-pod-name> -- \
     sh -c "BAO_ADDR=http://127.0.0.1:8200 BAO_TOKEN=<root_token> bao token lookup"
   ```

   Une réponse réussie inclut `policies  [root]`.

1. Effectuez les opérations privilégiées requises.

1. Révoquez le jeton root :

   ```shell
   kubectl exec -n gitlab <openbao-pod-name> -- \
     sh -c "BAO_ADDR=http://127.0.0.1:8200 BAO_TOKEN=<root_token> bao token revoke -self"
   ```
