import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import { GlButton, GlCollapse, GlIcon, GlLink, GlLoadingIcon, GlPopover } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { createAlert } from '~/alert';
import WorkItemDrawer from '~/work_items/components/work_item_drawer.vue';
import MRRelatedWorkItems from '~/sidebar/components/related_work_items/related_work_items.vue';
import mergeRequestRelatedWorkItemsQuery from '~/sidebar/queries/merge_request_related_work_items.query.graphql';
import { getParameterByName, removeParams, updateHistory } from '~/lib/utils/url_utility';

jest.mock('~/alert');
jest.mock('~/lib/utils/url_utility');

Vue.use(VueApollo);

const MOCK_MERGE_REQUEST_ID = 'gid://gitlab/MergeRequest/1';

let workItemCounter = 0;
const mockLinkedItem = ({ title, linkType }) => {
  workItemCounter += 1;
  return {
    linkType,
    workItem: {
      id: `gid://gitlab/WorkItem/${workItemCounter + 100}`,
      iid: String(workItemCounter),
      title,
      webUrl: `/group/project/-/work_items/${workItemCounter}`,
      webPath: `/group/project/-/work_items/${workItemCounter}`,
      namespace: {
        id: 'gid://gitlab/Project/7',
        fullPath: 'group/project',
        __typename: 'Namespace',
      },
      __typename: 'WorkItem',
    },
    __typename: 'LinkedWorkItem',
  };
};

const closingItem1 = mockLinkedItem({ title: 'Fix bug', linkType: 'CLOSES' });
const closingItem2 = mockLinkedItem({ title: 'Update docs', linkType: 'CLOSES' });
const mentionedItem = mockLinkedItem({ title: 'Refactor code', linkType: 'MENTIONED' });

const buildQueryResponse = (linkedWorkItems = []) => ({
  data: {
    mergeRequest: {
      id: MOCK_MERGE_REQUEST_ID,
      linkedWorkItems,
      __typename: 'MergeRequest',
    },
  },
});

