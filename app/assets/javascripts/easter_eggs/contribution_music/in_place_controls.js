import { prefersReducedMotion } from './visualizer';
import { brandColors } from './utils';
import { BRAND_FADE_MS, BRAND_HOLD_MS, I18N } from './constants';

// The play and open buttons both profile calendars put beside their legend, so the song plays
// on the calendar itself. Each is styled as one more square of the legend. The caller wires up
// the play button, since what it toggles depends on the calendar.
const SVG_NS = 'http://www.w3.org/2000/svg';
const OPEN_PULSE_MS = 6000;

export const svgElement = (name, attributes = {}) => {
  const element = document.createElementNS(SVG_NS, name);

  Object.entries(attributes).forEach(([key, value]) => element.setAttribute(key, value));

  return element;
};

const createButton = ({ size, radius, marginLeft, style }) => {
  const button = document.createElement('button');
  const glyph = svgElement('svg', { width: 7, height: 7, viewBox: '0 0 7 7', 'aria-hidden': true });

  button.type = 'button';
  Object.assign(button.style, {
    display: 'inline-flex',
    flexShrink: 0,
    alignItems: 'center',
    justifyContent: 'center',
    width: `${size}px`,
    height: `${size}px`,
    marginLeft: `${marginLeft}px`,
    padding: 0,
    border: 0,
    borderRadius: radius,
    backgroundColor: 'var(--user-contribution-graph-cell-level-0)',
    color: 'var(--gl-text-color-subtle)',
    cursor: 'pointer',
    ...style,
  });
  glyph.style.fill = 'currentColor';
  button.append(glyph);

  return { button, glyph };
};

export const createControls = ({
  anchor,
  size,
  radius = '2px',
  playMargin = 0,
  openMargin = 0,
  style = {},
  onOpen,
}) => {
  const { button, glyph } = createButton({ size, radius, marginLeft: playMargin, style });
  let openButton = null;

  const setPlaying = (isPlaying) => {
    button.setAttribute('aria-label', isPlaying ? I18N.stopInPlace : I18N.playInPlace);
    button.setAttribute('aria-pressed', isPlaying);
    glyph.replaceChildren(
      isPlaying
        ? svgElement('rect', { width: 6, height: 6, x: 0.5, y: 0.5 })
        : svgElement('polygon', { points: '1,0 7,3.5 1,7' }),
    );
  };

  // Once the song has played through, the full player is one step away. The button fades in
  // as the brand colors fade from the calendar, and keeps cycling through them.
  const showOpenButton = () => {
    if (openButton) {
      return;
    }

    const open = createButton({ size, radius, marginLeft: openMargin, style });
    const colors = brandColors().slice(1);
    const [first] = colors;

    openButton = open.button;
    open.glyph.remove();
    openButton.setAttribute('aria-label', I18N.openPlayer);
    openButton.addEventListener('click', onOpen);
    button.after(openButton);
    openButton.animate([{ opacity: 0 }, { opacity: 1 }], {
      duration: BRAND_FADE_MS,
      delay: BRAND_HOLD_MS,
      fill: 'backwards',
    });

    if (prefersReducedMotion()) {
      openButton.style.backgroundColor = first;
    } else {
      openButton.animate(
        [...colors, first].map((backgroundColor) => ({ backgroundColor })),
        { duration: OPEN_PULSE_MS, iterations: Infinity, easing: 'ease-in-out' },
      );
    }
  };

  setPlaying(false);
  anchor.after(button);

  return { button, setPlaying, showOpenButton };
};
