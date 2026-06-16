---
stage: Security Risk Management
group: Security Platform Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Gestion des profils de configuration de sécurité
---

{{< details >}}

- Niveau :  Ultimate
- Offre :  GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [Introduit](https://gitlab.com/groups/gitlab-org/-/epics/19802) dans GitLab 18.9.

{{< /history >}}

Les profils de configuration de sécurité sont des paramètres centralisés qui définissent comment et quand les scanners de sécurité s'exécutent dans vos projets. Utilisez les profils de configuration de sécurité pour gérer efficacement les scanners de sécurité au sein de votre organisation. Une approche basée sur les profils applique les bonnes pratiques avec une configuration manuelle minimale.

<i class="fa-youtube-play" aria-hidden="true"></i> Pour une vue d'ensemble, consultez [Introducing security configuration profiles](https://www.youtube.com/watch?v=XYMKhhtRvwA).

Lorsque vous appliquez un profil à un groupe, il est appliqué à chaque projet individuel au sein de ce groupe. Les profils ne sont pas attachés au groupe lui-même, et il n'y a pas d'héritage entre les profils ou les sous-groupes.

Utilisez les [profils par défaut](#default-profiles) pour activer l'analyse de sécurité préconfigurée en quelques minutes et avec une configuration minimale.

## Configurer les scanners de sécurité {#configure-security-scanners}

Pour évaluer et gérer vos profils, utilisez l'[inventaire de sécurité](../security_inventory/_index.md#view-the-security-inventory) de votre groupe comme tableau de bord central.

### Examiner la couverture des tests {#review-test-coverage}

Pour afficher un statut de haut niveau (**Activé**, **Not Enabled** ou **Échec**) des scanners dans le groupe tels que SAST, DAST et la détection des secrets :

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et trouvez votre groupe.
1. Dans la barre latérale gauche, sélectionnez **Sécurisation** > **Inventaire de sécurité**.
1. Dans l'inventaire de sécurité, examinez la colonne **Test Coverage**.

### Modifier la couverture d'un projet individuel {#change-individual-project-coverage}

Pour configurer un projet spécifique :

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et trouvez votre groupe.
1. Dans la barre latérale gauche, sélectionnez **Sécurisation** > **Inventaire de sécurité**.
1. À côté du projet, sélectionnez les points de suspension verticaux ({{< icon name="ellipsis_v" >}}) et sélectionnez **Manage tool coverage**.
1. Activez ou désactivez les scanners individuellement.

### Appliquer un profil à plusieurs projets {#apply-a-profile-to-multiple-projects}

Pour gagner du temps, vous pouvez appliquer des paramètres de sécurité à plusieurs projets en même temps :

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et trouvez votre groupe.
1. Dans la barre latérale gauche, sélectionnez **Sécurisation** > **Inventaire de sécurité**.
1. Sélectionnez plusieurs projets ou un sous-groupe entier auxquels appliquer les paramètres.
1. Sélectionnez le menu déroulant **Bulk Action** et choisissez **Gérer les scanners de sécurité**.
1. Choisissez **Appliquer le profil par défaut à tous** pour standardiser votre posture de sécurité dans la sélection.

## Profils par défaut {#default-profiles}

GitLab fournit des profils par défaut qui sont des paramètres de scanner préconfigurés afin que vous puissiez activer l'analyse de sécurité avec une configuration minimale.

### Profil de détection des secrets {#secret-detection-profile}

Lorsque vous appliquez le profil de détection des secrets, vous activez la protection de référence recommandée pour les secrets dans l'ensemble de votre workflow de développement. Le profil active les déclencheurs d'analyse suivants :

- **Push protection** :  Analyse tous les événements Git push et bloque les push où des secrets sont détectés, empêchant les secrets d'entrer dans votre base de code.
- **Merge Request Pipelines** :  Exécute automatiquement une analyse chaque fois que de nouveaux commits sont poussés vers une branche avec un merge request ouvert. Les résultats sont limités aux nouvelles vulnérabilités introduites par le merge request. Cible toutes les branches.
- **Branch Pipelines (default only)** :  S'exécute automatiquement lorsque des modifications sont fusionnées ou poussées vers la branche par défaut, offrant une vue complète de la posture de détection des secrets de votre branche par défaut. Cible toutes les branches.

### Profil SAST {#sast-profile}

Lorsque vous appliquez le profil SAST, vous activez le test statique de sécurité des applications dans vos projets en utilisant la configuration recommandée. Le profil active les déclencheurs d'analyse suivants :

- **Merge Request Pipelines** :  Exécute automatiquement une analyse SAST chaque fois que de nouveaux commits sont poussés vers une branche avec un merge request ouvert. Les résultats incluent uniquement les nouvelles vulnérabilités introduites par le merge request. Cible toutes les branches.
- **Branch Pipelines (default only)** :  S'exécute automatiquement lorsque des modifications sont fusionnées ou poussées vers la branche par défaut, offrant une vue complète de la posture SAST de votre branche par défaut. Cible la branche par défaut.

### Afficher les détails d'un profil {#view-details-about-a-profile}

Pour afficher les détails techniques concernant le profil de détection des secrets :

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et trouvez votre groupe.
1. Dans la barre latérale gauche, sélectionnez **Sécurisation** > **Inventaire de sécurité**.
1. Sélectionnez le profil **Détection de secret**.
1. Examinez les informations suivantes :
   - **Type d'analyseur** :  Le type de profil (par exemple, **Détection de secret**, **SAST**).
   - **Déclencheurs d'analyse** :  Les déclencheurs que le profil prend en charge (par exemple, **Push Protection**, **Merge Request Pipelines**, **Branch Pipelines**).
   - **Statut** :  Indique si le profil est actuellement **Actif** ou **Désactivé** pour le contexte actuel à l'aide d'indicateurs de statut de couverture.

## Indicateurs de statut de couverture {#coverage-status-indicators}

Le système utilise des repères visuels dans l'inventaire pour indiquer si vos projets sont protégés :

- **Solid green bar** :  Le scanner est entièrement activé et actif.
- **Gray/empty bar** :  Le scanner n'est pas encore configuré ou activé.
- **Partial bar** :  Une partie de la protection est active (par exemple, certains déclencheurs disponibles dans le profil sont activés, mais d'autres ne le sont pas).
- **Tooltips** :  Survolez n'importe quelle barre de couverture pour voir la date de **last scan** pour les analyses basées sur les pipelines et le statut spécifique du pipeline.

Contrairement aux analyses basées sur les pipelines, la protection push n'a pas de date de dernière analyse car elle s'exécute en temps réel pendant le processus de push.

## Dépannage {#troubleshooting}

Lorsque vous travaillez avec des profils de configuration de sécurité, vous pouvez rencontrer les problèmes suivants.

### Aucune date de dernière analyse n'apparaît pour la protection push {#no-last-scan-date-appears-for-push-protection}

La protection push est basée sur les événements, et non sur une planification. Elle intercepte les secrets en temps réel pendant le processus `git push`. Étant donné qu'elle est active au moment de la commande `push`, il n'y a pas de date de dernière analyse comme vous pourriez en attendre avec des scanners basés sur les pipelines.

### Le statut du scanner est actif dans le tableau de bord mais n'est pas activé dans l'infobulle de l'inventaire {#scanner-status-is-active-in-the-dashboard-but-not-enabled-in-inventory-tooltip}

Cela peut se produire lorsqu'un projet utilise des paramètres hérités tout en se voyant attribuer un nouveau profil.

Pour résoudre ce problème :

1. Vérifiez la page **Security Configuration** pour obtenir l'état de profil actuel le plus précis.
1. Si nécessaire, supprimez les configurations de scanner héritées de votre fichier `.gitlab-ci.yml` pour vous reposer uniquement sur la configuration basée sur les profils.

> [!note]
> L'infobulle de l'inventaire est en cours d'amélioration afin de refléter le statut combiné des paramètres hérités et basés sur les profils.

### Comprendre la configuration héritée par rapport à la configuration basée sur les profils {#understanding-legacy-versus-profile-based-configuration}

Si vous migrez d'une configuration de scanner héritée vers une configuration basée sur les profils, notez les différences suivantes :

- Configuration héritée :  Nécessite des modifications manuelles de vos fichiers YAML ou des paramètres de projet individuels pour activer les scanners.
- Configuration basée sur les profils :  Utilise un système centralisé qui vous permet d'appliquer un profil par défaut à plusieurs projets en même temps sans modifier le code.

La configuration basée sur les profils est recommandée pour une gestion plus facile et une meilleure cohérence entre les projets.
