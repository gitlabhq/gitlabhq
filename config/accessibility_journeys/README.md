# Accessibility Journey Configuration Files

This directory contains YAML configuration files for generating accessibility test boilerplates for golden user journeys.
Each YAML file represents one golden user journey and maps to multiple E2E test files that collectively represent that journey.
The generator script reads these configs and produces comprehensive accessibility test boilerplates.

## File Naming Convention

Files should be named: `[STAGE]_[JOURNEY_NAME].yml`

Examples:

- `create_writing_code.yml`
- `create_reviewing_code.yml`
- `plan_managing_issues.yml`

## YAML Structure

```yaml
# Required fields
stage: create                          # Stage name (create, plan, verify, etc.)
journey_name: writing_code             # Journey name (snake_case)
feature_category: source_code_management  # Feature category for RSpec metadata
description: "Brief description of this golden user journey"

# E2E test file mappings
e2e_test_files:
  - path: qa/qa/specs/features/browser_ui/3_create/some_test_spec.rb
    description: Short description of what this test covers
    focus_area: Area Name           # Used to group related tests in contexts
    has_ui: true                    # Set to false for tests without UI to test

  - path: qa/qa/specs/features/browser_ui/3_create/another_test_spec.rb
    description: Another test description
    focus_area: Area Name
    has_ui: true
```

## Field Descriptions

### Required Top-Level Fields

- **stage**: The GitLab stage this journey belongs to (create, plan, verify, etc.)
- **journey_name**: Snake_case name for the journey (used in filename generation)
- **feature_category**: The RSpec feature_category metadata
- **description**: A brief description of the golden user journey
- **e2e_test_files**: List of E2E test file mappings (see below)

### Optional Top-Level Fields

- **feature_test_hints**: List of directory paths to search for relevant feature tests
  - Helps the generator find the most appropriate reference files
  - Paths are relative to `spec/features/`
  - Example: `['projects/files', 'projects/tree', 'work_items/issues']`
  - If omitted, the generator uses intelligent domain mapping from E2E test paths

### E2E Test File Fields

Each entry in `e2e_test_files` should have:

- **path**: Relative path to the E2E test file from GitLab root
- **description**: Short description of what this E2E test validates
- **focus_area**: Category/area name used to group related tests together in the generated spec
- **has_ui**: Boolean indicating if this test has UI elements to check for accessibility
  - Set to `true` if the test exercises UI that can be checked with axe
  - Set to `false` for backend/API tests or git operations without UI

## Focus Areas

The `focus_area` field is used to organize related E2E tests into context blocks in the generated spec. Tests with the same `focus_area` are grouped together.

Examples of good focus areas:

- "Single-file editor"
- "Web IDE"
- "Git interactions"
- "Issue list view"
- "Issue detail view"
- "Board interactions"

## Filtering Tests Without UI

Tests with `has_ui: false` are automatically filtered out by the generator script. Use this to mark:

- Git push/pull operations (no UI to test)
- API-only tests
- Backend functionality without frontend components

## How to Generate Accessibility Test Boilerplates

### Quick Start

1. Create a YAML configuration for your golden journey:

   ```shell
   cp config/accessibility_journeys/_template.yml config/accessibility_journeys/plan_managing_issues.yml
   ```

1. Edit the YAML file with your journey details and E2E test mappings (see structure above)
1. Run the generator:

   ```shell
     ruby scripts/generate_accessibility_spec.rb plan_managing_issues.yml
   ```

1. Review the generated spec at `spec/features/accessibility/[stage]/[journey_name]_spec.rb`

### What the Generator Does

1. Reads and validates the YAML configuration
1. Filters out tests without UI (`has_ui: false`)
1. Groups tests by `focus_area`
1. Extracts test metadata from E2E files (test case URLs, descriptions)
1. Searches for related feature test files
1. Generates the boilerplate spec at `spec/features/accessibility/[STAGE]/[JOURNEY_NAME]_spec.rb`

## Creating New Journey Configs

1. Select a user journey from [the Figma repository](https://www.figma.com/files/972612628770206748/team/1517620701713485782).
1. Use Glean to map the user journey to E2E test cases in qa/qa/specs/features/browser_ui/[stage_name]. Use [existing mapping](https://gitlab.com/gitlab-org/gitlab/-/issues/580804#note_3093172518) as an example.
1. Take the output and generate the YAML file for it based on `_template.yml`.
1. Mark tests without GitLab UI as `has_ui: false`
1. Run the generator to create the boilerplate spec
1. Commit both the YAML configuration and generated spec

## Related Documentation

- [UX User journeys](https://handbook.gitlab.com/handbook/product/ux/user-journeys/#key-terminology)
- [Golden User Journeys Work Item](https://gitlab.com/gitlab-org/gitlab/-/work_items/580804)
- [Generator Script](https://gitlab.com/gitlab-org/gitlab/-/blob/f652945b38c45d71773a25773c71348abad7eef0/scripts/generate_accessibility_spec.rb)
- [Generated Specs Directory](https://gitlab.com/gitlab-org/gitlab/-/tree/f652945b38c45d71773a25773c71348abad7eef0/spec/features/accessibility)
