import { GlTooltip, GlLink, GlIcon } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { TEST_HOST } from 'helpers/test_constants';
import UserAvatarImage from '~/vue_shared/components/user_avatar/user_avatar_image.vue';
import TitleSuggestionsItem from '~/work_items/components/title_suggestions_item.vue';

describe('Issue title suggestions item component', () => {
  let wrapper;

  function getDate(daysMinus) {
    const today = new Date();
    today.setDate(today.getDate() - daysMinus);

    return today.toISOString();
  }

  function createComponent(suggestion = {}) {
    wrapper = shallowMount(TitleSuggestionsItem, {
      propsData: {
        suggestion: {
          id: 1,
          iid: 1,
          state: 'opened',
          upvotes: 1,
          userNotesCount: 2,
          closedAt: getDate(1),
          createdAt: getDate(3),
          updatedAt: getDate(2),
          confidential: false,
          webUrl: `${TEST_HOST}/test/issue/1`,
          title: 'Test issue',
          author: {
            avatarUrl: `${TEST_HOST}/avatar`,
            name: 'Author Name',
            username: 'author.username',
            webUrl: `${TEST_HOST}/author`,
          },
          ...suggestion,
        },
      },
    });
  }

  const findLink = () => wrapper.findComponent(GlLink);
  const findAuthorLink = () => wrapper.findAllComponents(GlLink).at(1);
  const findIcon = () => wrapper.findComponent(GlIcon);
  const findTooltip = () => wrapper.findComponent(GlTooltip);
  const findUserAvatar = () => wrapper.findComponent(UserAvatarImage);

  it('renders title', () => {
    createComponent();

    expect(wrapper.text()).toContain('Test issue');
  });

  it('renders issue link', () => {
    createComponent();

    expect(findLink().attributes('href')).toBe(`${TEST_HOST}/test/issue/1`);
  });

  it('renders IID', () => {
    createComponent();

    expect(wrapper.text()).toContain('#1');
  });

  describe('opened state', () => {
    it('renders icon', () => {
      createComponent();

      expect(findIcon().props('name')).toBe('issue-open-m');
      expect(findIcon().attributes('class')).toMatch('gl-fill-icon-success');
    });

    it('renders created timeago', () => {
      createComponent({
        closedAt: '',
      });

      expect(findTooltip().text()).toContain('Opened');
      expect(findTooltip().text()).toContain('3 days ago');
    });
  });

  describe('closed state', () => {
    it('renders icon', () => {
      createComponent({
        state: 'closed',
      });

      expect(findIcon().props('name')).toBe('issue-close');
      expect(findIcon().attributes('class')).toMatch('gl-fill-icon-info');
    });

    it('renders closed timeago', () => {
      createComponent();

      expect(findTooltip().text()).toContain('Opened');
      expect(findTooltip().text()).toContain('1 day ago');
    });
  });

  describe('author', () => {
    it('renders author info', () => {
      createComponent();

      expect(findAuthorLink().text()).toContain('Author Name');
      expect(findAuthorLink().text()).toContain('@author.username');
    });

    it('renders author image', () => {
      createComponent();

      expect(findUserAvatar().props('imgSrc')).toBe(`${TEST_HOST}/avatar`);
    });
  });

  describe('confidential', () => {
    it('renders confidential icon', () => {
      createComponent({
        confidential: true,
      });

      expect(findIcon().props('name')).toBe('eye-slash');
      expect(findIcon().attributes('variant')).toBe('warning');
      expect(findIcon().attributes('title')).toBe('Confidential');
    });
  });
});
