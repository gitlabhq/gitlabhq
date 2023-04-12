import { nextTick } from 'vue';
import { GlBadge } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import ActivityBar from '~/ide/components/activity_bar.vue';
import { leftSidebarViews } from '~/ide/constants';
import { createStore } from '~/ide/stores';

const { edit, ...VIEW_OBJECTS_WITHOUT_EDIT } = leftSidebarViews;
const MODES_WITHOUT_EDIT = Object.keys(VIEW_OBJECTS_WITHOUT_EDIT);
const MODES = Object.keys(leftSidebarViews);

describe('IDE ActivityBar component', () => {
  let wrapper;
  let store;

  const findChangesBadge = () => wrapper.findComponent(GlBadge);
  const findModeButton = (mode) => wrapper.findByTestId(`${mode}-mode-button`);

  const mountComponent = (state) => {
    store = createStore();
    store.replaceState({
      ...store.state,
      projects: { abcproject: { web_url: 'testing' } },
      currentProjectId: 'abcproject',
      ...state,
    });

    wrapper = shallowMountExtended(ActivityBar, { store });
  };

  describe('active item', () => {
    // Test that mode button does not have 'active' class before click,
    // and does have 'active' class after click
    const testSettingActiveItem = async (mode) => {
      const button = findModeButton(mode);

      expect(button.classes('active')).toBe(false);

      button.trigger('click');
      await nextTick();

      expect(button.classes('active')).toBe(true);
    };

    it.each(MODES)('is initially set to %s mode', (mode) => {
      mountComponent({ currentActivityView: leftSidebarViews[mode].name });

      const button = findModeButton(mode);

      expect(button.classes('active')).toBe(true);
    });

    it.each(MODES_WITHOUT_EDIT)('is correctly set after clicking %s mode button', (mode) => {
      mountComponent();

      testSettingActiveItem(mode);
    });

    it('is correctly set after clicking edit mode button', () => {
      // The default currentActivityView is leftSidebarViews.edit.name,
      // so for the 'edit' mode, we pass a different currentActivityView.
      mountComponent({ currentActivityView: leftSidebarViews.review.name });

      testSettingActiveItem('edit');
    });
  });

  describe('changes badge', () => {
    it('is rendered when files are staged', () => {
      mountComponent({ stagedFiles: [{ path: '/path/to/file' }] });

      expect(findChangesBadge().text()).toBe('1');
    });

    it('is not rendered when no changes are present', () => {
      mountComponent();

      expect(findChangesBadge().exists()).toBe(false);
    });
  });
});
