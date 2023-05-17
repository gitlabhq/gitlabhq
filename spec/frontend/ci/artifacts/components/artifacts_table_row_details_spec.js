import { GlModal } from '@gitlab/ui';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import getJobArtifactsResponse from 'test_fixtures/graphql/ci/artifacts/graphql/queries/get_job_artifacts.query.graphql.json';
import waitForPromises from 'helpers/wait_for_promises';
import ArtifactsTableRowDetails from '~/ci/artifacts/components/artifacts_table_row_details.vue';
import ArtifactRow from '~/ci/artifacts/components/artifact_row.vue';
import ArtifactDeleteModal from '~/ci/artifacts/components/artifact_delete_modal.vue';
import createMockApollo from 'helpers/mock_apollo_helper';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import destroyArtifactMutation from '~/ci/artifacts/graphql/mutations/destroy_artifact.mutation.graphql';
import { I18N_DESTROY_ERROR, I18N_MODAL_TITLE } from '~/ci/artifacts/constants';
import { createAlert } from '~/alert';

jest.mock('~/alert');

const { artifacts } = getJobArtifactsResponse.data.project.jobs.nodes[0];
const refetchArtifacts = jest.fn();

Vue.use(VueApollo);

describe('ArtifactsTableRowDetails component', () => {
  let wrapper;
  let requestHandlers;

  const findModal = () => wrapper.findComponent(GlModal);

  const createComponent = ({
    handlers = {
      destroyArtifactMutation: jest.fn(),
    },
    selectedArtifacts = [],
  } = {}) => {
    requestHandlers = handlers;
    wrapper = mountExtended(ArtifactsTableRowDetails, {
      apolloProvider: createMockApollo([
        [destroyArtifactMutation, requestHandlers.destroyArtifactMutation],
      ]),
      propsData: {
        artifacts,
        selectedArtifacts,
        refetchArtifacts,
        queryVariables: {},
        isSelectedArtifactsLimitReached: false,
      },
      provide: { canDestroyArtifacts: true },
      data() {
        return { deletingArtifactId: null };
      },
    });
  };

  describe('passes correct props', () => {
    beforeEach(() => {
      createComponent();
    });

    it('to the artifact rows', () => {
      [0, 1, 2].forEach((index) => {
        expect(wrapper.findAllComponents(ArtifactRow).at(index).props()).toMatchObject({
          artifact: artifacts.nodes[index],
        });
      });
    });
  });

  describe('when the artifact row emits the delete event', () => {
    it('shows the artifact delete modal', async () => {
      createComponent();
      await waitForPromises();

      expect(findModal().props('visible')).toBe(false);

      await wrapper.findComponent(ArtifactRow).vm.$emit('delete');

      expect(findModal().props('visible')).toBe(true);
      expect(findModal().props('title')).toBe(I18N_MODAL_TITLE(artifacts.nodes[0].name));
    });
  });

  describe('when the artifact delete modal emits its primary event', () => {
    it('triggers the destroyArtifact GraphQL mutation', async () => {
      createComponent();
      await waitForPromises();

      wrapper.findComponent(ArtifactRow).vm.$emit('delete');
      wrapper.findComponent(ArtifactDeleteModal).vm.$emit('primary');

      expect(requestHandlers.destroyArtifactMutation).toHaveBeenCalledWith({
        id: artifacts.nodes[0].id,
      });
    });

    it('displays an alert message and refetches artifacts when the mutation fails', async () => {
      createComponent({
        destroyArtifactMutation: jest.fn().mockRejectedValue(new Error('Error!')),
      });
      await waitForPromises();

      expect(wrapper.emitted('refetch')).toBeUndefined();

      wrapper.findComponent(ArtifactRow).vm.$emit('delete');
      wrapper.findComponent(ArtifactDeleteModal).vm.$emit('primary');
      await waitForPromises();

      expect(createAlert).toHaveBeenCalledWith({ message: I18N_DESTROY_ERROR });
      expect(wrapper.emitted('refetch')).toBeDefined();
    });
  });

  describe('when the artifact delete modal is cancelled', () => {
    it('does not trigger the destroyArtifact GraphQL mutation', async () => {
      createComponent();
      await waitForPromises();

      wrapper.findComponent(ArtifactRow).vm.$emit('delete');
      wrapper.findComponent(ArtifactDeleteModal).vm.$emit('cancel');

      expect(requestHandlers.destroyArtifactMutation).not.toHaveBeenCalled();
    });
  });

  describe('bulk delete selection', () => {
    it('is not selected for unselected artifact', async () => {
      createComponent();
      await waitForPromises();

      expect(wrapper.findAllComponents(ArtifactRow).at(0).props('isSelected')).toBe(false);
    });

    it('is selected for selected artifacts', async () => {
      createComponent({ selectedArtifacts: [artifacts.nodes[0].id] });
      await waitForPromises();

      expect(wrapper.findAllComponents(ArtifactRow).at(0).props('isSelected')).toBe(true);
    });
  });
});
