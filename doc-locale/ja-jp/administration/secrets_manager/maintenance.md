---
stage: Software Supply Chain Security
group: Pipeline Security
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: OpenBaoを保守する
---

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab Self-Managed
- ステータス: ベータ版

{{< /details >}}

Geoフェイルオーバーについては、[Geoディザスターリカバリー](../geo/disaster_recovery/_index.md#step-4-optional-promote-the-openbao-ha-cluster)を参照してください。

## OpenBaoのバックアップと復元する {#back-up-and-restore-openbao}

OpenBaoは、PostgreSQL上の独立した論理データベースにデータを格納します。通常のGitLabバックアップと共にこのデータベースをバックアップすることで、障害発生後にシークレットを復元することができます。

OpenBao固有の詳細なバックアップと復元する手順については、[OpenBaoバックアップドキュメント](https://docs.gitlab.com/charts/charts/openbao/#back-up-openbao)を参照してください。

## リカバリーキー管理 {#recovery-key-management}

OpenBaoのリカバリーキーの管理（保存、表示、ルートトークン生成への使用を含む）に関する情報については、[リカバリーキー管理](recovery_key.md)を参照してください。

## OpenBao認証のリカバリー {#recover-openbao-authentication}

JWT `aud` (オーディエンス) クレームと保存されている`bound_audiences`の値が乖離した場合、OpenBao認証をリカバリーする必要があるかもしれません。

格納されているシークレットが保持されるため、最初にリカバリーキーで認証を再設定します。格納されているすべてのシークレットが削除されるため、最終手段としてのみOpenBaoデータをリセットしてください。

### リカバリーキーで認証を再設定する {#reconfigure-authentication-with-a-recovery-key}

この方法は、保存されているすべてのシークレットを保持しますが、リカバリーキーが必要です。

1. リカバリーキーから一時的なルートトークンを生成します。手順については、[リカバリーキーからルートトークンを生成する](recovery_key.md#generate-a-root-token-from-the-recovery-key)を参照してください。

1. 現在の認証ロールを読み取り、その完全な設定を取得します:

   ```shell
   OPENBAO_POD=$(kubectl get pods -n gitlab -l app.kubernetes.io/name=openbao -o name | head -1)
   kubectl exec -n gitlab "$OPENBAO_POD" -c openbao-server -- \
     sh -c "BAO_ADDR=http://127.0.0.1:8200 BAO_TOKEN=<root_token> bao read auth/gitlab_rails_jwt/role/app"
   ```

1. 修正された`bound_audiences`と、前のステップの他のすべてのフィールドでロールを再適用します。更新時、OpenBaoは省略されたフィールドをデフォルトにリセットするため、リクエストには完全な設定を含める必要があります。重要な点:

   - `role_type`フィールドは`oidc`にデフォルト設定されるため、`role_type=jwt`を含める必要があります。そうしないとロールが機能しなくなります。
   - `claim_mappings`フィールドは省略すると空にリセットされ、認可が機能しなくなります。前のステップが返した同じマッピングを含めます。

   `bound_claims`と`claim_mappings`はマップなので、`bao write <path> -`を使用して標準入力でJSONとして設定を指定します。`<your-domain>`をOpenBaoドメインに置き換え、`claim_mappings`およびその他の値を前のステップで返されたものに置き換えます:

   ```shell
   kubectl exec -i -n gitlab "$OPENBAO_POD" -c openbao-server -- \
     sh -c "BAO_ADDR=http://127.0.0.1:8200 BAO_TOKEN=<root_token> bao write auth/gitlab_rails_jwt/role/app -" <<'JSON'
   {
     "role_type": "jwt",
     "user_claim": "user_id",
     "bound_subject": "gitlab_secrets_manager",
     "bound_audiences": ["https://openbao.<your-domain>"],
     "token_policies": ["secrets_manager"],
     "bound_claims": {"secrets_manager_scope": "privileged"},
     "claim_mappings": {
       "user_id": "user_id",
       "project_id": "project_id",
       "group_id": "group_id",
       "namespace_id": "namespace_id",
       "correlation_id": "correlation_id"
     }
   }
   JSON
   ```

1. ルートトークンを失効する。最初のステップの手順には、失効するコマンドが含まれています。

この手順は、ルートレベルのオーディエンスのみを修正します。異なるドメインを持つセカンダリサイトへのGeoフェイルオーバーはサポートされていません。これは、すべてのプロジェクトとグループに対してJWT認証を再プロビジョニングする必要もあるためです。代わりに、プライマリドメインがプロモートされたセカンダリを指すようにDNSを更新してください。詳細については、[Geoデプロイ](_index.md#geo-deployment)を参照してください。

### OpenBaoデータのリセット {#reset-openbao-data}

> [!warning]
> この手順により、OpenBaoに格納されているすべてのシークレットが完全に削除されます。完了後、すべてのシークレットマネージャーシークレットを再作成してください。

リカバリーキーがなく、`bound_audiences`がJWT `aud`クレームと同期していないため認証が失敗する場合に、OpenBaoデータをリセットします。OpenBaoが間違ったURLで初期化された場合、不一致が発生する可能性があります。このリセットによりOpenBaoデータベースが消去され、OpenBaoは正しい設定で自己初期化されます。

リカバリーキーがある場合は、代わりに[リカバリーキーで認証を再設定](#reconfigure-authentication-with-a-recovery-key)してください。この方法では、保存されているシークレットが保持されます。

開始する前に、設定で正しいオーディエンスを設定してください:

- GitLab 18.10以降の場合、`global.openbao.jwt_audience`を目的のオーディエンスに設定します。
- 以前のバージョンの場合は、OpenBaoの外部URLを設定します。OpenBaoは、自己初期化中にこのURLから`bound_audiences`を導出します。

OpenBaoデータをリセットするには:

1. OpenBaoをゼロレプリカにスケールする:

   ```shell
   kubectl -n gitlab scale deployment gitlab-openbao --replicas=0
   kubectl -n gitlab rollout status deployment gitlab-openbao --timeout=60s
   ```

1. ツールボックスポッド名を取得します:

   ```shell
   kubectl -n gitlab get pods -l app=toolbox -o jsonpath='{.items[0].metadata.name}'
   ```

1. OpenBaoストレージテーブルを消去します。プレースホルダーをOpenBaoデータベースのパスワードとホストに置き換えます:

   ```shell
   kubectl -n gitlab exec -ti <toolbox-pod-name> -- \
     env PGPASSWORD='<openbao_database_password>' \
     psql -h <postgres_host> -U openbao -d openbao \
     -c "TRUNCATE TABLE openbao_kv_store; TRUNCATE TABLE openbao_ha_locks;"
   ```

1. 修正された設定でOpenBaoを再デプロイします:

   ```shell
   helm upgrade --install --version <chart-version> gitlab gitlab/gitlab \
     -n gitlab -f gitlab.yaml
   ```

1. OpenBaoを再びスケールする。チャートの再デプロイでは、手動でスケールするダウンしたデプロイメントは復元されません:

   ```shell
   kubectl -n gitlab scale deployment gitlab-openbao --replicas=2
   kubectl -n gitlab rollout status deployment gitlab-openbao --timeout=120s
   ```

1. OpenBaoが初期化され、アンシールされており、正しいオーディエンスを使用していることを確認します:

   ```shell
   OPENBAO_POD=$(kubectl -n gitlab get pods -l app.kubernetes.io/name=openbao \
     -l openbao-active=true -o jsonpath='{.items[0].metadata.name}')
   kubectl -n gitlab exec -ti "$OPENBAO_POD" -c openbao-server -- \
     sh -c "BAO_ADDR=http://127.0.0.1:8200 bao status"
   kubectl -n gitlab get configmap gitlab-openbao-config -o yaml | grep bound_audiences
   ```

   ステータスが`Initialized   true`と`Sealed   false`を示し、`bound_audiences`の値がGitLabが送信するオーディエンスと一致します。
