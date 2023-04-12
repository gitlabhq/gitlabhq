import { GlBadge } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import RunnerTypeBadge from '~/ci/runner/components/runner_type_badge.vue';
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

describe('RunnerTypeBadge', () => {
  let wrapper;

  const findBadge = () => wrapper.findComponent(GlBadge);
  const getTooltip = () => getBinding(findBadge().element, 'gl-tooltip');

  const createComponent = ({ props = {} } = {}) => {
    wrapper = shallowMount(RunnerTypeBadge, {
      propsData: {
        ...props,
      },
      directives: {
        GlTooltip: createMockDirective('gl-tooltip'),
      },
    });
  };

  describe.each`
    type             | text
    ${INSTANCE_TYPE} | ${I18N_INSTANCE_TYPE}
    ${GROUP_TYPE}    | ${I18N_GROUP_TYPE}
    ${PROJECT_TYPE}  | ${I18N_PROJECT_TYPE}
  `('displays $type runner', ({ type, text }) => {
    beforeEach(() => {
      createComponent({ props: { type } });
    });

    it(`as "${text}" with an "info" variant`, () => {
      expect(findBadge().text()).toBe(text);
      expect(findBadge().props('variant')).toBe('muted');
    });

    it('with a tooltip', () => {
      expect(getTooltip().value).toBeDefined();
    });
  });

  it('validation fails for an incorrect type', () => {
    expect(() => {
      assertProps(RunnerTypeBadge, { type: 'AN_UNKNOWN_VALUE' });
    }).toThrow();
  });

  it('does not render content when type is missing', () => {
    createComponent({ props: { type: undefined } });

    expect(findBadge().exists()).toBe(false);
  });
});
