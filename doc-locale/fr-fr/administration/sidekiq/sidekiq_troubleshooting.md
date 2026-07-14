---
stage: Tenant Scale
group: Tenant Services
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Dépannage de Sidekiq
---

{{< details >}}

- Niveau :  Free, Premium, Ultimate
- Offre :  GitLab Self-Managed

{{< /details >}}

Sidekiq est le processeur de jobs en arrière-plan que GitLab utilise pour exécuter des tâches de manière asynchrone. Lorsque des problèmes surviennent, le dépannage peut s'avérer difficile. Ces situations ont également tendance à être très stressantes car la file d'attente des jobs d'un système en production peut se remplir. Les utilisateurs le remarquent car les nouvelles branches peuvent ne pas apparaître et les merge requests peuvent ne pas être mises à jour. Voici quelques étapes de dépannage pour vous aider à diagnostiquer le goulot d'étranglement.

Les administrateurs/utilisateurs de GitLab devraient envisager de suivre ces étapes de débogage avec le support GitLab afin que les traces de la pile puissent être analysées par notre équipe. Cela peut révéler un bug ou une amélioration nécessaire dans GitLab.

Dans toutes les traces de la pile, méfiez-vous des cas où chaque fil de discussion semble attendre dans la base de données, Redis, ou attendre l'acquisition d'un mutex. Cela **may** signifier qu'il y a une contention dans la base de données, par exemple, mais cherchez un fil de discussion différent des autres. Cet autre fil de discussion utilise peut-être tout le CPU disponible, ou possède un Ruby Global Interpreter Lock, empêchant les autres fils de discussion de continuer.

## Journaliser les arguments des jobs Sidekiq {#log-arguments-to-sidekiq-jobs}

Certains arguments transmis aux jobs Sidekiq sont journalisés par défaut. Pour éviter de journaliser des informations sensibles (par exemple, des jetons de réinitialisation de mot de passe), GitLab journalise les arguments numériques pour tous les workers, avec des remplacements pour certains workers spécifiques dont les arguments ne sont pas sensibles.

Exemple de sortie de journal :

```json
{"severity":"INFO","time":"2020-06-08T14:37:37.892Z","class":"AdminEmailsWorker","args":["[FILTERED]","[FILTERED]","[FILTERED]"],"retry":3,"queue":"admin_emails","backtrace":true,"jid":"9e35e2674ac7b12d123e13cc","created_at":"2020-06-08T14:37:37.373Z","meta.user":"root","meta.caller_id":"Admin::EmailsController#create","correlation_id":"37D3lArJmT1","uber-trace-id":"2d942cc98cc1b561:6dc94409cfdd4d77:9fbe19bdee865293:1","enqueued_at":"2020-06-08T14:37:37.410Z","pid":65011,"message":"AdminEmailsWorker JID-9e35e2674ac7b12d123e13cc: done: 0.48085 sec","job_status":"done","scheduling_latency_s":0.001012,"redis_calls":9,"redis_duration_s":0.004608,"redis_read_bytes":696,"redis_write_bytes":6141,"duration_s":0.48085,"cpu_s":0.308849,"completed_at":"2020-06-08T14:37:37.892Z","db_duration_s":0.010742}
{"severity":"INFO","time":"2020-06-08T14:37:37.894Z","class":"ActiveJob::QueueAdapters::SidekiqAdapter::JobWrapper","wrapped":"ActionMailer::MailDeliveryJob","queue":"mailers","args":["[FILTERED]"],"retry":3,"backtrace":true,"jid":"e47a4f6793d475378432e3c8","created_at":"2020-06-08T14:37:37.884Z","meta.user":"root","meta.caller_id":"AdminEmailsWorker","correlation_id":"37D3lArJmT1","uber-trace-id":"2d942cc98cc1b561:29344de0f966446d:5c3b0e0e1bef987b:1","enqueued_at":"2020-06-08T14:37:37.885Z","pid":65011,"message":"ActiveJob::QueueAdapters::SidekiqAdapter::JobWrapper JID-e47a4f6793d475378432e3c8: start","job_status":"start","scheduling_latency_s":0.009473}
{"severity":"INFO","time":"2020-06-08T14:39:50.648Z","class":"NewIssueWorker","args":["455","1"],"retry":3,"queue":"new_issue","backtrace":true,"jid":"a24af71f96fd129ec47f5d1e","created_at":"2020-06-08T14:39:50.643Z","meta.user":"root","meta.project":"h5bp/html5-boilerplate","meta.root_namespace":"h5bp","meta.caller_id":"Projects::IssuesController#create","correlation_id":"f9UCZHqhuP7","uber-trace-id":"28f65730f99f55a3:a5d2b62dec38dffc:48ddd092707fa1b7:1","enqueued_at":"2020-06-08T14:39:50.646Z","pid":65011,"message":"NewIssueWorker JID-a24af71f96fd129ec47f5d1e: start","job_status":"start","scheduling_latency_s":0.001144}
```

