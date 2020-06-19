import mitt from 'mitt';

export default () => {
  const emitter = mitt();

  const originalEmit = emitter.emit;

  emitter.once = (event, handler) => {
    const wrappedHandler = evt => {
      handler(evt);
      emitter.off(event, wrappedHandler);
    };
    emitter.on(event, wrappedHandler);
  };

  emitter.emit = (event, args = []) => {
    originalEmit(event, args);
  };

  emitter.$on = emitter.on;
  emitter.$once = emitter.once;
  emitter.$off = emitter.off;
  emitter.$emit = emitter.emit;

  return emitter;
};
