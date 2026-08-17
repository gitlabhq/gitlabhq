---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Résolution des problèmes liés aux jetons GitLab
---

Lorsque vous utilisez des jetons GitLab, vous pouvez rencontrer les problèmes suivants.

## Jetons d'accès expirés {#expired-access-tokens}

Si un jeton d'accès existant est en cours d'utilisation et atteint la valeur `expires_at`, le jeton expire et :

- Ne peut plus être utilisé pour l'authentification
- N'est pas visible dans l'interface utilisateur

Les requêtes effectuées à l'aide de ce jeton renvoient une réponse `401 Unauthorized`. Un trop grand nombre de requêtes non autorisées en peu de temps depuis la même adresse IP génère des réponses `403 Forbidden` de la part de GitLab.com.

Pour plus d'informations sur les limites des requêtes d'authentification, consultez [Interdiction d'authentification échouée pour Git et le registre de conteneurs](../../user/gitlab_com/_index.md#git-and-container-registry-failed-authentication-ban).

### Identifier les jetons d'accès expirés à partir des journaux {#identify-expired-access-tokens-from-logs}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/464652) dans GitLab 17.2.

{{< /history >}}

Prérequis :

Vous devez :

- Être un administrateur.
- Avoir accès au fichier [`api_json.log`](../../administration/logs/_index.md#api_jsonlog).

Pour identifier les requêtes `401 Unauthorized` qui échouent en raison de jetons d'accès expirés, utilisez les champs suivants dans le fichier `api_json.log` :

| Nom du champ                | Description |
|---------------------------|-------------|
| `meta.auth_fail_reason`   | La raison pour laquelle la requête a été rejetée. Valeurs possibles : `token_expired`, `token_revoked`, `insufficient_scope` et `impersonation_disabled`. |
| `meta.auth_fail_token_id` | Une chaîne décrivant le type et l'ID du jeton utilisé. |

Lorsqu'un utilisateur tente d'utiliser un jeton expiré, `meta.auth_fail_reason` est `token_expired`. Ce qui suit montre un extrait d'une entrée de journal :

```json
{
  "status": 401,
  "method": "GET",
  "path": "/api/v4/user",
  ...
  "meta.auth_fail_reason": "token_expired",
  "meta.auth_fail_token_id": "PersonalAccessToken/12",
}
```

`meta.auth_fail_token_id` indique qu'un jeton d'accès avec l'ID 12 a été utilisé. À partir de GitLab 18.9, `meta.user` sera également renseigné avec tout nom d'utilisateur associé au jeton utilisé pour la requête ayant échoué.

Pour obtenir plus d'informations sur ce jeton, utilisez l'[API des jetons d'accès personnels](../../api/personal_access_tokens.md#retrieve-a-personal-access-token). Vous pouvez également utiliser l'API pour [faire tourner le jeton](../../api/personal_access_tokens.md#rotate-a-personal-access-token).

### Remplacer les jetons d'accès expirés {#replace-expired-access-tokens}

Pour remplacer le jeton :

1. Vérifiez où ce jeton a pu être utilisé précédemment et supprimez-le de toute automatisation qui pourrait encore l'utiliser.
   - Pour les jetons d'accès personnels, utilisez l'[API](../../api/personal_access_tokens.md#list-all-personal-access-tokens) pour lister les jetons qui ont expiré récemment. Par exemple, accédez à `https://gitlab.com/api/v4/personal_access_tokens` et localisez les jetons avec une date `expires_at` spécifique.
   - Pour les jetons d'accès au projet, utilisez l'[API des jetons d'accès au projet](../../api/project_access_tokens.md#list-all-project-access-tokens) pour lister les jetons récemment expirés.
   - Pour les jetons d'accès de groupe, utilisez l'[API des jetons d'accès de groupe](../../api/group_access_tokens.md#list-all-group-access-tokens) pour lister les jetons récemment expirés.
1. Créez un nouveau jeton d'accès :
   - Pour les jetons d'accès personnels, [utilisez l'interface utilisateur](../../user/profile/personal_access_tokens.md#create-a-personal-access-token) ou l'[API des jetons utilisateur](../../api/user_tokens.md#create-a-personal-access-token).
   - Pour un jeton d'accès au projet, [utilisez l'interface utilisateur](../../user/project/settings/project_access_tokens.md#create-a-project-access-token) ou l'[API des jetons d'accès au projet](../../api/project_access_tokens.md#create-a-project-access-token).
   - Pour un jeton d'accès de groupe, [utilisez l'interface utilisateur](../../user/group/settings/group_access_tokens.md#create-a-group-access-token) ou l'[API des jetons d'accès de groupe](../../api/group_access_tokens.md#create-a-group-access-token).
1. Remplacez l'ancien jeton d'accès par le nouveau jeton d'accès. Ce processus varie selon la façon dont vous utilisez le jeton, par exemple s'il est configuré comme un secret ou intégré dans une application. Les requêtes effectuées depuis ce jeton ne devraient plus renvoyer de réponses `401`.

### Prolonger la durée de vie des jetons {#extend-token-lifetime}

Retardez l'expiration de certains jetons à l'aide de ce script.

À partir de GitLab 16.0, tous les jetons d'accès ont une date d'expiration. Après avoir déployé au moins GitLab 16.0, tous les jetons d'accès sans expiration expirent un an après la date de déploiement.

Si cette date approche et que certains jetons n'ont pas encore été renouvelés, vous pouvez utiliser ce script pour retarder l'expiration et donner aux utilisateurs plus de temps pour renouveler leurs jetons.

#### Prolonger la durée de vie de jetons spécifiques {#extend-lifetime-for-specific-tokens}

Ce script prolonge la durée de vie de tous les jetons qui expirent à une date spécifiée, notamment :

- Jetons d'accès personnels
- Jetons d'accès de groupe
- Jetons d'accès au projet

Pour les jetons d'accès de groupe et de projet, ce script prolonge uniquement la durée de vie de ces jetons s'ils ont reçu une date d'expiration automatiquement lors de la mise à niveau vers GitLab 16.0 ou ultérieur. Si un jeton d'accès de groupe ou de projet a été généré avec une date d'expiration ou a été renouvelé, la validité de ce jeton dépend d'une appartenance valide à une ressource, et la durée de vie du jeton ne peut donc pas être prolongée à l'aide de ce script.

Pour utiliser le script :

{{< tabs >}}

{{< tab title="Rails console session" >}}

1. Dans votre fenêtre de terminal, démarrez une session de console Rails avec `sudo gitlab-rails console`.
1. Collez l'intégralité du script `extend_expiring_tokens.rb` de la section suivante. Si vous le souhaitez, modifiez la valeur `expiring_date` pour une date différente.
1. Appuyez sur <kbd>Enter</kbd>.

{{< /tab >}}

{{< tab title="Rails Runner" >}}

1. Dans votre fenêtre de terminal, connectez-vous à votre instance.
1. Copiez l'intégralité du script `extend_expiring_tokens.rb` de la section suivante et enregistrez-le en tant que fichier sur votre instance :
   - Nommez-le `extend_expiring_tokens.rb`.
   - Si vous le souhaitez, modifiez la valeur `expiring_date` pour une date différente.
   - Le fichier doit être accessible à `git:git`.
1. Exécutez cette commande en remplaçant `/path/to/extend_expiring_tokens.rb` par le chemin complet vers votre fichier `extend_expiring_tokens.rb` :

   ```shell
   sudo gitlab-rails runner /path/to/extend_expiring_tokens.rb
   ```

Pour plus d'informations, consultez la [section de résolution des problèmes de Rails Runner](../../administration/operations/rails_console.md#troubleshooting).

{{< /tab >}}

{{< /tabs >}}

##### `extend_expiring_tokens.rb` {#extend_expiring_tokensrb}

```ruby
expiring_date = Date.new(2024, 5, 30)
new_expires_at = 6.months.from_now

total_updated = PersonalAccessToken
                  .not_revoked
                  .without_impersonation
                  .where(expires_at: expiring_date.to_date)
                  .update_all(expires_at: new_expires_at.to_date)

puts "Updated #{total_updated} tokens with new expiry date #{new_expires_at}"
```

## Restaurer un jeton d'accès personnel {#restore-a-personal-access-token}

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Sur les instances GitLab Self-Managed ou GitLab Dedicated, les administrateurs peuvent restaurer les jetons d'accès personnels qui ont été révoqués accidentellement. La restauration n'est pas disponible sur GitLab.com.

> [!warning]
> L'exécution des commandes suivantes modifie les données directement. Cela peut être dommageable si cela n'est pas effectué correctement ou dans les bonnes conditions. Vous devez d'abord exécuter ces commandes dans un environnement de test avec une sauvegarde de l'instance prête à être restaurée, par précaution.

1. Ouvrez une [console Rails](../../administration/operations/rails_console.md#starting-a-rails-console-session).
1. Restaurez le jeton :

   ```ruby
   token = PersonalAccessToken.find_by_token('<token_string>')
   token.update!(revoked:false)
   ```

   Par exemple, pour restaurer un jeton de `token-string-here123` :

   ```ruby
   token = PersonalAccessToken.find_by_token('token-string-here123')
   token.update!(revoked:false)
   ```

## Identifier les jetons d'accès personnels, de projet et de groupe expirant à une certaine date {#identify-personal-project-and-group-access-tokens-expiring-on-a-certain-date}

Les jetons d'accès sans date d'expiration sont valables indéfiniment, ce qui constitue un risque de sécurité si le jeton d'accès est divulgué.

Pour gérer ce risque, lorsque vous effectuez la mise à niveau vers GitLab 16.0 et versions ultérieures, tout jeton d'accès [personnel](../../user/profile/personal_access_tokens.md), de [projet](../../user/project/settings/project_access_tokens.md) ou de [groupe](../../user/group/settings/group_access_tokens.md) qui n'a pas de date d'expiration se voit automatiquement attribuer une date d'expiration fixée à un an à compter de la date de mise à niveau.

Dans GitLab 17.3 et versions ultérieures, ce paramétrage automatique de l'expiration sur les jetons existants a été annulé, et vous pouvez [désactiver l'application des dates d'expiration pour les nouveaux jetons d'accès](../../administration/settings/account_and_limit_settings.md#require-expiration-dates-for-new-access-tokens).

Si vous n'êtes pas informé de la date d'expiration de vos jetons parce que les dates ont changé, vous pourriez rencontrer des échecs d'authentification inattendus lors de vos tentatives de connexion à GitLab à cette date.

Pour gérer ce problème, vous devez effectuer la mise à niveau vers GitLab 17.2 ou une version ultérieure, car ces versions contiennent un [outil qui facilite l'analyse, la prolongation ou la suppression des dates d'expiration des jetons](../../administration/raketasks/tokens/_index.md).

Si vous ne pouvez pas exécuter l'outil, vous pouvez également exécuter des scripts dans les instances GitLab Self-Managed pour identifier les jetons qui :

- Expirent à une date spécifique
- N'ont pas de date d'expiration

Vous exécutez ces scripts depuis votre fenêtre de terminal dans l'un des environnements suivants :

- Une [session de console Rails](../../administration/operations/rails_console.md#starting-a-rails-console-session)
- En utilisant le [Rails Runner](../../administration/operations/rails_console.md#using-the-rails-runner)

Les scripts spécifiques que vous exécutez varient selon que vous avez effectué la mise à niveau vers GitLab 16.0 et versions ultérieures ou non :

- Si vous n'avez pas encore effectué la mise à niveau vers GitLab 16.0 ou une version ultérieure, identifiez les jetons qui n'ont pas de date d'expiration.
- Si vous avez effectué la mise à niveau vers GitLab 16.0 ou une version ultérieure, utilisez des scripts pour identifier l'un des éléments suivants :
  - [Jetons expirant à une date spécifique](#find-all-tokens-expiring-on-a-specific-date)
  - [Jetons expirant dans un mois spécifique](#find-tokens-expiring-in-a-given-month)
  - [Dates auxquelles de nombreux jetons expirent](#identify-dates-when-many-tokens-expire)

Après avoir identifié les jetons affectés par ce problème, vous pouvez exécuter un script final pour prolonger la durée de vie de jetons spécifiques si nécessaire.

Ces scripts renvoient des résultats dans le format suivant :

```plaintext
Expired group access token in Group ID 25, Token ID: 8, Name: Example Token, Scopes: ["read_api", "create_runner"], Last used:
Expired project access token in Project ID 2, Token ID: 9, Name: Test Token, Scopes: ["api", "read_registry", "write_registry"], Last used: 2022-02-11 13:22:14 UTC
```

Pour plus d'informations à ce sujet, consultez l'[incident 18003](https://gitlab.com/gitlab-com/gl-infra/production/-/issues/18003).

### Trouver tous les jetons expirant à une date spécifique {#find-all-tokens-expiring-on-a-specific-date}

Ce script trouve les jetons qui expirent à une date spécifique.

Prérequis :

- Vous devez connaître la date exacte à laquelle votre instance a été mise à niveau vers GitLab 16.0.

Pour l'utiliser :

{{< tabs >}}

{{< tab title="Rails console session" >}}

1. Dans votre fenêtre de terminal, connectez-vous à votre instance.
1. Démarrez une session de console Rails avec `sudo gitlab-rails console`.
1. Selon vos besoins, copiez soit l'intégralité de `expired_tokens.rb` de la section suivante, soit le script `expired_tokens_date_range.rb` de la section d'après, et collez-le dans la console. Modifiez la valeur `expires_at_date` pour la date correspondant à un an après la mise à niveau de votre instance vers GitLab 16.0.
1. Appuyez sur <kbd>Enter</kbd>.

{{< /tab >}}

{{< tab title="Rails Runner" >}}

1. Dans votre fenêtre de terminal, connectez-vous à votre instance.
1. Selon vos besoins, copiez soit l'intégralité de `expired_tokens.rb` de la section suivante, soit le script `expired_tokens_date_range.rb` de la section d'après, et enregistrez-le en tant que fichier sur votre instance :
   - Nommez-le `expired_tokens.rb`.
   - Modifiez la valeur `expires_at_date` pour la date correspondant à un an après la mise à niveau de votre instance vers GitLab 16.0.
   - Le fichier doit être accessible à `git:git`.
1. Exécutez cette commande en remplaçant le chemin par le chemin complet vers votre fichier `expired_tokens.rb` :

   ```shell
   sudo gitlab-rails runner /path/to/expired_tokens.rb
   ```

Pour plus d'informations, consultez la [section de résolution des problèmes de Rails Runner](../../administration/operations/rails_console.md#troubleshooting).

{{< /tab >}}

{{< /tabs >}}

#### `expired_tokens.rb` {#expired_tokensrb}

Ce script nécessite que vous connaissiez la date exacte à laquelle votre instance GitLab a été mise à niveau vers GitLab 16.0.

```ruby
# Change this value to the date one year after your GitLab instance was upgraded.

expires_at_date = "2024-05-22"

# Check for expiring personal access tokens
PersonalAccessToken.for_user_types(:human).where(expires_at: expires_at_date).find_each do |token|
  if token.user.blocked?
    next
    # Hide unusable, blocked PATs from output
  end

  puts "Expired personal access token ID: #{token.id}, User Email: #{token.user.email}, Name: #{token.name}, Scopes: #{token.scopes}, Last used: #{token.last_used_at}"
end

# Check for expiring project and group access tokens
PersonalAccessToken.project_access_token.where(expires_at: expires_at_date).find_each do |token|
  token.user.members.each do |member|
    type = member.is_a?(GroupMember) ? 'Group' : 'Project'

    puts "Expired #{type} access token in #{type} ID #{member.source_id}, Token ID: #{token.id}, Name: #{token.name}, Scopes: #{token.scopes}, Last used: #{token.last_used_at}"
  end
end
```

> [!note]
> Pour masquer et supprimer également les jetons appartenant à des utilisateurs bloqués, ajoutez `token.destroy!` directement en dessous de `if token.user.blocked?`. Cependant, cette action ne laisse pas d'événement d'audit, contrairement à la [méthode API](../../api/personal_access_tokens.md#revoke-a-personal-access-token).

### Trouver les jetons expirant dans un mois donné {#find-tokens-expiring-in-a-given-month}

Ce script trouve les jetons qui expirent dans un mois particulier. Vous n'avez pas besoin de connaître la date exacte à laquelle votre instance a été mise à niveau vers GitLab 16.0. Pour l'utiliser :

{{< tabs >}}

{{< tab title="Rails console session" >}}

1. Dans votre fenêtre de terminal, démarrez une session de console Rails avec `sudo gitlab-rails console`.
1. Collez l'intégralité du script `expired_tokens_date_range.rb` de la section suivante. Si vous le souhaitez, modifiez la valeur `date_range` pour une plage différente.
1. Appuyez sur <kbd>Enter</kbd>.

{{< /tab >}}

{{< tab title="Rails Runner" >}}

1. Dans votre fenêtre de terminal, connectez-vous à votre instance.
1. Copiez l'intégralité du script `expired_tokens_date_range.rb` de la section suivante et enregistrez-le en tant que fichier sur votre instance :
   - Nommez-le `expired_tokens_date_range.rb`.
   - Si vous le souhaitez, modifiez la valeur `date_range` pour une plage différente.
   - Le fichier doit être accessible à `git:git`.
1. Exécutez cette commande en remplaçant `/path/to/expired_tokens_date_range.rb` par le chemin complet vers votre fichier `expired_tokens_date_range.rb` :

   ```shell
   sudo gitlab-rails runner /path/to/expired_tokens_date_range.rb
   ```

Pour plus d'informations, consultez la [section de résolution des problèmes de Rails Runner](../../administration/operations/rails_console.md#troubleshooting).

{{< /tab >}}

{{< /tabs >}}

#### `expired_tokens_date_range.rb` {#expired_tokens_date_rangerb}

```ruby
# This script enables you to search for tokens that expire within a
# certain date range (like 1.month) from the current date. Use it if
# you're unsure when exactly your GitLab 16.0 upgrade completed.

date_range = 1.month

# Check for personal access tokens
PersonalAccessToken.for_user_types(:human).where(expires_at: Date.today .. Date.today + date_range).find_each do |token|
  puts "Expired personal access token ID: #{token.id}, User Email: #{token.user.email}, Name: #{token.name}, Scopes: #{token.scopes}, Last used: #{token.last_used_at}"
end

# Check for expiring project and group access tokens
PersonalAccessToken.project_access_token.where(expires_at: Date.today .. Date.today + date_range).find_each do |token|
  token.user.members.each do |member|
    type = member.is_a?(GroupMember) ? 'Group' : 'Project'

    puts "Expired #{type} access token in #{type} ID #{member.source_id}, Token ID: #{token.id}, Name: #{token.name}, Scopes: #{token.scopes}, Last used: #{token.last_used_at}"
  end
end
```

### Identifier les dates auxquelles de nombreux jetons expirent {#identify-dates-when-many-tokens-expire}

Ce script identifie les dates auxquelles la plupart des jetons expirent. Vous pouvez l'utiliser en combinaison avec d'autres scripts de cette page pour identifier et prolonger de grands lots de jetons qui pourraient approcher de leur date d'expiration, au cas où votre équipe n'aurait pas encore configuré la rotation des jetons.

Le script renvoie des résultats dans ce format :

```plaintext
42 Personal access tokens will expire at 2024-06-27
17 Personal access tokens will expire at 2024-09-23
3 Personal access tokens will expire at 2024-08-13
```

Pour l'utiliser :

{{< tabs >}}

{{< tab title="Rails console session" >}}

1. Dans votre fenêtre de terminal, démarrez une session de console Rails avec `sudo gitlab-rails console`.
1. Collez l'intégralité du script `dates_when_most_of_tokens_expire.rb`.
1. Appuyez sur <kbd>Enter</kbd>.

{{< /tab >}}

{{< tab title="Rails Runner" >}}

1. Dans votre fenêtre de terminal, connectez-vous à votre instance.
1. Copiez l'intégralité du script `dates_when_most_of_tokens_expire.rb` et enregistrez-le en tant que fichier sur votre instance :
   - Nommez-le `dates_when_most_of_tokens_expire.rb`.
   - Le fichier doit être accessible à `git:git`.
1. Exécutez cette commande en remplaçant `/path/to/dates_when_most_of_tokens_expire.rb` par le chemin complet vers votre fichier `dates_when_most_of_tokens_expire.rb` :

   ```shell
   sudo gitlab-rails runner /path/to/dates_when_most_of_tokens_expire.rb
   ```

Pour plus d'informations, consultez la [section de résolution des problèmes de Rails Runner](../../administration/operations/rails_console.md#troubleshooting).

{{< /tab >}}

{{< /tabs >}}

#### `dates_when_most_of_tokens_expire.rb` {#dates_when_most_of_tokens_expirerb}

```ruby
PersonalAccessToken
  .select(:expires_at, Arel.sql('count(*)'))
  .where('expires_at >= NOW()')
  .group(:expires_at)
  .order(Arel.sql('count(*) DESC'))
  .limit(10)
  .each do |token|
    puts "#{token.count} Personal access tokens will expire at #{token.expires_at}"
  end
```

### Trouver les jetons sans date d'expiration {#find-tokens-with-no-expiration-date}

Ce script trouve les jetons qui n'ont pas de date d'expiration : `expires_at` est `NULL`. Pour les utilisateurs qui n'ont pas encore effectué la mise à niveau vers GitLab version 16.0 ou ultérieure, la valeur `expires_at` du jeton est `NULL`, ce qui peut être utilisé pour identifier les jetons auxquels ajouter une date d'expiration.

Vous pouvez utiliser ce script dans la [console Rails](../../administration/operations/rails_console.md) ou dans le [Rails Runner](../../administration/operations/rails_console.md#using-the-rails-runner) :

{{< tabs >}}

{{< tab title="Rails console session" >}}

1. Dans votre fenêtre de terminal, connectez-vous à votre instance.
1. Démarrez une session de console Rails avec `sudo gitlab-rails console`.
1. Collez l'intégralité du script `tokens_with_no_expiry.rb` de la section suivante.
1. Appuyez sur <kbd>Enter</kbd>.

{{< /tab >}}

{{< tab title="Rails Runner" >}}

1. Dans votre fenêtre de terminal, connectez-vous à votre instance.
1. Copiez l'intégralité du script `tokens_with_no_expiry.rb` de la section suivante et enregistrez-le en tant que fichier sur votre instance :
   - Nommez-le `tokens_with_no_expiry.rb`.
   - Le fichier doit être accessible à `git:git`.
1. Exécutez cette commande en remplaçant le chemin par le chemin complet vers votre fichier `tokens_with_no_expiry.rb` :

   ```shell
   sudo gitlab-rails runner /path/to/tokens_with_no_expiry.rb
   ```

Pour plus d'informations, consultez la [section de résolution des problèmes de Rails Runner](../../administration/operations/rails_console.md#troubleshooting).

{{< /tab >}}

{{< /tabs >}}

#### `tokens_with_no_expiry.rb` {#tokens_with_no_expiryrb}

Ce script trouve les jetons sans valeur définie pour `expires_at`.

   ```ruby
   # This script finds tokens which do not have an expires_at value set.

   # Check for expiring personal access tokens
   PersonalAccessToken.for_user_types(:human).where(expires_at: nil).find_each do |token|
     puts "Expires_at is nil for personal access token ID: #{token.id}, User Email: #{token.user.email}, Name: #{token.name}, Scopes: #{token.scopes}, Last used: #{token.last_used_at}"
   end

   # Check for expiring project and group access tokens
   PersonalAccessToken.project_access_token.where(expires_at: nil).find_each do |token|
     token.user.members.each do |member|
       type = member.is_a?(GroupMember) ? 'Group' : 'Project'

       puts "Expires_at is nil for #{type} access token in #{type} ID #{member.source_id}, Token ID: #{token.id}, Name: #{token.name}, Scopes: #{token.scopes}, Last used: #{token.last_used_at}"
     end
   end
   ```
