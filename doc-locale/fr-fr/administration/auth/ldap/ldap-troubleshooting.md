---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Dépannage LDAP
---

{{< details >}}

- Niveau : Free, Premium, Ultimate
- Offre : GitLab Self-Managed

{{< /details >}}

Si vous êtes un administrateur, utilisez les informations suivantes pour dépanner LDAP.

## Problèmes courants et workflows {#common-problems--workflows}

### Connexion {#connection}

#### Connexion refusée {#connection-refused}

Si vous obtenez des messages d'erreur `Connection Refused` lors de la tentative de connexion au serveur LDAP, vérifiez les paramètres LDAP `port` et `encryption` utilisés par GitLab. Les combinaisons courantes sont `encryption: 'plain'` et `port: 389`, ou `encryption: 'simple_tls'` et `port: 636`.

#### Délai d'expiration de la connexion {#connection-times-out}

Si GitLab ne peut pas atteindre votre point de terminaison LDAP, vous voyez un message comme celui-ci :

```plaintext
Could not authenticate you from Ldapmain because "Connection timed out - user specified timeout".
```

Si votre fournisseur LDAP configuré et/ou votre point de terminaison est hors ligne ou autrement inaccessible par GitLab, aucun utilisateur LDAP ne peut s'authentifier et se connecter. GitLab ne met pas en cache ni ne stocke les identifiants des utilisateurs LDAP pour fournir une authentification lors d'une panne LDAP.

Contactez votre fournisseur LDAP ou votre administrateur si vous voyez cette erreur.

#### Erreur de référence {#referral-error}

Si vous voyez `LDAP search error: Referral` dans les journaux, ou lors du dépannage de la synchronisation de groupe LDAP, cette erreur peut indiquer un problème de configuration. La configuration LDAP `/etc/gitlab/gitlab.rb` (Omnibus) ou `config/gitlab.yml` (source) est au format YAML et est sensible à l'indentation. Vérifiez que les clés de configuration `group_base` et `admin_group` sont indentées de 2 espaces au-delà de l'identifiant du serveur. L'identifiant par défaut est `main` et un exemple de snippet ressemble à ce qui suit :

```yaml
main: # 'main' is the GitLab 'provider ID' of this LDAP server
  label: 'LDAP'
  host: 'ldap.example.com'
  # ...
  group_base: 'cn=my_group,ou=groups,dc=example,dc=com'
  admin_group: 'my_admin_group'
```

#### Interroger LDAP {#query-ldap}

{{< details >}}

- Niveau : Premium, Ultimate
- Offre : GitLab Self-Managed

{{< /details >}}

