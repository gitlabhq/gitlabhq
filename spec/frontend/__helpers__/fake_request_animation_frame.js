export const useFakeRequestAnimationFrame = () => {
  let orig;

  beforeEach(() => {
    orig = global.requestAnimationFrame;
    global.requestAnimationFrame = (cb) => cb();
  });

  afterEach(() => {
    global.requestAnimationFrame = orig;
  });
};
