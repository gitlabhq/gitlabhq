export function createCveIdRequestIssueBody(fullPath, iid) {
  return `### Vulnerability Submission

**NOTE:** Only maintainers of GitLab-hosted projects may request a CVE for
a vulnerability within their project.

Project issue: ${fullPath}#${iid}

#### Publishing Schedule

After a CVE request is validated, a CVE identifier will be assigned. On what
schedule should the details of the CVE be published?

* [ ] Publish immediately
* [ ] Wait to publish

<!--
Please fill out the yaml codeblock below
-->

\`\`\`yaml
reporter:
  name: "TODO" # "First Last"
  email: "TODO" # "email@domain.tld"
vulnerability:
  description: "TODO" # "[VULNTYPE] in [COMPONENT] in [VENDOR][PRODUCT] [VERSION] allows [ATTACKER] to [IMPACT] via [VECTOR]"
  cwe: "TODO" # "CWE-22" # Path Traversal
  product:
    gitlab_path: "${fullPath}"
    vendor: "TODO" # "Deluxe Sandwich Maker Company"
    name: "TODO" # "Deluxe Sandwich Maker 2"
    affected_versions:
      - "TODO" # "1.2.3"
      - "TODO" # ">1.3.0, <=1.3.9"
    fixed_versions:
      - "TODO" # "1.2.4"
      - "TODO" # "1.3.10"
  impact: "TODO" # "CVSS v3 string" # https://nvd.nist.gov/vuln-metrics/cvss/v3-calculator
  solution: "TODO" # "Upgrade to version 1.2.4 or 1.3.10"
  credit: "TODO"
  references:
    - "TODO" # "https://some.domain.tld/a/reference"
\`\`\`

CVSS scores can be computed by means of the [NVD CVSS Calculator](https://nvd.nist.gov/vuln-metrics/cvss/v3-calculator).

/relate ${fullPath}#${iid}
/label ~"devops::secure" ~"group::vulnerability research" ~"vulnerability research::cve" ~"advisory::queued"
  `;
}
