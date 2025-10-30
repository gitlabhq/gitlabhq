import { GlPopover } from '@gitlab/ui';
import { createWrapper } from '@vue/test-utils';
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
            `<div><div class="js-vue-popover" data-app-data="${escape(JSON.stringify(x))}"></div></div>`,
        )
        .join('\n'),
    );
  });

  afterEach(() => {
    resetHTMLFixture();
  });

  const findJsHooks = () => document.querySelectorAll('.js-vue-popover');

  const serializePopover = (popoverWrapper) => ({
    title: popoverWrapper.props('title'),
    target: popoverWrapper.props('target'),
    content: popoverWrapper.props('content'),
  });

  it('starts with only JsHooks', () => {
    expect(findJsHooks()).toHaveLength(popovers.length);
  });

  describe('when mounted', () => {
    let popoverWrappers;

    beforeEach(() => {
      const popoverInstances = initVuePopovers();
      popoverWrappers = popoverInstances.map((instance) =>
        createWrapper(instance).findComponent(GlPopover),
      );
    });

    afterEach(() => {
      popoverWrappers = undefined;
    });

    it('replaces JsHook with Popovers and triggers', () => {
      expect(findJsHooks()).toHaveLength(0);
      expect(popoverWrappers).toHaveLength(popovers.length);
    });

    it('passes along props to gl-popover', () => {
      const actual = popoverWrappers.map(serializePopover);

      expect(actual).toEqual(popovers);
    });
  });
});
