---
stage: Developer Experience
group: API Platform
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: "Documentation interactive de l'API"
description: "Utiliser OpenAPI pour tester l'API REST GitLab."
---

La [spécification OpenAPI](https://swagger.io/specification/) (anciennement appelée Swagger) définit une interface standard et indépendante du langage pour les API RESTful. Les fichiers de définition OpenAPI sont écrits au format YAML, qui est automatiquement rendu par le navigateur GitLab dans une interface plus lisible.

Pour des informations générales sur les API GitLab, voir [Étendre avec GitLab](../_index.md).

<!--
The following link is absolute rather than relative because it needs to be viewed through the GitLab
Open API file viewer: <https://docs.gitlab.com/user/project/repository/files/#render-openapi-files>.
-->
L'[outil de documentation interactive de l'API](https://gitlab.com/gitlab-org/gitlab/-/blob/master/doc/api/openapi/openapi_v3.yaml) permet de tester l'API directement sur le site GitLab.com. Seuls quelques-uns des endpoints disponibles sont documentés avec la spécification OpenAPI, mais la liste actuelle illustre les fonctionnalités de l'outil.

> [!note]
> La spécification OpenAPI 2.0 (`openapi_v2.yaml`) est obsolète et ne reçoit plus de mises à jour. Utilisez plutôt la spécification OpenAPI 3.0 (`openapi_v3.yaml`).

![Liste de certains endpoints disponibles de l'API GitLab.](img/apiviewer01_v19_0.png)

## Paramètres des endpoints {#endpoint-parameters}

Lorsque vous développez la liste d'un endpoint, vous voyez une description, les paramètres d'entrée (si nécessaire) et des exemples de réponses du serveur. Certains paramètres incluent une valeur par défaut ou une liste de valeurs autorisées.

![Vue développée affichant les informations de l'endpoint et l'option Essayer.](img/apiviewer04-fs8_v13_9.png)

## Démarrer une session interactive {#starting-an-interactive-session}

Un [jeton d'accès personnel](../../user/profile/personal_access_tokens.md) (PAT) est l'un des moyens de démarrer une session interactive. Pour ce faire, sélectionnez **Autoriser** depuis la page principale ; une boîte de dialogue vous invite à saisir votre PAT, qui est valide pour la session web en cours.

Pour tester l'endpoint, sélectionnez d'abord **Try it out** sur la page de définition de l'endpoint. Saisissez les paramètres requis, puis sélectionnez **Execute**. L'exemple suivant exécute une requête pour l'endpoint `version` (aucun paramètre requis). L'outil affiche la commande `curl` et l'URL de la requête, suivies des réponses du serveur renvoyées. Vous pouvez créer de nouvelles réponses en modifiant les paramètres concernés, puis sélectionner à nouveau **Execute**.

![Vue de test de l'endpoint incluant la requête et la réponse.](img/apiviewer03-fs8_v13_9.png)

## Vision {#vision}

Le code de l'API est la source de vérité unique, et la documentation de l'API doit être étroitement liée à son implémentation. La spécification OpenAPI fournit une méthode standardisée et complète pour documenter les API. Elle devrait être le format de référence pour documenter l'API REST GitLab. Cela se traduira par une documentation plus précise, fiable et conviviale, qui améliorera l'expérience globale d'utilisation de l'API REST GitLab.

Pour y parvenir, il devrait être obligatoire de mettre à jour la spécification OpenAPI à chaque modification du code de l'API. Cela garantit que la documentation est toujours à jour et précise, réduisant ainsi les risques de confusion et d'erreurs pour les utilisateurs.

La documentation OpenAPI devrait être générée automatiquement à partir du code de l'API, afin qu'il soit facile de la maintenir à jour et précise. Cela permettra de gagner du temps et des efforts pour notre équipe de documentation.

Vous pouvez suivre la progression actuelle de cette vision dans l'[epic Documenter l'API REST dans OpenAPI V2](https://gitlab.com/groups/gitlab-org/-/epics/8926).
