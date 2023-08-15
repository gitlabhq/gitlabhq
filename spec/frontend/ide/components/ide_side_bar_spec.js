import { GlSkeletonLoader } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import Vue, { nextTick } from 'vue';
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';
import waitForPromises from 'helpers/wait_for_promises';
import IdeReview from '~/ide/components/ide_review.vue';
import IdeSidebar from '~/ide/components/ide_side_bar.vue';
import IdeTree from '~/ide/components/ide_tree.vue';
import RepoCommitSection from '~/ide/components/repo_commit_section.vue';
import { leftSidebarViews } from '~/ide/constants';
import { createStore } from '~/ide/stores';
import { projectData } from '../mock_data';

Vue.use(Vuex);

describe('IdeSidebar', () => {
  let wrapper;
  let store;

  function createComponent({ view = leftSidebarViews.edit.name } = {}) {
    store = createStore();

    store.state.currentProjectId = 'abcproject';
    store.state.projects.abcproject = projectData;
    store.state.currentActivityView = view;

    return mount(IdeSidebar, {
      store,
    });
  }

  it('renders a sidebar', () => {
    wrapper = createComponent();

    expect(wrapper.find('[data-testid="ide-side-bar-inner"]').exists()).toBe(true);
  });

  it('renders loading components', async () => {
    wrapper = createComponent();

    store.state.loading = true;

    await nextTick();

    expect(wrapper.findAllComponents(GlSkeletonLoader)).toHaveLength(3);
  });

  describe('deferred rendering components', () => {
    it('fetches components on demand', async () => {
      wrapper = createComponent();

      expect(wrapper.findComponent(IdeTree).exists()).toBe(true);
      expect(wrapper.findComponent(IdeReview).exists()).toBe(false);
      expect(wrapper.findComponent(RepoCommitSection).exists()).toBe(false);

      store.state.currentActivityView = leftSidebarViews.review.name;
      await waitForPromises();
      await nextTick();

      expect(wrapper.findComponent(IdeTree).exists()).toBe(false);
      expect(wrapper.findComponent(IdeReview).exists()).toBe(true);
      expect(wrapper.findComponent(RepoCommitSection).exists()).toBe(false);

      store.state.currentActivityView = leftSidebarViews.commit.name;
      await waitForPromises();
      await nextTick();

      expect(wrapper.findComponent(IdeTree).exists()).toBe(false);
      expect(wrapper.findComponent(IdeReview).exists()).toBe(false);
      expect(wrapper.findComponent(RepoCommitSection).exists()).toBe(true);
    });
    it.each`
      view                            | tree     | review   | commit
      ${leftSidebarViews.edit.name}   | ${true}  | ${false} | ${false}
      ${leftSidebarViews.review.name} | ${false} | ${true}  | ${false}
      ${leftSidebarViews.commit.name} | ${false} | ${false} | ${true}
    `('renders correct panels for $view', async ({ view, tree, review, commit } = {}) => {
      wrapper = createComponent({
        view,
      });
      await waitForPromises();
      await nextTick();

      expect(wrapper.findComponent(IdeTree).exists()).toBe(tree);
      expect(wrapper.findComponent(IdeReview).exists()).toBe(review);
      expect(wrapper.findComponent(RepoCommitSection).exists()).toBe(commit);
    });
  });

  it('keeps the current activity view components alive', async () => {
    wrapper = createComponent();

    const ideTreeComponent = wrapper.findComponent(IdeTree).element;

    store.state.currentActivityView = leftSidebarViews.commit.name;
    await waitForPromises();
    await nextTick();

    expect(wrapper.findComponent(IdeTree).exists()).toBe(false);
    expect(wrapper.findComponent(RepoCommitSection).exists()).toBe(true);

    store.state.currentActivityView = leftSidebarViews.edit.name;

    await waitForPromises();
    await nextTick();

    // reference to the elements remains the same, meaning the components were kept alive
    expect(wrapper.findComponent(IdeTree).element).toEqual(ideTreeComponent);
  });
});
