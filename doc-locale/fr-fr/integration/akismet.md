---
stage: Software Supply Chain Security
group: Authorization
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Akismet
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

GitLab utilise [Akismet](https://akismet.com/) pour empêcher la création de tickets indésirables dans les projets publics. Les tickets créés via l'interface utilisateur web ou l'API peuvent être soumis à Akismet pour examen, et les administrateurs d'instance peuvent [marquer des extraits comme indésirables](../user/snippets.md#mark-snippet-as-spam).

Le spam détecté est rejeté et une entrée est ajoutée dans la section **Spam log** de la zone **Admin**.

Note de confidentialité : GitLab transmet l'adresse IP de l'utilisateur et son agent utilisateur à Akismet.

> [!note]
> GitLab soumet tous les tickets à Akismet.

La configuration d'Akismet est disponible pour les utilisateurs de GitLab Self-Managed. Akismet est déjà activé sur GitLab.com, où sa configuration et sa gestion sont assurées par GitLab Inc.

## Configurer Akismet {#configure-akismet}

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Pour utiliser Akismet :

1. Accédez à la [page de connexion Akismet](https://akismet.com/account/).
1. Connectez-vous ou créez un nouveau compte.
1. Sélectionnez **Afficher** pour révéler la clé API, puis copiez sa valeur.
1. Connectez-vous à GitLab en tant qu'administrateur.
1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Rapports**.
1. Déroulez **Protection anti‐spam et anti‐robot**.
1. Cochez la case **Activer Akismet**.
1. Saisissez la clé API obtenue à l'étape 3.
1. Enregistrez la configuration.

## Entraîner le filtre Akismet {#train-the-akismet-filter}

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Pour mieux différencier le spam du contenu légitime, vous pouvez entraîner le filtre Akismet à chaque fois qu'un faux positif ou un faux négatif est détecté.

Lorsqu'une entrée est identifiée comme spam, elle est rejetée et ajoutée aux journaux des spams. Depuis cet emplacement, vous pouvez vérifier si les entrées sont réellement du spam. Si l'une d'elles n'est pas réellement du spam, sélectionnez **Soumettre comme acceptable** pour indiquer à Akismet qu'il a identifié à tort une entrée comme spam.

Si une entrée qui est réellement du spam n'a pas été identifiée comme telle, utilisez **Soumettre comme indésirable** pour transmettre cette information à Akismet. Le bouton **Soumettre comme indésirable** est uniquement affiché aux utilisateurs administrateurs.

Entraîner Akismet l'aide à identifier le spam plus précisément à l'avenir.
