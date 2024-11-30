import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import { GlModal } from '@gitlab/ui';
import { createAlert } from '~/alert';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { stubComponent, RENDER_ALL_SLOTS_TEMPLATE } from 'helpers/stub_component';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import KeepAllAsPlaceholderModal from '~/members/placeholders/components/keep_all_as_placeholder_modal.vue';

import importSourceUsersQuery from '~/members/placeholders/graphql/queries/import_source_users.query.graphql';
import importSourceUserKeepAllAsPlaceholderMutation from '~/members/placeholders/graphql/mutations/keep_all_as_placeholder.mutation.graphql';

import {
  mockSourceUsersQueryResponse,
  mockKeepAllAsPlaceholderMutationResponse,
} from '../mock_data';

Vue.use(VueApollo);
jest.mock('~/alert');

describe('KeepAllAsPlaceholderModal', () => {
  let wrapper;
  let mockApollo;

  const sourceUsersQueryHandler = jest.fn().mockResolvedValue(mockSourceUsersQueryResponse());
  const defaultKeepAllAsPlaceholderMutationHandler = jest
    .fn()
    .mockResolvedValue(mockKeepAllAsPlaceholderMutationResponse);

  const findGlModal = () => wrapper.findComponent(GlModal);

  const createComponent = ({
    keepAllAsPlaceholderMutationHandler = defaultKeepAllAsPlaceholderMutationHandler,
  } = {}) => {
    mockApollo = createMockApollo([
      [importSourceUsersQuery, sourceUsersQueryHandler],
      [importSourceUserKeepAllAsPlaceholderMutation, keepAllAsPlaceholderMutationHandler],
    ]);

    mockApollo.clients.defaultClient
      .watchQuery({
        query: importSourceUsersQuery,
        variables: { fullPath: 'test' },
      })
      .subscribe();

    wrapper = shallowMountExtended(KeepAllAsPlaceholderModal, {
      apolloProvider: mockApollo,
      propsData: {
        modalId: 'keep-all-as-placeholder-modal',
        groupId: 1,
      },
      stubs: {
        GlModal: stubComponent(GlModal, {
          template: RENDER_ALL_SLOTS_TEMPLATE,
          methods: {
            hide: jest.fn(),
          },
        }),
      },
    });
  };

  describe('when primary button is clicked', () => {
    beforeEach(async () => {
      createComponent();
      findGlModal().vm.$emit('primary');
      await nextTick();
    });

    it('calls keepAllAsPlaceholder mutation', async () => {
      await waitForPromises();

      expect(defaultKeepAllAsPlaceholderMutationHandler).toHaveBeenCalledWith({
        namespaceId: 'gid://gitlab/Group/1',
      });
    });

    it('emits "confirm" event', async () => {
      await waitForPromises();
      expect(wrapper.emitted('confirm')[0]).toEqual([1]);
    });
  });

  describe('when the mutation fails', () => {
    beforeEach(async () => {
      const failedKeepAllAsPlaceholderMutationHandler = jest
        .fn()
        .mockRejectedValue(new Error('GraphQL error'));

      createComponent({
        keepAllAsPlaceholderMutationHandler: failedKeepAllAsPlaceholderMutationHandler,
      });

      findGlModal().vm.$emit('primary');
      await nextTick();
    });

    it('creates an alert', async () => {
      await waitForPromises();
      expect(createAlert).toHaveBeenCalledWith({
        message: 'Keeping all as placeholders could not be done.',
      });
    });
  });
});
