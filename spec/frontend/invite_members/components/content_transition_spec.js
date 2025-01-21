import { groupBy, mapValues } from 'lodash';
import { shallowMount } from '@vue/test-utils';
import ContentTransition from '~/invite_members/components/content_transition.vue';

const TEST_CURRENT_SLOT = 'default';
const TEST_TRANSITION_NAME = 'test_transition_name';
const TEST_SLOTS = [
  { key: 'default', attributes: { 'data-testval': 'default' } },
  { key: 'foo', attributes: { 'data-testval': 'foo' } },
  { key: 'bar', attributes: { 'data-testval': 'bar' } },
];

describe('~/vue_shared/components/content_transition.vue', () => {
  let wrapper;

  const createComponent = (props = {}, slots = {}) => {
    wrapper = shallowMount(ContentTransition, {
      propsData: {
        transitionName: TEST_TRANSITION_NAME,
        currentSlot: TEST_CURRENT_SLOT,
        slots: TEST_SLOTS,
        ...props,
      },
      slots: {
        default: '<p>Default</p>',
        foo: '<p>Foo</p>',
        bar: '<p>Bar</p>',
        dne: '<p>DOES NOT EXIST</p>',
        ...slots,
      },
    });
  };

  const findTransitionsData = () =>
    wrapper.findAll('transition-stub').wrappers.map((transition) => {
      const child = transition.find('[data-testval]');
      const { style, ...attributes } = child.attributes();

      return {
        transitionName: transition.attributes('name'),
        isVisible: child.isVisible(),
        attributes,
        text: transition.text(),
      };
    });
  const findVisibleData = () => {
    const group = groupBy(findTransitionsData(), (x) => x.attributes['data-testval']);

    return mapValues(group, (x) => x[0].isVisible);
  };

  describe('default', () => {
    beforeEach(() => {
      createComponent();
    });

    it('shows all transitions and only default is visible', () => {
      expect(wrapper.element).toMatchSnapshot();
    });

    it('render transitions for each slot', () => {
      expect(findTransitionsData()).toEqual([
        {
          attributes: {
            'data-testval': 'default',
          },
          isVisible: true,
          text: 'Default',
          transitionName: 'test_transition_name',
        },
        {
          attributes: {
            'data-testval': 'foo',
          },
          isVisible: false,
          text: 'Foo',
          transitionName: 'test_transition_name',
        },
        {
          attributes: {
            'data-testval': 'bar',
          },
          isVisible: false,
          text: 'Bar',
          transitionName: 'test_transition_name',
        },
      ]);
    });
  });

  describe('with currentSlot=foo', () => {
    beforeEach(() => {
      createComponent({ currentSlot: 'foo' });
    });

    it('should only show the foo slot', () => {
      expect(findVisibleData()).toEqual({
        default: false,
        foo: true,
        bar: false,
      });
    });
  });
});
