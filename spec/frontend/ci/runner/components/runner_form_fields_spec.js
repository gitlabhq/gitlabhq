import { nextTick } from 'vue';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import RunnerFormFields from '~/ci/runner/components/runner_form_fields.vue';
import { ACCESS_LEVEL_NOT_PROTECTED, ACCESS_LEVEL_REF_PROTECTED } from '~/ci/runner/constants';

const mockDescription = 'My description';
const mockMaxTimeout = 60;
const mockTags = 'tag, tag2';

describe('RunnerFormFields', () => {
  let wrapper;

  const findInput = (name) => wrapper.find(`input[name="${name}"]`);

  const createComponent = ({ runner } = {}) => {
    wrapper = mountExtended(RunnerFormFields, {
      propsData: {
        value: runner,
      },
    });
  };

  it('updates runner fields', async () => {
    createComponent();

    expect(wrapper.emitted('input')).toBe(undefined);

    findInput('description').setValue(mockDescription);
    findInput('max-timeout').setValue(mockMaxTimeout);
    findInput('paused').setChecked(true);
    findInput('protected').setChecked(true);
    findInput('run-untagged').setChecked(true);
    findInput('tags').setValue(mockTags);

    await nextTick();

    expect(wrapper.emitted('input')[0][0]).toMatchObject({
      description: mockDescription,
      maximumTimeout: mockMaxTimeout,
      tagList: mockTags,
    });
  });

  it('checks checkbox fields', async () => {
    createComponent({
      runner: {
        paused: false,
        accessLevel: ACCESS_LEVEL_NOT_PROTECTED,
        runUntagged: false,
      },
    });

    findInput('paused').setChecked(true);
    findInput('protected').setChecked(true);
    findInput('run-untagged').setChecked(true);

    await nextTick();

    expect(wrapper.emitted('input')[0][0]).toEqual({
      paused: true,
      accessLevel: ACCESS_LEVEL_REF_PROTECTED,
      runUntagged: true,
    });
  });

  it('unchecks checkbox fields', async () => {
    createComponent({
      runner: {
        paused: true,
        accessLevel: ACCESS_LEVEL_REF_PROTECTED,
        runUntagged: true,
      },
    });

    findInput('paused').setChecked(false);
    findInput('protected').setChecked(false);
    findInput('run-untagged').setChecked(false);

    await nextTick();

    expect(wrapper.emitted('input')[0][0]).toEqual({
      paused: false,
      accessLevel: ACCESS_LEVEL_NOT_PROTECTED,
      runUntagged: false,
    });
  });
});
