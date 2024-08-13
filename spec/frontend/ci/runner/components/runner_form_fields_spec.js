import { nextTick } from 'vue';
import { GlSkeletonLoader } from '@gitlab/ui';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import RunnerFormFields from '~/ci/runner/components/runner_form_fields.vue';
import {
  ACCESS_LEVEL_NOT_PROTECTED,
  ACCESS_LEVEL_REF_PROTECTED,
  PROJECT_TYPE,
} from '~/ci/runner/constants';

const mockDescription = 'My description';
const mockNewDescription = 'My new description';
const mockMaxTimeout = 60;
const mockTags = 'tag, tag2';

describe('RunnerFormFields', () => {
  let wrapper;

  const findInputByLabel = (label) => wrapper.findByLabelText(label);
  const findInput = (name) => wrapper.find(`input[name="${name}"]`);

  const expectRendersFields = () => {
    expect(wrapper.text()).toContain('Tags');
    expect(wrapper.text()).toContain('Configuration');

    expect(wrapper.findAllComponents(GlSkeletonLoader)).toHaveLength(0);
    expect(wrapper.findAll('input')).toHaveLength(6);
  };

  const createComponent = ({ ...props } = {}) => {
    wrapper = mountExtended(RunnerFormFields, {
      propsData: {
        ...props,
      },
    });
  };

  describe('when runner is loading', () => {
    beforeEach(() => {
      createComponent({ loading: true });
    });

    it('renders a loading frame', () => {
      expect(wrapper.text()).toContain('Tags');
      expect(wrapper.text()).toContain('Configuration');

      expect(wrapper.findAllComponents(GlSkeletonLoader)).toHaveLength(2);
      expect(wrapper.findAll('input')).toHaveLength(0);
    });

    describe('and then is loaded', () => {
      beforeEach(() => {
        wrapper.setProps({ loading: false, value: { description: mockDescription } });
      });

      it('renders fields', () => {
        expectRendersFields();
      });
    });
  });

  it('when runner is loaded, renders fields', () => {
    createComponent({
      value: { description: mockDescription },
    });

    expectRendersFields();
  });

  it('when runner is updated with the same value, only emits when changed (avoids infinite loop)', async () => {
    createComponent({ value: null, loading: true });
    await wrapper.setProps({ value: { description: mockDescription }, loading: false });
    await wrapper.setProps({ value: { description: mockDescription }, loading: false });

    expect(wrapper.emitted('input')).toHaveLength(1);
  });

  it('updates runner fields', async () => {
    createComponent({
      value: { description: mockDescription },
    });

    expect(wrapper.emitted('input')).toBe(undefined);

    findInputByLabel('Runner description').setValue(mockNewDescription);
    findInput('max-timeout').setValue(mockMaxTimeout);
    findInput('tags').setValue(mockTags);

    await nextTick();

    expect(wrapper.emitted('input').at(-1)).toEqual([
      {
        description: mockNewDescription,
        maximumTimeout: mockMaxTimeout,
        tagList: mockTags,
      },
    ]);
  });

  it('checks checkbox fields', async () => {
    createComponent({
      value: {
        runUntagged: false,
        paused: false,
        accessLevel: ACCESS_LEVEL_NOT_PROTECTED,
      },
    });

    findInput('run-untagged').setChecked(true);
    findInput('paused').setChecked(true);
    findInput('protected').setChecked(true);

    await nextTick();

    expect(wrapper.emitted('input').at(-1)).toEqual([
      {
        runUntagged: true,
        paused: true,
        accessLevel: ACCESS_LEVEL_REF_PROTECTED,
      },
    ]);
  });

  it('locked checkbox is not shown', () => {
    createComponent();

    expect(findInput('locked').exists()).toBe(false);
  });

  it('when runner is of project type, locked checkbox can be checked', async () => {
    createComponent({
      runnerType: PROJECT_TYPE,
      value: {
        locked: false,
      },
    });

    findInput('locked').setChecked(true);

    await nextTick();

    expect(wrapper.emitted('input').at(-1)).toEqual([
      {
        locked: true,
      },
    ]);
  });

  it('unchecks checkbox fields', async () => {
    createComponent({
      value: {
        paused: true,
        accessLevel: ACCESS_LEVEL_REF_PROTECTED,
        runUntagged: true,
      },
    });

    findInput('paused').setChecked(false);
    findInput('protected').setChecked(false);
    findInput('run-untagged').setChecked(false);

    await nextTick();

    expect(wrapper.emitted('input').at(-1)).toEqual([
      {
        paused: false,
        accessLevel: ACCESS_LEVEL_NOT_PROTECTED,
        runUntagged: false,
      },
    ]);
  });
});
