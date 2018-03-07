See the general Documentation guidelines http://docs.gitlab.com/ce/development/doc_styleguide.html

## What does this MR do?

(briefly describe what this MR is about)

## Moving docs to a new location?

See the guidelines: http://docs.gitlab.com/ce/development/doc_styleguide.html#changing-document-location

- [ ] Make sure the old link is not removed and has its contents replaced with a link to the new location.
- [ ] Make sure internal links pointing to the document in question are not broken.
- [ ] Search and replace any links referring to old docs in GitLab Rails app, specifically under the `app/views/` directory.
- [ ] Make sure to add [`redirect_from`](https://docs.gitlab.com/ee/development/doc_styleguide.html#redirections-for-pages-with-disqus-comments) to the new document if there are any Disqus comments on the old document thread.
- [ ] If working on CE, submit an MR to EE with the changes as well.
- [ ] Ping one of the technical writers for review.
