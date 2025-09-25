import initAmbiguousRefModal from '~/ref/init_ambiguous_ref_modal';
import { setHTMLFixture } from 'helpers/fixtures';
import setWindowLocation from 'helpers/set_window_location_helper';

const generateFixture = (isAmbiguous) => {
  return `<div id="js-ambiguous-ref-modal" data-ambiguous="${isAmbiguous}" data-ref="main"></div>`;
};

let modal;

const init = ({ isAmbiguous, htmlFixture = generateFixture(isAmbiguous) }) => {
  setHTMLFixture(htmlFixture);
  modal = initAmbiguousRefModal();
};

describe('initAmbiguousRefModal', () => {
  it('inits a new AmbiguousRefModal Vue component', () => {
    init({ isAmbiguous: true });

    expect(Boolean(modal)).toBe(true);
  });

  it.each(['<div></div>', '', null])(
    'does not render a new AmbiguousRefModal Vue component when root element is %s',
    (htmlFixture) => {
      init({ isAmbiguous: true, htmlFixture });

      expect(Boolean(modal)).toBe(false);
    },
  );

  it('does not render a new AmbiguousRefModal Vue component "ambiguous" data attribute is "false"', () => {
    init({ isAmbiguous: false });

    expect(Boolean(modal)).toBe(false);
  });

  it.each(['tags', 'heads'])(
    'does not render a new AmbiguousRefModal Vue component when "ref_type" param is set to %s',
    (refType) => {
      setWindowLocation(`?ref_type=${refType}`);
      init({ isAmbiguous: true });

      expect(Boolean(modal)).toBe(false);
    },
  );
});
