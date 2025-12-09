---
stage: Runtime
group: Geo
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Geoセキュリティレビュー（Q＆A）
---

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

次のGeo機能セットのセキュリティレビューでは、独自のGitLabインスタンスを実行している顧客に適用される、この機能のセキュリティ面に焦点を当てています。レビューの質問は、[OWASPアプリケーションセキュリティ検証標準プロジェクト](https://owasp.org/www-project-application-security-verification-standard/) （[owasp.org](https://owasp.org/)）の一部に基づいています。

## ビジネスモデル {#business-model}

### アプリケーションサービスはどの地域を対象としていますか？ {#what-geographic-areas-does-the-application-service}

- これは顧客によって異なります。Geoを使用すると、顧客は複数の領域にデプロイでき、顧客はデプロイ場所を選択できます。
- 地域とノードの選択は完全に手動です。

## データエッセンシャル {#data-essentials}

### アプリケーションはどのようなデータを受信、生成、処理しますか？ {#what-data-does-the-application-receive-produce-and-process}

- Geoは、GitLabインスタンスが保持するほぼすべてのデータをサイト間で同期します。これには、完全なデータベースレプリケーション、ユーザーがアップロードした添付ファイルなどのほとんどのファイル、リポジトリ + Wikiデータが含まれます。一般的な設定では、これはパブリックインターネット経由で行われ、TLSで暗号化された状態になります。
- PostgreSQLレプリケーションはTLSで暗号化された状態になります。
- 参考：[TLSv1.2のみをサポートする必要があります](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/2948)

### データの機密性に応じて、データをカテゴリに分類するにはどうすればよいですか？ {#how-can-the-data-be-classified-into-categories-according-to-its-sensitivity}

- GitLabの機密性モデルは、パブリック、内部、プライベートのプロジェクトを中心としています。Geoは、それらをすべて無差別にレプリケートします。「選択的同期」は、ファイルとリポジトリ（ただしデータベースコンテンツではない）に存在し、必要に応じて、機密性の低いプロジェクトのみを**セカンダリ**サイトにレプリケートすることを許可します。

### アプリケーションに定義されているデータのバックアップと保持の要件は何ですか？ {#what-data-backup-and-retention-requirements-have-been-defined-for-the-application}

- Geoは、アプリケーションデータの特定のサブセットのレプリケーションを提供するように設計されています。それは問題の一部ではなく、ソリューションの一部です。

## エンドユーザー {#end-users}

### アプリケーションのエンドユーザーは誰ですか？ {#who-are-the-applications-end-users}

- **セカンダリ**サイトは、（インターネットレイテンシーに関して）メインのGitLabインストール（**プライマリ**サイト）から遠い地域に作成されます。これらは、通常の**プライマリ**サイトを使用するすべての人、つまり、**セカンダリ**サイトが（インターネットレイテンシーに関して）自分に近いと感じる人が使用することを目的としています。

### エンドユーザーはアプリケーションとどのように対話しますか？ {#how-do-the-end-users-interact-with-the-application}

- **セカンダリ**サイトは、**プライマリ**サイト（特にHTTP/HTTPS Webアプリケーション、およびHTTP/HTTPSまたはSSH Gitリポジトリアクセス）が提供するすべてのインターフェースを提供しますが、読み取り専用アクティビティーに制限されます。主なユースケースは、**セカンダリ**サイトからGitリポジトリをクローンして**プライマリ**サイトを優先することであると考えられていますが、エンドユーザーはGitLab Webインターフェースを使用して、プロジェクト、イシュー、マージリクエスト、スニペットなどの情報を表示できます。

### エンドユーザーはどのようなセキュリティを期待していますか？ {#what-security-expectations-do-the-end-users-have}

- レプリケーションプロセスは安全である必要があります。たとえば、データベースの内容全体またはすべてのファイルとリポジトリをパブリックインターネット経由で平文で送信することは、通常は容認できません。
- **セカンダリ**サイトは、**プライマリ**サイトと同じコンテンツに対するアクセス制御を持つ必要があります。認証されていないユーザーは、**プライマリ**サイトの特権情報に**セカンダリ**サイトにクエリを実行してアクセスできるようになってはなりません。
- 攻撃者は、**セカンダリ**サイトになりすまして**プライマリ**サイトにアクセスし、特権情報にアクセスできるようになってはなりません。

## 管理者 {#administrators}

### アプリケーションにはどのような管理機能がありますか？ {#who-has-administrative-capabilities-in-the-application}

- Geo固有の機能はありません。データベースで`admin: true`が設定されているユーザーは、スーパーユーザー権限を持つ管理者と見なされます。
- 参考：[よりきめ細かいアクセス制御](https://gitlab.com/gitlab-org/gitlab/-/issues/18242)（Geo固有ではありません）。
- Geoのインテグレーション（たとえば、データベースレプリケーション）の多くは、通常、システム管理者によってアプリケーションで設定する必要があります。

### アプリケーションはどのような管理機能を提供しますか？ {#what-administrative-capabilities-does-the-application-offer}

- **セカンダリ**サイトは、管理アクセス制御権を持つユーザーが追加、変更、または削除できます。
- レプリケーションプロセスは、Sidekiq管理アクセス制御を介して制御（開始/停止）できます。

## ネットワーク {#network}

### ルーティング、スイッチング、ファイアウォール、およびロードバランシングに関して、どのような詳細が定義されていますか？ {#what-details-regarding-routing-switching-firewalling-and-load-balancing-have-been-defined}

- Geoでは、**プライマリ**サイトと**セカンダリ**サイトがTCP/IPネットワークを介して相互に通信できる必要があります。特に、**セカンダリ**サイトは、**プライマリ**サイトのHTTP/HTTPSおよびPostgreSQLサービスにアクセスできる必要があります。

### アプリケーションをサポートする主なネットワークデバイスは何ですか？ {#what-core-network-devices-support-the-application}

- これは顧客によって異なります。

### どのようなネットワークパフォーマンス要件がありますか？ {#what-network-performance-requirements-exist}

- **プライマリ**サイトと**セカンダリ**サイト間の最大レプリケーション速度は、サイト間で利用可能な帯域幅によって制限されます。厳密な要件は存在しません。完了までの時間レプリケーション（および**プライマリ**サイトでの変更に追いつく能力）は、データセットのサイズ、レイテンシーに対する許容度、および利用可能なネットワーク容量の関数です。

### アプリケーションをサポートするプライベートおよびパブリックネットワークリンクは何ですか？ {#what-private-and-public-network-links-support-the-application}

- 顧客は独自のネットワークを選択します。サイトは地理的に分離されることを目的としているため、一般的なデプロイでは、レプリケーショントラフィックがパブリックインターネット経由で渡されることが想定されていますが、これは要件ではありません。

## システム {#systems}

### アプリケーションをサポートするオペレーティングシステムは何ですか？ {#what-operating-systems-support-the-application}

- Geoは、オペレーティングシステムに追加の制限を課していません（詳細については、[GitLabインストール](https://about.gitlab.com/install/)ページを参照してください）。ただし、[Geoドキュメント](../_index.md#requirements-for-running-geo)にリストされているオペレーティングシステムを使用することをお勧めします。

### 必要なOSコンポーネントとロックダウンのニーズに関して、どのような詳細が定義されていますか？ {#what-details-regarding-required-os-components-and-lock-down-needs-have-been-defined}

- サポートされているLinuxパッケージインストール方法では、ほとんどのコンポーネント自体がパッケージ化されています。
- システムにインストールされたOpenSSHデーモン（Geoでは、ユーザーがカスタム認証方法を設定する必要がある）と、Linuxパッケージが提供またはシステムが提供するPostgreSQLデーモン（TCPでリッスンするように設定する必要があり、追加のユーザーとレプリケーションスロットを追加する必要があるなど）に大きな依存関係があります。
- セキュリティアップデートに対処するためのプロセス（たとえば、OpenSSHまたはその他のサービスに重大な脆弱性があり、顧客がOS上のそれらのサービスにパッチを適用したい場合）は、Geoを使用しない場合と同じです。OpenSSHへのセキュリティアップデートは、通常の配布チャンネルを介してユーザーに提供されます。Geoはそこに遅延を導入しません。

## インフラストラクチャモニタリング {#infrastructure-monitoring}

### ネットワークとシステムのパフォーマンスモニタリングの要件として、どのような要件が定義されていますか？ {#what-network-and-system-performance-monitoring-requirements-have-been-defined}

- Geoに固有のものはありません。

### 悪意のあるコードまたは侵害されたアプリケーションコンポーネントを検出するためのメカニズムとして、どのようなメカニズムが存在しますか？ {#what-mechanisms-exist-to-detect-malicious-code-or-compromised-application-components}

- Geoに固有のものはありません。

### ネットワークおよびシステムのセキュリティモニタリング要件として、どのような要件が定義されていますか？ {#what-network-and-system-security-monitoring-requirements-have-been-defined}

- Geoに固有のものはありません。

## 仮想化と外部化 {#virtualization-and-externalization}

### アプリケーションのどの側面が仮想化に適していますか？ {#what-aspects-of-the-application-lend-themselves-to-virtualization}

- すべて。

## アプリケーションに定義されている仮想化要件は何ですか？ {#what-virtualization-requirements-have-been-defined-for-the-application}

- Geo固有のものはありませんが、GitLabのすべては、そのような環境で完全な機能を備えている必要があります。

### 製品のどの側面をクラウドコンピューティングモデルでホストできるものとできないものがありますか？ {#what-aspects-of-the-product-may-or-may-not-be-hosted-via-the-cloud-computing-model}

- GitLabは「クラウドコンピューティングネイティブ」であり、これは製品の他の部分と同じようにGeoにも当てはまります。クラウドでのデプロイは、一般的でサポートされているシナリオです。

## 該当する場合、クラウドコンピューティングに対するどのようなアプローチが取られますか？ {#if-applicable-what-approaches-to-cloud-computing-are-taken}

- これらを使用するかどうかは、運用上のニーズに応じて、お客様が決定します:

  - マネージドホスティング対「ピュア」クラウド
  - AWS-ED2などの「フルマシン」アプローチと、AWS-RDSやAzureなどの「ホストされたデータベース」アプローチ

## 環境 {#environment}

### アプリケーションの作成には、どのようなフレームワークとプログラミング言語が使用されていますか？ {#what-frameworks-and-programming-languages-have-been-used-to-create-the-application}

- Ruby on Rails、Ruby。

### アプリケーションに定義されているプロセス、コード、またはインフラストラクチャの依存関係は何ですか？ {#what-process-code-or-infrastructure-dependencies-have-been-defined-for-the-application}

- Geoに固有のものはありません。

### どのようなデータベースとアプリケーションサーバーがアプリケーションをサポートしていますか？ {#what-databases-and-application-servers-support-the-application}

- PostgreSQL >= 12、Redis、Sidekiq、Puma。

### データベース接続文字列、暗号化キー、およびその他の機密コンポーネントを保護するにはどうすればよいですか？ {#how-to-protect-database-connection-strings-encryption-keys-and-other-sensitive-components}

- Geo固有の値がいくつかあります。一部は共有シークレットであり、設定時に**プライマリ**サイトから**セカンダリ**サイトに安全に送信する必要があります。ドキュメントでは、**プライマリ**サイトからシステム管理者にSSH経由で送信し、同じ方法で**セカンダリ**サイトに戻すことをお勧めします。特に、これにはPostgreSQLレプリケーションの認証情報と、データベース内の特定の列を復号化するために使用されるシークレットキー（`db_key_base`）が含まれます。`db_key_base`シークレットは、他の多くのシークレットとともに、ファイルシステムの`/etc/gitlab/gitlab-secrets.json`に暗号化された状態で保存されません。それらに対する保存時保護はありません。

## データ処理 {#data-processing}

### アプリケーションはどのようなデータエントリパスをサポートしていますか？ {#what-data-entry-paths-does-the-application-support}

- データは、GitLab自体が公開しているWebアプリケーションを介してエントリされます。一部のデータは、GitLabサーバー上のシステム管理コマンド（たとえば、`gitlab-ctl set-primary-node`）を使用してエントリすることもできます。
- **セカンダリ**サイトは、**プライマリ**サイトからのPostgreSQLストリーミングレプリケーションを介して入力も受信します。

### アプリケーションはどのようなデータ出力パスをサポートしていますか？ {#what-data-output-paths-does-the-application-support}

- **プライマリ**サイトは、PostgreSQLストリーミングレプリケーションを介して**セカンダリ**サイトに出力します。それ以外の場合は、主にGitLab自体が公開するWebアプリケーションを介して、およびエンドユーザーが開始したSSH `git clone`操作を介して行われます。

### アプリケーションの内部コンポーネント全体でデータはどのようにトラフィックしますか？ {#how-does-data-flow-across-the-applications-internal-components}

- **セカンダリ**サイトと**プライマリ**サイトは、HTTP/HTTPS（JSON Webトークンで保護）およびPostgreSQLストリーミングレプリケーションを介して相互作用します。
- **プライマリ**サイトまたは**セカンダリ**サイト内では、SSOTは、ファイルシステムとデータベース（**セカンダリ**サイトのGeoトラッキングデータベースを含む）です。さまざまな内部コンポーネントがオーケストレーションを行い、これらのストアに変更を加えます。

### どのようなデータ入力検証要件が定義されていますか？ {#what-data-input-validation-requirements-have-been-defined}

- **セカンダリ**サイトは、**プライマリ**サイトのデータの忠実なレプリケーションを持っている必要があります。

### アプリケーションはどのようなデータをどのように保存しますか？ {#what-data-does-the-application-store-and-how}

- Gitリポジトリとファイル、それらに関連する追跡情報、およびGitLabデータベースの内容。

### どのようなデータを暗号化する必要がありますか？どのようなキー管理要件が定義されていますか？ {#what-data-should-be-encrypted-what-key-management-requirements-are-defined}

- **プライマリ**サイトも**セカンダリ**サイトも、保存時にGitリポジトリまたはファイルシステムのデータを暗号化しません。データベース列のサブセットは、`db_otp_key`を使用して保存時に暗号化されます。
- GitLabデプロイ内のすべてのホスト間で共有される静的なシークレット。
- 転送時、データは暗号化された状態である必要がありますが、アプリケーションは暗号化されていない通信の続行を許可します。2つの主な転送は、PostgreSQLの**セカンダリ**サイトのレプリケーションプロセスと、Gitリポジトリ/ファイルの場合です。どちらもTLSを使用して保護する必要があり、そのキーは、GitLabへのエンドユーザーアクセスに対する既存の設定ごとにLinuxパッケージによって管理されます。

### 機密データの漏洩を検出するためにどのような機能が存在しますか？ {#what-capabilities-exist-to-detect-the-leakage-of-sensitive-data}

- GitLabとPostgreSQLへのすべての接続を追跡する包括的なシステムログが存在します。

### 転送時のデータに対して、どのような暗号化要件が定義されていますか？ {#what-encryption-requirements-have-been-defined-for-data-in-transit}

- （これには、WAN、LAN、SecureFTP、または`http:`や`https:`などの公開されているプロトコルを介した送信が含まれます）。
- データには、転送時に暗号化された状態にするオプションがあり、受動的および能動的な攻撃者から保護されている必要があります（たとえば、MITM攻撃者は不可能である必要があります）。

## アクセス {#access}

### アプリケーションはどのようなユーザー権限レベルをサポートしていますか？ {#what-user-privilege-levels-does-the-application-support}

- Geoは1種類の権限を追加します。**セカンダリ**サイトは、特別なGeo APIにアクセスしてHTTP/HTTPS経由でファイルをダウンロードしたり、HTTP/HTTPSを使用してリポジトリをクローンしたりできます。

### どのようなユーザー識別および認証要件が定義されていますか？ {#what-user-identification-and-authentication-requirements-have-been-defined}

- **セカンダリ**サイトは、共有データベース（HTTPアクセス）またはPostgreSQLレプリケーションユーザー（データベースレプリケーションの場合）に基づいて、OAuthまたはJWT認証を介してGeo **プライマリ**サイトを識別します。データベースレプリケーションでは、IPベースのアクセス制御も定義する必要があります。

### どのようなユーザー認可要件が定義されていますか？ {#what-user-authorization-requirements-have-been-defined}

- **セカンダリ**サイトは、データの読み取りのみを実行できる必要があります。彼らは**プライマリ**サイトのデータを変更できません。

### どのようなセッション管理要件が定義されていますか？ {#what-session-management-requirements-have-been-defined}

- Geo JWTは、再生成が必要になるまでわずか2分間持続するように定義されています。
- Geo JWTは、次の特定のスコープのいずれかに対して生成されます:
  - Geo APIアクセス。
  - Gitアクセス。
  - LFSとファイルID。
  - アップロードとファイルID。
  - ジョブアーティファクトとファイルID。

### URIおよびサービス呼び出しに対して、どのようなアクセス要件が定義されていますか？ {#what-access-requirements-have-been-defined-for-uri-and-service-calls}

- **セカンダリ**サイトは、**プライマリ**サイトのAPIに多くの呼び出しを行います。たとえば、これによりファイルレプリケーションが進行します。このエンドポイントには、JWTトークンでのみアクセスできます。
- **プライマリ**サイトは、ステータス情報を取得するために**セカンダリ**サイトにも呼び出しを行います。

## アプリケーションモニタリング {#application-monitoring}

### 監査ログとデバッグログには、どのようにアクセス、保存、および保護されますか？ {#how-are-audit-and-debug-logs-accessed-stored-and-secured}

- 構造化されたJSONログはファイルシステムに書き込まれ、さらに分析するためにKibanaインストールにインジェストすることもできます。
