---
stage: Create
group: Source Code
info: "To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments"
title: Rails Endpoints
---

Rails Endpoints are used by different GitLab components, they cannot be
used by other consumers. This documentation is intended for people
working on the GitLab codebase.

These Rails Endpoints:

- May not have extensive documentation or follow the same conventions as our public or private APIs.
- May not adhere to standardized rules or guidelines.
- Are designed to serve specific internal purposes in the codebase.
- Are subject to change at any time.

## Proof of concept period: Feedback Request

We are evaluating a new approach for documenting Rails endpoints. [Check out the Feedback Issue](https://gitlab.com/gitlab-org/gitlab/-/issues/411605) and feel free to share your thoughts, suggestions, or concerns. We appreciate your participation in helping us improve the documentation!

## SAST Scanners

Static Application Security Testing (SAST) checks your source code for known vulnerabilities. When SAST is enabled
on a Project these endpoints are available.

### List existing merge request code quality findings sorted by files

Get a list of existing code quality Findings, if any, sorted by files.

```plaintext
GET /projects/:id/merge_requests/:merge_request_iid/codequality_mr_diff_reports.json
```

Response:

```json
{
  "files": {
    "index.js": [
      {
        "line": 1,
        "description": "Unexpected 'debugger' statement.",
        "severity": "major"
      }
    ]
  }
}
```

### List new, resolved and existing merge request code quality findings

Get a list of new, resolved, and existing code quality Findings, if any.

```plaintext
GET /projects/:id/merge_requests/:merge_request_iid/codequality_reports.json
```

```json
{
  "status": "failed",
  "new_errors": [
    {
      "description": "Unexpected 'debugger' statement.",
      "severity": "major",
      "file_path": "index.js",
      "line": 1,
      "web_url": "https://gitlab.com/jannik_lehmann/code-quality-test/-/blob/ed1c1b3052fe6963beda0e416d5e2ba3378eb715/noise.rb#L12",
      "engine_name": "eslint"
    }
  ],
  "resolved_errors": [],
  "existing_errors": [],
  "summary": { "total": 1, "resolved": 0, "errored": 1 }
}
```
