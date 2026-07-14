---
stage: Developer Experience
group: Performance Enablement
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
gitlab_dedicated: yes
title: Barre de performance
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

La barre de performance affiche des métriques en temps réel directement dans votre navigateur, vous fournissant des informations sans avoir à parcourir les journaux ou à exécuter des outils de profilage distincts.

Pour les équipes de développement, la barre de performance simplifie le débogage en indiquant exactement où elles doivent concentrer leurs efforts.

![Barre de performance](img/performance_bar_v14_4.png)

## Informations disponibles {#available-information}

{{< history >}}

- Les appels Rugged ont été [supprimés](https://gitlab.com/gitlab-org/gitlab/-/issues/421591) dans GitLab 16.6.

{{< /history >}}

De gauche à droite, la barre de performance affiche :

- **Hôte actuel** : l'hôte actuel qui sert la page.
- **Requêtes de base de données** : le temps pris (en millisecondes) et le nombre total de requêtes de base de données, affiché au format `00ms / 00 (00 cached) pg`. Sélectionnez pour afficher une boîte de dialogue avec plus de détails. Vous pouvez l'utiliser pour voir les détails suivants pour chaque requête :
  - **Dans une transaction** : s'affiche sous la requête si elle a été exécutée dans le contexte d'une transaction.
  - **Rôle** : s'affiche lorsque [Répartition de charge de base de données](../../postgresql/database_load_balancing.md) est activé. Il indique quel rôle de serveur a été utilisé pour la requête. « Primary » signifie que la requête a été envoyée au serveur primaire en lecture/écriture. « Replica » signifie qu'elle a été envoyée à un réplica en lecture seule.
  - **Nom de la configuration** : utilisé pour distinguer les différentes bases de données configurées pour différentes fonctionnalités de GitLab. Le nom affiché est le même que celui utilisé pour configurer les connexions à la base de données dans GitLab.
- **Appels Gitaly** : le temps pris (en millisecondes) et le nombre total d'appels [Gitaly](../../gitaly/_index.md). Sélectionnez pour afficher une boîte de dialogue avec plus de détails.
- **Appels Redis** : le temps pris (en millisecondes) et le nombre total d'appels Redis. Sélectionnez pour afficher une boîte de dialogue avec plus de détails.
- **Appels Elasticsearch** : le temps pris (en millisecondes) et le nombre total d'appels Elasticsearch. Sélectionnez pour afficher une boîte de dialogue avec plus de détails.
- **Appels HTTP externes** : le temps pris (en millisecondes) et le nombre total d'appels externes vers d'autres systèmes. Sélectionnez pour afficher une boîte de dialogue avec plus de détails.
- **Temps de chargement** de la page : si votre navigateur prend en charge les temps de chargement, plusieurs valeurs en millisecondes, séparées par des barres obliques. Sélectionnez pour afficher une boîte de dialogue avec plus de détails. Les valeurs, de gauche à droite :
  - **Backend** : temps nécessaire au chargement de la page de base.
  - [**First Contentful Paint**](https://developer.chrome.com/docs/lighthouse/performance/first-contentful-paint/) : Temps jusqu'à ce que quelque chose soit visible pour l'utilisateur. Affiche `NaN` si votre navigateur ne prend pas en charge cette fonctionnalité.
  - Événement [**DomContentLoaded**](https://web.dev/articles/critical-rendering-path/measure-crp).
  - **Nombre total de requêtes** chargées par la page.
- **Mémoire** : la quantité de mémoire consommée et les objets alloués pendant la requête sélectionnée. Sélectionnez-la pour afficher une fenêtre avec plus de détails.
- **Trace** : si Jaeger est intégré, **Trace** renvoie vers une page de traçage Jaeger avec le `correlation_id` de la requête en cours inclus.
- **+** : un lien pour ajouter les détails d'une requête à la barre de performance. La requête peut être ajoutée par son URL complète (authentifiée en tant qu'utilisateur actuel), ou par la valeur de son en-tête `X-Request-Id`.
- **Télécharger** : un lien pour télécharger le JSON brut utilisé pour générer les rapports de la barre de performance.
- **Rapport de mémoire** : un lien qui génère un rapport de profilage mémoire de l'URL actuelle.
- **Flamegraph** avec mode : un lien pour générer un flamegraph de l'URL actuelle avec le [mode Stackprof](https://github.com/tmm1/stackprof#sampling) sélectionné :
  - Le mode **Mur** échantillonne à chaque intervalle de temps sur une horloge murale. L'intervalle est défini à `10100` microsecondes.
  - Le mode **CPU** échantillonne à chaque intervalle d'activité CPU. L'intervalle est défini à `10100` microsecondes.
  - Le mode **Objet** échantillonne à chaque intervalle. L'intervalle est défini à `100` allocations.
- **Sélecteur de requêtes** : une liste de sélection affichée sur le côté droit de la barre de performance qui vous permet de visualiser ces métriques pour toutes les requêtes effectuées pendant que la page actuelle était ouverte. Seules les deux premières requêtes par URL unique sont capturées.
- **Statistiques** (optionnel) : si la variable d'environnement `GITLAB_PERFORMANCE_BAR_STATS_URL` est définie, cette URL est affichée dans la barre. Utilisé uniquement sur GitLab.com.

> [!note]
> Tous les indicateurs ne sont pas disponibles dans tous les environnements. Par exemple, la vue mémoire nécessite d'exécuter Ruby avec des [correctifs spécifiques](https://gitlab.com/gitlab-org/gitlab-build-images/-/blob/master/patches/ruby/2.7.4/thread-memory-allocations-2.7.patch) appliqués. Lors de l'exécution de GitLab localement à l'aide du [GDK](https://gitlab.com/gitlab-org/gitlab-development-kit), ce n'est généralement pas le cas et la vue mémoire ne peut pas être utilisée.

## Raccourci clavier {#keyboard-shortcut}

Appuyez sur le [raccourci clavier <kbd>p</kbd> + <kbd>b</kbd>](../../../user/shortcuts.md) pour afficher la barre de performance, et à nouveau pour la masquer.

Pour que les non-administrateurs puissent afficher la barre de performance, elle doit être [activée pour eux](#enable-the-performance-bar-for-non-administrators).

## Avertissements de requêtes {#request-warnings}

Les requêtes qui dépassent les limites prédéfinies affichent une icône d'avertissement {{< icon name="warning" >}} et une explication à côté de la métrique. Dans cet exemple, la durée de l'appel Gitaly a dépassé le seuil.

![Durée de l'appel Gitaly dépassant le seuil](img/performance_bar_gitaly_threshold_v12_4.png)

## Activer la barre de performance pour les non-administrateurs {#enable-the-performance-bar-for-non-administrators}

La barre de performance est désactivée par défaut pour les non-administrateurs. Pour l'activer pour un groupe donné :

1. Connectez-vous en tant qu'utilisateur disposant d'un accès administrateur.
1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Statistiques et rapports**.
1. Développez **Profilage - barre de performance**.
1. Sélectionnez **Autoriser les non-administrateurs à accéder à la barre de performance**.
1. Dans le champ **Autoriser l'accès aux membres du groupe suivant**, indiquez le chemin complet du groupe autorisé à accéder à la performance.
1. Sélectionnez **Sauvegarder les modifications**.
