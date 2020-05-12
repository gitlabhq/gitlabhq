import { shallowMount } from '@vue/test-utils';
import { GlDropdownItem, GlModal, GlLoadingIcon, GlAlert, GlIcon } from '@gitlab/ui';
import waitForPromises from 'helpers/wait_for_promises';

import DashboardsDropdown from '~/monitoring/components/dashboards_dropdown.vue';
import DuplicateDashboardForm from '~/monitoring/components/duplicate_dashboard_form.vue';

import { dashboardGitResponse } from '../mock_data';

const defaultBranch = 'master';

const starredDashboards = dashboardGitResponse.filter(({ starred }) => starred);
const notStarredDashboards = dashboardGitResponse.filter(({ starred }) => !starred);

describe('DashboardsDropdown', () => {
  let wrapper;
  let mockDashboards;
  let mockSelectedDashboard;

  function createComponent(props, opts = {}) {
    const storeOpts = {
      methods: {
        duplicateSystemDashboard: jest.fn(),
      },
      computed: {
        allDashboards: () => mockDashboards,
        selectedDashboard: () => mockSelectedDashboard,
      },
    };

    return shallowMount(DashboardsDropdown, {
      propsData: {
        ...props,
        defaultBranch,
      },
      sync: false,
      ...storeOpts,
      ...opts,
    });
  }

  const findItems = () => wrapper.findAll(GlDropdownItem);
  const findItemAt = i => wrapper.findAll(GlDropdownItem).at(i);
  const findSearchInput = () => wrapper.find({ ref: 'monitorDashboardsDropdownSearch' });
  const findNoItemsMsg = () => wrapper.find({ ref: 'monitorDashboardsDropdownMsg' });
  const findStarredListDivider = () => wrapper.find({ ref: 'starredListDivider' });
  const setSearchTerm = searchTerm => wrapper.setData({ searchTerm });

  beforeEach(() => {
    mockDashboards = dashboardGitResponse;
    mockSelectedDashboard = null;
  });

  describe('when it receives dashboards data', () => {
    beforeEach(() => {
      wrapper = createComponent();
    });

    it('displays an item for each dashboard', () => {
      expect(findItems().length).toEqual(dashboardGitResponse.length);
    });

    it('displays items with the dashboard display name, with starred dashboards first', () => {
      expect(findItemAt(0).text()).toBe(starredDashboards[0].display_name);
      expect(findItemAt(1).text()).toBe(notStarredDashboards[0].display_name);
      expect(findItemAt(2).text()).toBe(notStarredDashboards[1].display_name);
    });

    it('displays separator between starred and not starred dashboards', () => {
      expect(findStarredListDivider().exists()).toBe(true);
    });

    it('displays a search input', () => {
      expect(findSearchInput().isVisible()).toBe(true);
    });

    it('hides no message text by default', () => {
      expect(findNoItemsMsg().isVisible()).toBe(false);
    });

    it('filters dropdown items when searched for item exists in the list', () => {
      const searchTerm = 'Default';
      setSearchTerm(searchTerm);

      return wrapper.vm.$nextTick(() => {
        expect(findItems()).toHaveLength(1);
      });
    });

    it('shows no items found message when searched for item does not exists in the list', () => {
      const searchTerm = 'does-not-exist';
      setSearchTerm(searchTerm);

      return wrapper.vm.$nextTick(() => {
        expect(findNoItemsMsg().isVisible()).toBe(true);
      });
    });
  });

  describe('when the dashboard is missing a display name', () => {
    beforeEach(() => {
      mockDashboards = dashboardGitResponse.map(d => ({ ...d, display_name: undefined }));
      wrapper = createComponent();
    });

    it('displays items with the dashboard path, with starred dashboards first', () => {
      expect(findItemAt(0).text()).toBe(starredDashboards[0].path);
      expect(findItemAt(1).text()).toBe(notStarredDashboards[0].path);
      expect(findItemAt(2).text()).toBe(notStarredDashboards[1].path);
    });
  });

  describe('when it receives starred dashboards', () => {
    beforeEach(() => {
      mockDashboards = starredDashboards;
      wrapper = createComponent();
    });

    it('displays an item for each dashboard', () => {
      expect(findItems().length).toEqual(starredDashboards.length);
    });

    it('displays a star icon', () => {
      const star = findItemAt(0).find(GlIcon);
      expect(star.exists()).toBe(true);
      expect(star.attributes('name')).toBe('star');
    });

    it('displays no separator between starred and not starred dashboards', () => {
      expect(findStarredListDivider().exists()).toBe(false);
    });
  });

  describe('when it receives only not-starred dashboards', () => {
    beforeEach(() => {
      mockDashboards = notStarredDashboards;
      wrapper = createComponent();
    });

    it('displays an item for each dashboard', () => {
      expect(findItems().length).toEqual(notStarredDashboards.length);
    });

    it('displays no star icon', () => {
      const star = findItemAt(0).find(GlIcon);
      expect(star.exists()).toBe(false);
    });

    it('displays no separator between starred and not starred dashboards', () => {
      expect(findStarredListDivider().exists()).toBe(false);
    });
  });

  describe('when a system dashboard is selected', () => {
    let duplicateDashboardAction;
    let modalDirective;

    beforeEach(() => {
      [mockSelectedDashboard] = dashboardGitResponse;
      modalDirective = jest.fn();
      duplicateDashboardAction = jest.fn().mockResolvedValue();

      wrapper = createComponent(
        {},
        {
          directives: {
            GlModal: modalDirective,
          },
          methods: {
            // Mock vuex actions
            duplicateSystemDashboard: duplicateDashboardAction,
          },
        },
      );

      wrapper.vm.$refs.duplicateDashboardModal.hide = jest.fn();
    });

    it('displays an item for each dashboard plus a "duplicate dashboard" item', () => {
      const item = wrapper.findAll({ ref: 'duplicateDashboardItem' });

      expect(findItems().length).toEqual(dashboardGitResponse.length + 1);
      expect(item.length).toBe(1);
    });

    describe('modal form', () => {
      let okEvent;

      const findModal = () => wrapper.find(GlModal);
      const findAlert = () => wrapper.find(GlAlert);

      beforeEach(() => {
        okEvent = {
          preventDefault: jest.fn(),
        };
      });

      it('exists and contains a form to duplicate a dashboard', () => {
        expect(findModal().exists()).toBe(true);
        expect(findModal().contains(DuplicateDashboardForm)).toBe(true);
      });

      it('saves a new dashboard', () => {
        findModal().vm.$emit('ok', okEvent);

        return waitForPromises().then(() => {
          expect(okEvent.preventDefault).toHaveBeenCalled();

          expect(wrapper.find(GlLoadingIcon).exists()).toBe(false);
          expect(wrapper.vm.$refs.duplicateDashboardModal.hide).toHaveBeenCalled();
          expect(wrapper.emitted().selectDashboard).toBeTruthy();
          expect(findAlert().exists()).toBe(false);
        });
      });

      describe('when a new dashboard is saved succesfully', () => {
        const newDashboard = {
          can_edit: true,
          default: false,
          display_name: 'A new dashboard',
          system_dashboard: false,
        };

        const submitForm = formVals => {
          duplicateDashboardAction.mockResolvedValueOnce(newDashboard);
          findModal()
            .find(DuplicateDashboardForm)
            .vm.$emit('change', {
              dashboard: 'common_metrics.yml',
              commitMessage: 'A commit message',
              ...formVals,
            });
          findModal().vm.$emit('ok', okEvent);
        };

        it('to the default branch, redirects to the new dashboard', () => {
          submitForm({
            branch: defaultBranch,
          });

          return waitForPromises().then(() => {
            expect(wrapper.emitted().selectDashboard[0][0]).toEqual(newDashboard);
          });
        });

        it('to a new branch refreshes in the current dashboard', () => {
          submitForm({
            branch: 'another-branch',
          });

          return waitForPromises().then(() => {
            expect(wrapper.emitted().selectDashboard[0][0]).toEqual(dashboardGitResponse[0]);
          });
        });
      });

      it('handles error when a new dashboard is not saved', () => {
        const errMsg = 'An error occurred';

        duplicateDashboardAction.mockRejectedValueOnce(errMsg);
        findModal().vm.$emit('ok', okEvent);

        return waitForPromises().then(() => {
          expect(okEvent.preventDefault).toHaveBeenCalled();

          expect(findAlert().exists()).toBe(true);
          expect(findAlert().text()).toBe(errMsg);

          expect(wrapper.find(GlLoadingIcon).exists()).toBe(false);
          expect(wrapper.vm.$refs.duplicateDashboardModal.hide).not.toHaveBeenCalled();
        });
      });

      it('id is correct, as the value of modal directive binding matches modal id', () => {
        expect(modalDirective).toHaveBeenCalledTimes(1);

        // Binding's second argument contains the modal id
        expect(modalDirective.mock.calls[0][1]).toEqual(
          expect.objectContaining({
            value: findModal().props('modalId'),
          }),
        );
      });

      it('updates the form on changes', () => {
        const formVals = {
          dashboard: 'common_metrics.yml',
          commitMessage: 'A commit message',
        };

        findModal()
          .find(DuplicateDashboardForm)
          .vm.$emit('change', formVals);

        // Binding's second argument contains the modal id
        expect(wrapper.vm.form).toEqual(formVals);
      });
    });
  });

  describe('when a custom dashboard is selected', () => {
    const findModal = () => wrapper.find(GlModal);

    beforeEach(() => {
      wrapper = createComponent({
        selectedDashboard: dashboardGitResponse[1],
      });
    });

    it('displays an item for each dashboard', () => {
      const item = wrapper.findAll({ ref: 'duplicateDashboardItem' });

      expect(findItems()).toHaveLength(dashboardGitResponse.length);
      expect(item.length).toBe(0);
    });

    it('modal form does not exist and contains a form to duplicate a dashboard', () => {
      expect(findModal().exists()).toBe(false);
    });
  });

  describe('when a dashboard gets selected by the user', () => {
    beforeEach(() => {
      wrapper = createComponent();
      findItemAt(1).vm.$emit('click');
    });

    it('emits a "selectDashboard" event', () => {
      expect(wrapper.emitted().selectDashboard).toBeTruthy();
    });
    it('emits a "selectDashboard" event with dashboard information', () => {
      expect(wrapper.emitted().selectDashboard[0]).toEqual([dashboardGitResponse[0]]);
    });
  });
});
