---
stage: Runtime
group: Geo
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
gitlab_dedicated: no
title: 自動バックグラウンド検証
---

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

自動バックグラウンド検証により、転送されたデータが計算されたチェックサムと一致することが保証されます。**プライマリ**サイトのデータのチェックサムが**セカンダリ**サイトのデータのチェックサムと一致する場合、データは正常に転送されています。計画的フェイルオーバー後、破損の程度によっては、破損したデータが**lost**（失われる）可能性があります。

**プライマリ**サイトでの検証が失敗した場合、これはGeoが破損したオブジェクトをレプリケートしていることを示します。バックアップから復元するか、**プライマリ**サイトから削除して、問題を解決できます。

**プライマリ**サイトでの検証が成功し、**セカンダリ**サイトでの検証が失敗した場合、これはオブジェクトがレプリケーション処理中に破損したことを示します。Geoは、バックオフ期間を設けて、リポジトリを再同期するようにマークすることにより、検証の失敗を積極的に修正しようとします。これらの失敗に対する検証をリセットする場合は、[次の手順](background_verification.md#reset-verification-for-projects-where-verification-has-failed)に従ってください。

検証がレプリケーションより大幅にラグしている場合は、計画的なフェイルオーバーをスケジュールする前に、サイトにもう少し時間を与えることを検討してください。

## リポジトリの検証 {#repository-verification}

**プライマリ**サイトで:

1. 左側のサイドバーの下部で、**管理者**を選択します。
1. **Geo** > **サイト**を選択します。
1. そのサイトの**検証情報**タブを展開して、リポジトリとWikiの自動チェックサムステータスを表示します。成功は緑色、保留中の作業は灰色、失敗は赤色で表示されます。

   ![正常なプライマリGeoインスタンスの概要を示す検証情報タブ。](img/verification_status_primary_v14_0.png)

**セカンダリ**サイトで:

1. 左側のサイドバーの下部で、**管理者**を選択します。
1. **Geo** > **サイト**を選択します。
1. そのサイトの**検証情報**タブを展開して、リポジトリとWikiの自動チェックサムステータスを表示します。成功は緑色、保留中の作業は灰色、失敗は赤色で表示されます。

   ![正常なセカンダリGeoインスタンスの概要を示す検証情報タブ。](img/verification_status_secondary_v14_0.png)

## チェックサムを使用してGeoサイトを比較する {#using-checksums-to-compare-geo-sites}

Geoの**セカンダリ**サイトのヘルス状態を確認するために、Gitの参照とその値のリスト全体でチェックサムを使用します。チェックサムには、真の整合性を確保するために、`HEAD`、`heads`、`tags`、`notes`、およびGitLab固有の参照が含まれます。2つのサイトのチェックサムが同じ場合、それらは間違いなく同じ参照を保持しています。すべてのサイトが同期していることを確認するために、更新ごとにすべてのサイトのチェックサムをコンピューティングします。

## リポジトリの再検証 {#repository-re-verification}

バグまたは一時的なインフラストラクチャの失敗により、Gitのリポジトリが検証用にマークされずに予期せず変更される可能性があります。Geoは、データの整合性を確保するために、リポジトリを常に再検証します。デフォルトおよび推奨される再検証間隔は7日間ですが、1日という短い間隔を設定することもできます。間隔が短いほどリスクは軽減されますが、負荷が増加し、逆もまた同様です。

**プライマリ**サイトで:

1. 左側のサイドバーの下部で、**管理者**を選択します。
1. **Geo** > **サイト**を選択します。
1. 最小再検証間隔をカスタマイズするには、**プライマリ**サイトの**編集**を選択します:

   ![Geoノードの設定属性を示すウィンドウ。](img/reverification-interval_v11_6.png)

## 検証に失敗したプロジェクトの検証をリセットする {#reset-verification-for-projects-where-verification-has-failed}

Geoは、バックオフ期間を設けて、リポジトリを再同期するようにマークすることにより、検証の失敗を積極的に修正しようとします。[UIまたはRailsコンソールを使用して、個々のコンポーネントを手動で再同期および再検証](../replication/troubleshooting/synchronization_verification.md#resync-and-reverify-individual-components)することもできます。

## チェックサムの不一致による差分を調整する {#reconcile-differences-with-checksum-mismatches}

{{< history >}}

- GitLab 16.3では、**Gitalyストレージ名**フィールドは**ストレージ名**フィールドに、**Gitaly相対パス**フィールドは**相対パス**フィールドに[名前が変更](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/128416)されました。

{{< /history >}}

**プライマリ**サイトと**セカンダリ**サイトにチェックサム検証の不一致がある場合、原因が明らかでない可能性があります。チェックサムの不一致の原因を見つけるには、次の手順に従います:

1. **プライマリ**サイトで:
   1. 左側のサイドバーの下部で、**管理者**を選択します。
   1. 左側のサイドバーで、**概要** > **プロジェクト**を選択します。
   1. チェックサムの差を確認するプロジェクトを見つけて、その名前を選択します。
   1. プロジェクト管理ページで、**Storage name**（リポジトリストレージ名）フィールドと**Relative path**（相対パス）フィールドの値を取得します。

1. **プライマリサイトのGitalyノード**と**セカンダリサイトのGitalyノード**で、プロジェクトのリポジトリディレクトリに移動します。Gitaly Cluster (Praefect)を使用している場合は、これらのコマンドを実行する前に、[正常な状態にあることを確認](../../gitaly/praefect/troubleshooting.md#check-cluster-health)してください。

   デフォルトのパスは`/var/opt/gitlab/git-data/repositories`です。リポジトリストレージがカスタマイズされている場合は、サーバー上のディレクトリレイアウトを確認して、確認してください:

   ```shell
   cd /var/opt/gitlab/git-data/repositories
   ```

   1. **プライマリ**サイトで次のコマンドを実行し、出力をファイルにリダイレクトします:

      ```shell
      git show-ref --head | grep -E "HEAD|(refs/(heads|tags|keep-around|merge-requests|environments|notes)/)" > primary-site-refs
      ```

   1. **セカンダリ**サイトで次のコマンドを実行し、出力をファイルにリダイレクトします:

      ```shell
      git show-ref --head | grep -E "HEAD|(refs/(heads|tags|keep-around|merge-requests|environments|notes)/)" > secondary-site-refs
      ```

   1. 同じシステムの前の手順からファイルをコピーし、コンテンツ間で差分をとります:

      ```shell
      diff primary-site-refs secondary-site-refs
      ```

## 現在の制限事項 {#current-limitations}

レプリケーションおよび検証でサポートされているメソッドの詳細については、[サポートされているGeoデータ型](../replication/datatypes.md)を参照してください。
