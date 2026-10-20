import { throttle } from 'lodash-es';

const isSafari = () => /^((?!chrome|android).)*safari/i.test(navigator.userAgent);

const isWrongDocumentError = (event) =>
  event.error?.name === 'NotSupportedError' && /belongs to a wrong document/.test(event.message);

// Safari doesn't consider custom elements as Web Components when streaming ¯\_(ツ)_/¯
export const fixWebComponentsStreamingOnSafari = (elementToObserve) => {
  if (!isSafari()) return () => {};

  // Safari 27 reports this for every streamed custom element; harmless since we upgrade them below.
  // Capture phase runs before window.onerror, which keeps it out of Sentry.
  // Created per call so an aborted stream's cleanup can't remove a newer stream's listener.
  const suppressWrongDocumentError = (event) => {
    if (!isWrongDocumentError(event)) return;
    event.preventDefault();
    event.stopImmediatePropagation();
  };
  window.addEventListener('error', suppressWrongDocumentError, true);

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

  return () => {
    observer.disconnect();
    window.removeEventListener('error', suppressWrongDocumentError, true);
  };
};
