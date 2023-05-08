import { GlSprintf } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { createMockDirective, getBinding } from 'helpers/vue_mock_directive';
import DeleteEnvironmentModal from '~/environments/components/delete_environment_modal.vue';
import EnvironmentsDetailHeader from '~/environments/components/environments_detail_header.vue';
import StopEnvironmentModal from '~/environments/components/stop_environment_modal.vue';
import TimeAgo from '~/vue_shared/components/time_ago_tooltip.vue';
import { createEnvironment } from './mock_data';

describe('Environments detail header component', () => {
  const cancelAutoStopPath = '/my-environment/cancel/path';
  const terminalPath = '/my-environment/terminal/path';
  const metricsPath = '/my-environment/metrics/path';
  const updatePath = '/my-environment/edit/path';

  let wrapper;

  const findHeader = () => wrapper.findByRole('heading');
  const findAutoStopsAt = () => wrapper.findByTestId('auto-stops-at');
  const findCancelAutoStopAtButton = () => wrapper.findByTestId('cancel-auto-stop-button');
  const findCancelAutoStopAtForm = () => wrapper.findByTestId('cancel-auto-stop-form');
  const findTerminalButton = () => wrapper.findByTestId('terminal-button');
  const findExternalUrlButton = () => wrapper.findComponentByTestId('external-url-button');
  const findMetricsButton = () => wrapper.findByTestId('metrics-button');
  const findEditButton = () => wrapper.findByTestId('edit-button');
  const findStopButton = () => wrapper.findByTestId('stop-button');
  const findDestroyButton = () => wrapper.findByTestId('destroy-button');
  const findStopEnvironmentModal = () => wrapper.findComponent(StopEnvironmentModal);
  const findDeleteEnvironmentModal = () => wrapper.findComponent(DeleteEnvironmentModal);

  const buttons = [
    ['Cancel Auto Stop At', findCancelAutoStopAtButton],
    ['Terminal', findTerminalButton],
    ['External Url', findExternalUrlButton],
    ['Metrics', findMetricsButton],
    ['Edit', findEditButton],
    ['Stop', findStopButton],
    ['Destroy', findDestroyButton],
  ];

  const createWrapper = ({ props }) => {
    wrapper = shallowMountExtended(EnvironmentsDetailHeader, {
      stubs: {
        GlSprintf,
        TimeAgo,
      },
      directives: {
        GlTooltip: createMockDirective('gl-tooltip'),
      },
      propsData: {
        canAdminEnvironment: false,
        canUpdateEnvironment: false,
        canStopEnvironment: false,
        canDestroyEnvironment: false,
        ...props,
      },
    });
  };

  describe('default state with minimal access', () => {
    beforeEach(() => {
      createWrapper({ props: { environment: createEnvironment({ externalUrl: null }) } });
    });

    it('displays the environment name', () => {
      expect(findHeader().text()).toBe('My environment');
    });

    it('does not display an auto stops at text', () => {
      expect(findAutoStopsAt().exists()).toBe(false);
    });

    it.each(buttons)('does not display button: %s', (_, findSelector) => {
      expect(findSelector().exists()).toBe(false);
    });

    it('does not display stop environment modal', () => {
      expect(findStopEnvironmentModal().exists()).toBe(false);
    });

    it('does not display delete environment modal', () => {
      expect(findDeleteEnvironmentModal().exists()).toBe(false);
    });
  });

  describe('when auto stops at is enabled and environment is available', () => {
    beforeEach(() => {
      const now = new Date();
      const tomorrow = new Date();
      tomorrow.setDate(now.getDate() + 1);
      createWrapper({
        props: {
          environment: createEnvironment({ autoStopAt: tomorrow.toISOString() }),
          cancelAutoStopPath,
        },
      });
    });

    it('displays a text that describes when the environment is going to be stopped', () => {
      expect(findAutoStopsAt().text()).toBe('Auto stops in 1 day');
    });

    it('displays a cancel auto stops at button with a form to make a post request', () => {
      const button = findCancelAutoStopAtButton();
      const form = findCancelAutoStopAtForm();
      expect(form.attributes('action')).toBe(cancelAutoStopPath);
      expect(form.attributes('method')).toBe('POST');
      expect(button.props('icon')).toBe('thumbtack');
      expect(button.attributes('type')).toBe('submit');
    });

    it('includes a csrf token', () => {
      const input = findCancelAutoStopAtForm().find('input');
      expect(input.attributes('name')).toBe('authenticity_token');
    });
  });

  describe('when auto stops at is enabled and environment is unavailable (already stopped)', () => {
    beforeEach(() => {
      const now = new Date();
      const tomorrow = new Date();
      tomorrow.setDate(now.getDate() + 1);
      createWrapper({
        props: {
          environment: createEnvironment({
            autoStopAt: tomorrow.toISOString(),
            isAvailable: false,
          }),
          cancelAutoStopPath,
        },
      });
    });

    it('does not display a text that describes when the environment is going to be stopped', () => {
      expect(findAutoStopsAt().exists()).toBe(false);
    });

    it('displays a cancel auto stops at button with correct path', () => {
      expect(findCancelAutoStopAtButton().exists()).toBe(false);
    });
  });

  describe('when has a terminal', () => {
    beforeEach(() => {
      createWrapper({
        props: {
          environment: createEnvironment({ hasTerminals: true }),
          canAdminEnvironment: true,
          terminalPath,
        },
      });
    });

    it('displays the terminal button with correct path', () => {
      expect(findTerminalButton().attributes('href')).toBe(terminalPath);
    });
  });

  describe('when has an external url enabled', () => {
    const externalUrl = 'https://example.com/my-environment/external/url';

    beforeEach(() => {
      createWrapper({
        props: {
          environment: createEnvironment({ hasTerminals: true, externalUrl }),
        },
      });
    });

    it('displays the external url button with correct path', () => {
      expect(findExternalUrlButton().attributes('href')).toBe(externalUrl);
      expect(findExternalUrlButton().props('isUnsafeLink')).toBe(true);
    });
  });

  describe('when metrics are enabled', () => {
    beforeEach(() => {
      createWrapper({
        props: {
          environment: createEnvironment({ metricsUrl: 'my metrics url' }),
          metricsPath,
        },
      });
    });

    it('displays the metrics button with correct path', () => {
      expect(findMetricsButton().attributes('href')).toBe(metricsPath);
    });

    it('uses a gl tooltip for the title', () => {
      const button = findMetricsButton();
      const tooltip = getBinding(button.element, 'gl-tooltip');

      expect(tooltip).toBeDefined();
      expect(button.attributes('title')).toBe('See metrics');
    });
  });

  describe('when has all admin rights', () => {
    beforeEach(() => {
      createWrapper({
        props: {
          environment: createEnvironment(),
          canAdminEnvironment: true,
          canStopEnvironment: true,
          canUpdateEnvironment: true,
          updatePath,
        },
      });
    });

    it('displays the edit button with correct path', () => {
      expect(findEditButton().attributes('href')).toBe(updatePath);
    });

    it('displays the stop button with correct icon', () => {
      expect(findStopButton().attributes('icon')).toBe('stop');
    });

    it('displays stop environment modal', () => {
      expect(findStopEnvironmentModal().exists()).toBe(true);
    });
  });

  describe('when the environment is unavailable and user has destroy permissions', () => {
    beforeEach(() => {
      createWrapper({
        props: {
          environment: createEnvironment({ isAvailable: false }),
          canDestroyEnvironment: true,
        },
      });
    });

    it('displays a delete button', () => {
      expect(findDestroyButton().exists()).toBe(true);
    });

    it('displays delete environment modal', () => {
      expect(findDeleteEnvironmentModal().exists()).toBe(true);
    });
  });
});
