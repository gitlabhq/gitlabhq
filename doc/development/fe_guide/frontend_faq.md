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

### How do I find the Rails route for a page?

The easiest way is to type the following in the browser while on the page in
question:

```javascript
document.body.dataset.page
```

Find here the [source code setting the attribute](https://gitlab.com/gitlab-org/gitlab-ce/blob/cc5095edfce2b4d4083a4fb1cdc7c0a1898b9921/app/views/layouts/application.html.haml#L4).

### `modal_copy_button` vs `clipboard_button`

The `clipboard_button` uses the `copy_to_clipboard.js` behaviour, which is
initialized on page load, so if there are vue-based clipboard buttons that
don't exist at page load (such as ones in a `GlModal`), they do not have the
click handlers associated with the clipboard package.

`modal_copy_button` was added that manages an instance of the
[`clipboard` plugin](https://www.npmjs.com/package/clipboard) specific to
the instance of that component, which means that clipboard events are
bound on mounting and destroyed when the button is, mitigating the above
issue. It also has bindings to a particular container or modal ID
available, to work with the focus trap created by our GlModal.
