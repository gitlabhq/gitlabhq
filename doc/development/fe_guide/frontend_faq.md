# Frontend FAQ

## Rules of Frontend FAQ

1. **You talk about Frontend FAQ.**
   Please share links to it whenever applicable, so more eyes catch when content
   gets outdated.
1. **Keep it short and simple.**
   Whenever an answer needs more than two sentences it does not belong here.
1. **Provide background when possible.**
   Linking to relevant source code, issue / epic, or other documentation helps
   to understand the answer.
1. **If you see something, do something.**
   Please remove or update any content that is outdated as soon as you see it.

## FAQ

### 1. How do I find the Rails route for a page?

#### Check the 'page' data attribute

The easiest way is to type the following in the browser while on the page in
question:

```javascript
document.body.dataset.page
```

Find here the [source code setting the attribute](https://gitlab.com/gitlab-org/gitlab/blob/cc5095edfce2b4d4083a4fb1cdc7c0a1898b9921/app/views/layouts/application.html.haml#L4).

#### Rails routes

The `rake routes` command can be used to list all the routes available in the application, piping the output into `grep`, we can perform a search through the list of available routes.
The output includes the request types available, route parameters and the relevant controller.

```shell
bundle exec rake routes | grep "issues"
```

### 2. `modal_copy_button` vs `clipboard_button`

The `clipboard_button` uses the `copy_to_clipboard.js` behavior, which is
initialized on page load, so if there are vue-based clipboard buttons that
don't exist at page load (such as ones in a `GlModal`), they do not have the
click handlers associated with the clipboard package.

`modal_copy_button` was added that manages an instance of the
[`clipboard` plugin](https://www.npmjs.com/package/clipboard) specific to
the instance of that component, which means that clipboard events are
bound on mounting and destroyed when the button is, mitigating the above
issue. It also has bindings to a particular container or modal ID
available, to work with the focus trap created by our GlModal.

### 3. A `gitlab-ui` component not conforming to [Pajamas Design System](https://design.gitlab.com/)

Some [Pajamas Design System](https://design.gitlab.com/) components implemented in
`gitlab-ui` do not conform with the design system specs because they lack some
planned features or are not correctly styled yet. In the Pajamas website, a
banner on top of the component examples indicates that:

> This component does not yet conform to the correct styling defined in our Design
> System. Refer to the Design System documentation when referencing visuals for this
> component.

For example, at the time of writing, this type of warning can be observed for
[all form components](https://design.gitlab.com/components/forms/). It, however,
doesn't imply that the component should not be used.

GitLab always asks to use `<gl-*>` components whenever a suitable component exists.
It makes codebase unified and more comfortable to maintain/refactor in the future.

Ensure a [Product Designer](https://about.gitlab.com/company/team/?department=ux-department)
reviews the use of the non-conforming component as part of the MR review. Make a
follow up issue and attach it to the component implementation epic found within the
[Components of Pajamas Design System epic](https://gitlab.com/groups/gitlab-org/-/epics/973).

### 4. My submit form button becomes disabled after submitting

If you are using a submit button inside a form and you attach an `onSubmit` event listener on the form element, [this piece of code](https://gitlab.com/gitlab-org/gitlab/blob/794c247a910e2759ce9b401356432a38a4535d49/app/assets/javascripts/main.js#L225) will add a `disabled` class selector to the submit button when the form is submitted.
To avoid this behavior, add the class `js-no-auto-disable` to the button.

### 5. Should I use a full URL (i.e. `gon.gitlab_url`) or a full path (i.e. `gon.relative_url_root`) when referencing backend endpoints?

It's preferred to use a **full path** over a **full URL** because the URL will use the hostname configured with
GitLab which may not match the request. This will cause [CORS issues like this Web IDE one](https://gitlab.com/gitlab-org/gitlab/issues/36810).

Example:

```javascript
// bad :(
// If gitlab is configured with hostname `0.0.0.0`
// This will cause CORS issues if I request from `localhost`
axios.get(joinPaths(gon.gitlab_url, '-', 'foo'))

// good :)
axios.get(joinPaths(gon.relative_url_root, '-', 'foo'))
```

Also, please try not to hardcode paths in the Frontend, but instead receive them from the Backend (see next section).
When referencing Backend rails paths, avoid using `*_url`, and use `*_path` instead.

Example:

```haml
-# Bad :(
#js-foo{ data: { foo_url: some_rails_foo_url } }

-# Good :)
#js-foo{ data: { foo_path: some_rails_foo_path } }
```

### 6. How should the Frontend reference Backend paths?

We prefer not to add extra coupling by hardcoding paths. If possible,
add these paths as data attributes to the DOM element being referenced in the JavaScript.

Example:

```javascript
// Bad :(
// Here's a Vuex action that hardcodes a path :(
export const fetchFoos = ({ state }) => {
  return axios.get(joinPaths(gon.relative_url_root, '-', 'foo'));
};

// Good :)
function initFoo() {
  const el = document.getElementById('js-foo');

  // Path comes from our root element's data which is used to initialize the store :)
  const store = createStore({
    fooPath: el.dataset.fooPath
  });

  Vue.extend({
    store,
    el,
    render(h) {
      return h(Component);
    },
  });
}

// Vuex action can now reference the path from it's state :)
export const fetchFoos = ({ state }) => {
  return axios.get(state.settings.fooPath);
};
```
