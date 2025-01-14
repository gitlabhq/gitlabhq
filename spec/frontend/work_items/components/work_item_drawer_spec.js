import { GlDrawer, GlLink } from '@gitlab/ui';
import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';

import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { stubComponent } from 'helpers/stub_component';
import { resetHTMLFixture, setHTMLFixture } from 'helpers/fixtures';

import { TYPE_EPIC, TYPE_ISSUE } from '~/issues/constants';
import { DETAIL_VIEW_QUERY_PARAM_NAME } from '~/work_items/constants';
import WorkItemDrawer from '~/work_items/components/work_item_drawer.vue';
import WorkItemDetail from '~/work_items/components/work_item_detail.vue';
import deleteWorkItemMutation from '~/work_items/graphql/delete_work_item.mutation.graphql';
import workspacePermissionsQuery from '~/work_items/graphql/workspace_permissions.query.graphql';
import { shallowMountExtended, mountExtended } from 'helpers/vue_test_utils_helper';
import { visitUrl, updateHistory, setUrlParams, removeParams } from '~/lib/utils/url_utility';
import { makeDrawerUrlParam } from '~/work_items/utils';
import { mockProjectPermissionsQueryResponse } from '../mock_data';

jest.mock('~/lib/utils/url_utility');

Vue.use(VueApollo);

const deleteWorkItemMutationHandler = jest
  .fn()
  .mockResolvedValue({ data: { workItemDelete: { errors: [] } } });
const workspacePermissionsHandler = jest
  .fn()
  .mockResolvedValue(mockProjectPermissionsQueryResponse());

