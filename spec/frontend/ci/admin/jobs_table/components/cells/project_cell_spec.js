import { GlLink } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import ProjectCell from '~/ci/admin/jobs_table/components/cells/project_cell.vue';
import { mockAllJobsNodes } from 'jest/ci/jobs_mock_data';

const mockJob = mockAllJobsNodes[0];

describe('Project cell', () => {
  let wrapper;

  const findProjectLink = () => wrapper.findComponent(GlLink);

  const createComponent = (props = {}) => {
    wrapper = shallowMount(ProjectCell, {
      propsData: {
        ...props,
      },
    });
  };

  describe('Project Link', () => {
    beforeEach(() => {
      createComponent({ job: mockJob });
    });

    it('shows and links to the project', () => {
      expect(findProjectLink().exists()).toBe(true);
      expect(findProjectLink().text()).toBe(mockJob.pipeline.project.fullPath);
      expect(findProjectLink().attributes('href')).toBe(mockJob.pipeline.project.webUrl);
    });
  });
});
