---
stage: Application Security Testing
group: Composition Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: プロジェクトの依存関係について、CycloneDX形式のソフトウェア部品表()を生成およびエクスポートし、CI/CDアーティファクトとして保存する方法について説明します。
title: 'チュートリアル: SBOM形式で依存関係リストをエクスポート'
---

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

依存関係スキャンの出力をCycloneDX JSON形式にエクスポートできます。

このチュートリアルでは、パイプラインのCycloneDX JSON SBOMを生成し、それをCIジョブアーティファクトとしてアップロードする方法を説明します。

## はじめる前 {#before-you-begin}

依存関係スキャンをセットアップします。詳細な手順については、[依存関係スキャンのチュートリアル](dependency_scanning.md)に従ってください。

## 設定ファイルを作成する {#create-configuration-files}

1. `api`スコープと`Developer`ロールを持つプライベートアクセストークンを作成します。
1. トークン値を`PRIVATE_TOKEN`という名前のCI/CD変数として追加します。
1. 次のコードで[スニペット](../api/snippets.md)を作成します。

   ファイル名: `export.sh`

   ```shell
   #! /bin/sh

   function create_export {
     curl --silent \
     --header "PRIVATE-TOKEN: $PRIVATE_TOKEN" \
     -X 'POST' --data "export_type=sbom" \
     "https://gitlab.com/api/v4/pipelines/$CI_PIPELINE_ID/dependency_list_exports" \
     | jq '.id'
   }

   function check_status {
     curl --silent \
       --header "PRIVATE-TOKEN: $PRIVATE_TOKEN" \
       --write-out "%{http_code}" --output /dev/null \
       https://gitlab.com/api/v4/dependency_list_exports/$1
   }

   function download {
     curl --header "PRIVATE-TOKEN: $PRIVATE_TOKEN" \
       --output "gl-sbom-merged-$CI_PIPELINE_ID.cdx.json" \
       "https://gitlab.com/api/v4/dependency_list_exports/$1/download"
   }

   function export_sbom {
     local ID=$(create_export)

     for run in $(seq 0 3); do
       local STATUS=$(check_status $ID)
       # Status is 200 when JSON is generated.
       # Status is 202 when generate JSON job is running.
       if [ $STATUS -eq "200" ]; then
         download $ID

         exit 0
       elif [ $STATUS -ne "202" ]; then
         exit 1
       fi

       echo "Waiting for JSON to be generated"
       sleep 5
     done

     exit 1
   }

   export_sbom
   ```

   この`export.sh`スクリプトは、次の手順で動作します:

   1. 現在のパイプラインのCycloneDX SBOMエクスポートを作成します。
   1. そのエクスポートのステータスを確認し、準備ができたら停止します。
   1. CycloneDX SBOMファイルをダウンロードします。

1. 次のコードで`.gitlab-ci.yml`を更新します。

   ```yaml
   export-merged-sbom:
     image: alpine
     before_script:
       - apk add --update jq curl
     stage: .post
     script:
       - |
         curl --header "Authorization: Bearer $PRIVATE_TOKEN" --output export.sh --url "https://gitlab.com/api/v4/snippets/<SNIPPET_ID>/raw"
       - /bin/sh export.sh
     artifacts:
       paths:
         - "gl-sbom-merged-*.cdx.json"

   ```

1. **ビルド** > **パイプライン**に移動し、最新のパイプラインが正常に完了したことを確認します。

ジョブアーティファクトでは、`gl-sbom-merged-<pipeline_id>.cdx.json`ファイルが存在する必要があります。
