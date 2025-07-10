import { escape } from 'lodash';
import { setHTMLFixture, resetHTMLFixture } from 'helpers/fixtures';
import initVuePopovers from '~/vue_popovers';

describe('VuePopovers', () => {
  const popovers = [
    {
      target: 'popover-1',
      title: 'Setting locked',
      content: 'This setting is disabled',
    },
    {
      target: 'popover-2',
      title: 'Test popover',
      content: 'Content about this',
    },
  ];

  beforeEach(() => {
    setHTMLFixture(
      popovers
        .map(
          (x) =>
            `<div><div class="js-vue-popover" data-app-data="${escape(
              JSON.stringify(x),
            )}"</div></div>`,
        )
        .join('\n'),
    );
  });

  afterEach(() => {
    resetHTMLFixture();
  });

  const findJsHooks = () => document.querySelectorAll('.js-vue-popover');
  const findPopovers = () => document.querySelectorAll('.gl-popover');

  const serializePopover = (popover) => ({
    target: popover.getAttribute('target'),
    title: popover.getAttribute('title'),
    content: popover.getAttribute('content'),
  });

  it('starts with only JsHooks', () => {
    expect(findJsHooks()).toHaveLength(popovers.length);
    expect(findPopovers()).toHaveLength(0);
  });

  describe('when mounted', () => {
    beforeEach(() => {
      initVuePopovers();
    });

    it('replaces JsHook with Popovers and triggers', () => {
      expect(findJsHooks()).toHaveLength(0);
      expect(findPopovers()).toHaveLength(popovers.length);
    });

    it('passes along props to gl-popover', () => {
      const actual = [...findPopovers()].map(serializePopover);

      expect(actual).toEqual(popovers);
    });
  });
});
