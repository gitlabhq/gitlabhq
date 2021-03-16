import { mount, shallowMount } from '@vue/test-utils';
import { hasHorizontalOverflow } from '~/lib/utils/dom_utils';
import TooltipOnTruncate from '~/vue_shared/components/tooltip_on_truncate.vue';

const DUMMY_TEXT = 'lorem-ipsum-dolar-sit-amit-consectur-adipiscing-elit-sed-do';

const createChildElement = () => `<a href="#">${DUMMY_TEXT}</a>`;

jest.mock('~/lib/utils/dom_utils', () => ({
  hasHorizontalOverflow: jest.fn(() => {
    throw new Error('this needs to be mocked');
  }),
}));
jest.mock('@gitlab/ui', () => ({
  GlTooltipDirective: {
    bind(el, binding) {
      el.classList.add('gl-tooltip');
      el.setAttribute('data-original-title', el.title);
      el.dataset.placement = binding.value.placement;
    },
  },
}));

describe('TooltipOnTruncate component', () => {
  let wrapper;
  let parent;

  const createComponent = ({ propsData, ...options } = {}) => {
    wrapper = shallowMount(TooltipOnTruncate, {
      attachTo: document.body,
      propsData: {
        ...propsData,
      },
      ...options,
    });
  };

  const createWrappedComponent = ({ propsData, ...options }) => {
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
          TooltipOnTruncate,
        },
      },
      {
        propsData: { ...propsData },
        attachTo: document.body,
        ...options,
      },
    );

    wrapper = parent.find(TooltipOnTruncate);
  };

  const hasTooltip = () => wrapper.classes('gl-tooltip');

  afterEach(() => {
    wrapper.destroy();
  });

  describe('with default target', () => {
    it('renders tooltip if truncated', () => {
      hasHorizontalOverflow.mockReturnValueOnce(true);
      createComponent({
        propsData: {
          title: DUMMY_TEXT,
        },
        slots: {
          default: [DUMMY_TEXT],
        },
      });

      return wrapper.vm.$nextTick().then(() => {
        expect(hasHorizontalOverflow).toHaveBeenCalledWith(wrapper.element);
        expect(hasTooltip()).toBe(true);
        expect(wrapper.attributes('data-original-title')).toEqual(DUMMY_TEXT);
        expect(wrapper.attributes('data-placement')).toEqual('top');
      });
    });

    it('does not render tooltip if normal', () => {
      hasHorizontalOverflow.mockReturnValueOnce(false);
      createComponent({
        propsData: {
          title: DUMMY_TEXT,
        },
        slots: {
          default: [DUMMY_TEXT],
        },
      });

      return wrapper.vm.$nextTick().then(() => {
        expect(hasHorizontalOverflow).toHaveBeenCalledWith(wrapper.element);
        expect(hasTooltip()).toBe(false);
      });
    });
  });

  describe('with child target', () => {
    it('renders tooltip if truncated', () => {
      hasHorizontalOverflow.mockReturnValueOnce(true);
      createComponent({
        propsData: {
          title: DUMMY_TEXT,
          truncateTarget: 'child',
        },
        slots: {
          default: createChildElement(),
        },
      });

      return wrapper.vm.$nextTick().then(() => {
        expect(hasHorizontalOverflow).toHaveBeenCalledWith(wrapper.element.childNodes[0]);
        expect(hasTooltip()).toBe(true);
      });
    });

    it('does not render tooltip if normal', () => {
      hasHorizontalOverflow.mockReturnValueOnce(false);
      createComponent({
        propsData: {
          truncateTarget: 'child',
        },
        slots: {
          default: createChildElement(),
        },
      });

      return wrapper.vm.$nextTick().then(() => {
        expect(hasHorizontalOverflow).toHaveBeenCalledWith(wrapper.element.childNodes[0]);
        expect(hasTooltip()).toBe(false);
      });
    });
  });

  describe('with fn target', () => {
    it('renders tooltip if truncated', () => {
      hasHorizontalOverflow.mockReturnValueOnce(true);
      createComponent({
        propsData: {
          title: DUMMY_TEXT,
          truncateTarget: (el) => el.childNodes[1],
        },
        slots: {
          default: [createChildElement(), createChildElement()],
        },
      });

      return wrapper.vm.$nextTick().then(() => {
        expect(hasHorizontalOverflow).toHaveBeenCalledWith(wrapper.element.childNodes[1]);
        expect(hasTooltip()).toBe(true);
      });
    });
  });

  describe('placement', () => {
    it('sets data-placement when tooltip is rendered', () => {
      const placement = 'bottom';

      hasHorizontalOverflow.mockReturnValueOnce(true);
      createComponent({
        propsData: {
          placement,
        },
        slots: {
          default: DUMMY_TEXT,
        },
      });

      return wrapper.vm.$nextTick().then(() => {
        expect(hasTooltip()).toBe(true);
        expect(wrapper.attributes('data-placement')).toEqual(placement);
      });
    });
  });

  describe('updates when title and slot content changes', () => {
    describe('is initialized with a long text', () => {
      beforeEach(() => {
        hasHorizontalOverflow.mockReturnValueOnce(true);
        createWrappedComponent({
          propsData: { title: DUMMY_TEXT },
        });
        return parent.vm.$nextTick();
      });

      it('renders tooltip', () => {
        expect(hasTooltip()).toBe(true);
        expect(wrapper.attributes('data-original-title')).toEqual(DUMMY_TEXT);
        expect(wrapper.attributes('data-placement')).toEqual('top');
      });

      it('does not render tooltip after updated to a short text', () => {
        hasHorizontalOverflow.mockReturnValueOnce(false);
        parent.setProps({
          title: 'new-text',
        });

        return wrapper.vm
          .$nextTick()
          .then(() => wrapper.vm.$nextTick()) // wait 2 times to get an updated slot
          .then(() => {
            expect(hasTooltip()).toBe(false);
          });
      });
    });

    describe('is initialized with a short text', () => {
      beforeEach(() => {
        hasHorizontalOverflow.mockReturnValueOnce(false);
        createWrappedComponent({
          propsData: { title: DUMMY_TEXT },
        });
        return wrapper.vm.$nextTick();
      });

      it('does not render tooltip', () => {
        expect(hasTooltip()).toBe(false);
      });

      it('renders tooltip after text is updated', () => {
        hasHorizontalOverflow.mockReturnValueOnce(true);
        const newText = 'new-text';
        parent.setProps({
          title: newText,
        });

        return wrapper.vm
          .$nextTick()
          .then(() => wrapper.vm.$nextTick()) // wait 2 times to get an updated slot
          .then(() => {
            expect(hasTooltip()).toBe(true);
            expect(wrapper.attributes('data-original-title')).toEqual(newText);
            expect(wrapper.attributes('data-placement')).toEqual('top');
          });
      });
    });
  });
});
