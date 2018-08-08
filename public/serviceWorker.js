/* global self */

self.addEventListener('install', event => { // eslint-disable-line no-restricted-globals
  event.waitUntil(
    caches.open('gl-offline')
      .then(cache => cache.addAll([
        '/offline.html',
      ])),
  );
});

self.addEventListener('fetch', event => { // eslint-disable-line no-restricted-globals
  const { request } = event;

  event.respondWith(
    caches.match(request)
      .then(response => response || fetch(request))
      .catch(() => (request.mode === 'navigate' ? caches.match('/offline.html') : null)),
  );
});