Ce qui suit vous permet d'effectuer une recherche dans LDAP en utilisant la console Rails. Selon ce que vous essayez de faire, il peut être plus judicieux d'interroger [un utilisateur](#query-a-user-in-ldap) ou [un groupe](#query-a-group-in-ldap) directement, ou même [utiliser `ldapsearch`](#ldapsearch) à la place.

```ruby
adapter = Gitlab::Auth::Ldap::Adapter.new('ldapmain')
options = {
    # :base is required
    # use .base or .group_base
    base: adapter.config.group_base,

    # :filter is optional
    # 'cn' looks for all "cn"s under :base
    # '*' is the search string - here, it's a wildcard
    filter: Net::LDAP::Filter.eq('cn', '*'),

    # :attributes is optional
    # the attributes we want to get returned
    attributes: %w(dn cn memberuid member submember uniquemember memberof)
}
adapter.ldap_search(options)
```

Lors de l'utilisation d'OID dans le filtre, remplacez `Net::LDAP::Filter.eq` par `Net::LDAP::Filter.construct` :

```ruby
adapter = Gitlab::Auth::Ldap::Adapter.new('ldapmain')
options = {
    # :base is required
    # use .base or .group_base
    base: adapter.config.base,

    # :filter is optional
    # This filter includes OID 1.2.840.113556.1.4.1941
    # It will search for all direct and nested members of the group gitlab_grp in the LDAP directory
    filter: Net::LDAP::Filter.construct("(memberOf:1.2.840.113556.1.4.1941:=CN=gitlab_grp,DC=example,DC=com)"),

    # :attributes is optional
    # the attributes we want to get returned
    attributes: %w(dn cn memberuid member submember uniquemember memberof)
}
adapter.ldap_search(options)
```

Pour des exemples sur la façon dont cela est exécuté, [consultez le module `Adapter`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/lib/ee/gitlab/auth/ldap/adapter.rb).

### Connexions des utilisateurs {#user-sign-ins}

#### Aucun utilisateur n'est trouvé {#no-users-are-found}

Si [vous avez confirmé](#ldap-check) qu'une connexion à LDAP peut être établie mais que GitLab ne vous montre pas les utilisateurs LDAP dans la sortie, l'une des situations suivantes est probablement vraie :

- L'utilisateur `bind_dn` ne dispose pas des autorisations suffisantes pour parcourir l'arborescence des utilisateurs.
- Les utilisateurs ne relèvent pas de la [`base` configurée](_index.md#configure-ldap).
- Le [`user_filter` configuré](_index.md#set-up-ldap-user-filter) bloque l'accès aux utilisateurs.

Dans ce cas, vous pouvez confirmer laquelle des situations précédentes est vraie en utilisant [ldapsearch](#ldapsearch) avec la configuration LDAP existante dans votre `/etc/gitlab/gitlab.rb`.

#### Les utilisateurs ne peuvent pas se connecter {#users-cannot-sign-in}

Un utilisateur peut avoir des difficultés à se connecter pour de nombreuses raisons. Pour commencer, voici quelques questions à vous poser :

- L'utilisateur relève-t-il de la [`base` configurée](_index.md#configure-ldap) dans LDAP ? L'utilisateur doit relever de cette `base` pour se connecter.
- L'utilisateur passe-t-il par le [`user_filter` configuré](_index.md#set-up-ldap-user-filter) ? Si aucun n'est configuré, cette question peut être ignorée. Si c'est le cas, l'utilisateur doit également passer par ce filtre pour être autorisé à se connecter.
  - Référez-vous à notre documentation sur [le débogage du `user_filter`](#debug-ldap-user-filter).

Si les questions précédentes sont toutes deux correctes, le prochain endroit où chercher le problème est dans les journaux eux-mêmes lors de la reproduction du problème.

- Demandez à l'utilisateur de se connecter et laissez-le échouer.
- [Parcourez la sortie](#gitlab-logs) pour trouver des erreurs ou d'autres messages concernant la connexion. Vous pouvez voir l'un des autres messages d'erreur sur cette page, auquel cas cette section peut aider à résoudre le problème.

Si les journaux ne mènent pas à la racine du problème, utilisez la [console Rails](#rails-console) pour [interroger cet utilisateur](#query-a-user-in-ldap) afin de voir si GitLab peut lire cet utilisateur sur le serveur LDAP.

Il peut également être utile de [déboguer une synchronisation d'utilisateurs](#sync-all-users) pour approfondir l'investigation.

#### Les utilisateurs voient une erreur `Invalid login or password.` {#users-see-an-error-invalid-login-or-password}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/438144) dans GitLab 16.10.

{{< /history >}}

Si les utilisateurs voient cette erreur, c'est peut-être parce qu'ils essaient de se connecter en utilisant le formulaire de connexion **Standard** au lieu du formulaire de connexion **LDAP**.

Pour résoudre ce problème, demandez à l'utilisateur de saisir son nom d'utilisateur et son mot de passe LDAP dans le formulaire de connexion **LDAP**.

#### Identifiants invalides lors de la connexion {#invalid-credentials-on-sign-in}

Si les identifiants de connexion utilisés sont corrects sur LDAP, assurez-vous que les conditions suivantes sont vraies pour l'utilisateur en question :

- Assurez-vous que l'utilisateur avec lequel vous vous liez dispose des autorisations suffisantes pour lire l'arborescence de l'utilisateur et la parcourir.
- Vérifiez que le `user_filter` ne bloque pas des utilisateurs autrement valides.
- Exécutez [une commande de vérification LDAP](#ldap-check) pour vous assurer que les paramètres LDAP sont corrects et que [GitLab peut voir vos utilisateurs](#no-users-are-found).

#### Accès refusé pour votre compte LDAP {#access-denied-for-your-ldap-account}

Il existe [un bug](https://gitlab.com/gitlab-org/gitlab/-/issues/235930) qui peut affecter les utilisateurs disposant d'un [accès de niveau Auditeur](../../auditor_users.md). Lors d'une rétrogradation depuis Premium/Ultimate, les utilisateurs Auditeurs qui tentent de se connecter peuvent voir le message suivant : `Access denied for your LDAP account`.

La solution de contournement consiste à modifier le niveau d'accès des utilisateurs affectés.

Prérequis :

- Accès administrateur.

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Vue d'ensemble** > **Utilisateurs**.
1. Sélectionnez le nom de l'utilisateur affecté.
1. Dans le coin supérieur droit, sélectionnez **Éditer**.
1. Modifiez le niveau d'accès de l'utilisateur de `Regular` à `Administrator` (ou vice versa).
1. En bas de la page, sélectionnez **Sauvegarder les modifications**.
1. Dans le coin supérieur droit, sélectionnez à nouveau **Éditer**.
1. Restaurez le niveau d'accès d'origine de l'utilisateur (`Regular` ou `Administrator`) et sélectionnez à nouveau **Sauvegarder les modifications**.

L'utilisateur devrait maintenant pouvoir se connecter.

#### L'adresse e-mail a déjà été prise {#email-has-already-been-taken}

Un utilisateur tente de se connecter avec les identifiants LDAP corrects, se voit refuser l'accès, et le [production.log](../../logs/_index.md#productionlog) affiche une erreur qui ressemble à ceci :

```plaintext
(LDAP) Error saving user <USER DN> (email@example.com): ["Email has already been taken"]
```

Cette erreur fait référence à l'adresse e-mail dans LDAP, `email@example.com`. Les adresses e-mail doivent être uniques dans GitLab et LDAP est lié à l'e-mail principal d'un utilisateur (par opposition à leurs éventuels nombreux e-mails secondaires). Un autre utilisateur (ou même le même utilisateur) a l'e-mail `email@example.com` défini comme e-mail secondaire, ce qui génère cette erreur.

Nous pouvons vérifier d'où provient cette adresse e-mail en conflit en utilisant la [console Rails](#rails-console). Dans la console, exécutez ce qui suit :

```ruby
# This searches for an email among the primary AND secondary emails
user = User.find_by_any_email('email@example.com')
user.username
```

Cela vous indique quel utilisateur possède cette adresse e-mail. L'une des deux étapes suivantes doit être effectuée ici :

- Pour créer un nouvel utilisateur/nom d'utilisateur GitLab pour cet utilisateur lors de la connexion avec LDAP, supprimez l'e-mail secondaire pour éliminer le conflit.
- Pour utiliser un utilisateur/nom d'utilisateur GitLab existant pour cet utilisateur avec LDAP, supprimez cet e-mail en tant qu'e-mail secondaire et faites-en un e-mail principal afin que GitLab associe ce profil à l'identité LDAP.

L'utilisateur peut effectuer l'une ou l'autre de ces étapes [dans son profil](../../../user/profile/_index.md#access-your-user-profile) ou un administrateur peut le faire.

#### Erreurs de limite de projets {#projects-limit-errors}

Les erreurs suivantes indiquent qu'une limite ou une restriction est activée, mais qu'un champ de données associé ne contient aucune donnée :

- `Projects limit can't be blank`.
- `Projects limit is not a number`.

Pour résoudre ce problème :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Général**.
1. Développez les deux éléments suivants :
   - **Limitations du compte**.
   - **Restrictions pour les nouveaux comptes utilisateurs**.
1. Vérifiez, par exemple, les champs **Limite de projets par défaut** ou **Allowed domains for new user accounts** et assurez-vous qu'une valeur pertinente est configurée.

#### Déboguer le filtre utilisateur LDAP {#debug-ldap-user-filter}

[`ldapsearch`](#ldapsearch) vous permet de tester votre [filtre utilisateur](_index.md#set-up-ldap-user-filter) configuré pour confirmer qu'il renvoie les utilisateurs que vous attendez.

```shell
ldapsearch -H ldaps://$host:$port -D "$bind_dn" -y bind_dn_password.txt  -b "$base" "$user_filter" sAMAccountName
```

- Les variables commençant par `$` font référence à une variable de la section LDAP de votre fichier de configuration.
- Remplacez `ldaps://` par `ldap://` si vous utilisez la méthode d'authentification en clair. Le port `389` est le port `ldap://` par défaut et `636` est le port `ldaps://` par défaut.
- Nous supposons que le mot de passe de l'utilisateur `bind_dn` se trouve dans `bind_dn_password.txt`.

#### Synchroniser tous les utilisateurs {#sync-all-users}

{{< details >}}

- Niveau : Premium, Ultimate
- Offre : GitLab Self-Managed

{{< /details >}}

La sortie d'une [synchronisation d'utilisateurs](ldap_synchronization.md#user-sync) manuelle peut vous montrer ce qui se passe lorsque GitLab tente de synchroniser ses utilisateurs avec LDAP. Accédez à la [console Rails](#rails-console) et exécutez :

```ruby
Rails.logger.level = Logger::DEBUG

LdapSyncWorker.new.perform
```

Ensuite, [apprenez à lire la sortie](#example-console-output-after-a-user-sync).

##### Exemple de sortie de console après une synchronisation d'utilisateurs {#example-console-output-after-a-user-sync}

{{< details >}}

- Niveau : Premium, Ultimate
- Offre : GitLab Self-Managed

{{< /details >}}

La sortie d'une [synchronisation manuelle d'utilisateurs](#sync-all-users) est très détaillée, et la synchronisation réussie d'un seul utilisateur peut ressembler à ceci :

```shell
Syncing user John, email@example.com
  Identity Load (0.9ms)  SELECT  "identities".* FROM "identities" WHERE "identities"."user_id" = 20 AND (provider LIKE 'ldap%') LIMIT 1
Instantiating Gitlab::Auth::Ldap::Person with LDIF:
dn: cn=John Smith,ou=people,dc=example,dc=com
cn: John Smith
mail: email@example.com
memberof: cn=admin_staff,ou=people,dc=example,dc=com
uid: John

  UserSyncedAttributesMetadata Load (0.9ms)  SELECT  "user_synced_attributes_metadata".* FROM "user_synced_attributes_metadata" WHERE "user_synced_attributes_metadata"."user_id" = 20 LIMIT 1
   (0.3ms)  BEGIN
  Namespace Load (1.0ms)  SELECT  "namespaces".* FROM "namespaces" WHERE "namespaces"."owner_id" = 20 AND "namespaces"."type" IS NULL LIMIT 1
  Route Load (0.8ms)  SELECT  "routes".* FROM "routes" WHERE "routes"."source_id" = 27 AND "routes"."source_type" = 'Namespace' LIMIT 1
  Ci::Runner Load (1.1ms)  SELECT "ci_runners".* FROM "ci_runners" INNER JOIN "ci_runner_namespaces" ON "ci_runners"."id" = "ci_runner_namespaces"."runner_id" WHERE "ci_runner_namespaces"."namespace_id" = 27
   (0.7ms)  COMMIT
   (0.4ms)  BEGIN
  Route Load (0.8ms)  SELECT "routes".* FROM "routes" WHERE (LOWER("routes"."path") = LOWER('John'))
  Namespace Load (1.0ms)  SELECT  "namespaces".* FROM "namespaces" WHERE "namespaces"."id" = 27 LIMIT 1
  Route Exists (0.9ms)  SELECT  1 AS one FROM "routes" WHERE LOWER("routes"."path") = LOWER('John') AND "routes"."id" != 50 LIMIT 1
  User Update (1.1ms)  UPDATE "users" SET "updated_at" = '2019-10-17 14:40:59.751685', "last_credential_check_at" = '2019-10-17 14:40:59.738714' WHERE "users"."id" = 20
```

Il y a beaucoup d'informations ici, alors passons en revue ce qui pourrait être utile lors du débogage.

Tout d'abord, GitLab recherche tous les utilisateurs qui se sont précédemment connectés avec LDAP et itère sur eux. La synchronisation de chaque utilisateur commence par la ligne suivante qui contient le nom d'utilisateur et l'e-mail de l'utilisateur, tels qu'ils existent dans GitLab maintenant :

```shell
Syncing user John, email@example.com
```

Si vous ne trouvez pas l'e-mail GitLab d'un utilisateur particulier dans la sortie, cet utilisateur ne s'est pas encore connecté avec LDAP.

Ensuite, GitLab recherche dans sa table `identities` le lien existant entre cet utilisateur et les fournisseurs LDAP configurés :

```sql
  Identity Load (0.9ms)  SELECT  "identities".* FROM "identities" WHERE "identities"."user_id" = 20 AND (provider LIKE 'ldap%') LIMIT 1
```

L'objet d'identité possède le DN que GitLab utilise pour rechercher l'utilisateur dans LDAP. Si le DN n'est pas trouvé, l'e-mail est utilisé à la place. Nous pouvons voir que cet utilisateur est trouvé dans LDAP :

```shell
Instantiating Gitlab::Auth::Ldap::Person with LDIF:
dn: cn=John Smith,ou=people,dc=example,dc=com
cn: John Smith
mail: email@example.com
memberof: cn=admin_staff,ou=people,dc=example,dc=com
uid: John
```

Si l'utilisateur n'a pas été trouvé dans LDAP avec le DN ou l'e-mail, vous pourriez voir le message suivant à la place :

```shell
LDAP search error: No Such Object
```

Dans ce cas, l'utilisateur est bloqué :

```shell
  User Update (0.4ms)  UPDATE "users" SET "state" = $1, "updated_at" = $2 WHERE "users"."id" = $3  [["state", "ldap_blocked"], ["updated_at", "2019-10-18 15:46:22.902177"], ["id", 20]]
```

Une fois que l'utilisateur est trouvé dans LDAP, le reste de la sortie met à jour la base de données GitLab avec les éventuelles modifications.

#### Interroger un utilisateur dans LDAP {#query-a-user-in-ldap}

Cela teste que GitLab peut contacter LDAP et lire un utilisateur particulier. Cela peut exposer des erreurs potentielles lors de la connexion à LDAP et/ou de son interrogation, qui peuvent sembler échouer silencieusement dans l'interface utilisateur GitLab.

```ruby
Rails.logger.level = Logger::DEBUG

adapter = Gitlab::Auth::Ldap::Adapter.new('ldapmain') # If `main` is the LDAP provider
Gitlab::Auth::Ldap::Person.find_by_uid('<uid>', adapter)
```

### Règles d'approbation des merge requests {#merge-request-approval-rules}

Lorsque des problèmes de connectivité LDAP surviennent, des utilisateurs peuvent être supprimés des règles d'approbation des merge requests lors des opérations de synchronisation. Cela peut entraîner le fait que les règles d'approbation deviennent vides et soient marquées comme invalides.

#### Les règles d'approbation échouent lorsque la connectivité LDAP est perdue {#approval-rules-fail-when-ldap-connectivity-is-lost}

Si votre serveur LDAP devient temporairement indisponible ou si le compte de liaison échoue :

- Les utilisateurs configurés dans les règles d'approbation basées sur LDAP peuvent être supprimés lors du prochain cycle de synchronisation.
- Les règles d'approbation sans utilisateurs restants deviennent [invalides](../../../user/project/merge_requests/approvals/_index.md#invalid-rules).
- Les règles d'approbation standard sont marquées comme **Approbation automatique** et ne bloquent plus les fusions.
- Les règles de politique d'approbation des merge requests sont marquées comme **Action requise** et continuent de bloquer les fusions.

Pour empêcher les règles d'approbation standard d'être contournées silencieusement :

- Assurez-vous que votre serveur LDAP dispose d'une haute disponibilité et d'une connectivité fiable.
- Surveillez les opérations de synchronisation LDAP pour détecter les échecs.
- Utilisez des [politiques d'approbation des merge requests](../../../user/application_security/policies/merge_request_approval_policies.md) à la place des règles d'approbation standard pour les exigences de sécurité critiques. Les politiques d'approbation offrent une application plus stricte et n'échouent pas en mode ouvert.

Pour plus d'informations sur le comportement des règles d'approbation, voir [Règles invalides](../../../user/project/merge_requests/approvals/_index.md#invalid-rules).

Si des utilisateurs sont supprimés des règles d'approbation en raison de problèmes LDAP, ils ne sont pas automatiquement rajoutés lorsque la connectivité LDAP est restaurée. Vous devrez peut-être restaurer manuellement les règles d'approbation ou récupérer à partir d'une sauvegarde.

### Appartenance aux groupes {#group-memberships}

{{< details >}}

- Niveau : Premium, Ultimate
- Offre : GitLab Self-Managed

{{< /details >}}

#### Appartenances non accordées {#memberships-not-granted}

Parfois, vous pouvez penser qu'un utilisateur particulier devrait être ajouté à un groupe GitLab via la synchronisation de groupe LDAP, mais pour une raison quelconque, cela ne se produit pas. Vous pouvez vérifier plusieurs éléments pour déboguer la situation.

- Assurez-vous que la configuration LDAP a un `group_base` spécifié. [Cette configuration](ldap_synchronization.md#group-sync) est requise pour que la synchronisation de groupe fonctionne correctement.
- Assurez-vous que le [lien de groupe LDAP correct est ajouté au groupe GitLab](ldap_synchronization.md#add-group-links).
- Vérifiez que l'utilisateur dispose d'une identité LDAP :
  1. Connectez-vous à GitLab en tant qu'utilisateur administrateur.
  1. Dans le coin supérieur droit, sélectionnez **Admin**.
  1. Dans la barre latérale gauche, sélectionnez **Vue d'ensemble** > **Utilisateurs**.
  1. Recherchez l'utilisateur.
  1. Ouvrez l'utilisateur en sélectionnant son nom. Ne sélectionnez pas **Éditer**.
  1. Sélectionnez l'onglet **Identités**. Il devrait y avoir une identité LDAP avec un DN LDAP comme `Identifier`. Si ce n'est pas le cas, cet utilisateur ne s'est pas encore connecté avec LDAP et doit le faire en premier.
- Vous avez attendu une heure ou [l'intervalle configuré](ldap_synchronization.md#adjust-ldap-sync-schedule) pour que le groupe se synchronise. Pour accélérer le processus, accédez au groupe GitLab **Gérer** > **Membres** et appuyez sur **Sync now** (synchroniser un groupe) ou [exécutez la tâche Rake de synchronisation de groupe](../../raketasks/ldap.md#run-a-group-sync) (synchroniser tous les groupes).

Si toutes les vérifications semblent correctes, passez à un débogage un peu plus avancé dans la console Rails.

1. Accédez à la [console Rails](#rails-console).
1. Choisissez un groupe GitLab à tester. Ce groupe doit déjà avoir un lien de groupe LDAP configuré.
1. Activez la journalisation de débogage, trouvez le groupe GitLab choisi et [synchronisez-le avec LDAP](#sync-one-group).
1. Parcourez la sortie de la synchronisation. Consultez [l'exemple de sortie de journal](#example-console-output-after-a-group-sync) pour savoir comment lire la sortie.
1. Si vous n'êtes toujours pas en mesure de comprendre pourquoi l'utilisateur n'est pas ajouté, [interrogez directement le groupe LDAP](#query-a-group-in-ldap) pour voir quels membres sont répertoriés.
1. Le DN ou l'UID de l'utilisateur figure-t-il dans l'une des listes du groupe interrogé ? L'un des DN ou UID ici devrait correspondre à l'« Identifier » de l'identité LDAP vérifiée précédemment. Si ce n'est pas le cas, l'utilisateur ne semble pas être dans le groupe LDAP.

#### Impossible d'ajouter un compte de service au groupe lorsque la synchronisation LDAP est activée {#cannot-add-service-account-user-to-group-when-ldap-sync-is-enabled}

Lorsque la synchronisation LDAP est activée pour un groupe, vous ne pouvez pas utiliser la boîte de dialogue « inviter » pour inviter de nouveaux membres du groupe.

Pour résoudre ce problème dans GitLab 16.8 et versions ultérieures, vous pouvez inviter des comptes de service dans un groupe et les en supprimer à l'aide des [points de terminaison de l'API des membres du groupe](../../../api/group_members.md#add-a-group-member).

#### Privilèges d'administrateur non accordés {#administrator-privileges-not-granted}

Lorsque [vous attribuez un rôle d'administrateur à un groupe LDAP](ldap_synchronization.md#assign-an-admin-role-to-an-ldap-group), mais que les utilisateurs configurés ne reçoivent pas les privilèges d'administrateur corrects, confirmez que les conditions suivantes sont vraies :

- Un [`group_base` est également configuré](ldap_synchronization.md#group-sync).
- Le `admin_group` configuré dans le `gitlab.rb` est un CN, et non un DN ou un tableau.
- Ce CN relève de la portée du `group_base` configuré.
- Les membres du `admin_group` se sont déjà connectés à GitLab avec leurs identifiants LDAP. GitLab n'accorde l'accès administrateur qu'aux utilisateurs dont les comptes sont déjà connectés à LDAP.

Si toutes les conditions précédentes sont vraies et que les utilisateurs n'ont toujours pas accès, [exécutez une synchronisation de groupe manuelle](#sync-all-groups) dans la console Rails et [parcourez la sortie](#example-console-output-after-a-group-sync) pour voir ce qui se passe lorsque GitLab synchronise le `admin_group`.

#### Le bouton Sync now est bloqué dans l'interface utilisateur {#sync-now-button-stuck-in-the-ui}

Le bouton **Sync now** sur la page **Groupe** > **Membres** d'un groupe peut se bloquer. Le bouton se bloque après avoir été pressé et la page rechargée. Le bouton ne peut alors plus être sélectionné à nouveau.

Le bouton **Sync now** peut se bloquer pour de nombreuses raisons et nécessite un débogage pour des cas spécifiques. Les éléments suivants sont deux causes possibles et des solutions possibles au problème.

##### Appartenances invalides {#invalid-memberships}

Le bouton **Sync now** se bloque si certains des membres du groupe ou des membres demandeurs sont invalides. Vous pouvez suivre les progrès sur l'amélioration de la visibilité de ce problème dans un [ticket pertinent](https://gitlab.com/gitlab-org/gitlab/-/issues/348226). Vous pouvez utiliser une [console Rails](#rails-console) pour confirmer si ce problème cause le blocage du bouton **Sync now** :

```ruby
# Find the group in question
group = Group.find_by(name: 'my_gitlab_group')

# Look for errors on the Group itself
group.valid?
group.errors.map(&:full_messages)

# Look for errors among the group's members and requesters
group.requesters.map(&:valid?)
group.requesters.map(&:errors).map(&:full_messages)
group.members.map(&:valid?)
group.members.map(&:errors).map(&:full_messages)
```

Une erreur affichée peut identifier le problème et indiquer une solution. Par exemple, l'équipe d'assistance a vu l'erreur suivante :

```ruby
irb(main):018:0> group.members.map(&:errors).map(&:full_messages)
=> [["The member's email address is not allowed for this group. Go to the group's 'Settings > General' page, and check 'Restrict membership by email domain'."]]
```

Cette erreur montrait qu'un administrateur avait choisi de [restreindre l'appartenance au groupe par domaine e-mail](../../../user/group/access_and_permissions.md#restrict-group-access-by-domain), mais il y avait une faute de frappe dans le domaine. Une fois le paramètre de domaine corrigé, le bouton **Sync now** a fonctionné à nouveau.

##### Configuration LDAP manquante sur les nœuds Sidekiq {#missing-ldap-configuration-on-sidekiq-nodes}

Le bouton **Sync now** se bloque lorsque GitLab est déployé sur plusieurs nœuds et que la configuration LDAP est absente de [le `/etc/gitlab/gitlab.rb` sur les nœuds exécutant Sidekiq](../../sidekiq/_index.md#configure-ldap-and-user-or-group-synchronization). Dans ce cas, les jobs Sidekiq semblent disparaître.

LDAP est requis sur les nœuds Sidekiq car LDAP possède plusieurs jobs qui s'exécutent de manière asynchrone et nécessitent une configuration LDAP locale :

- [Synchronisation des utilisateurs](ldap_synchronization.md#user-sync).
- [Synchronisation des groupes](ldap_synchronization.md#group-sync).

Vous pouvez tester si la configuration LDAP manquante est le problème en exécutant [la tâche Rake pour vérifier LDAP](#ldap-check) sur chaque nœud exécutant Sidekiq. Si LDAP est correctement configuré sur ce nœud, il se connecte au serveur LDAP et renvoie des utilisateurs.

Pour résoudre ce problème, [configurez LDAP](../../sidekiq/_index.md#configure-ldap-and-user-or-group-synchronization) sur les nœuds Sidekiq. Une fois configuré, exécutez [la tâche Rake pour vérifier LDAP](#ldap-check) afin de confirmer que le nœud GitLab peut se connecter à LDAP.

#### Synchroniser tous les groupes {#sync-all-groups}

> [!note]
> Pour synchroniser tous les groupes manuellement lorsque le débogage n'est pas nécessaire, [utilisez la tâche Rake](../../raketasks/ldap.md#run-a-group-sync) à la place.

La sortie d'une [synchronisation de groupe](ldap_synchronization.md#group-sync) manuelle peut vous montrer ce qui se passe lorsque GitLab synchronise ses appartenances de groupe LDAP avec LDAP. Accédez à la [console Rails](#rails-console) et exécutez :

```ruby
Rails.logger.level = Logger::DEBUG

LdapAllGroupsSyncWorker.new.perform
```

Ensuite, [apprenez à lire la sortie](#example-console-output-after-a-group-sync).

##### Exemple de sortie de console après une synchronisation de groupe {#example-console-output-after-a-group-sync}

Comme la sortie de la synchronisation des utilisateurs, la sortie de la [synchronisation de groupe manuelle](#sync-all-groups) est également très détaillée. Cependant, elle contient beaucoup d'informations utiles.

Indique le point où la synchronisation commence réellement :

```shell
Started syncing 'ldapmain' provider for 'my_group' group
```

L'entrée suivante affiche un tableau de tous les DN d'utilisateurs que GitLab voit dans le serveur LDAP. Ces DN sont les utilisateurs d'un seul groupe LDAP, pas d'un groupe GitLab. Si vous avez plusieurs groupes LDAP liés à ce groupe GitLab, vous voyez plusieurs entrées de journal comme celle-ci - une pour chaque groupe LDAP. Si vous ne voyez pas le DN d'un utilisateur LDAP dans cette entrée de journal, LDAP ne renvoie pas l'utilisateur lors de la recherche. Vérifiez que l'utilisateur est bien dans le groupe LDAP.

```shell
Members in 'ldap_group_1' LDAP group: ["uid=john0,ou=people,dc=example,dc=com",
"uid=mary0,ou=people,dc=example,dc=com", "uid=john1,ou=people,dc=example,dc=com",
"uid=mary1,ou=people,dc=example,dc=com", "uid=john2,ou=people,dc=example,dc=com",
"uid=mary2,ou=people,dc=example,dc=com", "uid=john3,ou=people,dc=example,dc=com",
"uid=mary3,ou=people,dc=example,dc=com", "uid=john4,ou=people,dc=example,dc=com",
"uid=mary4,ou=people,dc=example,dc=com"]
```

Peu après chacune des entrées, vous voyez un hachage des niveaux d'accès des membres résolus. Ce hachage représente tous les DN d'utilisateurs que GitLab pense devoir avoir accès à ce groupe, et à quel niveau d'accès (rôle). Ce hachage est additif, et d'autres DN peuvent être ajoutés, ou des entrées existantes modifiées, en fonction de recherches supplémentaires de groupes LDAP. La toute dernière occurrence de cette entrée devrait indiquer exactement quels utilisateurs GitLab pense devoir être ajoutés au groupe.

> [!note]
> 10 correspond à `Guest`, 20 à `Reporter`, 25 à `Security Manager`, 30 à `Developer`, 40 à `Maintainer` et 50 à `Owner`.

```shell
Resolved 'my_group' group member access: {"uid=john0,ou=people,dc=example,dc=com"=>30,
"uid=mary0,ou=people,dc=example,dc=com"=>30, "uid=john1,ou=people,dc=example,dc=com"=>30,
"uid=mary1,ou=people,dc=example,dc=com"=>30, "uid=john2,ou=people,dc=example,dc=com"=>30,
"uid=mary2,ou=people,dc=example,dc=com"=>30, "uid=john3,ou=people,dc=example,dc=com"=>30,
"uid=mary3,ou=people,dc=example,dc=com"=>30, "uid=john4,ou=people,dc=example,dc=com"=>30,
"uid=mary4,ou=people,dc=example,dc=com"=>30}
```

Il n'est pas rare de voir des avertissements comme les suivants. Ceux-ci indiquent que GitLab aurait ajouté l'utilisateur à un groupe, mais l'utilisateur n'a pas pu être trouvé dans GitLab. Habituellement, cela n'est pas une cause de préoccupation.

Si vous pensez qu'un utilisateur particulier devrait déjà exister dans GitLab, mais que vous voyez cette entrée, cela pourrait être dû à un DN non concordant stocké dans GitLab. Voir [Le DN et l'e-mail de l'utilisateur ont changé](#user-dn-and-email-have-changed) pour mettre à jour l'identité LDAP de l'utilisateur.

```shell
User with DN `uid=john0,ou=people,dc=example,dc=com` should have access
to 'my_group' group but there is no user in GitLab with that
identity. Membership will be updated when the user signs in for
the first time.
```

Enfin, l'entrée suivante indique que la synchronisation est terminée pour ce groupe :

```shell
Finished syncing all providers for 'my_group' group
```

Lorsque tous les liens de groupe configurés ont été synchronisés, GitLab recherche les administrateurs ou les utilisateurs externes à synchroniser :

```shell
Syncing admin users for 'ldapmain' provider
```

La sortie ressemble à ce qui se passe avec un seul groupe, puis cette ligne indique que la synchronisation est terminée :

```shell
Finished syncing admin users for 'ldapmain' provider
```

Si vous n'avez pas [attribué un rôle d'administrateur](ldap_synchronization.md#assign-an-admin-role-to-an-ldap-group), vous voyez ce message :

```shell
No `admin_group` configured for 'ldapmain' provider. Skipping
```

#### Synchroniser un groupe {#sync-one-group}

[La synchronisation de tous les groupes](#sync-all-groups) peut produire beaucoup de bruit dans la sortie, ce qui peut être perturbant lorsque vous n'êtes intéressé que par le dépannage des appartenances d'un seul groupe GitLab. Dans ce cas, voici comment vous pouvez synchroniser uniquement ce groupe et voir sa sortie de débogage :

```ruby
Rails.logger.level = Logger::DEBUG

# Find the GitLab group.
# If the output is `nil`, the group could not be found.
# If a bunch of group attributes are in the output, your group was found successfully.
group = Group.find_by(name: 'my_gitlab_group')

# Sync this group against LDAP
EE::Gitlab::Auth::Ldap::Sync::Group.execute_all_providers(group)
```

La sortie est similaire à [celle obtenue lors de la synchronisation de tous les groupes](#example-console-output-after-a-group-sync).

#### Interroger un groupe dans LDAP {#query-a-group-in-ldap}

Lorsque vous souhaitez confirmer que GitLab peut lire un groupe LDAP et voir tous ses membres, vous pouvez exécuter ce qui suit :

```ruby
# Find the adapter and the group itself
adapter = Gitlab::Auth::Ldap::Adapter.new('ldapmain') # If `main` is the LDAP provider
ldap_group = EE::Gitlab::Auth::Ldap::Group.find_by_cn('group_cn_here', adapter)

# Find the members of the LDAP group
ldap_group.member_dns
ldap_group.member_uids
```

#### La synchronisation LDAP ne supprime pas le créateur du groupe du groupe {#ldap-synchronization-does-not-remove-group-creator-from-group}

[La synchronisation LDAP](ldap_synchronization.md) devrait supprimer le créateur d'un groupe LDAP de ce groupe, si cet utilisateur n'existe pas dans le groupe. Si l'exécution de la synchronisation LDAP ne fait pas cela :

1. Ajoutez l'utilisateur au groupe LDAP.
1. Attendez que la synchronisation du groupe LDAP soit terminée.
1. Supprimez l'utilisateur du groupe LDAP.

### Le DN et l'e-mail de l'utilisateur ont changé {#user-dn-and-email-have-changed}

Si l'e-mail principal **et** le DN changent tous les deux dans LDAP, GitLab ne peut pas identifier le bon enregistrement LDAP d'un utilisateur. En conséquence, GitLab bloque cet utilisateur. Pour que GitLab puisse trouver l'enregistrement LDAP, mettez à jour le profil GitLab existant de l'utilisateur avec au moins l'un des éléments suivants :

- Le nouvel e-mail principal.
- Les valeurs DN.

Le script suivant met à jour les e-mails de tous les utilisateurs fournis afin qu'ils ne soient pas bloqués ou dans l'impossibilité d'accéder à leurs comptes.

> [!note]
> Le script suivant requiert que tous les nouveaux comptes avec la nouvelle adresse e-mail soient supprimés en premier. Les adresses e-mail doivent être uniques dans GitLab.

Accédez à la [console Rails](#rails-console) et exécutez :

```ruby
# Each entry must include the old username and the new email
emails = {
  'ORIGINAL_USERNAME' => 'NEW_EMAIL_ADDRESS',
  ...
}

emails.each do |username, email|
  user = User.find_by_username(username)
  user.email = email
  user.skip_reconfirmation!
  user.save!
end
```

Vous pouvez ensuite [exécuter une UserSync](#sync-all-users) pour synchroniser le dernier DN pour chacun de ces utilisateurs.

## Impossible de s'authentifier depuis AzureActivedirectoryV2 en raison de `Invalid grant` {#could-not-authenticate-from-azureactivedirectoryv2-because-invalid-grant}

Lors de la conversion de LDAP vers SAML, vous pouvez obtenir une erreur dans Azure qui indique ce qui suit :

```plaintext
Authentication failure! invalid_credentials: OAuth2::Error, invalid_grant.
```

Ce problème survient lorsque les deux conditions suivantes sont vraies :

- Les identités LDAP existent toujours pour les utilisateurs après que SAML a été configuré pour ces utilisateurs.
- Vous désactivez LDAP pour ces utilisateurs.

Vous recevriez à la fois des métadonnées LDAP et Azure dans les journaux, ce qui génère l'erreur dans Azure.

La solution de contournement pour un seul utilisateur consiste à supprimer l'identité LDAP de l'utilisateur dans **Admin** > **Identités**.

Pour supprimer plusieurs identités LDAP, utilisez l'une des solutions de contournement pour l'erreur `Could not authenticate you from Ldapmain because "Unknown provider"` ci-dessous.

## Erreur : `Could not authenticate you from Ldapmain because "Unknown provider"` {#error-could-not-authenticate-you-from-ldapmain-because-unknown-provider}

Vous pouvez recevoir l'erreur suivante lors de l'authentification avec un serveur LDAP :

```plaintext
Could not authenticate you from Ldapmain because "Unknown provider (ldapsecondary). available providers: ["ldapmain"]".
```

Cette erreur est causée par l'utilisation d'un compte qui s'est précédemment authentifié avec un serveur LDAP renommé ou supprimé de votre configuration GitLab. Par exemple :

- Initialement, `main` et `secondary` sont définis dans `ldap_servers` dans la configuration GitLab.
- Le paramètre `secondary` est supprimé ou renommé en `main`.
- Un utilisateur tentant de se connecter a un enregistrement `identify` pour `secondary`, mais celui-ci n'est plus configuré.

Utilisez la [console Rails](../../operations/rails_console.md) pour lister les utilisateurs affectés et vérifier pour quels serveurs LDAP ils ont des identités :

```ruby
ldap_identities = Identity.where(provider: "ldapsecondary")
ldap_identities.each do |identity|
  u=User.find_by_id(identity.user_id)
  ui=Identity.where(user_id: identity.user_id)
  puts "user: #{u.username}\n   #{u.email}\n   last activity: #{u.last_activity_on}\n   #{identity.provider} ID: #{identity.id} external: #{identity.extern_uid}"
  puts "   all identities:"
  ui.each do |alli|
    puts "    - #{alli.provider} ID: #{alli.id} external: #{alli.extern_uid}"
  end
end;nil
```

Vous pouvez résoudre cette erreur de deux manières.

### Renommer les références au serveur LDAP {#rename-references-to-the-ldap-server}

Cette solution est adaptée lorsque les serveurs LDAP sont des répliques les uns des autres, et que les utilisateurs affectés devraient pouvoir se connecter en utilisant un serveur LDAP configuré. Par exemple, si un équilibreur de charge est maintenant utilisé pour gérer la haute disponibilité LDAP et qu'une option de connexion secondaire séparée n'est plus nécessaire.

> [!note]
> Si les serveurs LDAP ne sont pas des répliques les uns des autres, cette solution empêche les utilisateurs affectés de pouvoir se connecter.

Pour [renommer les références au serveur LDAP](../../raketasks/ldap.md#other-options) qui n'est plus configuré, exécutez :

```shell
sudo gitlab-rake gitlab:ldap:rename_provider[ldapsecondary,ldapmain]
```

### Supprimer les enregistrements `identity` liés au serveur LDAP supprimé {#remove-the-identity-records-that-relate-to-the-removed-ldap-server}

Prérequis :

- Assurez-vous que `auto_link_ldap_user` est activé.

Avec cette solution, après la suppression de l'identité, les utilisateurs affectés peuvent se connecter avec les serveurs LDAP configurés et un nouvel enregistrement `identity` est créé par GitLab.

Étant donné que le serveur LDAP supprimé était `ldapsecondary`, dans une [console Rails](../../operations/rails_console.md), supprimez toutes les identités `ldapsecondary` :

```ruby
ldap_identities = Identity.where(provider: "ldapsecondary")
ldap_identities.each do |identity|
  puts "Destroying identity: #{identity.id} #{identity.provider}: #{identity.extern_uid}"
  identity.destroy!
rescue => e
  puts 'Error generated when destroying identity:\n ' + e.to_s
end; nil
```

## Une licence expirée provoque des erreurs avec plusieurs serveurs LDAP {#expired-license-causes-errors-with-multiple-ldap-servers}

L'utilisation de [plusieurs serveurs LDAP](_index.md#use-multiple-ldap-servers) nécessite une licence valide. Une licence expirée peut provoquer :

- Des erreurs `502` dans l'interface web.
- L'erreur suivante dans les journaux (le nom de la stratégie réelle dépend du nom configuré dans `/etc/gitlab/gitlab.rb`) :

  ```plaintext
  Could not find a strategy with name `Ldapsecondary'. Please ensure it is required or explicitly set it using the :strategy_class option. (Devise::OmniAuth::StrategyNotFound)
  ```

Pour résoudre cette erreur, vous devez appliquer une nouvelle licence à l'instance GitLab sans l'interface web :

1. Supprimez ou commentez les lignes de configuration GitLab pour tous les serveurs LDAP non primaires.
1. [Reconfigurez GitLab](../../restart_gitlab.md#reconfigure-a-linux-package-installation) afin qu'il utilise temporairement un seul serveur LDAP.
1. Accédez à la [console Rails et ajoutez la clé de licence](../../license_file.md#add-a-license-through-the-console).
1. Réactivez les serveurs LDAP supplémentaires dans la configuration GitLab et reconfigurez GitLab à nouveau.

## Les utilisateurs sont supprimés du groupe et rajoutés {#users-are-being-removed-from-group-and-re-added-again}

Si un utilisateur a été ajouté à un groupe lors d'une synchronisation de groupe, et supprimé lors de la synchronisation suivante, et que cela s'est produit à plusieurs reprises, assurez-vous que l'utilisateur ne dispose pas de plusieurs identités LDAP redondantes.

Si l'une de ces identités a été ajoutée pour un fournisseur LDAP plus ancien qui n'est plus utilisé, [supprimez les enregistrements `identity` liés au serveur LDAP supprimé](#remove-the-identity-records-that-relate-to-the-removed-ldap-server).

## Outils de débogage {#debugging-tools}

### Vérification LDAP {#ldap-check}

La [tâche Rake pour vérifier LDAP](../../raketasks/ldap.md#check) est un outil précieux pour déterminer si GitLab peut établir avec succès une connexion à LDAP et même lire des utilisateurs.

Si une connexion ne peut pas être établie, c'est probablement en raison d'un problème de configuration ou d'un pare-feu bloquant la connexion.

- Assurez-vous qu'aucun pare-feu ne bloque la connexion et que le serveur LDAP est accessible à l'hôte GitLab.
- Recherchez un message d'erreur dans la sortie de vérification Rake, qui peut vous orienter vers votre configuration LDAP pour confirmer que les valeurs de configuration (spécifiquement `host`, `port`, `bind_dn` et `password`) sont correctes.
- Recherchez des [erreurs](#connection) dans [les journaux](#gitlab-logs) pour déboguer davantage les échecs de connexion.

Si GitLab peut se connecter avec succès à LDAP mais ne renvoie aucun utilisateur, [consultez la marche à suivre lorsqu'aucun utilisateur n'est trouvé](#no-users-are-found).

### Journaux GitLab {#gitlab-logs}

Si un compte utilisateur est bloqué ou débloqué en raison de la configuration LDAP, un message est [consigné dans `application_json.log`](../../logs/_index.md#application_jsonlog).

En cas d'erreur inattendue lors d'une recherche LDAP (erreur de configuration, délai d'expiration), la connexion est rejetée et un message est [consigné dans `production.log`](../../logs/_index.md#productionlog).

### ldapsearch {#ldapsearch}

`ldapsearch` est un utilitaire qui vous permet d'interroger votre serveur LDAP. Vous pouvez l'utiliser pour tester vos paramètres LDAP et vous assurer que les paramètres que vous utilisez vous donnent les résultats attendus.

Lors de l'utilisation de `ldapsearch`, assurez-vous d'utiliser les mêmes paramètres que ceux déjà spécifiés dans votre configuration `gitlab.rb` afin de pouvoir confirmer ce qui se passe lorsque ces paramètres exacts sont utilisés.

L'exécution de cette commande sur l'hôte GitLab aide également à confirmer qu'il n'y a pas d'obstruction entre l'hôte GitLab et LDAP.

Par exemple, considérez la configuration GitLab suivante :

```shell
gitlab_rails['ldap_servers'] = YAML.load <<-'EOS' # remember to close this block with 'EOS' below
   main: # 'main' is the GitLab 'provider ID' of this LDAP server
     label: 'LDAP'
     host: '127.0.0.1'
     port: 389
     uid: 'uid'
     encryption: 'plain'
     bind_dn: 'cn=admin,dc=ldap-testing,dc=example,dc=com'
     password: 'Password1'
     active_directory: true
     allow_username_or_email_login: false
     block_auto_created_users: false
     base: 'dc=ldap-testing,dc=example,dc=com'
     user_filter: ''
     attributes:
       username: ['uid', 'userid', 'sAMAccountName']
       email:    ['mail', 'email', 'userPrincipalName']
       name:       'cn'
       first_name: 'givenName'
       last_name:  'sn'
     group_base: 'ou=groups,dc=ldap-testing,dc=example,dc=com'
     admin_group: 'gitlab_admin'
EOS
```

Vous exécuteriez la commande `ldapsearch` suivante pour trouver l'utilisateur `bind_dn` :

```shell
ldapsearch -D "cn=admin,dc=ldap-testing,dc=example,dc=com" \
  -w Password1 \
  -p 389 \
  -h 127.0.0.1 \
  -b "dc=ldap-testing,dc=example,dc=com"
```

Les `bind_dn`, `password`, `port`, `host` et `base` sont tous identiques à ce qui est configuré dans le `gitlab.rb`.

#### Utiliser ldapsearch avec le chiffrement `start_tls` {#use-ldapsearch-with-start_tls-encryption}

L'exemple précédent effectue un test LDAP en texte clair sur le port 389. Si vous utilisez le [chiffrement `start_tls`](_index.md#basic-configuration-settings), dans la commande `ldapsearch`, incluez :

- L'indicateur `-Z`.
- Le FQDN du serveur LDAP.

Vous devez les inclure car, lors de la négociation TLS, le FQDN du serveur LDAP est évalué par rapport à son certificat :

```shell
ldapsearch -D "cn=admin,dc=ldap-testing,dc=example,dc=com" \
  -w Password1 \
  -p 389 \
  -h "testing.ldap.com" \
  -b "dc=ldap-testing,dc=example,dc=com" -Z
```

#### Utiliser ldapsearch avec le chiffrement `simple_tls` {#use-ldapsearch-with-simple_tls-encryption}

Si vous utilisez le [chiffrement `simple_tls`](_index.md#basic-configuration-settings) (généralement sur le port 636), incluez les éléments suivants dans la commande `ldapsearch` :

- Le FQDN du serveur LDAP avec l'indicateur `-H` et le port.
- L'URI complète construite.

```shell
ldapsearch -D "cn=admin,dc=ldap-testing,dc=example,dc=com" \
  -w Password1 \
  -H "ldaps://testing.ldap.com:636" \
  -b "dc=ldap-testing,dc=example,dc=com"
```

Pour plus d'informations, consultez la [documentation officielle de `ldapsearch`](https://linux.die.net/man/1/ldapsearch).

### Utilisation d'**AdFind** (Windows) {#using-adfind-windows}

Vous pouvez utiliser l'utilitaire [`AdFind`](https://learn.microsoft.com/en-us/archive/technet-wiki/7535.adfind-command-examples) (sur les systèmes Windows) pour tester que votre serveur LDAP est accessible et que l'authentification fonctionne correctement. AdFind est un utilitaire gratuit créé par [Joe Richards](https://www.joeware.net/freetools/tools/adfind/index.htm).

**Return all objects**

Vous pouvez utiliser le filtre `objectclass=*` pour retourner tous les objets du répertoire.

```shell
adfind -h ad.example.org:636 -ssl -u "CN=GitLabSRV,CN=Users,DC=GitLab,DC=org" -up Password1 -b "OU=GitLab INT,DC=GitLab,DC=org" -f (objectClass=*)
```

**Return single object using filter**

Vous pouvez également récupérer un seul objet en **specifying** le nom de l'objet ou le **DN** complet. Dans cet exemple, nous spécifions uniquement le nom de l'objet `CN=Leroy Fox`.

```shell
adfind -h ad.example.org:636 -ssl -u "CN=GitLabSRV,CN=Users,DC=GitLab,DC=org" -up Password1 -b "OU=GitLab INT,DC=GitLab,DC=org" -f "(&(objectcategory=person)(CN=Leroy Fox))"
```

### Console Rails {#rails-console}

> [!warning]
> Il est très facile de créer, lire, modifier et supprimer des données avec la console Rails. Assurez-vous d'exécuter les commandes exactement telles qu'elles sont listées.

La console Rails est un outil précieux pour déboguer les problèmes LDAP. Elle vous permet d'interagir directement avec l'application en exécutant des commandes et en observant les réponses de GitLab.

Pour obtenir des instructions sur l'utilisation de la console Rails, consultez ce [guide](../../operations/rails_console.md#starting-a-rails-console-session).

#### Activer la sortie de débogage {#enable-debug-output}

Cela fournit une sortie de débogage qui montre ce que GitLab fait et avec quoi. Cette valeur n'est pas persistée et n'est activée que pour cette session dans la console Rails.

Pour activer la sortie de débogage dans la console Rails, [accédez à la console Rails](#rails-console) et exécutez :

```ruby
Rails.logger.level = Logger::DEBUG
```

#### Obtenir tous les messages d'erreur associés aux groupes, sous-groupes, membres et demandeurs {#get-all-error-messages-associated-with-groups-subgroups-members-and-requesters}

Collectez les messages d'erreur associés aux groupes, sous-groupes, membres et demandeurs. Cela capture les messages d'erreur qui peuvent ne pas apparaître dans l'interface Web. Cela peut être particulièrement utile pour résoudre les problèmes liés à la [synchronisation de groupe LDAP](ldap_synchronization.md#group-sync) et aux comportements inattendus des utilisateurs et de leur appartenance aux groupes et sous-groupes.

```ruby
# Find the group and subgroup
group = Group.find_by_full_path("parent_group")
subgroup = Group.find_by_full_path("parent_group/child_group")

# Group and subgroup errors
group.valid?
group.errors.map(&:full_messages)

subgroup.valid?
subgroup.errors.map(&:full_messages)

# Group and subgroup errors for the members AND requesters
group.requesters.map(&:valid?)
group.requesters.map(&:errors).map(&:full_messages)
group.members.map(&:valid?)
group.members.map(&:errors).map(&:full_messages)
group.members_and_requesters.map(&:errors).map(&:full_messages)

subgroup.requesters.map(&:valid?)
subgroup.requesters.map(&:errors).map(&:full_messages)
subgroup.members.map(&:valid?)
subgroup.members.map(&:errors).map(&:full_messages)
subgroup.members_and_requesters.map(&:errors).map(&:full_messages)
```
