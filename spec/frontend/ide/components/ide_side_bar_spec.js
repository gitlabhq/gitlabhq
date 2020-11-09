import { mount, createLocalVue } from '@vue/test-utils';
import Vuex from 'vuex';
import { GlSkeletonLoading } from '@gitlab/ui';
import waitForPromises from 'helpers/wait_for_promises';
import { createStore } from '~/ide/stores';
import IdeSidebar from '~/ide/components/ide_side_bar.vue';
import IdeTree from '~/ide/components/ide_tree.vue';
import RepoCommitSection from '~/ide/components/repo_commit_section.vue';
import IdeReview from '~/ide/components/ide_review.vue';
import { leftSidebarViews } from '~/ide/constants';
import { projectData } from '../mock_data';

const localVue = createLocalVue();
localVue.use(Vuex);

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
      localVue,
    });
  }

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  it('renders a sidebar', () => {
    wrapper = createComponent();

    expect(wrapper.find('[data-testid="ide-side-bar-inner"]').exists()).toBe(true);
  });

  it('renders loading components', async () => {
    wrapper = createComponent();

    store.state.loading = true;

    await wrapper.vm.$nextTick();

    expect(wrapper.findAll(GlSkeletonLoading)).toHaveLength(3);
  });

  describe('deferred rendering components', () => {
    it('fetches components on demand', async () => {
      wrapper = createComponent();

      expect(wrapper.find(IdeTree).exists()).toBe(true);
      expect(wrapper.find(IdeReview).exists()).toBe(false);
      expect(wrapper.find(RepoCommitSection).exists()).toBe(false);

      store.state.currentActivityView = leftSidebarViews.review.name;
      await waitForPromises();
      await wrapper.vm.$nextTick();

      expect(wrapper.find(IdeTree).exists()).toBe(false);
      expect(wrapper.find(IdeReview).exists()).toBe(true);
      expect(wrapper.find(RepoCommitSection).exists()).toBe(false);

      store.state.currentActivityView = leftSidebarViews.commit.name;
      await waitForPromises();
      await wrapper.vm.$nextTick();

      expect(wrapper.find(IdeTree).exists()).toBe(false);
      expect(wrapper.find(IdeReview).exists()).toBe(false);
      expect(wrapper.find(RepoCommitSection).exists()).toBe(true);
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
      await wrapper.vm.$nextTick();

      expect(wrapper.find(IdeTree).exists()).toBe(tree);
      expect(wrapper.find(IdeReview).exists()).toBe(review);
      expect(wrapper.find(RepoCommitSection).exists()).toBe(commit);
    });
  });

  it('keeps the current activity view components alive', async () => {
    wrapper = createComponent();

    const ideTreeComponent = wrapper.find(IdeTree).element;

    store.state.currentActivityView = leftSidebarViews.commit.name;
    await waitForPromises();
    await wrapper.vm.$nextTick();

    expect(wrapper.find(IdeTree).exists()).toBe(false);
    expect(wrapper.find(RepoCommitSection).exists()).toBe(true);

    store.state.currentActivityView = leftSidebarViews.edit.name;

    await waitForPromises();
    await wrapper.vm.$nextTick();

    // reference to the elements remains the same, meaning the components were kept alive
    expect(wrapper.find(IdeTree).element).toEqual(ideTreeComponent);
  });
});
