---
stage: Software Supply Chain Security
group: Authorization
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: reCAPTCHA
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

GitLab utilise [reCAPTCHA](https://www.google.com/recaptcha/about/) pour se protéger contre le spam et les abus. GitLab affiche le formulaire CAPTCHA sur la page de création de compte utilisateur pour confirmer qu'un véritable utilisateur, et non un bot, tente de créer un compte.

## Configuration {#configuration}

Pour utiliser reCAPTCHA, commencez par créer un site et une clé privée.

1. Accédez à la [page Google reCAPTCHA](https://www.google.com/recaptcha/admin).
1. Pour obtenir les clés reCAPTCHA v2, remplissez le formulaire et sélectionnez **Envoyer**.
1. Connectez-vous à votre serveur GitLab en tant qu'administrateur.
1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Rapports**.
1. Déroulez **Protection anti‐spam et anti‐robot**.
1. Dans les champs reCAPTCHA, saisissez les clés obtenues lors des étapes précédentes.
1. Cochez la case **Activer le reCAPTCHA**.
1. Pour activer le reCAPTCHA pour les connexions via mot de passe, cochez la case **Enable reCAPTCHA for login**.
1. Sélectionnez **Enregistrer les modifications**.
1. Pour court-circuiter la vérification anti-spam et déclencher le retour de la réponse `recaptcha_html` :
   1. Ouvrez `app/services/spam/spam_verdict_service.rb`.
   1. Remplacez la première ligne de la méthode `#execute` par `return CONDITIONAL_ALLOW`.

> [!note]
> Assurez-vous de consulter un élément de type issuable dans un projet public. Si vous travaillez avec un ticket, le ticket est public.

## Activer le reCAPTCHA pour les connexions utilisateur via l'en-tête HTTP {#enable-recaptcha-for-user-logins-using-the-http-header}

Vous pouvez activer le reCAPTCHA pour les connexions utilisateur via mot de passe [dans l'interface utilisateur](#configuration) ou en définissant l'en-tête HTTP `X-GitLab-Show-Login-Captcha`. Par exemple, dans NGINX, cela peut être effectué via la variable de configuration `proxy_set_header` :

```nginx
proxy_set_header X-GitLab-Show-Login-Captcha 1;
```

Pour les instances du package Linux, configurez dans `/etc/gitlab/gitlab.rb` :

```ruby
nginx['proxy_set_headers'] = { 'X-GitLab-Show-Login-Captcha' => '1' }
```
