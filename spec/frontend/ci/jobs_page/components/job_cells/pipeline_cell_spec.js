import { GlAvatar } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import PipelineCell from '~/ci/jobs_page/components/job_cells/pipeline_cell.vue';

const mockJobWithoutUser = {
  id: 'gid://gitlab/Ci::Build/2264',
  pipeline: {
    id: 'gid://gitlab/Ci::Pipeline/460',
    path: '/root/ci-project/-/pipelines/460',
  },
};

const mockJobWithUser = {
  id: 'gid://gitlab/Ci::Build/2264',
  pipeline: {
    id: 'gid://gitlab/Ci::Pipeline/460',
    path: '/root/ci-project/-/pipelines/460',
    user: {
      avatarUrl:
        'https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon',
      webPath: '/root',
    },
  },
};

describe('Pipeline Cell', () => {
  let wrapper;

  const findPipelineId = () => wrapper.findByTestId('pipeline-id');
  const findPipelineUserLink = () => wrapper.findByTestId('pipeline-user-link');
  const findUserAvatar = () => wrapper.findComponent(GlAvatar);

  const createComponent = (props = mockJobWithUser) => {
    wrapper = extendedWrapper(
      shallowMount(PipelineCell, {
        propsData: {
          job: props,
        },
      }),
    );
  };

  describe('Pipeline Id', () => {
    beforeEach(() => {
      createComponent();
    });

    it('displays the pipeline id and links to the pipeline', () => {
      const expectedPipelineId = `#${getIdFromGraphQLId(mockJobWithUser.pipeline.id)}`;

      expect(findPipelineId().text()).toBe(expectedPipelineId);
      expect(findPipelineId().attributes('href')).toBe(mockJobWithUser.pipeline.path);
    });
  });

  describe('Pipeline created by', () => {
    const apiWrapperText = 'API';

    it('shows and links to the pipeline user', () => {
      createComponent();

      expect(findPipelineUserLink().exists()).toBe(true);
      expect(findPipelineUserLink().attributes('href')).toBe(mockJobWithUser.pipeline.user.webPath);
      expect(findUserAvatar().attributes('src')).toBe(mockJobWithUser.pipeline.user.avatarUrl);
      expect(wrapper.text()).not.toContain(apiWrapperText);
    });

    it('shows pipeline was created by the API', () => {
      createComponent(mockJobWithoutUser);

      expect(findPipelineUserLink().exists()).toBe(false);
      expect(findUserAvatar().exists()).toBe(false);
      expect(wrapper.text()).toContain(apiWrapperText);
    });
  });
});
