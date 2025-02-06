---
stage: Application Security Testing
group: Composition Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: 'Tutorial: Export dependency list in SBOM format'
---

DETAILS:
**Tier:** Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

Dependency Scanning output can be exported to the CycloneDX JSON format.

This tutorial shows you how to generate a CycloneDX JSON SBOM for a pipeline, and then to upload it as a CI job artifact.

## Before you begin

Set up Dependency Scanning. For detailed instructions, follow [the Dependency Scanning tutorial](dependency_scanning.md).

## Create configuration files

1. Create a private access token with `api` scope and the `Developer` role.
1. Add the token value as a CI/CD variable named `PRIVATE_TOKEN`.
1. Create a [snippet](../api/snippets.md) with the following code.

   Filename: `export.sh`

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

   The above script works in the following steps:

   1. Create a CycloneDX SBOM export for the current pipeline.
   1. Check the status of that export, and stop when it's ready.
   1. Download the CycloneDX SBOM file.

1. Update `.gitlab-ci.yml` with the following code.

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

1. Go to **Build > Pipelines** and confirm that the latest pipeline completed successfully.

In the job artifacts, `gl-sbom-merged-<pipeline_id>.cdx.json` file should be present.
