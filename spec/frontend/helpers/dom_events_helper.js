// eslint-disable-next-line import/prefer-default-export
export const triggerDOMEvent = type => {
  window.document.dispatchEvent(
    new Event(type, {
      bubbles: true,
      cancelable: true,
    }),
  );
};
