---
stage: Application Security Testing
group: Composition Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: プロジェクトの依存関係に関するソフトウェア部品表（SBOM）をCycloneDX形式で生成およびエクスポートし、それをCI/CDアーティファクトとして保存する方法を学びます。
title: 'チュートリアル: SBOM形式での依存関係リストのエクスポート'
---

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

依存関係スキャンの出力は、CycloneDX JSON形式にエクスポートできます。

このチュートリアルでは、パイプライン用のCycloneDX JSON SBOMを生成し、それをCIジョブのアーティファクトとしてアップロードする方法を示します。

## はじめる前 {#before-you-begin}

依存関係スキャンを設定します。詳細な手順については、[依存関係スキャンチュートリアル](dependency_scanning.md)を参照してください。

## 設定ファイルを作成します {#create-configuration-files}

1. プライベートアクセストークンを、`api`スコープと`Developer`ロールで作成します。
1. トークンの値を、CI/CD変数`PRIVATE_TOKEN`として追加します。
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

   この`export.sh`スクリプトは次の手順で動作します:

   1. 現在のパイプラインのCycloneDX SBOMをエクスポートします。
   1. そのエクスポートのステータスを確認し、準備が完了したら停止します。
   1. CycloneDX SBOMファイルをダウンロードします。

1. `.gitlab-ci.yml`を次のコードで更新します。

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

ジョブのアーティファクトには、`gl-sbom-merged-<pipeline_id>.cdx.json`ファイルが存在しているはずです。
