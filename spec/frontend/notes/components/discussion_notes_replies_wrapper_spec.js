import { mount } from '@vue/test-utils';
import DiscussionNotesRepliesWrapper from '~/notes/components/discussion_notes_replies_wrapper.vue';

const TEST_CHILDREN = '<li>Hello!</li><li>World!</li>';

// We have to wrap our SUT with a TestComponent because multiple roots are possible
// because it's a functional component.
const TestComponent = {
  components: { DiscussionNotesRepliesWrapper },
  template: `<ul><discussion-notes-replies-wrapper v-bind="$attrs">${TEST_CHILDREN}</discussion-notes-replies-wrapper></ul>`,
};

describe('DiscussionNotesRepliesWrapper', () => {
  let wrapper;

  const createComponent = (props = {}) => {
    wrapper = mount(TestComponent, {
      propsData: props,
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  describe('when normal discussion', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders children directly', () => {
      expect(wrapper.element.outerHTML).toEqual(`<ul>${TEST_CHILDREN}</ul>`);
    });
  });

  describe('when diff discussion', () => {
    beforeEach(() => {
      createComponent({
        isDiffDiscussion: true,
      });
    });

    it('wraps children with notes', () => {
      const notes = wrapper.find('li.discussion-collapsible ul.notes');

      expect(notes.exists()).toBe(true);
      expect(notes.element.outerHTML).toEqual(`<ul class="notes">${TEST_CHILDREN}</ul>`);
    });
  });
});
