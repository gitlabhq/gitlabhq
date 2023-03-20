import { shallowMount } from '@vue/test-utils';
import { GlIcon } from '@gitlab/ui';
import { nextTick } from 'vue';
import { createMockDirective, getBinding } from 'helpers/vue_mock_directive';
import DropdownValueCollapsedComponent from '~/sidebar/components/labels/labels_select_vue/dropdown_value_collapsed.vue';

import { mockCollapsedLabels as mockLabels, mockRegularLabel } from './mock_data';

describe('DropdownValueCollapsedComponent', () => {
  let wrapper;

  const defaultProps = {
    labels: [],
  };

  const mockManyLabels = [...mockLabels, ...mockLabels, ...mockLabels];

  const createComponent = ({ props = {} } = {}) => {
    wrapper = shallowMount(DropdownValueCollapsedComponent, {
      propsData: { ...defaultProps, ...props },
      directives: {
        GlTooltip: createMockDirective('gl-tooltip'),
      },
    });
  };

  const findGlIcon = () => wrapper.findComponent(GlIcon);
  const getTooltip = () => getBinding(wrapper.element, 'gl-tooltip');

  describe('template', () => {
    it('renders tags icon element', () => {
      createComponent();

      expect(findGlIcon().exists()).toBe(true);
    });

    it('emits onValueClick event on click', async () => {
      createComponent();

      wrapper.trigger('click');

      await nextTick();

      expect(wrapper.emitted('onValueClick')[0]).toBeDefined();
    });

    describe.each`
      scenario                            | labels                | expectedResult                                          | expectedText
      ${'`labels` is empty'}              | ${[]}                 | ${'default text'}                                       | ${'Labels'}
      ${'`labels` has 1 item'}            | ${[mockRegularLabel]} | ${'label name'}                                         | ${'Foo Label'}
      ${'`labels` has 2 items'}           | ${mockLabels}         | ${'comma separated label names'}                        | ${'Foo Label, Foo::Bar'}
      ${'`labels` has more than 5 items'} | ${mockManyLabels}     | ${'comma separated label names with "and more" phrase'} | ${'Foo Label, Foo::Bar, Foo Label, Foo::Bar, Foo Label, and 1 more'}
    `('when $scenario', ({ labels, expectedResult, expectedText }) => {
      beforeEach(() => {
        createComponent({
          props: {
            labels,
          },
        });
      });

      it('renders labels count', () => {
        expect(wrapper.text()).toBe(`${labels.length}`);
      });

      it(`renders "${expectedResult}" as tooltip`, () => {
        expect(getTooltip().value).toBe(expectedText);
      });
    });
  });
});
