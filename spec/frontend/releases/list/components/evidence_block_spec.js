import { mount, createLocalVue } from '@vue/test-utils';
import { GlLink } from '@gitlab/ui';
import { truncateSha } from '~/lib/utils/text_utility';
import Icon from '~/vue_shared/components/icon.vue';
import { release } from '../../mock_data';
import EvidenceBlock from '~/releases/list/components/evidence_block.vue';
import ClipboardButton from '~/vue_shared/components/clipboard_button.vue';

describe('Evidence Block', () => {
  let wrapper;

  const factory = (options = {}) => {
    const localVue = createLocalVue();

    wrapper = mount(localVue.extend(EvidenceBlock), {
      localVue,
      ...options,
    });
  };

  beforeEach(() => {
    factory({
      propsData: {
        release,
      },
    });
  });

  afterEach(() => {
    wrapper.destroy();
  });

  it('renders the evidence icon', () => {
    expect(wrapper.find(Icon).props('name')).toBe('review-list');
  });

  it('renders the title for the dowload link', () => {
    expect(wrapper.find(GlLink).text()).toBe(`${release.tag_name}-evidence.json`);
  });

  it('renders the correct hover text for the download', () => {
    expect(wrapper.find(GlLink).attributes('data-original-title')).toBe('Download evidence JSON');
  });

  it('renders the correct file link for download', () => {
    expect(wrapper.find(GlLink).attributes().download).toBe(`${release.tag_name}-evidence.json`);
  });

  describe('sha text', () => {
    it('renders the short sha initially', () => {
      expect(wrapper.find('.js-short').text()).toBe(truncateSha(release.evidence_sha));
    });

    it('renders the long sha after expansion', () => {
      wrapper.find('.js-text-expander-prepend').trigger('click');
      expect(wrapper.find('.js-expanded').text()).toBe(release.evidence_sha);
    });
  });

  describe('copy to clipboard button', () => {
    it('renders button', () => {
      expect(wrapper.find(ClipboardButton).exists()).toBe(true);
    });

    it('renders the correct hover text', () => {
      expect(wrapper.find(ClipboardButton).attributes('data-original-title')).toBe(
        'Copy commit SHA',
      );
    });

    it('copies the sha', () => {
      expect(wrapper.find(ClipboardButton).attributes('data-clipboard-text')).toBe(
        release.evidence_sha,
      );
    });
  });
});
