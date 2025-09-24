<!--
Title: MCP Tool Proposal
Instructions: Replace placeholders. Keep comments as needed during drafting; remove before submission.
-->

## Summary
<!-- Briefly describe the tool, the user problem/use case, and expected outcome. -->

## Problem Statement / Use Case
<!-- Explain the purpose of the tool. What problem does it solve? Who benefits? Include concrete scenarios. -->

## Scope and Non-Goals
<!-- What this tool will cover vs. what it will not. Note any future follow-ups. -->

## API Interactions
<!-- If this tool interacts with existing APIs, document them here. -->

- Uses existing API endpoints? (Yes/No)
  - If Yes, list all endpoints (REST/GraphQL):
    - REST: `METHOD /path` — purpose
      - Docs: <link to API doc>
    - GraphQL: `query/mutation Name` — purpose
      - Docs: <link to schema/doc>
  - Does the tool perform search or list functionality via an existing API? (Yes/No)
  - Additional input parameters not available on the API? (Yes/No)
    - If Yes, list params, rationale, and server-side handling:
      - `param_name` — why needed; how it maps or is composed server-side

## Data Shape and Context Engineering
<!-- Define input/output schemas; show how you avoid context saturation (chunking, limits, metadata). -->

- Input schema (example):
<!--
```json
{
  "tool": "read_repository_files",
  "description": "Reads and retrieves the contents of multiple files from a repository, with optional filtering by line ranges or output size limits.",
  "parameters": {
    "project_path": "string",
    "files": [
      {
        "path": "string",
        "ref": "string",
        "line_start": "integer (optional)",
        "line_end": "integer (optional)",
        "max_lines": "integer (optional, default: 100)"
      }
    ],
    "include_metadata": "boolean (default: true)"
  }
}
```
-->

<!--
- Output schema (JSON example):
```json
{
  "repository_files": [
    {
      "path": "app/models/user.rb",
      "ref": "main",
      "metadata": {
        "total_lines": 450,
        "returned_lines": {
          "start": 1,
          "end": 100
        },
        "truncated": true,
        "size_bytes": 15234
      },
      "content": "First 100 lines of content here",
      "system_instruction": "File truncated. To view more content, use:\n- Lines 101-200: {\"line_start\": 101, \"line_end\": 200}\n- Lines around specific area: {\"line_start\": 250, \"line_end\": 300}\n- Remaining lines: 350 lines available"
    },
    {
      "path": "config/routes.rb",
      "ref": "main",
      "metadata": {
        "total_lines": 75,
        "returned_lines": {
          "start": 1,
          "end": 75
        },
        "truncated": false
      },
      "content": "Complete file content"
    }
  ]
}
```

- Output schema  (XML example):
```xml
<repository_files>
  <file path="app/models/user.rb" ref="main">
    <metadata>
      <total_lines>450</total_lines>
      <returned_lines start="1" end="100"/>
      <truncated>true</truncated>
      <size_bytes>15234</size_bytes>
    </metadata>
    <content>
      First 100 lines of content here
    </content>
    <system_instruction>
      File truncated. To view more content, use:
      - Lines 101-200: {"line_start": 101, "line_end": 200}
      - Lines around specific area: {"line_start": 250, "line_end": 300}
      - Remaining lines: 350 lines available
    </system_instruction>
  </file>
  <file path="config/routes.rb" ref="main">
    <metadata>
      <total_lines>75</total_lines>
      <returned_lines start="1" end="75"/>
      <truncated>false</truncated>
    </metadata>
    <content>
      Complete file content
    </content>
  </file>
</repository_files>
```
-->

<!--
Resources: 
* Context Engineering Best Practices: https://jxnl.co/writing/2025/08/27/facets-context-engineering/
* MCP vs Traditional APIs: https://auth0.com/blog/mcp-vs-api/
-->

/assign me
/assign_reviewer @gitlab-org/ai-powered/mcp-tool-review-board
