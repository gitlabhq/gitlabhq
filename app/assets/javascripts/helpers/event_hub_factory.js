import mitt from 'mitt';

export default () => {
  const emitter = mitt();

  emitter.once = (event, handler) => {
    const wrappedHandler = evt => {
      handler(evt);
      emitter.off(event, wrappedHandler);
    };
    emitter.on(event, wrappedHandler);
  };

  emitter.$on = emitter.on;
  emitter.$once = emitter.once;
  emitter.$off = emitter.off;
  emitter.$emit = emitter.emit;

  return emitter;
};
