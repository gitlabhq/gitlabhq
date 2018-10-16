# Dirty Submit

> [Introduced][ce-21115] in GitLab 11.3.  
> [dirty_submit][dirty-submit]

## Summary

Prevent submitting forms with no changes.

Currently handles `input`, `textarea` and `select` elements.

## Usage

```js
import dirtySubmitFactory from './dirty_submit/dirty_submit_form';

new DirtySubmitForm(document.querySelector('form'));
// or
new DirtySubmitForm(document.querySelectorAll('form'));
```

[ce-21115]: https://gitlab.com/gitlab-org/gitlab-ce/merge_requests/21115
[dirty-submit]: https://gitlab.com/gitlab-org/gitlab-ce/blob/master/app/assets/javascripts/dirty_submit/