import { createPlayer } from '~/easter_eggs/contribution_music/synth';

// jsdom has no Web Audio, so the player is driven against a fake context
// whose clock this spec advances by hand.
const createFakeAudioContext = () => {
  const node = () => ({
    connect: jest.fn((target) => {
      return target;
    }),
    frequency: { value: 0 },
    detune: { value: 0 },
    delayTime: { value: 0 },
    Q: { value: 0 },
    gain: {
      value: 1,
      setValueAtTime: jest.fn(),
      linearRampToValueAtTime: jest.fn(),
      exponentialRampToValueAtTime: jest.fn(),
      cancelScheduledValues: jest.fn(),
    },
    start: jest.fn(),
    stop: jest.fn(),
    disconnect: jest.fn(),
    type: '',
    frequencyBinCount: 128,
  });

  return {
    currentTime: 0,
    destination: {},
    resume: jest.fn().mockResolvedValue(undefined),
    close: jest.fn(),
    createOscillator: node,
    createBiquadFilter: node,
    createGain: node,
    createWaveShaper: node,
    createDelay: node,
    createAnalyser: node,
  };
};

describe('contribution music player', () => {
  let context;
  let onColumn;
  let player;
  let frameCallbacks;

  const columns = [[], [], [], []].map(() => [
    { frequency: 440, voice: { wave: 'sine', cutoff: 1000, gain: 0.5, attack: 0.01, decay: 0.2 } },
  ]);

  // Run one animation frame and one scheduler tick at the current clock.
  const advance = (seconds) => {
    context.currentTime += seconds;
    jest.advanceTimersByTime(seconds * 1000);
    const pending = frameCallbacks;
    frameCallbacks = [];
    pending.forEach((cb) => cb());
  };

  beforeEach(() => {
    jest.useFakeTimers();
    frameCallbacks = [];
    jest.spyOn(window, 'requestAnimationFrame').mockImplementation((cb) => {
      frameCallbacks.push(cb);
      return frameCallbacks.length;
    });
    jest.spyOn(window, 'cancelAnimationFrame').mockImplementation(() => {});

    context = createFakeAudioContext();
    window.AudioContext = jest.fn(() => context);

    onColumn = jest.fn();
    player = createPlayer({ onColumn, onPosition: () => {}, onEnd: () => {} });
  });

  afterEach(() => {
    jest.useRealTimers();
  });

  const start = async () => {
    await player.start({ columns, columnsPerSecond: 10, loop: true });
  };

  it('reports the sounding column', async () => {
    await start();
    advance(0.2);

    expect(onColumn).toHaveBeenCalled();
  });

  it('stops reporting columns once stopped', async () => {
    await start();
    advance(0.2);
    player.stop();
    onColumn.mockClear();

    advance(0.5);

    expect(onColumn).not.toHaveBeenCalled();
  });

  it('stops reporting columns after a restart, with no run left orphaned', async () => {
    await start();
    advance(0.2);
    // What the speed/scale/key watchers do: start again without stopping.
    await start();
    advance(0.2);
    player.stop();
    onColumn.mockClear();

    advance(0.5);

    expect(onColumn).not.toHaveBeenCalled();
  });
});
