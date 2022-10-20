import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import getJobArtifactsResponse from 'test_fixtures/graphql/artifacts/graphql/queries/get_job_artifacts.query.graphql.json';
import waitForPromises from 'helpers/wait_for_promises';
import ArtifactsTableRowDetails from '~/artifacts/components/artifacts_table_row_details.vue';
import ArtifactRow from '~/artifacts/components/artifact_row.vue';
import createMockApollo from 'helpers/mock_apollo_helper';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import destroyArtifactMutation from '~/artifacts/graphql/mutations/destroy_artifact.mutation.graphql';
import { I18N_DESTROY_ERROR } from '~/artifacts/constants';
import { createAlert } from '~/flash';

jest.mock('~/flash');

const { artifacts } = getJobArtifactsResponse.data.project.jobs.nodes[0];
const refetchArtifacts = jest.fn();

Vue.use(VueApollo);

describe('ArtifactsTableRowDetails component', () => {
  let wrapper;
  let requestHandlers;

  const createComponent = (
    handlers = {
      destroyArtifactMutation: jest.fn(),
    },
  ) => {
    requestHandlers = handlers;
    wrapper = mountExtended(ArtifactsTableRowDetails, {
      apolloProvider: createMockApollo([
        [destroyArtifactMutation, requestHandlers.destroyArtifactMutation],
      ]),
      propsData: {
        artifacts,
        refetchArtifacts,
        queryVariables: {},
      },
      data() {
        return { deletingArtifactId: null };
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  describe('passes correct props', () => {
    beforeEach(() => {
      createComponent();
    });

    it('to the artifact rows', () => {
      [0, 1, 2].forEach((index) => {
        expect(wrapper.findAllComponents(ArtifactRow).at(index).props()).toMatchObject({
          artifact: artifacts.nodes[index],
          isLoading: false,
        });
      });
    });
  });

  describe('when an artifact row emits the delete event', () => {
    it('sets isLoading to true for that row', async () => {
      createComponent();
      await waitForPromises();

      wrapper.findComponent(ArtifactRow).vm.$emit('delete');

      await nextTick();

      [
        { index: 0, expectedLoading: true },
        { index: 1, expectedLoading: false },
      ].forEach(({ index, expectedLoading }) => {
        expect(wrapper.findAllComponents(ArtifactRow).at(index).props('isLoading')).toBe(
          expectedLoading,
        );
      });
    });

    it('triggers the destroyArtifact GraphQL mutation', async () => {
      createComponent();
      await waitForPromises();

      wrapper.findComponent(ArtifactRow).vm.$emit('delete');

      expect(requestHandlers.destroyArtifactMutation).toHaveBeenCalled();
    });

    it('displays a flash message and refetches artifacts when the mutation fails', async () => {
      createComponent({
        destroyArtifactMutation: jest.fn().mockRejectedValue(new Error('Error!')),
      });
      await waitForPromises();

      expect(wrapper.emitted('refetch')).toBeUndefined();

      wrapper.findComponent(ArtifactRow).vm.$emit('delete');
      await waitForPromises();

      expect(createAlert).toHaveBeenCalledWith({ message: I18N_DESTROY_ERROR });
      expect(wrapper.emitted('refetch')).toBeDefined();
    });
  });
});
