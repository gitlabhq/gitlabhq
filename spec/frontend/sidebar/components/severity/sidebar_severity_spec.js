import { GlDropdown, GlDropdownItem, GlLoadingIcon, GlTooltip, GlSprintf } from '@gitlab/ui';
import { nextTick } from 'vue';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { createAlert } from '~/flash';
import { TYPE_INCIDENT } from '~/issues/constants';
import { INCIDENT_SEVERITY } from '~/sidebar/constants';
import updateIssuableSeverity from '~/sidebar/queries/update_issuable_severity.mutation.graphql';
import SeverityToken from '~/sidebar/components/severity/severity.vue';
import SidebarSeverityWidget from '~/sidebar/components/severity/sidebar_severity_widget.vue';

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
      issuableType: TYPE_INCIDENT,
      initialSeverity: severity,
      ...props,
    };
    mutate = jest.fn();
    wrapper = mountExtended(SidebarSeverityWidget, {
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
    wrapper.destroy();
  });

  const findSeverityToken = () => wrapper.findAllComponents(SeverityToken);
  const findEditBtn = () => wrapper.findByTestId('edit-button');
  const findDropdown = () => wrapper.findComponent(GlDropdown);
  const findCriticalSeverityDropdownItem = () => wrapper.findComponent(GlDropdownItem);
  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const findTooltip = () => wrapper.findComponent(GlTooltip);
  const findCollapsedSeverity = () => wrapper.findComponent({ ref: 'severity' });

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

    it('shows error alert when severity update fails', async () => {
      const errorMsg = 'Something went wrong';
      jest.spyOn(wrapper.vm.$apollo, 'mutate').mockRejectedValueOnce(errorMsg);
      findCriticalSeverityDropdownItem().vm.$emit('click');

      await waitForPromises();

      expect(createAlert).toHaveBeenCalled();
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
    describe('collapsed', () => {
      it('should have collapsed icon class', () => {
        expect(findCollapsedSeverity().classes('sidebar-collapsed-icon')).toBe(true);
      });

      it('should display only icon with a tooltip', () => {
        expect(findSeverityToken().exists()).toBe(true);
        expect(findTooltip().text()).toContain(INCIDENT_SEVERITY[severity].label);
        expect(findEditBtn().exists()).toBe(false);
      });
    });

    describe('expanded', () => {
      it('toggles dropdown with edit button', async () => {
        canUpdate = true;
        createComponent();
        await nextTick();
        expect(findDropdown().isVisible()).toBe(false);

        findEditBtn().vm.$emit('click');
        await nextTick();
        expect(findDropdown().isVisible()).toBe(true);

        findEditBtn().vm.$emit('click');
        await nextTick();
        expect(findDropdown().isVisible()).toBe(false);
      });
    });
  });
});
