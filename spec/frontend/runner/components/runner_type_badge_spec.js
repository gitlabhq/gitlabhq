import { GlBadge } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import RunnerTypeBadge from '~/runner/components/runner_type_badge.vue';
import { createMockDirective, getBinding } from 'helpers/vue_mock_directive';
import { INSTANCE_TYPE, GROUP_TYPE, PROJECT_TYPE } from '~/runner/constants';

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
        GlTooltip: createMockDirective(),
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  describe.each`
    type             | text
    ${INSTANCE_TYPE} | ${'shared'}
    ${GROUP_TYPE}    | ${'group'}
    ${PROJECT_TYPE}  | ${'specific'}
  `('displays $type runner', ({ type, text }) => {
    beforeEach(() => {
      createComponent({ props: { type } });
    });

    it(`as "${text}" with an "info" variant`, () => {
      expect(findBadge().text()).toBe(text);
      expect(findBadge().props('variant')).toBe('info');
    });

    it('with a tooltip', () => {
      expect(getTooltip().value).toBeDefined();
    });
  });

  it('validation fails for an incorrect type', () => {
    expect(() => {
      createComponent({ props: { type: 'AN_UNKNOWN_VALUE' } });
    }).toThrow();
  });

  it('does not render content when type is missing', () => {
    createComponent({ props: { type: undefined } });

    expect(findBadge().exists()).toBe(false);
  });
});
