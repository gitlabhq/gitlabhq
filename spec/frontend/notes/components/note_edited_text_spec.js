import { shallowMount, createLocalVue } from '@vue/test-utils';
import NoteEditedText from '~/notes/components/note_edited_text.vue';

const localVue = createLocalVue();
const propsData = {
  actionText: 'Edited',
  className: 'foo-bar',
  editedAt: '2017-08-04T09:52:31.062Z',
  editedBy: {
    avatar_url: 'path',
    id: 1,
    name: 'Root',
    path: '/root',
    state: 'active',
    username: 'root',
  },
};

describe('NoteEditedText', () => {
  let wrapper;

  beforeEach(() => {
    wrapper = shallowMount(NoteEditedText, {
      localVue,
      propsData,
      sync: false,
      attachToDocument: true,
    });
  });

  afterEach(() => {
    wrapper.destroy();
  });

  it('should render block with provided className', () => {
    expect(wrapper.classes()).toContain(propsData.className);
  });

  it('should render provided actionText', () => {
    expect(wrapper.text().trim()).toContain(propsData.actionText);
  });

  it('should render provided user information', () => {
    const authorLink = wrapper.find('.js-user-link');

    expect(authorLink.attributes('href')).toEqual(propsData.editedBy.path);
    expect(authorLink.text().trim()).toEqual(propsData.editedBy.name);
  });
});