Lors de l'utilisation de [la journalisation JSON de Sidekiq](../logs/_index.md#sidekiqlog), les journaux d'arguments sont limités à une taille maximale de 10 kilo-octets de texte ; tous les arguments dépassant cette limite sont ignorés et remplacés par un seul argument contenant la chaîne `"..."`.

Vous pouvez définir la [variable d'environnement](https://docs.gitlab.com/omnibus/settings/environment-variables/) `SIDEKIQ_LOG_ARGUMENTS` à `0` (false) pour désactiver la journalisation des arguments.

Exemple :

```ruby
gitlab_rails['env'] = {"SIDEKIQ_LOG_ARGUMENTS" => "0"}
```

## Analyse des backlogs de files d'attente Sidekiq ou des performances lentes {#investigating-sidekiq-queue-backlogs-or-slow-performance}

Les symptômes de performances lentes de Sidekiq incluent des problèmes de mise à jour des statuts de merge request et des retards avant le démarrage des pipelines CI.

Les causes potentielles incluent :

- L'instance GitLab peut nécessiter davantage de workers Sidekiq. Par défaut, une installation de package Linux à nœud unique exécute un seul worker, limitant l'exécution des jobs Sidekiq à un maximum d'un cœur CPU. [En savoir plus sur l'exécution de plusieurs workers Sidekiq](extra_sidekiq_processes.md).

- L'instance est configurée avec davantage de workers Sidekiq, mais la plupart des workers supplémentaires ne sont pas configurés pour exécuter les jobs en attente dans la file d'attente. Cela peut entraîner un backlog de jobs lorsque l'instance est occupée, si la charge de travail a évolué au cours des mois ou des années suivant la configuration des workers, ou à la suite de changements dans le produit GitLab.

Collectez des données sur l'état des workers Sidekiq à l'aide du script Ruby suivant.

1. Créez le script :

   ```ruby
   cat > /var/opt/gitlab/sidekiqcheck.rb <<EOF
   require 'sidekiq/monitor'
   Sidekiq::Monitor::Status.new.display('overview')
   Sidekiq::Monitor::Status.new.display('processes'); nil
   Sidekiq::Monitor::Status.new.display('queues'); nil
   puts "----------- workers ----------- "
   workers = Sidekiq::Workers.new
   workers.each do |_process_id, _thread_id, work|
     pp work
   end
   puts "----------- Queued Jobs ----------- "
   Sidekiq::Queue.all.each do |queue|
     queue.each do |job|
       pp job
     end
   end ;nil
   puts "----------- done! ----------- "
   EOF
   ```

1. Exécutez et capturez la sortie :

   ```shell
   sudo gitlab-rails runner /var/opt/gitlab/sidekiqcheck.rb > /tmp/sidekiqcheck_$(date '+%Y%m%d-%H:%M').out
   ```

   Si le problème de performance est intermittent :

   - Exécutez ceci dans un cron job toutes les cinq minutes. Écrivez les fichiers dans un emplacement disposant de suffisamment d'espace : prévoyez au moins 500 Ko par fichier.

     ```shell
     cat > /etc/cron.d/sidekiqcheck <<EOF
     */5 * * * *  root  /opt/gitlab/bin/gitlab-rails runner /var/opt/gitlab/sidekiqcheck.rb > /tmp/sidekiqcheck_$(date '+\%Y\%m\%d-\%H:\%M').out 2>&1
     EOF
     ```

   - Reportez-vous aux données pour identifier ce qui s'est mal passé.

