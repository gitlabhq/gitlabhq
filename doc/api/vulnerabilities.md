# Vulnerabilities API **[ULTIMATE]**

Every API call to vulnerabilities must be authenticated.

If a user is not a member of a project and the project is private, a `GET`
request on that project will result in a `404` status code.

CAUTION: **Caution:**
This API is in an alpha stage and considered unstable.
The response payload may be subject to change or breakage
across GitLab releases.

## Vulnerabilities pagination

By default, `GET` requests return 20 results at a time because the API results
are paginated.

Read more on [pagination](README.md#pagination).

## List project vulnerabilities

List all of a project's vulnerabilities.

```
GET /projects/:id/vulnerabilities
GET /projects/:id/vulnerabilities?report_type=sast
GET /projects/:id/vulnerabilities?report_type=container_scanning
GET /projects/:id/vulnerabilities?report_type=sast,dast
GET /projects/:id/vulnerabilities?scope=all
GET /projects/:id/vulnerabilities?scope=dismissed
GET /projects/:id/vulnerabilities?severity=high
GET /projects/:id/vulnerabilities?confidence=unknown,experimental
```

| Attribute           | Type             | Required   | Description                                                                                                                                                                 |
| ------------------- | ---------------- | ---------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `id`                | integer/string   | yes        | The ID or [URL-encoded path of the project](README.md#namespaced-path-encoding) owned by the authenticated user.                                                            |
| `report_type`       | Array[string]    | no         | Returns vulnerabilities belonging to specified report type. Valid values: `sast`, `dast`, `dependency_scanning`, or `container_scanning`.                                   |
| `scope`             | string           | no         | Returns vulnerabilities for the given scope: `all` or `dismissed`. Defaults to `dismissed`                                                                                  |
| `severity`          | Array[string]    | no         | Returns vulnerabilities belonging to specified severity level: `undefined`, `info`, `unknown`, `low`, `medium`, `high`, or `critical`. Defaults to all'                     |
| `confidence`        | Array[string]    | no         | Returns vulnerabilities belonging to specified confidence level: `undefined`, `ignore`, `unknown`, `experimental`, `low`, `medium`, `high`, or `confirmed`. Defaults to all |

```bash
curl --header "PRIVATE-TOKEN: <your_access_token>" https://gitlab.example.com/api/v4/projects/4/vulnerabilities
```

Example response:

```json
[
  {
    "id": null,
    "report_type": "dependency_scanning",
    "name": "Authentication bypass via incorrect DOM traversal and canonicalization in saml2-js",
    "severity": "unknown",
    "confidence": "undefined",
    "scanner": {
      "external_id": "gemnasium",
      "name": "Gemnasium"
    },
    "identifiers": [
      {
        "external_type": "gemnasium",
        "external_id": "9952e574-7b5b-46fa-a270-aeb694198a98",
        "name": "Gemnasium-9952e574-7b5b-46fa-a270-aeb694198a98",
        "url": "https://deps.sec.gitlab.com/packages/npm/saml2-js/versions/1.5.0/advisories"
      },
      {
        "external_type": "cve",
        "external_id": "CVE-2017-11429",
        "name": "CVE-2017-11429",
        "url": "https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2017-11429"
      }
    ],
    "project_fingerprint": "fa6f5b6c5d240b834ac5e901dc69f9484cef89ec",
    "create_vulnerability_feedback_issue_path": "/tests/yarn-remediation-test/vulnerability_feedback",
    "create_vulnerability_feedback_merge_request_path": "/tests/yarn-remediation-test/vulnerability_feedback",
    "create_vulnerability_feedback_dismissal_path": "/tests/yarn-remediation-test/vulnerability_feedback",
    "project": {
      "id": 31,
      "name": "yarn-remediation-test",
      "full_path": "/tests/yarn-remediation-test",
      "full_name": "tests / yarn-remediation-test"
    },
    "dismissal_feedback": null,
    "issue_feedback": null,
    "merge_request_feedback": null,
    "description": "Some XML DOM traversal and canonicalization APIs may be inconsistent in handling of comments within XML nodes. Incorrect use of these APIs by some SAML libraries results in incorrect parsing of the inner text of XML nodes such that any inner text after the comment is lost prior to cryptographically signing the SAML message. Text after the comment therefore has no impact on the signature on the SAML message.\r\n\r\nA remote attacker can modify SAML content for a SAML service provider without invalidating the cryptographic signature, which may allow attackers to bypass primary authentication for the affected SAML service provider.",
    "links": [
      {
        "url": "https://github.com/Clever/saml2/commit/3546cb61fd541f219abda364c5b919633609ef3d#diff-af730f9f738de1c9ad87596df3f6de84R279"
      },
      {
        "url": "https://www.kb.cert.org/vuls/id/475445"
      },
      {
        "url": "https://github.com/Clever/saml2/issues/127"
      }
    ],
    "location": {
      "file": "yarn.lock",
      "dependency": {
        "package": {
          "name": "saml2-js"
        },
        "version": "1.5.0"
      }
    },
    "solution": "Upgrade to fixed version.\r\n",
    "blob_path": "/tests/yarn-remediation-test/blob/cc6c4a0778460455ae5d16ca7025ca9ca1ca75ac/yarn.lock"
  }
]
```
