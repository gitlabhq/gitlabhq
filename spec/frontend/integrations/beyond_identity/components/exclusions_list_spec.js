import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { GlEmptyState, GlKeysetPagination } from '@gitlab/ui';
import { createAlert } from '~/alert';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import fetchExclusions from '~/integrations/beyond_identity/graphql/queries/beyond_identity_exclusions.query.graphql';
import createExclusion from '~/integrations/beyond_identity/graphql/mutations/create_beyond_identity_exclusion.mutation.graphql';
import deleteExclusion from '~/integrations/beyond_identity/graphql/mutations/delete_beyond_identity_exclusion.mutation.graphql';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import ExclusionsList from '~/integrations/beyond_identity/components/exclusions_list.vue';
import AddExclusionsDrawer from '~/integrations/beyond_identity/components/add_exclusions_drawer.vue';
import ExclusionsTabs from '~/integrations/beyond_identity/components/exclusions_tabs.vue';
import ExclusionsListItem from '~/integrations/beyond_identity/components/exclusions_list_item.vue';
import ConfirmRemovalModal from '~/integrations/beyond_identity/components/remove_exclusion_confirmation_modal.vue';
import showToast from '~/vue_shared/plugins/global_toast';
import {
  projectExclusionsMock,
  groupExclusionsMock,
  fetchExclusionsResponse,
  createExclusionMutationResponse,
  deleteExclusionMutationResponse,
} from './mock_data';

Vue.use(VueApollo);

jest.mock('~/vue_shared/plugins/global_toast');
jest.mock('~/alert');

