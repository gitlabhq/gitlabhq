import { shallowMount } from '@vue/test-utils';
import GreetingHeader from '~/homepage/components/greeting_header.vue';

describe('GreetingHeader', () => {
  let wrapper;

  const createComponent = (gonData = {}) => {
    window.gon = {
      current_user_fullname: 'John Doe',
      current_username: 'johndoe',
      current_user_avatar_url: 'avatar.png',
      ...gonData,
    };
    wrapper = shallowMount(GreetingHeader);
  };

  describe('Greeting', () => {
    it('renders greeting with first name', () => {
      createComponent();

      expect(wrapper.find('h1').text()).toBe('Hi, John');
    });

    it('renders greeting with username when first name not available', () => {
      createComponent({ current_user_fullname: null });

      expect(wrapper.find('h1').text()).toBe('Hi, johndoe');
    });

    it('does not render greeting when user has no available name', () => {
      createComponent({ current_user_fullname: null, current_username: null });

      expect(wrapper.find('h1').exists()).toBe(false);
    });

    it('handles single name correctly', () => {
      createComponent({ current_user_fullname: 'Madonna' });

      expect(wrapper.find('h1').text()).toBe('Hi, Madonna');
    });

    it('uses only first name for multi-word names', () => {
      createComponent({ current_user_fullname: 'John Doe Smith Jr' });

      expect(wrapper.find('h1').text()).toBe('Hi, John');
    });

    it('handles empty string name', () => {
      createComponent({ current_user_fullname: '' });

      expect(wrapper.find('h1').text()).toBe('Hi, johndoe');
    });

    it('handles whitespace-only name', () => {
      createComponent({ current_user_fullname: '   ' });

      expect(wrapper.find('h1').text()).toBe('Hi, johndoe');
    });

    it('handles name with extra whitespace', () => {
      createComponent({ current_user_fullname: '  John  Doe  ' });

      expect(wrapper.find('h1').text()).toBe('Hi, John');
    });
  });

  describe('Avatar', () => {
    it('renders avatar with correct source', () => {
      createComponent({ current_user_avatar_url: 'https://gitlab.com/user-avatar.png' });

      expect(wrapper.find('img').exists()).toBe(true);
      expect(wrapper.find('img').element.src).toBe('https://gitlab.com/user-avatar.png');
    });
  });
});
