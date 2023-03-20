import { GlBadge } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import ActivityBar from '~/ide/components/activity_bar.vue';
import { leftSidebarViews } from '~/ide/constants';
import { createStore } from '~/ide/stores';

describe('IDE ActivityBar component', () => {
  let wrapper;
  let store;

  const findChangesBadge = () => wrapper.findComponent(GlBadge);

  const mountComponent = (state) => {
    store = createStore();
    store.replaceState({
      ...store.state,
      projects: { abcproject: { web_url: 'testing' } },
      currentProjectId: 'abcproject',
      ...state,
    });

    wrapper = shallowMount(ActivityBar, { store });
  };

  describe('updateActivityBarView', () => {
    beforeEach(() => {
      mountComponent();
      jest.spyOn(wrapper.vm, 'updateActivityBarView').mockImplementation(() => {});
    });

    it('calls updateActivityBarView with edit value on click', () => {
      wrapper.find('.js-ide-edit-mode').trigger('click');

      expect(wrapper.vm.updateActivityBarView).toHaveBeenCalledWith(leftSidebarViews.edit.name);
    });

    it('calls updateActivityBarView with commit value on click', () => {
      wrapper.find('.js-ide-commit-mode').trigger('click');

      expect(wrapper.vm.updateActivityBarView).toHaveBeenCalledWith(leftSidebarViews.commit.name);
    });

    it('calls updateActivityBarView with review value on click', () => {
      wrapper.find('.js-ide-review-mode').trigger('click');

      expect(wrapper.vm.updateActivityBarView).toHaveBeenCalledWith(leftSidebarViews.review.name);
    });
  });

  describe('active item', () => {
    it('sets edit item active', () => {
      mountComponent();

      expect(wrapper.find('.js-ide-edit-mode').classes()).toContain('active');
    });

    it('sets commit item active', () => {
      mountComponent({ currentActivityView: leftSidebarViews.commit.name });

      expect(wrapper.find('.js-ide-commit-mode').classes()).toContain('active');
    });
  });

  describe('changes badge', () => {
    it('is rendered when files are staged', () => {
      mountComponent({ stagedFiles: [{ path: '/path/to/file' }] });

      expect(findChangesBadge().exists()).toBe(true);
      expect(findChangesBadge().text()).toBe('1');
    });

    it('is not rendered when no changes are present', () => {
      mountComponent();

      expect(findChangesBadge().exists()).toBe(false);
    });
  });
});
