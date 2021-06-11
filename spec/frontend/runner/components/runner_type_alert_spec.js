import { GlAlert, GlLink } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import RunnerTypeAlert from '~/runner/components/runner_type_alert.vue';
import { INSTANCE_TYPE, GROUP_TYPE, PROJECT_TYPE } from '~/runner/constants';

describe('RunnerTypeAlert', () => {
  let wrapper;

  const findAlert = () => wrapper.findComponent(GlAlert);
  const findLink = () => wrapper.findComponent(GlLink);

  const createComponent = ({ props = {} } = {}) => {
    wrapper = shallowMount(RunnerTypeAlert, {
      propsData: {
        type: INSTANCE_TYPE,
        ...props,
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  describe.each`
    type             | exampleText                                                           | anchor                 | variant
    ${INSTANCE_TYPE} | ${'Shared runners are available to every project'}                    | ${'#shared-runners'}   | ${'success'}
    ${GROUP_TYPE}    | ${'Use Group runners when you want all projects in a group'}          | ${'#group-runners'}    | ${'success'}
    ${PROJECT_TYPE}  | ${'You can set up a specific runner to be used by multiple projects'} | ${'#specific-runners'} | ${'info'}
  `('When it is an $type level runner', ({ type, exampleText, anchor, variant }) => {
    beforeEach(() => {
      createComponent({ props: { type } });
    });

    it('Describes runner type', () => {
      expect(wrapper.text()).toMatch(exampleText);
    });

    it(`Shows a ${variant} variant`, () => {
      expect(findAlert().props('variant')).toBe(variant);
    });

    it(`Links to anchor "${anchor}"`, () => {
      expect(findLink().attributes('href')).toBe(`/help/ci/runners/runners_scope${anchor}`);
    });
  });

  describe('When runner type is not correct', () => {
    it('Does not render content when type is missing', () => {
      createComponent({ props: { type: undefined } });

      expect(wrapper.html()).toBe('');
    });

    it('Validation fails for an incorrect type', () => {
      expect(() => {
        createComponent({ props: { type: 'NOT_A_TYPE' } });
      }).toThrow();
    });
  });
});
