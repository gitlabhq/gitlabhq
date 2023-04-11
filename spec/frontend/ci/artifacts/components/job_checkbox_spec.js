import { GlFormCheckbox } from '@gitlab/ui';
import mockGetJobArtifactsResponse from 'test_fixtures/graphql/ci/artifacts/graphql/queries/get_job_artifacts.query.graphql.json';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import JobCheckbox from '~/ci/artifacts/components/job_checkbox.vue';

describe('JobCheckbox component', () => {
  let wrapper;

  const mockArtifactNodes = mockGetJobArtifactsResponse.data.project.jobs.nodes[0].artifacts.nodes;
  const mockSelectedArtifacts = [mockArtifactNodes[0], mockArtifactNodes[1]];
  const mockUnselectedArtifacts = [mockArtifactNodes[2]];

  const findCheckbox = () => wrapper.findComponent(GlFormCheckbox);

  const createComponent = ({
    hasArtifacts = true,
    selectedArtifacts = mockSelectedArtifacts,
    unselectedArtifacts = mockUnselectedArtifacts,
  } = {}) => {
    wrapper = shallowMountExtended(JobCheckbox, {
      propsData: {
        hasArtifacts,
        selectedArtifacts,
        unselectedArtifacts,
      },
      mocks: { GlFormCheckbox },
    });
  };

  it('is disabled when the job has no artifacts', () => {
    createComponent({ hasArtifacts: false });

    expect(findCheckbox().attributes('disabled')).toBe('true');
  });

  describe('when some artifacts are selected', () => {
    beforeEach(() => {
      createComponent();
    });

    it('is indeterminate', () => {
      expect(findCheckbox().attributes('indeterminate')).toBe('true');
      expect(findCheckbox().attributes('checked')).toBeUndefined();
    });

    it('selects the unselected artifacts on click', () => {
      findCheckbox().vm.$emit('input', true);

      expect(wrapper.emitted('selectArtifact')).toMatchObject([[mockUnselectedArtifacts[0], true]]);
    });
  });

  describe('when all artifacts are selected', () => {
    beforeEach(() => {
      createComponent({ unselectedArtifacts: [] });
    });

    it('is checked', () => {
      expect(findCheckbox().attributes('checked')).toBe('true');
    });

    it('deselects the selected artifacts on click', () => {
      findCheckbox().vm.$emit('input', false);

      expect(wrapper.emitted('selectArtifact')).toMatchObject([
        [mockSelectedArtifacts[0], false],
        [mockSelectedArtifacts[1], false],
      ]);
    });
  });
});
