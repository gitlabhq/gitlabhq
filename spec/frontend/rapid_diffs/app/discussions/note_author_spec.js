import { shallowMount } from '@vue/test-utils';
import NoteAuthor from '~/rapid_diffs/app/discussions/note_author.vue';

describe('NoteAuthor', () => {
  let wrapper;

  const createComponent = (props = {}, slots = {}) => {
    wrapper = shallowMount(NoteAuthor, {
      propsData: props,
      slots,
    });
  };

  const findAuthorLink = () => wrapper.find('a');

  it('renders link with author path', () => {
    const author = {
      id: 'gid://gitlab/User/123',
      name: 'John Doe',
      username: 'johndoe',
      path: '/johndoe',
    };
    createComponent({ author });

    const link = findAuthorLink();
    expect(link.exists()).toBe(true);
    expect(link.attributes('href')).toBe('/johndoe');
    expect(link.text()).toBe('John Doe@johndoe');
    expect(link.attributes('data-user-id')).toBe('123');
    expect(link.attributes('data-username')).toBe('johndoe');
  });

  it('skips username when not present', () => {
    const author = {
      id: 'gid://gitlab/User/123',
      name: 'John Doe',
      username: undefined,
      path: '/johndoe',
    };
    createComponent({ author });

    const link = findAuthorLink();
    expect(link.text()).toBe('John Doe');
  });

  it('skips username when showUsername is false', () => {
    const author = {
      id: 'gid://gitlab/User/123',
      name: 'John Doe',
      username: 'johndoe',
      path: '/johndoe',
    };
    createComponent({ author, showUsername: false });

    const link = findAuthorLink();
    expect(link.text()).toBe('John Doe');
  });

  it('uses webUrl when path is not available', () => {
    const author = {
      id: 'gid://gitlab/User/123',
      name: 'John Doe',
      username: 'johndoe',
      webUrl: 'https://example.com/johndoe',
    };
    createComponent({ author });

    expect(findAuthorLink().attributes('href')).toBe('https://example.com/johndoe');
  });
});
