---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Console Rails
description: Interagissez avec votre instance GitLab depuis la ligne de commande.
---

{{< details >}}

- Niveau : Free, Premium, Ultimate
- Offre : GitLab Self-Managed

{{< /details >}}

Au cœur de GitLab se trouve une application web [construite à l'aide du framework Ruby on Rails](https://about.gitlab.com/blog/why-we-use-rails-to-build-gitlab/). La [console Rails](https://guides.rubyonrails.org/command_line.html#rails-console) offre un moyen d'interagir avec votre instance GitLab depuis la ligne de commande, et donne également accès aux outils exceptionnels intégrés à Rails.

> [!warning]
> La console Rails interagit directement avec GitLab. Dans de nombreux cas, il n'existe aucune protection pour vous empêcher de modifier, de corrompre ou de détruire définitivement des données de production. Si vous souhaitez explorer la console Rails sans conséquences, il vous est fortement conseillé de le faire dans un environnement de test.

La console Rails est destinée aux administrateurs système GitLab qui cherchent à résoudre un problème ou qui ont besoin de récupérer des données accessibles uniquement via un accès direct à l'application GitLab. Des connaissances de base en Ruby sont nécessaires (essayez [ce tutoriel de 30 minutes](https://try.ruby-lang.org/) pour une introduction rapide). Une expérience avec Rails est utile mais n'est pas obligatoire.

## Démarrer une session de console Rails {#starting-a-rails-console-session}

Le processus de démarrage d'une session de console Rails dépend du type d'installation GitLab.

{{< tabs >}}

{{< tab title="Package Linux (Omnibus)" >}}

```shell
sudo gitlab-rails console
```

{{< /tab >}}

{{< tab title="Docker" >}}

```shell
docker exec -it <container-id> gitlab-rails console
```

{{< /tab >}}

{{< tab title="Auto-compilé (source)" >}}

```shell
sudo -u git -H bundle exec rails console -e production
```

{{< /tab >}}

{{< tab title="Chart Helm (Kubernetes)" >}}

```shell
# find the pod
kubectl get pods --namespace <namespace> -lapp=toolbox

# open the Rails console
kubectl exec -it -c toolbox <toolbox-pod-name> -- gitlab-rails console
```

{{< /tab >}}

{{< /tabs >}}

Pour quitter la console, saisissez : `quit`.

### Désactiver la saisie semi-automatique {#disable-autocompletion}

La saisie semi-automatique Ruby peut ralentir le terminal. Si vous souhaitez :

- Désactiver la saisie semi-automatique, exécutez `Reline.autocompletion = IRB.conf[:USE_AUTOCOMPLETE] = false`.
- Réactiver la saisie semi-automatique, exécutez `Reline.autocompletion = IRB.conf[:USE_AUTOCOMPLETE] = true`.

## Activer la journalisation Active Record {#enable-active-record-logging}

Vous pouvez activer les données de sortie de la journalisation de débogage d'Active Record dans la session de console Rails en exécutant :

```ruby
ActiveRecord::Base.logger = Logger.new($stdout)
```

Par défaut, le script précédent journalise vers les données de sortie standard. Vous pouvez spécifier un fichier journal vers lequel rediriger les données de sortie, en remplaçant `$stdout` par le chemin de fichier souhaité. Par exemple, ce code journalise tout vers `/tmp/output.log` :

```ruby
ActiveRecord::Base.logger = Logger.new('/tmp/output.log')
```

Cela affiche des informations sur les requêtes de base de données déclenchées par tout code Ruby que vous pourriez exécuter dans la console. Pour désactiver à nouveau la journalisation, exécutez :

```ruby
ActiveRecord::Base.logger = nil
```

## Attributs {#attributes}

Affichez les attributs disponibles, mis en forme avec pretty print (`pp`).

Par exemple, déterminez quels attributs contiennent les noms et adresses e-mail des utilisateurs :

```ruby
u = User.find_by_username('someuser')
pp u.attributes
```

Données de sortie partielles :

```plaintext
{"id"=>1234,
 "email"=>"someuser@example.com",
 "sign_in_count"=>99,
 "name"=>"S User",
 "username"=>"someuser",
 "first_name"=>nil,
 "last_name"=>nil,
 "bot_type"=>nil}
```

Utilisez ensuite les attributs, [pour tester SMTP, par exemple](https://docs.gitlab.com/omnibus/settings/smtp/#testing-the-smtp-configuration) :

```ruby
e = u.email
n = u.name
Notify.test_email(e, "Test email for #{n}", 'Test email').deliver_now
#
Notify.test_email(u.email, "Test email for #{u.name}", 'Test email').deliver_now
```

## Désactiver le délai d'expiration des instructions de base de données {#disable-database-statement-timeout}

Vous pouvez désactiver le délai d'expiration des instructions PostgreSQL pour la session de console Rails en cours.

Dans GitLab 15.11 et versions antérieures, pour désactiver le délai d'expiration des instructions de base de données, exécutez :

```ruby
ActiveRecord::Base.connection.execute('SET statement_timeout TO 0')
```

Dans GitLab 16.0 et versions ultérieures, [GitLab utilise deux connexions de base de données par défaut](../../update/versions/gitlab_16_changes.md#1600). Pour désactiver le délai d'expiration des instructions de base de données, exécutez :

```ruby
ActiveRecord::Base.connection.execute('SET statement_timeout TO 0')
Ci::ApplicationRecord.connection.execute('SET statement_timeout TO 0')
```

Les instances exécutant GitLab 16.0 et versions ultérieures reconfigurées pour utiliser une connexion de base de données unique doivent désactiver le délai d'expiration des instructions de base de données en utilisant le code pour GitLab 15.11 et versions antérieures.

La désactivation du délai d'expiration des instructions de base de données n'affecte que la session de console Rails en cours et ne persiste pas dans l'environnement de production GitLab ni dans la prochaine session de console Rails.

## Afficher l'historique de la session de console Rails {#output-rails-console-session-history}

Saisissez la commande suivante dans la console Rails pour afficher l'historique de vos commandes.

```ruby
puts Reline::HISTORY.to_a
```

Vous pouvez ensuite la copier dans votre presse-papiers et la sauvegarder pour référence future.

## Utiliser le Rails Runner {#using-the-rails-runner}

Si vous avez besoin d'exécuter du code Ruby dans le contexte de votre environnement de production GitLab, vous pouvez le faire en utilisant le [Rails Runner](https://guides.rubyonrails.org/command_line.html#rails-runner). Lors de l'exécution d'un fichier script, le script doit être accessible par l'utilisateur `git`.

Lorsque la commande ou le script se termine, le processus Rails Runner s'arrête. Il est utile pour être exécuté dans d'autres scripts ou des tâches cron, par exemple.

- Pour les installations de paquets Linux :

  ```shell
  sudo gitlab-rails runner "RAILS_COMMAND"

  # Example with a two-line Ruby script
  sudo gitlab-rails runner "user = User.first; puts user.username"

  # Example with a ruby script file (make sure to use the full path)
  sudo gitlab-rails runner /path/to/script.rb
  ```

- Pour les installations auto-compilées :

  ```shell
  sudo -u git -H bundle exec rails runner -e production "RAILS_COMMAND"

  # Example with a two-line Ruby script
  sudo -u git -H bundle exec rails runner -e production "user = User.first; puts user.username"

  # Example with a ruby script file (make sure to use the full path)
  sudo -u git -H bundle exec rails runner -e production /path/to/script.rb
  ```

Rails Runner ne produit pas la même sortie que la console.

Si vous définissez une variable sur la console, la console génère une sortie de débogage utile telle que le contenu de la variable ou les propriétés de l'entité référencée :

```ruby
irb(main):001:0> user = User.first
=> #<User id:1 @root>
```

Rails Runner ne fait pas cela : vous devez explicitement générer une sortie :

```shell
$ sudo gitlab-rails runner "user = User.first"
$ sudo gitlab-rails runner "user = User.first; puts user.username ; puts user.id"
root
1
```

Des connaissances de base en Ruby sont très utiles. Essayez [ce tutoriel de 30 minutes](https://try.ruby-lang.org/) pour une introduction rapide. Une expérience avec Rails est utile mais n'est pas indispensable.

## Trouver des méthodes spécifiques pour un objet {#find-specific-methods-for-an-object}

```ruby
Array.methods.select { |m| m.to_s.include? "sing" }
Array.methods.grep(/sing/)
```

## Trouver la source d'une méthode {#find-method-source}

```ruby
instance_of_object.method(:foo).source_location

# Example for when we would call project.private?
project.method(:private?).source_location
```

## Limiter les données de sortie {#limiting-output}

L'ajout d'un point-virgule (`;`) et d'une instruction de suivi à la fin d'une instruction empêche les données de sortie de retour implicite par défaut. Cela peut être utilisé si vous imprimez déjà explicitement des détails et que vous avez potentiellement beaucoup de sortie de retour :

```ruby
puts ActiveRecord::Base.descendants; :ok
Project.select(&:pages_deployed?).each {|p| puts p.path }; true
```

## Obtenir ou stocker le résultat de la dernière opération {#get-or-store-the-result-of-last-operation}

Le caractère souligné (`_`) représente le retour implicite de l'instruction précédente. Vous pouvez l'utiliser pour assigner rapidement une variable à partir des données de sortie de la commande précédente :

```ruby
Project.last
# => #<Project id:2537 root/discard>>
project = _
# => #<Project id:2537 root/discard>>
project.id
# => 2537
```

## Chronométrer une opération {#time-an-operation}

Si vous souhaitez chronométrer une ou plusieurs opérations, utilisez le format suivant, en remplaçant l'espace réservé `<operation>` par les commandes Ruby ou Rails de votre choix :

```ruby
# A single operation
Benchmark.measure { <operation> }

# A breakdown of multiple operations
Benchmark.bm do |x|
  x.report(:label1) { <operation_1> }
  x.report(:label2) { <operation_2> }
end
```

Pour plus d'informations, consultez notre documentation développeur sur les benchmarks.

## Objets Active Record {#active-record-objects}

### Rechercher des objets persistants en base de données {#looking-up-database-persisted-objects}

En coulisses, Rails utilise [Active Record](https://guides.rubyonrails.org/active_record_basics.html), un système de mapping objet-relationnel, pour lire, écrire et mapper les objets de l'application vers la base de données PostgreSQL. Ces mappings sont gérés par les modèles Active Record, qui sont des classes Ruby définies dans une application Rails. Pour GitLab, les classes de modèles se trouvent à `/opt/gitlab/embedded/service/gitlab-rails/app/models`.

Activons la journalisation de débogage pour Active Record afin de voir les requêtes de base de données sous-jacentes effectuées :

```ruby
ActiveRecord::Base.logger = Logger.new($stdout)
```

Maintenant, essayons de récupérer un utilisateur depuis la base de données :

```ruby
user = User.find(1)
```

Ce qui retournerait :

```ruby
D, [2020-03-05T16:46:25.571238 #910] DEBUG -- :   User Load (1.8ms)  SELECT "users".* FROM "users" WHERE "users"."id" = 1 LIMIT 1
=> #<User id:1 @root>
```

Nous pouvons voir que nous avons interrogé la table `users` dans la base de données pour une ligne dont la colonne `id` a la valeur `1`, et Active Record a traduit cet enregistrement de base de données en un objet Ruby avec lequel nous pouvons interagir. Essayez certaines des opérations suivantes :

- `user.username`
- `user.created_at`
- `user.admin`

Par convention, les noms de colonnes sont directement traduits en attributs d'objets Ruby, vous devriez donc pouvoir utiliser `user.<column_name>` pour afficher la valeur de l'attribut.

Également par convention, les noms de classes Active Record (au singulier et en camel case) correspondent directement aux noms de tables (au pluriel et en snake case) et vice versa. Par exemple, la table `users` correspond à la classe `User`, tandis que la table `application_settings` correspond à la classe `ApplicationSetting`.

Vous pouvez trouver une liste de tables et de noms de colonnes dans le schéma de base de données Rails, disponible à `/opt/gitlab/embedded/service/gitlab-rails/db/schema.rb`.

Vous pouvez également rechercher un objet dans la base de données par nom d'attribut :

```ruby
user = User.find_by(username: 'root')
```

Ce qui retournerait :

```ruby
D, [2020-03-05T17:03:24.696493 #910] DEBUG -- :   User Load (2.1ms)  SELECT "users".* FROM "users" WHERE "users"."username" = 'root' LIMIT 1
=> #<User id:1 @root>
```

Essayez ce qui suit :

- `User.find_by(username: 'root')`
- `User.where.not(admin: true)`
- `User.where('created_at < ?', 7.days.ago)`

Avez-vous remarqué que les deux dernières commandes ont retourné un objet `ActiveRecord::Relation` qui semblait contenir plusieurs objets `User` ?

Jusqu'à présent, nous avons utilisé `.find` ou `.find_by`, qui sont conçus pour retourner un seul objet (remarquez le `LIMIT 1` dans la requête SQL générée ?). `.where` est utilisé lorsqu'il est souhaitable d'obtenir une collection d'objets.

Récupérons une collection d'utilisateurs non-administrateurs et voyons ce que nous pouvons en faire :

```ruby
users = User.where.not(admin: true)
```

Ce qui retournerait :

```ruby
D, [2020-03-05T17:11:16.845387 #910] DEBUG -- :   User Load (2.8ms)  SELECT "users".* FROM "users" WHERE "users"."admin" != TRUE LIMIT 11
=> #<ActiveRecord::Relation [#<User id:3 @support-bot>, #<User id:7 @alert-bot>, #<User id:5 @carrie>, #<User id:4 @bernice>, #<User id:2 @anne>]>
```

Maintenant, essayez ce qui suit :

- `users.count`
- `users.order(created_at: :desc)`
- `users.where(username: 'support-bot')`

Dans la dernière commande, nous voyons que nous pouvons enchaîner des instructions `.where` pour générer des requêtes plus complexes. Remarquez également que si la collection retournée ne contient qu'un seul objet, nous ne pouvons pas interagir directement avec lui :

```ruby
users.where(username: 'support-bot').username
```

Ce qui retournerait :

```ruby
Traceback (most recent call last):
        1: from (irb):37
D, [2020-03-05T17:18:25.637607 #910] DEBUG -- :   User Load (1.6ms)  SELECT "users".* FROM "users" WHERE "users"."admin" != TRUE AND "users"."username" = 'support-bot' LIMIT 11
NoMethodError (undefined method `username' for #<ActiveRecord::Relation [#<User id:3 @support-bot>]>)
Did you mean?  by_username
```

Récupérons l'objet unique de la collection en utilisant la méthode `.first` pour obtenir le premier élément de la collection :

```ruby
users.where(username: 'support-bot').first.username
```

Nous obtenons maintenant le résultat souhaité :

```ruby
D, [2020-03-05T17:18:30.406047 #910] DEBUG -- :   User Load (2.6ms)  SELECT "users".* FROM "users" WHERE "users"."admin" != TRUE AND "users"."username" = 'support-bot' ORDER BY "users"."id" ASC LIMIT 1
=> "support-bot"
```

Pour en savoir plus sur les différentes façons de récupérer des données depuis la base de données avec Active Record, consultez la [documentation sur l'interface de requête Active Record](https://guides.rubyonrails.org/active_record_querying.html).

## Interroger la base de données à l'aide d'un modèle Active Record {#query-the-database-using-an-active-record-model}

```ruby
m = Model.where('attribute like ?', 'ex%')

# for example to query the projects
projects = Project.where('path like ?', 'Oumua%')
```

### Modifier des objets Active Record {#modifying-active-record-objects}

Dans la section précédente, nous avons appris à récupérer des enregistrements de base de données à l'aide d'Active Record. Maintenant, voyons comment écrire des modifications dans la base de données.

Tout d'abord, récupérons l'utilisateur `root` :

```ruby
user = User.find_by(username: 'root')
```

Ensuite, essayons de mettre à jour le mot de passe de l'utilisateur :

```ruby
user.password = 'password'
user.save
```

Ce qui retournerait :

```ruby
Enqueued ActionMailer::MailDeliveryJob (Job ID: 05915c4e-c849-4e14-80bb-696d5ae22065) to Sidekiq(mailers) with arguments: "DeviseMailer", "password_change", "deliver_now", #<GlobalID:0x00007f42d8ccebe8 @uri=#<URI::GID gid://gitlab/User/1>>
=> true
```

Ici, nous voyons que la commande `.save` a retourné `true`, indiquant que le changement de mot de passe a été correctement enregistré dans la base de données.

Nous voyons également que l'opération de sauvegarde a déclenché une autre action, dans ce cas un job en arrière-plan pour envoyer une notification par e-mail. Il s'agit d'un exemple de [rappel Active Record](https://guides.rubyonrails.org/active_record_callbacks.html), code désigné pour s'exécuter en réponse aux événements dans le cycle de vie des objets Active Record. C'est également pourquoi l'utilisation de la console Rails est préférée lorsque des modifications directes des données sont nécessaires, car les modifications effectuées via des requêtes de base de données directes ne déclenchent pas ces rappels.

Il est également possible de mettre à jour des attributs en une seule ligne :

```ruby
user.update(password: 'password')
```

Ou de mettre à jour plusieurs attributs en même temps :

```ruby
user.update(password: 'password', email: 'hunter2@example.com')
```

Maintenant, essayons quelque chose de différent :

```ruby
# Retrieve the object again so we get its latest state
user = User.find_by(username: 'root')
user.password = 'password'
user.password_confirmation = 'hunter2'
user.save
```

Cela retourne `false`, indiquant que les modifications apportées n'ont pas été enregistrées dans la base de données. Vous pouvez probablement deviner pourquoi, mais vérifions-le :

```ruby
user.save!
```

Cela devrait retourner :

```ruby
Traceback (most recent call last):
        1: from (irb):64
ActiveRecord::RecordInvalid (Validation failed: Password confirmation doesn't match Password)
```

Ah ! Nous avons déclenché une [validation Active Record](https://guides.rubyonrails.org/active_record_validations.html). Les validations sont une logique métier mise en place au niveau de l'application pour empêcher l'enregistrement de données indésirables dans la base de données et, dans la plupart des cas, elles s'accompagnent de messages utiles vous indiquant comment corriger les entrées problématiques.

Nous pouvons également ajouter le bang (terme Ruby pour `!`) à `.update` :

```ruby
user.update!(password: 'password', password_confirmation: 'hunter2')
```

En Ruby, les noms de méthodes se terminant par `!` sont communément appelés « méthodes bang ». Par convention, le bang indique que la méthode modifie directement l'objet sur lequel elle agit, par opposition au retour du résultat transformé en laissant l'objet sous-jacent intact. Pour les méthodes Active Record qui écrivent dans la base de données, les méthodes bang remplissent également une fonction supplémentaire : elles lèvent une exception explicite chaque fois qu'une erreur se produit, au lieu de simplement retourner `false`.

Nous pouvons également ignorer complètement les validations :

```ruby
# Retrieve the object again so we get its latest state
user = User.find_by(username: 'root')
user.password = 'password'
user.password_confirmation = 'hunter2'
user.save!(validate: false)
```

Cela n'est pas recommandé car les validations sont généralement mises en place pour garantir l'intégrité et la cohérence des données fournies par les utilisateurs.

Une erreur de validation empêche l'enregistrement de l'objet entier dans la base de données. Vous pouvez en voir un aperçu dans la section ci-dessous. Si vous obtenez une mystérieuse bannière rouge dans l'interface utilisateur GitLab lors de la soumission d'un formulaire, cela peut souvent être le moyen le plus rapide d'identifier la cause du problème.

### Interagir avec des objets Active Record {#interacting-with-active-record-objects}

En fin de compte, les objets Active Record sont de simples objets Ruby standard. En tant que tels, nous pouvons y définir des méthodes qui effectuent des actions arbitraires.

Par exemple, les développeurs de GitLab ont ajouté des méthodes qui facilitent l'authentification à deux facteurs :

```ruby
def disable_two_factor!
  transaction do
    update(
      otp_required_for_login:      false,
      encrypted_otp_secret:        nil,
      encrypted_otp_secret_iv:     nil,
      encrypted_otp_secret_salt:   nil,
      otp_grace_period_started_at: nil,
      otp_backup_codes:            nil
    )
    self.second_factor_webauthn_registrations.destroy_all # rubocop: disable DestroyAll
  end
end

def two_factor_enabled?
  two_factor_otp_enabled? || two_factor_webauthn_enabled?
end
```

(Voir : `/opt/gitlab/embedded/service/gitlab-rails/app/models/user.rb`)

Nous pouvons ensuite utiliser ces méthodes sur n'importe quel objet utilisateur :

```ruby
user = User.find_by(username: 'root')
user.two_factor_enabled?
user.disable_two_factor!
```

Certaines méthodes sont définies par des gemmes, ou paquets logiciels Ruby, utilisés par GitLab. Par exemple, la gemme [StateMachines](https://github.com/state-machines/state_machines-activerecord) que GitLab utilise pour gérer l'état des utilisateurs :

```ruby
state_machine :state, initial: :active do
  event :block do

  ...

  event :activate do

  ...

end
```

Essayez :

```ruby
user = User.find_by(username: 'root')
user.state
user.block
user.state
user.activate
user.state
```

Précédemment, nous avons mentionné qu'une erreur de validation empêche l'enregistrement de l'objet entier dans la base de données. Voyons comment cela peut entraîner des interactions inattendues :

```ruby
user.password = 'password'
user.password_confirmation = 'hunter2'
user.block
```

Nous obtenons `false` en retour ! Voyons ce qui s'est passé en ajoutant un bang comme nous l'avons fait précédemment :

```ruby
user.block!
```

Ce qui retournerait :

```ruby
Traceback (most recent call last):
        1: from (irb):87
StateMachines::InvalidTransition (Cannot transition state via :block from :active (Reason(s): Password confirmation doesn't match Password))
```

Nous voyons qu'une erreur de validation provenant de ce qui ressemble à un attribut complètement séparé revient nous hanter lorsque nous essayons de mettre à jour l'utilisateur de quelque façon que ce soit.

En pratique, nous voyons parfois cela se produire avec les paramètres d'administration de GitLab : des validations sont parfois ajoutées ou modifiées lors d'une mise à jour de GitLab, ce qui entraîne l'échec de la validation pour des paramètres précédemment enregistrés. Comme vous ne pouvez mettre à jour qu'un sous-ensemble de paramètres à la fois via l'interface utilisateur, dans ce cas la seule façon de retrouver un bon état est la manipulation directe via la console Rails.

### Modèles Active Record couramment utilisés et comment rechercher des objets {#commonly-used-active-record-models-and-how-to-look-up-objects}

**Trouver un utilisateur par adresse e-mail principale ou nom d'utilisateur** :

```ruby
User.find_by(email: 'admin@example.com')
User.find_by(username: 'root')
```

**Trouver un utilisateur par adresse e-mail principale OU secondaire** :

```ruby
User.find_by_any_email('user@example.com')
```

La méthode `find_by_any_email` est une méthode personnalisée ajoutée par les développeurs GitLab plutôt qu'une méthode par défaut fournie par Rails.

**Trouver une collection d'utilisateurs administrateurs** :

```ruby
User.admins
```

`admins` est une [méthode de commodité de portée](https://guides.rubyonrails.org/active_record_querying.html#scopes) qui effectue `where(admin: true)` en coulisses.

**Trouver un projet par son chemin** :

```ruby
Project.find_by_full_path('group/subgroup/project')
```

`find_by_full_path` est une méthode personnalisée ajoutée par les développeurs GitLab plutôt qu'une méthode par défaut fournie par Rails.

**Trouver un ticket de projet ou une merge request par son ID numérique** :

```ruby
project = Project.find_by_full_path('group/subgroup/project')
project.issues.find_by(iid: 42)
project.merge_requests.find_by(iid: 42)
```

`iid` signifie « ID interne » et c'est ainsi que nous maintenons les ID des tickets et des merge requests dans la portée de chaque projet GitLab.

**Trouver un groupe par son chemin** :

```ruby
Group.find_by_full_path('group/subgroup')
```

**Trouver des groupes reliés au groupe** :

```ruby
group = Group.find_by_full_path('group/subgroup')

# Get a group's parent group
group.parent

# Get a group's child groups
group.children
```

**Trouver les projets du groupe** :

```ruby
group = Group.find_by_full_path('group/subgroup')

# Get group's immediate child projects
group.projects

# Get group's child projects, including those in subgroups
group.all_projects
```

**Trouver un pipeline ou des builds CI** :

```ruby
Ci::Pipeline.find(4151)
Ci::Build.find(66124)
```

Les numéros d'ID de pipeline et de job s'incrémentent globalement sur l'ensemble de votre instance GitLab, il n'est donc pas nécessaire d'utiliser un attribut d'ID interne pour les rechercher, contrairement aux tickets ou aux merge requests.

**Trouver l'objet des paramètres de l'application actuelle** :

```ruby
ApplicationSetting.current
```

### Ouvrir un objet dans `irb` {#open-object-in-irb}

> [!warning]
> Les commandes qui modifient des données peuvent causer des dommages si elles ne sont pas exécutées correctement ou dans les bonnes conditions. Exécutez toujours les commandes dans un environnement de test en premier et disposez d'une instance de sauvegarde prête à être restaurée.

Il est parfois plus facile de parcourir une méthode lorsque vous êtes dans le contexte de l'objet. Vous pouvez vous glisser dans l'espace de nommage de `Object` pour vous permettre d'ouvrir `irb` dans le contexte de n'importe quel objet :

```ruby
Object.define_method(:irb) { binding.irb }

project = Project.last
# => #<Project id:2537 root/discard>>
project.irb
# Notice new context
irb(#<Project>)> web_url
# => "https://gitlab-example/root/discard"
```

## Dépannage {#troubleshooting}

### Rails Runner `syntax error` {#rails-runner-syntax-error}

La commande `gitlab-rails` exécute Rails Runner en utilisant un compte et un groupe non-root, par défaut : `git:git`.

Si le compte non-root ne trouve pas le nom de fichier du script Ruby passé à `gitlab-rails runner`, vous pouvez obtenir une erreur de syntaxe, et non une erreur indiquant que le fichier n'était pas accessible.

Une raison courante à cela est que le script a été placé dans le répertoire personnel du compte root.

`runner` tente d'analyser le chemin et le paramètre de fichier comme du code Ruby.

Par exemple :

```plaintext
[root ~]# echo 'puts "hello world"' > ./helloworld.rb
[root ~]# sudo gitlab-rails runner ./helloworld.rb
Please specify a valid ruby command or the path of a script to run.
Run 'rails runner -h' for help.

/opt/gitlab/..../runner_command.rb:45: syntax error, unexpected '.'
./helloworld.rb
^
[root ~]# sudo gitlab-rails runner /root/helloworld.rb
Please specify a valid ruby command or the path of a script to run.
Run 'rails runner -h' for help.

/opt/gitlab/..../runner_command.rb:45: unknown regexp options - hllwrld
[root ~]# mv ~/helloworld.rb /tmp
[root ~]# sudo gitlab-rails runner /tmp/helloworld.rb
hello world
```

Une erreur significative devrait être générée si le répertoire est accessible mais pas le fichier :

```plaintext
[root ~]# chmod 400 /tmp/helloworld.rb
[root ~]# sudo gitlab-rails runner /tmp/helloworld.rb
Traceback (most recent call last):
      [traceback removed]
/opt/gitlab/..../runner_command.rb:42:in `load': cannot load such file -- /tmp/helloworld.rb (LoadError)
```

Si vous rencontrez une erreur similaire à celle-ci :

```plaintext
[root ~]# sudo gitlab-rails runner helloworld.rb
Please specify a valid ruby command or the path of a script to run.
Run 'rails runner -h' for help.

undefined local variable or method `helloworld' for main:Object
```

Vous pouvez soit déplacer le fichier vers le répertoire `/tmp`, soit créer un nouveau répertoire appartenant à l'utilisateur `git` et y enregistrer le script comme illustré ci-dessous :

```shell
sudo mkdir /scripts
sudo mv /script_path/helloworld.rb /scripts
sudo chown -R git:git /scripts
sudo chmod 700 /scripts
sudo gitlab-rails runner /scripts/helloworld.rb
```

### Données de sortie filtrées de la console {#filtered-console-output}

Certaines sorties de la console peuvent être filtrées par défaut pour éviter les fuites de certaines valeurs telles que des variables, des journaux ou des secrets. Cette sortie s'affiche sous la forme `[FILTERED]`. Par exemple :

```plaintext
> Plan.default.actual_limits
=> ci_instance_level_variables: "[FILTERED]",
```

Pour contourner le filtrage, lisez les valeurs directement depuis l'objet. Par exemple :

```plaintext
> Plan.default.limits.ci_instance_level_variables
=> 25
```
