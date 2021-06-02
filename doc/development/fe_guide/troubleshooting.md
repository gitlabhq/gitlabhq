---
stage: none
group: unassigned
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Troubleshooting

Running into a problem? Maybe this will help ¯\＿(ツ)＿/¯.

## Troubleshooting issues

### This guide doesn't contain the issue I ran into

If you run into a Frontend development issue that is not in this guide, please consider updating this guide with your issue and possible remedies. This way future adventurers can face these dragons with more success, being armed with your experience and knowledge.

## Testing issues

### ``Property or method `nodeType` is not defined`` but I'm not using `nodeType` anywhere

This issue can happen in Vue component tests, when an expectation fails, but there is an error thrown when
Jest tries to pretty print the diff in the console. It's been noted that using `toEqual` with an array as a
property might also be a contributing factor.

See [this video](https://youtu.be/-BkEhghP-kM) for an in-depth overview and investigation.

**Remedy - Try cloning the object that has Vue watchers**

```patch
- expect(wrapper.findComponent(ChildComponent).props()).toEqual(...);
+ expect(cloneDeep(wrapper.findComponent(ChildComponent).props())).toEqual(...)
```

**Remedy - Try using `toMatchObject` instead of `toEqual`**

```patch
- expect(wrapper.findComponent(ChildComponent).props()).toEqual(...);
+ expect(wrapper.findComponent(ChildComponent).props()).toMatchObject(...);
```

Please note that `toMatchObject` actually changes the nature of the assertion and won't fail if some items are **missing** from the expectation.

### Script issues

## `core-js` errors when running scripts within the GitLab repository

The following command assumes you've set up the GitLab repository in the
`~/workspace/gdk` directory. When running scripts within the GitLab repository,
such as code transformations, you might run into issues with `core-js` like this:

```shell
~/workspace/gdk/gitlab/node_modules/core-js/modules/es.global-this.js:7
$({
^
TypeError: $ is not a function
    at Object.<anonymous> (~/workspace/gdk/gitlab/node_modules/core-js/modules/es.global-this.js:6:1)
    at Module._compile (internal/modules/cjs/loader.js:1063:30)
    at Module._compile (~/workspace/gdk/gitlab/node_modules/pirates/lib/index.js:99:24)
    at Module._extensions..js (internal/modules/cjs/loader.js:1092:10)
    at Object.newLoader [as .js] (~/workspace/gdk/gitlab/node_modules/pirates/lib/index.js:104:7)
    at Module.load (internal/modules/cjs/loader.js:928:32)
    at Function.Module._load (internal/modules/cjs/loader.js:769:14)
    at Module.require (internal/modules/cjs/loader.js:952:19)
    at require (internal/modules/cjs/helpers.js:88:18)
    at Object.<anonymous> (~/workspace/gdk/gitlab/node_modules/core-js/modules/esnext.global-this.js:2:1)
```

**Remedy - Try moving the script into a separate repository and point to it to files in the GitLab repository**

## Using Vue component issues

### When rendering a component that uses GlFilteredSearch and the component or its parent uses Vue Apollo

When trying to render our component GlFilteredSearch, you might get an error in the component's `provide` function:

`cannot read suggestionsListClass of undefined`

Currently, `vue-apollo` tries to [manually call a component's `provide()` in the `beforeCreate` part](https://github.com/vuejs/vue-apollo/blob/35e27ec398d844869e1bbbde73c6068b8aabe78a/packages/vue-apollo/src/mixin.js#L149) of the component lifecycle. This means that when a `provide()` references props, which aren't actually setup until after `created`, it will blow up.

See this [closed MR](https://gitlab.com/gitlab-org/gitlab-ui/-/merge_requests/2019#note_514671251) for more context.

**Remedy - try providing `apolloProvider` to the top-level Vue instance options**

VueApollo will skip manually running `provide()` if it sees that an `apolloProvider` is provided in the `$options`.

```patch
  new Vue(
    el,
+   apolloProvider: {},
    render(h) {
      return h(App);
    },
  );
```
