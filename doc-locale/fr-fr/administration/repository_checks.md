---
stage: Tenant Scale
group: Gitaly
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
gitlab_dedicated: yes
title: Vérifications de dépôt
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Vous pouvez utiliser [`git fsck`](https://git-scm.com/docs/git-fsck) pour vérifier l'intégrité de toutes les données validées dans un dépôt. Les administrateurs GitLab peuvent :

- [Déclencher manuellement cette vérification pour un projet](#check-a-projects-repository-using-gitlab-ui).
- [Planifier cette vérification](#enable-repository-checks-for-all-projects) pour qu'elle s'exécute automatiquement pour tous les projets.
- [Exécuter cette vérification depuis la ligne de commande](#run-a-check-using-the-command-line).
- Exécuter une [tâche Rake](raketasks/check.md#repository-integrity) pour vérifier les dépôts Git, qui peut être utilisée pour exécuter `git fsck` sur tous les dépôts et générer des sommes de contrôle de dépôt, afin de comparer les dépôts sur différents serveurs.

Les vérifications qui ne sont pas exécutées manuellement sur la ligne de commande sont effectuées via un nœud Gitaly. Pour en savoir plus sur les vérifications de cohérence des dépôts Gitaly, certaines vérifications désactivées et la façon de configurer les vérifications de cohérence, consultez [Vérifications de cohérence des dépôts](gitaly/consistency_checks.md).

## Vérifier le dépôt d'un projet via l'interface utilisateur GitLab {#check-a-projects-repository-using-gitlab-ui}

Pour vérifier le dépôt d'un projet via l'interface utilisateur GitLab :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Vue d'ensemble** > **Projets**.
1. Sélectionnez le projet à vérifier.
1. Dans la section **Vérification du dépôt**, sélectionnez **Déclencher la vérification du dépôt**.

Les vérifications s'exécutent de manière asynchrone, il peut donc s'écouler quelques minutes avant que le résultat de la vérification soit visible sur la page du projet dans la zone **Admin**. Si les vérifications échouent, consultez [la marche à suivre](#what-to-do-if-a-check-failed).

## Exécuter une vérification depuis la ligne de commande {#enable-repository-checks-for-all-projects}

Au lieu de vérifier les dépôts manuellement, GitLab peut être configuré pour exécuter les vérifications périodiquement :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Dépôt**.
1. Développez **Maintenance du dépôt**.
1. Activez **Activer les vérifications de dépôt**.

Lorsqu'elle est activée, GitLab exécute périodiquement une vérification de dépôt sur tous les dépôts de projets et les dépôts wiki pour détecter d'éventuelles corruptions de données. Un projet est vérifié au maximum une fois par mois, et les nouveaux projets ne sont pas vérifiés pendant au moins 24 heures.

Les administrateurs GitLab Self-Managed peuvent configurer la fréquence des vérifications de dépôt. Pour modifier la fréquence :

- Pour les installations de packages Linux, modifiez `gitlab_rails['repository_check_worker_cron']` dans `/etc/gitlab/gitlab.rb`.
- Pour les installations basées sur les sources, modifiez `[gitlab.cron_jobs.repository_check_worker]` dans `/home/git/gitlab/config/gitlab.yml`.

Si des projets échouent à leurs vérifications de dépôt, tous les administrateurs GitLab reçoivent une notification par e-mail de la situation. Par défaut, cette notification est envoyée une fois par semaine à minuit au début du dimanche.

Les dépôts présentant des échecs de vérification connus peuvent être trouvés à l'adresse `/admin/projects?last_repository_check_failed=true`.

## Exécuter une vérification depuis la ligne de commande {#run-a-check-using-the-command-line}

{{< details >}}

- Offre : GitLab Self-Managed

{{< /details >}}

Vous pouvez exécuter [`git fsck`](https://git-scm.com/docs/git-fsck) depuis la ligne de commande sur les dépôts des [serveurs Gitaly](gitaly/_index.md). Pour localiser les dépôts :

1. Accédez à l'emplacement de stockage des dépôts :
   - Pour les installations de packages Linux, les dépôts sont stockés par défaut dans le répertoire `/var/opt/gitlab/git-data/repositories`.
   - Pour les installations GitLab Helm chart, les dépôts sont stockés par défaut dans le répertoire `/home/git/repositories` à l'intérieur du pod Gitaly.
1. [Identifiez le sous-répertoire contenant le dépôt](repository_storage_paths.md#from-project-name-to-hashed-path) que vous devez vérifier.
1. Exécutez la vérification. Par exemple :

   ```shell
   sudo -u git /opt/gitlab/embedded/bin/git \
      -C /var/opt/gitlab/git-data/repositories/@hashed/0b/91/0b91...f9.git fsck --no-dangling
   ```

   L'erreur `fatal: detected dubious ownership in repository` signifie que vous exécutez la commande avec le mauvais compte. Par exemple, `root`.

## Que faire si une vérification a échoué {#what-to-do-if-a-check-failed}

{{< details >}}

- Offre : GitLab Self-Managed

{{< /details >}}

Si une vérification de dépôt échoue, localisez l'erreur dans le [fichier `repocheck.log`](logs/_index.md#repochecklog) sur le disque à :

- `/var/log/gitlab/gitlab-rails` pour les installations avec le package Linux.
- `/home/git/gitlab/log` pour les installations compilées à partir des sources.
- `/var/log/gitlab` dans le pod Sidekiq pour les installations GitLab Helm chart.

Si les vérifications périodiques de dépôt génèrent de fausses alertes, vous pouvez effacer tous les états de vérification de dépôt :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Dépôt**.
1. Développez **Maintenance du dépôt**.
1. Sélectionnez **Effacer toutes les vérifications de dépôt**.

## Dépannage {#troubleshooting}

{{< details >}}

- Offre : GitLab Self-Managed

{{< /details >}}

Lorsque vous travaillez avec des vérifications de dépôt, vous pouvez rencontrer les problèmes suivants.

### Erreur : `failed to parse commit <commit SHA> from object database for commit-graph` {#error-failed-to-parse-commit-commit-sha-from-object-database-for-commit-graph}

Vous pouvez voir une erreur `failed to parse commit <commit SHA> from object database for commit-graph` dans les journaux de vérification de dépôt. Cette erreur se produit si votre cache `commit-graph` est obsolète. Le cache `commit-graph` est un cache auxiliaire et n'est pas requis pour les opérations Git régulières.

Bien que le message puisse être ignoré sans risque, consultez le ticket [erreur : Impossible de lire depuis la base de données d'objets pour commit-graph](https://gitlab.com/gitlab-org/gitaly/-/issues/2359) pour plus de détails.

### Messages de commit, tag ou blob en suspens {#dangling-commit-tag-or-blob-messages}

La sortie de vérification de dépôt inclut souvent des tags, des blobs et des commits qui doivent être supprimés :

```plaintext
dangling tag 5c6886c774b713a43158aae35c4effdb03a3ceca
dangling blob 3e268c23fcd736db92e89b31d9f267dd4a50ac4b
dangling commit 919ff61d8d78c2e3ea9a32701dff70ecbefdd1d7
```

Cela est courant dans les dépôts Git. Ils sont générés par des opérations telles que le force push vers des branches, car cela génère un commit dans le dépôt qui n'est plus référencé par une ref ou par un autre commit.

Si une vérification de dépôt échoue, la sortie est susceptible d'inclure ces avertissements.

Ignorez ces messages et identifiez la cause principale de l'échec de la vérification de dépôt à partir des autres informations de sortie.

[GitLab 15.8 et versions ultérieures](https://gitlab.com/gitlab-org/gitaly/-/merge_requests/5230) n'inclut plus ces messages dans la sortie de vérification. Utilisez l'option `--no-dangling` pour les supprimer lors de l'exécution depuis la ligne de commande.
