import { GlModal } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import GlqlViewSourceModal from '~/glql/components/common/view_source_modal.vue';
import { copyToClipboard } from '~/lib/utils/copy_to_clipboard';

jest.mock('~/lib/utils/copy_to_clipboard');

describe('GlqlViewSourceModal', () => {
  let wrapper;

  const query = 'type = Issue AND state = opened';
  const wrappedQuery = `\`\`\`glql\n${query}\n\`\`\``;

  const createComponent = (props = {}) => {
    wrapper = shallowMountExtended(GlqlViewSourceModal, {
      propsData: {
        query,
        ...props,
      },
    });
  };

  const findModal = () => wrapper.findComponent(GlModal);

  beforeEach(() => {
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
    beforeEach(() => {
      findModal().vm.$emit('primary');
    });

    it('copies the wrapped query to the clipboard', () => {
      expect(copyToClipboard).toHaveBeenCalledWith(wrappedQuery, expect.any(HTMLElement));
    });

    it('copies from inside the modal, so the focus trap cannot cancel the fallback copy', () => {
      const [, container] = copyToClipboard.mock.calls[0];

      expect(container.textContent).toEqual(wrappedQuery);
    });
  });
});
