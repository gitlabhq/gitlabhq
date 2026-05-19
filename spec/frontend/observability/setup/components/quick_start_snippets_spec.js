import { GlTabs, GlTab } from '@gitlab/ui';
import { nextTick } from 'vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { mockTracking, unmockTracking } from 'helpers/tracking_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { copyToClipboard } from '~/lib/utils/copy_to_clipboard';
import QuickStartSnippets from '~/observability/setup/components/quick_start_snippets.vue';
import { SNIPPET_COPIED_TIMEOUT } from '~/observability/setup/constants';

jest.mock('~/lib/utils/copy_to_clipboard');
jest.mock('~/sentry/sentry_browser_wrapper');

describe('QuickStartSnippets', () => {
  let wrapper;
  let trackingSpy;

  const defaultProps = {
    endpoint: 'https://observe.gitlab.com',
  };

  const createComponent = (props = {}) => {
    wrapper = shallowMountExtended(QuickStartSnippets, {
      propsData: {
        ...defaultProps,
        ...props,
      },
      mocks: {
        $toast: { show: jest.fn() },
      },
    });
  };

  beforeEach(() => {
    trackingSpy = mockTracking(undefined, undefined, jest.spyOn);
  });

  afterEach(() => {
    unmockTracking();
    global.JEST_DEBOUNCE_THROTTLE_TIMEOUT = undefined;
  });

  const findTabs = () => wrapper.findComponent(GlTabs);
  const findCopyButton = () => wrapper.findByTestId('copy-snippet-button');

  const triggerCopy = async () => {
    await findCopyButton().vm.$emit('click');
    await waitForPromises();
  };

  describe('rendering', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders heading, description, and copy button', () => {
      expect(wrapper.find('h3').text()).toBe('Quick start');
      expect(wrapper.find('p').text()).toContain(
        'Add this to your application to start sending traces to GitLab.',
      );
      expect(findCopyButton().exists()).toBe(true);
      expect(findCopyButton().text()).toBe('Copy');
    });

    it('renders all language tabs', () => {
      const tabTitles = findTabs()
        .findAllComponents(GlTab)
        .wrappers.map((tab) => tab.attributes('title'));

      expect(tabTitles).toEqual(['Ruby', 'Python', 'Go', 'Node.js', 'Java', '.NET']);
    });
  });

  describe('snippet content', () => {
    it.each([
      ['default endpoint', {}, 'https://observe.gitlab.com/v1/traces'],
      [
        'custom endpoint',
        { endpoint: 'https://custom.endpoint.com' },
        'https://custom.endpoint.com/v1/traces',
      ],
    ])('includes %s in the snippet', (_, props, expected) => {
      createComponent(props);
      expect(wrapper.find('code').text()).toContain(expected);
    });
  });

  describe('tab switching', () => {
    beforeEach(() => {
      createComponent();
    });

    it('tracks the language switch event', () => {
      findTabs().vm.$emit('input', 2);

      expect(trackingSpy).toHaveBeenCalledWith(undefined, 'switch_quick_start_language', {
        label: 'go',
      });
    });

    it('updates the displayed snippet when switching tabs', async () => {
      findTabs().vm.$emit('input', 3);
      await nextTick();

      expect(wrapper.findAll('code').at(3).text()).toContain('NodeSDK');
    });
  });

  describe('copy to clipboard', () => {
    beforeEach(() => {
      copyToClipboard.mockResolvedValue();
      createComponent();
    });

    it('copies the active snippet and tracks the event', async () => {
      trackingSpy.mockClear();

      await triggerCopy();

      expect(copyToClipboard).toHaveBeenCalledWith(
        expect.stringContaining('https://observe.gitlab.com/v1/traces'),
      );
      expect(trackingSpy).toHaveBeenCalledWith(undefined, 'copy_quick_start_snippet', {
        label: 'ruby',
      });
    });

    it('shows "Copied!" text then resets after timeout', async () => {
      global.JEST_DEBOUNCE_THROTTLE_TIMEOUT = SNIPPET_COPIED_TIMEOUT;
      copyToClipboard.mockResolvedValue();
      createComponent();

      await triggerCopy();

      expect(findCopyButton().text()).toBe('Copied!');

      jest.advanceTimersByTime(SNIPPET_COPIED_TIMEOUT);
      await nextTick();

      expect(findCopyButton().text()).toBe('Copy');
    });

    it('shows toast on copy failure', async () => {
      copyToClipboard.mockRejectedValue(new Error('fail'));
      createComponent();

      await triggerCopy();

      expect(wrapper.vm.$toast.show).toHaveBeenCalledWith('Failed to copy snippet');
    });
  });
});
