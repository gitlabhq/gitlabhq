import {
  GlDisclosureDropdownItem,
  GlDisclosureDropdown,
  GlDisclosureDropdownGroup,
} from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { createMockDirective, getBinding } from 'helpers/vue_mock_directive';
import moreActionsDropdown from '~/groups_projects/components/more_actions_dropdown.vue';

describe('moreActionsDropdown', () => {
  let wrapper;

  const createComponent = ({ provideData = {}, propsData = {} } = {}) => {
    wrapper = shallowMountExtended(moreActionsDropdown, {
      directives: {
        GlTooltip: createMockDirective('gl-tooltip'),
      },
      provide: {
        isGroup: false,
        groupOrProjectId: 1,
        leavePath: '',
        leaveConfirmMessage: '',
        withdrawPath: '',
        withdrawConfirmMessage: '',
        requestAccessPath: '',
        canEdit: false,
        editPath: '',
        ...provideData,
      },
      propsData,
      stubs: {
        GlDisclosureDropdownItem,
      },
    });
  };

  const findDropdown = () => wrapper.findComponent(GlDisclosureDropdown);
  const showDropdown = () => {
    findDropdown().vm.$emit('show');
  };
  const findDropdownTooltip = () => getBinding(findDropdown().element, 'gl-tooltip');
  const findDropdownGroup = () => wrapper.findComponent(GlDisclosureDropdownGroup);
  const findGroupSettings = () => wrapper.findByTestId('settings-group-link');
  const findProjectSettings = () => wrapper.findByTestId('settings-project-link');

  describe('copy id', () => {
    describe('project namespace type', () => {
      beforeEach(async () => {
        createComponent({
          provideData: {
            groupOrProjectId: 22,
          },
        });
        await showDropdown();
      });

      it('has correct test id `copy-project-id`', () => {
        expect(wrapper.findByTestId('copy-project-id').exists()).toBe(true);
        expect(wrapper.findByTestId('copy-group-id').exists()).toBe(false);
      });

      it('renders copy project id with correct id', () => {
        expect(wrapper.findByTestId('copy-project-id').text()).toBe('Copy project ID: 22');
      });
    });

    describe('group namespace type', () => {
      beforeEach(async () => {
        createComponent({
          provideData: {
            isGroup: true,
            groupOrProjectId: 11,
          },
        });
        await showDropdown();
      });

      it('has correct test id `copy-group-id`', () => {
        expect(wrapper.findByTestId('copy-project-id').exists()).toBe(false);
        expect(wrapper.findByTestId('copy-group-id').exists()).toBe(true);
      });

      it('renders copy group id with correct id', () => {
        expect(wrapper.findByTestId('copy-group-id').text()).toBe('Copy group ID: 11');
      });
    });
  });

  describe('dropdown group', () => {
    it('is not rendered if no path is set', () => {
      createComponent({
        provideData: {
          requestAccessPath: undefined,
          leavePath: '',
          withdrawPath: null,
        },
      });

      expect(findDropdownGroup().exists()).toBe(false);
    });

    it('is rendered if path is set', () => {
      createComponent({
        provideData: {
          requestAccessPath: 'path/to/request/access',
        },
      });
      expect(findDropdownGroup().exists()).toBe(true);
    });

    it('renders tooltip', () => {
      createComponent();

      expect(findDropdownTooltip().value).toBe('More actions');
    });
  });

  describe('request access', () => {
    it('does not render request access link', async () => {
      createComponent();
      await showDropdown();

      expect(wrapper.findByTestId('request-access-link').exists()).toBe(false);
    });

    it('renders request access link', async () => {
      createComponent({
        provideData: {
          requestAccessPath: 'http://request.path/path',
        },
      });
      await showDropdown();

      expect(wrapper.findByTestId('request-access-link').text()).toBe('Request Access');
      expect(wrapper.findByTestId('request-access-link').attributes('href')).toBe(
        'http://request.path/path',
      );
    });
  });

  describe('withdraw access', () => {
    it('does not render withdraw access link', async () => {
      createComponent();
      await showDropdown();

      expect(wrapper.findByTestId('withdraw-access-link').exists()).toBe(false);
    });

    it('renders withdraw access link', async () => {
      createComponent({
        provideData: {
          withdrawPath: 'http://withdraw.path/path',
        },
      });
      await showDropdown();

      expect(wrapper.findByTestId('withdraw-access-link').text()).toBe('Withdraw Access Request');
      expect(wrapper.findByTestId('withdraw-access-link').attributes('href')).toBe(
        'http://withdraw.path/path',
      );
    });
  });

  describe('leave access', () => {
    it('does not render leave link', async () => {
      createComponent();
      await showDropdown();

      expect(wrapper.findByTestId('leave-project-link').exists()).toBe(false);
    });

    it('renders leave link', async () => {
      createComponent({
        provideData: {
          leavePath: 'http://leave.path/path',
        },
      });
      await showDropdown();

      expect(wrapper.findByTestId('leave-project-link').exists()).toBe(true);
      expect(wrapper.findByTestId('leave-project-link').text()).toBe('Leave project');
      expect(wrapper.findByTestId('leave-project-link').attributes('href')).toBe(
        'http://leave.path/path',
      );
    });

    describe('when `isGroup` is set to `false`', () => {
      it('use testid `leave-project-link`', async () => {
        createComponent({
          provideData: {
            leavePath: 'http://leave.path/path',
          },
        });
        await showDropdown();

        expect(wrapper.findByTestId('leave-project-link').exists()).toBe(true);
        expect(wrapper.findByTestId('leave-group-link').exists()).toBe(false);
      });
    });

    describe('when `isGroup` is set to `true`', () => {
      it('use testid `leave-group-link`', async () => {
        createComponent({
          provideData: {
            isGroup: true,
            leavePath: 'http://leave.path/path',
          },
        });
        await showDropdown();

        expect(wrapper.findByTestId('leave-project-link').exists()).toBe(false);
        expect(wrapper.findByTestId('leave-group-link').exists()).toBe(true);
      });
    });
  });

  describe('settings', () => {
    describe('when `canEdit` is `true`', () => {
      const provideData = {
        editPath: '/settings',
        canEdit: true,
      };

      describe('when `isGroup` is set to `false`', () => {
        beforeEach(() => {
          createComponent({
            provideData,
          });
          showDropdown();
        });

        it('renders `Project settings` dropdown item', () => {
          const settingsDropdownItem = findProjectSettings();

          expect(settingsDropdownItem.text()).toBe('Project settings');
          expect(settingsDropdownItem.attributes('href')).toBe(provideData.editPath);
        });
      });

      describe('when `isGroup` is set to `true`', () => {
        beforeEach(() => {
          createComponent({
            provideData: {
              ...provideData,
              isGroup: true,
            },
          });
          showDropdown();
        });

        it('renders `Group settings` dropdown item', () => {
          const settingsDropdownItem = findGroupSettings();

          expect(settingsDropdownItem.text()).toBe('Group settings');
          expect(settingsDropdownItem.attributes('href')).toBe(provideData.editPath);
        });
      });
    });

    describe('when `canEdit` is `false`', () => {
      const provideData = {
        editPath: '/settings',
        canEdit: false,
      };

      beforeEach(() => {
        createComponent({
          provideData,
        });
        showDropdown();
      });

      it('does not render dropdown item', () => {
        expect(findGroupSettings().exists()).toBe(false);
        expect(findProjectSettings().exists()).toBe(false);
      });
    });
  });
});
