---
stage: Fulfillment
group: Provision
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Activer GitLab Enterprise Edition
description: Activez GitLab Enterprise Edition avec un fichier de licence ou une clé.
---

Si vous recevez un fichier de licence de GitLab (par exemple, pour un essai), vous pouvez le télécharger vers votre instance ou l'ajouter lors de l'installation. Le fichier de licence est un fichier texte ASCII encodé en base64 avec l'extension `.gitlab-license`.

La première fois que vous vous connectez à votre instance GitLab, une note avec un lien vers la page **Ajouter la licence** devrait s'afficher.

Sinon, ajoutez votre licence dans la zone Admin.

## Ajouter une licence dans la zone Admin {#add-license-in-the-admin-area}

1. Connectez-vous à GitLab en tant qu'administrateur.
1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Général**.
1. Dans la zone **Ajouter une licence**, ajoutez une licence en téléchargeant le fichier ou en saisissant la clé.
1. Cochez la case **Conditions d'utilisation**.
1. Sélectionnez **Ajouter la licence**.

## Activer l'abonnement lors de l'installation {#activate-subscription-during-installation}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/114572) dans GitLab 16.0.

{{< /history >}}

Pour activer votre abonnement lors de l'installation, définissez la variable d'environnement `GITLAB_ACTIVATION_CODE` avec le code d'activation :

```shell
export GITLAB_ACTIVATION_CODE=your_activation_code
```

## Ajouter un fichier de licence lors de l'installation {#add-license-file-during-installation}

Si vous disposez d'une licence, vous pouvez également l'importer lors de l'installation de GitLab.

- Pour les installations compilées à partir des sources :
  - Placez le fichier `Gitlab.gitlab-license` dans le répertoire `config/`.
  - Pour spécifier un emplacement et un nom de fichier personnalisés pour la licence, définissez la variable d'environnement `GITLAB_LICENSE_FILE` avec le chemin d'accès au fichier :

    ```shell
    export GITLAB_LICENSE_FILE="/path/to/license/file"
    ```

- Pour les installations avec le package Linux :
  - Placez le fichier `Gitlab.gitlab-license` dans le répertoire `/etc/gitlab/`.
  - Pour spécifier un emplacement et un nom de fichier personnalisés pour la licence, ajoutez cette entrée dans `gitlab.rb` :

    ```ruby
    gitlab_rails['initial_license_file'] = "/path/to/license/file"
    ```

