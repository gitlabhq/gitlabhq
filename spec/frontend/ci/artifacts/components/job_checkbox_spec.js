import { GlFormCheckbox } from '@gitlab/ui';
import mockGetJobArtifactsResponse from 'test_fixtures/graphql/ci/artifacts/graphql/queries/get_job_artifacts.query.graphql.json';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import JobCheckbox from '~/ci/artifacts/components/job_checkbox.vue';
import { I18N_BULK_DELETE_MAX_SELECTED } from '~/ci/artifacts/constants';

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
    isSelectedArtifactsLimitReached = false,
  } = {}) => {
    wrapper = shallowMountExtended(JobCheckbox, {
      propsData: {
        hasArtifacts,
        selectedArtifacts,
        unselectedArtifacts,
        isSelectedArtifactsLimitReached,
      },
      mocks: { GlFormCheckbox },
    });
  };

  it('is disabled when the job has no artifacts', () => {
    createComponent({ hasArtifacts: false });

    expect(findCheckbox().attributes('disabled')).toBeDefined();
  });

  describe('when some artifacts from this job are selected', () => {
    describe('when the selected artifacts limit has not been reached', () => {
      beforeEach(() => {
        createComponent();
      });

      it('is indeterminate', () => {
        expect(findCheckbox().attributes('indeterminate')).toBe('true');
        expect(findCheckbox().attributes('checked')).toBeUndefined();
      });

      it('selects the unselected artifacts on click', () => {
        findCheckbox().vm.$emit('change', true);

        expect(wrapper.emitted('selectArtifact')).toMatchObject([
          [mockUnselectedArtifacts[0], true],
        ]);
      });
    });

    describe('when the selected artifacts limit has been reached', () => {
      beforeEach(() => {
        // limit has been reached by selecting artifacts from this job
        createComponent({
          selectedArtifacts: mockSelectedArtifacts,
          isSelectedArtifactsLimitReached: true,
        });
      });

      it('remains enabled', () => {
        // job checkbox remains enabled to allow de-selection
        expect(findCheckbox().attributes('disabled')).toBeUndefined();
        expect(findCheckbox().attributes('title')).not.toBe(I18N_BULK_DELETE_MAX_SELECTED);
      });
    });
  });

  describe('when all artifacts from this job are selected', () => {
    beforeEach(() => {
      createComponent({ unselectedArtifacts: [] });
    });

    it('is checked', () => {
      expect(findCheckbox().attributes('checked')).toBe('true');
    });

    it('deselects the selected artifacts on click', () => {
      findCheckbox().vm.$emit('change', false);

      expect(wrapper.emitted('selectArtifact')).toMatchObject([
        [mockSelectedArtifacts[0], false],
        [mockSelectedArtifacts[1], false],
      ]);
    });
  });

  describe('when no artifacts from this job are selected', () => {
    describe('when the selected artifacts limit has not been reached', () => {
      beforeEach(() => {
        createComponent({ selectedArtifacts: [] });
      });

      it('is enabled and not checked', () => {
        expect(findCheckbox().attributes('checked')).toBeUndefined();
        expect(findCheckbox().attributes('disabled')).toBeUndefined();
        expect(findCheckbox().attributes('title')).toBe('');
      });

      it('selects the artifacts on click', () => {
        findCheckbox().vm.$emit('change', true);

        expect(wrapper.emitted('selectArtifact')).toMatchObject([
          [mockUnselectedArtifacts[0], true],
        ]);
      });
    });

    describe('when the selected artifacts limit has been reached', () => {
      beforeEach(() => {
        // limit has been reached by selecting artifacts from other jobs
        createComponent({
          selectedArtifacts: [],
          isSelectedArtifactsLimitReached: true,
        });
      });

      it('is disabled when the selected artifacts limit has been reached', () => {
        // job checkbox is disabled to block further selection
        expect(findCheckbox().attributes('disabled')).toBeDefined();
        expect(findCheckbox().attributes('title')).toBe(I18N_BULK_DELETE_MAX_SELECTED);
      });
    });
  });
});