1. Analysez la sortie. Les commandes suivantes supposent que vous disposez d'un répertoire de fichiers de sortie.

   1. `grep 'Busy: ' *` indique le nombre de jobs en cours d'exécution. `grep 'Enqueued: ' *` indique le backlog de travail à ce moment-là.

   1. Examinez le nombre de fils de discussion actifs parmi les workers dans les échantillons où Sidekiq est sous charge :

      ```shell
      ls | while read f ; do if grep -q 'Enqueued: 0' $f; then :
        else echo $f; egrep 'Busy:|Enqueued:|---- Processes' $f
        grep 'Threads:' $f ; fi
      done | more
      ```

      Exemple de sortie :

      ```plaintext
      sidekiqcheck_20221024-14:00.out
             Busy: 47
         Enqueued: 363
      ---- Processes (13) ----
        Threads: 30 (0 busy)
        Threads: 30 (0 busy)
        Threads: 30 (0 busy)
        Threads: 30 (0 busy)
        Threads: 23 (0 busy)
        Threads: 30 (0 busy)
        Threads: 30 (0 busy)
        Threads: 30 (0 busy)
        Threads: 30 (0 busy)
        Threads: 30 (0 busy)
        Threads: 30 (0 busy)
        Threads: 30 (24 busy)
        Threads: 30 (23 busy)
      ```

      - Dans ce fichier de sortie, 47 fils de discussion étaient actifs, et il y avait un backlog de 363 jobs.
      - Sur les 13 processus workers, seulement deux étaient actifs.
      - Cela indique que les autres workers sont configurés de manière trop spécifique.
      - Examinez la sortie complète pour déterminer quels workers étaient actifs. Corrélez avec votre configuration `sidekiq_queues` dans `gitlab.rb`.
      - Un environnement à worker unique surchargé pourrait ressembler à ceci :

        ```plaintext
        sidekiqcheck_20221024-14:00.out
               Busy: 25
           Enqueued: 363
        ---- Processes (1) ----
          Threads: 25 (25 busy)
        ```

   1. Examinez la section `---- Queues (xxx) ----` du fichier de sortie pour déterminer quels jobs étaient en attente dans la file d'attente à ce moment-là.

   1. Les fichiers incluent également des détails de bas niveau sur l'état de Sidekiq à ce moment-là. Cela peut être utile pour identifier l'origine des pics de charge de travail.

      - La section `----------- workers -----------` détaille les jobs qui constituent le nombre `Busy` dans le résumé.
      - La section `----------- Queued Jobs -----------` fournit des détails sur les jobs qui sont `Enqueued`.

## Vidage de fils de discussion {#thread-dump}

Envoyez au PID du processus Sidekiq le signal `TTIN` pour afficher les traces de la pile des fils de discussion dans le fichier journal.

```shell
kill -TTIN <sidekiq_pid>
```

Vérifiez dans `/var/log/gitlab/sidekiq/current` ou `$GITLAB_HOME/log/sidekiq.log` la sortie des traces de la pile. Les traces de la pile sont longues et commencent généralement par plusieurs messages de niveau `WARN`. Voici un exemple de trace de la pile d'un seul fil de discussion :

```plaintext
2016-04-13T06:21:20.022Z 31517 TID-orn4urby0 WARN: ActiveRecord::RecordNotFound: Couldn't find Note with 'id'=3375386
2016-04-13T06:21:20.022Z 31517 TID-orn4urby0 WARN: /opt/gitlab/embedded/service/gem/ruby/2.1.0/gems/activerecord-4.2.5.2/lib/active_record/core.rb:155:in `find'
/opt/gitlab/embedded/service/gitlab-rails/app/workers/new_note_worker.rb:7:in `perform'
/opt/gitlab/embedded/service/gem/ruby/2.1.0/gems/sidekiq-4.0.1/lib/sidekiq/processor.rb:150:in `execute_job'
/opt/gitlab/embedded/service/gem/ruby/2.1.0/gems/sidekiq-4.0.1/lib/sidekiq/processor.rb:132:in `block (2 levels) in process'
/opt/gitlab/embedded/service/gem/ruby/2.1.0/gems/sidekiq-4.0.1/lib/sidekiq/middleware/chain.rb:127:in `block in invoke'
/opt/gitlab/embedded/service/gitlab-rails/lib/gitlab/sidekiq_middleware/memory_killer.rb:17:in `call'
/opt/gitlab/embedded/service/gem/ruby/2.1.0/gems/sidekiq-4.0.1/lib/sidekiq/middleware/chain.rb:129:in `block in invoke'
/opt/gitlab/embedded/service/gitlab-rails/lib/gitlab/sidekiq_middleware/arguments_logger.rb:6:in `call'
...
```

Dans certains cas, Sidekiq peut être bloqué et incapable de répondre au signal `TTIN`. Passez à d'autres méthodes de dépannage si cela se produit.

## Profilage Ruby avec `rbspy` {#ruby-profiling-with-rbspy}

