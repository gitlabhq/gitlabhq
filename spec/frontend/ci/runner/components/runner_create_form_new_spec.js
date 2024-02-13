import { GlForm } from '@gitlab/ui';
import { nextTick } from 'vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import RunnerCreateFormNew from '~/ci/runner/components/runner_create_form_new.vue';
import RunnerFormFields from '~/ci/runner/components/runner_form_fields.vue';
import {
  DEFAULT_ACCESS_LEVEL,
  INSTANCE_TYPE,
  PROJECT_TYPE,
  GROUP_TYPE,
} from '~/ci/runner/constants';

describe('New Runner Create Form', () => {
  let wrapper;

  const defaultRunnerModel = {
    runnerType: PROJECT_TYPE,
    description: '',
    accessLevel: DEFAULT_ACCESS_LEVEL,
    paused: false,
    maintenanceNote: '',
    maximumTimeout: '',
    runUntagged: false,
    locked: false,
    tagList: '',
  };

  const findForm = () => wrapper.findComponent(GlForm);
  const findRunnerFormFields = () => wrapper.findComponent(RunnerFormFields);
  const findSubmitBtn = () => wrapper.find('[type="submit"]');
  const findBackButton = () => wrapper.findByTestId('back-button');

  const createComponent = ({ props } = {}) => {
    wrapper = shallowMountExtended(RunnerCreateFormNew, {
      propsData: {
        runnerType: PROJECT_TYPE,
        ...props,
      },
    });
  };

  it('shows default runner values', () => {
    createComponent();

    expect(findRunnerFormFields().props('value')).toEqual(defaultRunnerModel);
    expect(findRunnerFormFields().props('runnerType')).toEqual(PROJECT_TYPE);
  });

  it('shows a submit button', () => {
    createComponent();

    expect(findSubmitBtn().exists()).toBe(true);
  });

  it('shows a back button', () => {
    createComponent();

    expect(findBackButton().exists()).toBe(true);
  });

  it('emits a previous event when the back button is clicked', async () => {
    createComponent();

    await nextTick();
    await findBackButton().vm.$emit('click');

    expect(wrapper.emitted('previous')).toBeDefined();
  });

  describe.each`
    typeName                | props                                                                 | scopeData
    ${'an instance runner'} | ${{ runnerType: INSTANCE_TYPE }}                                      | ${{ runnerType: INSTANCE_TYPE }}
    ${'a group runner'}     | ${{ runnerType: GROUP_TYPE, groupId: 'gid://gitlab/Group/72' }}       | ${{ runnerType: GROUP_TYPE, groupId: 'gid://gitlab/Group/72' }}
    ${'a project runner'}   | ${{ runnerType: PROJECT_TYPE, projectId: 'gid://gitlab/Project/42' }} | ${{ runnerType: PROJECT_TYPE, projectId: 'gid://gitlab/Project/42' }}
  `('when user submits $typeName', ({ props, scopeData }) => {
    let preventDefault;

    beforeEach(() => {
      createComponent({ props });

      preventDefault = jest.fn();

      findRunnerFormFields().vm.$emit('input', {
        ...defaultRunnerModel,
        runnerType: props.runnerType,
        description: 'My runner',
        maximumTimeout: 0,
        tagList: 'tag1, tag2',
      });
    });

    describe('immediately after submit', () => {
      beforeEach(() => {
        findForm().vm.$emit('submit', { preventDefault });
      });

      it('prevents default form submission', () => {
        expect(preventDefault).toHaveBeenCalledTimes(1);
      });

      it('emits a createRunner event', () => {
        expect(wrapper.emitted('createRunner')).toEqual([
          [
            {
              ...defaultRunnerModel,
              ...scopeData,
              description: 'My runner',
              maximumTimeout: 0,
              tagList: ['tag1', 'tag2'],
            },
          ],
        ]);
      });
    });
  });
});
