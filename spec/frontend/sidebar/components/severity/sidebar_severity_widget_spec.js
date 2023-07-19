import { GlCollapsibleListbox, GlLoadingIcon, GlTooltip, GlSprintf } from '@gitlab/ui';
import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { createAlert } from '~/alert';
import { TYPE_INCIDENT } from '~/issues/constants';
import { INCIDENT_SEVERITY } from '~/sidebar/constants';
import updateIssuableSeverity from '~/sidebar/queries/update_issuable_severity.mutation.graphql';
import SeverityToken from '~/sidebar/components/severity/severity.vue';
import SidebarSeverityWidget from '~/sidebar/components/severity/sidebar_severity_widget.vue';

jest.mock('~/alert');

Vue.use(VueApollo);

describe('SidebarSeverityWidget', () => {
  let wrapper;
  let mockApollo;
  const projectPath = 'gitlab-org/gitlab-test';
  const iid = '1';
  const severity = 'CRITICAL';

  function createComponent({ props, canUpdate = true, mutationMock } = {}) {
    mockApollo = createMockApollo([[updateIssuableSeverity, mutationMock]]);

    const propsData = {
      projectPath,
      iid,
      issuableType: TYPE_INCIDENT,
      initialSeverity: severity,
      ...props,
    };

    wrapper = mountExtended(SidebarSeverityWidget, {
      propsData,
      provide: {
        canUpdate,
      },
      apolloProvider: mockApollo,
      stubs: {
        GlSprintf,
      },
    });
  }

  afterEach(() => {
    mockApollo = null;
  });

  const findSeverityToken = () => wrapper.findAllComponents(SeverityToken);
  const findEditBtn = () => wrapper.findByTestId('edit-button');
  const findDropdown = () => wrapper.findComponent(GlCollapsibleListbox);
  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const findTooltip = () => wrapper.findComponent(GlTooltip);
  const findCollapsedSeverity = () => wrapper.findComponent({ ref: 'severity' });

  describe('Severity widget', () => {
    it('renders severity dropdown and token', () => {
      createComponent();

      expect(findSeverityToken().exists()).toBe(true);
      expect(findDropdown().exists()).toBe(true);
    });

    describe('edit button', () => {
      it('is rendered when `canUpdate` provided as `true`', () => {
        createComponent();

        expect(findEditBtn().exists()).toBe(true);
      });

      it('is NOT rendered when `canUpdate` provided as `false`', () => {
        createComponent({ canUpdate: false });

        expect(findEditBtn().exists()).toBe(false);
      });
    });
  });

  describe('Update severity', () => {
    it('calls mutate with `updateIssuableSeverity`', () => {
      const mutationMock = jest.fn().mockResolvedValue({
        data: { issueSetSeverity: { issue: { severity } } },
      });
      createComponent({ mutationMock });

      findDropdown().vm.$emit('select', severity);

      expect(mutationMock).toHaveBeenCalledWith({
        iid,
        projectPath,
        severity,
      });
    });

    it('shows error alert when severity update fails', async () => {
      const mutationMock = jest.fn().mockRejectedValue('Something went wrong');
      createComponent({ mutationMock });

      findDropdown().vm.$emit('select', severity);
      await waitForPromises();

      expect(createAlert).toHaveBeenCalled();
    });

    it('shows loading icon while updating', async () => {
      const mutationMock = jest.fn().mockRejectedValue({});
      createComponent({ mutationMock });

      findDropdown().vm.$emit('select', severity);
      await nextTick();

      expect(findLoadingIcon().exists()).toBe(true);

      await waitForPromises();

      expect(findLoadingIcon().exists()).toBe(false);
    });
  });

  describe('Switch between collapsed/expanded view of the sidebar', () => {
    describe('collapsed', () => {
      beforeEach(() => {
        createComponent({ canUpdate: false });
      });

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