- Pour les installations Helm Charts, utilisez [les clés de configuration `global.gitlab.license`](https://docs.gitlab.com/charts/installation/command-line-options/#basic-configuration).

> [!warning]
> Ces méthodes n'ajoutent une licence qu'au moment de l'installation. Pour renouveler ou mettre à niveau une licence, ajoutez la licence dans la zone **Admin** dans l'interface utilisateur web.

## Soumettre les données d'utilisation de la licence {#submit-license-usage-data}

Si vous utilisez un fichier de licence ou une clé pour activer votre instance dans un environnement hors ligne, nous vous encourageons à soumettre vos données d'utilisation de licence mensuellement afin de simplifier les achats et les renouvellements futurs. Pour soumettre les données, [exportez votre utilisation de licence](license_usage.md#export-license-usage) et envoyez-les par e-mail au service de renouvellement, `renewals-service@customers.gitlab.com`. **Vous ne devez pas ouvrir le fichier d'utilisation de la licence avant de l'envoyer**. Sinon, le contenu du fichier pourrait être manipulé par le programme utilisé (par exemple, les horodatages pourraient être convertis dans un autre format) et provoquer des échecs lors du traitement du fichier.

Si vous ne soumettez pas vos données chaque mois après la date de début de votre abonnement, un e-mail est envoyé à l'adresse associée à votre abonnement et une bannière s'affiche pour vous rappeler de soumettre vos données. La bannière s'affiche dans la zone **Admin** sur les pages **Tableau de bord** et **Abonnement**, et peut être ignorée une fois le fichier d'utilisation téléchargé. Vous ne pouvez l'ignorer que jusqu'au mois suivant après avoir soumis vos données d'utilisation de licence.

## Ce qui se passe lorsque votre licence expire {#what-happens-when-your-license-expires}

Quinze jours avant l'expiration de la licence, une bannière de notification affichant la date d'expiration imminente s'affiche pour les administrateurs GitLab.

Les licences expirent au début de la date d'expiration, à 00:00 heure du serveur.

Lorsque votre licence expire, GitLab verrouille des fonctionnalités, comme les pushs Git et la création de tickets. Votre instance devient en lecture seule et un message d'expiration s'affiche pour tous les administrateurs.

Par exemple, si une licence a une date de début au 1er janvier 2024 et une date de fin au 1er janvier 2025 :

- Elle expire à 23:59:59 heure du serveur le 31 décembre 2024.
- Elle est considérée comme expirée à partir de 00:00:00 heure du serveur le 1er janvier 2025.

Pour supprimer l'état en lecture seule et reprendre les fonctionnalités, [renouvelez votre abonnement](../subscriptions/manage_subscription.md#renew-manually).

Si la licence a expiré depuis plus de 30 jours, vous devez acheter un [nouvel abonnement](../subscriptions/manage_subscription.md) pour reprendre les fonctionnalités.

Pour revenir aux fonctionnalités gratuites, [supprimez toutes les licences expirées](#remove-a-license).

## Supprimer une licence {#remove-a-license}

Pour supprimer une licence d'une instance GitLab auto-gérée :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Abonnement**.
1. Sélectionnez **Supprimer la licence**.

Répétez ces étapes pour supprimer toutes les licences, y compris celles appliquées par le passé.

## Afficher les détails et l'historique de la licence {#view-license-details-and-history}

Pour afficher les détails de votre licence :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Abonnement**.

Vous pouvez ajouter et afficher plusieurs licences, mais seule la dernière licence dans la plage de dates actuelle est la licence active.

Lorsque vous ajoutez une licence datée dans le futur, elle ne prend effet qu'à la date applicable. Vous pouvez consulter tous les abonnements actifs dans le tableau **Historique des abonnements**.

Vous pouvez également [exporter](../subscriptions/manage_subscription.md) vos informations d'utilisation de licence dans un fichier CSV.

## Commandes de licence dans la console Rails {#license-commands-in-the-rails-console}

Les commandes suivantes peuvent être exécutées dans la [console Rails](operations/rails_console.md#starting-a-rails-console-session).

> [!warning]
> Toute commande qui modifie directement des données peut être dommageable si elle n'est pas exécutée correctement ou dans les bonnes conditions. Nous recommandons vivement de les exécuter dans un environnement de test avec une sauvegarde de l'instance prête à être restaurée, au cas où.

### Afficher les informations de licence actuelles {#see-current-license-information}

```ruby
# License information (name, company, email address)
License.current.licensee

# Plan:
License.current.plan

# Uploaded:
License.current.created_at

# Started:
License.current.starts_at

# Expires at:
License.current.expires_at

# Is this a trial license?
License.current.trial?

# License ID for lookup on CustomersDot
License.current.license_id

# License data in Base64-encoded ASCII format
License.current.data

# Confirm the current billable seat count excluding guest users. This is useful for customers who use an Ultimate subscription tier where Guest seats are not counted.
User.active.without_bots.excluding_guests_and_requests.count

```

#### Interaction avec les licences dont la date de début est dans le futur {#interaction-with-licenses-that-start-in-the-future}

```ruby
# Future license data follows the same format as current license data it just uses a different modifier for the License prefix
License.future_dated
```

### Vérifier si une fonctionnalité de projet est disponible sur l'instance {#check-if-a-project-feature-is-available-on-the-instance}

Fonctionnalités répertoriées dans [`features.rb`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/app/models/gitlab_subscriptions/features.rb).

```ruby
License.current.feature_available?(:jira_dev_panel_integration)
```

#### Vérifier si une fonctionnalité de projet est disponible dans un projet {#check-if-a-project-feature-is-available-in-a-project}

Fonctionnalités répertoriées dans [`features.rb`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/app/models/gitlab_subscriptions/features.rb).

```ruby
p = Project.find_by_full_path('<group>/<project>')
p.feature_available?(:jira_dev_panel_integration)
```

### Ajouter une licence via la console {#add-a-license-through-the-console}

#### Utilisation d'une variable `key` {#using-a-key-variable}

```ruby
key = "<key>"
license = License.new(data: key)
license.save
License.current # check to make sure it applied
```

#### Utilisation d'un fichier de licence {#using-a-license-file}

```ruby
license_file = File.open("/tmp/Gitlab.license")

key = license_file.read.gsub("\r\n", "\n").gsub(/\n+$/, '') + "\n"

license = License.new(data: key)
license.save
License.current # check to make sure it applied
```

Ces extraits de code peuvent être enregistrés dans un fichier et exécutés [à l'aide de Rails Runner](operations/rails_console.md#using-the-rails-runner) pour que la licence puisse être appliquée via des scripts d'automatisation shell.

Cela est nécessaire par exemple dans un cas limite connu avec [une licence expirée et plusieurs serveurs LDAP](auth/ldap/ldap-troubleshooting.md#expired-license-causes-errors-with-multiple-ldap-servers).

### Supprimer les licences {#remove-licenses}

Pour nettoyer le [tableau de l'historique des licences](license_file.md#view-license-details-and-history) :

```ruby
TYPE = :trial?
# or :expired?

License.select(&TYPE).each(&:destroy!)

# or even License.all.each(&:destroy!)
```

## Dépannage {#troubleshooting}

### Aucune zone Abonnement dans la zone Admin {#no-subscription-area-in-the-admin-area}

Vous ne pouvez pas ajouter votre licence car il n'y a pas de zone **Abonnement**. Ce problème peut survenir si :

- Vous utilisez GitLab Community Edition. Avant d'ajouter votre licence, vous devez effectuer une mise à niveau vers Enterprise Edition.
- Vous utilisez GitLab.com. Vous ne pouvez pas ajouter une licence GitLab auto-gérée à GitLab.com. Pour utiliser les fonctionnalités payantes sur GitLab.com, [achetez un abonnement séparé](../subscriptions/manage_seats.md#gitlabcom-billing-and-usage).

### Les utilisateurs dépassent la limite de la licence lors du renouvellement {#users-exceed-license-limit-upon-renewal}

GitLab affiche un message vous invitant à acheter des utilisateurs supplémentaires. Ce problème se produit si vous ajoutez une licence qui ne dispose pas d'un nombre d'utilisateurs suffisant pour couvrir le nombre d'utilisateurs de votre instance.

Pour résoudre ce problème, achetez des sièges supplémentaires pour couvrir ces utilisateurs. Pour plus d'informations, consultez la [FAQ sur les licences](https://about.gitlab.com/pricing/licensing-faq/).

Dans GitLab 14.2 et versions ultérieures, pour les instances qui utilisent un fichier de licence, les règles suivantes s'appliquent :

- Si les utilisateurs dépassant la licence sont inférieurs ou égaux à 10 % des utilisateurs dans le fichier de licence, la licence est appliquée et vous payez le dépassement lors du prochain renouvellement.
- Si les utilisateurs dépassant la licence représentent plus de 10 % des utilisateurs dans le fichier de licence, vous ne pouvez pas appliquer la licence sans acheter plus d'utilisateurs.

Par exemple, si vous achetez une licence pour 100 utilisateurs, vous pouvez avoir 110 utilisateurs lorsque vous ajoutez votre licence. Cependant, si vous avez 111 utilisateurs, vous devez acheter plus d'utilisateurs avant de pouvoir ajouter la licence.

### `Start GitLab Ultimate trial` s'affiche toujours après l'ajout de la licence {#start-gitlab-ultimate-trial-still-displays-after-adding-license}

Pour résoudre ce problème, redémarrez [Puma ou l'intégralité de votre instance GitLab](restart_gitlab.md).
