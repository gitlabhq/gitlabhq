import { GlDrawer, GlLabel, GlModal, GlButton } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { MountingPortal } from 'portal-vue';
import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import { createMockDirective, getBinding } from 'helpers/vue_mock_directive';
import waitForPromises from 'helpers/wait_for_promises';
import { stubComponent } from 'helpers/stub_component';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import BoardSettingsSidebar from '~/boards/components/board_settings_sidebar.vue';
import destroyBoardListMutation from '~/boards/graphql/board_list_destroy.mutation.graphql';
import * as cacheUpdates from '~/boards/graphql/cache_updates';
import { mockLabelList, destroyBoardListMutationResponse } from '../mock_data';

Vue.use(VueApollo);

describe('BoardSettingsSidebar', () => {
  let wrapper;
  let mockApollo;
  const labelTitle = mockLabelList.label.title;
  const labelColor = mockLabelList.label.color;
  const modalID = 'board-settings-sidebar-modal';

  const destroyBoardListMutationHandlerSuccess = jest
    .fn()
    .mockResolvedValue(destroyBoardListMutationResponse);
  const errorMessage = 'Failed to delete list';
  const destroyBoardListMutationHandlerFailure = jest
    .fn()
    .mockRejectedValue(new Error(errorMessage));

  const createComponent = ({
    canAdminList = false,
    list = {},
    destroyBoardListMutationHandler = destroyBoardListMutationHandlerSuccess,
  } = {}) => {
    mockApollo = createMockApollo([[destroyBoardListMutation, destroyBoardListMutationHandler]]);

    wrapper = extendedWrapper(
      shallowMount(BoardSettingsSidebar, {
        apolloProvider: mockApollo,
        provide: {
          canAdminList,
          scopedLabelsAvailable: false,
          isIssueBoard: true,
          boardType: 'group',
          issuableType: 'issue',
        },
        propsData: {
          listId: list.id || '',
          boardId: 'gid://gitlab/Board/1',
          list,
          queryVariables: {},
        },
        directives: {
          GlModal: createMockDirective('gl-modal'),
        },
        stubs: {
          GlDrawer: stubComponent(GlDrawer, {
            template: '<div><slot name="header"></slot><slot></slot></div>',
          }),
        },
      }),
    );

    // Necessary for cache update
    mockApollo.clients.defaultClient.cache.updateQuery = jest.fn();
  };
  const findLabel = () => wrapper.findComponent(GlLabel);
  const findDrawer = () => wrapper.findComponent(GlDrawer);
  const findModal = () => wrapper.findComponent(GlModal);
  const findRemoveButton = () => wrapper.findComponent(GlButton);

  beforeEach(() => {
    cacheUpdates.setError = jest.fn();
  });

  describe('default', () => {
    beforeEach(() => {
      createComponent();
    });
    it('renders a MountingPortal component', () => {
      expect(wrapper.findComponent(MountingPortal).props()).toMatchObject({
        mountTo: '#js-right-sidebar-portal',
        append: true,
        name: 'board-settings-sidebar',
      });
    });

    it('renders a GlDrawer component', () => {
      expect(findDrawer().exists()).toBe(true);
    });

    describe('on close', () => {
      it('closes the sidebar', async () => {
        findDrawer().vm.$emit('close');

        await nextTick();

        expect(wrapper.findComponent(GlDrawer).props('open')).toBe(false);
      });
    });

    describe('when there is no active list', () => {
      it('renders GlDrawer with open false', () => {
        createComponent();

        expect(findDrawer().props('open')).toBe(false);
        expect(findLabel().exists()).toBe(false);
      });
    });

    describe('when there is an active list', () => {
      it('renders GlDrawer with list title and label', () => {
        createComponent({ list: mockLabelList });

        expect(findDrawer().props('open')).toBe(true);
        expect(findLabel().props('title')).toBe(labelTitle);
        expect(findLabel().props('backgroundColor')).toBe(labelColor);
      });
    });
  });

  it('does not render "Remove list" when user cannot admin the boards list', () => {
    createComponent();

    expect(findRemoveButton().exists()).toBe(false);
  });

  describe('when user can admin the boards list', () => {
    beforeEach(() => {
      createComponent({ canAdminList: true, list: mockLabelList });
    });

    it('renders "Remove list" button', () => {
      expect(findRemoveButton().exists()).toBe(true);
    });

    it('removes the list', () => {
      findRemoveButton().vm.$emit('click');

      wrapper.findComponent(GlModal).vm.$emit('primary');

      expect(destroyBoardListMutationHandlerSuccess).toHaveBeenCalled();
    });

    it('has the correct ID on the button', () => {
      const binding = getBinding(findRemoveButton().element, 'gl-modal');
      expect(binding.value).toBe(modalID);
    });

    it('has the correct ID on the modal', () => {
      expect(findModal().props('modalId')).toBe(modalID);
    });

    it('sets error when destroy list mutation fails', async () => {
      createComponent({
        canAdminList: true,
        list: mockLabelList,
        destroyBoardListMutationHandler: destroyBoardListMutationHandlerFailure,
      });

      findRemoveButton().vm.$emit('click');

      wrapper.findComponent(GlModal).vm.$emit('primary');

      await waitForPromises();

      expect(cacheUpdates.setError).toHaveBeenCalled();
    });
  });
});