describe('ExclusionsList component', () => {
  let wrapper;
  let fakeApollo;

  const findTabs = () => wrapper.findComponent(ExclusionsTabs);
  const findListItems = () => wrapper.findAllComponents(ExclusionsListItem);
  const findPagination = () => wrapper.findComponent(GlKeysetPagination);
  const findConfirmRemoveModal = () => wrapper.findComponent(ConfirmRemovalModal);
  const findByText = (text) => wrapper.findByText(text);
  const findAddExclusionsButton = () => wrapper.findByTestId('add-exclusions-btn');
  const findEmptyState = () => wrapper.findComponent(GlEmptyState);
  const findDrawer = () => wrapper.findComponent(AddExclusionsDrawer);

  const fetchExclusionsSuccessHandler = jest.fn().mockResolvedValue(fetchExclusionsResponse);
  const createMutationMock = jest.fn().mockResolvedValue(createExclusionMutationResponse);
  const deleteMutationMock = jest.fn().mockResolvedValue(deleteExclusionMutationResponse);

  const createComponent = ({
    querySuccessHandler = fetchExclusionsSuccessHandler,
    createSuccessHandler = createMutationMock,
    deleteSuccessHandler = deleteMutationMock,
  } = {}) => {
    fakeApollo = createMockApollo([
      [fetchExclusions, querySuccessHandler],
      [createExclusion, createSuccessHandler],
      [deleteExclusion, deleteSuccessHandler],
    ]);
    wrapper = shallowMountExtended(ExclusionsList, { apolloProvider: fakeApollo });
  };

  beforeEach(async () => {
    createComponent();

    await waitForPromises();
  });

  describe('default behavior', () => {
    it('renders tabs', () => {
      expect(findTabs().exists()).toBe(true);
    });

    it('renders help text', () => {
      expect(
        findByText(
          'Groups and projects in this list no longer require commits to be signed.',
        ).exists(),
      ).toBe(true);
    });

    it('renders an Add exclusions button', () => {
      expect(findAddExclusionsButton().exists()).toBe(true);
    });

    it('renders an Empty state', async () => {
      createComponent({ querySuccessHandler: jest.fn().mockResolvedValue([]) });

      await waitForPromises();

      expect(findEmptyState().props('title')).toBe('There are no exclusions');
    });

    it('does not render an open drawer', () => {
      expect(findDrawer().props('isOpen')).toBe(false);
    });

    it('does not render pagination by default', () => {
      expect(findPagination().exists()).toBe(false);
    });

    describe('pagination', () => {
      beforeEach(() => {
        createComponent({
          querySuccessHandler: jest.fn().mockResolvedValue({
            data: {
              integrationExclusions: {
                nodes: [],
                pageInfo: {
                  __typename: 'PageInfo',
                  startCursor: '12345',
                  endCursor: '6789',
                  hasNextPage: true,
                  hasPreviousPage: true,
                },
              },
            },
          }),
        });
      });

      it('does not render pagination while loading', () => {
        expect(findPagination().exists()).toBe(false);
      });

      it('renders pagination when done loading', async () => {
        await waitForPromises();

        expect(findPagination().exists()).toBe(true);
      });
    });

    it('renders an error when fetching exclusions fail', async () => {
      const error = new Error('Network error!');
      createComponent({ querySuccessHandler: jest.fn().mockRejectedValue({ error }) });

      await waitForPromises();

      expect(createAlert).toHaveBeenCalledWith({
        message: 'Failed to fetch the exclusions. Try refreshing the page.',
      });
    });
  });

  describe('adding Exclusions (success)', () => {
    beforeEach(() => findAddExclusionsButton().vm.$emit('click'));

    it('opens a drawer', () => {
      expect(findDrawer().props('isOpen')).toBe(true);
    });

    describe('Exclusions added', () => {
      beforeEach(async () => {
        findDrawer().vm.$emit('add', [...projectExclusionsMock, ...groupExclusionsMock]);
        await waitForPromises();
      });

      it('calls a GraphQL mutation to add the exclusions', () => {
        expect(createMutationMock).toHaveBeenCalledWith({
          input: {
            integrationName: 'BEYOND_IDENTITY',
            projectIds: ['gid://gitlab/Project/1', 'gid://gitlab/Project/2'],
            groupIds: ['gid://gitlab/Group/1', 'gid://gitlab/Group/2'],
          },
        });
      });

      it('closes the drawer', () => {
        expect(findDrawer().props('isOpen')).toBe(false);
      });

      it('re-fetches the list of exclusions', () => {
        expect(fetchExclusionsSuccessHandler).toHaveBeenCalledTimes(2);
      });
    });

    describe('Error handling', () => {
      beforeEach(async () => {
        const response = {
          data: {
            integrationExclusionCreate: {
              ...createExclusionMutationResponse.data.integrationExclusionCreate,
              errors: ['some error'],
            },
          },
        };

        createComponent({ createSuccessHandler: jest.fn().mockResolvedValue(response) });
        findDrawer().vm.$emit('add', projectExclusionsMock);
        await waitForPromises();
      });

      it('closes the drawer', () => {
        expect(findDrawer().props('isOpen')).toBe(false);
      });

      it('renders an error', () => {
        expect(createAlert).toHaveBeenCalledWith({
          message: 'Failed to add the exclusion. Try adding it again.',
        });
      });
    });
  });

  describe.each`
    exclusionIndex | type         | name             | mutationPayload                                             | successMessage
    ${1}           | ${'project'} | ${'project bar'} | ${{ projectIds: ['gid://gitlab/Project/2'], groupIds: [] }} | ${'Project exclusion removed'}
    ${2}           | ${'group'}   | ${'group foo'}   | ${{ projectIds: [], groupIds: ['gid://gitlab/Group/2'] }}   | ${'Group exclusion removed'}
  `(
    'removes $type exclusion',
    ({ exclusionIndex, type, name, mutationPayload, successMessage }) => {
      beforeEach(() => {
        findListItems().at(exclusionIndex).vm.$emit('remove');
      });

      it('opens a confirmation modal', () => {
        expect(findConfirmRemoveModal().props()).toMatchObject({
          name,
          type,
          visible: true,
        });
      });

      describe('confirmation modal primary action', () => {
        beforeEach(async () => {
          findConfirmRemoveModal().vm.$emit('primary');
          await waitForPromises();
        });

        it('calls a GraphQL mutation to remove the exclusion', () => {
          expect(deleteMutationMock).toHaveBeenCalledWith({
            input: {
              integrationName: 'BEYOND_IDENTITY',
              ...mutationPayload,
            },
          });
        });

        it('renders a toast', () => {
          expect(showToast).toHaveBeenCalledWith(successMessage, {
            action: {
              text: 'Undo',
              onClick: expect.any(Function),
            },
          });
        });
      });

      describe('Error handling', () => {
        beforeEach(async () => {
          const response = {
            data: {
              integrationExclusionDelete: {
                ...deleteExclusionMutationResponse.data.integrationExclusionDelete,
                errors: ['some error'],
              },
            },
          };

          createComponent({ deleteSuccessHandler: jest.fn().mockResolvedValue(response) });
          await waitForPromises();

          findListItems().at(1).vm.$emit('remove');
          await waitForPromises();
          findConfirmRemoveModal().vm.$emit('primary');
          await waitForPromises();
        });

        it('renders an error', () => {
          expect(createAlert).toHaveBeenCalledWith({
            message: 'Failed to remove the exclusion. Try removing it again.',
          });
        });
      });
    },
  );
});
