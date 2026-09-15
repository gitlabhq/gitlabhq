import { GlModal } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import GlqlViewSourceModal from '~/glql/components/common/view_source_modal.vue';
import { copyToClipboard } from '~/lib/utils/copy_to_clipboard';

jest.mock('~/lib/utils/copy_to_clipboard');

describe('GlqlViewSourceModal', () => {
  let wrapper;
  let toastShow;

  const query = 'type = Issue AND state = opened';
  const wrappedQuery = `\`\`\`glql\n${query}\n\`\`\``;

  const createComponent = (props = {}) => {
    wrapper = shallowMountExtended(GlqlViewSourceModal, {
      propsData: {
        query,
        ...props,
      },
      mocks: {
        $toast: { show: toastShow },
      },
    });
  };

  const findModal = () => wrapper.findComponent(GlModal);
  const triggerPrimaryAction = async () => {
    findModal().vm.$emit('primary');
    await waitForPromises();
  };

  beforeEach(() => {
    toastShow = jest.fn();
    copyToClipboard.mockResolvedValue();
    createComponent();
  });

  it('renders the query wrapped in a glql code block', () => {
    expect(findModal().text()).toContain(wrappedQuery);
  });

  it('configures the primary and cancel actions', () => {
    expect(findModal().props('actionPrimary')).toEqual({ text: 'Copy source' });
    expect(findModal().props('actionCancel')).toEqual({ text: 'Close' });
  });

  it('renders the given title', () => {
    createComponent({ title: 'Panel query' });

    expect(findModal().props('title')).toBe('Panel query');
  });

  it('gives each instance a unique modal id', () => {
    const firstModalId = findModal().props('modalId');
    expect(firstModalId).toEqual(expect.stringContaining('glql-view-source-modal-'));

    createComponent();

    expect(findModal().props('modalId')).not.toBe(firstModalId);
  });

  describe('visibility', () => {
    it('is hidden by default', () => {
      expect(findModal().props('visible')).toBe(false);
    });

    it('is shown when the visible prop is set', () => {
      createComponent({ visible: true });

      expect(findModal().props('visible')).toBe(true);
    });

    it('emits change when the modal visibility changes', () => {
      findModal().vm.$emit('change', true);

      expect(wrapper.emitted('change')).toEqual([[true]]);
    });
  });

  describe('when the primary action is triggered', () => {
    beforeEach(async () => {
      await triggerPrimaryAction();
    });

    it('copies the wrapped query to the clipboard', () => {
      expect(copyToClipboard).toHaveBeenCalledWith(wrappedQuery, expect.any(HTMLElement));
    });

    it('copies from inside the modal, so the focus trap cannot cancel the fallback copy', () => {
      const [, container] = copyToClipboard.mock.calls[0];

      expect(container.textContent).toEqual(wrappedQuery);
    });

    it('shows a success toast', () => {
      expect(toastShow).toHaveBeenCalledTimes(1);
      expect(toastShow).toHaveBeenCalledWith('Source copied to clipboard');
    });
  });

  describe('when copying fails', () => {
    beforeEach(async () => {
      copyToClipboard.mockRejectedValue(new Error('Clipboard permission denied'));

      await triggerPrimaryAction();
    });

    it('shows an error toast', () => {
      expect(toastShow).toHaveBeenCalledTimes(1);
      expect(toastShow).toHaveBeenCalledWith('Failed to copy source to clipboard');
    });
  });
});
