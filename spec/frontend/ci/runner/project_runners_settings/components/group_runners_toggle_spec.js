import { GlToggle } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import waitForPromises from 'helpers/wait_for_promises';
import createMockApollo from 'helpers/mock_apollo_helper';
import groupRunnersEnabledQuery from '~/ci/runner/project_runners_settings/graphql/group_runners_enabled.query.graphql';
import groupRunnersEnabledMutation from '~/ci/runner/project_runners_settings/graphql/group_runners_enabled.mutation.graphql';
import GroupRunnersToggle from '~/ci/runner/project_runners_settings/components/group_runners_toggle.vue';

Vue.use(VueApollo);

const groupRunnersEnabledData = {
  data: {
    project: {
      id: '1',
      ciCdSettings: { groupRunnersEnabled: true },
    },
  },
};

const groupRunnersEnabledMutationData = {
  data: {
    projectCiCdSettingsUpdate: {
      ciCdSettings: { groupRunnersEnabled: false },
      errors: [],
    },
  },
};

const projectFullPath = 'gitlab-org/gitlab';

describe('GroupRunnersToggle', () => {
  let wrapper;
  let queryHandler;
  let mutationHandler;

  const findToggle = () => wrapper.findComponent(GlToggle);

  const createComponent = ({ props } = {}) => {
    const apolloProvider = createMockApollo([
      [groupRunnersEnabledQuery, queryHandler],
      [groupRunnersEnabledMutation, mutationHandler],
    ]);

    wrapper = shallowMount(GroupRunnersToggle, {
      apolloProvider,
      propsData: {
        projectFullPath,
        ...props,
      },
    });

    return waitForPromises();
  };

  beforeEach(() => {
    queryHandler = jest.fn().mockResolvedValue(groupRunnersEnabledData);
    mutationHandler = jest.fn().mockResolvedValue(groupRunnersEnabledMutationData);
  });

  it('displays toggle', () => {
    createComponent();

    expect(findToggle().props()).toMatchObject({
      isLoading: true,
      labelPosition: 'left',
      value: null,
      label: 'Turn on group runners for this project',
    });
  });

  it('fetches current setting', async () => {
    await createComponent();

    expect(queryHandler).toHaveBeenCalledWith({
      fullPath: projectFullPath,
    });
    expect(findToggle().props('value')).toBe(true);
    expect(findToggle().props('isLoading')).toBe(false);

    expect(wrapper.emitted('change')).toEqual([[true]]);
  });

  it('handles error when fetching', async () => {
    queryHandler.mockRejectedValueOnce(new Error('Error fetching'));

    await createComponent();

    expect(findToggle().props('isLoading')).toBe(false);
    expect(wrapper.emitted('error')).toEqual([[new Error('Error fetching')]]);
  });

  it('updates setting', async () => {
    await createComponent();
    findToggle().vm.$emit('change', false);

    expect(mutationHandler).toHaveBeenCalledWith({
      input: {
        fullPath: projectFullPath,
        groupRunnersEnabled: false,
      },
    });
    expect(findToggle().props('isLoading')).toBe(false);

    expect(wrapper.emitted('change')).toEqual([[true]]);
  });

  it('handles error when updating settings', async () => {
    mutationHandler.mockRejectedValueOnce(new Error('Error'));

    await createComponent();

    findToggle().vm.$emit('change', false);
    await waitForPromises();

    expect(wrapper.emitted('error')).toEqual([[new Error('Error')]]);
  });

  it('handles api error when updating settings', async () => {
    mutationHandler.mockResolvedValueOnce({
      data: {
        projectCiCdSettingsUpdate: {
          ...groupRunnersEnabledMutationData.data.projectCiCdSettingsUpdate,
          errors: ['API Error'],
        },
      },
    });

    await createComponent();

    findToggle().vm.$emit('change', false);
    await waitForPromises();

    expect(wrapper.emitted('error')).toEqual([[new Error('API Error')]]);
  });
});
