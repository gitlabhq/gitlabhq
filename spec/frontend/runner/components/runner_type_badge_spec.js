import { GlBadge } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import RunnerTypeBadge from '~/runner/components/runner_type_badge.vue';
import { INSTANCE_TYPE, GROUP_TYPE, PROJECT_TYPE } from '~/runner/constants';

describe('RunnerTypeBadge', () => {
  let wrapper;

  const findBadge = () => wrapper.findComponent(GlBadge);

  const createComponent = ({ props = {} } = {}) => {
    wrapper = shallowMount(RunnerTypeBadge, {
      propsData: {
        ...props,
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  it.each`
    type             | text          | variant
    ${INSTANCE_TYPE} | ${'shared'}   | ${'success'}
    ${GROUP_TYPE}    | ${'group'}    | ${'success'}
    ${PROJECT_TYPE}  | ${'specific'} | ${'info'}
  `('displays $type runner with as "$text" with a $variant variant ', ({ type, text, variant }) => {
    createComponent({ props: { type } });

    expect(findBadge().text()).toBe(text);
    expect(findBadge().props('variant')).toBe(variant);
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
