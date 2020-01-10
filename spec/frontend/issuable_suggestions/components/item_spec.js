import { shallowMount } from '@vue/test-utils';
import { GlTooltip, GlLink } from '@gitlab/ui';
import Icon from '~/vue_shared/components/icon.vue';
import UserAvatarImage from '~/vue_shared/components/user_avatar/user_avatar_image.vue';
import Suggestion from '~/issuable_suggestions/components/item.vue';
import mockData from '../mock_data';

describe('Issuable suggestions suggestion component', () => {
  let vm;

  function createComponent(suggestion = {}) {
    vm = shallowMount(Suggestion, {
      propsData: {
        suggestion: {
          ...mockData(),
          ...suggestion,
        },
      },
      attachToDocument: true,
    });
  }

  afterEach(() => {
    vm.destroy();
  });

  it('renders title', () => {
    createComponent();

    expect(vm.text()).toContain('Test issue');
  });

  it('renders issue link', () => {
    createComponent();

    const link = vm.find(GlLink);

    expect(link.attributes('href')).toBe(`${gl.TEST_HOST}/test/issue/1`);
  });

  it('renders IID', () => {
    createComponent();

    expect(vm.text()).toContain('#1');
  });

  describe('opened state', () => {
    it('renders icon', () => {
      createComponent();

      const icon = vm.find(Icon);

      expect(icon.props('name')).toBe('issue-open-m');
    });

    it('renders created timeago', () => {
      createComponent({
        closedAt: '',
      });

      const tooltip = vm.find(GlTooltip);

      expect(tooltip.find('.d-block').text()).toContain('Opened');
      expect(tooltip.text()).toContain('3 days ago');
    });
  });

  describe('closed state', () => {
    it('renders icon', () => {
      createComponent({
        state: 'closed',
      });

      const icon = vm.find(Icon);

      expect(icon.props('name')).toBe('issue-close');
    });

    it('renders closed timeago', () => {
      createComponent();

      const tooltip = vm.find(GlTooltip);

      expect(tooltip.find('.d-block').text()).toContain('Opened');
      expect(tooltip.text()).toContain('1 day ago');
    });
  });

  describe('author', () => {
    it('renders author info', () => {
      createComponent();

      const link = vm.findAll(GlLink).at(1);

      expect(link.text()).toContain('Author Name');
      expect(link.text()).toContain('@author.username');
    });

    it('renders author image', () => {
      createComponent();

      const image = vm.find(UserAvatarImage);

      expect(image.props('imgSrc')).toBe(`${gl.TEST_HOST}/avatar`);
    });
  });

  describe('counts', () => {
    it('renders upvotes count', () => {
      createComponent();

      const count = vm.findAll('.suggestion-counts span').at(0);

      expect(count.text()).toContain('1');
      expect(count.find(Icon).props('name')).toBe('thumb-up');
    });

    it('renders notes count', () => {
      createComponent();

      const count = vm.findAll('.suggestion-counts span').at(1);

      expect(count.text()).toContain('2');
      expect(count.find(Icon).props('name')).toBe('comment');
    });
  });

  describe('confidential', () => {
    it('renders confidential icon', () => {
      createComponent({
        confidential: true,
      });

      const icon = vm.find(Icon);

      expect(icon.props('name')).toBe('eye-slash');
      expect(icon.attributes('title')).toBe('Confidential');
    });
  });
});
