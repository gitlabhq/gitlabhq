---
stage: Tenant Scale
group: Tenant Services
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Linuxパッケージを使用したRedisレプリケーションとフェイルオーバー
---

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

このドキュメントはLinuxパッケージ向けです。独自のバンドルされていないRedisを使用するには、[Redisのレプリケーションとフェイルオーバー（独自のインスタンスを使用する場合）](replication_and_failover_external.md)を参照してください。

Redis用語では、`primary`は`master`と呼ばれます。このドキュメントでは、`primary`は`master`の代わりに、設定で`master`が必要な場合を除いて使用されます。

[Redis](https://redis.io/)をスケーラブルな環境で使用するには、[Redis Sentinel](https://redis.io/docs/latest/operate/oss_and_stack/management/sentinel/)サービスで**プライマリ**x**レプリカ**トポロジーを使用して、フェイルオーバーを監視し、フェイルオーバー手順を自動的に開始します。

Sentinelと併用する場合、Redisは認証を必要とします。詳細については、[Redisのセキュリティ](https://redis.io/docs/latest/operate/rc/security/)ドキュメントを参照してください。Redisサービスを保護するには、Redisパスワードと厳格なファイアウォールルールの組み合わせを使用することをおすすめします。トポロジーとアーキテクチャを十分に理解するために、GitLabでRedisを設定する前に、[Redis Sentinel](https://redis.io/docs/latest/operate/oss_and_stack/management/sentinel/)のドキュメントを読むことをおすすめします。

レプリケートされたトポロジーのためにRedisとRedis Sentinelを設定する詳細に入る前に、コンポーネントがどのように連携しているかをよりよく理解するために、このドキュメント全体を一度読んでおいてください。

少なくとも`3`台の独立したマシン（物理マシン、または独立した物理マシン上で実行されるVM）が必要です。すべてのプライマリおよびレプリカRedisインスタンスが異なるマシンで実行されることが不可欠です。その特定の方法でマシンをプロビジョニングするのに失敗すると、共有環境の問題がセットアップ全体を停止させる可能性があります。

プライマリまたはレプリカRedisインスタンスと並行してSentinelを実行しても問題ありません。ただし、同じマシン上にはSentinelは1つのみである必要があります。

また、基盤となるネットワークトポロジーも考慮し、Redis/SentinelとGitLabインスタンス間の冗長な接続が確保されていることを確認する必要があります。そうしないと、ネットワークが単一障害点になります。

スケールされた環境でRedisを実行するには、いくつかの要素が必要です:

- 複数のRedisインスタンス
- Redisを**プライマリ** x **Replica**トポロジーで実行します。
- 複数のSentinelインスタンス
- すべてのSentinelおよびRedisインスタンスに対するアプリケーションサポートと可視性

Redis Sentinelは、HA環境における最も重要なタスクを処理でき、サーバーのオンライン状態を最小限のダウンタイムまたはダウンタイムなしで維持するのに役立ちます。Redis Sentinel:

- **プライマリ**と**Replicas**インスタンスを監視し、利用可能かどうかを確認します。
- **プライマリ**が失敗したときに、**Replica**を**プライマリ**にプロモートします。
- 失敗した**プライマリ**がオンラインに戻ったときに、**プライマリ**を**Replica**に降格させます（データパーティショニングを防ぐため）。
- アプリケーションによってクエリすることができ、常に現在の**プライマリ**サーバーに接続します。

**プライマリ**が応答を失敗した場合、タイムアウトの処理と再接続（新しい**プライマリ**のために**Sentinel**にクエリすること）は、アプリケーション（この場合はGitLab）の責任です。

Sentinelを正しく設定する方法をよりよく理解するために、まず[Redis Sentinel](https://redis.io/docs/latest/operate/oss_and_stack/management/sentinel/)のドキュメントを読んでください。正しく設定しないと、データ損失につながる可能性があり、クラスター全体がダウンし、フェイルオーバーの取り組みが無効になる可能性があります。

## 推奨されるセットアップ {#recommended-setup}

最小限のセットアップでは、`3`台の**independent**マシンにLinuxパッケージをインストールする必要があります。**Redis**と**Sentinel**の両方を含みます:

- Redisプライマリ + Sentinel
- Redisレプリカ + Sentinel
- Redisレプリカ + Sentinel

ノードの数がどこから来るのか不明な場合や理解できない場合は、[Redisセットアップの概要](#redis-setup-overview)と[Sentinelセットアップの概要](#sentinel-setup-overview)をお読みください。

より多くの障害に耐えられる推奨セットアップの場合、`5`台の**independent**マシンにLinuxパッケージをインストールする必要があります。**Redis**と**Sentinel**の両方を含みます:

- Redisプライマリ + Sentinel
- Redisレプリカ + Sentinel
- Redisレプリカ + Sentinel
- Redisレプリカ + Sentinel
- Redisレプリカ + Sentinel

### Redisセットアップの概要 {#redis-setup-overview}

少なくとも`3`台のRedisサーバー（`1`台のプライマリ、`2`台のレプリカ）が必要で、それぞれ独立したマシン上に設置されている必要があります。

追加のRedisノードを持つことで、より多くのノードがダウンする状況でも存続することができます。オンラインのノードが`2`つしかない場合、フェイルオーバーは開始されません。

例として、`6`台のRedisノードがある場合、最大`3`台が同時にダウンしても対応できます。

Sentinelノードには異なる要件があります。同じRedisマシンでホストする場合、プロビジョニングするされるノードの量を計算する際に、その制限を考慮に入れる必要があるかもしれません。詳細については、[Sentinel setup overview](#sentinel-setup-overview)ドキュメントを参照してください。

すべてのRedisノードは同じ方法で、類似のサーバー仕様で設定する必要があります。フェイルオーバー時には、どの**Replica**でもSentinelサーバーによって新しい**プライマリ**としてプロモートされる可能性があるためです。

レプリケーションには認証が必要であるため、すべてのRedisノードとSentinelを保護するためにパスワードを定義する必要があります。それらすべてが同じパスワードを共有し、すべてのインスタンスがネットワーク経由で互いに通信できる必要があります。

### Sentinelセットアップの概要 {#sentinel-setup-overview}

Sentinelは、他のSentinelとRedisノードの両方を監視します。SentinelがRedisノードが応答していないことを検出すると、そのノードのステータスを他のSentinelに通知します。Sentinelは、_quorum_（ノードがダウンしていることに同意するSentinelの最小数）に到達して、フェイルオーバーを開始できる必要があります。

**quorum**が満たされると、既知のすべてのSentinelノードの**majority**が利用可能で到達可能である必要があり、それによってサービス可用性を復元するためのすべての決定を下すSentinelの**leader**を選出できます:

- 新しい**プライマリ**をプロモートする
- 他の**Replicas**を再設定するし、新しい**プライマリ**を指すようにします。
- 新しい**プライマリ**を他のすべてのSentinelピアに通知します。
- 古い**プライマリ**を再設定するし、オンラインに戻ったときに**Replica**に降格させます。

少なくとも`3`台のRedis Sentinelサーバーが必要で、それぞれ独立したマシン（独立して失敗すると考えられる）に設置されている必要があり、理想的には異なる地理的地域に配置します。

他のRedisサーバーを設定したのと同じマシンにそれらを設定できますが、ノード全体がダウンすると、SentinelとRedisインスタンスの両方を失うことを理解してください。

障害発生時に合意アルゴリズムを効果的に機能させるには、Sentinelの数は理想的には常に**奇数**にする必要があります。

`3`ノードトポロジーでは、`1`台のSentinelノードがダウンするまでしか許容できません。Sentinelの**過半数**がダウンすると、ネットワークパーティション保護によって破壊的なアクションが防止され、フェイルオーバーは**開始されません**。

次に例を示します: 

- `5`または`6`台のSentinelがある場合、フェイルオーバーが開始されるまでに最大`2`台がダウンしても問題ありません。
- `7`台のSentinelがある場合、最大`3`ノードがダウンしても問題ありません。

**Leader**の選出は、**consensus**が達成されない場合、投票ラウンドで失敗することがあります。その場合、`sentinel['failover_timeout']`で定義された時間（ミリ秒単位）が経過した後に、再試行されます。

> [!note]
> `sentinel['failover_timeout']`がどこで定義されているかは後で確認できます。

`failover_timeout`変数には多くの異なるユースケースがあります。公式ドキュメントによると:

- 特定のSentinelによって同じプライマリに対して以前に試行されたフェイルオーバーの後で、フェイルオーバーを再開するために必要な時間は、フェイルオーバータイムアウトの2倍です。

- Sentinelの現在の設定に従って誤ったプライマリにレプリカがレプリケートする場合、正しいプライマリにレプリケートすることを強制するために必要な時間は、正確にフェイルオーバータイムアウトです（Sentinelが設定ミスを検出した瞬間からカウント）。

- すでに進行中であるが設定変更を生成しなかったフェイルオーバーをキャンセルするために必要な時間（プロモートされたレプリカによってまだ承認されていないREPLICAOF NO ONE）。

- 進行中のフェイルオーバーが、すべてのレプリカが新しいプライマリのレプリカとして再設定されるのを待つ最大時間。ただし、この時間が経過した後でも、レプリカはSentinelによって再設定されるしますが、指定された正確な並列同期の進行ではありません。

## Redisの設定 {#configuring-redis}

このセクションでは、新しいRedisインスタンスをインストールしてセットアップします。

GitLabとすべてのコンポーネントをゼロからインストールしているものと仮定します。すでにRedisがインストールされ実行されている場合は、[単一マシンでのインストールから切り替える](#switching-from-an-existing-single-machine-installation)方法をお読みください。

> [!note]
> Redisノード（プライマリとレプリカの両方）には、`redis['password']`で定義されたのと同じパスワードが必要です。フェイルオーバー中はいつでも、Sentinelはノードを再設定するし、そのステータスをプライマリからレプリカに変更したり、その逆も可能です。

### 要件 {#requirements}

Redisのセットアップの要件は次のとおりです。

1. [recommended setup](#recommended-setup)セクションで指定されている最小限必要な数のインスタンスをプロビジョニングするします。
1. RedisまたはRedis SentinelをGitLabアプリケーションが実行されているのと同じマシンにインストールすることは**Do not**。これはHA設定を弱めるためです。ただし、同じマシンにRedisとSentinelをインストールすることもできます。
1. すべてのRedisノードは、相互に通信でき、Redis（`6379`）およびSentinel（`26379`）ポート経由で受信接続を受け入れることができる必要があります（デフォルトを変更しない限り）。
1. GitLabアプリケーションをホストするサーバーは、Redisノードにアクセスできる必要があります。
1. ファイアウォールを使用して、外部ネットワーク（[Internet](https://gitlab.com/gitlab-org/gitlab-foss/uploads/c4cc8cd353604bd80315f9384035ff9e/The_Internet_IT_Crowd.png)）からのアクセスからノードを保護します。

### 既存の単一マシンインストールからの切り替え {#switching-from-an-existing-single-machine-installation}

すでに単一マシンのGitLabが実行されている場合、その内部のRedisインスタンスを非アクティブ化する前に、まずこのマシンからレプリケートする必要があります。

単一マシンでのインストールは初期の**プライマリ**であり、他の`3`台はこのマシンを指すように**Replica**として設定する必要があります。

レプリケーションが追いついた後、単一マシンのインストールでサービスを停止し、**プライマリ**を新しいノードのいずれかにローテーションする必要があります。

設定に必要な変更を加え、新しいノードを再度再起動してください。

単一インストールでRedisを無効にするには、`/etc/gitlab/gitlab.rb`を編集します:

```ruby
redis['enable'] = false
```

最初にレプリケートすることに失敗すると、データ（未処理のバックグラウンドジョブ）を失う可能性があります。

### ステップ1.プライマリRedisインスタンスの設定 {#step-1-configuring-the-primary-redis-instance}

1. **プライマリ**RedisサーバーにSSHで接続します。
1. GitLabダウンロードページから、**steps 1 and 2**を使用して、目的のLinuxパッケージを[ダウンロードしてインストール](https://about.gitlab.com/install/)します。
   - 現在のインストールと同じバージョンとタイプ（Community版、Enterprise版）の正しいLinuxパッケージを選択していることを確認してください。
   - ダウンロードページで他のステップを完了しないでください。

1. `/etc/gitlab/gitlab.rb`を編集し、次の内容を追加します。

   ```ruby
   # Specify server role as 'redis_master_role'
   roles ['redis_master_role']

   # IP address pointing to a local IP that the other machines can reach to.
   # You can also set bind to '0.0.0.0' which listen in all interfaces.
   # If you really need to bind to an external accessible IP, make
   # sure you add extra firewall rules to prevent unauthorized access.
   redis['bind'] = '10.0.0.1'

   # Define a port so Redis can listen for TCP requests which allows other
   # machines to connect to it.
   redis['port'] = 6379

   # Set up password authentication for Redis (use the same password in all nodes).
   redis['password'] = 'redis-password-goes-here'
   ```

1. プライマリGitLabアプリケーションサーバーのみが移行を処理する必要があります。アップグレード時にデータベースの移行が実行されないようにするには、次の設定を`/etc/gitlab/gitlab.rb`ファイルに追加します:

   ```ruby
   gitlab_rails['auto_migrate'] = false
   ```

1. 変更を有効にするため、[GitLabを再設定](../restart_gitlab.md#reconfigure-a-linux-package-installation)します。

> [!note]
> SentinelやRedisのような複数のロールを`roles ['redis_sentinel_role', 'redis_master_role']`のように指定できます。[ロール](https://docs.gitlab.com/omnibus/roles/)の詳細については、こちらをご覧ください。

### ステップ2.レプリカRedisインスタンスの設定 {#step-2-configuring-the-replica-redis-instances}

1. **replica**RedisサーバーにSSHで接続します。
1. GitLabダウンロードページから、**steps 1 and 2**を使用して、目的のLinuxパッケージを[ダウンロードしてインストール](https://about.gitlab.com/install/)します。
   - 現在のインストールと同じバージョンとタイプ（Community版、Enterprise版）の正しいLinuxパッケージを選択していることを確認してください。
   - ダウンロードページで他のステップを完了しないでください。

1. `/etc/gitlab/gitlab.rb`を編集し、次の内容を追加します。

   ```ruby
   # Specify server role as 'redis_replica_role'
   roles ['redis_replica_role']

   # IP address pointing to a local IP that the other machines can reach to.
   # You can also set bind to '0.0.0.0' which listen in all interfaces.
   # If you really need to bind to an external accessible IP, make
   # sure you add extra firewall rules to prevent unauthorized access.
   redis['bind'] = '10.0.0.2'

   # Define a port so Redis can listen for TCP requests which allows other
   # machines to connect to it.
   redis['port'] = 6379

   # The same password for Redis authentication you set up for the primary node.
   redis['password'] = 'redis-password-goes-here'

   # The IP of the primary Redis node.
   redis['master_ip'] = '10.0.0.1'

   # Port of primary Redis server, uncomment to change to non default. Defaults
   # to `6379`.
   #redis['master_port'] = 6379
   ```

1. アップグレード時に再設定が自動的に実行されるのを防ぐには、以下を実行します:

   ```shell
   sudo touch /etc/gitlab/skip-auto-reconfigure
   ```

1. プライマリGitLabアプリケーションサーバーのみが移行を処理する必要があります。アップグレード時にデータベースの移行が実行されないようにするには、次の設定を`/etc/gitlab/gitlab.rb`ファイルに追加します:

   ```ruby
   gitlab_rails['auto_migrate'] = false
   ```

1. 変更を有効にするため、[GitLabを再設定](../restart_gitlab.md#reconfigure-a-linux-package-installation)します。
1. 他のすべてのレプリカノードについても、これらのステップを繰り返してください。

> [!note]
> SentinelやRedisのような複数のロールを`roles ['redis_sentinel_role', 'redis_master_role']`のように指定できます。[ロール](https://docs.gitlab.com/omnibus/roles/)の詳細については、こちらをご覧ください。

フェイルオーバー後もこれらの値を`/etc/gitlab/gitlab.rb`で再度変更する必要はありません。なぜなら、ノードはSentinelによって管理されており、`gitlab-ctl reconfigure`の後でも、同じSentinelによって設定が復元されるためです。

### ステップ3.Redis Sentinelインスタンスの設定 {#step-3-configuring-the-redis-sentinel-instances}

{{< history >}}

- [導入](https://gitlab.com/gitlab-org/gitlab/-/issues/235938)されたGitLab 16.1でのSentinelパスワード認証のサポート。

{{< /history >}}

Redisサーバーの設定が完了したので、Sentinelサーバーを設定しましょう。

Redisサーバーが正しく動作し、レプリケートしているかどうかわからない場合は、Sentinelの設定に進む前に、[トラブルシューティングレプリケーション](troubleshooting.md#troubleshooting-redis-replication)を読んで修正してください。

少なくとも`3`台のRedis Sentinelサーバーが必要で、それぞれ独立したマシンに設置されている必要があります。他のRedisサーバーを設定したのと同じマシンにそれらを設定できます。

GitLab Enterprise Editionを使用すると、Linuxパッケージを使って複数のマシンにSentinelデーモンを設定できます。

1. Redis SentinelをホストするサーバーにSSHで接続します。
1. **You can omit this step if the Sentinels is hosted in the same node as the other Redis instances**。

   GitLabダウンロードページから、**steps 1 and 2**を使用して、Linux Enterprise Editionパッケージを[ダウンロードしてインストール](https://about.gitlab.com/install/)します。
   - GitLabアプリケーションが実行されているのと同じバージョンの、正しいLinuxパッケージを選択していることを確認してください。
   - ダウンロードページで他のステップを完了しないでください。

1. `/etc/gitlab/gitlab.rb`を編集し、コンテンツを追加します（他のRedisインスタンスと同じノードにSentinelをインストールする場合、一部の値は以下で重複する可能性があります）:

   ```ruby
   roles ['redis_sentinel_role']

   # Must be the same in every sentinel node
   redis['master_name'] = 'gitlab-redis'

   # The same password for Redis authentication you set up for the primary node.
   redis['master_password'] = 'redis-password-goes-here'

   # The IP of the primary Redis node.
   redis['master_ip'] = '10.0.0.1'

   # Define a port so Redis can listen for TCP requests which allows other
   # machines to connect to it.
   redis['port'] = 6379

   # Port of primary Redis server, uncomment to change to non default. Defaults
   # to `6379`.
   #redis['master_port'] = 6379

   ## Configure Sentinel
   sentinel['bind'] = '10.0.0.1'

   ## Optional password for Sentinel authentication. Defaults to no password required.
   # sentinel['password'] = 'sentinel-password-goes here'

   # Port that Sentinel listens on, uncomment to change to non default. Defaults
   # to `26379`.
   # sentinel['port'] = 26379

   ## Quorum must reflect the amount of voting sentinels it take to start a failover.
   ## Value must NOT be greater then the amount of sentinels.
   ##
   ## The quorum can be used to tune Sentinel in two ways:
   ## 1. If a the quorum is set to a value smaller than the majority of Sentinels
   ##    we deploy, we are basically making Sentinel more sensible to primary failures,
   ##    triggering a failover as soon as even just a minority of Sentinels is no longer
   ##    able to talk with the primary.
   ## 1. If a quorum is set to a value greater than the majority of Sentinels, we are
   ##    making Sentinel able to failover only when there are a very large number (larger
   ##    than majority) of well connected Sentinels which agree about the primary being down.s
   sentinel['quorum'] = 2

   ## Consider unresponsive server down after x amount of ms.
   # sentinel['down_after_milliseconds'] = 10000

   ## Specifies the failover timeout in milliseconds. It is used in many ways:
   ##
   ## - The time needed to re-start a failover after a previous failover was
   ##   already tried against the same primary by a given Sentinel, is two
   ##   times the failover timeout.
   ##
   ## - The time needed for a replica replicating to a wrong primary according
   ##   to a Sentinel current configuration, to be forced to replicate
   ##   with the right primary, is exactly the failover timeout (counting since
   ##   the moment a Sentinel detected the misconfiguration).
   ##
   ## - The time needed to cancel a failover that is already in progress but
   ##   did not produced any configuration change (REPLICAOF NO ONE yet not
   ##   acknowledged by the promoted replica).
   ##
   ## - The maximum time a failover in progress waits for all the replica to be
   ##   reconfigured as replicas of the new primary. However even after this time
   ##   the replicas are reconfigured by the Sentinels anyway, but not with
   ##   the exact parallel-syncs progression as specified.
   # sentinel['failover_timeout'] = 60000
   ```

1. アップグレード時にデータベースの移行が実行されないようにするには、以下を実行します:

   ```shell
   sudo touch /etc/gitlab/skip-auto-reconfigure
   ```

   プライマリGitLabアプリケーションサーバーのみが移行を処理する必要があります。

1. 変更を有効にするため、[GitLabを再設定](../restart_gitlab.md#reconfigure-a-linux-package-installation)します。
1. 他のすべてのSentinelノードについても、これらのステップを繰り返してください。

### ステップ4.GitLabアプリケーションの設定 {#step-4-configuring-the-gitlab-application}

最後の部分は、メインのGitLabアプリケーションサーバーにRedis Sentinelサーバーと認証認証情報を通知することです。

新規または既存のインストールでSentinelサポートをいつでも有効または無効にできます。GitLabアプリケーションの観点からは、必要なのはSentinelノードに対する正しい認証情報だけです。

すべてのSentinelノードのリストは必要ありませんが、障害が発生した場合、リストされているノードの少なくとも1つにアクセスする必要があります。

> [!note]
> 以下のステップは、HAセットアップのために、理想的にはRedisまたはSentinelがインストールされていないGitLabアプリケーションサーバーで実行する必要があります。

1. GitLabアプリケーションがインストールされているサーバーにSSHで接続します。
1. `/etc/gitlab/gitlab.rb`を編集し、以下の行を追加/変更します:

   ```ruby
   ## Must be the same in every sentinel node
   redis['master_name'] = 'gitlab-redis'

   ## The same password for Redis authentication you set up for the primary node.
   redis['master_password'] = 'redis-password-goes-here'

   ## A list of sentinels with `host` and `port`
   gitlab_rails['redis_sentinels'] = [
     {'host' => '10.0.0.1', 'port' => 26379},
     {'host' => '10.0.0.2', 'port' => 26379},
     {'host' => '10.0.0.3', 'port' => 26379}
   ]
   # gitlab_rails['redis_sentinels_password'] = 'sentinel-password-goes-here' # uncomment and set it to the same value as in sentinel['password']
   ```

1. 変更を有効にするため、[GitLabを再設定](../restart_gitlab.md#reconfigure-a-linux-package-installation)します。

### ステップ5.モニタリングを有効にする {#step-5-enable-monitoring}

モニタリングを有効にする場合、**すべて**のRedisサーバーで有効にする必要があります。

1. 次のステップのために、ConsulサーバーノードのIPアドレスまたはDNSレコードである[`CONSUL_SERVER_NODES`](../postgresql/replication_and_failover.md#consul-information)を収集してください。これらは`Y.Y.Y.Y consul1.gitlab.example.com Z.Z.Z.Z`の形式で表示されます。

1. `/etc/gitlab/gitlab.rb`を作成/編集し、次の設定を追加します:

   ```ruby
   # Enable service discovery for Prometheus
   consul['enable'] = true
   consul['monitoring_service_discovery'] =  true

   # Replace placeholders
   # Y.Y.Y.Y consul1.gitlab.example.com Z.Z.Z.Z
   # with the addresses of the Consul server nodes
   consul['configuration'] = {
      retry_join: %w(Y.Y.Y.Y consul1.gitlab.example.com Z.Z.Z.Z),
   }

   # Set the network addresses that the exporters listen on
   node_exporter['listen_address'] = '0.0.0.0:9100'
   redis_exporter['listen_address'] = '0.0.0.0:9121'
   ```

1. `sudo gitlab-ctl reconfigure`を実行して設定をコンパイルします。

## 1つのプライマリ、2つのレプリカ、3つのSentinelを含む最小設定の例 {#example-of-a-minimal-configuration-with-1-primary-2-replicas-and-3-sentinels}

この例では、すべてのサーバーが`10.0.0.x`範囲のIPを持つ内部ネットワークインターフェースを持ち、これらのIPを使用して互いに接続できるものとします。

実際の使用では、他のマシンからの不正アクセスを防ぎ、外部（Internet）からのトラフィックをブロックするために、ファイアウォールルールも設定します。

[Redisセットアップの概要](#redis-setup-overview)および[Sentinelセットアップの概要](#sentinel-setup-overview)ドキュメントで説明されている、**Redis** + **Sentinel**トポロジーを持つ同じ`3`ノードを使用します。

各**machine**と割り当てられた**IP**のリストと説明は次のとおりです:

- `10.0.0.1`: Redisプライマリ + Sentinel 1
- `10.0.0.2`: Redisレプリカ1 + Sentinel 2
- `10.0.0.3`: Redisレプリカ2 + Sentinel 3
- `10.0.0.4`: GitLabアプリケーション

初期設定後、Sentinelノードによってフェイルオーバーが開始されると、Redisノードは再設定されるし、**プライマリ**は（`redis.conf`内を含め）一方のノードから他方に永続的に変更され、新しいフェイルオーバーが再び開始されるまで続きます。

同様のことが`sentinel.conf`でも発生します。これは初期実行後に上書きされ、新しいSentinelノードが**プライマリ**の監視を開始した後、またはフェイルオーバーによって異なる**プライマリ**ノードがプロモートされた後に起こります。

### RedisプライマリとSentinel 1の設定例 {#example-configuration-for-redis-primary-and-sentinel-1}

`/etc/gitlab/gitlab.rb`で次を行います:

```ruby
roles ['redis_sentinel_role', 'redis_master_role']
redis['bind'] = '10.0.0.1'
redis['port'] = 6379
redis['password'] = 'redis-password-goes-here'
redis['master_name'] = 'gitlab-redis' # must be the same in every sentinel node
redis['master_password'] = 'redis-password-goes-here' # the same value defined in redis['password'] in the primary instance
redis['master_ip'] = '10.0.0.1' # ip of the initial primary redis instance
#redis['master_port'] = 6379 # port of the initial primary redis instance, uncomment to change to non default
sentinel['bind'] = '10.0.0.1'
# sentinel['password'] = 'sentinel-password-goes-here' # must be the same in every sentinel node, uncomment to set a password
# sentinel['port'] = 26379 # uncomment to change default port
sentinel['quorum'] = 2
# sentinel['down_after_milliseconds'] = 10000
# sentinel['failover_timeout'] = 60000
```

変更を有効にするため、[GitLabを再設定](../restart_gitlab.md#reconfigure-a-linux-package-installation)します。

### Redisレプリカ1とSentinel 2の設定例 {#example-configuration-for-redis-replica-1-and-sentinel-2}

`/etc/gitlab/gitlab.rb`で次を行います:

```ruby
roles ['redis_sentinel_role', 'redis_replica_role']
redis['bind'] = '10.0.0.2'
redis['port'] = 6379
redis['password'] = 'redis-password-goes-here'
redis['master_password'] = 'redis-password-goes-here'
redis['master_ip'] = '10.0.0.1' # IP of primary Redis server
#redis['master_port'] = 6379 # Port of primary Redis server, uncomment to change to non default
redis['master_name'] = 'gitlab-redis' # must be the same in every sentinel node
sentinel['bind'] = '10.0.0.2'
# sentinel['password'] = 'sentinel-password-goes-here' # must be the same in every sentinel node, uncomment to set a password
# sentinel['port'] = 26379 # uncomment to change default port
sentinel['quorum'] = 2
# sentinel['down_after_milliseconds'] = 10000
# sentinel['failover_timeout'] = 60000
```

変更を有効にするため、[GitLabを再設定](../restart_gitlab.md#reconfigure-a-linux-package-installation)します。

### Redisレプリカ2とSentinel 3の設定例 {#example-configuration-for-redis-replica-2-and-sentinel-3}

`/etc/gitlab/gitlab.rb`で次を行います:

```ruby
roles ['redis_sentinel_role', 'redis_replica_role']
redis['bind'] = '10.0.0.3'
redis['port'] = 6379
redis['password'] = 'redis-password-goes-here'
redis['master_password'] = 'redis-password-goes-here'
redis['master_ip'] = '10.0.0.1' # IP of primary Redis server
#redis['master_port'] = 6379 # Port of primary Redis server, uncomment to change to non default
redis['master_name'] = 'gitlab-redis' # must be the same in every sentinel node
sentinel['bind'] = '10.0.0.3'
# sentinel['password'] = 'sentinel-password-goes-here' # must be the same in every sentinel node, uncomment to set a password
# sentinel['port'] = 26379 # uncomment to change default port
sentinel['quorum'] = 2
# sentinel['down_after_milliseconds'] = 10000
# sentinel['failover_timeout'] = 60000
```

変更を有効にするため、[GitLabを再設定](../restart_gitlab.md#reconfigure-a-linux-package-installation)します。

### GitLabアプリケーションの設定例 {#example-configuration-for-the-gitlab-application}

`/etc/gitlab/gitlab.rb`で次を行います:

```ruby
redis['master_name'] = 'gitlab-redis'
redis['master_password'] = 'redis-password-goes-here'
gitlab_rails['redis_sentinels'] = [
  {'host' => '10.0.0.1', 'port' => 26379},
  {'host' => '10.0.0.2', 'port' => 26379},
  {'host' => '10.0.0.3', 'port' => 26379}
]
# gitlab_rails['redis_sentinels_password'] = 'sentinel-password-goes-here' # uncomment and set it to the same value as in sentinel['password']
```

変更を有効にするため、[GitLabを再設定](../restart_gitlab.md#reconfigure-a-linux-package-installation)します。

## 高度な設定 {#advanced-configuration}

このセクションでは、推奨される最小設定を超える設定オプションについて説明します。

### 複数のRedisクラスターの実行 {#running-multiple-redis-clusters}

Linuxパッケージは、異なる永続性クラス向けに個別のRedisとSentinelインスタンスの実行をサポートしています。

| クラス              | 目的 |
|--------------------|---------|
| `cache`            | キャッシュされたデータを保存します。 |
| `queues`           | Sidekiqバックグラウンドジョブを保存します。 |
| `shared_state`     | セッション関連およびその他の永続データを保存します。 |
| `actioncable`      | ActionCable用のPub/Subキューバックエンド。 |
| `trace_chunks`     | [CIトレースチャンク](../cicd/job_logs.md#incremental-logging)データを保存します。 |
| `rate_limiting`    | [レート制限](../settings/user_and_ip_rate_limits.md)の状態を保存します。 |
| `sessions`         | セッションを保存します。 |
| `repository_cache` | リポジトリに固有のキャッシュデータを保存します。 |

これをSentinelで動作させるには:

1. ニーズに基づいて、異なる[Redis/Sentinelを設定](#configuring-redis)インスタンスを構成します。
1. 各Railsアプリケーションインスタンスについて、`/etc/gitlab/gitlab.rb`ファイルを編集します:

   ```ruby
   gitlab_rails['redis_cache_instance'] = REDIS_CACHE_URL
   gitlab_rails['redis_queues_instance'] = REDIS_QUEUES_URL
   gitlab_rails['redis_shared_state_instance'] = REDIS_SHARED_STATE_URL
   gitlab_rails['redis_actioncable_instance'] = REDIS_ACTIONCABLE_URL
   gitlab_rails['redis_trace_chunks_instance'] = REDIS_TRACE_CHUNKS_URL
   gitlab_rails['redis_rate_limiting_instance'] = REDIS_RATE_LIMITING_URL
   gitlab_rails['redis_sessions_instance'] = REDIS_SESSIONS_URL
   gitlab_rails['redis_repository_cache_instance'] = REDIS_REPOSITORY_CACHE_URL

   # Configure the Sentinels
   gitlab_rails['redis_cache_sentinels'] = [
     { host: REDIS_CACHE_SENTINEL_HOST, port: 26379 },
     { host: REDIS_CACHE_SENTINEL_HOST2, port: 26379 }
   ]
   gitlab_rails['redis_queues_sentinels'] = [
     { host: REDIS_QUEUES_SENTINEL_HOST, port: 26379 },
     { host: REDIS_QUEUES_SENTINEL_HOST2, port: 26379 }
   ]
   gitlab_rails['redis_shared_state_sentinels'] = [
     { host: SHARED_STATE_SENTINEL_HOST, port: 26379 },
     { host: SHARED_STATE_SENTINEL_HOST2, port: 26379 }
   ]
   gitlab_rails['redis_actioncable_sentinels'] = [
     { host: ACTIONCABLE_SENTINEL_HOST, port: 26379 },
     { host: ACTIONCABLE_SENTINEL_HOST2, port: 26379 }
   ]
   gitlab_rails['redis_trace_chunks_sentinels'] = [
     { host: TRACE_CHUNKS_SENTINEL_HOST, port: 26379 },
     { host: TRACE_CHUNKS_SENTINEL_HOST2, port: 26379 }
   ]
   gitlab_rails['redis_rate_limiting_sentinels'] = [
     { host: RATE_LIMITING_SENTINEL_HOST, port: 26379 },
     { host: RATE_LIMITING_SENTINEL_HOST2, port: 26379 }
   ]
   gitlab_rails['redis_sessions_sentinels'] = [
     { host: SESSIONS_SENTINEL_HOST, port: 26379 },
     { host: SESSIONS_SENTINEL_HOST2, port: 26379 }
   ]
   gitlab_rails['redis_repository_cache_sentinels'] = [
     { host: REPOSITORY_CACHE_SENTINEL_HOST, port: 26379 },
     { host: REPOSITORY_CACHE_SENTINEL_HOST2, port: 26379 }
   ]

   # gitlab_rails['redis_cache_sentinels_password'] = 'sentinel-password-goes-here'
   # gitlab_rails['redis_queues_sentinels_password'] = 'sentinel-password-goes-here'
   # gitlab_rails['redis_shared_state_sentinels_password'] = 'sentinel-password-goes-here'
   # gitlab_rails['redis_actioncable_sentinels_password'] = 'sentinel-password-goes-here'
   # gitlab_rails['redis_trace_chunks_sentinels_password'] = 'sentinel-password-goes-here'
   # gitlab_rails['redis_rate_limiting_sentinels_password'] = 'sentinel-password-goes-here'
   # gitlab_rails['redis_sessions_sentinels_password'] = 'sentinel-password-goes-here'
   # gitlab_rails['redis_repository_cache_sentinels_password'] = 'sentinel-password-goes-here'
   ```

   - Redis URLは`redis://:PASSWORD@SENTINEL_PRIMARY_NAME`の形式である必要があります。ここで、:
     - `PASSWORD`は、Redisインスタンスのプレーンテキストパスワードです。
     - `SENTINEL_PRIMARY_NAME`は、`redis['master_name']`で設定されたSentinelプライマリ名であり、例えば`gitlab-redis-cache`です。

1. ファイルを保存し、変更を有効にするためにGitLabを再設定するします:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

> [!note]
> 各永続性クラスについて、GitLabは、以前に説明した設定によって上書きされない限り、`gitlab_rails['redis_sentinels']`で指定された設定を使用するようデフォルトで設定されています。

### 実行中のサービスを制御する {#control-running-services}

前の例では、`redis_sentinel_role`と`redis_master_role`を使用しました。これにより、設定変更の量が簡素化されます。

より詳細な制御が必要な場合は、有効にしたときにそれぞれが自動的に設定する内容を次に示します:

```ruby
## Redis Sentinel Role
redis_sentinel_role['enable'] = true

# When Sentinel Role is enabled, the following services are also enabled
sentinel['enable'] = true

# The following services are disabled
redis['enable'] = false
bootstrap['enable'] = false
nginx['enable'] = false
postgresql['enable'] = false
gitlab_rails['enable'] = false
mailroom['enable'] = false

-------

## Redis primary/replica Role
redis_master_role['enable'] = true # enable only one of them
redis_replica_role['enable'] = true # enable only one of them

# When Redis primary or Replica role are enabled, the following services are
# enabled/disabled. If Redis and Sentinel roles are combined, both
# services are enabled.

# The following services are disabled
sentinel['enable'] = false
bootstrap['enable'] = false
nginx['enable'] = false
postgresql['enable'] = false
gitlab_rails['enable'] = false
mailroom['enable'] = false

# For Redis Replica role, also change this setting from default 'true' to 'false':
redis['master'] = false
```

[`gitlab_rails.rb`](https://gitlab.com/gitlab-org/omnibus-gitlab/blob/master/files/gitlab-cookbooks/gitlab/libraries/gitlab_rails.rb)で定義されている関連する属性を見つけることができます。

### 起動動作を制御する {#control-startup-behavior}

{{< history >}}

- GitLab 15.10で[導入](https://gitlab.com/gitlab-org/omnibus-gitlab/-/merge_requests/6646)されました。

{{< /history >}}

バンドルされたRedisサービスが起動時に開始されたり、設定の変更後に再起動されたりするのを防ぐには:

1. `/etc/gitlab/gitlab.rb`を編集します:

   ```ruby
   redis['start_down'] = true
   ```

1. GitLabを再設定します:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

新しいレプリカノードをテストする必要がある場合、`start_down`を`true`に設定し、手動でノードを起動できます。新しいレプリカノードがRedisクラスターで動作することを確認した後、`start_down`を`false`に設定し、GitLabを再設定するして、ノードが操作中に期待どおりに起動および再起動することを確認します。

### レプリカ設定の制御 {#control-replica-configuration}

{{< history >}}

- GitLab 15.10で[導入](https://gitlab.com/gitlab-org/omnibus-gitlab/-/merge_requests/6646)されました。

{{< /history >}}

`replicaof`行がRedis設定ファイルにレンダリングされるのを防ぐには:

1. `/etc/gitlab/gitlab.rb`を編集します:

   ```ruby
   redis['set_replicaof'] = false
   ```

1. GitLabを再設定します:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

この設定は、他のRedis設定とは独立して、Redisノードのレプリケーションを防ぐために使用できます。

## Redisの代わりにValkeyを使用する {#use-valkey-instead-of-redis}

{{< details >}}

- ステータス: ベータ版

{{< /details >}}

{{< history >}}

- GitLab 18.9で[ベータ版](../../policy/development_stages_support.md#beta)として[導入](https://gitlab.com/gitlab-org/omnibus-gitlab/-/merge_requests/9113)されました。

{{< /history >}}

Redisのレプリケーションおよびフェイルオーバーのセットアップにおいて、[Valkey](https://valkey.io/)をドロップイン置換として使用できます。Valkeyは、Redisと同じロールと設定オプションを使用します。

Redisの代わりにValkeyを使用することは、[ベータ](../../policy/development_stages_support.md#beta)機能です。

### Valkeyプライマリおよびレプリカノードの設定 {#configure-valkey-primary-and-replica-nodes}

各ノード（プライマリとレプリカ）で、RedisからValkeyに切り替えるために、`/etc/gitlab/gitlab.rb`に以下を追加します:

```ruby
# Use the same Redis roles
roles ['redis_master_role']  # or 'redis_replica_role' for replicas

# Switch to Valkey
redis['backend'] = 'valkey'

# Use the same configuration options as for Redis
redis['bind'] = '10.0.0.1'
redis['port'] = 6379
redis['password'] = 'redis-password-goes-here'

gitlab_rails['auto_migrate'] = false
```

### ValkeyのSentinelを設定する {#configure-sentinel-for-valkey}

各Sentinelノードで、`/etc/gitlab/gitlab.rb`に以下を追加します:

```ruby
roles ['redis_sentinel_role']

# Switch redis backend to Valkey
# Then Sentinel will use the same backend
redis['backend'] = 'valkey'

# Sentinel configuration (same as for Redis)
redis['master_name'] = 'gitlab-redis'
redis['master_password'] = 'redis-password-goes-here'
redis['master_ip'] = '10.0.0.1'
redis['port'] = 6379

sentinel['bind'] = '10.0.0.1'
sentinel['quorum'] = 2
```

その他のすべてのSentinel設定オプションは、[Redis Sentinelインスタンスの設定](#step-3-configuring-the-redis-sentinel-instances)でドキュメント化されているものと同じです。

### 既知の問題 {#known-issues}

- 既知の[イシュー589642](https://gitlab.com/gitlab-org/gitlab/-/issues/589642)が原因で、管理者エリアはValkeyのバージョンを誤ってレポートします。このイシューは、インストールされているValkeyのバージョンやその機能には影響しません。

## トラブルシューティング {#troubleshooting}

[Redisトラブルシューティングガイド](troubleshooting.md)を参照してください。

## さらに詳しく {#further-reading}

詳細については、以下を参照してください。

1. [リファレンスアーキテクチャ](../reference_architectures/_index.md)
1. [データベースを設定する](../postgresql/replication_and_failover.md)
1. [NFSを設定する](../nfs.md)
1. [ロードバランサーを設定する](../load_balancer.md)
