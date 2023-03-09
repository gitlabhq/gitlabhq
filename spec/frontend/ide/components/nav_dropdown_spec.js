import { mount } from '@vue/test-utils';
import $ from 'jquery';
import { nextTick } from 'vue';
import NavDropdown from '~/ide/components/nav_dropdown.vue';
import { PERMISSION_READ_MR } from '~/ide/constants';
import { createStore } from '~/ide/stores';

const TEST_PROJECT_ID = 'lorem-ipsum';

describe('IDE NavDropdown', () => {
  let store;
  let wrapper;

  beforeEach(() => {
    store = createStore();
    Object.assign(store.state, {
      currentProjectId: TEST_PROJECT_ID,
      currentBranchId: 'main',
      projects: {
        [TEST_PROJECT_ID]: {
          userPermissions: {
            [PERMISSION_READ_MR]: true,
          },
          branches: {
            main: { id: 'main' },
          },
        },
      },
    });
    jest.spyOn(store, 'dispatch').mockImplementation(() => {});
  });

  const createComponent = () => {
    wrapper = mount(NavDropdown, {
      store,
    });
  };

  const findIcon = (name) => wrapper.find(`[data-testid="${name}-icon"]`);
  const findMRIcon = () => findIcon('merge-request');
  const findNavForm = () => wrapper.find('.ide-nav-form');
  const showDropdown = () => {
    $(wrapper.vm.$el).trigger('show.bs.dropdown');
  };
  const hideDropdown = () => {
    $(wrapper.vm.$el).trigger('hide.bs.dropdown');
  };

  describe('default', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders nothing initially', () => {
      expect(findNavForm().exists()).toBe(false);
    });

    it('renders nav form when show.bs.dropdown', async () => {
      showDropdown();

      await nextTick();
      expect(findNavForm().exists()).toBe(true);
    });

    it('destroys nav form when closed', async () => {
      showDropdown();
      hideDropdown();

      await nextTick();
      expect(findNavForm().exists()).toBe(false);
    });

    it('renders merge request icon', () => {
      expect(findMRIcon().exists()).toBe(true);
    });
  });

  describe('when user cannot read merge requests', () => {
    beforeEach(() => {
      store.state.projects[TEST_PROJECT_ID].userPermissions = {};

      createComponent();
    });

    it('does not render merge requests', () => {
      expect(findMRIcon().exists()).toBe(false);
    });
  });
});
