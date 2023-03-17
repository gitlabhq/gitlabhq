import { GlSprintf, GlModal } from '@gitlab/ui';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import mockGetJobArtifactsResponse from 'test_fixtures/graphql/artifacts/graphql/queries/get_job_artifacts.query.graphql.json';
import createMockApollo from 'helpers/mock_apollo_helper';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import ArtifactsBulkDelete from '~/artifacts/components/artifacts_bulk_delete.vue';
import bulkDestroyArtifactsMutation from '~/artifacts/graphql/mutations/bulk_destroy_job_artifacts.mutation.graphql';

Vue.use(VueApollo);

describe('ArtifactsBulkDelete component', () => {
  let wrapper;
  let requestHandlers;

  const projectId = '123';
  const selectedArtifacts = [
    mockGetJobArtifactsResponse.data.project.jobs.nodes[0].artifacts.nodes[0].id,
    mockGetJobArtifactsResponse.data.project.jobs.nodes[0].artifacts.nodes[1].id,
  ];

  const findText = () => wrapper.findComponent(GlSprintf).text();
  const findDeleteButton = () => wrapper.findByTestId('bulk-delete-delete-button');
  const findClearButton = () => wrapper.findByTestId('bulk-delete-clear-button');
  const findModal = () => wrapper.findComponent(GlModal);

  const createComponent = ({
    handlers = {
      bulkDestroyArtifactsMutation: jest.fn(),
    },
  } = {}) => {
    requestHandlers = handlers;
    wrapper = mountExtended(ArtifactsBulkDelete, {
      apolloProvider: createMockApollo([
        [bulkDestroyArtifactsMutation, requestHandlers.bulkDestroyArtifactsMutation],
      ]),
      propsData: {
        selectedArtifacts,
        queryVariables: {},
        isLoading: false,
        isLastRow: false,
      },
      provide: { projectId },
    });
  };

  describe('selected artifacts box', () => {
    beforeEach(async () => {
      createComponent();
      await waitForPromises();
    });

    it('displays selected artifacts count', () => {
      expect(findText()).toContain(String(selectedArtifacts.length));
    });

    it('opens the confirmation modal when the delete button is clicked', async () => {
      expect(findModal().props('visible')).toBe(false);

      findDeleteButton().trigger('click');
      await waitForPromises();

      expect(findModal().props('visible')).toBe(true);
    });

    it('emits clearSelectedArtifacts event when the clear button is clicked', () => {
      findClearButton().trigger('click');

      expect(wrapper.emitted('clearSelectedArtifacts')).toBeDefined();
    });
  });

  describe('bulk delete confirmation modal', () => {
    beforeEach(async () => {
      createComponent();
      findDeleteButton().trigger('click');
      await waitForPromises();
    });

    it('calls the bulk delete mutation with the selected artifacts on confirm', () => {
      findModal().vm.$emit('primary');

      expect(requestHandlers.bulkDestroyArtifactsMutation).toHaveBeenCalledWith({
        projectId: `gid://gitlab/Project/${projectId}`,
        ids: selectedArtifacts,
      });
    });

    it('does not call the bulk delete mutation on cancel', () => {
      findModal().vm.$emit('cancel');

      expect(requestHandlers.bulkDestroyArtifactsMutation).not.toHaveBeenCalled();
    });
  });
});
