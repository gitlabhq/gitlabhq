---
stage: none
group: unassigned
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
title: Refactoring guide
---

This document is a collection of techniques and best practices to consider while performing a refactor.

## Pinning tests

Pinning tests help you ensure that you don't unintentionally change the output or behavior of the entity you're refactoring. This even includes preserving any existing *buggy* behavior, since consumers may rely on those bugs implicitly.

### Example steps

1. Identify all the possible inputs to the refactor subject (for example, anything that's injected into the template or used in a conditional).
1. For each possible input, identify the significant possible values.
1. Create a test to save a full detailed snapshot for each helpful combination values per input. This should guarantee that we have "pinned down" the current behavior. The snapshot could be literally a screenshot, a dump of HTML, or even an ordered list of debugging statements.
1. Run all the pinning tests against the code, before you start refactoring (Oracle)
1. Perform the refactor (or check out the commit with the work done)
1. Run again all the pinning test against the post refactor code (Pin)
1. Compare the Oracle with the Pin. If the Pin is different, you know the refactoring doesn't preserve existing behavior.
1. Repeat the previous three steps as necessary until the refactoring is complete.

### Example commit history

Leaving in the commits for adding and removing pins helps others check out and verify the result of the test.

```shell
AAAAAA Add pinning tests to funky_foo
BBBBBB Refactor funky_foo into nice_foo
CCCCCC Remove pinning tests for funky_foo
```

Then you can leave a reviewer instructions on how to run the pinning test in your MR. Example:

> First revert the commit which removes the pin.
>
> ```shell
> git revert --no-commit $(git log -1 --grep="Remove pinning test for funky_foo" --pretty=format:"%H")
> ```
>
> Then run the test
>
> ```shell
> yarn run jest path/to/funky_foo_pin_spec.js
> ```

### Try to keep pins green

It's hard for a refactor to be 100% pure. This means that a pin which captures absolutely everything is bound to fail with
some trivial and expected differences. Try to keep the pins green by cleaning the pin with the expected changes. This helps
others quickly verify that a refactor was safe.

[Example](https://gitlab.com/gitlab-org/gitlab/-/commit/7b73da4078a60cf18f5c10c712c66c302174f506?merge_request_iid=29528#a061e6835fd577ccf6802c8a476f4e9d47466d16_0_23):

```javascript
// funky_foo_pin_spec.js

const cleanForSnapshot = el => {
  Array.from(rootEl.querySelectorAll('[data-deprecated-attribute]')).forEach(el => {
    el.removeAttribute('data-deprecated-attribute');
  });
};

// ...

expect(cleanForSnapshot(wrapper.element)).toMatchSnapshot();
```

### Resources

[Unofficial wiki explanation](https://wiki.c2.com/?PinningTests)

### Examples

- [Pinning test in a Haml to Vue refactor](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/27691#pinning-tests)
- [Pinning test in isolating a bug](https://gitlab.com/gitlab-org/gitlab-foss/-/merge_requests/32198#note_212736225)
- [Pinning test in refactoring dropdown list](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/28173)
- [Pinning test in refactoring vulnerability_details.vue](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/25830/commits)
- [Pinning test in refactoring notes_award_list.vue](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/29528#pinning-test)
- <i class="fa fa-youtube-play youtube" aria-hidden="true"></i> [Video of pair programming session on pinning tests](https://youtu.be/LrakPcspBK4)
