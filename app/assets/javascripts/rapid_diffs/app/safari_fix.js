import { throttle } from 'lodash';

// Safari doesn't consider custom elements as Web Components when streaming ¯\_(ツ)_/¯
export const fixWebComponentsStreamingOnSafari = (elementToObserve, DiffFileImplementation) => {
  const isSafari = /^((?!chrome|android).)*safari/i.test(navigator.userAgent);
  if (!isSafari) return;
  const observer = new MutationObserver(
    throttle(
      () => {
        document.querySelectorAll('diff-file-mounted:not([mounted])').forEach((diffFileMounted) => {
          diffFileMounted.setAttribute('mounted', 'true');
          const diffFile = diffFileMounted.parentElement;
          if (diffFile instanceof DiffFileImplementation) return;
          Object.setPrototypeOf(diffFile, DiffFileImplementation.prototype);
          Object.assign(diffFile, new DiffFileImplementation(diffFile));
          diffFile.mount();
        });
      },
      200,
      { trailing: true },
    ),
  );
  observer.observe(elementToObserve, {
    attributes: false,
    childList: true,
    subtree: true,
  });
};
