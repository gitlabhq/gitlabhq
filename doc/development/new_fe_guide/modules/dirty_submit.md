---
stage: none
group: unassigned
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Dirty Submit

> [Introduced](https://gitlab.com/gitlab-org/gitlab-foss/-/merge_requests/21115) in GitLab 11.3.

## Summary

Prevent submitting forms with no changes.

Currently handles `input`, `textarea` and `select` elements.

Also, see [the code](https://gitlab.com/gitlab-org/gitlab/-/blob/master/app/assets/javascripts/dirty_submit/)
within the GitLab project.

## Usage

```javascript
import dirtySubmitFactory from './dirty_submit/dirty_submit_form';

new DirtySubmitForm(document.querySelector('form'));
// or
new DirtySubmitForm(document.querySelectorAll('form'));
```
