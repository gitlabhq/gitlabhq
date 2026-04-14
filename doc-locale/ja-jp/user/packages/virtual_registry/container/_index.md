---
stage: Package
group: Container Registry
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: コンテナ仮想レジストリ
description: コンテナ仮想レジストリを使用して、アップストリームレジストリからコンテナイメージをキャッシュします。
---

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed
- ステータス: ベータ版

{{< /details >}}

{{< history >}}

- GitLab 18.5で`container_virtual_registries`[フラグ](../../../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/548794)されました。デフォルトでは無効になっています。
- GitLab 18.9で実験的機能からベータ版に[変更](https://gitlab.com/gitlab-org/gitlab/-/work_items/589631)されました。
- GitLab 18.10で[GitLab.com、GitLab Self-Managed、およびGitLab Dedicatedで有効になりました。](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/224250)

{{< /history >}}

> [!flag]
> この機能の可用性は機能フラグによって制御されます。詳細については、履歴を参照してください。

GitLabコンテナ仮想レジストリは、アップストリームレジストリからコンテナイメージをキャッシュするために使用できるローカルプロキシです。これはプルスルーキャッシュとして機能し、頻繁にアクセスされるイメージをローカルに保存して、帯域幅の使用量を削減し、ビルドパフォーマンスを向上させます。

## 前提条件 {#prerequisites}

コンテナ仮想レジストリを使用する前に:

- 仮想レジストリを使用するための[前提条件](../_index.md#prerequisites)を確認してください。
- バーチャルレジストリへの認証を設定します。詳細については、[仮想レジストリへの認証](../_index.md#authenticate-to-the-virtual-registry)を参照してください。

コンテナ仮想レジストリを使用する場合は、次の制限事項に注意してください:

- トップレベルグループごとに最大`5`個のコンテナ仮想レジストリを作成できます。
- 指定されたコンテナ仮想レジストリに設定できるアップストリームは`5`個のみです。
- Geoサポートは実装されていません。

## 仮想レジストリを管理する {#manage-virtual-registries}

{{< history >}}

- GitLab 18.10で[導入](https://gitlab.com/groups/gitlab-org/-/work_items/19283)され、`ui_for_container_virtual_registries`という名前の[フラグ](../../../../administration/feature_flags/_index.md)が付いています。

{{< /history >}}

グループのコンテナバーチャルレジストリを管理します。

[APIを使用する](../../../../api/container_virtual_registries.md)こともできます。

### コンテナバーチャルレジストリの作成 {#create-a-container-virtual-registry}

コンテナバーチャルレジストリを作成するには:

1. 上部のバーで、**検索または移動先**を選択して、グループを見つけます。このグループはトップレベルにある必要があります。
1. **デプロイ** > **バーチャルレジストリ**を選択します。
1. 次のいずれかの場合:
   - 既存のレジストリがある場合は、**レジストリを作成**を選択します。ドロップダウンリストから、**コンテナ**を選択します。
   - 既存のレジストリがない場合は、ドロップダウンリストから**コンテナ**を選択します。次に、**レジストリを作成**を選択します。
1. **名前**とオプションの**説明**を入力します。
1. **レジストリを作成**を選択します。

## アップストリームレジストリを管理する {#manage-upstream-registries}

バーチャルレジストリ内のアップストリームコンテナレジストリを管理します。

### コンテナアップストリームレジストリの作成 {#create-a-container-upstream-registry}

バーチャルレジストリに接続するためのコンテナアップストリームレジストリを作成します。

前提条件: 

- コンテナバーチャルレジストリが必要です。詳細については、[バーチャルレジストリの作成](#create-a-container-virtual-registry)を参照してください。

コンテナアップストリームレジストリを作成するには:

1. 上部のバーで、**検索または移動先**を選択して、グループを見つけます。このグループはトップレベルにある必要があります。
1. **デプロイ** > **バーチャルレジストリ**を選択します。
1. **レジストリタイプ**で、**レジストリの表示**を選択します。
1. **レジストリ**タブで、レジストリを選択します。
1. **アップストリームの追加**を選択します。バーチャルレジストリに既存のアップストリームがある場合は、ドロップダウンリストから次のいずれかを選択します:
   - **新しいアップストリームを作成**を選択して、アップストリームを設定します。
   - **既存のアップストリームをリンク** > **Select existing upstream**。
     1. ドロップダウンリストからアップストリームを選択します。
     1. オプション。オプション。**アップストリームのテスト**を選択して、アップストリーム接続を作成する前にテストします。
     1. **アップストリームの追加**を選択します。
1. フィールドに入力します。
   - **ユーザー名**と**password**の両方、またはどちらも指定しません。設定されていない場合、パブリック（匿名）リクエストを使用してアップストリームにアクセスします。
   - アップストリームをDocker Hardened Imagesに接続する場合は、**アップストリームのURL**として以下を使用します:

      ```plaintext
      https://dhi.io
      ```

   - **アーティファクトのキャッシュ期間**は24時間にデフォルト設定されています。`0`に設定すると、キャッシュエントリのチェックが無効になります。
   - アップストリーム接続を作成する前にテストする場合は、**アップストリームのテスト**を選択します。

1. **アップストリームを作成**を選択します。

キャッシュの有効期間設定の詳細については、[キャッシュの有効期間を設定](../_index.md#set-the-cache-validity-period)を参照してください。

## コンテナ仮想レジストリで認証 {#authenticate-with-the-container-virtual-registry}

コンテナ仮想レジストリは、トップレベルグループに関連付けられたレジストリにコンテナイメージを保存して関連付けます。コンテナイメージにアクセスするには、グループのコンテナ仮想レジストリで認証する必要があります。

手動で認証するには、次のコマンドを実行します:

```shell
echo "$CONTAINER_REGISTRY_PASSWORD" | docker login gitlab.example.com/virtual_registries/container/1 --username <your_username> --password-stdin
```

または、[仮想レジストリへの認証](../_index.md#authenticate-to-the-virtual-registry)で説明されているいずれかの方法で設定を行います。

コンテナ仮想レジストリは、[Docker v2トークン認証フロー](https://distribution.github.io/distribution/spec/auth/token/)に従います:

1. クライアント認証後、クライアントに発行されたJWTトークンは、クライアントがコンテナイメージをプルすることを承認します。
1. トークンは、その有効期限に従って有効期限が切れます。
1. トークンの有効期限が切れると、ほとんどのDockerクライアントはユーザー認証情報を保存し、それ以上の操作なしに自動的に新しいトークンを要求します。

## 仮想レジストリからコンテナイメージをプルする {#pull-container-images-from-the-virtual-registry}

仮想レジストリを介してコンテナイメージをプルするには:

1. 仮想レジストリで認証します。
1. コンテナイメージをプルするには、仮想レジストリのURL形式を使用します:

   ```plaintext
   gitlab.example.com/virtual_registries/container/<registry_id>/<image_path>:<tag>
   ```

例: 

- タグでイメージをプル:

  ```shell
  docker pull gitlab.example.com/virtual_registries/container/1/library/alpine:latest
  ```

- ダイジェストでイメージをプル:

  ```shell
  docker pull gitlab.example.com/virtual_registries/container/1/library/alpine@sha256:c9375e662992791e3f39e919b26f510e5254b42792519c180aad254e6b38f4dc
  ```

- `Dockerfile`でイメージをプル:

  ```dockerfile
  FROM gitlab.example.com/virtual_registries/container/1/library/alpine:latest
  ```

- `.gitlab-ci.yml`ファイルでイメージをプル:

  ```yaml
  image: gitlab.example.com/virtual_registries/container/1/library/alpine:latest
  ```

コンテナイメージをプルすると、仮想レジストリは次のようになります:

1. イメージが既にキャッシュされているかどうかを確認します。
   1. イメージがキャッシュされていて、アップストリームの`cache_validity_hours`設定に基づいてまだ有効な場合、イメージはキャッシュから提供されます。
   1. イメージがキャッシュされていないか、キャッシュが無効な場合、設定されたアップストリームレジストリからイメージがフェッチされ、キャッシュされます。
1. Dockerクライアントにイメージを提供します。

### コンテナイメージの仮想レジストリキャッシュ検証 {#virtual-registry-cache-validation-for-images}

`alpine:latest`のようなイメージタグは、常に最新バージョンのイメージをプルします。新しいバージョンには、更新されたイメージマニフェストが含まれています。コンテナ仮想レジストリは、マニフェストが変更されても新しいイメージをプルしません。

代わりに、コンテナ仮想レジストリは次のようになります:

1. アップストリームの`cache_validity_hours`設定を確認して、イメージマニフェストが無効になる時期を判断します。
1. アップストリームにHEADリクエストを送信します。マニフェストが無効な場合、新しいイメージがプルされます。

たとえば、パイプラインが`node:latest`プルし、`cache_validity_period`を24時間に設定した場合、仮想レジストリはイメージをキャッシュし、キャッシュが期限切れになるか、アップストリームで`node:latest`が変更されたときにイメージを更新します。

## トラブルシューティング {#troubleshooting}

### 認証エラー：`HTTP Basic: Access Denied` {#authentication-error-http-basic-access-denied}

仮想レジストリに対して認証を行うときに`HTTP Basic: Access denied`エラーが発生した場合は、[2要素認証のトラブルシューティング](../../../profile/account/two_factor_authentication_troubleshooting.md#error-http-basic-access-denied-if-a-password-was-provided-for-git-authentication-)を参照してください。

### 仮想レジストリ接続失敗 {#virtual-registry-connection-failure}

サービスエイリアスが設定されていない場合、`docker:20.10.16`イメージは`dind`サービスを見つけることができず、次のようなエラーがスローされます:

```plaintext
error during connect: Get http://docker:2376/v1.39/info: dial tcp: lookup docker on 192.168.0.1:53: no such host
```

このエラーを解決するには、Dockerサービスのサービスエイリアスを設定します:

```yaml
services:
  - name: docker:20.10.16-dind
    alias: docker
```

### CI/CDジョブからの仮想レジストリ認証の問題 {#virtual-registry-authentication-issues-from-cicd-jobs}

GitLab Runnerは、CI/CDジョブトークンを使用して自動的に認証します。ただし、基盤となるDockerエンジンは、引き続き[承認解決プロセス](https://docs.gitlab.com/runner/configuration/advanced-configuration/#precedence-of-docker-authorization-resolving)の対象となります。

認証メカニズムの設定ミスにより、`HTTP Basic: Access denied`および`403: Access forbidden`エラーが発生する可能性があります。

ジョブログを使用して、仮想レジストリに対する認証に使用される認証メカニズムを表示できます:

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

このようなエラーは、次のことを示している可能性があります:

- ジョブを実行しているユーザーが、バーチャルレジストリを所有するグループのゲスト、プランナー、レポーター、デベロッパー、メンテナー、またはオーナーのロールを持っていません。
- URL内の仮想レジストリIDが正しくありません。
- アップストリームレジストリにリクエストされたイメージが含まれていません。
- 仮想レジストリに設定されたアップストリームがありません。

エラーメッセージの例:

```plaintext
ERROR: gitlab.example.com/virtual_registries/container/1/library/alpine:latest: not found
```

```plaintext
ERROR: Job failed: failed to pull image "gitlab.example.com/virtual_registries/container/1/library/alpine:latest" with specified policies [always]:
Error response from daemon: error parsing HTTP 404 response body: unexpected end of JSON input: "" (manager.go:237:1s)
```

これらのエラーを解決するには:

1. グループのゲスト、プランナー、レポーター、デベロッパー、メンテナー、またはオーナーのロールを持っていることを確認します。
1. 仮想レジストリIDが正しいことを確認します。
1. 仮想レジストリに、少なくとも1つの設定されたアップストリームがあることを確認します。
1. イメージがアップストリームレジストリに存在することを確認します。
