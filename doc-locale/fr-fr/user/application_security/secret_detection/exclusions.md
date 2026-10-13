---
stage: Application Security Testing
group: Secret Detection
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Exclusions de la détection des secrets
---

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Statut : version expérimentale

{{< /details >}}

{{< history >}}

- [Introduite](https://gitlab.com/groups/gitlab-org/-/epics/14878) en tant que [version expérimentale](../../../policy/development_stages_support.md) dans GitLab 17.5 [avec un feature flag](../../../administration/feature_flags/list.md) nommé `secret_detection_project_level_exclusions`. Activés par défaut.
- [Suppression](https://gitlab.com/gitlab-org/gitlab/-/issues/499059) du feature flag `secret_detection_project_level_exclusions` dans GitLab 17.7.

{{< /history >}}

La détection des secrets peut détecter quelque chose qui n'est pas réellement un secret. Par exemple, si vous utilisez une valeur fictive comme espace réservé dans votre code, elle pourrait être détectée et éventuellement bloquée.

Pour éviter les faux positifs et [optimiser les performances](secret_push_protection/_index.md#optimize-performance), vous pouvez exclure de la détection des secrets :

- Un chemin.
- Une valeur brute.
- Une règle de l'ensemble de règles par défaut.

Vous pouvez définir plusieurs exclusions pour un projet.

## Restrictions {#restrictions}

Les restrictions suivantes s'appliquent :

- Les exclusions ne peuvent être définies que pour chaque projet.
- Les exclusions s'appliquent uniquement à [la protection push de détection des secrets](secret_push_protection/_index.md).
- Le nombre maximum d'exclusions basées sur un chemin par projet est de 10.
- La profondeur maximale pour les exclusions basées sur un chemin est de 20.

<i class="fa-youtube-play" aria-hidden="true"></i> Pour une présentation générale, consultez [exclusions de la détection des secrets - démo](https://www.youtube.com/watch?v=vh_Uh4_4aoc).
<!-- Video published on 2024-10-12 -->

## Ajouter une exclusion {#add-an-exclusion}

Définissez une exclusion pour éviter les faux positifs de la détection des secrets.

Prérequis :

- Vous devez disposer du rôle Responsable sécurité, Chargé de maintenance ou Propriétaire pour le projet.

Pour définir une exclusion :

1. Dans la barre supérieure, sélectionnez **Rechercher ou accéder à**, puis recherchez votre projet ou votre groupe.
1. Dans la barre latérale gauche, sélectionnez **Sécurisation** > **Configuration de la sécurité**.
1. Faites défiler vers le bas jusqu'à **Protection push de détection des secrets**.
1. Activez le bouton bascule **Protection Push de détection des secrets**.
1. Sélectionnez **Configurer la détection de secret** ({{< icon name="settings" >}}).
1. Sélectionnez **Ajouter une exclusion** pour ouvrir le formulaire d'exclusion.
1. Saisissez les détails de l'exclusion, puis sélectionnez **Ajouter une exclusion**.

Les exclusions de chemins prennent en charge les motifs glob, qui sont supportés et interprétés avec la méthode Ruby [`File.fnmatch`](https://docs.ruby-lang.org/en/master/File.html#method-c-fnmatch) avec les [indicateurs](https://docs.ruby-lang.org/en/master/File/Constants.html#module-File::Constants-label-Filename+Globbing+Constants+-28File-3A-3AFNM_-2A-29) `File::FNM_PATHNAME | File::FNM_DOTMATCH | File::FNM_EXTGLOB`.

Les exclusions de règles prennent en charge l'un des identifiants répertoriés dans l'[ensemble de règles par défaut](https://gitlab.com/gitlab-org/security-products/secret-detection/secret-detection-rules). Par exemple, `gitlab_personal_access_token` est l'identifiant de règle pour les jetons d'accès personnels GitLab.
