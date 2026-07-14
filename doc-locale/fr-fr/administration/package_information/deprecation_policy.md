---
stage: GitLab Delivery
group: Build
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Politique de dépréciation des paquets Linux
---

{{< details >}}

- Niveau : Free, Premium, Ultimate
- Offre : GitLab Self-Managed

{{< /details >}}

Les paquets Linux sont fournis avec un certain nombre de bibliothèques et de services différents qui offrent aux utilisateurs une multitude d'options de configuration.

À mesure que les bibliothèques et les services sont mis à jour, leurs options de configuration changent et deviennent obsolètes. Pour améliorer la maintenabilité et préserver une configuration fonctionnelle, différentes configurations nécessitent une suppression.

## Dépréciation de configuration {#configuration-deprecation}

### Politique {#policy}

Le paquet Linux conserve la configuration pendant au moins **une version majeure**. Nous ne pouvons pas garantir que la configuration dépréciée sera disponible dans la prochaine release majeure. Voir [l'exemple](#example) pour plus de détails.

### Avis {#notice}

Si la configuration devient obsolète, nous annonçons la dépréciation :

- via un article de blog de release sur `https://about.gitlab.com/blog/`. L'article de blog contient l'avis de dépréciation ainsi que la date de suppression cible.
- via la sortie de l'installation/reconfiguration (le cas échéant).
- via la documentation officielle sur `https://docs.gitlab.com/`. La mise à jour de la documentation contient la syntaxe corrigée (le cas échéant) ou une date de suppression de la configuration.

### Procédure {#procedure}

Cette section liste les étapes nécessaires à la dépréciation et à la suppression de la configuration.

Nous pouvons distinguer deux types de configuration différents :

- Sensible :  Configuration pouvant entraîner une panne de service majeure (comme l'intégrité des données, l'intégrité de l'installation, ou empêchant les utilisateurs d'accéder à l'installation)
- Régulière :  Configuration pouvant rendre une fonctionnalité indisponible mais laissant l'installation utilisable (comme un changement dans les paramètres par défaut du projet/groupe, ou une mauvaise communication avec d'autres composants)

Nous devons également différencier la procédure de dépréciation et de suppression.

#### Dépréciation de la configuration {#deprecating-configuration}

La procédure de dépréciation est similaire pour les configurations `sensitive` et `regular`. La seule différence réside dans la date cible de suppression.

Étapes communes :

1. Créez un ticket dans le [système de suivi des `omnibus-gitlab`](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues) avec les détails sur le type de dépréciation et toute autre information nécessaire. Appliquez le label `deprecation`.
1. Décidez de la cible de suppression pour la configuration dépréciée
1. Formulez l'avis de dépréciation pour chaque élément comme indiqué dans la [section Avis](#notice)

Cible de suppression :

Pour une configuration régulière, la cible de suppression doit toujours être la date de la prochaine release **next major**. Si la date n'est pas connue, vous pouvez faire référence à la prochaine version majeure.

Pour la configuration sensible, les choses sont un peu plus compliquées. Nous devons viser à ne pas supprimer la configuration sensible dans la prochaine release majeure si celle-ci est à 2 versions mineures de distance (ce nombre est choisi pour correspondre à notre politique de release de backport de sécurité).

Consultez le tableau ci-dessous pour quelques exemples :

| Type de configuration | Dépréciation annoncée | Dernière version mineure | Supprimer |
| -------- | -------- | -------- | -------- |
| Sensible | 10.1.0   | 10.9.0   | 11.0.0 |
| Sensible | 10.7.0   | 10.9.0   | 12.0.0 |
| Régulière | 10.1.0 | 10.9.0 | 11.0.0 |
| Régulière | 10.8.0 | 10.9.0 | 11.0.0 |

#### Suppression de la configuration {#removing-configuration}

Lorsque la dépréciation est annoncée et la cible de suppression définie, le jalon du ticket doit être modifié pour correspondre à la version cible de suppression.

Le commentaire final dans le ticket doit contenir :

- Un extrait de texte pour la section du blog de release.
- Un lien vers un merge request de documentation (ou un extrait de documentation) qui introduit le changement.
- L'un ou l'autre :
  - Un lien vers un merge request brouillon qui supprime la configuration.
  - Des détails sur ce qui doit être fait.

## Exemple {#example}

La configuration utilisateur disponible dans `/etc/gitlab/gitlab.rb` a été introduite dans GitLab version 10.0, `gitlab_rails['configuration'] = true`. Dans GitLab version 10.4.0, un nouveau changement a été introduit nécessitant le renommage de cette option de configuration. La nouvelle option de configuration est `gitlab_rails['better_configuration'] = true`. L'équipe de développement traduit l'ancienne configuration en une nouvelle et déclenche une procédure de dépréciation.

Cela signifie que ces deux options de configuration sont valides tout au long de GitLab version 10. En d'autres termes, si vous avez encore `gitlab_rails['configuration'] = true` défini dans GitLab 10.8.0, la fonctionnalité continue de fonctionner de la même manière que si vous aviez `gitlab_rails['better_configuration'] = true` défini. Cependant, définir l'ancienne version de la configuration affiche un avis de dépréciation à la fin de l'exécution de l'installation/mise à niveau/reconfiguration.

Dans GitLab 11, `gitlab_rails['configuration'] = true` ne fonctionne plus et vous devez modifier manuellement la configuration dans `/etc/gitlab/gitlab.rb` vers la nouvelle configuration valide. **Note** Si cette option de configuration est sensible et peut mettre en danger l'intégrité de l'installation ou des données, l'installation ou la mise à niveau est abandonnée.
