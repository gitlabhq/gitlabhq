import Vue, { nextTick } from 'vue';
import { GlBadge } from '@gitlab/ui';
import VueApollo from 'vue-apollo';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import WorkItemLinks from '~/work_items/components/work_item_links/work_item_links.vue';
import getWorkItemLinksQuery from '~/work_items/graphql/work_item_links.query.graphql';
import {
  workItemHierarchyResponse,
  workItemHierarchyEmptyResponse,
  workItemHierarchyNoUpdatePermissionResponse,
} from '../../mock_data';

Vue.use(VueApollo);

describe('WorkItemLinks', () => {
  let wrapper;

  const createComponent = async ({ response = workItemHierarchyResponse } = {}) => {
    wrapper = shallowMountExtended(WorkItemLinks, {
      apolloProvider: createMockApollo([
        [getWorkItemLinksQuery, jest.fn().mockResolvedValue(response)],
      ]),
      propsData: { issuableId: 1 },
    });

    await waitForPromises();
  };

  const findToggleButton = () => wrapper.findByTestId('toggle-links');
  const findLinksBody = () => wrapper.findByTestId('links-body');
  const findEmptyState = () => wrapper.findByTestId('links-empty');
  const findToggleAddFormButton = () => wrapper.findByTestId('toggle-add-form');
  const findAddLinksForm = () => wrapper.findByTestId('add-links-form');
  const findFirstLinksMenu = () => wrapper.findByTestId('links-menu');

  beforeEach(async () => {
    await createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  it('is expanded by default', () => {
    expect(findToggleButton().props('icon')).toBe('chevron-lg-up');
    expect(findLinksBody().exists()).toBe(true);
  });

  it('expands on click toggle button', async () => {
    findToggleButton().vm.$emit('click');
    await nextTick();

    expect(findToggleButton().props('icon')).toBe('chevron-lg-down');
    expect(findLinksBody().exists()).toBe(false);
  });

  describe('add link form', () => {
    it('displays form on click add button and hides form on cancel', async () => {
      findToggleAddFormButton().vm.$emit('click');
      await nextTick();

      expect(findAddLinksForm().exists()).toBe(true);

      findAddLinksForm().vm.$emit('cancel');
      await nextTick();

      expect(findAddLinksForm().exists()).toBe(false);
    });
  });

  describe('when no child links', () => {
    beforeEach(async () => {
      await createComponent({ response: workItemHierarchyEmptyResponse });
    });

    it('displays empty state if there are no children', () => {
      expect(findEmptyState().exists()).toBe(true);
    });
  });

  it('renders all hierarchy widget children', () => {
    expect(findLinksBody().exists()).toBe(true);

    const children = wrapper.findAll('[data-testid="links-child"]');

    expect(children).toHaveLength(4);
    expect(children.at(0).findComponent(GlBadge).text()).toBe('Open');
    expect(findFirstLinksMenu().exists()).toBe(true);
  });

  describe('when no permission to update', () => {
    beforeEach(async () => {
      await createComponent({ response: workItemHierarchyNoUpdatePermissionResponse });
    });

    it('does not display button to toggle Add form', () => {
      expect(findToggleAddFormButton().exists()).toBe(false);
    });

    it('does not display link menu on children', () => {
      expect(findFirstLinksMenu().exists()).toBe(false);
    });
  });
});
