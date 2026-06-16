import { throttle } from 'lodash-es';

const isSafari = () => /^((?!chrome|android).)*safari/i.test(navigator.userAgent);

// Safari doesn't consider custom elements as Web Components when streaming ¯\_(ツ)_/¯
export const fixWebComponentsStreamingOnSafari = (elementToObserve) => {
  if (!isSafari()) return () => {};

  const DiffFile = customElements.get('diff-file');
  const DiffFileMounted = customElements.get('diff-file-mounted');
  const observer = new MutationObserver(
    throttle(
      () => {
        document.querySelectorAll('diff-file-mounted:not([mounted])').forEach((diffFileMounted) => {
          diffFileMounted.setAttribute('mounted', 'true');
          const diffFile = diffFileMounted.parentElement;
          if (diffFile instanceof DiffFile) return;
          Object.setPrototypeOf(diffFile, DiffFile.prototype);
          Object.setPrototypeOf(diffFileMounted, DiffFileMounted.prototype);
          Object.assign(diffFile, new DiffFile(diffFile));
          diffFileMounted.connectedCallback();
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

  return () => observer.disconnect();
};
