export default function scrollIntoViewPromise(intersectionTarget, timeout = 100, maxTries = 5) {
  return new Promise((resolve, reject) => {
    let intersectionObserver;
    let retry = 0;

    const intervalId = setInterval(() => {
      if (retry >= maxTries) {
        intersectionObserver.disconnect();
        clearInterval(intervalId);
        reject(new Error(`Could not scroll target into viewPort within ${timeout * maxTries} ms`));
      }
      retry += 1;
      intersectionTarget.scrollIntoView();
    }, timeout);

    intersectionObserver = new IntersectionObserver(entries => {
      if (entries[0].isIntersecting) {
        intersectionObserver.disconnect();
        clearInterval(intervalId);
        resolve();
      }
    });

    intersectionObserver.observe(intersectionTarget);

    intersectionTarget.scrollIntoView();
  });
}
