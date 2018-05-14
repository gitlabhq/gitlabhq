# Performance

## Best Practices

### Realtime Components

When writing code for realtime features we have to keep a couple of things in mind:
1. Do not overload the server with requests.
1. It should feel realtime.

Thus, we must strike a balance between sending requests and the feeling of realtime.
Use the following rules when creating realtime solutions.

1. The server will tell you how much to poll by sending `Poll-Interval` in the header.
Use that as your polling interval. This way it is [easy for system administrators to change the
polling rate](../../administration/polling.md).
A `Poll-Interval: -1` means you should disable polling, and this must be implemented.
1. A response with HTTP status `4XX` or `5XX` should disable polling as well.
1. Use a common library for polling.
1. Poll on active tabs only. Please use [Visibility](https://github.com/ai/visibilityjs).
1. Use regular polling intervals, do not use backoff polling, or jitter, as the interval will be
controlled by the server.
1. The backend code will most likely be using etags. You do not and should not check for status
`304 Not Modified`. The browser will transform it for you.

### Lazy Loading Images

To improve the time to first render we are using lazy loading for images. This works by setting 
the actual image source on the `data-src` attribute. After the HTML is rendered and JavaScript is loaded, 
the value of `data-src` will be moved to `src` automatically if the image is in the current viewport.

*  Prepare images in HTML for lazy loading by renaming the `src` attribute to `data-src` AND adding the class `lazy`
*  If you are using the Rails `image_tag` helper, all images will be lazy-loaded by default unless `lazy: false` is provided.

If you are asynchronously adding content which contains lazy images then you need to call the function
`gl.lazyLoader.searchLazyImages()` which will search for lazy images and load them if needed. 
But in general it should be handled automatically through a `MutationObserver` in the lazy loading function.

### Animations

Only animate `opacity` & `transform` properties. Other properties (such as `top`, `left`, `margin`, and `padding`) all cause
Layout to be recalculated, which is much more expensive. For details on this, see "Styles that Affect Layout" in
[High Performance Animations][high-perf-animations].

If you _do_ need to change layout (e.g. a sidebar that pushes main content over), prefer [FLIP][flip] to change expensive
properties once, and handle the actual animation with transforms.

## Reducing Asset Footprint

### Universal code

Code that is contained within `main.js` and `commons/index.js` are loaded and
run on _all_ pages. **DO NOT ADD** anything to these files unless it is truly
needed _everywhere_. These bundles include ubiquitous libraries like `vue`,
`axios`, and `jQuery`, as well as code for the main navigation and sidebar.
Where possible we should aim to remove modules from these bundles to reduce our
code footprint.

### Page-specific JavaScript

Webpack has been configured to automatically generate entry point bundles based
on the file structure within `app/assets/javascripts/pages/*`. The directories
within the `pages` directory correspond to Rails controllers and actions. These
auto-generated bundles will be automatically included on the corresponding
pages.

For example, if you were to visit [gitlab.com/gitlab-org/gitlab-ce/issues](https://gitlab.com/gitlab-org/gitlab-ce/issues),
you would be accessing the `app/controllers/projects/issues_controller.rb`
controller with the `index` action. If a corresponding file exists at
`pages/projects/issues/index/index.js`, it will be compiled into a webpack
bundle and included on the page.

> **Note:** Previously we had encouraged the use of
> `content_for :page_specific_javascripts` within haml files, along with
> manually generated webpack bundles. However under this new system you should
> not ever need to manually add an entry point to the `webpack.config.js` file.

> **Tip:**
> If you are unsure what controller and action corresponds to a given page, you
> can find this out by inspecting `document.body.dataset.page` within your
> browser's developer console while on any page within gitlab.

#### Important Considerations:

- **Keep Entry Points Lite:**
  Page-specific javascript entry points should be as lite as possible.  These
  files are exempt from unit tests, and should be used primarily for
  instantiation and dependency injection of classes and methods that live in
  modules outside of the entry point script.  Just import, read the DOM,
  instantiate, and nothing else.

- **Entry Points May Be Asynchronous:**
  _DO NOT ASSUME_ that the DOM has been fully loaded and available when an
  entry point script is run.  If you require that some code be run after the
  DOM has loaded, you should attach an event handler to the `DOMContentLoaded`
  event with:

    ```javascript
    import initMyWidget from './my_widget';
  
    document.addEventListener('DOMContentLoaded', () => {
      initMyWidget();
    });
    ```

- **Supporting Module Placement:**  
    - If a class or a module is _specific to a particular route_, try to locate
      it close to the entry point it will be used. For instance, if
      `my_widget.js` is only imported within `pages/widget/show/index.js`, you
      should place the module at `pages/widget/show/my_widget.js` and import it
      with a relative path (e.g. `import initMyWidget from './my_widget';`).
      
    - If a class or module is _used by multiple routes_, place it within a
      shared directory at the closest common parent directory for the entry
      points that import it.  For example, if `my_widget.js` is imported within
      both `pages/widget/show/index.js` and `pages/widget/run/index.js`, then
      place the module at `pages/widget/shared/my_widget.js` and import it with
      a relative path if possible (e.g. `../shared/my_widget`).

- **Enterprise Edition Caveats:**
  For GitLab Enterprise Edition, page-specific entry points will override their
  Community Edition counterparts with the same name, so if
  `ee/app/assets/javascripts/pages/foo/bar/index.js` exists, it will take
  precedence over `app/assets/javascripts/pages/foo/bar/index.js`.  If you want
  to minimize duplicate code, you can import one entry point from the other.
  This is not done automatically to allow for flexibility in overriding
  functionality.

### Code Splitting

For any code that does not need to be run immediately upon page load, (e.g.
modals, dropdowns, and other behaviors that can be lazy-loaded), you can split
your module into asynchronous chunks with dynamic import statements.  These
imports return a Promise which will be resolved once the script has loaded:

```javascript
import(/* webpackChunkName: 'emoji' */ '~/emoji')
  .then(/* do something */)
  .catch(/* report error */)
```

Please try to use `webpackChunkName` when generating these dynamic imports as
it will provide a deterministic filename for the chunk which can then be cached
the browser across GitLab versions.

More information is available in [webpack's code splitting documentation](https://webpack.js.org/guides/code-splitting/#dynamic-imports).

### Minimizing page size

A smaller page size means the page loads faster (especially important on mobile
and poor connections), the page is parsed more quickly by the browser, and less
data is used for users with capped data plans.

General tips:

- Don't add new fonts.
- Prefer font formats with better compression, e.g. WOFF2 is better than WOFF, which is better than TTF.
- Compress and minify assets wherever possible (For CSS/JS, Sprockets and webpack do this for us).
- If some functionality can reasonably be achieved without adding extra libraries, avoid them.
- Use page-specific JavaScript as described above to load libraries that are only needed on certain pages.
- Use code-splitting dynamic imports wherever possible to lazy-load code that is not needed initially.
- [High Performance Animations][high-perf-animations]

-------

## Additional Resources

- [WebPage Test][web-page-test] for testing site loading time and size.
- [Google PageSpeed Insights][pagespeed-insights] grades web pages and provides feedback to improve the page.
- [Profiling with Chrome DevTools][google-devtools-profiling]
- [Browser Diet][browser-diet] is a community-built guide that catalogues practical tips for improving web page performance.


[web-page-test]: http://www.webpagetest.org/
[pagespeed-insights]: https://developers.google.com/speed/pagespeed/insights/
[google-devtools-profiling]: https://developers.google.com/web/tools/chrome-devtools/profile/?hl=en
[browser-diet]: https://browserdiet.com/
[high-perf-animations]: https://www.html5rocks.com/en/tutorials/speed/high-performance-animations/
[flip]: https://aerotwist.com/blog/flip-your-animations/
