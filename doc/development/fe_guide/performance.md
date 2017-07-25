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

### Lazy Loading

To improve the time to first render we are using lazy loading for images. This works by setting 
the actual image source on the `data-src` attribute. After the HTML is rendered and JavaScript is loaded, 
the value of `data-src` will be moved to `src` automatically if the image is in the current viewport.

*  Prepare images in HTML for lazy loading by renaming the `src` attribute to `data-src`
*  If you are using the Rails `image_tag` helper, all images will be lazy-loaded by default unless `lazy: false` is provided.

If you are asynchronously adding content which contains lazy images then you need to call the function
`gl.lazyLoader.searchLazyImages()` which will search for lazy images and load them if needed.

## Reducing Asset Footprint

### Page-specific JavaScript

Certain pages may require the use of a third party library, such as [d3][d3] for
the User Activity Calendar and [Chart.js][chartjs] for the Graphs pages. These
libraries increase the page size significantly, and impact load times due to
bandwidth bottlenecks and the browser needing to parse more JavaScript.

In cases where libraries are only used on a few specific pages, we use
"page-specific JavaScript" to prevent the main `main.js` file from
becoming unnecessarily large.

Steps to split page-specific JavaScript from the main `main.js`:

1. Create a directory for the specific page(s), e.g. `graphs/`.
1. In that directory, create a `namespace_bundle.js` file, e.g. `graphs_bundle.js`.
1. Add the new "bundle" file to the list of entry files in `config/webpack.config.js`.
  - For example: `graphs: './graphs/graphs_bundle.js',`.
1. Move code reliant on these libraries into the `graphs` directory.
1. In `graphs_bundle.js` add CommonJS `require('./path_to_some_component.js');` statements to load any other files in this directory. Make sure to use relative urls.
1. In the relevant views, add the scripts to the page with the following:

```haml
- content_for :page_specific_javascripts do
  = webpack_bundle_tag 'lib_chart'
  = webpack_bundle_tag 'graphs'
```

The above loads `chart.js` and `graphs_bundle.js` for this page only. `chart.js`
is separated from the bundle file so it can be cached separately from the bundle
and reused for other pages that also rely on the library. For an example, see
[this Haml file][page-specific-js-example].

### Code Splitting

> *TODO* flesh out this section once webpack is ready for code-splitting

### Minimizing page size

A smaller page size means the page loads faster (especially important on mobile
and poor connections), the page is parsed more quickly by the browser, and less
data is used for users with capped data plans.

General tips:

- Don't add new fonts.
- Prefer font formats with better compression, e.g. WOFF2 is better than WOFF, which is better than TTF.
- Compress and minify assets wherever possible (For CSS/JS, Sprockets and webpack do this for us).
- If some functionality can reasonably be achieved without adding extra libraries, avoid them.
- Use page-specific JavaScript as described above to dynamically load libraries that are only needed on certain pages.

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
[d3]: https://d3js.org/
[chartjs]: http://www.chartjs.org/
[page-specific-js-example]: https://gitlab.com/gitlab-org/gitlab-ce/blob/13bb9ed77f405c5f6ee4fdbc964ecf635c9a223f/app/views/projects/graphs/_head.html.haml#L6-8
