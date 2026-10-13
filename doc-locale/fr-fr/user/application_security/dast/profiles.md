---
stage: Application Security Testing
group: Dynamic Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Profils DAST
---

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Les profils de site et de scanner DAST enregistrent les informations relatives à vos applications et aux scanners que vous utilisez pour les évaluer. Une fois un profil défini, vous pouvez l'utiliser pour les jobs DAST de pipeline et à la demande.

La création, la mise à jour et la suppression des profils DAST, des profils de scanner DAST et des profils de site DAST sont incluses dans le [journal d'audit](../../../administration/compliance/audit_event_reports.md).

## Profil de site {#site-profile}

{{< history >}}

- Les fonctionnalités du profil de site, la méthode d'analyse et l'URL du fichier, ont été [activées sur GitLab.com et GitLab Self-Managed](https://gitlab.com/gitlab-org/gitlab/-/issues/345837) dans GitLab 15.6.
- La fonctionnalité de chemin d'accès du point de terminaison GraphQL a été [introduite](https://gitlab.com/gitlab-org/gitlab/-/issues/378692) dans GitLab 15.7.
- Des variables supplémentaires ont été [introduites](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/177703) dans GitLab 17.9.

{{< /history >}}

Un profil de site définit les attributs et les détails de configuration de l'application déployée, du site Web ou de l'API à analyser par DAST.

Un profil de site contient :

- **Nom du profil** : un nom que vous attribuez au site à analyser. Lorsqu'un profil de site est référencé dans `.gitlab-ci.yml` ou dans une analyse à la demande, il **ne peut pas** être renommé.
- **Type de site** : le type de cible à analyser : site Web ou analyse d'API.
- **URL cible** : l'URL sur laquelle DAST s'exécute.
- **URL exclues** : une liste d'URL séparées par des virgules à exclure de l'analyse. Vous pouvez utiliser les [expressions régulières de style RE2](https://github.com/google/re2/wiki/Syntax). L'expression régulière ne peut pas inclure le caractère point d'interrogation (`?`), car il s'agit d'un caractère d'URL valide.
- **En-têtes de requête** : une liste d'en-têtes de requête HTTP séparés par des virgules, incluant les noms et les valeurs. Ces en-têtes sont ajoutés à chaque requête effectuée par DAST.
- **Authentification** : 
  - **Authenticated URL** : l'URL de la page contenant le formulaire HTML de connexion sur le site Web cible. Le nom d'utilisateur et le mot de passe sont soumis avec le formulaire de connexion pour créer une analyse authentifiée.
  - **Nom d'utilisateur** : le nom d'utilisateur utilisé pour s'authentifier sur le site Web.
  - **Mot de passe** : le mot de passe utilisé pour s'authentifier sur le site Web.
  - **Champ de formulaire du nom d'utilisateur** : le nom du champ du nom d'utilisateur dans le formulaire HTML de connexion.
  - **Champ de formulaire du mot de passe** : le nom du champ du mot de passe dans le formulaire HTML de connexion.
  - **Submit form field** : l'`id` ou le `name` de l'élément qui, lorsqu'il est sélectionné, soumet le formulaire HTML de connexion.
- **Méthode d'analyse** : un type de méthode pour effectuer des tests d'API. Les méthodes prises en charge sont OpenAPI, Postman Collections, HTTP Archive (HAR) ou GraphQL.
  - **Chemin d'accès du point de terminaison GraphQL** : le chemin d'accès au point de terminaison GraphQL. Ce chemin est concaténé avec l'URL cible pour fournir l'URI que l'analyse doit tester. Le point de terminaison GraphQL doit prendre en charge les requêtes d'introspection.
  - **File URL** : l'URL du fichier OpenAPI, Postman Collection ou HTTP Archive.
- **Variables supplémentaires** : une liste de variables d'environnement pour configurer des comportements d'analyse spécifiques. Ces variables offrent les mêmes options de configuration que les analyses DAST basées sur un pipeline, telles que la définition de délais d'expiration, l'ajout d'une URL de succès d'authentification ou l'activation de fonctionnalités d'analyse avancées.

Lorsqu'un type de site API est sélectionné, un remplacement d'hôte est utilisé pour s'assurer que l'API analysée se trouve sur le même hôte que la cible. Cela est effectué pour réduire le risque d'exécuter une analyse active contre la mauvaise API.

Lorsqu'ils sont configurés, les en-têtes de requête et les champs de mot de passe sont chiffrés à l'aide de [`aes-256-gcm`](https://en.wikipedia.org/wiki/Advanced_Encryption_Standard) avant d'être stockés dans la base de données. Ces données ne peuvent être lues et déchiffrées qu'avec un fichier de secrets valide.

Vous pouvez référencer un profil de site dans `.gitlab-ci.yml` et dans les analyses à la demande.

```yaml
stages:
  - dast

include:
  - template: DAST.gitlab-ci.yml

dast:
  stage: dast
  dast_configuration:
    site_profile: "<profile name>"
```

### Validation du profil de site {#site-profile-validation}

La validation du profil de site réduit le risque d'exécuter une analyse active contre le mauvais site Web. Vous devez valider un site pour y exécuter une analyse à la demande.

La validation du profil de site n'est pas une fonctionnalité de sécurité. Si nécessaire, vous pouvez exécuter DAST contre un site non validé avec une [analyse de pipeline](browser/configuration/enabling_the_analyzer.md).

Chacune des méthodes de validation de site est équivalente en termes de fonctionnalité, utilisez donc celle qui convient le mieux :

- **Validation par fichier texte** : nécessite qu'un fichier texte soit téléversé sur le site cible. Le fichier texte se voit attribuer un nom et un contenu uniques au projet. Le processus de validation vérifie le contenu du fichier.
- **Validation de l'en-tête** : nécessite que l'en-tête `Gitlab-On-Demand-DAST` soit ajouté au site cible, avec une valeur unique au projet. Le processus de validation vérifie que l'en-tête est présent et contrôle sa valeur.
- **Validation de la balise Meta** : nécessite que la balise meta nommée `gitlab-dast-validation` soit ajoutée au site cible, avec une valeur unique au projet. Assurez-vous qu'elle est ajoutée à la section `<head>` de la page. Le processus de validation vérifie que la balise meta est présente et contrôle sa valeur.

### Créer un profil de site {#create-a-site-profile}

Pour créer un profil de site :

1. Dans la barre supérieure, sélectionnez **Rechercher ou accéder à** et repérez votre projet.
1. Dans la barre latérale gauche, sélectionnez **Sécurisation** > **Configuration de la sécurité**.
1. Dans la section **Test dynamique de sécurité des applications (DAST)**, sélectionnez **Gérer les profils**.
1. Sélectionnez **Nouvelle** > **Profil de site**.
1. Remplissez les champs puis sélectionnez **Enregistrer le profil**.

Le profil de site est enregistré pour être utilisé dans une analyse à la demande.

### Modifier un profil de site {#edit-a-site-profile}

Modifiez un profil de site pour changer ses paramètres avant une analyse.

Si un profil de site est lié à une politique de sécurité, vous ne pouvez pas modifier le profil depuis cette page. Consultez les [politiques d'exécution d'analyse](../policies/scan_execution_policies.md) pour plus d'informations.

Pour activer le pipeline de validation de site, vous devez définir un runner avec le tag `dast-validation-runner` ou définir un runner pouvant exécuter des jobs sans tag.

Prérequis :

- Si une analyse DAST utilise le profil, vous devez être en mesure d'effectuer un push vers la branche associée à l'analyse.

Pour modifier un profil de site :

1. Dans la barre supérieure, sélectionnez **Rechercher ou accéder à** et repérez votre projet.
1. Dans la barre latérale gauche, sélectionnez **Sécurisation** > **Configuration de la sécurité**.
1. Dans la section **Test dynamique de sécurité des applications (DAST)**, sélectionnez **Gérer les profils**.
1. Sélectionnez l'onglet **Site Profiles**.
1. Dans la ligne du profil, sélectionnez le menu **Plus d'actions** ({{< icon name="ellipsis_v" >}}), puis sélectionnez **Modifier**.
1. Modifiez les champs puis sélectionnez **Enregistrer le profil**.

Si l'URL cible ou l'URL authentifiée d'un profil de site est mise à jour, les en-têtes de requête et les champs de mot de passe associés à ce profil sont effacés.

### Supprimer un profil de site {#delete-a-site-profile}

> [!note]
> Si un profil de site est lié à une politique de sécurité, un utilisateur ne peut pas supprimer le profil depuis cette page. Consultez les [politiques d'exécution d'analyse](../policies/scan_execution_policies.md) pour plus d'informations. Si un profil de site est lié à une [analyse à la demande](on-demand_scan.md) et est supprimé, l'analyse à la demande est également supprimée.

Pour supprimer un profil de site :

1. Dans la barre supérieure, sélectionnez **Rechercher ou accéder à** et repérez votre projet.
1. Dans la barre latérale gauche, sélectionnez **Sécurisation** > **Configuration de la sécurité**.
1. Dans la section **Test dynamique de sécurité des applications (DAST)**, sélectionnez **Gérer les profils**.
1. Sélectionnez l'onglet **Site Profiles**.
1. Dans la ligne du profil, sélectionnez le menu **Plus d'actions** ({{< icon name="ellipsis_v" >}}), puis sélectionnez **Supprimer**.
1. Sélectionnez **Supprimer** pour confirmer la suppression.

### Valider un profil de site {#validate-a-site-profile}

La validation d'un site est requise pour exécuter une analyse active.

Prérequis :

- Un runner doit être disponible dans le projet pour exécuter un job de validation.

Pour valider un profil de site :

1. Dans la barre supérieure, sélectionnez **Rechercher ou accéder à** et repérez votre projet.
1. Dans la barre latérale gauche, sélectionnez **Sécurisation** > **Configuration de la sécurité**.
1. Dans la section **Test dynamique de sécurité des applications (DAST)**, sélectionnez **Gérer les profils**.
1. Sélectionnez l'onglet **Site Profiles**.
1. Dans la ligne du profil, sélectionnez **Valider**.
1. Sélectionnez la méthode de validation.
   1. Pour la **Validation par fichier texte** :
      1. Téléchargez le fichier de validation indiqué à l'**Étape 2**.
      1. Téléversez le fichier de validation sur l'hôte, à l'emplacement indiqué à l'**Étape 3** ou à tout autre emplacement de votre choix.
      1. Si nécessaire, modifiez l'emplacement du fichier à l'**Étape 3**.
      1. Sélectionnez **Valider**.
   1. Pour la **Validation de l'en-tête** :
      1. Sélectionnez l'icône du presse-papiers à l'**Étape 2**.
      1. Modifiez l'en-tête du site à valider et collez le contenu du presse-papiers.
      1. Sélectionnez le champ de saisie à l'**Étape 3** et saisissez l'emplacement de l'en-tête.
      1. Sélectionnez **Valider**.
   1. Pour la **Validation de la balise Meta** :
      1. Sélectionnez l'icône du presse-papiers à l'**Étape 2**.
      1. Modifiez le contenu du site à valider et collez le contenu du presse-papiers.
      1. Sélectionnez le champ de saisie à l'**Étape 3** et saisissez l'emplacement de la balise meta.
      1. Sélectionnez **Valider**.

Le site est validé et une analyse active peut y être exécutée. Le statut de validation d'un profil de site n'est révoqué que s'il est révoqué manuellement ou si son fichier, son en-tête ou sa balise meta est modifié.

### Retenter une validation échouée {#retry-a-failed-validation}

Les tentatives de validation de site échouées sont répertoriées dans l'onglet **Profils de sites** de la page **Gérer les profils**.

Pour retenter la validation échouée d'un profil de site :

1. Dans la barre supérieure, sélectionnez **Rechercher ou accéder à** et repérez votre projet.
1. Dans la barre latérale gauche, sélectionnez **Sécurisation** > **Configuration de la sécurité**.
1. Dans la section **Test dynamique de sécurité des applications (DAST)**, sélectionnez **Gérer les profils**.
1. Sélectionnez l'onglet **Site Profiles**.
1. Dans la ligne du profil, sélectionnez **Retenter la validation**.

### Révoquer le statut de validation d'un profil de site {#revoke-a-site-profiles-validation-status}

> [!warning]
> Lorsque le statut de validation d'un profil de site est révoqué, tous les profils de site partageant la même URL voient également leur statut de validation révoqué.

Pour révoquer le statut de validation d'un profil de site :

1. Dans la barre supérieure, sélectionnez **Rechercher ou accéder à** et repérez votre projet.
1. Dans la barre latérale gauche, sélectionnez **Sécurisation** > **Configuration de la sécurité**.
1. Dans la section **Test dynamique de sécurité des applications (DAST)**, sélectionnez **Gérer les profils**.
1. À côté du profil validé, sélectionnez **Révoquer la validation**.

Le statut de validation du profil de site est révoqué.

### En-têtes de profil de site validés {#validated-site-profile-headers}

Voici des exemples de code illustrant comment fournir l'en-tête de profil de site requis dans votre application.

#### Exemple Ruby on Rails pour une analyse à la demande {#ruby-on-rails-example-for-on-demand-scan}

Voici comment ajouter un en-tête personnalisé dans une application Ruby on Rails :

```ruby
class DastWebsiteTargetController < ActionController::Base
  def dast_website_target
    response.headers['Gitlab-On-Demand-DAST'] = '0dd79c9a-7b29-4e26-a815-eaaf53fcab1c'
    head :ok
  end
end
```

#### Exemple Django pour une analyse à la demande {#django-example-for-on-demand-scan}

Voici comment ajouter un [en-tête personnalisé dans Django](https://docs.djangoproject.com/en/2.2/ref/request-response/#setting-header-fields) :

```python
class DastWebsiteTargetView(View):
    def head(self, *args, **kwargs):
      response = HttpResponse()
      response['Gitlab-On-Demand-DAST'] = '0dd79c9a-7b29-4e26-a815-eaaf53fcab1c'

      return response
```

#### Exemple Node (avec Express) pour une analyse à la demande {#node-with-express-example-for-on-demand-scan}

Voici comment ajouter un [en-tête personnalisé dans Node (avec Express)](https://expressjs.com/en/5x/api.html#res.append) :

```javascript
app.get('/dast-website-target', function(req, res) {
  res.append('Gitlab-On-Demand-DAST', '0dd79c9a-7b29-4e26-a815-eaaf53fcab1c')
  res.send('Respond to DAST ping')
})
```

## Profil de scanner {#scanner-profile}

{{< history >}}

- Option AJAX Spider dépréciée avec l'introduction des analyses DAST à la demande basées sur le navigateur dans GitLab 17.0.
- Délai d'expiration de l'araignée renommé en délai d'expiration de l'indexation avec l'introduction des analyses DAST à la demande basées sur le navigateur dans GitLab 17.0.

{{< /history >}}

Un profil de scanner définit les détails de configuration d'un scanner de sécurité.

Un profil de scanner contient :

- **Nom du profil** : un nom que vous donnez au profil de scanner. Par exemple, « Spider_15 ». Lorsqu'un profil de scanner est référencé dans `.gitlab-ci.yml` ou dans une analyse à la demande, il **ne peut pas** être renommé.
- **Mode d'analyse** : une analyse passive surveille tous les messages HTTP (requêtes et réponses) envoyés à la cible. Une analyse active attaque la cible pour détecter les vulnérabilités potentielles.
- **Délai d'expiration de l'indexation** : le nombre maximum de minutes allouées au crawler pour parcourir le site.
- **Délai d'expiration pour la cible** : le nombre maximum de secondes pendant lesquelles DAST attend que le site soit disponible avant de lancer l'analyse.
- **Messages de débogage** : inclure les messages de débogage dans la sortie console de DAST.

Vous pouvez référencer un profil de scanner dans `.gitlab-ci.yml` et dans les analyses à la demande.

```yaml
stages:
  - dast

include:
  - template: DAST.gitlab-ci.yml

dast:
  stage: dast
  dast_configuration:
    scanner_profile: "<profile name>"
```

### Créer un profil de scanner {#create-a-scanner-profile}

Pour créer un profil de scanner :

1. Dans la barre supérieure, sélectionnez **Rechercher ou accéder à** et repérez votre projet.
1. Dans la barre latérale gauche, sélectionnez **Sécurisation** > **Configuration de la sécurité**.
1. Dans la section **Test dynamique de sécurité des applications (DAST)**, sélectionnez **Gérer les profils**.
1. Sélectionnez **Nouvelle** > **Profil de scanner**.
1. Remplissez le formulaire. Pour plus de détails sur chaque champ, consultez [Profil de scanner](#scanner-profile).
1. Sélectionnez **Enregistrer le profil**.

### Modifier un profil de scanner {#edit-a-scanner-profile}

Prérequis :

- Si une analyse DAST utilise le profil, vous devez être en mesure d'effectuer un push vers la branche associée à l'analyse.

> [!note]
> Si un profil de scanner est lié à une politique de sécurité, vous ne pouvez pas modifier le profil depuis cette page. Pour plus d'informations, consultez les [politiques d'exécution d'analyse](../policies/scan_execution_policies.md).

Pour modifier un profil de scanner :

1. Dans la barre supérieure, sélectionnez **Rechercher ou accéder à** et repérez votre projet.
1. Dans la barre latérale gauche, sélectionnez **Sécurisation** > **Configuration de la sécurité**.
1. Dans la section **Test dynamique de sécurité des applications (DAST)**, sélectionnez **Gérer les profils**.
1. Sélectionnez l'onglet **Profils de scanners**.
1. Dans la ligne du scanner, sélectionnez le menu **Plus d'actions** ({{< icon name="ellipsis_v" >}}), puis sélectionnez **Modifier**.
1. Modifiez le formulaire.
1. Sélectionnez **Enregistrer le profil**.

### Supprimer un profil de scanner {#delete-a-scanner-profile}

> [!note]
> Si un profil de scanner est lié à une politique de sécurité, un utilisateur ne peut pas supprimer le profil depuis cette page. Pour plus d'informations, consultez les [politiques d'exécution d'analyse](../policies/scan_execution_policies.md). Si un profil de scanner est lié à une [analyse à la demande](on-demand_scan.md) et est supprimé, l'analyse à la demande est également supprimée.

Pour supprimer un profil de scanner :

1. Dans la barre supérieure, sélectionnez **Rechercher ou accéder à** et repérez votre projet.
1. Dans la barre latérale gauche, sélectionnez **Sécurisation** > **Configuration de la sécurité**.
1. Dans la section **Test dynamique de sécurité des applications (DAST)**, sélectionnez **Gérer les profils**.
1. Sélectionnez l'onglet **Profils de scanners**.
1. Dans la ligne du scanner, sélectionnez le menu **Plus d'actions** ({{< icon name="ellipsis_v" >}}), puis sélectionnez **Supprimer**.
1. Sélectionnez **Supprimer**.
