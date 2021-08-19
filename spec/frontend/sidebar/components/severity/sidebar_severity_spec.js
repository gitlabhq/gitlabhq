import { GlDropdown, GlDropdownItem, GlLoadingIcon, GlTooltip, GlSprintf } from '@gitlab/ui';
import { nextTick } from 'vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import createFlash from '~/flash';
import { INCIDENT_SEVERITY, ISSUABLE_TYPES } from '~/sidebar/components/severity/constants';
import updateIssuableSeverity from '~/sidebar/components/severity/graphql/mutations/update_issuable_severity.mutation.graphql';
import SeverityToken from '~/sidebar/components/severity/severity.vue';
import SidebarSeverity from '~/sidebar/components/severity/sidebar_severity.vue';

jest.mock('~/flash');

describe('SidebarSeverity', () => {
  let wrapper;
  let mutate;
  const projectPath = 'gitlab-org/gitlab-test';
  const iid = '1';
  const severity = 'CRITICAL';
  let canUpdate = true;

  function createComponent(props = {}) {
    const propsData = {
      projectPath,
      iid,
      issuableType: ISSUABLE_TYPES.INCIDENT,
      initialSeverity: severity,
      ...props,
    };
    mutate = jest.fn();
    wrapper = shallowMountExtended(SidebarSeverity, {
      propsData,
      provide: {
        canUpdate,
      },
      mocks: {
        $apollo: {
          mutate,
        },
      },
      stubs: {
        GlSprintf,
      },
    });
  }

  beforeEach(() => {
    createComponent();
  });

  afterEach(() => {
    if (wrapper) {
      wrapper.destroy();
    }
  });

  const findSeverityToken = () => wrapper.findAllComponents(SeverityToken);
  const findEditBtn = () => wrapper.findByTestId('editButton');
  const findDropdown = () => wrapper.findComponent(GlDropdown);
  const findCriticalSeverityDropdownItem = () => wrapper.findComponent(GlDropdownItem);
  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const findTooltip = () => wrapper.findComponent(GlTooltip);
  const findCollapsedSeverity = () => wrapper.find({ ref: 'severity' });

  describe('Severity widget', () => {
    it('renders severity dropdown and token', () => {
      expect(findSeverityToken().exists()).toBe(true);
      expect(findDropdown().exists()).toBe(true);
    });

    describe('edit button', () => {
      it('is rendered when `canUpdate` provided as `true`', () => {
        expect(findEditBtn().exists()).toBe(true);
      });

      it('is NOT rendered when `canUpdate` provided as `false`', () => {
        canUpdate = false;
        createComponent();
        expect(findEditBtn().exists()).toBe(false);
      });
    });
  });

  describe('Update severity', () => {
    it('calls `$apollo.mutate` with `updateIssuableSeverity`', () => {
      jest
        .spyOn(wrapper.vm.$apollo, 'mutate')
        .mockResolvedValueOnce({ data: { issueSetSeverity: { issue: { severity } } } });

      findCriticalSeverityDropdownItem().vm.$emit('click');
      expect(wrapper.vm.$apollo.mutate).toHaveBeenCalledWith({
        mutation: updateIssuableSeverity,
        variables: {
          iid,
          projectPath,
          severity,
        },
      });
    });

    it('shows error alert when severity update fails ', () => {
      const errorMsg = 'Something went wrong';
      jest.spyOn(wrapper.vm.$apollo, 'mutate').mockRejectedValueOnce(errorMsg);
      findCriticalSeverityDropdownItem().vm.$emit('click');

      setImmediate(() => {
        expect(createFlash).toHaveBeenCalled();
      });
    });

    it('shows loading icon while updating', async () => {
      let resolvePromise;
      wrapper.vm.$apollo.mutate = jest.fn(
        () =>
          new Promise((resolve) => {
            resolvePromise = resolve;
          }),
      );
      findCriticalSeverityDropdownItem().vm.$emit('click');

      await nextTick();
      expect(findLoadingIcon().exists()).toBe(true);

      resolvePromise();
      await waitForPromises();
      expect(findLoadingIcon().exists()).toBe(false);
    });
  });

  describe('Switch between collapsed/expanded view of the sidebar', () => {
    const HIDDDEN_CLASS = 'gl-display-none';
    const SHOWN_CLASS = 'show';

    describe('collapsed', () => {
      it('should have collapsed icon class', () => {
        expect(findCollapsedSeverity().classes('sidebar-collapsed-icon')).toBe(true);
      });

      it('should display only icon with a tooltip', () => {
        expect(findSeverityToken().at(0).attributes('icononly')).toBe('true');
        expect(findSeverityToken().at(0).attributes('iconsize')).toBe('14');
        expect(findTooltip().text().replace(/\s+/g, ' ')).toContain(
          `Severity: ${INCIDENT_SEVERITY[severity].label}`,
        );
      });

      it('should expand the dropdown on collapsed icon click', async () => {
        wrapper.vm.isDropdownShowing = false;
        await nextTick();
        expect(findDropdown().classes(HIDDDEN_CLASS)).toBe(true);

        findCollapsedSeverity().trigger('click');
        await nextTick();
        expect(findDropdown().classes(SHOWN_CLASS)).toBe(true);
      });
    });

    describe('expanded', () => {
      it('toggles dropdown with edit button', async () => {
        canUpdate = true;
        createComponent();
        wrapper.vm.isDropdownShowing = false;
        await nextTick();
        expect(findDropdown().classes(HIDDDEN_CLASS)).toBe(true);

        findEditBtn().vm.$emit('click');
        await nextTick();
        expect(findDropdown().classes(SHOWN_CLASS)).toBe(true);

        findEditBtn().vm.$emit('click');
        await nextTick();
        expect(findDropdown().classes(HIDDDEN_CLASS)).toBe(true);
      });
    });
  });
});
