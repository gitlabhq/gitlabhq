import { RenderBalancer } from '~/streaming/render_balancer';

const HIGH_FRAME_TIME = 100;
const LOW_FRAME_TIME = 10;

describe('renderBalancer', () => {
  let frameTime = 0;
  let frameTimeDelta = 0;
  let decrease;
  let increase;

  const createBalancer = () => {
    decrease = jest.fn();
    increase = jest.fn();
    return new RenderBalancer({
      highFrameTime: HIGH_FRAME_TIME,
      lowFrameTime: LOW_FRAME_TIME,
      increase,
      decrease,
    });
  };

  const renderTimes = (times) => {
    const balancer = createBalancer();
    return new Promise((resolve) => {
      let counter = 0;
      balancer.render(() => {
        if (counter === times) {
          resolve(counter);
          return false;
        }
        counter += 1;
        return true;
      });
    });
  };

  beforeEach(() => {
    jest.spyOn(window, 'requestAnimationFrame').mockImplementation((cb) => {
      frameTime += frameTimeDelta;
      cb(frameTime);
    });
  });

  afterEach(() => {
    window.requestAnimationFrame.mockRestore();
    frameTime = 0;
    frameTimeDelta = 0;
  });

  it('renders in a loop', async () => {
    const count = await renderTimes(5);
    expect(count).toBe(5);
  });

  it('calls decrease', async () => {
    frameTimeDelta = 200;
    await renderTimes(5);
    expect(decrease).toHaveBeenCalled();
    expect(increase).not.toHaveBeenCalled();
  });

  it('calls increase', async () => {
    frameTimeDelta = 1;
    await renderTimes(5);
    expect(increase).toHaveBeenCalled();
    expect(decrease).not.toHaveBeenCalled();
  });
});
