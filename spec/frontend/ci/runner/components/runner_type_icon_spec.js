import { GlIcon } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import RunnerTypeIcon from '~/ci/runner/components/runner_type_icon.vue';
import { createMockDirective, getBinding } from 'helpers/vue_mock_directive';
import { assertProps } from 'helpers/assert_props';
import {
  INSTANCE_TYPE,
  GROUP_TYPE,
  PROJECT_TYPE,
  I18N_INSTANCE_TYPE,
  I18N_GROUP_TYPE,
  I18N_PROJECT_TYPE,
} from '~/ci/runner/constants';

describe('RunnerTypeIcon', () => {
  let wrapper;

  const findIcon = () => wrapper.findComponent(GlIcon);
  const getTooltip = () => getBinding(findIcon().element, 'gl-tooltip');

  const createComponent = ({ props = {} } = {}) => {
    wrapper = shallowMount(RunnerTypeIcon, {
      propsData: {
        ...props,
      },
      directives: {
        GlTooltip: createMockDirective('gl-tooltip'),
      },
    });
  };

  describe.each`
    type             | tooltipText
    ${INSTANCE_TYPE} | ${I18N_INSTANCE_TYPE}
    ${GROUP_TYPE}    | ${I18N_GROUP_TYPE}
    ${PROJECT_TYPE}  | ${I18N_PROJECT_TYPE}
  `('displays $type runner', ({ type, tooltipText }) => {
    beforeEach(() => {
      createComponent({ props: { type } });
    });

    it(`with no text`, () => {
      expect(findIcon().text()).toBe('');
    });

    it(`with aria-label`, () => {
      expect(findIcon().props('ariaLabel')).toBeDefined();
    });

    it('with a tooltip', () => {
      expect(getTooltip().value).toBeDefined();
      expect(getTooltip().value).toContain(tooltipText);
    });
  });

  it('validation fails for an incorrect type', () => {
    expect(() => {
      assertProps(RunnerTypeIcon, { type: 'AN_UNKNOWN_VALUE' });
    }).toThrow();
  });

  it('does not render content when type is missing', () => {
    createComponent({ props: { type: undefined } });

    expect(findIcon().exists()).toBe(false);
  });
});
