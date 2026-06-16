---
stage: Tenant Scale
group: Geo
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
ignore_in_report: true
title: Runbooks de promotion pour la reprise après sinistre (Geo)
---

{{< details >}}

- Niveau :  Premium, Ultimate
- Offre : GitLab Self-Managed
- Statut :  Expérience

{{< /details >}}

Runbooks de promotion pour la reprise après sinistre (Geo).

> [!warning]
> Ce runbook est une [expérience](../../../../policy/development_stages_support.md#experiment). Pour une documentation complète et prête pour la production, consultez la [documentation sur la reprise après sinistre](../_index.md).

## Basculement planifié Geo pour une configuration à nœud unique {#geo-planned-failover-for-a-single-node-configuration}

| Composant   | Configuration                |
|:------------|:-----------------------------|
| PostgreSQL  | Géré par le package Linux |
| Site Geo    | Nœud unique                  |
| Secondaires | Un                          |

Ce runbook vous guide à travers un basculement planifié d'un site Geo à nœud unique avec un secondaire. L'architecture générale suivante est supposée :

Site principal :

- Nœud GitLab

Site secondaire :

- Nœud GitLab

Ce guide aboutit aux résultats suivants :

1. Un principal hors ligne.
1. Un secondaire promu qui est maintenant le nouveau principal.

Ce qui n'est pas couvert :

1. Réajout de l'ancien **principal** en tant que secondaire.
1. Ajout d'un nouveau secondaire.

### Préparation {#preparation}

> [!note]
> Avant de suivre l'une de ces étapes, assurez-vous d'avoir accès à `root` sur le site **secondaire** pour le promouvoir, car il n'existe pas de méthode automatisée pour promouvoir un réplica Geo et effectuer un basculement.

Sur le site **secondaire**, accédez à l'**Espace d'administration** > tableau de bord **Geo** pour vérifier son statut. Les objets répliqués (affichés en vert) doivent être proches de 100 %, et il ne doit y avoir aucun échec (affiché en rouge). Si une grande proportion d'objets n'est pas encore répliquée (affichée en gris), envisagez de laisser plus de temps au site pour terminer.

![Tableau de bord d'administration Geo affichant le statut de synchronisation d'un site secondaire.](img/geo_dashboard_v14_0.png)

Si des objets échouent à se répliquer, cela doit être investigué avant de planifier la fenêtre de maintenance. Après un basculement planifié, tout ce qui n'a pas réussi à se répliquer est **lost**.

Une cause courante d'échecs de réplication est l'absence de données sur le site **principal** \- vous pouvez résoudre ces échecs en restaurant les données à partir d'une sauvegarde, ou en supprimant les références aux données manquantes.

La fenêtre de maintenance ne se termine pas tant que la réplication et la vérification Geo ne sont pas complètement terminées. Pour maintenir la fenêtre aussi courte que possible, vous devez vous assurer que ces processus sont aussi proches de 100 % que possible pendant l'utilisation active.

Si le site **secondaire** est encore en train de répliquer des données depuis le site **principal**, suivez ces étapes pour éviter toute perte de données inutile :

1. Tant qu'un [mode lecture seule](https://gitlab.com/gitlab-org/gitlab/-/issues/14609) n'est pas implémenté, les mises à jour doivent être empêchées manuellement sur le site **principal**. Votre site **secondaire** a toujours besoin d'un accès en lecture seule au site **principal** pendant la fenêtre de maintenance :

   1. Au moment prévu, en utilisant votre fournisseur cloud ou le pare-feu de votre site, bloquez tout le trafic HTTP, HTTPS et SSH vers/depuis le site **principal**, **except** pour votre IP et l'IP du site **secondaire**.

      Par exemple, vous pouvez exécuter les commandes suivantes sur le site **principal** :

      ```shell
      sudo iptables -A INPUT -p tcp -s <secondary_site_ip> --destination-port 22 -j ACCEPT
      sudo iptables -A INPUT -p tcp -s <your_ip> --destination-port 22 -j ACCEPT
      sudo iptables -A INPUT --destination-port 22 -j REJECT

      sudo iptables -A INPUT -p tcp -s <secondary_site_ip> --destination-port 80 -j ACCEPT
      sudo iptables -A INPUT -p tcp -s <your_ip> --destination-port 80 -j ACCEPT
      sudo iptables -A INPUT --tcp-dport 80 -j REJECT

      sudo iptables -A INPUT -p tcp -s <secondary_site_ip> --destination-port 443 -j ACCEPT
      sudo iptables -A INPUT -p tcp -s <your_ip> --destination-port 443 -j ACCEPT
      sudo iptables -A INPUT --tcp-dport 443 -j REJECT
      ```

      À partir de ce moment, les utilisateurs ne peuvent plus consulter leurs données ni apporter des modifications sur le site **principal**. Ils ne peuvent pas non plus se connecter au site **secondaire**. Cependant, les sessions existantes doivent continuer à fonctionner pour le reste de la période de maintenance, et les données publiques restent donc accessibles tout au long.

   1. Vérifiez que le site **principal** est bloqué au trafic HTTP en le visitant dans un navigateur via une autre IP. Le serveur doit refuser la connexion.

   1. Vérifiez que le site **principal** est bloqué au trafic Git via SSH en tentant de récupérer un dépôt Git existant avec une URL distante SSH. Le serveur doit refuser la connexion.

   1. Sur le site **principal** :
      1. Dans le coin supérieur droit, sélectionnez **Admin**.
      1. Dans la barre latérale gauche, sélectionnez **Surveillance** > **Jobs en arrière-plan**.
      1. Sur le tableau de bord Sidekiq, sélectionnez **Cron**.
      1. Sélectionnez `Disable All` pour désactiver tous les jobs périodiques en arrière-plan non liés à Geo.
      1. Sélectionnez `Enable` pour le job cron `geo_sidekiq_cron_config_worker`. Ce job réactive plusieurs autres jobs cron qui sont essentiels pour que le basculement planifié se termine avec succès.

1. Terminez la réplication et la vérification de toutes les données :

   > [!warning]
   > Toutes les données ne sont pas automatiquement répliquées. Lisez-en plus sur [ce qui est exclu](../planned_failover.md#not-all-data-is-automatically-replicated).

   1. Si vous répliquez manuellement des [données non gérées par Geo](../../replication/datatypes.md#replicated-data-types), déclenchez le processus de réplication final maintenant.
   1. Sur le site **principal** :
      1. Dans le coin supérieur droit, sélectionnez **Admin**.
      1. Dans la barre latérale gauche, sélectionnez **Surveillance** > **Jobs en arrière-plan**.
      1. Sur le tableau de bord Sidekiq, sélectionnez **Queues** et attendez que toutes les files d'attente, à l'exception de celles contenant `geo` dans leur nom, tombent à 0. Ces files d'attente contiennent le travail soumis par vos utilisateurs ; basculer avant que celui-ci soit terminé entraîne la perte de ce travail.
      1. Dans la barre latérale gauche, sélectionnez **Geo** > **Sites** et attendez que les conditions suivantes soient remplies pour le site **secondaire** vers lequel vous basculez :

         - Tous les indicateurs de réplication atteignent 100 % de réplication, 0 % d'échecs.
         - Tous les indicateurs de vérification atteignent 100 % de vérification, 0 % d'échecs.
         - Le délai de réplication de la base de données est de 0 ms.
         - Le curseur de journal Geo est à jour (0 événement de retard).

   1. Sur le site **secondaire** :
      1. Dans le coin supérieur droit, sélectionnez **Admin**.
      1. Dans la barre latérale gauche, sélectionnez **Surveillance** > **Jobs en arrière-plan**.
      1. Sur le tableau de bord Sidekiq, sélectionnez **Queues** et attendez que toutes les files d'attente `geo` tombent à 0 jobs en attente et 0 jobs en cours d'exécution.
      1. [Exécutez une vérification d'intégrité](../../../raketasks/check.md) pour vérifier l'intégrité des artefacts CI, des objets LFS et des téléversements dans le stockage de fichiers.

   À ce stade, votre site **secondaire** contient une copie à jour de tout ce que possède le site **principal**, ce qui signifie qu'aucune donnée n'est perdue lors du basculement.

1. Dans cette dernière étape, vous devez désactiver définitivement le site **principal**.

   > [!warning]
   > Lorsque le site **principal** passe hors ligne, il se peut que des données enregistrées sur le site **principal** n'aient pas été répliquées vers le site **secondaire**. Ces données doivent être considérées comme perdues si vous continuez.

   Si vous prévoyez de [mettre à jour l'enregistrement DNS du domaine **principal**](../_index.md#optional-updating-the-primary-domain-dns-record), vous souhaiterez peut-être réduire le TTL maintenant pour accélérer la propagation.

   Lors d'un basculement, nous voulons éviter une situation de split-brain dans laquelle des écritures peuvent se produire dans deux instances GitLab différentes. Ainsi, pour vous préparer au basculement, vous devez désactiver le site **principal** :

   - Si vous avez un accès SSH au site **principal**, arrêtez et désactivez GitLab :

     ```shell
     sudo gitlab-ctl stop
     ```

     Empêcher GitLab de redémarrer si le serveur redémarre de façon inattendue :

     ```shell
     sudo systemctl disable gitlab-runsvdir
     ```

     > [!note]
     >
     > - Dans CentOS 6 ou une version antérieure, il est difficile d'empêcher GitLab de démarrer si le redémarrage de la machine n'est pas disponible (voir [issue 3058](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/3058)). Il peut être plus sûr de désinstaller complètement le package GitLab avec `sudo yum remove gitlab-ee`.
     > - Si vous utilisez une ancienne version d'Ubuntu telle que 14.04 LTS ou toute autre distribution basée sur le système d'initialisation Upstart, vous pouvez empêcher GitLab de démarrer si la machine redémarre en tant que `root` avec `initctl stop gitlab-runsvvdir && echo 'manual' > /etc/init/gitlab-runsvdir.override && initctl reload-configuration`.

   - Si vous n'avez pas accès SSH au site **principal**, mettez la machine hors ligne et empêchez-la de redémarrer. Étant donné qu'il existe de nombreuses façons d'accomplir cela selon vos préférences, nous évitons de formuler une recommandation unique. Vous devrez peut-être :

     - Reconfigurer les équilibreurs de charge.
     - Modifier les enregistrements DNS (par exemple, pointer l'enregistrement DNS **principal** vers le site **secondaire** pour arrêter d'utiliser le site **principal**).
     - Arrêter les serveurs virtuels.
     - Bloquer le trafic via un pare-feu.
     - Révoquer les autorisations de stockage d'objets du site **principal**.
     - Déconnecter physiquement une machine.

### Promotion du site **secondaire** {#promoting-the-secondary-site}

Notez les points suivants lors de la promotion d'un secondaire :

- Un nouveau site **secondaire** ne doit pas être ajouté à ce stade. Si vous souhaitez ajouter un nouveau **secondaire**, faites-le après avoir terminé l'intégralité du processus de promotion du **secondaire** en tant que **principal**.
- Si vous rencontrez une erreur `ActiveRecord::RecordInvalid: Validation failed: Name has already been taken` lors de ce processus, consultez [les conseils de dépannage](../failover_troubleshooting.md#fixing-errors-during-a-failover-or-when-promoting-a-secondary-to-a-primary-site).

Pour promouvoir le site secondaire :

1. Connectez-vous en SSH à votre site **secondaire** et exécutez l'une des commandes suivantes :

   - Pour promouvoir le site secondaire en principal :

     ```shell
     sudo gitlab-ctl geo promote
     ```

   - Pour promouvoir le site secondaire en principal **sans aucune confirmation supplémentaire** :

     ```shell
     sudo gitlab-ctl geo promote --force
     ```

1. Vérifiez que vous pouvez vous connecter au nouveau site **principal** récemment promu en utilisant l'URL précédemment utilisée pour le site **secondaire**.

   En cas de succès, le site **secondaire** est maintenant promu en tant que site **principal**.

### Étapes suivantes {#next-steps}

Pour retrouver la redondance géographique aussi rapidement que possible, vous devriez [ajouter un nouveau site **secondaire**](../../setup/_index.md). Pour ce faire, vous pouvez réajouter l'ancien site **principal** en tant que nouveau secondaire et le remettre en ligne.
