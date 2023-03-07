import { GlSprintf } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import WorkItemHistoryOnlyFilterNote from '~/work_items/components/notes/work_item_history_only_filter_note.vue';
import {
  WORK_ITEM_NOTES_FILTER_ALL_NOTES,
  WORK_ITEM_NOTES_FILTER_ONLY_COMMENTS,
} from '~/work_items/constants';

describe('Work Item History Filter note', () => {
  let wrapper;

  const findShowAllActivityButton = () => wrapper.findByTestId('show-all-activity');
  const findShowCommentsButton = () => wrapper.findByTestId('show-comments-only');

  const createComponent = () => {
    wrapper = shallowMountExtended(WorkItemHistoryOnlyFilterNote, {
      stubs: {
        GlSprintf,
      },
    });
  };

  beforeEach(() => {
    createComponent();
  });

  it('timelineContent renders a string containing instruction for switching feed type', () => {
    expect(wrapper.text()).toContain(
      "You're only seeing other activity in the feed. To add a comment, switch to one of the following options.",
    );
  });

  it('emits `changeFilter` event with 0 parameter on clicking Show all activity button', () => {
    findShowAllActivityButton().vm.$emit('click');

    expect(wrapper.emitted('changeFilter')).toEqual([[WORK_ITEM_NOTES_FILTER_ALL_NOTES]]);
  });

  it('emits `changeFilter` event with 1 parameter on clicking Show comments only button', () => {
    findShowCommentsButton().vm.$emit('click');

    expect(wrapper.emitted('changeFilter')).toEqual([[WORK_ITEM_NOTES_FILTER_ONLY_COMMENTS]]);
  });
});
