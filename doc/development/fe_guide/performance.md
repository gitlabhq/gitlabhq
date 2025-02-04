---
stage: none
group: unassigned
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
title: Performance
---

Performance is an essential part and one of the main areas of concern for any modern application.

## Monitoring

We have a performance dashboard available in one of our [Grafana instances](https://dashboards.gitlab.net/d/000000043/sitespeed-page-summary?orgId=1). This dashboard automatically aggregates metric data from [sitespeed.io](https://www.sitespeed.io/) every 4 hours. These changes are displayed after a set number of pages are aggregated.

These pages can be found inside text files in the [`sitespeed-measurement-setup` repository](https://gitlab.com/gitlab-org/frontend/sitespeed-measurement-setup) called [`gitlab`](https://gitlab.com/gitlab-org/frontend/sitespeed-measurement-setup/-/tree/master/gitlab)
Any frontend engineer can contribute to this dashboard. They can contribute by adding or removing URLs of pages to the text files. The changes are pushed live on the next scheduled run after the changes are merged into `main`.

There are 3 recommended high impact metrics (core web vitals) to review on each page:

- [Largest Contentful Paint](https://web.dev/articles/lcp)
- [First Input Delay](https://web.dev/articles/fid/)
- [Cumulative Layout Shift](https://web.dev/articles/cls)

For these metrics, lower numbers are better as it means that the website is more performant.

## User Timing API

[User Timing API](https://developer.mozilla.org/en-US/docs/Web/API/Performance_API/User_timing) is a web API
[available in all modern browsers](https://caniuse.com/?search=User%20timing). It allows measuring
custom times and durations in your applications by placing special marks in your
code. You can use the User Timing API in GitLab to measure any timing, regardless of the framework,
including Rails, Vue, or vanilla JavaScript environments. For consistency and
convenience of adoption, GitLab offers several ways to enable custom user timing metrics in
your code.

User Timing API introduces two important paradigms: `mark` and `measure`.

**Mark** is the timestamp on the performance timeline. For example,
`performance.mark('my-component-start');` makes a browser note the time this code
is met. Then, you can obtain information about this mark by querying the global
performance object again. For example, in your DevTools console:

```javascript
performance.getEntriesByName('my-component-start')
```

**Measure** is the duration between either:

- Two marks
- The start of navigation and a mark
- The start of navigation and the moment the measurement is taken

It takes several arguments of which the measurement's name is the only one required. Examples:

- Duration between the start and end marks:

  ```javascript
  performance.measure('My component', 'my-component-start', 'my-component-end')
  ```

- Duration between a mark and the moment the measurement is taken. The end mark is omitted in
  this case.

  ```javascript
  performance.measure('My component', 'my-component-start')
  ```

- Duration between [the navigation start](https://developer.mozilla.org/en-US/docs/Web/API/Performance/timeOrigin)
  and the moment the actual measurement is taken.

  ```javascript
  performance.measure('My component')
  ```

- Duration between [the navigation start](https://developer.mozilla.org/en-US/docs/Web/API/Performance/timeOrigin)
  and a mark. You cannot omit the start mark in this case but you can set it to `undefined`.

  ```javascript
  performance.measure('My component', undefined, 'my-component-end')
  ```

To query a particular `measure`, You can use the same API, as for `mark`:

```javascript
performance.getEntriesByName('My component')
```

You can also query for all captured marks and measurements:

```javascript
performance.getEntriesByType('mark');
performance.getEntriesByType('measure');
```

Using `getEntriesByName()` or `getEntriesByType()` returns an Array of
[the PerformanceMeasure objects](https://developer.mozilla.org/en-US/docs/Web/API/PerformanceMeasure)
which contain information about the measurement's start time and duration.

### User Timing API utility

You can use the `performanceMarkAndMeasure` utility anywhere in GitLab, as it's not tied to any
particular environment.

`performanceMarkAndMeasure` takes an object as an argument, where:

| Attribute   | Type     | Required | Description           |
|:------------|:---------|:---------|:----------------------|
| `mark`      | `String` | no       | The name for the mark to set. Used for retrieving the mark later. If not specified, the mark is not set. |
| `measures`  | `Array`  | no       | The list of the measurements to take at this point. |

In return, the entries in the `measures` array are objects with the following API:

| Attribute   | Type     | Required | Description           |
|:------------|:---------|:---------|:----------------------|
| `name`      | `String` | yes      | The name for the measurement. Used for retrieving the mark later. Must be specified for every measure object, otherwise JavaScript fails. |
| `start`     | `String` | no       | The name of a mark **from** which the measurement should be taken. |
| `end`       | `String` | no       | The name of a mark **to** which the measurement should be taken. |

Example:

```javascript
import { performanceMarkAndMeasure } from '~/performance/utils';
...
performanceMarkAndMeasure({
  mark: MR_DIFFS_MARK_DIFF_FILES_END,
  measures: [
    {
      name: MR_DIFFS_MEASURE_DIFF_FILES_DONE,
      start: MR_DIFFS_MARK_DIFF_FILES_START,
      end: MR_DIFFS_MARK_DIFF_FILES_END,
    },
  ],
});
```

### Vue performance plugin

The plugin captures and measures the performance of the specified Vue components automatically
leveraging the Vue lifecycle and the User Timing API.

To use the Vue performance plugin:

1. Import the plugin:

   ```javascript
   import PerformancePlugin from '~/performance/vue_performance_plugin';
   ```

1. Use it before initializing your Vue application:

   ```javascript
   Vue.use(PerformancePlugin, {
     components: [
       'IdeTreeList',
       'FileTree',
       'RepoEditor',
     ]
   });
   ```

The plugin accepts the list of components, performance of which should be measured. The components
should be specified by their `name` option.

You might need to explicitly set this option on the needed components, as
most components in the codebase don't have this option set:

```javascript
export default {
  name: 'IdeTreeList',
  components: {
    ...
  ...
}
```

The plugin captures and stores the following:

- The start **mark** for when the component has been initialized (in `beforeCreate()` hook)
- The end **mark** of the component when it has been rendered (next animation frame after `nextTick`
  in `mounted()` hook). In most cases, this event does not wait for all sub-components to be
  bootstrapped. To measure the sub-components, you should include those into the
  plugin options.
- **Measure** duration between the two marks above.

### Access stored measurements

To access stored measurements, you can use either:

- **Performance bar**. If you have it enabled (`P` + `B` key-combo), you can see the metrics
  output in your DevTools console.
- **"Performance" tab** of the DevTools. You can get the measurements (not the marks, though) in
  this tab when profiling performance.
- **DevTools console**. As mentioned above, you can query for the entries:

  ```javascript
  performance.getEntriesByType('mark');
  performance.getEntriesByType('measure');
  ```

### Naming convention

All the marks and measures should be instantiated with the constants from
`app/assets/javascripts/performance/constants.js`. When you're ready to add a new mark's or
measurement's label, you can follow the pattern.

NOTE:
This pattern is a recommendation and not a hard rule.

```javascript
app-*-start // for a start 'mark'
app-*-end   // for an end 'mark'
app-*       // for 'measure'
```

For example, `'webide-init-editor-start`, `mr-diffs-mark-file-tree-end`, and so on. We do it to
help identify marks and measures coming from the different apps on the same page.

## Best Practices

### Real-time Components

When writing code for real-time features we have to keep a couple of things in mind:

1. Do not overload the server with requests.
1. It should feel real-time.

Thus, we must strike a balance between sending requests and the feeling of real-time.
Use the following rules when creating real-time solutions.

<!-- vale gitlab_base.Spelling = NO -->

1. The server tells you how much to poll by sending `Poll-Interval` in the header.
   Use that as your polling interval. This enables system administrators to change the
   [polling rate](../../administration/polling.md).
   A `Poll-Interval: -1` means you should disable polling, and this must be implemented.
1. A response with HTTP status different from 2XX should disable polling as well.
1. Use a common library for polling.
1. Poll on active tabs only. Use [Visibility](https://github.com/ai/visibilityjs).
1. Use regular polling intervals, do not use backoff polling or jitter, as the interval is
   controlled by the server.
1. The backend code is likely to be using ETags. You do not and should not check for status
   `304 Not Modified`. The browser transforms it for you.

<!-- vale gitlab_base.Spelling = YES -->

### Lazy Loading Images

To improve the time to first render we are using lazy loading for images. This works by setting
the actual image source on the `data-src` attribute. After the HTML is rendered and JavaScript is loaded,
the value of `data-src` is moved to `src` automatically if the image is in the current viewport.

- Prepare images in HTML for lazy loading by renaming the `src` attribute to `data-src` and adding the class `lazy`.
- If you are using the Rails `image_tag` helper, all images are lazy-loaded by default unless `lazy: false` is provided.

When asynchronously adding content which contains lazy images, call the function
`gl.lazyLoader.searchLazyImages()` which searches for lazy images and loads them if needed.
In general, it should be handled automatically through a `MutationObserver` in the lazy loading function.

### Animations

Only animate `opacity` & `transform` properties. Other properties (such as `top`, `left`, `margin`, and `padding`) all cause
Layout to be recalculated, which is much more expensive. For details on this, see
[High Performance Animations](https://web.dev/articles/animations-guide).

If you _do_ need to change layout (for example, a sidebar that pushes main content over), prefer [FLIP](https://aerotwist.com/blog/flip-your-animations/). FLIP allows you to change expensive
properties once, and handle the actual animation with transforms.

### Prefetching assets

In addition to prefetching data from the [API](graphql.md#making-initial-queries-early-with-graphql-startup-calls)
we allow prefetching the named JavaScript "chunks" as
[defined in the Webpack configuration](https://gitlab.com/gitlab-org/gitlab/-/blob/master/config/webpack.config.js#L298-359).
We support two types of prefetching for the chunks:

- The [`prefetch` link type](https://developer.mozilla.org/en-US/docs/Web/HTML/Attributes/rel/prefetch)
  is used to prefetch a chunk for the future navigation
- The [`preload` link type](https://developer.mozilla.org/en-US/docs/Web/HTML/Attributes/rel/preload)
  is used to prefetch a chunk that is crucial for the current navigation but is not
  discovered until later in the rendering process

Both `prefetch` and `preload` links bring the loading performance benefit to the pages. Both are
fetched asynchronously, but contrary to [deferring the loading](https://developer.mozilla.org/en-US/docs/Web/HTML/Element/script#attr-defer)
of the assets which is used for other JavaScript resources in the product by default, `prefetch` and
`preload` neither parse nor execute the fetched script unless explicitly imported in any JavaScript
module. This allows to cache the fetched resources without blocking the execution of the
remaining page resources.

To prefetch a JavaScript chunk in a HAML view, `:prefetch_asset_tags` with the combination of
the `webpack_preload_asset_tag` helper is provided:

```javascript
- content_for :prefetch_asset_tags do
  - webpack_preload_asset_tag('monaco')
```

This snippet will add a new `<link rel="preload">` element into the resulting HTML page:

```HTML
<link rel="preload" href="/assets/webpack/monaco.chunk.js" as="script" type="text/javascript">
```

By default, `webpack_preload_asset_tag` will `preload` the chunk. You don't need to worry about
`as` and `type` attributes for preloading the JavaScript chunks. However, when a chunk is not
critical, for the current navigation, one has to explicitly request `prefetch`:

```javascript
- content_for :prefetch_asset_tags do
  - webpack_preload_asset_tag('monaco', prefetch: true)
```

This snippet will add a new `<link rel="prefetch">` element into the resulting HTML page:

```HTML
<link rel="prefetch" href="/assets/webpack/monaco.chunk.js">
```

## Reducing Asset Footprint

### Universal code

Code that is contained in `main.js` and `commons/index.js` is loaded and
run on _all_ pages. **Do not add** anything to these files unless it is truly
needed _everywhere_. These bundles include ubiquitous libraries like `vue`,
`axios`, and `jQuery`, as well as code for the main navigation and sidebar.
Where possible we should aim to remove modules from these bundles to reduce our
code footprint.

### Page-specific JavaScript

Webpack has been configured to automatically generate entry point bundles based
on the file structure in `app/assets/javascripts/pages/*`. The directories
in the `pages` directory correspond to Rails controllers and actions. These
auto-generated bundles are automatically included on the corresponding
pages.

For example, if you were to visit <https://gitlab.com/gitlab-org/gitlab/-/issues>,
you would be accessing the `app/controllers/projects/issues_controller.rb`
controller with the `index` action. If a corresponding file exists at
`pages/projects/issues/index/index.js`, it is compiled into a webpack
bundle and included on the page.

Previously, GitLab encouraged the use of
`content_for :page_specific_javascripts` in HAML files, along with
manually generated webpack bundles. However under this new system you should
not ever need to manually add an entry point to the `webpack.config.js` file.

NOTE:
When unsure what controller and action corresponds to a page,
inspect `document.body.dataset.page` in your
browser's developer console from any page in GitLab.

TROUBLESHOOTING:
If using Vite, keep in mind that support for it is new and you may encounter unexpected effects from time to
time. If the entrypoint is correctly configured but the JavaScript is not loading,
try clearing the Vite cache and restarting the service:
`rm -rf tmp/cache/vite && gdk restart vite`

Alternatively, you can opt to use Webpack instead. Follow these [instructions for disabling Vite and using Webpack](https://gitlab.com/gitlab-org/gitlab-development-kit/-/blob/main/doc/configuration.md#vite-settings).

#### Important Considerations

- **Keep Entry Points Lite:**
  Page-specific JavaScript entry points should be as lite as possible. These
  files are exempt from unit tests, and should be used primarily for
  instantiation and dependency injection of classes and methods that live in
  modules outside of the entry point script. Just import, read the DOM,
  instantiate, and nothing else.

- **`DOMContentLoaded` should not be used:**
  All GitLab JavaScript files are added with the `defer` attribute.
  According to the [Mozilla documentation](https://developer.mozilla.org/en-US/docs/Web/HTML/Element/script#attr-defer),
  this implies that "the script is meant to be executed after the document has
  been parsed, but before firing `DOMContentLoaded`". Because the document is already
  parsed, `DOMContentLoaded` is not needed to bootstrap applications because all
  the DOM nodes are already at our disposal.

- **Supporting Module Placement:**
  - If a class or a module is _specific to a particular route_, try to locate
    it close to the entry point in which it is used. For instance, if
    `my_widget.js` is only imported in `pages/widget/show/index.js`, you
    should place the module at `pages/widget/show/my_widget.js` and import it
    with a relative path (for example, `import initMyWidget from './my_widget';`).
  - If a class or module is _used by multiple routes_, place it in a
    shared directory at the closest common parent directory for the entry
    points that import it. For example, if `my_widget.js` is imported in
    both `pages/widget/show/index.js` and `pages/widget/run/index.js`, then
    place the module at `pages/widget/shared/my_widget.js` and import it with
    a relative path if possible (for example, `../shared/my_widget`).

- **Enterprise Edition Caveats:**
  For GitLab Enterprise Edition, page-specific entry points override their
  Community Edition counterparts with the same name, so if
  `ee/app/assets/javascripts/pages/foo/bar/index.js` exists, it takes
  precedence over `app/assets/javascripts/pages/foo/bar/index.js`. If you want
  to minimize duplicate code, you can import one entry point from the other.
  This is not done automatically to allow for flexibility in overriding
  functionality.

### Code Splitting

Code that does not need to be run immediately upon page load (for example,
modals, dropdowns, and other behaviors that can be lazy-loaded) should be split
into asynchronous chunks with dynamic import statements. These
imports return a Promise which is resolved after the script has loaded:

```javascript
import(/* webpackChunkName: 'emoji' */ '~/emoji')
  .then(/* do something */)
  .catch(/* report error */)
```

Use `webpackChunkName` when generating dynamic imports as
it provides a deterministic filename for the chunk which can then be cached
in the browser across GitLab versions.

More information is available in the [webpack code splitting documentation](https://webpack.js.org/guides/code-splitting/#dynamic-imports) and the [Vue dynamic component documentation](https://v2.vuejs.org/v2/guide/components-dynamic-async.html).

### Minimizing page size

A smaller page size means the page loads faster, especially on mobile
and poor connections. The page is parsed more quickly by the browser, and less
data is used for users with capped data plans.

General tips:

- Don't add new fonts.
- Prefer font formats with better compression, for example, WOFF2 is better than WOFF, which is better than TTF.
- Compress and minify assets wherever possible (For CSS/JS, Sprockets and webpack do this for us).
- If some functionality can reasonably be achieved without adding extra libraries, avoid them.
- Use page-specific JavaScript as described above to load libraries that are only needed on certain pages.
- Use code-splitting dynamic imports wherever possible to lazy-load code that is not needed initially.
- [High Performance Animations](https://web.dev/articles/animations-guide)

---

## Additional Resources

- [WebPage Test](https://www.webpagetest.org) for testing site loading time and size.
- [Google PageSpeed Insights](https://pagespeed.web.dev/) grades web pages and provides feedback to improve the page.
- [Profiling with Chrome DevTools](https://developer.chrome.com/docs/devtools/)
- [Browser Diet](https://github.com/zenorocha/browser-diet) was a community-built guide that cataloged practical tips for improving web page performance.
