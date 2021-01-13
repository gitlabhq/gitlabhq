import { GlFormCheckbox, GlLink } from '@gitlab/ui';
import { shallowMount, createLocalVue } from '@vue/test-utils';
import VueApollo from 'vue-apollo';
import createMockApollo from 'jest/helpers/mock_apollo_helper';
import KeepLatestArtifactCheckbox from '~/artifacts_settings/keep_latest_artifact_checkbox.vue';
import GetKeepLatestArtifactProjectSetting from '~/artifacts_settings/graphql/queries/get_keep_latest_artifact_project_setting.query.graphql';
import UpdateKeepLatestArtifactProjectSetting from '~/artifacts_settings/graphql/mutations/update_keep_latest_artifact_project_setting.mutation.graphql';

const localVue = createLocalVue();
localVue.use(VueApollo);

const keepLatestArtifactMock = {
  data: {
    project: {
      ciCdSettings: { keepLatestArtifact: true },
    },
  },
};

const keepLatestArtifactMockResponse = {
  data: { ciCdSettingsUpdate: { errors: [], __typename: 'CiCdSettingsUpdatePayload' } },
};

describe('Keep latest artifact checkbox', () => {
  let wrapper;
  let apolloProvider;
  let requestHandlers;

  const fullPath = 'gitlab-org/gitlab';
  const helpPagePath = '/help/ci/pipelines/job_artifacts';

  const findCheckbox = () => wrapper.find(GlFormCheckbox);
  const findHelpLink = () => wrapper.find(GlLink);

  const createComponent = (handlers) => {
    requestHandlers = {
      keepLatestArtifactQueryHandler: jest.fn().mockResolvedValue(keepLatestArtifactMock),
      keepLatestArtifactMutationHandler: jest
        .fn()
        .mockResolvedValue(keepLatestArtifactMockResponse),
      ...handlers,
    };

    apolloProvider = createMockApollo([
      [GetKeepLatestArtifactProjectSetting, requestHandlers.keepLatestArtifactQueryHandler],
      [UpdateKeepLatestArtifactProjectSetting, requestHandlers.keepLatestArtifactMutationHandler],
    ]);

    wrapper = shallowMount(KeepLatestArtifactCheckbox, {
      provide: {
        fullPath,
        helpPagePath,
      },
      localVue,
      apolloProvider,
    });
  };

  beforeEach(() => {
    createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
    apolloProvider = null;
  });

  it('displays the checkbox and the help link', () => {
    expect(findCheckbox().exists()).toBe(true);
    expect(findHelpLink().exists()).toBe(true);
  });

  it('sets correct setting value in checkbox with query result', async () => {
    await wrapper.vm.$nextTick();

    expect(wrapper.element).toMatchSnapshot();
  });

  it('calls mutation on artifact setting change with correct payload', () => {
    findCheckbox().vm.$emit('change', false);

    expect(requestHandlers.keepLatestArtifactMutationHandler).toHaveBeenCalledWith({
      fullPath,
      keepLatestArtifact: false,
    });
  });
});
