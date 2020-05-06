import mitt from 'mitt';

export default () => {
  const emitter = mitt();

  emitter.$on = emitter.on;
  emitter.$off = emitter.off;
  emitter.$emit = emitter.emit;

  return emitter;
};
