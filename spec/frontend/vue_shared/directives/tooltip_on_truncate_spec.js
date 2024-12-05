import { shallowMount } from '@vue/test-utils';
import { createMockDirective as mockDirective, getBinding } from 'helpers/vue_mock_directive';
import { hasHorizontalOverflow } from '~/lib/utils/dom_utils';

import TooltipOnTruncate from '~/vue_shared/directives/tooltip_on_truncate';

jest.mock('~/lib/utils/dom_utils');
jest.mock('@gitlab/ui', () => ({
  ...jest.requireActual('@gitlab/ui'),
  GlTooltipDirective: mockDirective('gl-tooltip'),
  GlResizeObserverDirective: mockDirective('gl-resize-observer'),
}));

describe('TooltipOnTruncate directive', () => {
  let wrapper;

  const createWrapper = ({ ...options } = {}) => {
    wrapper = shallowMount({
      directives: {
        TooltipOnTruncate,
      },
      template: `
        <div v-tooltip-on-truncate>
          <strong>An overflowing text</strong>
        </div>`,
      ...options,
    });
  };

  const triggerOverflow = (overflown = true) => {
    hasHorizontalOverflow.mockReturnValue(overflown);
    getBinding(wrapper.element, 'gl-resize-observer').value();
  };

  const getTooltip = () => getBinding(wrapper.element, 'gl-tooltip');

  describe('when the element is truncated', () => {
    beforeEach(() => {
      hasHorizontalOverflow.mockReturnValue(true);

      createWrapper();
    });

    it('shows a tooltip', () => {
      expect(getTooltip().value).toBe('An overflowing text');
    });

    it('unbinds when destroyed', () => {
      wrapper.vm.$destroy();

      expect(getBinding(wrapper.element, 'gl-tooltip')).toBeUndefined();
      expect(getBinding(wrapper.element, 'gl-resize-observer')).toBeUndefined();
    });

    describe('when it resizes to expand', () => {
      beforeEach(() => {
        triggerOverflow(false);
      });

      it('does not show a tooltip', () => {
        expect(getTooltip()).toBeUndefined();
      });
    });
  });

  describe('when the element is not truncated', () => {
    beforeEach(() => {
      hasHorizontalOverflow.mockReturnValue(false);

      createWrapper();
    });

    it('does not show a tooltip', () => {
      expect(getTooltip()).toBeUndefined();
    });

    describe('when it resizes to contract', () => {
      beforeEach(() => {
        triggerOverflow(true);
      });

      it('shows a tooltip', () => {
        expect(getTooltip().value).toBe('An overflowing text');
      });
    });
  });

  describe('when content is updated', () => {
    beforeEach(() => {
      hasHorizontalOverflow.mockReturnValue(true);

      createWrapper({
        props: ['content'],
        template: `
          <div v-tooltip-on-truncate>
            {{content}}
          </div>`,
      });
    });

    it('shows a tooltip', async () => {
      expect(getTooltip().value).toBe('');

      await wrapper.setProps({ content: 'Some content' });

      expect(getTooltip().value).toBe('Some content');
    });
  });

  describe('when the tooltip has data and modifiers', () => {
    beforeEach(() => {
      hasHorizontalOverflow.mockReturnValue(true);

      createWrapper({
        template: `
          <div v-tooltip-on-truncate.focus="{ title: 'A summary of the text', container: 'body' }">
            An overflowing text
          </div>`,
      });
    });

    it('shows a tooltip with the modifiers and data provided', () => {
      expect(getTooltip()).toMatchObject({
        value: { title: 'A summary of the text', container: 'body' },
        modifiers: { focus: true },
      });
    });
  });
});
