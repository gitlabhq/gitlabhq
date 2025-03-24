---
stage: Package
group: Package Registry
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: 'Tutorial: Generate a software bill of materials with GitLab package registry'
---

This tutorial shows you how to generate a software bill of materials (SBOM) in CycloneDX format with a CI/CD pipeline. The pipeline you'll build collects packages across multiple projects in a group, providing you with a comprehensive view of the dependencies in related projects. 

You'll create a virtual Python environment to complete this tutorial, but you can apply the same approach to other supported package types, too.

## What is a software bill of materials?
 
An SBOM is a machine-readable inventory of all the software components that comprise a software product. The SBOM might include:

- Direct and indirect dependencies
- Open-source components and licenses
- Package versions and their origins

An organization that's interested in using a software product may require an SBOM to determine how secure the product is before adopting it.

If you're familiar with the GitLab package registry, you might wonder what the difference is between an SBOM and a [dependency list](../../../user/application_security/dependency_list/_index.md). The following table highlights the key differences:

| Differences | Dependency list | SBOM |
|---|---|---|
| **Scope** | Shows dependencies for individual projects. | Creates an inventory of all packages published across your group. |
| **Direction** | Tracks what your projects depend on (incoming dependencies). | Tracks what your group publishes (outgoing packages). |
| **Coverage** | Based on package manifests, like `package.json` or `pom.xml`. | Covers actual published artifacts in your package registry. |
| **Format** | GitLab-specific feature. | Generates standard CycloneDX SBOMs that can be used with external tools. |

## What is CycloneDX?

CycloneDX is a lightweight, standardized format for creating SBOMs. CycloneDX provides a well-defined schema that helps organizations:

- Document software components and their relationships.
- Track vulnerabilities across the software supply chain.
- Verify license compliance for open-source dependencies.
- Establish a consistent and machine-readable SBOM format.

CycloneDX supports multiple output formats, including JSON, XML, and Protocol Buffers, making it versatile for different integration needs. The specification is designed to be comprehensive yet efficient, covering everything from basic component identification to detailed metadata about software provenance.

## Before you begin

To complete this tutorial, you need:

