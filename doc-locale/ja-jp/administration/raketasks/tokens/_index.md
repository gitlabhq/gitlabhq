---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: アクセストークンRakeタスク
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

{{< history >}}

- GitLab 17.2で[導入されました](https://gitlab.com/gitlab-org/gitlab/-/issues/467416)。

{{< /history >}}

## トークンの有効期限を分析する {#analyze-token-expiration-dates}

GitLab 16.0では、[バックグラウンド移行](https://gitlab.com/gitlab-org/gitlab/-/issues/369123)により、有効期限のないすべての個人、プロジェクト、グループアクセストークンに、作成から1年後の有効期限が設定されました。

この移行の影響を受けた可能性のあるトークンを特定するには、すべてのアクセストークンを分析し、最も一般的な有効期限の上位10件を表示するRakeタスクを実行します:

   {{< tabs >}}

   {{< tab title="Linuxパッケージ（Omnibus）" >}}

   ```shell
   gitlab-rake gitlab:tokens:analyze
   ```

   {{< /tab >}}

   {{< tab title="Helmチャート（Kubernetes）" >}}

   ```shell
   # Find the toolbox pod
   kubectl --namespace <namespace> get pods -lapp=toolbox
   kubectl exec -it <toolbox-pod-name> -- sh -c 'cd /srv/gitlab && bin/rake gitlab:tokens:analyze'
   ```

   {{< /tab >}}

   {{< tab title="Docker" >}}

   ```shell
   sudo docker exec -it <container_name> /bin/bash
   gitlab-rake gitlab:tokens:analyze
   ```

   {{< /tab >}}

   {{< tab title="自己コンパイル（ソース）" >}}

   ```shell
   sudo RAILS_ENV=production -u git -H bundle exec rake gitlab:tokens:analyze
   ```

   {{< /tab >}}

   {{< /tabs >}}

このタスクは、すべてのアクセストークンを分析し、有効期限ごとにグループ化します。左の列には有効期限が、右の列にはその有効期限を持つトークンの数が表示されます。出力例: 

```plaintext
======= Personal/Project/Group Access Token Expiration Migration =======
Started at: 2023-06-15 10:20:35 +0000
Finished  : 2023-06-15 10:23:01 +0000
===== Top 10 Personal/Project/Group Access Token Expiration Dates =====
| Expiration Date | Count |
|-----------------|-------|
| 2024-06-15      | 1565353 |
| 2017-12-31      | 2508  |
| 2018-01-01      | 1008  |
| 2016-12-31      | 833   |
| 2017-08-31      | 705   |
| 2017-06-30      | 596   |
| 2018-12-31      | 548   |
| 2017-05-31      | 523   |
| 2017-09-30      | 520   |
| 2017-07-31      | 494   |
========================================================================
```

この例では、150万を超えるアクセストークンに2023-06-15に移行が実行されてから1年後の2024-06-15の有効期限が設定されていることがわかります。これは、これらのトークンのほとんどが、移行によって割り当てられたことを示唆しています。ただし、他のトークンが同じ日付で手動で作成されたかどうかを確実に知る方法はありません。

## 有効期限を一括更新する {#update-expiration-dates-in-bulk}

前提条件: 

これを行うには、次の手順に従います。

- 管理者である必要があります。
- 対話型ターミナルを使用できること。

以下のRakeタスクを実行して、トークンの有効期限を一括で延長または削除します:

1. ツールを実行します:

   {{< tabs >}}

   {{< tab title="Linuxパッケージ（Omnibus）" >}}

   ```shell
   gitlab-rake gitlab:tokens:edit
   ```

   {{< /tab >}}

   {{< tab title="Helmチャート（Kubernetes）" >}}

   ```shell
   # Find the toolbox pod
   kubectl --namespace <namespace> get pods -lapp=toolbox
   kubectl exec -it <toolbox-pod-name> -- sh -c 'cd /srv/gitlab && bin/rake gitlab:tokens:edit'
   ```

   {{< /tab >}}

   {{< tab title="Docker" >}}

   ```shell
   sudo docker exec -it <container_name> /bin/bash
   gitlab-rake gitlab:tokens:edit
   ```

   {{< /tab >}}

   {{< tab title="自己コンパイル（ソース）" >}}

   ```shell
   sudo RAILS_ENV=production -u git -H bundle exec rake gitlab:tokens:edit
   ```

   {{< /tab >}}

   {{< /tabs >}}

   ツールが起動すると、[分析ステップ](#analyze-token-expiration-dates)からの出力と、有効期限の変更に関する追加のプロンプトが表示されます:

   ```plaintext
   ======= Personal/Project/Group Access Token Expiration Migration =======
   Started at: 2023-06-15 10:20:35 +0000
   Finished  : 2023-06-15 10:23:01 +0000
   ===== Top 10 Personal/Project/Group Access Token Expiration Dates =====
   | Expiration Date | Count |
   |-----------------|-------|
   | 2024-05-14      | 1565353 |
   | 2017-12-31      | 2508  |
   | 2018-01-01      | 1008  |
   | 2016-12-31      | 833   |
   | 2017-08-31      | 705   |
   | 2017-06-30      | 596   |
   | 2018-12-31      | 548   |
   | 2017-05-31      | 523   |
   | 2017-09-30      | 520   |
   | 2017-07-31      | 494   |
   ========================================================================
   What do you want to do? (Press ↑/↓ arrow or 1-3 number to move and Enter to select)
   ‣ 1. Extend expiration date
     2. Remove expiration date
     3. Quit
   ```

### 有効期限を延長する {#extend-expiration-dates}

特定の有効期限に一致するすべてのトークンの有効期限を延長するには:

1. オプション1、`Extend expiration date`を選択します:

   ```plaintext
   What do you want to do?
   ‣ 1. Extend expiration date
     2. Remove expiration date
     3. Quit
   ```

1. ツールは、リストされている有効期限のいずれかを選択するように求めます。例: 

   ```plaintext
   Select an expiration date (Press ↑/↓/←/→ arrow to move and Enter to select)
   ‣ 2024-05-14
     2017-12-31
     2018-01-01
     2016-12-31
     2017-08-31
     2017-06-30
   ```

   キーボードの矢印キーを使用して日付を選択します。中止するには、一番下までスクロールして`--> Abort`を選択します。<kbd>Enter</kbd>を押して選択を確定します:

   ```plaintext
   Select an expiration date
     2017-06-30
     2018-12-31
     2017-05-31
     2017-09-30
     2017-07-31
   ‣ --> Abort
   ```

   日付を選択すると、ツールは新しい有効期限をプロンプト表示します:

   ```plaintext
   What would you like the new expiration date to be? (2025-05-14) 2024-05-14
   ```

   デフォルトは、選択した日付から1年後です。<kbd>Enter</kbd>を押してデフォルトを使用するか、`YYYY-MM-DD`形式で日付を手動で入力します。

1. 有効な日付を入力すると、ツールはもう一度確認を求めます:

   ```plaintext
   Old expiration date: 2024-05-14
   New expiration date: 2025-05-14
   WARNING: This will now update 1565353 token(s). Are you sure? (y/N)
   ```

   `y`と入力すると、ツールは選択した有効期限を持つすべてのトークンの有効期限を延長します。

   `N`と入力すると、ツールは更新タスクを中止し、元の分析出力に戻ります。

### 有効期限を削除する {#remove-expiration-dates}

特定の有効期限に一致するすべてのトークンの有効期限を削除するには:

1. オプション2、`Remove expiration date`を選択します:

   ```plaintext
   What do you want to do?
     1. Extend expiration date
   ‣ 2. Remove expiration date
     3. Quit
   ```

1. ツールは、テーブルから有効期限を選択するように求めます。例: 

   ```plaintext
   Select an expiration date (Press ↑/↓/←/→ arrow to move and Enter to select)
   ‣ 2024-05-14
     2017-12-31
     2018-01-01
     2016-12-31
     2017-08-31
     2017-06-30
   ```

   キーボードの矢印キーを使用して日付を選択します。中止するには、一番下までスクロールして`--> Abort`を選択します。<kbd>Enter</kbd>を押して選択を確定します:

   ```plaintext
   Select an expiration date
     2017-06-30
     2018-12-31
     2017-05-31
     2017-09-30
     2017-07-31
   ‣ --> Abort
   ```

1. 日付を選択すると、ツールは選択の確認をプロンプト表示します:

   ```plaintext
   WARNING: This will remove the expiration for tokens that expire on 2024-05-14.
   This will affect 1565353 tokens. Are you sure? (y/N)
   ```

   `y`と入力すると、ツールは選択した有効期限を持つすべてのトークンから有効期限を削除します。

   `N`と入力すると、ツールは更新タスクを中止し、最初のメニューに戻ります。

## CI/CD IDトークンのカスタム発行者URL設定を検証する {#validate-custom-issuer-url-configuration-for-cicd-id-tokens}

非公開GitLabインスタンスで、[AWSで一時的な認証情報を取得するためのOpenID Connect](../../../ci/cloud_services/aws/_index.md#configure-a-non-public-gitlab-instance)を設定する場合、`ci:validate_id_token_configuration` Rakeタスクを使用して、トークンの設定を検証することができます:

```shell
bundle exec rake ci:validate_id_token_configuration
```