describe('WorkItemDrawer', () => {
  let wrapper;

  const mockListener = jest.fn();
  const mockRouterPush = jest.fn();

  const findGlDrawer = () => wrapper.findComponent(GlDrawer);
  const findWorkItem = () => wrapper.findComponent(WorkItemDetail);
  const findLinkButton = () => wrapper.findByTestId('work-item-drawer-link-button');
  const findReferenceLink = () => wrapper.findComponent(GlLink);

  const createComponent = ({
    open = false,
    activeItem = { id: '1', iid: '1', webUrl: 'test', fullPath: 'gitlab-org/gitlab' },
    issuableType = TYPE_ISSUE,
    clickOutsideExcludeSelector = undefined,
    isGroup = true,
    workItemsViewPreference = false,
    mountFn = shallowMountExtended,
    stubs = { WorkItemDetail },
  } = {}) => {
    window.gon.current_user_use_work_items_view = true;

    wrapper = mountFn(WorkItemDrawer, {
      attachTo: document.body,
      propsData: {
        activeItem,
        open,
        issuableType,
        clickOutsideExcludeSelector,
      },
      listeners: {
        customEvent: mockListener,
      },
      provide: {
        fullPath: 'gitlab-org/gitlab',
        reportAbusePath: '',
        groupPath: '',
        hasSubepicsFeature: false,
        hasLinkedItemsEpicsFeature: true,
        isGroup,
        glFeatures: {
          workItemsViewPreference,
        },
      },
      mocks: {
        $router: {
          push: mockRouterPush,
        },
      },
      stubs,
      apolloProvider: createMockApollo([
        [deleteWorkItemMutation, deleteWorkItemMutationHandler],
        [workspacePermissionsQuery, workspacePermissionsHandler],
      ]),
    });
  };

  it('passes correct `open` prop to GlDrawer', () => {
    createComponent();

    expect(findGlDrawer().props('open')).toBe(false);
  });

  it('focus on first item when drawer loads the active item', async () => {
    createComponent({
      mountFn: mountExtended,
      stubs: {
        GlDrawer: stubComponent(GlDrawer, {
          template: `
        <div>
          <slot name="title"></slot>
          <slot></slot>
        </div>`,
        }),
      },
    });
    await nextTick();

    expect(document.activeElement).toBe(findReferenceLink().element);
  });

  it('displays correct URL and text in link', () => {
    createComponent();

    const link = wrapper.findComponent(GlLink);
    expect(link.attributes('href')).toBe('test');
    expect(link.text()).toBe('gitlab#1');
  });

  it('displays the correct URL in the full page button', () => {
    createComponent();

    expect(wrapper.findByTestId('work-item-drawer-link-button').attributes('href')).toBe('test');
  });

  it('has a copy to clipboard button for the item URL', () => {
    createComponent();

    expect(
      wrapper.findByTestId('work-item-drawer-copy-button').attributes('data-clipboard-text'),
    ).toBe('test');
  });

  describe('closing the drawer', () => {
    it('emits `close` event when drawer is closed', () => {
      createComponent({ open: true });

      findGlDrawer().vm.$emit('close');

      expect(wrapper.emitted('close')).toHaveLength(1);
    });

    it('emits `close` event when clicking outside of drawer', () => {
      createComponent({ open: true });

      document.dispatchEvent(new MouseEvent('click'));

      expect(wrapper.emitted('close')).toHaveLength(1);
    });

    it('calls `upddateHistory`', () => {
      createComponent({ open: true });

      findGlDrawer().vm.$emit('close');

      expect(updateHistory).toHaveBeenCalled();
    });
    it('calls `removeParams` to remove the `show` param', () => {
      createComponent({ open: true });

      findGlDrawer().vm.$emit('close');

      expect(removeParams).toHaveBeenCalledWith([DETAIL_VIEW_QUERY_PARAM_NAME]);
    });

    describe('`clickOutsideExcludeSelector` prop', () => {
      let fakeParent;
      let otherElement;

      beforeEach(() => {
        createComponent({ open: true, clickOutsideExcludeSelector: '.selector' });

        fakeParent = document.createElement('div');
        fakeParent.classList.add('selector');
        document.body.appendChild(fakeParent);

        otherElement = document.createElement('div');
        document.body.appendChild(otherElement);
      });
      it('emits `close` event when clicking outside of drawer and not on excluded element', () => {
        otherElement.dispatchEvent(new MouseEvent('click'));

        expect(wrapper.emitted('close')).toHaveLength(1);
      });

      it('does not emit `close` event when clicking outside of drawer on excluded element', () => {
        fakeParent.dispatchEvent(new MouseEvent('click'));

        expect(wrapper.emitted('close')).toBeUndefined();
      });
    });
  });

  it('passes listeners correctly to WorkItemDetail', () => {
    createComponent({ open: true });
    const mockPayload = { iid: '1' };

    findWorkItem().vm.$emit('customEvent', mockPayload);

    expect(mockListener).toHaveBeenCalledWith(mockPayload);
  });

  describe('when deleting work item', () => {
    it('calls deleteWorkItemMutation', () => {
      createComponent({ open: true });
      findWorkItem().vm.$emit('deleteWorkItem', { workItemId: '1' });

      expect(deleteWorkItemMutationHandler).toHaveBeenCalledWith({
        input: { id: '1' },
      });
    });

    it('emits `workItemDeleted` event when on successful mutation', async () => {
      createComponent({ open: true });
      findWorkItem().vm.$emit('deleteWorkItem', { workItemId: '1' });

      await waitForPromises();

      expect(wrapper.emitted('workItemDeleted')).toHaveLength(1);
    });

    it('emits `deleteWorkItemError` event when mutation failed', async () => {
      deleteWorkItemMutationHandler.mockRejectedValue('Houston, we have a problem');

      createComponent({ open: true });
      findWorkItem().vm.$emit('deleteWorkItem', { workItemId: '1' });

      await waitForPromises();

      expect(wrapper.emitted('deleteWorkItemError')).toHaveLength(1);
    });
  });

  describe('when calculating activeItemFullPath', () => {
    it('passes active issuable full path to work item detail if provided', () => {
      const fullPath = '/gitlab-org';
      createComponent({ activeItem: { fullPath } });

      expect(findWorkItem().props('modalWorkItemFullPath')).toBe(fullPath);
    });

    describe('when active issuable has no fullPath property', () => {
      it('uses injected fullPath if active issuable has no reference path or full path', () => {
        createComponent({ activeItem: {} });

        expect(findWorkItem().props('modalWorkItemFullPath')).toBe('gitlab-org/gitlab');
      });

      it('passes correctly calculated path if active issuable is an issue', () => {
        createComponent({ activeItem: { referencePath: 'gitlab-org/gitlab#35' } });

        expect(findWorkItem().props('modalWorkItemFullPath')).toBe('gitlab-org/gitlab');
      });

      it('passes correctly calculated fullPath if active issuable is an epic', () => {
        createComponent({
          activeItem: { referencePath: 'gitlab-org/gitlab&35' },
          issuableType: TYPE_EPIC,
        });

        expect(findWorkItem().props('modalWorkItemFullPath')).toBe('gitlab-org/gitlab');
      });
    });
  });

  it('passes modalIsGroup as undefined if issuableType is issue', () => {
    createComponent();

    expect(findWorkItem().props('modalIsGroup')).toBe(false);
  });

  it('passes modalIsGroup as true if issuableType is epic', () => {
    createComponent({ issuableType: TYPE_EPIC });

    expect(findWorkItem().props('modalIsGroup')).toBe(true);
  });

  describe('when redirecting to full screen view', () => {
    it('calls `visitUrl` when link is not a work item path', () => {
      createComponent();
      findLinkButton().vm.$emit('click', new MouseEvent('click'));

      expect(visitUrl).toHaveBeenCalledWith('test');
    });

    it('calls `router.push` when link is a group level work item and we are at the group level', () => {
      createComponent({
        isGroup: true,
        activeItem: {
          iid: '1',
          webUrl: '/groups/gitlab-org/gitlab/-/work_items/1',
          fullPath: 'gitlab-org/gitlab',
        },
      });
      findLinkButton().vm.$emit('click', new MouseEvent('click'));

      expect(visitUrl).not.toHaveBeenCalled();
      expect(mockRouterPush).toHaveBeenCalledWith({ name: 'workItem', params: { iid: '1' } });
    });

    it('does not call `router.push` when link is a group level work item and we are at the project level', () => {
      createComponent({
        isGroup: false,
        activeItem: {
          iid: '1',
          webUrl: '/groups/gitlab-org/gitlab/-/work_items/1',
          fullPath: 'gitlab-org/gitlab',
        },
      });
      findLinkButton().vm.$emit('click', new MouseEvent('click'));

      expect(visitUrl).toHaveBeenCalledWith('/groups/gitlab-org/gitlab/-/work_items/1');
      expect(mockRouterPush).not.toHaveBeenCalled();
    });

    it('calls `router.push` when issue as work item view is enabled and work item is in same project', () => {
      createComponent({
        isGroup: false,
        workItemsViewPreference: true,
        activeItem: {
          iid: '1',
          webUrl: '/gitlab-org/gitlab/-/work_items/1',
          fullPath: 'gitlab-org/gitlab',
        },
      });

      findLinkButton().vm.$emit('click', new MouseEvent('click'));

      expect(visitUrl).not.toHaveBeenCalled();
      expect(mockRouterPush).toHaveBeenCalledWith({ name: 'workItem', params: { iid: '1' } });
    });

    it('does not call `router.push` when issue as work item view is enabled and work item is in different project', () => {
      createComponent({
        isGroup: false,
        workItemsViewPreference: true,
        activeItem: {
          iid: '1',
          webUrl: '/gitlab-org/gitlab-other/-/work_items/1',
          fullPath: 'gitlab-org/gitlab',
        },
      });

      findLinkButton().vm.$emit('click', new MouseEvent('click'));

      expect(visitUrl).toHaveBeenCalledWith('/gitlab-org/gitlab-other/-/work_items/1');
      expect(mockRouterPush).not.toHaveBeenCalled();
    });
  });

  describe('when `activeItem` prop is changed and it contains an `id`', () => {
    const activeItem = {
      iid: '1',
      webUrl: '/groups/gitlab-org/gitlab/-/work_items/1',
      fullPath: 'gitlab-org/gitlab',
      id: 'gid://gitlab/WorkItem/1',
    };
    const showParam = makeDrawerUrlParam(activeItem, 'gitlab-org/gitlab');
    beforeEach(async () => {
      createComponent();
      await wrapper.setProps({
        open: true,
        activeItem,
      });
    });
    it('calls `updateHistory`', () => {
      expect(updateHistory).toHaveBeenCalled();
    });
    it('calls `setUrlParams` with `show` param', () => {
      expect(setUrlParams).toHaveBeenCalledWith({ [DETAIL_VIEW_QUERY_PARAM_NAME]: showParam });
    });

    it('focus on first item once drawer loads', async () => {
      createComponent({
        mountFn: mountExtended,
        stubs: {
          GlDrawer: stubComponent(GlDrawer, {
            template: `
          <div>
            <slot name="title"></slot>
            <slot></slot>
          </div>`,
          }),
        },
      });

      await wrapper.setProps({
        open: true,
        activeItem,
      });

      await nextTick();

      expect(document.activeElement).toBe(findReferenceLink().element);
    });
  });

  describe('when drawer is opened from a link', () => {
    beforeEach(() => {
      setHTMLFixture(
        `<div><a id="listItem-gitlab-org/gitlab/1" tabIndex="1">Link 1</a><div id="drawer-container"></div></div>`,
      );
    });
    afterEach(() => {
      resetHTMLFixture();
    });

    it('focuses on the link when drawer is closed', async () => {
      createComponent({ attachTo: '#drawer-container', open: true });

      findGlDrawer().vm.$emit('close');

      await nextTick();

      expect(document.activeElement).toBe(document.getElementById('listItem-gitlab-org/gitlab/1'));
    });
  });
});
