import { GlToggle, GlLink } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import waitForPromises from 'helpers/wait_for_promises';
import createMockApollo from 'helpers/mock_apollo_helper';
import UpdateKeepLatestArtifactProjectSetting from '~/artifacts_settings/graphql/mutations/update_keep_latest_artifact_project_setting.mutation.graphql';
import GetKeepLatestArtifactApplicationSetting from '~/artifacts_settings/graphql/queries/get_keep_latest_artifact_application_setting.query.graphql';
import GetKeepLatestArtifactProjectSetting from '~/artifacts_settings/graphql/queries/get_keep_latest_artifact_project_setting.query.graphql';
import KeepLatestArtifactToggle from '~/artifacts_settings/keep_latest_artifact_toggle.vue';

Vue.use(VueApollo);

const keepLatestArtifactProjectMock = {
  data: {
    project: {
      id: '1',
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
  data: {
    projectCiCdSettingsUpdate: { errors: [], __typename: 'ProjectCiCdSettingsUpdatePayload' },
  },
};

describe('Keep latest artifact toggle', () => {
  let wrapper;
  let apolloProvider;
  let requestHandlers;

  const fullPath = 'gitlab-org/gitlab';
  const helpPagePath = '/help/ci/pipelines/job_artifacts';

  const findToggle = () => wrapper.findComponent(GlToggle);
  const findHelpLink = () => wrapper.findComponent(GlLink);

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

    wrapper = shallowMount(KeepLatestArtifactToggle, {
      provide: {
        fullPath,
        helpPagePath,
      },
      stubs: {
        GlToggle,
      },
      apolloProvider,
    });
  };

  afterEach(() => {
    apolloProvider = null;
  });

  describe('default', () => {
    beforeEach(() => {
      createComponent();
    });

    it('displays the toggle and the help link', () => {
      expect(findToggle().exists()).toBe(true);
      expect(findHelpLink().exists()).toBe(true);
    });

    it('calls mutation on artifact setting change with correct payload', () => {
      findToggle().vm.$emit('change', false);

      expect(requestHandlers.keepLatestArtifactMutationHandler).toHaveBeenCalledWith({
        fullPath,
        keepLatestArtifact: false,
      });
    });
  });

  describe('when application keep latest artifact setting is enabled', () => {
    beforeEach(async () => {
      createComponent();
      await waitForPromises();
    });

    it('sets correct setting value in toggle with query result', () => {
      expect(findToggle().props().value).toBe(
        keepLatestArtifactProjectMock.data.project.ciCdSettings.keepLatestArtifact,
      );
    });

    it('toggle is enabled when application setting is enabled', () => {
      expect(findToggle().attributes('disabled')).toBeUndefined();
    });
  });
});
