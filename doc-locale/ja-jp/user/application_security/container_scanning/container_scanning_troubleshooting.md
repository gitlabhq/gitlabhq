---
stage: Application Security Testing
group: Composition Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: コンテナスキャンのトラブルシューティング
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

コンテナスキャンを使用していると、以下のイシューが発生する場合があります。

## 詳細ログを有効にする {#enable-verbose-logging}

コンテナスキャンのジョブの内容を詳しく確認する必要がある場合は、詳細出力を有効にします。詳細については、[デバッグレベルのログを生成する](../troubleshooting_application_security.md#debug-level-logging)を参照してください。

## `docker: Error response from daemon: failed to copy xattrs` {#docker-error-response-from-daemon-failed-to-copy-xattrs}

Runnerが`docker` executorを使用し、NFSが使用されている場合（例: `/var/lib/docker`がNFSマウント上にある場合）、コンテナスキャンが次のようなエラーで失敗する可能性があります。

```plaintext
docker: Error response from daemon: failed to copy xattrs: failed to set xattr "security.selinux" on /path/to/file: operation not supported.
```

このエラーは、Dockerのバグによるエラーで発生していましたが、すでに[修正されています](https://github.com/containerd/continuity/pull/138 "（fs: add WithAllowXAttrErrors CopyOpt")）。エラーを防ぐには、Runnerが使用しているDockerのバージョンが`18.09.03`以上であることを確認してください。詳細については、[イシュー#10241](https://gitlab.com/gitlab-org/gitlab/-/issues/10241 "コンテナスキャンがNFSマウントで動作しない理由を調査する")を参照してください。

## エラー: `gl-container-scanning-report.json: no matching files` {#error-gl-container-scanning-reportjson-no-matching-files}

この警告に関する情報については、[アプリケーションセキュリティの一般的なトラブルシューティングのセクション](../../../ci/jobs/job_artifacts_troubleshooting.md#error-message-no-files-to-upload)を参照してください。

## エラー: `unexpected status code 401 Unauthorized: Not Authorized` {#error-unexpected-status-code-401-unauthorized-not-authorized}

このエラーは、AWS ECRからコンテナイメージをスキャンし、AWSリージョンが構成されていない場合に発生する可能性があります。スキャナーは認可トークンを取得することができません。`SECURE_LOG_LEVEL`を`debug`に設定すると、次のようなログメッセージが表示されます:

```shell
[35mDEBUG[0m failed to get authorization token: MissingRegion: could not find region configuration
```

これを解決するには、`AWS_DEFAULT_REGION`をCI/CD変数に追加します。

```yaml
variables:
  AWS_DEFAULT_REGION: <AWS_REGION_FOR_ECR>
```

## エラー: `unable to open a file: open /home/gitlab/.cache/trivy/ee/db/metadata.json` {#error-unable-to-open-a-file-open-homegitlabcachetrivyeedbmetadatajson}

圧縮されたTrivyデータベースはコンテナの`/tmp`フォルダーに保存され、ランタイム時に`/home/gitlab/.cache/trivy/{ee|ce}/db`に展開されます。このエラーは、Runner設定に`/tmp`ディレクトリのボリュームマウントがある場合に発生する可能性があります。

このイシューを解決するには、`/tmp`フォルダーをバインドする代わりに、`/tmp`内の特定のファイルまたはフォルダー（`/tmp/myfile.txt`など）をバインドします。

## エラー: `context deadline exceeded` {#error-context-deadline-exceeded}

このエラーは、タイムアウトが発生したことを意味します。これを解決するには、十分な長さの期間を設定した`TRIVY_TIMEOUT`環境変数を`container_scanning`ジョブに追加します。

## 古いイメージに基づくイメージで検出された脆弱性はありません {#no-vulnerabilities-detected-on-images-based-on-an-old-image}

Trivyは、更新を受信しなくなったオペレーティングシステムのイメージをスキャンしません。

これをUIで表示することは、[イシュー433325](https://gitlab.com/gitlab-org/gitlab/-/issues/433325)で提案されています。

## 予期される脆弱性が検出されません {#expected-vulnerabilities-not-detected}

Trivyは[言語固有の調査結果](_index.md#report-language-specific-findings)をデフォルトではレポートしないため、イメージに脆弱性のあるオペレーティングシステムの依存関係がない場合、空のレポートになる可能性があります。言語固有の調査結果を有効にするには、リンクされたドキュメントの手順に従って、スキャンを再実行してください。

## 警告: `vulnerability database was built X days ago (max allowed age is Y days)` {#warning-vulnerability-database-was-built-x-days-ago-max-allowed-age-is-y-days}

次のようなエラーメッセージが表示される場合があります:

```plaintext
1 error occurred: * the vulnerability database was built 6 days ago (max allowed age is 5 days)
```

コンテナスキャンイメージが5日より古い場合、コンテナスキャンは失敗します。GitLabはイメージを毎日更新しますが、オフライン環境などでイメージのコピーを使用すると、イメージが古くなる可能性があります。現在のイメージにより、Trivyデータベース（イメージに保存されている）が最新の状態になります。

このイシューを解決するには、コンテナスキャンイメージを更新します。詳細については、[ローカルコンテナイメージの更新](_index.md#update-local-container-image)を参照してください。
