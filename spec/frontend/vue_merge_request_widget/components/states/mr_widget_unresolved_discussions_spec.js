import { mount } from '@vue/test-utils';
import { TEST_HOST } from 'helpers/test_constants';
import { removeBreakLine } from 'helpers/text_helper';
import notesEventHub from '~/notes/event_hub';
import UnresolvedDiscussions from '~/vue_merge_request_widget/components/states/unresolved_discussions.vue';

function createComponent({ path = '' } = {}) {
  return mount(UnresolvedDiscussions, {
    propsData: {
      mr: {
        createIssueToResolveDiscussionsPath: path,
      },
    },
  });
}

describe('UnresolvedDiscussions', () => {
  let wrapper;

  beforeEach(() => {
    wrapper = createComponent();
  });

  it('triggers the correct notes event when the go to first unresolved discussion button is clicked', () => {
    jest.spyOn(notesEventHub, '$emit');

    wrapper.find('[data-testid="jump-to-first"]').trigger('click');

    expect(notesEventHub.$emit).toHaveBeenCalledWith('jumpToFirstUnresolvedDiscussion');
  });

  describe('with threads path', () => {
    beforeEach(() => {
      wrapper = createComponent({ path: TEST_HOST });
    });

    it('should have correct elements', () => {
      const text = removeBreakLine(wrapper.text()).trim();
      expect(text).toContain('Merge blocked:');
      expect(text).toContain('all threads must be resolved.');

      expect(wrapper.element.innerText).toContain('Go to first unresolved thread');
    });
  });

  describe('without threads path', () => {
    it('should not show create issue link if user cannot create issue', () => {
      const text = removeBreakLine(wrapper.text()).trim();
      expect(text).toContain('Merge blocked:');
      expect(text).toContain('all threads must be resolved.');

      expect(wrapper.element.innerText).toContain('Go to first unresolved thread');
    });
  });
});