[rbspy](https://rbspy.github.io) est un profileur Ruby facile à utiliser et à faible surcharge, qui peut être utilisé pour créer des diagrammes de style flamegraph de l'utilisation du CPU par les processus Ruby.

Aucune modification de GitLab n'est requise pour l'utiliser et il n'a pas de dépendances. Pour l'installer :

1. Téléchargez le binaire depuis la [page des versions de `rbspy`](https://github.com/rbspy/rbspy/releases).
1. Rendez le binaire exécutable.

Pour profiler un worker Sidekiq pendant une minute, exécutez :

```shell
sudo ./rbspy record --pid <sidekiq_pid> --duration 60 --file /tmp/sidekiq_profile.svg
```

![Exemple de flamegraph rbspy](img/sidekiq_flamegraph_v14_6.png)

Dans cet exemple de flamegraph généré par `rbspy`, presque tout le temps du processus Sidekiq est passé dans `rev_parse`, une fonction C native dans Rugged. Dans la pile, nous pouvons voir que `rev_parse` est appelé par le `ExpirePipelineCacheWorker`.

`rbspy` requiert des [capacités](https://man7.org/linux/man-pages/man7/capabilities.7.html) supplémentaires dans les [environnements conteneurisés](https://rbspy.github.io/using-rbspy/index.html#containers). Il nécessite au minimum la capacité `SYS_PTRACE`, sinon il se termine avec une erreur `permission denied`.

{{< tabs >}}

{{< tab title="Kubernetes" >}}

```yaml
securityContext:
  capabilities:
    add:
      - SYS_PTRACE
```

{{< /tab >}}

{{< tab title="Docker" >}}

```shell
docker run --cap-add SYS_PTRACE [...]
```

{{< /tab >}}

{{< tab title="Docker Compose" >}}

```yaml
services:
  ruby_container_name:
    # ...
    cap_add:
      - SYS_PTRACE
```

{{< /tab >}}

{{< /tabs >}}

## Profilage de processus avec `perf` {#process-profiling-with-perf}

Linux dispose d'un outil de profilage de processus appelé `perf` qui est utile lorsqu'un certain processus consomme beaucoup de CPU. Si vous constatez une utilisation élevée du CPU et que Sidekiq ne répond pas au signal `TTIN`, c'est une bonne prochaine étape.

Si `perf` n'est pas installé sur votre système, installez-le avec `apt-get` ou `yum` :

```shell
# Debian
sudo apt-get install linux-tools

# Ubuntu (may require these additional Kernel packages)
sudo apt-get install linux-tools-common linux-tools-generic linux-tools-`uname -r`

# Red Hat/CentOS
sudo yum install perf
```

Exécutez `perf` contre le PID de Sidekiq :

```shell
sudo perf record -p <sidekiq_pid>
```

Laissez tourner pendant 30 à 60 secondes, puis appuyez sur <kbd>Control</kbd>-<kbd>C</kbd>. Puis consultez le rapport `perf` :

```shell
$ sudo perf report

# Sample output
Samples: 348K of event 'cycles', Event count (approx.): 280908431073
 97.69%            ruby  nokogiri.so         [.] xmlXPathNodeSetMergeAndClear
  0.18%            ruby  libruby.so.2.1.0    [.] objspace_malloc_increase
  0.12%            ruby  libc-2.12.so        [.] _int_malloc
  0.10%            ruby  libc-2.12.so        [.] _int_free
```

La sortie d'exemple du rapport `perf` montre que 97 % du CPU est consommé par Nokogiri et `xmlXPathNodeSetMergeAndClear`. Pour quelque chose d'aussi évident, vous devriez ensuite chercher quel job dans GitLab utiliserait Nokogiri et XPath. Combinez avec la sortie `TTIN` ou `gdb` pour afficher le code Ruby correspondant où cela se produit.

## Le débogueur GNU Project (`gdb`) {#the-gnu-project-debugger-gdb}

`gdb` peut être un autre outil efficace pour déboguer Sidekiq. Il vous offre une façon un peu plus interactive d'examiner chaque fil de discussion et de voir ce qui cause des problèmes.

L'attachement à un processus avec `gdb` suspend le fonctionnement normal du processus (Sidekiq ne traite pas les jobs lorsque `gdb` est attaché).

Commencez par vous attacher au PID de Sidekiq :

```shell
gdb -p <sidekiq_pid>
```

Collectez ensuite des informations sur tous les fils de discussion :

```plaintext
info threads

# Example output
30 Thread 0x7fe5fbd63700 (LWP 26060) 0x0000003f7cadf113 in poll () from /lib64/libc.so.6
29 Thread 0x7fe5f2b3b700 (LWP 26533) 0x0000003f7ce0b68c in pthread_cond_wait@@GLIBC_2.3.2 () from /lib64/libpthread.so.0
28 Thread 0x7fe5f2a3a700 (LWP 26534) 0x0000003f7ce0ba5e in pthread_cond_timedwait@@GLIBC_2.3.2 () from /lib64/libpthread.so.0
27 Thread 0x7fe5f2939700 (LWP 26535) 0x0000003f7ce0b68c in pthread_cond_wait@@GLIBC_2.3.2 () from /lib64/libpthread.so.0
26 Thread 0x7fe5f2838700 (LWP 26537) 0x0000003f7ce0b68c in pthread_cond_wait@@GLIBC_2.3.2 () from /lib64/libpthread.so.0
25 Thread 0x7fe5f2737700 (LWP 26538) 0x0000003f7ce0b68c in pthread_cond_wait@@GLIBC_2.3.2 () from /lib64/libpthread.so.0
24 Thread 0x7fe5f2535700 (LWP 26540) 0x0000003f7ce0b68c in pthread_cond_wait@@GLIBC_2.3.2 () from /lib64/libpthread.so.0
23 Thread 0x7fe5f2434700 (LWP 26541) 0x0000003f7ce0b68c in pthread_cond_wait@@GLIBC_2.3.2 () from /lib64/libpthread.so.0
22 Thread 0x7fe5f2232700 (LWP 26543) 0x0000003f7ce0b68c in pthread_cond_wait@@GLIBC_2.3.2 () from /lib64/libpthread.so.0
21 Thread 0x7fe5f2131700 (LWP 26544) 0x00007fe5f7b570f0 in xmlXPathNodeSetMergeAndClear ()
from /opt/gitlab/embedded/service/gem/ruby/2.1.0/gems/nokogiri-1.6.7.2/lib/nokogiri/nokogiri.so
...
```

Si vous voyez un fil de discussion suspect, comme celui de Nokogiri dans l'exemple, vous souhaitez peut-être obtenir plus d'informations :

```plaintext
thread 21
bt

# Example output
#0  0x00007ff0d6afe111 in xmlXPathNodeSetMergeAndClear () from /opt/gitlab/embedded/service/gem/ruby/2.1.0/gems/nokogiri-1.6.7.2/lib/nokogiri/nokogiri.so
#1  0x00007ff0d6b0b836 in xmlXPathNodeCollectAndTest () from /opt/gitlab/embedded/service/gem/ruby/2.1.0/gems/nokogiri-1.6.7.2/lib/nokogiri/nokogiri.so
#2  0x00007ff0d6b09037 in xmlXPathCompOpEval () from /opt/gitlab/embedded/service/gem/ruby/2.1.0/gems/nokogiri-1.6.7.2/lib/nokogiri/nokogiri.so
#3  0x00007ff0d6b09017 in xmlXPathCompOpEval () from /opt/gitlab/embedded/service/gem/ruby/2.1.0/gems/nokogiri-1.6.7.2/lib/nokogiri/nokogiri.so
#4  0x00007ff0d6b092e0 in xmlXPathCompOpEval () from /opt/gitlab/embedded/service/gem/ruby/2.1.0/gems/nokogiri-1.6.7.2/lib/nokogiri/nokogiri.so
#5  0x00007ff0d6b0bc37 in xmlXPathRunEval () from /opt/gitlab/embedded/service/gem/ruby/2.1.0/gems/nokogiri-1.6.7.2/lib/nokogiri/nokogiri.so
#6  0x00007ff0d6b0be5f in xmlXPathEvalExpression () from /opt/gitlab/embedded/service/gem/ruby/2.1.0/gems/nokogiri-1.6.7.2/lib/nokogiri/nokogiri.so
#7  0x00007ff0d6a97dc3 in evaluate (argc=2, argv=0x1022d058, self=<value optimized out>) at xml_xpath_context.c:221
#8  0x00007ff0daeab0ea in vm_call_cfunc_with_frame (th=0x1022a4f0, reg_cfp=0x1032b810, ci=<value optimized out>) at vm_insnhelper.c:1510
```

Pour afficher une trace de la pile de tous les fils de discussion à la fois :

```plaintext
set pagination off
thread apply all bt
```

Une fois le débogage avec `gdb` terminé, assurez-vous de vous détacher du processus et de quitter :

```plaintext
detach
exit
```

## Signaux d'arrêt Sidekiq {#sidekiq-kill-signals}

TTIN a été décrit précédemment comme le signal permettant d'imprimer les traces de la pile pour la journalisation, mais Sidekiq répond également à d'autres signaux. Par exemple, TSTP et TERM peuvent être utilisés pour arrêter Sidekiq proprement, voir [la documentation des signaux Sidekiq](https://github.com/mperham/sidekiq/wiki/Signals#ttin).

## Vérifier les requêtes bloquantes {#check-for-blocking-queries}

Parfois, la vitesse à laquelle Sidekiq traite les jobs peut être si rapide qu'elle peut provoquer une contention de base de données. Recherchez les requêtes bloquantes lorsque les traces de la pile documentées précédemment montrent que de nombreux fils de discussion sont bloqués dans l'adaptateur de base de données.

Le wiki PostgreSQL contient des détails sur la requête que vous pouvez exécuter pour voir les requêtes bloquantes. La requête diffère selon la version de PostgreSQL. Consultez [Lock Monitoring](https://wiki.postgresql.org/wiki/Lock_Monitoring) pour les détails de la requête.

## Gestion des files d'attente Sidekiq {#managing-sidekiq-queues}

Il est possible d'utiliser l'[API Sidekiq](https://github.com/mperham/sidekiq/wiki/API) pour effectuer un certain nombre d'étapes de dépannage sur Sidekiq.

Ce sont des commandes administratives qui ne doivent être utilisées que si l'interface d'administration actuelle n'est pas adaptée en raison de l'échelle de l'installation.

Toutes ces commandes doivent être exécutées avec `gitlab-rails console`.

### Afficher la taille de la file d'attente {#view-the-queue-size}

```ruby
Sidekiq::Queue.new("pipeline_processing:build_queue").size
```

### Énumérer tous les jobs en attente {#enumerate-all-enqueued-jobs}

```ruby
queue = Sidekiq::Queue.new("chaos:chaos_sleep")
queue.each do |job|
  # job.klass # => 'MyWorker'
  # job.args # => [1, 2, 3]
  # job.jid # => jid
  # job.queue # => chaos:chaos_sleep
  # job["retry"] # => 3
  # job.item # => {
  #   "class"=>"Chaos::SleepWorker",
  #   "args"=>[1000],
  #   "retry"=>3,
  #   "queue"=>"chaos:chaos_sleep",
  #   "backtrace"=>true,
  #   "queue_namespace"=>"chaos",
  #   "jid"=>"39bc482b823cceaf07213523",
  #   "created_at"=>1566317076.266069,
  #   "correlation_id"=>"c323b832-a857-4858-b695-672de6f0e1af",
  #   "enqueued_at"=>1566317076.26761},
  # }

  # job.delete if job.jid == 'abcdef1234567890'
end
```

### Énumérer les jobs en cours d'exécution {#enumerate-currently-running-jobs}

```ruby
workers = Sidekiq::Workers.new
workers.each do |process_id, thread_id, work|
  # process_id is a unique identifier per Sidekiq process
  # thread_id is a unique identifier per thread
  # work is a Hash which looks like:
  # {"queue"=>"chaos:chaos_sleep",
  #  "payload"=>
  #  { "class"=>"Chaos::SleepWorker",
  #    "args"=>[1000],
  #    "retry"=>3,
  #    "queue"=>"chaos:chaos_sleep",
  #    "backtrace"=>true,
  #    "queue_namespace"=>"chaos",
  #    "jid"=>"b2a31e3eac7b1a99ff235869",
  #    "created_at"=>1566316974.9215662,
  #    "correlation_id"=>"e484fb26-7576-45f9-bf21-b99389e1c53c",
  #    "enqueued_at"=>1566316974.9229589},
  #  "run_at"=>1566316974}],
end
```

### Supprimer les jobs Sidekiq pour des paramètres donnés (destructif) {#remove-sidekiq-jobs-for-given-parameters-destructive}

La méthode générale pour supprimer des jobs conditionnellement est la commande suivante, qui supprime les jobs en attente mais non démarrés. Les jobs en cours d'exécution ne peuvent pas être supprimés.

```ruby
queue = Sidekiq::Queue.new('<queue name>')
queue.each { |job| job.delete if <condition>}
```

Consultez la section ci-dessous pour annuler les jobs en cours d'exécution.

Dans la méthode documentée précédemment, `<queue-name>` est le nom de la file d'attente contenant les jobs que vous souhaitez supprimer, et `<condition>` détermine quels jobs sont supprimés.

Généralement, `<condition>` fait référence aux arguments du job, qui dépendent du type de job concerné. Pour trouver les arguments d'une file d'attente spécifique, vous pouvez consulter la fonction `perform` du fichier worker associé, généralement trouvé à l'emplacement `/app/workers/<queue-name>_worker.rb`.

Par exemple, `repository_import` a `project_id` comme argument de job, tandis que `update_merge_requests` a `project_id, user_id, oldrev, newrev, ref`.

Les arguments doivent être référencés par leur ID de séquence en utilisant `job.args[<id>]` car `job.args` est une liste de tous les arguments fournis au job Sidekiq.

Voici quelques exemples :

```ruby
queue = Sidekiq::Queue.new('update_merge_requests')
# In this example, we want to remove any update_merge_requests jobs
# for the Project with ID 125 and ref `ref/heads/my_branch`
queue.each { |job| job.delete if job.args[0] == 125 and job.args[4] == 'ref/heads/my_branch' }
```

```ruby
# Canceling jobs like: `RepositoryImportWorker.new.perform_async(100)`
id_list = [100]

queue = Sidekiq::Queue.new('repository_import')
queue.each do |job|
  job.delete if id_list.include?(job.args[0])
end
```

### Supprimer un ID de job spécifique (destructif) {#remove-specific-job-id-destructive}

```ruby
queue = Sidekiq::Queue.new('repository_import')
queue.each do |job|
  job.delete if job.jid == 'my-job-id'
end
```

### Supprimer les jobs Sidekiq pour un worker spécifique (destructif) {#remove-sidekiq-jobs-for-a-specific-worker-destructive}

```ruby
queue = Sidekiq::Queue.new("default")

queue.each do |job|
  if job.klass == "TodosDestroyer::PrivateFeaturesWorker"
    # Uncomment the line below to actually delete jobs
    #job.delete
    puts "Deleted job ID #{job.jid}"
  end
end
```

## Annuler les jobs en cours d'exécution (destructif) {#canceling-running-jobs-destructive}

Il s'agit d'une opération très risquée à n'utiliser qu'en dernier recours. Cela peut entraîner une corruption des données, car le job est interrompu en cours d'exécution et il n'est pas garanti qu'une annulation correcte des transactions soit implémentée.

```ruby
Gitlab::SidekiqDaemon::Monitor.cancel_job('job-id')
```

Cela nécessite que Sidekiq soit exécuté avec la variable d'environnement `SIDEKIQ_MONITOR_WORKER=1`.

Pour effectuer l'interruption, nous utilisons `Thread.raise`, qui présente un certain nombre d'inconvénients, comme mentionné dans [Why Ruby's Timeout is dangerous (and `Thread.raise` is terrifying)](https://jvns.ca/blog/2015/11/27/why-rubys-timeout-is-dangerous-and-thread-dot-raise-is-terrifying/#timeout-how-it-works-and-why-thread-raise-is-terrifying).

## Déclencher manuellement un cron job {#manually-trigger-a-cron-job}

En visitant `/admin/background_jobs`, vous pouvez voir quels jobs sont planifiés/en cours d'exécution/en attente sur votre instance.

Vous pouvez déclencher un cron job depuis l'interface utilisateur en sélectionnant le bouton « Enqueue Now ». Pour déclencher un cron job par programmation, ouvrez d'abord une [console Rails](../operations/rails_console.md).

Pour trouver le cron job que vous souhaitez tester :

```ruby
job = Sidekiq::Cron::Job.find('job-name')

# get status of job:
job.status

# enqueue job right now!
job.enque!
```

Par exemple, pour déclencher le cron job `update_all_mirrors_worker` qui met à jour les miroirs du dépôt :

```ruby
irb(main):001:0> job = Sidekiq::Cron::Job.find('update_all_mirrors_worker')
=>
#<Sidekiq::Cron::Job:0x00007f147f84a1d0
...
irb(main):002:0> job.status
=> "enabled"
irb(main):003:0> job.enque!
=> 257
```

La liste des jobs disponibles se trouve dans le répertoire [workers](https://gitlab.com/gitlab-org/gitlab/-/tree/master/app/workers).

Pour plus d'informations sur les jobs Sidekiq, consultez la documentation [Sidekiq-cron](https://github.com/sidekiq-cron/sidekiq-cron#work-with-job).

## Désactivation des cron jobs {#disabling-cron-jobs}

Vous pouvez désactiver tous les cron jobs Sidekiq en visitant la [section Monitoring dans la zone **Admin**](../admin_area.md#monitoring-section). Vous pouvez également effectuer la même action en utilisant la ligne de commande et le [Rails Runner](../operations/rails_console.md#using-the-rails-runner).

Pour désactiver tous les cron jobs :

```shell
sudo gitlab-rails runner 'Sidekiq::Cron::Job.all.map(&:disable!)'
```

Pour activer tous les cron jobs :

```shell
sudo gitlab-rails runner 'Sidekiq::Cron::Job.all.map(&:enable!)'
```

Si vous souhaitez n'activer qu'un sous-ensemble de jobs à la fois, vous pouvez utiliser la correspondance par nom. Par exemple, pour n'activer que les jobs contenant `geo` dans le nom :

```shell
 sudo gitlab-rails runner 'Sidekiq::Cron::Job.all.select{ |j| j.name.match("geo") }.map(&:disable!)'
```

## Effacement d'une clé d'idempotence de déduplication de job Sidekiq {#clearing-a-sidekiq-job-deduplication-idempotency-key}

Occasionnellement, des jobs censés s'exécuter (par exemple, des cron jobs) sont observés comme ne s'exécutant pas du tout. Lors de la vérification des journaux, il peut y avoir des cas où des jobs semblent ne pas s'exécuter avec un `"job_status": "deduplicated"`.

Cela peut se produire lorsqu'un job a échoué et que la clé d'idempotence n'a pas été effacée correctement. Par exemple, [l'arrêt de Sidekiq supprime tous les jobs restants après 25 secondes](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/4918).

[Par défaut, la clé expire après 6 heures](https://gitlab.com/gitlab-org/gitlab/-/blob/87c92f06eb92716a26679cd339f3787ae7edbdc3/lib/gitlab/sidekiq_middleware/duplicate_jobs/duplicate_job.rb#L23), mais si vous souhaitez effacer la clé d'idempotence immédiatement, suivez les étapes suivantes (l'exemple fourni concerne `Geo::VerificationBatchWorker`) :

1. Trouvez la classe worker et les `args` du job dans les journaux Sidekiq :

   ```plaintext
   { ... "class":"Geo::VerificationBatchWorker","args":["container_repository"] ... }
   ```

1. Démarrez une [session de console Rails](../operations/rails_console.md#starting-a-rails-console-session).
1. Exécutez l'extrait de code suivant :

   ```ruby
   worker_class = Geo::VerificationBatchWorker
   args = ["container_repository"]
   dj = Gitlab::SidekiqMiddleware::DuplicateJobs::DuplicateJob.new({ 'class' => worker_class.name, 'args' => args }, worker_class.queue)
   dj.send(:idempotency_key)
   dj.delete!
   ```

## Saturation du CPU dans Redis causée par les appels BRPOP de Sidekiq {#cpu-saturation-in-redis-caused-by-sidekiq-brpop-calls}

Les appels `BROP` de Sidekiq peuvent entraîner une augmentation de l'utilisation du CPU sur Redis. Augmentez la [variable d'environnement `SIDEKIQ_SEMI_RELIABLE_FETCH_TIMEOUT`](../environment_variables.md) pour améliorer l'utilisation du CPU sur Redis.

## Erreur : `OpenSSL::Cipher::CipherError` {#error-opensslcipherciphererror}

Si vous recevez des messages d'erreur tels que :

```plaintext
"OpenSSL::Cipher::CipherError","exception.message":"","exception.backtrace":["encryptor (3.0.0) lib/encryptor.rb:98:in `final'","encryptor (3.0.0) lib/encryptor.rb:98:in `crypt'","encryptor (3.0.0) lib/encryptor.rb:49:in `decrypt'"
```

Cette erreur signifie que les processus sont incapables de déchiffrer les données chiffrées stockées dans la base de données GitLab. Cela indique qu'il y a un problème avec votre fichier `/etc/gitlab/gitlab-secrets.json`, assurez-vous d'avoir copié le fichier depuis votre nœud GitLab principal vers vos nœuds Sidekiq.

## Sujets connexes {#related-topics}

- [Les workers Elasticsearch surchargent Sidekiq](../../integration/elasticsearch/troubleshooting/migrations.md#elasticsearch-workers-overload-sidekiq).
