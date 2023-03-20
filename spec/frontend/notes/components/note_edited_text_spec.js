import { GlSprintf, GlLink } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import NoteEditedText from '~/notes/components/note_edited_text.vue';

const propsData = {
  actionText: 'Edited',
  className: 'foo-bar',
  editedAt: '2017-08-04T09:52:31.062Z',
  editedBy: null,
};

describe('NoteEditedText', () => {
  let wrapper;

  const createWrapper = (props = {}) => {
    wrapper = shallowMount(NoteEditedText, {
      propsData: {
        ...propsData,
        ...props,
      },
      stubs: {
        GlSprintf,
      },
    });
  };

  const findUserElement = () => wrapper.findComponent(GlLink);

  describe('default', () => {
    beforeEach(() => {
      createWrapper();
    });

    it('should render block with provided className', () => {
      expect(wrapper.classes()).toContain(propsData.className);
    });

    it('should render provided actionText', () => {
      expect(wrapper.text().trim()).toContain(propsData.actionText);
    });

    it('should not render user information', () => {
      expect(findUserElement().exists()).toBe(false);
    });
  });

  describe('edited note', () => {
    const editedBy = {
      avatar_url: 'path',
      id: 1,
      name: 'Root',
      path: '/root',
      state: 'active',
      username: 'root',
    };

    beforeEach(() => {
      createWrapper({ editedBy });
    });

    it('should render user information', () => {
      const authorLink = findUserElement();

      expect(authorLink.attributes('href')).toEqual(editedBy.path);
      expect(authorLink.text().trim()).toEqual(editedBy.name);
    });
  });
});
