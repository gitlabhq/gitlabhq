import { nextTick } from 'vue';
import { GlSprintf } from '@gitlab/ui';
import { mountExtended, shallowMountExtended } from 'helpers/vue_test_utils_helper';
import PickUpWidget from '~/homepage/components/pick_up_widget.vue';
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';
import { lastPushEvent } from './mocks/last_push_event_mock';

describe('PickUpWidget', () => {
  let wrapper;

  const defaultProps = {
    lastPushEvent,
  };

  const findWidget = () => wrapper.findByTestId('pick-up-widget-container');
  const findCreateMrButton = () => wrapper.findByTestId('create-merge-request-button');
  const findDismissButton = () => wrapper.findByTestId('dismiss-button');
  const findProjectLink = () => wrapper.findByTestId('project-link');
  const findTimeAgoTooltip = () => wrapper.findComponent(TimeAgoTooltip);

  function createShallowWrapper(props = {}) {
    wrapper = shallowMountExtended(PickUpWidget, {
      propsData: {
        ...defaultProps,
        ...props,
      },
      stubs: {
        GlSprintf,
      },
    });
  }

  function createWrapper(props = {}) {
    wrapper = mountExtended(PickUpWidget, {
      propsData: {
        ...defaultProps,
        ...props,
      },
      stubs: {
        GlSprintf,
      },
    });
  }

  beforeEach(() => {
    createShallowWrapper();
  });

  it('displays the push message with branch name', () => {
    expect(wrapper.text()).toContain('You published branch');
    expect(wrapper.text()).toContain('feature-branch');
  });

  it('renders the project link with correct href', () => {
    const projectLink = findProjectLink();

    expect(projectLink.attributes('href')).toBe('https://example.com/project-path');
    expect(projectLink.text()).toBe('Test Project');
  });

  it('renders the time ago tooltip', () => {
    const timeAgoTooltip = findTimeAgoTooltip();

    expect(timeAgoTooltip.props('time')).toBe('2023-01-01T12:00:00Z');
  });

  it('renders the create merge request button when createMrPath is provided', () => {
    const createMrButton = findCreateMrButton();

    expect(createMrButton.attributes('href')).toBe(
      '/group/test-project/-/merge_requests/new?merge_request%5Bsource_branch%5D=feature-branch',
    );
    expect(createMrButton.text()).toBe('Create merge request');
  });

  it('renders the dismiss button', () => {
    const dismissButton = findDismissButton();

    expect(dismissButton.text()).toBe('Dismiss');
  });

  describe('when create MR button should not be shown', () => {
    it('does not render the create MR button when createMrPath is empty', () => {
      createShallowWrapper({ lastPushEvent: { create_mr_path: '' } });

      expect(findCreateMrButton().exists()).toBe(false);
    });

    it('does not render the create MR button when createMrPath is null', () => {
      createShallowWrapper({ lastPushEvent: { create_mr_path: null } });

      expect(findCreateMrButton().exists()).toBe(false);
    });
  });

  describe('when project data is missing', () => {
    beforeEach(() => {
      createShallowWrapper({
        lastPushEvent: {
          ...lastPushEvent,
          project: null,
        },
      });
    });

    it('does not display the project link', () => {
      expect(findProjectLink().exists()).toBe(false);
    });
  });

  describe('when there is no creation time of the push event', () => {
    it('does not render the time ago tooltip', () => {
      createShallowWrapper({
        lastPushEvent: {
          ...lastPushEvent,
          created_at: null,
        },
      });
      const timeAgoTooltip = findTimeAgoTooltip();

      expect(timeAgoTooltip.exists()).toBe(false);
    });
  });

  describe('dismissal functionality', () => {
    beforeEach(() => {
      localStorage.clear();
      createWrapper();
    });

    it('hides the widget when dismissed', async () => {
      expect(findWidget().exists()).toBe(true);

      findDismissButton().vm.$emit('click');
      await nextTick();

      expect(findWidget().exists()).toBe(false);
    });

    it('updates localStorage value to true', async () => {
      expect(findWidget().exists()).toBe(true);

      findDismissButton().vm.$emit('click');
      await nextTick();
      wrapper.destroy();
      createWrapper();
      await nextTick();

      expect(findWidget().exists()).toBe(false);
    });
  });
});
