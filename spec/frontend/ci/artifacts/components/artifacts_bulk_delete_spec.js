import { GlSprintf } from '@gitlab/ui';
import mockGetJobArtifactsResponse from 'test_fixtures/graphql/ci/artifacts/graphql/queries/get_job_artifacts.query.graphql.json';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import ArtifactsBulkDelete from '~/ci/artifacts/components/artifacts_bulk_delete.vue';

describe('ArtifactsBulkDelete component', () => {
  let wrapper;

  const selectedArtifacts = [
    mockGetJobArtifactsResponse.data.project.jobs.nodes[0].artifacts.nodes[0].id,
    mockGetJobArtifactsResponse.data.project.jobs.nodes[0].artifacts.nodes[1].id,
  ];

  const findText = () => wrapper.findComponent(GlSprintf).text();
  const findDeleteButton = () => wrapper.findByTestId('bulk-delete-delete-button');
  const findClearButton = () => wrapper.findByTestId('bulk-delete-clear-button');

  const createComponent = () => {
    wrapper = shallowMountExtended(ArtifactsBulkDelete, {
      propsData: {
        selectedArtifacts,
      },
      stubs: { GlSprintf },
    });
  };

  describe('selected artifacts box', () => {
    beforeEach(() => {
      createComponent();
    });

    it('displays selected artifacts count', () => {
      expect(findText()).toContain(String(selectedArtifacts.length));
    });

    it('emits showBulkDeleteModal event when the delete button is clicked', () => {
      findDeleteButton().vm.$emit('click');

      expect(wrapper.emitted('showBulkDeleteModal')).toBeDefined();
    });

    it('emits clearSelectedArtifacts event when the clear button is clicked', () => {
      findClearButton().vm.$emit('click');

      expect(wrapper.emitted('clearSelectedArtifacts')).toBeDefined();
    });
  });
});
