import { shallowMount } from '@vue/test-utils';
import GreetingHeader from '~/homepage/components/greeting_header.vue';

describe('GreetingHeader', () => {
  let wrapper;

  const createComponent = (gonData = {}) => {
    window.gon = { current_user_fullname: 'John Doe', ...gonData };
    wrapper = shallowMount(GreetingHeader);
  };

  it('renders welcome message with first name', () => {
    createComponent();

    expect(wrapper.find('p').text()).toBe('Welcome John,');
  });

  it('does not render welcome message when user has no name', () => {
    createComponent({ current_user_fullname: null });

    expect(wrapper.find('p').exists()).toBe(false);
  });

  it('handles single name correctly', () => {
    createComponent({ current_user_fullname: 'Madonna' });

    expect(wrapper.find('p').text()).toBe('Welcome Madonna,');
  });

  it('uses only first name for multi-word names', () => {
    createComponent({ current_user_fullname: 'John Doe Smith Jr' });

    expect(wrapper.find('p').text()).toBe('Welcome John,');
  });

  it('handles empty string name', () => {
    createComponent({ current_user_fullname: '' });

    expect(wrapper.find('p').exists()).toBe(false);
  });

  it('handles whitespace-only name', () => {
    createComponent({ current_user_fullname: '   ' });

    expect(wrapper.find('p').exists()).toBe(false);
  });

  it('handles name with extra whitespace', () => {
    createComponent({ current_user_fullname: '  John  Doe  ' });

    expect(wrapper.find('p').text()).toBe('Welcome John,');
  });
});