describe('MRRelatedWorkItems', () => {
  let wrapper;

  const findCollapseButton = () => wrapper.findComponent(GlButton);
  const findInfoIcon = () => wrapper.findComponent(GlIcon);
  const findPopover = () => wrapper.findComponent(GlPopover);
  const findCollapse = () => wrapper.findComponent(GlCollapse);
  const findDrawer = () => wrapper.findComponent(WorkItemDrawer);
  const findAllLinks = () => wrapper.findAllComponents(GlLink);
  const findNoneText = () => wrapper.find('.hide-collapsed.gl-text-subtle');
  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);

  const createComponent = ({
    queryHandler = jest.fn().mockResolvedValue(buildQueryResponse()),
  } = {}) => {
    wrapper = shallowMountExtended(MRRelatedWorkItems, {
      apolloProvider: createMockApollo([[mergeRequestRelatedWorkItemsQuery, queryHandler]]),
      provide: {
        fullPath: 'group/project',
        id: '1',
      },
      stubs: {
        GlCollapse,
      },
    });
  };

  describe('when loading', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders loading icon while query is in progress', () => {
      expect(findLoadingIcon().exists()).toBe(true);
    });

    it('does not render "None" text while loading', () => {
      expect(findNoneText().exists()).toBe(false);
    });

    it('does not render info icon while loading', () => {
      expect(findInfoIcon().exists()).toBe(false);
    });
  });

  it('displays an alert when query is rejected', async () => {
    createComponent({
      queryHandler: jest.fn().mockRejectedValue(new Error('GraphQL error')),
    });
    await waitForPromises();

    expect(createAlert).toHaveBeenCalledWith({
      message: 'Something went wrong while fetching related work items.',
    });
  });

  describe('with no items', () => {
    beforeEach(async () => {
      createComponent();
      await waitForPromises();
    });

    it('does not render loading icon', () => {
      expect(findLoadingIcon().exists()).toBe(false);
    });

    it('renders "None" text', () => {
      expect(findNoneText().text()).toBe('None');
    });

    it('renders info icon', () => {
      expect(findInfoIcon().exists()).toBe(true);
      expect(findInfoIcon().attributes('name')).toBe('information-o');
    });

    it('renders popover with closing patterns link', () => {
      const popover = findPopover();
      expect(popover.exists()).toBe(true);
      expect(popover.attributes('target')).toBe('related-work-items-info');
    });

    it('does not render collapse button', () => {
      expect(findCollapseButton().exists()).toBe(false);
    });
  });

  describe('with items (not exceeding collapse threshold)', () => {
    beforeEach(async () => {
      createComponent({
        queryHandler: jest
          .fn()
          .mockResolvedValue(buildQueryResponse([closingItem1, mentionedItem])),
      });
      await waitForPromises();
    });

    it('does not render "None" text', () => {
      expect(wrapper.text()).not.toContain('None');
    });

    it('does not render info icon', () => {
      expect(wrapper.find('#related-work-items-info').exists()).toBe(false);
    });

    it('renders closing and mentioned section labels', () => {
      expect(wrapper.text()).toContain('Closing');
      expect(wrapper.text()).toContain('Mentioned');
    });

    it('renders work item links', () => {
      const links = findAllLinks();
      expect(links).toHaveLength(2);
      expect(links.at(0).text()).toBe('Fix bug');
      expect(links.at(1).text()).toBe('Refactor code');
    });

    it('sets popover data attributes on links', () => {
      const link = findAllLinks().at(0);
      expect(link.classes()).toContain('has-popover');
      expect(link.attributes('data-reference-type')).toBe('work_item');
      expect(link.attributes('data-iid')).toBe('1');
      expect(link.attributes('data-project-path')).toBe('group/project');
    });

    it('does not show collapse button when items <= 2', () => {
      expect(findCollapseButton().exists()).toBe(false);
    });

    it('shows items directly without collapsing', () => {
      expect(findCollapse().props('visible')).toBe(true);
    });
  });

  describe('with items exceeding collapse threshold (> 2)', () => {
    beforeEach(async () => {
      createComponent({
        queryHandler: jest
          .fn()
          .mockResolvedValue(buildQueryResponse([closingItem1, closingItem2, mentionedItem])),
      });
      await waitForPromises();
    });

    it('renders collapsed summary link', () => {
      const summaryLink = findAllLinks().at(0);
      expect(summaryLink.text()).toBe('Closing 2, Mentioned 1');
    });

    it('starts in collapsed state', () => {
      expect(findCollapse().props('visible')).toBe(false);
    });

    it('expands when summary link is clicked', async () => {
      findAllLinks().at(0).vm.$emit('click');
      await nextTick();

      expect(findCollapse().props('visible')).toBe(true);
    });

    it('shows collapse button when expanded', async () => {
      findAllLinks().at(0).vm.$emit('click');
      await nextTick();

      const collapseBtn = findCollapseButton();
      expect(collapseBtn.exists()).toBe(true);
      expect(collapseBtn.attributes('icon')).toBe('chevron-down');
      expect(collapseBtn.attributes('title')).toBe('Collapse work items');
    });

    it('collapses when collapse button is clicked', async () => {
      findAllLinks().at(0).vm.$emit('click');
      await nextTick();

      findCollapseButton().vm.$emit('click');
      await nextTick();

      expect(findCollapse().props('visible')).toBe(false);
    });
  });

  describe('drawer interaction', () => {
    beforeEach(async () => {
      createComponent({
        queryHandler: jest.fn().mockResolvedValue(buildQueryResponse([closingItem1])),
      });
      await waitForPromises();
    });

    it('opens drawer when link is clicked', async () => {
      findAllLinks().at(0).vm.$emit('click', { preventDefault: jest.fn(), metaKey: false });
      await nextTick();

      expect(findDrawer().props('open')).toBe(true);
      expect(findDrawer().props('activeItem')).toMatchObject({
        iid: '1',
        title: 'Fix bug',
      });
    });

    it('does not open drawer on meta+click', async () => {
      findAllLinks().at(0).vm.$emit('click', { preventDefault: jest.fn(), metaKey: true });
      await nextTick();

      expect(findDrawer().props('open')).toBe(false);
    });

    it('does not open drawer on ctrl+click', async () => {
      findAllLinks().at(0).vm.$emit('click', { preventDefault: jest.fn(), ctrlKey: true });
      await nextTick();

      expect(findDrawer().props('open')).toBe(false);
    });

    it('closes drawer on close event', async () => {
      findAllLinks().at(0).vm.$emit('click', { preventDefault: jest.fn(), metaKey: false });
      await nextTick();
      expect(findDrawer().props('open')).toBe(true);

      findDrawer().vm.$emit('close');
      await nextTick();
      expect(findDrawer().props('open')).toBe(false);
    });
  });

  describe('checkDrawerParams', () => {
    const validItem = { id: 101, iid: '1', full_path: 'group/project' };
    const encodedParam = btoa(JSON.stringify(validItem));

    it('opens drawer when valid show param is present', async () => {
      getParameterByName.mockReturnValue(encodedParam);

      createComponent({
        queryHandler: jest.fn().mockResolvedValue(buildQueryResponse([closingItem1])),
      });
      await waitForPromises();

      expect(findDrawer().props('open')).toBe(true);
      expect(findDrawer().props('activeItem')).toMatchObject({
        iid: '1',
        title: 'Fix bug',
      });
    });

    it('removes param when item is not found', async () => {
      getParameterByName.mockReturnValue(
        btoa(JSON.stringify({ id: 999, iid: '999', full_path: 'group/project' })),
      );
      removeParams.mockReturnValue('http://test.host/');

      createComponent({
        queryHandler: jest.fn().mockResolvedValue(buildQueryResponse([closingItem1])),
      });
      await waitForPromises();

      expect(updateHistory).toHaveBeenCalledWith({
        url: 'http://test.host/',
      });
      expect(findDrawer().props('open')).toBe(false);
    });

    it('removes param when base64 is invalid', async () => {
      getParameterByName.mockReturnValue('not-valid-base64!!!');
      removeParams.mockReturnValue('http://test.host/');

      createComponent({
        queryHandler: jest.fn().mockResolvedValue(buildQueryResponse([closingItem1])),
      });
      await waitForPromises();

      expect(updateHistory).toHaveBeenCalled();
      expect(findDrawer().props('open')).toBe(false);
    });

    it('sets activeItem to null when no show param', async () => {
      getParameterByName.mockReturnValue(null);

      createComponent({
        queryHandler: jest.fn().mockResolvedValue(buildQueryResponse([closingItem1])),
      });
      await waitForPromises();

      expect(findDrawer().props('open')).toBe(false);
    });

    it('responds to popstate events', async () => {
      getParameterByName.mockReturnValue(null);

      createComponent({
        queryHandler: jest.fn().mockResolvedValue(buildQueryResponse([closingItem1])),
      });
      await waitForPromises();

      expect(findDrawer().props('open')).toBe(false);

      getParameterByName.mockReturnValue(encodedParam);
      window.dispatchEvent(new PopStateEvent('popstate'));
      await nextTick();

      expect(findDrawer().props('open')).toBe(true);
    });
  });
});
