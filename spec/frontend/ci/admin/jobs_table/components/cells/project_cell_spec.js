import { set } from 'lodash';
import { shallowMount } from '@vue/test-utils';
import ProjectCell from '~/ci/admin/jobs_table/components/cells/project_cell.vue';
import { mockAllJobsNodes } from 'jest/ci/jobs_mock_data';
import LinkCell from '~/ci/runner/components/cells/link_cell.vue';

const mockJob = mockAllJobsNodes[0];

describe('Project cell', () => {
  let wrapper;

  const findProjectLink = () => wrapper.findComponent(LinkCell);

  const createComponent = (props = {}) => {
    wrapper = shallowMount(ProjectCell, {
      propsData: {
        ...props,
      },
    });
  };

  describe('Project Link', () => {
    const projectFullPath = mockJob.pipeline.project.fullPath;

    beforeEach(() => {
      createComponent({ job: mockJob });
    });

    it("renders a LinkCell with href set to the project's webUrl", () => {
      expect(findProjectLink().text()).toBe(projectFullPath);
      expect(findProjectLink().props('href')).toBe(mockJob.pipeline.project.webUrl);
    });

    describe('when URL of the project is not available', () => {
      beforeEach(() => {
        set(mockJob, ['pipeline', 'project', 'webUrl'], null);

        createComponent({ job: mockJob });
      });

      it('renders a LinkCell with href set to null', () => {
        expect(findProjectLink().text()).toBe(projectFullPath);
        expect(findProjectLink().props('href')).toBe(null);
      });
    });
  });
});
