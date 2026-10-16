import { glowCell } from '~/easter_eggs/contribution_music/shimmer';

describe('glowCell', () => {
  let element;

  const glow = (options = {}) =>
    glowCell(element, {
      level: 2,
      color: '#fb8017',
      columnMs: 100,
      step: 20,
      reducedMotion: false,
      ...options,
    });

  const keyframes = () => element.animate.mock.calls[0][0];

  beforeEach(() => {
    element = document.createElement('button');
    element.animate = jest.fn();
    element.getBoundingClientRect = () => ({ width: 17.6 });
  });

  describe('with motion', () => {
    beforeEach(() => glow());

    // Calendar cells are buttons with a border their own color fills.
    it('covers the border, like the cell color does', () => {
      keyframes().forEach((keyframe) => expect(keyframe.backgroundOrigin).toBe('border-box'));
    });

    it('sweeps the cell at its unrounded width', () => {
      const [, end] = keyframes();

      expect(end.backgroundPosition).toBe('17.6px 0, 0 0');
      expect(end.backgroundSize).toBe('40px 100%, 57.6px 100%');
    });
  });

  describe('with reduced motion', () => {
    beforeEach(() => glow({ reducedMotion: true }));

    it('fades the cell into its color', () => {
      expect(keyframes().at(-1)).toEqual({ backgroundColor: '#fb8017' });
    });
  });
});
