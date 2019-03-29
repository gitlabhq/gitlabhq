export default (domElement, attributes, timeout = 1500) =>
  new Promise((resolve, reject) => {
    let observer;
    const timeoutId = setTimeout(() => {
      observer.disconnect();
      reject(new Error(`Could not see an attribute update within ${timeout} ms`));
    }, timeout);

    observer = new MutationObserver(() => {
      clearTimeout(timeoutId);
      observer.disconnect();
      resolve();
    });

    observer.observe(domElement, { attributes: true, attributeFilter: attributes });
  });
