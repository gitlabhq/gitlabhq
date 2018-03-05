# Performance

## Lazy loading

Lazy loading is a method we use to improve the time to first render. This feature is built into GitLab.

```
// no lazy loading
<image src="gitlab.png">

// lazy loading
<image class="lazy" data-src="gitlab.png">
```

Asnchronously loaded content containing lazy loaded images need to instantiate `LazyLoader` and call `searchLazyImages()`.

> Note: The Rails `image_tag` helper will add lazy-loading by default unless `lazy: false` is explicitly provided.

## Online resources

- [WebPage Test][web-page-test] for testing site loading time and size.
- [Google PageSpeed Insights][pagespeed-insights] grades web pages and provides feedback to improve the page.
- [Profiling with Chrome DevTools][google-devtools-profiling]
- [Browser Diet][browser-diet] is a community-built guide that catalogues practical tips for improving web page performance.
- [High Performance Animations][high-performance-animations]

[web-page-test]: http://www.webpagetest.org/
[pagespeed-insights]: https://developers.google.com/speed/pagespeed/insights/
[google-devtools-profiling]: https://developers.google.com/web/tools/chrome-devtools/profile/?hl=en
[browser-diet]: https://browserdiet.com/
[high-performance-animations]: https://www.html5rocks.com/en/tutorials/speed/high-performance-animations/
