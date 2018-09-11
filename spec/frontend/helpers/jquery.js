import $ from 'jquery';

const spyOnEvent = (selector, eventName, tearDownHook = afterEach) => {
  const handler = jest.fn().mockName(`spyOnEvent(${selector}, ${eventName})`);
  $(selector).on(eventName, handler);

  tearDownHook(() => {
    $(selector).off(eventName, handler);
  });

  return handler;
};

export default spyOnEvent;
