# What does this MR do?

This merge request contains translations of GitLab product documentation. The source files are
from the `/doc` directory, and translations are returned to language-specific directories under `/doc-locale`.

## Translation MR information

- Argo Request: [{{argo_request_key}}: {{argo_request_name}}]({{argo_request_url}})
- Source: {{source_content_origin}}

## Review workflow

For the full review workflow documentation, see the [Translation MR Review Workflow](https://gitlab.com/gitlab-com/localization/docs-site-localization/-/blob/main/translation_mr_review_workflow.md).

### Assignee checklist

- [ ] Fix conflicts (check commit history of each file in `main` to identify target changes causing conflicts, such as translation changes on production or TW shortcode/linting updates)
- [ ] Fix any pipeline issues
- [ ] Rebase if needed
- [ ] Check the review app for all impacted pages (Duo can help produce a list of URLs)
- [ ] Remove the MR from Draft mode (this triggers the first review by GitLab Duo)
- [ ] If the Duo review identified translation errors requiring review by [Japanese content maintainers](https://gitlab.com/gitlab-com/localization/maintainers/japanese), ping and add them as a reviewer.
- [ ] Hand off for review to a [tech docs maintainer](https://gitlab.com/gitlab-com/localization/maintainers/tech-docs). The MR should be ready to merge at this point

### Review App

| Review app |
| ---------- |
|  |

### Reviewer checklist

- [ ] Review changes
- [ ] Verify build pipeline
- [ ] Merge on approval

/title Product Docs AI Translation: {{argo_request_key}} #{{translation_mr_number}}
/draft

/assign @gitlab-argo-bot

/label ~documentation
/label ~"gitlab-translation-service"
/label ~"group::localization"
/label ~"docs-only"
/label ~"type::maintenance"
