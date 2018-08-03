self.addEventListener('install', event => {
  event.waitUntil(
    // TODO: Add useful, cacheable pages in here
    caches.open('gl-offline')
      .then(cache => cache.addAll([
        '/offline.html',
      ]))
  );
});

self.addEventListener('fetch', event => {
  const request = event.request;

  event.respondWith(
    caches.match(event.request)
      .then(response => response || fetch(event.request))
      .catch(() => {
        if (event.request.mode === 'navigate') {
          return caches.match('/offline.html');
        }
      })
  );
});