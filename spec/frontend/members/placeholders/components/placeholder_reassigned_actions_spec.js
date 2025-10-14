import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import { GlAvatarLabeled } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import PlaceholderReassignedActions from '~/members/placeholders/components/placeholder_reassigned_actions.vue';
import importSourceUserUndoKeepAsPlaceholderMutation from '~/members/placeholders/graphql/mutations/undo_keep_as_placeholder.mutation.graphql';

import { mockSourceUsers, mockUndoKeepAsPlaceholderMutationResponse } from '../mock_data';

Vue.use(VueApollo);

describe('PlaceholderReassignedActions', () => {
  let wrapper;
  let mockApollo;

  const undoKeepAsPlaceholderMutationHandler = jest
    .fn()
    .mockResolvedValue(mockUndoKeepAsPlaceholderMutationResponse);

  const createComponent = ({ props = {}, provide = {} } = {}) => {
    mockApollo = createMockApollo([
      [importSourceUserUndoKeepAsPlaceholderMutation, undoKeepAsPlaceholderMutationHandler],
    ]);
    wrapper = shallowMountExtended(PlaceholderReassignedActions, {
      apolloProvider: mockApollo,
      propsData: {
        ...props,
      },
      provide: {
        ...provide,
      },
    });
  };

  const findUndoButton = () => wrapper.findByTestId('undo-button');
  const findAvatar = () =>
    wrapper.findByTestId('placeholder-reassigned').findComponent(GlAvatarLabeled);

  describe('when status is KEEP_AS_PLACEHOLDER', () => {
    const mockSourceUser = mockSourceUsers[5];

    beforeEach(() => {
      createComponent({
        props: {
          sourceUser: {
            ...mockSourceUser,
            status: 'KEEP_AS_PLACEHOLDER',
          },
        },
      });
    });

    it('renders avatar with placeholderUser data', () => {
      expect(findAvatar().props('label')).toBe(mockSourceUser.placeholderUser.name);
    });

    it('renders Undo button', () => {
      expect(findUndoButton().exists()).toBe(true);
    });

    describe('when Undo button is clicked', () => {
      beforeEach(async () => {
        findUndoButton().vm.$emit('click');
        await nextTick();
      });

      it('calls undoKeepAsPlaceholder mutation', async () => {
        expect(findUndoButton().props('loading')).toBe(true);
        await waitForPromises();
        expect(findUndoButton().props('loading')).toBe(false);

        expect(undoKeepAsPlaceholderMutationHandler).toHaveBeenCalledWith({
          id: mockSourceUser.id,
        });
      });
    });
  });

  describe('when status is COMPLETED', () => {
    const mockSourceUser = mockSourceUsers[6];

    beforeEach(() => {
      createComponent({
        props: {
          sourceUser: {
            ...mockSourceUser,
            status: 'COMPLETED',
          },
        },
      });
    });

    it('renders avatar with reassignToUser data', () => {
      expect(findAvatar().props('label')).toBe(mockSourceUser.reassignToUser.name);
    });

    it('does not renders Undo button', () => {
      expect(findUndoButton().exists()).toBe(false);
    });
  });
});
