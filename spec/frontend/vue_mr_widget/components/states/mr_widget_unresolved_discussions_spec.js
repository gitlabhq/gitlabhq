import { mount } from '@vue/test-utils';
import { TEST_HOST } from 'helpers/test_constants';
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

  afterEach(() => {
    wrapper.destroy();
  });

  it('triggers the correct notes event when the jump to first unresolved discussion button is clicked', () => {
    jest.spyOn(notesEventHub, '$emit');

    wrapper.find('[data-testid="jump-to-first"]').trigger('click');

    expect(notesEventHub.$emit).toHaveBeenCalledWith('jumpToFirstUnresolvedDiscussion');
  });

  describe('with threads path', () => {
    beforeEach(() => {
      wrapper = createComponent({ path: TEST_HOST });
    });

    afterEach(() => {
      wrapper.destroy();
    });

    it('should have correct elements', () => {
      expect(wrapper.element.innerText).toContain(`Merge blocked: all threads must be resolved.`);

      expect(wrapper.element.innerText).toContain('Jump to first unresolved thread');
      expect(wrapper.element.innerText).toContain('Resolve all threads in new issue');
      expect(wrapper.element.querySelector('.js-create-issue').getAttribute('href')).toEqual(
        TEST_HOST,
      );
    });
  });

  describe('without threads path', () => {
    it('should not show create issue link if user cannot create issue', () => {
      expect(wrapper.element.innerText).toContain(`Merge blocked: all threads must be resolved.`);

      expect(wrapper.element.innerText).toContain('Jump to first unresolved thread');
      expect(wrapper.element.innerText).not.toContain('Resolve all threads in new issue');
      expect(wrapper.element.querySelector('.js-create-issue')).toEqual(null);
    });
  });
});
