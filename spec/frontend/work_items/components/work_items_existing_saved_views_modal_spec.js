import { GlModal, GlSearchBoxByType, GlLoadingIcon } from '@gitlab/ui';
import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { createMockDirective } from 'helpers/vue_mock_directive';
import getNamespaceSavedViewsQuery from '~/work_items/graphql/work_item_saved_views_namespace.query.graphql';
import waitForPromises from 'helpers/wait_for_promises';
import WorkItemsExistingSavedViewsModal from '~/work_items/components/work_items_existing_saved_views_modal.vue';

describe('WorkItemsExistingSavedViewsModal', () => {
  let wrapper;

  Vue.use(VueApollo);

  const mockSavedViewsData = [
    {
      __typename: 'SavedView',
      id: '1',
      title: 'My Private View',
      description: 'Only I can see this',
      isPrivate: true,
      isSubscribed: true,
    },
    {
      __typename: 'SavedView',
      id: '2',
      title: 'Team View',
      description: 'Shared with the team',
      isPrivate: false,
      isSubscribed: false,
    },
  ];

  const createComponent = async ({ props, mockSavedViews = mockSavedViewsData } = {}) => {
    const apolloProvider = createMockApollo();

    // TODO: to be removed when actual API is integrated
    apolloProvider.defaultClient.writeQuery({
      query: getNamespaceSavedViewsQuery,
      variables: {
        fullPath: 'test-project-path',
      },
      data: {
        namespace: {
          id: 'namespace',
          savedViews: {
            __typename: 'SavedViewConnection',
            nodes: mockSavedViews,
          },
        },
      },
    });

    wrapper = shallowMountExtended(WorkItemsExistingSavedViewsModal, {
      apolloProvider,
      propsData: {
        show: true,
        fullPath: 'test-project-path',
        ...props,
      },
      directives: {
        GlTooltip: createMockDirective('gl-tooltip'),
      },
      stubs: {
        GlModal,
      },
    });

    await waitForPromises();
  };

  const findModal = () => wrapper.findComponent(GlModal);
  const findSearch = () => wrapper.findComponent(GlSearchBoxByType);
  const findNewViewButton = () => wrapper.findByTestId('new-view-button');
  const findSavedViewItems = () => wrapper.findAllByTestId('saved-view-item');
  const findSubscribedIcons = () => wrapper.findAllByTestId('subscribed-view-icon');
  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);

  beforeEach(async () => {
    await createComponent();
  });

  it('shows loading icon while saved views are loading', async () => {
    const apolloProvider = createMockApollo();

    wrapper = shallowMountExtended(WorkItemsExistingSavedViewsModal, {
      apolloProvider,
      propsData: {
        show: true,
        fullPath: 'test-project-path',
      },
      directives: {
        GlTooltip: createMockDirective('gl-tooltip'),
      },
      stubs: {
        GlModal,
      },
    });

    await nextTick();
    expect(findLoadingIcon().exists()).toBe(true);
  });

  it('focuses the search input on showing modal', async () => {
    const focusSpy = jest.fn();
    findSearch().element.focus = focusSpy;

    findModal().vm.$emit('shown');
    await waitForPromises();
    expect(focusSpy).toHaveBeenCalled();
  });

  it('clears search input on hiding the modal', async () => {
    findSearch().vm.$emit('input', 'team');
    await waitForPromises();

    expect(findSearch().props('value')).toBe('team');
    findModal().vm.$emit('hide');

    await waitForPromises();
    expect(findSearch().props('value')).toBe('');
  });

  describe('saved view list', () => {
    it('correctly renders the saved views list', () => {
      expect(findSavedViewItems()).toHaveLength(mockSavedViewsData.length);

      mockSavedViewsData.forEach((view) => {
        expect(wrapper.text()).toContain(view.title);
        expect(wrapper.text()).toContain(view.description);
      });
    });

    it('shows "Added" and check icon only for subscribed views', () => {
      createComponent();

      expect(wrapper.text()).toContain('Added');
      expect(findSubscribedIcons()).toHaveLength(1);
    });

    it('hides modal and clears search when clicking on a view', async () => {
      createComponent();

      findSearch().vm.$emit('input', 'view');
      await waitForPromises();

      await findSavedViewItems().at(0).trigger('click');

      expect(wrapper.emitted('hide')).toEqual([[false]]);
      expect(findSearch().props('value')).toBe('');
    });
  });

  describe('search filtering', () => {
    it('filters views by title or description', async () => {
      findSearch().vm.$emit('input', 'team');

      await waitForPromises();

      expect(findSavedViewItems()).toHaveLength(1);
      expect(wrapper.text()).toContain('Team View');
      expect(wrapper.text()).not.toContain('My Private View');
    });

    it('shows "No results found" when there are no matches', async () => {
      findSearch().vm.$emit('input', 'foo');
      await waitForPromises();

      expect(wrapper.text()).toContain('No results found');
      expect(wrapper.text()).toContain('Edit your search and try again.');
      expect(findSavedViewItems()).toHaveLength(0);
    });
  });

  describe('when there are no saved views available', () => {
    beforeEach(() => {
      createComponent({ mockSavedViews: [] });
    });

    it('disables the search input', () => {
      expect(findSearch().props('disabled')).toBe(true);
    });

    it('renders empty state and redirects to New View Modal', async () => {
      expect(wrapper.text()).toContain('No views currently exist');
      expect(findNewViewButton().exists()).toBe(true);

      findNewViewButton().vm.$emit('click');
      await nextTick();

      expect(wrapper.emitted('hide')).toEqual([[false]]);
      expect(wrapper.emitted('show-new-view-modal')).toEqual([[]]);
    });
  });
});
