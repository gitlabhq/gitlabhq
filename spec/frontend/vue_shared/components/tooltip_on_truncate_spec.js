import { mount, shallowMount } from '@vue/test-utils';
import { nextTick } from 'vue';
import { hasHorizontalOverflow } from '~/lib/utils/dom_utils';
import TooltipOnTruncate from '~/vue_shared/components/tooltip_on_truncate/tooltip_on_truncate.vue';
import { createMockDirective, getBinding } from 'helpers/vue_mock_directive';

const MOCK_TITLE = 'lorem-ipsum-dolar-sit-amit-consectur-adipiscing-elit-sed-do';
const SHORT_TITLE = 'my-text';

const createChildElement = () => `<a href="#">${MOCK_TITLE}</a>`;

jest.mock('~/lib/utils/dom_utils', () => ({
  ...jest.requireActual('~/lib/utils/dom_utils'),
  hasHorizontalOverflow: jest.fn().mockImplementation(() => {
    throw new Error('this needs to be mocked');
  }),
}));

describe('TooltipOnTruncate component', () => {
  let wrapper;
  let parent;

  const createComponent = ({ propsData, ...options } = {}) => {
    wrapper = shallowMount(TooltipOnTruncate, {
      propsData: {
        title: MOCK_TITLE,
        ...propsData,
      },
      slots: {
        default: [MOCK_TITLE],
      },
      directives: {
        GlTooltip: createMockDirective('gl-tooltip'),
        GlResizeObserver: createMockDirective('gl-resize-observer'),
      },
      ...options,
    });
  };

  const createWrappedComponent = ({ propsData, ...options }) => {
    const WrappedTooltipOnTruncate = {
      ...TooltipOnTruncate,
      directives: {
        ...TooltipOnTruncate.directives,
        GlTooltip: createMockDirective('gl-tooltip'),
        GlResizeObserver: createMockDirective('gl-resize-observer'),
      },
    };

    // set a parent around the tested component
    parent = mount(
      {
        props: {
          title: { default: '' },
        },
        template: `
          <TooltipOnTruncate :title="title" truncate-target="child">
            <div>{{title}}</div>
          </TooltipOnTruncate>
        `,
        components: {
          TooltipOnTruncate: WrappedTooltipOnTruncate,
        },
      },
      {
        propsData: { ...propsData },
        ...options,
      },
    );

    wrapper = parent.findComponent(WrappedTooltipOnTruncate);
  };

  const getTooltipValue = () => getBinding(wrapper.element, 'gl-tooltip')?.value;
  const resize = async ({ truncate }) => {
    hasHorizontalOverflow.mockReturnValueOnce(truncate);
    getBinding(wrapper.element, 'gl-resize-observer').value();
    await nextTick();
  };

  describe('when truncated', () => {
    beforeEach(() => {
      hasHorizontalOverflow.mockReturnValueOnce(true);
      createComponent();
    });

    it('renders tooltip', () => {
      expect(hasHorizontalOverflow).toHaveBeenLastCalledWith(wrapper.element);
      expect(getTooltipValue()).toStrictEqual({
        title: MOCK_TITLE,
        placement: 'top',
        disabled: false,
      });
      expect(wrapper.classes('js-show-tooltip')).toBe(true);
    });
  });

  describe('with default target', () => {
    beforeEach(() => {
      hasHorizontalOverflow.mockReturnValueOnce(false);
      createComponent();
    });

    it('does not render tooltip if not truncated', () => {
      expect(hasHorizontalOverflow).toHaveBeenLastCalledWith(wrapper.element);
      expect(getTooltipValue()).toMatchObject({
        disabled: true,
      });
      expect(wrapper.classes('js-show-tooltip')).toBe(false);
    });

    it('renders tooltip on resize', async () => {
      await resize({ truncate: true });

      expect(getTooltipValue()).toMatchObject({
        disabled: false,
      });

      await resize({ truncate: false });

      expect(getTooltipValue()).toMatchObject({
        disabled: true,
      });
    });
  });

  describe('with child target', () => {
    it('renders tooltip if truncated', async () => {
      hasHorizontalOverflow.mockReturnValueOnce(true);
      createComponent({
        propsData: {
          truncateTarget: 'child',
        },
        slots: {
          default: createChildElement(),
        },
      });

      expect(hasHorizontalOverflow).toHaveBeenLastCalledWith(wrapper.element.childNodes[0]);

      await nextTick();

      expect(getTooltipValue()).toStrictEqual({
        title: MOCK_TITLE,
        placement: 'top',
        disabled: false,
      });
    });

    it('does not render tooltip if normal', async () => {
      hasHorizontalOverflow.mockReturnValueOnce(false);
      createComponent({
        propsData: {
          truncateTarget: 'child',
        },
        slots: {
          default: createChildElement(),
        },
      });

      expect(hasHorizontalOverflow).toHaveBeenLastCalledWith(wrapper.element.childNodes[0]);

      await nextTick();

      expect(getTooltipValue()).toMatchObject({
        disabled: true,
      });
    });
  });

  describe('with fn target', () => {
    it('renders tooltip if truncated', async () => {
      hasHorizontalOverflow.mockReturnValueOnce(true);
      createComponent({
        propsData: {
          truncateTarget: (el) => el.childNodes[1],
        },
        slots: {
          default: [createChildElement(), createChildElement()],
        },
      });

      expect(hasHorizontalOverflow).toHaveBeenLastCalledWith(wrapper.element.childNodes[1]);

      await nextTick();

      expect(getTooltipValue()).toMatchObject({
        disabled: false,
      });
    });
  });

  describe('tooltip customization', () => {
    it.each`
      property       | mockValue
      ${'placement'} | ${'bottom'}
      ${'boundary'}  | ${'viewport'}
    `('sets $property when the tooltip is rendered', ({ property, mockValue }) => {
      hasHorizontalOverflow.mockReturnValueOnce(true);
      createComponent({
        propsData: {
          [property]: mockValue,
        },
      });

      expect(hasHorizontalOverflow).toHaveBeenLastCalledWith(wrapper.element);
      expect(getTooltipValue()).toMatchObject({
        [property]: mockValue,
      });
    });
  });

  describe('updates when title and slot content changes', () => {
    describe('is initialized with a long text', () => {
      beforeEach(async () => {
        hasHorizontalOverflow.mockReturnValueOnce(true);
        createWrappedComponent({
          propsData: { title: MOCK_TITLE },
        });
        await nextTick();
      });

      it('renders tooltip', () => {
        expect(getTooltipValue()).toMatchObject({
          title: MOCK_TITLE,
          placement: 'top',
          disabled: false,
        });
      });

      it('does not render tooltip after updated to a short text', async () => {
        hasHorizontalOverflow.mockReturnValueOnce(false);
        parent.setProps({
          title: SHORT_TITLE,
        });

        await nextTick();
        await nextTick(); // wait 2 times to get an updated slot

        expect(getTooltipValue()).toMatchObject({
          title: SHORT_TITLE,
          disabled: true,
        });
      });
    });

    describe('is initialized with a short text that does not overflow', () => {
      beforeEach(async () => {
        hasHorizontalOverflow.mockReturnValueOnce(false);
        createWrappedComponent({
          propsData: { title: MOCK_TITLE },
        });
        await nextTick();
      });

      it('does not render tooltip', () => {
        expect(getTooltipValue()).toMatchObject({
          title: MOCK_TITLE,
          disabled: true,
        });
      });

      it('renders tooltip after text is updated', async () => {
        hasHorizontalOverflow.mockReturnValueOnce(true);
        parent.setProps({
          title: SHORT_TITLE,
        });

        await nextTick();
        await nextTick(); // wait 2 times to get an updated slot

        expect(getTooltipValue()).toMatchObject({
          title: SHORT_TITLE,
          disabled: false,
        });
      });
    });
  });
});
