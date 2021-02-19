import { GlFormCheckbox, GlLink } from '@gitlab/ui';
import { shallowMount, createLocalVue } from '@vue/test-utils';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import UpdateKeepLatestArtifactProjectSetting from '~/artifacts_settings/graphql/mutations/update_keep_latest_artifact_project_setting.mutation.graphql';
import GetKeepLatestArtifactApplicationSetting from '~/artifacts_settings/graphql/queries/get_keep_latest_artifact_application_setting.query.graphql';
import GetKeepLatestArtifactProjectSetting from '~/artifacts_settings/graphql/queries/get_keep_latest_artifact_project_setting.query.graphql';
import KeepLatestArtifactCheckbox from '~/artifacts_settings/keep_latest_artifact_checkbox.vue';

const localVue = createLocalVue();
localVue.use(VueApollo);

const keepLatestArtifactProjectMock = {
  data: {
    project: {
      ciCdSettings: { keepLatestArtifact: true },
    },
  },
};

const keepLatestArtifactApplicationMock = {
  data: {
    ciApplicationSettings: {
      keepLatestArtifact: true,
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
      keepLatestArtifactProjectQueryHandler: jest
        .fn()
        .mockResolvedValue(keepLatestArtifactProjectMock),
      keepLatestArtifactApplicationQueryHandler: jest
        .fn()
        .mockResolvedValue(keepLatestArtifactApplicationMock),
      keepLatestArtifactMutationHandler: jest
        .fn()
        .mockResolvedValue(keepLatestArtifactMockResponse),
      ...handlers,
    };

    apolloProvider = createMockApollo([
      [GetKeepLatestArtifactProjectSetting, requestHandlers.keepLatestArtifactProjectQueryHandler],
      [
        GetKeepLatestArtifactApplicationSetting,
        requestHandlers.keepLatestArtifactApplicationQueryHandler,
      ],
      [UpdateKeepLatestArtifactProjectSetting, requestHandlers.keepLatestArtifactMutationHandler],
    ]);

    wrapper = shallowMount(KeepLatestArtifactCheckbox, {
      provide: {
        fullPath,
        helpPagePath,
      },
      stubs: {
        GlFormCheckbox,
      },
      localVue,
      apolloProvider,
    });
  };

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
    apolloProvider = null;
  });

  describe('default', () => {
    beforeEach(() => {
      createComponent();
    });

    it('displays the checkbox and the help link', () => {
      expect(findCheckbox().exists()).toBe(true);
      expect(findHelpLink().exists()).toBe(true);
    });

    it('calls mutation on artifact setting change with correct payload', () => {
      findCheckbox().vm.$emit('change', false);

      expect(requestHandlers.keepLatestArtifactMutationHandler).toHaveBeenCalledWith({
        fullPath,
        keepLatestArtifact: false,
      });
    });
  });

  describe('when application keep latest artifact setting is enabled', () => {
    beforeEach(() => {
      createComponent();
    });

    it('sets correct setting value in checkbox with query result', async () => {
      await wrapper.vm.$nextTick();

      expect(wrapper.element).toMatchSnapshot();
    });

    it('checkbox is enabled when application setting is enabled', async () => {
      await wrapper.vm.$nextTick();

      expect(findCheckbox().attributes('disabled')).toBeUndefined();
    });
  });
});
