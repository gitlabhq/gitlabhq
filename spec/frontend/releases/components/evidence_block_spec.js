import { GlLink, GlIcon } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import { nextTick } from 'vue';
import originalRelease from 'test_fixtures/api/releases/release.json';
import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import { truncateSha } from '~/lib/utils/text_utility';
import EvidenceBlock from '~/releases/components/evidence_block.vue';
import ClipboardButton from '~/vue_shared/components/clipboard_button.vue';

describe('Evidence Block', () => {
  let wrapper;
  let release;

  const factory = (options = {}) => {
    wrapper = mount(EvidenceBlock, {
      ...options,
    });
  };

  beforeEach(() => {
    release = convertObjectPropsToCamelCase(originalRelease, { deep: true });

    factory({
      propsData: {
        release,
      },
    });
  });

  it('renders the evidence icon', () => {
    expect(wrapper.findComponent(GlIcon).props('name')).toBe('review-list');
  });

  it('renders the title for the dowload link', () => {
    expect(wrapper.findComponent(GlLink).text()).toMatch(/v1\.1-evidences-[0-9]+\.json/);
  });

  it('renders the correct hover text for the download', () => {
    expect(wrapper.findComponent(GlLink).attributes('title')).toBe('Open evidence JSON in new tab');
  });

  it('renders a link that opens in a new tab', () => {
    expect(wrapper.findComponent(GlLink).attributes().target).toBe('_blank');
  });

  describe('sha text', () => {
    it('renders the short sha initially', () => {
      expect(wrapper.find('.js-short').text()).toBe(truncateSha(release.evidences[0].sha));
    });

    it('renders the long sha after expansion', async () => {
      wrapper.find('.js-text-expander-prepend').trigger('click');

      await nextTick();
      expect(wrapper.find('.js-expanded').text()).toBe(release.evidences[0].sha);
    });
  });

  describe('copy to clipboard button', () => {
    it('renders button', () => {
      expect(wrapper.findComponent(ClipboardButton).exists()).toBe(true);
    });

    it('renders the correct hover text', () => {
      expect(wrapper.findComponent(ClipboardButton).attributes('title')).toBe('Copy evidence SHA');
    });

    it('copies the sha', () => {
      expect(wrapper.findComponent(ClipboardButton).attributes('data-clipboard-text')).toBe(
        release.evidences[0].sha,
      );
    });
  });
});