- A group with the Maintainer or Owner role.
- Access to GitLab CI/CD.
- A configured [GitLab Runner](../../../ci/runners/_index.md#runner-categories) if you're using a GitLab Self-Managed instance. If you're using GitLab.com, you can skip this requirement.
- Optional. A [group deploy token](../../project/deploy_tokens/_index.md) to authenticate requests to the package registry. 

## Steps 

This tutorial involves two sets of steps to complete:

- Configuring a CI/CD pipeline that generates an SBOM in the CycloneDX format
- Accessing and working with the generated SBOM and package statistics files

Here's an overview of what you'll do:

1. [Add the base pipeline configuration](#add-the-base-pipeline-configuration).
1. [Configure the `prepare` stage](#configure-the-prepare-stage).
1. [Configure the `collect` stage](#configure-the-collect-stage).
1. [Configure the `aggregate` stage](#configure-the-aggregate-stage).
1. [Configure the `publish` stage](#configure-the-publish-stage).
1. [Access the generated SBOM and statistics files](#access-the-generated-files).

{{< alert type="note" >}}

Before implementing this solution, be aware that:

- Package dependencies are not resolved (only direct packages are listed).
- Package versions are included, but not analyzed for vulnerabilities.

{{< /alert >}}

### Add the base pipeline configuration

First, set up the base image that defines 
the variables and stages used throughout the pipeline. 

In the following sections, you'll build out 
the pipeline by adding the configuration for each stage.

In your project:

1. Create a `.gitlab-ci.yml` file.
1. In the file, add the following base configuration:

   ```yaml
   # Base image for all jobs
   image: alpine:latest

   variables:
     SBOM_OUTPUT_DIR: "sbom-output"
     SBOM_FORMAT: "cyclonedx"
     OUTPUT_TYPE: "json"
     GROUP_PATH: ${CI_PROJECT_NAMESPACE}
     AUTH_HEADER: "${GROUP_DEPLOY_TOKEN:+Deploy-Token: $GROUP_DEPLOY_TOKEN}"

   before_script:
     - apk add --no-cache curl jq ca-certificates

   stages:
     - prepare
     - collect
     - aggregate
     - publish
   ```

This configuration:

- Uses Alpine Linux for its small footprint and fast job startup
- Supports group deploy tokens for authentication
- Installs `curl` for API requests, `jq` for JSON processing, and `ca-certificates` to ensure secure HTTPS connections
- Stores all outputs in the `sbom-output` directory
- Generates an SBOM in CycloneDX JSON format

### Configure the `prepare` stage

The `prepare` stage sets up a Python environment and installs the required dependencies.

In your `.gitlab-ci.yml` file, add the following configuration:

```yaml
# Set up Python virtual environment and install required packages
prepare_environment:
  stage: prepare
  script: |
    mkdir -p ${SBOM_OUTPUT_DIR}
    apk add --no-cache python3 py3-pip py3-virtualenv
    python3 -m venv venv
    source venv/bin/activate
    pip3 install cyclonedx-bom
  artifacts:
    paths:
      - ${SBOM_OUTPUT_DIR}/
      - venv/
    expire_in: 1 week
```

This stage:

- Creates a Python virtual environment for isolation
- Installs the CycloneDX library for SBOM generation
- Creates the output directory for artifacts
- Persists the virtual environment for later stages
- Sets a one-week expiration for artifacts to manage storage

### Configure the `collect` stage

The `collect` stage gathers package information from your group's package registry.

In your `.gitlab-ci.yml` file, add the following configuration:

```yaml
# Collect package information and versions from GitLab registry
collect_group_packages:
  stage: collect
  script: |
    echo "[]" > "${SBOM_OUTPUT_DIR}/packages.json"
    
    GROUP_PATH_ENCODED=$(echo "${GROUP_PATH}" | sed 's|/|%2F|g')
    PACKAGES_URL="${CI_API_V4_URL}/groups/${GROUP_PATH_ENCODED}/packages"
    
    # Optional exclusion list - you can add package types you want to exclude
    # EXCLUDE_TYPES="terraform"
    
    page=1
    while true; do
      # Fetch all packages without specifying type, with pagination
      response=$(curl --silent --header "${AUTH_HEADER:-"JOB-TOKEN: $CI_JOB_TOKEN"}" \
                    "${PACKAGES_URL}?per_page=100&page=${page}")
      
      if ! echo "$response" | jq 'type == "array"' > /dev/null 2>&1; then
        echo "Error in API response for page $page"
        break
      fi
      
      count=$(echo "$response" | jq '. | length')
      if [ "$count" -eq 0 ]; then
        break
      fi
      
      # Filter packages if EXCLUDE_TYPES is set
      if [ -n "${EXCLUDE_TYPES:-}" ]; then
        filtered_response=$(echo "$response" | jq --arg types "$EXCLUDE_TYPES" '[.[] | select(.package_type | inside($types | split(" ")) | not)]')
        response="$filtered_response"
        count=$(echo "$response" | jq '. | length')
      fi
      
      # Merge this page of results with existing data
      jq -s '.[0] + .[1]' "${SBOM_OUTPUT_DIR}/packages.json" <(echo "$response") > "${SBOM_OUTPUT_DIR}/packages.tmp.json"
      mv "${SBOM_OUTPUT_DIR}/packages.tmp.json" "${SBOM_OUTPUT_DIR}/packages.json"
      
      # Move to next page if we got a full page of results
      if [ "$count" -lt 100 ]; then
        break
      fi
      
      page=$((page + 1))
    done
  artifacts:
    paths:
      - ${SBOM_OUTPUT_DIR}/
    expire_in: 1 week
  dependencies:
    - prepare_environment
```

This stage:

- Makes a single API call to fetch all package types at once (instead of separate calls per type)
- Supports an optional exclusion list for filtering out unwanted package types
- Implements pagination to handle groups with many packages (100 per page)
- URL-encodes the group path to handle subgroups correctly
- Handles API errors gracefully by skipping invalid responses

### Configure the `aggregate` stage

The `aggregate` stage processes the collected data and generates the SBOM.

In your `.gitlab-ci.yml` file, add the following configuration:

```yaml
# Generate SBOM by aggregating package data
aggregate_sboms:
  stage: aggregate
  before_script:
    - apk add --no-cache python3 py3-pip py3-virtualenv
    - python3 -m venv venv
    - source venv/bin/activate
    - pip3 install --no-cache-dir cyclonedx-bom
  script: |
    cat > process_sbom.py << 'EOL'
    import json
    import os
    from datetime import datetime

    def analyze_version_history(packages_file):
        """Process version information by aggregating packages with same name and type"""
        version_history = {}
        package_versions = {}  # Dict to group packages by name and type
        
        try:
            with open(packages_file, 'r') as f:
                packages = json.load(f)
                if not isinstance(packages, list):
                    return version_history
                
                # First, group packages by name and type
                for package in packages:
                    key = f"{package.get('name')}:{package.get('package_type')}"
                    if key not in package_versions:
                        package_versions[key] = []
                    
                    package_versions[key].append({
                        'id': package.get('id'),
                        'version': package.get('version', 'unknown'),
                        'created_at': package.get('created_at')
                    })
                
                # Then process each group to create version history
                for package_key, versions in package_versions.items():
                    # Sort versions by creation date, newest first
                    versions.sort(key=lambda x: x.get('created_at', ''), reverse=True)
                    
                    # Use the first package's ID as the key (newest version)
                    if versions:
                        package_id = str(versions[0]['id'])
                        version_history[package_id] = {
                            'versions': [v['version'] for v in versions],
                            'latest_version': versions[0]['version'] if versions else None,
                            'version_count': len(versions),
                            'first_published': min((v.get('created_at') for v in versions if v.get('created_at')), default=None),
                            'last_updated': max((v.get('created_at') for v in versions if v.get('created_at')), default=None)
                        }
        except Exception as e:
            print(f"Error processing version history: {e}")
        return version_history

    def merge_package_data(package_file):
        """Combine package data and generate component list"""
        merged_components = {}
        package_stats = {
            'total_packages': 0,
            'package_types': {}
        }
        
        try:
            with open(package_file, 'r') as f:
                packages = json.load(f)
                if not isinstance(packages, list):
                    return [], package_stats
                
                for package in packages:
                    package_stats['total_packages'] += 1
                    pkg_type = package.get('package_type', 'unknown')
                    package_stats['package_types'][pkg_type] = package_stats['package_types'].get(pkg_type, 0) + 1
                    
                    component = {
                        'type': 'library',
                        'name': package['name'],
                        'version': package.get('version', 'unknown'),
                        'purl': f"pkg:gitlab/{package['name']}@{package.get('version', 'unknown')}",
                        'package_type': pkg_type,
                        'properties': [{
                            'name': 'registry_url',
                            'value': package.get('_links', {}).get('web_path', '')
                        }]
                    }
                    
                    key = f"{component['name']}:{component['version']}"
                    if key not in merged_components:
                        merged_components[key] = component
        except Exception as e:
            print(f"Error merging package data: {e}")
            return [], package_stats
        
        return list(merged_components.values()), package_stats

    # Main processing
    version_history = analyze_version_history(f"{os.environ['SBOM_OUTPUT_DIR']}/packages.json")
    components, stats = merge_package_data(f"{os.environ['SBOM_OUTPUT_DIR']}/packages.json")
    stats['version_history'] = version_history

    # Create final SBOM document
    sbom = {
        "bomFormat": os.environ['SBOM_FORMAT'],
        "specVersion": "1.4",
        "version": 1,
        "metadata": {
            "timestamp": datetime.utcnow().isoformat(),
            "tools": [{
                "vendor": "GitLab",
                "name": "Package Registry SBOM Generator",
                "version": "1.0.0"
            }],
            "properties": [{
                "name": "package_stats",
                "value": json.dumps(stats)
            }]
        },
        "components": components
    }

    # Write results to files
    with open(f"{os.environ['SBOM_OUTPUT_DIR']}/merged_sbom.{os.environ['OUTPUT_TYPE']}", 'w') as f:
        json.dump(sbom, f, indent=2)

    with open(f"{os.environ['SBOM_OUTPUT_DIR']}/package_stats.json", 'w') as f:
        json.dump(stats, f, indent=2)
    EOL

    python3 process_sbom.py
  artifacts:
    paths:
      - ${SBOM_OUTPUT_DIR}/
    expire_in: 1 week
  dependencies:
    - collect_group_packages
```

This stage:

- Uses an optimized version history analysis that works directly with the `packages.json` file
- Groups packages by name and type to identify different versions of the same package
- Creates a CycloneDX-compliant SBOM in JSON format
- Calculates package statistics, including:
  - Total number of packages by type
  - Version history for each package
  - First-published and last-updated dates
- Generates Package URLs (`purl`) for each component
- Handles missing or invalid data gracefully with proper exception handling
- Creates both the SBOM and a separate statistics file

### Configure the `publish` stage

The `publish` stage uploads the generated SBOM and statistics file to GitLab.

In your `.gitlab-ci.yml` file, add the following configuration:

```yaml
# Publish SBOM files to GitLab package registry
publish_sbom:
  stage: publish
  script: |
    STATS=$(cat "${SBOM_OUTPUT_DIR}/package_stats.json")
    
    # Upload generated files
    curl --header "${AUTH_HEADER:-"JOB-TOKEN: $CI_JOB_TOKEN"}" \
         --upload-file "${SBOM_OUTPUT_DIR}/merged_sbom.${OUTPUT_TYPE}" \
         "${CI_API_V4_URL}/projects/${CI_PROJECT_ID}/packages/generic/sbom/${CI_COMMIT_SHA}/merged_sbom.${OUTPUT_TYPE}"
    
    curl --header "${AUTH_HEADER:-"JOB-TOKEN: $CI_JOB_TOKEN"}" \
         --upload-file "${SBOM_OUTPUT_DIR}/package_stats.json" \
         "${CI_API_V4_URL}/projects/${CI_PROJECT_ID}/packages/generic/sbom/${CI_COMMIT_SHA}/package_stats.json"
    
    # Add package description
    curl --header "${AUTH_HEADER:-"JOB-TOKEN: $CI_JOB_TOKEN"}" \
         --header "Content-Type: application/json" \
         --request PUT \
         --data @- \
         "${CI_API_V4_URL}/projects/${CI_PROJECT_ID}/packages/generic/sbom/${CI_COMMIT_SHA}" << EOF
    {
      "description": "Group Package Registry SBOM generated on $(date -u)\nStats: ${STATS}"
    }
    EOF
  dependencies:
    - aggregate_sboms
```

This stage:

- Publishes the SBOM and statistics files to your project's package registry
- Uses the generic package type for storage
- Uses the commit SHA as the package version for traceability
- Adds a generation timestamp and statistics to the package description

## Access the generated files

When the pipeline completes, it generates these files:

- `merged_sbom.json`: The complete SBOM in CycloneDX format
- `package_stats.json`: Statistics about your packages

To access the generated files:

1. In your project, select **Deploy > Package registry**.
1. Find the package named `sbom`.
1. Download the SBOM and statistics files.

### Using the SBOM file 

The SBOM file follows the [CycloneDX 1.4 JSON specification](https://cyclonedx.org/docs/1.4/json/), and provides details about published packages, package versions, and artifacts in your group's package registry.

You can also use the SBOM file for compliance and auditing purposes, such as:

- Generating reports of published packages
- Documenting your group's package registry contents
- Tracking publishing activity over time

When working with CycloneDX files, consider using the following tools:

- [OWASP Dependency-Track](https://dependencytrack.org/)
- [CycloneDX CLI](https://github.com/CycloneDX/cyclonedx-cli)
- [SBOM analysis tools](https://cyclonedx.org/tool-center/)

### Using the statistics file

The statistics file provides package registry analytics and activity tracking. 

For example, to analyze your package registry, you can:

- View the total number of published packages by type.
- See version counts for each package.
- Track first-published and last-updated dates.

To track package registry activity, you can:

- Monitor package publishing patterns.
- Identify the most-frequently-updated packages.
- Track package registry growth over time.

You can use a CLI tool like `jq` with the statistics file
to generate analytics or activity information in a readable
JSON format. 

The following code block lists several examples of `jq` commands you can run against the statistics file for general analysis or reporting purposes:

```shell
# Get total package count in registry
jq '.total_packages' package_stats.json

# List package types and their counts
jq '.package_types' package_stats.json

# Find packages with most versions published
jq '.version_history | to_entries | sort_by(.value.version_count) | reverse | .[0:5]' package_stats.json
```

## Pipeline scheduling

If you frequently update your package registry, you should update your SBOM accordingly. You can configure pipeline scheduling to generate an updated SBOM based on your publishing activity.

Consider the following recommendations:

- **Daily updates**: Recommended if you publish packages frequently or need up-to-date reports
- **Weekly updates**: Suitable for most teams with moderate package publishing activity
- **Monthly updates**: Sufficient for groups with infrequent package updates

To schedule the pipeline:

1. In your project, go to **Build > Pipeline schedules**.
1. Select **Create a new pipeline schedule** and fill in the form:
   - From the **Cron timezone** dropdown list, select a timezone. 
   - Select an **Interval Pattern**, or add a **Custom** pattern using [cron syntax](../../../ci/pipelines/schedules.md).
   - Select the branch or tag for the pipeline.
   - Under **Variables**, enter any number of CI/CD variables to the schedule.
1. Select **Create pipeline schedule**.

## Troubleshooting

You might run into the following issues while completing this tutorial.

### Authentication errors

If you encounter authentication errors:

- Check your group deploy token permissions.
- Ensure the token has both the `read_package_registry` and `write_package_registry` scopes.
- Verify the token hasn't expired.

### Missing package types

If you're missing package types:

- Make sure your [deploy token has access](../../project/deploy_tokens/_index.md#pull-packages-from-a-package-registry) to all package types. 
- Check if the package type is enabled in your group settings.

### Memory issues in the `aggregate` stage

If you experience memory issues:

- Use a runner with more memory.
- Process fewer packages at once by filtering package types.

### Resource recommendations

For optimal performance:

- Use runners with at least 2GB of RAM.
- Allow 5-10 minutes per 1,000 packages.
- Increase the job timeout for groups with many packages.

### Getting help

If you encounter other issues:

- Check the job logs for specific error messages.
- Verify API access using `curl` commands directly.
- Test with a smaller subset of package types first.
