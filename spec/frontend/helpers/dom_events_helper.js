export const triggerDOMEvent = type => {
  window.document.dispatchEvent(
    new Event(type, {
      bubbles: true,
      cancelable: true,
    }),
  );
};

export default () => {};
