---
stage: Application Security Testing
group: Secret Detection
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Protection push de détection des secrets
---

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/11439) dans GitLab 16.7 en tant que [version expérimentale](../../../../policy/development_stages_support.md) pour les clients GitLab Dedicated.
- [Changed](https://gitlab.com/groups/gitlab-org/-/epics/12729) en version bêta et rendue disponible sur GitLab.com dans GitLab 17.1.
- [Enabled on GitLab Self-Managed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/156907) dans GitLab 17.2 [with feature flags](../../../../administration/feature_flags/_index.md) nommés `pre_receive_secret_detection_beta_release` et `pre_receive_secret_detection_push_check`.
- Le feature flag `pre_receive_secret_detection_beta_release` a été [removed](https://gitlab.com/gitlab-org/gitlab/-/issues/472418) dans GitLab 17.4.
- [Generally available](https://gitlab.com/groups/gitlab-org/-/epics/13107) dans GitLab 17.5.
- [Suppression](https://gitlab.com/gitlab-org/gitlab/-/issues/472419) du feature flag `pre_receive_secret_detection_push_check` dans GitLab 17.7.

{{< /history >}}

La protection push de détection des secrets empêche les secrets tels que les clés et les jetons API d'être poussés vers GitLab.

<i class="fa-youtube-play" aria-hidden="true"></i> Pour une présentation générale, consultez la playlist [Get Started with Secret Push Protection](https://www.youtube.com/playlist?list=PL05JrBw4t0KoADm-g2vxfyR0m6QLphTv-).

Utilisez la détection des secrets de pipeline avec la protection push de détection des secrets pour renforcer davantage votre sécurité.

## Workflow de la protection push de détection des secrets {#secret-push-protection-workflow}

La protection push de détection des secrets s'effectue dans le hook de pré-réception. Lorsque vous poussez des modifications vers GitLab, la protection push vérifie la présence de secrets dans chaque fichier ou commit. Par défaut, si un secret est détecté, le push est bloqué.

<!-- To edit the diagram, use either Draw.io or the VS Code extension "Draw.io Integration" -->
![Organigramme montrant comment la protection des secrets peut bloquer un push](img/spp_workflow_v17_9.drawio.svg)

Lorsqu'un push est bloqué, GitLab affiche un message qui comprend :

- L'ID du commit contenant le secret.
- Le nom du fichier et la ligne contenant le secret.
- Le type de secret.

Par exemple, voici un extrait du message renvoyé lorsqu'un push utilisant le client Git CLI est bloqué. Lorsque vous utilisez d'autres clients, y compris le Web IDE GitLab, le format du message est différent, mais le contenu est identique.

```plain
remote: PUSH BLOCKED: Secrets detected in code changes
remote: Secret push protection found the following secrets in commit: 37e54de5e78c31d9e3c3821fd15f7069e3d375b6
remote:
remote: -- test.txt:2 GitLab Personal Access Token
remote:
remote: To push your changes you must remove the identified secrets.
```

Si la protection push de détection des secrets ne détecte aucun secret dans vos commits, aucun message n'est affiché.

## Secrets détectés {#detected-secrets}

La protection push de détection des secrets analyse les fichiers ou les commits à la recherche de motifs spécifiques. Chaque motif correspond à un type de secret spécifique. Pour confirmer quels secrets sont détectés par la protection push de détection des secrets, consultez [les secrets détectés](../detected_secrets.md). Seuls les motifs à haute confiance ont été retenus pour la protection push de détection des secrets, afin de minimiser le délai lors du push de vos commits et de réduire le nombre de fausses alertes. Par exemple, les jetons d'accès personnels utilisant un préfixe personnalisé ne sont pas détectés par la protection push de détection des secrets. Vous pouvez [exclure](../exclusions.md) certains secrets de la détection par la protection push de détection des secrets.

## Premiers pas {#getting-started}

Sur les instances GitLab Dedicated et GitLab Self-Managed, vous devez :

1. Autoriser la protection push de détection des secrets sur l'ensemble de l'instance.
1. Activer la protection push de détection des secrets. Vous pouvez soit :
   - Activer la protection push de détection des secrets dans un projet spécifique.
   - Utiliser l'API pour activer la protection push de détection des secrets pour tous les projets d'un groupe.

### Autoriser l'utilisation de la protection push de détection des secrets dans votre instance GitLab {#allow-the-use-of-secret-push-protection-in-your-gitlab-instance}

Sur les instances GitLab Dedicated et GitLab Self-Managed, vous devez autoriser la protection push de détection des secrets avant de pouvoir l'activer dans un projet.

Prérequis :

- Vous devez être administrateur de votre instance GitLab.

Pour autoriser l'utilisation de la protection push de détection des secrets dans votre instance GitLab :

1. Connectez-vous à votre instance GitLab en tant qu'administrateur.
1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Sécurité et conformité**.
1. Sous **Détection de secret**, cochez ou décochez **Allow secret push protection**.

La protection push de détection des secrets est autorisée sur l'instance. Pour utiliser cette fonctionnalité, vous devez l'activer par projet.

### Activer la protection push de détection des secrets dans un projet {#enable-secret-push-protection-in-a-project}

Prérequis :

- Vous devez disposer du rôle Responsable sécurité, Maintainer ou Owner pour le projet.
- Sur GitLab Dedicated et GitLab Self-Managed, vous devez autoriser la protection push de détection des secrets sur l'instance.

Pour activer la protection push de détection des secrets dans un projet :

1. Dans la barre supérieure, sélectionnez **Rechercher ou accéder à** et repérez votre projet.
1. Dans la barre latérale gauche, sélectionnez **Sécurisation** > **Configuration de la sécurité**.
1. Activez le bouton bascule **Protection push de détection des secrets**.

Vous pouvez également activer la protection push de détection des secrets pour tous les projets d'un groupe [avec l'API](../../../../api/group_security_settings.md#update-group-security-settings).

## Couverture {#coverage}

{{< history >}}

- [Changed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/185882) vers une analyse des diffs uniquement dans GitLab 17.11.

{{< /history >}}

La protection push de détection des secrets ne bloque pas un secret dans les cas suivants :

- Vous utilisez l'option pour ignorer la protection push de détection des secrets lors du push des commits.
- Le secret est exclu de la protection push de détection des secrets.
- Le secret se trouve dans un chemin défini comme une [exclusion](../exclusions.md).

La protection push de détection des secrets ne vérifie pas un fichier dans un commit dans les cas suivants :

- Le fichier est un fichier binaire.
- Le fichier ou le patch de diff dépasse 1 Mio.
- Le fichier est renommé, supprimé ou déplacé sans modification du contenu.
- Le contenu du fichier est identique au contenu d'un autre fichier dans le code source.
- Le fichier est inclus dans le push initial ayant créé le dépôt.
- Le push contient plus de 350 000 lignes modifiées au total.

### Analyse des diffs {#diff-scanning}

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/469161) dans GitLab 17.5 [with a feature flag](../../../../administration/feature_flags/_index.md) nommé `spp_scan_diffs`. Désactivées par défaut.
- [Enabled on GitLab.com](https://gitlab.com/gitlab-org/gitlab/-/issues/480092) dans GitLab 17.6.
- [Added](https://gitlab.com/gitlab-org/gitlab/-/issues/491282) la prise en charge des pushs depuis le Web IDE dans GitLab 17.10 [with a feature flag](../../../../administration/feature_flags/_index.md) nommé `secret_checks_for_web_requests`. Désactivées par défaut.
- [Passage en disponibilité générale](https://gitlab.com/gitlab-org/gitlab/-/issues/525627) dans GitLab 17.11. Suppression du feature flag `spp_scan_diffs`.
- [Removed](https://gitlab.com/gitlab-org/gitlab/-/issues/525629) le feature flag `secret_checks_for_web_requests` dans GitLab 17.11.

{{< /history >}}

La protection push de détection des secrets analyse uniquement les diffs des commits poussés via HTTP(S) et SSH. Si un secret est déjà présent dans un fichier et ne fait pas partie des modifications, il n'est pas détecté.

## Événements d'audit {#audit-events}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/work_items/604787) dans GitLab 19.3.

{{< /history >}}

Les [événements d'audit](../../../compliance/audit_event_types.md#secret-detection) sont journalisés dans les cas suivants :

- La protection push de détection des secrets est ignorée car un push contient [trop de chemins modifiés](#push-size-threshold).
- La protection push de détection des secrets est ignorée car un push [modifie trop de lignes](#push-size-threshold).
- Le délai d'expiration de l'analyse de la protection push de détection des secrets se produit et GitLab accepte le push.
- La protection push de secrets rencontre une erreur d'analyse ou de compilation de l'ensemble de règles.
- La protection push de détection des secrets est ignorée car l'analyse a reçu une entrée invalide.
- La protection push de détection des secrets rencontre une erreur d'analyse inattendue.

## Seuil de taille du push {#push-size-threshold}

La protection push de détection des secrets est ignorée lorsqu'un push modifie plus de 3 150 chemins ou 350 000 lignes. Les seuils s'appliquent uniquement aux fichiers analysés par la protection push de détection des secrets (après exclusion des chemins définis dans les [exclusions](../exclusions.md)). Ces seuils évitent les délais d'expiration de push lorsque vous poussez des ensembles de modifications volumineux.

## Comprendre les résultats {#understanding-the-results}

La protection push de détection des secrets peut identifier différentes catégories de secrets :

- Clés et jetons API : informations d'authentification spécifiques à un service
- Chaînes de connexion aux bases de données : URL contenant des informations d'identification intégrées
- Clés privées : clés cryptographiques pour l'authentification ou le chiffrement
- Chaînes à haute entropie génériques : motifs qui semblent être des secrets générés aléatoirement

Lorsqu'un push est bloqué, la protection push de détection des secrets fournit des informations détaillées pour vous aider à localiser et à traiter les secrets détectés :

- ID du commit : le commit spécifique contenant le secret. Utile pour suivre les modifications dans votre historique Git.
- Chemin du fichier et numéro de ligne : l'emplacement exact du motif détecté pour une navigation rapide.
- Type de secret : la classification du motif détecté. Par exemple, `GitLab Personal Access Token` ou `AWS Access Key`.

### Catégories de détection courantes {#common-detection-categories}

Toutes les détections ne nécessitent pas une action immédiate. Tenez compte des éléments suivants lors de l'évaluation des résultats :

- Vrais positifs : véritables secrets qui doivent être renouvelés et supprimés. Par exemple :
  - Clés ou jetons API valides
  - Informations d'identification de base de données de production
  - Clés cryptographiques privées
  - Toute information d'identification susceptible d'accorder un accès non autorisé
- Faux positifs : modèles détectés qui ne sont pas de véritables secrets. Par exemple :
  - Données de test ressemblant à des secrets mais n'ayant aucune valeur réelle
  - Valeurs de remplacement dans les modèles de configuration
  - Exemples d'informations d'identification dans la documentation
  - Valeurs de hachage ou sommes de contrôle correspondant à des motifs de secrets

Documentez les motifs de faux positifs courants dans votre organisation afin de simplifier les évaluations futures.

## Optimisation {#optimization}

Avant de déployer largement la protection push de détection des secrets, optimisez la configuration pour réduire les faux positifs et améliorer la précision pour votre environnement spécifique.

### Réduire les faux positifs {#reduce-false-positives}

Les faux positifs peuvent avoir un impact significatif sur la productivité des développeurs et entraîner une fatigue liée à la sécurité.

Pour réduire les faux positifs :

- [Configurez les exclusions](../exclusions.md) de manière stratégique :
  - Créez des exclusions basées sur les chemins pour les répertoires de test, la documentation et les dépendances tierces.
  - Utilisez des exclusions basées sur des motifs pour les faux positifs connus spécifiques à votre base de code.
  - Documentez vos règles d'exclusion et révisez-les régulièrement.
- Créez des standards pour les valeurs de remplacement et les informations d'identification de test, qui doivent correspondre à vos règles d'exclusion, mais pas à l'[ensemble de règles par défaut](../detected_secrets.md).
- Surveillez les taux de faux positifs et continuez à ajuster les exclusions en conséquence.

### Optimiser les performances {#optimize-performance}

Les dépôts volumineux ou les pushs fréquents peuvent avoir un impact sur les performances.

Pour optimiser les performances de la protection push de détection des secrets :

- Surveillez les temps de push et établissez des métriques de référence avant le déploiement.
- Tenez compte des limites de taille de fichier pour les dépôts contenant des ressources binaires volumineuses.
- [Implémentez des exclusions](../exclusions.md#add-an-exclusion) pour les répertoires peu susceptibles de contenir des secrets.

### Intégration avec les workflows existants {#integration-with-existing-workflows}

Assurez-vous que la protection push de détection des secrets complète vos pratiques de développement existantes :

- Configurez la détection des secrets de pipeline et la protection push de détection des secrets pour garantir une défense en profondeur.
- Mettez à jour la documentation des développeurs pour inclure les procédures de la protection push de détection des secrets.
- Alignez-vous sur la formation à la sécurité pour sensibiliser les développeurs aux pratiques de codage sécurisé afin de minimiser les fuites de secrets.

## Déploiement {#roll-out}

Le déploiement réussi de la protection push de détection des secrets à grande échelle nécessite une planification rigoureuse et une mise en œuvre par phases :

1. Choisissez deux ou trois projets non critiques avec un développement actif pour tester la fonctionnalité et comprendre son impact sur les workflows des développeurs.
1. Activez la protection push de détection des secrets pour vos projets de test sélectionnés et surveillez les retours des développeurs.
1. Documentez les processus de traitement des pushs bloqués et formez vos équipes de développement aux nouveaux workflows.
1. Suivez le nombre de secrets détectés, les taux de faux positifs et les retours sur l'expérience des développeurs pendant la phase pilote.

Vous devriez exécuter la phase pilote pendant deux à quatre semaines afin de collecter suffisamment de données et d'identifier les ajustements de workflow nécessaires avant un déploiement plus large.

Une fois le pilote terminé, envisagez les phases suivantes pour un déploiement à grande échelle :

1. Premiers adoptants (semaines 3-6)
   - Activez sur 10 à 20 % des projets actifs, en priorisant les dépôts sensibles en matière de sécurité.
   - Concentrez-vous sur les équipes ayant une forte sensibilisation à la sécurité et une adhésion solide.
   - Surveillez les impacts sur les performances et l'expérience des développeurs.
   - Affinez les processus en fonction de l'utilisation réelle.
1. Déploiement élargi (semaines 7-12)
   - Activez progressivement sur les projets restants par lots.
   - Fournissez un support et une formation continus aux équipes de développement.
   - Surveillez les performances du système et faites évoluer l'infrastructure si nécessaire.
   - Continuez à optimiser les règles d'exclusion en fonction des schémas d'utilisation.
1. Couverture complète (semaines 13-16)
   - Activez la protection push de détection des secrets sur tous les projets restants.
   - Établissez des processus de maintenance et de révision continus.
   - Mettez en place des audits réguliers des règles d'exclusion et des motifs détectés.

## Résoudre un push bloqué {#resolve-a-blocked-push}

Lorsque la protection push de détection des secrets bloque un push, vous pouvez soit :

- [Supprimer le secret](../remove_secrets_tutorial.md).
- Ignorer la protection push de détection des secrets.

### Ignorer la protection push de détection des secrets {#skip-secret-push-protection}

Dans certains cas, il peut être nécessaire d'ignorer la protection push de détection des secrets. Par exemple, un développeur peut avoir besoin de pousser un secret de remplacement à des fins de test, ou un utilisateur peut souhaiter ignorer la protection push de détection des secrets en raison d'un délai d'expiration d'une opération Git.

Les événements d'audit sont journalisés lorsque la protection push de détection des secrets est ignorée. Les détails de l'événement d'audit comprennent :

- La méthode d'omission utilisée.
- Le nom du compte GitLab.
- La date et l'heure auxquelles la protection push de détection des secrets a été ignorée.
- Le nom du projet vers lequel le secret a été poussé.
- La branche cible. (Introduit dans GitLab 17.4)
- Les commits ayant ignoré la protection push de détection des secrets. (Introduit dans GitLab 17.9)

Si la détection des secrets de pipeline est activée, le contenu de tous les commits est analysé après leur push vers le dépôt.

Pour ignorer la protection push de détection des secrets pour tous les commits d'un push, soit :

- Si vous utilisez le client Git CLI, demandez à Git d'ignorer la protection push de détection des secrets.
- Si vous utilisez un autre client, ajoutez `[skip secret push protection]` dans l'un des messages de commit.

#### Pour le client Git CLI {#for-the-git-cli-client}

Pour ignorer la protection push de détection des secrets depuis la ligne de commande :

- Utilisez l'option de push `secret_push_protection.skip_all`.

  Par exemple, vous avez plusieurs commits dont le push est bloqué parce que l'un d'eux contient un secret. Pour ignorer la protection push de détection des secrets, ajoutez l'option de push à la commande Git.

  ```shell
  git push -o secret_push_protection.skip_all
  ```

#### Pour tout client Git {#for-any-git-client}

Pour ignorer la protection push de détection des secrets :

- Ajoutez `[skip secret push protection]` dans l'un des messages de commit, sur une ligne existante ou sur une nouvelle ligne, puis poussez les commits.

  Par exemple, vous utilisez le Web IDE GitLab et avez plusieurs commits dont le push est bloqué parce que l'un d'eux contient un secret. Pour ignorer la protection push de détection des secrets, modifiez le dernier message de commit et ajoutez `[skip secret push protection]`, puis poussez les commits.

## Dépannage {#troubleshooting}

Lorsque vous travaillez avec la protection push de détection des secrets, vous pouvez rencontrer les situations suivantes.

### Push bloqué de manière inattendue {#push-blocked-unexpectedly}

Avant GitLab 17.11, la protection push de détection des secrets analysait le contenu de tous les fichiers modifiés. Cela peut entraîner le blocage inattendu d'un push si un fichier modifié contient un secret, même si ce secret ne fait pas partie du diff.

Sur GitLab 17.10 et versions antérieures, activez le feature flag `spp_scan_diffs` pour vous assurer que seules les modifications nouvellement validées sont analysées. Pour pousser une modification depuis le Web IDE vers un fichier contenant un secret, vous devez également activer le feature flag `secret_checks_for_web_requests`.

### Le fichier n'a pas été analysé {#file-was-not-scanned}

Certains fichiers sont exclus de l'analyse. Pour plus de détails, consultez la [couverture](#coverage).
