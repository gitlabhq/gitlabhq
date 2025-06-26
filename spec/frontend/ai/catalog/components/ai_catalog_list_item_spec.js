import { GlBadge, GlMarkdown, GlLink, GlAvatar } from '@gitlab/ui';

import { shallowMountExtended } from 'helpers/vue_test_utils_helper';

import AiCatalogListItem from '~/ai/catalog/components/ai_catalog_list_item.vue';

describe('AiCatalogListItem', () => {
  let wrapper;

  const mockItem = {
    id: 1,
    name: 'Test AI Agent',
    model: 'gpt-4',
    type: 'Assistant',
    version: 'v1.2.0',
    description: 'A helpful AI assistant for testing purposes',
    releasedAt: '2024-01-15T10:30:00Z',
    verified: true,
  };

  const mockItemWithoutOptionalFields = {
    id: 2,
    name: 'Basic Agent',
    model: 'claude-3',
    type: 'Chatbot',
    version: 'v1.0.0',
    verified: false,
  };

  const createComponent = (item = mockItem) => {
    wrapper = shallowMountExtended(AiCatalogListItem, {
      propsData: {
        item,
      },
    });
  };

  const findAvatar = () => wrapper.findComponent(GlAvatar);
  const findLink = () => wrapper.findComponent(GlLink);
  const findBadges = () => wrapper.findAllComponents(GlBadge);
  const findTypeBadge = () => findBadges().at(0);
  const findVersionBadge = () => findBadges().at(1);
  const findMarkdown = () => wrapper.findComponent(GlMarkdown);
  const findVerifiedIcon = () => wrapper.findByTestId('tanuki-verified-icon');

  describe('component rendering', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders the list item container with correct attributes', () => {
      const listItem = wrapper.findByTestId('ai-catalog-list-item');

      expect(listItem.exists()).toBe(true);
      expect(listItem.element.tagName).toBe('LI');
    });

    it('renders avatar with correct props', () => {
      const avatar = findAvatar();

      expect(avatar.exists()).toBe(true);
      expect(avatar.props('alt')).toBe('Test AI Agent avatar');
      expect(avatar.props('entityName')).toBe('Test AI Agent');
      expect(avatar.props('size')).toBe(48);
    });

    it('displays the model name', () => {
      expect(wrapper.text()).toContain('gpt-4');
    });

    it('displays the agent name as a button', () => {
      const link = findLink();

      expect(link.exists()).toBe(true);
      expect(link.text()).toBe('Test AI Agent');
    });

    it('displays type badge with correct variant and text', () => {
      const typeBadge = findTypeBadge();

      expect(typeBadge.exists()).toBe(true);
      expect(typeBadge.props('variant')).toBe('neutral');
      expect(typeBadge.text()).toBe('Assistant');
    });

    it('displays version badge with correct variant and text', () => {
      const versionBadge = findVersionBadge();

      expect(versionBadge.exists()).toBe(true);
      expect(versionBadge.props('variant')).toBe('info');
      expect(versionBadge.text()).toBe('v1.2.0');
    });

    it('displays description when provided', () => {
      const markdown = findMarkdown();

      expect(markdown.exists()).toBe(true);
      expect(markdown.text()).toBe('A helpful AI assistant for testing purposes');
      expect(markdown.props('compact')).toBe(true);
    });
  });

  describe('verified icon', () => {
    it('shows verified icon when item is verified', () => {
      createComponent();

      const verifiedIcon = findVerifiedIcon();
      expect(verifiedIcon.exists()).toBe(true);
      expect(verifiedIcon.props('name')).toBe('tanuki-verified');
      expect(verifiedIcon.props('size')).toBe(16);
    });

    it('does not show verified icon when item is not verified', () => {
      createComponent(mockItemWithoutOptionalFields);

      const verifiedIcon = findVerifiedIcon();
      expect(verifiedIcon.exists()).toBe(false);
    });
  });

  describe('description handling', () => {
    it('shows description when provided', () => {
      createComponent();

      expect(findMarkdown().exists()).toBe(true);
    });

    it('does not show description when not provided', () => {
      createComponent(mockItemWithoutOptionalFields);

      expect(findMarkdown().exists()).toBe(false);
    });
  });
});
