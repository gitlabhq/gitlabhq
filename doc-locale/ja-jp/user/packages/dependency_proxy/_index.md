---
stage: Package
group: Container Registry
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: コンテナイメージの依存プロキシ
description: アップストリームコンテナイメージからのデータ転送を削減するには、コンテナイメージにGitLab依存プロキシを設定します。
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

コンテナイメージ用のGitLab依存プロキシは、頻繁にアクセスするアップストリームイメージに使用可能なローカルプロキシです。

CI/CDの場合、依存プロキシはリクエストを受信し、プルスルーキャッシュとして機能し、レジストリからアップストリームイメージを返します。

## 前提要件 {#prerequisites}

コンテナイメージの依存プロキシを使用するには、GitLabインスタンスで有効にする必要があります。デフォルトで有効になっていますが、[管理者はオフにすることができます](../../../administration/packages/dependency_proxy.md)。

### サポートされているイメージとパッケージ {#supported-images-and-packages}

次のイメージとパッケージがサポートされています。

| イメージ/パッケージ    | GitLabバージョン |
| ---------------- | -------------- |
| Docker           | 14.0+         |

予定されている追加機能のリストについては、[方向性のページ](https://about.gitlab.com/direction/package/#dependency-proxy)をご覧ください。

## グループの依存プロキシを有効または無効にする {#enable-or-turn-off-the-dependency-proxy-for-a-group}

{{< history >}}

- GitLab 15.0で、必要なロールがデベロッパーからメンテナーに[変更](https://gitlab.com/gitlab-org/gitlab/-/issues/350682)されました。
- GitLab 17.0で、必要なロールがメンテナーからオーナーに[変更](https://gitlab.com/gitlab-org/gitlab/-/issues/370471)されました。

{{< /history >}}

グループの依存プロキシを有効または無効にするには、次の手順に従います:

1. 左側のサイドバーで、**検索または移動先**を選択して、グループを見つけます。
1. **設定** > **パッケージとレジストリ**を選択します。
1. **依存プロキシ**セクションを展開します。
1. プロキシを有効にするには、**Enable Proxy**（プロキシを有効にする）をオンにします。オフにするには、切替をオフにします。

この設定は、グループの依存プロキシにのみ影響します。GitLabインスタンス全体の[依存プロキシのオン/オフを切り替える](../../../administration/packages/dependency_proxy.md)ことができるのは管理者のみです。

## コンテナイメージの依存プロキシを表示する {#view-the-dependency-proxy-for-container-images}

コンテナイメージの依存プロキシを表示するには、次の手順に従います:

1. 左側のサイドバーで、**検索または移動先**を選択して、グループを見つけます。
1. **操作** > **依存プロキシ**を選択します。

依存プロキシはプロジェクトでは利用できません。

## Dockerイメージに依存プロキシを使用する {#use-the-dependency-proxy-for-docker-images}

GitLabをDockerイメージのソースとして使用できます。

前提要件:

- イメージは[Docker Hub](https://hub.docker.com/)に保存されている必要があります。

### コンテナイメージの依存プロキシで認証する {#authenticate-with-the-dependency-proxy-for-container-images}

{{< history >}}

- 機能フラグ`dependency_proxy_for_private_groups`は、GitLab 15.0で[削除](https://gitlab.com/gitlab-org/gitlab/-/issues/276777)されました。
- グループアクセストークンのサポートは、GitLab 16.3で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/362991)されました。
- デプロイトークンのスコープ`read_virtual_registry`および`write_virtual_registry`は、GitLab 17.11で`dependency_proxy_read_write_scopes`フラグとともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/336800)されました。デフォルトでは無効になっています。
- GitLab 18.0[で一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/517249)になりました。機能フラグ`dependency_proxy_read_write_scopes`は削除されました。

{{< /history >}}

コンテナイメージの依存プロキシは、グループに関連付けられた領域にDockerイメージを保存するため、認証する必要があります。

[プライベートレジストリからイメージを使用する手順](../../../ci/docker/using_docker_images.md#access-an-image-from-a-private-container-registry)に従いますが、`registry.example.com:5000`を使用する代わりに、ポート`gitlab.example.com`なしでGitLabドメインを使用します。

{{< alert type="note" >}}

[管理者モード](../../../administration/settings/sign_in_restrictions.md#admin-mode)は、コンテナイメージの依存プロキシで認証する際に適用されません。管理者モードが有効になっている管理者が、`admin_mode`スコープなしでパーソナルアクセストークンを作成した場合、管理者モードが有効になっていても、そのトークンは機能します。

{{< /alert >}}

たとえば、手動でサインインするには次を実行します:

```shell
echo "$CONTAINER_REGISTRY_PASSWORD" | docker login gitlab.example.com --username my_username --password-stdin
```

次のものを使用して認証できます:

- GitLabユーザー名とパスワード。
- [GitLab CLI](../../../editor_extensions/gitlab_cli/_index.md#use-the-cli-as-a-docker-credential-helper)。
- [パーソナルアクセストークン](../../profile/personal_access_tokens.md)。
- [グループデプロイトークン](../../project/deploy_tokens/_index.md)。
- グループの[グループアクセストークン](../../group/settings/group_access_tokens.md)。

トークンには、次のいずれかのスコープを設定する必要があります:

- `api`: APIへのフルアクセスを許可します。
- `read_registry`: コンテナレジストリへの読み取り専用アクセスを許可します。
- `write_registry`: コンテナレジストリへの読み取り/書き込みアクセスを許可します。
- `read_virtual_registry`: 依存プロキシを介したコンテナイメージへの読み取り専用アクセス（プル）を許可します。
- `write_virtual_registry`: 依存プロキシを介したコンテナイメージへの読み取りアクセス（プル）、書き込みアクセス（プッシュ）、および削除アクセスを許可します。

コンテナイメージの依存プロキシで認証する場合、次の条件を満たす必要があります:

- `read_virtual_registry`スコープを持つトークンには、`read_registry`スコープも含まれている必要があります。
- `write_virtual_registry`スコープを持つトークンには、`write_registry`スコープも含まれている必要があります。

パーソナルアクセストークンまたはユーザー名とパスワードを使用してコンテナイメージの依存プロキシにアクセスするユーザーは、イメージのプル元のグループに対して少なくともゲストロールを持っている必要があります。

コンテナイメージの依存プロキシは、[Docker v2トークン認証フロー](https://distribution.github.io/distribution/spec/auth/token/)に従い、プルリクエストに使用するJWTをクライアントに発行します。認証の結果として発行されるJWTは、一定時間後に期限切れになります。トークンの期限が切れると、ほとんどのDockerクライアントは認証情報を保存し、それ以上の操作なしに自動的に新しいトークンを要求します。

トークンの有効期限を[設定することも可能](../../../administration/packages/dependency_proxy.md#changing-the-jwt-expiration)です。GitLab.comでは、有効期限は15分です。

#### SAML SSO {#saml-sso}

[SSOの適用](../../group/saml_sso/_index.md#sso-enforcement)が有効になっている場合、ユーザーはコンテナイメージの依存プロキシを介してイメージをプルする前に、SSOを介してサインインする必要があります。

SSOの適用は[自動マージ](../../project/merge_requests/auto_merge.md)にも影響します。自動マージがトリガーされる前にSSOセッションが期限切れになった場合、マージパイプラインは依存プロキシを介してイメージをプルできません。

#### CI/CD内で認証する {#authenticate-within-cicd}

Runnerはコンテナイメージの依存プロキシに自動的にサインインします。依存プロキシを介してプルするには、[定義済み変数](../../../ci/variables/predefined_variables.md)のいずれかを次のように使用します:

- `CI_DEPENDENCY_PROXY_GROUP_IMAGE_PREFIX`は、トップレベルグループを介してプルします。
- `CI_DEPENDENCY_PROXY_DIRECT_GROUP_IMAGE_PREFIX`は、サブグループ、またはプロジェクトが存在する直接グループを介してプルします。

最新のalpineイメージをプルする例は、次のとおりです:

```yaml
# .gitlab-ci.yml
image: ${CI_DEPENDENCY_PROXY_GROUP_IMAGE_PREFIX}/alpine:latest
```

使用できる追加の定義済みCI/CD変数もあります。例は次のとおりです:

- `CI_DEPENDENCY_PROXY_USER`: 依存プロキシにログインするためのCI/CDユーザー。
- `CI_DEPENDENCY_PROXY_PASSWORD`: 依存プロキシにログインするためのCI/CDパスワード
- `CI_DEPENDENCY_PROXY_SERVER`: 依存プロキシにログインするためのサーバー。
- `CI_DEPENDENCY_PROXY_GROUP_IMAGE_PREFIX`: トップレベルグループから依存プロキシを介してイメージをプルするためのイメージプレフィックス。
- `CI_DEPENDENCY_PROXY_DIRECT_GROUP_IMAGE_PREFIX`: プロジェクトが属する直接グループまたはサブグループから依存プロキシを介してイメージをプルするためのイメージプレフィックス。

`CI_DEPENDENCY_PROXY_SERVER`、`CI_DEPENDENCY_PROXY_GROUP_IMAGE_PREFIX`、および`CI_DEPENDENCY_PROXY_DIRECT_GROUP_IMAGE_PREFIX`にはサーバーポートが含まれます。依存プロキシパスを明示的に含める場合、ポートを含めずに依存プロキシに手動でログインしていない限り、次のようにポートを含める必要があります:

```shell
docker pull gitlab.example.com:443/my-group/dependency_proxy/containers/alpine:latest
```

依存プロキシを使用してイメージをビルドする場合の例:

```plaintext
# Dockerfile
FROM gitlab.example.com:443/my-group/dependency_proxy/containers/alpine:latest
```

```yaml
# .gitlab-ci.yml
image: docker:20.10.16

variables:
  DOCKER_HOST: tcp://docker:2375
  DOCKER_TLS_CERTDIR: ""

services:
  - docker:20.10.16-dind

build:
  image: docker:20.10.16
  before_script:
    - echo "$CI_DEPENDENCY_PROXY_PASSWORD" | docker login $CI_DEPENDENCY_PROXY_SERVER -u $CI_DEPENDENCY_PROXY_USER --password-stdin
  script:
    - docker build -t test .
```

[カスタムCI/CD変数](../../../ci/variables/_index.md#for-a-project)を使用して、パーソナルアクセストークンまたはデプロイトークンを保存およびアクセスすることもできます。

### Docker Hubで認証する {#authenticate-with-docker-hub}

{{< history >}}

- Docker Hubの認証情報のサポートは、GitLab 17.10で[追加](https://gitlab.com/gitlab-org/gitlab/-/issues/331741)されました。
- UIのサポートは、GitLab 17.11で[追加](https://gitlab.com/gitlab-org/gitlab/-/issues/521954)されました。

{{< /history >}}

デフォルトでは、依存プロキシはDocker Hubからイメージをプルするときに認証情報を使用しません。Docker Hubの認証情報をトークンで設定できます。

Docker Hubでの認証には、次のものを使用できます:

- Docker Hubのユーザー名とパスワード。
  - この方法は、[シングルサインオン（SSO）を強制](https://docs.docker.com/security/faqs/single-sign-on/enforcement-faqs/#does-docker-sso-support-authenticating-through-the-command-line)するDocker Hub組織とは互換性がありません。
- Docker Hubの[パーソナルアクセストークン](https://docs.docker.com/security/for-developers/access-tokens/)。
- Docker Hubの[組織アクセストークン](https://docs.docker.com/security/for-admins/access-tokens/)。

#### 認証情報を設定する {#configure-credentials}

グループの依存プロキシに対してDocker Hubの認証情報を設定するには、次の手順に従います:

1. 左側のサイドバーで、**検索または移動先**を選択して、グループを見つけます。
1. **設定** > **パッケージとレジストリ**を選択します。
1. **依存プロキシ**セクションを展開します。
1. **Enable Proxy**（プロキシを有効にする）をオンにします。
1. **Docker Hubでの認証**で、次のように認証情報を入力します:
   - **アイデンティティ**には、ユーザー名または組織名（組織アクセストークン用）を入力します。
   - **シークレット**には、パスワード、パーソナルアクセストークン、または組織アクセストークンを入力します。

   両方のフィールドを入力するか、両方を空のままにする必要があります。両方のフィールドが空である場合、Docker Hubへのリクエストは認証されないままになります。

#### GraphQL APIを使用して認証情報を設定する {#configure-credentials-using-the-graphql-api}

[GraphQL API](../../../api/graphql/_index.md)を使用して、依存プロキシの設定でDocker Hubの認証情報を設定するには、次の手順に従います:

1. GraphiQLに移動します:
   - GitLab.comの場合は、[`https://gitlab.com/-/graphql-explorer`](https://gitlab.com/-/graphql-explorer)を使用します。
   - GitLab Self-Managedの場合は、`https://gitlab.example.com/-/graphql-explorer`を使用します。
1. GraphiQLで、次のミューテーションを入力します:

   ```graphql
   mutation {
     updateDependencyProxySettings(input: {
       enabled: true,
         identity: "<identity>",
         secret: "<secret>",
         groupPath: "<group path>"
     }) {
       dependencyProxySetting {
        enabled
        identity
       }
       errors
     }
   }
   ```

   各設定項目の意味は次のとおりです:
   - `<identity>`は、ユーザー名（パスワードまたはパーソナルアクセストークン用）または組織名（組織アクセストークン用）です。
   - `<secret>`は、パスワード、パーソナルアクセストークン、または組織アクセストークンです。
   - `<group path>`は、依存プロキシがあるグループのパスです。

1. **Play**（再生）を選択します。
1. 結果ペインでエラーがないか確認します。

#### 認証情報を検証する {#verify-your-credentials}

依存プロキシで認証したら、Dockerイメージをプルして、Docker Hubの認証情報を次のように確認します:

```shell
docker pull gitlab.example.com/groupname/dependency_proxy/containers/alpine:latest
```

認証が成功すると、[Docker Hub使用状況ダッシュボード](https://hub.docker.com/usage/pulls)にアクティビティーが表示されます。

### Dockerイメージを依存プロキシキャッシュに保存する {#store-a-docker-image-in-dependency-proxy-cache}

Dockerイメージを依存プロキシストレージに保存するには、次の手順に従います:

1. 左側のサイドバーで、**検索または移動先**を選択して、グループを見つけます。
1. **操作** > **依存プロキシ**を選択します。
1. **依存プロキシのイメージプレフィックス**をコピーします。
1. 次のコマンドのいずれかを使用します。これらの例では、イメージは`alpine:latest`です。
1. ダイジェストでイメージをプルして、プルするイメージのバージョンを正確に指定することもできます。

   - イメージを[`.gitlab-ci.yml`](../../../ci/yaml/_index.md#image)ファイルに追加して、タグでイメージをプルします:

     ```shell
     image: gitlab.example.com/groupname/dependency_proxy/containers/alpine:latest
     ```

   - イメージを[`.gitlab-ci.yml`](../../../ci/yaml/_index.md#image)ファイルに追加して、ダイジェストでイメージをプルします:

     ```shell
     image: ${CI_DEPENDENCY_PROXY_GROUP_IMAGE_PREFIX}/alpine@sha256:c9375e662992791e3f39e919b26f510e5254b42792519c180aad254e6b38f4dc
     ```

   - Dockerイメージを手動でプルします:

     ```shell
     docker pull gitlab.example.com/groupname/dependency_proxy/containers/alpine:latest
     ```

   - URLを`Dockerfile`に追加します:

     ```shell
     FROM gitlab.example.com/groupname/dependency_proxy/containers/alpine:latest
     ```

GitLabはDocker HubからDockerイメージをプルし、blobをGitLabサーバーにキャッシュします。次回同じイメージをプルすると、GitLabはDocker Hubからイメージに関する最新情報を取得しますが、GitLabサーバーから既存のblobを提供します。

## ストレージ使用量を削減する {#reduce-storage-usage}

コンテナイメージの依存プロキシでストレージ使用量を削減する方法については、[依存プロキシのストレージ使用量を削減する](reduce_dependency_proxy_storage.md)を参照してください。

## Docker Hubのレート制限と依存プロキシ {#docker-hub-rate-limits-and-the-dependency-proxy}

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i> [依存プロキシを使用してDocker Hubのレート制限を回避する方法](https://youtu.be/Nc4nUo7Pq08)をご覧ください。

Docker Hubは、[プルにレート制限](https://docs.docker.com/docker-hub/usage/pulls/)を適用します。GitLabの[CI/CD設定](../../../ci/_index.md)でDocker Hubからのイメージを使用している場合、ジョブが実行されるたびにプルとしてカウントされることがあります。この制限を回避するために、代わりに依存プロキシキャッシュからイメージをプルできます。

イメージをプルすると（`docker pull`のようなコマンドを使用するか、`.gitlab-ci.yml`ファイルで`image: foo:latest`を使用）、Dockerクライアントはリクエストのコレクションを作成します:

1. イメージマニフェストがリクエストされます。マニフェストには、イメージのビルド方法に関する情報が含まれています。
1. マニフェストを使用して、Dockerクライアントは（blobとも呼ばれる）レイヤーのコレクションを1つずつリクエストします。

Docker Hubのレート制限は、マニフェストに対するGETリクエストの数に基づいています。依存プロキシは、特定イメージのマニフェストとblobの両方をキャッシュするため、再度リクエストするときにDocker Hubに接続する必要はありません。

### キャッシュされたタグ付きイメージが古くなっているかどうかをGitLabが確認する方法 {#how-does-gitlab-know-if-a-cached-tagged-image-is-stale}

`alpine:latest`のようなイメージタグを使用している場合、イメージは時間の経過とともに変化します。変更されるたびに、マニフェストには、リクエストするblobに関するさまざまな情報が含まれます。依存プロキシは、マニフェストが変更されるたびに新しいイメージをプルするのではなく、マニフェストが古くなった場合にのみチェックします。

Dockerは、イメージマニフェストに対するHEADリクエストをレート制限にカウントしません。`alpine:latest`に対してHEADリクエストを行い、ヘッダーで返されるダイジェスト（チェックサム）値を表示し、マニフェストが変更されたかどうかを判断できます。

依存プロキシは、すべてのリクエストをHEADリクエストから開始します。マニフェストが古くなっている場合にのみ、新しいイメージがプルされます。

たとえば、パイプラインが5分ごとに`node:latest`をプルする場合、依存プロキシはイメージ全体をキャッシュし、`node:latest`が変更された場合にのみ更新します。そのため、6時間でイメージに対して（Docker Hubのレート制限を超える量である）360件のリクエストを行う代わりに、（マニフェストがその間に変更されない限りは）プルリクエストを1回行います。

### Docker Hubのレート制限を確認する {#check-your-docker-hub-rate-limit}

Docker Hubへのリクエスト数と残りのリクエスト数が気になる場合は、Runnerから、またはCI/CDスクリプトで次のコマンドを実行できます:

```shell
# Note, you must have jq installed to run this command
TOKEN=$(curl "https://auth.docker.io/token?service=registry.docker.io&scope=repository:ratelimitpreview/test:pull" | jq --raw-output .token) && curl --head --header "Authorization: Bearer $TOKEN" "https://registry-1.docker.io/v2/ratelimitpreview/test/manifests/latest" 2>&1 | grep --ignore-case RateLimit
...
```

出力は次のようになります:

```shell
RateLimit-Limit: 100;w=21600
RateLimit-Remaining: 98;w=21600
```

この例では、6時間で合計100回のプル制限があり、残り98回プルが可能であることを示しています。

#### CI/CDジョブでレート制限を確認する {#check-the-rate-limit-in-a-cicd-job}

この例は、`jq`と`curl`がインストールされたイメージを使用するGitLab CI/CDジョブを示しています:

```yaml
hub_docker_quota_check:
    stage: build
    image: alpine:latest
    tags:
        - <optional_runner_tag>
    before_script: apk add curl jq
    script:
      - |
        TOKEN=$(curl "https://auth.docker.io/token?service=registry.docker.io&scope=repository:ratelimitpreview/test:pull" | jq --raw-output .token) && curl --head --header "Authorization: Bearer $TOKEN" "https://registry-1.docker.io/v2/ratelimitpreview/test/manifests/latest" 2>&1
```

## トラブルシューティング {#troubleshooting}

### 認証エラー: 「HTTP Basic: Access Denied」 {#authentication-error-http-basic-access-denied}

依存プロキシに対して認証するときに`HTTP Basic: Access denied`エラーが発生した場合は、[2要素認証のトラブルシューティングガイド](../../profile/account/two_factor_authentication_troubleshooting.md)を参照してください。

### 依存プロキシの接続エラー {#dependency-proxy-connection-failure}

サービスエイリアスが設定されていない場合、`docker:20.10.16`イメージは`dind`サービスを見つけることができず、次のようなエラーがスローされます:

```plaintext
error during connect: Get http://docker:2376/v1.39/info: dial tcp: lookup docker on 192.168.0.1:53: no such host
```

これは、次のようにDockerサービスのサービスエイリアスを設定することで解決できます:

```yaml
services:
    - name: ${CI_DEPENDENCY_PROXY_GROUP_IMAGE_PREFIX}/docker:18.09.7-dind
      alias: docker
```

### CI/CDジョブから依存プロキシへの認証時の問題 {#issues-when-authenticating-to-the-dependency-proxy-from-cicd-jobs}

GitLab Runnerは、依存プロキシに対して自動的に認証を行います。ただし、基盤となるDockerエンジンは、引き続き[承認解決プロセス](https://docs.gitlab.com/runner/configuration/advanced-configuration.html#precedence-of-docker-authorization-resolving)の対象となります。

認証メカニズムの設定ミスにより、`HTTP Basic: Access denied`および`403: Access forbidden`エラーが発生する可能性があります。

ジョブログで、依存プロキシに対する認証に使用される認証メカニズムを表示できます:

```plaintext
Authenticating with credentials from $DOCKER_AUTH_CONFIG
```

```plaintext
Authenticating with credentials from /root/.docker/config.json
```

```plaintext
Authenticating with credentials from job payload (GitLab Registry)
```

想定される認証メカニズムを使用していることを確認してください。

### イメージのプル時の`Not Found`または`404`エラー {#not-found-or-404-error-when-pulling-image}

これらのエラーは、ジョブを実行しているユーザーが、依存プロキシグループに対して最低限のゲストロールさえ持っていないことを示している可能性があります:

- ```plaintext
  ERROR: gitlab.example.com:443/group1/dependency_proxy/containers/alpine:latest: not found

  failed to solve with frontend dockerfile.v0: failed to create LLB definition: gitlab.example.com:443/group1/dependency_proxy/containers/alpine:latest: not found
  ```

- ```plaintext
  ERROR: Job failed: failed to pull image "gitlab.example.com:443/group1/dependency_proxy/containers/alpine:latest" with specified policies [always]:
  Error response from daemon: error parsing HTTP 404 response body: unexpected end of JSON input: "" (manager.go:237:1s)
  ```

`Access denied`と同様のケースでエラーメッセージを改善するための作業の詳細については、[イシュー354826](https://gitlab.com/gitlab-org/gitlab/-/issues/354826)を参照してください。

### 依存プロキシからイメージを実行するときの`exec format error` {#exec-format-error-when-running-images-from-the-dependency-proxy}

{{< alert type="note" >}}

この問題はGitLab 16.3で[解決](https://gitlab.com/gitlab-org/gitlab/-/issues/325669)されました。16.2以前のGitLab Self-Managedインスタンスの場合は、インスタンスを16.3に更新するか、以下に記載されている回避策を使用できます。

{{< /alert >}}

このエラーは、GitLab 16.2以前のARMベースのDockerインストールで依存プロキシを使用しようとすると発生します。依存プロキシは、特定のタグを持つイメージをプルするときに、x86_64アーキテクチャのみをサポートします。

回避策として、イメージのSHA256を指定して、依存プロキシに別のアーキテクチャを強制的にプルさせることができます:

```shell
docker pull ${CI_DEPENDENCY_PROXY_GROUP_IMAGE_PREFIX}/library/docker:20.10.3@sha256:bc9dcf5c8e5908845acc6d34ab8824bca496d6d47d1b08af3baf4b3adb1bd8fe
```

この例では、`bc9dcf5c8e5908845acc6d34ab8824bca496d6d47d1b08af3baf4b3adb1bd8fe`はARMベースのイメージのSHA256です。

### バックアップを復元後の`MissingFile`エラー {#missingfile-errors-after-restoring-a-backup}

`MissingFile`または`Cannot read file`エラーが発生した場合、[バックアップアーカイブ](../../../administration/backup_restore/backup_gitlab.md)に`gitlab-rails/shared/dependency_proxy/`の内容が含まれていないことが原因である可能性があります。

この[既知の問題](https://gitlab.com/gitlab-org/gitlab/-/issues/354574)を解決するには、`rsync`、`scp`、または同様のツールを使用して、影響を受けるファイルまたは`gitlab-rails/shared/dependency_proxy/`フォルダー構造全体を、バックアップのソースとなったGitLabインスタンスからコピーできます。

データが不要な場合は、次のコマンドでデータベースエントリを削除できます:

```shell
gitlab-psql -c "DELETE FROM dependency_proxy_blobs; DELETE FROM dependency_proxy_blob_states; DELETE FROM dependency_proxy_manifest_states; DELETE FROM dependency_proxy_manifests;"
```
